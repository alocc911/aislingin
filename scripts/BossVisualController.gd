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
var _active_flash_tweens: Dictionary = {}


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


func _cache_base_transforms() -> void:
	_base_positions.clear()
	_base_rotations.clear()
	_part_nodes.clear()
	for part_name in BOSS_PART_NAMES:
		var body: Node2D = get_node_or_null("BossPart_%s" % part_name) as Node2D
		if body == null:
			continue

		_part_nodes[part_name] = body
		_base_positions[part_name] = body.position

		var swing_root: Node2D = body.get_node_or_null("SwingRoot") as Node2D
		if swing_root != null:
			# Keep collision and visual geometry in the same transform space.
			# The previous implementation rotated SwingRoot only, which visually moved limbs
			# while body collision polygons remained unrotated and caused early/late contacts.
			var combined_rotation: float = body.rotation + swing_root.rotation
			body.rotation = combined_rotation
			swing_root.rotation = 0.0
			_base_rotations[part_name] = combined_rotation
		else:
			_base_rotations[part_name] = body.rotation



func _physics_process(delta: float) -> void:
	if _base_positions.size() < BOSS_PART_NAMES.size():
		_cache_base_transforms()
		if _base_positions.size() < 2:
			return
	_elapsed = fmod(_elapsed + delta, 10000.0)
	_apply_all_motion()


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
	body.rotation = base_rotation + rotation_offset
	if swing_root != null:
		swing_root.rotation = 0.0


func _get_part_node(part_name: String) -> Node2D:
	var cached: Node2D = _part_nodes.get(part_name, null) as Node2D
	if cached != null and is_instance_valid(cached):
		return cached
	var body: Node2D = get_node_or_null("BossPart_%s" % part_name) as Node2D
	if body != null:
		_part_nodes[part_name] = body
	return body


func trigger_part_hit_flash(part_name: String) -> void:
	var clean_part_name: String = String(part_name).strip_edges()
	if clean_part_name == "":
		return
	var body: Node2D = _get_part_node(clean_part_name)
	if body == null or bool(body.get_meta("boss_destroyed", false)):
		return
	var visual_nodes: Array[CanvasItem] = _collect_flash_visual_nodes(body)
	if visual_nodes.is_empty():
		return
	clear_part_hit_flash(clean_part_name)
	for visual in visual_nodes:
		if visual == null or not is_instance_valid(visual):
			continue
		var base_modulate: Color = visual.modulate
		var flash_color := Color(2.2, 2.2, 2.2, base_modulate.a)
		visual.modulate = flash_color
		var tween: Tween = create_tween()
		tween.tween_property(visual, "modulate", base_modulate, maxf(0.05, LevelConfig.get_boss_hit_flash_duration_seconds()))
		_active_flash_tweens["%s:%s" % [clean_part_name, String(visual.get_instance_id())]] = tween
		tween.finished.connect(func() -> void:
			if is_instance_valid(visual):
				visual.modulate = base_modulate
			_active_flash_tweens.erase("%s:%s" % [clean_part_name, String(visual.get_instance_id())])
		)


func clear_part_hit_flash(part_name: String) -> void:
	var clean_part_name: String = String(part_name).strip_edges()
	if clean_part_name == "":
		return
	var keys_to_remove: Array[String] = []
	for key_any in _active_flash_tweens.keys():
		var key: String = String(key_any)
		if not key.begins_with("%s:" % clean_part_name):
			continue
		var tween: Tween = _active_flash_tweens.get(key, null) as Tween
		if tween != null and is_instance_valid(tween):
			tween.kill()
		keys_to_remove.append(key)
	for key in keys_to_remove:
		_active_flash_tweens.erase(key)


func clear_all_hit_flashes() -> void:
	for tween_any in _active_flash_tweens.values():
		var tween: Tween = tween_any as Tween
		if tween != null and is_instance_valid(tween):
			tween.kill()
	_active_flash_tweens.clear()


func _collect_flash_visual_nodes(root: Node) -> Array[CanvasItem]:
	var visuals: Array[CanvasItem] = []
	if root == null or not is_instance_valid(root):
		return visuals
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is CanvasItem:
			var canvas_item: CanvasItem = cur as CanvasItem
			if canvas_item.visible:
				visuals.append(canvas_item)
		for child_any in cur.get_children():
			stack.append(child_any)
	return visuals
