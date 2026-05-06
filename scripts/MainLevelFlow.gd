extends RefCounted

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const LevelGenerator = preload("res://scripts/LevelGenerator.gd")

const BOSS_VISUAL_ROOT_NAME: String = "BossVisualRoot"
const BOSS_VISUAL_CONTAINER_PREFIX: String = "BossVisualContainer_"
const BOSS_PART_GROUP: String = "boss_part"
const BOSS_PART_HIT_SEPARATOR: String = "|"
const FRIENDLY_BOSS_PENDING_OVERLAY_ROOT_NAME: String = "FriendlyBossPendingOverlayRoot"
const BOSS_FOOTPRINT_HALF_SIZE: Vector2 = Vector2(88.0, 118.0)
const BOSS_FOOTPRINT_CLEARANCE: float = 14.0

const OPENING_TUTORIAL_ACTIVE_META: String = "opening_gameplay_tutorial_active"
const OPENING_TUTORIAL_SKIPPED_META: String = "opening_gameplay_tutorial_skipped"
const OPENING_TUTORIAL_COMPLETED_META: String = "opening_gameplay_tutorial_completed"
const OPENING_TUTORIAL_TARGET_PROVINCE_META: String = "opening_gameplay_tutorial_target_province_id"
const OPENING_TUTORIAL_ORIGIN_PROVINCE_META: String = "opening_gameplay_tutorial_origin_province_id"
const OPENING_TUTORIAL_HOME_PROVINCE_ID: int = 0
const OPENING_TUTORIAL_TARGET_PROVINCE_ID: int = 1
const OPENING_TUTORIAL_HOME_PROVINCE_NAME: String = "Home Province"
const OPENING_TUTORIAL_TARGET_PROVINCE_NAME: String = "Neutral Province"
const PENDING_FRIENDLY_BOSS_SPAWN_META: String = "pending_friendly_boss_spawn_entry"

var _main: Node = null
var _live_caltrop_nodes_by_key: Dictionary = {}
var _active_caltrop_button_areas: Array[Area2D] = []
var _cached_grand_map_seed: int = 0
var _cached_grand_map_generation_level: int = 0
var _cached_grand_map_zone_children: Array = []
var _cached_grand_map_obstacle_children: Array = []
var _cached_grand_map_province_children: Array = []
var _last_queued_boss_hit_token: String = ""
var _last_queued_boss_hit_frame: int = -1


func setup(main_node: Node) -> void:
	_main = main_node


func _set_runtime_meta_value(key: String, value: Variant) -> void:
	if _main == null:
		return
	_main.set_meta(key, value)


func _get_runtime_meta_value(key: String, default_value: Variant = null) -> Variant:
	if _main == null or not _main.has_meta(key):
		return default_value
	return _main.get_meta(key)


func get_opening_gameplay_tutorial_skip_label() -> String:
	return "Skip Tutorial"


func is_opening_gameplay_tutorial_active() -> bool:
	return bool(_get_runtime_meta_value(OPENING_TUTORIAL_ACTIVE_META, false))


func has_opening_gameplay_tutorial_completed() -> bool:
	return bool(_get_runtime_meta_value(OPENING_TUTORIAL_COMPLETED_META, false))


func has_opening_gameplay_tutorial_been_skipped() -> bool:
	return bool(_get_runtime_meta_value(OPENING_TUTORIAL_SKIPPED_META, false))


func should_start_opening_gameplay_tutorial() -> bool:
	if _main == null:
		return false
	var is_first_campaign_level: bool = int(_main.get_campaign_current_level_progress()) <= 1
	var has_no_campaign_clears: bool = int(_main.campaign_total_cleared_levels) <= 0
	if is_first_campaign_level and has_no_campaign_clears:
		return true
	if is_opening_gameplay_tutorial_active():
		return true
	if has_opening_gameplay_tutorial_completed() or has_opening_gameplay_tutorial_been_skipped():
		return false
	var guide: Object = _main.get("tutorial_guide") as Object
	if guide != null:
		if guide.has_method("should_auto_start_gameplay_tutorial"):
			return bool(guide.call("should_auto_start_gameplay_tutorial"))
		if guide.has_method("should_auto_start_first_run"):
			return bool(guide.call("should_auto_start_first_run"))
	return LevelConfig.should_auto_start_first_run_tutorial()


func start_opening_gameplay_tutorial() -> void:
	if _main == null:
		return
	var guide: Object = _main.get("tutorial_guide") as Object
	if guide != null and guide.has_method("mark_gameplay_tutorial_started"):
		guide.call("mark_gameplay_tutorial_started")
	_set_runtime_meta_value(OPENING_TUTORIAL_ACTIVE_META, true)
	_set_runtime_meta_value(OPENING_TUTORIAL_SKIPPED_META, false)
	_set_runtime_meta_value(OPENING_TUTORIAL_COMPLETED_META, false)
	_set_runtime_meta_value(OPENING_TUTORIAL_ORIGIN_PROVINCE_META, OPENING_TUTORIAL_HOME_PROVINCE_ID)
	_set_runtime_meta_value(OPENING_TUTORIAL_TARGET_PROVINCE_META, OPENING_TUTORIAL_TARGET_PROVINCE_ID)
	_main._locked_province_id_after_win = OPENING_TUTORIAL_HOME_PROVINCE_ID
	_main._active_engagement_province_id = -1
	_invalidate_grand_map_snapshot()
	generate_grand_map()


func skip_opening_gameplay_tutorial() -> void:
	if _main == null:
		return
	var guide: Object = _main.get("tutorial_guide") as Object
	if guide != null and guide.has_method("mark_gameplay_tutorial_skipped"):
		guide.call("mark_gameplay_tutorial_skipped")
	_set_runtime_meta_value(OPENING_TUTORIAL_ACTIVE_META, false)
	_set_runtime_meta_value(OPENING_TUTORIAL_SKIPPED_META, true)
	_set_runtime_meta_value(OPENING_TUTORIAL_COMPLETED_META, false)


func mark_opening_gameplay_tutorial_complete() -> void:
	if _main == null:
		return
	var guide: Object = _main.get("tutorial_guide") as Object
	if guide != null and guide.has_method("mark_gameplay_tutorial_completed"):
		guide.call("mark_gameplay_tutorial_completed")
	_set_runtime_meta_value(OPENING_TUTORIAL_ACTIVE_META, false)
	_set_runtime_meta_value(OPENING_TUTORIAL_SKIPPED_META, false)
	_set_runtime_meta_value(OPENING_TUTORIAL_COMPLETED_META, true)


func _get_opening_gameplay_tutorial_target_province_id() -> int:
	return int(_get_runtime_meta_value(OPENING_TUTORIAL_TARGET_PROVINCE_META, OPENING_TUTORIAL_TARGET_PROVINCE_ID))


func _get_opening_gameplay_tutorial_origin_province_id() -> int:
	return int(_get_runtime_meta_value(OPENING_TUTORIAL_ORIGIN_PROVINCE_META, OPENING_TUTORIAL_HOME_PROVINCE_ID))


func _build_opening_gameplay_tutorial_status_text() -> String:
	if _is_opening_gameplay_tutorial_clear_condition_met():
		return "Tutorial complete."
	if _main != null and int(_main.turn_number) <= 1:
		return "Tutorial — start from the highlighted friendly province and clear the neutral province."
	return "Tutorial — keep attacking the neutral province until all of its troops are gone."


func _build_opening_gameplay_tutorial_initial_entries() -> Array[Dictionary]:
	var friendly_defaults: Dictionary = _main.province_system.get_default_province_counts(LevelConfig.PROVINCE_TYPE_FRIENDLY) if _main != null and _main.province_system != null else {}
	var neutral_defaults: Dictionary = _main.province_system.get_default_province_counts(LevelConfig.PROVINCE_TYPE_NEUTRAL) if _main != null and _main.province_system != null else {}
	return [
		{
			"id": OPENING_TUTORIAL_HOME_PROVINCE_ID,
			"type": LevelConfig.PROVINCE_TYPE_FRIENDLY,
			"province_name": OPENING_TUTORIAL_HOME_PROVINCE_NAME,
			"remaining_buildings": 0,
			"remaining_troops": int(friendly_defaults.get("remaining_troops", LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_FRIENDLY))),
			"neighbors": [OPENING_TUTORIAL_TARGET_PROVINCE_ID],
			"invading_troops": 0,
			"encounter_seed": 0,
			"encounter_level": 0,
			"faction_id": int(friendly_defaults.get("faction_id", 0)),
			"construction_progress": 0,
			"is_target": false,
			"capture_source": "none",
			"is_boss_home": false,
			"caltrops": [],
			"gold_production": 0,
			"free_buildings": 0,
			"building_capacity": LevelConfig.PROVINCE_BUILDING_CAP_MIN,
			"engagement_map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		},
		{
			"id": OPENING_TUTORIAL_TARGET_PROVINCE_ID,
			"type": LevelConfig.PROVINCE_TYPE_NEUTRAL,
			"province_name": OPENING_TUTORIAL_TARGET_PROVINCE_NAME,
			"remaining_buildings": 0,
			"remaining_troops": int(neutral_defaults.get("remaining_troops", LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_NEUTRAL))),
			"neighbors": [OPENING_TUTORIAL_HOME_PROVINCE_ID],
			"invading_troops": 0,
			"encounter_seed": 0,
			"encounter_level": 0,
			"faction_id": int(neutral_defaults.get("faction_id", 0)),
			"construction_progress": 0,
			"is_target": false,
			"capture_source": "none",
			"is_boss_home": false,
			"caltrops": [],
			"gold_production": 0,
			"free_buildings": 0,
			"building_capacity": LevelConfig.PROVINCE_BUILDING_CAP_MIN,
			"engagement_map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		}
	]


func _get_or_build_opening_gameplay_tutorial_entries() -> Array[Dictionary]:
	var previous_by_id: Dictionary = {}
	if _main != null:
		for entry_any in _main._province_persistence:
			if entry_any is Dictionary:
				var entry: Dictionary = (entry_any as Dictionary).duplicate(true)
				previous_by_id[int(entry.get("id", -1))] = entry
	var resolved_entries: Array[Dictionary] = []
	for entry_any in _build_opening_gameplay_tutorial_initial_entries():
		var base_entry: Dictionary = (entry_any as Dictionary).duplicate(true)
		var province_id: int = int(base_entry.get("id", -1))
		if previous_by_id.has(province_id):
			var prev: Dictionary = (previous_by_id[province_id] as Dictionary).duplicate(true)
			prev["neighbors"] = Array(base_entry.get("neighbors", [])).duplicate()
			prev["province_name"] = OPENING_TUTORIAL_HOME_PROVINCE_NAME if province_id == OPENING_TUTORIAL_HOME_PROVINCE_ID else OPENING_TUTORIAL_TARGET_PROVINCE_NAME
			prev["remaining_buildings"] = 0
			prev["is_boss_home"] = false
			prev["caltrops"] = []
			prev["gold_production"] = 0
			prev["free_buildings"] = 0
			prev["building_capacity"] = LevelConfig.PROVINCE_BUILDING_CAP_MIN
			prev["engagement_map_type"] = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
			resolved_entries.append(prev)
		else:
			resolved_entries.append(base_entry)
	return resolved_entries


func _build_opening_gameplay_tutorial_province_layout(entries: Array[Dictionary]) -> Array[Dictionary]:
	var left_poly: PackedVector2Array = PackedVector2Array([
		Vector2(-760.0, -360.0),
		Vector2(0.0, -360.0),
		Vector2(0.0, 360.0),
		Vector2(-760.0, 360.0)
	])
	var right_poly: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -360.0),
		Vector2(760.0, -360.0),
		Vector2(760.0, 360.0),
		Vector2(0.0, 360.0)
	])
	var by_id: Dictionary = {}
	for entry_any in entries:
		if entry_any is Dictionary:
			var entry: Dictionary = entry_any
			by_id[int(entry.get("id", -1))] = entry
	var left_entry: Dictionary = (by_id.get(OPENING_TUTORIAL_HOME_PROVINCE_ID, {}) as Dictionary).duplicate(true)
	var right_entry: Dictionary = (by_id.get(OPENING_TUTORIAL_TARGET_PROVINCE_ID, {}) as Dictionary).duplicate(true)
	return [
		{
			"id": OPENING_TUTORIAL_HOME_PROVINCE_ID,
			"polygon": left_poly,
			"type": String(left_entry.get("type", LevelConfig.PROVINCE_TYPE_FRIENDLY)),
			"troops": int(left_entry.get("remaining_troops", 0)),
			"buildings": 0,
			"invading_troops": int(left_entry.get("invading_troops", 0)),
			"neighbors": [OPENING_TUTORIAL_TARGET_PROVINCE_ID],
			"faction_id": int(left_entry.get("faction_id", 0)),
			"is_target": false,
			"is_boss_home": false,
			"province_name": OPENING_TUTORIAL_HOME_PROVINCE_NAME,
			"gold_production": 0,
			"free_buildings": 0,
			"building_capacity": LevelConfig.PROVINCE_BUILDING_CAP_MIN,
			"engagement_map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL,
			"tint_index": 0
		},
		{
			"id": OPENING_TUTORIAL_TARGET_PROVINCE_ID,
			"polygon": right_poly,
			"type": String(right_entry.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			"troops": int(right_entry.get("remaining_troops", 0)),
			"buildings": 0,
			"invading_troops": int(right_entry.get("invading_troops", 0)),
			"neighbors": [OPENING_TUTORIAL_HOME_PROVINCE_ID],
			"faction_id": int(right_entry.get("faction_id", 0)),
			"is_target": false,
			"is_boss_home": false,
			"province_name": OPENING_TUTORIAL_TARGET_PROVINCE_NAME,
			"gold_production": 0,
			"free_buildings": 0,
			"building_capacity": LevelConfig.PROVINCE_BUILDING_CAP_MIN,
			"engagement_map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL,
			"tint_index": 1
		}
	]


func _render_opening_gameplay_tutorial_sand_backdrop() -> void:
	if _main == null or not is_instance_valid(_main.zones_root):
		return
	var half_extents: Vector2 = LevelConfig.GRAND_MAP_HALF_EXTENTS
	var sand := Polygon2D.new()
	sand.name = "TutorialGrandMapSand"
	sand.polygon = PackedVector2Array([
		Vector2(-half_extents.x, -half_extents.y),
		Vector2(half_extents.x, -half_extents.y),
		Vector2(half_extents.x, half_extents.y),
		Vector2(-half_extents.x, half_extents.y)
	])
	sand.color = LevelConfig.RESORT_SAND
	sand.z_index = LevelConfig.VISUAL_LAYER_SAND
	_main.zones_root.add_child(sand)

	var sand_tile_texture: Texture2D = load(LevelConfig.RESORT_SAND_TILE_TEXTURE_PATH) as Texture2D
	if sand_tile_texture == null:
		return
	var texture_layer := Node2D.new()
	texture_layer.name = "TutorialGrandMapSandTexture"
	texture_layer.z_index = LevelConfig.VISUAL_LAYER_SAND
	_main.zones_root.add_child(texture_layer)
	var tile_size := maxf(16.0, LevelConfig.RESORT_SAND_TILE_SIZE)
	var tile_scale := tile_size / maxf(1.0, float(sand_tile_texture.get_width()))
	var rendered_tile_width := maxf(1.0, float(sand_tile_texture.get_width()) * tile_scale)
	var rendered_tile_height := maxf(1.0, float(sand_tile_texture.get_height()) * tile_scale)
	var map_width := half_extents.x * 2.0
	var map_height := half_extents.y * 2.0
	var columns := int(ceil(map_width / rendered_tile_width)) + 1
	var rows := int(ceil(map_height / rendered_tile_height)) + 1
	for row in range(rows):
		for col in range(columns):
			var tile := Sprite2D.new()
			tile.texture = sand_tile_texture
			tile.centered = true
			tile.scale = Vector2.ONE * tile_scale
			tile.position = Vector2(
				-half_extents.x + (float(col) + 0.5) * rendered_tile_width,
				-half_extents.y + (float(row) + 0.5) * rendered_tile_height
			)
			tile.modulate = Color(1.0, 1.0, 1.0, 0.52)
			tile.z_index = 0
			texture_layer.add_child(tile)


func _render_opening_gameplay_tutorial_provinces(province_data: Array[Dictionary]) -> void:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return
	for province_entry in province_data:
		var poly: PackedVector2Array = province_entry.get("polygon", PackedVector2Array())
		var province_id: int = int(province_entry.get("id", -1))
		var ptype: String = String(province_entry.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		var troops: int = int(province_entry.get("troops", 0))
		var buildings: int = int(province_entry.get("buildings", 0))
		var invading_troops: int = int(province_entry.get("invading_troops", 0))
		var faction_id: int = int(province_entry.get("faction_id", 0))
		var province_name: String = String(province_entry.get("province_name", "Province %d" % province_id))
		var tint_idx: int = int(province_entry.get("tint_index", province_id))
		var province_node := Node2D.new()
		province_node.name = "Province_%d" % province_id
		province_node.z_index = LevelConfig.VISUAL_LAYER_PROVINCE_FILL
		province_node.set_meta("province_data", {
			"id": province_id,
			"province_name": province_name,
			"type": ptype,
			"tint_index": tint_idx,
			"troops": troops,
			"buildings": buildings,
			"invading_troops": invading_troops,
			"neighbors": Array(province_entry.get("neighbors", [])).duplicate(),
			"faction_id": faction_id,
			"is_target": false,
			"is_boss_home": false,
			"gold_production": 0,
			"free_buildings": 0,
			"building_capacity": LevelConfig.PROVINCE_BUILDING_CAP_MIN,
			"engagement_map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		})
		province_node.set_meta("province_polygon", poly)
		province_node.set_meta("province_logical_polygon", poly)
		province_node.set_meta("province_display_polygon", poly)
		_main.provinces_root.add_child(province_node)

		var fill := Polygon2D.new()
		fill.name = "ProvinceFill"
		fill.polygon = poly
		fill.z_index = 0
		if ptype == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			fill.color = LevelConfig.get_friendly_province_fill_color()
		else:
			fill.color = LevelConfig.PROVINCE_FILL_COLORS[tint_idx % LevelConfig.PROVINCE_FILL_COLORS.size()]
		province_node.add_child(fill)

		var border := Line2D.new()
		border.name = "ProvinceBorder"
		border.width = LevelConfig.PROVINCE_BORDER_WIDTH
		border.default_color = LevelConfig.PROVINCE_BORDER_COLOR
		border.antialiased = true
		border.closed = true
		border.points = poly
		border.z_index = LevelConfig.VISUAL_LAYER_BORDERS - LevelConfig.VISUAL_LAYER_PROVINCE_FILL
		province_node.set_meta("province_display_border_points", poly)
		province_node.add_child(border)

		var inner := Line2D.new()
		inner.name = "ProvinceInnerGlow"
		inner.width = 2.8
		inner.default_color = Color(1.0, 0.96, 0.72, 0.22)
		inner.antialiased = true
		inner.closed = true
		inner.points = poly
		inner.z_index = LevelConfig.VISUAL_LAYER_BORDER_OVERLAYS - LevelConfig.VISUAL_LAYER_PROVINCE_FILL
		province_node.set_meta("province_display_inner_points", poly)
		province_node.add_child(inner)

		if _main.generator != null and _main.generator.has_method("_add_province_counts_display"):
			_main.generator.call("_add_province_counts_display", province_node, poly, province_id, troops, buildings, invading_troops, ptype, faction_id, false, 0, 0, LevelConfig.PROVINCE_BUILDING_CAP_MIN, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL, false, province_name)

	if _main.generator != null and _main.generator.has_method("_spawn_grand_map_outer_barrier"):
		_main.generator.call("_spawn_grand_map_outer_barrier", _main.obstacles_root, province_data)


func _generate_opening_gameplay_tutorial_grand_map() -> void:
	if _main == null:
		return
	_invalidate_grand_map_snapshot()
	var runtime_entries: Array[Dictionary] = _get_or_build_opening_gameplay_tutorial_entries()
	_main._province_persistence = runtime_entries
	_render_opening_gameplay_tutorial_sand_backdrop()
	var province_layout: Array[Dictionary] = _build_opening_gameplay_tutorial_province_layout(runtime_entries)
	_render_opening_gameplay_tutorial_provinces(province_layout)


func _is_opening_gameplay_tutorial_clear_condition_met() -> bool:
	if _main == null:
		return false
	var target_id: int = _get_opening_gameplay_tutorial_target_province_id()
	for entry_any in _main._province_persistence:
		if not (entry_any is Dictionary):
			continue
		var entry: Dictionary = entry_any
		if int(entry.get("id", -1)) != target_id:
			continue
		if int(entry.get("remaining_troops", 0)) <= 0:
			return true
		return String(entry.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_NEUTRAL
	return false


func _maybe_mark_opening_gameplay_tutorial_complete() -> bool:
	if not is_opening_gameplay_tutorial_active():
		return false
	if not _is_opening_gameplay_tutorial_clear_condition_met():
		return false
	mark_opening_gameplay_tutorial_complete()
	return true

func _unlock_tutorial_notes_for_event(event_key: String, show_toasts: bool = true) -> void:
	if _main == null:
		return
	if event_key.strip_edges() == "":
		return
	if not _main.has_method("_unlock_tutorial_notes_for_event"):
		return
	_main.call("_unlock_tutorial_notes_for_event", event_key, show_toasts)


func _maybe_unlock_boss_seen_note(show_toasts: bool = true) -> void:
	if _main == null or _main.boss_system == null:
		return
	if not bool(_main.boss_system.has_method("is_boss_active") and _main.boss_system.is_boss_active()):
		return
	_unlock_tutorial_notes_for_event("first_boss_seen", show_toasts)


func _restore_saved_grand_map_camera_if_available() -> void:
	if _main == null:
		return
	if _main._current_phase == LevelConfig.PHASE_GRAND_MAP or _main.state == _main.GameState.GRAND_MAP or _main.state == _main.GameState.BALL_IN_FLIGHT:
		if _main.has_method("_restore_saved_grand_map_camera_state"):
			_main._restore_saved_grand_map_camera_state()


func _make_level_config_instance() -> Object:
	if LevelConfig != null and LevelConfig is Script:
		return LevelConfig.new()
	return null


func _get_initial_boss_province_troops() -> int:
	var cfg := _make_level_config_instance()
	if cfg != null and cfg.has_method("get_initial_boss_province_troops"):
		return int(cfg.call("get_initial_boss_province_troops"))
	return int(LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY))


func _get_initial_boss_province_buildings() -> int:
	var cfg := _make_level_config_instance()
	if cfg != null and cfg.has_method("get_initial_boss_province_buildings"):
		return int(cfg.call("get_initial_boss_province_buildings"))
	return int(LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_ENEMY))


const BOSS_HOME_TROOPS_PER_HIT_POINT: int = 5


func _get_campaign_enemy_troop_level_bonus_total() -> int:
	if _main != null and _main.has_method("get_campaign_enemy_troop_level_bonus_total"):
		return maxi(0, int(_main.call("get_campaign_enemy_troop_level_bonus_total")))
	return 0


func _get_conquered_boss_province_troops() -> int:
	var base_value: int = int(LevelConfig.get_conquered_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY))
	var cfg := _make_level_config_instance()
	if cfg != null and cfg.has_method("get_conquered_boss_province_troops"):
		base_value = int(cfg.call("get_conquered_boss_province_troops"))
	return maxi(0, base_value + _get_campaign_enemy_troop_level_bonus_total())


func _get_conquered_boss_province_buildings() -> int:
	var cfg := _make_level_config_instance()
	if cfg != null and cfg.has_method("get_conquered_boss_province_buildings"):
		return int(cfg.call("get_conquered_boss_province_buildings"))
	return int(LevelConfig.get_conquered_province_buildings(LevelConfig.PROVINCE_TYPE_ENEMY))


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


func _format_province_label(province_id: int) -> String:
	if province_id < 0:
		return "Unknown Province"
	var province_state: Dictionary = _find_persistent_province_state(province_id)
	var province_name: String = String(province_state.get("province_name", "")).strip_edges()
	if not province_name.is_empty():
		return province_name
	if _main != null and _main.province_system != null and _main.province_system.has_method("get_province_display_name"):
		var resolved: String = String(_main.province_system.call("get_province_display_name", province_id, province_state)).strip_edges()
		if not resolved.is_empty() and not resolved.begins_with("Province "):
			return resolved
	var map_seed: int = 1
	if _main != null:
		map_seed = maxi(1, int(_main.get("map_seed")))
	var generated: String = String(LevelConfig.generate_province_name(map_seed, province_id)).strip_edges()
	if not generated.is_empty():
		return generated
	return "Province %d" % province_id



func _get_boss_home_assault_troops() -> int:
	if _main != null and _main.has_method("_get_boss_home_assault_troops"):
		return maxi(1, int(_main.call("_get_boss_home_assault_troops")))
	var cfg := _make_level_config_instance()
	if cfg != null and cfg.has_method("get_boss_home_assault_troops"):
		return maxi(1, int(cfg.call("get_boss_home_assault_troops")))
	return 100


func _get_active_boss_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	if _main == null or _main.boss_system == null:
		return states
	if _main.boss_system.has_method("get_active_boss_states"):
		var raw_states: Variant = _main.boss_system.get_active_boss_states()
		if raw_states is Array:
			for entry in raw_states:
				if entry is Dictionary:
					states.append((entry as Dictionary).duplicate(true))
		if not states.is_empty():
			return states
	if _main.boss_system.has_method("is_boss_active") and bool(_main.boss_system.is_boss_active()):
		if _main.boss_system.has_method("get_boss_state"):
			var fallback_state: Dictionary = _main.boss_system.get_boss_state()
			if not fallback_state.is_empty():
				states.append(fallback_state.duplicate(true))
	return states


func _get_primary_boss_id() -> int:
	if _main == null or _main.boss_system == null:
		return -1
	if _main.boss_system.has_method("get_primary_boss_id"):
		return int(_main.boss_system.get_primary_boss_id())
	if _main.boss_system.has_method("get_boss_state"):
		return int(_main.boss_system.get_boss_state().get("boss_id", -1))
	return -1


func _get_active_boss_home_province_ids() -> Array[int]:
	var home_ids: Array[int] = []
	for boss_state in _get_active_boss_states():
		var home_id: int = int(boss_state.get("home_province_id", -1))
		if home_id >= 0 and not home_ids.has(home_id):
			home_ids.append(home_id)
	return home_ids


func _is_any_active_boss_home_province_id(province_id: int) -> bool:
	if province_id < 0 or _main == null or _main.boss_system == null:
		return false
	if _main.boss_system.has_method("is_any_boss_home_province_id"):
		return bool(_main.boss_system.is_any_boss_home_province_id(province_id))
	if _main.boss_system.has_method("is_boss_home_province_id"):
		return bool(_main.boss_system.is_boss_home_province_id(province_id))
	return false


func _make_pending_boss_part_hit_token(boss_id: int, part_name: String) -> String:
	var clean_part_name: String = String(part_name).strip_edges()
	if clean_part_name == "":
		return ""
	if boss_id < 0:
		return clean_part_name
	return "%d%s%s" % [boss_id, BOSS_PART_HIT_SEPARATOR, clean_part_name]


func _parse_pending_boss_part_hit_token(token: String) -> Dictionary:
	var clean_token: String = String(token).strip_edges()
	var result: Dictionary = {"boss_id": -1, "part_name": ""}
	if clean_token == "":
		return result
	var split_index: int = clean_token.find(BOSS_PART_HIT_SEPARATOR)
	if split_index == -1:
		result["part_name"] = clean_token
		return result
	result["boss_id"] = int(clean_token.substr(0, split_index))
	result["part_name"] = clean_token.substr(split_index + BOSS_PART_HIT_SEPARATOR.length())
	return result


func _parse_pending_boss_part_hit_tokens(raw_tokens: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var clean_tokens: String = String(raw_tokens).strip_edges()
	if clean_tokens == "":
		return entries
	for token in clean_tokens.split(",", false):
		var parsed: Dictionary = _parse_pending_boss_part_hit_token(String(token).strip_edges())
		var parsed_part_name: String = String(parsed.get("part_name", "")).strip_edges()
		if parsed_part_name == "":
			continue
		entries.append(parsed)
	return entries

func free_children_immediately(node: Node) -> void:
	if node == null:
		return
	var children: Array = node.get_children().duplicate()
	for child in children:
		if child and is_instance_valid(child):
			node.remove_child(child)
			if child is GPUParticles2D:
				(child as GPUParticles2D).emitting = false
			child.queue_free()


func ensure_spawn_roots() -> void:
	if _main == null:
		return

	var world_node: Node = _main.get_node_or_null("World")
	if not is_instance_valid(_main.ball_holder):
		if is_instance_valid(world_node):
			_main.ball_holder = world_node.get_node_or_null("BallHolder")
		if not is_instance_valid(_main.ball_holder):
			_main.ball_holder = Node2D.new()
			_main.ball_holder.name = "BallHolder"
			if is_instance_valid(world_node):
				world_node.add_child(_main.ball_holder)
			else:
				_main.add_child(_main.ball_holder)

	if not is_instance_valid(_main.provinces_root):
		if is_instance_valid(world_node):
			_main.provinces_root = world_node.get_node_or_null("Provinces")


func _free_cached_snapshot_nodes(nodes: Array) -> void:
	for node_any in nodes:
		if node_any is Node:
			var cached_node: Node = node_any
			if is_instance_valid(cached_node):
				cached_node.free()
	nodes.clear()


func _invalidate_grand_map_snapshot() -> void:
	_free_cached_snapshot_nodes(_cached_grand_map_zone_children)
	_free_cached_snapshot_nodes(_cached_grand_map_obstacle_children)
	_free_cached_snapshot_nodes(_cached_grand_map_province_children)
	_cached_grand_map_seed = 0
	_cached_grand_map_generation_level = 0


func _is_grand_map_snapshot_valid_for_current_run() -> bool:
	if _main == null:
		return false
	if _cached_grand_map_province_children.is_empty():
		return false
	if _cached_grand_map_seed != int(_main.map_seed):
		return false
	if _cached_grand_map_generation_level != int(_main._grand_map_generation_level):
		return false
	return true


func _snapshot_root_children(root: Node, exclude_names: Array = []) -> Array:
	var snapshots: Array = []
	if root == null or not is_instance_valid(root):
		return snapshots
	for child_any in root.get_children():
		var child: Node = child_any
		if not is_instance_valid(child):
			continue
		if exclude_names.has(String(child.name)):
			continue
		var duplicate_child: Node = child.duplicate()
		if duplicate_child != null:
			snapshots.append(duplicate_child)
	return snapshots


func _cache_current_grand_map_snapshot() -> void:
	if _main == null:
		return
	ensure_spawn_roots()
	if not is_instance_valid(_main.zones_root) or not is_instance_valid(_main.obstacles_root) or not is_instance_valid(_main.provinces_root):
		return
	_invalidate_grand_map_snapshot()
	_cached_grand_map_seed = int(_main.map_seed)
	_cached_grand_map_generation_level = int(_main._grand_map_generation_level)
	_cached_grand_map_zone_children = _snapshot_root_children(_main.zones_root)
	_cached_grand_map_obstacle_children = _snapshot_root_children(_main.obstacles_root)
	_cached_grand_map_province_children = _snapshot_root_children(_main.provinces_root, [BOSS_VISUAL_ROOT_NAME])


func _restore_children_from_snapshot(root: Node, snapshots: Array) -> void:
	if root == null or not is_instance_valid(root):
		return
	for snapshot_any in snapshots:
		if not (snapshot_any is Node):
			continue
		var snapshot_node: Node = snapshot_any
		if not is_instance_valid(snapshot_node):
			continue
		var restored_node: Node = snapshot_node.duplicate()
		if restored_node != null:
			root.add_child(restored_node)


func _on_restored_zone_body_entered(body_node: Node, area: Area2D) -> void:
	if body_node != null and is_instance_valid(body_node) and body_node.has_method("register_zone"):
		body_node.register_zone(area)


func _on_restored_zone_body_exited(body_node: Node, area: Area2D) -> void:
	if body_node != null and is_instance_valid(body_node) and body_node.has_method("unregister_zone"):
		body_node.unregister_zone(area)


func _rebind_restored_zone_callbacks_recursive(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is Area2D:
		var area: Area2D = node as Area2D
		if area.has_meta("zone_type"):
			area.monitoring = true
			area.monitorable = true
			var entered_cb := Callable(self, "_on_restored_zone_body_entered").bind(area)
			if not area.body_entered.is_connected(entered_cb):
				area.body_entered.connect(entered_cb)
			var exited_cb := Callable(self, "_on_restored_zone_body_exited").bind(area)
			if not area.body_exited.is_connected(exited_cb):
				area.body_exited.connect(exited_cb)
	for child_any in node.get_children():
		if child_any is Node:
			_rebind_restored_zone_callbacks_recursive(child_any)


func _restore_cached_grand_map_snapshot() -> bool:
	if not _is_grand_map_snapshot_valid_for_current_run():
		return false
	ensure_spawn_roots()
	if not is_instance_valid(_main.zones_root) or not is_instance_valid(_main.obstacles_root) or not is_instance_valid(_main.provinces_root):
		return false
	_restore_children_from_snapshot(_main.zones_root, _cached_grand_map_zone_children)
	_restore_children_from_snapshot(_main.obstacles_root, _cached_grand_map_obstacle_children)
	_restore_children_from_snapshot(_main.provinces_root, _cached_grand_map_province_children)
	_rebind_restored_zone_callbacks_recursive(_main.zones_root)
	return true


func _refresh_turn_economy_if_needed(force: bool = false) -> void:
	if _main == null:
		return
	if _main.has_method("_reset_turn_gold_and_upgrades_for_current_turn"):
		_main.call("_reset_turn_gold_and_upgrades_for_current_turn", force)


func clear_level() -> void:
	if _main == null:
		return

	_main.preview_ball = null
	_main.ball = null
	_main._wall_grace_end_time = 0.0
	_main._is_auto_charging = false
	_main._final_launch_radius = 0.0
	_main._final_launch_velocity = Vector2.ZERO
	_main._preview_radius = 0.0
	_main._preview_velocity = Vector2.ZERO
	_main._initial_pin_count = 0
	_main._destroyed_buildings_this_level = 0
	_main._grand_map_fit_zoom = 0.0
	_main._camera_follow_active = false
	_main._total_active_touches = 0
	_main._right_mouse_pan_active = false
	_main._pending_boss_part_hit = ""
	_live_caltrop_nodes_by_key.clear()
	_active_caltrop_button_areas.clear()
	if _main.has_method("_set_magnet_placement_armed"):
		_main.call("_set_magnet_placement_armed", false)

	free_children_immediately(_main.zones_root)
	free_children_immediately(_main.obstacles_root)
	free_children_immediately(_main.pins_root)
	free_children_immediately(_main.provinces_root)
	free_children_immediately(_main.ball_holder)
	if _main.has_method("_ensure_global_sand_tile_backdrop"):
		_main.call("_ensure_global_sand_tile_backdrop")

	for node in _main.get_tree().get_nodes_in_group("particles"):
		if node is GPUParticles2D and is_instance_valid(node):
			(node as GPUParticles2D).emitting = false
			node.queue_free()

	if _main.projection_line:
		_main.projection_line.visible = false
	if _main.aim_line:
		_main.aim_line.visible = false

	_main.rest_timer = 0.0
	_main.settle_timer = 0.0
	_main.flight_timer = 0.0
	_main._pins_ui_accum = 0.0

	_main.dragging = false
	_main._drag_pending = false
	_main.drag_pointer_id = -1
	_main.drag_source = _main.DragSource.NONE

	_main.pan_dragging = false
	_main.pan_drag_pointer_ids.clear()
	_main.pan_drag_pointer_positions.clear()

	if _main.ui and _main.ui.has_method("show_extra_ball_button"):
		_main.ui.call("show_extra_ball_button", false)

	ensure_spawn_roots()


func generate_grand_map() -> void:
	if _main == null:
		return

	clear_level()
	_main._current_phase = LevelConfig.PHASE_GRAND_MAP

	var completion_status_pending: bool = String(_main._pending_campaign_completion_status_text).strip_edges() != ""

	if _main.ui_bridge != null:
		_main.ui_bridge.ui_refresh_header()
		if not completion_status_pending:
			_main.ui_bridge.ui_clear_state_message()

	if _main.ui != null and _main.ui.has_method("set_seed_display"):
		_main.ui.call("set_seed_display", _main.map_seed)

	if _main.generator == null:
		_main.generator = LevelGenerator.new()

	var restored_from_snapshot: bool = false
	if not _is_grand_map_snapshot_valid_for_current_run() and (_cached_grand_map_seed != 0 or _cached_grand_map_generation_level != 0):
		_invalidate_grand_map_snapshot()

	var opening_tutorial_active: bool = is_opening_gameplay_tutorial_active()
	if opening_tutorial_active:
		_invalidate_grand_map_snapshot()
		restored_from_snapshot = false
	else:
		restored_from_snapshot = _restore_cached_grand_map_snapshot()
	if not restored_from_snapshot:
		if opening_tutorial_active:
			_generate_opening_gameplay_tutorial_grand_map()
		else:
			_main.generator.generate_into(
				_main.map_seed,
				_main._grand_map_generation_level,
				_main.zones_root,
				_main.obstacles_root,
				_main.pins_root,
				_main.provinces_root,
				LevelConfig.PHASE_GRAND_MAP
			)

	ensure_spawn_roots()
	if _main.province_system != null:
		if restored_from_snapshot:
			_main.province_system.apply_persistence_to_province_visuals()
		else:
			_main.province_system.sync_province_persistence()
	if not restored_from_snapshot:
		_cache_current_grand_map_snapshot()

	if not opening_tutorial_active:
		if _main.has_method("_handle_campaign_map_completion") and bool(_main.call("_handle_campaign_map_completion")):
			return

	var turn_start_boss_status_text: String = ""
	if not opening_tutorial_active:
		turn_start_boss_status_text = _maybe_spawn_boss_for_current_turn()
		_refresh_turn_economy_if_needed(completion_status_pending)
		refresh_live_boss_map_presentation()
		_maybe_unlock_boss_seen_note(true)

	var lock_visuals_need_refresh: bool = false
	var previous_locked_province_id: int = _main._locked_province_id_after_win
	if opening_tutorial_active:
		_main._locked_province_id_after_win = _get_opening_gameplay_tutorial_origin_province_id()
	elif _main.turn_number == 1 and _main._locked_province_id_after_win == -1:
		for province_state in _main._province_persistence:
			if province_state.type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
				_main._locked_province_id_after_win = province_state.id
				break

	if not opening_tutorial_active:
		_sanitize_locked_launch_province_for_active_boss()
	lock_visuals_need_refresh = _main._locked_province_id_after_win != previous_locked_province_id
	if lock_visuals_need_refresh and _main.province_system != null:
		_main.province_system.apply_persistence_to_province_visuals()

	force_grand_map_wall_reset()
	if _main.camera_controller != null:
		_main.camera_controller.sync_runtime_bounds_to_camera()
	call_deferred("force_grand_map_wall_reset")
	_main.get_tree().create_timer(0.05).timeout.connect(Callable(self, "force_grand_map_wall_reset"))

	_main.state = _main.GameState.GRAND_MAP
	var opening_tutorial_cleared_now: bool = false
	if opening_tutorial_active:
		opening_tutorial_cleared_now = _maybe_mark_opening_gameplay_tutorial_complete()
	if _main.ui_bridge != null and not completion_status_pending:
		var grand_map_status_text: String = ""
		if opening_tutorial_active or opening_tutorial_cleared_now or has_opening_gameplay_tutorial_completed():
			grand_map_status_text = _build_opening_gameplay_tutorial_status_text()
		elif _main._locked_province_id_after_win != -1:
			if _main.turn_number == 1:
				grand_map_status_text = "Turn 1 — start from the highlighted friendly province."
			else:
				grand_map_status_text = "Turn %d — your next shot starts in the highlighted province." % _main.turn_number
		if turn_start_boss_status_text.strip_edges() != "":
			if grand_map_status_text != "":
				grand_map_status_text = "%s\n%s" % [turn_start_boss_status_text.strip_edges(), grand_map_status_text]
			else:
				grand_map_status_text = turn_start_boss_status_text.strip_edges()
		if grand_map_status_text != "":
			_main.ui_bridge.ui_set_status(grand_map_status_text)

	if _main.ui_bridge != null:
		_main.ui_bridge.sync_ui_button_states()

	if _main.camera_controller != null:
		_main.camera_controller.call_deferred("apply_camera_fit")

	if _should_apply_new_grand_map_opening_camera_view():
		call_deferred("_apply_new_grand_map_opening_camera_view")
		_main.get_tree().create_timer(0.12).timeout.connect(Callable(self, "_apply_new_grand_map_opening_camera_view"))
	elif _main._current_phase == LevelConfig.PHASE_GRAND_MAP and _main._locked_province_id_after_win >= 0:
		call_deferred("center_camera_on_turn_origin_province")
		_main.get_tree().create_timer(0.12).timeout.connect(Callable(self, "center_camera_on_turn_origin_province"))


func _should_apply_new_grand_map_opening_camera_view() -> bool:
	if _main == null:
		return false
	if _main._current_phase != LevelConfig.PHASE_GRAND_MAP:
		return false
	if is_opening_gameplay_tutorial_active():
		return _main._locked_province_id_after_win != -1
	if _main.turn_number != 1:
		return false
	return _main._locked_province_id_after_win != -1


func _apply_new_grand_map_opening_camera_view() -> void:
	if not _should_apply_new_grand_map_opening_camera_view():
		return
	if _main.camera_controller == null:
		return

	var origin_province_id: int = _main._locked_province_id_after_win
	var origin_center: Vector2 = _get_live_province_center_by_id(origin_province_id)

	if _main.has_method("_clear_saved_grand_map_camera_state"):
		_main._clear_saved_grand_map_camera_state()

	_main._camera_follow_active = false
	_main.camera_pan_offset = Vector2.ZERO
	_main.current_camera_zoom = 1.0
	_main.camera_controller.apply_camera_fit()

	var fit_zoom: float = maxf(0.0001, float(_main._grand_map_fit_zoom))
	var desired_zoom: float = lerpf(fit_zoom, float(LevelConfig.GRAND_MAP_CAMERA_MAX_ZOOM), 0.5)
	_main.current_camera_zoom = clampf(desired_zoom, fit_zoom, float(LevelConfig.GRAND_MAP_CAMERA_MAX_ZOOM))
	_main.camera_pan_offset = origin_center
	_main.camera_controller.apply_camera_fit()

	if _main.has_method("_store_current_grand_map_camera_state"):
		_main._store_current_grand_map_camera_state()


func center_camera_on_turn_origin_province() -> void:
	if _main == null:
		return
	if _main._current_phase != LevelConfig.PHASE_GRAND_MAP:
		return
	if _main.camera_controller == null:
		return

	var origin_province_id: int = int(_main._locked_province_id_after_win)
	if origin_province_id < 0:
		return
	var origin_center: Vector2 = _get_live_province_center_by_id(origin_province_id)

	if _main.has_method("_clear_saved_grand_map_camera_state"):
		_main._clear_saved_grand_map_camera_state()

	_main._camera_follow_active = false
	var fit_zoom: float = maxf(0.0001, float(_main._grand_map_fit_zoom))
	_main.current_camera_zoom = clampf(float(_main.current_camera_zoom), fit_zoom, float(LevelConfig.GRAND_MAP_CAMERA_MAX_ZOOM))
	_main.camera_pan_offset = origin_center
	_main.camera_controller.apply_camera_fit()

	if _main.has_method("_store_current_grand_map_camera_state"):
		_main._store_current_grand_map_camera_state()


func force_grand_map_wall_reset() -> void:
	if _main == null:
		return
	if _main._camera_follow_active:
		return

	var thick: float = LevelConfig.GRAND_MAP_WALL_THICKNESS
	var safety: float = 80.0
	var horiz: float = LevelConfig.GRAND_MAP_WORLD_SIZE.x + thick * 2.0 + safety * 2.0
	var vert: float = LevelConfig.GRAND_MAP_WORLD_SIZE.y + thick * 2.0 + safety * 2.0
	var half_x: float = LevelConfig.GRAND_MAP_HALF_EXTENTS.x
	var half_y: float = LevelConfig.GRAND_MAP_HALF_EXTENTS.y

	if _main.wall_top_shape and _main.wall_top_shape.shape is RectangleShape2D:
		(_main.wall_top_shape.shape as RectangleShape2D).size = Vector2(horiz, thick)
		_main.wall_top.position.y = -half_y - (thick * 0.5)
	if _main.wall_top:
		_main.wall_top.collision_layer = 4
		_main.wall_top.collision_mask = 3

	if _main.wall_bottom_shape and _main.wall_bottom_shape.shape is RectangleShape2D:
		(_main.wall_bottom_shape.shape as RectangleShape2D).size = Vector2(horiz, thick)
		_main.wall_bottom.position.y = half_y + (thick * 0.5)
	if _main.wall_bottom:
		_main.wall_bottom.collision_layer = 4
		_main.wall_bottom.collision_mask = 3

	if _main.wall_left_shape and _main.wall_left_shape.shape is RectangleShape2D:
		(_main.wall_left_shape.shape as RectangleShape2D).size = Vector2(thick, vert)
		_main.wall_left.position.x = -half_x - (thick * 0.5)
	if _main.wall_left:
		_main.wall_left.collision_layer = 4
		_main.wall_left.collision_mask = 3

	if _main.wall_right_shape and _main.wall_right_shape.shape is RectangleShape2D:
		(_main.wall_right_shape.shape as RectangleShape2D).size = Vector2(thick, vert)
		_main.wall_right.position.x = half_x + (thick * 0.5)
	if _main.wall_right:
		_main.wall_right.collision_layer = 4
		_main.wall_right.collision_mask = 3


func generate_level_from_seed(seed_value: int) -> void:
	if _main == null:
		return

	clear_level()

	if seed_value == 0:
		_main._new_run_seed()
		seed_value = _main.map_seed

	_main.map_seed = seed_value
	if _main.ui_bridge != null:
		_main.ui_bridge.ui_refresh_header()
		_main.ui_bridge.ui_clear_state_message()

	if _main.generator == null:
		_main.generator = LevelGenerator.new()

	if _main.camera_controller != null:
		_main.camera_controller.apply_camera_fit()

	spawn_engagement(_main._active_engagement_province_id, false)

	if _main.ui and _main.ui.has_method("set_seed_display"):
		_main.ui.call("set_seed_display", _main.map_seed)

	_reset_engagement_camera_to_standard_zoomed_out_view()


func retry_current_engagement(province_id: int) -> void:
	if _main == null:
		return

	if province_id == -1:
		province_id = _main._active_engagement_province_id
	if province_id == -1 and _main.province_system != null:
		province_id = int(_main.province_system.find_first_province_id_for_phase(_main._current_phase))
	if province_id == -1:
		generate_grand_map()
		return

	_main._active_engagement_province_id = province_id
	spawn_engagement(province_id, true)


func _uses_logical_offensive_buildings() -> bool:
	return _main != null and _main._current_phase == LevelConfig.PHASE_OFFENSIVE


func _get_live_downed_pin_count() -> int:
	var live_standing_pins: int = count_standing_pins()
	return maxi(0, _main._initial_pin_count - live_standing_pins)


func _get_offensive_logical_destroyed_buildings() -> int:
	if not _uses_logical_offensive_buildings():
		return 0
	return LevelConfig.get_offensive_logical_destroyed_buildings(
		_main._initial_pin_count,
		_get_live_downed_pin_count(),
		_main._engagement_initial_buildings
	)



func _reset_engagement_camera_to_standard_zoomed_out_view() -> void:
	if _main == null:
		return
	_main._camera_follow_active = false
	_main.camera_pan_offset = Vector2.ZERO
	_main.current_camera_zoom = 1.0
	if _main.camera_controller != null:
		if _main.camera_controller.has_method("apply_camera_fit"):
			_main.camera_controller.apply_camera_fit()
			_main.camera_controller.call_deferred("apply_camera_fit")
			_main.get_tree().create_timer(0.12).timeout.connect(Callable(_main.camera_controller, "apply_camera_fit"))
	elif _main.camera_2d != null:
		_main.camera_2d.position = Vector2.ZERO
		_main.camera_2d.zoom = Vector2.ONE


func spawn_engagement(province_id: int = -1, clear_existing: bool = true) -> void:
	if _main == null:
		return

	if clear_existing:
		clear_level()

	if province_id == -1:
		province_id = _main._active_engagement_province_id
	if province_id == -1 and _main.province_system != null:
		province_id = int(_main.province_system.find_first_province_id_for_phase(_main._current_phase))
	if province_id == -1:
		return

	_main._active_engagement_province_id = province_id

	var boss_home_assault_active: bool = bool(_main.get("_boss_home_assault_active"))
	var boss_home_assault_province_id: int = int(_main.get("_boss_home_assault_province_id"))
	var is_boss_home_assault: bool = boss_home_assault_active and province_id == boss_home_assault_province_id

	var troops: int = LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_NEUTRAL)
	var buildings: int = LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_NEUTRAL)
	var province_type: String = LevelConfig.PROVINCE_TYPE_NEUTRAL
	var invading_troops: int = 0
	var engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL

	if _main.province_system != null:
		var province_context: Dictionary = _main.province_system.get_province_context(province_id)
		province_type = String(province_context.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		invading_troops = int(province_context.get("invading_troops", 0))
		buildings = int(province_context.get("remaining_buildings", buildings))
		engagement_map_type = LevelConfig.normalize_engagement_map_type(String(province_context.get("engagement_map_type", LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)))

		if is_boss_home_assault:
			var assault_troops: int = int(province_context.get("remaining_troops", int(_main.get("_boss_home_assault_troop_count"))))
			troops = maxi(1, assault_troops if assault_troops > 0 else _get_boss_home_assault_troops())
			province_type = LevelConfig.PROVINCE_TYPE_ENEMY
			buildings = 0
			_main._current_phase = LevelConfig.PHASE_OFFENSIVE
		elif province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
			troops = int(province_context.get("remaining_troops", LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY)))
			_main._current_phase = LevelConfig.PHASE_OFFENSIVE
		elif province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
			troops = invading_troops
			_main._current_phase = LevelConfig.PHASE_DEFENSIVE
		else:
			troops = int(province_context.get("remaining_troops", LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_NEUTRAL)))
			_main._current_phase = LevelConfig.PHASE_NEUTRAL
	else:
		if is_boss_home_assault:
			var assault_troops_no_context: int = int(_main.get("_boss_home_assault_troop_count"))
			troops = maxi(1, assault_troops_no_context if assault_troops_no_context > 0 else _get_boss_home_assault_troops())
			buildings = 0
			_main._current_phase = LevelConfig.PHASE_OFFENSIVE
		elif _main._current_phase == LevelConfig.PHASE_OFFENSIVE:
			troops = LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY)
			buildings = LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_ENEMY)
		elif _main._current_phase == LevelConfig.PHASE_DEFENSIVE:
			troops = LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY)
			buildings = LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_FRIENDLY)
		else:
			troops = LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_NEUTRAL)
			buildings = LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_NEUTRAL)

	if _main.ui_bridge != null:
		_main.ui_bridge.ui_refresh_header()
		_main.ui_bridge.ui_clear_state_message()

	_unlock_tutorial_notes_for_event("first_engagement_started", true)
	if _main._current_phase == LevelConfig.PHASE_DEFENSIVE:
		_unlock_tutorial_notes_for_event("first_defensive_engagement_started", true)

	if _main.generator == null:
		_main.generator = LevelGenerator.new()

	var encounter_layout: Dictionary = {}
	if _main.province_system != null:
		encounter_layout = _main.province_system.ensure_province_encounter_layout(province_id)
		engagement_map_type = LevelConfig.normalize_engagement_map_type(String(encounter_layout.get("map_type", engagement_map_type)))

	_main.generator.generate_into(
		int(encounter_layout.get("seed", _main.map_seed)),
		int(encounter_layout.get("level", _main.level_index)),
		_main.zones_root,
		_main.obstacles_root,
		_main.pins_root,
		null,
		_main._current_phase,
		buildings,
		troops,
		engagement_map_type
	)

	if is_boss_home_assault:
		_spawn_boss_home_assault_focus_visual(province_id)

	_spawn_persistent_engagement_caltrops(province_id)

	_main._initial_pin_count = _main.pins_root.get_child_count()
	_main._engagement_initial_buildings = 0
	if _uses_logical_offensive_buildings():
		_main._engagement_initial_buildings = maxi(0, buildings)
	else:
		for child in _main.obstacles_root.get_children():
			if child.has_meta("is_building"):
				_main._engagement_initial_buildings += 1

	if _main.ui_bridge != null:
		_main.ui_bridge.ui_set_pins_counts(_main._initial_pin_count, 0)
		_main.ui_bridge.ui_refresh_upgrades()

	connect_buildings()
	refresh_engagement_live_counter()

	_main.state = _main.GameState.ENGAGEMENT
	if _main.ui_bridge != null:
		_main.ui_bridge.sync_ui_button_states()

	_reset_engagement_camera_to_standard_zoomed_out_view()
func _make_caltrop_runtime_key(province_id: int, caltrop_id: int) -> String:
	return "%d:%d" % [province_id, caltrop_id]


func _spawn_persistent_engagement_caltrops(province_id: int) -> void:
	_live_caltrop_nodes_by_key.clear()
	_active_caltrop_button_areas.clear()

	if _main == null or province_id < 0:
		return
	if _main.province_system == null or _main.generator == null:
		return
	if not _main.province_system.has_method("get_province_caltrops"):
		return
	if not _main.generator.has_method("spawn_persistent_caltrops_for_engagement"):
		return

	var caltrops: Array = _main.province_system.call("get_province_caltrops", province_id)
	if caltrops.is_empty():
		return

	var placed_results_any: Variant = _main.generator.call(
		"spawn_persistent_caltrops_for_engagement",
		province_id,
		caltrops,
		_main.zones_root,
		_main.obstacles_root,
		_main.pins_root
	)
	if not (placed_results_any is Array):
		return

	for entry_any in placed_results_any:
		if not (entry_any is Dictionary):
			continue
		var entry: Dictionary = entry_any
		var entry_province_id: int = int(entry.get("province_id", province_id))
		var caltrop_id: int = int(entry.get("caltrop_id", -1))
		if caltrop_id < 0:
			continue

		var node: Node = entry.get("node", null)
		if not is_instance_valid(node):
			continue

		var key: String = _make_caltrop_runtime_key(entry_province_id, caltrop_id)
		_live_caltrop_nodes_by_key[key] = node

		var button_area: Area2D = entry.get("button_area", null) as Area2D
		if button_area == null or not is_instance_valid(button_area):
			button_area = node.get_node_or_null("ButtonArea") as Area2D
		if button_area == null or not is_instance_valid(button_area):
			continue

		_active_caltrop_button_areas.append(button_area)
		button_area.body_entered.connect(Callable(self, "_on_caltrop_button_body_entered").bind(entry_province_id, caltrop_id))


func _on_caltrop_button_body_entered(body: Node, province_id: int, caltrop_id: int) -> void:
	if _main == null or province_id < 0 or caltrop_id < 0:
		return
	if body == null or not is_instance_valid(body):
		return
	if _main.ball == null or not is_instance_valid(_main.ball):
		return
	if body != _main.ball:
		return

	_destroy_live_caltrop(province_id, caltrop_id, true)


func _destroy_live_caltrop(province_id: int, caltrop_id: int, persist_destroyed: bool) -> void:
	var key: String = _make_caltrop_runtime_key(province_id, caltrop_id)
	if not _live_caltrop_nodes_by_key.has(key):
		if persist_destroyed and _main != null and _main.province_system != null and _main.province_system.has_method("mark_caltrop_destroyed"):
			_main.province_system.call("mark_caltrop_destroyed", province_id, caltrop_id)
		return

	var node: Node = _live_caltrop_nodes_by_key.get(key, null)
	_live_caltrop_nodes_by_key.erase(key)

	if persist_destroyed and _main != null and _main.province_system != null and _main.province_system.has_method("mark_caltrop_destroyed"):
		_main.province_system.call("mark_caltrop_destroyed", province_id, caltrop_id)

	if node == null or not is_instance_valid(node):
		return

	var button_area: Area2D = node.get_node_or_null("ButtonArea") as Area2D
	if button_area != null and is_instance_valid(button_area):
		_active_caltrop_button_areas.erase(button_area)
		button_area.monitoring = false
		button_area.monitorable = false

	node.set_meta("destroyed", true)
	node.collision_layer = 0
	node.collision_mask = 0
	node.queue_free()

	if _main != null and _main.has_method("_apply_screen_shake"):
		_main.call("_apply_screen_shake", 2.0, 0.12)


func count_standing_pins() -> int:
	if _main == null or not is_instance_valid(_main.pins_root):
		return 0

	var count: int = 0
	for pin_node in _main.pins_root.get_children():
		if pin_node is Pin and not pin_node.knocked_over and not pin_node.is_sunk_in_water():
			count += 1
	return count


func count_standing_buildings() -> int:
	if _main == null:
		return 0
	if _uses_logical_offensive_buildings():
		return maxi(0, _main._engagement_initial_buildings - _get_offensive_logical_destroyed_buildings())
	if not is_instance_valid(_main.obstacles_root):
		return 0

	var count: int = 0
	for child in _main.obstacles_root.get_children():
		if not is_instance_valid(child):
			continue
		if not child.has_meta("is_building"):
			continue
		if child.is_queued_for_deletion():
			continue
		if bool(child.get_meta("destroyed", false)):
			continue
		count += 1
	return count


func refresh_engagement_live_counter() -> void:
	if _main == null:
		return
	if _main.state == _main.GameState.LEVEL_END or _main.state == _main.GameState.GAME_OVER:
		return

	var live_standing_pins: int = count_standing_pins()
	var live_downed_pins: int = maxi(0, _main._initial_pin_count - live_standing_pins)
	var live_destroyed_buildings: int = _get_offensive_logical_destroyed_buildings() if _uses_logical_offensive_buildings() else _main._destroyed_buildings_this_level
	var live_standing_buildings: int = maxi(0, _main._engagement_initial_buildings - live_destroyed_buildings)
	if _uses_logical_offensive_buildings():
		_main._destroyed_buildings_this_level = live_destroyed_buildings

	if _main.ui_bridge != null:
		_main.ui_bridge.ui_set_pins_counts(_main._initial_pin_count, live_downed_pins)
		_main.ui_bridge.ui_show_engagement_live_counter(
			_main._initial_pin_count,
			live_downed_pins,
			_main._engagement_initial_buildings,
			live_destroyed_buildings
		)


func connect_buildings() -> void:
	if _main == null:
		return

	_main._destroyed_buildings_this_level = 0
	if _uses_logical_offensive_buildings():
		refresh_engagement_live_counter()
		return
	if not is_instance_valid(_main.obstacles_root):
		return

	_main._engagement_initial_buildings = 0
	for child in _main.obstacles_root.get_children():
		if child.has_meta("is_building") and not child.is_queued_for_deletion():
			_main._engagement_initial_buildings += 1

	refresh_engagement_live_counter()


func on_ball_body_entered(body: Node) -> void:
	if _main == null or not is_instance_valid(body):
		return

	var boss_part_name: String = _extract_boss_part_name_from_body(body)
	if boss_part_name != "":
		var boss_id: int = int(body.get_meta("boss_id", -1))
		_queue_boss_part_hit_from_contact(boss_part_name, boss_id, body)
		return

	if bool(body.get_meta("is_caltrop", false)):
		var province_id: int = int(body.get_meta("caltrop_province_id", -1))
		var caltrop_id: int = int(body.get_meta("caltrop_id", -1))
		if province_id >= 0 and caltrop_id >= 0:
			_destroy_live_caltrop(province_id, caltrop_id, true)
		return

	if _uses_logical_offensive_buildings():
		return
	if body.has_meta("is_building"):
		on_building_hit(body)


func _extract_boss_part_name_from_body(body: Node) -> String:
	if body == null or not is_instance_valid(body):
		return ""

	var part_name: String = String(body.get_meta("boss_part_name", "")).strip_edges()
	if part_name != "":
		return part_name

	if bool(body.get_meta("is_boss_part", false)):
		var name_from_node: String = String(body.name)
		if name_from_node.begins_with("BossPart_"):
			return name_from_node.trim_prefix("BossPart_")

	if body.is_in_group(BOSS_PART_GROUP):
		var grouped_name: String = String(body.name)
		if grouped_name.begins_with("BossPart_"):
			return grouped_name.trim_prefix("BossPart_")

	return ""


func _queue_boss_part_hit_from_contact(part_name: String, boss_id: int = -1, source_body: Node = null) -> void:
	if _main == null or _main.boss_system == null:
		return
	if _main.state != _main.GameState.BALL_IN_FLIGHT:
		return
	var allow_engagement_boss_hit: bool = bool(_main.get("_boss_home_assault_active")) and int(_main.get("_boss_home_assault_province_id")) == int(_main.get("_active_engagement_province_id"))
	if _main._current_phase != LevelConfig.PHASE_GRAND_MAP and not allow_engagement_boss_hit:
		return
	if not bool(_main.boss_system.is_boss_active(boss_id)):
		return

	var clean_part_name: String = String(part_name).strip_edges()
	if clean_part_name == "":
		return
	if _main.boss_system.has_method("is_friendly_boss") and bool(_main.boss_system.is_friendly_boss(boss_id)):
		clean_part_name = "head"
	if _main.boss_system.has_method("is_valid_boss_part_name") and not bool(_main.boss_system.is_valid_boss_part_name(clean_part_name)):
		return
	if bool(_main.boss_system.is_part_destroyed(clean_part_name, boss_id)):
		return

	var token: String = _make_pending_boss_part_hit_token(boss_id, clean_part_name)
	var current_frame: int = Engine.get_physics_frames()
	var duplicate_contact: bool = token == _last_queued_boss_hit_token and current_frame == _last_queued_boss_hit_frame
	if duplicate_contact:
		return

	_trigger_boss_part_hit_flash(clean_part_name, boss_id)
	var existing_tokens: String = String(_main._pending_boss_part_hit).strip_edges()
	if existing_tokens == "":
		_main._pending_boss_part_hit = token
	else:
		_main._pending_boss_part_hit = "%s,%s" % [existing_tokens, token]
	_last_queued_boss_hit_token = token
	_last_queued_boss_hit_frame = current_frame
	_resolve_pending_boss_part_hit_immediately()


func _spawn_boss_home_assault_focus_visual(province_id: int) -> void:
	if _main == null or _main.boss_system == null:
		return
	if not is_instance_valid(_main.obstacles_root):
		return
	var boss_id: int = -1
	if _main.boss_system.has_method("get_boss_id_for_home_province_id"):
		boss_id = int(_main.boss_system.get_boss_id_for_home_province_id(province_id))
	if boss_id < 0:
		boss_id = _get_primary_boss_id()
	if boss_id < 0 or not bool(_main.boss_system.is_boss_active(boss_id)):
		return

	var surviving_limbs: Array[String] = []
	for part_name in ["left_arm", "right_arm", "left_leg", "right_leg"]:
		if not bool(_main.boss_system.is_part_destroyed(part_name, boss_id)):
			surviving_limbs.append(part_name)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(_main.map_seed) * 4099 + int(province_id) * 313 + int(_main.turn_number) * 17 + boss_id * 101
	var focus_part: String = "head"
	if not surviving_limbs.is_empty():
		focus_part = surviving_limbs[rng.randi_range(0, surviving_limbs.size() - 1)]

	var world_rect: Rect2 = LevelConfig.get_outer_world_rect()
	var center: Vector2 = world_rect.get_center()
	var base_size: Vector2 = world_rect.size
	var head_radius: float = minf(base_size.x, base_size.y) * 0.70
	var limb_size: Vector2 = Vector2(base_size.x * 0.48, base_size.y * 0.98)

	var corner_sign_x: float = -1.0 if rng.randf() < 0.5 else 1.0
	var corner_sign_y: float = -1.0 if rng.randf() < 0.5 else 1.0
	match focus_part:
		"left_arm":
			corner_sign_x = 1.0
			corner_sign_y = 1.0
		"right_arm":
			corner_sign_x = -1.0
			corner_sign_y = 1.0
		"left_leg":
			corner_sign_x = 1.0
			corner_sign_y = -1.0
		"right_leg":
			corner_sign_x = -1.0
			corner_sign_y = -1.0

	var head_center: Vector2 = center + Vector2(corner_sign_x * base_size.x * 0.48, corner_sign_y * base_size.y * 0.48)
	var head_size: Vector2 = Vector2(head_radius * 2.0, head_radius * 2.0)
	var head_node: Node2D = _create_boss_focus_part_body("head", boss_id, head_center, head_size, 0.0, true)
	if head_node != null:
		_main.obstacles_root.add_child(head_node)

	if focus_part != "head":
		var head_half: Vector2 = head_size * 0.5
		var head_anchor: Vector2 = head_center + Vector2(-corner_sign_x * head_half.x, -corner_sign_y * head_half.y)
		var limb_rotation: float = atan2(-corner_sign_y, -corner_sign_x) - PI * 0.5 + PI
		var limb_anchor_local: Vector2 = _get_boss_focus_limb_visual_corner_offset(focus_part, limb_size, corner_sign_x, corner_sign_y)
		var limb_anchor_world: Vector2 = limb_anchor_local.rotated(limb_rotation)
		var limb_center: Vector2 = head_anchor - limb_anchor_world
		var corner_pull: float = float(LevelConfig.get_boss_home_assault_limb_corner_pull(focus_part))
		if absf(corner_pull) > 0.0001:
			var corner_dir: Vector2 = Vector2(corner_sign_x, corner_sign_y).normalized()
			var pull_distance: float = minf(base_size.x, base_size.y) * 0.20 * corner_pull
			limb_center += corner_dir * pull_distance
		var limb_node: Node2D = _create_boss_focus_part_body(focus_part, boss_id, limb_center, limb_size, limb_rotation, false)
		if limb_node != null:
			_main.obstacles_root.add_child(limb_node)


func _get_boss_focus_limb_visual_corner_offset(part_name: String, desired_size: Vector2, corner_sign_x: float, corner_sign_y: float) -> Vector2:
	var half_size: Vector2 = desired_size * 0.5
	var default_corner: Vector2 = Vector2(corner_sign_x * half_size.x, corner_sign_y * half_size.y)
	var sprite_path: String = String(LevelConfig.get_boss_limb_sprite_path(part_name)).strip_edges()
	if sprite_path == "" or not ResourceLoader.exists(sprite_path):
		return default_corner
	var texture: Texture2D = load(sprite_path) as Texture2D
	if texture == null:
		return default_corner
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return default_corner

	var image_size: Vector2i = image.get_size()
	if image_size.x <= 0 or image_size.y <= 0:
		return default_corner

	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, 0.10)
	var polys: Array = bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, image_size), 2.0)
	if polys.is_empty():
		return default_corner

	var min_x: float = float(image_size.x)
	var min_y: float = float(image_size.y)
	var max_x: float = 0.0
	var max_y: float = 0.0
	var found: bool = false
	for poly_any in polys:
		if not (poly_any is PackedVector2Array):
			continue
		var poly: PackedVector2Array = poly_any
		for pt in poly:
			min_x = minf(min_x, pt.x)
			min_y = minf(min_y, pt.y)
			max_x = maxf(max_x, pt.x)
			max_y = maxf(max_y, pt.y)
			found = true
	if not found:
		return default_corner

	var corner_x: float = max_x if corner_sign_x > 0.0 else min_x
	var corner_y: float = max_y if corner_sign_y > 0.0 else min_y
	var tex_size: Vector2 = texture.get_size()
	if tex_size.x <= 0.001 or tex_size.y <= 0.001:
		return default_corner
	var centered_corner: Vector2 = Vector2(corner_x - tex_size.x * 0.5, corner_y - tex_size.y * 0.5)
	var scale: Vector2 = Vector2(desired_size.x / tex_size.x, desired_size.y / tex_size.y)
	return Vector2(centered_corner.x * scale.x, centered_corner.y * scale.y)


func on_building_hit(building: Node) -> void:
	if _main == null:
		return
	if _uses_logical_offensive_buildings():
		return
	if not is_instance_valid(building) or building.has_meta("destroyed"):
		return

	if _main.ball and is_instance_valid(_main.ball):
		if _main.ball.has_method("apply_hit_slowdown"):
			_main.ball.apply_hit_slowdown(LevelConfig.BUILDING_SLOWDOWN_FACTOR)

		var impact_speed: float = _main.ball.linear_velocity.length()
		if impact_speed > LevelConfig.BUILDING_DESTRUCTION_THRESHOLD:
			destroy_building(building)


func destroy_building(building: Node) -> void:
	if _main == null or not is_instance_valid(building):
		return
	if _uses_logical_offensive_buildings():
		return

	building.set_meta("destroyed", true)
	building.collision_layer = 0
	building.collision_mask = 0

	var imprint: Polygon2D = Polygon2D.new()
	imprint.global_position = building.global_position
	imprint.color = LevelConfig.BUILDING_IMPRINT_COLOR

	for poly_node in building.get_children():
		if poly_node is Polygon2D and poly_node.name.begins_with("base"):
			imprint.polygon = (poly_node as Polygon2D).polygon
			break

	_main.obstacles_root.add_child(imprint)
	building.queue_free()
	_main._destroyed_buildings_this_level += 1
	refresh_engagement_live_counter()
	_main._apply_screen_shake(2.5, 0.15)


func activate_ball_follow() -> void:
	if _main == null:
		return
	if _main.ball and is_instance_valid(_main.ball):
		_main._camera_follow_active = true
		if _main.camera_controller != null:
			_main.camera_controller.call_deferred("update_ball_follow", 0.0)


func on_ball_sunk_in_water() -> void:
	if _main == null:
		return
	_main._last_ball_end_reason = "water"
	if _main.ball and is_instance_valid(_main.ball) and _main.province_system != null:
		_main.province_system.cache_ball_end_world_pos(_main.ball.global_position)
	finalize_ball_flight_now()


func finalize_ball_flight_now() -> void:
	if _main == null:
		return

	if _main.ball and is_instance_valid(_main.ball):
		if _main.province_system != null:
			_main.province_system.cache_ball_end_world_pos(_main.ball.global_position)

		var preserve_ball_visual: bool = false
		if _main.ball.has_method("is_sunk_in_water"):
			preserve_ball_visual = bool(_main.ball.call("is_sunk_in_water"))

		if preserve_ball_visual:
			_main.ball.linear_velocity = Vector2.ZERO
			_main.ball.angular_velocity = 0.0
			_main.ball.sleeping = true
			_main.ball.freeze = true
			_main.ball.collision_layer = 0
			_main.ball.collision_mask = 0
			_main.ball.visible = true
			_main.ball.z_index = max(_main.ball.z_index, 50)

	_main._camera_follow_active = false
	_restore_saved_grand_map_camera_if_available()
	if _main.camera_controller != null:
		_main.camera_controller.call_deferred("apply_camera_fit")

	if _main.has_method("_finalize_ball_flight"):
		_main.call("_finalize_ball_flight")
	elif _main.engagement_resolver != null:
		_main.engagement_resolver.end_level()


func advance_after_rest() -> void:
	if _main == null:
		return

	if _main._current_phase == LevelConfig.PHASE_GRAND_MAP:
		generate_grand_map()
	else:
		_main.level_index += 1
		_main.turn_number += 1
		generate_grand_map()


func refresh_live_boss_map_presentation() -> void:
	if _main == null:
		return
	sync_active_boss_home_province_stats()
	_clear_existing_boss_visual_root()
	_refresh_pending_friendly_boss_invasion_overlays()
	if _main.boss_system == null:
		return
	if not _main.boss_system.has_method("is_boss_active"):
		return
	if not bool(_main.boss_system.is_boss_active()):
		return
	if not is_instance_valid(_main.provinces_root):
		return

	var active_boss_states: Array[Dictionary] = _get_active_boss_states()
	if active_boss_states.is_empty():
		return

	var master_root := Node2D.new()
	master_root.name = BOSS_VISUAL_ROOT_NAME
	master_root.z_as_relative = false
	master_root.z_index = LevelConfig.VISUAL_LAYER_GRAND_MAP_PROVINCE_TROOPS + 40
	_main.provinces_root.add_child(master_root)

	for boss_state in active_boss_states:
		var boss_id: int = int(boss_state.get("boss_id", -1))
		var province_id: int = int(boss_state.get("current_province_id", boss_state.get("home_province_id", -1)))
		if province_id < 0:
			continue
		var use_enemy_sprite: bool = false
		if _main.province_system != null:
			var province_idx: int = _main.province_system.find_persistence_index_by_id(province_id)
			if province_idx >= 0:
				var province_state: Dictionary = _main._province_persistence[province_idx]
				use_enemy_sprite = bool(province_state.get("friendly_boss_invasion_pending", false))
		_build_live_boss_visual_root(master_root, boss_id, province_id, use_enemy_sprite)


func _refresh_pending_friendly_boss_invasion_overlays() -> void:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return
	var existing_root: Node = _main.provinces_root.get_node_or_null(FRIENDLY_BOSS_PENDING_OVERLAY_ROOT_NAME)
	if is_instance_valid(existing_root):
		existing_root.queue_free()
	var overlay_root := Node2D.new()
	overlay_root.name = FRIENDLY_BOSS_PENDING_OVERLAY_ROOT_NAME
	overlay_root.z_as_relative = false
	overlay_root.z_index = LevelConfig.VISUAL_LAYER_GRAND_MAP_PROVINCE_TROOPS + 50
	_main.provinces_root.add_child(overlay_root)

	var friendly_texture: Texture2D = load(String(LevelConfig.get_boss_friendly_invading_image_path())) as Texture2D
	if friendly_texture == null:
		return

	for province_state_any in _main._province_persistence:
		if not (province_state_any is Dictionary):
			continue
		var province_state: Dictionary = province_state_any
		if not bool(province_state.get("friendly_boss_invasion_pending", false)):
			continue
		var province_id: int = int(province_state.get("id", -1))
		if province_id < 0:
			continue
		var province_node: Node2D = _find_live_province_node_by_id(province_id)
		if province_node == null:
			continue
		var poly: PackedVector2Array = province_node.get_meta("province_polygon", PackedVector2Array())
		if poly.is_empty():
			continue
		var bounds: Rect2 = Rect2(poly[0], Vector2.ZERO)
		for pt in poly:
			bounds = bounds.expand(pt)
		if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
			continue
		var center: Vector2 = bounds.get_center()
		var marker_size: Vector2 = bounds.size * 0.21

		var friendly_sprite := Sprite2D.new()
		friendly_sprite.texture = friendly_texture
		friendly_sprite.centered = true
		friendly_sprite.position = center + Vector2(0.0, -bounds.size.y * 0.32)
		friendly_sprite.scale = Vector2(marker_size.x / friendly_texture.get_size().x, marker_size.y / friendly_texture.get_size().y)
		overlay_root.add_child(friendly_sprite)


func sync_active_boss_home_province_stats() -> void:
	if _main == null or _main.boss_system == null or _main.province_system == null:
		return
	if not _main.boss_system.has_method("get_active_boss_states"):
		return
	var active_states_any: Variant = _main.boss_system.get_active_boss_states()
	if not (active_states_any is Array):
		return
	var active_states: Array = active_states_any
	var changed: bool = false
	for state_any in active_states:
		if not (state_any is Dictionary):
			continue
		var boss_state: Dictionary = state_any
		var home_id: int = int(boss_state.get("home_province_id", -1))
		if home_id < 0:
			continue
		var idx: int = _main.province_system.find_persistence_index_by_id(home_id)
		if idx == -1:
			continue
		var province_state: Dictionary = _main._province_persistence[idx]
		var boss_id: int = int(boss_state.get("boss_id", -1))
		var boss_faction_id: int = int(boss_state.get("boss_faction_id", province_state.get("faction_id", 0)))
		var desired_troops: int = 0
		if _main.boss_system.has_method("get_boss_home_troop_count"):
			desired_troops = maxi(0, int(_main.boss_system.get_boss_home_troop_count(boss_id)))
		var desired_type: String = LevelConfig.PROVINCE_TYPE_ENEMY
		var is_friendly_boss: bool = _main.boss_system.has_method("is_friendly_boss") and bool(_main.boss_system.is_friendly_boss(boss_id))
		if is_friendly_boss:
			desired_type = LevelConfig.PROVINCE_TYPE_FRIENDLY
		if String(province_state.get("type", "")) != desired_type:
			province_state["type"] = desired_type
			changed = true
		if int(province_state.get("remaining_troops", -1)) != desired_troops:
			province_state["remaining_troops"] = desired_troops
			changed = true
		if int(province_state.get("remaining_buildings", -1)) != 0:
			province_state["remaining_buildings"] = 0
			changed = true
		if int(province_state.get("invading_troops", 0)) != 0:
			province_state["invading_troops"] = 0
			changed = true
		if int(province_state.get("faction_id", -1)) != boss_faction_id:
			province_state["faction_id"] = boss_faction_id
			changed = true
		province_state["is_boss_home"] = true
	if changed and _main.province_system.has_method("apply_persistence_to_province_visuals"):
		_main.province_system.apply_persistence_to_province_visuals()


func _get_boss_show_up_turn_for_current_run() -> int:
	if _main != null and _main.boss_system != null and _main.boss_system.has_method("get_boss_show_up_turn"):
		return maxi(1, int(_main.boss_system.get_boss_show_up_turn()))
	var campaign_level: int = 1
	var tutorial_active: bool = false
	if _main != null and _main.has_method("get_campaign_current_level_progress"):
		campaign_level = maxi(1, int(_main.call("get_campaign_current_level_progress")))
	if _main != null and _main.has_method("is_opening_gameplay_tutorial_active"):
		tutorial_active = bool(_main.call("is_opening_gameplay_tutorial_active"))
	return maxi(1, int(LevelConfig.get_boss_show_up_turn_for_level(campaign_level, tutorial_active)))


func _get_boss_spawn_roll_threshold_for_current_run() -> int:
	if _main != null and _main.boss_system != null and _main.boss_system.has_method("get_boss_spawn_roll_threshold"):
		return maxi(0, int(_main.boss_system.get_boss_spawn_roll_threshold()))
	return maxi(0, int(LevelConfig.get_boss_spawn_roll_threshold()))


func _should_spawn_boss_for_current_turn() -> bool:
	if _main == null or _main.boss_system == null:
		return false
	if String(_main._current_phase) != String(LevelConfig.PHASE_GRAND_MAP):
		return false
	if int(_main.turn_number) < _get_boss_show_up_turn_for_current_run():
		return false
	if _main.boss_system.has_method("has_spawned_once") and bool(_main.boss_system.has_spawned_once()):
		return false
	if _main.boss_system.has_method("is_boss_active") and bool(_main.boss_system.is_boss_active()):
		return false
	if _main.boss_system.has_method("is_boss_dead") and bool(_main.boss_system.is_boss_dead()):
		return false
	if _main.boss_system.has_method("get_completed_grand_map_rolls"):
		var completed_rolls: int = int(_main.boss_system.get_completed_grand_map_rolls())
		if completed_rolls < _get_boss_spawn_roll_threshold_for_current_run():
			return false
	return true


func _maybe_spawn_boss_for_current_turn() -> String:
	if not _should_spawn_boss_for_current_turn():
		return ""
	if _main == null or _main.boss_system == null:
		return ""

	var required_rolls: int = _get_boss_spawn_roll_threshold_for_current_run()
	if _main.boss_system.has_method("get_completed_grand_map_rolls") and _main.boss_system.has_method("set_completed_grand_map_rolls"):
		var current_rolls: int = int(_main.boss_system.get_completed_grand_map_rolls())
		if current_rolls < required_rolls:
			_main.boss_system.set_completed_grand_map_rolls(required_rolls)

	var spawn_result: Dictionary = _spawn_live_boss_on_current_map()
	if not bool(spawn_result.get("spawned", false)):
		return ""

	_maybe_unlock_boss_seen_note(true)
	_sanitize_locked_launch_province_for_active_boss()
	return _build_boss_spawn_status_text(spawn_result)


func try_finalize_live_boss_grand_map_settlement(end_world_pos: Vector2, has_live_ball: bool) -> bool:
	if _main == null or _main.boss_system == null:
		return false

	var boss_active: bool = bool(_main.boss_system.has_method("is_boss_active") and _main.boss_system.is_boss_active())
	var pending_hits: Array[Dictionary] = _parse_pending_boss_part_hit_tokens(String(_main._pending_boss_part_hit))
	var province_data: Dictionary = {}
	if _main.province_system != null:
		province_data = _main.province_system.get_province_data(end_world_pos)
	var landed_province_id: int = int(province_data.get("id", -1))
	var landed_on_boss_home: bool = boss_active and _is_any_active_boss_home_province_id(landed_province_id)

	if boss_active and (not pending_hits.is_empty() or landed_on_boss_home):
		var damage_status_text: String = ""
		if not pending_hits.is_empty():
			var status_lines: Array[String] = []
			for pending_hit_info in pending_hits:
				var pending_part_hit: String = String(pending_hit_info.get("part_name", "")).strip_edges()
				if pending_part_hit == "":
					continue
				var pending_boss_id: int = int(pending_hit_info.get("boss_id", -1))
				if pending_boss_id < 0 and landed_on_boss_home and _main.boss_system.has_method("get_boss_id_for_home_province_id"):
					pending_boss_id = int(_main.boss_system.get_boss_id_for_home_province_id(landed_province_id))
				var hit_result: Dictionary = _main.boss_system.register_part_hit(pending_part_hit, pending_boss_id)
				status_lines.append(String(_main.boss_system.make_hit_status_text(hit_result)))
				if bool(hit_result.get("boss_killed", false)):
					_on_boss_killed_from_grand_map(int(hit_result.get("boss_id", pending_boss_id)))
			damage_status_text = "\n".join(status_lines)
		elif landed_on_boss_home:
			damage_status_text = "The ball landed in a boss province."

		_main._pending_boss_part_hit = ""
		if damage_status_text.strip_edges() != "":
			var existing_status_text: String = String(_main.get("_pending_boss_damage_status_text")).strip_edges()
			if existing_status_text != "":
				_main.set("_pending_boss_damage_status_text", "%s\n%s" % [existing_status_text, damage_status_text.strip_edges()])
			else:
				_main.set("_pending_boss_damage_status_text", damage_status_text.strip_edges())

		refresh_live_boss_map_presentation()
		return false

	if boss_active:
		return false

	if _main.boss_system.has_method("increment_completed_grand_map_rolls"):
		_main.boss_system.increment_completed_grand_map_rolls()
	return false


func _build_boss_spawn_status_text(spawn_result: Dictionary) -> String:
	var raw_entries: Variant = spawn_result.get("spawn_entries", [])
	var spawn_entries: Array[Dictionary] = []
	if raw_entries is Array:
		for entry in raw_entries:
			if entry is Dictionary:
				spawn_entries.append((entry as Dictionary).duplicate(true))

	if spawn_entries.is_empty():
		var home_id: int = int(spawn_result.get("home_province_id", -1))
		if home_id < 0:
			return "A boss appeared."
		var fallback_text: String = "A boss appeared in %s." % _format_province_label(home_id)
		var raw_seized: Variant = spawn_result.get("conquered_province_ids", [])
		if raw_seized is Array and not (raw_seized as Array).is_empty():
			var seized_labels: Array[String] = []
			for entry in raw_seized:
				seized_labels.append(_format_province_label(int(entry)))
			fallback_text = "A boss appeared in %s and seized %s." % [_format_province_label(home_id), ", ".join(seized_labels)]
		return fallback_text

	if spawn_entries.size() == 1:
		var only_entry: Dictionary = spawn_entries[0]
		var only_home_id: int = int(only_entry.get("home_province_id", -1))
		var only_faction_name: String = String(only_entry.get("boss_faction_name", "A boss")).strip_edges()
		if only_faction_name.is_empty():
			only_faction_name = "A boss"
		var only_expected_home_count: int = maxi(0, int(only_entry.get("expected_home_count", 1)))
		var only_expected_non_home_count: int = maxi(0, int(only_entry.get("expected_non_home_count", 0)))
		var only_seized_labels: Array[String] = []
		var raw_only_seized: Variant = only_entry.get("conquered_province_ids", [])
		if raw_only_seized is Array:
			for entry in raw_only_seized:
				only_seized_labels.append(_format_province_label(int(entry)))
		var line: String = "%s spawn plan — expected home provinces: %d; expected non-home provinces: %d." % [only_faction_name, only_expected_home_count, only_expected_non_home_count]
		line += "\n%s home assignment: %s." % [only_faction_name, _format_province_label(only_home_id)]
		if not only_seized_labels.is_empty():
			line += "\n%s non-home assignments (%d/%d): %s." % [only_faction_name, only_seized_labels.size(), only_expected_non_home_count, ", ".join(only_seized_labels)]
		else:
			line += "\n%s non-home assignments (0/%d): none." % [only_faction_name, only_expected_non_home_count]
		var only_candidate_count: int = maxi(0, int(only_entry.get("spawn_candidate_count", -1)))
		var only_blocked_count: int = maxi(0, int(only_entry.get("blocked_id_count", -1)))
		if only_candidate_count >= 0 and only_blocked_count >= 0:
			line += "\nSpawn debug: candidates=%d, blocked=%d." % [only_candidate_count, only_blocked_count]
		return line

	var lines: Array[String] = ["%d bosses appeared." % spawn_entries.size()]
	var plan_boss_count: int = maxi(0, int(spawn_result.get("target_boss_count", spawn_entries.size())))
	var plan_non_home_count: int = maxi(0, int(spawn_result.get("expected_non_home_per_boss", -1)))
	var plan_candidate_count: int = maxi(0, int(spawn_result.get("candidate_count", -1)))
	var plan_water_safe_candidate_count: int = maxi(0, int(spawn_result.get("water_safe_candidate_count", -1)))
	var plan_seed: int = int(spawn_result.get("spawn_seed", 0))
	if plan_non_home_count >= 0:
		lines.append("Boss spawn plan: target bosses=%d; expected per boss = 1 home + %d non-home provinces." % [plan_boss_count, plan_non_home_count])
	if plan_candidate_count >= 0:
		lines.append("Spawn debug: candidate provinces=%d." % plan_candidate_count)
	if plan_water_safe_candidate_count >= 0:
		lines.append("Spawn debug: water-safe candidate provinces=%d." % plan_water_safe_candidate_count)
	if plan_seed != 0:
		lines.append("Spawn debug: deterministic seed=%d." % plan_seed)
	for index in range(spawn_entries.size()):
		var spawn_entry: Dictionary = spawn_entries[index]
		var faction_name: String = String(spawn_entry.get("boss_faction_name", "Boss %d" % [index + 1])).strip_edges()
		if faction_name.is_empty():
			faction_name = "Boss %d" % [index + 1]
		var home_label: String = _format_province_label(int(spawn_entry.get("home_province_id", -1)))
		var expected_home_count: int = maxi(0, int(spawn_entry.get("expected_home_count", 1)))
		var expected_non_home_count: int = maxi(0, int(spawn_entry.get("expected_non_home_count", plan_non_home_count)))
		var seized_labels: Array[String] = []
		var raw_seized_entry: Variant = spawn_entry.get("conquered_province_ids", [])
		if raw_seized_entry is Array:
			for province_id in raw_seized_entry:
				seized_labels.append(_format_province_label(int(province_id)))
		var detail_line: String = "%s plan — home:%d non-home:%d." % [faction_name, expected_home_count, expected_non_home_count]
		detail_line += " Home assignment: %s." % home_label
		if not seized_labels.is_empty():
			detail_line += " Non-home assignments (%d/%d): %s." % [seized_labels.size(), expected_non_home_count, ", ".join(seized_labels)]
		else:
			detail_line += " Non-home assignments (0/%d): none." % expected_non_home_count
		lines.append(detail_line)
	return "\n".join(lines)


func _build_boss_faction_name_for_faction_id(faction_id: int) -> String:
	var safe_faction_id: int = maxi(1, int(faction_id))
	if _main != null and _main.province_system != null and _main.province_system.has_method("get_faction_display_name"):
		var faction_name: String = String(_main.province_system.call("get_faction_display_name", safe_faction_id)).strip_edges()
		if not faction_name.is_empty():
			return faction_name
	var map_seed: int = 1
	if _main != null:
		map_seed = maxi(1, int(_main.get("map_seed")))
	var generated: String = String(LevelConfig.generate_province_name(map_seed, 1000000 + safe_faction_id)).strip_edges()
	if not generated.is_empty():
		return generated
	return "Faction %d" % safe_faction_id


func _refresh_pending_friendly_boss_conquered_provinces(spawn_entry: Dictionary) -> Dictionary:
	var updated_entry: Dictionary = spawn_entry.duplicate(true)
	if _main == null or _main.boss_system == null:
		return updated_entry

	var home_id: int = int(updated_entry.get("home_province_id", -1))
	var eligible_lookup: Dictionary = {}
	if is_instance_valid(_main.provinces_root):
		for province_node_any in _main.provinces_root.get_children():
			var province_node: Node = province_node_any
			if not is_instance_valid(province_node):
				continue
			if not province_node.has_meta("province_data"):
				continue
			var province_state: Dictionary = province_node.get_meta("province_data", {})
			var province_id: int = int(province_state.get("id", -1))
			if province_id < 0 or province_id == home_id:
				continue
			if bool(province_state.get("is_boss_home", false)):
				continue
			var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
			if province_type != LevelConfig.PROVINCE_TYPE_FRIENDLY and province_type != LevelConfig.PROVINCE_TYPE_ENEMY:
				continue
			if _main.boss_system.is_boss_faction_province_state(province_state):
				continue
			eligible_lookup[province_id] = true
	if eligible_lookup.is_empty():
		for province_state_any in _main._province_persistence:
			var province_state: Dictionary = province_state_any
			var province_id: int = int(province_state.get("id", -1))
			if province_id < 0 or province_id == home_id:
				continue
			if bool(province_state.get("is_boss_home", false)):
				continue
			var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
			if province_type != LevelConfig.PROVINCE_TYPE_FRIENDLY and province_type != LevelConfig.PROVINCE_TYPE_ENEMY:
				continue
			if _main.boss_system.is_boss_faction_province_state(province_state):
				continue
			eligible_lookup[province_id] = true
	var eligible_ids: Array[int] = []
	for province_id_any in eligible_lookup.keys():
		eligible_ids.append(int(province_id_any))

	var refreshed_conquered_ids: Array[int] = []
	if not eligible_ids.is_empty():
		var selection_rng := RandomNumberGenerator.new()
		selection_rng.seed = int(_main.map_seed) * 130363 + int(_main.turn_number) * 1741 + int(home_id + 1) * 6151
		for i in range(eligible_ids.size() - 1, 0, -1):
			var swap_index: int = selection_rng.randi_range(0, i)
			var tmp: int = eligible_ids[i]
			eligible_ids[i] = eligible_ids[swap_index]
			eligible_ids[swap_index] = tmp
		var desired_count: int = mini(2, eligible_ids.size())
		for index in range(desired_count):
			refreshed_conquered_ids.append(eligible_ids[index])

	updated_entry["conquered_province_ids"] = refreshed_conquered_ids
	return updated_entry


func maybe_activate_pending_friendly_boss_spawn() -> String:
	if _main == null or _main.boss_system == null:
		return ""
	if not _main.has_meta(PENDING_FRIENDLY_BOSS_SPAWN_META):
		return ""
	var pending_any: Variant = _main.get_meta(PENDING_FRIENDLY_BOSS_SPAWN_META, {})
	if not (pending_any is Dictionary):
		_main.remove_meta(PENDING_FRIENDLY_BOSS_SPAWN_META)
		return ""
	var pending: Dictionary = pending_any
	var activate_turn: int = int(pending.get("activate_turn", -1))
	if activate_turn < 0 or int(_main.turn_number) < activate_turn:
		return ""
	var spawn_entry: Dictionary = (pending.get("spawn_entry", {}) as Dictionary).duplicate(true)
	if spawn_entry.is_empty():
		_main.remove_meta(PENDING_FRIENDLY_BOSS_SPAWN_META)
		return ""
	spawn_entry = _refresh_pending_friendly_boss_conquered_provinces(spawn_entry)
	var spawn_entries: Array[Dictionary] = [spawn_entry]
	_apply_live_boss_spawn_entries_to_persistence(spawn_entries, false)
	if _main.boss_system.has_method("append_bosses"):
		_main.boss_system.append_bosses(spawn_entries)
	elif _main.boss_system.has_method("activate_multiple_bosses"):
		_main.boss_system.activate_multiple_bosses(spawn_entries)
	if _main.province_system != null:
		_main.province_system.apply_persistence_to_province_visuals()
	refresh_live_boss_map_presentation()
	_main.remove_meta(PENDING_FRIENDLY_BOSS_SPAWN_META)
	var home_label: String = _format_province_label(int(spawn_entry.get("home_province_id", -1)))
	var faction_name: String = String(spawn_entry.get("boss_faction_name", "")).strip_edges()
	if faction_name.is_empty():
		faction_name = "Friendly Boss"
	return "%s arrived at %s." % [faction_name, home_label]


func _choose_lock_province_after_boss_event(preferred_province_id: int) -> int:
	var candidate_id: int = preferred_province_id
	if candidate_id < 0:
		candidate_id = _main._locked_province_id_after_win
	if _main == null or _main.boss_system == null:
		return candidate_id
	if not bool(_main.boss_system.has_method("is_boss_active") and _main.boss_system.is_boss_active()):
		return candidate_id
	if candidate_id >= 0 and not _is_any_active_boss_home_province_id(candidate_id):
		return candidate_id
	var home_ids: Array[int] = _get_active_boss_home_province_ids()
	if home_ids.is_empty():
		return candidate_id
	return _find_nearest_non_boss_province_id(home_ids[0])


func _sanitize_locked_launch_province_for_active_boss() -> void:
	if _main == null or _main.boss_system == null:
		return
	if _main._locked_province_id_after_win < 0:
		return
	if not bool(_main.boss_system.has_method("is_boss_active") and _main.boss_system.is_boss_active()):
		return
	if not _is_any_active_boss_home_province_id(_main._locked_province_id_after_win):
		return
	var redirected_id: int = _find_nearest_non_boss_province_id(_main._locked_province_id_after_win)
	if redirected_id >= 0:
		_main._locked_province_id_after_win = redirected_id


func _find_nearest_non_boss_province_id(reference_province_id: int) -> int:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return -1
	var reference_center: Vector2 = _get_live_province_center_by_id(reference_province_id)
	var best_id: int = -1
	var best_dist_sq: float = INF
	for province_node_any in _main.provinces_root.get_children():
		var province_node: Node = province_node_any
		if not is_instance_valid(province_node):
			continue
		if String(province_node.name) == BOSS_VISUAL_ROOT_NAME:
			continue
		if not province_node.has_meta("province_data"):
			continue
		var meta_data: Dictionary = province_node.get_meta("province_data")
		var province_id: int = int(meta_data.get("id", -1))
		if province_id < 0 or province_id == reference_province_id:
			continue
		if _is_any_active_boss_home_province_id(province_id):
			continue
		var candidate_center: Vector2 = _get_live_province_center_by_id(province_id)
		var dist_sq: float = reference_center.distance_squared_to(candidate_center)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_id = province_id
	return best_id


func _get_live_province_center_by_id(province_id: int) -> Vector2:
	var province_node: Node2D = _find_live_province_node_by_id(province_id)
	if province_node == null:
		return Vector2.ZERO
	if province_node.has_meta("province_polygon"):
		var polygon: PackedVector2Array = province_node.get_meta("province_polygon")
		if not polygon.is_empty():
			return _estimate_polygon_center(polygon)
	return province_node.global_position


func _advance_after_boss_grand_map_event(status_text: String, lock_province_id: int = -1) -> void:
	_main.state = _main.GameState.GRAND_MAP
	_main._current_phase = LevelConfig.PHASE_GRAND_MAP
	_main._active_engagement_province_id = -1
	if _main.enemy_turn_system != null:
		_main.enemy_turn_system.advance_grand_map_turn_after_rest(status_text, lock_province_id)
	else:
		_main.level_index += 1
		_main.turn_number += 1
		if lock_province_id != -1:
			_main._locked_province_id_after_win = lock_province_id
		generate_grand_map()
		if _main.ui_bridge != null:
			_main.ui_bridge.ui_set_status(status_text)
			_main.ui_bridge.sync_ui_button_states()


func _spawn_live_boss_on_current_map() -> Dictionary:
	var result: Dictionary = {
		"spawned": false,
		"home_province_id": -1,
		"conquered_province_ids": [],
		"spawn_entries": [],
		"boss_count": 0,
		"target_boss_count": 0,
		"expected_non_home_per_boss": 0,
		"candidate_count": 0,
		"water_safe_candidate_count": 0,
		"spawn_seed": 0
	}
	if _main == null or _main.boss_system == null or _main.province_system == null:
		return result
	if _main.has_meta(PENDING_FRIENDLY_BOSS_SPAWN_META):
		_main.remove_meta(PENDING_FRIENDLY_BOSS_SPAWN_META)

	var candidates: Array[Dictionary] = _build_live_boss_candidate_provinces()
	result["candidate_count"] = candidates.size()
	var water_safe_candidate_count: int = 0
	for candidate_any in candidates:
		var candidate: Dictionary = candidate_any
		if bool(candidate.get("is_boss_footprint_water_safe", false)):
			water_safe_candidate_count += 1
	result["water_safe_candidate_count"] = water_safe_candidate_count
	if candidates.is_empty():
		return result

	var target_boss_count: int = 1
	if _main.boss_system.has_method("get_target_boss_count_for_current_level"):
		target_boss_count = maxi(1, int(_main.boss_system.get_target_boss_count_for_current_level()))
	var is_final_campaign_level: bool = false
	if _main.has_method("is_campaign_final_level_active"):
		is_final_campaign_level = bool(_main.call("is_campaign_final_level_active"))
	elif _main.has_method("get_campaign_current_level_progress"):
		is_final_campaign_level = LevelConfig.is_campaign_final_level(int(_main.call("get_campaign_current_level_progress")))
	if is_final_campaign_level:
		target_boss_count = 4
	target_boss_count = clampi(target_boss_count, 1, maxi(1, candidates.size()))
	result["target_boss_count"] = target_boss_count

	var blocked_ids: Array[int] = []
	if _main._locked_province_id_after_win >= 0:
		blocked_ids.append(_main._locked_province_id_after_win)

	var home_ids: Array[int] = []
	if target_boss_count > 1 and _main.boss_system.has_method("choose_multiple_boss_home_province_ids"):
		home_ids = _main.boss_system.choose_multiple_boss_home_province_ids(candidates, blocked_ids, target_boss_count)
	if home_ids.is_empty():
		var single_home_id: int = int(_main.boss_system.choose_boss_home_province_id(candidates, blocked_ids))
		if single_home_id >= 0:
			home_ids.append(single_home_id)
	if home_ids.is_empty():
		return result

	var spawn_rng := RandomNumberGenerator.new()
	spawn_rng.seed = int(_main.map_seed) * 104729 + int(_main.turn_number) * 1009 + int(_main.level_index) * 37 + int(_main.boss_system.get_completed_grand_map_rolls()) * 7919
	result["spawn_seed"] = int(spawn_rng.seed)

	var globally_excluded_ids: Array[int] = blocked_ids.duplicate()
	for home_id in home_ids:
		if not globally_excluded_ids.has(home_id):
			globally_excluded_ids.append(home_id)

	var spawn_entries: Array[Dictionary] = []
	var conquered_count_per_boss: int = 2
	result["expected_non_home_per_boss"] = conquered_count_per_boss
	for index in range(home_ids.size()):
		var home_id: int = int(home_ids[index])
		var conquered_ids: Array[int] = _main.boss_system.choose_initial_boss_faction_province_ids(candidates, globally_excluded_ids, spawn_rng, conquered_count_per_boss)
		if conquered_ids.size() < conquered_count_per_boss:
			var fallback_ids: Array[int] = _select_fallback_initial_boss_conquered_ids(candidates, globally_excluded_ids, spawn_rng, conquered_count_per_boss - conquered_ids.size())
			for fallback_id in fallback_ids:
				if not conquered_ids.has(fallback_id):
					conquered_ids.append(fallback_id)
		for conquered_id in conquered_ids:
			if not globally_excluded_ids.has(conquered_id):
				globally_excluded_ids.append(conquered_id)
		var is_friendly_boss: bool = is_final_campaign_level and index == home_ids.size() - 1
		var boss_faction_id: int = int(_main.boss_system.get_default_boss_faction_id_for_index(index)) if _main.boss_system.has_method("get_default_boss_faction_id_for_index") else int(_main.boss_system.get_boss_faction_id())
		if is_friendly_boss and _main.boss_system.has_method("get_friendly_boss_faction_id"):
			boss_faction_id = int(_main.boss_system.get_friendly_boss_faction_id())
		var entry: Dictionary = {
			"home_province_id": home_id,
			"conquered_province_ids": conquered_ids.duplicate(),
			"boss_faction_id": boss_faction_id,
			"is_friendly_boss": is_friendly_boss,
			"boss_faction_name": _build_boss_faction_name_for_faction_id(boss_faction_id),
			"expected_home_count": 1,
			"expected_non_home_count": conquered_count_per_boss,
			"spawn_candidate_count": candidates.size(),
			"blocked_id_count": blocked_ids.size()
		}
		if conquered_ids.size() < conquered_count_per_boss:
			push_warning("Boss spawn assigned fewer non-home provinces than expected for faction %s (got %d, expected %d)." % [String(entry.get("boss_faction_name", "Unknown")), conquered_ids.size(), conquered_count_per_boss])
		spawn_entries.append(entry)

	if spawn_entries.is_empty():
		return result

	_apply_live_boss_spawn_entries_to_persistence(spawn_entries)
	if _main.boss_system.has_method("activate_multiple_bosses"):
		_main.boss_system.activate_multiple_bosses(spawn_entries)
	elif not spawn_entries.is_empty():
		var first_entry: Dictionary = spawn_entries[0]
		_main.boss_system.activate_boss(
			int(first_entry.get("home_province_id", -1)),
			first_entry.get("conquered_province_ids", []),
			int(first_entry.get("boss_faction_id", _main.boss_system.get_boss_faction_id()))
		)
	if _main.province_system != null:
		_main.province_system.apply_persistence_to_province_visuals()
		_play_boss_spawn_transfer_flash_sequence(spawn_entries)
	refresh_live_boss_map_presentation()

	if spawn_entries.is_empty():
		return result
	result["spawned"] = true
	result["home_province_id"] = int(spawn_entries[0].get("home_province_id", -1))
	result["conquered_province_ids"] = spawn_entries[0].get("conquered_province_ids", []).duplicate()
	result["spawn_entries"] = spawn_entries.duplicate(true)
	result["boss_count"] = spawn_entries.size()
	return result


func _select_fallback_initial_boss_conquered_ids(candidate_provinces: Array[Dictionary], excluded_ids: Array[int], gen_rng: RandomNumberGenerator, count: int) -> Array[int]:
	var desired_count: int = maxi(0, count)
	if desired_count <= 0:
		return []
	var excluded_lookup: Dictionary = {}
	for province_id in excluded_ids:
		excluded_lookup[int(province_id)] = true
	var available_ids: Array[int] = []
	for province_any in candidate_provinces:
		var province: Dictionary = province_any
		var province_id: int = int(province.get("id", -1))
		if province_id < 0:
			continue
		if excluded_lookup.has(province_id):
			continue
		if bool(province.get("is_target", false)):
			continue
		available_ids.append(province_id)
	if available_ids.is_empty():
		return []
	if gen_rng != null:
		for idx in range(available_ids.size() - 1, 0, -1):
			var swap_idx: int = int(gen_rng.randi_range(0, idx))
			var tmp: int = int(available_ids[idx])
			available_ids[idx] = int(available_ids[swap_idx])
			available_ids[swap_idx] = tmp
	var picked: Array[int] = []
	for province_id in available_ids:
		if picked.size() >= desired_count:
			break
		picked.append(int(province_id))
	return picked


func _apply_live_boss_spawn_entries_to_persistence(spawn_entries: Array[Dictionary], reset_existing_boss_flags: bool = true) -> void:
	if _main == null or _main.province_system == null or _main.boss_system == null:
		return
	var boss_home_troops: int = _get_initial_boss_province_troops()
	var boss_home_buildings: int = 0
	var campaign_enemy_troop_increase_per_level: int = int(LevelConfig.get_campaign_enemy_troop_increase_per_level())
	if _main != null and _main.has_method("get_campaign_enemy_troop_increase_per_level"):
		campaign_enemy_troop_increase_per_level = maxi(0, int(_main.call("get_campaign_enemy_troop_increase_per_level")))

	if reset_existing_boss_flags:
		for province_state_any in _main._province_persistence:
			var province_state: Dictionary = province_state_any
			province_state["is_boss_home"] = false
			province_state["is_friendly_boss_province"] = false

	for spawn_entry in spawn_entries:
		var boss_faction_id: int = int(spawn_entry.get("boss_faction_id", 0))
		var is_friendly_boss: bool = bool(spawn_entry.get("is_friendly_boss", false))
		var home_id: int = int(spawn_entry.get("home_province_id", -1))
		var home_idx: int = _main.province_system.find_persistence_index_by_id(home_id)
		if home_idx != -1:
			var home_state: Dictionary = _main._province_persistence[home_idx]
			home_state["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
			# Friendly boss home arrival should mirror enemy boss home troops exactly.
			# Any existing home-province troops are intentionally replaced on arrival.
			home_state["remaining_troops"] = boss_home_troops
			home_state["remaining_buildings"] = boss_home_buildings
			home_state["invading_troops"] = 0
			home_state["invading_source_ids"] = []
			home_state["pending_invasion_started_turn"] = -1
			home_state["friendly_boss_invasion_pending"] = false
			home_state["friendly_boss_invading_troops"] = 0
			home_state["friendly_boss_invader_id"] = -1
			home_state["friendly_boss_invasion_started_turn"] = -1
			home_state["faction_id"] = boss_faction_id
			home_state["construction_progress"] = 0
			home_state["is_boss_home"] = true
			home_state["is_friendly_boss_province"] = is_friendly_boss
			if _main.province_system.has_method("clear_province_capture_source_by_id"):
				_main.province_system.clear_province_capture_source_by_id(home_id)

	for spawn_entry in spawn_entries:
		var boss_faction_id: int = int(spawn_entry.get("boss_faction_id", 0))
		var is_friendly_boss: bool = bool(spawn_entry.get("is_friendly_boss", false))
		var conquered_ids: Array[int] = []
		var raw_conquered: Variant = spawn_entry.get("conquered_province_ids", [])
		if raw_conquered is Array:
			for entry in raw_conquered:
				conquered_ids.append(int(entry))

		for province_id in conquered_ids:
			var idx: int = _main.province_system.find_persistence_index_by_id(province_id)
			if idx == -1:
				continue
			var province_state: Dictionary = _main._province_persistence[idx]
			var preserved_troops: int = maxi(0, int(province_state.get("remaining_troops", 0)))
			var preserved_buildings: int = maxi(0, int(province_state.get("remaining_buildings", 0)))
			province_state["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
			province_state["remaining_troops"] = preserved_troops + campaign_enemy_troop_increase_per_level
			province_state["remaining_buildings"] = preserved_buildings
			province_state["invading_troops"] = 0
			province_state["faction_id"] = boss_faction_id
			province_state["construction_progress"] = 0
			province_state["is_boss_home"] = false
			province_state["is_friendly_boss_province"] = is_friendly_boss
			if _main.province_system.has_method("clear_province_capture_source_by_id"):
				_main.province_system.clear_province_capture_source_by_id(province_id)


func _apply_live_boss_spawn_to_persistence(home_id: int, conquered_ids: Array[int]) -> void:
	var boss_faction_id: int = 0
	if _main != null and _main.boss_system != null:
		boss_faction_id = int(_main.boss_system.get_boss_faction_id())
	_apply_live_boss_spawn_entries_to_persistence([{
		"home_province_id": home_id,
		"conquered_province_ids": conquered_ids.duplicate(),
		"boss_faction_id": boss_faction_id
	}])


func _play_boss_spawn_transfer_flash_sequence(spawn_entries: Array[Dictionary]) -> void:
	if _main == null or _main.province_system == null or spawn_entries.is_empty():
		return
	var transfer_order: Array[int] = []
	for spawn_entry in spawn_entries:
		var home_id: int = int(spawn_entry.get("home_province_id", -1))
		if home_id >= 0:
			transfer_order.append(home_id)
	for spawn_entry in spawn_entries:
		var raw_conquered: Variant = spawn_entry.get("conquered_province_ids", [])
		if raw_conquered is Array:
			for province_id_any in raw_conquered:
				var province_id: int = int(province_id_any)
				if province_id >= 0:
					transfer_order.append(province_id)
	if transfer_order.is_empty():
		return
	var flash_duration: float = maxf(0.05, float(LevelConfig.get_boss_spawn_transfer_flash_duration_seconds()))
	var flash_tween: Tween = _main.create_tween()
	for province_id in transfer_order:
		var flash_id: int = int(province_id)
		flash_tween.tween_callback(func() -> void:
			if _main != null and _main.province_system != null and _main.province_system.has_method("flash_province_faction_fill_if_visible"):
				_main.province_system.call("flash_province_faction_fill_if_visible", flash_id, flash_duration)
		)
		flash_tween.tween_interval(flash_duration)


func _build_live_boss_candidate_provinces() -> Array[Dictionary]:
	var all_candidates: Array[Dictionary] = []
	if _main == null:
		return all_candidates
	var live_candidate_by_id: Dictionary = {}
	var can_sample_live_map: bool = is_instance_valid(_main.provinces_root)
	if can_sample_live_map:
		for province_node_any in _main.provinces_root.get_children():
			var province_node: Node = province_node_any
			if not is_instance_valid(province_node):
				continue
			if not province_node.has_meta("province_data"):
				continue
			var meta_data: Dictionary = province_node.get_meta("province_data")
			var province_id: int = int(meta_data.get("id", -1))
			if province_id < 0:
				continue
			var polygon: PackedVector2Array = PackedVector2Array()
			if province_node.has_meta("province_polygon"):
				polygon = province_node.get_meta("province_polygon")
			live_candidate_by_id[province_id] = {
				"center": _estimate_polygon_center(polygon),
				"area": _estimate_polygon_area(polygon),
				"is_target": bool(meta_data.get("is_target", false)),
				"has_live_geometry": polygon.size() >= 3
			}

	if _main._province_persistence.is_empty():
		return all_candidates
	var province_total: int = maxi(1, _main._province_persistence.size())
	for province_state_any in _main._province_persistence:
		if not (province_state_any is Dictionary):
			continue
		var province_state: Dictionary = province_state_any
		var province_id: int = int(province_state.get("id", -1))
		if province_id < 0:
			continue
		var fallback_ratio: float = float(province_id + 1) / float(province_total + 1)
		var fallback_x: float = lerpf(-LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS.x * 0.75, LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS.x * 0.75, fallback_ratio)
		var fallback_y: float = sin(float(province_id + 1) * 1.618) * LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS.y * 0.45
		var center: Vector2 = Vector2(fallback_x, fallback_y)
		var area: float = 0.0
		var is_target: bool = false
		var has_live_geometry: bool = false
		if live_candidate_by_id.has(province_id):
			var live_entry: Dictionary = live_candidate_by_id[province_id]
			center = Vector2(live_entry.get("center", center))
			area = float(live_entry.get("area", 0.0))
			is_target = bool(live_entry.get("is_target", false))
			has_live_geometry = bool(live_entry.get("has_live_geometry", false))
		all_candidates.append({
			"id": province_id,
			"center": center,
			"area": area,
			"is_target": is_target,
			"type": String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			"has_live_geometry": has_live_geometry,
			"is_boss_footprint_water_safe": _is_boss_footprint_clear_of_water(center) if has_live_geometry else false
		})

	return all_candidates


func _estimate_polygon_center(polygon: PackedVector2Array) -> Vector2:
	if polygon.is_empty():
		return Vector2.ZERO
	var accum: Vector2 = Vector2.ZERO
	for point in polygon:
		accum += point
	return accum / float(polygon.size())


func _estimate_polygon_area(polygon: PackedVector2Array) -> float:
	if polygon.size() < 3:
		return 0.0
	var twice_area: float = 0.0
	for i in range(polygon.size()):
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		twice_area += a.x * b.y - b.x * a.y
	return absf(twice_area) * 0.5


func _is_boss_footprint_clear_of_water(center: Vector2) -> bool:
	if _main == null or not is_instance_valid(_main.zones_root):
		return true
	for zone_node_any in _main.zones_root.get_children():
		var zone_node: Node = zone_node_any
		if not is_instance_valid(zone_node):
			continue
		if not (zone_node is Area2D):
			continue
		if String(zone_node.get_meta("zone_type", "")) != "water":
			continue
		if _water_zone_overlaps_boss_footprint(zone_node as Area2D, center):
			return false
	return true


func _remove_water_overlapping_boss_footprint(center: Vector2) -> void:
	if _main == null or not is_instance_valid(_main.zones_root):
		return
	var doomed: Array[Node] = []
	for zone_node_any in _main.zones_root.get_children():
		var zone_node: Node = zone_node_any
		if not is_instance_valid(zone_node):
			continue
		if not (zone_node is Area2D):
			continue
		if String(zone_node.get_meta("zone_type", "")) != "water":
			continue
		if _water_zone_overlaps_boss_footprint(zone_node as Area2D, center):
			doomed.append(zone_node)
	for zone_node in doomed:
		if is_instance_valid(zone_node) and zone_node.get_parent() == _main.zones_root:
			_main.zones_root.remove_child(zone_node)
			zone_node.queue_free()


func _water_zone_overlaps_boss_footprint(water_area: Area2D, center: Vector2) -> bool:
	if water_area == null or not is_instance_valid(water_area):
		return false
	var water_center: Vector2 = water_area.global_position
	var radius: float = float(water_area.get_meta("zone_radius", 0.0))
	var aspect: float = maxf(0.42, float(water_area.get_meta("zone_aspect", 1.0)))
	var water_half_size := Vector2(radius * aspect, radius)
	var boss_half_size := BOSS_FOOTPRINT_HALF_SIZE + Vector2.ONE * BOSS_FOOTPRINT_CLEARANCE
	var delta: Vector2 = water_center - center
	return absf(delta.x) <= (water_half_size.x + boss_half_size.x) and absf(delta.y) <= (water_half_size.y + boss_half_size.y)


func _remove_rocks_overlapping_boss_head_spawn(home_polygon: PackedVector2Array) -> void:
	if home_polygon.is_empty():
		return
	if _main == null or not is_instance_valid(_main.obstacles_root):
		return
	if _main.generator == null or not _main.generator.has_method("get_boss_head_spawn_bounds"):
		return

	var head_bounds: Rect2 = _main.generator.get_boss_head_spawn_bounds(home_polygon, BOSS_FOOTPRINT_CLEARANCE)
	if head_bounds.size.x <= 0.001 or head_bounds.size.y <= 0.001:
		return

	var doomed: Array[Node] = []
	for obstacle_any in _main.obstacles_root.get_children():
		var obstacle_node: Node = obstacle_any
		if not is_instance_valid(obstacle_node):
			continue
		if not _is_removable_rock_obstacle_for_boss_head_clearance(obstacle_node):
			continue
		var obstacle_bounds: Rect2 = _compute_collision_object_bounds(obstacle_node)
		if obstacle_bounds.size.x <= 0.001 or obstacle_bounds.size.y <= 0.001:
			continue
		if head_bounds.intersects(obstacle_bounds, true):
			doomed.append(obstacle_node)

	for obstacle_node in doomed:
		if is_instance_valid(obstacle_node) and obstacle_node.get_parent() == _main.obstacles_root:
			_main.obstacles_root.remove_child(obstacle_node)
			obstacle_node.queue_free()


func _is_removable_rock_obstacle_for_boss_head_clearance(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if not (node is CollisionObject2D):
		return false
	if bool(node.get_meta("is_mountain", false)):
		return false
	if bool(node.get_meta("is_caltrop", false)):
		return false
	if bool(node.get_meta("is_boss_part", false)):
		return false

	for child_any in node.get_children():
		var child: Node = child_any
		if child is CollisionShape2D:
			var collision_shape: CollisionShape2D = child as CollisionShape2D
			if collision_shape.disabled:
				continue
			if collision_shape.shape is CircleShape2D:
				return true
	return false


func _compute_collision_object_bounds(node: Node) -> Rect2:
	if node == null or not is_instance_valid(node):
		return Rect2()
	if not (node is Node2D):
		return Rect2()

	var has_bounds: bool = false
	var merged: Rect2 = Rect2()
	for child_any in node.get_children():
		var child: Node = child_any
		var shape_bounds: Rect2 = Rect2()
		if child is CollisionShape2D:
			var collision_shape: CollisionShape2D = child as CollisionShape2D
			if collision_shape.disabled or collision_shape.shape == null:
				continue
			var center: Vector2 = collision_shape.global_position
			var scale_x: float = absf(collision_shape.global_scale.x)
			var scale_y: float = absf(collision_shape.global_scale.y)
			if collision_shape.shape is CircleShape2D:
				var radius: float = (collision_shape.shape as CircleShape2D).radius * maxf(scale_x, scale_y)
				shape_bounds = Rect2(center - Vector2.ONE * radius, Vector2.ONE * (radius * 2.0))
			elif collision_shape.shape is RectangleShape2D:
				var rect_size: Vector2 = (collision_shape.shape as RectangleShape2D).size * Vector2(scale_x, scale_y)
				shape_bounds = Rect2(center - rect_size * 0.5, rect_size)
			elif collision_shape.shape is CapsuleShape2D:
				var capsule: CapsuleShape2D = collision_shape.shape as CapsuleShape2D
				var half_w: float = capsule.radius * scale_x
				var half_h: float = (capsule.height * 0.5 + capsule.radius) * scale_y
				shape_bounds = Rect2(center - Vector2(half_w, half_h), Vector2(half_w * 2.0, half_h * 2.0))
			else:
				continue
		elif child is CollisionPolygon2D:
			var collision_poly: CollisionPolygon2D = child as CollisionPolygon2D
			if collision_poly.disabled:
				continue
			var poly: PackedVector2Array = collision_poly.polygon
			if poly.is_empty():
				continue
			var xf: Transform2D = collision_poly.global_transform
			var min_v: Vector2 = xf * poly[0]
			var max_v: Vector2 = min_v
			for i in range(1, poly.size()):
				var p: Vector2 = xf * poly[i]
				min_v.x = minf(min_v.x, p.x)
				min_v.y = minf(min_v.y, p.y)
				max_v.x = maxf(max_v.x, p.x)
				max_v.y = maxf(max_v.y, p.y)
			shape_bounds = Rect2(min_v, max_v - min_v)
		else:
			continue

		if not has_bounds:
			merged = shape_bounds
			has_bounds = true
		else:
			merged = merged.merge(shape_bounds)

	return merged if has_bounds else Rect2()


func _clear_existing_boss_visual_root() -> void:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return
	var existing: Node = _main.provinces_root.get_node_or_null(BOSS_VISUAL_ROOT_NAME)
	if existing != null and is_instance_valid(existing):
		_main.provinces_root.remove_child(existing)
		existing.queue_free()


func _get_live_boss_master_root() -> Node:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return null
	var root: Node = _main.provinces_root.get_node_or_null(BOSS_VISUAL_ROOT_NAME)
	if root == null or not is_instance_valid(root):
		return null
	return root


func _get_live_boss_visual_container(boss_id: int) -> Node:
	if boss_id < 0:
		return null
	var master_root: Node = _get_live_boss_master_root()
	if master_root == null:
		return null
	var container: Node = master_root.get_node_or_null("%s%d" % [BOSS_VISUAL_CONTAINER_PREFIX, boss_id])
	if container == null or not is_instance_valid(container):
		return null
	return container


func _build_live_boss_visual_root(master_root: Node2D, boss_id: int, home_province_id: int, use_enemy_sprite: bool = false) -> void:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return
	if master_root == null or not is_instance_valid(master_root):
		return
	var home_node: Node2D = _find_live_province_node_by_id(home_province_id)
	if home_node == null:
		return
	var home_polygon: PackedVector2Array = PackedVector2Array()
	if home_node.has_meta("province_polygon"):
		home_polygon = home_node.get_meta("province_polygon")
	if home_polygon.is_empty():
		return

	var center: Vector2 = _estimate_polygon_center(home_polygon)
	_remove_water_overlapping_boss_footprint(center)

	if _main.generator == null:
		_main.generator = LevelGenerator.new()

	_remove_rocks_overlapping_boss_head_spawn(home_polygon)

	var container := Node2D.new()
	container.name = "%s%d" % [BOSS_VISUAL_CONTAINER_PREFIX, boss_id]
	container.z_as_relative = false
	container.z_index = LevelConfig.VISUAL_LAYER_GRAND_MAP_PROVINCE_TROOPS + 40
	container.set_meta("boss_id", boss_id)
	container.set_meta("boss_home_province_id", home_province_id)
	master_root.add_child(container)

	var part_state_map: Dictionary = _get_live_boss_part_state_map(boss_id)
	var is_friendly_boss: bool = false
	if _main.boss_system != null and _main.boss_system.has_method("is_friendly_boss"):
		is_friendly_boss = bool(_main.boss_system.is_friendly_boss(boss_id))
	if use_enemy_sprite:
		is_friendly_boss = false
	var root: Node2D = null
	if _main.generator != null and _main.generator.has_method("build_or_refresh_boss_visuals"):
		root = _main.generator.build_or_refresh_boss_visuals(container, home_polygon, part_state_map, is_friendly_boss, use_enemy_sprite)
	if root == null:
		return

	root.set_meta("boss_id", boss_id)
	root.set_meta("boss_home_province_id", home_province_id)

	for part_name in ["head", "left_arm", "right_arm", "left_leg", "right_leg"]:
		var part_body: Node = root.get_node_or_null("BossPart_%s" % part_name)
		if part_body != null and is_instance_valid(part_body):
			part_body.set_meta("boss_id", boss_id)

	if root.has_method("refresh_animation_setup"):
		root.call_deferred("refresh_animation_setup")
	elif root.has_method("_cache_base_positions"):
		root.call("_cache_base_positions")

	_attach_boss_hit_sensors(root, boss_id)

	for part_name in ["head", "left_arm", "right_arm", "left_leg", "right_leg"]:
		_set_boss_part_destroyed_visual(part_name, bool(_main.boss_system.is_part_destroyed(part_name, boss_id)), boss_id)


func _get_live_boss_part_state_map(boss_id: int = -1) -> Dictionary:
	if _main == null or _main.boss_system == null:
		return {}
	if _main.boss_system.has_method("get_boss_state"):
		var boss_state: Dictionary = _main.boss_system.get_boss_state(boss_id)
		return boss_state.get("parts", {}).duplicate(true)
	if not _main.boss_system.has_method("get_runtime_state"):
		return {}
	var runtime_state: Dictionary = _main.boss_system.get_runtime_state()
	return runtime_state.get("parts", {}).duplicate(true)


func _attach_boss_hit_sensors(root: Node, boss_id: int = -1) -> void:
	if root == null or not is_instance_valid(root):
		return
	for part_name in ["head", "left_arm", "right_arm", "left_leg", "right_leg"]:
		var part_body: Node = root.get_node_or_null("BossPart_%s" % part_name)
		_attach_boss_hit_sensor_to_part(part_body, part_name, boss_id)


func _attach_boss_hit_sensor_to_part(part_body: Node, part_name: String, boss_id: int = -1) -> void:
	if part_body == null or not is_instance_valid(part_body):
		return
	var body_2d: CollisionObject2D = part_body as CollisionObject2D
	if body_2d == null:
		return

	var existing_sensor: Area2D = part_body.get_node_or_null("HitSensor") as Area2D
	if existing_sensor != null and is_instance_valid(existing_sensor):
		existing_sensor.queue_free()

	var sensor := Area2D.new()
	sensor.name = "HitSensor"
	sensor.collision_layer = 0
	sensor.collision_mask = LevelConfig.MASK_BALL
	sensor.monitoring = true
	sensor.monitorable = true
	sensor.input_pickable = false
	sensor.set_meta("boss_part_name", part_name)
	sensor.set_meta("boss_id", boss_id)
	sensor.body_entered.connect(Callable(self, "_on_boss_part_body_entered").bind(part_name, boss_id))
	part_body.add_child(sensor)

	var copied_shape_count: int = 0
	for child_any in part_body.get_children():
		var child: Node = child_any
		if child == sensor:
			continue
		if child is CollisionShape2D:
			var source_shape: Shape2D = (child as CollisionShape2D).shape
			if source_shape == null:
				continue
			var sensor_shape := CollisionShape2D.new()
			sensor_shape.position = (child as CollisionShape2D).position
			sensor_shape.rotation = (child as CollisionShape2D).rotation
			sensor_shape.scale = (child as CollisionShape2D).scale
			sensor_shape.disabled = bool((child as CollisionShape2D).disabled)
			sensor_shape.shape = source_shape.duplicate(true)
			sensor.add_child(sensor_shape)
			copied_shape_count += 1
		elif child is CollisionPolygon2D:
			var source_polygon: PackedVector2Array = (child as CollisionPolygon2D).polygon
			if source_polygon.is_empty():
				continue
			var sensor_poly := CollisionPolygon2D.new()
			sensor_poly.position = (child as CollisionPolygon2D).position
			sensor_poly.rotation = (child as CollisionPolygon2D).rotation
			sensor_poly.scale = (child as CollisionPolygon2D).scale
			sensor_poly.disabled = bool((child as CollisionPolygon2D).disabled)
			sensor_poly.polygon = source_polygon
			sensor.add_child(sensor_poly)
			copied_shape_count += 1

	if copied_shape_count <= 0:
		var fallback_shape := CollisionShape2D.new()
		var fallback_circle := CircleShape2D.new()
		fallback_circle.radius = 18.0
		fallback_shape.shape = fallback_circle
		sensor.add_child(fallback_shape)


func _get_live_boss_visual_root(boss_id: int = -1) -> Node:
	if boss_id < 0:
		boss_id = _get_primary_boss_id()
	var container: Node = _get_live_boss_visual_container(boss_id)
	if container != null:
		var root: Node = container.get_node_or_null(BOSS_VISUAL_ROOT_NAME)
		if root != null and is_instance_valid(root):
			return root
	return null


func _get_boss_part_node(part_name: String, boss_id: int = -1) -> Node:
	var root: Node = _get_live_boss_visual_root(boss_id)
	if root == null:
		return null
	return root.get_node_or_null("BossPart_%s" % part_name)


func _trigger_boss_part_hit_flash(part_name: String, boss_id: int = -1) -> void:
	var clean_part_name: String = String(part_name).strip_edges()
	if clean_part_name == "":
		return
	var root: Node = _get_live_boss_visual_root(boss_id)
	if root == null:
		return
	if root.has_method("trigger_part_hit_flash"):
		root.call("trigger_part_hit_flash", clean_part_name)


func _create_boss_focus_part_body(part_name: String, boss_id: int, world_pos: Vector2, desired_size: Vector2, world_rotation: float, is_head: bool) -> Node2D:
	var body := StaticBody2D.new()
	body.name = "BossPart_%s" % part_name
	body.global_position = world_pos
	body.global_rotation = world_rotation
	body.collision_layer = LevelConfig.MASK_WALLS
	body.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
	body.z_as_relative = false
	body.z_index = LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES + 50
	body.add_to_group(BOSS_PART_GROUP)
	body.set_meta("boss_part_name", part_name)
	body.set_meta("boss_id", boss_id)
	body.set_meta("is_boss_part", true)

	var added_sprite_collision: bool = _add_focus_part_collision_from_sprite(body, part_name, is_head, desired_size)
	var source_part: Node = _get_boss_part_node(part_name, boss_id)
	var copied_visual: bool = false
	if source_part != null and is_instance_valid(source_part):
		copied_visual = _copy_boss_part_collision_and_visual_from_source(body, source_part, desired_size)
	if not copied_visual:
		var collision := CollisionShape2D.new()
		if added_sprite_collision:
			collision = null
		if collision != null:
			if is_head:
				var circle := CircleShape2D.new()
				circle.radius = desired_size.x * 0.5
				collision.shape = circle
			else:
				var rect := RectangleShape2D.new()
				rect.size = desired_size
				collision.shape = rect
			body.add_child(collision)
		var fallback_texture_path: String = LevelConfig.get_boss_head_image_path() if is_head else LevelConfig.get_boss_limb_sprite_path(part_name)
		if ResourceLoader.exists(fallback_texture_path):
			var fallback_texture: Texture2D = load(fallback_texture_path) as Texture2D
			if fallback_texture != null:
				var sprite := Sprite2D.new()
				sprite.name = "Visual"
				sprite.texture = fallback_texture
				sprite.centered = true
				sprite.z_index = 55
				var tex_size: Vector2 = fallback_texture.get_size()
				if tex_size.x > 0.001 and tex_size.y > 0.001:
					sprite.scale = Vector2(desired_size.x / tex_size.x, desired_size.y / tex_size.y)
				body.add_child(sprite)
			else:
				var visual := Polygon2D.new()
				visual.name = "Visual"
				visual.color = Color(0.85, 0.2, 0.2, 0.55)
				visual.z_index = 55
				visual.polygon = _create_circle_polygon(desired_size.x * 0.5, 18) if is_head else _create_rectangle_polygon(desired_size)
				body.add_child(visual)
		else:
			var visual := Polygon2D.new()
			visual.name = "Visual"
			visual.color = Color(0.85, 0.2, 0.2, 0.55)
			visual.z_index = 55
			visual.polygon = _create_circle_polygon(desired_size.x * 0.5, 18) if is_head else _create_rectangle_polygon(desired_size)
			body.add_child(visual)
	if not is_head:
		_apply_boss_focus_limb_visual_rotation_offset(body, LevelConfig.get_boss_home_assault_limb_visual_rotation_radians(part_name))
	return body


func _apply_boss_focus_limb_visual_rotation_offset(body: StaticBody2D, rotation_offset: float) -> void:
	if body == null:
		return
	for child_any in body.get_children():
		if child_any is CollisionShape2D or child_any is CollisionPolygon2D:
			continue
		if child_any is Node2D:
			var node2d: Node2D = child_any as Node2D
			node2d.rotation += rotation_offset


func _add_focus_part_collision_from_sprite(body: StaticBody2D, part_name: String, is_head: bool, desired_size: Vector2) -> bool:
	if body == null:
		return false
	var texture_path: String = LevelConfig.get_boss_head_image_path() if is_head else LevelConfig.get_boss_limb_sprite_path(part_name)
	if not ResourceLoader.exists(texture_path):
		return false
	var texture: Texture2D = load(texture_path) as Texture2D
	if texture == null:
		return false
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return false
	var image_size: Vector2i = image.get_size()
	if image_size.x <= 0 or image_size.y <= 0:
		return false
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, 0.10)
	var alpha_polys: Array = bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, image_size), 2.0)
	if alpha_polys.is_empty():
		return false
	var added: bool = false
	for alpha_poly_any in alpha_polys:
		if not (alpha_poly_any is PackedVector2Array):
			continue
		var alpha_poly: PackedVector2Array = alpha_poly_any
		if alpha_poly.size() < 3:
			continue
		var local_collision_poly := PackedVector2Array()
		for tex_point in alpha_poly:
			local_collision_poly.append(Vector2(
				(tex_point.x / float(image_size.x) - 0.5) * desired_size.x,
				(tex_point.y / float(image_size.y) - 0.5) * desired_size.y
			))
		if local_collision_poly.size() < 3:
			continue
		var collision := CollisionPolygon2D.new()
		collision.name = "SpriteCollision"
		collision.polygon = local_collision_poly
		collision.disabled = false
		body.add_child(collision)
		added = true
	return added


func _copy_boss_part_collision_and_visual_from_source(target_body: StaticBody2D, source_part: Node, desired_size: Vector2) -> bool:
	if target_body == null or source_part == null:
		return false
	var source_bounds: Rect2 = _compute_collision_object_bounds(source_part)
	if source_bounds.size.x <= 0.001 or source_bounds.size.y <= 0.001:
		source_bounds = _compute_source_canvas_item_bounds(source_part)
	if source_bounds.size.x <= 0.001 or source_bounds.size.y <= 0.001:
		return false
	var scale_factor: float = minf(desired_size.x / source_bounds.size.x, desired_size.y / source_bounds.size.y)
	scale_factor = maxf(scale_factor, 0.01)
	target_body.scale = Vector2.ONE * scale_factor

	var source_clone: Node = source_part.duplicate(Node.DUPLICATE_USE_INSTANTIATION | Node.DUPLICATE_GROUPS)
	if source_clone == null:
		return false
	if source_clone is Node2D:
		var source_clone_2d: Node2D = source_clone as Node2D
		source_clone_2d.position = Vector2.ZERO
		source_clone_2d.rotation = 0.0
		source_clone_2d.scale = Vector2.ONE
	_disable_collision_for_visual_clone(source_clone)
	target_body.add_child(source_clone)
	if target_body.get_child_count() <= 0:
		return false
	return true


func _disable_collision_for_visual_clone(node: Node) -> void:
	if node == null:
		return
	if node is CollisionObject2D:
		var collision_node: CollisionObject2D = node as CollisionObject2D
		collision_node.collision_layer = 0
		collision_node.collision_mask = 0
	for child_any in node.get_children():
		_disable_collision_for_visual_clone(child_any as Node)


func _clone_boss_part_visual_subtree(source: Node) -> Node:
	if source == null or not is_instance_valid(source):
		return null
	var allow_self: bool = (
		source is Node2D
		or source is CollisionShape2D
		or source is CollisionPolygon2D
		or source is CanvasItem
	)
	if not allow_self:
		return null

	# Preserve render hierarchy/transforms from source parts while avoiding gameplay object trees.
	var clone_flags: int = Node.DUPLICATE_USE_INSTANTIATION
	var cloned: Node = source.duplicate(clone_flags)
	if cloned == null:
		return null

	for cloned_child_any in cloned.get_children():
		var cloned_child: Node = cloned_child_any
		cloned.remove_child(cloned_child)
		cloned_child.free()

	var copied_descendant: bool = false
	for child_any in source.get_children():
		var child: Node = child_any
		var child_clone: Node = _clone_boss_part_visual_subtree(child)
		if child_clone != null:
			cloned.add_child(child_clone)
			copied_descendant = true

	var is_direct_visual: bool = (
		source is CollisionShape2D
		or source is CollisionPolygon2D
		or source is CanvasItem
	)
	if not is_direct_visual and not copied_descendant:
		return null
	return cloned


func _compute_source_canvas_item_bounds(node: Node) -> Rect2:
	if node == null or not is_instance_valid(node):
		return Rect2()
	var merged := Rect2()
	var has_bounds: bool = false
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is CanvasItem and cur.has_method("get_rect"):
			var rect_any: Variant = cur.call("get_rect")
			if rect_any is Rect2:
				var local_rect: Rect2 = rect_any
				if local_rect.size.x > 0.001 and local_rect.size.y > 0.001:
					var xf: Transform2D = (cur as CanvasItem).get_global_transform_with_canvas()
					var p0: Vector2 = xf * local_rect.position
					var p1: Vector2 = xf * (local_rect.position + Vector2(local_rect.size.x, 0.0))
					var p2: Vector2 = xf * (local_rect.position + local_rect.size)
					var p3: Vector2 = xf * (local_rect.position + Vector2(0.0, local_rect.size.y))
					var min_v: Vector2 = Vector2(minf(minf(p0.x, p1.x), minf(p2.x, p3.x)), minf(minf(p0.y, p1.y), minf(p2.y, p3.y)))
					var max_v: Vector2 = Vector2(maxf(maxf(p0.x, p1.x), maxf(p2.x, p3.x)), maxf(maxf(p0.y, p1.y), maxf(p2.y, p3.y)))
					var world_rect := Rect2(min_v, max_v - min_v)
					if not has_bounds:
						merged = world_rect
						has_bounds = true
					else:
						merged = merged.merge(world_rect)
		for child_any in cur.get_children():
			stack.append(child_any)
	return merged if has_bounds else Rect2()


func _create_rectangle_polygon(size: Vector2) -> PackedVector2Array:
	var half: Vector2 = size * 0.5
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	])


func _create_circle_polygon(radius: float, points: int = 18) -> PackedVector2Array:
	var poly := PackedVector2Array()
	var count: int = maxi(8, points)
	for i in range(count):
		var angle: float = TAU * float(i) / float(count)
		poly.append(Vector2(cos(angle), sin(angle)) * radius)
	return poly



func _get_all_boss_part_nodes(part_name: String, boss_id: int = -1) -> Array[Node]:
	var nodes: Array[Node] = []
	var live_node: Node = _get_boss_part_node(part_name, boss_id)
	if live_node != null and is_instance_valid(live_node):
		nodes.append(live_node)
	if _main == null or not is_instance_valid(_main.obstacles_root):
		return nodes
	for child_any in _main.obstacles_root.get_children():
		var child: Node = child_any
		if child == null or not is_instance_valid(child):
			continue
		if not bool(child.get_meta("is_boss_part", false)):
			continue
		if String(child.get_meta("boss_part_name", "")).strip_edges() != part_name:
			continue
		var node_boss_id: int = int(child.get_meta("boss_id", -1))
		if boss_id >= 0 and node_boss_id >= 0 and node_boss_id != boss_id:
			continue
		if not nodes.has(child):
			nodes.append(child)
	return nodes


func _set_boss_part_destroyed_visual(part_name: String, destroyed: bool, boss_id: int = -1) -> void:
	var nodes: Array[Node] = _get_all_boss_part_nodes(part_name, boss_id)
	if nodes.is_empty():
		return

	for node in nodes:
		node.set_meta("boss_destroyed", destroyed)

		if node is CollisionObject2D:
			(node as CollisionObject2D).collision_layer = 0 if destroyed else LevelConfig.MASK_WALLS
			(node as CollisionObject2D).collision_mask = 0 if destroyed else LevelConfig.MASK_BALL | LevelConfig.MASK_PINS

		_set_collision_descendants_disabled(node, destroyed)

		var swing_root: Node = node.get_node_or_null("SwingRoot")
		if swing_root != null and is_instance_valid(swing_root):
			for child in swing_root.get_children():
				if child is CanvasItem:
					(child as CanvasItem).modulate.a = 0.0 if destroyed else 1.0
		elif node is CanvasItem:
			(node as CanvasItem).modulate.a = 0.0 if destroyed else 1.0

		if destroyed:
			node.set_deferred("visible", false)



func _set_collision_descendants_disabled(node: Node, disabled: bool) -> void:
	if node == null or not is_instance_valid(node):
		return
	for child in node.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).disabled = disabled
		elif child is CollisionPolygon2D:
			(child as CollisionPolygon2D).disabled = disabled
		elif child is Area2D:
			(child as Area2D).monitoring = not disabled
		_set_collision_descendants_disabled(child, disabled)

func _resolve_pending_boss_part_hit_immediately() -> void:
	if _main == null or _main.boss_system == null:
		return
	var pending_hits: Array[Dictionary] = _parse_pending_boss_part_hit_tokens(String(_main._pending_boss_part_hit))
	if pending_hits.is_empty():
		return
	_main._pending_boss_part_hit = ""
	var status_lines: Array[String] = []
	for pending_hit_info in pending_hits:
		var pending_part_hit: String = String(pending_hit_info.get("part_name", "")).strip_edges()
		if pending_part_hit == "":
			continue
		var pending_boss_id: int = int(pending_hit_info.get("boss_id", -1))
		if pending_boss_id < 0 and _main.boss_system.has_method("get_primary_boss_id"):
			pending_boss_id = int(_main.boss_system.get_primary_boss_id())
		if pending_boss_id < 0:
			continue
		var hit_result: Dictionary = _main.boss_system.register_part_hit(pending_part_hit, pending_boss_id)
		if _main.boss_system.has_method("make_hit_status_text"):
			var hit_text: String = String(_main.boss_system.make_hit_status_text(hit_result)).strip_edges()
			if hit_text != "":
				status_lines.append(hit_text)
		if bool(hit_result.get("part_destroyed", false)):
			_hide_boss_part_visual_immediately(pending_part_hit, pending_boss_id)
			call_deferred("_set_boss_part_destroyed_visual", pending_part_hit, true, pending_boss_id)
		if bool(hit_result.get("boss_killed", false)):
			_on_boss_killed_from_grand_map(int(hit_result.get("boss_id", pending_boss_id)))
	refresh_live_boss_map_presentation()
	if not status_lines.is_empty():
		var existing_status_text: String = String(_main.get("_pending_boss_damage_status_text")).strip_edges()
		var damage_status_text: String = "\n".join(status_lines)
		if existing_status_text != "":
			_main.set("_pending_boss_damage_status_text", "%s\n%s" % [existing_status_text, damage_status_text])
		else:
			_main.set("_pending_boss_damage_status_text", damage_status_text)


func _hide_boss_part_visual_immediately(part_name: String, boss_id: int = -1) -> void:
	var nodes: Array[Node] = _get_all_boss_part_nodes(part_name, boss_id)
	for node in nodes:
		node.set_meta("boss_destroyed", true)
		var swing_root: Node = node.get_node_or_null("SwingRoot")
		if swing_root != null and is_instance_valid(swing_root):
			for child in swing_root.get_children():
				if child is CanvasItem:
					(child as CanvasItem).modulate.a = 0.0
		elif node is CanvasItem:
			(node as CanvasItem).modulate.a = 0.0
		node.visible = false


func _find_live_province_node_by_id(province_id: int) -> Node2D:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return null
	for province_node_any in _main.provinces_root.get_children():
		var province_node: Node = province_node_any
		if not is_instance_valid(province_node):
			continue
		if String(province_node.name) == BOSS_VISUAL_ROOT_NAME:
			continue
		if not province_node.has_meta("province_data"):
			continue
		var meta_data: Dictionary = province_node.get_meta("province_data")
		if int(meta_data.get("id", -1)) == province_id:
			return province_node as Node2D
	return null


func _on_boss_part_body_entered(body: Node, part_name: String, boss_id: int = -1) -> void:
	if _main == null or _main.boss_system == null:
		return
	if _main.state != _main.GameState.BALL_IN_FLIGHT:
		return
	if _main._current_phase != LevelConfig.PHASE_GRAND_MAP:
		return
	if not is_instance_valid(body):
		return
	if body != _main.ball:
		return
	_queue_boss_part_hit_from_contact(part_name, boss_id, body)


func _on_boss_killed_from_grand_map(boss_id: int = -1) -> void:
	if _main == null or _main.boss_system == null or _main.province_system == null:
		return
	var resolved_boss_id: int = boss_id
	if resolved_boss_id < 0 and _main.boss_system.has_method("get_primary_boss_id"):
		resolved_boss_id = int(_main.boss_system.get_primary_boss_id())
	var home_id: int = int(_main.boss_system.get_boss_home_province_id(resolved_boss_id))
	var home_idx: int = _main.province_system.find_persistence_index_by_id(home_id)
	if home_idx == -1:
		return
	var home_state: Dictionary = _main._province_persistence[home_idx]
	var friendly_counts: Dictionary = _main.province_system.get_conquered_province_counts(LevelConfig.PROVINCE_TYPE_FRIENDLY)
	home_state["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
	home_state["remaining_troops"] = int(friendly_counts.get("remaining_troops", home_state.get("remaining_troops", 0)))
	home_state["remaining_buildings"] = int(friendly_counts.get("remaining_buildings", home_state.get("remaining_buildings", 0)))
	home_state["invading_troops"] = 0
	home_state["faction_id"] = 0
	home_state["construction_progress"] = 0
	home_state["is_boss_home"] = false
	_main._locked_province_id_after_win = home_id
	if _main.province_system.has_method("mark_province_captured_by_player_engagement"):
		_main.province_system.mark_province_captured_by_player_engagement(home_id)
	if _main.province_system != null:
		_main.province_system.apply_persistence_to_province_visuals()
