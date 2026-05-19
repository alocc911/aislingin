extends Node2D

const POLYGON_COLOR: Color = Color(0.15, 0.95, 0.25, 0.95)
const SHAPE_COLOR: Color = Color(0.2, 0.9, 1.0, 0.95)
const FALLBACK_COLOR: Color = Color(1.0, 0.2, 0.85, 0.95)
const FILL_ALPHA: float = 0.22
const LINE_WIDTH: float = 10.0
const SEGMENTS: int = 32

var _sensor: Node2D = null

func _ready() -> void:
	visible = true
	self_modulate = Color(1, 1, 1, 1)
	top_level = true
	z_as_relative = false
	z_index = 100000
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_sensor = get_parent() as Node2D
	call_deferred("_rebuild")


func _process(_delta: float) -> void:
	if _sensor == null or not is_instance_valid(_sensor):
		queue_free()
		return
	_rebuild()


func _rebuild() -> void:
	for child_any in get_children():
		(child_any as Node).queue_free()

	if _sensor == null or not is_instance_valid(_sensor):
		print("[BossDebug][HitSensorDebugDraw] Rebuild skipped: sensor missing")
		return

	var rendered_count: int = 0
	for child_any in _sensor.get_children():
		var child: Node = child_any
		if child is CollisionPolygon2D:
			if _add_polygon_debug(_sensor, child as CollisionPolygon2D):
				rendered_count += 1
		elif child is CollisionShape2D:
			if _add_shape_debug(_sensor, child as CollisionShape2D):
				rendered_count += 1

	print("[BossDebug][HitSensorDebugDraw] Rebuilt sensor=", _sensor.name, " rendered=", rendered_count, " sensor_visible=", _sensor.visible, " sensor_global=", _sensor.global_position)


func _add_polygon_debug(sensor: Node2D, poly: CollisionPolygon2D) -> bool:
	if poly.disabled:
		return false
	var points: PackedVector2Array = poly.polygon
	if points.size() < 3:
		return false
	var line := Line2D.new()
	line.default_color = POLYGON_COLOR
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = points
	line.global_transform = sensor.global_transform * poly.transform
	line.top_level = true
	line.z_as_relative = false
	line.z_index = 100000
	add_child(line)

	var fill := Polygon2D.new()
	fill.polygon = points
	fill.global_transform = sensor.global_transform * poly.transform
	var c := POLYGON_COLOR
	c.a = FILL_ALPHA
	fill.color = c
	fill.top_level = true
	fill.z_as_relative = false
	fill.z_index = 99999
	add_child(fill)
	return true


func _add_shape_debug(sensor: Node2D, collision_shape: CollisionShape2D) -> bool:
	if collision_shape.disabled:
		return false
	var shape: Shape2D = collision_shape.shape
	if shape == null:
		return _add_fallback(sensor.global_transform * collision_shape.transform)

	if shape is CircleShape2D:
		return _add_circle(sensor.global_transform * collision_shape.transform, (shape as CircleShape2D).radius, SHAPE_COLOR)
	if shape is RectangleShape2D:
		return _add_rect(sensor.global_transform * collision_shape.transform, (shape as RectangleShape2D).size, SHAPE_COLOR)
	if shape is CapsuleShape2D:
		return _add_capsule(sensor.global_transform * collision_shape.transform, (shape as CapsuleShape2D).radius, (shape as CapsuleShape2D).height, SHAPE_COLOR)

	return _add_fallback(sensor.global_transform * collision_shape.transform)


func _add_circle(xform: Transform2D, radius: float, color: Color) -> bool:
	var points := PackedVector2Array()
	for i in SEGMENTS:
		var t := TAU * float(i) / float(SEGMENTS)
		points.append(xform * Vector2(cos(t), sin(t)) * radius)
	return _add_polyline_and_fill(points, color)


func _add_rect(xform: Transform2D, size: Vector2, color: Color) -> bool:
	var half := size * 0.5
	var points := PackedVector2Array([
		xform * Vector2(-half.x, -half.y),
		xform * Vector2(half.x, -half.y),
		xform * Vector2(half.x, half.y),
		xform * Vector2(-half.x, half.y),
	])
	return _add_polyline_and_fill(points, color)


func _add_capsule(xform: Transform2D, radius: float, height: float, color: Color) -> bool:
	var half_body: float = max((height * 0.5) - radius, 0.0)
	var points := PackedVector2Array()
	var arc_steps: int = max(SEGMENTS / 2, 8)
	for i in arc_steps + 1:
		var a_top := PI + PI * float(i) / float(arc_steps)
		points.append(xform * (Vector2(cos(a_top), sin(a_top)) * radius + Vector2(0.0, -half_body)))
	for j in arc_steps + 1:
		var a_bottom := PI * float(j) / float(arc_steps)
		points.append(xform * (Vector2(cos(a_bottom), sin(a_bottom)) * radius + Vector2(0.0, half_body)))
	return _add_polyline_and_fill(points, color)


func _add_fallback(xform: Transform2D) -> bool:
	return _add_circle(xform, 14.0, FALLBACK_COLOR)


func _add_polyline_and_fill(points: PackedVector2Array, color: Color) -> bool:
	if points.size() < 3:
		return false
	var fill := Polygon2D.new()
	fill.polygon = points
	var fill_color := color
	fill_color.a = FILL_ALPHA
	fill.color = fill_color
	fill.top_level = true
	fill.z_as_relative = false
	fill.z_index = 99999
	fill.top_level = true
	fill.z_as_relative = false
	fill.z_index = 99999
	add_child(fill)

	var line := Line2D.new()
	line.default_color = color
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = points
	line.top_level = true
	line.z_as_relative = false
	line.z_index = 100000
	line.top_level = true
	line.z_as_relative = false
	line.z_index = 100000
	add_child(line)
	return true
