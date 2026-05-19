extends Node2D

const POLYGON_COLOR: Color = Color(0.15, 0.95, 0.25, 1.0)
const SHAPE_COLOR: Color = Color(0.2, 0.9, 1.0, 1.0)
const FALLBACK_COLOR: Color = Color(1.0, 0.2, 0.85, 1.0)
const FILL_ALPHA: float = 0.25
const LINE_WIDTH: float = 4.0
const SEGMENTS: int = 40

var _did_log_first_draw: bool = false

func _ready() -> void:
	visible = true
	show_behind_parent = false
	top_level = false
	z_as_relative = false
	z_index = 100000
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var sensor: Node2D = get_parent() as Node2D
	if sensor == null:
		return
	if not _did_log_first_draw:
		_did_log_first_draw = true
		print("[BossDebug][HitSensorDebugDraw] First draw for sensor=", sensor.name, " children=", sensor.get_child_count())

	for child_any in sensor.get_children():
		var child: Node = child_any
		if child is CollisionPolygon2D:
			_draw_collision_polygon(child as CollisionPolygon2D)
		elif child is CollisionShape2D:
			_draw_collision_shape(child as CollisionShape2D)


func _draw_collision_polygon(poly: CollisionPolygon2D) -> void:
	if poly.disabled:
		return
	var points: PackedVector2Array = poly.polygon
	if points.size() < 2:
		return
	var local_points := PackedVector2Array()
	for i in points.size():
		local_points.append(poly.transform * points[i])
	var fill_color: Color = POLYGON_COLOR
	fill_color.a = FILL_ALPHA
	draw_colored_polygon(local_points, fill_color)
	draw_polyline(local_points, POLYGON_COLOR, LINE_WIDTH, true)
	draw_line(local_points[local_points.size() - 1], local_points[0], POLYGON_COLOR, LINE_WIDTH, true)


func _draw_collision_shape(collision_shape: CollisionShape2D) -> void:
	if collision_shape.disabled:
		return
	var shape: Shape2D = collision_shape.shape
	if shape == null:
		_draw_fallback(collision_shape)
		return
	if shape is CircleShape2D:
		var circle: CircleShape2D = shape as CircleShape2D
		_draw_circle_outline(collision_shape.transform, circle.radius, SHAPE_COLOR)
		return
	if shape is RectangleShape2D:
		var rect: RectangleShape2D = shape as RectangleShape2D
		_draw_rect_outline(collision_shape.transform, rect.size, SHAPE_COLOR)
		return
	if shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = shape as CapsuleShape2D
		_draw_capsule_outline(collision_shape.transform, capsule.radius, capsule.height, SHAPE_COLOR)
		return
	_draw_fallback(collision_shape)


func _draw_circle_outline(xform: Transform2D, radius: float, color: Color) -> void:
	var center: Vector2 = xform.origin
	var fill_color: Color = color
	fill_color.a = FILL_ALPHA
	draw_circle(center, radius, fill_color)
	draw_arc(center, radius, 0.0, TAU, SEGMENTS, color, LINE_WIDTH, true)


func _draw_rect_outline(xform: Transform2D, rect_size: Vector2, color: Color) -> void:
	var half := rect_size * 0.5
	var corners := PackedVector2Array([
		xform * Vector2(-half.x, -half.y),
		xform * Vector2(half.x, -half.y),
		xform * Vector2(half.x, half.y),
		xform * Vector2(-half.x, half.y),
	])
	var fill_color: Color = color
	fill_color.a = FILL_ALPHA
	draw_colored_polygon(corners, fill_color)
	draw_polyline(corners, color, LINE_WIDTH, true)
	draw_line(corners[3], corners[0], color, LINE_WIDTH, true)


func _draw_capsule_outline(xform: Transform2D, radius: float, height: float, color: Color) -> void:
	var half_body: float = max((height * 0.5) - radius, 0.0)
	var top_center: Vector2 = xform * Vector2(0.0, -half_body)
	var bottom_center: Vector2 = xform * Vector2(0.0, half_body)
	draw_arc(top_center, radius, PI, TAU, SEGMENTS / 2, color, LINE_WIDTH, true)
	draw_arc(bottom_center, radius, 0.0, PI, SEGMENTS / 2, color, LINE_WIDTH, true)
	var left_top: Vector2 = xform * Vector2(-radius, -half_body)
	var left_bottom: Vector2 = xform * Vector2(-radius, half_body)
	var right_top: Vector2 = xform * Vector2(radius, -half_body)
	var right_bottom: Vector2 = xform * Vector2(radius, half_body)
	draw_line(left_top, left_bottom, color, LINE_WIDTH, true)
	draw_line(right_top, right_bottom, color, LINE_WIDTH, true)


func _draw_fallback(collision_shape: CollisionShape2D) -> void:
	var center: Vector2 = collision_shape.transform.origin
	draw_arc(center, 16.0, 0.0, TAU, SEGMENTS, FALLBACK_COLOR, LINE_WIDTH, true)
