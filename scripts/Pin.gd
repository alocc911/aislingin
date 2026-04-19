extends RigidBody2D
class_name Pin
"""
Base class for all enemy pins (skiers/snowboarders).

Handles physics, knock-over detection, poison death, squash-stretch animation,
water death, and reusable drawing helpers for nuanced body and asymmetric face.
Subclasses override colors, scale, knock behavior, and specific draw calls.
"""

const LevelConfig = preload("res://scripts/LevelConfig.gd")

signal sunk_in_water

var knocked_over: bool = false
var _visual_scale: Vector2 = Vector2.ONE
var _cleanup_scheduled: bool = false
var _water_zones: Array[Area2D] = []
var _sunk_in_water: bool = false
var _touched_by_ball_this_shot: bool = false
var _last_visual_tilt: float = 0.0
var _has_visual_tilt_sample: bool = false

var _standing_sprite_texture: Texture2D = null
var _standing_sprite_region: Rect2 = Rect2()
var _standing_sprite_attempted_load: bool = false

var _downed_sprite_texture: Texture2D = null
var _downed_sprite_region: Rect2 = Rect2()
var _downed_sprite_attempted_load: bool = false


func _is_ball_body(body: Node) -> bool:
	return body != null and body is RigidBody2D and body.has_method("register_pin_contact")

# ==================== VIRTUAL OVERRIDES (subclasses implement) ====================

func _get_knock_threshold() -> float:
	return LevelConfig.PIN_KNOCK_VELOCITY_THRESHOLD

func _get_standing_linear_damp() -> float:
	return LevelConfig.PIN_STANDING_LINEAR_DAMP

func _get_standing_angular_damp() -> float:
	return LevelConfig.PIN_STANDING_ANGULAR_DAMP

func _get_knocked_linear_damp() -> float:
	return LevelConfig.PIN_KNOCKED_DAMP_LINEAR

func _get_knocked_angular_damp() -> float:
	return LevelConfig.PIN_KNOCKED_DAMP_ANGULAR

func _get_body_color() -> Color:
	return LevelConfig.SKI_PIN_SUIT_PRIMARY

func _get_helmet_color() -> Color:
	return LevelConfig.SKI_PIN_HELMET

func _get_goggles_color() -> Color:
	return LevelConfig.SKI_PIN_GOGGLES

func _get_draw_scale() -> float:
	return LevelConfig.ENEMY_SCALE_PIN

func _get_knock_mass() -> float:
	return 0.12

func _get_knock_friction() -> float:
	return 0.35

func _get_knock_bounce() -> float:
	return 0.45

func _on_hit_ball(ball: RigidBody2D) -> void:
	pass

func _has_ai() -> bool:
	return false

func _get_standing_sprite_path() -> String:
	return LevelConfig.ENEMY_STANDING_SPRITE_PATH_PIN

func _get_standing_sprite_target_height() -> float:
	return LevelConfig.ENEMY_STANDING_SPRITE_HEIGHT_PIN

func _get_standing_sprite_feet_y() -> float:
	return 60.0

func _get_standing_sprite_x_offset() -> float:
	return 0.0

func _should_use_standing_sprite() -> bool:
	return true

func _get_downed_sprite_path() -> String:
	return LevelConfig.ENEMY_DOWNED_SPRITE_PATH_PIN

func _get_downed_sprite_target_width() -> float:
	return LevelConfig.ENEMY_DOWNED_SPRITE_WIDTH_PIN

func _should_use_downed_sprite() -> bool:
	return true

# ==================== JUICY KNOCK ANIMATION ====================

func trigger_knock_pop() -> void:
	if not is_inside_tree():
		return
	var tween := create_tween()
	tween.tween_method(Callable(self, "_set_visual_scale_and_redraw"), _visual_scale, Vector2(1.65, 0.55), LevelConfig.JUICY_KNOCK_SQUASH_DURATION).set_trans(Tween.TRANS_BACK)
	tween.tween_method(Callable(self, "_set_visual_scale_and_redraw"), Vector2(1.65, 0.55), Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC)
	queue_redraw()

func _set_visual_scale_and_redraw(value: Vector2) -> void:
	_visual_scale = value
	queue_redraw()

func _ensure_standing_sprite_loaded() -> void:
	if _standing_sprite_attempted_load:
		return
	_standing_sprite_attempted_load = true

	var sprite_path := _get_standing_sprite_path()
	if sprite_path.is_empty():
		return
	if not ResourceLoader.exists(sprite_path):
		return

	_standing_sprite_texture = load(sprite_path) as Texture2D
	if _standing_sprite_texture == null:
		return

	var image := Image.load_from_file(sprite_path)
	if image == null or image.is_empty():
		_standing_sprite_region = Rect2(Vector2.ZERO, _standing_sprite_texture.get_size())
		return

	var used_rect: Rect2i = image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		_standing_sprite_region = Rect2(Vector2.ZERO, _standing_sprite_texture.get_size())
		return

	_standing_sprite_region = Rect2(used_rect.position, used_rect.size)

func _can_draw_standing_sprite() -> bool:
	if not _should_use_standing_sprite():
		return false
	_ensure_standing_sprite_loaded()
	return _standing_sprite_texture != null and _standing_sprite_region.size.x > 0.0 and _standing_sprite_region.size.y > 0.0

func _draw_standing_sprite() -> void:
	var s := _get_draw_scale()
	var region_size := _standing_sprite_region.size
	if region_size.x <= 0.0 or region_size.y <= 0.0:
		_draw_standing_fallback()
		return

	var target_height := _get_standing_sprite_target_height() * s
	var target_width := target_height * (region_size.x / region_size.y)
	var feet_y := _get_standing_sprite_feet_y() * s
	var top_y := feet_y - target_height
	var target_rect := Rect2(
		_get_standing_sprite_x_offset() * s - target_width * 0.5,
		top_y,
		target_width,
		target_height
	)

	draw_texture_rect_region(_standing_sprite_texture, target_rect, _standing_sprite_region)
	_draw_speed_sparkles(s, LevelConfig.ENEMY_CARTOON_SPARKLE_COUNT_STANDING)

	draw_set_transform(LevelConfig.ENEMY_SHADOW_OFFSET * 1.18, 0.0, Vector2(s * 1.14, s * 0.64))
	draw_circle(Vector2.ZERO, LevelConfig.PIN_BODY_WIDTH * 0.76, Color(0.0, 0.0, 0.0, 0.29))

func _ensure_downed_sprite_loaded() -> void:
	if _downed_sprite_attempted_load:
		return
	_downed_sprite_attempted_load = true

	var sprite_path := _get_downed_sprite_path()
	if sprite_path.is_empty():
		return
	if not ResourceLoader.exists(sprite_path):
		return

	_downed_sprite_texture = load(sprite_path) as Texture2D
	if _downed_sprite_texture == null:
		return

	var image := Image.load_from_file(sprite_path)
	if image == null or image.is_empty():
		_downed_sprite_region = Rect2(Vector2.ZERO, _downed_sprite_texture.get_size())
		return

	var used_rect: Rect2i = image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		_downed_sprite_region = Rect2(Vector2.ZERO, _downed_sprite_texture.get_size())
		return

	_downed_sprite_region = Rect2(used_rect.position, used_rect.size)

func _can_draw_downed_sprite() -> bool:
	if not _should_use_downed_sprite():
		return false
	_ensure_downed_sprite_loaded()
	return _downed_sprite_texture != null and _downed_sprite_region.size.x > 0.0 and _downed_sprite_region.size.y > 0.0

func _draw_downed_sprite() -> void:
	var s := _get_draw_scale()
	var region_size := _downed_sprite_region.size
	if region_size.x <= 0.0 or region_size.y <= 0.0:
		_draw_knocked_fallback()
		return

	var target_width := _get_downed_sprite_target_width() * s
	var target_height := target_width * (region_size.y / region_size.x)
	var target_rect := Rect2(
		-target_width * 0.5,
		-target_height * 0.5,
		target_width,
		target_height
	)

	draw_set_transform(LevelConfig.ENEMY_SHADOW_OFFSET * 0.9, 0.0, Vector2(s * 1.05, s * 0.62))
	draw_circle(Vector2.ZERO, LevelConfig.PIN_BODY_WIDTH * 0.82, Color(0.0, 0.0, 0.0, 0.24))
	draw_set_transform(Vector2.ZERO, 0.0, _visual_scale * s)
	draw_texture_rect_region(_downed_sprite_texture, target_rect, _downed_sprite_region)

# ==================== DRAWING HELPERS (shared across all pins) ====================

func _draw_nuanced_body(s: float, suit_col: Color, bw: float, bh: float) -> void:
	var top_w := bw * LevelConfig.ENEMY_BODY_TORSO_TOP_WIDTH_RATIO
	var bot_w := bw * LevelConfig.ENEMY_BODY_TORSO_BOTTOM_WIDTH_RATIO
	var waist_y := -bh * 0.12

	var points := PackedVector2Array([
		Vector2(-top_w * 0.5, -bh * 0.94),
		Vector2( top_w * 0.5, -bh * 0.94),
		Vector2( bot_w * 0.5 * LevelConfig.ENEMY_BODY_WAIST_PINCH, waist_y),
		Vector2(-bot_w * 0.5 * LevelConfig.ENEMY_BODY_WAIST_PINCH, waist_y)
	])
	draw_polygon(points, [suit_col])

	draw_arc(Vector2(-top_w * 0.38, -bh * 0.92), LevelConfig.ENEMY_BODY_SHOULDER_ROUNDNESS * s, -2.1, -0.8, 12, suit_col, 7.5 * s)
	draw_arc(Vector2( top_w * 0.38, -bh * 0.92), LevelConfig.ENEMY_BODY_SHOULDER_ROUNDNESS * s, -2.1, -0.8, 12, suit_col, 7.5 * s)

	draw_line(Vector2(-top_w * 0.48, -bh * 0.78), Vector2(top_w * 0.48, -bh * 0.78), LevelConfig.ENEMY_BODY_SEAM_COLOR, 2.8 * s)

	for i in range(LevelConfig.ENEMY_BODY_FOLD_LINE_COUNT):
		var x_off := -bw * 0.36 + i * (bw * 0.72 / float(LevelConfig.ENEMY_BODY_FOLD_LINE_COUNT - 1))
		draw_line(Vector2(x_off, -bh * 0.88), Vector2(x_off * 0.82, waist_y * 0.92), suit_col.darkened(0.25), LevelConfig.ENEMY_BODY_FOLD_THICKNESS * s)

	draw_line(Vector2(0, -bh * 0.91), Vector2(0, waist_y * 0.95), LevelConfig.ENEMY_BODY_SEAM_COLOR, 2.1 * s)

func _draw_cartoon_head(helmet_col: Color, goggles_col: Color, head_r: float, helmet_y: float, s: float) -> void:
	var rim_offset := LevelConfig.ENEMY_HEAD_HELMET_RIM_OVERHANG * s
	draw_circle(Vector2(0, helmet_y), head_r, helmet_col)
	draw_circle(Vector2(1.8 * s, helmet_y), head_r * 1.02, helmet_col)

	draw_arc(Vector2(0, helmet_y + rim_offset), head_r * 1.05, -2.6, 2.6, 22, helmet_col.darkened(0.2), 6.5 * s)

	draw_arc(Vector2(-5.5 * s, helmet_y - 10.5 * s), head_r * 0.74, -2.4, 1.0, 16, Color.WHITE, 5.2 * s)

func _draw_detailed_face(helmet_y: float, head_r: float, s: float) -> void:
	var face_y := helmet_y + 4.0 * s

	var brow_lift_left := LevelConfig.ENEMY_FACE_EYEBROW_LIFT * s + LevelConfig.ENEMY_FACE_EYEBROW_ASYMMETRY * s
	var brow_lift_right := LevelConfig.ENEMY_FACE_EYEBROW_LIFT * s - LevelConfig.ENEMY_FACE_EYEBROW_ASYMMETRY * s * 0.6
	draw_arc(Vector2(-head_r * 0.42, face_y - brow_lift_left), LevelConfig.ENEMY_FACE_EYEBROW_LENGTH * s * 0.5, -2.2, -1.0, 9, Color(0.12, 0.12, 0.18, 0.98), LevelConfig.ENEMY_FACE_EYEBROW_THICKNESS * s)
	draw_arc(Vector2( head_r * 0.42, face_y - brow_lift_right), LevelConfig.ENEMY_FACE_EYEBROW_LENGTH * s * 0.5, -2.2, -1.0, 9, Color(0.12, 0.12, 0.18, 0.98), LevelConfig.ENEMY_FACE_EYEBROW_THICKNESS * s)

	var nose_center := Vector2(LevelConfig.ENEMY_FACE_NOSE_OFFSET * s, face_y + 5.5 * s)
	draw_circle(nose_center, LevelConfig.ENEMY_FACE_NOSE_WIDTH * s * 0.48, Color(0.95, 0.82, 0.72, 1.0))
	draw_circle(nose_center + Vector2(2.2 * s, 1.5 * s), LevelConfig.ENEMY_FACE_NOSE_WIDTH * s * 0.32, LevelConfig.ENEMY_FACE_NOSE_SHADOW_COLOR)

	var mouth_y := face_y + 12.5 * s
	var smile_radius := LevelConfig.ENEMY_FACE_MOUTH_CURVE_RADIUS * s
	draw_arc(Vector2(0, mouth_y + LevelConfig.ENEMY_FACE_MOUTH_TILT * s), smile_radius * 0.52, 0.25, PI - 0.25, 14, LevelConfig.SKI_CARTOON_MOUTH_SMILE_COLOR, 3.1 * s)
	draw_arc(Vector2(0, mouth_y + 2.2 * s), smile_radius * 0.55, 0.32, PI - 0.32, 12, LevelConfig.ENEMY_FACE_MOUTH_LIP_COLOR, 1.6 * s)

	draw_circle(Vector2(-head_r * 0.48 + 1.2 * s, mouth_y + 2.8 * s), 2.3 * s, LevelConfig.ENEMY_FACE_DIMPLE_COLOR)
	draw_circle(Vector2( head_r * 0.48 - 0.8 * s, mouth_y + 1.6 * s), 2.1 * s, LevelConfig.ENEMY_FACE_DIMPLE_COLOR)

	var strap_y := helmet_y + head_r * 0.98
	draw_line(Vector2(-head_r * 0.78, strap_y), Vector2(-head_r * 0.42, strap_y + 8 * s), LevelConfig.ENEMY_FACE_HELMET_STRAP_COLOR, 3.4 * s)
	draw_line(Vector2( head_r * 0.72, strap_y), Vector2( head_r * 0.38, strap_y + 7 * s), LevelConfig.ENEMY_FACE_HELMET_STRAP_COLOR, 3.4 * s)

	draw_arc(Vector2(0, helmet_y + 2.5 * s), head_r * 0.94, -2.45, 2.45, 20, LevelConfig.ENEMY_FACE_VISOR_RIM_COLOR, 2.4 * s)

func _draw_cute_skis_and_poles(s: float, suit_col: Color) -> void:
	var bh := LevelConfig.PIN_BODY_HEIGHT
	var ski_y := bh * 0.62 * s
	draw_line(Vector2(-23 * s, ski_y), Vector2(23 * s, ski_y), Color(0.09, 0.09, 0.16, 1.0), 5.8 * s)
	draw_line(Vector2(-23 * s, ski_y + 9 * s), Vector2(23 * s, ski_y + 9 * s), Color(0.09, 0.09, 0.16, 1.0), 5.8 * s)
	draw_line(Vector2(-28 * s, ski_y), Vector2(-38 * s, ski_y - 11 * s), Color(0.92, 0.96, 1.0, 1.0), 3.6 * s)
	draw_line(Vector2( 28 * s, ski_y), Vector2( 38 * s, ski_y - 11 * s), Color(0.92, 0.96, 1.0, 1.0), 3.6 * s)
	draw_line(Vector2(-26 * s, ski_y - 3 * s), Vector2(26 * s, ski_y - 3 * s), LevelConfig.SKI_PIN_ACCENT, 2.1 * s)
	var pole_offset := Vector2(19.5 * s, -bh * 0.24 * s)
	draw_line(pole_offset, pole_offset + Vector2(13 * s, 41 * s), Color(0.96, 0.97, 1.0, 0.9), 3.4 * s)
	draw_line(-pole_offset, -pole_offset + Vector2(-13 * s, 41 * s), Color(0.96, 0.97, 1.0, 0.9), 3.4 * s)
	draw_circle(pole_offset + Vector2(13 * s, 38 * s), 3.2 * s, suit_col.darkened(0.3))
	draw_circle(-pole_offset + Vector2(-13 * s, 38 * s), 3.2 * s, suit_col.darkened(0.3))

func _draw_speed_sparkles(s: float, count: int) -> void:
	var speed := linear_velocity.length()
	if speed < 35.0:
		return
	for i in range(count):
		var a := i * 1.4 + Time.get_ticks_msec() * 0.008
		var p := Vector2(cos(a) * 28 * s, sin(a) * 14 * s - 22 * s)
		draw_circle(p, 2.4 * s, LevelConfig.SKI_SPARKLE_COLOR)

# ==================== MAIN DRAW CALL ====================

func _get_current_visual_tilt() -> float:
	if knocked_over:
		return 0.0
	if linear_velocity.length() <= 35.0:
		return 0.0
	return clampf(linear_velocity.x * 0.0012, -0.28, 0.28)

func _draw() -> void:
	if _sunk_in_water:
		return

	var s := _get_draw_scale()
	var tilt := _get_current_visual_tilt()
	draw_set_transform(Vector2.ZERO, tilt, _visual_scale * s)

	if knocked_over:
		_draw_knocked()
	else:
		_draw_standing()

func _draw_standing() -> void:
	if _can_draw_standing_sprite():
		_draw_standing_sprite()
		return
	_draw_standing_fallback()

func _draw_standing_fallback() -> void:
	var s := _get_draw_scale()
	var suit_col := _get_body_color()
	var helmet_col := _get_helmet_color()
	var goggles_col := _get_goggles_color()

	var bw := LevelConfig.PIN_BODY_WIDTH * 0.96
	var bh := LevelConfig.PIN_BODY_HEIGHT * 1.04

	_draw_nuanced_body(s, suit_col, bw, bh)

	var helmet_y := -bh * 0.97
	var head_r := LevelConfig.PIN_HEAD_RADIUS * 1.38
	_draw_cartoon_head(helmet_col, goggles_col, head_r, helmet_y, s)
	_draw_detailed_face(helmet_y, head_r, s)

	_draw_cute_skis_and_poles(s, suit_col)

	_draw_speed_sparkles(s, LevelConfig.ENEMY_CARTOON_SPARKLE_COUNT_STANDING)

	draw_set_transform(LevelConfig.ENEMY_SHADOW_OFFSET * 1.18, 0.0, Vector2(s * 1.14, s * 0.64))
	draw_circle(Vector2.ZERO, bw * 0.76, Color(0.0, 0.0, 0.0, 0.29))

func _draw_knocked() -> void:
	if _can_draw_downed_sprite():
		_draw_downed_sprite()
		return
	_draw_knocked_fallback()

func _draw_knocked_fallback() -> void:
	var s := _get_draw_scale()
	var rot := PI * 0.5 + 0.18
	draw_set_transform(Vector2.ZERO, rot, Vector2(s * 1.26, s * 0.81) * _visual_scale)

	var bw := LevelConfig.PIN_BODY_WIDTH
	var bh := LevelConfig.PIN_BODY_HEIGHT

	var tumbled_col := _get_body_color().darkened(0.26)
	draw_rect(Rect2(-bw * 0.68, -bh * 0.45, bw * 1.62, bh * 1.05), tumbled_col)
	for i in range(4):
		var fold_x := -bw * 0.55 + i * (bw * 1.1 / 3.0)
		draw_line(Vector2(fold_x, -bh * 0.38), Vector2(fold_x * 0.7, -bh * 0.05), tumbled_col.darkened(0.35), 2.4 * s)

	var helmet_y := -bh * 0.41
	var head_r := LevelConfig.PIN_HEAD_RADIUS * 1.32
	draw_circle(Vector2(bw * 0.75, helmet_y), head_r, _get_helmet_color())
	_draw_detailed_face(helmet_y, head_r, s)

	var eye_y := helmet_y + 4.5 * s
	draw_circle(Vector2(bw * 0.58, eye_y), LevelConfig.ENEMY_CARTOON_EYE_RADIUS * 0.9 * s, _get_goggles_color().darkened(0.4))
	draw_circle(Vector2(bw * 0.92, eye_y), LevelConfig.ENEMY_CARTOON_EYE_RADIUS * 0.9 * s, _get_goggles_color().darkened(0.4))

	for i in range(5):
		var a := Time.get_ticks_msec() * 0.011 + i * 1.35
		var off := Vector2(cos(a) * 19 * s, sin(a) * 19 * s - 12 * s)
		draw_circle(Vector2(bw * 0.76, helmet_y) + off, LevelConfig.ENEMY_CARTOON_DIZZY_STAR_SIZE * s, LevelConfig.ENEMY_CARTOON_DIZZY_STAR_COLOR)

	var ski_y := bh * 0.48
	draw_line(Vector2(-36 * s, ski_y), Vector2(52 * s, ski_y - 24 * s), Color(0.09, 0.09, 0.16, 1.0), 7.2 * s)
	draw_line(Vector2(-31 * s, ski_y + 14 * s), Vector2(47 * s, ski_y - 6 * s), Color(0.09, 0.09, 0.16, 1.0), 7.2 * s)

	draw_circle(Vector2(bw * 0.88, -bh * 0.52), 6.8 * s, Color.WHITE)

# ==================== PHYSICS, ZONES, & KNOCK LOGIC ====================

func _ready() -> void:
	_touched_by_ball_this_shot = false
	gravity_scale = 0.0
	linear_damp = _get_standing_linear_damp()
	angular_damp = _get_standing_angular_damp()
	contact_monitor = true
	max_contacts_reported = 8
	mass = 0.18

	var mat := PhysicsMaterial.new()
	mat.friction = 0.0
	mat.bounce = 0.92
	physics_material_override = mat

	body_entered.connect(_on_body_entered)
	_ensure_standing_sprite_loaded()
	_ensure_downed_sprite_loaded()
	_last_visual_tilt = _get_current_visual_tilt()
	_has_visual_tilt_sample = true
	queue_redraw()

func is_knocked_over() -> bool:
	return knocked_over

func is_sunk_in_water() -> bool:
	return _sunk_in_water


func mark_touched_by_ball_this_shot() -> void:
	_touched_by_ball_this_shot = true

func was_touched_by_ball_this_shot() -> bool:
	return _touched_by_ball_this_shot

func reset_touched_by_ball_this_shot() -> void:
	_touched_by_ball_this_shot = false

func register_zone(area: Area2D) -> void:
	if not area or not area.has_meta("zone_type"):
		return
	var ztype := str(area.get_meta("zone_type"))
	if ztype == "water" and not _water_zones.has(area):
		_water_zones.append(area)

func unregister_zone(area: Area2D) -> void:
	if not area or not area.has_meta("zone_type"):
		return
	var ztype := str(area.get_meta("zone_type"))
	if ztype == "water":
		_water_zones.erase(area)

func _get_current_knocked_pin_count() -> int:
	var current_knocked := 0
	for p in get_tree().get_nodes_in_group("pins"):
		if p is Pin and p.knocked_over:
			current_knocked += 1
	return current_knocked

func _enter_knocked_state() -> void:
	if knocked_over or _sunk_in_water:
		return
	knocked_over = true
	_last_visual_tilt = 0.0
	_has_visual_tilt_sample = false
	mass = _get_knock_mass()
	if physics_material_override:
		physics_material_override.friction = _get_knock_friction()
		physics_material_override.bounce = _get_knock_bounce()
	linear_damp = _get_knocked_linear_damp()
	angular_damp = _get_knocked_angular_damp()
	trigger_knock_pop()
	queue_redraw()
	_schedule_cleanup()

func apply_poison_death() -> void:
	if knocked_over or _sunk_in_water:
		return
	_enter_knocked_state()

func apply_forcefield_hit(force_origin: Vector2, source_velocity: Vector2, strength_mult: float) -> void:
	if _sunk_in_water:
		return

	var applied_mult := maxf(0.0, strength_mult)
	if applied_mult <= 0.0:
		return

	var source_speed := source_velocity.length()
	if source_speed <= 0.01:
		return

	var dir := global_position - force_origin
	if dir.length_squared() <= 0.0001:
		dir = source_velocity.normalized()
	else:
		dir = dir.normalized()

	_touched_by_ball_this_shot = true

	var effective_speed := source_speed * applied_mult
	var desired_delta_v := effective_speed * 0.58
	var impulse_mag := mass * desired_delta_v
	apply_central_impulse(dir * impulse_mag)
	sleeping = false
	queue_redraw()

	if not knocked_over and effective_speed > _get_knock_threshold():
		if _get_current_knocked_pin_count() >= LevelConfig.MAX_SIMULTANEOUS_KNOCKED_PINS:
			return
		_enter_knocked_state()

func _on_body_entered(body: Node) -> void:
	if _sunk_in_water:
		return
	if not (body is RigidBody2D):
		return

	var other: RigidBody2D = body as RigidBody2D
	var rel_vel: Vector2 = other.linear_velocity - linear_velocity
	var hit_by_ball: bool = _is_ball_body(other)

	if hit_by_ball:
		_touched_by_ball_this_shot = true
		other.register_pin_contact(self)
		_on_hit_ball(other)

	if not knocked_over and rel_vel.length() > _get_knock_threshold():
		if _get_current_knocked_pin_count() >= LevelConfig.MAX_SIMULTANEOUS_KNOCKED_PINS:
			return
		_enter_knocked_state()

func _schedule_cleanup() -> void:
	if _cleanup_scheduled or _sunk_in_water:
		return
	_cleanup_scheduled = true
	get_tree().create_timer(0.15).timeout.connect(_check_for_settle)

func _check_for_settle() -> void:
	if not is_instance_valid(self) or not knocked_over or _sunk_in_water:
		return
	if linear_velocity.length() < 12.0 and abs(angular_velocity) < 0.6:
		var delay := randf_range(LevelConfig.KNOCKED_PIN_CLEANUP_DELAY_MIN, LevelConfig.KNOCKED_PIN_CLEANUP_DELAY_MAX)
		get_tree().create_timer(delay).timeout.connect(_remove_pin)
	else:
		get_tree().create_timer(0.08).timeout.connect(_check_for_settle)

func _remove_pin() -> void:
	if is_instance_valid(self):
		queue_free()

func _physics_process(_delta: float) -> void:
	if _sunk_in_water:
		return

	if _water_overlap_ratio() > float(LevelConfig.WATER_OVERLAP_KILL_RATIO):
		_sink_into_water()
		return

	if not knocked_over:
		var tilt := _get_current_visual_tilt()
		if not _has_visual_tilt_sample or absf(tilt - _last_visual_tilt) >= 0.01:
			_last_visual_tilt = tilt
			_has_visual_tilt_sample = true
			queue_redraw()

func _sink_into_water() -> void:
	if _sunk_in_water:
		return

	_sunk_in_water = true
	knocked_over = true
	_last_visual_tilt = 0.0
	_has_visual_tilt_sample = false

	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = true
	freeze = true

	collision_layer = 0
	collision_mask = 0
	set_deferred("monitorable", false)

	_water_zones.clear()
	queue_redraw()
	emit_signal("sunk_in_water")
	call_deferred("queue_free")

func _water_overlap_ratio() -> float:
	if _water_zones.is_empty():
		return 0.0

	var active_water: Array[Area2D] = []
	for area in _water_zones:
		if is_instance_valid(area) and not area.is_queued_for_deletion():
			active_water.append(area)

	if active_water.is_empty():
		return 0.0

	var total := 0.0

	total += _sample_water_weight(Vector2(0, -18), 0.12, active_water)
	total += _sample_water_weight(Vector2(0, 6), 0.16, active_water)
	total += _sample_water_weight(Vector2(-12, -10), 0.10, active_water)
	total += _sample_water_weight(Vector2(12, -10), 0.10, active_water)
	total += _sample_water_weight(Vector2(-14, 10), 0.10, active_water)
	total += _sample_water_weight(Vector2(14, 10), 0.10, active_water)
	total += _sample_water_weight(Vector2(0, -34), 0.10, active_water)
	total += _sample_water_weight(Vector2(-8, 28), 0.07, active_water)
	total += _sample_water_weight(Vector2(8, 28), 0.07, active_water)
	total += _sample_water_weight(Vector2(-18, 0), 0.04, active_water)
	total += _sample_water_weight(Vector2(18, 0), 0.04, active_water)

	return clampf(total, 0.0, 1.0)

func _sample_water_weight(local_offset: Vector2, weight: float, active_water: Array[Area2D]) -> float:
	var world_point := global_transform * local_offset
	for area in active_water:
		if _point_inside_water_zone(world_point, area):
			return weight
	return 0.0

func _point_inside_water_zone(world_point: Vector2, area: Area2D) -> bool:
	var center := area.global_position
	var base_radius := float(area.get_meta("zone_radius", 0.0))
	var aspect := maxf(0.42, float(area.get_meta("zone_aspect", 1.0)))

	if base_radius <= 0.001:
		return false

	var rx := base_radius * maxf(1.0, aspect)
	var ry := base_radius / maxf(0.42, aspect * 0.92)

	if rx <= 0.001 or ry <= 0.001:
		return false

	var local := world_point - center
	if absf(area.global_rotation) > 0.0001:
		local = local.rotated(-area.global_rotation)

	var nx := local.x / rx
	var ny := local.y / ry
	return (nx * nx + ny * ny) <= 1.0
