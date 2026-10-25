extends SceneTree

const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const LevelConfig = preload("res://scripts/LevelConfig.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const EngagementResolverScript = preload("res://scripts/EngagementResolver.gd")
const EnemyTurnSystemScript = preload("res://scripts/EnemyTurnSystem.gd")

class MockMain extends Node:
	var _province_persistence: Array[Dictionary] = []
	var province_system = null
	var boss_system = null
	var gold_balance: int = 0
	var level_index: int = 1
	var map_seed: int = 1
	const INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT: int = 3
	func get_friendly_march_threshold() -> int:
		return 20
	func get_enemy_march_threshold() -> int:
		return 15
	func _is_milestone(_idx: int) -> bool:
		return false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	_test_conquest(failures)
	_test_geography(failures)
	_test_friendly_long_distance_routing(failures)
	_test_enemy_unlimited_full_force_marching(failures)
	_test_friendly_full_force_marching(failures)
	_test_garrison_reserves(failures)
	var report: Dictionary = {"ok": failures.is_empty(), "failures": failures}
	print("CONQUEST_AND_GEOGRAPHY_TEST: ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func _test_conquest(failures: Array[String]) -> void:
	var main := MockMain.new()
	var ps = ProvinceSystemScript.new()
	main.province_system = ps
	ps.setup(main)
	var resolver = EngagementResolverScript.new()
	resolver.setup(main)

	for percentage in [0, 25, 50, 75, 100]:
		var knocked: int = int(20 * percentage / 100)
		var expected_destroyed: int = roundi(float(10 * percentage) / 100.0)
		var actual: int = EngagementResolverScript.calculate_proportional_building_losses(20, knocked, 10)
		if actual != expected_destroyed:
			failures.append("proportional_%d_percent_expected_%d_got_%d" % [percentage, expected_destroyed, actual])

	for knocked in [0, 5, 10, 15, 20]:
		var state: Dictionary = {
			"id": 33, "type": LevelConfig.PROVINCE_TYPE_ENEMY, "faction_id": 3,
			"remaining_troops": 20, "remaining_buildings": 10,
			"building_capacity": 16, "neighbors": [], "is_boss_home": false
		}
		main._province_persistence = [state]
		var result: Dictionary = resolver.resolve_engagement({
			"player_participating": true, "troops_A": 0, "troops_B": 20,
			"buildings_A": 0, "buildings_B": 10,
			"player_downed_troops": knocked,
			"player_destroyed_buildings": 0,
			"province_id": 33
		})
		var damage: int = EngagementResolverScript.calculate_proportional_building_losses(20, knocked, 10)
		if knocked < 20:
			if int(result.get("final_buildings_B", -1)) != 10 - damage:
				failures.append("partial_assault_buildings_%d" % knocked)
			if String(result.get("province_type_after", "")) != LevelConfig.PROVINCE_TYPE_ENEMY:
				failures.append("partial_assault_changed_owner_%d" % knocked)
		else:
			if not bool(result.get("conquered", false)):
				failures.append("full_assault_did_not_conquer")
			if String(result.get("province_type_after", "")) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
				failures.append("full_assault_not_friendly")
			if int(result.get("final_buildings_B", -1)) != 0:
				failures.append("full_assault_buildings_not_destroyed")
		if knocked == 10 and not bool(result.get("won", false)):
			failures.append("half_troops_did_not_win")
		if knocked == 10 and bool(result.get("conquered", false)):
			failures.append("half_troops_conquered")
	main._province_persistence = [{
		"id": 33, "type": LevelConfig.PROVINCE_TYPE_ENEMY, "faction_id": 3,
		"remaining_troops": 20, "remaining_buildings": 10,
		"building_capacity": 16, "neighbors": [], "is_boss_home": true
	}]
	var boss_result: Dictionary = resolver.resolve_engagement({
		"player_participating": true, "troops_A": 0, "troops_B": 20,
		"buildings_A": 0, "buildings_B": 10,
		"player_downed_troops": 20, "player_destroyed_buildings": 0, "province_id": 33
	})
	if bool(boss_result.get("conquered", false)) or String(boss_result.get("province_type_after", "")) != LevelConfig.PROVINCE_TYPE_ENEMY:
		failures.append("boss_home_captured_without_boss_defeat")
	main._province_persistence = [{
		"id": 33, "type": LevelConfig.PROVINCE_TYPE_NEUTRAL, "faction_id": 0,
		"remaining_troops": 0, "remaining_buildings": 4, "building_capacity": 16,
		"neighbors": [], "is_boss_home": false
	}]
	var empty_result: Dictionary = resolver.resolve_engagement({
		"player_participating": true, "troops_A": 0, "troops_B": 0,
		"buildings_A": 0, "buildings_B": 4,
		"player_downed_troops": 0, "player_destroyed_buildings": 0, "province_id": 33
	})
	if not bool(empty_result.get("conquered", false)) or int(empty_result.get("final_buildings_B", -1)) != 0:
		failures.append("unguarded_province_not_conquered")
	main.free()

func _test_friendly_long_distance_routing(failures: Array[String]) -> void:
	# A large-map peninsula corridor: an eligible friendly source is twelve
	# border crossings from the last neutral province. The old five-hop
	# candidate search could select a local reinforcement instead.
	var main := MockMain.new()
	var ps = ProvinceSystemScript.new()
	main.province_system = ps
	ps.setup(main)
	var marcher = EnemyTurnSystemScript.new()
	marcher.setup(main)
	var states: Array[Dictionary] = []
	for province_id in range(13):
		var neighbors: Array[int] = []
		if province_id > 0:
			neighbors.append(province_id - 1)
		if province_id < 12:
			neighbors.append(province_id + 1)
		states.append({
			"id": province_id,
			"type": LevelConfig.PROVINCE_TYPE_NEUTRAL if province_id == 12 else LevelConfig.PROVINCE_TYPE_FRIENDLY,
			"faction_id": 0,
			"remaining_troops": 6 if province_id == 12 else (65 if province_id == 0 else 8),
			"remaining_buildings": 0,
			"neighbors": neighbors
		})
	main._province_persistence = states
	var snapshot: Dictionary = ps.make_province_snapshot_by_id()
	var candidates: Array[Dictionary] = marcher._collect_march_candidates(0, snapshot, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0)
	if candidates.is_empty():
		failures.append("friendly_corridor_no_candidates")
	else:
		var attack: Dictionary = candidates[0]
		var path: Array = attack.get("path", [])
		if int(attack.get("destination_id", -1)) != 12 or path.size() != 13:
			failures.append("friendly_corridor_not_nearest_distant_target")
	var source: Dictionary = snapshot.get(0, {})
	var attack_plan: Dictionary = marcher._choose_best_march_plan(0, snapshot, source, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 60, 5, 65)
	if int(attack_plan.get("destination_id", -1)) != 12:
		failures.append("friendly_corridor_did_not_attack_distant_target")

	# Retain the original no-suicide attack scoring: if the nearest target
	# cannot be attacked effectively, reinforce the friendly province directly
	# beside it rather than selecting an unrelated reinforcement or stalling.
	states[12]["remaining_troops"] = 100
	states[12]["remaining_buildings"] = 10
	snapshot = ps.make_province_snapshot_by_id()
	source = snapshot.get(0, {})
	var staging_plan: Dictionary = marcher._choose_best_march_plan(0, snapshot, source, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 21, 5, 26)
	if int(staging_plan.get("destination_id", -1)) != 11:
		failures.append("friendly_corridor_no_nearest_frontline_reinforcement")

	# A nearer hostile province must take precedence over a distant easier one.
	states[12]["remaining_troops"] = 0
	states[12]["remaining_buildings"] = 0
	states.append({
		"id": 13, "type": LevelConfig.PROVINCE_TYPE_NEUTRAL, "faction_id": 0,
		"remaining_troops": 90, "remaining_buildings": 10, "neighbors": [2]
	})
	(states[2]["neighbors"] as Array).append(13)
	main._province_persistence = states
	snapshot = ps.make_province_snapshot_by_id()
	candidates = marcher._collect_march_candidates(0, snapshot, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0)
	if candidates.is_empty() or int(candidates[0].get("destination_id", -1)) != 13:
		failures.append("friendly_did_not_prefer_nearest_hostile")
	main.free()



func _test_enemy_unlimited_full_force_marching(failures: Array[String]) -> void:
	# An interior enemy army must find targets through more than five provinces.
	# Once it commits, even an easy target receives the entire mobile army.
	var main := MockMain.new()
	var ps = ProvinceSystemScript.new()
	main.province_system = ps
	ps.setup(main)
	var marcher = EnemyTurnSystemScript.new()
	marcher.setup(main)
	var states: Array[Dictionary] = []
	for province_id in range(15):
		var neighbors: Array[int] = []
		if province_id > 0:
			neighbors.append(province_id - 1)
		if province_id < 14:
			neighbors.append(province_id + 1)
		states.append({
			"id": province_id,
			"type": LevelConfig.PROVINCE_TYPE_FRIENDLY if province_id == 14 else LevelConfig.PROVINCE_TYPE_ENEMY,
			"faction_id": 0 if province_id == 14 else 2,
			"remaining_troops": 8 if province_id != 0 else 500,
			"remaining_buildings": 3,
			"neighbors": neighbors
		})
	main._province_persistence = states
	var snapshot: Dictionary = ps.make_province_snapshot_by_id()
	var candidates: Array[Dictionary] = marcher._collect_march_candidates(0, snapshot, LevelConfig.PROVINCE_TYPE_ENEMY, 2)
	var found_distant_attack: bool = false
	var found_distant_reinforcement: bool = false
	for candidate in candidates:
		var destination: int = int(candidate.get("destination_id", -1))
		var path: Array = candidate.get("path", [])
		if destination == 14 and String(candidate.get("candidate_type", "")) == "attack" and path.size() == 15:
			found_distant_attack = true
		if destination == 13 and String(candidate.get("candidate_type", "")) == "reinforce" and path.size() == 14:
			found_distant_reinforcement = true
	if not found_distant_attack:
		failures.append("enemy_14_hop_attack_candidate_missing")
	if not found_distant_reinforcement:
		failures.append("enemy_13_hop_reinforcement_candidate_missing")
	var source: Dictionary = snapshot.get(0, {})
	var plan: Dictionary = marcher._choose_best_march_plan(0, snapshot, source, LevelConfig.PROVINCE_TYPE_ENEMY, 2, 495, 5, 500)
	if int(plan.get("destination_id", -1)) != 14 or int(plan.get("moving_troops", 0)) != 495:
		failures.append("enemy_distant_conquest_did_not_send_entire_mobile_army")
	if bool(plan.get("reserve_relaxed_for_decisive_conquest", false)):
		failures.append("enemy_distant_conquest_relaxed_reserve")
	# On an unwinnable attack, use the same full-force rule when staging at
	# the last allied province, even if that province already has 18+ troops.
	states[14]["remaining_troops"] = 1200
	states[13]["remaining_troops"] = 30
	snapshot = ps.make_province_snapshot_by_id()
	source = snapshot.get(0, {})
	plan = marcher._choose_best_march_plan(0, snapshot, source, LevelConfig.PROVINCE_TYPE_ENEMY, 2, 495, 5, 500)
	if int(plan.get("destination_id", -1)) != 13 or int(plan.get("moving_troops", 0)) != 495:
		failures.append("enemy_distant_reinforcement_not_full_force")
	# The defensive reserve remains binding, even if conquest would otherwise
	# be attractive; a very strong neighbor can justify holding all troops.
	var border: Dictionary = {
		"id": 60, "type": LevelConfig.PROVINCE_TYPE_ENEMY, "faction_id": 2,
		"remaining_troops": 500, "remaining_buildings": 2, "neighbors": [61]
	}
	var threat: Dictionary = {
		"id": 61, "type": LevelConfig.PROVINCE_TYPE_FRIENDLY, "faction_id": 0,
		"remaining_troops": 1200, "remaining_buildings": 2, "neighbors": [60]
	}
	var threatened_snapshot: Dictionary = {60: border, 61: threat}
	var reserve: int = marcher._get_local_defense_need(60, border, threatened_snapshot, LevelConfig.PROVINCE_TYPE_ENEMY, 2, 5)
	if reserve != 500:
		failures.append("strong_threat_did_not_preserve_garrison_reserve")
	var cannot_leave: Dictionary = marcher._choose_best_march_plan(60, threatened_snapshot, border, LevelConfig.PROVINCE_TYPE_ENEMY, 2, 0, reserve, 500)
	if not cannot_leave.is_empty():
		failures.append("conquest_bypassed_full_defensive_reserve")
	main.free()


func _test_friendly_full_force_marching(failures: Array[String]) -> void:
	var main := MockMain.new()
	var ps = ProvinceSystemScript.new()
	main.province_system = ps
	ps.setup(main)
	var marcher = EnemyTurnSystemScript.new()
	marcher.setup(main)
	var states: Array[Dictionary] = [
		{"id": 0, "type": LevelConfig.PROVINCE_TYPE_FRIENDLY, "faction_id": 0, "remaining_troops": 500, "remaining_buildings": 2, "neighbors": [1]},
		{"id": 1, "type": LevelConfig.PROVINCE_TYPE_NEUTRAL, "faction_id": 0, "remaining_troops": 5, "remaining_buildings": 2, "neighbors": [0]}
	]
	main._province_persistence = states
	var snapshot: Dictionary = ps.make_province_snapshot_by_id()
	var plan: Dictionary = marcher._choose_best_march_plan(0, snapshot, snapshot.get(0, {}), LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 495, 5, 500)
	if int(plan.get("destination_id", -1)) != 1 or int(plan.get("moving_troops", 0)) != 495:
		failures.append("friendly_attack_did_not_send_entire_mobile_army")
	# A friendly staging move must not stop at the old reinforcement quota.
	states = [
		{"id": 0, "type": LevelConfig.PROVINCE_TYPE_FRIENDLY, "faction_id": 0, "remaining_troops": 500, "remaining_buildings": 2, "neighbors": [1]},
		{"id": 1, "type": LevelConfig.PROVINCE_TYPE_FRIENDLY, "faction_id": 0, "remaining_troops": 100, "remaining_buildings": 2, "neighbors": [0, 2]},
		{"id": 2, "type": LevelConfig.PROVINCE_TYPE_NEUTRAL, "faction_id": 0, "remaining_troops": 1200, "remaining_buildings": 5, "neighbors": [1]}
	]
	main._province_persistence = states
	snapshot = ps.make_province_snapshot_by_id()
	plan = marcher._choose_best_march_plan(0, snapshot, snapshot.get(0, {}), LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 495, 5, 500)
	if int(plan.get("destination_id", -1)) != 1 or int(plan.get("moving_troops", 0)) != 495:
		failures.append("friendly_reinforcement_did_not_send_entire_mobile_army")
	main.free()



func _test_garrison_reserves(failures: Array[String]) -> void:
	var main := MockMain.new()
	var ps = ProvinceSystemScript.new()
	main.province_system = ps
	ps.setup(main)
	var marcher = EnemyTurnSystemScript.new()
	marcher.setup(main)
	var friendly: Dictionary = {"id": 1, "type": LevelConfig.PROVINCE_TYPE_FRIENDLY, "faction_id": 0, "remaining_troops": 500, "remaining_buildings": 3, "neighbors": [2]}
	var neutral: Dictionary = {"id": 2, "type": LevelConfig.PROVINCE_TYPE_NEUTRAL, "faction_id": 0, "remaining_troops": 3, "remaining_buildings": 2, "neighbors": [1]}
	var snapshot: Dictionary = {1: friendly, 2: neutral}
	var friendly_reserve: int = marcher._get_local_defense_need(1, friendly, snapshot, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 5)
	if friendly_reserve != 5:
		failures.append("friendly_invasion_did_not_leave_exactly_five")
	var friendly_plan: Dictionary = marcher._choose_best_march_plan(1, snapshot, friendly, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 500 - friendly_reserve, friendly_reserve, 500)
	if int(friendly_plan.get("moving_troops", -1)) != 500 - friendly_reserve:
		failures.append("friendly_march_ignores_calculated_reserve")
	var enemy: Dictionary = {"id": 3, "type": LevelConfig.PROVINCE_TYPE_ENEMY, "faction_id": 2, "remaining_troops": 500, "remaining_buildings": 3, "neighbors": [4]}
	var rival: Dictionary = {"id": 4, "type": LevelConfig.PROVINCE_TYPE_ENEMY, "faction_id": 3, "remaining_troops": 3, "remaining_buildings": 2, "neighbors": [3]}
	snapshot = {3: enemy, 4: rival}
	var enemy_reserve: int = marcher._get_local_defense_need(3, enemy, snapshot, LevelConfig.PROVINCE_TYPE_ENEMY, 2, 5)
	if enemy_reserve != 5:
		failures.append("enemy_invasion_did_not_leave_exactly_five")
	var enemy_plan: Dictionary = marcher._choose_best_march_plan(3, snapshot, enemy, LevelConfig.PROVINCE_TYPE_ENEMY, 2, 500 - enemy_reserve, enemy_reserve, 500)
	if int(enemy_plan.get("moving_troops", -1)) != 500 - enemy_reserve:
		failures.append("enemy_march_ignores_calculated_reserve")
	# Strong adjacent enemies can still justify reserving more than five.
	rival["remaining_troops"] = 1200
	enemy_reserve = marcher._get_local_defense_need(3, enemy, snapshot, LevelConfig.PROVINCE_TYPE_ENEMY, 2, 5)
	if enemy_reserve != 500:
		failures.append("overwhelming_enemy_did_not_preserve_full_defense")
	# Merely bordering a weak hostile province must not trigger the old
	# 10/8 troop half-threshold reserve.
	rival["remaining_troops"] = 3
	enemy_reserve = marcher._get_local_defense_need(3, enemy, snapshot, LevelConfig.PROVINCE_TYPE_ENEMY, 2, 5)
	if enemy_reserve != 5:
		failures.append("weak_border_enemy_increased_garrison_above_five")
	main.free()


func _test_geography(failures: Array[String]) -> void:
	var generator = LevelGeneratorScript.new()
	var signatures: Dictionary = {}
	var gateway_maps: int = 0
	for seed_value in [71, 211, 447, 619, 829, 1009, 1201, 1553]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var data: Dictionary = generator._generate_template_grand_map_data(LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS, rng, seed_value, 3)
		var provinces: Array = data.get("provinces", [])
		var geo: Dictionary = data.get("geography", {})
		print("GEOGRAPHY_SEED ", JSON.stringify({"seed":seed_value,"provinces":provinces.size(),"peninsulas":geo.get("peninsulas",0),"gulfs":geo.get("gulfs",0),"gateways":geo.get("province_gateways",0),"gateway_seeds":geo.get("gateway_seeds",0),"blob_score":geo.get("blob_score",0.0),"land_cells":geo.get("land_cells",0)}))
		if seed_value in [71, 447, 829, 1553]:
			print("GEOGRAPHY_SILHOUETTE_%d\n%s" % [seed_value, _ascii_province_silhouette(provinces)])
		if String(data.get("template_id", "")) != LevelConfig.GRAND_MAP_TEMPLATE_EUROPE:
			failures.append("non_europe_template_%d" % seed_value)
		if provinces.size() < 18 or provinces.size() > 36:
			failures.append("wrong_province_count_%d_%d" % [seed_value, provinces.size()])
		if int(geo.get("peninsulas", 0)) < 2:
			failures.append("few_peninsulas_%d" % seed_value)
		if int(geo.get("gulfs", 0)) < 2:
			failures.append("few_gulfs_%d" % seed_value)
		if int(geo.get("province_gateways", 0)) > 0:
			gateway_maps += 1
		# Every province must be reachable by ordinary land adjacency.
		if not provinces.is_empty():
			var visited: Dictionary = {0: true}
			var q: Array[int] = [0]
			var h: int = 0
			while h < q.size():
				var current: int = q[h]
				h += 1
				var neighbors: Array = provinces[current].get("neighbors", [])
				for other_any in neighbors:
					var other: int = int(other_any)
					if other < 0 or other >= provinces.size():
						failures.append("invalid_neighbor_%d" % seed_value)
						continue
					if not (provinces[other].get("neighbors", []) as Array).has(current):
						failures.append("asymmetric_neighbor_%d" % seed_value)
					if not visited.has(other):
						visited[other] = true
						q.append(other)
			if visited.size() != provinces.size():
				failures.append("disconnected_provinces_%d" % seed_value)
		var signature: String = JSON.stringify(geo)
		if not provinces.is_empty():
			signature += str(provinces[0].get("polygon", PackedVector2Array()))
		signatures[signature] = true
	if signatures.size() < 6:
		failures.append("insufficient_seed_shape_variation")
	if gateway_maps < 4:
		failures.append("not_enough_maps_have_chokepoints_%d" % gateway_maps)


func _ascii_province_silhouette(provinces: Array) -> String:
	var drawn: Array[String] = []
	var columns: int = 46
	var rows: int = 24
	for row in range(rows):
		var line: String = ""
		for col in range(columns):
			var p: Vector2 = Vector2(
				LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS.x * (2.0 * (float(col) + 0.5) / float(columns) - 1.0),
				LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS.y * (2.0 * (float(row) + 0.5) / float(rows) - 1.0)
			)
			var occupied: bool = false
			for province in provinces:
				var poly: PackedVector2Array = province.get("polygon", PackedVector2Array())
				if poly.size() >= 3 and Geometry2D.is_point_in_polygon(p, poly):
					occupied = true
					break
			line += "#" if occupied else "."
		drawn.append(line)
	return "\n".join(drawn)
