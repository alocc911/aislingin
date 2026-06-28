extends RefCounted
class_name ProvinceOverhaulSelfTest

const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const LevelConfig = preload("res://scripts/LevelConfig.gd")


static func run(province_system: Object = null) -> Dictionary:
	var failures: Array[String] = []
	var ps: Object = province_system
	if ps == null:
		ps = ProvinceSystemScript.new()

	_check_normalization(ps, failures)
	_check_food_and_accommodation(ps, failures)
	_check_building_validation(ps, failures)
	_check_revolution(ps, failures)
	_check_repair_completion(ps, failures)
	_check_income_and_building_effects(ps, failures)

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
	if not ps.add_typed_building(province, "food_maker", 1):
		failures.append("food_maker_add_failed")
	var food_after: float = float(province.get("food", {}).get("surplus", 0.0))
	if food_after <= food_before:
		failures.append("food_surplus_not_responsive")
	if float(province.get("accommodation", {}).get("native_ceiling", 0.0)) <= 0.0:
		failures.append("native_accommodation_not_seeded")


static func _check_building_validation(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	if not ps.add_typed_building(province, "command_center", 1):
		failures.append("command_center_first_add_failed")
	if ps.add_typed_building(province, "command_center", 1):
		failures.append("command_center_duplicate_allowed")
	if not ps.province_has_command_center(province):
		failures.append("command_center_presence_helper_failed")


static func _check_revolution(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	province["happiness"]["natives"] = 0.0
	var result: Dictionary = ps.tick_province_economy(province)
	if not bool(result.get("revolted", false)):
		failures.append("revolution_not_triggered")
	if String(province.get("type", "")) != LevelConfig.PROVINCE_TYPE_ENEMY:
		failures.append("revolution_owner_not_enemy")
	if int(province.get("faction_id", 0)) != 9000:
		failures.append("revolution_faction_not_rebel")


static func _check_repair_completion(ps: Object, failures: Array[String]) -> void:
	var province: Dictionary = _base_province()
	ps.normalize_province_economy_state(province)
	var before_t1: int = int(ps.get_typed_building_count(province, "food_maker", 1))
	if not ps.start_building_repair_construction(province):
		failures.append("repair_start_failed")
	province["rates"]["construction"] = 999.0
	ps._advance_active_construction(province)
	var after_t1: int = int(ps.get_typed_building_count(province, "food_maker", 1))
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
	ps.add_typed_building(province, "defense_nest", 1)
	ps.add_typed_building(province, "catapult", 1)
	if int(ps.get_province_defense_strength(province)) <= 0:
		failures.append("defense_strength_missing")
	if int(ps.get_province_catapult_adjacent_damage(province)) <= 0:
		failures.append("catapult_damage_missing")
