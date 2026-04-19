extends "res://scripts/Pin.gd"
class_name HeavyPin
"""
Heavy snowboarder variant.

Higher knock resistance and mass.
Bulky padded jacket, wide snowboard, reinforced helmet with nuanced body and detailed face.
All core knock, poison, and physics behavior inherited from Pin.
"""

func _get_knock_threshold() -> float:
	return LevelConfig.PIN_KNOCK_VELOCITY_THRESHOLD * LevelConfig.ENEMY_KNOCK_MULTIPLIER_HEAVY

func _get_knock_mass() -> float:
	return 0.26

func _get_draw_scale() -> float:
	return LevelConfig.ENEMY_SCALE_HEAVY

func _get_body_color() -> Color:
	return LevelConfig.SKI_HEAVY_SUIT

func _get_helmet_color() -> Color:
	return LevelConfig.SKI_PIN_HELMET

func _get_goggles_color() -> Color:
	return LevelConfig.SKI_PIN_GOGGLES

func _get_standing_sprite_path() -> String:
	return LevelConfig.ENEMY_STANDING_SPRITE_PATH_HEAVY

func _get_standing_sprite_target_height() -> float:
	return LevelConfig.ENEMY_STANDING_SPRITE_HEIGHT_HEAVY

func _get_downed_sprite_path() -> String:
	return LevelConfig.ENEMY_DOWNED_SPRITE_PATH_HEAVY

func _get_downed_sprite_target_width() -> float:
	return LevelConfig.ENEMY_DOWNED_SPRITE_WIDTH_HEAVY

func _draw_standing() -> void:
	if _can_draw_standing_sprite():
		_draw_standing_sprite()
		return

	var s := _get_draw_scale()
	var suit_col := _get_body_color()
	var helmet_col := _get_helmet_color()
	var goggles_col := _get_goggles_color()

	var bw := LevelConfig.PIN_BODY_WIDTH * 1.32
	var bh := LevelConfig.PIN_BODY_HEIGHT * 1.18

	_draw_nuanced_body(s, suit_col, bw, bh)

	draw_rect(Rect2(-bw * 0.46, -bh * 0.68, bw * 0.92, 19.0 * s), LevelConfig.SKI_PIN_ACCENT)
	draw_rect(Rect2(-bw * 0.46, bh * 0.08, bw * 0.92, 15.0 * s), LevelConfig.SKI_PIN_ACCENT)

	var helmet_y := -bh * 1.02
	var head_r := LevelConfig.PIN_HEAD_RADIUS * 1.48
	_draw_cartoon_head(helmet_col, goggles_col, head_r, helmet_y, s)
	_draw_detailed_face(helmet_y, head_r, s)

	var board_y := bh * 0.68
	var board_len := 68.0 * s
	draw_rect(Rect2(-board_len * 0.5, board_y - 6.0 * s, board_len, 14.0 * s), Color(0.08, 0.08, 0.13, 1.0))
	draw_line(Vector2(-board_len * 0.5, board_y - 9.0 * s), Vector2(board_len * 0.5, board_y - 9.0 * s), Color(0.92, 0.95, 1.0, 1.0), 3.4 * s)

	var pole_offset := Vector2(26 * s, -bh * 0.19)
	draw_line(pole_offset, pole_offset + Vector2(10 * s, 46 * s), Color(0.94, 0.96, 1.0, 0.9), 5.2 * s)
	draw_line(-pole_offset, -pole_offset + Vector2(-10 * s, 46 * s), Color(0.94, 0.96, 1.0, 0.9), 5.2 * s)

	_draw_speed_sparkles(s, LevelConfig.ENEMY_CARTOON_SPARKLE_COUNT_STANDING + 1)

	draw_set_transform(LevelConfig.ENEMY_SHADOW_OFFSET * 1.25, 0.0, Vector2(s * 1.28, s * 0.72))
	draw_circle(Vector2.ZERO, bw * 0.82, Color(0.0, 0.0, 0.0, 0.28))

func _draw_knocked() -> void:
	if _can_draw_downed_sprite():
		_draw_downed_sprite()
		return

	var s := _get_draw_scale()
	var rot := PI * 0.5 + 0.19
	draw_set_transform(Vector2.ZERO, rot, Vector2(s * 1.34, s * 0.84) * _visual_scale)

	var bw := LevelConfig.PIN_BODY_WIDTH
	var bh := LevelConfig.PIN_BODY_HEIGHT

	var tumbled_col := _get_body_color().darkened(0.27)
	draw_rect(Rect2(-bw * 0.74, -bh * 0.47, bw * 1.74, bh * 1.12), tumbled_col)
	for i in range(4):
		var fold_x := -bw * 0.58 + i * (bw * 1.16 / 3.0)
		draw_line(Vector2(fold_x, -bh * 0.40), Vector2(fold_x * 0.75, -bh * 0.08), tumbled_col.darkened(0.32), 2.8 * s)

	var helmet_y := -bh * 0.44
	var head_r := LevelConfig.PIN_HEAD_RADIUS * 1.45
	draw_circle(Vector2(bw * 0.82, helmet_y), head_r, _get_helmet_color())
	_draw_detailed_face(helmet_y, head_r, s)

	var eye_y := helmet_y + 5.0 * s
	draw_circle(Vector2(bw * 0.64, eye_y), LevelConfig.ENEMY_CARTOON_EYE_RADIUS * 0.88 * s, _get_goggles_color().darkened(0.45))
	draw_circle(Vector2(bw * 1.0, eye_y), LevelConfig.ENEMY_CARTOON_EYE_RADIUS * 0.88 * s, _get_goggles_color().darkened(0.45))

	for i in range(6):
		var a := Time.get_ticks_msec() * 0.009 + i * 1.1
		var off := Vector2(cos(a) * 23 * s, sin(a) * 19 * s - 14 * s)
		draw_circle(Vector2(bw * 0.83, helmet_y) + off, LevelConfig.ENEMY_CARTOON_DIZZY_STAR_SIZE * s * 1.1, LevelConfig.ENEMY_CARTOON_DIZZY_STAR_COLOR)

	var board_y := bh * 0.55
	draw_line(Vector2(-52 * s, board_y), Vector2(58 * s, board_y + 16 * s), Color(0.08, 0.08, 0.13, 1.0), 11.0 * s)

	draw_circle(Vector2(bw * 1.02, -bh * 0.58), 8.2 * s, Color.WHITE)
