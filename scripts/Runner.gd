extends "res://scripts/Pin.gd"
class_name Runner
"""
Fast freestyle racer pin with AI pathing.

Behavior:
- Periodically picks new random targets near its spawn anchor.
- Avoids choosing targets in water.
- Refuses to continue along a path that would voluntarily enter water.
- If shoved toward water, it can still end up in water and die, which matches design.

All knock, poison, and base water-death behavior are inherited from Pin.
"""

var _spawn_pos: Vector2
var _target_pos: Vector2
var _path_timer: float = 0.0

var _water_scan_timer: float = 0.0
var _known_water_areas: Array[Area2D] = []

func _ready() -> void:
	super._ready()
	_spawn_pos = global_position
	_refresh_water_cache()
	_pick_new_target()

func _has_ai() -> bool:
	return true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if knocked_over or is_sunk_in_water():
		return

	_water_scan_timer -= delta
	if _water_scan_timer <= 0.0:
		_refresh_water_cache()

	_path_timer -= delta
	if _path_timer <= 0.0 or _is_target_unsafe(_target_pos):
		_pick_new_target()

	if global_position.distance_to(_target_pos) < 18.0:
		_pick_new_target()

	var dir_to_target := _target_pos - global_position
	if dir_to_target.length() < 0.001:
		return

	var dir := dir_to_target.normalized()

	if _would_step_into_water(dir, delta) or _path_crosses_water(global_position, _target_pos):
		_pick_new_target()
		dir_to_target = _target_pos - global_position
		if dir_to_target.length() < 0.001:
			return
		dir = dir_to_target.normalized()

		if _would_step_into_water(dir, delta) or _path_crosses_water(global_position, _target_pos):
			_steer_away_from_water()
			return

	apply_central_force(dir * LevelConfig.RUNNER_BASE_SPEED * mass)

func _pick_new_target() -> void:
	_path_timer = LevelConfig.RUNNER_PATH_UPDATE_INTERVAL

	var min_dist := 80.0
	var max_dist := float(LevelConfig.RUNNER_MAX_DISTANCE_FROM_SPAWN)
	var best_target := _spawn_pos
	var found := false

	for _i in range(24):
		var angle := randf_range(0.0, TAU)
		var dist := randf_range(min_dist, max_dist)
		var candidate := _spawn_pos + Vector2(cos(angle), sin(angle)) * dist
		candidate = candidate.clamp(
			_spawn_pos - Vector2(max_dist, max_dist),
			_spawn_pos + Vector2(max_dist, max_dist)
		)

		if _is_target_unsafe(candidate):
			continue
		if _path_crosses_water(global_position, candidate):
			continue

		best_target = candidate
		found = true
		break

	if not found:
		for _j in range(10):
			var angle2 := randf_range(0.0, TAU)
			var dist2 := randf_range(30.0, min_dist)
			var candidate2 := global_position + Vector2(cos(angle2), sin(angle2)) * dist2
			if _is_target_unsafe(candidate2):
				continue
			if _path_crosses_water(global_position, candidate2):
				continue
			best_target = candidate2
			found = true
			break

	if not found:
		best_target = _find_nearest_dry_point(_spawn_pos)

	_target_pos = best_target

func _refresh_water_cache() -> void:
	_water_scan_timer = 0.75
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
	var lookahead_dist := maxf(22.0, linear_velocity.length() * maxf(delta, 0.10) + 34.0)
	var lookahead_point := global_position + dir * lookahead_dist
	return _point_in_known_water(lookahead_point, LevelConfig.WATER_EDGE_AVOIDANCE_PADDING)

func _path_crosses_water(from_point: Vector2, to_point: Vector2) -> bool:
	var travel := to_point - from_point
	var dist := travel.length()
	if dist <= 0.001:
		return _point_in_known_water(from_point, LevelConfig.WATER_EDGE_AVOIDANCE_PADDING)

	var steps := maxi(2, ceili(dist / 28.0))
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
		var radius := 26.0 * float(ring)
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
			apply_central_force(away.normalized() * LevelConfig.RUNNER_BASE_SPEED * mass * 0.95)

	if linear_velocity.length() > 12.0:
		linear_velocity *= 0.90

func _get_draw_scale() -> float:
	return LevelConfig.ENEMY_SCALE_RUNNER

func _get_body_color() -> Color:
	return LevelConfig.SKI_RUNNER_SUIT

func _get_helmet_color() -> Color:
	return LevelConfig.SKI_PIN_HELMET

func _get_goggles_color() -> Color:
	return LevelConfig.SKI_PIN_GOGGLES

func _get_standing_sprite_path() -> String:
	return LevelConfig.ENEMY_STANDING_SPRITE_PATH_RUNNER

func _get_standing_sprite_target_height() -> float:
	return LevelConfig.ENEMY_STANDING_SPRITE_HEIGHT_RUNNER

func _get_downed_sprite_path() -> String:
	return LevelConfig.ENEMY_DOWNED_SPRITE_PATH_RUNNER

func _get_downed_sprite_target_width() -> float:
	return LevelConfig.ENEMY_DOWNED_SPRITE_WIDTH_RUNNER

func _draw_standing() -> void:
	if _can_draw_standing_sprite():
		_draw_standing_sprite()
		return

	var s := _get_draw_scale()
	var suit_col := _get_body_color()
	var helmet_col := _get_helmet_color()
	var goggles_col := _get_goggles_color()

	var bw := LevelConfig.PIN_BODY_WIDTH * 1.05
	var bh := LevelConfig.PIN_BODY_HEIGHT * 1.02

	_draw_nuanced_body(s, suit_col, bw, bh)

	draw_rect(Rect2(-bw * 0.44, -bh * 0.65, bw * 0.88, 9.5 * s), LevelConfig.SKI_PIN_ACCENT)

	var helmet_y := -bh * 0.98
	var head_r := LevelConfig.PIN_HEAD_RADIUS * 1.35
	_draw_cartoon_head(helmet_col, goggles_col, head_r, helmet_y, s)
	_draw_detailed_face(helmet_y, head_r, s)

	var tuft_offset := Vector2(-4.5 * s, helmet_y - head_r * 0.88)
	draw_circle(tuft_offset, 6.8 * s, suit_col)
	draw_circle(tuft_offset + Vector2(3.5 * s, -2.5 * s), 4.1 * s, suit_col)

	_draw_cute_skis_and_poles(s, suit_col)

	var ski_y := bh * 0.59
	draw_line(Vector2(-36 * s, ski_y), Vector2(-46 * s, ski_y - 13 * s), Color(0.88, 0.92, 0.98, 1.0), 3.1 * s)
	draw_line(Vector2(36 * s, ski_y), Vector2(46 * s, ski_y - 13 * s), Color(0.88, 0.92, 0.98, 1.0), 3.1 * s)

	_draw_speed_sparkles(s, LevelConfig.ENEMY_CARTOON_SPARKLE_COUNT_STANDING + 2)

	draw_set_transform(LevelConfig.ENEMY_SHADOW_OFFSET * 1.15, 0.0, Vector2(s * 1.10, s * 0.62))
	draw_circle(Vector2.ZERO, bw * 0.72, Color(0.0, 0.0, 0.0, 0.26))
