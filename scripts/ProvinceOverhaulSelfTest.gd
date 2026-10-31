extends RefCounted
class_name ProvinceOverhaulSelfTest

const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const LevelConfig = preload("res://scripts/LevelConfig.gd")
const SpriteRegionCache = preload("res://scripts/SpriteRegionCache.gd")

class MockBossRecruitment extends RefCounted:
	func get_boss_recruitment_bonus_for_faction(faction_id: int) -> int:
		return 4 if faction_id == 101 else 0
	func is_friendly_boss_faction_id(_faction_id: int) -> bool:
		return false


class MockMain extends Node:
	var _province_persistence: Array[Dictionary] = []
	var boss_system = null
	var province_system = null
	var provinces_root: Node2D = Node2D.new()
	var map_seed: int = 1
	var current_camera_zoom: float = 0.4
	var _current_phase: String = "grand_map"
	var _locked_province_id_after_win: int = -1
	var _construction_build_mode_enabled: bool = false
	var gold_balance: int = 100
	var turn_number: int = 1
	var capital_id: int = -1
	var locked_troop_province_id: int = -1

	func is_province_troop_destination_locked(province_id: int) -> bool:
		return province_id == locked_troop_province_id

	func get_player_capital_province_id() -> int:
		return capital_id


static func run(province_system: Object = null) -> Dictionary:
	var failures: Array[String] = []
	var ps: Object = province_system
	if ps == null:
		ps = ProvinceSystemScript.new()

	_check_normalization(ps, failures)
	_check_food_and_accommodation(ps, failures)
	_check_population_and_uncapped_rates(ps, failures)
	_check_building_validation(ps, failures)
	_check_capture_building_loss(ps, failures)
	_check_player_capture_starter_buildings(ps, failures)
	_check_revolution(ps, failures)
	_check_revolt_happiness_recovery(ps, failures)
	_check_neutral_troop_cap(ps, failures)
	_check_food_shortage_population_loss(ps, failures)
	_check_migration_and_conquest_population(failures)
	_check_population_crises_and_recovery(ps, failures)
	_check_repair_completion(ps, failures)
	_check_income_and_building_effects(ps, failures)
	_check_neutral_recruitment_rate(ps, failures)
	_check_protected_ai_queue_and_funding(failures)
	_check_boss_limb_recruitment_bonus(failures)
	_check_player_construction_control(ps, failures)
	_check_menu_construction_queue_and_owner_change(failures)
	_check_construction_queue_carries_surplus(failures)
	_check_player_landing_construction_bonus(ps, failures)
	_check_construction_recommendations(ps, failures)
	_check_construction_forecast_temperance(ps, failures)
	_check_tier_three_home_cave_global_troop_control(ps, failures)
	_check_paid_construction(ps, failures)
	_check_recruitment_focus_queue(ps, failures)
	_check_repair_persistence_and_combat_damage(ps, failures)
	_check_queue_spending_and_affordable_fallback(ps, failures)
	_check_performance_cache_invalidation(failures)
	_check_cached_troop_rendering(failures)
	_check_automated_battle_preview_icons(failures)
	_check_imported_sprite_region_cache(failures)

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
		"construction_queue",
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


static func _check_population_and_uncapped_rates(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	province["population"] = {"natives": 999.0, "outlanders": 999.0}
	ps.normalize_province_economy_state(province)
	if float(province["population"]["natives"]) != 999.0 or float(province["population"]["outlanders"]) != 999.0:
		failures.append("population_clamped_by_housing")
	# Enough food permits natural growth even far beyond housing capacity.
	province["buildings"]["farm"]["3"] = 30
	ps.recalculate_province_derived_economy(province)
	var before: float = float(province["population"]["natives"])
	ps._update_province_population(province)
	if float(province["population"]["natives"]) <= before:
		failures.append("population_growth_stops_at_housing_limit")
	province["buildings"]["club_factory"]["3"] = 10
	ps.recalculate_province_derived_economy(province)
	if float(province.get("rates", {}).get("construction", 0.0)) <= 10.0:
		failures.append("construction_rate_still_capped")
	if float(province.get("rates", {}).get("recruitment", 0.0)) <= 8.0:
		failures.append("recruitment_rate_still_capped")


static func _check_building_validation(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	if not ps.add_typed_building(province, "home_cave", 1):
		failures.append("home_cave_first_add_failed")
	if ps.add_typed_building(province, "home_cave", 1):
		failures.append("home_cave_duplicate_allowed")
	if not ps.province_has_command_center(province):
		failures.append("command_center_presence_helper_failed")
	if ps.get_home_cave_tier(province) != 1:
		failures.append("home_cave_tier_1_not_detected")
	if not ps.upgrade_typed_building(province, "home_cave", 1):
		failures.append("home_cave_upgrade_to_t2_failed")
	if ps.get_home_cave_tier(province) != 2:
		failures.append("home_cave_tier_2_not_detected")
	if not ps.upgrade_typed_building(province, "home_cave", 2):
		failures.append("home_cave_upgrade_to_t3_failed")
	if ps.get_home_cave_tier(province) != 3:
		failures.append("home_cave_tier_3_not_detected")
	if ps.upgrade_typed_building(province, "home_cave", 3):
		failures.append("home_cave_upgrade_past_t3_allowed")


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


static func _check_player_capture_starter_buildings(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	ps.add_typed_building(province, "club_factory", 1)
	ps.add_typed_building(province, "trap_factory", 1)
	ps.seed_basic_conquest_buildings(province)
	if int(ps.calculate_occupied_building_slots(province)) != 3:
		failures.append("player_capture_not_three_starter_buildings")
	for basic_type in ["farm", "mansion", "tenement"]:
		if int(ps.get_typed_building_count(province, basic_type, 1)) != 1:
			failures.append("player_capture_missing_" + basic_type)
	if int(ps.get_typed_building_count(province, "club_factory")) != 0 or int(ps.get_typed_building_count(province, "trap_factory")) != 0:
		failures.append("player_capture_preserved_former_buildings")


static func _check_boss_limb_recruitment_bonus(failures: Array[String]) -> void:
	var main := MockMain.new()
	main.boss_system = MockBossRecruitment.new()
	var ps = ProvinceSystemScript.new()
	ps.setup(main)
	var province: Dictionary = _base_province()
	province["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
	province["faction_id"] = 101
	ps.normalize_province_economy_state(province)
	var boss_rate: float = ps.calculate_recruitment_rate(province)
	province["faction_id"] = 2
	var ordinary_rate: float = ps.calculate_recruitment_rate(province)
	if absf((boss_rate - ordinary_rate) - 4.0) > 0.01:
		failures.append("boss_limbs_not_four_flat_recruits")
	province["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
	province["faction_id"] = 101  # A pending hostile invasion cannot receive the boss bonus.
	if absf(ps.calculate_recruitment_rate(province) - ordinary_rate) > 0.01:
		failures.append("pending_invasion_received_boss_recruitment")
	main.free()


static func _check_revolution(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	ps.add_typed_building(province, "club_factory", 2)
	ps.add_typed_building(province, "trap_factory", 1)
	province["happiness"]["natives"] = 0.0
	province["happiness"]["outlanders"] = 17.0
	# No troops gives a guaranteed revolt if the post-tick happiness stays at zero.
	province["remaining_troops"] = 0
	province["buildings"]["farm"]["1"] = 0
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
	if int(ps.get_typed_building_count(province, "club_factory")) != 1:
		failures.append("revolution_erased_noncombat_buildings")
	if float(province["population"]["natives"]) < 20.0:
		failures.append("revolution_destroyed_population")


static func _check_revolt_happiness_recovery(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	province["happiness"]["natives"] = 0.0
	province["happiness"]["outlanders"] = 10.0
	var still_at_zero: bool = ps._apply_province_happiness_deltas(province, 0)
	if still_at_zero or float(province["happiness"]["natives"]) <= 0.0:
		failures.append("recovered_zero_happiness_incorrectly_revolts")


static func _check_neutral_troop_cap(ps: Object, failures: Array[String]) -> void:
	var neutral: Dictionary = _base_province()
	neutral["type"] = LevelConfig.PROVINCE_TYPE_NEUTRAL
	neutral["faction_id"] = 0
	ps.normalize_province_economy_state(neutral)
	neutral["remaining_troops"] = 49
	neutral["population"]["natives"] = 150.0
	neutral["happiness"]["natives"] = 100.0
	ps.recalculate_province_derived_economy(neutral)
	ps._apply_recruitment_and_income(neutral, 0)
	if int(neutral["remaining_troops"]) > 50:
		failures.append("neutral_normal_recruitment_exceeds_50")
	neutral["remaining_troops"] = 120
	ps.normalize_province_economy_state(neutral)
	if int(neutral["remaining_troops"]) != 50:
		failures.append("neutral_load_normalization_not_capped")
	neutral["remaining_troops"] = 120
	neutral["happiness"]["natives"] = 100.0
	neutral["happiness"]["outlanders"] = 100.0
	ps.tick_province_economy(neutral)
	if int(neutral["remaining_troops"]) > 50:
		failures.append("existing_neutral_exceeds_50")
	var enemy: Dictionary = neutral.duplicate(true)
	enemy["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
	if int(ps._cap_neutral_province_troops(enemy, 650)) != 650:
		failures.append("neutral_cap_affected_enemy")


static func _check_food_shortage_population_loss(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	province["population"] = {"natives": 100.0, "outlanders": 30.0}
	ps.recalculate_province_derived_economy(province)
	var before: float = float(province["population"]["natives"])
	var before_happy: float = float(province["happiness"]["natives"])
	ps._update_province_population(province)
	if float(province["population"]["natives"]) <= before:
		failures.append("ordinary_food_deficit_stopped_population_growth")
	ps.recalculate_province_derived_economy(province)
	ps._apply_province_happiness_deltas(province)
	if float(province["happiness"]["natives"]) >= before_happy - 5.0:
		failures.append("food_deficit_did_not_reduce_happiness_quickly")
	province["buildings"]["farm"]["1"] = 0
	ps.recalculate_province_derived_economy(province)
	var starved_before: float = float(province["population"]["natives"])
	ps._update_province_population(province)
	var loss_fraction: float = (starved_before - float(province["population"]["natives"])) / starved_before
	if loss_fraction < 0.009 or loss_fraction > 0.021:
		failures.append("extreme_starvation_population_loss_not_slow")


static func _check_migration_and_conquest_population(failures: Array[String]) -> void:
	var ps: Object = ProvinceSystemScript.new()
	var mock := MockMain.new()
	var a: Dictionary = _base_province()
	var b: Dictionary = _base_province()
	var c: Dictionary = _base_province()
	a["id"] = 5101
	b["id"] = 5102
	c["id"] = 5103
	a["neighbors"] = [5102, 5103]
	b["neighbors"] = [5101]
	c["neighbors"] = [5101]
	mock._province_persistence = [a, b, c]
	ps.setup(mock)
	mock.province_system = ps
	for p in mock._province_persistence:
		ps.normalize_province_economy_state(p)
		p["buildings"]["farm"]["3"] = 2
		p["buildings"]["mansion"]["3"] = 2
		p["buildings"]["tenement"]["3"] = 2
	a["population"] = {"natives": 100.0, "outlanders": 30.0}
	b["population"] = {"natives": 20.0, "outlanders": 50.0}
	c["population"] = {"natives": 20.0, "outlanders": 20.0}
	a["happiness"] = {"natives": 40.0, "outlanders": 70.0}
	b["happiness"] = {"natives": 85.0, "outlanders": 70.0}
	c["happiness"] = {"natives": 55.0, "outlanders": 70.0}
	for p in mock._province_persistence:
		ps.recalculate_province_derived_economy(p)
	var natives_before: float = float(a["population"]["natives"]) + float(b["population"]["natives"]) + float(c["population"]["natives"])
	var outlanders_before: float = float(a["population"]["outlanders"]) + float(b["population"]["outlanders"]) + float(c["population"]["outlanders"])
	var migrated: Dictionary = ps.migrate_adjacent_provinces()
	if float(migrated.get("natives", 0.0)) <= 0.0 or float(b["population"]["natives"]) <= 20.0:
		failures.append("natives_did_not_follow_happiness")
	if float(migrated.get("outlanders", 0.0)) <= 0.0:
		failures.append("outlanders_did_not_follow_gold")
	if absf(natives_before - float(a["population"]["natives"]) - float(b["population"]["natives"]) - float(c["population"]["natives"])) > 0.001:
		failures.append("native_migration_created_population")
	if absf(outlanders_before - float(a["population"]["outlanders"]) - float(b["population"]["outlanders"]) - float(c["population"]["outlanders"])) > 0.001:
		failures.append("outlander_migration_created_population")
	var old_n: float = float(b["population"]["natives"])
	var old_o: float = float(b["population"]["outlanders"])
	ps.apply_violent_conquest_population_losses(b)
	if absf(float(b["population"]["natives"]) - old_n * 0.15) > 0.001 or absf(float(b["population"]["outlanders"]) - old_o * 0.15) > 0.001:
		failures.append("conquest_did_not_destroy_85_percent")
	mock.free()


static func _check_population_crises_and_recovery(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	if ps._get_starvation_tier({"production": 100.0, "demand": 100.0}) != 0 or ps._get_starvation_tier({"production": 90.0, "demand": 100.0}) != 1 or ps._get_starvation_tier({"production": 60.0, "demand": 100.0}) != 2 or ps._get_starvation_tier({"production": 20.0, "demand": 100.0}) != 3:
		failures.append("three_starvation_tiers_incorrect")
	var well_fed: Dictionary = _base_province()
	ps.normalize_province_economy_state(well_fed)
	well_fed["population"] = {"natives": 24.0, "outlanders": 4.0}
	well_fed["happiness"] = {"natives": 60.0, "outlanders": 60.0}
	ps.recalculate_province_derived_economy(well_fed)
	var small_recruitment: float = float(ps.calculate_recruitment_rate(well_fed, {}, 0))
	well_fed["population"]["natives"] = 200.0
	well_fed["buildings"]["farm"]["3"] = 3
	ps.recalculate_province_derived_economy(well_fed)
	var large_recruitment: float = float(ps.calculate_recruitment_rate(well_fed, {}, 0))
	if large_recruitment < small_recruitment * 4.0:
		failures.append("population_recruitment_not_sensitive")
	if float(ps.calculate_recruitment_rate(well_fed, {}, 2)) >= large_recruitment * 0.6:
		failures.append("moderate_starvation_not_reducing_recruitment")
	if float(ps.calculate_recruitment_rate(well_fed, {}, 3)) > 0.01:
		failures.append("severe_starvation_still_recruiting")
	well_fed["happiness"]["natives"] = 30.0
	if float(ps.calculate_recruitment_rate(well_fed, {}, 0)) >= large_recruitment * 0.6:
		failures.append("happiness_not_reducing_total_recruitment")
	well_fed["population"]["natives"] = 0.0
	if float(ps.calculate_recruitment_rate(well_fed, {}, 0)) > 0.01:
		failures.append("zero_native_population_still_recruiting")
	# Housing loss must not erase the residents.
	province["population"] = {"natives": 200.0, "outlanders": 30.0}
	province["buildings"]["tenement"]["1"] = 0
	province["buildings"]["mansion"]["1"] = 0
	ps.recalculate_province_derived_economy(province)
	if float(province["population"]["natives"]) < 199.9 or float(province["population"]["outlanders"]) < 29.9:
		failures.append("housing_loss_erased_population")
	# Extinct groups can resettle when food is available, but cannot grow on bare ground.
	var recovery: Dictionary = _base_province()
	ps.normalize_province_economy_state(recovery)
	recovery["population"] = {"natives": 0.0, "outlanders": 0.0}
	ps.recalculate_province_derived_economy(recovery)
	ps._update_province_population(recovery)
	if float(recovery["population"]["natives"]) < 1.0 or float(recovery["population"]["outlanders"]) < 1.0:
		failures.append("zero_population_cannot_resettle")
	recovery["population"] = {"natives": 0.0, "outlanders": 0.0}
	recovery["buildings"]["farm"]["1"] = 0
	ps.recalculate_province_derived_economy(recovery)
	ps._update_province_population(recovery)
	if float(recovery["population"]["natives"]) != 0.0 or float(recovery["population"]["outlanders"]) != 0.0:
		failures.append("resettlement_without_food")
	# Severe famine must use the shortage before attrition, suppress both recruitment paths,
	# reduce happiness substantially, and eventually revolt at the existing zero threshold.
	var famine: Dictionary = _base_province()
	ps.normalize_province_economy_state(famine)
	famine["buildings"]["farm"]["1"] = 0
	famine["remaining_troops"] = 5
	ps.recalculate_province_derived_economy(famine)
	var after_one: Dictionary = ps.tick_province_economy(famine)
	if bool(after_one.get("revolted", false)) or int(famine.get("remaining_troops", 0)) != 5:
		failures.append("severe_famine_recruited_troops")
	if float(famine.get("happiness", {}).get("natives", 0.0)) > 50.01:
		failures.append("famine_happiness_uses_post_death_deficit")
	var famine_revolted: bool = false
	for _i in range(6):
		if bool(ps.tick_province_economy(famine).get("revolted", false)):
			famine_revolted = true
			break
	if not famine_revolted:
		failures.append("severe_famine_did_not_trigger_zero_happiness_revolution")
	var focus: Dictionary = _base_province()
	ps.normalize_province_economy_state(focus)
	focus["buildings"]["farm"]["1"] = 0
	focus["active_construction"] = {"project_type": "recruitment", "building_type": "", "target_tier": 1, "progress": 0.0, "required_progress": 1.0}
	focus["remaining_troops"] = 5
	ps.recalculate_province_derived_economy(focus)
	ps._advance_active_construction(focus, 3)
	if int(focus.get("remaining_troops", 0)) != 5:
		failures.append("recruitment_focus_bypassed_famine")

static func _check_repair_completion(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	if ps.start_building_repair_construction(province):
		failures.append("undamaged_building_could_be_repaired")
	if not ps.upgrade_typed_building(province, "farm", 1):
		failures.append("repair_fixture_upgrade_failed")
	ps.damage_typed_buildings(province, 1)
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
	ps.recalculate_province_derived_economy(neutral)
	if float(neutral.get("rates", {}).get("recruitment", 0.0)) <= 0.0:
		failures.append("neutral_recruitment_should_be_positive")
	for military in ["club_factory", "trap_factory", "catapult"]:
		if ps._is_construction_action_valid(neutral, {"request_type": "build", "building_type": military, "tier": 1}):
			failures.append("neutral_military_construction_allowed_" + military)
	if not ps._is_construction_action_valid(neutral, {"request_type": "build", "building_type": "farm", "tier": 1}):
		failures.append("neutral_economic_construction_blocked")


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

	var focus_result: Dictionary = ps.start_province_construction_order(102, "recruitment", "", 1)
	if bool(focus_result.get("ok", false)):
		failures.append("recruitment_focus_allowed_over_active_project")
	mock_main._province_persistence[1]["active_construction"] = {}
	focus_result = ps.start_province_construction_order(102, "recruitment", "", 1)
	if not bool(focus_result.get("ok", false)):
		failures.append("recruitment_focus_rejected")
	if String(mock_main._province_persistence[1].get("active_construction", {}).get("project_type", "")) != "recruitment":
		failures.append("recruitment_focus_not_active")


static func _check_menu_construction_queue_and_owner_change(failures: Array[String]) -> void:
	var ps: Object = ProvinceSystemScript.new()
	var mock := MockMain.new()
	mock.gold_balance = 100
	var province: Dictionary = _base_province()
	province["id"] = 4401
	mock._province_persistence = [province]
	ps.setup(mock)
	mock.province_system = ps
	ps.normalize_province_economy_state(province)
	var first: Dictionary = ps.enqueue_province_construction_order(4401, {"request_type": "build", "building_type": "club_factory", "tier": 1})
	if not bool(first.get("ok", false)) or province.get("active_construction", {}).is_empty():
		failures.append("menu_queue_did_not_start_immediate_project")
	var before_second: int = mock.gold_balance
	var second: Dictionary = ps.enqueue_province_construction_order(4401, {"request_type": "build", "building_type": "farm", "tier": 1})
	var pending: Array = province.get("construction_queue", [])
	if not bool(second.get("ok", false)) or pending.size() != 1:
		failures.append("menu_queue_rejected_while_active")
	if mock.gold_balance != before_second or (not pending.is_empty() and bool(pending[0].get("prepaid", false))):
		failures.append("menu_queue_charged_before_construction")
	var before_cancel: int = mock.gold_balance
	var cancelled: Dictionary = ps.remove_queued_province_construction_order(4401, 0)
	if not bool(cancelled.get("ok", false)) or mock.gold_balance != before_cancel:
		failures.append("menu_queue_cancel_changed_gold")
	ps.enqueue_province_construction_order(4401, {"request_type": "build", "building_type": "farm", "tier": 1})
	var balance_before_loss: int = mock.gold_balance
	ps.reset_construction_on_owner_change(province, LevelConfig.PROVINCE_TYPE_FRIENDLY, LevelConfig.PROVINCE_TYPE_ENEMY)
	if not province.get("active_construction", {}).is_empty() or not (province.get("construction_queue", []) as Array).is_empty():
		failures.append("conquered_province_inherited_construction")
	if mock.gold_balance != balance_before_loss:
		failures.append("conquered_province_unpaid_queue_changed_gold")
	mock.free()


static func _check_protected_ai_queue_and_funding(failures: Array[String]) -> void:
	var ps: Object = ProvinceSystemScript.new()
	var mock := MockMain.new()
	mock.turn_number = 10
	mock.gold_balance = 100
	var province: Dictionary = _base_province()
	province["id"] = 4410
	province["building_capacity"] = 12
	province["construction_queue"] = [
		{"request_type": "build", "building_type": "farm", "tier": 1, "automatic_recommendation": true},
		{"request_type": "build", "building_type": "mansion", "tier": 1, "automatic_recommendation": true},
		{"request_type": "build", "building_type": "catapult", "tier": 1, "automatic_recommendation": true}
	]
	mock._province_persistence = [province]
	ps.setup(mock)
	mock.province_system = ps
	ps.normalize_province_economy_state(province)
	var moved: Dictionary = ps.move_queued_province_construction_order(4410, 1, -1)
	if not bool(moved.get("ok", false)):
		failures.append("player_queue_reorder_rejected")
	var approved: Array = province.get("construction_queue", [])
	if approved.size() != 3 or String(approved[0].get("building_type", "")) != "mansion":
		failures.append("player_queue_reorder_wrong_order")
	for order_any in approved:
		if bool((order_any as Dictionary).get("automatic_recommendation", true)):
			failures.append("player_queue_intervention_did_not_protect_entire_queue")
			break
	mock.turn_number += 1
	ps._fill_automatic_construction_queue(province)
	var refreshed: Array = province.get("construction_queue", [])
	if refreshed.size() < 3 or String(refreshed[0].get("building_type", "")) != "mansion" or String(refreshed[1].get("building_type", "")) != "farm" or String(refreshed[2].get("building_type", "")) != "catapult":
		failures.append("queue_refresh_lost_approved_prefix")
	for i in range(mini(3, refreshed.size())):
		if bool((refreshed[i] as Dictionary).get("automatic_recommendation", true)):
			failures.append("queue_refresh_unprotected_prefix")
			break
	mock.turn_number += 1
	ps._fill_automatic_construction_queue(province)
	var later: Array = province.get("construction_queue", [])
	if later.size() < 3 or String(later[0].get("building_type", "")) != "mansion":
		failures.append("queue_second_refresh_modified_player_orders")
	var clear_result: Dictionary = ps.clear_queued_province_construction_orders(4410)
	if not bool(clear_result.get("ok", false)) or not (province.get("construction_queue", []) as Array).is_empty():
		failures.append("cancel_all_did_not_clear_pending")
	mock.turn_number += 1
	ps.plan_all_province_construction_queues()
	if (province.get("construction_queue", []) as Array).is_empty():
		failures.append("cancel_all_blocked_next_turn_ai_refill")
	province["construction_queue"] = [
		{"request_type": "build", "building_type": "farm", "tier": 1, "automatic_recommendation": false},
		{"request_type": "build", "building_type": "mansion", "tier": 1, "automatic_recommendation": false},
		{"request_type": "build", "building_type": "tenement", "tier": 1, "automatic_recommendation": false}
	]
	mock.turn_number += 1
	ps.plan_all_province_construction_queues()
	var protected_refill: Array = province.get("construction_queue", [])
	if protected_refill.size() != 5 or String(protected_refill[0].get("building_type", "")) != "farm" or String(protected_refill[2].get("building_type", "")) != "tenement":
		failures.append("ai_failed_to_fill_two_slots_after_three_manual_orders")
	# Shared treasury order must not depend on persistence array order.
	var first: Dictionary = _base_province()
	first["id"] = 4412
	first["construction_queue"] = [{"request_type": "build", "building_type": "farm", "tier": 1, "manual_sequence": 1}]
	var second: Dictionary = _base_province()
	second["id"] = 4411
	second["construction_queue"] = [{"request_type": "build", "building_type": "farm", "tier": 1, "manual_sequence": 2}]
	mock._province_persistence = [second, first]
	mock.gold_balance = 3
	mock.turn_number += 1
	ps.invalidate_persistence_index_cache()
	ps._schedule_player_construction_starts()
	if first.get("active_construction", {}).is_empty() or not second.get("active_construction", {}).is_empty():
		failures.append("shared_gold_not_allocated_in_manual_sequence")
	if mock.gold_balance != 0:
		failures.append("manual_construction_start_not_charged_once")
	mock.free()


static func _check_construction_queue_carries_surplus(failures: Array[String]) -> void:
	var ps: Object = ProvinceSystemScript.new()
	var mock := MockMain.new()
	mock.gold_balance = 100
	var province: Dictionary = _base_province()
	province["id"] = 4402
	mock._province_persistence = [province]
	ps.setup(mock)
	mock.province_system = ps
	ps.normalize_province_economy_state(province)
	ps.enqueue_province_construction_order(4402, {"request_type": "build", "building_type": "club_factory", "tier": 1})
	ps.enqueue_province_construction_order(4402, {"request_type": "build", "building_type": "farm", "tier": 1})
	var active: Dictionary = province.get("active_construction", {})
	if active.is_empty():
		failures.append("surplus_fixture_no_active_project")
		mock.free()
		return
	active["progress"] = float(active.get("required_progress", 1.0)) - 2.0
	province["active_construction"] = active
	province["rates"]["construction"] = 8.0
	ps._advance_active_construction(province)
	var next_project: Dictionary = province.get("active_construction", {})
	if String(next_project.get("building_type", "")) != "farm":
		failures.append("surplus_did_not_start_second_building")
	if absf(float(next_project.get("progress", -1.0)) - 6.0) > 0.01:
		failures.append("surplus_was_not_carried_into_second_building")
	province["rates"]["construction"] = 100.0
	ps._advance_active_construction(province)
	if not province.get("active_construction", {}).is_empty():
		failures.append("surplus_second_building_not_completed")
	if ps.get_typed_building_count(province, "club_factory", 1) < 1 or ps.get_typed_building_count(province, "farm", 1) < 1:
		failures.append("surplus_completion_missing_buildings")
	mock.free()


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

	var focus: Dictionary = _base_province()
	focus["id"] = 404
	focus["remaining_troops"] = 5
	focus["active_construction"] = {
		"project_type": "recruitment",
		"building_type": "",
		"target_tier": 1,
		"progress": 0.0,
		"required_progress": 1.0,
	}
	mock_main._province_persistence = [focus]
	ps.tick_all_province_economies(404)
	var focus_construction_rate: float = float(focus.get("rates", {}).get("construction", 0.0))
	var expected_focus_gain: int = int(floor((focus_construction_rate + 10.0) * 0.5 * ps._recruitment_condition_multiplier(focus)))
	var actual_focus_gain: int = int(focus.get("remaining_troops", 0)) - 5 - int(floor(float(focus.get("rates", {}).get("recruitment", 0.0))))
	if actual_focus_gain != expected_focus_gain:
		failures.append("recruitment_focus_conversion_%d_expected_%d" % [actual_focus_gain, expected_focus_gain])
	if not focus.get("active_construction", {}).is_empty():
		failures.append("recruitment_focus_not_one_turn")
	var enemy_control: Dictionary = enemy.duplicate(true)
	mock_main._province_persistence = [enemy_control]
	ps.tick_all_province_economies(-1)
	var enemy_expected_progress_after: float = float(enemy_control.get("active_construction", {}).get("progress", 0.0))
	mock_main._province_persistence = [landing, other, enemy]
	ps.tick_all_province_economies(403)
	var enemy_progress_after: float = float(enemy.get("active_construction", {}).get("progress", 0.0))
	if absf(enemy_progress_after - enemy_expected_progress_after) > 0.01:
		failures.append("enemy_landing_bonus_applied")


static func _check_tier_three_home_cave_global_troop_control(ps: Object, failures: Array[String]) -> void:
	var mock_main := MockMain.new()
	var states: Array[Dictionary] = []
	for province_id in range(801, 806):
		var province: Dictionary = _base_province()
		province["id"] = province_id
		province["neighbors"] = []
		if province_id > 801:
			province["neighbors"].append(province_id - 1)
		if province_id < 805:
			province["neighbors"].append(province_id + 1)
		states.append(province)
	mock_main._locked_province_id_after_win = 801
	mock_main.capital_id = 801
	mock_main._province_persistence = states
	ps.setup(mock_main)
	mock_main.province_system = ps
	for province in states:
		ps.normalize_province_economy_state(province)

	if not ps.can_player_control_troops_in_province(801) or ps.can_player_control_troops_in_province(802):
		failures.append("home_cave_t0_control_not_start_only")
	var home: Dictionary = states[0]
	home["buildings"]["home_cave"]["1"] = 1
	if not ps.can_player_control_troops_in_province(802) or ps.can_player_control_troops_in_province(803):
		failures.append("home_cave_t1_not_one_hop")
	home["buildings"]["home_cave"]["1"] = 0
	home["buildings"]["home_cave"]["2"] = 1
	if not ps.can_player_control_troops_in_province(803) or ps.can_player_control_troops_in_province(804):
		failures.append("home_cave_t2_not_two_hops")
	home["buildings"]["home_cave"]["2"] = 0
	home["buildings"]["home_cave"]["3"] = 1
	if not ps.can_player_control_troops_in_province(805):
		failures.append("home_cave_t3_not_global")
	if bool(ps.get_player_march_threshold_authority(801).get("can_set", true)):
		failures.append("home_cave_unexpected_march_threshold_bonus")
	var cave_effects: Dictionary = ps.calculate_building_effects(home)
	if float(cave_effects.get("construction", 0.0)) != 0.0:
		failures.append("home_cave_unexpected_construction_bonus")
	mock_main.locked_troop_province_id = 803
	if ps.get_player_troop_order_max_count(803) != 0:
		failures.append("reinforced_player_province_can_move")
	if bool(ps.validate_player_troop_order(803, 804, 4).get("ok", false)):
		failures.append("reinforced_player_troops_order_accepted")
	mock_main.locked_troop_province_id = -1
	if not bool(ps.validate_player_troop_order(803, 804, 4).get("ok", false)):
		failures.append("unlocked_remote_troop_order_rejected")
	mock_main.free()


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
	native_province["buildings"]["farm"]["3"] = 3
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
	enemy_province["construction_gold_reserve"] = 100
	enemy_province["id"] = 601
	enemy_province["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
	enemy_province["faction_id"] = LevelConfig.ENEMY_FACTION_DEFAULT
	enemy_province["neighbors"] = [501]
	mock_main._province_persistence = [player_province, enemy_province]
	local_ps.setup(mock_main)
	mock_main.province_system = local_ps
	var player_actions: Array = local_ps.build_province_construction_actions(501)
	for action_any in player_actions:
		if action_any is Dictionary and bool((action_any as Dictionary).get("recommended", false)):
			failures.append("recommended_build_menu_action_not_removed")

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
	var auto_queue: Array = auto_player.get("construction_queue", [])
	if auto_queue.is_empty():
		failures.append("player_auto_construction_queue_not_filled")
	if auto_queue.size() > 5:
		failures.append("player_auto_construction_queue_overfilled")
	for queued_any in auto_queue:
		if not (queued_any is Dictionary) or not bool((queued_any as Dictionary).get("automatic_recommendation", false)):
			failures.append("player_auto_construction_queue_lost_ai_marker")
			break

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

	var queued_player: Dictionary = (player_province as Dictionary).duplicate(true)
	queued_player["id"] = 703
	queued_player["population"] = {"natives": 0.0, "outlanders": 60.0}
	queued_player["construction_queue"] = [{
		"request_type": "build",
		"building_type": "club_factory",
		"tier": 1
	}]
	local_ps.normalize_province_economy_state(queued_player)
	var queued_result: Dictionary = local_ps.tick_province_economy(queued_player)
	var queued_project: Dictionary = queued_player.get("active_construction", {})
	if String(queued_result.get("player_auto_started_building", "")) != "club_factory":
		failures.append("player_manual_queue_not_reported")
	if String(queued_project.get("building_type", "")) != "club_factory":
		failures.append("player_manual_queue_not_prioritized")
	var remaining_orders: Array = queued_player.get("construction_queue", [])
	for pending_any in remaining_orders:
		if pending_any is Dictionary and not bool((pending_any as Dictionary).get("automatic_recommendation", false)):
			failures.append("player_manual_queue_not_consumed")
			break

	var queued_upgrade_player: Dictionary = (player_province as Dictionary).duplicate(true)
	queued_upgrade_player["id"] = 704
	queued_upgrade_player["construction_queue"] = [{
		"request_type": "upgrade",
		"building_type": "farm",
		"tier": 1
	}]
	local_ps.normalize_province_economy_state(queued_upgrade_player)
	local_ps.tick_province_economy(queued_upgrade_player)
	var queued_upgrade_project: Dictionary = queued_upgrade_player.get("active_construction", {})
	if String(queued_upgrade_project.get("project_type", "")) != "upgrade":
		failures.append("player_upgrade_queue_not_started")
	if String(queued_upgrade_project.get("building_type", "")) != "farm":
		failures.append("player_upgrade_queue_wrong_building")


static func _check_construction_forecast_temperance(ps: Object, failures: Array[String]) -> void:
	var local_ps: Object = _fresh_recommendation_system()
	var province: Dictionary = _normalized_recommendation_province(local_ps)
	local_ps.recalculate_province_derived_economy(province)
	var recommendation: Dictionary = local_ps.build_recommended_construction_order(province)
	if String(recommendation.get("reason", "")) == "Forecast native overcrowding":
		failures.append("forecast_default_native_overcrowding_too_active")
	if String(recommendation.get("building_type", "")) == "tenement":
		failures.append("forecast_default_tenement_overpreferred")


static func _check_paid_construction(ps: Object, failures: Array[String]) -> void:
	var mock := MockMain.new()
	mock.gold_balance = 3
	var province: Dictionary = _base_province()
	province["id"] = 9901
	mock._province_persistence = [province]
	var local_ps: Object = ProvinceSystemScript.new()
	local_ps.setup(mock)
	mock.province_system = local_ps
	local_ps.normalize_province_economy_state(province)
	if local_ps._start_construction_action(province, {"request_type": "build", "building_type": "catapult", "tier": 1}):
		failures.append("unaffordable_construction_allowed")
	if mock.gold_balance != 3:
		failures.append("failed_construction_charged_gold")
	mock.gold_balance = 50
	if not local_ps._start_construction_action(province, {"request_type": "build", "building_type": "catapult", "tier": 1}):
		failures.append("affordable_construction_denied")
	elif mock.gold_balance != 35:
		failures.append("construction_gold_not_charged_once")
	if not local_ps._start_construction_action(province, {"request_type": "build", "building_type": "farm", "tier": 1}) and mock.gold_balance != 35:
		failures.append("busy_project_charged_gold")
	mock.queue_free()


static func _check_recruitment_focus_queue(ps: Object, failures: Array[String]) -> void:
	var local_ps: Object = ProvinceSystemScript.new()
	var mock := MockMain.new()
	mock.gold_balance = 100
	var province: Dictionary = _base_province()
	province["id"] = 9902
	province["construction_queue"] = [{"request_type": "recruitment", "building_type": "", "tier": 1}]
	mock._province_persistence = [province]
	local_ps.setup(mock)
	mock.province_system = local_ps
	local_ps.normalize_province_economy_state(province)
	if local_ps.normalize_construction_queue(province["construction_queue"]).is_empty():
		failures.append("recruitment_queue_normalization_lost_order")
	local_ps._maybe_start_player_recommended_construction(province)
	if String((province.get("active_construction", {}) as Dictionary).get("project_type", "")) != "recruitment":
		failures.append("recruitment_queue_was_not_started")
	mock.queue_free()


static func _check_repair_persistence_and_combat_damage(ps: Object, failures: Array[String]) -> void:
	var local_ps: Object = ProvinceSystemScript.new()
	var original: Dictionary = _base_province()
	original["id"] = 9911
	original["construction_gold_reserve"] = 87
	local_ps.normalize_province_economy_state(original)
	if not local_ps.add_typed_building(original, "farm", 2):
		failures.append("repair_persistence_fixture_failed")
		return
	var count_before: int = local_ps.calculate_occupied_building_slots(original)
	local_ps.set_typed_building_count_ceiling(original, count_before - 1, true)
	var tickets: Array = original.get("repair_ledger", [])
	if tickets.is_empty():
		failures.append("combat_did_not_record_repairable_building")
	var copied: Dictionary = {}
	local_ps._copy_economy_fields_to_dictionary(original, copied)
	if int(copied.get("construction_gold_reserve", 0)) != 87:
		failures.append("npc_gold_reserve_lost_during_copy")
	if (copied.get("repair_ledger", []) as Array).size() != tickets.size():
		failures.append("repair_tickets_lost_during_copy")
	local_ps.normalize_province_economy_state(copied)
	if not local_ps.start_building_repair_construction(copied):
		failures.append("combat_damage_cannot_start_repair_after_copy")
	else:
		copied["rates"]["construction"] = 1000.0
		local_ps._advance_active_construction(copied)
		if local_ps.calculate_occupied_building_slots(copied) != count_before:
			failures.append("combat_repair_did_not_rebuild_structure")
	if not (copied.get("repair_ledger", []) as Array).is_empty():
		failures.append("repaired_combat_ticket_not_cleared")
	var destroyed: Dictionary = original.duplicate(true)
	local_ps.clear_typed_buildings(destroyed)
	if local_ps.start_building_repair_construction(destroyed):
		failures.append("destroyed_buildings_could_be_repaired")
	var irreversible: Dictionary = original.duplicate(true)
	local_ps.set_typed_building_count_ceiling(irreversible, count_before - 2, false)
	if (irreversible.get("repair_ledger", []) as Array).size() > tickets.size():
		failures.append("permanent_destruction_created_repair_ticket")


static func _check_queue_spending_and_affordable_fallback(ps: Object, failures: Array[String]) -> void:
	var local_ps: Object = ProvinceSystemScript.new()
	var mock := MockMain.new()
	mock.gold_balance = 4
	var province: Dictionary = _base_province()
	province["id"] = 9920
	province["construction_queue"] = [{"request_type": "build", "building_type": "farm", "tier": 1}]
	mock._province_persistence = [province]
	local_ps.setup(mock)
	mock.province_system = local_ps
	local_ps.normalize_province_economy_state(province)
	local_ps._maybe_start_player_recommended_construction(province)
	if String(province.get("active_construction", {}).get("building_type", "")) != "farm":
		failures.append("player_manual_queue_blocked_by_auto_reserve")
	if mock.gold_balance != 1:
		failures.append("player_manual_queue_not_charged")
	mock.gold_balance = 28
	province["active_construction"] = {}
	province["construction_queue"] = []
	var actions: Array[Dictionary] = [
		{"request_type": "build", "building_type": "home_cave", "tier": 1},
		{"request_type": "build", "building_type": "farm", "tier": 1}
	]
	var alternative: Dictionary = local_ps.build_recommended_construction_order(province, actions, true)
	if String(alternative.get("building_type", "")) != "farm":
		failures.append("ai_did_not_select_affordable_fallback")
	mock.queue_free()


static func _check_performance_cache_invalidation(failures: Array[String]) -> void:
	var cache_ps: Object = ProvinceSystemScript.new()
	var mock := MockMain.new()
	mock._province_persistence = [{"id": 3}, {"id": 7}]
	cache_ps.setup(mock)
	if cache_ps.find_persistence_index_by_id(7) != 1:
		failures.append("cache_initial_id_lookup")
	mock._province_persistence = [{"id": 7}, {"id": 3}]
	cache_ps.invalidate_persistence_index_cache()
	if cache_ps.find_persistence_index_by_id(7) != 0:
		failures.append("cache_reordered_id_lookup")
	mock._province_persistence.clear()
	cache_ps.invalidate_persistence_index_cache()
	if cache_ps.find_persistence_index_by_id(7) != -1:
		failures.append("cache_cleared_id_lookup")
	var province_node := Node2D.new()
	var first_poly := PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)])
	var second_poly := PackedVector2Array([Vector2(300, 0), Vector2(400, 0), Vector2(400, 100), Vector2(300, 100)])
	var first_center: Vector2 = cache_ps._get_cached_polygon_label_center(province_node, first_poly, Vector2.ZERO)
	var same_center: Vector2 = cache_ps._get_cached_polygon_label_center(province_node, first_poly, Vector2.ZERO)
	var moved_center: Vector2 = cache_ps._get_cached_polygon_label_center(province_node, second_poly, Vector2.ZERO)
	if first_center != same_center or moved_center.x <= 200.0:
		failures.append("cache_label_geometry_invalidation")
	province_node.free()
	mock.free()


# Rendering regression: unchanged troop counts/placement, one textured draw
# batch per province, safe reuse across troop losses and replenishment.
static func _check_cached_troop_rendering(failures: Array[String]) -> void:
	var ps: Object = ProvinceSystemScript.new()
	var mock := MockMain.new()
	ps.setup(mock)
	var province := Node2D.new()
	province.name = "Province_17"
	province.set_meta("province_data", {"id": 17})
	var fill := Polygon2D.new()
	fill.name = "ProvinceFill"
	fill.polygon = PackedVector2Array([Vector2(0, 0), Vector2(200, 0), Vector2(200, 200), Vector2(0, 200)])
	province.add_child(fill)
	mock.provinces_root.add_child(province)
	var color := Color(0.8, 0.3, 0.2, 1.0)
	ps._layout_province_troop_visuals(province, {"remaining_troops": 7}, color)
	var root: Node = province.get_node_or_null("ProvinceTroopVisuals")
	var batch: MultiMeshInstance2D = root.get_node_or_null("ProvinceTroopBatch") as MultiMeshInstance2D if root != null else null
	if batch == null or batch.multimesh == null or batch.texture == null:
		failures.append("cached_troops_missing_texture_or_batch")
	else:
		if root.get_child_count() != 1 or batch.multimesh.instance_count != 7:
			failures.append("cached_troops_instancing_count")
		var material: ShaderMaterial = batch.material as ShaderMaterial
		if material == null or material.shader == null:
			failures.append("cached_troops_missing_shader")
		var first_position: Vector2 = batch.multimesh.get_instance_transform_2d(0).origin
		ps._layout_province_troop_visuals(province, {"remaining_troops": 7}, color)
		if batch.multimesh.get_instance_transform_2d(0).origin != first_position:
			failures.append("cached_troops_unstable_position")
		ps._layout_province_troop_visuals(province, {"remaining_troops": 0}, color)
		if batch.multimesh.instance_count != 0:
			failures.append("cached_troops_not_cleared")
		ps._layout_province_troop_visuals(province, {"remaining_troops": 4}, color)
		if batch.multimesh.instance_count != 4 or root.get_child_count() != 1:
			failures.append("cached_troops_not_restored")
	mock.provinces_root.free()
	mock.free()


static func _check_imported_sprite_region_cache(failures: Array[String]) -> void:
	# A transparent imported resource must yield the same cropped region as
	# the old source-PNG path, including repeat calls through the shared cache.
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in range(2, 4):
		for y in range(3, 5):
			image.set_pixel(x, y, Color.WHITE)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var expected := Rect2(Vector2(2, 3), Vector2(2, 2))
	var first: Rect2 = SpriteRegionCache.visible_region(texture)
	var second: Rect2 = SpriteRegionCache.visible_region(texture)
	if first != expected or second != expected:
		failures.append("imported_texture_crop_region_incorrect")
	var blank := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	blank.fill(Color.TRANSPARENT)
	var blank_texture: ImageTexture = ImageTexture.create_from_image(blank)
	if SpriteRegionCache.visible_region(blank_texture) != Rect2(Vector2.ZERO, Vector2(4, 4)):
		failures.append("imported_texture_blank_fallback_incorrect")



# Regression for the transient per-unit battle visualization. The permanent
# map intentionally uses MultiMesh, but automated turn previews must still be
# able to create, animate and eliminate troops and buildings individually.
static func _check_automated_battle_preview_icons(failures: Array[String]) -> void:
	var ps: Object = ProvinceSystemScript.new()
	if not ps.has_method("_make_troop_visual_icon") or not ps.has_method("_make_building_visual_icon"):
		failures.append("automated_preview_icon_factory_missing")
		return
	var overlay := Node2D.new()
	var units: Array[Node2D] = []
	var buildings: Array[Node2D] = []
	for i in range(5):
		var icon: Node2D = ps.call("_make_troop_visual_icon") as Node2D
		if icon == null or not icon.has_method("update_visual"):
			failures.append("automated_preview_troop_icon_not_drawable")
			continue
		var size_value: float = float(icon.get("icon_size"))
		icon.call("update_visual", size_value, Color(0.4, 0.8, 0.3, 1.0), 0.9)
		overlay.add_child(icon)
		icon.position = Vector2(i * 10.0, 22.0)
		units.append(icon)
	for i in range(3):
		var icon: Node2D = ps.call("_make_building_visual_icon") as Node2D
		if icon == null or not icon.has_method("update_visual"):
			failures.append("automated_preview_building_icon_not_drawable")
			continue
		overlay.add_child(icon)
		icon.position = Vector2(i * 15.0, -10.0)
		buildings.append(icon)
	if units.size() != 5 or buildings.size() != 3 or overlay.get_child_count() != 8:
		failures.append("automated_preview_icon_counts")
	else:
		# Preview tweens modify positions and kill units independently.
		units[0].position.x += 28.0
		if absf(units[0].position.x - 28.0) > 0.001:
			failures.append("automated_preview_unit_motion")
		for icon in units:
			overlay.remove_child(icon)
			icon.free()
		if overlay.get_child_count() != 3:
			failures.append("automated_preview_individual_troop_losses")
		for icon in buildings:
			overlay.remove_child(icon)
			icon.free()
		if overlay.get_child_count() != 0:
			failures.append("automated_preview_individual_building_losses")
	overlay.free()
