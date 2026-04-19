extends "res://scripts/Pin.gd"
class_name Chief
"""
Boss-tier Chief pin with wandering AI.

Behavior:
- Uses a fixed spawn anchor and periodically picks small random wander targets.
- Avoids voluntarily wandering into water.
- Can still be bumped into water and die there.
- Applies strong slowdown to the ball on hit.

All knock, poison, and base water-death behavior are inherited from Pin.
"""

var _anchor_pos: Vector2
var _target_pos: Vector2
var _wander_timer: float = 0.0

var _water_scan_timer: float = 0.0
var _known_water_areas: Array[Area2D] = []

func _ready() -> void:
	super._ready()
	call_deferred("_capture_spawn_anchor")

func _capture_spawn_anchor() -> void:
	_anchor_pos = global_position
	_refresh_water_cache()
	_anchor_pos = _find_nearest_dry_point(_anchor_pos)
	_target_pos = _anchor_pos
	_pick_wander_target()

func _has_ai() -> bool:
	return true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if knocked_over or is_sunk_in_water():
		return

	_water_scan_timer -= delta
	if _water_scan_timer <= 0.0:
		_refresh_water_cache()

	_wander_timer -= delta
	if _wander_timer <= 0.0 or _is_target_unsafe(_target_pos):
		_pick_wander_target()

	if global_position.distance_to(_target_pos) < 16.0:
		_pick_wander_target()

	var dir_to_target := _target_pos - global_position
	if dir_to_target.length() < 0.001:
		return

	var dir := dir_to_target.normalized()

	if _would_step_into_water(dir, delta) or _path_crosses_water(global_position, _target_pos):
		_pick_wander_target()
		dir_to_target = _target_pos - global_position
		if dir_to_target.length() < 0.001:
			return
		dir = dir_to_target.normalized()

		if _would_step_into_water(dir, delta) or _path_crosses_water(global_position, _target_pos):
			_steer_away_from_water()
			return

	apply_central_force(dir * LevelConfig.CHIEF_WANDER_SPEED * mass)

func _pick_wander_target() -> void:
	_wander_timer = randf_range(0.4, 0.8)

	var best_target := _anchor_pos
	var found := false

	for _i in range(20):
		var angle := randf_range(0.0, TAU)
		var dist := randf_range(0.0, LevelConfig.CHIEF_MAX_WANDER_OFFSET)
		var candidate := _anchor_pos + Vector2(cos(angle), sin(angle)) * dist

		if _is_target_unsafe(candidate):
			continue
		if _path_crosses_water(global_position, candidate):
			continue

		best_target = candidate
		found = true
		break

	if not found:
		for _j in range(8):
			var angle2 := randf_range(0.0, TAU)
			var dist2 := randf_range(12.0, 40.0)
			var candidate2 := global_position + Vector2(cos(angle2), sin(angle2)) * dist2
			if _is_target_unsafe(candidate2):
				continue
			if _path_crosses_water(global_position, candidate2):
				continue
			best_target = candidate2
			found = true
			break

	if not found:
		best_target = _find_nearest_dry_point(_anchor_pos)

	_target_pos = best_target

func _refresh_water_cache() -> void:
	_water_scan_timer = 0.85
	_known_water_areas.clear()

	var tree := get_tree()
	if tree == null:
		return

	var root := tree.current_scene
	if root == null:
		root = tree.root
	if root == null:
		return

	_collect_water_areas(root)

func _collect_water_areas(node: Node) -> void:
	if node is Area2D and node.has_meta("zone_type") and str(node.get_meta("zone_type")) == "water":
		_known_water_areas.append(node as Area2D)

	for child in node.get_children():
		_collect_water_areas(child)

func _is_target_unsafe(point: Vector2) -> bool:
	return _point_in_known_water(point, LevelConfig.WATER_EDGE_AVOIDANCE_PADDING)

func _would_step_into_water(dir: Vector2, delta: float) -> bool:
	var lookahead_dist := maxf(20.0, linear_velocity.length() * maxf(delta, 0.10) + 30.0)
	var lookahead_point := global_position + dir * lookahead_dist
	return _point_in_known_water(lookahead_point, LevelConfig.WATER_EDGE_AVOIDANCE_PADDING)

func _path_crosses_water(from_point: Vector2, to_point: Vector2) -> bool:
	var travel := to_point - from_point
	var dist := travel.length()
	if dist <= 0.001:
		return _point_in_known_water(from_point, LevelConfig.WATER_EDGE_AVOIDANCE_PADDING)

	var steps := maxi(2, ceili(dist / 26.0))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var sample := from_point.lerp(to_point, t)
		if _point_in_known_water(sample, LevelConfig.WATER_EDGE_AVOIDANCE_PADDING):
			return true
	return false

func _point_in_known_water(point: Vector2, padding: float = 0.0) -> bool:
	for area in _known_water_areas:
		if not is_instance_valid(area) or area.is_queued_for_deletion():
			continue
		if _point_inside_water_with_padding(point, area, padding):
			return true
	return false

func _point_inside_water_with_padding(world_point: Vector2, area: Area2D, padding: float = 0.0) -> bool:
	var center := area.global_position
	var base_radius := float(area.get_meta("zone_radius", 0.0)) + padding
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

func _find_nearest_dry_point(origin: Vector2) -> Vector2:
	if not _point_in_known_water(origin, LevelConfig.WATER_EDGE_AVOIDANCE_PADDING):
		return origin

	for ring in range(1, 9):
		var radius := 28.0 * float(ring)
		for step in range(16):
			var angle := (TAU / 16.0) * float(step)
			var candidate := origin + Vector2(cos(angle), sin(angle)) * radius
			if not _point_in_known_water(candidate, LevelConfig.WATER_EDGE_AVOIDANCE_PADDING):
				return candidate

	return origin

func _steer_away_from_water() -> void:
	var nearest_center := Vector2.ZERO
	var nearest_dist := INF
	var found := false

	for area in _known_water_areas:
		if not is_instance_valid(area) or area.is_queued_for_deletion():
			continue
		var d := global_position.distance_to(area.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_center = area.global_position
			found = true

	if found:
		var away := global_position - nearest_center
		if away.length() > 0.001:
			apply_central_force(away.normalized() * LevelConfig.CHIEF_WANDER_SPEED * mass * 0.95)

	if linear_velocity.length() > 10.0:
		linear_velocity *= 0.90

func _get_knock_threshold() -> float:
	return LevelConfig.PIN_KNOCK_VELOCITY_THRESHOLD * LevelConfig.ENEMY_KNOCK_MULTIPLIER_CHIEF

func _get_knock_mass() -> float:
	return 0.38

func _on_hit_ball(ball: RigidBody2D) -> void:
	if ball and ball.has_method("apply_hit_slowdown"):
		ball.apply_hit_slowdown(LevelConfig.ENEMY_SLOWDOWN_CHIEF)

func _get_draw_scale() -> float:
	return LevelConfig.ENEMY_SCALE_CHIEF

func _get_body_color() -> Color:
	return LevelConfig.SKI_CHIEF_SUIT

func _get_helmet_color() -> Color:
	return LevelConfig.SKI_PIN_HELMET

func _get_goggles_color() -> Color:
	return LevelConfig.SKI_PIN_GOGGLES

func _get_standing_sprite_path() -> String:
	return LevelConfig.ENEMY_STANDING_SPRITE_PATH_CHIEF

func _get_standing_sprite_target_height() -> float:
	return LevelConfig.ENEMY_STANDING_SPRITE_HEIGHT_CHIEF

func _get_downed_sprite_path() -> String:
	return LevelConfig.ENEMY_DOWNED_SPRITE_PATH_CHIEF

func _get_downed_sprite_target_width() -> float:
	return LevelConfig.ENEMY_DOWNED_SPRITE_WIDTH_CHIEF

func _draw_standing() -> void:
	if _can_draw_standing_sprite():
		draw_circle(Vector2.ZERO, LevelConfig.PIN_BODY_WIDTH * 1.22 * 0.95, Color(1.0, 0.88, 0.35, 0.26))
		_draw_standing_sprite()
		return

	_draw_standing_fallback()

func _draw_standing_fallback() -> void:
	var s := _get_draw_scale()
	var suit_col := _get_body_color()
	var helmet_col := _get_helmet_color()
	var goggles_col := _get_goggles_color()

	var bw := LevelConfig.PIN_BODY_WIDTH * 1.22
	var bh := LevelConfig.PIN_BODY_HEIGHT * 1.25

	_draw_nuanced_body(s, suit_col, bw, bh)

	draw_rect(Rect2(-bw * 0.46, -bh * 0.71, bw * 0.92, 13.5 * s), LevelConfig.SKI_CHIEF_ACCENT)
	draw_rect(Rect2(-bw * 0.46, bh * 0.12, bw * 0.92, 11.0 * s), LevelConfig.SKI_CHIEF_ACCENT)

	draw_rect(Rect2(-bw * 0.42, -bh * 0.85, bw * 0.84, 6.0 * s), Color.WHITE, false, 2.6 * s)

	var helmet_y := -bh * 1.04
	var head_r := LevelConfig.PIN_HEAD_RADIUS * 1.52
	_draw_cartoon_head(helmet_col, goggles_col, head_r, helmet_y, s)
	_draw_detailed_face(helmet_y, head_r, s)

	draw_circle(Vector2(0, helmet_y - 16.0 * s), 8.8 * s, LevelConfig.SKI_CHIEF_ACCENT)
	draw_circle(Vector2(0, helmet_y - 16.0 * s), 4.2 * s, Color.WHITE)

	var banner_start := Vector2(-bw * 0.49, -bh * 0.38)
	var banner_end := banner_start + Vector2(-42 * s, 58 * s)
	draw_line(banner_start, banner_end, LevelConfig.SKI_CHIEF_ACCENT, 11.5 * s)
	draw_line(banner_start + Vector2(5 * s, 0), banner_end + Vector2(8 * s, -11 * s), Color.WHITE, 4.8 * s)

	_draw_cute_skis_and_poles(s, suit_col)

	var ski_y := bh * 0.64
	draw_line(Vector2(-37 * s, ski_y), Vector2(-49 * s, ski_y - 13 * s), LevelConfig.SKI_CHIEF_ACCENT, 4.1 * s)
	draw_line(Vector2(37 * s, ski_y), Vector2(49 * s, ski_y - 13 * s), LevelConfig.SKI_CHIEF_ACCENT, 4.1 * s)

	_draw_speed_sparkles(s, LevelConfig.ENEMY_CARTOON_SPARKLE_COUNT_STANDING + 3)

	draw_circle(Vector2.ZERO, bw * 0.95, Color(1.0, 0.88, 0.35, 0.26))

	draw_set_transform(LevelConfig.ENEMY_SHADOW_OFFSET * 1.28, 0.0, Vector2(s * 1.32, s * 0.76))
	draw_circle(Vector2.ZERO, bw * 0.84, Color(0.0, 0.0, 0.0, 0.27))

func _draw_knocked() -> void:
	if _can_draw_downed_sprite():
		_draw_downed_sprite()
		return

	_draw_knocked_fallback()

func _draw_knocked_fallback() -> void:
	var s := _get_draw_scale()
	var rot := PI * 0.5 + 0.21
	draw_set_transform(Vector2.ZERO, rot, Vector2(s * 1.38, s * 0.86) * _visual_scale)

	var bw := LevelConfig.PIN_BODY_WIDTH
	var bh := LevelConfig.PIN_BODY_HEIGHT

	var tumbled_col := _get_body_color().darkened(0.25)
	draw_rect(Rect2(-bw * 0.73, -bh * 0.48, bw * 1.76, bh * 1.08), tumbled_col)
	for i in range(4):
		var fold_x := -bw * 0.62 + i * (bw * 1.24 / 3.0)
		draw_line(Vector2(fold_x, -bh * 0.41), Vector2(fold_x * 0.72, -bh * 0.06), tumbled_col.darkened(0.28), 2.9 * s)

	var helmet_y := -bh * 0.43
	var head_r := LevelConfig.PIN_HEAD_RADIUS * 1.48
	draw_circle(Vector2(bw * 0.81, helmet_y), head_r, _get_helmet_color())
	_draw_detailed_face(helmet_y, head_r, s)

	var eye_y := helmet_y + 5.2 * s
	draw_circle(Vector2(bw * 0.62, eye_y), LevelConfig.ENEMY_CARTOON_EYE_RADIUS * 0.85 * s, _get_goggles_color().darkened(0.42))
	draw_circle(Vector2(bw * 1.0, eye_y), LevelConfig.ENEMY_CARTOON_EYE_RADIUS * 0.85 * s, _get_goggles_color().darkened(0.42))

	for i in range(7):
		var a := Time.get_ticks_msec() * 0.008 + i * 1.05
		var off := Vector2(cos(a) * 26 * s, sin(a) * 21 * s - 15 * s)
		draw_circle(Vector2(bw * 0.82, helmet_y) + off, LevelConfig.ENEMY_CARTOON_DIZZY_STAR_SIZE * s * 1.15, LevelConfig.ENEMY_CARTOON_DIZZY_STAR_COLOR)

	draw_line(Vector2(-31 * s, -bh * 0.31), Vector2(55 * s, -bh * 0.58), LevelConfig.SKI_CHIEF_ACCENT, 12.0 * s)
	draw_line(Vector2(-26 * s, -bh * 0.24), Vector2(51 * s, -bh * 0.51), Color.WHITE, 5.2 * s)

	var ski_y := bh * 0.56
	draw_line(Vector2(-48 * s, ski_y), Vector2(60 * s, ski_y + 19 * s), Color(0.09, 0.09, 0.16, 1.0), 7.8 * s)

	draw_circle(Vector2(bw * 0.96, -bh * 0.51), 8.8 * s, Color.WHITE)
