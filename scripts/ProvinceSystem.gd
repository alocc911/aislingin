extends RefCounted

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const CAPTURE_SOURCE_NONE := ""
const CAPTURE_SOURCE_PLAYER_ENGAGEMENT := "player_engagement"
const CAPTURE_SOURCE_FRIENDLY_MARCH := "friendly_march"
const BOSS_HOME_FLAG_KEY := "is_boss_home"
const CALTROPS_KEY := "caltrops"
const MAX_ACTIVE_CALTROPS_PER_PROVINCE: int = 5
const PROVINCE_GOLD_PRODUCTION_KEY := "gold_production"
const PROVINCE_FREE_BUILDINGS_KEY := "free_buildings"
const PROVINCE_BUILDING_CAPACITY_KEY := "building_capacity"
const PROVINCE_ENGAGEMENT_MAP_TYPE_KEY := "engagement_map_type"
const PROVINCE_NAME_KEY := "province_name"

const BOSS_HOME_FILL_COLOR := Color(0.62, 0.14, 0.78, 0.62)
const BOSS_HOME_BORDER_COLOR := Color(1.0, 0.54, 0.22, 0.98)
const BOSS_HOME_INNER_GLOW_COLOR := Color(1.0, 0.76, 0.32, 0.72)
const BOSS_HOME_INFO_BOX_BG_COLOR := Color(0.20, 0.08, 0.24, 0.88)
const BOSS_HOME_INFO_TEXT_COLOR := Color(1.0, 0.92, 0.72, 1.0)
const PROVINCE_FILL_Z_INDEX := LevelConfig.VISUAL_LAYER_PROVINCE_FILL
const PROVINCE_BORDERS_Z_INDEX := LevelConfig.VISUAL_LAYER_BORDERS
const PROVINCE_BORDER_OVERLAYS_Z_INDEX := LevelConfig.VISUAL_LAYER_BORDER_OVERLAYS
const PROVINCE_COUNTS_BACKGROUND_Z_INDEX := LevelConfig.VISUAL_LAYER_PROVINCE_INFO_CARDS
const PROVINCE_COUNTS_LABEL_Z_INDEX := LevelConfig.VISUAL_LAYER_PROVINCE_INFO_CARDS + 1
const PROVINCE_TROOP_VISUALS_Z_INDEX := LevelConfig.VISUAL_LAYER_GRAND_MAP_PROVINCE_TROOPS
const PROVINCE_TROOP_VISUALS_ROOT_NAME := "ProvinceTroopVisuals"
const PROVINCE_BUILDING_VISUALS_ROOT_NAME := "ProvinceBuildingVisuals"
const PROVINCE_TROOP_VISUALS_MAX_COUNT: int = 50
const PROVINCE_TROOP_VISUALS_REDUCED_COUNT: int = 24
const PROVINCE_TROOP_VISUALS_ICON_SIZE: float = 3.2
const PROVINCE_TROOP_VISUALS_ICON_SPACING: float = 8.0
const PROVINCE_TROOP_VISUALS_ROW_WIDTH: int = 10
const PROVINCE_TROOP_VISUALS_PILE_MIN_RADIUS_MULTIPLIER: float = 0.35
const PROVINCE_TROOP_VISUALS_PILE_MAX_RADIUS_MULTIPLIER: float = 2.1
const PROVINCE_TROOP_VISUALS_PILE_SWIRL_TURNS: float = 2.55
const PROVINCE_BUILDING_VISUALS_CARD_GAP: float = 8.0
const LOCKED_PROVINCE_INNER_OVERLAY_NAME := "LockedProvinceInnerOverlay"
const LOCKED_PROVINCE_PATTERN_OVERLAY_NAME := "LockedProvincePatternOverlay"
const PROVINCE_INFO_PANEL_TEXTURE_PATH := "res://sprites/province_info_panel.png"
const PROVINCE_OWNER_BADGE_NEUTRAL_TEXTURE_PATH := "res://sprites/province_owner_badge_neutral.png"
const PROVINCE_OWNER_BADGE_FRIENDLY_TEXTURE_PATH := "res://sprites/province_owner_badge_friendly.png"
const PROVINCE_OWNER_BADGE_ENEMY_TEXTURE_PATH := "res://sprites/province_owner_badge_enemy.png"
const RELATION_SELF := "self"
const RELATION_ALLY := "ally"
const RELATION_HOSTILE := "hostile"
const RELATION_NEUTRAL := "neutral"
# Canonical owner-relation semantics for province ownership:
# - RELATION_SELF: player-owned province (friendly type, non-friendly-boss faction id).
# - RELATION_ALLY: non-player friendly ownership (friendly-boss faction).
# - RELATION_HOSTILE: enemy ownership (enemy type, non-friendly-boss faction id).
# - RELATION_NEUTRAL: unowned/neutral province (neutral type, faction_id normalized to 0).
const PROVINCE_ICON_TROOPS_TEXTURE_PATH := "res://sprites/icon_troops.png"
const PROVINCE_ICON_BUILDING_TEXTURE_PATH := "res://sprites/icon_building.png"
const PROVINCE_ICON_GOLD_TEXTURE_PATH := "res://sprites/icon_gold.png"
const PROVINCE_ICON_FREE_BUILDING_TEXTURE_PATH := "res://sprites/icon_free_building.png"
const PROVINCE_ICON_CAP_TEXTURE_PATH := "res://sprites/icon_cap.png"
const PROVINCE_ICON_BIOME_NORMAL_TEXTURE_PATH := "res://sprites/icon_biome_normal.png"
const PROVINCE_ICON_BIOME_JUNGLE_TEXTURE_PATH := "res://sprites/icon_biome_jungle.png"
const PROVINCE_ICON_BIOME_ROCK_TEXTURE_PATH := "res://sprites/icon_biome_rock.png"
const PROVINCE_ICON_BIOME_SETTLEMENT_TEXTURE_PATH := "res://sprites/icon_biome_settlement.png"
const PROVINCE_INFO_PANEL_ROOT_NAME := "ProvinceInfoPanelRoot"
const PROVINCE_INFO_PANEL_BG_NAME := "ProvinceInfoPanelTexture"
const PROVINCE_INFO_PANEL_OWNER_BADGE_NAME := "ProvinceOwnerBadge"
const PROVINCE_INFO_PANEL_BIOME_ICON_NAME := "ProvinceBiomeIcon"
const PROVINCE_INFO_PANEL_OWNER_LABEL_NAME := "ProvinceOwnerLabel"
const PROVINCE_INFO_PANEL_NAME_LABEL_NAME := "ProvinceNameLabel"
const PROVINCE_INFO_PANEL_TROOPS_ICON_NAME := "ProvinceTroopsIcon"
const PROVINCE_INFO_PANEL_TROOPS_LABEL_NAME := "ProvinceTroopsLabel"
const PROVINCE_INFO_PANEL_BUILDINGS_ICON_NAME := "ProvinceBuildingsIcon"
const PROVINCE_INFO_PANEL_BUILDINGS_LABEL_NAME := "ProvinceBuildingsLabel"
const PROVINCE_INFO_PANEL_GOLD_ICON_NAME := "ProvinceGoldIcon"
const PROVINCE_INFO_PANEL_GOLD_LABEL_NAME := "ProvinceGoldLabel"
const PROVINCE_INFO_PANEL_FREE_ICON_NAME := "ProvinceFreeIcon"
const PROVINCE_INFO_PANEL_FREE_LABEL_NAME := "ProvinceFreeLabel"
const PROVINCE_INFO_PANEL_CAP_ICON_NAME := "ProvinceCapIcon"
const PROVINCE_INFO_PANEL_CAP_LABEL_NAME := "ProvinceCapLabel"
const PROVINCE_INFO_PANEL_DESIRED_WIDTH: float = 190.0
const PROVINCE_INFO_PANEL_FALLBACK_HEIGHT: float = 94.0
const FRIENDLY_BOSS_FACTION_DISPLAY_COLOR := Color(0.95, 0.84, 0.22, 0.45)
const FACTION_NAME_ID_OFFSET: int = 1000000
const ENABLE_LAUNCH_PROVINCE_PULSE: bool = false
const LAUNCH_PULSE_QUANTIZE_STEP_SECONDS: float = 0.10

var _main: Node = null
var _province_ui_texture_cache: Dictionary = {}
var _province_owner_badge_fill_shader: Shader = null
var _province_node_cache_dirty: bool = true
var _cached_province_nodes: Array = []
var _province_node_by_id: Dictionary = {}
var _last_locked_launch_province_id: int = -1
var _shared_border_overlay_geometry_signature: int = 0
var _shared_border_overlay_cached_display_runs: Array = []
var _faction_name_cache: Dictionary = {}
var _launch_pulse_last_quantized_step: int = -1
var _locked_province_pattern_texture: Texture2D = null
var _locked_province_pattern_texture_cell_size: int = -1

class ProvinceTroopVisual extends Node2D:
	var icon_size: float = PROVINCE_TROOP_VISUALS_ICON_SIZE
	var icon_color: Color = Color.WHITE
	var icon_opacity: float = 1.0

	func update_visual(new_icon_size: float, new_icon_color: Color, new_icon_opacity: float) -> void:
		icon_size = maxf(0.5, new_icon_size)
		icon_color = new_icon_color
		icon_opacity = clampf(new_icon_opacity, 0.05, 1.0)
		queue_redraw()

	func _draw() -> void:
		var draw_color: Color = icon_color
		draw_color.a *= icon_opacity
		var stroke: float = maxf(1.0, icon_size * 0.24)
		var outline_stroke: float = stroke * 1.9
		var outline_color: Color = Color.BLACK
		outline_color.a = draw_color.a
		var head_center: Vector2 = Vector2(0.0, -icon_size * 0.58)
		var neck_y: float = -icon_size * 0.34
		var hip_y: float = icon_size * 0.30
		draw_circle(head_center, icon_size * 0.33, outline_color)
		draw_line(Vector2(0.0, neck_y), Vector2(0.0, hip_y), outline_color, outline_stroke, true)
		draw_line(Vector2(-icon_size * 0.38, -icon_size * 0.05), Vector2(icon_size * 0.38, -icon_size * 0.05), outline_color, outline_stroke * 0.85, true)
		draw_line(Vector2(0.0, hip_y), Vector2(-icon_size * 0.28, icon_size * 0.88), outline_color, outline_stroke * 0.85, true)
		draw_line(Vector2(0.0, hip_y), Vector2(icon_size * 0.28, icon_size * 0.88), outline_color, outline_stroke * 0.85, true)
		draw_circle(head_center, icon_size * 0.24, draw_color)
		draw_line(Vector2(0.0, neck_y), Vector2(0.0, hip_y), draw_color, stroke, true)
		draw_line(Vector2(-icon_size * 0.38, -icon_size * 0.05), Vector2(icon_size * 0.38, -icon_size * 0.05), draw_color, stroke * 0.85, true)
		draw_line(Vector2(0.0, hip_y), Vector2(-icon_size * 0.28, icon_size * 0.88), draw_color, stroke * 0.85, true)
		draw_line(Vector2(0.0, hip_y), Vector2(icon_size * 0.28, icon_size * 0.88), draw_color, stroke * 0.85, true)

class ProvinceBuildingVisual extends Node2D:
	var icon_size: float = PROVINCE_TROOP_VISUALS_ICON_SIZE
	var icon_color: Color = Color.WHITE
	var icon_opacity: float = 1.0

	func update_visual(new_icon_size: float, new_icon_color: Color, new_icon_opacity: float) -> void:
		icon_size = maxf(0.5, new_icon_size)
		icon_color = new_icon_color
		icon_opacity = clampf(new_icon_opacity, 0.05, 1.0)
		queue_redraw()

	func _draw() -> void:
		var draw_color: Color = icon_color
		draw_color.a *= icon_opacity
		var outline_color: Color = Color.BLACK
		outline_color.a = draw_color.a
		var half_w: float = icon_size * 0.42
		var body_top: float = -icon_size * 0.18
		var body_bottom: float = icon_size * 0.55
		var roof_peak: Vector2 = Vector2(0.0, -icon_size * 0.70)
		var roof_left: Vector2 = Vector2(-half_w * 1.12, body_top)
		var roof_right: Vector2 = Vector2(half_w * 1.12, body_top)
		var body_rect := Rect2(Vector2(-half_w, body_top), Vector2(half_w * 2.0, body_bottom - body_top))
		var door_rect := Rect2(Vector2(-icon_size * 0.12, icon_size * 0.10), Vector2(icon_size * 0.24, icon_size * 0.45))
		draw_polygon(PackedVector2Array([roof_peak, roof_right, roof_left]), [outline_color])
		draw_rect(body_rect.grow(0.85), outline_color, true)
		draw_polygon(PackedVector2Array([roof_peak, roof_right, roof_left]), [draw_color])
		draw_rect(body_rect, draw_color, true)
		var door_color: Color = Color(0.16, 0.12, 0.08, draw_color.a)
		draw_rect(door_rect, door_color, true)



func setup(main_node: Node) -> void:
	_main = main_node
	_province_node_cache_dirty = true
	_cached_province_nodes.clear()
	_province_node_by_id.clear()
	_last_locked_launch_province_id = -1
	_shared_border_overlay_geometry_signature = 0
	_shared_border_overlay_cached_display_runs.clear()
	_faction_name_cache.clear()


func _mark_province_node_cache_dirty() -> void:
	_province_node_cache_dirty = true


func _is_cached_province_node_live(province_node: Variant) -> bool:
	if province_node == null:
		return false
	if not (province_node is Object):
		return false
	if not is_instance_valid(province_node):
		return false
	if not (province_node is Node):
		return false
	if _main == null or not is_instance_valid(_main.provinces_root):
		return false
	var node: Node = province_node
	return node.get_parent() == _main.provinces_root and node.has_meta("province_data")


func _rebuild_province_node_cache() -> void:
	_cached_province_nodes.clear()
	_province_node_by_id.clear()
	if _main == null or not is_instance_valid(_main.provinces_root):
		_province_node_cache_dirty = false
		return
	for child_any in _main.provinces_root.get_children():
		var province_node: Node = child_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		if province_node.name == "SharedProvinceBorderOverlay":
			continue
		if not province_node.has_meta("province_data"):
			continue
		_cached_province_nodes.append(province_node)
		var province_meta: Dictionary = province_node.get_meta("province_data")
		var province_id: int = int(province_meta.get("id", -1))
		if province_id >= 0:
			_province_node_by_id[province_id] = province_node
	_province_node_cache_dirty = false


func _get_expected_cached_province_node_count() -> int:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return 0
	var count: int = 0
	for child_any in _main.provinces_root.get_children():
		var province_node: Node = child_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		if province_node.name == "SharedProvinceBorderOverlay":
			continue
		if not province_node.has_meta("province_data"):
			continue
		count += 1
	return count


func _get_cached_province_nodes() -> Array:
	if _province_node_cache_dirty:
		_rebuild_province_node_cache()
	elif _cached_province_nodes.size() != _get_expected_cached_province_node_count():
		_rebuild_province_node_cache()
	else:
		for province_node in _cached_province_nodes:
			if not _is_cached_province_node_live(province_node):
				_rebuild_province_node_cache()
				break
	return _cached_province_nodes


func _get_cached_province_node_by_id(province_id: int) -> Node:
	if province_id < 0:
		return null
	_get_cached_province_nodes()
	var province_node_any: Variant = _province_node_by_id.get(province_id, null)
	if _is_cached_province_node_live(province_node_any):
		return province_node_any as Node
	_rebuild_province_node_cache()
	province_node_any = _province_node_by_id.get(province_id, null)
	return province_node_any as Node if _is_cached_province_node_live(province_node_any) else null


func _compute_polygon_signature(poly: PackedVector2Array) -> int:
	var hash_value: int = poly.size() * 486187739
	for point in poly:
		var px: int = int(round(point.x * 100.0))
		var py: int = int(round(point.y * 100.0))
		hash_value = int(hash("%d|%d|%d" % [hash_value, px, py])) & 0x7fffffff
	return hash_value


func _ensure_cached_province_display_geometry(province_node: Node, fill_node: Polygon2D) -> Dictionary:
	if province_node == null or not is_instance_valid(province_node) or fill_node == null:
		return {
			"border_points": PackedVector2Array(),
			"inner_points": PackedVector2Array()
		}
	var polygon_signature: int = _compute_polygon_signature(fill_node.polygon)
	var cached_signature: int = int(province_node.get_meta("province_display_geometry_signature") if province_node.has_meta("province_display_geometry_signature") else -1)
	var cached_border: PackedVector2Array = province_node.get_meta("province_display_border_points") if province_node.has_meta("province_display_border_points") else PackedVector2Array()
	var cached_inner: PackedVector2Array = province_node.get_meta("province_display_inner_points") if province_node.has_meta("province_display_inner_points") else PackedVector2Array()
	if cached_signature == polygon_signature and cached_border.size() > 0 and cached_inner.size() > 0:
		return {
			"border_points": cached_border,
			"inner_points": cached_inner
		}
	var border_points: PackedVector2Array = make_smoothed_province_display_polyline(fill_node.polygon, maxf(0.5, get_province_outer_line_width() * 0.5))
	var inner_points: PackedVector2Array = make_smoothed_province_display_polyline(fill_node.polygon, maxf(0.5, get_province_outer_line_width() * 0.5 + get_province_inner_line_inset()))
	province_node.set_meta("province_display_geometry_signature", polygon_signature)
	province_node.set_meta("province_display_border_points", border_points)
	province_node.set_meta("province_display_inner_points", inner_points)
	return {
		"border_points": border_points,
		"inner_points": inner_points
	}


func _compute_shared_border_overlay_geometry_signature(province_nodes: Array) -> int:
	var hash_value: int = province_nodes.size() * 92821
	for province_node_any in province_nodes:
		var province_node: Node = province_node_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		var province_meta: Dictionary = province_node.get_meta("province_data") if province_node.has_meta("province_data") else {}
		var province_id: int = int(province_meta.get("id", -1))
		var logical_poly: PackedVector2Array = _ensure_polygon_ccw(_get_logical_province_polygon(province_node))
		hash_value = int(hash("%d|%d|%d" % [hash_value, province_id, _compute_polygon_signature(logical_poly)])) & 0x7fffffff
	return hash_value


func _build_cached_shared_border_display_runs(province_nodes: Array) -> Array:
	var province_centers: Dictionary = {}
	for province_node_any in province_nodes:
		var province_node: Node = province_node_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		var province_data: Dictionary = province_node.get_meta("province_data") if province_node.has_meta("province_data") else {}
		var province_id: int = int(province_data.get("id", -1))
		var logical_poly: PackedVector2Array = _ensure_polygon_ccw(_get_logical_province_polygon(province_node))
		province_centers[province_id] = _get_province_center_from_polygon(logical_poly)
	var border_graph: Dictionary = _collect_province_border_segments(province_nodes)
	var raw_display_runs: Array = _collect_shared_border_display_runs(border_graph, province_centers)
	var cached_runs: Array = []
	var center_inset: float = get_province_shared_border_center_inset()
	for raw_run_any in raw_display_runs:
		var run_data: Dictionary = raw_run_any
		var raw_points: PackedVector2Array = run_data.get("points", PackedVector2Array())
		var closed: bool = bool(run_data.get("closed", false))
		var center_points: PackedVector2Array = _build_shared_border_centerline(raw_points, closed)
		if closed:
			if center_points.size() < 3:
				continue
		else:
			if center_points.size() < 2:
				continue
		var left_points: PackedVector2Array = _build_shared_border_side_line(center_points, center_inset, closed)
		var right_points: PackedVector2Array = _build_shared_border_side_line(center_points, -center_inset, closed)
		cached_runs.append({
			"left_id": int(run_data.get("left_id", -1)),
			"right_id": int(run_data.get("right_id", -1)),
			"closed": closed,
			"left_points": left_points,
			"right_points": right_points
		})
	return cached_runs


func _set_province_inner_glow_visible(province_id: int, visible: bool) -> void:
	var province_node: Node = _get_cached_province_node_by_id(province_id)
	if province_node == null:
		return
	var inner_glow: Line2D = get_province_inner_glow_node(province_node)
	if inner_glow != null:
		inner_glow.visible = visible


func _set_active_locked_launch_province(active_locked_id: int) -> void:
	if _last_locked_launch_province_id == active_locked_id:
		return
	if _last_locked_launch_province_id >= 0:
		_set_province_inner_glow_visible(_last_locked_launch_province_id, false)
	_last_locked_launch_province_id = active_locked_id


func _set_canvas_item_layer(item: CanvasItem, layer_value: int, relative: bool = false) -> void:
	if item == null:
		return
	item.z_as_relative = relative
	item.z_index = layer_value


func _make_empty_province_context(province_id: int = -1) -> Dictionary:
	return {
		"id": province_id,
		"type": LevelConfig.PROVINCE_TYPE_NEUTRAL,
		"remaining_troops": 0,
		"remaining_buildings": 0,
		"invading_troops": 0,
		"faction_id": 0,
		"construction_progress": 0,
		"is_target": false,
		"capture_source": CAPTURE_SOURCE_NONE,
		"neighbors": [],
		"is_boss_home": false,
		"caltrops": [],
		"active_caltrop_count": 0,
		"gold_production": 0,
		"free_buildings": 0,
		"building_capacity": LevelConfig.PROVINCE_BUILDING_CAP_MIN,
		"engagement_map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL,
		PROVINCE_NAME_KEY: ""
	}


func _normalize_caltrop_entries(raw_entries) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if raw_entries is Array:
		for entry_any in raw_entries:
			if not (entry_any is Dictionary):
				continue
			var entry: Dictionary = entry_any
			var caltrop_id: int = int(entry.get("id", -1))
			if caltrop_id < 0:
				continue
			var seed: int = int(entry.get("seed", 0))
			if seed == 0:
				seed = caltrop_id + 1
			out.append({
				"id": caltrop_id,
				"seed": seed,
				"destroyed": bool(entry.get("destroyed", false)),
				"is_friendly": bool(entry.get("is_friendly", false))
			})
	return out


func _make_province_variation_rng(province_id: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var map_seed: int = 1
	if _main != null:
		map_seed = maxi(1, int(_main.map_seed))
	var mixed: int = int(hash("%d|province_variation|%d|%d" % [map_seed, province_id, LevelConfig.GRAND_MAP_PROVINCE_VARIATION]))
	mixed = mixed & 0x7fffffff
	if mixed == 0:
		mixed = (province_id + 1) * 15485863
	rng.seed = mixed
	return rng


func _roll_province_variation(province_id: int) -> Dictionary:
	var rng: RandomNumberGenerator = _make_province_variation_rng(province_id)
	var engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
	if not LevelConfig.ENGAGEMENT_MAP_TYPE_VALUES.is_empty():
		var map_type_idx: int = rng.randi_range(0, LevelConfig.ENGAGEMENT_MAP_TYPE_VALUES.size() - 1)
		engagement_map_type = String(LevelConfig.ENGAGEMENT_MAP_TYPE_VALUES[map_type_idx])
	return {
		PROVINCE_GOLD_PRODUCTION_KEY: rng.randi_range(LevelConfig.PROVINCE_GOLD_PRODUCTION_MIN, LevelConfig.PROVINCE_GOLD_PRODUCTION_MAX),
		PROVINCE_FREE_BUILDINGS_KEY: rng.randi_range(LevelConfig.PROVINCE_FREE_BUILDINGS_MIN, LevelConfig.PROVINCE_FREE_BUILDINGS_MAX),
		PROVINCE_BUILDING_CAPACITY_KEY: rng.randi_range(LevelConfig.PROVINCE_BUILDING_CAP_MIN, LevelConfig.PROVINCE_BUILDING_CAP_MAX),
		PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: engagement_map_type
	}


func normalize_province_variation_state(province_id: int, province_state: Dictionary) -> Dictionary:
	var rolled: Dictionary = _roll_province_variation(province_id)
	province_state[PROVINCE_GOLD_PRODUCTION_KEY] = LevelConfig.clamp_province_gold_production(int(province_state.get(PROVINCE_GOLD_PRODUCTION_KEY, rolled.get(PROVINCE_GOLD_PRODUCTION_KEY, 0))))
	province_state[PROVINCE_FREE_BUILDINGS_KEY] = LevelConfig.clamp_province_free_buildings(int(province_state.get(PROVINCE_FREE_BUILDINGS_KEY, rolled.get(PROVINCE_FREE_BUILDINGS_KEY, 0))))
	province_state[PROVINCE_BUILDING_CAPACITY_KEY] = LevelConfig.clamp_province_building_cap(int(province_state.get(PROVINCE_BUILDING_CAPACITY_KEY, rolled.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN))))
	province_state[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = LevelConfig.normalize_engagement_map_type(String(province_state.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, rolled.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL))))
	return province_state


func get_province_gold_production(province_state: Dictionary) -> int:
	return LevelConfig.clamp_province_gold_production(int(province_state.get(PROVINCE_GOLD_PRODUCTION_KEY, 0)))


func get_province_free_buildings(province_state: Dictionary) -> int:
	return LevelConfig.clamp_province_free_buildings(int(province_state.get(PROVINCE_FREE_BUILDINGS_KEY, 0)))


func get_province_building_capacity(province_state: Dictionary) -> int:
	return LevelConfig.clamp_province_building_cap(int(province_state.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN)))


func get_province_engagement_map_type(province_state: Dictionary) -> String:
	return LevelConfig.normalize_engagement_map_type(String(province_state.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)))


func get_province_map_type_info_text(province_state: Dictionary) -> String:
	match get_province_engagement_map_type(province_state):
		LevelConfig.ENGAGEMENT_MAP_TYPE_JUNGLE:
			return "Jungle"
		LevelConfig.ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING:
			return "Rock Outcrop"
		LevelConfig.ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return "Settlement"
		_:
			return "Normal"




func _get_trimmed_ui_texture(path: String) -> Texture2D:
	if _province_ui_texture_cache.has(path):
		return _province_ui_texture_cache[path]
	var loaded = load(path)
	if loaded == null or not (loaded is Texture2D):
		_province_ui_texture_cache[path] = null
		return null
	var texture: Texture2D = loaded as Texture2D
	var trimmed: Texture2D = texture
	var image: Image = texture.get_image()
	if image != null:
		var used_rect: Rect2i = image.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0 and (used_rect.position.x != 0 or used_rect.position.y != 0 or used_rect.size.x != image.get_width() or used_rect.size.y != image.get_height()):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(float(used_rect.position.x), float(used_rect.position.y), float(used_rect.size.x), float(used_rect.size.y))
			trimmed = atlas
	_province_ui_texture_cache[path] = trimmed
	return trimmed


func _get_province_panel_icon_texture(path: String) -> Texture2D:
	if LevelConfig.PROVINCE_INFO_PANEL_TRIM_ICON_TEXTURES:
		return _get_trimmed_ui_texture(path)
	var loaded = load(path)
	return loaded as Texture2D if loaded is Texture2D else null


func _get_province_panel_stat_icon_scale(icon_name: String) -> float:
	match icon_name:
		PROVINCE_INFO_PANEL_TROOPS_ICON_NAME:
			return LevelConfig.PROVINCE_INFO_PANEL_TROOPS_ICON_SCALE
		PROVINCE_INFO_PANEL_BUILDINGS_ICON_NAME:
			return LevelConfig.PROVINCE_INFO_PANEL_BUILDINGS_ICON_SCALE
		PROVINCE_INFO_PANEL_GOLD_ICON_NAME:
			return LevelConfig.PROVINCE_INFO_PANEL_GOLD_ICON_SCALE
		PROVINCE_INFO_PANEL_FREE_ICON_NAME:
			return LevelConfig.PROVINCE_INFO_PANEL_FREE_ICON_SCALE
		PROVINCE_INFO_PANEL_CAP_ICON_NAME:
			return LevelConfig.PROVINCE_INFO_PANEL_CAP_ICON_SCALE
		_:
			return LevelConfig.PROVINCE_INFO_PANEL_STAT_ICON_SCALE_DEFAULT


func _layout_province_panel_icon(icon: TextureRect, position: Vector2, slot_size: Vector2, visual_scale: float = 1.0) -> void:
	if icon == null:
		return
	var safe_slot := Vector2(maxf(1.0, slot_size.x), maxf(1.0, slot_size.y))
	var safe_scale: float = clampf(visual_scale, 0.05, 1.0)
	var visual_size := safe_slot * safe_scale
	icon.position = position + (safe_slot - visual_size) * 0.5
	icon.size = visual_size
	icon.custom_minimum_size = Vector2.ZERO
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.clip_contents = true
	if LevelConfig.PROVINCE_INFO_PANEL_FORCE_ICON_IGNORE_TEXTURE_SIZE:
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	else:
		icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _configure_panel_icon(icon: TextureRect, texture_path: String, position: Vector2, size: Vector2, visual_scale: float = 1.0) -> void:
	if icon == null:
		return
	icon.texture = _get_province_panel_icon_texture(texture_path)
	icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_layout_province_panel_icon(icon, position, size, visual_scale)


func _get_province_info_panel_size() -> Vector2:
	var desired_width: float = maxf(64.0, LevelConfig.PROVINCE_INFO_PANEL_DESIRED_WIDTH)
	var fallback_height: float = maxf(48.0, LevelConfig.PROVINCE_INFO_PANEL_FALLBACK_HEIGHT)
	var panel_texture: Texture2D = _get_trimmed_ui_texture(PROVINCE_INFO_PANEL_TEXTURE_PATH)
	if panel_texture == null:
		return Vector2(desired_width, fallback_height)
	var texture_size: Vector2 = panel_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2(desired_width, fallback_height)
	var scaled_height: float = desired_width * (texture_size.y / texture_size.x)
	return Vector2(desired_width, maxf(fallback_height, scaled_height))


func _get_province_info_panel_root(province_node: Node) -> Control:
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is Control and String(child.name) == PROVINCE_INFO_PANEL_ROOT_NAME:
			return child as Control
	return null


func _get_province_owner_badge_texture_path(province_state: Dictionary) -> String:
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	match province_type:
		LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return PROVINCE_OWNER_BADGE_FRIENDLY_TEXTURE_PATH
		LevelConfig.PROVINCE_TYPE_ENEMY:
			return PROVINCE_OWNER_BADGE_ENEMY_TEXTURE_PATH
		_:
			return PROVINCE_OWNER_BADGE_NEUTRAL_TEXTURE_PATH

func _get_province_owner_badge_fill_color(province_state: Dictionary) -> Color:
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var faction_id: int = int(province_state.get("faction_id", 0))
	match province_type:
		LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return LevelConfig.color_with_alpha(LevelConfig.PROVINCE_FRIENDLY_FILL_RGB, 1.0)
		LevelConfig.PROVINCE_TYPE_ENEMY:
			return LevelConfig.color_with_alpha(_get_enemy_faction_display_color(faction_id), 1.0)
		_:
			return LevelConfig.color_with_alpha(LevelConfig.PROVINCE_NEUTRAL_BORDER_COLOR, 1.0)


func _get_province_owner_badge_fill_shader() -> Shader:
	if _province_owner_badge_fill_shader != null:
		return _province_owner_badge_fill_shader
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float white_threshold = 0.82;
uniform float chroma_threshold = 0.18;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float max_c = max(tex.r, max(tex.g, tex.b));
	float min_c = min(tex.r, min(tex.g, tex.b));
	float chroma = max_c - min_c;
	bool tint_fill = tex.a > 0.001 && min_c >= white_threshold && chroma <= chroma_threshold;
	if (tint_fill) {
		float value = clamp((tex.r + tex.g + tex.b) / 3.0, 0.0, 1.0);
		vec3 shaded = clamp(fill_color.rgb * mix(0.82, 1.05, value), 0.0, 1.0);
		COLOR = vec4(shaded, tex.a * fill_color.a);
	} else {
		COLOR = tex;
	}
}
"""
	_province_owner_badge_fill_shader = shader
	return _province_owner_badge_fill_shader


func _apply_province_owner_badge_fill(icon: TextureRect, province_state: Dictionary) -> void:
	if icon == null:
		return
	var material := icon.material as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		icon.material = material
	material.shader = _get_province_owner_badge_fill_shader()
	material.set_shader_parameter("fill_color", _get_province_owner_badge_fill_color(province_state))


func _get_province_biome_texture_path(province_state: Dictionary) -> String:
	match get_province_engagement_map_type(province_state):
		LevelConfig.ENGAGEMENT_MAP_TYPE_JUNGLE:
			return PROVINCE_ICON_BIOME_JUNGLE_TEXTURE_PATH
		LevelConfig.ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING:
			return PROVINCE_ICON_BIOME_ROCK_TEXTURE_PATH
		LevelConfig.ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return PROVINCE_ICON_BIOME_SETTLEMENT_TEXTURE_PATH
		_:
			return PROVINCE_ICON_BIOME_NORMAL_TEXTURE_PATH


func _get_province_panel_owner_line(province_state: Dictionary) -> String:
	var parts: Array[String] = []
	if is_target_province_state(province_state):
		parts.append(LevelConfig.TARGET_PROVINCE_LABEL_TEXT)
	parts.append(get_province_owner_text(province_state))
	var invading_troops: int = int(province_state.get("invading_troops", 0))
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
		parts.append("Inv %d" % invading_troops)
	return " • ".join(parts)


func _configure_panel_label(label: Label, font_size: int, font_color: Color, h_align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if label == null:
		return
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.horizontal_alignment = h_align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_constant_override("outline_size", max(1, LevelConfig.PROVINCE_INFO_OUTLINE_SIZE))
	label.add_theme_color_override("font_outline_color", LevelConfig.PROVINCE_INFO_OUTLINE_COLOR)


func _get_province_info_panel_bg_modulate(province_state: Dictionary) -> Color:
	var panel_alpha: float = LevelConfig.get_province_info_panel_bg_alpha()
	if is_boss_home_province_state(province_state):
		return Color(1.0, 0.94, 0.94, panel_alpha)
	if is_target_province_state(province_state):
		return Color(1.0, 0.98, 0.92, panel_alpha)
	return Color(1.0, 1.0, 1.0, panel_alpha)


func _refresh_province_info_panel(panel_root: Control, province_id: int, province_state: Dictionary) -> void:
	if panel_root == null:
		return
	var panel_size: Vector2 = _get_province_info_panel_size()
	panel_root.size = panel_size

	var bg: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_BG_NAME) as TextureRect
	if bg != null:
		bg.texture = _get_trimmed_ui_texture(PROVINCE_INFO_PANEL_TEXTURE_PATH)
		bg.position = Vector2.ZERO
		bg.size = panel_size
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.modulate = _get_province_info_panel_bg_modulate(province_state)

	var owner_badge: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_OWNER_BADGE_NAME) as TextureRect
	_configure_panel_icon(owner_badge, _get_province_owner_badge_texture_path(province_state), LevelConfig.PROVINCE_INFO_PANEL_OWNER_BADGE_POS, LevelConfig.PROVINCE_INFO_PANEL_OWNER_BADGE_SLOT_SIZE, LevelConfig.PROVINCE_INFO_PANEL_OWNER_BADGE_SCALE)
	_apply_province_owner_badge_fill(owner_badge, province_state)

	var biome_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_BIOME_ICON_NAME) as TextureRect
	var biome_slot_size: Vector2 = LevelConfig.PROVINCE_INFO_PANEL_BIOME_ICON_SLOT_SIZE
	var biome_pos := Vector2(panel_size.x - LevelConfig.PROVINCE_INFO_PANEL_BIOME_ICON_RIGHT_MARGIN - biome_slot_size.x, LevelConfig.PROVINCE_INFO_PANEL_BIOME_ICON_TOP)
	_configure_panel_icon(biome_icon, _get_province_biome_texture_path(province_state), biome_pos, biome_slot_size, LevelConfig.PROVINCE_INFO_PANEL_BIOME_ICON_SCALE)

	var stat_y: float = panel_size.y - LevelConfig.PROVINCE_INFO_PANEL_STAT_ROW_BOTTOM_MARGIN
	var icon_offsets: Array = LevelConfig.PROVINCE_INFO_PANEL_STAT_ICON_X_OFFSETS.duplicate()
	while icon_offsets.size() < 5:
		icon_offsets.append(10.0 + float(icon_offsets.size()) * 35.0)
	var stat_icon_size: Vector2 = LevelConfig.PROVINCE_INFO_PANEL_STAT_ICON_SLOT_SIZE

	var troops_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_TROOPS_ICON_NAME) as TextureRect
	_configure_panel_icon(troops_icon, PROVINCE_ICON_TROOPS_TEXTURE_PATH, Vector2(float(icon_offsets[0]), stat_y), stat_icon_size, _get_province_panel_stat_icon_scale(PROVINCE_INFO_PANEL_TROOPS_ICON_NAME))

	var buildings_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_BUILDINGS_ICON_NAME) as TextureRect
	_configure_panel_icon(buildings_icon, PROVINCE_ICON_BUILDING_TEXTURE_PATH, Vector2(float(icon_offsets[1]), stat_y), stat_icon_size, _get_province_panel_stat_icon_scale(PROVINCE_INFO_PANEL_BUILDINGS_ICON_NAME))

	var gold_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_GOLD_ICON_NAME) as TextureRect
	_configure_panel_icon(gold_icon, PROVINCE_ICON_GOLD_TEXTURE_PATH, Vector2(float(icon_offsets[2]), stat_y), stat_icon_size, _get_province_panel_stat_icon_scale(PROVINCE_INFO_PANEL_GOLD_ICON_NAME))

	var free_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_FREE_ICON_NAME) as TextureRect
	_configure_panel_icon(free_icon, PROVINCE_ICON_FREE_BUILDING_TEXTURE_PATH, Vector2(float(icon_offsets[3]), stat_y), stat_icon_size, _get_province_panel_stat_icon_scale(PROVINCE_INFO_PANEL_FREE_ICON_NAME))

	var cap_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_CAP_ICON_NAME) as TextureRect
	_configure_panel_icon(cap_icon, PROVINCE_ICON_CAP_TEXTURE_PATH, Vector2(float(icon_offsets[4]), stat_y), stat_icon_size, _get_province_panel_stat_icon_scale(PROVINCE_INFO_PANEL_CAP_ICON_NAME))

	var owner_color: Color = LevelConfig.PROVINCE_INFO_TEXT_COLOR
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if is_boss_home_province_state(province_state):
		owner_color = BOSS_HOME_INFO_TEXT_COLOR
	elif province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		owner_color = Color(0.88, 0.98, 0.88, 1.0)
	elif province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		owner_color = Color(1.0, 0.90, 0.82, 1.0)

	var owner_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_OWNER_LABEL_NAME) as Label
	if owner_label != null:
		owner_label.position = LevelConfig.PROVINCE_INFO_PANEL_OWNER_LABEL_POS
		owner_label.size = Vector2(maxf(24.0, panel_size.x - LevelConfig.PROVINCE_INFO_PANEL_OWNER_LABEL_POS.x - LevelConfig.PROVINCE_INFO_PANEL_OWNER_LABEL_RIGHT_MARGIN), 16.0)
		_configure_panel_label(owner_label, max(11, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE - 5), owner_color, HORIZONTAL_ALIGNMENT_LEFT)
		owner_label.text = _get_province_panel_owner_line(province_state)

	var name_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_NAME_LABEL_NAME) as Label
	if name_label != null:
		name_label.position = LevelConfig.PROVINCE_INFO_PANEL_NAME_LABEL_POS
		name_label.size = Vector2(maxf(24.0, panel_size.x - LevelConfig.PROVINCE_INFO_PANEL_NAME_LABEL_POS.x - LevelConfig.PROVINCE_INFO_PANEL_NAME_LABEL_RIGHT_MARGIN), 24.0)
		_configure_panel_label(name_label, max(13, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE - 1), LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		name_label.text = get_province_display_name(province_id, province_state)

	var label_y: float = stat_y + LevelConfig.PROVINCE_INFO_PANEL_STAT_LABEL_Y_OFFSET
	var value_offset_x: float = LevelConfig.PROVINCE_INFO_PANEL_STAT_VALUE_OFFSET_X
	var value_width: float = LevelConfig.PROVINCE_INFO_PANEL_STAT_VALUE_WIDTH
	var stat_font_size: int = max(11, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE - 3)

	var troops_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_TROOPS_LABEL_NAME) as Label
	if troops_label != null:
		troops_label.position = Vector2(float(icon_offsets[0]) + value_offset_x, label_y)
		troops_label.size = Vector2(value_width, 18.0)
		_configure_panel_label(troops_label, stat_font_size, LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		troops_label.text = str(maxi(0, int(province_state.get("remaining_troops", 0))))

	var buildings_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_BUILDINGS_LABEL_NAME) as Label
	if buildings_label != null:
		buildings_label.position = Vector2(float(icon_offsets[1]) + value_offset_x, label_y)
		buildings_label.size = Vector2(value_width, 18.0)
		_configure_panel_label(buildings_label, stat_font_size, LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		buildings_label.text = str(maxi(0, int(province_state.get("remaining_buildings", 0))))

	var gold_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_GOLD_LABEL_NAME) as Label
	if gold_label != null:
		gold_label.position = Vector2(float(icon_offsets[2]) + value_offset_x, label_y)
		gold_label.size = Vector2(value_width, 18.0)
		_configure_panel_label(gold_label, stat_font_size, LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		gold_label.text = str(get_province_gold_production(province_state))

	var free_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_FREE_LABEL_NAME) as Label
	if free_label != null:
		free_label.position = Vector2(float(icon_offsets[3]) + value_offset_x, label_y)
		free_label.size = Vector2(value_width + 4.0, 18.0)
		_configure_panel_label(free_label, stat_font_size, LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		free_label.text = "+%d" % get_province_free_buildings(province_state)

	var cap_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_CAP_LABEL_NAME) as Label
	if cap_label != null:
		cap_label.position = Vector2(float(icon_offsets[4]) + value_offset_x, label_y)
		cap_label.size = Vector2(value_width + 2.0, 18.0)
		_configure_panel_label(cap_label, stat_font_size, LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		cap_label.text = str(get_province_building_capacity(province_state))


func clamp_province_buildings_to_capacity(province_state: Dictionary) -> void:
	var building_capacity: int = get_province_building_capacity(province_state)
	province_state["remaining_buildings"] = clampi(int(province_state.get("remaining_buildings", 0)), 0, building_capacity)


func get_province_variation_info_lines(province_state: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	lines.append("Gold:%d  Free:+%d" % [get_province_gold_production(province_state), get_province_free_buildings(province_state)])
	lines.append("Cap:%d" % get_province_building_capacity(province_state))
	lines.append("Map:%s" % get_province_map_type_info_text(province_state))
	return lines


func _make_caltrop_spawn_seed(province_id: int, caltrop_id: int, gen_rng: RandomNumberGenerator = null) -> int:
	var salt: int = 0
	if gen_rng != null:
		salt = int(gen_rng.randi())
	var map_seed: int = 1
	var turn_number: int = 0
	if _main != null:
		map_seed = maxi(1, int(_main.map_seed))
		turn_number = maxi(0, int(_main.turn_number))
	var mixed: int = int(hash("%d|%d|%d|boss_caltrop|%d|%d" % [map_seed, turn_number, province_id, caltrop_id, salt]))
	mixed = mixed & 0x7fffffff
	return mixed if mixed != 0 else (province_id + 1) * 7919 + caltrop_id + 1


func get_province_caltrops(province_id: int) -> Array[Dictionary]:
	if _main == null or province_id < 0:
		return []
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return []
	return _normalize_caltrop_entries(_main._province_persistence[index].get(CALTROPS_KEY, []))


func count_active_province_caltrops(province_id: int) -> int:
	var count: int = 0
	for caltrop in get_province_caltrops(province_id):
		if not bool(caltrop.get("destroyed", false)):
			count += 1
	return count


func mark_caltrop_destroyed(province_id: int, caltrop_id: int) -> bool:
	if _main == null or province_id < 0 or caltrop_id < 0:
		return false
	var province_index: int = find_persistence_index_by_id(province_id)
	if province_index == -1:
		return false
	var province_state: Dictionary = _main._province_persistence[province_index]
	var caltrops: Array[Dictionary] = _normalize_caltrop_entries(province_state.get(CALTROPS_KEY, []))
	for i in range(caltrops.size()):
		if int(caltrops[i].get("id", -1)) != caltrop_id:
			continue
		if bool(caltrops[i].get("destroyed", false)):
			return false
		caltrops[i]["destroyed"] = true
		province_state[CALTROPS_KEY] = caltrops
		return true
	return false


func spawn_boss_caltrops(province_spawn_count: int, gen_rng: RandomNumberGenerator) -> Array[Dictionary]:
	var spawned: Array[Dictionary] = []
	if _main == null or province_spawn_count <= 0:
		return spawned
	var eligible_ids: Array[int] = []
	for province_state in _main._province_persistence:
		var province_id: int = int(province_state.get("id", -1))
		if province_id < 0:
			continue
		eligible_ids.append(province_id)
	if eligible_ids.is_empty():
		return spawned
	for _i in range(province_spawn_count):
		var spawnable_ids: Array[int] = []
		for candidate_id in eligible_ids:
			if count_active_province_caltrops(candidate_id) < MAX_ACTIVE_CALTROPS_PER_PROVINCE:
				spawnable_ids.append(candidate_id)
		if spawnable_ids.is_empty():
			break
		var province_id: int = spawnable_ids[gen_rng.randi_range(0, spawnable_ids.size() - 1)]
		var province_index: int = find_persistence_index_by_id(province_id)
		if province_index == -1:
			continue
		var province_state: Dictionary = _main._province_persistence[province_index]
		var caltrops: Array[Dictionary] = _normalize_caltrop_entries(province_state.get(CALTROPS_KEY, []))
		var next_id: int = 0
		for caltrop in caltrops:
			next_id = maxi(next_id, int(caltrop.get("id", -1)) + 1)
		var seed: int = _make_caltrop_spawn_seed(province_id, next_id, gen_rng)
		caltrops.append({
			"id": next_id,
			"seed": seed,
			"destroyed": false,
			"is_friendly": false
		})
		province_state[CALTROPS_KEY] = caltrops
		spawned.append({
			"province_id": province_id,
			"caltrop_id": next_id,
			"seed": seed
		})
	return spawned


func spawn_friendly_boss_caltrops(province_spawn_count: int, gen_rng: RandomNumberGenerator) -> Array[Dictionary]:
	var spawned: Array[Dictionary] = spawn_boss_caltrops(province_spawn_count, gen_rng)
	for i in range(spawned.size()):
		var entry: Dictionary = spawned[i]
		var province_id: int = int(entry.get("province_id", -1))
		var caltrop_id: int = int(entry.get("caltrop_id", -1))
		if province_id < 0 or caltrop_id < 0:
			continue
		var province_index: int = find_persistence_index_by_id(province_id)
		if province_index == -1:
			continue
		var province_state: Dictionary = _main._province_persistence[province_index]
		var caltrops: Array[Dictionary] = _normalize_caltrop_entries(province_state.get(CALTROPS_KEY, []))
		for j in range(caltrops.size()):
			if int(caltrops[j].get("id", -1)) != caltrop_id:
				continue
			caltrops[j]["is_friendly"] = true
			province_state[CALTROPS_KEY] = caltrops
			break
	return spawned



func find_persistence_index_by_id(province_id: int) -> int:
	if _main == null:
		return -1
	for i in range(_main._province_persistence.size()):
		if int(_main._province_persistence[i].get("id", -1)) == province_id:
			return i
	return -1


func get_province_faction(province_state: Dictionary) -> int:
	return int(province_state.get("faction_id", 0))


func is_boss_home_province_state(province_state: Dictionary) -> bool:
	return bool(province_state.get(BOSS_HOME_FLAG_KEY, false))


func is_boss_home_province_id(province_id: int) -> bool:
	if _main == null or province_id < 0:
		return false
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return false
	return is_boss_home_province_state(_main._province_persistence[index])


func get_boss_home_province_id_from_persistence() -> int:
	var boss_home_ids: Array[int] = get_boss_home_province_ids_from_persistence()
	if boss_home_ids.is_empty():
		return -1
	return int(boss_home_ids[0])


func get_boss_home_province_ids_from_persistence() -> Array[int]:
	var home_ids: Array[int] = []
	if _main == null:
		return home_ids
	for province_state in _main._province_persistence:
		if is_boss_home_province_state(province_state):
			home_ids.append(int(province_state.get("id", -1)))
	return home_ids


func _get_all_boss_faction_ids() -> Array[int]:
	var out: Array[int] = []
	if _main == null or _main.boss_system == null:
		return out
	if _main.boss_system.has_method("get_all_boss_faction_ids"):
		var ids_any: Variant = _main.boss_system.call("get_all_boss_faction_ids")
		if ids_any is Array:
			for id_any in ids_any:
				var faction_id: int = int(id_any)
				if faction_id > 0 and not out.has(faction_id):
					out.append(faction_id)
	if out.is_empty() and _main.boss_system.has_method("get_boss_faction_id"):
		var fallback_id: int = int(_main.boss_system.call("get_boss_faction_id"))
		if fallback_id > 0:
			out.append(fallback_id)
	return out


func is_boss_faction_province_state(province_state: Dictionary) -> bool:
	if _main == null or _main.boss_system == null:
		return false
	if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_ENEMY:
		return false
	var province_faction_id: int = int(province_state.get("faction_id", 0))
	for boss_faction_id in _get_all_boss_faction_ids():
		if province_faction_id == int(boss_faction_id):
			return true
	return false


func get_initial_province_counts(province_type: String) -> Dictionary:
	var campaign_enemy_troop_bonus_total: int = _get_campaign_enemy_troop_level_bonus_total()
	match province_type:
		LevelConfig.PROVINCE_TYPE_ENEMY:
			return {
				"remaining_buildings": LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_ENEMY),
				"remaining_troops": maxi(0, LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY) + campaign_enemy_troop_bonus_total),
				"faction_id": LevelConfig.ENEMY_FACTION_DEFAULT,
				"construction_progress": 0
			}
		LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return {
				"remaining_buildings": LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_FRIENDLY),
				"remaining_troops": LevelConfig.get_runtime_initial_province_friendly_troops_for_level(_get_campaign_current_level_progress(), _is_opening_gameplay_tutorial_active()),
				"faction_id": 0,
				"construction_progress": 0
			}
		_:
			return {
				"remaining_buildings": LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_NEUTRAL),
				"remaining_troops": LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_NEUTRAL),
				"faction_id": 0,
				"construction_progress": 0
			}



func _get_campaign_current_level_progress() -> int:
	if _main != null and _main.has_method("get_campaign_current_level_progress"):
		return maxi(1, int(_main.call("get_campaign_current_level_progress")))
	return 1


func _is_opening_gameplay_tutorial_active() -> bool:
	if _main != null and _main.has_method("is_opening_gameplay_tutorial_active"):
		return bool(_main.call("is_opening_gameplay_tutorial_active"))
	return false


func _get_campaign_enemy_troop_level_bonus_total() -> int:
	if _main == null:
		return 0
	if _main.has_method("get_campaign_enemy_troop_level_bonus_total"):
		return maxi(0, int(_main.call("get_campaign_enemy_troop_level_bonus_total")))
	return 0


func get_conquered_province_counts(province_type: String, province_state: Dictionary = {}) -> Dictionary:
	var counts: Dictionary = {}
	match province_type:
		LevelConfig.PROVINCE_TYPE_ENEMY:
			counts = {
				"remaining_buildings": LevelConfig.get_conquered_province_buildings(LevelConfig.PROVINCE_TYPE_ENEMY),
				"remaining_troops": LevelConfig.get_conquered_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY),
				"faction_id": LevelConfig.ENEMY_FACTION_DEFAULT,
				"construction_progress": 0
			}
		LevelConfig.PROVINCE_TYPE_FRIENDLY:
			counts = {
				"remaining_buildings": LevelConfig.get_conquered_province_buildings(LevelConfig.PROVINCE_TYPE_FRIENDLY),
				"remaining_troops": LevelConfig.get_runtime_conquered_province_friendly_troops_for_level(_get_campaign_current_level_progress(), _is_opening_gameplay_tutorial_active()),
				"faction_id": 0,
				"construction_progress": 0
			}
		_:
			counts = {
				"remaining_buildings": LevelConfig.get_conquered_province_buildings(LevelConfig.PROVINCE_TYPE_NEUTRAL),
				"remaining_troops": LevelConfig.get_conquered_province_troops(LevelConfig.PROVINCE_TYPE_NEUTRAL),
				"faction_id": 0,
				"construction_progress": 0
			}
	var free_buildings: int = get_province_free_buildings(province_state)
	counts["remaining_buildings"] = mini(get_province_building_capacity(province_state), int(counts.get("remaining_buildings", 0)) + free_buildings)
	counts[PROVINCE_GOLD_PRODUCTION_KEY] = get_province_gold_production(province_state)
	counts[PROVINCE_FREE_BUILDINGS_KEY] = free_buildings
	counts[PROVINCE_BUILDING_CAPACITY_KEY] = get_province_building_capacity(province_state)
	counts[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = get_province_engagement_map_type(province_state)
	return counts

func get_default_province_counts(province_type: String) -> Dictionary:
	return get_initial_province_counts(province_type)


func get_province_fill_node(province_node: Node) -> Polygon2D:
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is Polygon2D:
			return child as Polygon2D
	return null


func get_province_counts_label_node(province_node: Node) -> Label:
	if not is_instance_valid(province_node):
		return null
	var panel_root: Control = _get_province_info_panel_root(province_node)
	if panel_root != null:
		var name_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_NAME_LABEL_NAME) as Label
		if name_label != null:
			return name_label
	for child in province_node.get_children():
		if child is Label and child.name == "ProvinceCountsLabel":
			return child as Label
	return null

func get_province_counts_background_node(province_node: Node) -> Control:
	var panel_root: Control = _get_province_info_panel_root(province_node)
	if panel_root != null:
		return panel_root
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is ColorRect and child.name == "ProvinceCountsBackground":
			return child as ColorRect
	return null

func ensure_province_counts_draw_order(counts_bg: Control, counts_label: Label) -> void:
	if counts_bg != null:
		_set_canvas_item_layer(counts_bg, PROVINCE_COUNTS_BACKGROUND_Z_INDEX + 1, false)
	if counts_label != null and counts_bg == null:
		_set_canvas_item_layer(counts_label, PROVINCE_COUNTS_LABEL_Z_INDEX + 1, false)


func flash_province_faction_fill_if_visible(province_id: int, flash_seconds: float = 1.0) -> void:
	if _main == null or province_id < 0:
		return
	var province_node: Node = _get_cached_province_node_by_id(province_id)
	if province_node == null or not is_instance_valid(province_node):
		return
	var fill: Polygon2D = get_province_fill_node(province_node)
	if fill == null:
		return
	var duration: float = maxf(0.05, flash_seconds)
	var base_color: Color = fill.color
	if fill.has_meta("province_fill_flash_base_color"):
		var stored_base_variant: Variant = fill.get_meta("province_fill_flash_base_color")
		if stored_base_variant is Color:
			base_color = stored_base_variant as Color
		else:
			fill.remove_meta("province_fill_flash_base_color")
	else:
		fill.set_meta("province_fill_flash_base_color", base_color)
	var existing_tween: Variant = fill.get_meta("province_fill_flash_tween", null) if fill.has_meta("province_fill_flash_tween") else null
	if existing_tween is Tween:
		var tween_to_kill: Tween = existing_tween as Tween
		if tween_to_kill != null and is_instance_valid(tween_to_kill):
			tween_to_kill.kill()
	fill.color = base_color
	var restore_tween: Tween = _main.create_tween()
	fill.set_meta("province_fill_flash_tween", restore_tween)
	var flash_color: Color = base_color
	flash_color.a = 1.0
	fill.color = flash_color
	restore_tween.tween_property(fill, "color", base_color, duration)
	restore_tween.tween_callback(func() -> void:
		if is_instance_valid(fill):
			fill.color = base_color
			if fill.has_meta("province_fill_flash_tween"):
				fill.remove_meta("province_fill_flash_tween")
			if fill.has_meta("province_fill_flash_base_color"):
				fill.remove_meta("province_fill_flash_base_color")
	)


func get_province_target_overlay_node(province_node: Node) -> Polygon2D:
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is Polygon2D and child.name == "ProvinceTargetOverlay":
			return child as Polygon2D
	return null


func _get_locked_province_pattern_texture() -> Texture2D:
	var cell_radius: int = LevelConfig.get_province_launch_pattern_cell_size()
	if _locked_province_pattern_texture != null and _locked_province_pattern_texture_cell_size == cell_radius:
		return _locked_province_pattern_texture
	var size: int = maxi(24, cell_radius * 5)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 0))
	var half: int = int(size / 2)
	var line_softness: int = 1
	for y in range(size):
		for x in range(size):
			var local_x: int = ((x + half) % (cell_radius * 2)) - cell_radius
			var local_y: int = ((y + half) % (cell_radius * 2)) - cell_radius
			var distance_to_diamond_edge: int = abs(abs(local_x) + abs(local_y) - cell_radius)
			if distance_to_diamond_edge <= line_softness:
				var alpha: float = 0.92 if distance_to_diamond_edge == 0 else 0.58
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	_locked_province_pattern_texture = ImageTexture.create_from_image(image)
	_locked_province_pattern_texture_cell_size = cell_radius
	return _locked_province_pattern_texture


func _ensure_locked_province_pattern_overlay_node(province_node: Node) -> Polygon2D:
	if province_node == null:
		return null
	var existing: Polygon2D = province_node.get_node_or_null(LOCKED_PROVINCE_PATTERN_OVERLAY_NAME) as Polygon2D
	if existing != null:
		return existing
	var overlay := Polygon2D.new()
	overlay.name = LOCKED_PROVINCE_PATTERN_OVERLAY_NAME
	province_node.add_child(overlay)
	return overlay


func get_province_troop_visuals_root(province_node: Node) -> Node2D:
	if not is_instance_valid(province_node):
		return null
	return province_node.get_node_or_null(PROVINCE_TROOP_VISUALS_ROOT_NAME) as Node2D


func ensure_province_troop_visuals_root(province_node: Node) -> Node2D:
	if not is_instance_valid(province_node):
		return null
	var root: Node2D = get_province_troop_visuals_root(province_node)
	if root != null:
		return root
	root = Node2D.new()
	root.name = PROVINCE_TROOP_VISUALS_ROOT_NAME
	_set_canvas_item_layer(root, PROVINCE_TROOP_VISUALS_Z_INDEX, false)
	province_node.add_child(root)
	return root


func get_province_building_visuals_root(province_node: Node) -> Node2D:
	if not is_instance_valid(province_node):
		return null
	return province_node.get_node_or_null(PROVINCE_BUILDING_VISUALS_ROOT_NAME) as Node2D


func ensure_province_building_visuals_root(province_node: Node) -> Node2D:
	if not is_instance_valid(province_node):
		return null
	var root: Node2D = get_province_building_visuals_root(province_node)
	if root != null:
		return root
	root = Node2D.new()
	root.name = PROVINCE_BUILDING_VISUALS_ROOT_NAME
	_set_canvas_item_layer(root, PROVINCE_TROOP_VISUALS_Z_INDEX, false)
	province_node.add_child(root)
	return root


func _make_troop_visual_icon() -> ProvinceTroopVisual:
	var icon := ProvinceTroopVisual.new()
	var visual_size_multiplier: float = LevelConfig.get_grand_map_province_troop_visual_size_multiplier()
	var icon_size: float = PROVINCE_TROOP_VISUALS_ICON_SIZE * visual_size_multiplier
	icon.update_visual(icon_size, LevelConfig.get_grand_map_province_troop_visual_color(), LevelConfig.get_grand_map_province_troop_visual_opacity())
	return icon


func _make_building_visual_icon() -> ProvinceBuildingVisual:
	var icon := ProvinceBuildingVisual.new()
	var visual_size_multiplier: float = LevelConfig.get_grand_map_province_troop_visual_size_multiplier()
	var icon_size: float = PROVINCE_TROOP_VISUALS_ICON_SIZE * visual_size_multiplier
	icon.update_visual(icon_size, LevelConfig.get_grand_map_province_troop_visual_color(), LevelConfig.get_grand_map_province_troop_visual_opacity())
	return icon


func _pseudo_random_01(seed_value: int) -> float:
	var v: float = sin(float(seed_value) * 12.9898 + 78.233) * 43758.5453
	return v - floor(v)


func _compute_visual_icon_offset(idx: int, required_icons: int, row_width: int, stack_direction: String, icon_spacing: float, pile_radius: float, province_id: int) -> Vector2:
	var col: int = 0
	var row: int = 0
	var x_offset: float = 0.0
	var y_offset: float = 0.0
	if stack_direction == "pile":
		var seed_base: int = province_id * 911 + required_icons * 131 + idx * 37
		var angle_jitter: float = _pseudo_random_01(seed_base + 7) * TAU
		var radial_jitter: float = _pseudo_random_01(seed_base + 19)
		var irregularity: float = lerpf(0.72, 1.22, _pseudo_random_01(seed_base + 43))
		var swirl_angle: float = float(idx) * (TAU * PROVINCE_TROOP_VISUALS_PILE_SWIRL_TURNS / float(maxi(1, required_icons)))
		var angle: float = swirl_angle + angle_jitter * 0.6
		var radial_fraction: float = pow(radial_jitter, 0.72)
		var radius: float = pile_radius * radial_fraction * irregularity
		x_offset = cos(angle) * radius
		y_offset = sin(angle) * radius * lerpf(0.88, 1.12, _pseudo_random_01(seed_base + 101))
	elif stack_direction == "vertical":
		row = idx % row_width
		col = idx / row_width
		var column_count: int = int(ceil(float(required_icons) / float(row_width)))
		var column_item_count: int = mini(row_width, required_icons - col * row_width)
		x_offset = (float(col) - (float(column_count - 1) * 0.5)) * icon_spacing
		y_offset = (float(row) - (float(column_item_count - 1) * 0.5)) * icon_spacing
	else:
		col = idx % row_width
		row = idx / row_width
		var row_count: int = mini(row_width, required_icons - row * row_width)
		x_offset = (float(col) - (float(row_count - 1) * 0.5)) * icon_spacing
		var total_rows: int = int(ceil(float(required_icons) / float(row_width)))
		y_offset = (float(row) - (float(total_rows - 1) * 0.5)) * icon_spacing
	return Vector2(x_offset, y_offset)


func _layout_province_troop_visuals(province_node: Node, province_state: Dictionary, base_color: Color) -> void:
	var troop_visuals_root: Node2D = ensure_province_troop_visuals_root(province_node)
	if troop_visuals_root == null:
		return
	var fill: Polygon2D = get_province_fill_node(province_node)
	var poly: PackedVector2Array = fill.polygon if fill != null else PackedVector2Array()
	var center: Vector2 = _find_polygon_label_center(poly, Vector2.ZERO) if poly.size() > 0 else Vector2.ZERO
	center.y += LevelConfig.get_grand_map_province_troop_visual_center_y_offset()
	var troop_visual_cap: int = _get_dynamic_troop_visual_cap()
	var troop_count: int = clampi(int(province_state.get("remaining_troops", 0)), 0, troop_visual_cap)
	var required_icons: int = troop_count
	var existing_icons: int = troop_visuals_root.get_child_count()
	while existing_icons < required_icons:
		troop_visuals_root.add_child(_make_troop_visual_icon())
		existing_icons += 1
	while existing_icons > required_icons:
		var child: Node = troop_visuals_root.get_child(existing_icons - 1)
		troop_visuals_root.remove_child(child)
		child.queue_free()
		existing_icons -= 1
	var icon_color: Color = base_color
	if icon_color.a <= 0.0:
		icon_color = LevelConfig.get_grand_map_province_troop_visual_color()
	else:
		icon_color.a = 1.0
	var icon_opacity: float = LevelConfig.get_grand_map_province_troop_visual_opacity()
	var row_width: int = maxi(1, PROVINCE_TROOP_VISUALS_ROW_WIDTH)
	var stack_direction: String = LevelConfig.get_grand_map_province_troop_visual_stack_direction()
	var visual_size_multiplier: float = LevelConfig.get_grand_map_province_troop_visual_size_multiplier()
	var icon_size: float = PROVINCE_TROOP_VISUALS_ICON_SIZE * visual_size_multiplier
	var icon_spacing: float = PROVINCE_TROOP_VISUALS_ICON_SPACING * visual_size_multiplier
	var province_meta: Dictionary = province_node.get_meta("province_data") if province_node.has_meta("province_data") else {}
	var province_id: int = int(province_meta.get("id", 0))
	var pile_growth: float = sqrt(float(required_icons) / float(maxi(1, troop_visual_cap))) if required_icons > 0 else 0.0
	var pile_radius: float = icon_spacing * lerpf(PROVINCE_TROOP_VISUALS_PILE_MIN_RADIUS_MULTIPLIER, PROVINCE_TROOP_VISUALS_PILE_MAX_RADIUS_MULTIPLIER, pile_growth)
	for idx in range(required_icons):
		var icon: ProvinceTroopVisual = troop_visuals_root.get_child(idx) as ProvinceTroopVisual
		if icon == null:
			var stale_icon: Node = troop_visuals_root.get_child(idx)
			troop_visuals_root.remove_child(stale_icon)
			stale_icon.queue_free()
			icon = _make_troop_visual_icon()
			troop_visuals_root.add_child(icon)
			troop_visuals_root.move_child(icon, idx)
		icon.update_visual(icon_size, icon_color, icon_opacity)
		var offset: Vector2 = _compute_visual_icon_offset(idx, required_icons, row_width, stack_direction, icon_spacing, pile_radius, province_id)
		icon.position = center + offset
		_set_canvas_item_layer(icon, PROVINCE_TROOP_VISUALS_Z_INDEX, false)

func _layout_province_building_visuals(province_node: Node, province_state: Dictionary, panel_top_left: Vector2, panel_size: Vector2, base_color: Color) -> void:
	var building_visuals_root: Node2D = ensure_province_building_visuals_root(province_node)
	if building_visuals_root == null:
		return
	var troop_visual_cap: int = _get_dynamic_troop_visual_cap()
	var required_icons: int = clampi(int(province_state.get("remaining_buildings", 0)), 0, troop_visual_cap)
	var existing_icons: int = building_visuals_root.get_child_count()
	while existing_icons < required_icons:
		building_visuals_root.add_child(_make_building_visual_icon())
		existing_icons += 1
	while existing_icons > required_icons:
		var child: Node = building_visuals_root.get_child(existing_icons - 1)
		building_visuals_root.remove_child(child)
		child.queue_free()
		existing_icons -= 1
	if required_icons <= 0:
		return
	var icon_color: Color = base_color
	if icon_color.a <= 0.0:
		icon_color = LevelConfig.get_grand_map_province_troop_visual_color()
	else:
		icon_color.a = 1.0
	var icon_opacity: float = LevelConfig.get_grand_map_province_troop_visual_opacity()
	var stack_direction: String = LevelConfig.get_grand_map_province_troop_visual_stack_direction()
	var row_width: int = maxi(1, PROVINCE_TROOP_VISUALS_ROW_WIDTH)
	var visual_size_multiplier: float = LevelConfig.get_grand_map_province_troop_visual_size_multiplier()
	var icon_size: float = PROVINCE_TROOP_VISUALS_ICON_SIZE * visual_size_multiplier
	var icon_spacing: float = PROVINCE_TROOP_VISUALS_ICON_SPACING * visual_size_multiplier
	var province_meta: Dictionary = province_node.get_meta("province_data") if province_node.has_meta("province_data") else {}
	var province_id: int = int(province_meta.get("id", 0))
	var pile_growth: float = sqrt(float(required_icons) / float(maxi(1, troop_visual_cap)))
	var pile_radius: float = icon_spacing * lerpf(PROVINCE_TROOP_VISUALS_PILE_MIN_RADIUS_MULTIPLIER, PROVINCE_TROOP_VISUALS_PILE_MAX_RADIUS_MULTIPLIER, pile_growth)
	var offsets: Array[Vector2] = []
	var mirrored_min_y: float = INF
	for idx in range(required_icons):
		var source_offset: Vector2 = _compute_visual_icon_offset(idx, required_icons, row_width, stack_direction, icon_spacing, pile_radius, province_id)
		var mirrored_offset := Vector2(-source_offset.x, source_offset.y)
		offsets.append(mirrored_offset)
		mirrored_min_y = minf(mirrored_min_y, mirrored_offset.y)
	var panel_bottom: float = panel_top_left.y + panel_size.y
	var desired_min_y: float = panel_bottom + PROVINCE_BUILDING_VISUALS_CARD_GAP + icon_size
	var center := Vector2(panel_top_left.x + panel_size.x * 0.5, desired_min_y - mirrored_min_y)
	for idx in range(required_icons):
		var icon: ProvinceBuildingVisual = building_visuals_root.get_child(idx) as ProvinceBuildingVisual
		if icon == null:
			var stale_icon: Node = building_visuals_root.get_child(idx)
			building_visuals_root.remove_child(stale_icon)
			stale_icon.queue_free()
			icon = _make_building_visual_icon()
			building_visuals_root.add_child(icon)
			building_visuals_root.move_child(icon, idx)
		icon.update_visual(icon_size, icon_color, icon_opacity)
		icon.position = center + offsets[idx]
		_set_canvas_item_layer(icon, PROVINCE_TROOP_VISUALS_Z_INDEX, false)


func _get_dynamic_troop_visual_cap() -> int:
	var cap: int = PROVINCE_TROOP_VISUALS_REDUCED_COUNT
	if _main != null and _main.has_method("get"):
		var camera_zoom_value: float = float(_main.get("current_camera_zoom"))
		if camera_zoom_value >= 0.85:
			cap = min(PROVINCE_TROOP_VISUALS_REDUCED_COUNT, 14)
		elif camera_zoom_value >= 0.65:
			cap = min(PROVINCE_TROOP_VISUALS_REDUCED_COUNT, 18)
	return clampi(cap, 8, PROVINCE_TROOP_VISUALS_MAX_COUNT)


func is_target_province_state(province_state: Dictionary) -> bool:
	return bool(province_state.get("is_target", false))


func get_province_info_box_size(province_state: Dictionary) -> Vector2:
	return _get_province_info_panel_size()

func _compute_polygon_average(poly: PackedVector2Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var sum: Vector2 = Vector2.ZERO
	for point in poly:
		sum += point
	return sum / float(poly.size())


func _compute_polygon_centroid(poly: PackedVector2Array) -> Vector2:
	if poly.size() < 3:
		return _compute_polygon_average(poly)
	var signed_area: float = 0.0
	var cx: float = 0.0
	var cy: float = 0.0
	for i in range(poly.size()):
		var p0: Vector2 = poly[i]
		var p1: Vector2 = poly[(i + 1) % poly.size()]
		var cross: float = p0.x * p1.y - p1.x * p0.y
		signed_area += cross
		cx += (p0.x + p1.x) * cross
		cy += (p0.y + p1.y) * cross
	if absf(signed_area) < 0.0001:
		return _compute_polygon_average(poly)
	signed_area *= 0.5
	return Vector2(cx / (6.0 * signed_area), cy / (6.0 * signed_area))


func _compute_polygon_bounds(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var min_x: float = poly[0].x
	var min_y: float = poly[0].y
	var max_x: float = poly[0].x
	var max_y: float = poly[0].y
	for point in poly:
		min_x = minf(min_x, point.x)
		min_y = minf(min_y, point.y)
		max_x = maxf(max_x, point.x)
		max_y = maxf(max_y, point.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _distance_point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq <= 0.0001:
		return point.distance_to(a)
	var t: float = clampf((point - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return point.distance_to(closest)


func _distance_to_polygon_edges(point: Vector2, poly: PackedVector2Array) -> float:
	if poly.size() < 2:
		return 0.0
	var best: float = INF
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		best = minf(best, _distance_point_to_segment(point, a, b))
	return 0.0 if best == INF else best


func _score_label_candidate(point: Vector2, poly: PackedVector2Array, desired_center: Vector2, box_size: Vector2, bounds: Rect2) -> float:
	if not Geometry2D.is_point_in_polygon(point, poly):
		return -INF
	var edge_distance: float = _distance_to_polygon_edges(point, poly)
	var score: float = edge_distance * 4.0 - point.distance_to(desired_center) * 0.35
	if box_size != Vector2.ZERO:
		var half: Vector2 = box_size * 0.5
		var overflow_x: float = maxf(0.0, bounds.position.x - (point.x - half.x)) + maxf(0.0, (point.x + half.x) - (bounds.position.x + bounds.size.x))
		var overflow_y: float = maxf(0.0, bounds.position.y - (point.y - half.y)) + maxf(0.0, (point.y + half.y) - (bounds.position.y + bounds.size.y))
		score -= (overflow_x + overflow_y) * 3.5
	return score


func _find_polygon_label_center(poly: PackedVector2Array, box_size: Vector2 = Vector2.ZERO) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var bounds: Rect2 = _compute_polygon_bounds(poly)
	var centroid: Vector2 = _compute_polygon_centroid(poly)
	var average: Vector2 = _compute_polygon_average(poly)
	var desired_center: Vector2 = centroid if Geometry2D.is_point_in_polygon(centroid, poly) else average
	var candidates: Array[Vector2] = [desired_center, average, bounds.get_center()]
	var steps_x: int = 9
	var steps_y: int = 9
	for yi in range(steps_y):
		var fy: float = 0.0 if steps_y <= 1 else float(yi) / float(steps_y - 1)
		for xi in range(steps_x):
			var fx: float = 0.0 if steps_x <= 1 else float(xi) / float(steps_x - 1)
			candidates.append(Vector2(
				bounds.position.x + bounds.size.x * fx,
				bounds.position.y + bounds.size.y * fy
			))
	var best_point: Vector2 = desired_center
	var best_score: float = -INF
	for candidate in candidates:
		var score: float = _score_label_candidate(candidate, poly, desired_center, box_size, bounds)
		if score > best_score:
			best_score = score
			best_point = candidate
	if best_score == -INF:
		return average
	return best_point


func get_label_display_center(province_node: Node, counts_bg: Control, counts_label: Label, box_size: Vector2 = Vector2.ZERO) -> Vector2:
	if counts_bg != null and counts_bg.has_meta("manual_center"):
		return counts_bg.get_meta("manual_center")
	if counts_label != null and counts_label.has_meta("manual_center"):
		return counts_label.get_meta("manual_center")
	var fill: Polygon2D = get_province_fill_node(province_node)
	if fill != null and fill.polygon.size() > 0:
		return _find_polygon_label_center(fill.polygon, box_size)
	if counts_bg != null:
		return counts_bg.position + counts_bg.size * 0.5
	if counts_label != null:
		return counts_label.position + counts_label.size * 0.5
	return Vector2.ZERO


func get_province_owner_text(province_state: Dictionary) -> String:
	if is_boss_home_province_state(province_state):
		var boss_faction: int = int(province_state.get("faction_id", 0))
		if boss_faction <= 0 and _main != null and _main.boss_system != null:
			var province_id: int = int(province_state.get("id", -1))
			if province_id >= 0 and _main.boss_system.has_method("get_boss_id_for_home_province_id") and _main.boss_system.has_method("get_boss_faction_id"):
				var boss_id: int = int(_main.boss_system.get_boss_id_for_home_province_id(province_id))
				if boss_id >= 0:
					boss_faction = int(_main.boss_system.get_boss_faction_id(boss_id))
		return get_faction_display_name(maxi(1, boss_faction))
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var relation: String = get_relation_to_player_for_province_state(province_state)
	if relation == RELATION_SELF:
		return "Friendly"
	if relation == RELATION_ALLY:
		return "Ally %d" % int(province_state.get("faction_id", 0))
	if relation == RELATION_HOSTILE:
		var faction: int = maxi(1, int(province_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
		return get_faction_display_name(faction)
	if province_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return "Neutral"
	return "Friendly"


func _get_name_generation_world_seed() -> int:
	if _main == null:
		return 1
	return maxi(1, int(_main.map_seed))


func _get_generated_faction_name_candidate(faction_id: int) -> String:
	var world_seed: int = _get_name_generation_world_seed()
	var generated_name_id: int = FACTION_NAME_ID_OFFSET + absi(faction_id)
	var generated: String = String(LevelConfig.generate_province_name(world_seed, generated_name_id)).strip_edges()
	if generated.is_empty():
		return "Faction %d" % faction_id
	return generated


func get_faction_display_name(faction_id: int) -> String:
	var safe_faction_id: int = int(faction_id)
	if safe_faction_id <= 0:
		return "Neutral"
	var cache_key: String = "%d|%d" % [_get_name_generation_world_seed(), safe_faction_id]
	if _faction_name_cache.has(cache_key):
		return String(_faction_name_cache.get(cache_key, "Faction %d" % safe_faction_id))
	var generated: String = _get_generated_faction_name_candidate(safe_faction_id)
	_faction_name_cache[cache_key] = generated
	return generated


func _is_friendly_boss_faction_id(faction_id: int) -> bool:
	if faction_id <= 0 or _main == null or _main.boss_system == null:
		return false
	if not _main.boss_system.has_method("is_friendly_boss_faction_id"):
		return false
	return bool(_main.boss_system.call("is_friendly_boss_faction_id", faction_id))


func is_player_owned(owner_type: String, faction_id: int) -> bool:
	return owner_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and not _is_friendly_boss_faction_id(faction_id)


func is_ally_owned(owner_type: String, faction_id: int) -> bool:
	return faction_id > 0 and _is_friendly_boss_faction_id(faction_id)


func is_hostile_owned(owner_type: String, faction_id: int) -> bool:
	return owner_type == LevelConfig.PROVINCE_TYPE_ENEMY and not _is_friendly_boss_faction_id(faction_id)


func normalize_owner_fields(province_state: Dictionary) -> Dictionary:
	var normalized: Dictionary = province_state.duplicate(true)
	var owner_type: String = String(normalized.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var faction_id: int = int(normalized.get("faction_id", 0))
	var is_friendly_boss_faction: bool = faction_id > 0 and _is_friendly_boss_faction_id(faction_id)
	if owner_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		if is_friendly_boss_faction:
			normalized["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
			normalized["faction_id"] = faction_id
		else:
			normalized["faction_id"] = 0
	elif owner_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		if is_friendly_boss_faction:
			normalized["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
			normalized["faction_id"] = faction_id
		else:
			normalized["faction_id"] = maxi(1, faction_id if faction_id != 0 else LevelConfig.ENEMY_FACTION_DEFAULT)
	elif owner_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		normalized["faction_id"] = 0
	else:
		normalized["type"] = LevelConfig.PROVINCE_TYPE_NEUTRAL
		normalized["faction_id"] = 0
	return normalized


func get_relation_to_player(owner_type: String, faction_id: int) -> String:
	if owner_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return RELATION_NEUTRAL
	if is_player_owned(owner_type, faction_id):
		return RELATION_SELF
	if is_ally_owned(owner_type, faction_id):
		return RELATION_ALLY
	if is_hostile_owned(owner_type, faction_id):
		return RELATION_HOSTILE
	return RELATION_NEUTRAL


func get_relation_to_player_for_province_state(province_state: Dictionary) -> String:
	return get_relation_to_player(
		String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
		int(province_state.get("faction_id", 0))
	)


func _get_enemy_faction_display_color(faction_id: int) -> Color:
	if _is_friendly_boss_faction_id(faction_id):
		return FRIENDLY_BOSS_FACTION_DISPLAY_COLOR
	return LevelConfig.get_enemy_faction_color(faction_id)


func _get_nonempty_province_name_from_dict(source: Dictionary) -> String:
	if source.is_empty():
		return ""
	return String(source.get(PROVINCE_NAME_KEY, "")).strip_edges()


func _generate_fallback_province_name(province_id: int) -> String:
	var map_seed: int = 1
	if _main != null:
		map_seed = maxi(1, int(_main.map_seed))
	var generated: String = String(LevelConfig.generate_province_name(map_seed, province_id)).strip_edges()
	if generated.is_empty():
		return "Province %d" % province_id
	return generated


func _resolve_province_name(province_id: int, province_state: Dictionary, province_meta: Dictionary = {}) -> String:
	var state_name: String = _get_nonempty_province_name_from_dict(province_state)
	if not state_name.is_empty():
		return state_name
	var meta_name: String = _get_nonempty_province_name_from_dict(province_meta)
	if not meta_name.is_empty():
		return meta_name
	return _generate_fallback_province_name(province_id)


func get_province_display_name(province_id: int, province_state: Dictionary) -> String:
	return _resolve_province_name(province_id, province_state)



func get_province_info_text(province_id: int, province_state: Dictionary) -> String:
	var lines: Array[String] = []
	if is_target_province_state(province_state):
		lines.append(LevelConfig.TARGET_PROVINCE_LABEL_TEXT)
	lines.append(get_province_owner_text(province_state))
	lines.append(get_province_display_name(province_id, province_state))
	lines.append(format_province_counts_text(province_state))
	for extra_line in get_province_variation_info_lines(province_state):
		lines.append(extra_line)
	return "\n".join(lines)

func get_province_border_node(province_node: Node) -> Line2D:
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is Line2D and String(child.name) == "ProvinceBorder":
			return child as Line2D
	for child in province_node.get_children():
		if child is Line2D and String(child.name) != "ProvinceInnerGlow":
			return child as Line2D
	return null


func get_province_inner_glow_node(province_node: Node) -> Line2D:
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is Line2D and String(child.name) == "ProvinceInnerGlow":
			return child as Line2D
	var line_count: int = 0
	for child in province_node.get_children():
		if child is Line2D:
			line_count += 1
			if line_count == 2:
				return child as Line2D
	return null


func ensure_province_inner_glow_node(province_node: Node) -> Line2D:
	if not is_instance_valid(province_node):
		return null
	var existing: Line2D = get_province_inner_glow_node(province_node)
	if existing != null:
		return existing
	var inner_glow := Line2D.new()
	inner_glow.name = "ProvinceInnerGlow"
	inner_glow.antialiased = true
	inner_glow.closed = true
	_set_canvas_item_layer(inner_glow, PROVINCE_BORDER_OVERLAYS_Z_INDEX, false)
	province_node.add_child(inner_glow)
	return inner_glow


func _enforce_province_line_visibility(province_node: Node, keep_inner_glow_visible: bool) -> void:
	if not is_instance_valid(province_node):
		return
	for child in province_node.get_children():
		if child is Line2D:
			var line := child as Line2D
			if String(line.name) == "ProvinceInnerGlow":
				line.visible = keep_inner_glow_visible
			else:
				line.visible = false


func get_base_province_fill_color(province_state: Dictionary, tint_idx: int) -> Color:
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var invading_troops: int = int(province_state.get("invading_troops", 0))
	var faction_id: int = int(province_state.get("faction_id", 0))
	
	if is_boss_home_province_state(province_state):
		var boss_home_faction: int = int(province_state.get("faction_id", 0))
		if boss_home_faction > 0:
			return _get_enemy_faction_display_color(boss_home_faction)
		return BOSS_HOME_FILL_COLOR
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and faction_id == BossSystem.FRIENDLY_BOSS_FACTION_ID:
		var friendly_boss_fill: Color = _get_enemy_faction_display_color(faction_id)
		if invading_troops > 0:
			var invaded_friendly_boss_fill: Color = friendly_boss_fill.lightened(0.2)
			invaded_friendly_boss_fill.a = friendly_boss_fill.a
			return invaded_friendly_boss_fill
		return friendly_boss_fill
	if province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		var faction: int = int(province_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT))
		return _get_enemy_faction_display_color(faction)
	
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
		return LevelConfig.get_friendly_invaded_province_fill_color()
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return LevelConfig.get_friendly_province_fill_color()
	return LevelConfig.PROVINCE_FILL_COLORS[tint_idx % LevelConfig.PROVINCE_FILL_COLORS.size()]


func _colors_match_for_border_selection(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) <= 0.002 and absf(a.g - b.g) <= 0.002 and absf(a.b - b.b) <= 0.002 and absf(a.a - b.a) <= 0.01


func get_province_border_line_color(base_fill_color: Color) -> Color:
	for neutral_color in LevelConfig.PROVINCE_FILL_COLORS:
		if _colors_match_for_border_selection(base_fill_color, neutral_color):
			return LevelConfig.PROVINCE_NEUTRAL_BORDER_COLOR
	if _colors_match_for_border_selection(base_fill_color, BOSS_HOME_FILL_COLOR):
		return BOSS_HOME_BORDER_COLOR
	var line_color: Color = base_fill_color
	line_color.a = 1.0
	return line_color


func get_province_outer_line_width() -> float:
	return LevelConfig.PROVINCE_BORDER_WIDTH


func get_province_inner_line_width() -> float:
	return maxf(2.0, LevelConfig.PROVINCE_BORDER_WIDTH * 0.42)


func get_province_inner_line_inset() -> float:
	return maxf(get_province_inner_line_width() * 0.7, LevelConfig.PROVINCE_BORDER_WIDTH * 0.55)


func get_province_shared_border_width() -> float:
	return maxf(1.0, float(LevelConfig.PROVINCE_SHARED_BORDER_WIDTH))


func get_province_shared_border_band_width() -> float:
	return maxf(get_province_shared_border_width() * 2.35, get_province_shared_border_width() + 5.0)


func get_province_shared_border_center_inset() -> float:
	return maxf(0.5, get_province_shared_border_band_width() * 0.5 + 0.2)


func get_province_shared_border_band_depth() -> float:
	return get_province_shared_border_band_width()


func get_province_shared_ownership_fill_width() -> float:
	return maxf(get_province_shared_border_band_width() + get_province_shared_border_center_inset() * 2.0 + 1.0, get_province_shared_border_band_width() + 4.0)


func get_province_shared_border_run_extension() -> float:
	return maxf(1.25, get_province_shared_border_band_width() * 0.35)


func _polygon_signed_area(poly: PackedVector2Array) -> float:
	var area: float = 0.0
	var count: int = poly.size()
	if count < 3:
		return 0.0
	for i in range(count):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % count]
		area += a.x * b.y - b.x * a.y
	return area * 0.5

func _ensure_polygon_ccw(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	if _polygon_signed_area(poly) >= 0.0:
		return poly
	var reversed_poly: PackedVector2Array = PackedVector2Array()
	for i in range(poly.size() - 1, -1, -1):
		reversed_poly.append(poly[i])
	return reversed_poly


func make_inset_polyline(poly: PackedVector2Array, inset_distance: float) -> PackedVector2Array:
	if poly.size() < 3 or inset_distance <= 0.0:
		return poly
	var offset_polys: Array = Geometry2D.offset_polygon(poly, -inset_distance)
	if offset_polys.is_empty():
		return poly
	var best_poly: PackedVector2Array = offset_polys[0]
	var best_area: float = absf(_polygon_signed_area(best_poly))
	for candidate in offset_polys:
		var candidate_poly: PackedVector2Array = candidate
		var candidate_area: float = absf(_polygon_signed_area(candidate_poly))
		if candidate_area > best_area:
			best_area = candidate_area
			best_poly = candidate_poly
	if best_poly.size() >= 3:
		return best_poly
	return poly

func _collapse_collinear_points(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 4:
		return poly
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(poly.size()):
		var prev: Vector2 = poly[(i - 1 + poly.size()) % poly.size()]
		var cur: Vector2 = poly[i]
		var nxt: Vector2 = poly[(i + 1) % poly.size()]
		var edge_a: Vector2 = cur - prev
		var edge_b: Vector2 = nxt - cur
		if edge_a.length_squared() <= 0.000001 or edge_b.length_squared() <= 0.000001:
			continue
		var v1: Vector2 = edge_a.normalized()
		var v2: Vector2 = edge_b.normalized()
		if absf(v1.cross(v2)) < 0.001 and v1.dot(v2) > 0.999:
			continue
		out.append(cur)
	return out


func _chaikin_smooth_closed_polygon(poly: PackedVector2Array, ratio: float) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	var clamped_ratio: float = clampf(ratio, 0.05, 0.45)
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		out.append(a.lerp(b, clamped_ratio))
		out.append(a.lerp(b, 1.0 - clamped_ratio))
	return out


func _rdp_simplify_open_polyline(points: PackedVector2Array, epsilon: float) -> PackedVector2Array:
	if points.size() <= 2:
		return points
	var max_distance: float = -1.0
	var max_index: int = -1
	var start_point: Vector2 = points[0]
	var end_point: Vector2 = points[points.size() - 1]
	for i in range(1, points.size() - 1):
		var distance: float = _distance_point_to_segment(points[i], start_point, end_point)
		if distance > max_distance:
			max_distance = distance
			max_index = i
	if max_distance > epsilon and max_index > 0:
		var left_source: PackedVector2Array = PackedVector2Array()
		for i in range(0, max_index + 1):
			left_source.append(points[i])
		var right_source: PackedVector2Array = PackedVector2Array()
		for i in range(max_index, points.size()):
			right_source.append(points[i])
		var left: PackedVector2Array = _rdp_simplify_open_polyline(left_source, epsilon)
		var right: PackedVector2Array = _rdp_simplify_open_polyline(right_source, epsilon)
		var out: PackedVector2Array = PackedVector2Array()
		for i in range(left.size() - 1):
			out.append(left[i])
		for point in right:
			out.append(point)
		return out
	var simple: PackedVector2Array = PackedVector2Array()
	simple.append(start_point)
	simple.append(end_point)
	return simple


func _normalize_closed_polygon_start(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	var working: PackedVector2Array = poly
	if _polygon_signed_area(working) < 0.0:
		var reversed_working: PackedVector2Array = PackedVector2Array()
		for i in range(working.size() - 1, -1, -1):
			reversed_working.append(working[i])
		working = reversed_working
	var best_index: int = 0
	for i in range(1, working.size()):
		var candidate: Vector2 = working[i]
		var best: Vector2 = working[best_index]
		if candidate.x < best.x - 0.001 or (absf(candidate.x - best.x) <= 0.001 and candidate.y < best.y):
			best_index = i
	if best_index == 0:
		return working
	var rotated: PackedVector2Array = PackedVector2Array()
	for i in range(working.size()):
		rotated.append(working[(best_index + i) % working.size()])
	return rotated


func _simplify_closed_polygon(poly: PackedVector2Array, epsilon: float) -> PackedVector2Array:
	if poly.size() < 4 or epsilon <= 0.0:
		return poly
	var working: PackedVector2Array = _normalize_closed_polygon_start(poly)
	var open_points: PackedVector2Array = PackedVector2Array()
	for point in working:
		open_points.append(point)
	open_points.append(working[0])
	var simplified_open: PackedVector2Array = _rdp_simplify_open_polyline(open_points, epsilon)
	if simplified_open.size() <= 3:
		return working
	var simplified_closed: PackedVector2Array = PackedVector2Array()
	for i in range(simplified_open.size() - 1):
		simplified_closed.append(simplified_open[i])
	if simplified_closed.size() >= 3:
		return simplified_closed
	return working


func make_smoothed_province_display_polyline(poly: PackedVector2Array, inset_distance: float = 0.0) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	var working: PackedVector2Array = poly
	if inset_distance > 0.0:
		working = make_inset_polyline(working, inset_distance)
	working = _collapse_collinear_points(working)
	if bool(LevelConfig.PROVINCE_BORDER_SIMPLIFY_ENABLED):
		var simplify_min_points: int = maxi(3, int(LevelConfig.PROVINCE_BORDER_SIMPLIFY_MIN_POINT_COUNT))
		if working.size() >= simplify_min_points:
			working = _simplify_closed_polygon(working, float(LevelConfig.PROVINCE_BORDER_SIMPLIFY_EPSILON))
			working = _collapse_collinear_points(working)
	if not bool(LevelConfig.PROVINCE_BORDER_SMOOTHING_ENABLED):
		return working
	var min_points: int = maxi(3, int(LevelConfig.PROVINCE_BORDER_SMOOTHING_MIN_POINT_COUNT))
	if working.size() < min_points:
		return working
	var ratio: float = float(LevelConfig.PROVINCE_BORDER_SMOOTHING_CHAIKIN_RATIO)
	var pass_count: int = maxi(0, int(LevelConfig.PROVINCE_BORDER_SMOOTHING_PASSES))
	for _pass_idx in range(pass_count):
		working = _chaikin_smooth_closed_polygon(working, ratio)
	working = _collapse_collinear_points(working)
	return working


func _chaikin_smooth_open_polyline(points: PackedVector2Array, ratio: float) -> PackedVector2Array:
	if points.size() < 2:
		return points
	var clamped_ratio: float = clampf(ratio, 0.05, 0.45)
	var out: PackedVector2Array = PackedVector2Array()
	out.append(points[0])
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		out.append(a.lerp(b, clamped_ratio))
		out.append(a.lerp(b, 1.0 - clamped_ratio))
	out.append(points[points.size() - 1])
	return out


func _smooth_open_province_polyline(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 2:
		return points
	var working: PackedVector2Array = PackedVector2Array()
	for point in points:
		if working.is_empty() or working[working.size() - 1].distance_to(point) > 0.001:
			working.append(point)
	if working.size() < 2:
		return working
	if not bool(LevelConfig.PROVINCE_BORDER_SMOOTHING_ENABLED):
		return working
	var ratio: float = float(LevelConfig.PROVINCE_BORDER_SMOOTHING_CHAIKIN_RATIO)
	var pass_count: int = maxi(0, int(LevelConfig.PROVINCE_BORDER_SMOOTHING_PASSES))
	for _pass_idx in range(pass_count):
		working = _chaikin_smooth_open_polyline(working, ratio)
	return working


func _vector_key(point: Vector2, snap: float = 0.25) -> String:
	var snapped_x: int = int(round(point.x / snap))
	var snapped_y: int = int(round(point.y / snap))
	return "%d,%d" % [snapped_x, snapped_y]


func _edge_key(a: Vector2, b: Vector2) -> String:
	var ka: String = _vector_key(a)
	var kb: String = _vector_key(b)
	if ka <= kb:
		return ka + "|" + kb
	return kb + "|" + ka


func _province_pair_key(a_id: int, b_id: int) -> String:
	if a_id <= b_id:
		return "%d|%d" % [a_id, b_id]
	return "%d|%d" % [b_id, a_id]


func _merge_polygon_collection(polygons: Array) -> Array:
	var merged: Array = []
	for poly_any in polygons:
		var source_poly: PackedVector2Array = poly_any
		if source_poly.size() < 3:
			continue
		var pending: Array = [_normalize_closed_polygon_start(source_poly)]
		var merge_guard: int = 0
		while not pending.is_empty() and merge_guard < 1024:
			merge_guard += 1
			var candidate: PackedVector2Array = pending.pop_back()
			var merged_into_existing: bool = false
			for i in range(merged.size()):
				var existing: PackedVector2Array = merged[i]
				var union_parts: Array = Geometry2D.merge_polygons(existing, candidate)
				if union_parts.size() == 1:
					merged.remove_at(i)
					pending.append(_normalize_closed_polygon_start(union_parts[0]))
					merged_into_existing = true
					break
			if not merged_into_existing:
				merged.append(_normalize_closed_polygon_start(candidate))
		if merge_guard >= 1024:
			for pending_poly_any in pending:
				var pending_poly: PackedVector2Array = pending_poly_any
				if pending_poly.size() >= 3:
					merged.append(_normalize_closed_polygon_start(pending_poly))
	return merged


func _get_merged_mainland_polygons_from_nodes(province_nodes: Array) -> Array:
	var province_polygons: Array = []
	for province_node_any in province_nodes:
		var province_node: Node = province_node_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		var poly: PackedVector2Array = _get_logical_province_polygon(province_node)
		if poly.size() >= 3:
			province_polygons.append(poly)
	return _merge_polygon_collection(province_polygons)


func _get_logical_province_polygon(province_node: Node) -> PackedVector2Array:
	if province_node != null and province_node.has_meta("province_polygon"):
		var meta_poly: PackedVector2Array = province_node.get_meta("province_polygon")
		if meta_poly.size() >= 3:
			return meta_poly
	var fill: Polygon2D = get_province_fill_node(province_node)
	if fill != null and fill.polygon.size() >= 3:
		return fill.polygon
	return PackedVector2Array()


func _get_province_center_from_polygon(poly: PackedVector2Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for point in poly:
		sum += point
	return sum / float(poly.size())



func _points_match(a: Vector2, b: Vector2, tolerance: float = 0.25) -> bool:
	return a.distance_to(b) <= tolerance


func _is_point_on_segment(point: Vector2, a: Vector2, b: Vector2, tolerance: float = 0.25) -> bool:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq <= 0.000001:
		return point.distance_to(a) <= tolerance
	var cross_amount: float = absf((point - a).cross(ab))
	if cross_amount > tolerance * sqrt(ab_len_sq):
		return false
	var t: float = (point - a).dot(ab) / ab_len_sq
	return t >= -0.001 and t <= 1.001


func _add_unique_breakpoint(points: Array, point: Vector2, t: float, tolerance: float = 0.25) -> Array:
	for i in range(points.size()):
		var existing: Dictionary = points[i]
		var existing_point: Vector2 = existing.get("point", Vector2.ZERO)
		if existing_point.distance_to(point) <= tolerance:
			var existing_t: float = float(existing.get("t", 0.0))
			existing["point"] = existing_point.lerp(point, 0.5)
			existing["t"] = (existing_t + t) * 0.5
			points[i] = existing
			return points
	points.append({"point": point, "t": t})
	return points


func _sort_breakpoints(points: Array) -> Array:
	var sorted_points: Array = points.duplicate(true)
	sorted_points.sort_custom(func(a, b):
		return float(a.get("t", 0.0)) < float(b.get("t", 0.0))
	)
	return sorted_points


func _get_collinear_overlap(a: Vector2, b: Vector2, c: Vector2, d: Vector2, tolerance: float = 0.25) -> Dictionary:
	var ab: Vector2 = b - a
	var cd: Vector2 = d - c
	var ab_len_sq: float = ab.length_squared()
	var cd_len_sq: float = cd.length_squared()
	if ab_len_sq <= 0.000001 or cd_len_sq <= 0.000001:
		return {"valid": false}
	var parallel_measure: float = absf(ab.cross(cd))
	var parallel_limit: float = tolerance * sqrt(ab_len_sq * cd_len_sq)
	if parallel_measure > parallel_limit:
		return {"valid": false}
	var line_limit: float = tolerance * sqrt(ab_len_sq)
	if absf((c - a).cross(ab)) > line_limit or absf((d - a).cross(ab)) > line_limit:
		return {"valid": false}
	var inv_ab_len_sq: float = 1.0 / ab_len_sq
	var t0: float = (c - a).dot(ab) * inv_ab_len_sq
	var t1: float = (d - a).dot(ab) * inv_ab_len_sq
	var start_t: float = maxf(0.0, minf(t0, t1))
	var end_t: float = minf(1.0, maxf(t0, t1))
	if end_t - start_t <= 0.001:
		return {"valid": false}
	var p0: Vector2 = a.lerp(b, start_t)
	var p1: Vector2 = a.lerp(b, end_t)
	var inv_cd_len_sq: float = 1.0 / cd_len_sq
	var u0: float = (p0 - c).dot(cd) * inv_cd_len_sq
	var u1: float = (p1 - c).dot(cd) * inv_cd_len_sq
	return {
		"valid": true,
		"a_p0": p0,
		"a_p1": p1,
		"a_t0": start_t,
		"a_t1": end_t,
		"b_p0": c.lerp(d, u0),
		"b_p1": c.lerp(d, u1),
		"b_t0": u0,
		"b_t1": u1
	}


func _append_point_if_distinct(points: PackedVector2Array, point: Vector2) -> PackedVector2Array:
	if points.is_empty() or points[points.size() - 1].distance_to(point) > 0.001:
		points.append(point)
	return points


func _append_fragment_to_runs(runs: Array, current_points: PackedVector2Array, a: Vector2, b: Vector2) -> Dictionary:
	var working: PackedVector2Array = current_points
	if working.is_empty():
		working.append(a)
		working.append(b)
		return {"runs": runs, "current": working}
	var tail: Vector2 = working[working.size() - 1]
	if tail.distance_to(a) <= 0.001:
		working = _append_point_if_distinct(working, b)
		return {"runs": runs, "current": working}
	if tail.distance_to(b) <= 0.001:
		working = _append_point_if_distinct(working, a)
		return {"runs": runs, "current": working}
	runs.append({"points": working, "closed": false})
	var restarted: PackedVector2Array = PackedVector2Array([a, b])
	return {"runs": runs, "current": restarted}


func _finalize_shared_runs(runs: Array, current_points: PackedVector2Array) -> Array:
	if not current_points.is_empty():
		runs.append({"points": current_points, "closed": false})
	if runs.size() > 1:
		var first: Dictionary = runs[0]
		var last: Dictionary = runs[runs.size() - 1]
		var first_points: PackedVector2Array = first.get("points", PackedVector2Array())
		var last_points: PackedVector2Array = last.get("points", PackedVector2Array())
		if first_points.size() >= 2 and last_points.size() >= 2 and last_points[last_points.size() - 1].distance_to(first_points[0]) <= 0.001:
			var merged: PackedVector2Array = PackedVector2Array()
			for point in last_points:
				merged = _append_point_if_distinct(merged, point)
			for i in range(1, first_points.size()):
				merged = _append_point_if_distinct(merged, first_points[i])
			runs[runs.size() - 1] = {"points": merged, "closed": false}
			runs.remove_at(0)
	for i in range(runs.size()):
		var entry: Dictionary = runs[i]
		var points: PackedVector2Array = entry.get("points", PackedVector2Array())
		if points.size() >= 3 and points[0].distance_to(points[points.size() - 1]) <= 0.001:
			points.remove_at(points.size() - 1)
			entry["points"] = points
			entry["closed"] = true
			runs[i] = entry
	return runs


func _build_province_shared_runs_from_graph(province_data: Dictionary, edge_fragment_map: Dictionary, atomic_segments: Dictionary) -> Array:
	var runs: Array = []
	var current_points: PackedVector2Array = PackedVector2Array()
	var poly: PackedVector2Array = province_data.get("polygon", PackedVector2Array())
	for edge_index in range(poly.size()):
		var fragments: Array = edge_fragment_map.get(edge_index, [])
		if fragments.is_empty():
			if not current_points.is_empty():
				runs.append({"points": current_points, "closed": false})
				current_points = PackedVector2Array()
			continue
		var sorted_fragments: Array = fragments.duplicate(true)
		sorted_fragments.sort_custom(func(a, b):
			return float(a.get("t0", 0.0)) < float(b.get("t0", 0.0))
		)
		for fragment_any in sorted_fragments:
			var fragment: Dictionary = fragment_any
			var atomic_key: String = String(fragment.get("key", ""))
			var atomic_entry: Dictionary = atomic_segments.get(atomic_key, {})
			var province_ids: Array = atomic_entry.get("province_ids", [])
			if province_ids.size() < 2:
				if not current_points.is_empty():
					runs.append({"points": current_points, "closed": false})
					current_points = PackedVector2Array()
				continue
			var a: Vector2 = fragment.get("a", Vector2.ZERO)
			var b: Vector2 = fragment.get("b", Vector2.ZERO)
			var result: Dictionary = _append_fragment_to_runs(runs, current_points, a, b)
			runs = result.get("runs", runs)
			current_points = result.get("current", PackedVector2Array())
	return _finalize_shared_runs(runs, current_points)


func _collect_province_border_segments(province_nodes: Array) -> Dictionary:
	var provinces: Array = []
	var edge_records: Array = []
	var tolerance: float = 0.25
	for province_node_any in province_nodes:
		var province_node: Node = province_node_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		if not province_node.has_meta("province_data"):
			continue
		var province_state: Dictionary = province_node.get_meta("province_data")
		var province_id: int = int(province_state.get("id", -1))
		var poly: PackedVector2Array = _ensure_polygon_ccw(_get_logical_province_polygon(province_node))
		if poly.size() < 3:
			continue
		var province_entry := {
			"id": province_id,
			"polygon": poly,
			"node": province_node
		}
		provinces.append(province_entry)
		for edge_index in range(poly.size()):
			var a: Vector2 = poly[edge_index]
			var b: Vector2 = poly[(edge_index + 1) % poly.size()]
			if a.distance_to(b) <= 0.001:
				continue
			edge_records.append({
				"province_id": province_id,
				"edge_index": edge_index,
				"a": a,
				"b": b,
				"breakpoints": [
					{"point": a, "t": 0.0},
					{"point": b, "t": 1.0}
				]
			})
	for i in range(edge_records.size()):
		for j in range(i + 1, edge_records.size()):
			var rec_a: Dictionary = edge_records[i]
			var rec_b: Dictionary = edge_records[j]
			if int(rec_a.get("province_id", -1)) == int(rec_b.get("province_id", -1)):
				continue
			var overlap: Dictionary = _get_collinear_overlap(
				rec_a.get("a", Vector2.ZERO),
				rec_a.get("b", Vector2.ZERO),
				rec_b.get("a", Vector2.ZERO),
				rec_b.get("b", Vector2.ZERO),
				tolerance
			)
			if not bool(overlap.get("valid", false)):
				continue
			var rec_a_breakpoints: Array = rec_a.get("breakpoints", [])
			rec_a_breakpoints = _add_unique_breakpoint(rec_a_breakpoints, overlap.get("a_p0", Vector2.ZERO), float(overlap.get("a_t0", 0.0)), tolerance)
			rec_a_breakpoints = _add_unique_breakpoint(rec_a_breakpoints, overlap.get("a_p1", Vector2.ZERO), float(overlap.get("a_t1", 1.0)), tolerance)
			rec_a["breakpoints"] = rec_a_breakpoints
			edge_records[i] = rec_a
			var rec_b_breakpoints: Array = rec_b.get("breakpoints", [])
			rec_b_breakpoints = _add_unique_breakpoint(rec_b_breakpoints, overlap.get("b_p0", Vector2.ZERO), float(overlap.get("b_t0", 0.0)), tolerance)
			rec_b_breakpoints = _add_unique_breakpoint(rec_b_breakpoints, overlap.get("b_p1", Vector2.ZERO), float(overlap.get("b_t1", 1.0)), tolerance)
			rec_b["breakpoints"] = rec_b_breakpoints
			edge_records[j] = rec_b
	var atomic_segments: Dictionary = {}
	var province_edge_fragments: Dictionary = {}
	var shared_edge_keys: Dictionary = {}
	for record_any in edge_records:
		var record: Dictionary = record_any
		var province_id: int = int(record.get("province_id", -1))
		var edge_index: int = int(record.get("edge_index", -1))
		var breakpoints: Array = _sort_breakpoints(record.get("breakpoints", []))
		for point_index in range(breakpoints.size() - 1):
			var bp_a: Dictionary = breakpoints[point_index]
			var bp_b: Dictionary = breakpoints[point_index + 1]
			var a: Vector2 = bp_a.get("point", Vector2.ZERO)
			var b: Vector2 = bp_b.get("point", Vector2.ZERO)
			if a.distance_to(b) <= 0.001:
				continue
			var midpoint: Vector2 = (a + b) * 0.5
			if not _is_point_on_segment(midpoint, record.get("a", Vector2.ZERO), record.get("b", Vector2.ZERO), tolerance):
				continue
			var key: String = _edge_key(a, b)
			var entry: Dictionary = atomic_segments.get(key, {
				"a": a,
				"b": b,
				"province_ids": [],
				"fragments": []
			})
			var province_ids: Array = entry.get("province_ids", [])
			var present: bool = false
			for existing_id_any in province_ids:
				if int(existing_id_any) == province_id:
					present = true
					break
			if not present:
				province_ids.append(province_id)
			entry["province_ids"] = province_ids
			var fragments: Array = entry.get("fragments", [])
			fragments.append({
				"province_id": province_id,
				"edge_index": edge_index,
				"a": a,
				"b": b,
				"t0": float(bp_a.get("t", 0.0)),
				"t1": float(bp_b.get("t", 1.0))
			})
			entry["fragments"] = fragments
			atomic_segments[key] = entry
			var by_province: Dictionary = province_edge_fragments.get(province_id, {})
			var edge_fragments: Array = by_province.get(edge_index, [])
			edge_fragments.append({
				"key": key,
				"a": a,
				"b": b,
				"t0": float(bp_a.get("t", 0.0)),
				"t1": float(bp_b.get("t", 1.0))
			})
			by_province[edge_index] = edge_fragments
			province_edge_fragments[province_id] = by_province
	for atomic_key_any in atomic_segments.keys():
		var atomic_key: String = String(atomic_key_any)
		var atomic_entry: Dictionary = atomic_segments.get(atomic_key, {})
		var province_ids: Array = atomic_entry.get("province_ids", [])
		if province_ids.size() >= 2:
			shared_edge_keys[atomic_key] = true
	var province_runs: Dictionary = {}
	for province_any in provinces:
		var province_entry: Dictionary = province_any
		var province_id: int = int(province_entry.get("id", -1))
		var edge_fragment_map: Dictionary = province_edge_fragments.get(province_id, {})
		province_runs[province_id] = _build_province_shared_runs_from_graph(province_entry, edge_fragment_map, atomic_segments)
	return {
		"provinces": provinces,
		"atomic_segments": atomic_segments,
		"shared_edge_keys": shared_edge_keys,
		"province_runs": province_runs
	}


func _get_shared_segment_left_right_ids(a: Vector2, b: Vector2, province_ids: Array, province_centers: Dictionary) -> Dictionary:
	if province_ids.size() < 2:
		return {"left_id": -1, "right_id": -1}
	var tangent: Vector2 = b - a
	if tangent.length_squared() <= 0.000001:
		return {"left_id": int(province_ids[0]), "right_id": int(province_ids[1])}
	var normal: Vector2 = Vector2(-tangent.y, tangent.x).normalized()
	var mid: Vector2 = (a + b) * 0.5
	var id_a: int = int(province_ids[0])
	var id_b: int = int(province_ids[1])
	var center_a: Vector2 = province_centers.get(id_a, Vector2.ZERO)
	var center_b: Vector2 = province_centers.get(id_b, Vector2.ZERO)
	var score_a: float = (center_a - mid).dot(normal)
	var score_b: float = (center_b - mid).dot(normal)
	if score_a > score_b:
		return {"left_id": id_a, "right_id": id_b}
	if score_b > score_a:
		return {"left_id": id_b, "right_id": id_a}
	if id_a <= id_b:
		return {"left_id": id_a, "right_id": id_b}
	return {"left_id": id_b, "right_id": id_a}


func _walk_shared_display_run(start_node_key: String, start_segment_key: String, adjacency: Dictionary, atomic_segments: Dictionary, province_centers: Dictionary, visited: Dictionary) -> Dictionary:
	var segments: Array = []
	var current_node_key: String = start_node_key
	var current_segment_key: String = start_segment_key
	var closed: bool = false
	var guard: int = 0
	while current_segment_key != "" and guard < 4096:
		guard += 1
		if visited.has(current_segment_key):
			break
		visited[current_segment_key] = true
		var atomic_entry: Dictionary = atomic_segments.get(current_segment_key, {})
		var a: Vector2 = atomic_entry.get("a", Vector2.ZERO)
		var b: Vector2 = atomic_entry.get("b", Vector2.ZERO)
		var a_key: String = _vector_key(a)
		var b_key: String = _vector_key(b)
		var from_point: Vector2 = a
		var to_point: Vector2 = b
		var next_node_key: String = b_key
		if current_node_key == b_key:
			from_point = b
			to_point = a
			next_node_key = a_key
		var side_ids: Dictionary = _get_shared_segment_left_right_ids(from_point, to_point, atomic_entry.get("province_ids", []), province_centers)
		segments.append({
			"a": from_point,
			"b": to_point,
			"left_id": int(side_ids.get("left_id", -1)),
			"right_id": int(side_ids.get("right_id", -1))
		})
		if next_node_key == start_node_key:
			closed = true
			break
		var incident: Array = adjacency.get(next_node_key, [])
		if incident.size() != 2:
			break
		var next_segment_key: String = ""
		for incident_any in incident:
			var incident_entry: Dictionary = incident_any
			var candidate_key: String = String(incident_entry.get("segment_key", ""))
			if not visited.has(candidate_key):
				next_segment_key = candidate_key
				break
		if next_segment_key == "":
			break
		current_node_key = next_node_key
		current_segment_key = next_segment_key
	return {
		"segments": segments,
		"closed": closed
	}


func _split_shared_display_segments(oriented_segments: Array, closed: bool) -> Array:
	var runs: Array = []
	if oriented_segments.is_empty():
		return runs
	var current_left_id: int = int(oriented_segments[0].get("left_id", -1))
	var current_right_id: int = int(oriented_segments[0].get("right_id", -1))
	var current_points: PackedVector2Array = PackedVector2Array()
	current_points.append(oriented_segments[0].get("a", Vector2.ZERO))
	current_points.append(oriented_segments[0].get("b", Vector2.ZERO))
	for i in range(1, oriented_segments.size()):
		var segment: Dictionary = oriented_segments[i]
		var seg_left_id: int = int(segment.get("left_id", -1))
		var seg_right_id: int = int(segment.get("right_id", -1))
		var seg_a: Vector2 = segment.get("a", Vector2.ZERO)
		var seg_b: Vector2 = segment.get("b", Vector2.ZERO)
		var same_side_ids: bool = seg_left_id == current_left_id and seg_right_id == current_right_id
		var connects_to_tail: bool = current_points[current_points.size() - 1].distance_to(seg_a) <= 0.001
		if same_side_ids and connects_to_tail:
			current_points = _append_point_if_distinct(current_points, seg_b)
			continue
		var current_closed: bool = false
		if closed and current_points.size() >= 3 and current_points[0].distance_to(current_points[current_points.size() - 1]) <= 0.001:
			current_points.remove_at(current_points.size() - 1)
			current_closed = true
		runs.append({
			"points": current_points,
			"closed": current_closed,
			"left_id": current_left_id,
			"right_id": current_right_id
		})
		current_left_id = seg_left_id
		current_right_id = seg_right_id
		current_points = PackedVector2Array([seg_a, seg_b])
	var final_closed: bool = false
	if closed and current_points.size() >= 3 and current_points[0].distance_to(current_points[current_points.size() - 1]) <= 0.001:
		current_points.remove_at(current_points.size() - 1)
		final_closed = true
	runs.append({
		"points": current_points,
		"closed": final_closed,
		"left_id": current_left_id,
		"right_id": current_right_id
	})
	return runs


func _collect_shared_border_display_runs(border_graph: Dictionary, province_centers: Dictionary) -> Array:
	var runs: Array = []
	var atomic_segments: Dictionary = border_graph.get("atomic_segments", {})
	var adjacency: Dictionary = {}
	for atomic_key_any in atomic_segments.keys():
		var atomic_key: String = String(atomic_key_any)
		var atomic_entry: Dictionary = atomic_segments.get(atomic_key, {})
		var province_ids: Array = atomic_entry.get("province_ids", [])
		if province_ids.size() < 2:
			continue
		var a: Vector2 = atomic_entry.get("a", Vector2.ZERO)
		var b: Vector2 = atomic_entry.get("b", Vector2.ZERO)
		var a_key: String = _vector_key(a)
		var b_key: String = _vector_key(b)
		if not adjacency.has(a_key):
			adjacency[a_key] = []
		if not adjacency.has(b_key):
			adjacency[b_key] = []
		adjacency[a_key].append({"segment_key": atomic_key})
		adjacency[b_key].append({"segment_key": atomic_key})
	var visited: Dictionary = {}
	for node_key_any in adjacency.keys():
		var node_key: String = String(node_key_any)
		var incident: Array = adjacency.get(node_key, [])
		if incident.size() == 2:
			continue
		for incident_any in incident:
			var incident_entry: Dictionary = incident_any
			var segment_key: String = String(incident_entry.get("segment_key", ""))
			if segment_key == "" or visited.has(segment_key):
				continue
			var walked: Dictionary = _walk_shared_display_run(node_key, segment_key, adjacency, atomic_segments, province_centers, visited)
			var oriented_segments: Array = walked.get("segments", [])
			if oriented_segments.is_empty():
				continue
			for run_any in _split_shared_display_segments(oriented_segments, bool(walked.get("closed", false))):
				runs.append(run_any)
	for atomic_key_any in atomic_segments.keys():
		var atomic_key: String = String(atomic_key_any)
		var atomic_entry: Dictionary = atomic_segments.get(atomic_key, {})
		var province_ids: Array = atomic_entry.get("province_ids", [])
		if province_ids.size() < 2 or visited.has(atomic_key):
			continue
		var a: Vector2 = atomic_entry.get("a", Vector2.ZERO)
		var loop_walked: Dictionary = _walk_shared_display_run(_vector_key(a), atomic_key, adjacency, atomic_segments, province_centers, visited)
		var loop_segments: Array = loop_walked.get("segments", [])
		if loop_segments.is_empty():
			continue
		for run_any in _split_shared_display_segments(loop_segments, bool(loop_walked.get("closed", false))):
			runs.append(run_any)
	return runs


func _build_shared_border_centerline(points: PackedVector2Array, closed: bool) -> PackedVector2Array:
	if closed:
		if points.size() < 3:
			return PackedVector2Array()
		return make_smoothed_province_display_polyline(_ensure_polygon_ccw(points), 0.0)
	if points.size() < 2:
		return PackedVector2Array()
	var smooth: PackedVector2Array = _smooth_open_province_polyline(points)
	return _extend_open_polyline(smooth, get_province_shared_border_run_extension())


func _build_shared_border_side_line(center_points: PackedVector2Array, offset: float, closed: bool) -> PackedVector2Array:
	if closed:
		return center_points
	return _offset_open_polyline(center_points, offset)


func _polyline_side_score(points: PackedVector2Array, probe_point: Vector2) -> float:
	if points.size() < 2:
		return 0.0
	var score: float = 0.0
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var tangent: Vector2 = b - a
		if tangent.length_squared() <= 0.000001:
			continue
		var normal: Vector2 = Vector2(-tangent.y, tangent.x).normalized()
		var mid: Vector2 = (a + b) * 0.5
		score += (probe_point - mid).dot(normal)
	return score


func _offset_open_polyline(points: PackedVector2Array, offset: float) -> PackedVector2Array:
	if points.size() < 2 or absf(offset) <= 0.001:
		return points
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(points.size()):
		var prev: Vector2 = points[maxi(i - 1, 0)]
		var nxt: Vector2 = points[mini(i + 1, points.size() - 1)]
		var tangent: Vector2 = nxt - prev
		if tangent.length_squared() <= 0.000001 and i < points.size() - 1:
			tangent = points[i + 1] - points[i]
		elif tangent.length_squared() <= 0.000001 and i > 0:
			tangent = points[i] - points[i - 1]
		if tangent.length_squared() <= 0.000001:
			out.append(points[i])
			continue
		var normal: Vector2 = Vector2(-tangent.y, tangent.x).normalized()
		out.append(points[i] + normal * offset)
	return out


func _extend_open_polyline(points: PackedVector2Array, extension: float) -> PackedVector2Array:
	if points.size() < 2 or extension <= 0.001:
		return points
	var out: PackedVector2Array = PackedVector2Array(points)
	var first_dir: Vector2 = points[1] - points[0]
	if first_dir.length_squared() > 0.000001:
		out[0] = points[0] - first_dir.normalized() * extension
	var last_index: int = points.size() - 1
	var last_dir: Vector2 = points[last_index] - points[last_index - 1]
	if last_dir.length_squared() > 0.000001:
		out[last_index] = points[last_index] + last_dir.normalized() * extension
	return out


func _add_shared_border_line(parent: Node2D, name: String, points: PackedVector2Array, width: float, color: Color, z_index: int, closed: bool = false) -> void:
	if parent == null:
		return
	if closed:
		if points.size() < 3:
			return
	else:
		if points.size() < 2:
			return
	var line := Line2D.new()
	line.name = name
	line.points = points
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.closed = closed
	line.z_index = z_index
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.round_precision = 8
	parent.add_child(line)

func _add_shared_border_underlay_line(parent: Node2D, name: String, points: PackedVector2Array, width: float, color: Color, z_index: int, closed: bool = false) -> void:
	var underlay_color: Color = color
	underlay_color.a = clampf(color.a, 0.0, 1.0)
	_add_shared_border_line(parent, name, points, width, underlay_color, z_index, closed)


func _add_shared_border_ownership_fill_line(parent: Node2D, name: String, points: PackedVector2Array, width: float, color: Color, z_index: int, closed: bool = false) -> void:
	var fill_color: Color = color
	fill_color.a = clampf(color.a, 0.0, 1.0)
	_add_shared_border_line(parent, name, points, width, fill_color, z_index, closed)


func _collect_province_shared_boundary_runs(province_node: Node, border_graph: Dictionary) -> Array:
	var runs: Array = []
	if province_node == null or not is_instance_valid(province_node):
		return runs
	if not province_node.has_meta("province_data"):
		return runs
	var province_data: Dictionary = province_node.get_meta("province_data")
	var province_id: int = int(province_data.get("id", -1))
	var province_runs: Dictionary = border_graph.get("province_runs", {})
	return province_runs.get(province_id, [])


func _build_province_shared_inset_data(points: PackedVector2Array, province_center: Vector2, inset_distance: float, closed: bool) -> Dictionary:
	if closed:
		if points.size() < 3:
			return {"points": PackedVector2Array(), "inward_sign": 1.0}
		return {
			"points": make_smoothed_province_display_polyline(_ensure_polygon_ccw(points), inset_distance),
			"inward_sign": 1.0
		}
	if points.size() < 2:
		return {"points": PackedVector2Array(), "inward_sign": 1.0}
	var smooth: PackedVector2Array = _smooth_open_province_polyline(points)
	if smooth.size() < 2:
		return {"points": PackedVector2Array(), "inward_sign": 1.0}
	smooth = _extend_open_polyline(smooth, get_province_shared_border_run_extension())
	var inward_score: float = _polyline_side_score(smooth, province_center)
	var offset_sign: float = 1.0 if inward_score >= 0.0 else -1.0
	return {
		"points": _offset_open_polyline(smooth, inset_distance * offset_sign),
		"inward_sign": offset_sign
	}


func _build_province_shared_inset_line(points: PackedVector2Array, province_center: Vector2, inset_distance: float, closed: bool) -> PackedVector2Array:
	var inset_data: Dictionary = _build_province_shared_inset_data(points, province_center, inset_distance, closed)
	return inset_data.get("points", PackedVector2Array())

func _build_open_ribbon_polygon(points: PackedVector2Array, start_offset: float, end_offset: float) -> PackedVector2Array:
	if points.size() < 2:
		return PackedVector2Array()
	var side_a: PackedVector2Array = _offset_open_polyline(points, start_offset)
	var side_b: PackedVector2Array = _offset_open_polyline(points, end_offset)
	if side_a.size() < 2 or side_b.size() < 2:
		return PackedVector2Array()
	var poly: PackedVector2Array = PackedVector2Array()
	for point in side_a:
		poly.append(point)
	for i in range(side_b.size() - 1, -1, -1):
		poly.append(side_b[i])
	return poly


func _add_shared_border_strip(parent: Node2D, name: String, center_points: PackedVector2Array, inner_offset: float, outer_offset: float, color: Color, z_index: int) -> void:
	if parent == null or center_points.size() < 2:
		return
	var poly_points: PackedVector2Array = _build_open_ribbon_polygon(center_points, inner_offset, outer_offset)
	if poly_points.size() < 3:
		return
	var poly := Polygon2D.new()
	poly.name = name
	poly.polygon = poly_points
	poly.color = color
	poly.z_index = z_index
	parent.add_child(poly)


func _add_locked_province_inner_line(parent: Node2D, name: String, points: PackedVector2Array, width: float, color: Color, z_index: int) -> void:
	if parent == null or points.size() < 2:
		return
	var line := Line2D.new()
	line.name = name
	line.points = points
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.closed = false
	line.z_index = z_index
	parent.add_child(line)


func _set_locked_province_inner_overlay_color(color: Color) -> void:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return
	var overlay: Node2D = _main.provinces_root.get_node_or_null("SharedProvinceBorderOverlay") as Node2D
	if overlay == null:
		return
	var locked_overlay: Node2D = overlay.get_node_or_null(LOCKED_PROVINCE_INNER_OVERLAY_NAME) as Node2D
	if locked_overlay == null:
		return
	for child in locked_overlay.get_children():
		if child is Line2D:
			(child as Line2D).default_color = color


func _refresh_locked_province_inner_overlay(parent: Node2D, display_runs: Array, active_locked_id: int, base_color: Color) -> void:
	if parent == null:
		return
	var locked_overlay: Node2D = parent.get_node_or_null(LOCKED_PROVINCE_INNER_OVERLAY_NAME) as Node2D
	if locked_overlay == null:
		locked_overlay = Node2D.new()
		locked_overlay.name = LOCKED_PROVINCE_INNER_OVERLAY_NAME
		_set_canvas_item_layer(locked_overlay, PROVINCE_BORDER_OVERLAYS_Z_INDEX, false)
		parent.add_child(locked_overlay)
	for child in locked_overlay.get_children():
		locked_overlay.remove_child(child)
		child.free()
	if active_locked_id < 0:
		return
	var pulse_width: float = maxf(0.1, LevelConfig.PROVINCE_SHARED_BORDER_WIDTH)
	for run_idx in range(display_runs.size()):
		var run_data: Dictionary = display_runs[run_idx]
		var closed: bool = bool(run_data.get("closed", false))
		var left_id: int = int(run_data.get("left_id", -1))
		var right_id: int = int(run_data.get("right_id", -1))
		var line_points: PackedVector2Array = PackedVector2Array()
		if left_id == active_locked_id:
			line_points = run_data.get("left_points", PackedVector2Array())
		elif right_id == active_locked_id:
			line_points = run_data.get("right_points", PackedVector2Array())
		else:
			continue
		if closed and line_points.size() < 3:
			continue
		if not closed and line_points.size() < 2:
			continue
		_add_shared_border_line(locked_overlay, "LockedProvinceInner_%d" % run_idx, line_points, pulse_width, base_color, 0, closed)

func _refresh_shared_province_border_overlay() -> void:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return
	var overlay: Node2D = _main.provinces_root.get_node_or_null("SharedProvinceBorderOverlay") as Node2D
	if overlay == null:
		overlay = Node2D.new()
		overlay.name = "SharedProvinceBorderOverlay"
		_set_canvas_item_layer(overlay, PROVINCE_BORDERS_Z_INDEX, false)
		_main.provinces_root.add_child(overlay)
	_mark_province_node_cache_dirty()
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.free()
	var province_nodes: Array = _get_cached_province_nodes()
	var geometry_signature: int = _compute_shared_border_overlay_geometry_signature(province_nodes)
	if geometry_signature != _shared_border_overlay_geometry_signature or _shared_border_overlay_cached_display_runs.is_empty():
		_shared_border_overlay_cached_display_runs = _build_cached_shared_border_display_runs(province_nodes)
		_shared_border_overlay_geometry_signature = geometry_signature
	var province_colors: Dictionary = {}
	var province_fill_colors: Dictionary = {}
	for province_node_any in province_nodes:
		var province_node: Node = province_node_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		var province_data: Dictionary = province_node.get_meta("province_data") if province_node.has_meta("province_data") else {}
		var province_id: int = int(province_data.get("id", -1))
		var fill_node: Polygon2D = get_province_fill_node(province_node)
		var fill_color: Color = fill_node.color if fill_node != null else LevelConfig.PROVINCE_BORDER_COLOR
		province_fill_colors[province_id] = fill_color
		province_colors[province_id] = get_province_border_line_color(fill_color)
	var line_width: float = get_province_shared_border_width()
	var band_width: float = get_province_shared_border_band_width()
	var ownership_fill_width: float = get_province_shared_ownership_fill_width()
	var active_locked_id: int = _main._locked_province_id_after_win if _main._current_phase == "grand_map" else -1
	var locked_inner_color := Color(1.0, 1.0, 1.0, 0.95)
	for run_idx in range(_shared_border_overlay_cached_display_runs.size()):
		var run_data: Dictionary = _shared_border_overlay_cached_display_runs[run_idx]
		var closed: bool = bool(run_data.get("closed", false))
		var left_id: int = int(run_data.get("left_id", -1))
		var right_id: int = int(run_data.get("right_id", -1))
		var left_points: PackedVector2Array = run_data.get("left_points", PackedVector2Array())
		var right_points: PackedVector2Array = run_data.get("right_points", PackedVector2Array())
		if left_id >= 0 and ((closed and left_points.size() >= 3) or (not closed and left_points.size() >= 2)):
			var left_border_color: Color = province_colors.get(left_id, LevelConfig.PROVINCE_BORDER_COLOR)
			var left_fill_color: Color = province_fill_colors.get(left_id, left_border_color)
			_add_shared_border_ownership_fill_line(overlay, "SharedProvinceOwnershipLeft_%d" % run_idx, left_points, ownership_fill_width, left_fill_color, 2, closed)
			_add_shared_border_underlay_line(overlay, "SharedProvinceBandLeft_%d" % run_idx, left_points, band_width, left_border_color, 3, closed)
			_add_shared_border_line(overlay, "SharedProvinceBorderLeft_%d" % run_idx, left_points, line_width, left_border_color, 0, closed)
		if right_id >= 0 and ((closed and right_points.size() >= 3) or (not closed and right_points.size() >= 2)):
			var right_border_color: Color = province_colors.get(right_id, LevelConfig.PROVINCE_BORDER_COLOR)
			var right_fill_color: Color = province_fill_colors.get(right_id, right_border_color)
			_add_shared_border_ownership_fill_line(overlay, "SharedProvinceOwnershipRight_%d" % run_idx, right_points, ownership_fill_width, right_fill_color, 2, closed)
			_add_shared_border_underlay_line(overlay, "SharedProvinceBandRight_%d" % run_idx, right_points, band_width, right_border_color, 3, closed)
			_add_shared_border_line(overlay, "SharedProvinceBorderRight_%d" % run_idx, right_points, line_width, right_border_color, 0, closed)
	_refresh_locked_province_inner_overlay(overlay, _shared_border_overlay_cached_display_runs, active_locked_id, locked_inner_color)


func format_province_counts_text(province_state: Dictionary) -> String:
	var troops: int = int(province_state.get("remaining_troops", 0))
	var buildings: int = int(province_state.get("remaining_buildings", 0))
	var invading_troops: int = int(province_state.get("invading_troops", 0))
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
		return "T:%d  B:%d  INV:%d" % [troops, buildings, invading_troops]
	return "T:%d  B:%d" % [troops, buildings]


func refresh_province_label_layout(province_node: Node, province_id: int, province_state: Dictionary) -> void:
	var counts_bg: Control = get_province_counts_background_node(province_node)
	var counts_label: Label = get_province_counts_label_node(province_node)
	if counts_bg == null and counts_label == null:
		return
	ensure_province_counts_draw_order(counts_bg, counts_label)

	var box_size: Vector2 = get_province_info_box_size(province_state)
	var center: Vector2 = get_label_display_center(province_node, counts_bg, counts_label, box_size)
	var top_left: Vector2 = center - box_size * 0.5
	var fill: Polygon2D = get_province_fill_node(province_node)
	var visuals_color: Color = fill.color if fill != null else get_base_province_fill_color(province_state, province_id)

	var panel_root: Control = _get_province_info_panel_root(province_node)
	if panel_root != null:
		panel_root.position = top_left
		_refresh_province_info_panel(panel_root, province_id, province_state)
		_layout_province_building_visuals(province_node, province_state, top_left, box_size, visuals_color)
		return

	if counts_bg != null:
		counts_bg.position = top_left
		counts_bg.size = box_size

	if counts_label != null:
		counts_label.position = top_left
		counts_label.size = box_size
		counts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		counts_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		counts_label.clip_text = false
		counts_label.text = get_province_info_text(province_id, province_state)
	_layout_province_building_visuals(province_node, province_state, top_left, box_size, visuals_color)

func cache_ball_end_world_pos(pos: Vector2) -> void:
	if _main == null:
		return
	_main._last_ball_end_world_pos = pos
	_main._has_last_ball_end_world_pos = true


func resolve_ball_end_world_pos() -> Vector2:
	if _main == null:
		return Vector2.ZERO
	if _main._has_last_ball_end_world_pos:
		return _main._last_ball_end_world_pos
	if _main.ball and is_instance_valid(_main.ball):
		return _main.ball.global_position
	return Vector2.ZERO


func clear_cached_ball_end_world_pos() -> void:
	if _main == null:
		return
	_main._has_last_ball_end_world_pos = false
	_main._last_ball_end_world_pos = Vector2.ZERO

func get_province_capture_source_by_id(province_id: int) -> String:
	if _main == null:
		return CAPTURE_SOURCE_NONE
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return CAPTURE_SOURCE_NONE
	var state: Dictionary = _main._province_persistence[index]
	return String(state.get("capture_source", CAPTURE_SOURCE_NONE))


func set_province_capture_source_by_id(province_id: int, capture_source: String) -> void:
	if _main == null:
		return
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return
	var normalized: String = String(capture_source)
	var state: Dictionary = _main._province_persistence[index]
	state["capture_source"] = normalized
	if is_instance_valid(_main.provinces_root):
		var province_node: Node = _get_cached_province_node_by_id(province_id)
		if province_node != null and province_node.has_meta("province_data"):
			var meta_data: Dictionary = province_node.get_meta("province_data")
			meta_data["capture_source"] = normalized
			province_node.set_meta("province_data", meta_data)


func clear_province_capture_source_by_id(province_id: int) -> void:
	set_province_capture_source_by_id(province_id, CAPTURE_SOURCE_NONE)


func mark_province_captured_by_player_engagement(province_id: int) -> void:
	set_province_capture_source_by_id(province_id, CAPTURE_SOURCE_PLAYER_ENGAGEMENT)


func mark_province_captured_by_friendly_march(province_id: int) -> void:
	set_province_capture_source_by_id(province_id, CAPTURE_SOURCE_FRIENDLY_MARCH)


func count_friendly_provinces_captured_by_player_engagement() -> int:
	if _main == null:
		return 0
	var count: int = 0
	for province_state in _main._province_persistence:
		if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		if String(province_state.get("capture_source", CAPTURE_SOURCE_NONE)) == CAPTURE_SOURCE_PLAYER_ENGAGEMENT:
			count += 1
	return count



func get_province_type_from_node(province_node: Node) -> String:
	if not is_instance_valid(province_node):
		return LevelConfig.PROVINCE_TYPE_NEUTRAL
	if province_node.has_meta("province_data"):
		var meta_data: Dictionary = province_node.get_meta("province_data")
		return String(meta_data.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var fill: Polygon2D = get_province_fill_node(province_node)
	if fill == null:
		return LevelConfig.PROVINCE_TYPE_NEUTRAL
	if fill.color == LevelConfig.PROVINCE_FRIENDLY_INVADED_COLOR:
		return LevelConfig.PROVINCE_TYPE_FRIENDLY
	if fill.color == LevelConfig.PROVINCE_FRIENDLY_COLOR:
		return LevelConfig.PROVINCE_TYPE_FRIENDLY
	for neutral_color in LevelConfig.PROVINCE_FILL_COLORS:
		if fill.color == neutral_color:
			return LevelConfig.PROVINCE_TYPE_NEUTRAL
	return LevelConfig.PROVINCE_TYPE_ENEMY


func normalize_neighbor_ids(raw_neighbors) -> Array[int]:
	var out: Array[int] = []
	if raw_neighbors is Array:
		for n in raw_neighbors:
			out.append(int(n))
	return out


func province_has_friendly_neighbor(province_state: Dictionary) -> bool:
	if _main == null:
		return false
	for neighbor_id in normalize_neighbor_ids(province_state.get("neighbors", [])):
		var neighbor_index: int = find_persistence_index_by_id(int(neighbor_id))
		if neighbor_index == -1:
			continue
		var neighbor_state: Dictionary = _main._province_persistence[neighbor_index]
		if String(neighbor_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return true
	return false


func get_total_friendly_gold_income() -> int:
	if _main == null:
		return 0
	var total: int = 0
	for province_state in _main._province_persistence:
		if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		total += get_province_gold_production(province_state)
	return total


func polygons_share_edge(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() < 2 or b.size() < 2:
		return false
	var shared_points: Array[Vector2] = []
	for pa in a:
		var va: Vector2 = pa
		var already_counted: bool = false
		for sp in shared_points:
			if va.distance_to(sp) <= 0.5:
				already_counted = true
				break
		if already_counted:
			continue
		for pb in b:
			var vb: Vector2 = pb
			if va.distance_to(vb) <= 0.5:
				shared_points.append(va)
				if shared_points.size() >= 2:
					return true
				break
	return false


func apply_persistence_to_province_visuals() -> void:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return

	var province_nodes: Array = _get_cached_province_nodes()
	for province_node in province_nodes:
		if not is_instance_valid(province_node):
			continue

		var province_id: int = -1
		var tint_idx: int = 0
		if province_node.has_meta("province_data"):
			var meta_data: Dictionary = province_node.get_meta("province_data")
			province_id = int(meta_data.get("id", -1))
			tint_idx = int(meta_data.get("tint_index", 0))

		var province_index: int = find_persistence_index_by_id(province_id)
		if province_index == -1:
			continue

		var province_state: Dictionary = _main._province_persistence[province_index]
		var is_target: bool = is_target_province_state(province_state)
		var is_boss_home: bool = is_boss_home_province_state(province_state)
		var base_fill_color: Color = get_base_province_fill_color(province_state, tint_idx)
		var is_locked_launch_province: bool = (_main._current_phase == "grand_map" and province_id == _main._locked_province_id_after_win)

		if province_node.has_meta("province_data"):
			var synced_meta: Dictionary = province_node.get_meta("province_data")
			synced_meta["type"] = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
			synced_meta[PROVINCE_NAME_KEY] = _resolve_province_name(province_id, province_state, synced_meta)
			synced_meta["troops"] = int(province_state.get("remaining_troops", 0))
			synced_meta["buildings"] = int(province_state.get("remaining_buildings", 0))
			synced_meta["invading_troops"] = int(province_state.get("invading_troops", 0))
			synced_meta["faction_id"] = int(province_state.get("faction_id", 0))
			synced_meta["construction_progress"] = int(province_state.get("construction_progress", 0))
			synced_meta["neighbors"] = normalize_neighbor_ids(province_state.get("neighbors", []))
			synced_meta["is_target"] = is_target
			synced_meta["capture_source"] = String(province_state.get("capture_source", CAPTURE_SOURCE_NONE))
			synced_meta[BOSS_HOME_FLAG_KEY] = is_boss_home
			synced_meta[CALTROPS_KEY] = _normalize_caltrop_entries(province_state.get(CALTROPS_KEY, []))
			synced_meta[PROVINCE_GOLD_PRODUCTION_KEY] = get_province_gold_production(province_state)
			synced_meta[PROVINCE_FREE_BUILDINGS_KEY] = get_province_free_buildings(province_state)
			synced_meta[PROVINCE_BUILDING_CAPACITY_KEY] = get_province_building_capacity(province_state)
			synced_meta[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = get_province_engagement_map_type(province_state)
			province_node.set_meta("province_data", synced_meta)

		var fill: Polygon2D = get_province_fill_node(province_node)
		var cached_geometry: Dictionary = {}
		if fill != null:
			fill.name = "ProvinceFill"
			_set_canvas_item_layer(fill, PROVINCE_FILL_Z_INDEX, false)
			if is_locked_launch_province:
				var highlighted_fill: Color = base_fill_color.lightened(0.38)
				highlighted_fill.a = minf(0.72, base_fill_color.a + 0.24)
				fill.color = highlighted_fill
			else:
				fill.color = base_fill_color
			cached_geometry = _ensure_cached_province_display_geometry(province_node, fill)
			var pattern_overlay: Polygon2D = _ensure_locked_province_pattern_overlay_node(province_node)
			if pattern_overlay != null:
				pattern_overlay.polygon = fill.polygon
				pattern_overlay.texture = _get_locked_province_pattern_texture()
				pattern_overlay.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
				pattern_overlay.texture_scale = Vector2.ONE
				var pattern_color: Color = LevelConfig.get_province_launch_pattern_color()
				pattern_color.a = LevelConfig.get_province_launch_pattern_opacity()
				pattern_overlay.color = pattern_color
				pattern_overlay.antialiased = true
				pattern_overlay.z_index = PROVINCE_BORDER_OVERLAYS_Z_INDEX
				pattern_overlay.visible = is_locked_launch_province

		var target_overlay: Polygon2D = get_province_target_overlay_node(province_node)
		if target_overlay != null:
			_set_canvas_item_layer(target_overlay, PROVINCE_BORDER_OVERLAYS_Z_INDEX, false)
			target_overlay.visible = is_target
			if is_target:
				var overlay_color: Color = LevelConfig.TARGET_PROVINCE_FILL_TINT
				if is_locked_launch_province:
					overlay_color = overlay_color.lightened(0.15)
				target_overlay.color = overlay_color

		var fill_node: Polygon2D = get_province_fill_node(province_node)
		var border_line_color: Color = get_province_border_line_color(base_fill_color)
		if is_locked_launch_province:
			border_line_color = border_line_color.lightened(0.08)

		var border: Line2D = get_province_border_node(province_node)
		if border != null:
			border.name = "ProvinceBorder"
			_set_canvas_item_layer(border, PROVINCE_BORDERS_Z_INDEX, false)
			border.default_color = border_line_color
			border.width = get_province_outer_line_width()
			border.visible = false
			if fill_node != null:
				var border_points: PackedVector2Array = cached_geometry.get("border_points", PackedVector2Array())
				if border_points.is_empty():
					border_points = make_smoothed_province_display_polyline(fill_node.polygon, maxf(0.5, get_province_outer_line_width() * 0.5))
				border.points = border_points

		var inner_glow: Line2D = ensure_province_inner_glow_node(province_node)
		if inner_glow != null:
			inner_glow.name = "ProvinceInnerGlow"
			inner_glow.width = get_province_inner_line_width()
			inner_glow.antialiased = true
			inner_glow.closed = true
			_set_canvas_item_layer(inner_glow, PROVINCE_BORDER_OVERLAYS_Z_INDEX, false)
			if fill_node != null:
				var inner_points: PackedVector2Array = cached_geometry.get("inner_points", PackedVector2Array())
				if inner_points.is_empty():
					inner_points = make_smoothed_province_display_polyline(fill_node.polygon, maxf(0.5, get_province_outer_line_width() * 0.5 + get_province_inner_line_inset()))
				inner_glow.points = inner_points
			var pulse_base_color: Color = border_line_color
			pulse_base_color.a = 1.0
			inner_glow.default_color = pulse_base_color
			inner_glow.visible = false

		_layout_province_troop_visuals(province_node, province_state, base_fill_color)
		_enforce_province_line_visibility(province_node, false)

		var counts_bg: Control = get_province_counts_background_node(province_node)
		var counts_label: Label = get_province_counts_label_node(province_node)
		ensure_province_counts_draw_order(counts_bg, counts_label)

		var panel_root: Control = _get_province_info_panel_root(province_node)
		if panel_root == null:
			var legacy_bg: ColorRect = counts_bg as ColorRect
			if legacy_bg != null:
				if is_boss_home:
					legacy_bg.color = BOSS_HOME_INFO_BOX_BG_COLOR.lightened(0.06) if is_locked_launch_province else BOSS_HOME_INFO_BOX_BG_COLOR
				elif is_target:
					legacy_bg.color = LevelConfig.TARGET_PROVINCE_INFO_BOX_BG_COLOR.lightened(0.08) if is_locked_launch_province else LevelConfig.TARGET_PROVINCE_INFO_BOX_BG_COLOR
				else:
					legacy_bg.color = Color(0.22, 0.18, 0.06, 0.82) if is_locked_launch_province else LevelConfig.PROVINCE_INFO_BOX_BG_COLOR

			if counts_label != null:
				counts_label.add_theme_font_size_override("font_size", LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE)
				var label_color: Color = LevelConfig.PROVINCE_INFO_TEXT_COLOR
				if is_boss_home:
					label_color = BOSS_HOME_INFO_TEXT_COLOR
				elif is_target:
					label_color = LevelConfig.TARGET_PROVINCE_INFO_TEXT_COLOR
				counts_label.add_theme_color_override("font_color", label_color)
				counts_label.add_theme_constant_override("outline_size", LevelConfig.PROVINCE_INFO_OUTLINE_SIZE)
				counts_label.add_theme_color_override("font_outline_color", LevelConfig.PROVINCE_INFO_OUTLINE_COLOR)

		refresh_province_label_layout(province_node, province_id, province_state)

	_refresh_shared_province_border_overlay()


func play_boss_attack_province_opacity_pulses(province_ids: Array[int]) -> void:
	if _main == null or province_ids.is_empty():
		return
	var pulse_seconds: float = LevelConfig.get_boss_attack_province_opacity_pulse_seconds()
	if pulse_seconds <= 0.0:
		return
	for province_id in province_ids:
		_play_single_boss_attack_province_opacity_pulse(int(province_id), pulse_seconds)


func _play_single_boss_attack_province_opacity_pulse(province_id: int, pulse_seconds: float) -> void:
	if province_id < 0:
		return
	var province_node: Node = _get_cached_province_node_by_id(province_id)
	if province_node == null or not is_instance_valid(province_node):
		return

	var province_index: int = find_persistence_index_by_id(province_id)
	if province_index < 0 or province_index >= _main._province_persistence.size():
		return
	var province_state: Dictionary = _main._province_persistence[province_index]
	var tint_idx: int = 0
	if province_node.has_meta("province_data"):
		var meta_data: Dictionary = province_node.get_meta("province_data")
		tint_idx = int(meta_data.get("tint_index", 0))

	var fill: Polygon2D = get_province_fill_node(province_node)
	if fill == null:
		return

	var current_alpha: float = clampf(fill.color.a, 0.0, 1.0)
	var base_color: Color = get_base_province_fill_color(province_state, tint_idx)
	base_color.a = current_alpha
	fill.color = base_color

	var peak_color: Color = base_color
	peak_color.a = 1.0

	var half_duration: float = maxf(0.01, pulse_seconds * 0.5)
	var tween: Tween = _main.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(fill, "color", peak_color, half_duration)
	tween.tween_property(fill, "color", base_color, half_duration)


func update_launch_province_pulse(time_seconds: float) -> void:
	# Kept for compatibility with existing callers; launch highlighting now uses
	# a persistent diamond fill pattern instead of a pulsing border line.
	_launch_pulse_last_quantized_step = int(floor(time_seconds / maxf(0.01, LAUNCH_PULSE_QUANTIZE_STEP_SECONDS)))


# =============================================================================
# UNIFIED CONTEXT HELPER (used by resolver and Main)
# =============================================================================
func get_province_context(province_id: int) -> Dictionary:
	if _main == null or province_id == -1:
		return _make_empty_province_context(province_id)

	var index := find_persistence_index_by_id(province_id)
	if index == -1:
		return _make_empty_province_context(province_id)

	var state: Dictionary = _main._province_persistence[index]
	var caltrops: Array[Dictionary] = _normalize_caltrop_entries(state.get(CALTROPS_KEY, []))
	var active_caltrop_count: int = 0
	for caltrop in caltrops:
		if not bool(caltrop.get("destroyed", false)):
			active_caltrop_count += 1

	return {
		"id": int(state.get("id", province_id)),
		"type": String(state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
		PROVINCE_NAME_KEY: _resolve_province_name(province_id, state),
		"remaining_troops": int(state.get("remaining_troops", 0)),
		"remaining_buildings": int(state.get("remaining_buildings", 0)),
		"invading_troops": int(state.get("invading_troops", 0)),
		"faction_id": int(state.get("faction_id", 0)),
		"construction_progress": int(state.get("construction_progress", 0)),
		"is_target": bool(state.get("is_target", false)),
		"capture_source": String(state.get("capture_source", CAPTURE_SOURCE_NONE)),
		"neighbors": normalize_neighbor_ids(state.get("neighbors", [])),
		"is_boss_home": bool(state.get(BOSS_HOME_FLAG_KEY, false)),
		"caltrops": caltrops,
		"active_caltrop_count": active_caltrop_count,
		PROVINCE_GOLD_PRODUCTION_KEY: get_province_gold_production(state),
		PROVINCE_FREE_BUILDINGS_KEY: get_province_free_buildings(state),
		PROVINCE_BUILDING_CAPACITY_KEY: get_province_building_capacity(state),
		PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: get_province_engagement_map_type(state)
	}

func find_first_province_id_for_phase(requested_phase: String = "") -> int:
	if _main == null:
		return -1

	var enemy_fallback: int = -1
	var invaded_friendly_fallback: int = -1
	var neutral_fallback: int = -1
	var friendly_fallback: int = -1

	for p in _main._province_persistence:
		var province_id: int = int(p.get("id", -1))
		var province_type: String = String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		var invading_troops: int = int(p.get("invading_troops", 0))
		var relation: String = get_relation_to_player_for_province_state(p)

		match requested_phase:
			"offensive":
				if relation == RELATION_HOSTILE or relation == RELATION_ALLY:
					return province_id
			"defensive":
				if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
					return province_id
			"neutral":
				if province_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
					return province_id
			"grand_map":
				if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
					return province_id

		if enemy_fallback == -1 and (relation == RELATION_HOSTILE or relation == RELATION_ALLY):
			enemy_fallback = province_id
		if invaded_friendly_fallback == -1 and province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
			invaded_friendly_fallback = province_id
		if neutral_fallback == -1 and province_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
			neutral_fallback = province_id
		if friendly_fallback == -1 and province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			friendly_fallback = province_id

	match requested_phase:
		"offensive":
			return enemy_fallback
		"defensive":
			return invaded_friendly_fallback
		"neutral":
			return neutral_fallback
		"grand_map":
			if friendly_fallback != -1:
				return friendly_fallback
			return invaded_friendly_fallback

	if enemy_fallback != -1:
		return enemy_fallback
	if invaded_friendly_fallback != -1:
		return invaded_friendly_fallback
	if neutral_fallback != -1:
		return neutral_fallback
	return friendly_fallback


func make_stable_province_encounter_seed(province_id: int) -> int:
	if _main == null:
		return 1
	var mixed: int = int(hash("%d|province_encounter|%d" % [_main.map_seed, province_id]))
	mixed = mixed & 0x7fffffff
	return mixed if mixed != 0 else 1


func ensure_province_encounter_layout(province_id: int) -> Dictionary:
	if _main == null:
		return {
			"seed": 1,
			"level": 1,
			"map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		}

	var encounter_seed: int = make_stable_province_encounter_seed(province_id)
	var encounter_level: int = maxi(1, _main.level_index)
	var province_index: int = find_persistence_index_by_id(province_id)

	if province_index == -1:
		return {
			"seed": encounter_seed,
			"level": encounter_level,
			"map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		}

	var province_state: Dictionary = _main._province_persistence[province_index]

	encounter_seed = int(province_state.get("encounter_seed", 0))
	if encounter_seed == 0:
		encounter_seed = make_stable_province_encounter_seed(province_id)
		province_state["encounter_seed"] = encounter_seed

	encounter_level = int(province_state.get("encounter_level", 0))
	if encounter_level <= 0:
		encounter_level = maxi(1, _main.level_index)
		province_state["encounter_level"] = encounter_level

	return {
		"seed": encounter_seed,
		"level": encounter_level,
		"map_type": get_province_engagement_map_type(province_state)
	}

func sync_province_persistence() -> void:
	if _main == null:
		return

	if not is_instance_valid(_main.provinces_root):
		_main._province_persistence.clear()
		return

	var previous_by_id: Dictionary = {}
	for p in _main._province_persistence:
		var pid: int = int(p.get("id", -1))
		previous_by_id[pid] = {
			"id": pid,
			"type": String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			PROVINCE_NAME_KEY: String(p.get(PROVINCE_NAME_KEY, "")).strip_edges(),
			"remaining_buildings": int(p.get("remaining_buildings", LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_NEUTRAL))),
			"remaining_troops": int(p.get("remaining_troops", LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_NEUTRAL))),
			"neighbors": normalize_neighbor_ids(p.get("neighbors", [])),
			"invading_troops": int(p.get("invading_troops", 0)),
			"encounter_seed": int(p.get("encounter_seed", 0)),
			"encounter_level": int(p.get("encounter_level", 0)),
			"faction_id": int(p.get("faction_id", 0)),
			"construction_progress": int(p.get("construction_progress", 0)),
			"is_target": bool(p.get("is_target", false)),
			"capture_source": String(p.get("capture_source", CAPTURE_SOURCE_NONE)),
			"is_boss_home": bool(p.get(BOSS_HOME_FLAG_KEY, false)),
			"caltrops": _normalize_caltrop_entries(p.get(CALTROPS_KEY, [])),
			PROVINCE_GOLD_PRODUCTION_KEY: LevelConfig.clamp_province_gold_production(int(p.get(PROVINCE_GOLD_PRODUCTION_KEY, 0))),
			PROVINCE_FREE_BUILDINGS_KEY: LevelConfig.clamp_province_free_buildings(int(p.get(PROVINCE_FREE_BUILDINGS_KEY, 0))),
			PROVINCE_BUILDING_CAPACITY_KEY: LevelConfig.clamp_province_building_cap(int(p.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN))),
			PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: LevelConfig.normalize_engagement_map_type(String(p.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)))
		}

	var runtime_entries: Array[Dictionary] = []
	var polygons: Array[PackedVector2Array] = []

	for idx in range(_main.provinces_root.get_child_count()):
		var province_node: Node = _main.provinces_root.get_child(idx)
		if not is_instance_valid(province_node):
			continue
		if String(province_node.name) == "BossVisualRoot":
			continue
		var province_id: int = idx
		var province_type: String = get_province_type_from_node(province_node)
		var neighbors: Array[int] = []
		var meta_buildings: int = 0
		var meta_troops: int = 0
		var meta_province_name: String = ""
		var meta_invading_troops: int = 0
		var meta_faction_id: int = 0
		var meta_is_target: bool = false
		var meta_capture_source: String = CAPTURE_SOURCE_NONE
		var meta_construction_progress: int = 0
		var meta_is_boss_home: bool = false
		var meta_caltrops: Array[Dictionary] = []
		var meta_gold_production: int = 0
		var meta_free_buildings: int = 0
		var meta_building_capacity: int = LevelConfig.PROVINCE_BUILDING_CAP_MIN
		var meta_engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL

		if province_node.has_meta("province_data"):
			var meta_data: Dictionary = province_node.get_meta("province_data")
			province_id = int(meta_data.get("id", idx))
			province_type = String(meta_data.get("type", province_type))
			neighbors = normalize_neighbor_ids(meta_data.get("neighbors", []))
			meta_buildings = int(meta_data.get("buildings", 0))
			meta_troops = int(meta_data.get("troops", 0))
			meta_province_name = String(meta_data.get(PROVINCE_NAME_KEY, "")).strip_edges()
			meta_invading_troops = int(meta_data.get("invading_troops", 0))
			meta_faction_id = int(meta_data.get("faction_id", 0))
			meta_is_target = bool(meta_data.get("is_target", false))
			meta_capture_source = String(meta_data.get("capture_source", CAPTURE_SOURCE_NONE))
			meta_construction_progress = int(meta_data.get("construction_progress", 0))
			meta_is_boss_home = bool(meta_data.get(BOSS_HOME_FLAG_KEY, false))
			meta_caltrops = _normalize_caltrop_entries(meta_data.get(CALTROPS_KEY, []))
			meta_gold_production = LevelConfig.clamp_province_gold_production(int(meta_data.get(PROVINCE_GOLD_PRODUCTION_KEY, 0)))
			meta_free_buildings = LevelConfig.clamp_province_free_buildings(int(meta_data.get(PROVINCE_FREE_BUILDINGS_KEY, 0)))
			meta_building_capacity = LevelConfig.clamp_province_building_cap(int(meta_data.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN)))
			meta_engagement_map_type = LevelConfig.normalize_engagement_map_type(String(meta_data.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)))
			if province_type == LevelConfig.PROVINCE_TYPE_ENEMY and not meta_is_boss_home and not previous_by_id.has(province_id):
				meta_troops += _get_campaign_enemy_troop_level_bonus_total()

		var defaults: Dictionary = get_default_province_counts(province_type)
		if meta_buildings <= 0 and province_type != LevelConfig.PROVINCE_TYPE_NEUTRAL:
			meta_buildings = int(defaults.get("remaining_buildings", 0))
		if meta_troops <= 0 and province_type != LevelConfig.PROVINCE_TYPE_NEUTRAL:
			meta_troops = int(defaults.get("remaining_troops", 0))
		if province_type == LevelConfig.PROVINCE_TYPE_ENEMY and meta_faction_id <= 0:
			meta_faction_id = int(defaults.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT))

		var entry: Dictionary = {
			"id": province_id,
			"type": province_type,
			PROVINCE_NAME_KEY: meta_province_name if province_node.has_meta("province_data") else "",
			"remaining_buildings": meta_buildings if province_node.has_meta("province_data") else int(defaults.get("remaining_buildings", 0)),
			"remaining_troops": meta_troops if province_node.has_meta("province_data") else int(defaults.get("remaining_troops", 0)),
			"neighbors": neighbors,
			"invading_troops": meta_invading_troops if province_node.has_meta("province_data") else 0,
			"encounter_seed": 0,
			"encounter_level": 0,
			"faction_id": meta_faction_id if province_node.has_meta("province_data") else int(defaults.get("faction_id", 0)),
			"construction_progress": meta_construction_progress if province_node.has_meta("province_data") else int(defaults.get("construction_progress", 0)),
			"is_target": meta_is_target if province_node.has_meta("province_data") else false,
			"capture_source": meta_capture_source if province_node.has_meta("province_data") else CAPTURE_SOURCE_NONE,
			"is_boss_home": meta_is_boss_home if province_node.has_meta("province_data") else false,
			"caltrops": meta_caltrops if province_node.has_meta("province_data") else [],
			PROVINCE_GOLD_PRODUCTION_KEY: meta_gold_production if province_node.has_meta("province_data") else 0,
			PROVINCE_FREE_BUILDINGS_KEY: meta_free_buildings if province_node.has_meta("province_data") else 0,
			PROVINCE_BUILDING_CAPACITY_KEY: meta_building_capacity if province_node.has_meta("province_data") else LevelConfig.PROVINCE_BUILDING_CAP_MIN,
			PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: meta_engagement_map_type if province_node.has_meta("province_data") else LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		}

		if previous_by_id.has(province_id):
			var prev: Dictionary = previous_by_id[province_id]
			entry["type"] = String(prev.get("type", entry["type"]))
			if String(entry.get(PROVINCE_NAME_KEY, "")).strip_edges().is_empty():
				entry[PROVINCE_NAME_KEY] = String(prev.get(PROVINCE_NAME_KEY, "")).strip_edges()
			entry["remaining_buildings"] = int(prev.get("remaining_buildings", entry["remaining_buildings"]))
			entry["remaining_troops"] = int(prev.get("remaining_troops", entry["remaining_troops"]))
			entry["invading_troops"] = int(prev.get("invading_troops", 0))
			entry["encounter_seed"] = int(prev.get("encounter_seed", 0))
			entry["encounter_level"] = int(prev.get("encounter_level", 0))
			entry["faction_id"] = int(prev.get("faction_id", entry["faction_id"]))
			entry["construction_progress"] = int(prev.get("construction_progress", entry["construction_progress"]))
			entry["is_target"] = bool(prev.get("is_target", entry["is_target"]))
			entry["capture_source"] = String(prev.get("capture_source", entry.get("capture_source", CAPTURE_SOURCE_NONE)))
			entry["is_boss_home"] = bool(prev.get("is_boss_home", entry.get("is_boss_home", false)))
			entry["caltrops"] = _normalize_caltrop_entries(prev.get(CALTROPS_KEY, entry.get(CALTROPS_KEY, [])))
			entry[PROVINCE_GOLD_PRODUCTION_KEY] = LevelConfig.clamp_province_gold_production(int(prev.get(PROVINCE_GOLD_PRODUCTION_KEY, entry.get(PROVINCE_GOLD_PRODUCTION_KEY, 0))))
			entry[PROVINCE_FREE_BUILDINGS_KEY] = LevelConfig.clamp_province_free_buildings(int(prev.get(PROVINCE_FREE_BUILDINGS_KEY, entry.get(PROVINCE_FREE_BUILDINGS_KEY, 0))))
			entry[PROVINCE_BUILDING_CAPACITY_KEY] = LevelConfig.clamp_province_building_cap(int(prev.get(PROVINCE_BUILDING_CAPACITY_KEY, entry.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN))))
			entry[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = LevelConfig.normalize_engagement_map_type(String(prev.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, entry.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL))))

			var prev_neighbors: Array[int] = normalize_neighbor_ids(prev.get("neighbors", []))
			if neighbors.is_empty() and not prev_neighbors.is_empty():
				entry["neighbors"] = prev_neighbors

		entry[PROVINCE_NAME_KEY] = _resolve_province_name(province_id, entry)
		entry[CALTROPS_KEY] = _normalize_caltrop_entries(entry.get(CALTROPS_KEY, []))
		normalize_province_variation_state(province_id, entry)
		clamp_province_buildings_to_capacity(entry)
		runtime_entries.append(entry)

		var fill: Polygon2D = get_province_fill_node(province_node)
		if fill != null:
			polygons.append(fill.polygon)
		else:
			polygons.append(PackedVector2Array())

	for i in range(runtime_entries.size()):
		var existing_neighbors: Array[int] = normalize_neighbor_ids(runtime_entries[i].get("neighbors", []))
		if not existing_neighbors.is_empty():
			runtime_entries[i]["neighbors"] = existing_neighbors
			continue

		var inferred_neighbors: Array[int] = []
		for j in range(runtime_entries.size()):
			if i == j:
				continue
			if polygons_share_edge(polygons[i], polygons[j]):
				inferred_neighbors.append(int(runtime_entries[j].get("id", j)))
		runtime_entries[i]["neighbors"] = inferred_neighbors

	_main._province_persistence = runtime_entries
	apply_persistence_to_province_visuals()


func get_province_data(world_pos: Vector2) -> Dictionary:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return {
			"id": -1,
			"type": LevelConfig.PROVINCE_TYPE_NEUTRAL,
			"buildings": 0,
			"troops": 0,
			"neighbors": [],
			"invading_troops": 0,
			"faction_id": 0,
			"construction_progress": 0,
			PROVINCE_NAME_KEY: "",
			"is_target": false,
			"capture_source": CAPTURE_SOURCE_NONE,
			"is_boss_home": false,
			PROVINCE_GOLD_PRODUCTION_KEY: 0,
			PROVINCE_FREE_BUILDINGS_KEY: 0,
			PROVINCE_BUILDING_CAPACITY_KEY: LevelConfig.PROVINCE_BUILDING_CAP_MIN,
			PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		}

	var idx: int = 0
	for p_node in _main.provinces_root.get_children():
		var fill: Polygon2D = get_province_fill_node(p_node)
		if fill != null:
			var poly: PackedVector2Array = fill.polygon
			var local_pos: Vector2 = world_pos - p_node.global_position
			if Geometry2D.is_point_in_polygon(local_pos, poly):
				var province_id: int = idx
				var meta_data: Dictionary = {}
				if p_node.has_meta("province_data"):
					meta_data = p_node.get_meta("province_data")
					province_id = int(meta_data.get("id", idx))

				var province_index: int = find_persistence_index_by_id(province_id)
				if province_index != -1:
					var pers: Dictionary = _main._province_persistence[province_index]
					return {
						"id": int(pers.get("id", province_id)),
						"type": String(pers.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
						PROVINCE_NAME_KEY: _resolve_province_name(province_id, pers, meta_data),
						"buildings": int(pers.get("remaining_buildings", 0)),
						"troops": int(pers.get("remaining_troops", 0)),
						"neighbors": normalize_neighbor_ids(pers.get("neighbors", [])),
						"invading_troops": int(pers.get("invading_troops", 0)),
						"faction_id": int(pers.get("faction_id", 0)),
						"construction_progress": int(pers.get("construction_progress", 0)),
						"is_target": bool(pers.get("is_target", false)),
						"capture_source": String(pers.get("capture_source", CAPTURE_SOURCE_NONE)),
						"is_boss_home": bool(pers.get(BOSS_HOME_FLAG_KEY, false)),
						"caltrops": _normalize_caltrop_entries(pers.get(CALTROPS_KEY, [])),
						PROVINCE_GOLD_PRODUCTION_KEY: get_province_gold_production(pers),
						PROVINCE_FREE_BUILDINGS_KEY: get_province_free_buildings(pers),
						PROVINCE_BUILDING_CAPACITY_KEY: get_province_building_capacity(pers),
						PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: get_province_engagement_map_type(pers)
					}

				return {
					"id": province_id,
					"type": get_province_type_from_node(p_node),
					PROVINCE_NAME_KEY: _resolve_province_name(province_id, {}, meta_data),
					"buildings": 0,
					"troops": 0,
					"neighbors": [],
					"invading_troops": 0,
					"faction_id": 0,
					"construction_progress": int(meta_data.get("construction_progress", 0)),
					"is_target": bool(meta_data.get("is_target", false)),
					"capture_source": String(meta_data.get("capture_source", CAPTURE_SOURCE_NONE)),
					"is_boss_home": bool(meta_data.get(BOSS_HOME_FLAG_KEY, false)),
					"caltrops": _normalize_caltrop_entries(meta_data.get(CALTROPS_KEY, [])),
					PROVINCE_GOLD_PRODUCTION_KEY: LevelConfig.clamp_province_gold_production(int(meta_data.get(PROVINCE_GOLD_PRODUCTION_KEY, 0))),
					PROVINCE_FREE_BUILDINGS_KEY: LevelConfig.clamp_province_free_buildings(int(meta_data.get(PROVINCE_FREE_BUILDINGS_KEY, 0))),
					PROVINCE_BUILDING_CAPACITY_KEY: LevelConfig.clamp_province_building_cap(int(meta_data.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN))),
					PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: LevelConfig.normalize_engagement_map_type(String(meta_data.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)))
				}
		idx += 1

	return {
		"id": -1,
		"type": LevelConfig.PROVINCE_TYPE_NEUTRAL,
		"buildings": 0,
		"troops": 0,
		"neighbors": [],
		"invading_troops": 0,
		"faction_id": 0,
		"construction_progress": 0,
		PROVINCE_NAME_KEY: "",
		"is_target": false,
		"is_boss_home": false,
		"caltrops": [],
		PROVINCE_GOLD_PRODUCTION_KEY: 0,
		PROVINCE_FREE_BUILDINGS_KEY: 0,
		PROVINCE_BUILDING_CAPACITY_KEY: LevelConfig.PROVINCE_BUILDING_CAP_MIN,
		PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
	}

func make_province_snapshot_by_id() -> Dictionary:
	var snapshot_by_id: Dictionary = {}
	if _main == null:
		return snapshot_by_id

	for p in _main._province_persistence:
		var pid: int = int(p.get("id", -1))
		snapshot_by_id[pid] = {
			"id": pid,
			"type": String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			PROVINCE_NAME_KEY: _resolve_province_name(pid, p),
			"remaining_buildings": int(p.get("remaining_buildings", 0)),
			"remaining_troops": int(p.get("remaining_troops", 0)),
			"neighbors": normalize_neighbor_ids(p.get("neighbors", [])),
			"invading_troops": int(p.get("invading_troops", 0)),
			"encounter_seed": int(p.get("encounter_seed", 0)),
			"encounter_level": int(p.get("encounter_level", 0)),
			"faction_id": int(p.get("faction_id", 0)),
			"construction_progress": int(p.get("construction_progress", 0)),
			"is_target": bool(p.get("is_target", false)),
			"capture_source": String(p.get("capture_source", CAPTURE_SOURCE_NONE)),
			"is_boss_home": bool(p.get(BOSS_HOME_FLAG_KEY, false)),
			"caltrops": _normalize_caltrop_entries(p.get(CALTROPS_KEY, [])),
			PROVINCE_GOLD_PRODUCTION_KEY: get_province_gold_production(p),
			PROVINCE_FREE_BUILDINGS_KEY: get_province_free_buildings(p),
			PROVINCE_BUILDING_CAPACITY_KEY: get_province_building_capacity(p),
			PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: get_province_engagement_map_type(p)
		}
	return snapshot_by_id

func find_path_to_nearest_non_own_faction(source_id: int, snapshot_by_id: Dictionary) -> Array[int]:
	if not snapshot_by_id.has(source_id):
		return []

	var source_faction: int = get_province_faction(snapshot_by_id[source_id])

	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array[int] = [source_id]
	visited[source_id] = true

	var queue_index: int = 0
	while queue_index < queue.size():
		var current_id: int = int(queue[queue_index])
		queue_index += 1

		var current_state: Dictionary = snapshot_by_id.get(current_id, {})
		if current_id != source_id:
			var current_faction: int = get_province_faction(current_state)
			if current_faction != source_faction:   # allows neutrals (faction 0) AND different enemy factions
				var path: Array[int] = [current_id]
				var walk_id: int = current_id
				while parent.has(walk_id):
					walk_id = int(parent[walk_id])
					path.push_front(walk_id)
				return path

		var neighbors: Array[int] = normalize_neighbor_ids(current_state.get("neighbors", []))
		neighbors.sort()
		for neighbor_id in neighbors:
			if not snapshot_by_id.has(neighbor_id):
				continue
			if visited.has(neighbor_id):
				continue
			visited[neighbor_id] = true
			parent[neighbor_id] = current_id
			queue.append(neighbor_id)

	return []


func find_nearest_friendly_province_id(source_id: int) -> int:
	if _main == null or _main._province_persistence.is_empty():
		return -1

	var snapshot_by_id: Dictionary = make_province_snapshot_by_id()
	var visited: Dictionary = {}
	var queue: Array[int] = []

	if snapshot_by_id.has(source_id):
		queue.append(source_id)
		visited[source_id] = true
	else:
		for p in _main._province_persistence:
			var province_id: int = int(p.get("id", -1))
			queue.append(province_id)
			visited[province_id] = true

	var queue_index: int = 0
	while queue_index < queue.size():
		var current_id: int = int(queue[queue_index])
		queue_index += 1

		if snapshot_by_id.has(current_id):
			var current_state: Dictionary = snapshot_by_id.get(current_id, {})
			if String(current_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
				return current_id

			var neighbors: Array[int] = normalize_neighbor_ids(current_state.get("neighbors", []))
			neighbors.sort()
			for neighbor_id in neighbors:
				if visited.has(neighbor_id):
					continue
				if not snapshot_by_id.has(neighbor_id):
					continue
				visited[neighbor_id] = true
				queue.append(neighbor_id)

	for province_state in _main._province_persistence:
		if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return int(province_state.get("id", -1))

	return -1
