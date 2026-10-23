extends RefCounted
## Shared, short-lived discovery cache for water Area2D nodes.
## Runner and Chief still perform their original point/ellipse/path checks; only
## the redundant recursive scene-tree walk is shared across enemies.
const RESCAN_MSEC: int = 500
static var _scene_id: int = 0
static var _cached_at_msec: int = -1
static var _areas: Array[Area2D] = []


static func get_water_areas(tree: SceneTree) -> Array[Area2D]:
	if tree == null:
		return []
	var root: Node = tree.current_scene
	if root == null:
		root = tree.root
	if root == null:
		return []
	var now_msec: int = Time.get_ticks_msec()
	var scene_id: int = root.get_instance_id()
	var needs_scan: bool = _cached_at_msec < 0 or _scene_id != scene_id or now_msec - _cached_at_msec >= RESCAN_MSEC
	if not needs_scan:
		for area in _areas:
			if not is_instance_valid(area) or area.is_queued_for_deletion():
				needs_scan = true
				break
	if needs_scan:
		var fresh: Array[Area2D] = []
		_collect_water_areas(root, fresh)
		_areas = fresh
		_scene_id = scene_id
		_cached_at_msec = now_msec
	return _areas


static func invalidate() -> void:
	_scene_id = 0
	_cached_at_msec = -1
	_areas = []


static func _collect_water_areas(node: Node, results: Array[Area2D]) -> void:
	if node is Area2D and node.has_meta("zone_type") and str(node.get_meta("zone_type")) == "water":
		results.append(node as Area2D)
	for child in node.get_children():
		_collect_water_areas(child, results)
