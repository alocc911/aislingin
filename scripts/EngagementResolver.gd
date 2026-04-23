extends RefCounted

const LevelConfig = preload("res://scripts/LevelConfig.gd")

var _main: Node = null

func setup(main_node: Node) -> void:
	_main = main_node


func _normalize_non_player_attacker_type(attacker_type: String) -> String:
	if attacker_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return LevelConfig.PROVINCE_TYPE_FRIENDLY
	return LevelConfig.PROVINCE_TYPE_ENEMY


func _normalize_non_player_attacker_faction(attacker_type: String, faction_id: int) -> int:
	if attacker_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return 0
	if faction_id > 0:
		return faction_id
	return LevelConfig.ENEMY_FACTION_DEFAULT



func _get_conquered_province_buildings(province_type: String, province_state: Dictionary = {}) -> int:
	if _main != null and _main.province_system != null and _main.province_system.has_method("get_conquered_province_counts"):
		var counts: Dictionary = _main.province_system.get_conquered_province_counts(province_type, province_state)
		return int(counts.get("remaining_buildings", 0))
	return LevelConfig.get_conquered_province_buildings(province_type)


func _get_conquered_province_troops(province_type: String, province_state: Dictionary = {}) -> int:
	if _main != null and _main.province_system != null and _main.province_system.has_method("get_conquered_province_counts"):
		var counts: Dictionary = _main.province_system.get_conquered_province_counts(province_type, province_state)
		return int(counts.get("remaining_troops", 0))
	return LevelConfig.get_conquered_province_troops(province_type)

func _get_annexed_to_friendly_buildings(province_state: Dictionary, previous_type: String) -> int:
	if bool(province_state.get("is_target", false)):
		return LevelConfig.get_conquered_ancestral_homeland_buildings()
	return _get_conquered_province_buildings(LevelConfig.PROVINCE_TYPE_FRIENDLY, province_state)


func _get_annexed_to_friendly_troops(province_state: Dictionary, previous_type: String) -> int:
	if bool(province_state.get("is_target", false)):
		return LevelConfig.get_conquered_ancestral_homeland_troops()
	return _get_conquered_province_troops(LevelConfig.PROVINCE_TYPE_FRIENDLY, province_state)

func _normalize_owner_faction_for_type(owner_type: String, faction_id: int) -> int:
	if owner_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		if faction_id > 0:
			return faction_id
		return LevelConfig.ENEMY_FACTION_DEFAULT
	return 0


func _did_owner_change(previous_type: String, previous_faction: int, new_type: String, new_faction: int) -> bool:
	if previous_type != new_type:
		return true
	if new_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		return _normalize_owner_faction_for_type(previous_type, previous_faction) != _normalize_owner_faction_for_type(new_type, new_faction)
	return false


func _get_player_phase_label(province_type: String) -> String:
	if province_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return "Offensive-Neutral"
	if province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		return "Offensive-Enemy"
	return "Defensive"


func _get_player_troop_label(province_type: String) -> String:
	if province_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return "Neutral troops"
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return "Invading troops"
	return "Enemy troops"


func _get_player_building_label(province_type: String) -> String:
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return "Friendly buildings"
	return "Buildings"


func _build_player_summary_text(
	phase_label: String,
	troop_label: String,
	building_label: String,
	starting_troops: int,
	ending_troops: int,
	starting_buildings: int,
	ending_buildings: int,
	outcome_line: String,
	next_action_text: String,
	enemy_turns: int
) -> String:
	var downed_troops: int = maxi(0, starting_troops - ending_troops)
	var destroyed_buildings: int = maxi(0, starting_buildings - ending_buildings)
	var enemy_turns_text: String = "Enemy advances %d turn%s." % [enemy_turns, "" if enemy_turns == 1 else "s"]

	return "%s — Start: %d • Finish: %d • Downed: %d\n%s — Start: %d • Finish: %d • Destroyed: %d\nOutcome: %s\nNext: %s\n%s Tap or click to return to the Grand Map." % [
		troop_label,
		starting_troops,
		ending_troops,
		downed_troops,
		building_label,
		starting_buildings,
		ending_buildings,
		destroyed_buildings,
		outcome_line,
		next_action_text,
		enemy_turns_text
	]


func _build_defensive_summary_text(
	phase_label: String,
	invader_label: String,
	defender_label: String,
	building_label: String,
	player_result_starting_troops: int,
	player_result_ending_troops: int,
	full_result_starting_troops: int,
	full_result_ending_troops: int,
	starting_defenders: int,
	ending_defenders: int,
	starting_buildings: int,
	ending_buildings: int,
	outcome_line: String,
	next_action_text: String,
	enemy_turns: int
) -> String:
	var player_downed_troops: int = maxi(0, player_result_starting_troops - player_result_ending_troops)
	var total_eliminated_troops: int = maxi(0, full_result_starting_troops - full_result_ending_troops)
	var defender_losses: int = maxi(0, starting_defenders - ending_defenders)
	var destroyed_buildings: int = maxi(0, starting_buildings - ending_buildings)
	var enemy_turns_text: String = "Enemy advances %d turn%s." % [enemy_turns, "" if enemy_turns == 1 else "s"]

	return "%s (player result) — Start: %d • Finish: %d • Downed: %d\n%s (after autoengagement) — Start: %d • Finish: %d • Downed: %d\n%s — Start: %d • Finish: %d • Lost: %d\n%s — Start: %d • Finish: %d • Destroyed: %d\nOutcome: %s\nNext: %s\n%s Tap or click to return to the Grand Map." % [
		invader_label,
		player_result_starting_troops,
		player_result_ending_troops,
		player_downed_troops,
		invader_label,
		full_result_starting_troops,
		full_result_ending_troops,
		total_eliminated_troops,
		defender_label,
		starting_defenders,
		ending_defenders,
		defender_losses,
		building_label,
		starting_buildings,
		ending_buildings,
		destroyed_buildings,
		outcome_line,
		next_action_text,
		enemy_turns_text
	]

# =============================================================================
# UNIFIED ENGAGEMENT RESOLVER (March 2026)
# =============================================================================
# Single deterministic entry point for EVERY engagement in the game.
# Inputs (all required):
#   - player_participating: bool
#   - troops_A: int          (attacking side)
#   - troops_B: int          (defending side)
#   - buildings_A: int
#   - buildings_B: int
#   - player_downed_troops: int   (only used when player_participating)
#   - player_destroyed_buildings: int
#   - province_id: int            (for type lookup, adjacency, neutral conquest)
#
# Returns a Dictionary with everything needed downstream:
#   outcome_line, post_summary_status_text, lock_province_id, enemy_turns,
#   grant_reward, final_troops_A, final_troops_B, final_buildings_A,
#   final_buildings_B, province_type_after, summary_text
# =============================================================================

func resolve_engagement(inputs: Dictionary) -> Dictionary:
	if _main == null:
		return _empty_outcome()

	var player_participating := bool(inputs.get("player_participating", false))
	var troops_A := maxi(0, int(inputs.get("troops_A", 0)))
	var troops_B := maxi(0, int(inputs.get("troops_B", 0)))
	var buildings_A := maxi(0, int(inputs.get("buildings_A", 0)))
	var buildings_B := maxi(0, int(inputs.get("buildings_B", 0)))
	var player_downed := maxi(0, int(inputs.get("player_downed_troops", 0)))
	var player_destroyed_buildings := maxi(0, int(inputs.get("player_destroyed_buildings", 0)))
	var province_id := int(inputs.get("province_id", -1))

	var province_index := -1
	var province_state: Dictionary = {}
	if _main.province_system != null and province_id != -1:
		province_index = _main.province_system.find_persistence_index_by_id(province_id)
		if province_index != -1:
			province_state = _main._province_persistence[province_index].duplicate()

	var province_type := String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var previous_faction := int(province_state.get("faction_id", 0))
	var previous_construction_progress := int(province_state.get("construction_progress", 0))
	var is_neutral := province_type == LevelConfig.PROVINCE_TYPE_NEUTRAL
	var is_defensive: bool = province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY
	var is_offensive_enemy: bool = province_type == LevelConfig.PROVINCE_TYPE_ENEMY

	# -------------------------------------------------------------------------
	# NON-PLAYER ENGAGEMENT (auto-invasions / marches)
	# -------------------------------------------------------------------------
	if not player_participating:
		var attacker_type: String = _normalize_non_player_attacker_type(String(inputs.get("attacker_type", LevelConfig.PROVINCE_TYPE_ENEMY)))
		var attacker_faction: int = _normalize_non_player_attacker_faction(attacker_type, int(inputs.get("attacker_faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
		var surviving_attackers: int = troops_A - troops_B
		var final_troops_B: int = maxi(0, troops_B - troops_A)
		var final_buildings_B: int = buildings_B

		if surviving_attackers > 0:
			var damage: int = floori(float(surviving_attackers) / float(_main.INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT))
			final_buildings_B = maxi(0, buildings_B - damage)

		var conquered: bool = false
		var final_type: String = province_type
		var final_faction: int = 0
		if province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
			final_faction = int(province_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT))

		if final_troops_B <= 0 and final_buildings_B <= 0 and surviving_attackers > 0:
			conquered = true
			if attacker_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
				final_type = LevelConfig.PROVINCE_TYPE_FRIENDLY
				final_buildings_B = _get_conquered_province_buildings(LevelConfig.PROVINCE_TYPE_FRIENDLY, province_state)
				final_troops_B = _get_conquered_province_troops(LevelConfig.PROVINCE_TYPE_FRIENDLY, province_state)
				final_faction = 0
			else:
				final_type = LevelConfig.PROVINCE_TYPE_ENEMY
				final_buildings_B = _get_conquered_province_buildings(LevelConfig.PROVINCE_TYPE_ENEMY, province_state)
				final_troops_B = _get_conquered_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY, province_state)
				final_faction = attacker_faction
		elif province_type != LevelConfig.PROVINCE_TYPE_ENEMY:
			final_faction = 0

		return {
			"player_participating": false,
			"outcome_line": "Non-player forces clashed.",
			"post_summary_status_text": "Non-player engagement resolved.",
			"lock_province_id": -1,
			"enemy_turns": 0,
			"grant_reward": false,
			"final_troops_A": 0,
			"final_troops_B": final_troops_B,
			"final_buildings_A": buildings_A,
			"final_buildings_B": final_buildings_B,
			"province_type_after": final_type,
			"faction_after": final_faction,
			"construction_progress_after": 0 if _did_owner_change(province_type, previous_faction, final_type, final_faction) else previous_construction_progress,
			"summary_text": "",
			"conquered": conquered
		}

	# -------------------------------------------------------------------------
	# PLAYER ENGAGEMENT (the only case that uses gameplay results)
	# -------------------------------------------------------------------------
	var required_half_downed := ceili(float(troops_B) * float(LevelConfig.ENGAGEMENT_WIN_THRESHOLD))
	var player_won_engagement := player_downed >= required_half_downed
	var met_progress := player_won_engagement
	var pass_condition := player_won_engagement

	var effective_player_destroyed_buildings: int = player_destroyed_buildings
	if is_offensive_enemy:
		effective_player_destroyed_buildings = int(LevelConfig.get_offensive_logical_destroyed_buildings(
			troops_B,
			player_downed,
			buildings_B
		))
	else:
		effective_player_destroyed_buildings = clampi(player_destroyed_buildings, 0, buildings_B)

	# Apply player results as battle results first; province normalization happens later.
	var combat_remaining_troops_B: int = maxi(0, troops_B - player_downed)
	var combat_remaining_buildings_B: int = maxi(0, buildings_B - effective_player_destroyed_buildings)
	var remaining_troops_B: int = combat_remaining_troops_B
	var remaining_buildings_B: int = combat_remaining_buildings_B
	var final_resident_troops: int = combat_remaining_troops_B
	var final_invading_troops: int = 0
	var summary_ending_troops: int = combat_remaining_troops_B
	var summary_ending_buildings: int = combat_remaining_buildings_B
	var defensive_player_result_ending_troops: int = combat_remaining_troops_B
	var defensive_full_result_ending_troops: int = combat_remaining_troops_B
	var defensive_starting_defenders: int = 0
	var defensive_ending_defenders: int = 0

	var is_target_province: bool = bool(province_state.get("is_target", false))
	var can_annex_to_friendly: bool = province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY or is_target_province
	if not can_annex_to_friendly and _main.province_system != null:
		can_annex_to_friendly = _main.province_system.province_has_friendly_neighbor(province_state)

	var annexed := false
	var fully_cleared := false
	var final_type := province_type
	var final_faction := 0
	if province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		# Preserve the current enemy faction on partial-damage outcomes.
		# Without this, weakened enemy provinces can end up with faction_id 0,
		# which later gets normalized into the default enemy faction (Enemy 1).
		final_faction = _normalize_owner_faction_for_type(province_type, previous_faction)
	var conquered := false

	if is_defensive:
		var defending_troops_before: int = maxi(0, int(province_state.get("remaining_troops", 0)))
		defensive_starting_defenders = defending_troops_before
		var invading_faction: int = _normalize_owner_faction_for_type(LevelConfig.PROVINCE_TYPE_ENEMY, int(province_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
		var mutual_losses: int = mini(combat_remaining_troops_B, defending_troops_before)
		var surviving_invaders: int = combat_remaining_troops_B - mutual_losses
		var surviving_defenders: int = defending_troops_before - mutual_losses
		defensive_ending_defenders = surviving_defenders
		var buildings_after_invasion: int = combat_remaining_buildings_B
		if surviving_invaders > 0:
			var invasion_damage: int = floori(float(surviving_invaders) / float(_main.INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT))
			buildings_after_invasion = maxi(0, combat_remaining_buildings_B - invasion_damage)

		defensive_player_result_ending_troops = combat_remaining_troops_B
		defensive_full_result_ending_troops = surviving_invaders
		summary_ending_troops = surviving_invaders
		summary_ending_buildings = buildings_after_invasion
		fully_cleared = surviving_invaders <= 0

		if buildings_after_invasion <= 0 and surviving_invaders > 0:
			conquered = true
			final_type = LevelConfig.PROVINCE_TYPE_ENEMY
			final_faction = invading_faction
			remaining_troops_B = _get_conquered_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY, province_state)
			remaining_buildings_B = _get_conquered_province_buildings(LevelConfig.PROVINCE_TYPE_ENEMY, province_state)
			final_resident_troops = remaining_troops_B
			final_invading_troops = 0
		else:
			final_type = LevelConfig.PROVINCE_TYPE_FRIENDLY
			final_faction = 0
			remaining_troops_B = surviving_invaders
			remaining_buildings_B = buildings_after_invasion
			final_resident_troops = surviving_defenders
			final_invading_troops = surviving_invaders
	else:
		if pass_condition or (met_progress and not is_neutral):
			fully_cleared = combat_remaining_troops_B <= 0 and combat_remaining_buildings_B <= 0
			if fully_cleared:
				if can_annex_to_friendly:
					annexed = true
					conquered = true
					final_type = LevelConfig.PROVINCE_TYPE_FRIENDLY
					remaining_buildings_B = _get_annexed_to_friendly_buildings(province_state, province_type)
					remaining_troops_B = _get_annexed_to_friendly_troops(province_state, province_type)
					final_faction = 0
				else:
					final_type = LevelConfig.PROVINCE_TYPE_NEUTRAL
					remaining_troops_B = 0
					remaining_buildings_B = 0
					final_faction = 0
		final_resident_troops = remaining_troops_B
		final_invading_troops = 0

	# Build outcome strings
	var phase_label: String = _get_player_phase_label(province_type)
	var troop_label: String = _get_player_troop_label(province_type)
	var building_label: String = _get_player_building_label(province_type)

	var outcome_line := ""
	var post_summary := ""
	var lock_id := -1
	var enemy_turns := 1
	var grant_reward := false

	if is_defensive:
		if conquered:
			if player_won_engagement:
				outcome_line = "You won the engagement, but the province was lost in the follow-up fighting."
			else:
				outcome_line = "You lost the engagement, and the province was lost in the follow-up fighting."
		elif final_invading_troops <= 0:
			outcome_line = "You won the engagement. Defense held and all invading troops were eliminated." if player_won_engagement else "You lost the engagement, but the defense still held. All invading troops were eliminated."
			grant_reward = true
		else:
			outcome_line = "You won the engagement. Defense held, but invaders remain in the province." if player_won_engagement else "You lost the engagement, but the defense still held and invaders remain in the province."

		if player_won_engagement:
			enemy_turns = 1
			if conquered:
				post_summary = "Friendly and enemy factions each acted once. The province fell, so your next shot must start in the closest friendly province."
				lock_id = -1 if _main.province_system == null else _main.province_system.find_nearest_friendly_province_id(province_id)
			else:
				post_summary = "Friendly and enemy factions each acted once. Your next shot starts in the highlighted province."
				lock_id = province_id
		else:
			enemy_turns = 2
			post_summary = "You lost the engagement. Friendly and enemy factions each acted once, then enemy factions acted again. Your next shot must start in the closest friendly province."
			lock_id = -1 if _main.province_system == null else _main.province_system.find_nearest_friendly_province_id(province_id)
	elif is_neutral:
		if annexed:
			outcome_line = "Ancestral Homeland annexed." if is_target_province else "Province annexed."
			grant_reward = true
			post_summary = "Friendly and enemy factions each acted once. Your next shot starts in the highlighted province."
			lock_id = province_id
		elif fully_cleared:
			outcome_line = "Neutral troops wiped out, but not adjacent to friendly land."
			grant_reward = true
			post_summary = "Friendly and enemy factions each acted once. Your next shot starts in the highlighted province."
			lock_id = province_id
		elif player_won_engagement:
			outcome_line = "You won the engagement, but full clear is still needed for annexation."
			post_summary = "Friendly and enemy factions each acted once. Your next shot starts in the highlighted province."
			lock_id = province_id
		else:
			enemy_turns = 2
			outcome_line = "You lost the engagement. Under 50% of defenders were downed."
			post_summary = "Friendly and enemy factions each acted once, then enemy factions acted again. Your next shot must start in the closest friendly province."
			lock_id = -1 if _main.province_system == null else _main.province_system.find_nearest_friendly_province_id(province_id)
	else:
		if annexed:
			outcome_line = "Ancestral Homeland secured as friendly ground." if is_target_province else "Province secured as friendly ground."
			grant_reward = true
			post_summary = "Friendly and enemy factions each acted once. Your next shot starts in the highlighted province."
			lock_id = province_id
		elif fully_cleared:
			outcome_line = "Province cleared, but not contiguous to friendly land."
			grant_reward = true
			post_summary = "Friendly and enemy factions each acted once. Your next shot starts in the highlighted province."
			lock_id = province_id
		elif player_won_engagement:
			grant_reward = true
			outcome_line = "You won the engagement and weakened the province."
			post_summary = "Friendly and enemy factions each acted once. Your next shot starts in the highlighted province."
			lock_id = province_id
		else:
			enemy_turns = 2
			outcome_line = "You lost the engagement. Under 50% of defenders were downed."
			post_summary = "Friendly and enemy factions each acted once, then enemy factions acted again. Your next shot must start in the closest friendly province."
			lock_id = -1 if _main.province_system == null else _main.province_system.find_nearest_friendly_province_id(province_id)

	if final_type == LevelConfig.PROVINCE_TYPE_ENEMY and final_faction <= 0:
		final_faction = _normalize_owner_faction_for_type(province_type, previous_faction)
	elif final_type != LevelConfig.PROVINCE_TYPE_ENEMY:
		final_faction = 0

	var owner_changed := _did_owner_change(province_type, previous_faction, final_type, final_faction)
	var construction_progress_after := 0 if owner_changed else previous_construction_progress
	var summary_text := ""
	if is_defensive:
		summary_text = _build_defensive_summary_text(
			phase_label,
			troop_label,
			"Friendly troops",
			building_label,
			troops_B,
			defensive_player_result_ending_troops,
			troops_B,
			defensive_full_result_ending_troops,
			defensive_starting_defenders,
			defensive_ending_defenders,
			buildings_B,
			summary_ending_buildings,
			outcome_line,
			post_summary,
			enemy_turns
		)
	else:
		summary_text = _build_player_summary_text(
			phase_label,
			troop_label,
			building_label,
			troops_B,
			summary_ending_troops,
			buildings_B,
			summary_ending_buildings,
			outcome_line,
			post_summary,
			enemy_turns
		)

	if grant_reward:
		_main.gold_balance += 3 if _main._is_milestone(_main.level_index) else 1

	return {
		"player_participating": true,
		"outcome_line": outcome_line,
		"post_summary_status_text": summary_text,
		"lock_province_id": lock_id,
		"enemy_turns": enemy_turns,
		"grant_reward": grant_reward,
		"final_troops_A": 0,
		"final_troops_B": remaining_troops_B,
		"final_buildings_A": buildings_A,
		"final_buildings_B": remaining_buildings_B,
		"final_resident_troops": final_resident_troops,
		"final_invading_troops": final_invading_troops,
		"player_result_starting_troops": troops_B if is_defensive else 0,
		"player_result_ending_troops": defensive_player_result_ending_troops if is_defensive else 0,
		"full_result_starting_troops": troops_B if is_defensive else 0,
		"full_result_ending_troops": defensive_full_result_ending_troops if is_defensive else 0,
		"defender_starting_troops": defensive_starting_defenders if is_defensive else 0,
		"defender_ending_troops": defensive_ending_defenders if is_defensive else 0,
		"province_type_after": final_type,
		"faction_after": final_faction,
		"construction_progress_after": construction_progress_after,
		"summary_text": summary_text,
		"conquered": conquered
	}

func _build_legacy_summary_text(phase_label: String, downed: int, total: int, buildings_lost: int, outcome_line: String, enemy_turns: int) -> String:
	var pct := 0
	if total > 0:
		pct = int(round(float(downed) / float(total) * 100.0))
	return "%s result\nTroops downed: %d/%d (%d%%) • Buildings lost: %d\n%s\nEnemy advances %d turn%s. Tap or click to return to the Grand Map." % [
		phase_label, downed, total, pct, buildings_lost, outcome_line,
		enemy_turns, "" if enemy_turns == 1 else "s"
	]

func _empty_outcome() -> Dictionary:
	return {
		"player_participating": false,
		"outcome_line": "",
		"post_summary_status_text": "",
		"lock_province_id": -1,
		"enemy_turns": 0,
		"grant_reward": false,
		"final_troops_A": 0,
		"final_troops_B": 0,
		"final_buildings_A": 0,
		"final_buildings_B": 0,
		"final_resident_troops": 0,
		"final_invading_troops": 0,
		"player_result_starting_troops": 0,
		"player_result_ending_troops": 0,
		"full_result_starting_troops": 0,
		"full_result_ending_troops": 0,
		"defender_starting_troops": 0,
		"defender_ending_troops": 0,
		"province_type_after": LevelConfig.PROVINCE_TYPE_NEUTRAL,
		"faction_after": 0,
		"construction_progress_after": 0,
		"summary_text": "",
		"conquered": false
	}

# =============================================================================
# LEGACY COMPATIBILITY WRAPPERS (kept for safe transition)
# =============================================================================
# These will be removed after all callers are updated in later files.
func begin_engagement_summary_wait(summary_text: String, post_summary_status_text: String, lock_province_id: int, enemy_turns: int, skip_province_id: int, preexisting_invaded: Array[int]) -> void:
	if _main == null:
		return

	_main._awaiting_engagement_summary_ack = true
	_main._pending_post_summary_status_text = post_summary_status_text
	_main._pending_post_summary_lock_province_id = lock_province_id
	_main._pending_post_summary_enemy_turns = maxi(0, enemy_turns)
	_main._pending_post_summary_skip_province_id = skip_province_id
	_main._pending_post_summary_preexisting_invaded_ids = preexisting_invaded.duplicate()
	_main.state = _main.GameState.LEVEL_END

	if _main.ui_bridge != null:
		var visible_text: String = summary_text if summary_text.strip_edges() != "" else post_summary_status_text
		_main.ui_bridge.ui_set_status(visible_text)
		_main.ui_bridge.sync_ui_button_states()

func finalize_engagement_summary_ack() -> void:
	if _main == null:
		return
	if not _main._awaiting_engagement_summary_ack:
		return

	var status_text: String = _main._pending_post_summary_status_text
	var lock_province_id: int = _main._pending_post_summary_lock_province_id
	var enemy_turns: int = maxi(0, _main._pending_post_summary_enemy_turns)
	var skip_province_id: int = _main._pending_post_summary_skip_province_id
	var preexisting_invaded_ids: Array[int] = _main._pending_post_summary_preexisting_invaded_ids.duplicate()

	_main._awaiting_engagement_summary_ack = false
	_main._pending_post_summary_status_text = ""
	_main._pending_post_summary_lock_province_id = -1
	_main._pending_post_summary_enemy_turns = 0
	_main._pending_post_summary_skip_province_id = -1
	_main._pending_post_summary_preexisting_invaded_ids.clear()
	_main._active_engagement_province_id = -1

	_main.level_index += maxi(1, enemy_turns)
	_main.turn_number += maxi(1, enemy_turns)

	if lock_province_id != -1:
		_main._locked_province_id_after_win = lock_province_id

	if _main.enemy_turn_system != null and enemy_turns > 0:
		if _main.enemy_turn_system.has_method("run_post_engagement_turn_sequence"):
			_main.enemy_turn_system.run_post_engagement_turn_sequence(1, enemy_turns, skip_province_id, preexisting_invaded_ids)
		else:
			_main.enemy_turn_system.run_enemy_turn_cycles(enemy_turns, skip_province_id, preexisting_invaded_ids)
		# Keep boss-arrival timing consistent with normal turn advancement.
		# Engagement summary flows can advance turns without going through
		# EnemyTurnSystem.advance_grand_map_turn_after_rest(), so we mirror the
		# same "end-of-turn arrivals" hooks here.
		var friendly_spawn_status: String = ""
		if _main.level_flow != null and _main.level_flow.has_method("maybe_activate_pending_friendly_boss_spawn"):
			friendly_spawn_status = String(_main.level_flow.call("maybe_activate_pending_friendly_boss_spawn")).strip_edges()
		if friendly_spawn_status != "" and _main.enemy_turn_system.has_method("_append_automated_engagement_log_with_priority"):
			_main.enemy_turn_system.call("_append_automated_engagement_log_with_priority", friendly_spawn_status, 98)
		if _main.has_method("_resolve_due_boss_arrivals_at_turn_end"):
			var status_lines_any: Variant = _main.call("_resolve_due_boss_arrivals_at_turn_end")
			if status_lines_any is Array and _main.enemy_turn_system.has_method("_append_automated_engagement_log_with_priority"):
				for line_any in status_lines_any:
					var spawn_line: String = String(line_any).strip_edges()
					if spawn_line != "":
						_main.enemy_turn_system.call("_append_automated_engagement_log_with_priority", spawn_line, 98)

	if _main.level_flow != null:
		_main.level_flow.generate_grand_map()
	if _main.enemy_turn_system != null and _main.enemy_turn_system.has_method("play_pending_boss_attack_province_pulses"):
		_main.enemy_turn_system.play_pending_boss_attack_province_pulses()

	if _main.ui_bridge != null:
		var visible_status_text: String = status_text
		if _main.enemy_turn_system != null:
			visible_status_text = _main.enemy_turn_system.build_automated_engagement_status_text(status_text)
		_main.ui_bridge.ui_set_status(visible_status_text)
		_main.ui_bridge.sync_ui_button_states()

func build_engagement_summary_text(phase_label: String, downed: int, total: int, buildings_lost: int, outcome_line: String, enemy_turns: int) -> String:
	return _build_legacy_summary_text(phase_label, downed, total, buildings_lost, outcome_line, enemy_turns)

func end_level() -> void:
	if _main == null:
		return
	if _main.has_method("end_level"):
		_main.call("end_level")
		return
	if _main.has_method("_finalize_ball_flight"):
		_main.call("_finalize_ball_flight")
		return
	_main.state = _main.GameState.LEVEL_END
