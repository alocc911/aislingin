extends RefCounted
class_name OwnershipSemanticsSelfTest

# Lightweight matrix-oriented checks for ownership semantics invariants.
# These checks are designed to be called from debug tooling or ad hoc scripts.

static func run(province_system: ProvinceSystem) -> Dictionary:
	var failures: Array[String] = []
	if province_system == null:
		failures.append("province_system_missing")
		return {"ok": false, "failures": failures}

	_check_owner_normalization(province_system, failures)
	_check_relation_routing(province_system, failures)
	_check_ui_owner_text_semantics(province_system, failures)

	return {
		"ok": failures.is_empty(),
		"failures": failures,
	}


static func _check_owner_normalization(province_system: ProvinceSystem, failures: Array[String]) -> void:
	# Defensive collapse outcome expectation: hostile owner cannot be friendly-boss faction.
	var hostile_input: Dictionary = {"type": LevelConfig.PROVINCE_TYPE_ENEMY, "faction_id": 0}
	var hostile_result: Dictionary = province_system.normalize_owner_fields(hostile_input)
	if String(hostile_result.get("type", "")) != LevelConfig.PROVINCE_TYPE_ENEMY:
		failures.append("normalize_hostile_type")

	# Friendly ownership should clear neutral faction id values.
	var friendly_input: Dictionary = {"type": LevelConfig.PROVINCE_TYPE_FRIENDLY, "faction_id": 0}
	var friendly_result: Dictionary = province_system.normalize_owner_fields(friendly_input)
	if int(friendly_result.get("faction_id", 0)) != 0:
		failures.append("normalize_friendly_faction_zero")

	# Neutral ownership must stay faction zero.
	var neutral_input: Dictionary = {"type": LevelConfig.PROVINCE_TYPE_NEUTRAL, "faction_id": 99}
	var neutral_result: Dictionary = province_system.normalize_owner_fields(neutral_input)
	if int(neutral_result.get("faction_id", 0)) != 0:
		failures.append("normalize_neutral_faction_zero")


static func _check_relation_routing(province_system: ProvinceSystem, failures: Array[String]) -> void:
	var self_relation: String = province_system.get_relation_to_player(LevelConfig.PROVINCE_TYPE_FRIENDLY, 0)
	if self_relation != ProvinceSystem.RELATION_SELF:
		failures.append("relation_self")

	var hostile_relation: String = province_system.get_relation_to_player(LevelConfig.PROVINCE_TYPE_ENEMY, 0)
	if hostile_relation != ProvinceSystem.RELATION_HOSTILE:
		failures.append("relation_hostile")

	var neutral_relation: String = province_system.get_relation_to_player(LevelConfig.PROVINCE_TYPE_NEUTRAL, 0)
	if neutral_relation != ProvinceSystem.RELATION_NEUTRAL:
		failures.append("relation_neutral")


static func _check_ui_owner_text_semantics(province_system: ProvinceSystem, failures: Array[String]) -> void:
	var hostile_label: String = province_system.get_province_owner_text({"type": LevelConfig.PROVINCE_TYPE_ENEMY, "faction_id": 2})
	if hostile_label.strip_edges().is_empty() or hostile_label.to_lower().find("ally") != -1:
		failures.append("ui_hostile_label")

	var friendly_label: String = province_system.get_province_owner_text({"type": LevelConfig.PROVINCE_TYPE_FRIENDLY, "faction_id": 0})
	if friendly_label != "Friendly":
		failures.append("ui_friendly_label")
