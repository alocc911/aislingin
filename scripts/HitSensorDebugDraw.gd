extends Node2D

const POLYGON_COLOR: Color = Color(0.15, 0.95, 0.25, 0.95)
const SHAPE_COLOR: Color = Color(0.2, 0.9, 1.0, 0.95)
const FALLBACK_COLOR: Color = Color(1.0, 0.2, 0.85, 0.95)
const LINE_WIDTH: float = 2.0
const SEGMENTS: int = 24

func _ready() -> void:
	z_as_relative = false
	z_index = 5000
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var sensor: Node = get_parent()
	if sensor == null:
		return

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
	var transformed := PackedVector2Array()
	transformed.resize(points.size())
	for i in points.size():
		transformed[i] = poly.transform * points[i]
	draw_polyline(transformed, POLYGON_COLOR, LINE_WIDTH, true)
	draw_line(transformed[transformed.size() - 1], transformed[0], POLYGON_COLOR, LINE_WIDTH, true)


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
	draw_arc(xform.origin, radius, 0.0, TAU, SEGMENTS, color, LINE_WIDTH, true)


func _draw_rect_outline(xform: Transform2D, rect_size: Vector2, color: Color) -> void:
	var half := rect_size * 0.5
	var corners := [
		xform * Vector2(-half.x, -half.y),
		xform * Vector2(half.x, -half.y),
		xform * Vector2(half.x, half.y),
		xform * Vector2(-half.x, half.y),
	]
	draw_polyline(PackedVector2Array(corners), color, LINE_WIDTH, true)
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
	draw_arc(center, 12.0, 0.0, TAU, SEGMENTS, FALLBACK_COLOR, LINE_WIDTH, true)
