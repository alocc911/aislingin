extends RefCounted
class_name ProvinceOverhaulSelfTest

const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const LevelConfig = preload("res://scripts/LevelConfig.gd")

class MockMain extends Node:
	var _province_persistence: Array[Dictionary] = []
	var boss_system = null
	var province_system = null
	var provinces_root: Node2D = Node2D.new()
	var map_seed: int = 1
	var _current_phase: String = "grand_map"
	var _locked_province_id_after_win: int = -1


static func run(province_system: Object = null) -> Dictionary:
	var failures: Array[String] = []
	var ps: Object = province_system
	if ps == null:
		ps = ProvinceSystemScript.new()

	_check_normalization(ps, failures)
	_check_food_and_accommodation(ps, failures)
	_check_population_and_rate_caps(ps, failures)
	_check_building_validation(ps, failures)
	_check_capture_building_loss(ps, failures)
	_check_revolution(ps, failures)
	_check_food_shortage_population_loss(ps, failures)
	_check_repair_completion(ps, failures)
	_check_income_and_building_effects(ps, failures)
	_check_neutral_recruitment_rate(ps, failures)
	_check_player_construction_control(ps, failures)
	_check_player_landing_construction_bonus(ps, failures)
	_check_construction_recommendations(ps, failures)
	_check_construction_forecast_temperance(ps, failures)

	return {
		"ok": failures.is_empty(),
		"failures": failures,
	}


static func _base_province() -> Dictionary:
	return {
		"id": 1,
		"type": LevelConfig.PROVINCE_TYPE_FRIENDLY,
		"faction_id": 0,
		"remaining_troops": 5,
		"remaining_buildings": 2,
		"building_capacity": 8,
		"gold_production": 1,
		"free_buildings": 0,
		"construction_progress": 0,
	}


static func _check_normalization(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	for key in [
		"province_economy_version",
		"population",
		"happiness",
		"food",
		"rates",
		"accommodation",
		"buildings",
		"active_construction",
		"province_status",
	]:
		if not province.has(key):
			failures.append("normalize_missing_%s" % key)


static func _check_food_and_accommodation(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	var food_before: float = float(province.get("food", {}).get("surplus", 0.0))
	if not ps.add_typed_building(province, "farm", 1):
		failures.append("farm_add_failed")
	var food_after: float = float(province.get("food", {}).get("surplus", 0.0))
	if food_after <= food_before:
		failures.append("food_surplus_not_responsive")
	if float(province.get("accommodation", {}).get("native_ceiling", 0.0)) <= 0.0:
		failures.append("native_accommodation_not_seeded")


static func _check_population_and_rate_caps(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	province["population"] = {"natives": 999.0, "outlanders": 999.0}
	ps.normalize_province_economy_state(province)
	var taper_caps: Dictionary = ps.get_population_taper_caps(province)
	var native_taper_cap: float = float(taper_caps.get("natives", 0.0))
	var outlander_taper_cap: float = float(taper_caps.get("outlanders", 0.0))
	if absf(native_taper_cap - 80.0) > 0.01:
		failures.append("native_taper_cap_not_seeded")
	if absf(outlander_taper_cap - 60.0) > 0.01:
		failures.append("outlander_taper_cap_not_seeded")
	if float(province.get("population", {}).get("natives", 0.0)) > native_taper_cap:
		failures.append("native_population_cap_not_applied")
	if float(province.get("population", {}).get("outlanders", 0.0)) > outlander_taper_cap:
		failures.append("outlander_population_cap_not_applied")
	var before_upgrade_native_ceiling: float = float(province.get("accommodation", {}).get("native_ceiling", 0.0))
	if not ps.upgrade_typed_building(province, "tenement", 1):
		failures.append("tenement_upgrade_fixture_failed")
	var upgraded_native_taper_cap: float = float(ps.get_population_taper_caps(province).get("natives", 0.0))
	var upgraded_native_ceiling: float = float(province.get("accommodation", {}).get("native_ceiling", 0.0))
	if absf(upgraded_native_taper_cap - native_taper_cap) > 0.01:
		failures.append("tenement_upgrade_changed_taper_cap")
	if upgraded_native_ceiling <= before_upgrade_native_ceiling:
		failures.append("tenement_upgrade_did_not_raise_accommodation")
	var before_upgrade_outlander_ceiling: float = float(province.get("accommodation", {}).get("outlander_ceiling", 0.0))
	if not ps.upgrade_typed_building(province, "mansion", 1):
		failures.append("mansion_upgrade_fixture_failed")
	var upgraded_outlander_taper_cap: float = float(ps.get_population_taper_caps(province).get("outlanders", 0.0))
	var upgraded_outlander_ceiling: float = float(province.get("accommodation", {}).get("outlander_ceiling", 0.0))
	if absf(upgraded_outlander_taper_cap - outlander_taper_cap) > 0.01:
		failures.append("mansion_upgrade_changed_taper_cap")
	if upgraded_outlander_ceiling <= before_upgrade_outlander_ceiling:
		failures.append("mansion_upgrade_did_not_raise_accommodation")
	if not ps.add_typed_building(province, "tenement", 1):
		failures.append("tenement_add_fixture_failed")
	if absf(float(ps.get_population_taper_caps(province).get("natives", 0.0)) - 110.0) > 0.01:
		failures.append("tenement_add_did_not_raise_taper_cap")
	if not ps.add_typed_building(province, "mansion", 1):
		failures.append("mansion_add_fixture_failed")
	if absf(float(ps.get_population_taper_caps(province).get("outlanders", 0.0)) - 90.0) > 0.01:
		failures.append("mansion_add_did_not_raise_taper_cap")
	native_taper_cap = float(ps.get_population_taper_caps(province).get("natives", 0.0))
	outlander_taper_cap = float(ps.get_population_taper_caps(province).get("outlanders", 0.0))
	province["population"]["natives"] = native_taper_cap - 0.1
	province["population"]["outlanders"] = outlander_taper_cap - 0.1
	ps.recalculate_province_derived_economy(province)
	ps._update_province_population(province)
	if float(province.get("population", {}).get("natives", 0.0)) > native_taper_cap:
		failures.append("native_population_growth_exceeded_cap")
	if float(province.get("population", {}).get("outlanders", 0.0)) > outlander_taper_cap:
		failures.append("outlander_population_growth_exceeded_cap")
	province["population"] = {"natives": native_taper_cap, "outlanders": outlander_taper_cap}
	province["buildings"]["club_factory"]["3"] = 10
	province["buildings"]["home_cave"]["3"] = 1
	ps.recalculate_province_derived_economy(province)
	if float(province.get("rates", {}).get("construction", 0.0)) > 10.0:
		failures.append("construction_rate_cap_not_applied")
	if float(province.get("rates", {}).get("recruitment", 0.0)) > 8.0:
		failures.append("recruitment_rate_cap_not_applied")


static func _check_building_validation(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	if not ps.add_typed_building(province, "home_cave", 1):
		failures.append("home_cave_first_add_failed")
	if ps.add_typed_building(province, "home_cave", 1):
		failures.append("home_cave_duplicate_allowed")
	if not ps.province_has_command_center(province):
		failures.append("command_center_presence_helper_failed")


static func _check_capture_building_loss(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	ps.add_typed_building(province, "club_factory", 1)
	ps.add_typed_building(province, "trap_factory", 1)
	var before_count: int = int(ps.calculate_occupied_building_slots(province))
	var counts: Dictionary = ps.get_conquered_province_counts(LevelConfig.PROVINCE_TYPE_FRIENDLY, province)
	if before_count != 5:
		failures.append("capture_fixture_building_count_%d" % before_count)
	if int(counts.get("remaining_buildings", 0)) != 3:
		failures.append("capture_building_loss_not_half")
	if int(ps.calculate_occupied_building_slots(province)) != before_count:
		failures.append("capture_counts_mutated_source_buildings")


static func _check_revolution(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	ps.add_typed_building(province, "club_factory", 2)
	ps.add_typed_building(province, "trap_factory", 1)
	province["happiness"]["natives"] = 0.0
	province["happiness"]["outlanders"] = 17.0
	var result: Dictionary = ps.tick_province_economy(province)
	if not bool(result.get("revolted", false)):
		failures.append("revolution_not_triggered")
	if String(province.get("type", "")) != LevelConfig.PROVINCE_TYPE_ENEMY:
		failures.append("revolution_owner_not_enemy")
	if int(province.get("faction_id", 0)) != 9000:
		failures.append("revolution_faction_not_rebel")
	if float(province.get("happiness", {}).get("natives", 0.0)) != 50.0:
		failures.append("revolution_native_happiness_not_reset")
	if float(province.get("happiness", {}).get("outlanders", 0.0)) != 50.0:
		failures.append("revolution_outlander_happiness_not_reset")
	if int(ps.calculate_occupied_building_slots(province)) != 3:
		failures.append("revolution_building_count_not_reset")
	if int(ps.get_typed_building_count(province, "farm", 1)) != 1:
		failures.append("revolution_farm_not_reset")
	if int(ps.get_typed_building_count(province, "mansion", 1)) != 1:
		failures.append("revolution_mansion_not_reset")
	if int(ps.get_typed_building_count(province, "tenement", 1)) != 1:
		failures.append("revolution_tenement_not_reset")
	if int(ps.get_typed_building_count(province, "club_factory")) != 0:
		failures.append("revolution_extra_building_not_removed")


static func _check_food_shortage_population_loss(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	province["population"] = {"natives": 100.0, "outlanders": 30.0}
	ps.recalculate_province_derived_economy(province)
	var before_natives: float = float(province.get("population", {}).get("natives", 0.0))
	var before_outlanders: float = float(province.get("population", {}).get("outlanders", 0.0))
	var before_food: Dictionary = province.get("food", {}).duplicate(true)
	var population_demand: float = before_natives * float(ps.get_province_tuning_value("native_food_demand")) + before_outlanders * float(ps.get_province_tuning_value("outlander_food_demand"))
	var sustainable_ratio: float = clampf(float(before_food.get("production", 0.0)) / population_demand, 0.0, 1.0)
	var expected_natives: float = (before_natives + before_natives * sustainable_ratio) * 0.5
	var expected_outlanders: float = (before_outlanders + before_outlanders * sustainable_ratio) * 0.5
	if not bool(ps._apply_food_shortage_population_loss(province)):
		failures.append("food_shortage_population_loss_not_applied")
	if absf(float(province.get("population", {}).get("natives", 0.0)) - expected_natives) > 0.01:
		failures.append("food_shortage_native_population_not_midpoint")
	if absf(float(province.get("population", {}).get("outlanders", 0.0)) - expected_outlanders) > 0.01:
		failures.append("food_shortage_outlander_population_not_midpoint")


static func _check_repair_completion(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	var before_t1: int = int(ps.get_typed_building_count(province, "farm", 1))
	if not ps.start_building_repair_construction(province):
		failures.append("repair_start_failed")
	province["rates"]["construction"] = 999.0
	ps._advance_active_construction(province)
	var after_t1: int = int(ps.get_typed_building_count(province, "farm", 1))
	if after_t1 >= before_t1:
		failures.append("repair_did_not_restore_typed_tier")
	if int(province.get("remaining_buildings", 0)) != int(ps.calculate_occupied_building_slots(province)):
		failures.append("repair_legacy_mirror_not_synced")


static func _check_income_and_building_effects(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	province["population"]["outlanders"] = 20.0
	ps.recalculate_province_derived_economy(province)
	if int(ps.get_province_total_income(province)) != int(ps.get_province_economy_income(province)):
		failures.append("legacy_gold_still_counted")
	if int(ps.get_province_total_income(province)) <= 0:
		failures.append("economy_income_not_counted")
	ps.add_typed_building(province, "trap_factory", 1)
	ps.add_typed_building(province, "catapult", 1)
	if int(ps.get_province_defense_strength(province)) <= 0:
		failures.append("defense_strength_missing")
	if int(ps.get_province_catapult_adjacent_damage(province)) <= 0:
		failures.append("catapult_damage_missing")


static func _check_neutral_recruitment_rate(ps: Object, failures: Array[String]) -> void:
	var neutral: Dictionary = _base_province()
	neutral["type"] = LevelConfig.PROVINCE_TYPE_NEUTRAL
	neutral["faction_id"] = 0
	neutral["population"] = {"natives": 100.0, "outlanders": 0.0}
	ps.normalize_province_economy_state(neutral)
	ps.add_typed_building(neutral, "club_factory", 1)
	ps.recalculate_province_derived_economy(neutral)
	if float(neutral.get("rates", {}).get("recruitment", -1.0)) != 0.0:
		failures.append("neutral_recruitment_not_zero")


static func _check_player_construction_control(ps: Object, failures: Array[String]) -> void:
	var mock_main := MockMain.new()
	var friendly_a: Dictionary = _base_province()
	friendly_a["id"] = 101
	var friendly_b: Dictionary = _base_province()
	friendly_b["id"] = 102
	var enemy: Dictionary = _base_province()
	enemy["id"] = 201
	enemy["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
	enemy["faction_id"] = LevelConfig.ENEMY_FACTION_DEFAULT
	var neutral: Dictionary = _base_province()
	neutral["id"] = 301
	neutral["type"] = LevelConfig.PROVINCE_TYPE_NEUTRAL
	neutral["faction_id"] = 0
	mock_main._province_persistence = [friendly_a, friendly_b, enemy, neutral]
	ps.setup(mock_main)
	mock_main.province_system = ps

	if not bool(ps.can_player_control_construction_in_province(101)):
		failures.append("friendly_construction_control_denied")
	if bool(ps.can_player_control_construction_in_province(201)):
		failures.append("enemy_construction_control_allowed")
	if bool(ps.can_player_control_construction_in_province(301)):
		failures.append("neutral_construction_control_allowed")

	var first_result: Dictionary = ps.start_province_construction_order(101, "build", "club_factory", 1)
	var second_result: Dictionary = ps.start_province_construction_order(102, "build", "trap_factory", 1)
	if not bool(first_result.get("ok", false)):
		failures.append("first_friendly_construction_rejected")
	if not bool(second_result.get("ok", false)):
		failures.append("second_friendly_construction_rejected")
	if mock_main._province_persistence[0].get("active_construction", {}).is_empty():
		failures.append("first_friendly_construction_not_queued")
	if mock_main._province_persistence[1].get("active_construction", {}).is_empty():
		failures.append("second_friendly_construction_not_queued")

	var enemy_actions: Array = ps.build_province_construction_actions(201)
	var neutral_actions: Array = ps.build_province_construction_actions(301)
	if not enemy_actions.is_empty():
		failures.append("enemy_construction_actions_visible")
	if not neutral_actions.is_empty():
		failures.append("neutral_construction_actions_visible")
	if bool(ps.start_province_construction_order(201, "build", "club_factory", 1).get("ok", false)):
		failures.append("enemy_construction_order_accepted")
	if bool(ps.start_province_construction_order(301, "build", "club_factory", 1).get("ok", false)):
		failures.append("neutral_construction_order_accepted")


static func _check_player_landing_construction_bonus(ps: Object, failures: Array[String]) -> void:
	var mock_main := MockMain.new()
	var landing: Dictionary = _base_province()
	landing["id"] = 401
	landing["active_construction"] = {
		"project_type": "build",
		"building_type": "club_factory",
		"target_tier": 1,
		"progress": 0.0,
		"required_progress": 1000.0,
	}
	var other: Dictionary = _base_province()
	other["id"] = 402
	other["active_construction"] = landing["active_construction"].duplicate(true)
	var enemy: Dictionary = _base_province()
	enemy["id"] = 403
	enemy["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
	enemy["faction_id"] = LevelConfig.ENEMY_FACTION_DEFAULT
	enemy["active_construction"] = landing["active_construction"].duplicate(true)
	mock_main._province_persistence = [landing, other, enemy]
	ps.setup(mock_main)
	mock_main.province_system = ps

	ps.tick_all_province_economies(401)
	var landing_progress: float = float(landing.get("active_construction", {}).get("progress", 0.0))
	var other_progress: float = float(other.get("active_construction", {}).get("progress", 0.0))
	if absf((landing_progress - other_progress) - 10.0) > 0.01:
		failures.append("landing_construction_bonus_not_exact")
	if int(landing.get("remaining_buildings", 0)) != int(other.get("remaining_buildings", 0)):
		failures.append("landing_bonus_changed_buildings")

	var enemy_progress_before: float = float(enemy.get("active_construction", {}).get("progress", 0.0))
	ps.tick_all_province_economies(403)
	var enemy_progress_after: float = float(enemy.get("active_construction", {}).get("progress", 0.0))
	if enemy_progress_after - enemy_progress_before > 10.0:
		failures.append("enemy_landing_bonus_applied")


static func _fresh_recommendation_system() -> Object:
	return ProvinceSystemScript.new()


static func _normalized_recommendation_province(ps: Object) -> Dictionary:
	var province: Dictionary = _base_province()
	province["id"] = 401
	province["building_capacity"] = 8
	ps.normalize_province_economy_state(province)
	return province


static func _check_construction_recommendations(ps: Object, failures: Array[String]) -> void:
	var local_ps: Object = _fresh_recommendation_system()
	var food_province: Dictionary = _normalized_recommendation_province(local_ps)
	food_province["population"]["natives"] = 24.0
	food_province["population"]["outlanders"] = 60.0
	food_province["buildings"]["mansion"]["3"] = 3
	local_ps.recalculate_province_derived_economy(food_province)
	var food_recommendation: Dictionary = local_ps.build_recommended_construction_order(food_province)
	if String(food_recommendation.get("building_type", "")) != "farm":
		failures.append("recommendation_food_deficit_not_farm")
	if not food_province.get("active_construction", {}).is_empty():
		failures.append("recommendation_mutated_active_project")

	var native_province: Dictionary = _normalized_recommendation_province(local_ps)
	native_province["population"]["natives"] = 300.0
	native_province["population"]["outlanders"] = 1.0
	native_province["buildings"]["farm"]["3"] = 1
	local_ps.recalculate_province_derived_economy(native_province)
	var native_recommendation: Dictionary = local_ps.build_recommended_construction_order(native_province)
	if String(native_recommendation.get("building_type", "")) != "tenement":
		failures.append("recommendation_native_overcrowding_not_tenement")

	var active_province: Dictionary = _normalized_recommendation_province(local_ps)
	if not local_ps.start_building_construction(active_province, "club_factory", 1):
		failures.append("recommendation_active_fixture_start_failed")
	if not local_ps.build_recommended_construction_order(active_province).is_empty():
		failures.append("recommendation_active_project_not_empty")

	var no_slot_province: Dictionary = _normalized_recommendation_province(local_ps)
	while int(local_ps.calculate_remaining_building_slots(no_slot_province)) > 0:
		if not local_ps.add_typed_building(no_slot_province, "club_factory", 1):
			break
	var no_slot_recommendation: Dictionary = local_ps.build_recommended_construction_order(no_slot_province)
	if not ["upgrade", "repair"].has(String(no_slot_recommendation.get("request_type", ""))):
		failures.append("recommendation_no_slots_no_valid_existing_project")

	var mock_main := MockMain.new()
	var player_province: Dictionary = _base_province()
	player_province["id"] = 501
	player_province["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
	player_province["faction_id"] = 0
	player_province["population"] = {"natives": 24.0, "outlanders": 60.0}
	player_province["buildings"] = {
		"farm": {"1": 1},
		"tenement": {"1": 1},
		"mansion": {"3": 3}
	}
	var enemy_province: Dictionary = _base_province()
	enemy_province["id"] = 601
	enemy_province["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
	enemy_province["faction_id"] = LevelConfig.ENEMY_FACTION_DEFAULT
	enemy_province["neighbors"] = [501]
	mock_main._province_persistence = [player_province, enemy_province]
	local_ps.setup(mock_main)
	mock_main.province_system = local_ps
	var player_actions: Array = local_ps.build_province_construction_actions(501)
	var recommended_count: int = 0
	for action_any in player_actions:
		if action_any is Dictionary and bool((action_any as Dictionary).get("recommended", false)):
			recommended_count += 1
			if String((action_any as Dictionary).get("building_type", "")) != "farm":
				failures.append("player_recommended_action_not_farm")
	if recommended_count != 1:
		failures.append("player_recommended_action_count_%d" % recommended_count)

	var cpu_started: String = String(local_ps._maybe_start_non_player_construction(mock_main._province_persistence[1]))
	if cpu_started == "":
		failures.append("cpu_recommendation_did_not_start")
	if mock_main._province_persistence[1].get("active_construction", {}).is_empty():
		failures.append("cpu_recommendation_no_active_project")
	if not mock_main._province_persistence[0].get("active_construction", {}).is_empty():
		failures.append("cpu_recommendation_mutated_player_province")

	var auto_player: Dictionary = (player_province as Dictionary).duplicate(true)
	auto_player["id"] = 701
	auto_player["population"] = {"natives": 0.0, "outlanders": 60.0}
	var auto_result: Dictionary = local_ps.tick_province_economy(auto_player)
	var auto_project: Dictionary = auto_player.get("active_construction", {})
	if String(auto_result.get("player_auto_started_building", "")) != "farm":
		failures.append("player_auto_construction_not_reported")
	if String(auto_project.get("building_type", "")) != "farm":
		failures.append("player_auto_construction_not_started")

	var override_player: Dictionary = (player_province as Dictionary).duplicate(true)
	override_player["id"] = 702
	override_player["population"] = {"natives": 0.0, "outlanders": 60.0}
	local_ps.normalize_province_economy_state(override_player)
	if not local_ps.start_building_construction(override_player, "club_factory", 1):
		failures.append("player_override_fixture_start_failed")
	var override_result: Dictionary = local_ps.tick_province_economy(override_player)
	var override_project: Dictionary = override_player.get("active_construction", {})
	if String(override_result.get("player_auto_started_building", "")) != "":
		failures.append("player_override_auto_started_extra_project")
	if String(override_project.get("building_type", "")) != "club_factory":
		failures.append("player_override_project_replaced")


static func _check_construction_forecast_temperance(ps: Object, failures: Array[String]) -> void:
	var local_ps: Object = _fresh_recommendation_system()
	var province: Dictionary = _normalized_recommendation_province(local_ps)
	local_ps.recalculate_province_derived_economy(province)
	var recommendation: Dictionary = local_ps.build_recommended_construction_order(province)
	if String(recommendation.get("reason", "")) == "Forecast native overcrowding":
		failures.append("forecast_default_native_overcrowding_too_active")
	if String(recommendation.get("building_type", "")) == "tenement":
		failures.append("forecast_default_tenement_overpreferred")
