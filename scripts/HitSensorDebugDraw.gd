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
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	top_level = true
	z_as_relative = false
	z_index = 1000000
	show_behind_parent = false
	if _sensor != null and is_instance_valid(_sensor) and not _sensor.tree_exited.is_connected(_on_sensor_tree_exited):
		_sensor.tree_exited.connect(_on_sensor_tree_exited)
	print("[BossDebug][HitSensorDebugDraw] ready sensor_valid=", _sensor != null and is_instance_valid(_sensor), " parent=", get_parent().name if get_parent() != null else "<none>", " overlay_mode=top_level")


func _on_sensor_tree_exited() -> void:
	queue_free()


func _exit_tree() -> void:
	if _sensor != null and is_instance_valid(_sensor) and _sensor.tree_exited.is_connected(_on_sensor_tree_exited):
		_sensor.tree_exited.disconnect(_on_sensor_tree_exited)


func _process(_delta: float) -> void:
	if _sensor == null or not is_instance_valid(_sensor):
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _sensor == null or not is_instance_valid(_sensor):
		return
	_draw_cross(_sensor.global_position, FALLBACK_COLOR)
	for child_any in _sensor.get_children():
		var child: Node = child_any
		if child is CollisionPolygon2D:
			_draw_polygon(_sensor, child as CollisionPolygon2D)
		elif child is CollisionShape2D:
			_draw_shape(_sensor, child as CollisionShape2D)


func _draw_cross(world_pos: Vector2, color: Color) -> void:
	draw_line(to_local(world_pos + Vector2(-14, 0)), to_local(world_pos + Vector2(14, 0)), color, LINE_WIDTH, true)
	draw_line(to_local(world_pos + Vector2(0, -14)), to_local(world_pos + Vector2(0, 14)), color, LINE_WIDTH, true)


func _draw_polygon(sensor: Node2D, poly: CollisionPolygon2D) -> void:
	if poly.disabled or poly.polygon.size() < 3:
		return
	var points := PackedVector2Array()
	for p in poly.polygon:
		points.append(to_local((sensor.global_transform * poly.transform) * p))
	draw_polyline(points, POLYGON_COLOR, LINE_WIDTH, true)
	draw_line(points[points.size() - 1], points[0], POLYGON_COLOR, LINE_WIDTH, true)


func _draw_shape(sensor: Node2D, cs: CollisionShape2D) -> void:
	if cs.disabled:
		return
	var shape: Shape2D = cs.shape
	if shape is CircleShape2D:
		var c := shape as CircleShape2D
		_draw_circle(sensor.global_transform * cs.transform, c.radius, SHAPE_COLOR)
		return
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
		return
	_draw_circle(sensor.global_transform * cs.transform, 10.0, FALLBACK_COLOR)


func _draw_circle(xf: Transform2D, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in SEGMENTS:
		var t := TAU * float(i) / float(SEGMENTS)
		points.append(to_local(xf * (Vector2(cos(t), sin(t)) * radius)))
	draw_polyline(points, color, LINE_WIDTH, true)
	draw_line(points[points.size() - 1], points[0], color, LINE_WIDTH, true)
