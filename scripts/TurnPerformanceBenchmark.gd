extends SceneTree

# Repeatable, headless strategic-turn benchmark. No gameplay files are changed.
# godot --headless --path . --script res://scripts/TurnPerformanceBenchmark.gd -- --output-dir /tmp/turn-benchmark
# Or: ... -- --save-file /absolute/path/game.ssave --samples 7 --output-dir /tmp/turn-benchmark
#
# Uses the actual ProvinceSystem, EnemyTurnSystem, EngagementResolver, BossSystem
# and generated geography. Rendering, camera animation, and player physics
# are intentionally excluded: this measures the pre-battle strategic work.
const LevelConfig = preload("res://scripts/LevelConfig.gd")
const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const EnemyTurnSystemScript = preload("res://scripts/EnemyTurnSystem.gd")
const EngagementResolverScript = preload("res://scripts/EngagementResolver.gd")
const BossSystemScript = preload("res://scripts/BossSystem.gd")

const PHASES: Array[String] = [
	"queue_planning",
	"pending_invasions",
	"marches",
	"construction_phase",
	"recruitment_phase",
	"boss_actions",
	"economy_migration_construction_revolts",
	"turn_income",
	"strategic_total"
]

class BenchmarkMain extends Node:
	const ENEMY_MARCH_LEAVE_BEHIND: int = LevelConfig.ENEMY_MARCH_LEAVE_BEHIND
	const ENEMY_MARCH_THRESHOLD: int = LevelConfig.ENEMY_MARCH_THRESHOLD
	const FRIENDLY_MARCH_THRESHOLD: int = LevelConfig.FRIENDLY_MARCH_THRESHOLD
	const BOSS_MARCH_THRESHOLD: int = LevelConfig.BOSS_MARCH_THRESHOLD
	const INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT: int = LevelConfig.INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT
	var _province_persistence: Array[Dictionary] = []
	var province_system = null
	var enemy_turn_system = null
	var engagement_resolver = null
	var boss_system = null
	var level_flow = null
	var ui_bridge = null
	var provinces_root: Node2D = Node2D.new()
	var gold_balance: int = 0
	var map_seed: int = 1
	var turn_number: int = 1
	var level_index: int = 3
	var _current_phase: String = "grand_map"
	var _locked_province_id_after_win: int = -1
	var _construction_build_mode_enabled: bool = false
	var campaign_debug_bonus_gold_per_turn: int = 0
	var capital_id: int = -1

	func get_friendly_march_threshold() -> int:
		return FRIENDLY_MARCH_THRESHOLD
	func get_enemy_march_threshold() -> int:
		return ENEMY_MARCH_THRESHOLD
	func get_boss_march_threshold() -> int:
		return BOSS_MARCH_THRESHOLD
	func get_enemy_march_leave_behind() -> int:
		return ENEMY_MARCH_LEAVE_BEHIND
	func should_defer_province_visual_refresh_during_automation() -> bool:
		return true
	func mark_automated_turn_visual_flush_pending() -> void:
		pass
	func _is_milestone(_idx: int) -> bool:
		return false
	func get_player_capital_province_id() -> int:
		return capital_id

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var argv: PackedStringArray = OS.get_cmdline_user_args()
	var samples: int = 7
	var warm_replays: int = 1
	var output_dir: String = "user://turn-performance-benchmark"
	var save_file: String = ""
	for i in range(argv.size() - 1):
		match argv[i]:
			"--samples":
				samples = clampi(int(argv[i + 1]), 2, 100)
			"--warm-replays":
				warm_replays = clampi(int(argv[i + 1]), 0, 10)
			"--output-dir":
				output_dir = String(argv[i + 1])
			"--save-file":
				save_file = String(argv[i + 1])

	var absolute_dir: String = ProjectSettings.globalize_path(output_dir) if output_dir.begins_with("user://") else output_dir
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		printerr("TURN_BENCH_ERROR cannot_create_output ", absolute_dir)
		quit(2)
		return

	var fixtures: Array[Dictionary] = []
	if save_file != "":
		var saved: Dictionary = _fixture_from_save(save_file)
		if saved.is_empty():
			printerr("TURN_BENCH_ERROR invalid_save_file ", save_file)
			quit(3)
			return
		fixtures.append(saved)
	else:
		fixtures.append(_make_generated_fixture("mid_turn_5", 71, 5, -1))
		fixtures.append(_make_generated_fixture("contested_turn_8", 172, 8, -1))
		fixtures.append(_make_generated_fixture("boss_turn_8", 273, 8, 5))
	var results: Array[Dictionary] = []
	var all_ok: bool = true
	for fixture in fixtures:
		if fixture.is_empty():
			all_ok = false
			continue
		var result: Dictionary = _benchmark_fixture(fixture, samples, warm_replays)
		results.append(result)
		if not bool(result.get("deterministic", false)):
			all_ok = false
		print("TURN_BENCH_SCENARIO ", JSON.stringify(result))
	var report: Dictionary = {
		"ok": all_ok,
		"mode": "headless_strategic_turn_only",
		"source_commit": OS.get_environment("GITHUB_SHA"),
		"engine": Engine.get_version_info().get("string", "unknown"),
		"samples_per_fixture": samples,
		"excluded_warmup_replays": warm_replays,
		"scenarios": results,
		"notes": [
			"Times exclude generated-map setup, fixture loading, replay restoration, digest calculation, writing files, visual refreshes, camera motion, and battle animation.",
			"One real turn is timed repeatedly from an identical state with the global random generator seeded identically before each replay.",
			"Only strategic turn phases represented by the existing autoplay headless wiring are measured. Live MainLevelFlow boss arrival scheduling, UI callbacks, and real visual presentation require separate in-game measurement.",
			"Hashes include complete persistent province and boss state plus treasury, but do not prove parity with an uninstrumented browser turn.",
			"The snapshot fixture RNG is fixed for reproducible comparison; ordinary browser saves do not serialize Godot's global RNG state."
		]
	}
	var path: String = absolute_dir.path_join("turn_performance_report.json")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("TURN_BENCH_ERROR cannot_write ", path)
		quit(4)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("TURN_BENCH_COMPLETE ", JSON.stringify({"ok": all_ok, "report": path, "fixtures": results.size(), "samples": samples}))
	quit(0 if all_ok else 5)

func _fixture_from_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var binary: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if binary.is_empty() or binary.size() > 20000000:
		return {}
	var value: Variant = bytes_to_var(binary)
	if not (value is Dictionary):
		return {}
	var payload: Dictionary = value
	if String(payload.get("format", "")) != "SunnySlopesGame" or int(payload.get("version", 0)) != 1:
		return {}
	var provinces: Array = payload.get("provinces", [])
	if provinces.is_empty() or provinces.size() > 1000:
		return {}
	var campaign: Dictionary = payload.get("campaign", {})
	return {
		"name": "saved_level_%d_turn_%d" % [int(campaign.get("progress", 0)), int(payload.get("turn_number", 1))],
		"map_seed": int(payload.get("map_seed", 1)),
		"level_index": int(payload.get("level_index", 3)),
		"turn_number": int(payload.get("turn_number", 1)),
		"provinces": provinces.duplicate(true),
		"boss_state": (payload.get("boss_state", {}) as Dictionary).duplicate(true),
		"gold": int(payload.get("gold", 0)),
		"capital_id": int(payload.get("capital_id", -1)),
		"debug_gold": int(campaign.get("debug_gold", 0)),
		"enemy_factions": int(campaign.get("enemy_factions", LevelConfig.get_runtime_enemy_faction_count()))
	}

func _make_generated_fixture(label: String, map_seed: int, warmup_turns: int, spawn_boss_on_turn: int) -> Dictionary:
	seed(map_seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	var generator = LevelGeneratorScript.new()
	var generated: Dictionary = generator._generate_template_grand_map_data(LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS, rng, map_seed, 3)
	var main := BenchmarkMain.new()
	main.map_seed = map_seed
	_setup_systems(main)
	for raw_any in generated.get("provinces", []):
		if not (raw_any is Dictionary):
			continue
		var raw: Dictionary = raw_any
		var province: Dictionary = {
			"id": int(raw.get("id", -1)),
			"province_name": String(raw.get("province_name", "Province %d" % int(raw.get("id", -1)))),
			"type": String(raw.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			"faction_id": int(raw.get("faction_id", 0)),
			"remaining_troops": int(raw.get("troops", 0)),
			"remaining_buildings": int(raw.get("buildings", 0)),
			"building_capacity": int(raw.get("building_capacity", 8)),
			"neighbors": (raw.get("neighbors", []) as Array).duplicate(),
			"is_target": bool(raw.get("is_target", false)),
			"is_boss_home": false,
			"invading_troops": 0
		}
		main.province_system.normalize_province_economy_state(province)
		main._province_persistence.append(province)
		if main.capital_id < 0 and String(province.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			main.capital_id = int(province.get("id", -1))
	for warmup_step in range(1, warmup_turns + 1):
		if warmup_step == spawn_boss_on_turn:
			_spawn_representative_boss(main)
		_advance_strategic_turn(main, false)
	var fixture: Dictionary = _capture_fixture(main, label)
	_dispose_main(main)
	return fixture

func _spawn_representative_boss(main: BenchmarkMain) -> void:
	# Test-only boss activation, deliberately excluded from measured time.
	var home_id: int = -1
	var neighbors: Array[int] = []
	for province in main._province_persistence:
		if String(province.get("type", "")) != LevelConfig.PROVINCE_TYPE_ENEMY:
			continue
		var local_neighbors: Array[int] = main.province_system.normalize_neighbor_ids(province.get("neighbors", []))
		if local_neighbors.size() >= 2:
			home_id = int(province.get("id", -1))
			neighbors = local_neighbors
			break
	if home_id < 0:
		return
	var acquired: Array[int] = []
	for candidate_id in neighbors:
		for province in main._province_persistence:
			if int(province.get("id", -1)) == candidate_id and String(province.get("type", "")) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
				acquired.append(candidate_id)
				break
		if acquired.size() >= 2:
			break
	var faction: int = int(main.boss_system.get_default_boss_faction_id_for_index(0))
	main.boss_system.activate_boss(home_id, acquired, faction)
	for province in main._province_persistence:
		var province_id: int = int(province.get("id", -1))
		if province_id != home_id and not acquired.has(province_id):
			continue
		province["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
		province["faction_id"] = faction
		province["invading_troops"] = 0
		province["invading_source_ids"] = []
		province["pending_invasion_started_turn"] = -1
		province["is_boss_home"] = province_id == home_id
		if province_id == home_id:
			province["remaining_buildings"] = 0
			province["remaining_troops"] = maxi(1, int(main.boss_system.get_boss_home_troop_count()))
		main.province_system.normalize_province_economy_state(province)

func _capture_fixture(main: BenchmarkMain, label: String) -> Dictionary:
	return {
		"name": label,
		"map_seed": main.map_seed,
		"level_index": main.level_index,
		"turn_number": main.turn_number,
		"provinces": main._province_persistence.duplicate(true),
		"boss_state": (main.get_meta("boss_runtime_state", {}) as Dictionary).duplicate(true),
		"gold": main.gold_balance,
		"capital_id": main.capital_id,
		"debug_gold": main.campaign_debug_bonus_gold_per_turn,
		"enemy_factions": LevelConfig.get_runtime_enemy_faction_count()
	}

func _setup_systems(main: BenchmarkMain) -> void:
	main.province_system = ProvinceSystemScript.new()
	main.engagement_resolver = EngagementResolverScript.new()
	main.enemy_turn_system = EnemyTurnSystemScript.new()
	main.boss_system = BossSystemScript.new()
	main.province_system.setup(main)
	main.engagement_resolver.setup(main)
	main.enemy_turn_system.setup(main)
	main.boss_system.setup(main)

func _main_from_fixture(fixture: Dictionary) -> BenchmarkMain:
	LevelConfig.set_runtime_enemy_faction_count(int(fixture.get("enemy_factions", LevelConfig.get_runtime_enemy_faction_count())))
	var main := BenchmarkMain.new()
	main.map_seed = int(fixture.get("map_seed", 1))
	main.turn_number = int(fixture.get("turn_number", 1))
	main.level_index = int(fixture.get("level_index", 3))
	main.gold_balance = int(fixture.get("gold", 0))
	main.capital_id = int(fixture.get("capital_id", -1))
	main.campaign_debug_bonus_gold_per_turn = int(fixture.get("debug_gold", 0))
	main.set_meta("boss_runtime_state", (fixture.get("boss_state", {}) as Dictionary).duplicate(true))
	for entry in fixture.get("provinces", []):
		if entry is Dictionary:
			main._province_persistence.append((entry as Dictionary).duplicate(true))
	_setup_systems(main)
	return main

func _dispose_main(main: BenchmarkMain) -> void:
	main.provinces_root.free()
	main.free()

func _advance_strategic_turn(main: BenchmarkMain, measure: bool) -> Dictionary:
	# Keep the ordering of EnemyTurnSystem.advance_turn_and_run_automation:
	# turn increment, queue planning, pending invasions, two-pass marches,
	# construction/recruitment, boss actions, then the economy and income.
	var stats: Dictionary = {}
	var ps = main.province_system
	var marcher = main.enemy_turn_system
	var started: int = Time.get_ticks_usec()
	main.level_index += 1
	main.turn_number += 1
	marcher.clear_automated_engagement_log()

	var stage: int = Time.get_ticks_usec()
	ps.plan_all_province_construction_queues()
	stats["queue_planning"] = _elapsed_ms(stage)

	stage = Time.get_ticks_usec()
	var invaded: Array[int] = marcher.get_invaded_friendly_province_ids()
	marcher.apply_undefended_invasion_damage(-1, invaded, true)
	stats["pending_invasions"] = _elapsed_ms(stage)

	stage = Time.get_ticks_usec()
	marcher.run_enemy_march_phase(true)
	stats["marches"] = _elapsed_ms(stage)

	stage = Time.get_ticks_usec()
	marcher.process_province_construction(true)
	stats["construction_phase"] = _elapsed_ms(stage)

	stage = Time.get_ticks_usec()
	marcher.recruit_enemy_provinces(true)
	stats["recruitment_phase"] = _elapsed_ms(stage)

	stage = Time.get_ticks_usec()
	marcher._run_boss_turn_phase()
	stats["boss_actions"] = _elapsed_ms(stage)

	stage = Time.get_ticks_usec()
	ps.tick_all_province_economies(-1)
	stats["economy_migration_construction_revolts"] = _elapsed_ms(stage)

	stage = Time.get_ticks_usec()
	# The live map transition credits the newly computed friendly income.
	main.gold_balance += ps.get_total_friendly_gold_income() + maxi(0, main.campaign_debug_bonus_gold_per_turn)
	stats["turn_income"] = _elapsed_ms(stage)

	stats["strategic_total"] = _elapsed_ms(started)
	return stats if measure else {}

func _elapsed_ms(started_usec: int) -> float:
	return float(Time.get_ticks_usec() - started_usec) / 1000.0

func _benchmark_fixture(fixture: Dictionary, samples: int, warm_replays: int) -> Dictionary:
	var values: Dictionary = {}
	for phase in PHASES:
		values[phase] = []
	var expected_digest: String = ""
	var mismatches: int = 0
	var first_end_summary: Dictionary = {}
	var rng_seed: int = int(fixture.get("map_seed", 1)) * 1009 + int(fixture.get("turn_number", 1)) * 9176
	for attempt in range(samples + warm_replays):
		seed(rng_seed)
		var main: BenchmarkMain = _main_from_fixture(fixture)
		var measurements: Dictionary = _advance_strategic_turn(main, true)
		var digest: String = _state_digest(main)
		if attempt >= warm_replays:
			if expected_digest == "":
				expected_digest = digest
				first_end_summary = _state_summary(main)
			elif expected_digest != digest:
				mismatches += 1
			for phase in PHASES:
				(values[phase] as Array).append(float(measurements.get(phase, 0.0)))
		_dispose_main(main)
	var summaries: Dictionary = {}
	for phase in PHASES:
		summaries[phase] = _statistics(values[phase])
	return {
		"name": String(fixture.get("name", "fixture")),
		"seed": int(fixture.get("map_seed", 1)),
		"turn_before": int(fixture.get("turn_number", 1)),
		"provinces": (fixture.get("provinces", []) as Array).size(),
		"boss_present_at_start": not (fixture.get("boss_state", {}) as Dictionary).get("bosses", []).is_empty(),
		"deterministic": mismatches == 0,
		"mismatched_replays": mismatches,
		"end_state_sha256": expected_digest,
		"end_summary": first_end_summary,
		"timings_ms": summaries
	}

func _state_digest(main: BenchmarkMain) -> String:
	var record: Dictionary = {
		"turn": main.turn_number,
		"gold": main.gold_balance,
		"provinces": main._province_persistence,
		"boss": main.get_meta("boss_runtime_state", {})
	}
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(var_to_bytes(record))
	return ctx.finish().hex_encode()

func _state_summary(main: BenchmarkMain) -> Dictionary:
	var owners: Dictionary = {}
	var troops: int = 0
	var pending: int = 0
	var total_population: float = 0.0
	for province in main._province_persistence:
		var owner: String = String(province.get("type", ""))
		if owner == LevelConfig.PROVINCE_TYPE_ENEMY:
			owner += ":%d" % int(province.get("faction_id", 0))
		owners[owner] = int(owners.get(owner, 0)) + 1
		troops += int(province.get("remaining_troops", 0))
		pending += int(province.get("invading_troops", 0))
		var population: Dictionary = province.get("population", {})
		total_population += float(population.get("natives", 0.0)) + float(population.get("outlanders", 0.0))
	return {"owners": owners, "troops": troops, "pending_invaders": pending, "population": total_population, "gold": main.gold_balance}

func _statistics(raw: Array) -> Dictionary:
	var sorted: Array[float] = []
	var total: float = 0.0
	for v in raw:
		var value: float = float(v)
		sorted.append(value)
		total += value
	sorted.sort()
	if sorted.is_empty():
		return {"samples": 0}
	var count: int = sorted.size()
	var median: float = sorted[count / 2] if count % 2 == 1 else (sorted[count / 2 - 1] + sorted[count / 2]) * 0.5
	var p95: float = sorted[clampi(ceili(float(count) * 0.95) - 1, 0, count - 1)]
	return {"samples": count, "median": snappedf(median, 0.001), "p95": snappedf(p95, 0.001), "mean": snappedf(total / float(count), 0.001), "min": snappedf(sorted[0], 0.001), "max": snappedf(sorted.back(), 0.001)}
