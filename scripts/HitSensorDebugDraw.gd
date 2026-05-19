extends Node2D

const POLYGON_COLOR: Color = Color(0.1, 1.0, 0.2, 1.0)
const SHAPE_COLOR: Color = Color(0.1, 0.9, 1.0, 1.0)
const FALLBACK_COLOR: Color = Color(1.0, 0.1, 0.9, 1.0)
const LINE_WIDTH: float = 8.0
const SEGMENTS: int = 24

var sensor_path: NodePath = NodePath("../HitSensor")
var _sensor: Node2D = null
var _frame_counter: int = 0

func _ready() -> void:
	_sensor = _resolve_sensor_before_reparent()
	var scene_root: Node = get_tree().current_scene
	if scene_root != null and get_parent() != scene_root:
		var from_name: String = get_parent().name if get_parent() != null else "<none>"
		get_parent().remove_child(self)
		scene_root.add_child(self)
		owner = null
		print("[BossDebug][HitSensorDebugDraw] moved to scene root from=", from_name)
	top_level = true
	z_as_relative = false
	z_index = 1000000
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	print("[BossDebug][HitSensorDebugDraw] ready sensor_found=", _sensor != null, " sensor_global=", _sensor.global_position if _sensor != null else Vector2.ZERO)


func _process(_delta: float) -> void:
	if _sensor == null or not is_instance_valid(_sensor):
		if _frame_counter % 60 == 0:
			print("[BossDebug][HitSensorDebugDraw] sensor lost; skipping draw")
		_frame_counter += 1
		return
	_rebuild_lines()
	_frame_counter += 1
	if _frame_counter <= 5 or _frame_counter % 60 == 0:
		print("[BossDebug][HitSensorDebugDraw] frame=", _frame_counter, " sensor_global=", _sensor.global_position, " child_lines=", get_child_count())


func _resolve_sensor_before_reparent() -> Node2D:
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


func _rebuild_lines() -> void:
	for child_any in get_children():
		(child_any as Node).queue_free()
	_add_cross(_sensor.global_position, FALLBACK_COLOR)
	for child_any in _sensor.get_children():
		var child: Node = child_any
		if child is CollisionPolygon2D:
			_add_polygon(_sensor, child as CollisionPolygon2D)
		elif child is CollisionShape2D:
			_add_shape(_sensor, child as CollisionShape2D)


func _add_cross(world_pos: Vector2, color: Color) -> void:
	var h := Line2D.new()
	h.default_color = color
	h.width = LINE_WIDTH
	h.points = PackedVector2Array([Vector2(-12, 0), Vector2(12, 0)])
	h.global_position = world_pos
	h.top_level = true
	h.z_index = 1000001
	add_child(h)
	var v := Line2D.new()
	v.default_color = color
	v.width = LINE_WIDTH
	v.points = PackedVector2Array([Vector2(0, -12), Vector2(0, 12)])
	v.global_position = world_pos
	v.top_level = true
	v.z_index = 1000001
	add_child(v)


func _add_polygon(sensor: Node2D, poly: CollisionPolygon2D) -> void:
	if poly.disabled or poly.polygon.size() < 3:
		return
	var line := Line2D.new()
	line.default_color = POLYGON_COLOR
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = poly.polygon
	line.global_transform = sensor.global_transform * poly.transform
	line.top_level = true
	line.z_index = 1000001
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
		pts.append(Vector2(cos(t), sin(t)) * radius)
	var line := Line2D.new()
	line.default_color = color
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = pts
	line.global_transform = xf
	line.top_level = true
	line.z_index = 1000001
	add_child(line)


func _add_rect(xf: Transform2D, size: Vector2, color: Color) -> void:
	var h := size * 0.5
	var line := Line2D.new()
	line.default_color = color
	line.width = LINE_WIDTH
	line.closed = true
	line.antialiased = true
	line.points = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	line.global_transform = xf
	line.top_level = true
	line.z_index = 1000001
	add_child(line)
