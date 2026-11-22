extends "res://scripts/TurnPerformanceBenchmark.gd"

# Cross-revision strategic parity regression. Reuses the production-system
# fixture generation, turn execution, and timing paths in TurnPerformanceBenchmark.
#
# Capture with the pinned, unmodified reference game:
#   godot --headless --path . --script res://scripts/StrategicTurnParityRegression.gd -- \
#     --mode capture --turns 20 --artifact-dir /tmp/turn-parity
# Verify a candidate against those EXACT binary starting states:
#   godot --headless --path . --script res://scripts/StrategicTurnParityRegression.gd -- \
#     --mode verify --artifact-dir /tmp/turn-parity
#
# The runner is copied unchanged into the reference checkout by CI. Only the
# gameplay implementations loaded by its parent benchmark differ between runs.

const PARITY_SCHEMA: int = 1
const DEFAULT_TURNS: int = 20
const REFERENCE_SOURCE_COMMIT: String = "72a7b826f2a4aaa98e89e6f4557b98f33190cdb4"

func _run() -> void:
	var argv: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = ""
	var artifact_dir: String = "user://strategic-turn-parity"
	var turns: int = DEFAULT_TURNS
	var save_file: String = ""
	for i in range(argv.size() - 1):
		match String(argv[i]):
			"--mode":
				mode = String(argv[i + 1]).strip_edges()
			"--artifact-dir":
				artifact_dir = String(argv[i + 1])
			"--turns":
				turns = clampi(int(argv[i + 1]), 1, 120)
			"--save-file":
				save_file = String(argv[i + 1])
	if mode != "capture" and mode != "verify":
		printerr("TURN_PARITY_ERROR specify --mode capture or --mode verify")
		quit(2)
		return
	var absolute_dir: String = ProjectSettings.globalize_path(artifact_dir) if artifact_dir.begins_with("user://") or artifact_dir.begins_with("res://") else artifact_dir
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		printerr("TURN_PARITY_ERROR cannot_create_dir ", absolute_dir)
		quit(3)
		return
	var passed: bool = _capture_baseline(absolute_dir, turns, save_file) if mode == "capture" else _verify_candidate(absolute_dir)
	print("TURN_PARITY_COMPLETE ", JSON.stringify({"ok": passed, "mode": mode, "artifact_dir": absolute_dir}))
	quit(0 if passed else 5)


func _generated_fixtures() -> Array[Dictionary]:
	return [
		_make_generated_fixture("mid_turn_5", 71, 5, -1),
		_make_generated_fixture("contested_turn_8", 172, 8, -1),
		_make_generated_fixture("boss_turn_8", 273, 8, 5),
		_make_generated_fixture("early_turn_1", 425, 1, -1),
		_make_generated_fixture("late_boss_turn_16", 829, 16, 5)
	]


func _capture_baseline(artifact_dir: String, turns: int, save_file: String) -> bool:
	var fixtures: Array[Dictionary] = _generated_fixtures()
	if save_file != "":
		var saved: Dictionary = _fixture_from_save(save_file)
		if saved.is_empty():
			printerr("TURN_PARITY_ERROR invalid_save_file ", save_file)
			return false
		fixtures.append(saved)
	var manifest_scenarios: Array[Dictionary] = []
	for index in range(fixtures.size()):
		var fixture: Dictionary = fixtures[index]
		if fixture.is_empty():
			printerr("TURN_PARITY_ERROR empty_generated_fixture ", index)
			return false
		var scenario_name: String = String(fixture.get("name", "scenario_%d" % index))
		var file_name: String = "scenario_%02d.parity" % index
		var rng_seed: int = _replay_seed(fixture)
		var replay: Dictionary = _replay_fixture(fixture, turns, rng_seed)
		var records: Array = replay.get("records", [])
		if records.size() != turns:
			printerr("TURN_PARITY_ERROR incomplete_baseline ", scenario_name)
			return false
		# A second replay guards against accidentally freezing a nondeterministic
		# baseline. Neither replay includes timestamps or wall-clock durations in
		# its expected gameplay observations.
		var confirmation: Dictionary = _replay_fixture(fixture, turns, rng_seed)
		var confirm_records: Array = confirmation.get("records", [])
		if confirm_records.size() != records.size():
			printerr("TURN_PARITY_ERROR baseline_not_deterministic ", scenario_name)
			return false
		for turn_index in range(records.size()):
			var first_observation: Dictionary = records[turn_index].get("observation", {})
			var confirm_observation: Dictionary = confirm_records[turn_index].get("observation", {})
			var mismatch: String = _first_difference(first_observation, confirm_observation, "state")
			if mismatch != "":
				printerr("TURN_PARITY_ERROR baseline_not_deterministic ", scenario_name, " step=", turn_index + 1, " ", mismatch)
				return false
		var payload: Dictionary = {
			"schema": PARITY_SCHEMA,
			"scenario": scenario_name,
			"rng_seed": rng_seed,
			"fixture": fixture.duplicate(true),
			"records": records
		}
		if not _write_variant(artifact_dir.path_join(file_name), payload):
			return false
		manifest_scenarios.append({"name": scenario_name, "file": file_name, "turns": turns})
		print("TURN_PARITY_CAPTURED ", JSON.stringify({"scenario": scenario_name, "turns": turns, "file": file_name, "initial_provinces": (fixture.get("provinces", []) as Array).size()}))
	var manifest: Dictionary = {
		"schema": PARITY_SCHEMA,
		"reference_source_commit": REFERENCE_SOURCE_COMMIT,
		"engine": Engine.get_version_info().get("string", ""),
		"scenarios": manifest_scenarios,
		"notes": [
			"All fixtures are generated and then frozen by the pinned reference gameplay source.",
			"Every expected turn includes full persistent province and boss data, treasury, turn counters, automated engagement logs, sanitized march diagnostics, and a future RNG probe.",
			"Godot system-clock timestamps and timing values are not compared for equality.",
			"Headless strategic simulation does not include MainLevelFlow arrivals, animated previews, physics, or province-node rendering."
		]
	}
	return _write_text(artifact_dir.path_join("baseline_manifest.json"), JSON.stringify(manifest, "\t"))


func _verify_candidate(artifact_dir: String) -> bool:
	var manifest_path: String = artifact_dir.path_join("baseline_manifest.json")
	if not FileAccess.file_exists(manifest_path):
		printerr("TURN_PARITY_ERROR missing_manifest ", manifest_path)
		return false
	var manifest_any: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not (manifest_any is Dictionary):
		printerr("TURN_PARITY_ERROR invalid_manifest")
		return false
	var manifest: Dictionary = manifest_any
	if int(manifest.get("schema", -1)) != PARITY_SCHEMA:
		printerr("TURN_PARITY_ERROR unexpected_schema ", manifest.get("schema", null))
		return false
	if String(manifest.get("reference_source_commit", "")) != REFERENCE_SOURCE_COMMIT:
		printerr("TURN_PARITY_ERROR unexpected_baseline_commit")
		return false
	var scenarios: Array = manifest.get("scenarios", [])
	if scenarios.is_empty():
		printerr("TURN_PARITY_ERROR empty_manifest")
		return false
	var reports: Array[Dictionary] = []
	var all_ok: bool = true
	for scenario_any in scenarios:
		if not (scenario_any is Dictionary):
			all_ok = false
			continue
		var scenario: Dictionary = scenario_any
		var scenario_name: String = String(scenario.get("name", "unnamed"))
		var file_name: String = String(scenario.get("file", ""))
		# Never accept path traversal from a modified manifest.
		if file_name.get_file() != file_name or not file_name.ends_with(".parity"):
			printerr("TURN_PARITY_ERROR invalid_filename ", file_name)
			all_ok = false
			continue
		var payload: Dictionary = _read_variant(artifact_dir.path_join(file_name))
		if int(payload.get("schema", -1)) != PARITY_SCHEMA:
			printerr("TURN_PARITY_ERROR missing_or_invalid_scenario ", scenario_name)
			all_ok = false
			continue
		var fixture: Dictionary = payload.get("fixture", {})
		var expected: Array = payload.get("records", [])
		var expected_turns: int = int(scenario.get("turns", -1))
		if fixture.is_empty() or expected_turns <= 0 or expected.size() != expected_turns:
			printerr("TURN_PARITY_ERROR invalid_fixture_or_turns ", scenario_name)
			all_ok = false
			continue
		var replay: Dictionary = _replay_fixture(fixture, expected_turns, int(payload.get("rng_seed", -1)))
		var actual: Array = replay.get("records", [])
		var first_mismatch: String = ""
		var first_mismatch_turn: int = -1
		if actual.size() != expected.size():
			first_mismatch = "turn_count expected=%d actual=%d" % [expected.size(), actual.size()]
		else:
			for turn_index in range(expected.size()):
				var expected_state: Dictionary = expected[turn_index].get("observation", {})
				var actual_state: Dictionary = actual[turn_index].get("observation", {})
				first_mismatch = _first_difference(expected_state, actual_state, "state")
				if first_mismatch != "":
					first_mismatch_turn = turn_index + 1
					break
		var row: Dictionary = {
			"scenario": scenario_name,
			"ok": first_mismatch == "",
			"turns_compared": mini(expected.size(), actual.size()),
			"first_mismatch_turn": first_mismatch_turn,
			"first_mismatch": first_mismatch,
			"reference_timing_ms": _total_timing_summary(expected),
			"candidate_timing_ms": _total_timing_summary(actual)
		}
		reports.append(row)
		if first_mismatch != "":
			all_ok = false
			printerr("TURN_PARITY_MISMATCH ", JSON.stringify(row))
		else:
			print("TURN_PARITY_MATCH ", JSON.stringify(row))
	var final_report: Dictionary = {
		"ok": all_ok,
		"reference_source_commit": REFERENCE_SOURCE_COMMIT,
		"candidate_source_commit": OS.get_environment("GITHUB_SHA"),
		"scenarios": reports,
		"note": "Timings are observational and excluded from equality checks; only headless strategic behavior is compared."
	}
	if not _write_text(artifact_dir.path_join("parity_comparison_report.json"), JSON.stringify(final_report, "\t")):
		return false
	return all_ok


func _replay_seed(fixture: Dictionary) -> int:
	return int(fixture.get("map_seed", 1)) * 1009 + int(fixture.get("turn_number", 1)) * 9176


func _replay_fixture(fixture: Dictionary, turns: int, rng_seed: int) -> Dictionary:
	seed(rng_seed)
	var main = _main_from_fixture(fixture)
	var records: Array[Dictionary] = []
	for turn_step in range(turns):
		main.enemy_turn_system.clear_march_diagnostic_records()
		var timings: Dictionary = _advance_strategic_turn(main, true)
		var observation: Dictionary = _capture_observation(main)
		records.append({
			"observation": observation,
			"state_sha256": _variant_sha256(observation),
			"timings_ms": timings
		})
	_dispose_main(main)
	return {"records": records}


func _capture_observation(main: Node) -> Dictionary:
	var diagnostics: Array[Dictionary] = main.enemy_turn_system.get_march_diagnostic_records()
	for record in diagnostics:
		# System clock time changes between the reference and candidate runs.
		# It is observational metadata, not strategic or diagnostic content.
		record.erase("ts_utc")
	return {
		"turn": int(main.turn_number),
		"level_index": int(main.level_index),
		"gold": int(main.gold_balance),
		"capital_id": int(main.capital_id),
		"provinces": main._province_persistence.duplicate(true),
		"boss": (main.get_meta("boss_runtime_state", {}) as Dictionary).duplicate(true),
		"march_diagnostics": diagnostics,
		"automated_log": main.enemy_turn_system.get_automated_engagement_log_lines(),
		# The probe reveals differences in the global random draw stream even
		# when they do not alter the immediate state. Both runs consume it at
		# precisely the same test-only boundary.
		"next_rng_probe": randf()
	}


func _variant_sha256(value: Variant) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(var_to_bytes(value))
	return context.finish().hex_encode()


func _first_difference(expected: Variant, actual: Variant, path: String) -> String:
	if typeof(expected) != typeof(actual):
		return "%s type: expected=%s actual=%s" % [path, type_string(typeof(expected)), type_string(typeof(actual))]
	if expected is Dictionary:
		var ed: Dictionary = expected
		var ad: Dictionary = actual
		for key in ed.keys():
			if not ad.has(key):
				return "%s missing_key=%s" % [path, str(key)]
			var difference: String = _first_difference(ed[key], ad[key], "%s.%s" % [path, str(key)])
			if difference != "":
				return difference
		for key in ad.keys():
			if not ed.has(key):
				return "%s extra_key=%s" % [path, str(key)]
		return ""
	if expected is Array:
		var ea: Array = expected
		var aa: Array = actual
		if ea.size() != aa.size():
			return "%s length: expected=%d actual=%d" % [path, ea.size(), aa.size()]
		for index in range(ea.size()):
			var difference: String = _first_difference(ea[index], aa[index], "%s[%d]" % [path, index])
			if difference != "":
				return difference
		return ""
	if expected != actual:
		return "%s: expected=%s actual=%s" % [path, _short_value(expected), _short_value(actual)]
	return ""


func _short_value(value: Variant) -> String:
	var rendered: String = var_to_str(value)
	return rendered.substr(0, 220) + "..." if rendered.length() > 220 else rendered


func _total_timing_summary(records: Array) -> Dictionary:
	var samples: Array[float] = []
	for record_any in records:
		if record_any is Dictionary:
			var timing: Dictionary = record_any.get("timings_ms", {})
			samples.append(float(timing.get("strategic_total", 0.0)))
	if samples.is_empty():
		return {}
	samples.sort()
	var count: int = samples.size()
	var sum_ms: float = 0.0
	for ms in samples:
		sum_ms += ms
	return {
		"turns": count,
		"median": snappedf(samples[count / 2] if count % 2 == 1 else (samples[count / 2 - 1] + samples[count / 2]) * 0.5, 0.001),
		"mean": snappedf(sum_ms / float(count), 0.001),
		"max": snappedf(samples.back(), 0.001)
	}


func _write_variant(path: String, value: Variant) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("TURN_PARITY_ERROR cannot_write ", path)
		return false
	file.store_buffer(var_to_bytes(value))
	file.close()
	return true


func _read_variant(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.is_empty() or bytes.size() > 200000000:
		return {}
	var value: Variant = bytes_to_var(bytes)
	return value if value is Dictionary else {}


func _write_text(path: String, value: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("TURN_PARITY_ERROR cannot_write ", path)
		return false
	file.store_string(value)
	file.close()
	return true
