extends RefCounted
# Stateless strategic choices plus per-run player attributes and counters.
# One aimed shot per player turn; zero trajectory or physics simulation.
const LevelConfig = preload("res://scripts/LevelConfig.gd")
const ShotModel = preload("res://scripts/PlayerSimShotModel.gd")

var shot_model = ShotModel.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var skill: float = 0.52
var profile: String = "average"
var campaign_level: int = 1
var stats: Dictionary = {}

func configure(profile_name: String, level: int, action_seed: int) -> void:
	profile = profile_name if ["casual", "average", "skilled"].has(profile_name) else "average"
	campaign_level = maxi(1, level)
	skill = 0.27 if profile == "casual" else (0.78 if profile == "skilled" else 0.52)
	rng.seed = action_seed
	stats = {
		"shots": 0, "full_clears": 0, "misses": 0, "shot_wins": 0,
		"shot_losses": 0, "shot_conquests": 0, "shot_damage": 0,
		"defensive_shots": 0, "boss_shots": 0, "boss_hits": 0,
		"boss_kills": 0, "troop_orders": 0, "troops_ordered": 0,
		"troop_conquests": 0, "troop_redeployment_orders": 0, "max_troop_orders_in_turn": 0, "upgrades_bought": 0, "gold_on_upgrades": 0,
		"home_cave_projects_started": 0, "peak_home_cave_tier": 0,
		"total_shot_difficulty": 0.0, "total_full_clear_chance": 0.0
	}

func _is_player_allied(main: Node, p: Dictionary) -> bool:
	if String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return true
	var faction: int = int(p.get("faction_id", -1))
	return main.boss_system != null and main.boss_system.is_friendly_boss_faction_id(faction) and String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_ENEMY

func _is_enemy_boss_home(main: Node, p: Dictionary) -> bool:
	return main.boss_system != null and main.boss_system.get_boss_id_for_home_province_id(int(p.get("id", -1))) >= 0 and not _is_player_allied(main, p)

func choose_shot_target(main: Node) -> int:
	var best_id: int = -1
	var best_score: float = -INF
	for province in main._province_persistence:
		var id: int = int(province.get("id", -1))
		if id < 0:
			continue
		var owner: String = String(province.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		var troops: int = maxi(0, int(province.get("remaining_troops", 0)))
		var invaders: int = maxi(0, int(province.get("invading_troops", 0)))
		var allied: bool = _is_player_allied(main, province)
		var boss_home: bool = _is_enemy_boss_home(main, province)
		if allied and invaders <= 0:
			continue
		var score: float = 0.0
		if allied:
			score = 170.0 + 0.25 * invaders
		elif boss_home:
			score = 145.0 - 0.035 * troops
		elif owner == LevelConfig.PROVINCE_TYPE_ENEMY:
			score = 90.0 - 0.32 * troops
		else:
			score = 72.0 - 0.38 * troops
		if troops == 0 and not allied and not boss_home:
			score += 80.0
		if bool(province.get("is_target", false)):
			score += 12.0
		if not allied and not boss_home:
			score += 10.0 / (1.0 + float(maxi(0, troops)))
		if score > best_score:
			best_score = score
			best_id = id
	return best_id

func purchase_upgrade(main: Node) -> void:
	# Real purchased upgrades last for ONE shot, not the whole level.
	# SimMain resets these values to the permanent baseline each turn.
	var priorities: Array[String] = ["bigger", "forcefield", "heavier", "poison", "magnet"]
	if profile == "skilled":
		priorities = ["forcefield", "bigger", "poison", "heavier", "magnet"]
	var max_purchases: int = 1 if profile == "casual" else (3 if profile == "skilled" else 2)
	for _purchase in range(max_purchases):
		var best: String = ""
		var best_cost: int = 0
		for kind in priorities:
			# Spread purchases over complementary upgrades rather than simply
			# buying five copies of the cheapest type.
			if int(main.sim_upgrades.get(kind, 0)) >= 1:
				continue
			var cost: int = maxi(1, LevelConfig.get_upgrade_cost_for_level(kind, campaign_level) - int(main.sim_discounts.get(kind, 0)))
			var reserve: int = 2 if main.gold_balance >= 7 else 0
			if main.gold_balance >= cost + reserve:
				best = kind
				best_cost = cost
				break
		if best == "":
			break
		main.gold_balance -= best_cost
		main.sim_upgrades[best] = int(main.sim_upgrades.get(best, 0)) + 1
		stats["upgrades_bought"] = int(stats["upgrades_bought"]) + 1
		stats["gold_on_upgrades"] = int(stats["gold_on_upgrades"]) + best_cost

# Home Cave is the player's main strategic troop-order multiplier. The normal
# economic planner may eventually recommend one, but a human player can
# deliberately prioritize building and upgrading it at the capital.
func observe_home_cave(main: Node) -> void:
	var capital_id: int = int(main.get_player_capital_province_id())
	if capital_id < 0:
		return
	var idx: int = main.province_system.find_persistence_index_by_id(capital_id)
	if idx < 0:
		return
	var tier: int = int(main.province_system.get_home_cave_tier(main._province_persistence[idx]))
	stats["peak_home_cave_tier"] = maxi(int(stats["peak_home_cave_tier"]), tier)

func manage_home_cave(main: Node) -> void:
	var ps = main.province_system
	var capital_id: int = int(main.get_player_capital_province_id())
	if capital_id < 0 or not ps.can_player_control_construction_in_province(capital_id):
		return
	var idx: int = ps.find_persistence_index_by_id(capital_id)
	if idx < 0:
		return
	var capital: Dictionary = main._province_persistence[idx]
	var tier: int = int(ps.get_home_cave_tier(capital))
	stats["peak_home_cave_tier"] = maxi(int(stats["peak_home_cave_tier"]), tier)
	if tier >= 3:
		return
	# Existing construction must finish normally, and the real project cost
	# is paid out of the player's treasury before the shot-upgrade purchases.
	if not ps.normalize_active_construction(capital.get("active_construction", {})).is_empty():
		return
	var request_type: String = "build" if tier == 0 else "upgrade"
	var request_tier: int = 1 if tier == 0 else tier
	var action: Dictionary = {
		"request_type": request_type,
		"building_type": "home_cave",
		"tier": request_tier
	}
	if int(main.gold_balance) < int(ps.get_construction_gold_cost(action)):
		return
	var result: Dictionary = ps.start_province_construction_order(capital_id, request_type, "home_cave", request_tier)
	if bool(result.get("ok", false)):
		stats["home_cave_projects_started"] = int(stats["home_cave_projects_started"]) + 1

func _frontline_pressure(main: Node, province: Dictionary) -> int:
	var pressure: int = 0
	for neighbor_any in province.get("neighbors", []):
		var adjacent_id: int = int(neighbor_any)
		var idx: int = main.province_system.find_persistence_index_by_id(adjacent_id)
		if idx < 0:
			continue
		var adjacent: Dictionary = main._province_persistence[idx]
		if _is_player_allied(main, adjacent):
			continue
		var enemy_troops: int = maxi(0, int(adjacent.get("remaining_troops", 0)))
		pressure += 24 + mini(30, int(float(enemy_troops) / 3.0))
	return pressure

func issue_troop_orders(main: Node) -> void:
	var ps = main.province_system
	var orders_this_turn: int = 0
	# Every successful order locks its destination for the rest of the turn.
	# Therefore there cannot be more than one successful arrival per province.
	# Re-evaluate after every order and continue until NO legal useful move
	# remains; province count is solely a cycle-safety bound, not a game cap.
	for _order in range(main._province_persistence.size()):
		var best: Dictionary = {}
		var best_score: float = -INF
		for source in main._province_persistence:
			var source_id: int = int(source.get("id", -1))
			if not _is_player_allied(main, source) or String(source.get("type", "")) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
				continue
			var maximum: int = ps.get_player_troop_order_max_count(source_id)
			var source_pressure: int = _frontline_pressure(main, source)
			var source_troops: int = maxi(0, int(source.get("remaining_troops", 0)))
			var reserve: int = maxi(5, int(float(source_pressure) * 0.35))
			var sendable: int = maxi(0, maximum - reserve)
			if sendable < 5:
				continue
			for target_record in ps.build_player_troop_order_targets(source_id):
				var target_id: int = int(target_record.get("id", -1))
				if main.is_province_troop_destination_locked(target_id):
					continue
				var target_idx: int = ps.find_persistence_index_by_id(target_id)
				if target_idx < 0:
					continue
				var target: Dictionary = main._province_persistence[target_idx]
				if _is_enemy_boss_home(main, target):
					continue
				var allied: bool = _is_player_allied(main, target)
				var amount: int = 0
				var score: float = -INF
				if allied:
					var invaders: int = maxi(0, int(target.get("invading_troops", 0)))
					var garrison: int = maxi(0, int(target.get("remaining_troops", 0)))
					if invaders > 0 and garrison < invaders + 5:
						amount = mini(sendable, maxi(5, invaders - garrison + 5))
						score = 140.0 + 0.25 * float(invaders)
					else:
						# Proactively move troops from safer rear provinces to the
						# threatened frontier, not just toward invasions already underway.
						var target_pressure: int = _frontline_pressure(main, target)
						var desired_garrison: int = maxi(25, target_pressure)
						if target_pressure >= source_pressure + 15 and garrison < desired_garrison and source_troops > garrison + 10:
							amount = mini(sendable, maxi(5, desired_garrison - garrison))
							score = 52.0 + 0.45 * float(target_pressure - source_pressure) + 0.1 * float(amount)
				else:
					var defenders: int = maxi(0, int(target.get("remaining_troops", 0)))
					var buildings: int = maxi(0, int(target.get("remaining_buildings", 0)))
					var trap_losses: int = maxi(0, ps.get_province_defense_strength(target))
					var minimum: int = defenders + buildings * 3 + trap_losses + 5
					if sendable >= minimum:
						amount = minimum
						score = 95.0 - float(minimum) * 0.22 + (12.0 if defenders == 0 else 0.0)
						if String(target.get("type", "")) == LevelConfig.PROVINCE_TYPE_NEUTRAL:
							score += 5.0
				if amount <= 0 or score <= best_score:
					continue
				if not bool(ps.validate_player_troop_order(source_id, target_id, amount).get("ok", false)):
					continue
				best = {"source_id": source_id, "target_id": target_id, "amount": amount, "before_allied": allied}
				best_score = score
		if best.is_empty():
			break
		var sid: int = int(best["source_id"])
		var tid: int = int(best["target_id"])
		var amt: int = int(best["amount"])
		var si: int = ps.find_persistence_index_by_id(sid)
		if si < 0:
			break
		var source_state: Dictionary = main._province_persistence[si]
		source_state["remaining_troops"] = maxi(0, int(source_state.get("remaining_troops", 0)) - amt)
		var arrived: bool = main.enemy_turn_system.resolve_march_arrival(tid, amt, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, sid)
		if not arrived:
			source_state["remaining_troops"] = int(source_state.get("remaining_troops", 0)) + amt
			break
		main.mark_province_troop_destination_locked(tid)
		stats["troop_orders"] = int(stats["troop_orders"]) + 1
		orders_this_turn += 1
		stats["troops_ordered"] = int(stats["troops_ordered"]) + amt
		var ti: int = ps.find_persistence_index_by_id(tid)
		if ti >= 0 and not bool(best["before_allied"]) and _is_player_allied(main, main._province_persistence[ti]):
			stats["troop_conquests"] = int(stats["troop_conquests"]) + 1
		elif bool(best["before_allied"]):
			stats["troop_redeployment_orders"] = int(stats["troop_redeployment_orders"]) + 1
	stats["max_troop_orders_in_turn"] = maxi(int(stats["max_troop_orders_in_turn"]), orders_this_turn)

func take_shot(main: Node) -> Dictionary:
	var target_id: int = choose_shot_target(main)
	if target_id < 0:
		return {"shot": false, "enemy_turns": 1}
	var ps = main.province_system
	var idx: int = ps.find_persistence_index_by_id(target_id)
	if idx < 0:
		return {"shot": false, "enemy_turns": 1}
	var p: Dictionary = main._province_persistence[idx]
	var defensive: bool = _is_player_allied(main, p)
	var boss_home: bool = _is_enemy_boss_home(main, p)
	var boss_id: int = main.boss_system.get_boss_id_for_home_province_id(target_id) if boss_home else -1
	var enemies: int = int(p.get("invading_troops", 0)) if defensive else int(p.get("remaining_troops", 0))
	if boss_home:
		enemies = int(main.boss_system.get_boss_home_troop_count(boss_id))
	enemies = maxi(0, enemies)
	# The live game annexes an undefended ordinary province without running
	# physics and retains its existing building inventory intact.
	if not defensive and not boss_home and enemies == 0:
		var previous_owner: String = String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		var new_counts: Dictionary = ps.get_conquered_province_counts(LevelConfig.PROVINCE_TYPE_FRIENDLY, p)
		ps.reset_construction_on_owner_change(p, previous_owner, LevelConfig.PROVINCE_TYPE_FRIENDLY)
		p["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
		p["faction_id"] = 0
		p["remaining_troops"] = int(new_counts.get("remaining_troops", 0))
		p["invading_troops"] = 0
		p["invading_source_ids"] = []
		p["construction_progress"] = 0
		ps.ensure_minimum_conquest_farm(p)
		ps.recalculate_province_derived_economy(p)
		ps.sync_legacy_building_count_from_typed(p)
		ps.mark_province_captured_by_player_engagement(target_id)
		ps.reset_happiness_on_owner_change(p)
		main.gold_balance += 3 if main._is_milestone(main.level_index) else 1
		main._locked_province_id_after_win = target_id
		stats["shots"] = int(stats["shots"]) + 1
		stats["shot_conquests"] = int(stats["shot_conquests"]) + 1
		stats["shot_wins"] = int(stats["shot_wins"]) + 1
		return {"shot": true, "target_id": target_id, "enemies": 0,
			"downed": 0, "conquered": true, "won": true, "enemy_turns": 1,
			"full_clear": true, "difficulty": 0.0, "full_clear_chance": 1.0,
			"boss_killed": false, "undefended": true}
	var phase: String = LevelConfig.PHASE_DEFENSIVE if defensive else (LevelConfig.PHASE_NEUTRAL if String(p.get("type", "")) == LevelConfig.PROVINCE_TYPE_NEUTRAL else LevelConfig.PHASE_OFFENSIVE)
	var encounter: Dictionary = ps.ensure_province_encounter_layout(target_id)
	var shot: Dictionary = shot_model.simulate(
		int(encounter.get("seed", 1)), int(encounter.get("level", campaign_level)),
		enemies, phase, String(encounter.get("map_type", LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)),
		main.sim_upgrades, skill, rng
	)
	var downed: int = int(shot.get("strategic_downed", 0))
	var buildings: int = maxi(0, int(p.get("remaining_buildings", 0)))
	var input: Dictionary = {
		"player_participating": true, "troops_A": 0, "troops_B": enemies,
		"buildings_A": 0, "buildings_B": 0 if boss_home else buildings,
		"player_downed_troops": downed, "player_destroyed_buildings": 0,
		"province_id": target_id, "boss_part_hit_troop_credit": 0
	}
	var result: Dictionary = main.engagement_resolver.resolve_engagement(input)
	var killed_boss: bool = false
	if boss_home and boss_id >= 0:
		# Match live boss-home engagements: pin losses damage the HP-linked
		# army through BossSystem, rather than treating it as ordinary troops.
		var damage: Dictionary = main.boss_system.apply_home_province_troop_losses_for_home_province_id(downed, rng, target_id)
		killed_boss = bool(damage.get("boss_killed", false))
		# Model the separate opportunity to strike a boss limb with the ball.
		if not killed_boss and rng.randf() < 0.15 + 0.43 * skill:
			var limbs: Array[String] = main.boss_system.get_damageable_part_names(boss_id)
			if not limbs.is_empty():
				var target_part: String = limbs[rng.randi_range(0, limbs.size() - 1)]
				var hit: Dictionary = main.boss_system.register_part_hit(target_part, boss_id)
				if bool(hit.get("accepted", false)):
					stats["boss_hits"] = int(stats["boss_hits"]) + 1
				killed_boss = bool(hit.get("boss_killed", false))
		if not main.boss_system.is_boss_active(boss_id):
			killed_boss = true
		if killed_boss:
			result["won"] = true
			result["conquered"] = true
			result["enemy_turns"] = 1
			result["province_type_after"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
			result["faction_after"] = 0
			result["final_troops_B"] = LevelConfig.get_runtime_conquered_province_friendly_troops_for_level(campaign_level)
			result["final_buildings_B"] = buildings
			stats["boss_kills"] = int(stats["boss_kills"]) + 1
		else:
			result["final_troops_B"] = int(p.get("remaining_troops", 0))
			result["final_buildings_B"] = buildings
			result["province_type_after"] = LevelConfig.PROVINCE_TYPE_ENEMY
			result["faction_after"] = int(p.get("faction_id", 0))
			result["conquered"] = false
			# Match the live engagement: an assisted shot that does not kill
			# the enemy boss is followed by the actual boss-versus-boss duel.
			if bool(p.get("friendly_boss_invasion_pending", false)) and main.enemy_turn_system != null:
				var duel: Dictionary = main.enemy_turn_system.resolve_friendly_boss_clash(target_id)
				if bool(duel.get("enemy_boss_died", false)):
					result["won"] = true
					result["enemy_turns"] = 1
				result["conquered"] = bool(duel.get("conquered", false))
				result["province_type_after"] = String(p.get("type", LevelConfig.PROVINCE_TYPE_ENEMY))
				result["faction_after"] = int(p.get("faction_id", 0))
				result["final_troops_B"] = int(p.get("remaining_troops", 0))
	var previous: String = String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var final_type: String = String(result.get("province_type_after", previous))
	var conquered: bool = bool(result.get("conquered", false)) and final_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and not defensive
	if previous != final_type and not (boss_home and conquered):
		ps.reset_construction_on_owner_change(p, previous, final_type)
	if boss_home and killed_boss and conquered:
		var resident_id: int = int(p.get("friendly_boss_invader_id", -1)) if bool(p.get("friendly_boss_invasion_pending", false)) else -1
		if resident_id >= 0 and (not main.boss_system.is_boss_active(resident_id) or not main.boss_system.is_friendly_boss(resident_id) or main.boss_system.get_boss_current_province_id(resident_id) != target_id):
			resident_id = -1
		var resident_troops: int = main.boss_system.get_boss_home_troop_count(resident_id) if resident_id >= 0 else 0
		ps.capture_defeated_boss_home_intact(p, 0, LevelConfig.get_runtime_conquered_province_friendly_troops_for_level(campaign_level), resident_id, resident_troops)
		main._locked_province_id_after_win = target_id
	elif boss_home:
		pass # Nonlethal boss damage does not affect ordinary defenses.
	elif conquered:
		p["type"] = final_type
		p["faction_id"] = 0
		p["is_boss_home"] = false
		p["remaining_troops"] = LevelConfig.get_runtime_conquered_province_friendly_troops_for_level(campaign_level)
		ps.seed_basic_conquest_buildings(p)
		ps.mark_province_captured_by_player_engagement(target_id)
		ps.ensure_minimum_conquest_farm(p)
		main._locked_province_id_after_win = target_id
	else:
		if defensive:
			p["type"] = final_type
			p["remaining_troops"] = maxi(0, int(result.get("final_resident_troops", p.get("remaining_troops", 0))))
			p["invading_troops"] = 0
			p["invading_faction_id"] = -1
			if final_type == LevelConfig.PROVINCE_TYPE_ENEMY:
				p["faction_id"] = int(result.get("faction_after", 1))
			p["remaining_buildings"] = int(ps.set_typed_building_count_ceiling(p, maxi(0, int(result.get("final_buildings_B", buildings))), final_type == LevelConfig.PROVINCE_TYPE_FRIENDLY))
		else:
			p["remaining_troops"] = maxi(0, int(result.get("final_troops_B", enemies - downed)))
			var remaining_buildings: int = maxi(0, int(result.get("final_buildings_B", buildings)))
			ps.set_typed_building_count_ceiling(p, remaining_buildings, false)
			if remaining_buildings <= 0:
				ps.clear_typed_buildings(p)
	if not defensive and not conquered:
		p["type"] = final_type
		p["faction_id"] = int(result.get("faction_after", p.get("faction_id", 0)))
	if final_type != previous:
		ps.reset_happiness_on_owner_change(p)
	stats["shots"] = int(stats["shots"]) + 1
	stats["shot_damage"] = int(stats["shot_damage"]) + downed
	stats["total_shot_difficulty"] = float(stats["total_shot_difficulty"]) + float(shot.get("difficulty", 0.0))
	stats["total_full_clear_chance"] = float(stats["total_full_clear_chance"]) + float(shot.get("full_clear_chance", 0.0))
	if bool(shot.get("full_clear", false)):
		stats["full_clears"] = int(stats["full_clears"]) + 1
	if downed == 0 and enemies > 0:
		stats["misses"] = int(stats["misses"]) + 1
	if bool(result.get("won", false)):
		stats["shot_wins"] = int(stats["shot_wins"]) + 1
	else:
		stats["shot_losses"] = int(stats["shot_losses"]) + 1
	if conquered:
		stats["shot_conquests"] = int(stats["shot_conquests"]) + 1
	if defensive:
		stats["defensive_shots"] = int(stats["defensive_shots"]) + 1
	if boss_home:
		stats["boss_shots"] = int(stats["boss_shots"]) + 1
	return {
		"shot": true, "target_id": target_id, "enemies": enemies,
		"downed": downed, "conquered": conquered, "won": bool(result.get("won", false)),
		"enemy_turns": clampi(int(result.get("enemy_turns", 1)), 1, 2),
		"full_clear": bool(shot.get("full_clear", false)),
		"difficulty": float(shot.get("difficulty", 0.0)),
		"full_clear_chance": float(shot.get("full_clear_chance", 0.0)),
		"boss_killed": killed_boss
	}
