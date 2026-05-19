extends Node2D

const POLYGON_COLOR: Color = Color(0.1, 1.0, 0.2, 1.0)
const SHAPE_COLOR: Color = Color(0.1, 0.9, 1.0, 1.0)
const FALLBACK_COLOR: Color = Color(1.0, 0.1, 0.9, 1.0)
const LINE_WIDTH: float = 6.0
const SEGMENTS: int = 28
const OVERLAY_LAYER_PATH: NodePath = ^"BossDebugOverlay"
const OVERLAY_LAYER_NAME: String = "BossDebugOverlay"

var _sensor: Node2D = null
var _overlay_node: Node2D = null
var _overlay_attached: bool = false


func set_target_sensor(sensor: Node2D) -> void:
	_sensor = sensor


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	if not tree_entered.is_connected(_on_tree_entered):
		tree_entered.connect(_on_tree_entered)
	_move_to_overlay()
	print("[BossDebug][HitSensorDebugDraw] ready sensor_valid=", _sensor != null and is_instance_valid(_sensor), " parent=", get_parent().name if get_parent() != null else "<none>", " moved_to_overlay=", str(_overlay_attached))


func _on_tree_entered() -> void:
	if not _overlay_attached:
		_move_to_overlay()


func _move_to_overlay() -> void:
	if _overlay_attached:
		return
	if not is_inside_tree():
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var root: Window = tree.root
	if root == null:
		return

	_overlay_node = root.get_node_or_null(OVERLAY_LAYER_PATH) as Node2D
	if _overlay_node == null:
		_overlay_node = Node2D.new()
		_overlay_node.name = OVERLAY_LAYER_NAME
		_overlay_node.z_as_relative = false
		_overlay_node.z_index = 1000000
		root.add_child(_overlay_node)

	var parent: Node = get_parent()
	if parent != _overlay_node:
		if parent != null:
			parent.remove_child(self)
		_overlay_node.add_child(self)

	top_level = true
	z_as_relative = false
	z_index = 1000000
	_overlay_attached = true


func _process(_delta: float) -> void:
	if _sensor == null or not is_instance_valid(_sensor):
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
