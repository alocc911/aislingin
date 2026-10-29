extends SceneTree

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const EngagementResolverScript = preload("res://scripts/EngagementResolver.gd")
const EnemyTurnSystemScript = preload("res://scripts/EnemyTurnSystem.gd")

class MockMain extends Node:
	const INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT: int = 3
	var _province_persistence: Array[Dictionary] = []
	var province_system = null
	var boss_system = null
	var gold_balance: int = 0
	var level_index: int = 1
	func _is_milestone(_level: int) -> bool:
		return false

func _initialize() -> void:
	call_deferred("_run")

func _expect(label: String, condition: bool, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)

func _state(ps, province_id: int, province_type: String, troops: int, typed_buildings: Dictionary, faction: int = 0) -> Dictionary:
	var state: Dictionary = {
		"id": province_id,
		"type": province_type,
		"faction_id": faction,
		"remaining_troops": troops,
		"remaining_buildings": 0,
		"building_capacity": 40,
		"neighbors": [],
		"invading_troops": 0,
		"is_boss_home": false
	}
	ps.normalize_province_economy_state(state)
	ps.clear_typed_buildings(state)
	state["buildings"] = ps.normalize_typed_buildings(typed_buildings)
	ps.recalculate_province_derived_economy(state)
	ps.sync_legacy_building_count_from_typed(state)
	return state

func _run() -> void:
	var failures: Array[String] = []
	var main := MockMain.new()
	var ps = ProvinceSystemScript.new()
	main.province_system = ps
	ps.setup(main)
	var resolver = EngagementResolverScript.new()
	resolver.setup(main)
	var marcher = EnemyTurnSystemScript.new()
	marcher.setup(main)

	# The original reproduced bug: economic buildings cannot turn an even
	# 75-versus-75 engagement into 45 surviving defenders.
	var enemy: Dictionary = _state(ps, 11, LevelConfig.PROVINCE_TYPE_ENEMY, 75, {"farm": {"1": 15}}, 100)
	main._province_persistence = [enemy]
	_expect("15_economic_buildings", int(enemy["remaining_buildings"]) == 15, failures)
	var inputs: Dictionary = {
		"player_participating": false,
		"troops_A": 75, "troops_B": 75,
		"buildings_A": 0, "buildings_B": 15,
		"province_id": 11,
		"attacker_type": LevelConfig.PROVINCE_TYPE_FRIENDLY
	}
	var result: Dictionary = resolver.resolve_engagement(inputs)
	var combat: Dictionary = result.get("combat_result", {})
	_expect("75_vs_75_defenders", int(result.get("final_troops_B", -1)) == 0, failures)
	_expect("75_vs_75_attackers", int(result.get("final_troops_A", -1)) == 0, failures)
	_expect("75_vs_75_buildings", int(result.get("final_buildings_B", -1)) == 15, failures)
	_expect("75_vs_75_no_capture", not bool(result.get("conquered", true)), failures)
	_expect("75_vs_75_combat_preview_data", int(combat.get("defenders_remaining", -1)) == 0 and int(combat.get("building_damage", -1)) == 0, failures)
	var estimate: Dictionary = marcher._build_march_estimate_diagnostic(enemy, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, 75, 75)
	_expect("75_vs_75_planner_matches", bool(estimate.get("estimated_will_clear_troops", false)) and not bool(estimate.get("estimated_will_conquer", true)) and int(estimate.get("survivors_after_troops", -1)) == 0, failures)

	# One-for-one combat, then one building per three surplus attackers.
	for values in [
		[70, 75, 15, 5, 15, false],
		[90, 75, 15, 0, 10, false],
		[120, 75, 15, 0, 0, true],
		[76, 75, 0, 0, 0, true],
		[75, 75, 0, 0, 0, false]
	]:
		var attack: int = int(values[0])
		var defending: int = int(values[1])
		var buildings: int = int(values[2])
		var predicted: Dictionary = EngagementResolverScript.calculate_automated_combat(attack, defending, 0, buildings, 3)
		_expect("combat_troops_%d_%d_%d" % [attack, defending, buildings], int(predicted["defenders_remaining"]) == int(values[3]), failures)
		_expect("combat_buildings_%d_%d_%d" % [attack, defending, buildings], int(predicted["buildings_remaining"]) == int(values[4]), failures)
		_expect("combat_capture_%d_%d_%d" % [attack, defending, buildings], bool(predicted["conquered"]) == bool(values[5]), failures)

	# A destroyed trap factory must cease providing defense BEFORE the
	# automatic follow-up fight and must be the structure persisted as lost.
	var friendly: Dictionary = _state(ps, 12, LevelConfig.PROVINCE_TYPE_FRIENDLY, 4, {"trap_factory": {"1": 2}, "farm": {"1": 3}})
	main._province_persistence = [friendly]
	var trap_losses: Array[Dictionary] = [
		{"building_type": "trap_factory", "tier": 1},
		{"building_type": "trap_factory", "tier": 1}
	]
	_expect("defense_trap_before", ps.get_province_defense_strength(friendly) > 0, failures)
	_expect("defense_trap_after_destroyed", ps.get_defense_strength_after_specific_building_losses(friendly, trap_losses) == 0, failures)
	var defensive_result: Dictionary = resolver.resolve_engagement({
		"player_participating": true,
		"troops_A": 0, "troops_B": 8,
		"buildings_A": 0, "buildings_B": 5,
		"player_downed_troops": 2,
		"player_destroyed_buildings": 2,
		"player_destroyed_building_entries": trap_losses,
		"province_id": 12
	})
	_expect("defensive_combat_hold", not bool(defensive_result.get("conquered", true)), failures)
	_expect("defensive_surviving_garrison", int(defensive_result.get("final_resident_troops", -1)) == 0, failures)
	_expect("defensive_building_count", int(defensive_result.get("final_buildings_B", -1)) == 3, failures)
	_expect("defensive_no_pending_invaders", int(defensive_result.get("final_invading_troops", -1)) == 0, failures)
	var copy: Dictionary = friendly.duplicate(true)
	ps.apply_specific_combat_building_losses(copy, trap_losses, true)
	_expect("destroyed_traps_persist", ps.get_typed_building_count(copy, "trap_factory") == 0, failures)
	_expect("farms_remain", ps.get_typed_building_count(copy, "farm") == 3, failures)
	_expect("repair_ledger_for_traps", (copy.get("repair_ledger", []) as Array).size() == 2, failures)
	var post_building_pred: Dictionary = EngagementResolverScript.calculate_automated_combat(6, 4, 0, 3, 3)
	_expect("player_vs_auto_same_followup", int(post_building_pred["defenders_remaining"]) == int(defensive_result["final_resident_troops"]) and int(post_building_pred["buildings_remaining"]) == int(defensive_result["final_buildings_B"]), failures)

	# Defensive structures remove attackers first, but do not protect
	# defenders with a second generic building-count bonus.
	var with_traps: Dictionary = EngagementResolverScript.calculate_automated_combat(20, 10, 3, 5, 3)
	_expect("explicit_strength", int(with_traps["defense_strength_losses"]) == 3 and int(with_traps["attackers_remaining"]) == 7 and int(with_traps["buildings_remaining"]) == 3, failures)
	main.free()
	var report: Dictionary = {"ok": failures.is_empty(), "failures": failures}
	print("COMBAT_CONSISTENCY_TEST: ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
