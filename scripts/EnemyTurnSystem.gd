extends RefCounted

const LevelConfig = preload("res://scripts/LevelConfig.gd")

var _main: Node = null
var _automated_engagement_log_entries: Array[Dictionary] = []
var _pending_boss_attack_pulse_province_ids: Array[int] = []

func _is_skip_to_end_trace_enabled() -> bool:
	if _main == null:
		return false
	if _main.has_method("_is_skip_to_end_running"):
		return bool(_main.call("_is_skip_to_end_running"))
	return false


func _log_skip_to_end_damage_trace(stage: String, details: String = "") -> void:
	if not _is_skip_to_end_trace_enabled():
		return
	var detail_suffix: String = ""
	if details.strip_edges() != "":
		detail_suffix = " | %s" % details.strip_edges()
	var line: String = "[SkipToEndDamageTrace] %s%s" % [stage, detail_suffix]
	if _main != null and _main.has_method("_append_skip_to_end_trace_line"):
		_main.call("_append_skip_to_end_trace_line", line)
	else:
		print(line)


func _get_boss_system():
	if _main == null:
		return null
	return _main.get("boss_system")


func _get_boss_pending_energy_drain() -> int:
	if _main == null:
		return 0
	if _main.has_meta("boss_pending_energy_drain"):
		return int(_main.get_meta("boss_pending_energy_drain", 0))
	return 0


func _set_boss_pending_energy_drain(value: int) -> void:
	if _main == null:
		return
	_main.set_meta("boss_pending_energy_drain", maxi(0, value))


func _clear_boss_pending_energy_drain() -> void:
	_set_boss_pending_energy_drain(0)


func _add_boss_pending_energy_drain(value: int) -> void:
	if value <= 0:
		return
	_set_boss_pending_energy_drain(_get_boss_pending_energy_drain() + value)


func _is_active_boss_home_destination(destination_id: int) -> bool:
	if destination_id < 0:
		return false
	var boss_system = _get_boss_system()
	if boss_system == null:
		return false
	if not bool(boss_system.call("is_boss_active")):
		return false
	return bool(boss_system.call("is_boss_home_province_id", destination_id))


func _is_friendly_boss_home_destination(destination_id: int) -> bool:
	if destination_id < 0:
		return false
	var boss_system = _get_boss_system()
	if boss_system == null or not boss_system.has_method("is_friendly_boss_home_province_id"):
		return false
	return bool(boss_system.call("is_friendly_boss_home_province_id", destination_id))


func _is_friendly_boss_faction_id(faction_id: int) -> bool:
	var boss_system = _get_boss_system()
	if boss_system == null or not boss_system.has_method("is_friendly_boss_faction_id"):
		return false
	return bool(boss_system.call("is_friendly_boss_faction_id", faction_id))


func _is_friendly_boss_province_state(province_state: Dictionary) -> bool:
	if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_ENEMY:
		return false
	return _is_friendly_boss_faction_id(_get_state_faction_id(province_state))


func _get_active_friendly_boss_id() -> int:
	var boss_system = _get_boss_system()
	if boss_system == null or not boss_system.has_method("get_active_boss_states"):
		return -1
	var active_states_any: Variant = boss_system.get_active_boss_states()
	if not (active_states_any is Array):
		return -1
	for state_any in active_states_any:
		if not (state_any is Dictionary):
			continue
		var boss_state: Dictionary = state_any
		if bool(boss_state.get("is_friendly_boss", false)):
			return int(boss_state.get("boss_id", -1))
	return -1


func _is_enemy_boss_faction_province_state(province_state: Dictionary) -> bool:
	if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_ENEMY:
		return false
	if _is_friendly_boss_province_state(province_state):
		return false
	return _is_boss_faction_id(_get_state_faction_id(province_state))


func _resolve_boss_home_arrival(destination_id: int, moving_troops: int, source_type: String, source_faction: int, source_id: int, province_label: String, source_province_text: String, attacker_label: String) -> bool:
	if moving_troops <= 0:
		return false
	var boss_system = _get_boss_system()
	if boss_system == null:
		return false
	if _is_friendly_boss_home_destination(destination_id):
		var destination_index: int = -1
		if _main != null and _main.province_system != null:
			destination_index = int(_main.province_system.find_persistence_index_by_id(destination_id))
		var defender_troops: int = 0
		var defender_after: int = 0
		var attacker_after: int = moving_troops
		var mutual_losses: int = 0
		var boss_damage_result: Dictionary = {}
		if destination_index >= 0:
			var destination_state: Dictionary = _main._province_persistence[destination_index]
			defender_troops = maxi(0, int(destination_state.get("remaining_troops", 0)))
			mutual_losses = mini(defender_troops, moving_troops)
			defender_after = defender_troops - mutual_losses
			if mutual_losses > 0 and boss_system.has_method("apply_home_province_troop_losses_for_home_province_id"):
				var invasion_rng: RandomNumberGenerator = _make_boss_turn_rng()
				var invasion_seed: int = int(invasion_rng.seed)
				invasion_seed += maxi(0, destination_id) * 263
				invasion_seed += maxi(0, source_id) * 97
				invasion_seed += maxi(0, moving_troops) * 17
				invasion_seed += maxi(0, source_faction) * 7
				invasion_rng.seed = invasion_seed
				boss_damage_result = boss_system.call("apply_home_province_troop_losses_for_home_province_id", mutual_losses, invasion_rng, destination_id)
				defender_after = maxi(0, int(boss_damage_result.get("remaining_troops", defender_after)))
			attacker_after = moving_troops - mutual_losses
			destination_state["remaining_troops"] = defender_after
		var boss_killed_from_losses: bool = false
		var defeated_boss_id: int = -1
		var line: String = "%s moved %d troops from %s into %s (Friendly Boss)." % [
			attacker_label,
			moving_troops,
			source_province_text,
			province_label
		]
		if attacker_after <= 0:
			line += " Both sides lost %d troop%s and the invasion ended." % [mutual_losses, "" if mutual_losses == 1 else "s"]
		elif defender_after <= 0:
			line += " The friendly boss home province was conquered."
			if destination_index >= 0:
				var destination_state: Dictionary = _main._province_persistence[destination_index]
				var conquered_counts: Dictionary = _get_conquered_province_counts(LevelConfig.PROVINCE_TYPE_ENEMY, destination_state)
				destination_state["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
				destination_state["remaining_troops"] = _get_enemy_conquest_resulting_troops(attacker_after)
				destination_state["remaining_buildings"] = int(conquered_counts.get("remaining_buildings", 0))
				destination_state["invading_troops"] = 0
				destination_state["faction_id"] = _normalize_enemy_faction_id(source_faction)
				destination_state["is_boss_home"] = false
				destination_state["is_friendly_boss_province"] = false
				_clear_capture_source_for_province(destination_id)
			if boss_system.has_method("mark_boss_dead") and boss_system.has_method("get_boss_id_for_home_province_id"):
				var home_boss_id: int = int(boss_system.call("get_boss_id_for_home_province_id", destination_id))
				if home_boss_id >= 0:
					boss_system.call("mark_boss_dead", home_boss_id)
					boss_killed_from_losses = true
					defeated_boss_id = home_boss_id
		_append_automated_engagement_log_with_priority(line, 98)
		if boss_system.has_method("append_turn_log_line"):
			boss_system.call("append_turn_log_line", line)
		if boss_killed_from_losses and _main != null and _main.level_flow != null and _main.level_flow.has_method("_on_boss_killed_from_grand_map"):
			_main.level_flow.call("_on_boss_killed_from_grand_map", defeated_boss_id)
		return true
	var energy_drain: int = int(boss_system.call("get_energy_drain_from_arriving_troops", moving_troops))
	_add_boss_pending_energy_drain(energy_drain)
	var line_template: String = "%s moved %d troops from %s into %s (Boss). The troops struck the boss"
	if energy_drain > 0:
		line_template += ", draining %d energy." % energy_drain
	else:
		line_template += ", but did not drain any energy."
	var line: String = line_template % [
		attacker_label,
		moving_troops,
		source_province_text,
		province_label
	]
	_append_automated_engagement_log_with_priority(line, 98)
	if boss_system.has_method("append_turn_log_line"):
		boss_system.call("append_turn_log_line", line)
	return true


func _resolve_enemy_boss_home_assault_from_friendly(destination_id: int, moving_troops: int, source_id: int, province_label: String, source_province_text: String) -> bool:
	if moving_troops <= 0 or _main == null:
		return false
	var boss_system = _get_boss_system()
	if boss_system == null:
		return false
	var destination_index: int = -1
	if _main.province_system != null:
		destination_index = int(_main.province_system.find_persistence_index_by_id(destination_id))
	if destination_index < 0:
		return false
	var destination_state: Dictionary = _main._province_persistence[destination_index]
	var defending_troops_before: int = maxi(0, int(destination_state.get("remaining_troops", 0)))
	var defenders_destroyed: int = mini(defending_troops_before, moving_troops)
	var attackers_lost: int = defenders_destroyed
	var surviving_attackers: int = maxi(0, moving_troops - attackers_lost)
	var loss_result: Dictionary = {}
	var hitpoints_removed: int = 0
	if defenders_destroyed > 0 and boss_system.has_method("apply_home_province_troop_losses_for_home_province_id"):
		var assault_rng: RandomNumberGenerator = _make_boss_turn_rng()
		var assault_seed: int = int(assault_rng.seed)
		assault_seed += maxi(0, destination_id) * 263
		assault_seed += maxi(0, source_id) * 97
		assault_seed += maxi(0, moving_troops) * 17
		assault_rng.seed = assault_seed
		loss_result = boss_system.call("apply_home_province_troop_losses_for_home_province_id", defenders_destroyed, assault_rng, destination_id)
		hitpoints_removed = maxi(0, int(loss_result.get("hitpoints_removed", loss_result.get("troop_chunks_applied", 0))))
	var synced_troops: int = defending_troops_before - defenders_destroyed
	if boss_system.has_method("get_boss_home_troop_count_for_home_province_id"):
		synced_troops = maxi(0, int(boss_system.get_boss_home_troop_count_for_home_province_id(destination_id)))
	elif not loss_result.is_empty():
		synced_troops = maxi(0, int(loss_result.get("remaining_troops", synced_troops)))
	destination_state["remaining_troops"] = synced_troops
	destination_state["remaining_buildings"] = 0
	destination_state["invading_troops"] = 0
	destination_state["is_boss_home"] = true
	if _main.level_flow != null and _main.level_flow.has_method("sync_active_boss_home_province_stats"):
		_main.level_flow.call("sync_active_boss_home_province_stats")
	var line: String = "Friendly moved %d troops from %s into %s (Enemy Boss Home). Defenders lost %d troop%s, boss lost %d hitpoint%s, and %d attacking troop%s were spent." % [
		moving_troops,
		source_province_text,
		province_label,
		defenders_destroyed,
		"" if defenders_destroyed == 1 else "s",
		hitpoints_removed,
		"" if hitpoints_removed == 1 else "s",
		attackers_lost,
		"" if attackers_lost == 1 else "s"
	]
	if surviving_attackers > 0:
		line += " %d attacking troop%s could not hold the province and dispersed." % [surviving_attackers, "" if surviving_attackers == 1 else "s"]
	_append_automated_engagement_log_with_priority(line, 1)
	return true


func _make_boss_turn_rng() -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var base_seed: int = 1
	if _main != null:
		base_seed = maxi(1, int(_main.get("map_seed")))
		base_seed += maxi(0, int(_main.get("turn_number"))) * 7919
		base_seed += _get_boss_pending_energy_drain() * 131
	rng.seed = int(base_seed)
	return rng

func _spawn_boss_caltrops_for_surviving_limbs(rng: RandomNumberGenerator) -> void:
	if _main == null or rng == null:
		return
	if not bool(LevelConfig.get_boss_caltrops_enabled()):
		return
	if _main.province_system == null or not _main.province_system.has_method("spawn_boss_caltrops"):
		return

	var boss_system = _get_boss_system()
	if boss_system == null or not bool(boss_system.call("is_boss_active")):
		return

	var surviving_limbs: int = int(boss_system.call("count_surviving_arms")) + int(boss_system.call("count_surviving_legs"))
	var per_limb_spawn_count: int = int(LevelConfig.get_boss_caltrops_per_surviving_limb())
	var province_spawn_count: int = maxi(0, surviving_limbs) * maxi(0, per_limb_spawn_count)
	if province_spawn_count <= 0:
		return

	var spawned_any: Variant = _main.province_system.call("spawn_boss_caltrops", province_spawn_count, rng)
	var spawned: Array = []
	if spawned_any is Array:
		spawned = spawned_any
	if spawned.is_empty():
		return

	var touched_provinces: Dictionary = {}
	for entry_any in spawned:
		if not (entry_any is Dictionary):
			continue
		var entry: Dictionary = entry_any
		touched_provinces[int(entry.get("province_id", -1))] = true

	_append_automated_engagement_log_with_priority("Boss scattered %d caltrop%s across %d province%s." % [
		spawned.size(),
		"" if spawned.size() == 1 else "s",
		touched_provinces.size(),
		"" if touched_provinces.size() == 1 else "s"
	], 98)

	if _main.province_system.has_method("apply_persistence_to_province_visuals"):
		_main.province_system.call("apply_persistence_to_province_visuals")


func _get_boss_extra_recruit_per_province() -> int:
	var boss_system = _get_boss_system()
	if boss_system == null:
		return 0
	if not bool(boss_system.call("is_boss_active")):
		return 0
	var arms_alive: int = int(boss_system.call("count_surviving_arms"))
	var legs_alive: int = int(boss_system.call("count_surviving_legs"))
	return maxi(0, arms_alive + legs_alive)


func _run_boss_turn_phase() -> void:
	var boss_system = _get_boss_system()
	if _main == null or boss_system == null:
		_clear_boss_pending_energy_drain()
		return
	if not bool(boss_system.call("is_boss_active")):
		_clear_boss_pending_energy_drain()
		return

	var pending_energy_drain: int = _get_boss_pending_energy_drain()
	var rng: RandomNumberGenerator = _make_boss_turn_rng()
	var plan: Dictionary = boss_system.call("build_boss_turn_plan", _main._province_persistence, rng, pending_energy_drain)
	var applied: Dictionary = boss_system.call("apply_boss_turn_plan", _main._province_persistence, plan)
	_spawn_boss_caltrops_for_surviving_limbs(rng)

	var energy_generated: int = int(applied.get("energy_generated", plan.get("energy_generated", 0)))
	var energy_drained: int = int(applied.get("energy_drained", plan.get("energy_drained", pending_energy_drain)))
	var energy_spent: int = int(applied.get("energy_spent", plan.get("energy_spent", 0)))
	var energy_remaining: int = int(applied.get("energy_remaining", plan.get("energy_remaining", 0)))
	_append_automated_engagement_log_with_priority("Boss generated %d energy, lost %d to incoming troops, spent %d, and ended with %d unused." % [
		energy_generated,
		energy_drained,
		energy_spent,
		energy_remaining
	], 98)

	var raw_results: Variant = applied.get("results", [])
	var attacked_province_ids: Array[int] = []
	if raw_results is Array:
		for result_any in raw_results:
			var result: Dictionary = result_any
			var province_id: int = int(result.get("province_id", -1))
			var province_label: String = _format_province_label(province_id)
			var attack_type: String = String(result.get("attack_type", ""))
			var applied_damage: int = int(result.get("applied_damage", 0))
			if province_id >= 0 and (attack_type == "punch" or attack_type == "kick") and not attacked_province_ids.has(province_id):
				attacked_province_ids.append(province_id)
			if attack_type == "punch":
				_append_automated_engagement_log_with_priority("Boss punched %s and killed %d troop%s." % [
					province_label,
					applied_damage,
					"" if applied_damage == 1 else "s"
				], 98)
			elif attack_type == "kick":
				_append_automated_engagement_log_with_priority("Boss kicked %s and destroyed %d building%s." % [
					province_label,
					applied_damage,
					"" if applied_damage == 1 else "s"
				], 98)

	_clear_boss_pending_energy_drain()
	for province_id in attacked_province_ids:
		_record_boss_attack_pulse_province_id(province_id)
	resolve_destroyed_enemy_provinces()
	if _main.province_system != null:
		_main.province_system.apply_persistence_to_province_visuals()
		if _main.province_system.has_method("flash_province_faction_fill_if_visible"):
			for province_id in attacked_province_ids:
				_main.province_system.call("flash_province_faction_fill_if_visible", province_id)


func setup(main_node: Node) -> void:
	_main = main_node
	_pending_boss_attack_pulse_province_ids.clear()


func _record_boss_attack_pulse_province_id(province_id: int) -> void:
	if province_id < 0:
		return
	if _pending_boss_attack_pulse_province_ids.has(province_id):
		return
	_pending_boss_attack_pulse_province_ids.append(province_id)


func _consume_pending_boss_attack_pulse_province_ids() -> Array[int]:
	var out: Array[int] = _pending_boss_attack_pulse_province_ids.duplicate()
	_pending_boss_attack_pulse_province_ids.clear()
	return out


func play_pending_boss_attack_province_pulses() -> void:
	if _main == null or _main.province_system == null:
		_pending_boss_attack_pulse_province_ids.clear()
		return
	if not _main.province_system.has_method("play_boss_attack_province_opacity_pulses"):
		_pending_boss_attack_pulse_province_ids.clear()
		return
	var pending_pulse_ids: Array[int] = _consume_pending_boss_attack_pulse_province_ids()
	if pending_pulse_ids.is_empty():
		return
	_main.province_system.call("play_boss_attack_province_opacity_pulses", pending_pulse_ids)


func clear_automated_engagement_log() -> void:
	_automated_engagement_log_entries.clear()
	_pending_boss_attack_pulse_province_ids.clear()


func get_automated_engagement_log_lines() -> Array[String]:
	var lines: Array[String] = []
	var ordered_priorities: Array[int] = [0, 1, 2, 3]
	for priority in ordered_priorities:
		for entry in _automated_engagement_log_entries:
			if int(entry.get("priority", 99)) != priority:
				continue
			lines.append(String(entry.get("line", "")))
	for entry in _automated_engagement_log_entries:
		var priority: int = int(entry.get("priority", 99))
		if ordered_priorities.has(priority):
			continue
		lines.append(String(entry.get("line", "")))
	return lines


func _join_lines(lines: Array[String]) -> String:
	if lines.is_empty():
		return ""
	var result: String = ""
	for i in range(lines.size()):
		if i > 0:
			result += "\n"
		result += lines[i]
	return result


func build_automated_engagement_status_text(base_status_text: String = "") -> String:
	var lines: Array[String] = []
	var trimmed_base: String = base_status_text.strip_edges()
	if trimmed_base != "":
		lines.append(trimmed_base)

	var ordered_log_lines: Array[String] = get_automated_engagement_log_lines()
	if ordered_log_lines.is_empty():
		lines.append("No automated engagements since your last shot.")
	else:
		lines.append("Automated engagements since your last shot:")
		for line in ordered_log_lines:
			lines.append(line)

	return _join_lines(lines)


func _append_automated_engagement_log(line: String) -> void:
	_append_automated_engagement_log_with_priority(line, 99)


func _append_automated_engagement_log_with_priority(line: String, priority: int) -> void:
	var trimmed: String = line.strip_edges()
	if trimmed == "":
		return
	_automated_engagement_log_entries.append({
		"priority": priority,
		"line": trimmed
	})


func _get_automated_engagement_log_priority(source_type: String, destination_type: String) -> int:
	if destination_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return 0
	if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and destination_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		return 1
	if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and destination_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return 2
	if source_type == LevelConfig.PROVINCE_TYPE_ENEMY and destination_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return 3
	return 99


func _normalize_enemy_faction_id(faction_id: int) -> int:
	if faction_id > 0:
		return faction_id
	return LevelConfig.ENEMY_FACTION_DEFAULT

func _get_initial_province_counts(province_type: String, province_state: Dictionary = {}) -> Dictionary:
	var province_system = _get_capture_source_province_system()
	if province_system != null and province_system.has_method("get_initial_province_counts"):
		var counts_any: Variant = province_system.call("get_initial_province_counts", province_type)
		if counts_any is Dictionary:
			var counts: Dictionary = counts_any
			if province_state != null and not province_state.is_empty():
				counts["remaining_buildings"] = _clamp_buildings_to_province_cap(province_state, int(counts.get("remaining_buildings", 0)))
			return counts
	return {
		"remaining_troops": LevelConfig.get_initial_province_troops(province_type),
		"remaining_buildings": _clamp_buildings_to_province_cap(province_state, LevelConfig.get_initial_province_buildings(province_type))
	}


func _get_conquered_province_counts(province_type: String, province_state: Dictionary = {}) -> Dictionary:
	var province_system = _get_capture_source_province_system()
	if province_system != null and province_system.has_method("get_conquered_province_counts"):
		var counts_any: Variant = province_system.call("get_conquered_province_counts", province_type, province_state)
		if counts_any is Dictionary:
			return counts_any
	return {
		"remaining_troops": LevelConfig.get_conquered_province_troops(province_type),
		"remaining_buildings": _clamp_buildings_to_province_cap(province_state, LevelConfig.get_conquered_province_buildings(province_type))
	}


func _get_enemy_conquest_resulting_troops(surviving_attackers: int) -> int:
	return maxi(0, int(surviving_attackers))


func _get_province_building_capacity(province_state: Dictionary) -> int:
	var province_system = _get_capture_source_province_system()
	if province_system != null and province_system.has_method("get_province_building_capacity"):
		return maxi(0, int(province_system.call("get_province_building_capacity", province_state)))
	return maxi(0, int(LevelConfig.PROVINCE_BUILDING_CAP))


func _clamp_buildings_to_province_cap(province_state: Dictionary, building_count: int) -> int:
	return clampi(int(building_count), 0, _get_province_building_capacity(province_state))


func _get_capture_source_province_system():
	if _main == null:
		return null
	return _main.province_system


func _clear_capture_source_for_province(province_id: int) -> void:
	if province_id < 0:
		return
	var province_system = _get_capture_source_province_system()
	if province_system != null and province_system.has_method("clear_province_capture_source_by_id"):
		province_system.clear_province_capture_source_by_id(province_id)


func _mark_province_captured_by_friendly_march(province_id: int) -> void:
	if province_id < 0:
		return
	var province_system = _get_capture_source_province_system()
	if province_system != null and province_system.has_method("mark_province_captured_by_friendly_march"):
		province_system.mark_province_captured_by_friendly_march(province_id)


func _update_capture_source_after_owner_change(province_id: int, previous_type: String, previous_faction: int, final_type: String, final_faction: int, source_type: String) -> void:
	if province_id < 0:
		return
	if not _did_owner_change(previous_type, previous_faction, final_type, final_faction):
		return
	if final_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		_mark_province_captured_by_friendly_march(province_id)
	else:
		_clear_capture_source_for_province(province_id)


func _set_enemy_control(province_state: Dictionary, troops: int, faction_id: int) -> void:
	province_state["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
	province_state["remaining_buildings"] = int(_get_conquered_province_counts(LevelConfig.PROVINCE_TYPE_ENEMY, province_state).get("remaining_buildings", LevelConfig.PROVINCE_ENEMY_BUILDINGS))
	province_state["remaining_troops"] = maxi(0, troops)
	province_state["invading_troops"] = 0
	province_state["faction_id"] = _normalize_enemy_faction_id(faction_id)
	_reset_construction_progress(province_state)


func _get_state_faction_id(province_state: Dictionary) -> int:
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		return _normalize_enemy_faction_id(int(province_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
	return 0


func _format_owner_label(owner_type: String, owner_faction: int = 0) -> String:
	if owner_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return "Friendly"
	if owner_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		return "Enemy %d" % _normalize_enemy_faction_id(owner_faction)
	return "Neutral"


func _find_persistent_province_state(province_id: int) -> Dictionary:
	if province_id < 0 or _main == null:
		return {}
	var raw_persistence: Variant = _main.get("_province_persistence")
	if raw_persistence is Array:
		for entry_any in raw_persistence:
			if not (entry_any is Dictionary):
				continue
			var entry: Dictionary = entry_any
			if int(entry.get("id", -1)) == province_id:
				return entry
	return {}


func _generate_fallback_province_label(province_id: int) -> String:
	if province_id < 0:
		return "Unknown Province"
	var map_seed: int = 1
	if _main != null:
		map_seed = maxi(1, int(_main.get("map_seed")))
	var generated: String = String(LevelConfig.generate_province_name(map_seed, province_id)).strip_edges()
	if not generated.is_empty():
		return generated
	return "Province %d" % province_id


func _format_province_label(province_id: int) -> String:
	if province_id < 0:
		return "Unknown Province"
	var province_state: Dictionary = _find_persistent_province_state(province_id)
	var province_name: String = String(province_state.get("province_name", "")).strip_edges()
	if not province_name.is_empty():
		return province_name
	if _main != null and _main.province_system != null and _main.province_system.has_method("get_province_display_name"):
		var resolved: String = String(_main.province_system.call("get_province_display_name", province_id, province_state)).strip_edges()
		if not resolved.is_empty():
			return resolved
	return _generate_fallback_province_label(province_id)


func _format_source_province_text(source_id: int) -> String:
	if source_id < 0:
		return "an unknown province"
	return _format_province_label(source_id)


func _get_invading_source_ids(province_state: Dictionary) -> Array[int]:
	var ids: Array[int] = []
	var raw_ids: Variant = province_state.get("invading_source_ids", [])
	if raw_ids is Array:
		for entry in raw_ids:
			var source_id: int = int(entry)
			if source_id < 0:
				continue
			if not ids.has(source_id):
				ids.append(source_id)
	ids.sort()
	return ids


func _append_invading_source_id(province_state: Dictionary, source_id: int) -> void:
	if source_id < 0:
		return
	var ids: Array[int] = _get_invading_source_ids(province_state)
	if not ids.has(source_id):
		ids.append(source_id)
		ids.sort()
	province_state["invading_source_ids"] = ids


func _clear_invading_source_ids(province_state: Dictionary) -> void:
	province_state["invading_source_ids"] = []


func _get_pending_invasion_started_turn(province_state: Dictionary) -> int:
	return int(province_state.get("pending_invasion_started_turn", -1))


func _set_pending_invasion_started_turn(province_state: Dictionary, started_turn: int) -> void:
	province_state["pending_invasion_started_turn"] = started_turn


func _should_resolve_pending_invasion_this_enemy_phase(province_state: Dictionary) -> bool:
	if int(province_state.get("invading_troops", 0)) <= 0:
		return false
	var started_turn: int = _get_pending_invasion_started_turn(province_state)
	if started_turn < 0:
		return true
	if _main == null:
		return true
	return started_turn < int(_main.get("turn_number"))


func _clear_pending_invasion(province_state: Dictionary) -> void:
	province_state["invading_troops"] = 0
	_clear_invading_source_ids(province_state)
	_set_pending_invasion_started_turn(province_state, -1)
	if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		province_state["faction_id"] = 0


func _start_pending_invasion(province_state: Dictionary, invading_troops: int, invading_faction: int, source_id: int = -1, preserve_started_turn: bool = false) -> void:
	var troops: int = maxi(0, invading_troops)
	if troops <= 0:
		_clear_pending_invasion(province_state)
		return
	var started_turn: int = -1
	if preserve_started_turn:
		started_turn = _get_pending_invasion_started_turn(province_state)
	if started_turn < 0 and _main != null:
		started_turn = int(_main.get("turn_number"))
	province_state["invading_troops"] = troops
	province_state["faction_id"] = _normalize_enemy_faction_id(invading_faction)
	_clear_invading_source_ids(province_state)
	_append_invading_source_id(province_state, source_id)
	_set_pending_invasion_started_turn(province_state, started_turn)


func _get_owner_faction_for_type(owner_type: String, province_state: Dictionary) -> int:
	if owner_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		return _get_state_faction_id(province_state)
	return 0


func _did_owner_change(previous_type: String, previous_faction: int, new_type: String, new_faction: int) -> bool:
	if previous_type != new_type:
		return true
	if new_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		return _normalize_enemy_faction_id(previous_faction) != _normalize_enemy_faction_id(new_faction)
	return false


func _reset_construction_progress(province_state: Dictionary) -> void:
	province_state["construction_progress"] = 0


func _complete_construction_from_progress(province_state: Dictionary, added_progress: int) -> int:
	var build_cost: int = maxi(1, LevelConfig.PROVINCE_BUILDING_TROOP_TURNS_PER_BUILDING)
	var building_cap: int = _get_province_building_capacity(province_state)
	var current_buildings: int = maxi(0, int(province_state.get("remaining_buildings", 0)))
	if current_buildings > building_cap:
		current_buildings = building_cap
		province_state["remaining_buildings"] = current_buildings
	if current_buildings >= building_cap:
		province_state["construction_progress"] = 0
		return 0

	var progress_before: int = int(province_state.get("construction_progress", 0))
	var total_progress: int = progress_before + maxi(0, added_progress)
	var builds_completed: int = 0
	if total_progress >= build_cost:
		builds_completed = int(total_progress / build_cost)
		var available_slots: int = building_cap - current_buildings
		if builds_completed > available_slots:
			builds_completed = available_slots
		if current_buildings + builds_completed >= building_cap:
			total_progress = 0
		else:
			total_progress = int(total_progress % build_cost)
	province_state["construction_progress"] = total_progress
	if builds_completed > 0:
		province_state["remaining_buildings"] = current_buildings + builds_completed
	return builds_completed


func process_province_construction(include_friendly_provinces: bool = true) -> void:
	if _main == null:
		return

	for province_state in _main._province_persistence:
		var province_id: int = int(province_state.get("id", -1))
		if _is_active_boss_home_destination(province_id):
			province_state["remaining_buildings"] = 0
			province_state["construction_progress"] = 0
			continue
		var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		if not include_friendly_provinces and province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		var resident_troops: int = int(province_state.get("remaining_troops", 0))
		if resident_troops < LevelConfig.PROVINCE_BUILDING_MIN_TROOPS_TO_BUILD:
			continue
		_complete_construction_from_progress(province_state, resident_troops)

	if _main.province_system != null:
		_main.province_system.apply_persistence_to_province_visuals()


func _format_source_provinces_text(source_ids: Array[int]) -> String:
	if source_ids.is_empty():
		return "an unknown province"
	if source_ids.size() == 1:
		return _format_province_label(source_ids[0])
	var labels: Array[String] = []
	for source_id in source_ids:
		labels.append(_format_province_label(source_id))
	return ", ".join(labels)


func _format_remaining_forces_text(troops: int, buildings: int) -> String:
	var parts: Array[String] = []
	parts.append("%d troop%s" % [troops, "" if troops == 1 else "s"])
	parts.append("%d building%s" % [buildings, "" if buildings == 1 else "s"])
	return ", ".join(parts)


func _is_same_owner_state(province_state: Dictionary, owner_type: String, owner_faction: int) -> bool:
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if owner_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY
	if owner_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		return province_type == LevelConfig.PROVINCE_TYPE_ENEMY and _get_state_faction_id(province_state) == _normalize_enemy_faction_id(owner_faction)
	return false


func _get_boss_faction_id() -> int:
	var boss_system = _get_boss_system()
	if boss_system == null or not boss_system.has_method("get_boss_faction_id"):
		return -1
	return int(boss_system.call("get_boss_faction_id"))


func _get_all_boss_faction_ids() -> Array[int]:
	var ids: Array[int] = []
	var boss_system = _get_boss_system()
	if boss_system != null and boss_system.has_method("get_all_boss_faction_ids"):
		var raw_ids: Variant = boss_system.call("get_all_boss_faction_ids")
		if raw_ids is Array:
			for id_any in raw_ids:
				var faction_id: int = _normalize_enemy_faction_id(int(id_any))
				if faction_id >= 0 and not ids.has(faction_id):
					ids.append(faction_id)
	if ids.is_empty():
		var boss_faction_id: int = _get_boss_faction_id()
		if boss_faction_id >= 0:
			ids.append(_normalize_enemy_faction_id(boss_faction_id))
	return ids


func _is_boss_faction_id(faction_id: int) -> bool:
	var normalized_faction_id: int = _normalize_enemy_faction_id(faction_id)
	for boss_faction_id in _get_all_boss_faction_ids():
		if normalized_faction_id == boss_faction_id:
			return true
	return false


func _is_boss_faction_owner(owner_type: String, owner_faction: int) -> bool:
	if owner_type != LevelConfig.PROVINCE_TYPE_ENEMY:
		return false
	return _is_boss_faction_id(owner_faction)


func _is_rival_boss_faction_target(province_state: Dictionary, owner_type: String, owner_faction: int) -> bool:
	if owner_type != LevelConfig.PROVINCE_TYPE_ENEMY:
		return false
	if not _is_boss_faction_id(owner_faction):
		return false
	if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_ENEMY:
		return false
	var province_faction: int = _get_state_faction_id(province_state)
	return _is_boss_faction_id(province_faction) and province_faction != _normalize_enemy_faction_id(owner_faction)


func _should_ignore_boss_home_for_marching(province_id: int) -> bool:
	if province_id < 0:
		return false
	if not _is_active_boss_home_destination(province_id):
		return false
	return not _is_friendly_boss_home_destination(province_id)


func _is_enemy_boss_home_destination(province_id: int) -> bool:
	if province_id < 0:
		return false
	return _is_active_boss_home_destination(province_id) and not _is_friendly_boss_home_destination(province_id)


func _get_effective_march_neighbors(current_state: Dictionary, snapshot_by_id: Dictionary) -> Array[int]:
	var direct_neighbors: Array[int] = []
	if _main != null and _main.province_system != null:
		direct_neighbors = _main.province_system.normalize_neighbor_ids(current_state.get("neighbors", []))
	var out: Array[int] = []
	var seen: Dictionary = {}
	for neighbor_id in direct_neighbors:
		var normalized_neighbor_id: int = int(neighbor_id)
		if not snapshot_by_id.has(normalized_neighbor_id):
			continue
		if _should_ignore_boss_home_for_marching(normalized_neighbor_id):
			var boss_home_state: Dictionary = snapshot_by_id.get(normalized_neighbor_id, {})
			var bridge_neighbors: Array[int] = []
			if _main != null and _main.province_system != null:
				bridge_neighbors = _main.province_system.normalize_neighbor_ids(boss_home_state.get("neighbors", []))
			for bridge_neighbor_id in bridge_neighbors:
				var normalized_bridge_neighbor_id: int = int(bridge_neighbor_id)
				if normalized_bridge_neighbor_id == int(current_state.get("id", -1)):
					continue
				if _should_ignore_boss_home_for_marching(normalized_bridge_neighbor_id):
					continue
				if not snapshot_by_id.has(normalized_bridge_neighbor_id):
					continue
				if seen.has(normalized_bridge_neighbor_id):
					continue
				seen[normalized_bridge_neighbor_id] = true
				out.append(normalized_bridge_neighbor_id)
			continue
		if seen.has(normalized_neighbor_id):
			continue
		seen[normalized_neighbor_id] = true
		out.append(normalized_neighbor_id)
	out.sort()
	return out


func _append_enemy_boss_home_neighbors_for_friendly(current_state: Dictionary, snapshot_by_id: Dictionary, neighbors: Array[int]) -> Array[int]:
	if _main == null or _main.province_system == null:
		return neighbors
	var out: Array[int] = neighbors.duplicate()
	var seen: Dictionary = {}
	for neighbor_id in out:
		seen[int(neighbor_id)] = true
	var direct_neighbors: Array[int] = _main.province_system.normalize_neighbor_ids(current_state.get("neighbors", []))
	for neighbor_id in direct_neighbors:
		var normalized_neighbor_id: int = int(neighbor_id)
		if seen.has(normalized_neighbor_id):
			continue
		if not _is_enemy_boss_home_destination(normalized_neighbor_id):
			continue
		if not snapshot_by_id.has(normalized_neighbor_id):
			continue
		seen[normalized_neighbor_id] = true
		out.append(normalized_neighbor_id)
	out.sort()
	return out


func _should_ignore_boss_home_as_march_source(province_id: int, owner_type: String, owner_faction: int) -> bool:
	if province_id < 0:
		return false
	if _is_active_boss_home_destination(province_id):
		return true
	if not _should_ignore_boss_home_for_marching(province_id):
		return false
	return true


func _is_frontline_target_for_owner(province_state: Dictionary, owner_type: String, owner_faction: int, allow_rival_boss_faction_targets: bool = true, allow_friendly_boss_home_target: bool = false, allow_enemy_boss_home_target: bool = false) -> bool:
	var province_id: int = int(province_state.get("id", -1))
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var is_enemy_boss_home_target: bool = _is_enemy_boss_home_destination(province_id)
	if _should_ignore_boss_home_as_march_source(province_id, owner_type, owner_faction):
		if not (owner_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and allow_enemy_boss_home_target and is_enemy_boss_home_target):
			return false
	if owner_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		if is_enemy_boss_home_target:
			return allow_enemy_boss_home_target
		if _is_friendly_boss_province_state(province_state):
			return allow_friendly_boss_home_target
		if _is_friendly_boss_home_destination(province_id):
			return allow_friendly_boss_home_target
		return province_type != LevelConfig.PROVINCE_TYPE_FRIENDLY
	if owner_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		if province_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
			if _is_friendly_boss_faction_id(owner_faction):
				return false
			return true
		if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			if _is_friendly_boss_faction_id(owner_faction):
				return false
			return true
		if province_type == LevelConfig.PROVINCE_TYPE_ENEMY and _get_state_faction_id(province_state) != _normalize_enemy_faction_id(owner_faction):
			if not allow_rival_boss_faction_targets and _is_rival_boss_faction_target(province_state, owner_type, owner_faction):
				return false
			return true
	return false


func _reconstruct_path(parent: Dictionary, target_id: int) -> Array[int]:
	var path: Array[int] = [target_id]
	var walk_id: int = target_id
	while parent.has(walk_id):
		walk_id = int(parent[walk_id])
		path.push_front(walk_id)
	return path


func _find_frontline_path_for_policy(source_id: int, snapshot_by_id: Dictionary, allow_rival_boss_faction_targets: bool, allow_friendly_boss_home_target: bool = false, allow_enemy_boss_home_target: bool = false) -> Array[int]:
	if not snapshot_by_id.has(source_id):
		return []

	var source_state: Dictionary = snapshot_by_id.get(source_id, {})
	var source_type: String = String(source_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if source_type != LevelConfig.PROVINCE_TYPE_ENEMY and source_type != LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return []

	var source_faction: int = 0
	if source_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		source_faction = _get_state_faction_id(source_state)

	if _should_ignore_boss_home_as_march_source(source_id, source_type, source_faction):
		return []

	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array[int] = [source_id]
	visited[source_id] = true

	var queue_index: int = 0
	while queue_index < queue.size():
		var current_id: int = int(queue[queue_index])
		queue_index += 1

		var current_state: Dictionary = snapshot_by_id.get(current_id, {})
		var current_is_enemy_boss_home: bool = _is_enemy_boss_home_destination(current_id)
		if current_id != source_id and _should_ignore_boss_home_for_marching(current_id):
			if not (source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and allow_enemy_boss_home_target and current_is_enemy_boss_home):
				continue
		if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and current_id != source_id and _is_friendly_boss_province_state(current_state) and not allow_friendly_boss_home_target:
			continue
		if current_id != source_id and _is_frontline_target_for_owner(current_state, source_type, source_faction, allow_rival_boss_faction_targets, allow_friendly_boss_home_target, allow_enemy_boss_home_target):
			return _reconstruct_path(parent, current_id)

		var neighbors: Array[int] = _get_effective_march_neighbors(current_state, snapshot_by_id)
		if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and allow_enemy_boss_home_target:
			neighbors = _append_enemy_boss_home_neighbors_for_friendly(current_state, snapshot_by_id, neighbors)

		for neighbor_id in neighbors:
			if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
				var neighbor_state: Dictionary = snapshot_by_id.get(neighbor_id, {})
				if _is_friendly_boss_province_state(neighbor_state) and not allow_friendly_boss_home_target:
					continue
			if visited.has(neighbor_id):
				continue
			visited[neighbor_id] = true
			parent[neighbor_id] = current_id
			queue.append(neighbor_id)

	return []


func _find_frontline_path(source_id: int, snapshot_by_id: Dictionary) -> Array[int]:
	if not snapshot_by_id.has(source_id):
		return []
	var source_state: Dictionary = snapshot_by_id.get(source_id, {})
	var source_type: String = String(source_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if source_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		var source_faction: int = _get_state_faction_id(source_state)
		if _is_boss_faction_id(source_faction):
			var cooperative_path: Array[int] = _find_frontline_path_for_policy(source_id, snapshot_by_id, false)
			if not cooperative_path.is_empty():
				return cooperative_path
	var default_path: Array[int] = _find_frontline_path_for_policy(source_id, snapshot_by_id, true)
	if not default_path.is_empty():
		return default_path
	if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		if _has_non_boss_home_frontline_targets_for_friendly(snapshot_by_id):
			return []
		return _find_frontline_path_for_policy(source_id, snapshot_by_id, true, false, true)
	return default_path


func _has_non_boss_home_frontline_targets_for_friendly(snapshot_by_id: Dictionary) -> bool:
	for province_state_variant in snapshot_by_id.values():
		var province_state: Dictionary = province_state_variant
		if _is_frontline_target_for_owner(province_state, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, true, false, false):
			return true
	return false


func _find_enemy_boss_home_path_for_friendly(source_id: int, snapshot_by_id: Dictionary) -> Array[int]:
	if not snapshot_by_id.has(source_id):
		return []
	var source_state: Dictionary = snapshot_by_id.get(source_id, {})
	if String(source_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return []
	if _should_ignore_boss_home_as_march_source(source_id, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0):
		return []

	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array[int] = [source_id]
	visited[source_id] = true
	var queue_index: int = 0

	while queue_index < queue.size():
		var current_id: int = int(queue[queue_index])
		queue_index += 1
		var current_state: Dictionary = snapshot_by_id.get(current_id, {})
		if current_id != source_id and _is_enemy_boss_home_destination(current_id):
			return _reconstruct_path(parent, current_id)

		var neighbors: Array[int] = _get_effective_march_neighbors(current_state, snapshot_by_id)
		neighbors = _append_enemy_boss_home_neighbors_for_friendly(current_state, snapshot_by_id, neighbors)
		for neighbor_id in neighbors:
			if visited.has(neighbor_id):
				continue
			var neighbor_state: Dictionary = snapshot_by_id.get(neighbor_id, {})
			if _is_friendly_boss_province_state(neighbor_state):
				continue
			visited[neighbor_id] = true
			parent[neighbor_id] = current_id
			queue.append(neighbor_id)

	return []


func resolve_destroyed_enemy_provinces() -> Array[int]:
	var changed_ids: Array[int] = []
	if _main == null:
		return changed_ids

	var changed_any: bool = true
	while changed_any:
		changed_any = false
		for province_state in _main._province_persistence:
			if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_ENEMY:
				continue
			if _is_active_boss_home_destination(int(province_state.get("id", -1))):
				continue
			if int(province_state.get("remaining_troops", 0)) > 0:
				continue
			if int(province_state.get("remaining_buildings", 0)) > 0:
				continue

			var province_id: int = int(province_state.get("id", -1))
			var has_friendly_neighbor: bool = false
			if _main.province_system != null:
				has_friendly_neighbor = _main.province_system.province_has_friendly_neighbor(province_state)

			if has_friendly_neighbor:
				var conquered_counts: Dictionary = _get_conquered_province_counts(LevelConfig.PROVINCE_TYPE_FRIENDLY, province_state)
				province_state["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
				province_state["remaining_troops"] = int(conquered_counts.get("remaining_troops", 0))
				province_state["remaining_buildings"] = int(conquered_counts.get("remaining_buildings", LevelConfig.PROVINCE_FRIENDLY_BUILDINGS))
				province_state["invading_troops"] = 0
				province_state["faction_id"] = 0
				_clear_invading_source_ids(province_state)
				_reset_construction_progress(province_state)
				_clear_capture_source_for_province(province_id)
			else:
				province_state["type"] = LevelConfig.PROVINCE_TYPE_NEUTRAL
				province_state["remaining_troops"] = 0
				province_state["remaining_buildings"] = 0
				province_state["invading_troops"] = 0
				province_state["faction_id"] = 0
				_clear_invading_source_ids(province_state)
				_reset_construction_progress(province_state)
				_clear_capture_source_for_province(province_id)

			if not changed_ids.has(province_id):
				changed_ids.append(province_id)
			changed_any = true

	if not changed_ids.is_empty():
		changed_ids.sort()
		if _main.province_system != null:
			_main.province_system.apply_persistence_to_province_visuals()

	return changed_ids


# =============================================================================
# UNIFIED NON-PLAYER ENGAGEMENTS (all now route through resolver)
# =============================================================================
func resolve_march_arrival(destination_id: int, moving_troops: int, source_type: String = LevelConfig.PROVINCE_TYPE_ENEMY, source_faction: int = LevelConfig.ENEMY_FACTION_DEFAULT, source_id: int = -1) -> bool:
	if _main == null or moving_troops <= 0:
		return false

	if source_type != LevelConfig.PROVINCE_TYPE_FRIENDLY:
		source_type = LevelConfig.PROVINCE_TYPE_ENEMY
		source_faction = _normalize_enemy_faction_id(source_faction)
	else:
		source_faction = 0

	if _should_ignore_boss_home_as_march_source(source_id, source_type, source_faction):
		return false
	if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and _is_friendly_boss_home_destination(destination_id):
		return false
	if _should_ignore_boss_home_for_marching(destination_id):
		if not (source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and _is_enemy_boss_home_destination(destination_id)):
			return false

	var destination_index: int = -1
	if _main.province_system != null:
		destination_index = int(_main.province_system.find_persistence_index_by_id(destination_id))
	if destination_index == -1:
		return false

	var destination_state: Dictionary = _main._province_persistence[destination_index]
	var destination_type: String = String(destination_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var destination_faction: int = _get_state_faction_id(destination_state)
	var destination_owner_faction_before: int = _get_owner_faction_for_type(destination_type, destination_state)
	var destination_troops_before: int = int(destination_state.get("remaining_troops", 0))
	var destination_buildings_before: int = int(destination_state.get("remaining_buildings", 0))
	var attacker_label: String = _format_owner_label(source_type, source_faction)
	var province_label: String = _format_province_label(destination_id)
	var source_province_text: String = _format_source_province_text(source_id)
	var destination_owner_before: String = _format_owner_label(destination_type, destination_faction)

	if source_type == LevelConfig.PROVINCE_TYPE_ENEMY and _is_active_boss_home_destination(destination_id) and _is_friendly_boss_home_destination(destination_id) and not _is_same_owner_state(destination_state, source_type, source_faction):
		return _resolve_boss_home_arrival(destination_id, moving_troops, source_type, source_faction, source_id, province_label, source_province_text, attacker_label)
	if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and _is_enemy_boss_home_destination(destination_id):
		return _resolve_enemy_boss_home_assault_from_friendly(destination_id, moving_troops, source_id, province_label, source_province_text)

	if source_type == LevelConfig.PROVINCE_TYPE_ENEMY and destination_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and _is_friendly_boss_faction_id(source_faction):
		return false

	if _is_same_owner_state(destination_state, source_type, source_faction):
		destination_state["remaining_troops"] = int(destination_state.get("remaining_troops", 0)) + moving_troops
		return true

	if source_type == LevelConfig.PROVINCE_TYPE_ENEMY and destination_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		var existing_invading_troops: int = int(destination_state.get("invading_troops", 0))
		if existing_invading_troops <= 0:
			_start_pending_invasion(destination_state, moving_troops, source_faction, source_id)
			_append_automated_engagement_log_with_priority("%s moved %d troops from %s into %s (%s-owned). The invasion is pending." % [
				attacker_label,
				moving_troops,
				source_province_text,
				province_label,
				destination_owner_before
			], _get_automated_engagement_log_priority(source_type, destination_type))
			return true

		var existing_invading_faction: int = _normalize_enemy_faction_id(int(destination_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
		if existing_invading_faction == source_faction:
			destination_state["invading_troops"] = existing_invading_troops + moving_troops
			_append_invading_source_id(destination_state, source_id)
			_append_automated_engagement_log_with_priority("%s moved %d troops from %s into %s (%s-owned). The pending invasion was reinforced to %d troops." % [
				attacker_label,
				moving_troops,
				source_province_text,
				province_label,
				destination_owner_before,
				int(destination_state.get("invading_troops", 0))
			], _get_automated_engagement_log_priority(source_type, destination_type))
			return true

		var existing_attacker_label: String = _format_owner_label(LevelConfig.PROVINCE_TYPE_ENEMY, existing_invading_faction)
		var existing_source_ids: Array[int] = _get_invading_source_ids(destination_state)
		var existing_source_text: String = _format_source_provinces_text(existing_source_ids)
		var mutual_losses: int = mini(existing_invading_troops, moving_troops)
		var remaining_existing: int = existing_invading_troops - mutual_losses
		var remaining_new: int = moving_troops - mutual_losses
		if remaining_existing > 0:
			destination_state["invading_troops"] = remaining_existing
			destination_state["faction_id"] = existing_invading_faction
			_append_automated_engagement_log_with_priority("%s moved %d troops from %s into %s (%s-owned), where %s already had a pending invasion from %s. The invading armies fought each other, and %s kept the invasion with %d troop%s remaining." % [
				attacker_label,
				moving_troops,
				source_province_text,
				province_label,
				destination_owner_before,
				existing_attacker_label,
				existing_source_text,
				existing_attacker_label,
				remaining_existing,
				"" if remaining_existing == 1 else "s"
			], _get_automated_engagement_log_priority(source_type, destination_type))
			return true
		if remaining_new > 0:
			_start_pending_invasion(destination_state, remaining_new, source_faction, source_id, true)
			_append_automated_engagement_log_with_priority("%s moved %d troops from %s into %s (%s-owned), where %s already had a pending invasion from %s. The invading armies fought each other, and %s took over the invasion with %d troop%s remaining." % [
				attacker_label,
				moving_troops,
				source_province_text,
				province_label,
				destination_owner_before,
				existing_attacker_label,
				existing_source_text,
				attacker_label,
				remaining_new,
				"" if remaining_new == 1 else "s"
			], _get_automated_engagement_log_priority(source_type, destination_type))
			return true

		_clear_pending_invasion(destination_state)
		_append_automated_engagement_log_with_priority("%s moved %d troops from %s into %s (%s-owned), where %s already had a pending invasion from %s. The invading armies destroyed each other, so the province is no longer under invasion." % [
			attacker_label,
			moving_troops,
			source_province_text,
			province_label,
			destination_owner_before,
			existing_attacker_label,
			existing_source_text
		], _get_automated_engagement_log_priority(source_type, destination_type))
		return true

	var input_dict := {
		"player_participating": false,
		"troops_A": moving_troops,
		"troops_B": destination_troops_before,
		"buildings_A": 0,
		"buildings_B": destination_buildings_before,
		"player_downed_troops": 0,
		"player_destroyed_buildings": 0,
		"province_id": destination_id,
		"attacker_type": source_type,
		"attacker_faction_id": source_faction
	}

	var outcome: Dictionary = {}
	if _main.engagement_resolver != null:
		outcome = _main.engagement_resolver.resolve_engagement(input_dict)

	var final_troops_B: int = int(outcome.get("final_troops_B", destination_troops_before))
	var final_buildings_B: int = int(outcome.get("final_buildings_B", destination_buildings_before))
	var final_type: String = String(outcome.get("province_type_after", destination_type))
	var final_faction: int = int(outcome.get("faction_after", destination_faction if destination_type == LevelConfig.PROVINCE_TYPE_ENEMY else 0))
	var conquered: bool = bool(outcome.get("conquered", false))
	var surviving_attackers: int = maxi(0, moving_troops - destination_troops_before)
	if conquered:
		var conquered_counts: Dictionary = _get_conquered_province_counts(final_type, destination_state)
		final_buildings_B = int(conquered_counts.get("remaining_buildings", final_buildings_B))
		if final_type == LevelConfig.PROVINCE_TYPE_ENEMY:
			final_troops_B = _get_enemy_conquest_resulting_troops(surviving_attackers)
			final_faction = _normalize_enemy_faction_id(final_faction)
		else:
			if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
				final_troops_B = maxi(0, surviving_attackers)
			else:
				final_troops_B = int(conquered_counts.get("remaining_troops", final_troops_B))
			final_faction = 0

	final_buildings_B = _clamp_buildings_to_province_cap(destination_state, final_buildings_B)
	destination_state["remaining_troops"] = final_troops_B
	destination_state["remaining_buildings"] = final_buildings_B
	destination_state["type"] = final_type
	destination_state["invading_troops"] = 0
	destination_state["faction_id"] = final_faction
	_clear_invading_source_ids(destination_state)
	if _did_owner_change(destination_type, destination_owner_faction_before, final_type, final_faction):
		_reset_construction_progress(destination_state)
	_update_capture_source_after_owner_change(destination_id, destination_type, destination_owner_faction_before, final_type, final_faction, source_type)

	if not conquered and source_type == LevelConfig.PROVINCE_TYPE_ENEMY and destination_type == LevelConfig.PROVINCE_TYPE_ENEMY and surviving_attackers > 0 and source_id >= 0 and _main.province_system != null:
		var source_index: int = int(_main.province_system.find_persistence_index_by_id(source_id))
		if source_index >= 0:
			var source_state: Dictionary = _main._province_persistence[source_index]
			if String(source_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_ENEMY and _get_state_faction_id(source_state) == _normalize_enemy_faction_id(source_faction):
				source_state["remaining_troops"] = int(source_state.get("remaining_troops", 0)) + surviving_attackers

	if conquered:
		_append_automated_engagement_log_with_priority("%s moved %d troops from %s into %s (%s-owned). %s was conquered and %d troop%s remain." % [
			attacker_label,
			moving_troops,
			source_province_text,
			province_label,
			destination_owner_before,
			province_label,
			final_troops_B,
			"" if final_troops_B == 1 else "s"
		], _get_automated_engagement_log_priority(source_type, destination_type))
	else:
		_append_automated_engagement_log_with_priority("%s moved %d troops from %s into %s (%s-owned). The province held with %s remaining." % [
			attacker_label,
			moving_troops,
			source_province_text,
			province_label,
			destination_owner_before,
			_format_remaining_forces_text(final_troops_B, final_buildings_B)
		], _get_automated_engagement_log_priority(source_type, destination_type))
	return true


func resolve_enemy_march_arrival(destination_id: int, moving_troops: int, source_faction: int = LevelConfig.ENEMY_FACTION_DEFAULT, source_id: int = -1) -> bool:
	return resolve_march_arrival(destination_id, moving_troops, LevelConfig.PROVINCE_TYPE_ENEMY, source_faction, source_id)


func _get_enemy_march_leave_behind() -> int:
	if _main == null:
		return 0
	if _main.has_method("get_enemy_march_leave_behind"):
		return maxi(0, int(_main.call("get_enemy_march_leave_behind")))
	return maxi(0, int(_main.ENEMY_MARCH_LEAVE_BEHIND))


func _get_march_threshold_for_snapshot(snapshot_state: Dictionary) -> int:
	if _main == null:
		return 1

	var province_type: String = String(snapshot_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		if _main.has_method("get_friendly_march_threshold"):
			return maxi(1, int(_main.call("get_friendly_march_threshold")))
		return maxi(1, int(_main.FRIENDLY_MARCH_THRESHOLD))

	if province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		var boss_system = _main.get_node_or_null("BossSystem")
		var boss_faction_id: int = -1
		if boss_system != null and boss_system.has_method("get_boss_faction_id"):
			boss_faction_id = int(boss_system.call("get_boss_faction_id"))
		var province_faction: int = _normalize_enemy_faction_id(int(snapshot_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
		if boss_faction_id >= 0 and province_faction == boss_faction_id:
			if _main.has_method("get_boss_march_threshold"):
				return maxi(1, int(_main.call("get_boss_march_threshold")))
			return maxi(1, int(_main.BOSS_MARCH_THRESHOLD))

		if _main.has_method("get_enemy_march_threshold"):
			return maxi(1, int(_main.call("get_enemy_march_threshold")))
		return maxi(1, int(_main.ENEMY_MARCH_THRESHOLD))

	return maxi(1, int(_main.ENEMY_MARCH_THRESHOLD))


func run_enemy_march_phase(include_friendly_sources: bool = true) -> void:
	if _main == null:
		return

	var snapshot_by_id: Dictionary = {}
	if _main.province_system != null:
		snapshot_by_id = _main.province_system.make_province_snapshot_by_id()

	var source_ids: Array[int] = []
	var friendly_boss_home_march_metrics: Dictionary = {
		"sources_considered": 0,
		"sources_with_direct_enemy_boss_home_neighbor": 0,
		"planned_moves_to_enemy_boss_home": 0,
		"arrival_attempts": 0,
		"arrival_successes": 0
	}

	for p in _main._province_persistence:
		var province_id: int = int(p.get("id", -1))
		var province_type: String = String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		if province_type != LevelConfig.PROVINCE_TYPE_ENEMY and province_type != LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue

		var snapshot_state: Dictionary = snapshot_by_id.get(province_id, {})
		if not include_friendly_sources and province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		var province_faction: int = 0
		if province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
			province_faction = _normalize_enemy_faction_id(int(snapshot_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
		if _should_ignore_boss_home_as_march_source(province_id, province_type, province_faction):
			continue
		var troops: int = int(snapshot_state.get("remaining_troops", 0))
		var march_threshold: int = _get_march_threshold_for_snapshot(snapshot_state)
		if troops >= march_threshold:
			source_ids.append(province_id)

	source_ids.sort()

	for source_id in source_ids:
		var source_index: int = -1
		if _main.province_system != null:
			source_index = int(_main.province_system.find_persistence_index_by_id(source_id))
		if source_index == -1:
			continue
		var source_state: Dictionary = _main._province_persistence[source_index]
		var source_type: String = String(source_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		if not include_friendly_sources and source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		if source_type != LevelConfig.PROVINCE_TYPE_FRIENDLY and source_type != LevelConfig.PROVINCE_TYPE_ENEMY:
			continue

		var source_faction: int = 0
		if source_type == LevelConfig.PROVINCE_TYPE_ENEMY:
			source_faction = _normalize_enemy_faction_id(int(source_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
		if _should_ignore_boss_home_as_march_source(source_id, source_type, source_faction):
			continue

		var leave_behind: int = _get_enemy_march_leave_behind()
		var source_troops_before: int = maxi(0, int(source_state.get("remaining_troops", 0)))
		var marchable_troops: int = source_troops_before
		if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			var boss_system = _get_boss_system()
			var friendly_boss_id: int = _get_active_friendly_boss_id()
			if friendly_boss_id >= 0 and boss_system != null and boss_system.has_method("get_boss_current_province_id") and boss_system.has_method("get_boss_home_troop_count"):
				var boss_province_id: int = int(boss_system.get_boss_current_province_id(friendly_boss_id))
				if boss_province_id == source_id:
					marchable_troops = maxi(0, source_troops_before - int(boss_system.get_boss_home_troop_count(friendly_boss_id)))
		var moving_troops: int = maxi(0, marchable_troops - leave_behind)
		if moving_troops <= 0:
			continue

		var live_snapshot_by_id: Dictionary = {}
		if _main.province_system != null:
			live_snapshot_by_id = _main.province_system.make_province_snapshot_by_id()
		var live_source_state: Dictionary = live_snapshot_by_id.get(source_id, {})

		if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			friendly_boss_home_march_metrics["sources_considered"] = int(friendly_boss_home_march_metrics.get("sources_considered", 0)) + 1
			var direct_neighbors: Array[int] = []
			if _main.province_system != null:
				direct_neighbors = _main.province_system.normalize_neighbor_ids(live_source_state.get("neighbors", []))
			var has_direct_enemy_boss_home_neighbor: bool = false
			for neighbor_id in direct_neighbors:
				if _is_enemy_boss_home_destination(int(neighbor_id)):
					has_direct_enemy_boss_home_neighbor = true
					break
			if has_direct_enemy_boss_home_neighbor:
				friendly_boss_home_march_metrics["sources_with_direct_enemy_boss_home_neighbor"] = int(friendly_boss_home_march_metrics.get("sources_with_direct_enemy_boss_home_neighbor", 0)) + 1

		var path: Array[int] = _find_frontline_path(source_id, live_snapshot_by_id)
		if path.size() < 2:
			continue
		var destination_id: int = int(path[path.size() - 1])
		if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and _is_enemy_boss_home_destination(destination_id):
			friendly_boss_home_march_metrics["planned_moves_to_enemy_boss_home"] = int(friendly_boss_home_march_metrics.get("planned_moves_to_enemy_boss_home", 0)) + 1

		source_state["remaining_troops"] = int(source_state.get("remaining_troops", 0)) - moving_troops
		var arrival_applied: bool = resolve_march_arrival(destination_id, moving_troops, source_type, source_faction, source_id)
		if source_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and _is_enemy_boss_home_destination(destination_id):
			friendly_boss_home_march_metrics["arrival_attempts"] = int(friendly_boss_home_march_metrics.get("arrival_attempts", 0)) + 1
			if arrival_applied:
				friendly_boss_home_march_metrics["arrival_successes"] = int(friendly_boss_home_march_metrics.get("arrival_successes", 0)) + 1
		if not arrival_applied:
			source_state["remaining_troops"] = int(source_state.get("remaining_troops", 0)) + moving_troops

	var sources_considered: int = int(friendly_boss_home_march_metrics.get("sources_considered", 0))
	var direct_neighbor_sources: int = int(friendly_boss_home_march_metrics.get("sources_with_direct_enemy_boss_home_neighbor", 0))
	var planned_boss_home_moves: int = int(friendly_boss_home_march_metrics.get("planned_moves_to_enemy_boss_home", 0))
	var arrival_attempts: int = int(friendly_boss_home_march_metrics.get("arrival_attempts", 0))
	var arrival_successes: int = int(friendly_boss_home_march_metrics.get("arrival_successes", 0))
	if sources_considered > 0 or direct_neighbor_sources > 0 or planned_boss_home_moves > 0 or arrival_attempts > 0:
		_append_automated_engagement_log_with_priority("Boss-home march debug: friendly sources=%d, direct-neighbor boss homes=%d, planned boss-home marches=%d, arrivals=%d, successes=%d, blocked=%d." % [
			sources_considered,
			direct_neighbor_sources,
			planned_boss_home_moves,
			arrival_attempts,
			arrival_successes,
			maxi(0, arrival_attempts - arrival_successes)
		], 98)

	_move_friendly_boss_after_marches()
	resolve_destroyed_enemy_provinces()
	if _main.province_system != null:
		_main.province_system.apply_persistence_to_province_visuals()


func _move_friendly_boss_after_marches() -> void:
	if _main == null or _main.province_system == null:
		return
	var boss_system = _get_boss_system()
	var friendly_boss_id: int = _get_active_friendly_boss_id()
	if friendly_boss_id < 0 or boss_system == null:
		return
	if not boss_system.has_method("get_boss_current_province_id") or not boss_system.has_method("set_boss_current_province_id"):
		return
	var source_id: int = int(boss_system.get_boss_current_province_id(friendly_boss_id))
	if source_id < 0:
		source_id = int(boss_system.get_boss_home_province_id(friendly_boss_id)) if boss_system.has_method("get_boss_home_province_id") else -1
	if source_id < 0:
		return
	var snapshot_by_id: Dictionary = _main.province_system.make_province_snapshot_by_id()
	var movement_plan: Dictionary = _plan_friendly_boss_move_toward_enemy_boss_home(source_id, snapshot_by_id)
	var path: Array[int] = []
	var considered_neighbors: Array[int] = []
	var candidate_enemy_boss_homes: Array[int] = []
	var raw_path: Variant = movement_plan.get("path", [])
	if raw_path is Array:
		for entry in raw_path:
			path.append(int(entry))
	var raw_considered: Variant = movement_plan.get("considered_neighbors", [])
	if raw_considered is Array:
		for entry in raw_considered:
			considered_neighbors.append(int(entry))
	var raw_enemy_homes: Variant = movement_plan.get("candidate_enemy_boss_homes", [])
	if raw_enemy_homes is Array:
		for entry in raw_enemy_homes:
			candidate_enemy_boss_homes.append(int(entry))
	var source_state_for_log: Dictionary = snapshot_by_id.get(source_id, {})
	_append_automated_engagement_log_with_priority("Friendly boss move debug: source=%d type=%s faction=%d troops=%d boss_troops=%d considered=%s enemy_boss_homes=%s path=%s reason=%s." % [
		source_id,
		String(source_state_for_log.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
		int(source_state_for_log.get("faction_id", 0)),
		int(source_state_for_log.get("remaining_troops", 0)),
		int(boss_system.get_boss_home_troop_count(friendly_boss_id)) if boss_system.has_method("get_boss_home_troop_count") else 0,
		str(considered_neighbors),
		str(candidate_enemy_boss_homes),
		str(path),
		String(movement_plan.get("reason", ""))
	], 98)
	if path.size() < 2:
		return
	var destination_id: int = int(path[1])
	var src_idx: int = _main.province_system.find_persistence_index_by_id(source_id)
	var dst_idx: int = _main.province_system.find_persistence_index_by_id(destination_id)
	if src_idx < 0 or dst_idx < 0:
		return
	var src_state: Dictionary = _main._province_persistence[src_idx]
	var dst_state: Dictionary = _main._province_persistence[dst_idx]
	var boss_troops: int = maxi(0, int(boss_system.get_boss_home_troop_count(friendly_boss_id))) if boss_system.has_method("get_boss_home_troop_count") else 0
	src_state["remaining_troops"] = maxi(0, int(src_state.get("remaining_troops", 0)) - boss_troops)
	dst_state["remaining_troops"] = int(dst_state.get("remaining_troops", 0)) + boss_troops
	boss_system.set_boss_current_province_id(friendly_boss_id, destination_id)
	var destination_type: String = String(dst_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var destination_faction: int = int(dst_state.get("faction_id", 0))
	var ended_in_friendly_control: bool = destination_type == LevelConfig.PROVINCE_TYPE_FRIENDLY or _is_friendly_boss_faction_id(destination_faction)
	if ended_in_friendly_control:
		dst_state["friendly_boss_invasion_pending"] = false
		dst_state["friendly_boss_invading_troops"] = 0
		dst_state["friendly_boss_invader_id"] = -1
	else:
		var friendly_boss_faction_id: int = int(src_state.get("faction_id", 0))
		if boss_system.has_method("get_friendly_boss_faction_id"):
			friendly_boss_faction_id = int(boss_system.get_friendly_boss_faction_id())
		dst_state["faction_id"] = friendly_boss_faction_id
		dst_state["friendly_boss_invasion_pending"] = true
		dst_state["friendly_boss_invading_troops"] = boss_troops
		dst_state["friendly_boss_invader_id"] = friendly_boss_id
		dst_state["friendly_boss_invasion_started_turn"] = int(_main.get("turn_number"))


func _plan_friendly_boss_move_toward_enemy_boss_home(source_id: int, snapshot_by_id: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"path": [],
		"considered_neighbors": [],
		"candidate_enemy_boss_homes": [],
		"reason": ""
	}
	if source_id < 0 or not snapshot_by_id.has(source_id):
		result["reason"] = "invalid_source"
		return result

	var source_state: Dictionary = snapshot_by_id.get(source_id, {})
	var considered_neighbors: Array[int] = _get_effective_march_neighbors(source_state, snapshot_by_id)
	result["considered_neighbors"] = considered_neighbors

	var has_frontline_target: bool = false
	for province_state_any in snapshot_by_id.values():
		var province_state: Dictionary = province_state_any
		if _is_frontline_target_for_owner(province_state, LevelConfig.PROVINCE_TYPE_FRIENDLY, 0, true, false, false):
			has_frontline_target = true
			break

	var frontline_path: Array[int] = _find_frontline_path(source_id, snapshot_by_id)
	result["path"] = frontline_path
	if frontline_path.size() >= 2:
		result["reason"] = "found_frontline_target"
	elif has_frontline_target:
		result["reason"] = "no_path_to_frontline_target"
	else:
		result["reason"] = "no_frontline_targets"
	return result


func apply_invasion_building_damage_and_conquest(province_state: Dictionary) -> void:
	if _main == null:
		return
	var province_id: int = int(province_state.get("id", -1))
	_log_skip_to_end_damage_trace("apply_invasion_enter", "province=%d type=%s inv=%d troops=%d bld=%d pending_turn=%d" % [
		province_id,
		String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
		int(province_state.get("invading_troops", 0)),
		int(province_state.get("remaining_troops", 0)),
		int(province_state.get("remaining_buildings", 0)),
		int(province_state.get("pending_invasion_started_turn", -1))
	])
	var is_active_boss_home: bool = _is_active_boss_home_destination(province_id)
	if is_active_boss_home:
		province_state["remaining_buildings"] = 0
		province_state["construction_progress"] = 0
		_clear_pending_invasion(province_state)
		_log_skip_to_end_damage_trace("apply_invasion_boss_home_block", "province=%d" % province_id)
		return

	var invading_troops: int = int(province_state.get("invading_troops", 0))
	if invading_troops <= 0:
		_log_skip_to_end_damage_trace("apply_invasion_no_invaders", "province=%d" % province_id)
		return

	var province_type_before: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var owner_faction_before: int = _get_owner_faction_for_type(province_type_before, province_state)
	var attacking_faction: int = _normalize_enemy_faction_id(int(province_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
	var attacker_label: String = _format_owner_label(LevelConfig.PROVINCE_TYPE_ENEMY, attacking_faction)
	var province_label: String = _format_province_label(province_id)
	var invaded_owner_before: String = "Friendly"
	var invading_source_ids: Array[int] = _get_invading_source_ids(province_state)
	var source_provinces_text: String = _format_source_provinces_text(invading_source_ids)
	var defenders_before: int = int(province_state.get("remaining_troops", 0))

	# Non-player invasion → use unified resolver
	var input_dict := {
		"player_participating": false,
		"troops_A": invading_troops,
		"troops_B": int(province_state.get("remaining_troops", 0)),
		"buildings_A": 0,
		"buildings_B": int(province_state.get("remaining_buildings", 0)),
		"player_downed_troops": 0,
		"player_destroyed_buildings": 0,
		"province_id": province_id,
		"attacker_type": LevelConfig.PROVINCE_TYPE_ENEMY,
		"attacker_faction_id": attacking_faction
	}

	var outcome: Dictionary = {}
	if _main.engagement_resolver != null:
		outcome = _main.engagement_resolver.resolve_engagement(input_dict)

	var final_troops_B: int = int(outcome.get("final_troops_B", 0))
	var final_buildings_B: int = int(outcome.get("final_buildings_B", 0))
	var final_type: String = String(outcome.get("province_type_after", province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)))
	var final_faction: int = int(outcome.get("faction_after", 0))
	var conquered: bool = bool(outcome.get("conquered", false))
	var surviving_attackers: int = maxi(0, invading_troops - defenders_before)
	if conquered:
		var conquered_counts: Dictionary = _get_conquered_province_counts(final_type, province_state)
		final_buildings_B = int(conquered_counts.get("remaining_buildings", final_buildings_B))
		if final_type == LevelConfig.PROVINCE_TYPE_ENEMY:
			final_troops_B = _get_enemy_conquest_resulting_troops(surviving_attackers)
			final_faction = _normalize_enemy_faction_id(final_faction)
		else:
			final_troops_B = int(conquered_counts.get("remaining_troops", final_troops_B))
			final_faction = 0

	final_buildings_B = _clamp_buildings_to_province_cap(province_state, final_buildings_B)
	province_state["remaining_troops"] = final_troops_B
	province_state["remaining_buildings"] = final_buildings_B
	province_state["type"] = final_type
	province_state["faction_id"] = final_faction
	if conquered:
		_clear_pending_invasion(province_state)
	elif final_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and surviving_attackers > 0:
		province_state["invading_troops"] = surviving_attackers
		province_state["faction_id"] = attacking_faction
		province_state["invading_source_ids"] = invading_source_ids.duplicate()
		_set_pending_invasion_started_turn(province_state, int(_main.get("turn_number")) if _main != null else -1)
	else:
		_clear_pending_invasion(province_state)
	_log_skip_to_end_damage_trace("apply_invasion_outcome", "province=%d conquered=%s final_type=%s final_t=%d final_b=%d final_faction=%d" % [
		province_id,
		str(conquered),
		final_type,
		final_troops_B,
		final_buildings_B,
		final_faction
	])
	if _did_owner_change(province_type_before, owner_faction_before, final_type, final_faction):
		_reset_construction_progress(province_state)
	_update_capture_source_after_owner_change(province_id, province_type_before, owner_faction_before, final_type, final_faction, LevelConfig.PROVINCE_TYPE_ENEMY)

	if conquered:
		_append_automated_engagement_log_with_priority("%s's invasion from %s into %s (%s-owned) went undefended. %s was conquered and %d troop%s remain." % [
			attacker_label,
			source_provinces_text,
			province_label,
			invaded_owner_before,
			province_label,
			final_troops_B,
			"" if final_troops_B == 1 else "s"
		], 0)
	else:
		_append_automated_engagement_log_with_priority("%s's invasion from %s into %s (%s-owned) went undefended. The province held with %s remaining." % [
			attacker_label,
			source_provinces_text,
			province_label,
			invaded_owner_before,
			_format_remaining_forces_text(final_troops_B, final_buildings_B)
		], 0)


func get_invaded_friendly_province_ids() -> Array[int]:
	var ids: Array[int] = []
	if _main == null:
		return ids

	for province_state in _main._province_persistence:
		if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		if int(province_state.get("invading_troops", 0)) <= 0:
			continue
		ids.append(int(province_state.get("id", -1)))

	ids.sort()
	return ids


func apply_undefended_invasion_damage(skip_province_id: int = -1, eligible_province_ids: Array[int] = [], restrict_to_eligible: bool = false) -> void:
	if _main == null:
		return

	_log_skip_to_end_damage_trace("undefended_damage_start", "skip_province=%d restrict=%s eligible=%s" % [
		skip_province_id,
		str(restrict_to_eligible),
		str(eligible_province_ids)
	])
	var eligible_lookup: Dictionary = {}
	for province_id in eligible_province_ids:
		eligible_lookup[int(province_id)] = true

	for province_state in _main._province_persistence:
		var province_id: int = int(province_state.get("id", -1))
		if province_id == skip_province_id:
			_log_skip_to_end_damage_trace("undefended_damage_skip_locked", "province=%d" % province_id)
			continue
		if restrict_to_eligible and not eligible_lookup.has(province_id):
			_log_skip_to_end_damage_trace("undefended_damage_skip_not_eligible", "province=%d" % province_id)
			continue
		if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		if int(province_state.get("invading_troops", 0)) <= 0:
			continue
		if not _should_resolve_pending_invasion_this_enemy_phase(province_state):
			_log_skip_to_end_damage_trace("undefended_damage_skip_not_ready", "province=%d inv=%d started_turn=%d current_turn=%d" % [
				province_id,
				int(province_state.get("invading_troops", 0)),
				int(province_state.get("pending_invasion_started_turn", -1)),
				int(_main.get("turn_number"))
			])
			continue

		apply_invasion_building_damage_and_conquest(province_state)

	resolve_destroyed_enemy_provinces()
	if _main.province_system != null:
		_main.province_system.apply_persistence_to_province_visuals()
	_log_skip_to_end_damage_trace("undefended_damage_end")


func _run_single_automated_cycle(include_friendly_actions: bool, skip_province_id: int = -1, eligible_province_ids: Array[int] = [], restrict_to_eligible: bool = false) -> Array[int]:
	if _main == null:
		return []

	apply_undefended_invasion_damage(skip_province_id, eligible_province_ids, restrict_to_eligible)
	run_enemy_march_phase(include_friendly_actions)
	process_province_construction(include_friendly_actions)
	recruit_enemy_provinces(include_friendly_actions)
	_run_boss_turn_phase()
	return get_invaded_friendly_province_ids()


func run_enemy_turn_cycles(turn_cycles: int, initial_skip_province_id: int = -1, initial_eligible_province_ids: Array[int] = []) -> void:
	if _main == null:
		return

	clear_automated_engagement_log()

	var cycles: int = maxi(0, turn_cycles)
	var skip_province_id: int = initial_skip_province_id
	var eligible_province_ids: Array[int] = initial_eligible_province_ids.duplicate()

	for cycle_index in range(cycles):
		var restrict_to_eligible: bool = cycle_index == 0
		eligible_province_ids = _run_single_automated_cycle(true, skip_province_id, eligible_province_ids, restrict_to_eligible)
		skip_province_id = -1


func run_post_engagement_turn_sequence(friendly_inclusive_cycles: int, enemy_total_cycles: int, initial_skip_province_id: int = -1, initial_eligible_province_ids: Array[int] = []) -> void:
	if _main == null:
		return

	clear_automated_engagement_log()

	var normal_cycles: int = maxi(0, friendly_inclusive_cycles)
	var total_enemy_cycles: int = maxi(0, enemy_total_cycles)
	var extra_enemy_only_cycles: int = maxi(0, total_enemy_cycles - normal_cycles)
	var skip_province_id: int = initial_skip_province_id
	var eligible_province_ids: Array[int] = initial_eligible_province_ids.duplicate()

	for cycle_index in range(normal_cycles):
		var restrict_to_eligible: bool = cycle_index == 0
		eligible_province_ids = _run_single_automated_cycle(true, skip_province_id, eligible_province_ids, restrict_to_eligible)
		skip_province_id = -1

	for enemy_cycle_index in range(extra_enemy_only_cycles):
		var restrict_to_eligible: bool = normal_cycles == 0 and enemy_cycle_index == 0
		eligible_province_ids = _run_single_automated_cycle(false, skip_province_id, eligible_province_ids, restrict_to_eligible)
		skip_province_id = -1


func advance_grand_map_turn_after_rest(status_text: String, lock_province_id: int = -1) -> void:
	if _main == null:
		return

	var preexisting_invaded_province_ids: Array[int] = get_invaded_friendly_province_ids()
	_main.level_index += 1
	_main.turn_number += 1
	if lock_province_id != -1:
		_main._locked_province_id_after_win = lock_province_id

	run_enemy_turn_cycles(1, -1, preexisting_invaded_province_ids)
	# Activate any queued friendly boss spawn only after the turn's automated marches resolve.
	# This prevents newly spawned boss factions from marching or triggering automated engagements
	# on their arrival turn, so the next player shot sees the immediate post-spawn map state.
	var friendly_spawn_status: String = ""
	if _main.level_flow != null and _main.level_flow.has_method("maybe_activate_pending_friendly_boss_spawn"):
		friendly_spawn_status = String(_main.level_flow.call("maybe_activate_pending_friendly_boss_spawn")).strip_edges()
	if friendly_spawn_status != "":
		_append_automated_engagement_log_with_priority(friendly_spawn_status, 98)
	if _main.has_method("_resolve_due_boss_arrivals_at_turn_end"):
		var status_lines_any: Variant = _main.call("_resolve_due_boss_arrivals_at_turn_end")
		if status_lines_any is Array:
			for line_any in status_lines_any:
				var spawn_line: String = String(line_any).strip_edges()
				if spawn_line != "":
					_append_automated_engagement_log_with_priority(spawn_line, 98)

	if _main.level_flow != null:
		_main.level_flow.generate_grand_map()
		if _main.level_flow.has_method("center_camera_on_turn_origin_province"):
			_main.level_flow.call_deferred("center_camera_on_turn_origin_province")
			_main.get_tree().create_timer(0.12).timeout.connect(Callable(_main.level_flow, "center_camera_on_turn_origin_province"))
	play_pending_boss_attack_province_pulses()

	if _main.ui_bridge != null:
		_main.ui_bridge.ui_set_status(build_automated_engagement_status_text(status_text))

	if _main.ui_bridge != null:
		_main.ui_bridge.sync_ui_button_states()


func recruit_enemy_provinces(include_friendly_provinces: bool = true) -> void:
	if _main == null:
		return

	var boss_system = _get_boss_system()
	var boss_faction_id: int = -1
	var boss_extra_recruit_per_province: int = 0
	if boss_system != null and bool(boss_system.call("is_boss_active")):
		boss_faction_id = int(boss_system.call("get_boss_faction_id"))
		boss_extra_recruit_per_province = _get_boss_extra_recruit_per_province()

	for p in _main._province_persistence:
		var province_id: int = int(p.get("id", -1))
		if _is_active_boss_home_destination(province_id):
			if int(p.get("remaining_buildings", -1)) != 0:
				p["remaining_buildings"] = 0
			continue
		var province_type: String = String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		if province_type != LevelConfig.PROVINCE_TYPE_ENEMY and province_type != LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		if not include_friendly_provinces and province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue

		var recruit: int = int(p.get("remaining_buildings", 0)) * LevelConfig.ENEMY_RECRUITMENT_PER_BUILDING
		if province_type == LevelConfig.PROVINCE_TYPE_ENEMY and boss_faction_id >= 0 and int(p.get("faction_id", 0)) == boss_faction_id:
			recruit += boss_extra_recruit_per_province
		if province_type == LevelConfig.PROVINCE_TYPE_ENEMY and _is_friendly_boss_faction_id(int(p.get("faction_id", 0))):
			recruit += 4
		p["remaining_troops"] = int(p.get("remaining_troops", 0)) + recruit

	if _main.province_system != null:
		_main.province_system.apply_persistence_to_province_visuals()
