extends Node2D

const POLYGON_COLOR: Color = Color(0.1, 1.0, 0.2, 1.0)
const SHAPE_COLOR: Color = Color(0.1, 0.9, 1.0, 1.0)
const FALLBACK_COLOR: Color = Color(1.0, 0.1, 0.9, 1.0)
const LINE_WIDTH: float = 6.0
const SEGMENTS: int = 28
var _sensor: Node2D = null

func set_target_sensor(sensor: Node2D) -> void:
	_sensor = sensor


func _ready() -> void:
	top_level = false
	z_as_relative = false
	z_index = 1000000
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	print("[BossDebug][HitSensorDebugDraw] ready sensor_valid=", _sensor != null and is_instance_valid(_sensor), " parent=", get_parent().name if get_parent()!=null else "<none>", " moved_to_overlay=false")


func _process(_delta: float) -> void:
	if _sensor == null or not is_instance_valid(_sensor):
		if Engine.get_process_frames() % 120 == 0:
			print("[BossDebug][HitSensorDebugDraw] no sensor ref; skip parent=", get_parent().name if get_parent()!=null else "<none>")
		return
	queue_redraw()


func _draw() -> void:
	if _sensor == null or not is_instance_valid(_sensor):
		return
	_draw_cross(_sensor.global_position, FALLBACK_COLOR)
	var count: int = 0
	for child_any in _sensor.get_children():
		var child: Node = child_any
		if child is CollisionPolygon2D:
			count += _draw_polygon(_sensor, child as CollisionPolygon2D)
		elif child is CollisionShape2D:
			count += _draw_shape(_sensor, child as CollisionShape2D)
	if Engine.get_process_frames() % 120 == 0:
		print("[BossDebug][HitSensorDebugDraw] draw count=", count, " sensor_pos=", _sensor.global_position)


func _draw_cross(world_pos: Vector2, color: Color) -> void:
	draw_line(to_local(world_pos + Vector2(-14, 0)), to_local(world_pos + Vector2(14, 0)), color, LINE_WIDTH, true)
	draw_line(to_local(world_pos + Vector2(0, -14)), to_local(world_pos + Vector2(0, 14)), color, LINE_WIDTH, true)


func _draw_polygon(sensor: Node2D, poly: CollisionPolygon2D) -> int:
	if poly.disabled or poly.polygon.size() < 3:
		return 0
	var points := PackedVector2Array()
	for p in poly.polygon:
		points.append(to_local((sensor.global_transform * poly.transform) * p))
	draw_polyline(points, POLYGON_COLOR, LINE_WIDTH, true)
	draw_line(points[points.size()-1], points[0], POLYGON_COLOR, LINE_WIDTH, true)
	return 1


func _draw_shape(sensor: Node2D, cs: CollisionShape2D) -> int:
	if cs.disabled:
		return 0
	var shape: Shape2D = cs.shape
	if shape is CircleShape2D:
		var c := shape as CircleShape2D
		_draw_circle(sensor.global_transform * cs.transform, c.radius, SHAPE_COLOR)
		return 1
	if shape is RectangleShape2D:
		var r := shape as RectangleShape2D
		var h := r.size * 0.5
		var points := PackedVector2Array([
			to_local((sensor.global_transform * cs.transform) * Vector2(-h.x, -h.y)),
			to_local((sensor.global_transform * cs.transform) * Vector2(h.x, -h.y)),
			to_local((sensor.global_transform * cs.transform) * Vector2(h.x, h.y)),
			to_local((sensor.global_transform * cs.transform) * Vector2(-h.x, h.y)),
		])
		draw_polyline(points, SHAPE_COLOR, LINE_WIDTH, true)
		draw_line(points[3], points[0], SHAPE_COLOR, LINE_WIDTH, true)
		return 1
	_draw_circle(sensor.global_transform * cs.transform, 10.0, FALLBACK_COLOR)
	return 1


func _draw_circle(xf: Transform2D, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in SEGMENTS:
		var t := TAU * float(i) / float(SEGMENTS)
		points.append(to_local(xf * Vector2(cos(t), sin(t)) * radius))
	draw_polyline(points, color, LINE_WIDTH, true)
	draw_line(points[points.size()-1], points[0], color, LINE_WIDTH, true)
