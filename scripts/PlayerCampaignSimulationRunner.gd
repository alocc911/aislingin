extends SceneTree
# Headless balancing runner with one heuristic player shot per turn.
# Run:
# godot --headless --path . --script res://scripts/PlayerCampaignSimulationRunner.gd -- \
#   --seeds 20 --first-seed 71 --turns 120 --level 3 --profile average \
#   --mode easy --output-dir user://player-sim
# For consecutive levels: --level 1 --levels 10
const LevelConfig = preload("res://scripts/LevelConfig.gd")
const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const EnemyTurnSystemScript = preload("res://scripts/EnemyTurnSystem.gd")
const EngagementResolverScript = preload("res://scripts/EngagementResolver.gd")
const BossSystemScript = preload("res://scripts/BossSystem.gd")
const EconomyMetricsScript = preload("res://scripts/AutoplayEconomyMetrics.gd")
const SimulatedPlayerScript = preload("res://scripts/SimulatedPlayer.gd")

class SimMain extends Node:
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
	var level_index: int = 1
	var campaign_mode: String = "easy"
	var _current_phase: String = "grand_map"
	var _locked_province_id_after_win: int = -1
	var _construction_build_mode_enabled: bool = false
	var _arrival_locks: Dictionary = {}
	var initial_capital: int = -1
	var sim_upgrades: Dictionary = {"bigger": 0, "heavier": 0, "poison": 0, "forcefield": 0, "magnet": 0}
	var sim_discounts: Dictionary = {"bigger": 0, "heavier": 0, "poison": 0, "forcefield": 0, "magnet": 0}
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
	func _is_milestone(idx: int) -> bool:
		return idx % LevelConfig.MILESTONE_INTERVAL == 0
	func is_opening_gameplay_tutorial_active() -> bool:
		return false
	func get_campaign_current_level_progress() -> int:
		return level_index
	func get_campaign_level_mode() -> String:
		return campaign_mode
	func get_campaign_enemy_troop_increase_per_level() -> int:
		return LevelConfig.get_campaign_enemy_troop_increase_per_level()
	func get_campaign_boss_part_extra_hits_to_kill(part_name: String) -> int:
		var steps: int = maxi(0, level_index - 1) * LevelConfig.get_campaign_boss_progress_steps_for_mode(campaign_mode)
		return int(LevelConfig.build_campaign_boss_defensive_bonus_map(steps).get(part_name, 0))
	func get_campaign_boss_offense_bonus_value(bonus_key: String) -> int:
		var steps: int = maxi(0, level_index - 1) * LevelConfig.get_campaign_boss_progress_steps_for_mode(campaign_mode)
		return int(LevelConfig.build_campaign_boss_offensive_bonus_map(steps).get(bonus_key, 0))
	func get_player_capital_province_id() -> int:
		if initial_capital >= 0:
			for p in _province_persistence:
				if int(p.get("id", -1)) == initial_capital and String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
					return initial_capital
		for p in _province_persistence:
			if String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY and int(p.get("faction_id", 0)) == 0:
				return int(p.get("id", -1))
		return -1
	func is_province_troop_destination_locked(province_id: int) -> bool:
		return _arrival_locks.has(province_id)
	func mark_province_troop_destination_locked(province_id: int) -> void:
		_arrival_locks[province_id] = true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var opts: Dictionary = {
		"seeds": 3, "first_seed": 71, "turns": 120, "level": 3,
		"levels": 1, "mode": "easy", "profile": "average",
		"output_dir": "user://player-sim"
	}
	for i in range(args.size() - 1):
		var key: String = String(args[i]).trim_prefix("--").replace("-", "_")
		if opts.has(key):
			opts[key] = String(args[i + 1])
	var seeds_count: int = clampi(int(opts["seeds"]), 1, 1000)
	var first_seed: int = int(opts["first_seed"])
	var max_turns: int = clampi(int(opts["turns"]), 1, 2000)
	var first_level: int = clampi(int(opts["level"]), 1, LevelConfig.get_campaign_total_levels())
	var level_count: int = clampi(int(opts["levels"]), 1, LevelConfig.get_campaign_total_levels())
	var mode: String = LevelConfig.normalize_campaign_level_mode(String(opts["mode"]))
	var profile: String = String(opts["profile"]).to_lower()
	if not ["casual", "average", "skilled"].has(profile):
		printerr("PLAYER_SIM_ERROR unknown profile ", profile)
		quit(2)
		return
	var output_dir: String = String(opts["output_dir"])
	var absolute_dir: String = ProjectSettings.globalize_path(output_dir) if output_dir.begins_with("user://") else output_dir
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		printerr("PLAYER_SIM_ERROR cannot create output ", absolute_dir)
		quit(2)
		return
	var runs: Array[Dictionary] = []
	var shots_csv: Array[String] = ["seed,level,turn,province,defenders,downed,fully_cleared,conquered,won,difficulty,full_clear_chance,boss_killed"]
	var turns_csv: Array[String] = ["seed,level,turn,player_provinces,player_share,enemy_provinces,neutral_provinces,rebel_provinces,active_bosses,gold,shots,troop_orders,shot_conquests,troop_conquests,revolts,win,home_cave_tier"]
	var ownership_csv: Array[String] = ["seed,turn,province_id,previous_owner,new_owner,cause,previous_holding_turns,native_happiness_before_revolt,outlander_happiness_before_revolt"]
	var provinces_csv: Array[String] = ["seed,turn,province_id,owner,natives,outlanders,native_happiness,outlander_happiness,food_production,food_demand,food_surplus,native_housing_capacity,outlander_housing_capacity,income,recruitment,construction_rate,active_project,native_migration_in,outlander_migration_in,native_migration_out,outlander_migration_out,troops,buildings,food_shortage,overcrowded"]
	var economy_csv: Array[String] = ["seed,turn,active_factions,neutral_provinces,rebel_provinces,total_population,natives,outlanders,mean_happiness,food_production,food_demand,total_income,native_migrants,outlander_migrants,food_shortage_provinces,overcrowded_provinces,troops,buildings,player_treasury,revolutions_this_turn,march_conquests_this_turn"]
	var campaigns: Array[Dictionary] = []
	var step: int = LevelConfig.get_campaign_step_advance_for_mode(mode)
	for index in range(seeds_count):
		var seed_value: int = first_seed + index * 101
		var discounts: Dictionary = {"bigger": 0, "heavier": 0, "poison": 0, "forcefield": 0, "magnet": 0}
		var campaign_runs: Array[Dictionary] = []
		var completed: bool = true
		for stage in range(level_count):
			var level: int = first_level + stage * step
			if level > LevelConfig.get_campaign_total_levels():
				break
			var map_seed: int = seed_value + level * 1000003
			var result: Dictionary = _run_level(map_seed, level, mode, profile, max_turns, discounts, shots_csv, turns_csv, ownership_csv, provinces_csv, economy_csv)
			result["campaign_seed"] = seed_value
			runs.append(result)
			campaign_runs.append(result)
			print("PLAYER_SIM_LEVEL ", JSON.stringify({"seed": seed_value, "level": level, "win": result.get("win", false), "turn": result.get("turns", 0), "shots": result.get("shots", 0)}))
			if not bool(result.get("win", false)):
				completed = false
				break
			_award_campaign_discounts(discounts, level, mode)
		campaigns.append({"seed": seed_value, "completed": completed, "levels_won": campaign_runs.size() if completed else maxi(0, campaign_runs.size() - 1), "discounts": discounts.duplicate(true)})
	var wins: int = 0
	var total_shots: int = 0
	var total_clears: int = 0
	var total_misses: int = 0
	var total_orders: int = 0
	var total_revolts: int = 0
	var total_conquests: int = 0
	var sum_turns_won: int = 0
	for run in runs:
		if bool(run.get("win", false)):
			wins += 1
			sum_turns_won += int(run.get("turns", 0))
		total_shots += int(run.get("shots", 0))
		total_clears += int(run.get("full_clears", 0))
		total_misses += int(run.get("misses", 0))
		total_orders += int(run.get("troop_orders", 0))
		total_revolts += int(run.get("revolts", 0))
		total_conquests += int(run.get("shot_conquests", 0)) + int(run.get("troop_conquests", 0))
	var report: Dictionary = {
		"engine": "real_generated_grand_map_and_live_ai_economy_boss_combat",
		"shot_model": "layout_informed_two_stage_full_clear_or_partial",
		"source_commit": OS.get_environment("GITHUB_SHA"),
		"settings": {"seeds": seeds_count, "first_seed": first_seed, "turns_per_level": max_turns, "level": first_level, "levels": level_count, "mode": mode, "profile": profile},
		"aggregate": {
			"levels_attempted": runs.size(), "levels_won": wins,
			"level_win_rate": float(wins) / float(maxi(1, runs.size())),
			"mean_turns_to_win": float(sum_turns_won) / float(maxi(1, wins)),
			"shots": total_shots, "full_clears": total_clears,
			"full_clear_rate": float(total_clears) / float(maxi(1, total_shots)),
			"miss_rate": float(total_misses) / float(maxi(1, total_shots)),
			"troop_orders": total_orders, "player_conquests": total_conquests,
			"revolts": total_revolts
		},
		"campaigns": campaigns,
		"runs": runs,
		"limitations": [
			"No ball physics; shot full-clear and partial-loss probabilities are uncalibrated and should be fitted to player observations.",
			"Engagement layouts are computed from deterministic pin/obstacle definitions, without instantiating scene nodes.",
			"One shot per player turn; heuristic targets and any number of legal troop orders, including proactive frontline reinforcement. Purchases remain limited by player skill and treasury.",
			"Simulated player actively requests Home Cave build/upgrade at its capital (up to tier 3), paying normal project costs and waiting for construction.",
			"Construction uses the normal ProvinceSystem automatic recommended queue; no manual player queue micromanagement.",
			"Bosses are spawned with the configured count and production BossSystem HP/limb combat, but live cinematic transitions and some friendly-boss assistance interactions are omitted.",
			"No opening tutorial, visual ball launches, between-level UI or interactive upgrade selection."
		]
	}
	if not _write_file(absolute_dir.path_join("player_sim_summary.json"), JSON.stringify(report, "\t")):
		quit(3)
		return
	_write_file(absolute_dir.path_join("player_sim_shots.csv"), "\n".join(shots_csv) + "\n")
	_write_file(absolute_dir.path_join("player_sim_turns.csv"), "\n".join(turns_csv) + "\n")
	_write_file(absolute_dir.path_join("player_sim_ownership.csv"), "\n".join(ownership_csv) + "\n")
	_write_file(absolute_dir.path_join("player_sim_provinces.csv"), "\n".join(provinces_csv) + "\n")
	_write_file(absolute_dir.path_join("player_sim_economy.csv"), "\n".join(economy_csv) + "\n")
	_write_file(absolute_dir.path_join("player_sim_balance_report.md"), _markdown_report(report))
	print("PLAYER_SIM_COMPLETE ", JSON.stringify(report.get("aggregate", {})))
	quit(0)

func _write_file(path: String, content: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("PLAYER_SIM_ERROR write failed ", path)
		return false
	file.store_string(content)
	file.close()
	return true

func _make_map(main: SimMain, seed_value: int, level: int, rng: RandomNumberGenerator) -> void:
	var generator = LevelGeneratorScript.new()
	var generated: Dictionary = generator._generate_template_grand_map_data(LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS, rng, seed_value, level)
	for item in generated.get("provinces", []):
		var raw: Dictionary = item
		var polygon: PackedVector2Array = raw.get("polygon", PackedVector2Array())
		var center: Vector2 = Vector2.ZERO
		for corner in polygon:
			center += corner
		if not polygon.is_empty():
			center /= float(polygon.size())
		var p: Dictionary = {
			"id": int(raw.get("id", -1)),
			"province_name": String(raw.get("province_name", "")),
			"type": String(raw.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			"faction_id": int(raw.get("faction_id", 0)),
			"remaining_troops": int(raw.get("troops", 0)),
			"remaining_buildings": int(raw.get("buildings", 0)),
			"building_capacity": int(raw.get("building_capacity", 8)),
			"neighbors": raw.get("neighbors", []).duplicate(),
			"is_target": bool(raw.get("is_target", false)),
			"is_boss_home": false,
			"center": center,
			"invading_troops": 0
		}
		main.province_system.normalize_province_economy_state(p)
		main._province_persistence.append(p)
		if main.initial_capital < 0 and String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			main.initial_capital = int(p.get("id", -1))

func _is_allied(main: SimMain, p: Dictionary) -> bool:
	if String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return true
	return String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_ENEMY and main.boss_system.is_friendly_boss_faction_id(int(p.get("faction_id", 0)))

func _control(main: SimMain) -> Dictionary:
	var total: int = main._province_persistence.size()
	var player: int = 0
	var enemies: int = 0
	var neutral: int = 0
	var rebels: int = 0
	var valid_victory_remainder: bool = true
	for p in main._province_persistence:
		if _is_allied(main, p):
			player += 1
		elif String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_ENEMY and int(p.get("faction_id", -1)) == ProvinceSystemScript.REBEL_FACTION_ID:
			rebels += 1
		else:
			valid_victory_remainder = false
			if String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_NEUTRAL:
				neutral += 1
			else:
				enemies += 1
	var win: bool = total > 0 and (player == total or (player > 0 and rebels > 0 and player * 5 >= total * 4 and valid_victory_remainder))
	return {
		"total": total, "player": player, "enemies": enemies,
		"neutral": neutral, "rebels": rebels, "win": win,
		"share": float(player) / float(maxi(1, total))
	}

func _pick_contiguous(main: SimMain, home_id: int, excluded: Array[int], rng: RandomNumberGenerator, desired: int) -> Array[int]:
	var chosen: Array[int] = []
	var connected: Array[int] = [home_id]
	while chosen.size() < desired:
		var choices: Array[int] = []
		for from_id in connected:
			var idx: int = main.province_system.find_persistence_index_by_id(from_id)
			if idx < 0:
				continue
			for neighbor_any in main._province_persistence[idx].get("neighbors", []):
				var id: int = int(neighbor_any)
				if excluded.has(id) or connected.has(id) or choices.has(id):
					continue
				var other: int = main.province_system.find_persistence_index_by_id(id)
				if other < 0 or bool(main._province_persistence[other].get("is_target", false)):
					continue
				choices.append(id)
		if choices.is_empty():
			break
		var next_id: int = choices[rng.randi_range(0, choices.size() - 1)]
		chosen.append(next_id)
		connected.append(next_id)
		excluded.append(next_id)
	return chosen

func _spawn_bosses(main: SimMain, rng: RandomNumberGenerator, mode: String, level: int) -> int:
	var candidates: Array[Dictionary] = []
	for p in main._province_persistence:
		candidates.append({"id": int(p.get("id", -1)), "type": String(p.get("type", "")), "is_target": bool(p.get("is_target", false)), "center": p.get("center", Vector2.ZERO)})
	var protected: int = main.get_player_capital_province_id()
	var blocked: Array[int] = []
	if protected >= 0:
		blocked.append(protected)
	var count: int = LevelConfig.get_campaign_boss_count_for_mode(mode, level)
	var homes: Array[int] = main.boss_system.choose_multiple_boss_home_province_ids(candidates, blocked, count, rng)
	if homes.is_empty():
		return 0
	for h in homes:
		blocked.append(h)
	var entries: Array[Dictionary] = []
	for i in range(homes.size()):
		var home: int = int(homes[i])
		var friendly: bool = LevelConfig.is_campaign_final_level(level) and i == homes.size() - 1
		var satellites: Array[int] = []
		if friendly:
			satellites = main.boss_system.choose_initial_boss_faction_province_ids(candidates, blocked, rng, 2)
			for sat in satellites:
				blocked.append(sat)
		else:
			satellites = _pick_contiguous(main, home, blocked, rng, 2)
		var faction: int = main.boss_system.get_friendly_boss_faction_id() if friendly else main.boss_system.get_default_boss_faction_id_for_index(i)
		entries.append({
			"home_province_id": home, "conquered_province_ids": satellites,
			"boss_faction_id": faction, "boss_faction_name": "Sim Boss %d" % i,
			"is_friendly_boss": friendly
		})
	var activated: Dictionary = main.boss_system.activate_multiple_bosses(entries)
	if int(activated.get("boss_count", 0)) <= 0:
		return 0
	for entry in entries:
		var home_id: int = int(entry["home_province_id"])
		var faction_id: int = int(entry["boss_faction_id"])
		var friendly: bool = bool(entry["is_friendly_boss"])
		var owned_type: String = LevelConfig.PROVINCE_TYPE_FRIENDLY if friendly else LevelConfig.PROVINCE_TYPE_ENEMY
		var index: int = main.province_system.find_persistence_index_by_id(home_id)
		if index < 0:
			continue
		var home_p: Dictionary = main._province_persistence[index]
		var inherited: int = maxi(0, int(home_p.get("remaining_troops", 0)))
		main.province_system.reset_construction_on_owner_change(home_p, String(home_p.get("type", "")), owned_type)
		home_p["type"] = owned_type
		home_p["faction_id"] = faction_id
		home_p["is_boss_home"] = true
		home_p["is_friendly_boss_province"] = friendly
		home_p["remaining_buildings"] = 0
		home_p["remaining_troops"] = main.boss_system.get_boss_home_troop_count_for_home_province_id(home_id)
		home_p["invading_troops"] = 0
		var satellites: Array = entry["conquered_province_ids"]
		for s in range(satellites.size()):
			var sid: int = int(satellites[s])
			var si: int = main.province_system.find_persistence_index_by_id(sid)
			if si < 0:
				continue
			var satellite: Dictionary = main._province_persistence[si]
			main.province_system.reset_construction_on_owner_change(satellite, String(satellite.get("type", "")), owned_type)
			satellite["type"] = owned_type
			satellite["faction_id"] = faction_id
			satellite["is_boss_home"] = false
			satellite["is_friendly_boss_province"] = friendly
			satellite["remaining_troops"] = int(satellite.get("remaining_troops", 0)) + LevelConfig.get_campaign_enemy_troop_increase_per_level() + int(inherited / maxi(1, satellites.size())) + (1 if s < inherited % maxi(1, satellites.size()) else 0)
			satellite["invading_troops"] = 0
			main.province_system.ensure_minimum_conquest_farm(satellite)
		main.province_system.normalize_province_economy_state(home_p)
	return entries.size()

func _run_level(map_seed: int, level: int, mode: String, profile: String, max_turns: int, discounts: Dictionary, shots_csv: Array[String], turns_csv: Array[String], ownership_csv: Array[String], provinces_csv: Array[String], economy_csv: Array[String]) -> Dictionary:
	LevelConfig.set_runtime_campaign_level_progress(level)
	seed(map_seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	var main := SimMain.new()
	main.map_seed = map_seed
	main.level_index = level
	main.campaign_mode = mode
	main.sim_discounts = discounts.duplicate(true)
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
	_make_map(main, map_seed, level, rng)
	var player = SimulatedPlayerScript.new()
	player.configure(profile, level, map_seed * 9176 + 97)
	var metrics = EconomyMetricsScript.new()
	metrics.initialize(map_seed, main._province_persistence)
	metrics.record_turn(main._province_persistence, 0, main.gold_balance, 0, 0)
	var boss_spawned: bool = false
	var boss_count: int = 0
	var revolts: int = 0
	var autonomous_conquests: int = 0
	var end_reason: String = "turn_limit"
	var winning_turn: int = -1
	var boss_turn: int = LevelConfig.get_boss_show_up_turn_for_level(level)
	var turn: int = 1
	while turn <= max_turns:
		main.turn_number = turn
		main._arrival_locks.clear()
		if not boss_spawned and turn >= boss_turn:
			boss_count = _spawn_bosses(main, rng, mode, level)
			boss_spawned = boss_count > 0
			if boss_spawned:
				metrics.track_ownership(main._province_persistence, turn, "boss_spawn")
		if turn % 25 == 0:
			print("PLAYER_SIM_PROGRESS seed=", map_seed, " level=", level, " turn=", turn)
		# Live Main resets all purchased ball upgrades to their permanent
		# baseline and credits income at the start of each player turn.
		for kind in main.sim_upgrades.keys():
			main.sim_upgrades[kind] = 0
		for province in main._province_persistence:
			if String(province.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY and int(province.get("faction_id", 0)) == 0:
				main.gold_balance += ps.get_province_total_income(province)
		player.manage_home_cave(main)
		player.purchase_upgrade(main)
		player.issue_troop_orders(main)
		metrics.track_ownership(main._province_persistence, turn, "player_troop_order")
		var shot: Dictionary = player.take_shot(main)
		metrics.track_ownership(main._province_persistence, turn, "player_shot")
		if bool(shot.get("shot", false)):
			shots_csv.append("%d,%d,%d,%d,%d,%d,%s,%s,%s,%.5f,%.5f,%s" % [
				map_seed, level, turn, int(shot.get("target_id", -1)),
				int(shot.get("enemies", 0)), int(shot.get("downed", 0)),
				str(bool(shot.get("full_clear", false))), str(bool(shot.get("conquered", false))),
				str(bool(shot.get("won", false))), float(shot.get("difficulty", 0.0)),
				float(shot.get("full_clear_chance", 0.0)), str(bool(shot.get("boss_killed", false)))
			])
		var control: Dictionary = _control(main)
		if bool(control.get("win", false)):
			end_reason = "victory"
			winning_turn = turn
		elif int(control.get("player", 0)) <= 0:
			end_reason = "eliminated"
		var enemy_turns: int = int(shot.get("enemy_turns", 1))
		if end_reason == "turn_limit":
			for enemy_step in range(enemy_turns):
				if turn > max_turns:
					break
				main.turn_number = turn
				# A failed shot incurs an extra automatic turn; income still
				# accrues during that second turn even without a player action.
				if enemy_step > 0:
					for p in main._province_persistence:
						if String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY and int(p.get("faction_id", 0)) == 0:
							main.gold_balance += ps.get_province_total_income(p)
				marcher.clear_march_diagnostic_records()
				marcher._run_single_automated_cycle(true)
				metrics.track_ownership(main._province_persistence, turn, "automated_action")
				var automated_this_turn: int = 0
				for event in marcher.get_march_diagnostic_records():
					if String(event.get("event_type", "")) == "march_execution" and bool(event.get("arrival_applied", false)):
						var before: Dictionary = event.get("destination_before", {})
						var after: Dictionary = event.get("destination_after", {})
						if String(before.get("type", "")) != String(after.get("type", "")) or int(before.get("faction_id", -1)) != int(after.get("faction_id", -1)):
							automated_this_turn += 1
				autonomous_conquests += automated_this_turn
				var economy_results: Array[Dictionary] = ps.tick_all_province_economies(-1)
				player.observe_home_cave(main)
				var revolted_ids: Array[int] = []
				for event in economy_results:
					if bool(event.get("revolted", false)):
						revolts += 1
						revolted_ids.append(int(event.get("province_id", -1)))
				metrics.track_ownership(main._province_persistence, turn, "economy", revolted_ids)
				metrics.record_turn(main._province_persistence, turn, main.gold_balance, revolted_ids.size(), automated_this_turn)
				control = _control(main)
				turns_csv.append("%d,%d,%d,%d,%.5f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%d" % [
					map_seed, level, turn, int(control.get("player", 0)),
					float(control.get("share", 0.0)), int(control.get("enemies", 0)),
					int(control.get("neutral", 0)), int(control.get("rebels", 0)),
					boss.get_active_boss_count(), main.gold_balance,
					int(player.stats.get("shots", 0)), int(player.stats.get("troop_orders", 0)),
					int(player.stats.get("shot_conquests", 0)), int(player.stats.get("troop_conquests", 0)),
					revolts, str(bool(control.get("win", false))),
					int(player.stats.get("peak_home_cave_tier", 0))
				])
				if bool(control.get("win", false)):
					end_reason = "victory"
					winning_turn = turn
				elif int(control.get("player", 0)) <= 0:
					end_reason = "eliminated"
				turn += 1
				if end_reason != "turn_limit":
					break
		if end_reason != "turn_limit":
			break
	if end_reason == "turn_limit" and not boss_spawned and max_turns >= boss_turn:
		end_reason = "boss_spawn_failed"
	player.observe_home_cave(main)
	var final_control: Dictionary = _control(main)
	var summary: Dictionary = {
		"seed": map_seed, "level": level, "profile": profile, "mode": mode,
		"turns": winning_turn if winning_turn >= 0 else mini(turn, max_turns),
		"end_reason": end_reason, "win": bool(final_control.get("win", false)),
		"total_provinces": int(final_control.get("total", 0)),
		"final_player_provinces": int(final_control.get("player", 0)),
		"final_player_share": float(final_control.get("share", 0.0)),
		"final_enemy_provinces": int(final_control.get("enemies", 0)),
		"final_neutral_provinces": int(final_control.get("neutral", 0)),
		"final_rebel_provinces": int(final_control.get("rebels", 0)),
		"boss_spawned": boss_spawned, "boss_count": boss_count,
		"boss_active_at_end": boss.get_active_boss_count(),
		"revolts": revolts, "automated_conquests": autonomous_conquests,
		"ending_gold": main.gold_balance, "ending_upgrades": main.sim_upgrades.duplicate(true)
	}
	summary.merge(player.stats, true)
	var shots: int = int(player.stats.get("shots", 0))
	summary["mean_shot_difficulty"] = float(player.stats.get("total_shot_difficulty", 0.0)) / float(maxi(1, shots))
	summary["mean_full_clear_chance"] = float(player.stats.get("total_full_clear_chance", 0.0)) / float(maxi(1, shots))
	summary.merge(metrics.summarize(main._province_persistence, mini(turn, max_turns)), true)
	ownership_csv.append_array(metrics.ownership_rows)
	provinces_csv.append_array(metrics.province_rows)
	economy_csv.append_array(metrics.map_rows)
	main.provinces_root.free()
	main.free()
	return summary

func _award_campaign_discounts(discounts: Dictionary, level: int, mode: String) -> void:
	var count: int = LevelConfig.get_campaign_reward_points_for_mode(mode)
	var order: Array[String] = ["forcefield", "bigger", "heavier", "poison", "magnet"]
	for _i in range(count):
		for kind in order:
			var next_level: int = mini(LevelConfig.get_campaign_total_levels(), level + LevelConfig.get_campaign_step_advance_for_mode(mode))
			var price: int = LevelConfig.get_upgrade_cost_for_level(kind, next_level)
			if int(discounts.get(kind, 0)) < maxi(0, price - 1):
				discounts[kind] = int(discounts.get(kind, 0)) + 1
				break

func _markdown_report(report: Dictionary) -> String:
	var agg: Dictionary = report.get("aggregate", {})
	var options: Dictionary = report.get("settings", {})
	var lines: Array[String] = [
		"# Simulated-player balance report", "",
		"Profile: %s; mode: %s; seed count: %d; per-level turn limit: %d." % [String(options.get("profile", "")), String(options.get("mode", "")), int(options.get("seeds", 0)), int(options.get("turns_per_level", 0))],
		"",
		"## Aggregate", "",
		"- Level win rate: %.1f%% (%d/%d)" % [100.0 * float(agg.get("level_win_rate", 0.0)), int(agg.get("levels_won", 0)), int(agg.get("levels_attempted", 0))],
		"- Mean turns to win (wins only): %.1f" % float(agg.get("mean_turns_to_win", 0.0)),
		"- Full-clear rate: %.1f%%" % [100.0 * float(agg.get("full_clear_rate", 0.0))],
		"- Zero-knockdown rate: %.1f%%" % [100.0 * float(agg.get("miss_rate", 0.0))],
		"- Total troop orders: %d" % int(agg.get("troop_orders", 0)),
		"- Total player conquests: %d" % int(agg.get("player_conquests", 0)),
		"- Total revolts: %d" % int(agg.get("revolts", 0)),
		"",
		"## Individual levels", "",
		"| Seed | Level | Won | Turns | Player share | Shots | Full clears | Troop orders | Boss kills | Revolts |",
		"|---:|---:|:---:|---:|---:|---:|---:|---:|---:|---:|"
	]
	for run in report.get("runs", []):
		lines.append("| %d | %d | %s | %d | %.1f%% | %d | %d | %d | %d | %d |" % [
			int(run.get("campaign_seed", 0)), int(run.get("level", 0)),
			"Yes" if bool(run.get("win", false)) else "No",
			int(run.get("turns", 0)), 100.0 * float(run.get("final_player_share", 0.0)),
			int(run.get("shots", 0)), int(run.get("full_clears", 0)),
			int(run.get("troop_orders", 0)), int(run.get("boss_kills", 0)),
			int(run.get("revolts", 0))
		])
	lines.append("")
	lines.append("Results depend on assumed shot probabilities, not calibrated human accuracy. For shots and individual turns see player_sim_shots.csv and player_sim_turns.csv. Economy and ownership details are exported separately.")
	return "\n".join(lines) + "\n"
