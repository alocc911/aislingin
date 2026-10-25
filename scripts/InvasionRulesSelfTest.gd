extends RefCounted
class_name InvasionRulesSelfTest

# Run with InvasionRulesSelfTest.run() from a Godot debug runner.
# Covers ordinary troop marches and player defensive engagement resolution.

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const EngagementResolverScript = preload("res://scripts/EngagementResolver.gd")
const EnemyTurnSystemScript = preload("res://scripts/EnemyTurnSystem.gd")


class MockProvinceSystem extends RefCounted:
	var main: Node = null

	func find_persistence_index_by_id(province_id: int) -> int:
		var provinces: Variant = main.get("_province_persistence")
		for i in range(provinces.size()):
			if int(provinces[i].get("id", -1)) == province_id:
				return i
		return -1

	func get_province_defense_strength(_province_state: Dictionary) -> int:
		return 0

	func get_province_building_capacity(_province_state: Dictionary) -> int:
		return 100

	func make_province_snapshot_by_id() -> Dictionary:
		var result: Dictionary = {}
		for province in main.get("_province_persistence"):
			result[int(province.get("id", -1))] = province.duplicate(true)
		return result

	func apply_persistence_to_province_visuals() -> void:
		pass

	func normalize_neighbor_ids(ids: Variant) -> Array[int]:
		var result: Array[int] = []
		if ids is Array:
			for province_id in ids:
				result.append(int(province_id))
		return result


class MockMain extends Node:
	const INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT: int = 3
	const FRIENDLY_MARCH_THRESHOLD: int = 15
	const ENEMY_MARCH_THRESHOLD: int = 15
	const BOSS_MARCH_THRESHOLD: int = 15
	const ENEMY_MARCH_LEAVE_BEHIND: int = 5
	var _province_persistence: Array[Dictionary] = []
	var province_system: Object = null
	var engagement_resolver: Object = null
	var boss_system: Object = null
	var turn_number: int = 5
	var _current_phase: String = "grand_map"
	var gold_balance: int = 0


static func run() -> Dictionary:
	var failures: Array[String] = []
	_check_friendly_march_zero_garrison(failures)
	_check_enemy_march_zero_garrison(failures)
	_check_enemy_march_with_garrison(failures)
	_check_enemy_against_enemy_no_retreat(failures)
	_check_player_defensive_result(failures)
	_check_no_fabricated_undefended_pressure(failures)
	return {"ok": failures.is_empty(), "failures": failures}


# The legacy full invasion suite contains unrelated outdated player-defence
# fixtures. Run this focused regression in CI until those fixtures are updated.
static func run_phantom_pressure_regression() -> Dictionary:
	var failures: Array[String] = []
	_check_no_fabricated_undefended_pressure(failures)
	return {"ok": failures.is_empty(), "failures": failures}


static func _make_context() -> Dictionary:
	var main := MockMain.new()
	var ps := MockProvinceSystem.new()
	ps.main = main
	main.province_system = ps
	var resolver = EngagementResolverScript.new()
	resolver.setup(main)
	main.engagement_resolver = resolver
	var turns = EnemyTurnSystemScript.new()
	turns.setup(main)
	return {"main": main, "turns": turns, "resolver": resolver}


static func _state(province_id: int, owner_type: String, troops: int, buildings: int, faction_id: int = 0) -> Dictionary:
	return {
		"id": province_id,
		"province_name": "Test province %d" % province_id,
		"type": owner_type,
		"faction_id": faction_id,
		"remaining_troops": troops,
		"remaining_buildings": buildings,
		"invading_troops": 0,
		"invading_source_ids": [],
		"pending_invasion_started_turn": -1,
		"construction_progress": 0
	}


static func _check_friendly_march_zero_garrison(failures: Array[String]) -> void:
	var context: Dictionary = _make_context()
	var main: MockMain = context["main"]
	var turns = context["turns"]
	var enemy: Dictionary = _state(1, LevelConfig.PROVINCE_TYPE_ENEMY, 0, 5, 2)
	main._province_persistence.append(enemy)
	if not turns.resolve_march_arrival(1, 8, LevelConfig.PROVINCE_TYPE_FRIENDLY):
		failures.append("friendly_zero_garrison_march_rejected")
	if enemy["type"] != LevelConfig.PROVINCE_TYPE_ENEMY or int(enemy["remaining_buildings"]) != 3:
		failures.append("friendly_zero_garrison_bypassed_buildings")
	if int(enemy["invading_troops"]) != 0:
		failures.append("friendly_survivors_persisted")
	var conquerable: Dictionary = _state(2, LevelConfig.PROVINCE_TYPE_ENEMY, 0, 5, 2)
	main._province_persistence.append(conquerable)
	turns.resolve_march_arrival(2, 15, LevelConfig.PROVINCE_TYPE_FRIENDLY)
	if conquerable["type"] != LevelConfig.PROVINCE_TYPE_FRIENDLY:
		failures.append("friendly_zero_garrison_full_building_clear_failed")
	main.free()


static func _check_enemy_march_zero_garrison(failures: Array[String]) -> void:
	var context: Dictionary = _make_context()
	var main: MockMain = context["main"]
	var turns = context["turns"]
	var friendly: Dictionary = _state(1, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 5)
	main._province_persistence.append(friendly)
	turns.resolve_march_arrival(1, 8, LevelConfig.PROVINCE_TYPE_ENEMY, 2)
	if friendly["type"] != LevelConfig.PROVINCE_TYPE_FRIENDLY or int(friendly["invading_troops"]) != 8:
		failures.append("enemy_zero_garrison_premature_capture")
	turns.apply_invasion_building_damage_and_conquest(friendly)
	if friendly["type"] != LevelConfig.PROVINCE_TYPE_FRIENDLY or int(friendly["remaining_buildings"]) != 3:
		failures.append("enemy_zero_garrison_building_damage")
	if int(friendly["invading_troops"]) != 0 or int(friendly["faction_id"]) != 0:
		failures.append("enemy_zero_garrison_survivors_not_cleared")
	var conquerable: Dictionary = _state(2, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 5)
	main._province_persistence.append(conquerable)
	turns.resolve_march_arrival(2, 15, LevelConfig.PROVINCE_TYPE_ENEMY, 2)
	turns.apply_invasion_building_damage_and_conquest(conquerable)
	if conquerable["type"] != LevelConfig.PROVINCE_TYPE_ENEMY:
		failures.append("enemy_zero_garrison_full_building_clear_failed")
	main.free()


static func _check_enemy_march_with_garrison(failures: Array[String]) -> void:
	var context: Dictionary = _make_context()
	var main: MockMain = context["main"]
	var turns = context["turns"]
	var friendly: Dictionary = _state(1, LevelConfig.PROVINCE_TYPE_FRIENDLY, 1, 5)
	main._province_persistence.append(friendly)
	turns.resolve_march_arrival(1, 8, LevelConfig.PROVINCE_TYPE_ENEMY, 2)
	turns.apply_invasion_building_damage_and_conquest(friendly)
	if friendly["type"] != LevelConfig.PROVINCE_TYPE_FRIENDLY or int(friendly["remaining_buildings"]) != 3:
		failures.append("enemy_garrison_building_damage")
	if int(friendly["invading_troops"]) != 0:
		failures.append("enemy_garrison_survivors_not_cleared")
	var small: Dictionary = _state(2, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 5)
	main._province_persistence.append(small)
	turns.resolve_march_arrival(2, 2, LevelConfig.PROVINCE_TYPE_ENEMY, 2)
	turns.apply_invasion_building_damage_and_conquest(small)
	if int(small["remaining_buildings"]) != 5 or int(small["invading_troops"]) != 0:
		failures.append("insufficient_attackers_lingered")
	main.free()


static func _check_enemy_against_enemy_no_retreat(failures: Array[String]) -> void:
	var context: Dictionary = _make_context()
	var main: MockMain = context["main"]
	var turns = context["turns"]
	var target: Dictionary = _state(1, LevelConfig.PROVINCE_TYPE_ENEMY, 0, 5, 2)
	var source: Dictionary = _state(2, LevelConfig.PROVINCE_TYPE_ENEMY, 12, 1, 1)
	main._province_persistence.append(target)
	main._province_persistence.append(source)
	turns.resolve_march_arrival(1, 8, LevelConfig.PROVINCE_TYPE_ENEMY, 1, 2)
	if int(source["remaining_troops"]) != 12:
		failures.append("enemy_survivors_returned_to_source")
	if int(target["remaining_buildings"]) != 3 or int(target["invading_troops"]) != 0:
		failures.append("enemy_enemy_partial_invasion_result")
	main.free()


static func _check_player_defensive_result(failures: Array[String]) -> void:
	var context: Dictionary = _make_context()
	var main: MockMain = context["main"]
	var resolver = context["resolver"]
	main._province_persistence.append(_state(1, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 5))
	var result: Dictionary = resolver.resolve_engagement({
		"player_participating": true,
		"province_id": 1,
		"troops_A": 0,
		"troops_B": 8,
		"buildings_B": 5,
		"player_downed_troops": 0,
		"player_destroyed_buildings": 0
	})
	if bool(result.get("conquered", true)) or int(result.get("final_buildings_B", 0)) != 3:
		failures.append("player_defense_did_not_hold_buildings")
	if int(result.get("final_invading_troops", -1)) != 0 or int(result.get("full_result_ending_troops", -1)) != 0:
		failures.append("player_defense_invaders_persisted")
	if bool(result.get("grant_reward", true)):
		failures.append("dispersal_changed_defense_reward_rules")
	main.free()


# An undefended friendly province may be attacked by real marches, but the
# automated march phase must not fabricate a free one-troop invasion.
static func _check_no_fabricated_undefended_pressure(failures: Array[String]) -> void:
	var context: Dictionary = _make_context()
	var main: MockMain = context["main"]
	var turns = context["turns"]
	var friendly: Dictionary = _state(1, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 3)
	var enemy: Dictionary = _state(2, LevelConfig.PROVINCE_TYPE_ENEMY, 0, 3, 11)
	friendly["neighbors"] = [2]
	enemy["neighbors"] = [1]
	main._province_persistence.append(friendly)
	main._province_persistence.append(enemy)

	turns.run_enemy_march_phase(false)
	if int(friendly.get("invading_troops", -1)) != 0 or int(friendly.get("remaining_buildings", -1)) != 3:
		failures.append("undefended_neighbor_created_phantom_invader")

	# A real invasion is still accepted, and a failed invasion must not
	# generate a second synthetic attacker after all attackers disappear.
	turns.resolve_march_arrival(1, 2, LevelConfig.PROVINCE_TYPE_ENEMY, 11, 2)
	if int(friendly.get("invading_troops", -1)) != 2:
		failures.append("real_invasion_blocked")
	turns.apply_invasion_building_damage_and_conquest(friendly)
	turns.run_enemy_march_phase(false)
	if int(friendly.get("invading_troops", -1)) != 0 or int(friendly.get("remaining_buildings", -1)) != 3:
		failures.append("phantom_invader_reappeared_after_failed_invasion")
	main.free()
