extends Node2D

const POLYGON_COLOR: Color = Color(0.15, 0.95, 0.25, 0.95)
const SHAPE_COLOR: Color = Color(0.2, 0.9, 1.0, 0.95)
const FALLBACK_COLOR: Color = Color(1.0, 0.2, 0.85, 0.95)
const LINE_WIDTH: float = 5.0
const SEGMENTS: int = 28

var sensor_path: NodePath = NodePath("../HitSensor")

func _ready() -> void:
	z_as_relative = false
	z_index = 100000
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	var sensor: Node = _resolve_sensor()
	print("[BossDebug][HitSensorDebugDraw] ready part=", get_parent().name if get_parent() != null else "<none>", " sensor_found=", sensor != null, " sensor_path=", String(sensor_path), " sibling_count=", get_parent().get_child_count() if get_parent() != null else -1)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var sensor: Node2D = _resolve_sensor()
	if sensor == null:
		if Engine.get_process_frames() % 120 == 0:
			print("[BossDebug][HitSensorDebugDraw] draw skipped no sensor part=", get_parent().name if get_parent() != null else "<none>")
		return
	var rendered: int = 0
	for child_any in sensor.get_children():
		var child: Node = child_any
		if child is CollisionPolygon2D:
			rendered += _draw_polygon(sensor, child as CollisionPolygon2D)
		elif child is CollisionShape2D:
			rendered += _draw_shape(sensor, child as CollisionShape2D)
	if Engine.get_process_frames() % 120 == 0:
		print("[BossDebug][HitSensorDebugDraw] draw part=", get_parent().name, " rendered=", rendered)




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
func _draw_polygon(sensor: Node2D, poly: CollisionPolygon2D) -> int:
	if poly.disabled or poly.polygon.size() < 3:
		return 0
	var pts := PackedVector2Array()
	for p in poly.polygon:
		pts.append(to_local((sensor.global_transform * poly.transform) * p))
	draw_polyline(pts, POLYGON_COLOR, LINE_WIDTH, true)
	draw_line(pts[pts.size()-1], pts[0], POLYGON_COLOR, LINE_WIDTH, true)
	return 1


func _draw_shape(sensor: Node2D, cs: CollisionShape2D) -> int:
	if cs.disabled:
		return 0
	var shape: Shape2D = cs.shape
	if shape is CircleShape2D:
		var c := shape as CircleShape2D
		_draw_circle_points(sensor.global_transform * cs.transform, c.radius, SHAPE_COLOR)
		return 1
	if shape is RectangleShape2D:
		var r := shape as RectangleShape2D
		var h := r.size * 0.5
		var corners := [Vector2(-h.x,-h.y), Vector2(h.x,-h.y), Vector2(h.x,h.y), Vector2(-h.x,h.y)]
		var pts := PackedVector2Array()
		for corner in corners:
			pts.append(to_local((sensor.global_transform * cs.transform) * corner))
		draw_polyline(pts, SHAPE_COLOR, LINE_WIDTH, true)
		draw_line(pts[3], pts[0], SHAPE_COLOR, LINE_WIDTH, true)
		return 1
	_draw_circle_points(sensor.global_transform * cs.transform, 10.0, FALLBACK_COLOR)
	return 1


func _draw_circle_points(xf: Transform2D, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in SEGMENTS:
		var t := TAU * float(i) / float(SEGMENTS)
		pts.append(to_local(xf * Vector2(cos(t), sin(t)) * radius))
	draw_polyline(pts, color, LINE_WIDTH, true)
	draw_line(pts[pts.size()-1], pts[0], color, LINE_WIDTH, true)
