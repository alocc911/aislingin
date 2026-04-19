extends Node2D
class_name BossVisualController

const BOSS_PART_NAMES: Array[String] = ["head", "left_arm", "right_arm", "left_leg", "right_leg"]

const DEFAULT_LEFT_ARM_ROT_RANGE_DEG: float = 38.0
const DEFAULT_RIGHT_ARM_ROT_RANGE_DEG: float = 38.0
const DEFAULT_LEFT_LEG_ROT_RANGE_DEG: float = 8.0
const DEFAULT_RIGHT_LEG_ROT_RANGE_DEG: float = 8.0

const DEFAULT_LEFT_ARM_RANDOM_SWAY: float = 2.5
const DEFAULT_RIGHT_ARM_RANDOM_SWAY: float = 2.5
const DEFAULT_LEFT_LEG_RANDOM_SWAY: float = 1.25
const DEFAULT_RIGHT_LEG_RANDOM_SWAY: float = 1.25

const DEFAULT_LEFT_ARM_ROT_SPEED: float = 0.95
const DEFAULT_RIGHT_ARM_ROT_SPEED: float = 0.95
const DEFAULT_LEFT_LEG_ROT_SPEED: float = 0.72
const DEFAULT_RIGHT_LEG_ROT_SPEED: float = 0.72

var _elapsed: float = 0.0
var _scale_size: float = 180.0
var _base_positions: Dictionary = {}
var _base_rotations: Dictionary = {}
var _part_nodes: Dictionary = {}
var _part_outline_nodes: Dictionary = {}
var _part_outline_base_colors: Dictionary = {}
var _part_fill_nodes: Dictionary = {}
var _part_fill_base_colors: Dictionary = {}
var _part_flash_outline_nodes: Dictionary = {}
var _part_flash_remaining: Dictionary = {}


func configure(scale_size: float) -> void:
	_scale_size = maxf(24.0, scale_size)


func _ready() -> void:
	set_process(false)
	set_physics_process(true)
	call_deferred("refresh_animation_setup")


func refresh_animation_setup() -> void:
	_cache_base_transforms()
	_elapsed = 0.0
	_apply_all_motion()
	_apply_all_hit_flash_visuals()


func _cache_base_transforms() -> void:
	_base_positions.clear()
	_base_rotations.clear()
	_part_nodes.clear()
	_part_outline_nodes.clear()
	_part_outline_base_colors.clear()
	_part_fill_nodes.clear()
	_part_fill_base_colors.clear()
	_part_flash_outline_nodes.clear()

	for part_name in BOSS_PART_NAMES:
		var body: Node2D = get_node_or_null("BossPart_%s" % part_name) as Node2D
		if body == null:
			continue

		_part_nodes[part_name] = body
		_base_positions[part_name] = body.position

		var swing_root: Node2D = body.get_node_or_null("SwingRoot") as Node2D
		if swing_root != null:
			_base_rotations[part_name] = swing_root.rotation
			body.rotation = 0.0
		else:
			_base_rotations[part_name] = body.rotation

		_cache_visual_nodes_for_part(part_name)

	_apply_all_hit_flash_visuals()


func _physics_process(delta: float) -> void:
	if _base_positions.size() < BOSS_PART_NAMES.size():
		_cache_base_transforms()
		if _base_positions.size() < 2:
			return
	_elapsed = fmod(_elapsed + delta, 10000.0)
	_apply_all_motion()
	_update_hit_flashes(delta)


func _apply_all_motion() -> void:
	_apply_limb_sway()
	_apply_head_motion()


func _cfg_float(method_name: String, fallback: float) -> float:
	match method_name:
		"get_boss_left_arm_rotational_sway_range_degrees":
			return LevelConfig.get_boss_left_arm_rotational_sway_range_degrees()
		"get_boss_right_arm_rotational_sway_range_degrees":
			return LevelConfig.get_boss_right_arm_rotational_sway_range_degrees()
		"get_boss_left_leg_rotational_sway_range_degrees":
			return LevelConfig.get_boss_left_leg_rotational_sway_range_degrees()
		"get_boss_right_leg_rotational_sway_range_degrees":
			return LevelConfig.get_boss_right_leg_rotational_sway_range_degrees()
		"get_boss_left_arm_random_sway_range":
			return LevelConfig.get_boss_left_arm_random_sway_range()
		"get_boss_right_arm_random_sway_range":
			return LevelConfig.get_boss_right_arm_random_sway_range()
		"get_boss_left_leg_random_sway_range":
			return LevelConfig.get_boss_left_leg_random_sway_range()
		"get_boss_right_leg_random_sway_range":
			return LevelConfig.get_boss_right_leg_random_sway_range()
		"get_boss_left_arm_rotational_sway_speed":
			return LevelConfig.get_boss_left_arm_rotational_sway_speed()
		"get_boss_right_arm_rotational_sway_speed":
			return LevelConfig.get_boss_right_arm_rotational_sway_speed()
		"get_boss_left_leg_rotational_sway_speed":
			return LevelConfig.get_boss_left_leg_rotational_sway_speed()
		"get_boss_right_leg_rotational_sway_speed":
			return LevelConfig.get_boss_right_leg_rotational_sway_speed()
		"get_boss_hit_flash_duration_seconds":
			return LevelConfig.get_boss_hit_flash_duration_seconds()
		"get_boss_hit_flash_peak_white_blend":
			return LevelConfig.get_boss_hit_flash_peak_white_blend()
		_:
			return fallback


func _apply_limb_sway() -> void:
	_apply_limb_motion(
		"left_arm",
		_cfg_float("get_boss_left_arm_rotational_sway_range_degrees", DEFAULT_LEFT_ARM_ROT_RANGE_DEG),
		_cfg_float("get_boss_left_arm_random_sway_range", DEFAULT_LEFT_ARM_RANDOM_SWAY),
		_cfg_float("get_boss_left_arm_rotational_sway_speed", DEFAULT_LEFT_ARM_ROT_SPEED),
		0.95,
		0.12,
		1.0,
		true
	)
	_apply_limb_motion(
		"right_arm",
		_cfg_float("get_boss_right_arm_rotational_sway_range_degrees", DEFAULT_RIGHT_ARM_ROT_RANGE_DEG),
		_cfg_float("get_boss_right_arm_random_sway_range", DEFAULT_RIGHT_ARM_RANDOM_SWAY),
		_cfg_float("get_boss_right_arm_rotational_sway_speed", DEFAULT_RIGHT_ARM_ROT_SPEED),
		0.95,
		PI + 0.12,
		-1.0,
		true
	)
	_apply_limb_motion(
		"left_leg",
		_cfg_float("get_boss_left_leg_rotational_sway_range_degrees", DEFAULT_LEFT_LEG_ROT_RANGE_DEG),
		_cfg_float("get_boss_left_leg_random_sway_range", DEFAULT_LEFT_LEG_RANDOM_SWAY),
		_cfg_float("get_boss_left_leg_rotational_sway_speed", DEFAULT_LEFT_LEG_ROT_SPEED),
		0.72,
		0.28,
		1.0,
		false
	)
	_apply_limb_motion(
		"right_leg",
		_cfg_float("get_boss_right_leg_rotational_sway_range_degrees", DEFAULT_RIGHT_LEG_ROT_RANGE_DEG),
		_cfg_float("get_boss_right_leg_random_sway_range", DEFAULT_RIGHT_LEG_RANDOM_SWAY),
		_cfg_float("get_boss_right_leg_rotational_sway_speed", DEFAULT_RIGHT_LEG_ROT_SPEED),
		0.72,
		PI + 0.28,
		-1.0,
		false
	)


func _apply_limb_motion(part_name: String, rotational_range_degrees: float, random_sway_range: float, rotational_speed: float, drift_speed: float, phase: float, handedness: float, is_arm: bool) -> void:
	var primary_rot: float = sin(_elapsed * rotational_speed + phase)
	var secondary_rot: float = sin(_elapsed * rotational_speed * 0.57 + phase * 1.73 + 0.85)
	var rotation_wave: float = clampf(primary_rot * 0.80 + secondary_rot * 0.20, -1.0, 1.0)
	var rotation_offset: float = deg_to_rad(rotational_range_degrees) * rotation_wave * handedness

	var drift: Vector2 = _compute_random_sway_offset(random_sway_range, drift_speed, phase)
	if is_arm:
		drift.x += handedness * sin(_elapsed * 1.18 + phase * 0.61) * maxf(0.0, random_sway_range) * 0.34
		drift.y += cos(_elapsed * 1.42 + phase * 0.47) * maxf(0.0, random_sway_range) * 0.18
	else:
		drift.x += handedness * sin(_elapsed * 0.92 + phase * 0.53) * maxf(0.0, random_sway_range) * 0.18
		drift.y += cos(_elapsed * 1.07 + phase * 0.39) * maxf(0.0, random_sway_range) * 0.10

	_apply_part_transform(part_name, rotation_offset, drift)


func _compute_random_sway_offset(random_sway_range: float, drift_speed: float, phase: float) -> Vector2:
	var amplitude: float = maxf(0.0, random_sway_range)
	if amplitude <= 0.001:
		return Vector2.ZERO
	var x_wave: float = sin(_elapsed * drift_speed + phase) * 0.64 + sin(_elapsed * drift_speed * 1.71 + phase * 1.91 + 0.77) * 0.36
	var y_wave: float = sin(_elapsed * drift_speed * 0.83 + phase * 1.29 + 1.17) * 0.60 + sin(_elapsed * drift_speed * 1.43 + phase * 0.59 + 2.08) * 0.40
	return Vector2(x_wave, y_wave) * amplitude


func _apply_head_motion() -> void:
	_apply_part_transform(
		"head",
		0.0,
		Vector2(
			sin(_elapsed * 0.78) * _scale_size * 0.0008,
			sin(_elapsed * 2.00) * _scale_size * 0.0036
		)
	)


func _apply_part_transform(part_name: String, rotation_offset: float, position_offset: Vector2) -> void:
	if not _base_positions.has(part_name):
		return
	var body: Node2D = _get_part_node(part_name)
	if body == null:
		return
	var swing_root: Node2D = body.get_node_or_null("SwingRoot") as Node2D
	var base_position: Vector2 = _base_positions.get(part_name, body.position)
	var base_rotation: float = float(_base_rotations.get(part_name, 0.0))
	if bool(body.get_meta("boss_destroyed", false)):
		body.position = base_position
		if swing_root != null:
			swing_root.rotation = base_rotation
		else:
			body.rotation = base_rotation
		return
	body.position = base_position + position_offset
	if swing_root != null:
		body.rotation = 0.0
		swing_root.rotation = base_rotation + rotation_offset
	else:
		body.rotation = base_rotation + rotation_offset


func trigger_part_hit_flash(part_name: String) -> void:
	var clean_part_name: String = String(part_name).strip_edges()
	if clean_part_name == "":
		return
	var body: Node2D = _get_part_node(clean_part_name)
	if body == null:
		return
	if bool(body.get_meta("boss_destroyed", false)):
		return

	_cache_visual_nodes_for_part(clean_part_name)

	var duration: float = _cfg_float("get_boss_hit_flash_duration_seconds", 0.12)
	if duration <= 0.0:
		_apply_hit_flash_visual(clean_part_name, 0.0)
		return

	_part_flash_remaining[clean_part_name] = duration
	_apply_hit_flash_visual(clean_part_name, 1.0)


func clear_part_hit_flash(part_name: String) -> void:
	var clean_part_name: String = String(part_name).strip_edges()
	if clean_part_name == "":
		return
	_part_flash_remaining.erase(clean_part_name)
	_apply_hit_flash_visual(clean_part_name, 0.0)


func clear_all_hit_flashes() -> void:
	_part_flash_remaining.clear()
	_apply_all_hit_flash_visuals()


func _update_hit_flashes(delta: float) -> void:
	if _part_flash_remaining.is_empty():
		return

	var duration: float = _cfg_float("get_boss_hit_flash_duration_seconds", 0.12)
	var finished: Array[String] = []

	for part_name_variant in _part_flash_remaining.keys():
		var part_name: String = String(part_name_variant)
		var remaining: float = maxf(0.0, float(_part_flash_remaining.get(part_name, 0.0)) - delta)
		if remaining <= 0.0 or duration <= 0.0:
			finished.append(part_name)
			_apply_hit_flash_visual(part_name, 0.0)
		else:
			_part_flash_remaining[part_name] = remaining
			var normalized: float = clampf(remaining / duration, 0.0, 1.0)
			_apply_hit_flash_visual(part_name, normalized)

	for part_name in finished:
		_part_flash_remaining.erase(part_name)


func _apply_all_hit_flash_visuals() -> void:
	for part_name in BOSS_PART_NAMES:
		var strength: float = 0.0
		if _part_flash_remaining.has(part_name):
			var duration: float = _cfg_float("get_boss_hit_flash_duration_seconds", 0.12)
			if duration > 0.0:
				strength = clampf(float(_part_flash_remaining.get(part_name, 0.0)) / duration, 0.0, 1.0)
		_apply_hit_flash_visual(part_name, strength)


func _apply_hit_flash_visual(part_name: String, normalized_strength: float) -> void:
	var outline: Line2D = _get_outline_node(part_name)
	var flash_outline: Line2D = _get_flash_outline_node(part_name)
	var fill: CanvasItem = _get_fill_node(part_name)
	if outline == null and flash_outline == null and fill == null:
		return

	var body: Node2D = _get_part_node(part_name)
	if body != null and bool(body.get_meta("boss_destroyed", false)):
		normalized_strength = 0.0

	var clamped_strength: float = clampf(normalized_strength, 0.0, 1.0)
	var peak_blend: float = clampf(_cfg_float("get_boss_hit_flash_peak_white_blend", 1.0), 0.0, 1.0)
	var blend: float = clamped_strength * peak_blend

	if outline != null:
		var base_color: Color = _get_outline_base_color(part_name, outline)
		outline.default_color = base_color.lerp(Color(1.0, 1.0, 1.0, base_color.a), blend)

	if fill != null:
		var base_fill: Color = _get_fill_base_color(part_name, fill)
		var fill_blend: float = blend * 0.35
		fill.modulate = base_fill.lerp(Color(1.0, 1.0, 1.0, base_fill.a), fill_blend)

	if flash_outline != null:
		flash_outline.visible = blend > 0.001
		flash_outline.modulate = Color(1.0, 1.0, 1.0, blend)


func _cache_visual_nodes_for_part(part_name: String) -> void:
	var body: Node2D = _get_part_node(part_name)
	if body == null:
		return
	var swing_root: Node2D = body.get_node_or_null("SwingRoot") as Node2D
	if swing_root == null:
		return

	var outline: Line2D = swing_root.get_node_or_null("Outline") as Line2D
	if outline != null:
		_part_outline_nodes[part_name] = outline
		if not _part_outline_base_colors.has(part_name):
			_part_outline_base_colors[part_name] = outline.default_color
		_ensure_flash_outline_node(part_name, swing_root, outline)

	var fill: CanvasItem = swing_root.get_node_or_null("Fill") as CanvasItem
	if fill != null:
		_part_fill_nodes[part_name] = fill
		if not _part_fill_base_colors.has(part_name):
			_part_fill_base_colors[part_name] = fill.modulate


func _ensure_flash_outline_node(part_name: String, swing_root: Node2D, base_outline: Line2D) -> void:
	var existing: Line2D = swing_root.get_node_or_null("HitFlashOutline") as Line2D
	if existing == null:
		existing = Line2D.new()
		existing.name = "HitFlashOutline"
		existing.closed = base_outline.closed
		existing.points = base_outline.points
		existing.width = base_outline.width * 1.55
		existing.default_color = Color(1.0, 1.0, 1.0, 1.0)
		existing.antialiased = true
		existing.z_index = base_outline.z_index + 1
		existing.visible = false
		existing.modulate = Color(1.0, 1.0, 1.0, 0.0)
		swing_root.add_child(existing)
	else:
		existing.closed = base_outline.closed
		existing.points = base_outline.points
		existing.width = base_outline.width * 1.55
		existing.z_index = base_outline.z_index + 1
	_part_flash_outline_nodes[part_name] = existing


func _get_part_node(part_name: String) -> Node2D:
	var cached: Node2D = _part_nodes.get(part_name, null) as Node2D
	if cached != null and is_instance_valid(cached):
		return cached

	var body: Node2D = get_node_or_null("BossPart_%s" % part_name) as Node2D
	if body != null:
		_part_nodes[part_name] = body
	return body


func _get_outline_node(part_name: String) -> Line2D:
	var cached: Line2D = _part_outline_nodes.get(part_name, null) as Line2D
	if cached != null and is_instance_valid(cached):
		return cached
	_cache_visual_nodes_for_part(part_name)
	cached = _part_outline_nodes.get(part_name, null) as Line2D
	if cached != null and is_instance_valid(cached):
		return cached
	return null


func _get_flash_outline_node(part_name: String) -> Line2D:
	var cached: Line2D = _part_flash_outline_nodes.get(part_name, null) as Line2D
	if cached != null and is_instance_valid(cached):
		return cached
	_cache_visual_nodes_for_part(part_name)
	cached = _part_flash_outline_nodes.get(part_name, null) as Line2D
	if cached != null and is_instance_valid(cached):
		return cached
	return null


func _get_fill_node(part_name: String) -> CanvasItem:
	var cached: CanvasItem = _part_fill_nodes.get(part_name, null) as CanvasItem
	if cached != null and is_instance_valid(cached):
		return cached
	_cache_visual_nodes_for_part(part_name)
	cached = _part_fill_nodes.get(part_name, null) as CanvasItem
	if cached != null and is_instance_valid(cached):
		return cached
	return null


func _get_outline_base_color(part_name: String, outline: Line2D) -> Color:
	if _part_outline_base_colors.has(part_name):
		return _part_outline_base_colors.get(part_name, outline.default_color)
	_part_outline_base_colors[part_name] = outline.default_color
	return outline.default_color


func _get_fill_base_color(part_name: String, fill: CanvasItem) -> Color:
	if _part_fill_base_colors.has(part_name):
		return _part_fill_base_colors.get(part_name, fill.modulate)
	_part_fill_base_colors[part_name] = fill.modulate
	return fill.modulate
