extends Node2D

const POLYGON_COLOR: Color = Color(0.1, 1.0, 0.2, 1.0)
const SHAPE_COLOR: Color = Color(0.1, 0.9, 1.0, 1.0)
const FALLBACK_COLOR: Color = Color(1.0, 0.1, 0.9, 1.0)
const LINE_WIDTH: float = 6.0
const SEGMENTS: int = 28
const OVERLAY_LAYER_PATH: NodePath = ^"BossDebugOverlay"
const OVERLAY_LAYER_NAME: String = "BossDebugOverlay"

var _sensor: Node2D = null
var _overlay_attached: bool = false
var _cached_polylines: Array[PackedVector2Array] = []
var _cached_colors: Array[Color] = []


func set_target_sensor(sensor: Node2D) -> void:
	_sensor = sensor


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	if _sensor != null and is_instance_valid(_sensor) and not _sensor.tree_exited.is_connected(_on_sensor_tree_exited):
		_sensor.tree_exited.connect(_on_sensor_tree_exited)
	_move_to_overlay()
	_cache_overlay_geometry()
	queue_redraw()
	print("[BossDebug][HitSensorDebugDraw] ready sensor_valid=", _sensor != null and is_instance_valid(_sensor), " parent=", get_parent().name if get_parent() != null else "<none>", " moved_to_overlay=", str(_overlay_attached), " cached_paths=", _cached_polylines.size())


func _on_sensor_tree_exited() -> void:
	queue_free()


func _exit_tree() -> void:
	if _sensor != null and is_instance_valid(_sensor) and _sensor.tree_exited.is_connected(_on_sensor_tree_exited):
		_sensor.tree_exited.disconnect(_on_sensor_tree_exited)


func _move_to_overlay() -> void:
	if _overlay_attached:
		return
	if not is_inside_tree():
		return
	var root: Window = get_tree().root
	if root == null:
		return
	var overlay: Node2D = root.get_node_or_null(OVERLAY_LAYER_PATH) as Node2D
	if overlay == null:
		overlay = Node2D.new()
		overlay.name = OVERLAY_LAYER_NAME
		overlay.z_as_relative = false
		overlay.z_index = 1000000
		root.add_child(overlay)
	var parent: Node = get_parent()
	if parent != overlay:
		if parent != null:
			parent.remove_child(self)
		overlay.add_child(self)
	top_level = true
	z_as_relative = false
	z_index = 1000001
	show_behind_parent = false
	_overlay_attached = true


func _cache_overlay_geometry() -> void:
	_cached_polylines.clear()
	_cached_colors.clear()
	if _sensor == null or not is_instance_valid(_sensor):
		return
	_add_cross(_sensor.global_position, FALLBACK_COLOR)
	for child_any in _sensor.get_children():
		var child: Node = child_any
		if child is CollisionPolygon2D:
			_cache_polygon(_sensor, child as CollisionPolygon2D)
		elif child is CollisionShape2D:
			_cache_shape(_sensor, child as CollisionShape2D)


func _draw() -> void:
	for i in _cached_polylines.size():
		var points: PackedVector2Array = _cached_polylines[i]
		if points.size() >= 2:
			draw_polyline(points, _cached_colors[i], LINE_WIDTH, true)


func _add_cross(world_pos: Vector2, color: Color) -> void:
	_add_polyline(PackedVector2Array([
		to_local(world_pos + Vector2(-14, 0)),
		to_local(world_pos + Vector2(14, 0)),
	]), color)
	_add_polyline(PackedVector2Array([
		to_local(world_pos + Vector2(0, -14)),
		to_local(world_pos + Vector2(0, 14)),
	]), color)


func _cache_polygon(sensor: Node2D, poly: CollisionPolygon2D) -> void:
	if poly.disabled or poly.polygon.size() < 3:
		return
	var points := PackedVector2Array()
	for p in poly.polygon:
		points.append(to_local((sensor.global_transform * poly.transform) * p))
	points.append(points[0])
	_add_polyline(points, POLYGON_COLOR)


func _cache_shape(sensor: Node2D, cs: CollisionShape2D) -> void:
	if cs.disabled:
		return
	var shape: Shape2D = cs.shape
	if shape is CircleShape2D:
		var c := shape as CircleShape2D
		_add_circle(sensor.global_transform * cs.transform, c.radius, SHAPE_COLOR)
		return
	if shape is RectangleShape2D:
		var r := shape as RectangleShape2D
		var h := r.size * 0.5
		var points := PackedVector2Array([
			to_local((sensor.global_transform * cs.transform) * Vector2(-h.x, -h.y)),
			to_local((sensor.global_transform * cs.transform) * Vector2(h.x, -h.y)),
			to_local((sensor.global_transform * cs.transform) * Vector2(h.x, h.y)),
			to_local((sensor.global_transform * cs.transform) * Vector2(-h.x, h.y)),
			to_local((sensor.global_transform * cs.transform) * Vector2(-h.x, -h.y)),
		])
		_add_polyline(points, SHAPE_COLOR)
		return
	_add_circle(sensor.global_transform * cs.transform, 10.0, FALLBACK_COLOR)


func _add_circle(xf: Transform2D, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in SEGMENTS + 1:
		var t := TAU * float(i) / float(SEGMENTS)
		points.append(to_local(xf * (Vector2(cos(t), sin(t)) * radius)))
	_add_polyline(points, color)


func _add_polyline(points: PackedVector2Array, color: Color) -> void:
	_cached_polylines.append(points)
	_cached_colors.append(color)
