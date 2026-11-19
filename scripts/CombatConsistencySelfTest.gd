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
	var turn_number: int = 5
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
	# Ardan-style defense: 42 physical pins out of a 56-pin battlefield
	# represent 66 of 88 invaders. The remaining 22 fight 13 defenders,
	# destroy three of four buildings, then disperse without conquering.
	var ardan_equivalent_hits: int = clampi(roundi(float(88 * 42) / float(56)), 0, 88)
	_expect("ardan_physical_hits_are_scaled", ardan_equivalent_hits == 66, failures)
	var ardan_combat: Dictionary = EngagementResolverScript.calculate_automated_combat(88 - ardan_equivalent_hits, 13, 0, 4, 3)
	_expect("ardan_friendly_garrison_eliminated", int(ardan_combat.get("defenders_remaining", -1)) == 0, failures)
	_expect("ardan_building_survives", int(ardan_combat.get("buildings_remaining", -1)) == 1, failures)
	_expect("ardan_province_held", not bool(ardan_combat.get("conquered", true)), failures)
	_expect("ardan_attackers_disperse", int(ardan_combat.get("attackers_remaining", -1)) == 9, failures)

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

	# Enemy boss homes preserve their ordinary garrison, while the HP-linked
	# defenders are counted separately in the AI's two-phase assault forecast.
	var boss_ps = ProvinceSystemScript.new()
	boss_ps.setup(boss_main)
	boss_main.province_system = boss_ps
	var enemy_boss: Dictionary = boss_system._make_default_single_boss_state(9, 101, 16, [])
	enemy_boss["active"] = true
	enemy_boss["dead"] = false
	boss_system.set_runtime_state({"bosses": [enemy_boss], "primary_boss_id": 9, "next_boss_id": 10})
	var enemy_home: Dictionary = _state(boss_ps, 16, LevelConfig.PROVINCE_TYPE_ENEMY, 12, {"farm": {"1": 2}}, 101)
	enemy_home["is_boss_home"] = true
	boss_main._province_persistence = [enemy_home]
	var enemy_marcher = EnemyTurnSystemScript.new()
	enemy_marcher.setup(boss_main)
	var enemy_core: int = boss_system.get_boss_home_troop_count(9)
	var conquest_need: int = enemy_marcher._get_total_troops_needed_to_conquer(enemy_home)
	_expect("boss_home_defense_counts_both_pools_and_buildings", conquest_need == enemy_core + 12 + 6, failures)
	var partial_pred: Dictionary = enemy_marcher._predict_march_combat(enemy_home, enemy_core - 5)
	_expect("boss_first_forecast_preserves_garrison", int(partial_pred.get("defenders_remaining", -1)) == 17, failures)
	_expect("boss_first_forecast_preserves_buildings", int(partial_pred.get("buildings_remaining", -1)) == 2, failures)
	var full_pred: Dictionary = enemy_marcher._predict_march_combat(enemy_home, enemy_core + 12 + 6)
	_expect("boss_full_assault_requires_every_building", bool(full_pred.get("conquered", false)) and int(full_pred.get("buildings_remaining", -1)) == 0, failures)
	boss_system.mark_boss_dead(9)
	_expect("boss_death_keeps_ordinary_garrison", int(enemy_home.get("remaining_troops", -1)) == 12 and int(enemy_home.get("remaining_buildings", -1)) == 2, failures)
	_expect("boss_death_keeps_enemy_ownership", String(enemy_home.get("type", "")) == LevelConfig.PROVINCE_TYPE_ENEMY and int(enemy_home.get("faction_id", -1)) == 101, failures)
	_expect("boss_death_is_not_conquest", bool(enemy_home.get("boss_defeated_home_pending_capture", false)) and not bool(enemy_home.get("is_boss_home", true)), failures)

	# Exception: a victorious friendly boss conquers immediately, removes
	# the enemy's normal garrison/buildings, and seeds exactly three basics.
	var allied_boss: Dictionary = boss_system._make_default_single_boss_state(7, BossSystemScript.FRIENDLY_BOSS_FACTION_ID, 17, [])
	allied_boss["active"] = true
	allied_boss["dead"] = false
	allied_boss["is_friendly_boss"] = true
	allied_boss["current_province_id"] = 16
	enemy_boss = boss_system._make_default_single_boss_state(9, 101, 16, [])
	enemy_boss["active"] = true
	enemy_boss["dead"] = false
	boss_system.set_runtime_state({"bosses": [allied_boss, enemy_boss], "primary_boss_id": 9, "next_boss_id": 10})
	var enemy_troops_before_duel: int = boss_system.get_boss_home_troop_count(9)
	enemy_boss["home_troop_linear_losses"] = enemy_troops_before_duel - 5
	boss_system.set_runtime_state({"bosses": [allied_boss, enemy_boss], "primary_boss_id": 9, "next_boss_id": 10})
	var special_home: Dictionary = _state(boss_ps, 16, LevelConfig.PROVINCE_TYPE_ENEMY, 21, {"farm": {"1": 3}, "trap_factory": {"1": 2}}, 101)
	special_home["is_boss_home"] = true
	special_home["friendly_boss_invasion_pending"] = true
	special_home["friendly_boss_invader_id"] = 7
	special_home["friendly_boss_defending_enemy_boss_id"] = 9
	special_home["friendly_boss_invading_troops"] = boss_system.get_boss_home_troop_count(7)
	boss_main._province_persistence = [special_home]
	var clash: Dictionary = enemy_marcher.resolve_friendly_boss_clash(16)
	_expect("friendly_boss_special_victory", bool(clash.get("enemy_boss_died", false)) and not bool(clash.get("friendly_boss_died", true)), failures)
	_expect("friendly_boss_inherits_no_enemy_garrison", int(special_home.get("friendly_boss_base_troops", -1)) == 0 and int(special_home.get("remaining_troops", -1)) == int(clash.get("invading_after", -2)), failures)
	_expect("friendly_boss_conquered_faction", String(special_home.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY and int(special_home.get("faction_id", -1)) == BossSystemScript.FRIENDLY_BOSS_FACTION_ID, failures)
	_expect("friendly_boss_resets_three_basics", int(special_home.get("remaining_buildings", -1)) == 3 and boss_ps.get_typed_building_count(special_home, "farm") == 1 and boss_ps.get_typed_building_count(special_home, "tenement") == 1 and boss_ps.get_typed_building_count(special_home, "mansion") == 1, failures)
	_expect("friendly_boss_removes_enemy_traps", boss_ps.get_typed_building_count(special_home, "trap_factory") == 0, failures)

	# A regular troop march fights boss troops first, then the ordinary
	# garrison, then buildings. A pending friendly boss only acts immediately
	# if that march kills the enemy boss without finishing the conquest.
	var boss_home_march_cases: Array[Dictionary] = [
		{"name": "no_pending_boss_survives", "pending": false, "boss_pool": 10, "friendly_pool": 20, "garrison": 8, "farms": 2, "march": 5},
		{"name": "no_pending_partial", "pending": false, "boss_pool": 10, "friendly_pool": 20, "garrison": 8, "farms": 2, "march": 13},
		{"name": "no_pending_full", "pending": false, "boss_pool": 10, "friendly_pool": 20, "garrison": 8, "farms": 2, "march": 24},
		{"name": "pending_boss_survives", "pending": true, "boss_pool": 10, "friendly_pool": 20, "garrison": 8, "farms": 2, "march": 5},
		{"name": "pending_player_conquest", "pending": true, "boss_pool": 10, "friendly_pool": 20, "garrison": 8, "farms": 2, "march": 24},
		{"name": "pending_friendly_finishes_garrison", "pending": true, "boss_pool": 10, "friendly_pool": 20, "garrison": 8, "farms": 2, "march": 13},
		{"name": "pending_friendly_ignores_buildings", "pending": true, "boss_pool": 10, "friendly_pool": 20, "garrison": 5, "farms": 5, "march": 17},
		{"name": "pending_friendly_loses", "pending": true, "boss_pool": 10, "friendly_pool": 4, "garrison": 8, "farms": 2, "march": 11},
		{"name": "pending_friendly_tie", "pending": true, "boss_pool": 10, "friendly_pool": 4, "garrison": 6, "farms": 2, "march": 12}
	]
	for case_data in boss_home_march_cases:
		var case_name: String = String(case_data["name"])
		var enemy_case: Dictionary = boss_system._make_default_single_boss_state(9, 101, 16, [])
		enemy_case["active"] = true
		enemy_case["dead"] = false
		var friendly_case: Dictionary = boss_system._make_default_single_boss_state(7, BossSystemScript.FRIENDLY_BOSS_FACTION_ID, 17, [])
		friendly_case["active"] = true
		friendly_case["dead"] = false
		friendly_case["is_friendly_boss"] = true
		friendly_case["current_province_id"] = 16
		boss_system.set_runtime_state({"bosses": [friendly_case, enemy_case], "primary_boss_id": 9, "next_boss_id": 10})
		enemy_case["home_troop_linear_losses"] = maxi(0, boss_system.get_boss_home_troop_count(9) - int(case_data["boss_pool"]))
		friendly_case["home_troop_linear_losses"] = maxi(0, boss_system.get_boss_home_troop_count(7) - int(case_data["friendly_pool"]))
		boss_system.set_runtime_state({"bosses": [friendly_case, enemy_case], "primary_boss_id": 9, "next_boss_id": 10})
		var farms: int = int(case_data["farms"])
		var home_case: Dictionary = _state(boss_ps, 16, LevelConfig.PROVINCE_TYPE_ENEMY, int(case_data["garrison"]), {"farm": {"1": farms}}, 101)
		home_case["is_boss_home"] = true
		if bool(case_data["pending"]):
			home_case["friendly_boss_invasion_pending"] = true
			home_case["friendly_boss_invader_id"] = 7
			home_case["friendly_boss_defending_enemy_boss_id"] = 9
			home_case["friendly_boss_invading_troops"] = boss_system.get_boss_home_troop_count(7)
			home_case["friendly_boss_invasion_started_turn"] = 4
		boss_main._province_persistence = [home_case]
		boss_ps._rebuild_persistence_index_cache()
		var case_applied: bool = enemy_marcher.resolve_march_arrival(16, int(case_data["march"]), LevelConfig.PROVINCE_TYPE_FRIENDLY)
		_expect(case_name + "_arrival_applied", case_applied, failures)
		var boss_survived: bool = boss_system.is_boss_active(9)
		var friendly_survived: bool = boss_system.is_boss_active(7)
		var still_pending: bool = bool(home_case.get("friendly_boss_invasion_pending", false))
		var garrison_after: int = int(home_case.get("remaining_troops", -1))
		var buildings_after: int = int(home_case.get("remaining_buildings", -1))
		match case_name:
			"no_pending_boss_survives":
				_expect(case_name, boss_survived and not still_pending and garrison_after == 8 and buildings_after == 2, failures)
			"no_pending_partial":
				_expect(case_name, not boss_survived and not still_pending and String(home_case.get("type", "")) == LevelConfig.PROVINCE_TYPE_ENEMY and garrison_after == 5 and buildings_after == 2, failures)
			"no_pending_full":
				_expect(case_name, not boss_survived and not still_pending and String(home_case.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY and buildings_after == 1, failures)
			"pending_boss_survives":
				_expect(case_name, boss_survived and friendly_survived and still_pending and int(home_case.get("friendly_boss_invader_id", -1)) == 7 and garrison_after == 8 and buildings_after == 2, failures)
			"pending_player_conquest":
				_expect(case_name, not boss_survived and friendly_survived and not still_pending and int(home_case.get("faction_id", -1)) == 0 and int(home_case.get("friendly_boss_resident_id", -1)) == 7 and garrison_after == int(home_case.get("friendly_boss_base_troops", -1)) + boss_system.get_boss_home_troop_count(7) and buildings_after == 1, failures)
			"pending_friendly_finishes_garrison":
				_expect(case_name, not boss_survived and friendly_survived and not still_pending and int(home_case.get("faction_id", -1)) == BossSystemScript.FRIENDLY_BOSS_FACTION_ID and garrison_after == 15 and buildings_after == 3, failures)
			"pending_friendly_ignores_buildings":
				_expect(case_name, not boss_survived and friendly_survived and not still_pending and int(home_case.get("faction_id", -1)) == BossSystemScript.FRIENDLY_BOSS_FACTION_ID and garrison_after == 20 and buildings_after == 3, failures)
			"pending_friendly_loses":
				_expect(case_name, not boss_survived and not friendly_survived and not still_pending and String(home_case.get("type", "")) == LevelConfig.PROVINCE_TYPE_ENEMY and garrison_after == 3 and buildings_after == 2, failures)
			"pending_friendly_tie":
				_expect(case_name, not boss_survived and not friendly_survived and not still_pending and String(home_case.get("type", "")) == LevelConfig.PROVINCE_TYPE_ENEMY and garrison_after == 0 and buildings_after == 2, failures)
	boss_main.free()

	# All enemy bosses now belong to one faction. Recruitment is additive per
	# surviving limb but counted only once for each province in that faction.
	var united_main := MockMain.new()
	var united_boss = BossSystemScript.new()
	united_main.boss_system = united_boss
	united_boss.setup(united_main)
	var united_entries: Array[Dictionary] = [
		{"home_province_id": 51, "boss_faction_id": 99, "boss_faction_name": "Empire", "boss_display_name": "First"},
		{"home_province_id": 52, "boss_faction_id": 100, "boss_faction_name": "Empire", "boss_display_name": "Second"},
		{"home_province_id": 53, "boss_faction_id": 101, "boss_faction_name": "Empire", "boss_display_name": "Third"},
		{"home_province_id": 54, "boss_faction_id": 199, "boss_faction_name": "Ally", "is_friendly_boss": true}
	]
	var united_spawn: Dictionary = united_boss.activate_multiple_bosses(united_entries)
	var united_states: Array[Dictionary] = united_boss.get_active_boss_states()
	_expect("united_enemy_3_bosses", int(united_spawn.get("boss_count", -1)) == 4 and united_states.size() == 4, failures)
	_expect("united_single_enemy_faction", united_boss.get_all_boss_faction_ids().size() == 2 and int(united_states[0].get("boss_faction_id", -1)) == 99 and int(united_states[1].get("boss_faction_id", -1)) == 99 and int(united_states[2].get("boss_faction_id", -1)) == 99, failures)
	_expect("united_boss_names_still_distinct", united_boss.get_boss_display_name(int(united_states[0]["boss_id"])) != united_boss.get_boss_display_name(int(united_states[1]["boss_id"])), failures)
	_expect("united_3_bosses_plus_24", united_boss.get_boss_recruitment_bonus_for_faction(99) == 24 and united_boss.get_total_boss_recruitment_bonus() == 24, failures)
	_expect("united_friendly_excluded", united_boss.get_boss_recruitment_bonus_for_faction(199) == 8, failures)
	var first_enemy_id: int = int(united_states[0]["boss_id"])
	var second_enemy_id: int = int(united_states[1]["boss_id"])
	var friendly_boss_id: int = int(united_states[3]["boss_id"])
	var normal_friendly_core: int = united_boss.get_total_remaining_hit_points(friendly_boss_id) * BossSystemScript.BOSS_HOME_TROOPS_PER_HIT_POINT + LevelConfig.get_friendly_boss_bonus_home_troops()
	_expect("friendly_boss_starts_with_double_core", united_boss.get_boss_home_troop_count(friendly_boss_id) == 2 * normal_friendly_core, failures)
	united_boss.register_part_hit("left_arm", first_enemy_id)
	_expect("united_one_limb_lost_plus_22", united_boss.get_boss_recruitment_bonus_for_faction(99) == 22, failures)
	united_boss.mark_boss_dead(second_enemy_id)
	_expect("united_one_boss_dead_plus_14", united_boss.get_boss_recruitment_bonus_for_faction(99) == 14 and united_boss.is_boss_active(first_enemy_id), failures)
	var old_a: Dictionary = united_boss._make_default_single_boss_state(81, 99, 71, [])
	var old_b: Dictionary = united_boss._make_default_single_boss_state(82, 100, 72, [])
	old_a["active"] = true
	old_b["active"] = true
	old_a["boss_faction_name"] = "Old A"
	old_b["boss_faction_name"] = "Old B"
	united_boss.set_runtime_state({"bosses": [old_a, old_b], "primary_boss_id": 81, "next_boss_id": 83})
	var legacy_provinces: Array[Dictionary] = [
		{"id": 71, "type": "enemy", "faction_id": 99},
		{"id": 72, "type": "enemy", "faction_id": 100},
		{"id": 73, "type": "friendly", "faction_id": 100, "invading_troops": 7, "invading_faction_id": 100}
	]
	united_boss.unify_enemy_boss_factions_in_loaded_game(legacy_provinces)
	_expect("united_legacy_map_reassigned", int(legacy_provinces[1]["faction_id"]) == 99 and int(legacy_provinces[2]["invading_faction_id"]) == 99 and int(legacy_provinces[2]["faction_id"]) == 99, failures)
	_expect("united_legacy_bosses_distinct", united_boss.get_boss_display_name(81) == "Old A" and united_boss.get_boss_display_name(82) == "Old B", failures)
	united_main.free()
	main.free()
	var report: Dictionary = {"ok": failures.is_empty(), "failures": failures}
	print("COMBAT_CONSISTENCY_TEST: ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
