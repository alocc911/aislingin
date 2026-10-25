extends SceneTree

# Reproducible no-human-action campaign harness using live map generation,
# ProvinceSystem, EnemyTurnSystem, EngagementResolver and BossSystem.
# Run: godot --headless --path . --script res://scripts/AutoplayCampaignRunner.gd -- \
#        --seeds 3 --turns 80 --first-seed 71 --boss-turn 15 --output-dir /absolute/path
const LevelConfig = preload("res://scripts/LevelConfig.gd")
const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const EnemyTurnSystemScript = preload("res://scripts/EnemyTurnSystem.gd")
const EngagementResolverScript = preload("res://scripts/EngagementResolver.gd")
const BossSystemScript = preload("res://scripts/BossSystem.gd")

class AutoplayMain extends Node:
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
	var turn_number: int = 0
	var level_index: int = 3
	var _current_phase: String = "grand_map"
	var _locked_province_id_after_win: int = -1
	var _construction_build_mode_enabled: bool = false
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

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var seeds_count: int = 3
	var first_seed: int = 71
	var max_turns: int = 80
	var boss_turn: int = 15
	var output_dir: String = "user://autoplay-results"
	for i in range(args.size() - 1):
		match args[i]:
			"--seeds":
				seeds_count = clampi(int(args[i + 1]), 1, 100)
			"--first-seed":
				first_seed = int(args[i + 1])
			"--turns":
				max_turns = clampi(int(args[i + 1]), 1, 2000)
			"--boss-turn":
				boss_turn = clampi(int(args[i + 1]), 0, 2000)
			"--output-dir":
				output_dir = String(args[i + 1])
	var absolute_dir: String = ProjectSettings.globalize_path(output_dir) if output_dir.begins_with("user://") else output_dir
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		printerr("AUTOPLAY_ERROR cannot_create_output ", absolute_dir)
		quit(2)
		return
	var summaries: Array[Dictionary] = []
	var csv: Array[String] = ["seed,turn,owner,provinces,troops,neutral_provinces,leader,leader_share,active_factions,marches,attacks,reinforcements,conquests,revolts,boss_active,boss_provinces,boss_share,boss_spawned"]
	for index in range(seeds_count):
		var map_seed: int = first_seed + index * 101
		var result: Dictionary = _run_seed(map_seed, max_turns, boss_turn, csv)
		summaries.append(result)
		print("AUTOPLAY_SEED ", JSON.stringify(result))
	var failures: Array[String] = []
	for row in summaries:
		if row.has("error"):
			failures.append("seed_%d_%s" % [int(row.get("seed", -1)), String(row.get("error", ""))])
		elif boss_turn > 0 and int(row.get("turns_simulated", 0)) >= boss_turn and not bool(row.get("boss_spawned", false)):
			failures.append("seed_%d_boss_not_spawned" % int(row.get("seed", -1)))
	var boss_dominance: int = 0
	var boss_full_control: int = 0
	var ordinary_full_control: int = 0
	var stalemates: int = 0
	var dominant_turns: Array[int] = []
	for row in summaries:
		if bool(row.get("boss_ever_led", false)):
			boss_dominance += 1
		if bool(row.get("boss_full_control", false)):
			boss_full_control += 1
		if bool(row.get("ordinary_full_control", false)):
			ordinary_full_control += 1
		if int(row.get("final_active_owners", 0)) > 1:
			stalemates += 1
		if int(row.get("first_majority_turn", -1)) >= 0:
			dominant_turns.append(int(row.get("first_majority_turn")))
	var report: Dictionary = {
		"mode": "headless_no_human_actions",
		"engine": "real_generated_map_and_live_game_systems",
		"settings": {"seed_count": seeds_count, "first_seed": first_seed, "turns": max_turns, "boss_spawn_turn": boss_turn},
		"failures": failures,
		"aggregate": {
			"boss_ever_led_runs": boss_dominance,
			"boss_full_control_runs": boss_full_control,
			"ordinary_full_control_runs": ordinary_full_control,
			"runs_with_multiple_owners_at_end": stalemates,
			"majority_turns": dominant_turns
		},
		"limitations": [
			"No mouse or player combat actions; friendly provinces retain their existing automated marching and economy.",
			"Boss spawn occurs at a fixed configurable turn using live BossSystem and two starting acquired provinces; actual campaign roll-based spawn schedule and map presentation are not simulated.",
			"Game-over and victory UI are not invoked; full control and boss dominance are measured from actual persistent province ownership.",
			"Boss and other turns use headless systems with graphics/UI omitted."
		],
		"runs": summaries
	}
	var summary_file: FileAccess = FileAccess.open(absolute_dir.path_join("autoplay_summary.json"), FileAccess.WRITE)
	var timeseries_file: FileAccess = FileAccess.open(absolute_dir.path_join("autoplay_timeseries.csv"), FileAccess.WRITE)
	if summary_file == null or timeseries_file == null:
		printerr("AUTOPLAY_ERROR cannot_write_output")
		quit(3)
		return
	summary_file.store_string(JSON.stringify(report, "\t"))
	summary_file.close()
	for line in csv:
		timeseries_file.store_line(line)
	timeseries_file.close()
	print("AUTOPLAY_COMPLETE ", JSON.stringify({"ok": failures.is_empty(), "failures": failures, "seeds": seeds_count, "turns": max_turns, "boss_ever_led": boss_dominance, "boss_full_control": boss_full_control, "rows": csv.size() - 1}))
	quit(0 if failures.is_empty() else 4)

func _owner_key(p: Dictionary) -> String:
	var type: String = String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if type == LevelConfig.PROVINCE_TYPE_ENEMY:
		var faction_id: int = int(p.get("faction_id", 1))
		# Rebels use faction ID 9000; they are not a boss victory.
		return "boss_%d" % faction_id if faction_id >= 99 and faction_id < 200 else "enemy_%d" % faction_id
	return type

func _tally(provinces: Array[Dictionary]) -> Dictionary:
	var owner_counts: Dictionary = {}
	var troops: Dictionary = {}
	for p in provinces:
		var key: String = _owner_key(p)
		owner_counts[key] = int(owner_counts.get(key, 0)) + 1
		troops[key] = int(troops.get(key, 0)) + maxi(0, int(p.get("remaining_troops", 0)))
	var leader: String = ""
	var leader_count: int = 0
	var active_owners: int = 0
	var boss_count: int = 0
	for key in owner_counts:
		var count: int = int(owner_counts[key])
		if key != "neutral":
			active_owners += 1
		if String(key).begins_with("boss_"):
			boss_count += count
		if count > leader_count and key != "neutral":
			leader = String(key)
			leader_count = count
	return {
		"owners": owner_counts, "troops": troops, "leader": leader,
		"leader_count": leader_count, "active_owners": active_owners,
		"boss_count": boss_count, "neutral_count": int(owner_counts.get("neutral", 0))
	}

func _spawn_boss(main: AutoplayMain, ps: Object, rng: RandomNumberGenerator) -> Dictionary:
	var boss = main.boss_system
	var candidates: Array[Dictionary] = []
	var friendly_id: int = -1
	for p in main._province_persistence:
		if _owner_key(p) == "friendly":
			friendly_id = int(p.get("id", -1))
		var c: Dictionary = {
			"id": int(p.get("id", -1)),
			"type": String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			"is_target": bool(p.get("is_target", false)),
			"center": p.get("center", Vector2.ZERO)
		}
		candidates.append(c)
	var blocked: Array[int] = []
	if friendly_id >= 0:
		blocked.append(friendly_id)
	var home_id: int = int(boss.choose_boss_home_province_id(candidates, blocked))
	if home_id < 0:
		return {}
	blocked.append(home_id)
	var captured_ids: Array[int] = boss.choose_initial_boss_faction_province_ids(candidates, blocked, rng, 2)
	var boss_faction: int = int(boss.get_default_boss_faction_id_for_index(0))
	var entry: Dictionary = {
		"home_province_id": home_id,
		"conquered_province_ids": captured_ids,
		"boss_faction_id": boss_faction,
		"boss_faction_name": "Autoplay Boss",
		"is_friendly_boss": false
	}
	var spawn_entries: Array[Dictionary] = [entry]
	boss.activate_multiple_bosses(spawn_entries)
	for p in main._province_persistence:
		var id: int = int(p.get("id", -1))
		if id != home_id and not captured_ids.has(id):
			continue
		p["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
		p["faction_id"] = boss_faction
		p["invading_troops"] = 0
		p["invading_source_ids"] = []
		p["pending_invasion_started_turn"] = -1
		p["is_boss_home"] = id == home_id
		if id == home_id:
			# Match MainLevelFlow's live boss takeover: it sets the visible
			# building count to zero but retains the underlying typed buildings.
			# Normalization on the next game tick applies the same live behavior.
			p["remaining_buildings"] = 0
			p["remaining_troops"] = maxi(1, int(boss.get_boss_home_troop_count()))
		ps.normalize_province_economy_state(p)
	return entry

func _run_seed(map_seed: int, turns_limit: int, boss_turn: int, csv: Array[String]) -> Dictionary:
	seed(map_seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	var generator = LevelGeneratorScript.new()
	var generated: Dictionary = generator._generate_template_grand_map_data(LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS, rng, map_seed, 3)
	var provinces_raw: Array = generated.get("provinces", [])
	var main := AutoplayMain.new()
	main.map_seed = map_seed
	var ps = ProvinceSystemScript.new()
	var resolver = EngagementResolverScript.new()
	var marcher = EnemyTurnSystemScript.new()
	var boss = BossSystemScript.new()
	main.province_system = ps
	main.engagement_resolver = resolver
	main.enemy_turn_system = marcher
	main.boss_system = boss
	ps.setup(main)
	resolver.setup(main)
	marcher.setup(main)
	boss.setup(main)
	for p_any in provinces_raw:
		var raw: Dictionary = p_any
		var p: Dictionary = {
			"id": int(raw.get("id", -1)),
			"province_name": String(raw.get("province_name", "Province %d" % int(raw.get("id", -1)))),
			"type": String(raw.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			"faction_id": int(raw.get("faction_id", 0)),
			"remaining_troops": int(raw.get("troops", 0)),
			"remaining_buildings": int(raw.get("buildings", 0)),
			"building_capacity": int(raw.get("building_capacity", 8)),
			"neighbors": raw.get("neighbors", []).duplicate(),
			"is_target": bool(raw.get("is_target", false)),
			"is_boss_home": false,
			"center": _polygon_center(raw.get("polygon", PackedVector2Array())),
			"invading_troops": 0
		}
		ps.normalize_province_economy_state(p)
		main._province_persistence.append(p)
	var boss_entry: Dictionary = {}
	var first_majority: int = -1
	var first_80: int = -1
	var first_full: int = -1
	var boss_ever_led: bool = false
	var boss_peak_provinces: int = 0
	var boss_zero_territory_turn: int = -1
	var cumulative_marches: int = 0
	var cumulative_attacks: int = 0
	var cumulative_conquests: int = 0
	var cumulative_revolts: int = 0
	var peak_troops: int = 0
	var total: int = main._province_persistence.size()
	for turn in range(0, turns_limit + 1):
		main.turn_number = turn
		if turn > 0:
			if boss_turn > 0 and turn == boss_turn:
				boss_entry = _spawn_boss(main, ps, rng)
				print("AUTOPLAY_BOSS_SPAWN seed=", map_seed, " turn=", turn, " entry=", JSON.stringify(boss_entry), " ownership=", JSON.stringify(_tally(main._province_persistence).get("owners", {})))
				if boss_entry.is_empty() or not boss.is_boss_active():
					printerr("AUTOPLAY_ERROR boss_activation_failed seed=", map_seed, " turn=", turn)
					main.provinces_root.free()
					main.free()
					return {"seed": map_seed, "error": "boss_activation_failed", "boss_spawned": false}
			if turn % 10 == 0:
				print("AUTOPLAY_PROGRESS seed=", map_seed, " turn=", turn, " of ", turns_limit)
			# Passively earned gold still funds ordinary auto-construction.
			# No player input, purchases, or manually queued orders are supplied.
			for province in main._province_persistence:
				if String(province.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
					main.gold_balance += ps.get_province_total_income(province)
			# Actual automated turn order, with no user shot or manual construction.
			marcher.clear_march_diagnostic_records()
			marcher._run_single_automated_cycle(true)
			var economy_results: Array[Dictionary] = ps.tick_all_province_economies(-1)
			for event in economy_results:
				if bool(event.get("revolted", false)):
					cumulative_revolts += 1
		var tallies: Dictionary = _tally(main._province_persistence)
		var owners: Dictionary = tallies.get("owners", {})
		var troop_totals: Dictionary = tallies.get("troops", {})
		var marches: int = 0
		var attacks: int = 0
		var reinforcements: int = 0
		var conquests: int = 0
		if turn > 0:
			for event in marcher.get_march_diagnostic_records():
				if String(event.get("event_type", "")) != "march_execution" or not bool(event.get("arrival_applied", false)):
					continue
				marches += 1
				var target_before: Dictionary = event.get("destination_before", {})
				var target_after: Dictionary = event.get("destination_after", {})
				var source_owner: Dictionary = event.get("source_owner", {})
				var is_attack: bool = String(target_before.get("type", "")) != String(source_owner.get("type", "")) or (String(source_owner.get("type", "")) == LevelConfig.PROVINCE_TYPE_ENEMY and int(target_before.get("faction_id", -1)) != int(source_owner.get("faction_id", -2)))
				if is_attack:
					attacks += 1
					if String(target_before.get("type", "")) != String(target_after.get("type", "")) or int(target_before.get("faction_id", -1)) != int(target_after.get("faction_id", -1)):
						conquests += 1
				else:
					reinforcements += 1
		cumulative_marches += marches
		cumulative_attacks += attacks
		cumulative_conquests += conquests
		var leader: String = String(tallies.get("leader", ""))
		var leader_count: int = int(tallies.get("leader_count", 0))
		if first_majority < 0 and leader_count * 2 > total:
			first_majority = turn
		if first_80 < 0 and leader_count * 5 >= total * 4:
			first_80 = turn
		if first_full < 0 and leader_count >= total:
			first_full = turn
		if leader.begins_with("boss_"):
			boss_ever_led = true
		var boss_provinces: int = int(tallies.get("boss_count", 0))
		boss_peak_provinces = maxi(boss_peak_provinces, boss_provinces)
		if turn >= boss_turn and boss_turn > 0 and not boss_entry.is_empty() and boss_provinces == 0 and boss_zero_territory_turn < 0:
			boss_zero_territory_turn = turn
		if turn > 0 and turn % 10 == 0:
			print("AUTOPLAY_CONTROL seed=", map_seed, " turn=", turn, " boss_provinces=", boss_provinces, " boss_alive=", boss.is_boss_active(), " owners=", JSON.stringify(owners))
		for key in owners:
			var count: int = int(owners[key])
			var troop_count: int = int(troop_totals.get(key, 0))
			peak_troops = maxi(peak_troops, troop_count)
			csv.append("%d,%d,%s,%d,%d,%d,%s,%.5f,%d,%d,%d,%d,%d,%d,%s,%d,%.5f,%s" % [
				map_seed, turn, String(key), count, troop_count, int(tallies.get("neutral_count", 0)),
				leader, float(leader_count) / float(maxi(1, total)),
				int(tallies.get("active_owners", 0)), marches, attacks, reinforcements,
				conquests, cumulative_revolts, str(boss.is_boss_active()), boss_provinces,
				float(boss_provinces) / float(maxi(1, total)), str(not boss_entry.is_empty())
			])
		if first_full >= 0:
			break
	var final_tally: Dictionary = _tally(main._province_persistence)
	var leader_final: String = String(final_tally.get("leader", ""))
	var summary: Dictionary = {
		"seed": map_seed, "provinces": total, "turns_simulated": main.turn_number,
		"first_majority_turn": first_majority, "first_80_percent_turn": first_80,
		"first_full_control_turn": first_full, "winner": leader_final if first_full >= 0 else "",
		"final_leader": leader_final,
		"final_leader_provinces": int(final_tally.get("leader_count", 0)),
		"final_ownership": final_tally.get("owners", {}),
		"boss_spawned": not boss_entry.is_empty(),
		"boss_alive_at_end": boss.is_boss_active(),
		"boss_ever_led": boss_ever_led,
		"boss_peak_provinces": boss_peak_provinces,
		"boss_zero_territory_turn": boss_zero_territory_turn,
		"boss_active_without_territory": boss.is_boss_active() and int(final_tally.get("boss_count", 0)) == 0,
		"boss_full_control": first_full >= 0 and leader_final.begins_with("boss_"),
		"ordinary_full_control": first_full >= 0 and not leader_final.begins_with("boss_"),
		"final_active_owners": int(final_tally.get("active_owners", 0)),
		"marches": cumulative_marches, "attacks": cumulative_attacks,
		"conquests": cumulative_conquests, "revolts": cumulative_revolts,
		"peak_faction_troops": peak_troops
	}
	main.provinces_root.free()
	main.free()
	return summary

func _polygon_center(poly: PackedVector2Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var center: Vector2 = Vector2.ZERO
	for p in poly:
		center += p
	return center / float(poly.size())
