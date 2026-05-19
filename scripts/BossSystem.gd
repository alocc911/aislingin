extends RefCounted
class_name BossSystem

const LevelConfig = preload("res://scripts/LevelConfig.gd")

const META_BOSS_RUNTIME_STATE: String = "boss_runtime_state"
const META_BOSS_ROLLS_COMPLETED: String = "boss_rolls_completed"
const META_BOSS_HAS_SPAWNED_ONCE: String = "boss_has_spawned_once"

const BOSS_STATE_VERSION: int = 2

const BOSS_FACTION_ID: int = 99
const BOSS_FACTION_ID_BASE: int = 99
const FRIENDLY_BOSS_FACTION_ID: int = 199
const BOSS_INITIAL_CONQUERED_PROVINCES: int = 3

const BOSS_PART_HEAD: String = "head"
const BOSS_PART_LEFT_ARM: String = "left_arm"
const BOSS_PART_RIGHT_ARM: String = "right_arm"
const BOSS_PART_LEFT_LEG: String = "left_leg"
const BOSS_PART_RIGHT_LEG: String = "right_leg"

const BOSS_HOME_FLAG_KEY: String = "is_boss_home"
const BOSS_FACTION_FLAG_KEY: String = "is_boss_faction_province"

const BOSS_BASE_ENERGY_PER_TURN: int = 2
const BOSS_ENERGY_PER_PROVINCE: int = 1
const BOSS_ENERGY_DRAIN_TROOPS_PER_POINT: int = 20
const BOSS_HOME_TROOPS_PER_HIT_POINT: int = 5

const BOSS_PUNCH_COST: int = 1
const BOSS_KICK_COST: int = 2
const BOSS_PUNCH_DAMAGE_MIN: int = 6
const BOSS_PUNCH_DAMAGE_MAX: int = 8
const BOSS_KICK_DAMAGE_MIN: int = 1
const BOSS_KICK_DAMAGE_MAX: int = 3

const BOSS_TARGET_FRIENDLY: String = LevelConfig.PROVINCE_TYPE_FRIENDLY
const BOSS_TARGET_ENEMY: String = LevelConfig.PROVINCE_TYPE_ENEMY

var _main: Node = null


func setup(main_node: Node) -> void:
	_main = main_node
	_ensure_runtime_state()
	_ensure_roll_tracking_state()


func _ensure_runtime_state() -> void:
	if _main == null:
		return
	var current_state: Dictionary = _make_default_runtime_state()
	if _main.has_meta(META_BOSS_RUNTIME_STATE):
		var raw_state: Variant = _main.get_meta(META_BOSS_RUNTIME_STATE, _make_default_runtime_state())
		if raw_state is Dictionary:
			current_state = _upgrade_runtime_state(raw_state)
	_main.set_meta(META_BOSS_RUNTIME_STATE, current_state)


func _ensure_roll_tracking_state() -> void:
	if _main == null:
		return
	if not _main.has_meta(META_BOSS_ROLLS_COMPLETED):
		_main.set_meta(META_BOSS_ROLLS_COMPLETED, 0)
	if not _main.has_meta(META_BOSS_HAS_SPAWNED_ONCE):
		_main.set_meta(META_BOSS_HAS_SPAWNED_ONCE, false)


func _make_default_part_state() -> Dictionary:
	return {
		"hits": 0,
		"destroyed": false
	}


func _make_default_parts_state() -> Dictionary:
	return {
		BOSS_PART_HEAD: _make_default_part_state(),
		BOSS_PART_LEFT_ARM: _make_default_part_state(),
		BOSS_PART_RIGHT_ARM: _make_default_part_state(),
		BOSS_PART_LEFT_LEG: _make_default_part_state(),
		BOSS_PART_RIGHT_LEG: _make_default_part_state()
	}


func _make_default_single_boss_state(boss_id: int = 1, boss_faction_id: int = BOSS_FACTION_ID, home_province_id: int = -1, conquered_province_ids: Array[int] = []) -> Dictionary:
	return {
		"boss_id": boss_id,
		"active": false,
		"dead": false,
		"is_friendly_boss": false,
		"boss_faction_id": boss_faction_id,
		"boss_faction_name": "",
		"home_province_id": home_province_id,
		"current_province_id": home_province_id,
		"energy_generated_this_turn": 0,
		"energy_drained_this_turn": 0,
		"energy_available_this_turn": 0,
		"parts": _make_default_parts_state(),
		"home_troop_loss_carry": 0,
		"home_troop_linear_losses": 0,
		"last_hit_part": "",
		"last_turn_log_lines": [],
		"initial_conquered_province_ids": conquered_province_ids.duplicate()
	}


func _make_default_runtime_state() -> Dictionary:
	var bosses: Array[Dictionary] = []
	var state: Dictionary = {
		"version": BOSS_STATE_VERSION,
		"next_boss_id": 1,
		"primary_boss_id": -1,
		"bosses": bosses,
		"active": false,
		"dead": false,
		"boss_faction_id": BOSS_FACTION_ID,
		"home_province_id": -1,
		"energy_generated_this_turn": 0,
		"energy_drained_this_turn": 0,
		"energy_available_this_turn": 0,
		"parts": _make_default_parts_state(),
		"last_hit_part": "",
		"last_turn_log_lines": [],
		"initial_conquered_province_ids": [],
		"active_boss_ids": [],
		"boss_count": 0,
		"active_boss_count": 0
	}
	return state


func _upgrade_runtime_state(state: Dictionary) -> Dictionary:
	var upgraded: Dictionary = _make_default_runtime_state()
	upgraded["version"] = BOSS_STATE_VERSION
	upgraded["next_boss_id"] = maxi(1, int(state.get("next_boss_id", 1)))
	upgraded["primary_boss_id"] = int(state.get("primary_boss_id", -1))

	var bosses: Array[Dictionary] = []
	var raw_bosses: Variant = state.get("bosses", [])
	if raw_bosses is Array:
		for boss_any in raw_bosses:
			if boss_any is Dictionary:
				bosses.append(_upgrade_single_boss_state(boss_any))

	if bosses.is_empty():
		var looks_like_legacy: bool = state.has("parts") or state.has("boss_faction_id") or state.has("home_province_id")
		if looks_like_legacy:
			var legacy_boss: Dictionary = _make_default_single_boss_state(
				1,
				int(state.get("boss_faction_id", BOSS_FACTION_ID)),
				int(state.get("home_province_id", -1)),
				_as_int_array(state.get("initial_conquered_province_ids", []))
			)
			legacy_boss["active"] = bool(state.get("active", false))
			legacy_boss["dead"] = bool(state.get("dead", false))
			legacy_boss["energy_generated_this_turn"] = maxi(0, int(state.get("energy_generated_this_turn", 0)))
			legacy_boss["energy_drained_this_turn"] = maxi(0, int(state.get("energy_drained_this_turn", 0)))
			legacy_boss["energy_available_this_turn"] = maxi(0, int(state.get("energy_available_this_turn", 0)))
			legacy_boss["parts"] = _upgrade_parts_state(state.get("parts", {}))
			legacy_boss["home_troop_loss_carry"] = maxi(0, mini(BOSS_HOME_TROOPS_PER_HIT_POINT - 1, int(state.get("home_troop_loss_carry", 0))))
			legacy_boss["home_troop_linear_losses"] = maxi(0, int(state.get("home_troop_linear_losses", 0)))
			legacy_boss["last_hit_part"] = String(state.get("last_hit_part", "")).strip_edges()
			legacy_boss["last_turn_log_lines"] = _as_string_array(state.get("last_turn_log_lines", []))
			bosses.append(legacy_boss)
			upgraded["next_boss_id"] = maxi(upgraded["next_boss_id"], 2)
			if bool(legacy_boss.get("active", false)) or bool(legacy_boss.get("dead", false)):
				upgraded["primary_boss_id"] = 1

	upgraded["bosses"] = bosses
	upgraded["next_boss_id"] = _compute_next_boss_id(bosses, int(upgraded.get("next_boss_id", 1)))
	upgraded = _synchronize_legacy_runtime_fields(upgraded)
	return upgraded


func _upgrade_single_boss_state(boss_state: Dictionary) -> Dictionary:
	var upgraded: Dictionary = _make_default_single_boss_state(
		maxi(1, int(boss_state.get("boss_id", 1))),
		int(boss_state.get("boss_faction_id", BOSS_FACTION_ID)),
		int(boss_state.get("home_province_id", -1)),
		_as_int_array(boss_state.get("initial_conquered_province_ids", []))
	)
	upgraded["active"] = bool(boss_state.get("active", false))
	upgraded["dead"] = bool(boss_state.get("dead", false))
	upgraded["is_friendly_boss"] = bool(boss_state.get("is_friendly_boss", false))
	upgraded["boss_faction_name"] = String(boss_state.get("boss_faction_name", "")).strip_edges()
	upgraded["energy_generated_this_turn"] = maxi(0, int(boss_state.get("energy_generated_this_turn", 0)))
	upgraded["energy_drained_this_turn"] = maxi(0, int(boss_state.get("energy_drained_this_turn", 0)))
	upgraded["energy_available_this_turn"] = maxi(0, int(boss_state.get("energy_available_this_turn", 0)))
	upgraded["current_province_id"] = int(boss_state.get("current_province_id", upgraded.get("home_province_id", -1)))
	upgraded["parts"] = _upgrade_parts_state(boss_state.get("parts", {}))
	upgraded["home_troop_loss_carry"] = maxi(0, mini(BOSS_HOME_TROOPS_PER_HIT_POINT - 1, int(boss_state.get("home_troop_loss_carry", 0))))
	upgraded["home_troop_linear_losses"] = maxi(0, int(boss_state.get("home_troop_linear_losses", 0)))
	upgraded["last_hit_part"] = String(boss_state.get("last_hit_part", "")).strip_edges()
	upgraded["last_turn_log_lines"] = _as_string_array(boss_state.get("last_turn_log_lines", []))
	return upgraded


func _upgrade_parts_state(raw_parts: Variant) -> Dictionary:
	var parts: Dictionary = _make_default_parts_state()
	if raw_parts is Dictionary:
		for part_name in get_all_boss_part_names():
			var raw_part_state: Variant = raw_parts.get(part_name, {})
			var part_state: Dictionary = _make_default_part_state()
			if raw_part_state is Dictionary:
				part_state["hits"] = maxi(0, int(raw_part_state.get("hits", 0)))
				part_state["destroyed"] = bool(raw_part_state.get("destroyed", false))
			parts[part_name] = part_state
	return parts


func _compute_next_boss_id(bosses: Array[Dictionary], seed_value: int) -> int:
	var next_id: int = maxi(1, seed_value)
	for boss_state in bosses:
		next_id = maxi(next_id, int(boss_state.get("boss_id", 0)) + 1)
	return next_id


func _synchronize_legacy_runtime_fields(state: Dictionary) -> Dictionary:
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	var primary_boss_id: int = int(state.get("primary_boss_id", -1))
	var primary_boss: Dictionary = {}
	if primary_boss_id >= 0:
		primary_boss = _find_boss_state_in_array(bosses, primary_boss_id)
	if primary_boss.is_empty():
		primary_boss = _choose_primary_boss_state_from_array(bosses)
		primary_boss_id = int(primary_boss.get("boss_id", -1))
	state["primary_boss_id"] = primary_boss_id

	var active_ids: Array[int] = []
	var any_dead: bool = false
	for boss_state in bosses:
		if bool(boss_state.get("active", false)) and not bool(boss_state.get("dead", false)):
			active_ids.append(int(boss_state.get("boss_id", -1)))
		if bool(boss_state.get("dead", false)):
			any_dead = true

	state["bosses"] = bosses
	state["boss_count"] = bosses.size()
	state["active_boss_count"] = active_ids.size()
	state["active_boss_ids"] = active_ids

	if primary_boss.is_empty():
		state["active"] = false
		state["dead"] = any_dead
		state["boss_faction_id"] = BOSS_FACTION_ID
		state["home_province_id"] = -1
		state["energy_generated_this_turn"] = 0
		state["energy_drained_this_turn"] = 0
		state["energy_available_this_turn"] = 0
		state["parts"] = _make_default_parts_state()
		state["home_troop_loss_carry"] = 0
		state["last_hit_part"] = ""
		state["last_turn_log_lines"] = []
		state["initial_conquered_province_ids"] = []
		return state

	state["active"] = bool(primary_boss.get("active", false)) and not bool(primary_boss.get("dead", false))
	state["dead"] = bool(primary_boss.get("dead", false))
	state["boss_faction_id"] = int(primary_boss.get("boss_faction_id", BOSS_FACTION_ID))
	state["home_province_id"] = int(primary_boss.get("home_province_id", -1))
	state["energy_generated_this_turn"] = maxi(0, int(primary_boss.get("energy_generated_this_turn", 0)))
	state["energy_drained_this_turn"] = maxi(0, int(primary_boss.get("energy_drained_this_turn", 0)))
	state["energy_available_this_turn"] = maxi(0, int(primary_boss.get("energy_available_this_turn", 0)))
	state["parts"] = _upgrade_parts_state(primary_boss.get("parts", {}))
	state["home_troop_loss_carry"] = maxi(0, mini(BOSS_HOME_TROOPS_PER_HIT_POINT - 1, int(primary_boss.get("home_troop_loss_carry", 0))))
	state["last_hit_part"] = String(primary_boss.get("last_hit_part", "")).strip_edges()
	state["last_turn_log_lines"] = _as_string_array(primary_boss.get("last_turn_log_lines", []))
	state["initial_conquered_province_ids"] = _as_int_array(primary_boss.get("initial_conquered_province_ids", []))
	return state


func _get_bosses_from_state(state: Dictionary) -> Array[Dictionary]:
	var bosses: Array[Dictionary] = []
	var raw_bosses: Variant = state.get("bosses", [])
	if raw_bosses is Array:
		for boss_any in raw_bosses:
			if boss_any is Dictionary:
				bosses.append(_upgrade_single_boss_state(boss_any))
	return bosses


func _set_bosses_on_state(state: Dictionary, bosses: Array[Dictionary]) -> Dictionary:
	state["bosses"] = bosses.duplicate(true)
	state["next_boss_id"] = _compute_next_boss_id(bosses, int(state.get("next_boss_id", 1)))
	return _synchronize_legacy_runtime_fields(state)


func _find_boss_state_in_array(bosses: Array[Dictionary], boss_id: int) -> Dictionary:
	for boss_state in bosses:
		if int(boss_state.get("boss_id", -1)) == boss_id:
			return boss_state.duplicate(true)
	return {}


func _find_boss_index_in_array(bosses: Array[Dictionary], boss_id: int) -> int:
	for index in range(bosses.size()):
		if int(bosses[index].get("boss_id", -1)) == boss_id:
			return index
	return -1


func _choose_primary_boss_state_from_array(bosses: Array[Dictionary]) -> Dictionary:
	for boss_state in bosses:
		if bool(boss_state.get("active", false)) and not bool(boss_state.get("dead", false)):
			return boss_state.duplicate(true)
	for boss_state in bosses:
		if bool(boss_state.get("dead", false)):
			return boss_state.duplicate(true)
	return {}


func _resolve_default_boss_id(state: Dictionary, preferred_boss_id: int = -1) -> int:
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	if preferred_boss_id >= 0:
		for boss_state in bosses:
			if int(boss_state.get("boss_id", -1)) == preferred_boss_id:
				return preferred_boss_id
	var primary_boss_id: int = int(state.get("primary_boss_id", -1))
	if primary_boss_id >= 0:
		for boss_state in bosses:
			if int(boss_state.get("boss_id", -1)) == primary_boss_id:
				return primary_boss_id
	for boss_state in bosses:
		if bool(boss_state.get("active", false)) and not bool(boss_state.get("dead", false)):
			return int(boss_state.get("boss_id", -1))
	for boss_state in bosses:
		return int(boss_state.get("boss_id", -1))
	return -1


func _store_runtime_state(state: Dictionary) -> void:
	if _main == null:
		return
	_main.set_meta(META_BOSS_RUNTIME_STATE, _upgrade_runtime_state(state))


func reset_all_boss_progress() -> void:
	if _main == null:
		return
	_main.set_meta(META_BOSS_RUNTIME_STATE, _make_default_runtime_state())
	_main.set_meta(META_BOSS_ROLLS_COMPLETED, 0)
	_main.set_meta(META_BOSS_HAS_SPAWNED_ONCE, false)


func clear_runtime_but_keep_spawn_history() -> void:
	if _main == null:
		return
	_main.set_meta(META_BOSS_RUNTIME_STATE, _make_default_runtime_state())


func get_runtime_state() -> Dictionary:
	_ensure_runtime_state()
	if _main == null:
		return _make_default_runtime_state()
	var state: Dictionary = _main.get_meta(META_BOSS_RUNTIME_STATE, _make_default_runtime_state())
	return _upgrade_runtime_state(state).duplicate(true)


func set_runtime_state(new_state: Dictionary) -> void:
	_store_runtime_state(new_state)


func get_completed_grand_map_rolls() -> int:
	_ensure_roll_tracking_state()
	if _main == null:
		return 0
	return int(_main.get_meta(META_BOSS_ROLLS_COMPLETED, 0))


func set_completed_grand_map_rolls(value: int) -> void:
	if _main == null:
		return
	_main.set_meta(META_BOSS_ROLLS_COMPLETED, maxi(0, value))


func increment_completed_grand_map_rolls() -> int:
	var next_value: int = get_completed_grand_map_rolls() + 1
	set_completed_grand_map_rolls(next_value)
	return next_value


func has_spawned_once() -> bool:
	_ensure_roll_tracking_state()
	if _main == null:
		return false
	return bool(_main.get_meta(META_BOSS_HAS_SPAWNED_ONCE, false))


func set_has_spawned_once(value: bool) -> void:
	if _main == null:
		return
	_main.set_meta(META_BOSS_HAS_SPAWNED_ONCE, value)


func _get_campaign_current_level_progress() -> int:
	if _main != null and _main.has_method("get_campaign_current_level_progress"):
		return maxi(1, int(_main.call("get_campaign_current_level_progress")))
	return 1


func _is_opening_gameplay_tutorial_active() -> bool:
	if _main != null and _main.has_method("is_opening_gameplay_tutorial_active"):
		return bool(_main.call("is_opening_gameplay_tutorial_active"))
	return false


func get_boss_show_up_turn() -> int:
	return maxi(1, int(LevelConfig.get_boss_show_up_turn_for_level(_get_campaign_current_level_progress(), _is_opening_gameplay_tutorial_active())))


func get_boss_spawn_roll_threshold() -> int:
	return maxi(0, int(LevelConfig.get_boss_spawn_roll_threshold_for_level(_get_campaign_current_level_progress(), _is_opening_gameplay_tutorial_active())))


func should_spawn_after_current_roll() -> bool:
	if has_spawned_once():
		return false
	if is_boss_active():
		return false
	if is_boss_dead():
		return false
	return get_completed_grand_map_rolls() >= get_boss_spawn_roll_threshold()


func get_default_boss_faction_id_for_index(index: int) -> int:
	return BOSS_FACTION_ID_BASE + maxi(0, index)


func get_friendly_boss_faction_id() -> int:
	return FRIENDLY_BOSS_FACTION_ID


func get_target_boss_count_for_current_level() -> int:
	if _main != null and _main.has_method("get_campaign_next_boss_count"):
		return maxi(1, int(_main.call("get_campaign_next_boss_count")))
	return 1


func get_active_boss_count() -> int:
	return get_active_boss_ids().size()


func get_active_boss_ids() -> Array[int]:
	var state: Dictionary = get_runtime_state()
	var ids: Array[int] = []
	var raw_ids: Variant = state.get("active_boss_ids", [])
	if raw_ids is Array:
		for boss_id in raw_ids:
			ids.append(int(boss_id))
	return ids


func get_all_boss_states() -> Array[Dictionary]:
	return _get_bosses_from_state(get_runtime_state())


func get_active_boss_states() -> Array[Dictionary]:
	var active_states: Array[Dictionary] = []
	for boss_state in get_all_boss_states():
		if bool(boss_state.get("active", false)) and not bool(boss_state.get("dead", false)):
			active_states.append(boss_state.duplicate(true))
	return active_states


func get_boss_state(boss_id: int = -1) -> Dictionary:
	var state: Dictionary = get_runtime_state()
	var resolved_boss_id: int = _resolve_default_boss_id(state, boss_id)
	if resolved_boss_id < 0:
		return {}
	return _find_boss_state_in_array(_get_bosses_from_state(state), resolved_boss_id)


func get_primary_boss_id() -> int:
	var state: Dictionary = get_runtime_state()
	return _resolve_default_boss_id(state, int(state.get("primary_boss_id", -1)))


func set_primary_boss_id(boss_id: int) -> void:
	var state: Dictionary = get_runtime_state()
	if _find_boss_index_in_array(_get_bosses_from_state(state), boss_id) == -1:
		return
	state["primary_boss_id"] = boss_id
	_store_runtime_state(state)


func get_boss_id_for_home_province_id(home_province_id: int) -> int:
	if home_province_id < 0:
		return -1
	for boss_state in get_all_boss_states():
		if int(boss_state.get("home_province_id", -1)) == home_province_id:
			return int(boss_state.get("boss_id", -1))
	return -1


func get_boss_id_for_faction_id(faction_id: int) -> int:
	for boss_state in get_all_boss_states():
		if int(boss_state.get("boss_faction_id", 0)) == faction_id:
			return int(boss_state.get("boss_id", -1))
	return -1


func get_all_boss_home_province_ids() -> Array[int]:
	var ids: Array[int] = []
	for boss_state in get_active_boss_states():
		var province_id: int = int(boss_state.get("home_province_id", -1))
		if province_id >= 0:
			ids.append(province_id)
	return ids


func get_all_boss_faction_ids() -> Array[int]:
	var ids: Array[int] = []
	for boss_state in get_active_boss_states():
		ids.append(int(boss_state.get("boss_faction_id", BOSS_FACTION_ID)))
	return ids


func activate_boss(home_province_id: int, conquered_province_ids: Array[int], boss_faction_id: int = BOSS_FACTION_ID) -> Dictionary:
	var spawn_entries: Array[Dictionary] = [{
		"home_province_id": home_province_id,
		"conquered_province_ids": conquered_province_ids.duplicate(),
		"boss_faction_id": boss_faction_id
	}]
	var result: Dictionary = activate_multiple_bosses(spawn_entries)
	var states: Array[Dictionary] = []
	var raw_states: Variant = result.get("boss_states", [])
	if raw_states is Array:
		for entry in raw_states:
			if entry is Dictionary:
				states.append(entry)
	if states.is_empty():
		return {}
	return states[0].duplicate(true)


func activate_multiple_bosses(spawn_entries: Array[Dictionary]) -> Dictionary:
	var state: Dictionary = get_runtime_state()
	var bosses: Array[Dictionary] = []
	var boss_states: Array[Dictionary] = []
	var next_boss_id: int = maxi(1, int(state.get("next_boss_id", 1)))
	var first_active_boss_id: int = -1
	for index in range(spawn_entries.size()):
		var entry: Dictionary = spawn_entries[index]
		var boss_id: int = next_boss_id
		next_boss_id += 1
		var faction_id: int = int(entry.get("boss_faction_id", get_default_boss_faction_id_for_index(index)))
		var home_province_id: int = int(entry.get("home_province_id", -1))
		var conquered_ids: Array[int] = _as_int_array(entry.get("conquered_province_ids", []))
		var boss_state: Dictionary = _make_default_single_boss_state(boss_id, faction_id, home_province_id, conquered_ids)
		boss_state["active"] = true
		boss_state["dead"] = false
		boss_state["is_friendly_boss"] = bool(entry.get("is_friendly_boss", false))
		boss_state["boss_faction_name"] = String(entry.get("boss_faction_name", "")).strip_edges()
		boss_states.append(boss_state.duplicate(true))
		bosses.append(boss_state)
		if first_active_boss_id < 0:
			first_active_boss_id = boss_id
	state["bosses"] = bosses
	state["next_boss_id"] = next_boss_id
	state["primary_boss_id"] = first_active_boss_id
	_store_runtime_state(state)
	set_has_spawned_once(not boss_states.is_empty())
	return {
		"boss_count": boss_states.size(),
		"primary_boss_id": first_active_boss_id,
		"boss_states": boss_states
	}


func append_bosses(spawn_entries: Array[Dictionary]) -> Dictionary:
	var state: Dictionary = get_runtime_state()
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	var boss_states: Array[Dictionary] = []
	var next_boss_id: int = maxi(1, int(state.get("next_boss_id", 1)))
	for index in range(spawn_entries.size()):
		var entry: Dictionary = spawn_entries[index]
		var boss_id: int = next_boss_id
		next_boss_id += 1
		var faction_id: int = int(entry.get("boss_faction_id", get_default_boss_faction_id_for_index(index)))
		var home_province_id: int = int(entry.get("home_province_id", -1))
		var conquered_ids: Array[int] = _as_int_array(entry.get("conquered_province_ids", []))
		var boss_state: Dictionary = _make_default_single_boss_state(boss_id, faction_id, home_province_id, conquered_ids)
		boss_state["active"] = true
		boss_state["dead"] = false
		boss_state["is_friendly_boss"] = bool(entry.get("is_friendly_boss", false))
		boss_state["boss_faction_name"] = String(entry.get("boss_faction_name", "")).strip_edges()
		boss_states.append(boss_state.duplicate(true))
		bosses.append(boss_state)
	state["next_boss_id"] = next_boss_id
	state = _set_bosses_on_state(state, bosses)
	_store_runtime_state(state)
	set_has_spawned_once(not boss_states.is_empty())
	return {
		"boss_count": boss_states.size(),
		"primary_boss_id": get_primary_boss_id(),
		"boss_states": boss_states
	}



func _notify_boss_killed(boss_id: int) -> void:
	if boss_id < 0 or _main == null or _main.level_flow == null:
		return
	if _main.level_flow.has_method("_on_boss_killed_from_grand_map"):
		_main.level_flow.call("_on_boss_killed_from_grand_map", boss_id)


func mark_boss_dead(boss_id: int = -1) -> Dictionary:
	var state: Dictionary = get_runtime_state()
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	var resolved_boss_id: int = _resolve_default_boss_id(state, boss_id)
	var boss_index: int = _find_boss_index_in_array(bosses, resolved_boss_id)
	if boss_index == -1:
		return {}
	var boss_state: Dictionary = bosses[boss_index].duplicate(true)
	boss_state["active"] = false
	boss_state["dead"] = true
	boss_state["energy_generated_this_turn"] = 0
	boss_state["energy_drained_this_turn"] = 0
	boss_state["energy_available_this_turn"] = 0
	bosses[boss_index] = boss_state
	state = _set_bosses_on_state(state, bosses)
	_store_runtime_state(state)
	_notify_boss_killed(resolved_boss_id)
	return boss_state.duplicate(true)


func is_boss_active(boss_id: int = -1) -> bool:
	if boss_id >= 0:
		var boss_state: Dictionary = get_boss_state(boss_id)
		return bool(boss_state.get("active", false)) and not bool(boss_state.get("dead", false))
	return get_active_boss_count() > 0


func is_boss_dead(boss_id: int = -1) -> bool:
	if boss_id >= 0:
		return bool(get_boss_state(boss_id).get("dead", false))
	var bosses: Array[Dictionary] = get_all_boss_states()
	if bosses.is_empty():
		return false
	for boss_state in bosses:
		if bool(boss_state.get("active", false)) and not bool(boss_state.get("dead", false)):
			return false
	return true


func get_boss_faction_id(boss_id: int = -1) -> int:
	return int(get_boss_state(boss_id).get("boss_faction_id", BOSS_FACTION_ID))


func get_boss_faction_name(boss_id: int = -1) -> String:
	return String(get_boss_state(boss_id).get("boss_faction_name", "")).strip_edges()


func is_friendly_boss(boss_id: int = -1) -> bool:
	if boss_id >= 0:
		return bool(get_boss_state(boss_id).get("is_friendly_boss", false))
	for boss_state in get_active_boss_states():
		if bool(boss_state.get("is_friendly_boss", false)):
			return true
	return false


func is_friendly_boss_faction_id(faction_id: int) -> bool:
	return int(faction_id) == get_friendly_boss_faction_id()


func is_friendly_boss_home_province_id(province_id: int) -> bool:
	if province_id < 0:
		return false
	for boss_state in get_active_boss_states():
		if not bool(boss_state.get("is_friendly_boss", false)):
			continue
		if int(boss_state.get("home_province_id", -1)) == province_id:
			return true
	return false


func is_friendly_boss_current_province_id(province_id: int) -> bool:
	if province_id < 0:
		return false
	for boss_state in get_active_boss_states():
		if not bool(boss_state.get("is_friendly_boss", false)):
			continue
		var current_id: int = int(boss_state.get("current_province_id", boss_state.get("home_province_id", -1)))
		if current_id == province_id:
			return true
	return false


func get_boss_home_province_id(boss_id: int = -1) -> int:
	return int(get_boss_state(boss_id).get("home_province_id", -1))


func get_boss_current_province_id(boss_id: int = -1) -> int:
	return int(get_boss_state(boss_id).get("current_province_id", get_boss_home_province_id(boss_id)))


func set_boss_current_province_id(boss_id: int, province_id: int) -> void:
	if boss_id < 0:
		return
	var state: Dictionary = get_runtime_state()
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	var idx: int = _find_boss_index_in_array(bosses, boss_id)
	if idx < 0:
		return
	var boss_state: Dictionary = bosses[idx].duplicate(true)
	boss_state["current_province_id"] = int(province_id)
	bosses[idx] = boss_state
	state = _set_bosses_on_state(state, bosses)
	_store_runtime_state(state)


func is_boss_home_province_id(province_id: int, boss_id: int = -1) -> bool:
	if province_id < 0:
		return false
	if boss_id >= 0:
		return is_boss_active(boss_id) and province_id == get_boss_home_province_id(boss_id)
	return is_any_boss_home_province_id(province_id)


func is_any_boss_home_province_id(province_id: int) -> bool:
	if province_id < 0:
		return false
	for boss_state in get_active_boss_states():
		if int(boss_state.get("home_province_id", -1)) == province_id:
			return true
	return false


func is_boss_faction_province_state(province_state: Dictionary, boss_id: int = -1) -> bool:
	if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_ENEMY:
		return false
	if boss_id >= 0:
		return int(province_state.get("faction_id", 0)) == get_boss_faction_id(boss_id)
	var province_faction_id: int = int(province_state.get("faction_id", 0))
	for faction_id in get_all_boss_faction_ids():
		if province_faction_id == faction_id:
			return true
	return false


func get_all_boss_part_names() -> Array[String]:
	return [
		BOSS_PART_HEAD,
		BOSS_PART_LEFT_ARM,
		BOSS_PART_RIGHT_ARM,
		BOSS_PART_LEFT_LEG,
		BOSS_PART_RIGHT_LEG
	]


func is_valid_boss_part_name(part_name: String) -> bool:
	return get_all_boss_part_names().has(String(part_name).strip_edges())


func _get_campaign_extra_hits_for_part(part_name: String) -> int:
	if _main != null and _main.has_method("get_campaign_boss_part_extra_hits_to_kill"):
		return maxi(0, int(_main.call("get_campaign_boss_part_extra_hits_to_kill", String(part_name).strip_edges())))
	return 0


func _get_campaign_offense_bonus_for_key(bonus_key: String) -> int:
	if _main != null and _main.has_method("get_campaign_boss_offense_bonus_value"):
		return maxi(0, int(_main.call("get_campaign_boss_offense_bonus_value", String(bonus_key).strip_edges())))
	return 0


func get_required_hits_for_part(part_name: String, boss_id: int = -1) -> int:
	var resolved_boss_id: int = _resolve_default_boss_id(get_runtime_state(), boss_id)
	var normalized_part_name: String = String(part_name).strip_edges()
	var base_hits: int = 1
	match normalized_part_name:
		BOSS_PART_HEAD, BOSS_PART_LEFT_ARM, BOSS_PART_RIGHT_ARM, BOSS_PART_LEFT_LEG, BOSS_PART_RIGHT_LEG:
			base_hits = maxi(1, int(LevelConfig.get_boss_part_hit_points(normalized_part_name)))
		_:
			return 0
	var resolved_hits: int = base_hits + _get_campaign_extra_hits_for_part(normalized_part_name)
	if _main != null and _main.has_method("_get_boss_debug_required_hits_override"):
		var override_hits_any: Variant = _main.call("_get_boss_debug_required_hits_override", normalized_part_name, resolved_boss_id)
		if override_hits_any is int:
			var override_hits: int = int(override_hits_any)
			if override_hits > 0:
				resolved_hits = override_hits
	return resolved_hits


func is_part_destroyed(part_name: String, boss_id: int = -1) -> bool:
	var boss_state: Dictionary = get_boss_state(boss_id)
	var parts: Dictionary = boss_state.get("parts", {})
	var part_state: Dictionary = parts.get(String(part_name).strip_edges(), {})
	return bool(part_state.get("destroyed", false))


func get_part_hit_count(part_name: String, boss_id: int = -1) -> int:
	var boss_state: Dictionary = get_boss_state(boss_id)
	var parts: Dictionary = boss_state.get("parts", {})
	var part_state: Dictionary = parts.get(String(part_name).strip_edges(), {})
	return int(part_state.get("hits", 0))


func register_part_hit(part_name: String, boss_id: int = -1) -> Dictionary:
	var normalized_part_name: String = String(part_name).strip_edges()
	var state: Dictionary = get_runtime_state()
	var resolved_boss_id: int = _resolve_default_boss_id(state, boss_id)
	if is_friendly_boss(resolved_boss_id):
		normalized_part_name = BOSS_PART_HEAD
	var result: Dictionary = {
		"accepted": false,
		"boss_id": resolved_boss_id,
		"boss_faction_id": get_boss_faction_id(resolved_boss_id),
		"part": normalized_part_name,
		"hits_before": 0,
		"hits_after": 0,
		"required_hits": get_required_hits_for_part(normalized_part_name, resolved_boss_id),
		"part_destroyed": false,
		"boss_killed": false,
		"remaining_active_bosses": get_active_boss_count(),
		"remaining_active_boss_count": get_active_boss_count(),
		"all_bosses_defeated": false
	}
	if not is_valid_boss_part_name(normalized_part_name):
		return result
	if not is_boss_active(resolved_boss_id):
		return result

	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	var boss_index: int = _find_boss_index_in_array(bosses, resolved_boss_id)
	if boss_index == -1:
		return result
	var boss_state: Dictionary = bosses[boss_index].duplicate(true)
	var parts: Dictionary = boss_state.get("parts", {}).duplicate(true)
	var part_state: Dictionary = parts.get(normalized_part_name, _make_default_part_state()).duplicate(true)
	if bool(part_state.get("destroyed", false)):
		result["accepted"] = true
		result["hits_before"] = int(part_state.get("hits", 0))
		result["hits_after"] = int(part_state.get("hits", 0))
		return result

	var hits_before: int = int(part_state.get("hits", 0))
	var hits_after: int = hits_before + 1
	var required_hits: int = get_required_hits_for_part(normalized_part_name, resolved_boss_id)
	var part_destroyed: bool = hits_after >= required_hits
	part_state["hits"] = hits_after
	part_state["destroyed"] = part_destroyed
	parts[normalized_part_name] = part_state
	boss_state["parts"] = parts
	boss_state["last_hit_part"] = normalized_part_name

	var boss_killed: bool = false
	if normalized_part_name == BOSS_PART_HEAD and part_destroyed:
		boss_state["active"] = false
		boss_state["dead"] = true
		boss_state["energy_generated_this_turn"] = 0
		boss_state["energy_drained_this_turn"] = 0
		boss_state["energy_available_this_turn"] = 0
		boss_killed = true

	bosses[boss_index] = boss_state
	state = _set_bosses_on_state(state, bosses)
	_store_runtime_state(state)

	result["accepted"] = true
	result["boss_id"] = resolved_boss_id
	result["boss_faction_id"] = int(boss_state.get("boss_faction_id", BOSS_FACTION_ID))
	result["hits_before"] = hits_before
	result["hits_after"] = hits_after
	result["required_hits"] = required_hits
	result["part_destroyed"] = part_destroyed
	result["boss_killed"] = boss_killed
	result["remaining_active_bosses"] = get_active_boss_count()
	result["remaining_active_boss_count"] = get_active_boss_count()
	result["all_bosses_defeated"] = not is_boss_active()
	if boss_killed:
		_notify_boss_killed(resolved_boss_id)
	return result


func register_part_hit_for_home_province(part_name: String, home_province_id: int) -> Dictionary:
	var boss_id: int = get_boss_id_for_home_province_id(home_province_id)
	return register_part_hit(part_name, boss_id)


func get_remaining_hit_points_for_part(part_name: String, boss_id: int = -1) -> int:
	if not is_valid_boss_part_name(part_name):
		return 0
	if not is_boss_active(boss_id):
		return 0
	var required_hits: int = get_required_hits_for_part(part_name, boss_id)
	var current_hits: int = get_part_hit_count(part_name, boss_id)
	return maxi(0, required_hits - current_hits)


func get_total_remaining_hit_points(boss_id: int = -1) -> int:
	if boss_id >= 0:
		if not is_boss_active(boss_id):
			return 0
		var total_single: int = 0
		for part_name in get_all_boss_part_names():
			total_single += get_remaining_hit_points_for_part(part_name, boss_id)
		return total_single
	var total: int = 0
	for active_boss_id in get_active_boss_ids():
		total += get_total_remaining_hit_points(active_boss_id)
	return total


func get_boss_home_troop_count(boss_id: int = -1) -> int:
	if boss_id >= 0:
		if not is_boss_active(boss_id):
			return 0
		var boss_state: Dictionary = get_boss_state(boss_id)
		var carry: int = maxi(0, mini(BOSS_HOME_TROOPS_PER_HIT_POINT - 1, int(boss_state.get("home_troop_loss_carry", 0))))
		var linear_losses: int = maxi(0, int(boss_state.get("home_troop_linear_losses", 0)))
		var base_troops: int = get_total_remaining_hit_points(boss_id) * BOSS_HOME_TROOPS_PER_HIT_POINT
		if bool(boss_state.get("is_friendly_boss", false)):
			base_troops += int(LevelConfig.get_friendly_boss_bonus_home_troops())
		return maxi(0, base_troops - carry - linear_losses)
	var primary_boss_id: int = get_primary_boss_id()
	if primary_boss_id >= 0:
		return get_boss_home_troop_count(primary_boss_id)
	return 0


func get_boss_home_troop_count_for_home_province_id(home_province_id: int) -> int:
	var boss_id: int = get_boss_id_for_home_province_id(home_province_id)
	if boss_id < 0:
		return 0
	return get_boss_home_troop_count(boss_id)


func get_boss_home_building_count(boss_id: int = -1) -> int:
	if boss_id >= 0 and is_boss_active(boss_id):
		return 0
	if boss_id < 0 and is_boss_active():
		return 0
	return 0


func _set_boss_home_troop_loss_carry(boss_id: int, carry: int) -> void:
	if boss_id < 0:
		return
	var state: Dictionary = get_runtime_state()
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	var idx: int = _find_boss_index_in_array(bosses, boss_id)
	if idx == -1:
		return
	var boss_state: Dictionary = bosses[idx].duplicate(true)
	boss_state["home_troop_loss_carry"] = maxi(0, mini(BOSS_HOME_TROOPS_PER_HIT_POINT - 1, carry))
	bosses[idx] = boss_state
	state = _set_bosses_on_state(state, bosses)
	_store_runtime_state(state)


func apply_nonlethal_home_troop_losses(troops_lost: int, boss_id: int = -1) -> int:
	var resolved_boss_id: int = get_primary_boss_id() if boss_id < 0 else boss_id
	if resolved_boss_id < 0 or not is_boss_active(resolved_boss_id):
		return 0
	var losses_to_apply: int = maxi(0, troops_lost)
	if losses_to_apply <= 0:
		return get_boss_home_troop_count(resolved_boss_id)
	var state: Dictionary = get_runtime_state()
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	var idx: int = _find_boss_index_in_array(bosses, resolved_boss_id)
	if idx == -1:
		return get_boss_home_troop_count(resolved_boss_id)
	var boss_state: Dictionary = bosses[idx].duplicate(true)
	var current_linear_losses: int = maxi(0, int(boss_state.get("home_troop_linear_losses", 0)))
	var current_troops: int = get_boss_home_troop_count(resolved_boss_id)
	var next_troops: int = maxi(0, current_troops - losses_to_apply)
	var next_linear_losses: int = current_linear_losses + (current_troops - next_troops)
	boss_state["home_troop_linear_losses"] = maxi(0, next_linear_losses)
	bosses[idx] = boss_state
	state = _set_bosses_on_state(state, bosses)
	_store_runtime_state(state)
	return next_troops


func get_damageable_part_names(boss_id: int = -1) -> Array[String]:
	var damageable: Array[String] = []
	if not is_boss_active(boss_id):
		return damageable
	for part_name in get_all_boss_part_names():
		if get_remaining_hit_points_for_part(part_name, boss_id) > 0:
			damageable.append(part_name)
	return damageable


func apply_home_province_troop_losses(troops_lost: int, gen_rng: RandomNumberGenerator, boss_id: int = -1) -> Dictionary:
	var resolved_boss_id: int = get_primary_boss_id() if boss_id < 0 else boss_id
	var result: Dictionary = {
		"accepted": false,
		"boss_id": resolved_boss_id,
		"troops_lost": maxi(0, troops_lost),
		"troops_per_hit_point": BOSS_HOME_TROOPS_PER_HIT_POINT,
		"troop_chunks_applied": 0,
		"hitpoints_removed": 0,
		"troop_remainder": 0,
		"hit_results": [],
		"boss_killed": false,
		"remaining_hit_points": 0,
		"remaining_troops": 0
	}
	if resolved_boss_id < 0 or not is_boss_active(resolved_boss_id):
		result["remaining_hit_points"] = get_total_remaining_hit_points(resolved_boss_id)
		result["remaining_troops"] = get_boss_home_troop_count(resolved_boss_id)
		return result
	if gen_rng == null:
		gen_rng = RandomNumberGenerator.new()
		gen_rng.randomize()
	var boss_state_before: Dictionary = get_boss_state(resolved_boss_id)
	var carry_before: int = maxi(0, mini(BOSS_HOME_TROOPS_PER_HIT_POINT - 1, int(boss_state_before.get("home_troop_loss_carry", 0))))
	var total_loss_for_chunks: int = maxi(0, troops_lost) + carry_before
	var chunks_to_apply: int = int(total_loss_for_chunks / BOSS_HOME_TROOPS_PER_HIT_POINT)
	var carry_after: int = int(total_loss_for_chunks % BOSS_HOME_TROOPS_PER_HIT_POINT)
	result["troop_chunks_applied"] = chunks_to_apply
	result["troop_remainder"] = carry_after
	var hit_results: Array[Dictionary] = []
	for _i in range(chunks_to_apply):
		var damageable_parts: Array[String] = get_damageable_part_names(resolved_boss_id)
		if damageable_parts.is_empty():
			break
		var non_head_parts: Array[String] = []
		for part_name in damageable_parts:
			if String(part_name) != BOSS_PART_HEAD:
				non_head_parts.append(String(part_name))
		var candidate_parts: Array[String] = non_head_parts if not non_head_parts.is_empty() else damageable_parts
		var chosen_part: String = candidate_parts[gen_rng.randi_range(0, candidate_parts.size() - 1)]
		var hit_result: Dictionary = register_part_hit(chosen_part, resolved_boss_id)
		hit_results.append(hit_result)
		if bool(hit_result.get("boss_killed", false)):
			result["boss_killed"] = true
			break
	result["troop_chunks_applied"] = hit_results.size()
	result["hitpoints_removed"] = hit_results.size()
	if result["boss_killed"]:
		carry_after = 0
	_set_boss_home_troop_loss_carry(resolved_boss_id, carry_after if is_boss_active(resolved_boss_id) else 0)
	result["accepted"] = not hit_results.is_empty() or chunks_to_apply == 0
	result["hit_results"] = hit_results
	result["remaining_hit_points"] = get_total_remaining_hit_points(resolved_boss_id)
	result["remaining_troops"] = get_boss_home_troop_count(resolved_boss_id)
	return result


func apply_home_province_troop_losses_for_home_province_id(troops_lost: int, gen_rng: RandomNumberGenerator, home_province_id: int) -> Dictionary:
	var boss_id: int = get_boss_id_for_home_province_id(home_province_id)
	return apply_home_province_troop_losses(troops_lost, gen_rng, boss_id)


func count_surviving_arms(boss_id: int = -1) -> int:
	if boss_id >= 0:
		var count_single: int = 0
		if not is_part_destroyed(BOSS_PART_LEFT_ARM, boss_id):
			count_single += 1
		if not is_part_destroyed(BOSS_PART_RIGHT_ARM, boss_id):
			count_single += 1
		return count_single
	var total: int = 0
	for active_boss_id in get_active_boss_ids():
		total += count_surviving_arms(active_boss_id)
	return total


func count_surviving_legs(boss_id: int = -1) -> int:
	if boss_id >= 0:
		var count_single: int = 0
		if not is_part_destroyed(BOSS_PART_LEFT_LEG, boss_id):
			count_single += 1
		if not is_part_destroyed(BOSS_PART_RIGHT_LEG, boss_id):
			count_single += 1
		return count_single
	var total: int = 0
	for active_boss_id in get_active_boss_ids():
		total += count_surviving_legs(active_boss_id)
	return total


func get_boss_recruitment_bonus_for_faction(faction_id: int) -> int:
	var boss_id: int = get_boss_id_for_faction_id(faction_id)
	if boss_id < 0 or not is_boss_active(boss_id):
		return 0
	return _get_campaign_offense_bonus_for_key(LevelConfig.BOSS_OFFENSE_RECRUIT) + count_surviving_arms(boss_id) + count_surviving_legs(boss_id)


func get_total_boss_recruitment_bonus() -> int:
	var total: int = 0
	for boss_state in get_active_boss_states():
		total += get_boss_recruitment_bonus_for_faction(int(boss_state.get("boss_faction_id", BOSS_FACTION_ID)))
	return total


func compute_turn_energy_available(province_states: Array[Dictionary], pending_energy_drain: int = 0, boss_id: int = -1) -> int:
	if boss_id >= 0:
		var boss_state: Dictionary = get_boss_state(boss_id)
		var generated: int = BOSS_BASE_ENERGY_PER_TURN
		var boss_faction_id: int = int(boss_state.get("boss_faction_id", BOSS_FACTION_ID))
		for province_state in province_states:
			if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_ENEMY:
				continue
			if int(province_state.get("faction_id", 0)) != boss_faction_id:
				continue
			generated += BOSS_ENERGY_PER_PROVINCE
		return maxi(0, generated - maxi(0, pending_energy_drain))
	var total_available: int = 0
	for active_boss_id in get_active_boss_ids():
		total_available += compute_turn_energy_available(province_states, pending_energy_drain, active_boss_id)
	return total_available


func begin_boss_turn(province_states: Array[Dictionary], pending_energy_drain: int = 0, boss_id: int = -1) -> Dictionary:
	var state: Dictionary = get_runtime_state()
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	if boss_id >= 0:
		var boss_index: int = _find_boss_index_in_array(bosses, boss_id)
		if boss_index == -1:
			return {}
		var boss_state: Dictionary = bosses[boss_index].duplicate(true)
		var generated: int = BOSS_BASE_ENERGY_PER_TURN
		var boss_faction_id: int = int(boss_state.get("boss_faction_id", BOSS_FACTION_ID))
		for province_state in province_states:
			if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_ENEMY:
				continue
			if int(province_state.get("faction_id", 0)) != boss_faction_id:
				continue
			generated += BOSS_ENERGY_PER_PROVINCE
		boss_state["energy_generated_this_turn"] = generated
		boss_state["energy_drained_this_turn"] = maxi(0, pending_energy_drain)
		boss_state["energy_available_this_turn"] = maxi(0, generated - maxi(0, pending_energy_drain))
		boss_state["last_turn_log_lines"] = []
		bosses[boss_index] = boss_state
		state = _set_bosses_on_state(state, bosses)
		_store_runtime_state(state)
		return boss_state.duplicate(true)

	var combined: Dictionary = {
		"energy_generated_this_turn": 0,
		"energy_drained_this_turn": 0,
		"energy_available_this_turn": 0
	}
	var active_ids: Array[int] = get_active_boss_ids()
	var split_drains: Array[int] = _split_pending_energy_drain(pending_energy_drain, active_ids.size())
	for index in range(active_ids.size()):
		var one_state: Dictionary = begin_boss_turn(province_states, split_drains[index], active_ids[index])
		combined["energy_generated_this_turn"] += int(one_state.get("energy_generated_this_turn", 0))
		combined["energy_drained_this_turn"] += int(one_state.get("energy_drained_this_turn", 0))
		combined["energy_available_this_turn"] += int(one_state.get("energy_available_this_turn", 0))
	return combined


func clear_turn_energy(boss_id: int = -1) -> void:
	var state: Dictionary = get_runtime_state()
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	if boss_id >= 0:
		var boss_index: int = _find_boss_index_in_array(bosses, boss_id)
		if boss_index == -1:
			return
		var boss_state: Dictionary = bosses[boss_index].duplicate(true)
		boss_state["energy_generated_this_turn"] = 0
		boss_state["energy_drained_this_turn"] = 0
		boss_state["energy_available_this_turn"] = 0
		bosses[boss_index] = boss_state
	else:
		for index in range(bosses.size()):
			var boss_state: Dictionary = bosses[index].duplicate(true)
			boss_state["energy_generated_this_turn"] = 0
			boss_state["energy_drained_this_turn"] = 0
			boss_state["energy_available_this_turn"] = 0
			bosses[index] = boss_state
	state = _set_bosses_on_state(state, bosses)
	_store_runtime_state(state)


func get_energy_drain_from_arriving_troops(arriving_troops: int) -> int:
	if arriving_troops <= 0:
		return 0
	return int(arriving_troops / BOSS_ENERGY_DRAIN_TROOPS_PER_POINT)


func append_turn_log_line(line: String, boss_id: int = -1) -> void:
	var trimmed: String = line.strip_edges()
	if trimmed == "":
		return
	var state: Dictionary = get_runtime_state()
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	if boss_id >= 0:
		var boss_index: int = _find_boss_index_in_array(bosses, boss_id)
		if boss_index == -1:
			return
		var boss_state: Dictionary = bosses[boss_index].duplicate(true)
		var lines: Array[String] = _as_string_array(boss_state.get("last_turn_log_lines", []))
		lines.append(trimmed)
		boss_state["last_turn_log_lines"] = lines
		bosses[boss_index] = boss_state
	else:
		for index in range(bosses.size()):
			var boss_state: Dictionary = bosses[index].duplicate(true)
			if not bool(boss_state.get("active", false)) or bool(boss_state.get("dead", false)):
				continue
			var lines: Array[String] = _as_string_array(boss_state.get("last_turn_log_lines", []))
			lines.append(trimmed)
			boss_state["last_turn_log_lines"] = lines
			bosses[index] = boss_state
	state = _set_bosses_on_state(state, bosses)
	_store_runtime_state(state)


func get_turn_log_lines(boss_id: int = -1) -> Array[String]:
	if boss_id >= 0:
		return _as_string_array(get_boss_state(boss_id).get("last_turn_log_lines", []))
	var lines: Array[String] = []
	for boss_state in get_active_boss_states():
		for entry in _as_string_array(boss_state.get("last_turn_log_lines", [])):
			lines.append(entry)
	return lines


func choose_boss_home_province_id(candidate_provinces: Array[Dictionary], blocked_ids: Array[int] = []) -> int:
	var blocked_lookup: Dictionary = {}
	for province_id in blocked_ids:
		blocked_lookup[int(province_id)] = true

	var best_id: int = -1
	var best_score: float = INF
	for province in candidate_provinces:
		var province_id: int = int(province.get("id", -1))
		if province_id < 0:
			continue
		if blocked_lookup.has(province_id):
			continue
		if bool(province.get("is_target", false)):
			continue
		var center: Vector2 = province.get("center", Vector2.ZERO)
		var center_score: float = center.length()
		var area: float = float(province.get("area", 0.0))
		var area_bonus: float = -minf(area, 500000.0) * 0.00005
		var score: float = center_score + area_bonus
		if score < best_score:
			best_score = score
			best_id = province_id
	return best_id


func choose_multiple_boss_home_province_ids(candidate_provinces: Array[Dictionary], blocked_ids: Array[int], count: int) -> Array[int]:
	var chosen_ids: Array[int] = []
	var working_blocked: Array[int] = blocked_ids.duplicate()
	for _i in range(maxi(0, count)):
		var next_home_id: int = choose_boss_home_province_id(candidate_provinces, working_blocked)
		if next_home_id < 0:
			break
		chosen_ids.append(next_home_id)
		working_blocked.append(next_home_id)
	return chosen_ids


func choose_initial_boss_faction_province_ids(candidate_provinces: Array[Dictionary], excluded_ids: Array[int], gen_rng: RandomNumberGenerator, count: int = BOSS_INITIAL_CONQUERED_PROVINCES) -> Array[int]:
	var excluded_lookup: Dictionary = {}
	for province_id in excluded_ids:
		excluded_lookup[int(province_id)] = true

	var friendly_pool: Array[int] = []
	var enemy_pool: Array[int] = []
	var neutral_pool: Array[int] = []
	for province in candidate_provinces:
		var province_id: int = int(province.get("id", -1))
		if province_id < 0:
			continue
		if excluded_lookup.has(province_id):
			continue
		if bool(province.get("is_target", false)):
			continue
		var province_type: String = String(province.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			friendly_pool.append(province_id)
		elif province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
			enemy_pool.append(province_id)
		else:
			neutral_pool.append(province_id)

	_shuffle_int_array(friendly_pool, gen_rng)
	_shuffle_int_array(enemy_pool, gen_rng)
	_shuffle_int_array(neutral_pool, gen_rng)
	var picked: Array[int] = []
	var desired_count: int = maxi(0, count)
	while picked.size() < desired_count:
		var friendly_available: bool = not friendly_pool.is_empty()
		var enemy_available: bool = not enemy_pool.is_empty()
		var neutral_available: bool = not neutral_pool.is_empty()
		if not friendly_available and not enemy_available and not neutral_available:
			break
		var pick_pool: String = "neutral"
		if friendly_available and enemy_available:
			pick_pool = "friendly" if gen_rng.randf() < 0.5 else "enemy"
		elif friendly_available:
			pick_pool = "friendly"
		elif enemy_available:
			pick_pool = "enemy"
		else:
			pick_pool = "neutral"
		if pick_pool == "friendly":
			picked.append(int(friendly_pool.pop_back()))
		elif pick_pool == "enemy":
			picked.append(int(enemy_pool.pop_back()))
		else:
			picked.append(int(neutral_pool.pop_back()))
	return picked


func get_valid_punch_target_ids(province_states: Array[Dictionary], boss_id: int = -1) -> Array[int]:
	var valid_ids: Array[int] = _get_valid_target_ids(province_states, true, false, boss_id)
	if valid_ids.is_empty():
		return valid_ids
	var filtered_ids: Array[int] = []
	for province_id in valid_ids:
		if is_friendly_boss_home_province_id(int(province_id)) or is_friendly_boss_current_province_id(int(province_id)):
			continue
		filtered_ids.append(int(province_id))
	return filtered_ids


func get_valid_kick_target_ids(province_states: Array[Dictionary], boss_id: int = -1) -> Array[int]:
	return _get_valid_target_ids(province_states, false, true, boss_id)


func _get_valid_target_ids(province_states: Array[Dictionary], require_troops: bool, require_buildings: bool, boss_id: int = -1) -> Array[int]:
	var valid_ids: Array[int] = []
	var excluded_home_ids: Dictionary = {}
	for home_id in get_all_boss_home_province_ids():
		excluded_home_ids[int(home_id)] = true
	if boss_id >= 0:
		var acting_home_id: int = get_boss_home_province_id(boss_id)
		if acting_home_id >= 0:
			excluded_home_ids[acting_home_id] = true
	for province_state in province_states:
		if not _is_valid_boss_attack_target_state(province_state, excluded_home_ids, require_troops, require_buildings, boss_id):
			continue
		valid_ids.append(int(province_state.get("id", -1)))
	return valid_ids


func _is_valid_boss_attack_target_state(province_state: Dictionary, excluded_home_ids: Dictionary, require_troops: bool, require_buildings: bool, boss_id: int = -1) -> bool:
	var province_id: int = int(province_state.get("id", -1))
	if province_id < 0:
		return false
	if excluded_home_ids.has(province_id):
		return false
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if is_friendly_boss(boss_id):
		if province_type != BOSS_TARGET_ENEMY:
			return false
		if is_friendly_boss_faction_id(int(province_state.get("faction_id", 0))):
			return false
		if require_troops and int(province_state.get("remaining_troops", 0)) <= 0:
			return false
		if require_buildings and int(province_state.get("remaining_buildings", 0)) <= 0:
			return false
		return true
	if is_boss_faction_province_state(province_state):
		return false
	if province_type != BOSS_TARGET_FRIENDLY and province_type != BOSS_TARGET_ENEMY:
		return false
	if require_troops and int(province_state.get("remaining_troops", 0)) <= 0:
		return false
	if require_buildings and int(province_state.get("remaining_buildings", 0)) <= 0:
		return false
	return true


func build_boss_turn_plan(province_states: Array[Dictionary], gen_rng: RandomNumberGenerator, pending_energy_drain: int = 0) -> Dictionary:
	var actions: Array[Dictionary] = []
	var per_boss_plans: Array[Dictionary] = []
	var energy_generated_total: int = 0
	var energy_drained_total: int = 0
	var energy_spent_total: int = 0
	var energy_remaining_total: int = 0

	var active_ids: Array[int] = get_active_boss_ids()
	if active_ids.is_empty():
		return {
			"energy_generated": 0,
			"energy_drained": 0,
			"energy_spent": 0,
			"energy_remaining": 0,
			"actions": [],
			"boss_plans": []
		}

	var split_drains: Array[int] = _split_pending_energy_drain(pending_energy_drain, active_ids.size())
	for index in range(active_ids.size()):
		var boss_id: int = active_ids[index]
		var boss_state: Dictionary = begin_boss_turn(province_states, split_drains[index], boss_id)
		var available_energy: int = int(boss_state.get("energy_available_this_turn", 0))
		var boss_actions: Array[Dictionary] = []
		var boss_energy_spent: int = 0
		var action_tokens: Array[Dictionary] = []

		if not is_part_destroyed(BOSS_PART_LEFT_ARM, boss_id):
			action_tokens.append({"attack_type": "punch", "part": BOSS_PART_LEFT_ARM, "cost": BOSS_PUNCH_COST, "boss_id": boss_id})
		if not is_part_destroyed(BOSS_PART_RIGHT_ARM, boss_id):
			action_tokens.append({"attack_type": "punch", "part": BOSS_PART_RIGHT_ARM, "cost": BOSS_PUNCH_COST, "boss_id": boss_id})
		if not is_part_destroyed(BOSS_PART_LEFT_LEG, boss_id):
			action_tokens.append({"attack_type": "kick", "part": BOSS_PART_LEFT_LEG, "cost": BOSS_KICK_COST, "boss_id": boss_id})
		if not is_part_destroyed(BOSS_PART_RIGHT_LEG, boss_id):
			action_tokens.append({"attack_type": "kick", "part": BOSS_PART_RIGHT_LEG, "cost": BOSS_KICK_COST, "boss_id": boss_id})

		_shuffle_dict_array(action_tokens, gen_rng)

		for token in action_tokens:
			var cost: int = int(token.get("cost", 0))
			if cost <= 0 or cost > available_energy:
				continue
			var attack_type: String = String(token.get("attack_type", ""))
			var target_ids: Array[int] = []
			if attack_type == "punch":
				target_ids = get_valid_punch_target_ids(province_states, boss_id)
			elif attack_type == "kick":
				target_ids = get_valid_kick_target_ids(province_states, boss_id)
			if target_ids.is_empty():
				continue

			var target_id: int = target_ids[gen_rng.randi_range(0, target_ids.size() - 1)]
			var part_name: String = String(token.get("part", ""))
			var action: Dictionary = {
				"boss_id": boss_id,
				"boss_faction_id": int(boss_state.get("boss_faction_id", BOSS_FACTION_ID)),
				"attack_type": attack_type,
				"part": part_name,
				"province_id": target_id,
				"energy_cost": cost
			}
			if attack_type == "punch":
				var punch_bonus_key: String = LevelConfig.BOSS_OFFENSE_LEFT_ARM_PUNCH if part_name == BOSS_PART_LEFT_ARM else LevelConfig.BOSS_OFFENSE_RIGHT_ARM_PUNCH
				var extra_kills: int = _get_campaign_offense_bonus_for_key(punch_bonus_key)
				action["troop_damage"] = gen_rng.randi_range(BOSS_PUNCH_DAMAGE_MIN, BOSS_PUNCH_DAMAGE_MAX) + extra_kills
				action["bonus_value"] = extra_kills
			else:
				var kick_bonus_key: String = LevelConfig.BOSS_OFFENSE_LEFT_LEG_KICK if part_name == BOSS_PART_LEFT_LEG else LevelConfig.BOSS_OFFENSE_RIGHT_LEG_KICK
				var extra_buildings: int = _get_campaign_offense_bonus_for_key(kick_bonus_key)
				action["building_damage"] = gen_rng.randi_range(BOSS_KICK_DAMAGE_MIN, BOSS_KICK_DAMAGE_MAX) + extra_buildings
				action["bonus_value"] = extra_buildings

			boss_actions.append(action)
			actions.append(action.duplicate(true))
			available_energy -= cost
			boss_energy_spent += cost

		_update_boss_energy_available(boss_id, available_energy)
		energy_generated_total += int(boss_state.get("energy_generated_this_turn", 0))
		energy_drained_total += int(boss_state.get("energy_drained_this_turn", 0))
		energy_spent_total += boss_energy_spent
		energy_remaining_total += available_energy
		per_boss_plans.append({
			"boss_id": boss_id,
			"boss_faction_id": int(boss_state.get("boss_faction_id", BOSS_FACTION_ID)),
			"energy_generated": int(boss_state.get("energy_generated_this_turn", 0)),
			"energy_drained": int(boss_state.get("energy_drained_this_turn", 0)),
			"energy_spent": boss_energy_spent,
			"energy_remaining": available_energy,
			"actions": boss_actions
		})

	return {
		"energy_generated": energy_generated_total,
		"energy_drained": energy_drained_total,
		"energy_spent": energy_spent_total,
		"energy_remaining": energy_remaining_total,
		"actions": actions,
		"boss_plans": per_boss_plans
	}


func _update_boss_energy_available(boss_id: int, available_energy: int) -> void:
	var state: Dictionary = get_runtime_state()
	var bosses: Array[Dictionary] = _get_bosses_from_state(state)
	var boss_index: int = _find_boss_index_in_array(bosses, boss_id)
	if boss_index == -1:
		return
	var boss_state: Dictionary = bosses[boss_index].duplicate(true)
	boss_state["energy_available_this_turn"] = maxi(0, available_energy)
	bosses[boss_index] = boss_state
	state = _set_bosses_on_state(state, bosses)
	_store_runtime_state(state)


func apply_boss_turn_plan(province_states: Array[Dictionary], plan: Dictionary) -> Dictionary:
	var by_id: Dictionary = {}
	for province_state in province_states:
		by_id[int(province_state.get("id", -1))] = province_state

	var results: Array[Dictionary] = []
	var raw_actions: Variant = plan.get("actions", [])
	if raw_actions is Array:
		for action_any in raw_actions:
			if not (action_any is Dictionary):
				continue
			var action: Dictionary = action_any
			var province_id: int = int(action.get("province_id", -1))
			if not by_id.has(province_id):
				continue
			var province_state: Dictionary = by_id[province_id]
			var attack_type: String = String(action.get("attack_type", ""))
			if attack_type == "punch":
				var before_troops: int = int(province_state.get("remaining_troops", 0))
				var troop_damage: int = int(action.get("troop_damage", 0))
				var after_troops: int = maxi(0, before_troops - troop_damage)
				province_state["remaining_troops"] = after_troops
				results.append({
					"boss_id": int(action.get("boss_id", -1)),
					"boss_faction_id": int(action.get("boss_faction_id", BOSS_FACTION_ID)),
					"attack_type": attack_type,
					"province_id": province_id,
					"before_troops": before_troops,
					"after_troops": after_troops,
					"applied_damage": before_troops - after_troops,
					"part": String(action.get("part", ""))
				})
			elif attack_type == "kick":
				var before_buildings: int = int(province_state.get("remaining_buildings", 0))
				var building_damage: int = int(action.get("building_damage", 0))
				var after_buildings: int = maxi(0, before_buildings - building_damage)
				province_state["remaining_buildings"] = after_buildings
				results.append({
					"boss_id": int(action.get("boss_id", -1)),
					"boss_faction_id": int(action.get("boss_faction_id", BOSS_FACTION_ID)),
					"attack_type": attack_type,
					"province_id": province_id,
					"before_buildings": before_buildings,
					"after_buildings": after_buildings,
					"applied_damage": before_buildings - after_buildings,
					"part": String(action.get("part", ""))
				})

	return {
		"energy_generated": int(plan.get("energy_generated", 0)),
		"energy_drained": int(plan.get("energy_drained", 0)),
		"energy_spent": int(plan.get("energy_spent", 0)),
		"energy_remaining": int(plan.get("energy_remaining", 0)),
		"results": results,
		"boss_plans": plan.get("boss_plans", [])
	}


func make_hit_status_text(hit_result: Dictionary) -> String:
	if not bool(hit_result.get("accepted", false)):
		return "The boss ignored the hit."
	var part_name: String = _format_boss_part_name(String(hit_result.get("part", "")))
	var hits_after: int = int(hit_result.get("hits_after", 0))
	var required_hits: int = int(hit_result.get("required_hits", 0))
	var remaining_bosses: int = int(hit_result.get("remaining_active_boss_count", hit_result.get("remaining_active_bosses", 0)))
	if bool(hit_result.get("boss_killed", false)):
		if bool(hit_result.get("all_bosses_defeated", false)):
			return "%s was hit (%d/%d). The head was destroyed and the last boss died." % [part_name, hits_after, required_hits]
		return "%s was hit (%d/%d). The head was destroyed and that boss died. %d boss%s remain." % [part_name, hits_after, required_hits, remaining_bosses, "" if remaining_bosses == 1 else "es"]
	if bool(hit_result.get("part_destroyed", false)):
		return "%s was hit (%d/%d) and destroyed." % [part_name, hits_after, required_hits]
	return "%s was hit (%d/%d)." % [part_name, hits_after, required_hits]


func _format_boss_part_name(part_name: String) -> String:
	match part_name:
		BOSS_PART_HEAD:
			return "Head"
		BOSS_PART_LEFT_ARM:
			return "Left arm"
		BOSS_PART_RIGHT_ARM:
			return "Right arm"
		BOSS_PART_LEFT_LEG:
			return "Left leg"
		BOSS_PART_RIGHT_LEG:
			return "Right leg"
		_:
			return "Boss part"


func _split_pending_energy_drain(total_drain: int, recipient_count: int) -> Array[int]:
	var splits: Array[int] = []
	var safe_total: int = maxi(0, total_drain)
	var safe_count: int = maxi(0, recipient_count)
	if safe_count <= 0:
		return splits
	var base_value: int = int(safe_total / safe_count)
	var remainder: int = int(safe_total % safe_count)
	for index in range(safe_count):
		splits.append(base_value + (1 if index < remainder else 0))
	return splits


func _as_int_array(raw_value: Variant) -> Array[int]:
	var values: Array[int] = []
	if raw_value is Array:
		for entry in raw_value:
			values.append(int(entry))
	return values


func _as_string_array(raw_value: Variant) -> Array[String]:
	var values: Array[String] = []
	if raw_value is Array:
		for entry in raw_value:
			values.append(String(entry))
	return values


func _shuffle_int_array(values: Array[int], gen_rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j: int = gen_rng.randi_range(0, i)
		var temp: int = values[i]
		values[i] = values[j]
		values[j] = temp


func _shuffle_dict_array(values: Array[Dictionary], gen_rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j: int = gen_rng.randi_range(0, i)
		var temp: Dictionary = values[i]
		values[i] = values[j]
		values[j] = temp
