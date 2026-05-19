extends Node2D

const POLYGON_COLOR: Color = Color(0.1, 1.0, 0.2, 1.0)
const SHAPE_COLOR: Color = Color(0.1, 0.9, 1.0, 1.0)
const FALLBACK_COLOR: Color = Color(1.0, 0.1, 0.9, 1.0)
const LINE_WIDTH: float = 8.0
const SEGMENTS: int = 24

var sensor_path: NodePath = NodePath("../HitSensor")
var _missing_sensor_frames: int = 0

func _ready() -> void:
	top_level = false
	z_as_relative = false
	z_index = 1000000
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	var sensor: Node2D = _resolve_sensor()
	print("[BossDebug][HitSensorDebugDraw] ready part=", get_parent().name if get_parent() != null else "<none>", " sensor_found=", sensor != null)


func _process(_delta: float) -> void:
	var sensor: Node2D = _resolve_sensor()
	if sensor == null or not is_instance_valid(sensor):
		_missing_sensor_frames += 1
		if _missing_sensor_frames % 60 == 0:
			print("[BossDebug][HitSensorDebugDraw] missing sensor frames=", _missing_sensor_frames, " part=", get_parent().name if get_parent() != null else "<none>")
		if _missing_sensor_frames > 300:
			queue_free()
		return
	_missing_sensor_frames = 0
	_rebuild_lines(sensor)


func _resolve_sensor() -> Node2D:
	var via_path: Node2D = get_node_or_null(sensor_path) as Node2D
	if via_path != null:
		return via_path
	var parent_node: Node = get_parent()
	if parent_node == null:
		return null
	for child_any in parent_node.get_children():
		var child: Node = child_any
		if child is Area2D and child.name == "HitSensor":
			return child as Node2D
	return null


func _rebuild_lines(sensor: Node2D) -> void:
	for child_any in get_children():
		(child_any as Node).queue_free()
	_add_cross(to_local(sensor.global_position), FALLBACK_COLOR)
	for child_any in sensor.get_children():
		var child: Node = child_any
		if child is CollisionPolygon2D:
			_add_polygon(sensor, child as CollisionPolygon2D)
		elif child is CollisionShape2D:
			_add_shape(sensor, child as CollisionShape2D)


func _add_cross(local_pos: Vector2, color: Color) -> void:
	var h := Line2D.new()
	h.default_color = color
	h.width = LINE_WIDTH
	h.points = PackedVector2Array([local_pos + Vector2(-12, 0), local_pos + Vector2(12, 0)])
	add_child(h)
	var v := Line2D.new()
	v.default_color = color
	v.width = LINE_WIDTH
	v.points = PackedVector2Array([local_pos + Vector2(0, -12), local_pos + Vector2(0, 12)])
	add_child(v)


func _add_polygon(sensor: Node2D, poly: CollisionPolygon2D) -> void:
	if poly.disabled or poly.polygon.size() < 3:
		return
	var points := PackedVector2Array()
	for p in poly.polygon:
		points.append(to_local((sensor.global_transform * poly.transform) * p))
	var line := Line2D.new()
	line.default_color = POLYGON_COLOR
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = points
	add_child(line)


func _add_shape(sensor: Node2D, cs: CollisionShape2D) -> void:
	if cs.disabled:
		return
	var shape: Shape2D = cs.shape
	if shape is CircleShape2D:
		_add_circle(sensor.global_transform * cs.transform, (shape as CircleShape2D).radius, SHAPE_COLOR)
		return
	if shape is RectangleShape2D:
		_add_rect(sensor.global_transform * cs.transform, (shape as RectangleShape2D).size, SHAPE_COLOR)
		return
	_add_circle(sensor.global_transform * cs.transform, 12.0, FALLBACK_COLOR)


func _add_circle(xf: Transform2D, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in SEGMENTS:
		var t := TAU * float(i) / float(SEGMENTS)
		pts.append(to_local(xf * Vector2(cos(t), sin(t)) * radius))
	var line := Line2D.new()
	line.default_color = color
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = pts
	add_child(line)


func _add_rect(xf: Transform2D, size: Vector2, color: Color) -> void:
	var h := size * 0.5
	var line := Line2D.new()
	line.default_color = color
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = PackedVector2Array([
		to_local(xf * Vector2(-h.x, -h.y)),
		to_local(xf * Vector2(h.x, -h.y)),
		to_local(xf * Vector2(h.x, h.y)),
		to_local(xf * Vector2(-h.x, h.y)),
	])
	add_child(line)
