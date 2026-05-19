extends Node2D

const POLYGON_COLOR: Color = Color(0.1, 1.0, 0.2, 1.0)
const SHAPE_COLOR: Color = Color(0.1, 0.9, 1.0, 1.0)
const FALLBACK_COLOR: Color = Color(1.0, 0.1, 0.9, 1.0)
const LINE_WIDTH: float = 6.0
const SEGMENTS: int = 24

var sensor_path: NodePath = NodePath("../HitSensor")

func _ready() -> void:
	z_as_relative = false
	z_index = 100000
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	print("[BossDebug][HitSensorDebugDraw] ready part=", get_parent().name if get_parent() != null else "<none>", " sensor_found=", _resolve_sensor() != null)


func _process(_delta: float) -> void:
	_rebuild_lines()


func _rebuild_lines() -> void:
	for child_any in get_children():
		(child_any as Node).queue_free()
	var sensor: Node2D = _resolve_sensor()
	if sensor == null:
		return

	# anchor marker so we always know draw node is alive
	var cross := Line2D.new()
	cross.default_color = FALLBACK_COLOR
	cross.width = LINE_WIDTH
	cross.points = PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(0, 0), Vector2(0, -8), Vector2(0, 8)])
	cross.global_position = sensor.global_position
	add_child(cross)

	var rendered: int = 0
	for child_any in sensor.get_children():
		var child: Node = child_any
		if child is CollisionPolygon2D:
			if _add_polygon(sensor, child as CollisionPolygon2D): rendered += 1
		elif child is CollisionShape2D:
			if _add_shape(sensor, child as CollisionShape2D): rendered += 1
	if Engine.get_process_frames() % 60 == 0:
		print("[BossDebug][HitSensorDebugDraw] rebuilt part=", get_parent().name if get_parent() != null else "<none>", " rendered=", rendered, " sensor_pos=", sensor.global_position)


func _resolve_sensor() -> Node2D:
	var via_path: Node2D = get_node_or_null(sensor_path) as Node2D
	if via_path != null:
		return via_path
	var p: Node = get_parent()
	if p == null:
		return null
	for child_any in p.get_children():
		var child: Node = child_any
		if child is Area2D and child.name == "HitSensor":
			return child as Node2D
	return null


func _add_polygon(sensor: Node2D, poly: CollisionPolygon2D) -> bool:
	if poly.disabled or poly.polygon.size() < 3:
		return false
	var line := Line2D.new()
	line.default_color = POLYGON_COLOR
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = poly.polygon
	line.global_transform = sensor.global_transform * poly.transform
	add_child(line)
	return true


func _add_shape(sensor: Node2D, cs: CollisionShape2D) -> bool:
	if cs.disabled:
		return false
	var shape: Shape2D = cs.shape
	if shape is CircleShape2D:
		return _add_circle(sensor.global_transform * cs.transform, (shape as CircleShape2D).radius, SHAPE_COLOR)
	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		return _add_rect(sensor.global_transform * cs.transform, rect.size, SHAPE_COLOR)
	return _add_circle(sensor.global_transform * cs.transform, 12.0, FALLBACK_COLOR)


func _add_circle(xf: Transform2D, radius: float, color: Color) -> bool:
	var pts := PackedVector2Array()
	for i in SEGMENTS:
		var t := TAU * float(i) / float(SEGMENTS)
		pts.append(Vector2(cos(t), sin(t)) * radius)
	var line := Line2D.new()
	line.default_color = color
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = pts
	line.global_transform = xf
	add_child(line)
	return true


func _add_rect(xf: Transform2D, size: Vector2, color: Color) -> bool:
	var h := size * 0.5
	var line := Line2D.new()
	line.default_color = color
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	line.global_transform = xf
	add_child(line)
	return true
