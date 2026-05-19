extends Node2D

const POLYGON_COLOR: Color = Color(0.1, 1.0, 0.2, 1.0)
const SHAPE_COLOR: Color = Color(0.1, 0.9, 1.0, 1.0)
const FALLBACK_COLOR: Color = Color(1.0, 0.1, 0.9, 1.0)
const LINE_WIDTH: float = 6.0
const SEGMENTS: int = 28
const OVERLAY_ROOT_NAME: String = "HitSensorDebugOverlayRoot"

var sensor_path: NodePath = NodePath("../HitSensor")
var _sensor: Node2D = null

func _ready() -> void:
	_sensor = _resolve_sensor()
	var scene_root: Node = get_tree().current_scene
	if scene_root != null:
		var overlay_root: CanvasLayer = scene_root.get_node_or_null(OVERLAY_ROOT_NAME) as CanvasLayer
		if overlay_root == null:
			overlay_root = CanvasLayer.new()
			overlay_root.name = OVERLAY_ROOT_NAME
			overlay_root.layer = 100
			scene_root.add_child(overlay_root)
		if get_parent() != overlay_root:
			if get_parent() != null:
				get_parent().remove_child(self)
			overlay_root.add_child(self)
	top_level = true
	z_as_relative = false
	z_index = 1000000
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	print("[BossDebug][HitSensorDebugDraw] ready sensor_found=", _sensor != null, " parent=", get_parent().name if get_parent()!=null else "<none>")


func _process(_delta: float) -> void:
	if _sensor == null or not is_instance_valid(_sensor):
		_sensor = _resolve_sensor()
	if _sensor == null or not is_instance_valid(_sensor):
		if Engine.get_process_frames() % 120 == 0:
			print("[BossDebug][HitSensorDebugDraw] no sensor; skip")
		return
	queue_redraw()


func _resolve_sensor() -> Node2D:
	var via_path: Node2D = get_node_or_null(sensor_path) as Node2D
	if via_path != null:
		return via_path
	for node in get_tree().get_nodes_in_group("boss_part"):
		if node is Node and node.has_node("HitSensor"):
			var s: Node2D = node.get_node_or_null("HitSensor") as Node2D
			if s != null:
				return s
	return null


func _draw() -> void:
	if _sensor == null:
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
