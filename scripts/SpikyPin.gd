extends "res://scripts/Pin.gd"
class_name SpikyPin
"""
Spiky racer variant.

On hit: shrinks ball radius and applies strong slowdown.
Sharp helmet spikes, razor edges, fiery orange suit with nuanced body and detailed face.
All knock, poison, and physics behavior inherited from Pin.
"""

const BALL_SHRINK_FACTOR: float = 0.92

func _get_knock_threshold() -> float:
	return LevelConfig.PIN_KNOCK_VELOCITY_THRESHOLD * 1.22

func _on_hit_ball(ball: RigidBody2D) -> void:
	if knocked_over:
		return
	
	if ball and ball.has_method("apply_hit_slowdown"):
		ball.apply_hit_slowdown(LevelConfig.ENEMY_SLOWDOWN_SPIKY)
	
	if ball and ball.has_method("shrink_radius"):
		ball.call("shrink_radius", BALL_SHRINK_FACTOR)

func _get_draw_scale() -> float:
	return LevelConfig.ENEMY_SCALE_SPIKY

func _get_body_color() -> Color:
	return LevelConfig.SKI_SPIKY_SUIT

func _get_helmet_color() -> Color:
	return LevelConfig.SKI_PIN_HELMET

func _get_goggles_color() -> Color:
	return LevelConfig.SKI_PIN_GOGGLES

func _get_standing_sprite_path() -> String:
	return LevelConfig.ENEMY_STANDING_SPRITE_PATH_SPIKY

func _get_standing_sprite_target_height() -> float:
	return LevelConfig.ENEMY_STANDING_SPRITE_HEIGHT_SPIKY

func _get_downed_sprite_path() -> String:
	return LevelConfig.ENEMY_DOWNED_SPRITE_PATH_SPIKY

func _get_downed_sprite_target_width() -> float:
	return LevelConfig.ENEMY_DOWNED_SPRITE_WIDTH_SPIKY

func _draw_standing() -> void:
	if _can_draw_standing_sprite():
		_draw_standing_sprite()
		return

	var s := _get_draw_scale()
	var suit_col := _get_body_color()
	var helmet_col := _get_helmet_color()
	var goggles_col := _get_goggles_color()
	
	var bw := LevelConfig.PIN_BODY_WIDTH * 1.12
	var bh := LevelConfig.PIN_BODY_HEIGHT * 1.11
	
	_draw_nuanced_body(s, suit_col, bw, bh)
	
	draw_rect(Rect2(-bw*0.43, -bh*0.71, bw*0.86, 9.8*s), LevelConfig.SKI_PIN_ACCENT)
	draw_rect(Rect2(-bw*0.43, bh*0.04, bw*0.86, 7.5*s), LevelConfig.SKI_PIN_ACCENT)
	
	var helmet_y := -bh * 0.99
	var head_r := LevelConfig.PIN_HEAD_RADIUS * 1.41
	_draw_cartoon_head(helmet_col, goggles_col, head_r, helmet_y, s)
	_draw_detailed_face(helmet_y, head_r, s)
	
	for i in range(6):
		var a := -2.05 + i * 0.71
		var base := Vector2(0, helmet_y - head_r * 0.68)
		var tip := base + Vector2(cos(a), sin(a)) * 19.5 * s
		draw_line(base, tip, LevelConfig.SKI_PIN_ACCENT, 3.6*s)
	
	_draw_cute_skis_and_poles(s, suit_col)
	
	var ski_y := bh * 0.61
	draw_line(Vector2(-29*s, ski_y - 3.5*s), Vector2(29*s, ski_y - 3.5*s), LevelConfig.SKI_PIN_ACCENT, 2.4*s)
	
	var pole_offset := Vector2(18.5*s, -bh*0.26)
	draw_line(pole_offset, pole_offset + Vector2(15*s, 37*s), Color(0.94, 0.95, 1.0, 0.86), 3.6*s)
	draw_line(-pole_offset, -pole_offset + Vector2(-15*s, 37*s), Color(0.94, 0.95, 1.0, 0.86), 3.6*s)
	
	_draw_speed_sparkles(s, LevelConfig.ENEMY_CARTOON_SPARKLE_COUNT_STANDING + 2)
	
	draw_set_transform(LevelConfig.ENEMY_SHADOW_OFFSET, 0.0, Vector2(s * 1.11, s * 0.65))
	draw_circle(Vector2.ZERO, bw * 0.67, Color(0.0, 0.0, 0.0, 0.27))

func _draw_knocked() -> void:
	if _can_draw_downed_sprite():
		_draw_downed_sprite()
		return

	var s := _get_draw_scale()
	var rot := PI * 0.5 + 0.17
	draw_set_transform(Vector2.ZERO, rot, Vector2(s * 1.21, s * 0.79) * _visual_scale)
	
	var bw := LevelConfig.PIN_BODY_WIDTH
	var bh := LevelConfig.PIN_BODY_HEIGHT
	
	var tumbled_col := _get_body_color().darkened(0.23)
	draw_rect(Rect2(-bw*0.66, -bh*0.42, bw*1.58, bh*0.96), tumbled_col)
	for i in range(3):
		var fold_x := -bw * 0.55 + i * (bw * 1.1 / 2.0)
		draw_line(Vector2(fold_x, -bh*0.36), Vector2(fold_x * 0.76, -bh*0.04), tumbled_col.darkened(0.3), 2.5 * s)
	
	var helmet_y := -bh * 0.39
	var head_r := LevelConfig.PIN_HEAD_RADIUS * 1.37
	draw_circle(Vector2(bw*0.78, helmet_y), head_r, _get_helmet_color())
	_draw_detailed_face(helmet_y, head_r, s)
	
	var eye_y := helmet_y + 4.6 * s
	draw_circle(Vector2(bw*0.59, eye_y), LevelConfig.ENEMY_CARTOON_EYE_RADIUS * 0.86 * s, _get_goggles_color().darkened(0.35))
	draw_circle(Vector2(bw*0.97, eye_y), LevelConfig.ENEMY_CARTOON_EYE_RADIUS * 0.86 * s, _get_goggles_color().darkened(0.35))
	
	for i in range(5):
		var a := Time.get_ticks_msec() * 0.013 + i * 1.18
		var off := Vector2(cos(a) * 20 * s, sin(a) * 18 * s - 13 * s)
		draw_circle(Vector2(bw*0.79, helmet_y) + off, LevelConfig.ENEMY_CARTOON_DIZZY_STAR_SIZE * s, LevelConfig.ENEMY_CARTOON_DIZZY_STAR_COLOR)
	
	var ski_y := bh * 0.51
	draw_line(Vector2(-41*s, ski_y), Vector2(47*s, ski_y - 21*s), Color(0.09, 0.09, 0.16, 1.0), 6.2*s)
	draw_line(Vector2(-36*s, ski_y + 13*s), Vector2(43*s, ski_y + 2*s), Color(0.09, 0.09, 0.16, 1.0), 6.2*s)
	
	draw_line(Vector2(-25*s, ski_y - 13*s), Vector2(29*s, ski_y - 19*s), LevelConfig.SKI_PIN_ACCENT, 2.6*s)
	
	draw_circle(Vector2(bw*0.94, -bh*0.49), 6.9*s, Color.WHITE)
