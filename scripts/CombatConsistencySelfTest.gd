extends SceneTree

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const EngagementResolverScript = preload("res://scripts/EngagementResolver.gd")
const EnemyTurnSystemScript = preload("res://scripts/EnemyTurnSystem.gd")
const BossSystemScript = preload("res://scripts/BossSystem.gd")

class MockMain extends Node:
	const INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT: int = 3
	var _province_persistence: Array[Dictionary] = []
	var province_system = null
	var boss_system = null
	var gold_balance: int = 0
	var level_index: int = 1
	var map_seed: int = 1
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
	ps._rebuild_persistence_index_cache()
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
	# Friendly boss and normal garrison share the province display, but their
	# casualty pools must remain separate. Reproduce garrison-first combat.
	var boss_main := MockMain.new()
	var boss_system = BossSystemScript.new()
	boss_main.boss_system = boss_system
	boss_system.setup(boss_main)
	var boss_state: Dictionary = boss_system._make_default_single_boss_state(5, BossSystemScript.FRIENDLY_BOSS_FACTION_ID, 15, [])
	boss_state["active"] = true
	boss_state["dead"] = false
	boss_state["is_friendly_boss"] = true
	boss_state["current_province_id"] = 15
	boss_system.set_runtime_state({"bosses": [boss_state], "primary_boss_id": 5, "next_boss_id": 6})
	var core: int = boss_system.get_boss_home_troop_count(5)
	var shared: Dictionary = {
		"id": 15, "type": LevelConfig.PROVINCE_TYPE_FRIENDLY, "faction_id": 199,
		"remaining_troops": core + 30, "friendly_boss_base_troops": 30,
		"friendly_boss_resident_id": 5, "is_boss_home": true
	}
	boss_main._province_persistence = [shared]
	var first_loss: Dictionary = boss_system.apply_friendly_boss_shared_troop_result(shared, core + 30, core + 10)
	_expect("boss_garrison_first_20", int(first_loss.get("garrison_after", -1)) == 10 and int(first_loss.get("boss_after", -1)) == core, failures)
	_expect("boss_no_head_hits_from_garrison", int(boss_system.get_part_hit_count("head", 5)) == 0, failures)
	var second_loss: Dictionary = boss_system.apply_friendly_boss_shared_troop_result(shared, core + 10, core - 15)
	_expect("boss_excess_15_from_core", int(second_loss.get("garrison_after", -1)) == 0 and int(second_loss.get("boss_after", -1)) == core - 15, failures)
	_expect("boss_survives_partial_losses", boss_system.is_boss_active(5) and int(boss_system.get_part_hit_count("head", 5)) == 0, failures)
	var final_loss: Dictionary = boss_system.apply_friendly_boss_shared_troop_result(shared, core - 15, 0)
	_expect("boss_core_zero_defeat", bool(final_loss.get("boss_died", false)) and boss_system.is_boss_dead(5), failures)
	_expect("boss_death_preserves_home_ownership", String(shared.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY and int(shared.get("faction_id", -1)) == 199 and int(shared.get("friendly_boss_resident_id", -1)) == -1, failures)
	_expect("boss_death_does_not_call_enemy_conquest", int(shared.get("remaining_troops", -1)) == 0 and not bool(shared.get("is_boss_home", true)), failures)
	# Independently moving friendly boss troops suffer direct nonlethal troop
	# losses rather than seven accidental head hits for 46 casualties.
	boss_system.set_runtime_state({"bosses": [boss_state], "primary_boss_id": 5, "next_boss_id": 6})
	var attack_core_before: int = boss_system.get_boss_home_troop_count(5)
	var attack_core_after: int = boss_system.apply_nonlethal_home_troop_losses(46, 5)
	_expect("boss_46_casualties_99_survivor_pattern", attack_core_after == attack_core_before - 46 and boss_system.is_boss_active(5), failures)
	_expect("boss_46_casualties_no_head_hits", boss_system.get_part_hit_count("head", 5) == 0, failures)
	boss_main.free()
	main.free()
	var report: Dictionary = {"ok": failures.is_empty(), "failures": failures}
	print("COMBAT_CONSISTENCY_TEST: ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
