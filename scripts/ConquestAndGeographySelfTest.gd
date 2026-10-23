extends SceneTree

const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const LevelConfig = preload("res://scripts/LevelConfig.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const EngagementResolverScript = preload("res://scripts/EngagementResolver.gd")

class MockMain extends Node:
	var _province_persistence: Array[Dictionary] = []
	var province_system = null
	var boss_system = null
	var gold_balance: int = 0
	var level_index: int = 1
	var map_seed: int = 1
	func _is_milestone(_idx: int) -> bool:
		return false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	_test_conquest(failures)
	_test_geography(failures)
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
