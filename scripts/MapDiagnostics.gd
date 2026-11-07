extends RefCounted
## Passive serialization for diagnosing generated grand-map geography. The serializers
## never use the generator RNG or modify the map, province data, or physics bodies.

static func point(p: Vector2) -> Array:
	return [p.x, p.y]


static func polygon(poly: PackedVector2Array) -> Array:
	var coords: Array = []
	for p in poly:
		coords.append(point(p))
	return coords


static func polygons(items: Array) -> Array:
	var result: Array = []
	for poly_any in items:
		if poly_any is PackedVector2Array:
			result.append(polygon(poly_any))
	return result


static func mask_rows(mask: Array) -> Array[String]:
	var result: Array[String] = []
	for row_any in mask:
		var row_text: String = ""
		for cell in row_any:
			row_text += "1" if bool(cell) else "0"
		result.append(row_text)
	return result


static func assignment_rows(assignments: Array) -> Array:
	var result: Array = []
	for row_any in assignments:
		if row_any is Array:
			result.append((row_any as Array).duplicate())
	return result


static func grid_cells(cells: Array) -> Array:
	var result: Array = []
	for cell_any in cells:
		if cell_any is Vector2i:
			var cell: Vector2i = cell_any
			result.append([cell.x, cell.y])
	return result


static func polygon_bounds(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var low: Vector2 = poly[0]
	var high: Vector2 = poly[0]
	for p in poly:
		low.x = minf(low.x, p.x)
		low.y = minf(low.y, p.y)
		high.x = maxf(high.x, p.x)
		high.y = maxf(high.y, p.y)
	return Rect2(low, high - low)


static func province_data(provinces: Array) -> Array:
	var result: Array = []
	for province_any in provinces:
		if not (province_any is Dictionary):
			continue
		var province: Dictionary = province_any
		var poly: PackedVector2Array = province.get("polygon", PackedVector2Array())
		result.append({
			"id": int(province.get("id", -1)),
			"polygon": polygon(poly),
			"neighbors": Array(province.get("neighbors", [])).duplicate(),
			"type": String(province.get("type", "")),
			"faction_id": int(province.get("faction_id", 0)),
			"is_target": bool(province.get("is_target", false)),
			"province_name": String(province.get("province_name", "")),
			"area": absf(_polygon_area(poly))
		})
	return result


static func _polygon_area(poly: PackedVector2Array) -> float:
	var twice_area: float = 0.0
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		twice_area += a.cross(b)
	return twice_area * 0.5


static func terrain_placements(placements: Array) -> Array:
	var result: Array = []
	for plc_any in placements:
		if not (plc_any is Dictionary):
			continue
		var plc: Dictionary = plc_any
		var tpl: ZoneTemplate = plc.get("template", null)
		if tpl == null:
			continue
		var components: Array = []
		for comp_any in tpl.components:
			if not (comp_any is Dictionary):
				continue
			var comp: Dictionary = comp_any
			var local: Vector2 = comp.get("local_pos", Vector2.ZERO)
			var entry: Dictionary = {
				"type": int(comp.get("type", -1)),
				"local_pos": point(local),
				"radius": float(comp.get("radius", 0.0)),
				"aspect": float(comp.get("aspect", 1.0))
			}
			components.append(entry)
		result.append({
			"name": tpl.template_name,
			"origin": point(plc.get("origin", Vector2.ZERO)),
			"rotation": float(plc.get("rotation", 0.0)),
			"scale": float(plc.get("scale", 1.0)),
			"components": components
		})
	return result


static func capture_outer_wall_bodies(obstacles_root: Node) -> Array:
	var bodies: Array = []
	if obstacles_root == null:
		return bodies
	var root: Node = obstacles_root.get_node_or_null("GrandMapOuterBarrier")
	if root != null:
		_walk_outer_walls(root, bodies)
	return bodies


static func _walk_outer_walls(node: Node, bodies: Array) -> void:
	if node is StaticBody2D:
		var body: StaticBody2D = node as StaticBody2D
		var collision: CollisionShape2D = null
		for child in body.get_children():
			if child is CollisionShape2D:
				collision = child as CollisionShape2D
				break
		if collision != null and collision.shape is RectangleShape2D:
			var size: Vector2 = (collision.shape as RectangleShape2D).size
			var axis: Vector2 = Vector2.RIGHT.rotated(body.global_rotation)
			var half_span: Vector2 = axis * size.x * 0.5
			bodies.append({
				"name": String(body.name),
				"path": String(body.get_path()),
				"center": point(body.global_position),
				"angle": body.global_rotation,
				"size": point(size),
				"axis_start": point(body.global_position - half_span),
				"axis_end": point(body.global_position + half_span),
				"collision_layer": body.collision_layer,
				"collision_mask": body.collision_mask,
				"mainland": String(body.get_parent().name) == "MainlandOuterBarrier"
			})
	for child in node.get_children():
		_walk_outer_walls(child, bodies)


static func capture_terrain_colliders(obstacles_root: Node) -> Array:
	var colliders: Array = []
	if obstacles_root == null:
		return colliders
	for child in obstacles_root.get_children():
		if String(child.name) != "GrandMapOuterBarrier":
			_walk_colliders(child, colliders)
	return colliders


static func _walk_colliders(node: Node, colliders: Array) -> void:
	if node is CollisionShape2D:
		var collision: CollisionShape2D = node as CollisionShape2D
		if collision.shape != null:
			var shape: Shape2D = collision.shape
			var record: Dictionary = {
				"path": String(collision.get_path()),
				"center": point(collision.global_position),
				"rotation": collision.global_rotation,
				"type": shape.get_class(),
				"disabled": collision.disabled
			}
			if shape is RectangleShape2D:
				record["size"] = point((shape as RectangleShape2D).size)
			elif shape is CircleShape2D:
				record["radius"] = (shape as CircleShape2D).radius
			elif shape is CapsuleShape2D:
				record["radius"] = (shape as CapsuleShape2D).radius
				record["height"] = (shape as CapsuleShape2D).height
			elif shape is ConvexPolygonShape2D:
				record["polygon"] = polygon((shape as ConvexPolygonShape2D).points)
			elif shape is ConcavePolygonShape2D:
				record["segments"] = polygon((shape as ConcavePolygonShape2D).segments)
			colliders.append(record)
	for child in node.get_children():
		_walk_colliders(child, colliders)


static func capture_live_provinces(provinces_root: Node) -> Array:
	var result: Array = []
	if provinces_root == null:
		return result
	for node in provinces_root.get_children():
		if not node.has_meta("province_data"):
			continue
		var entry: Dictionary = node.get_meta("province_data")
		var poly: PackedVector2Array = node.get_meta("province_polygon", PackedVector2Array())
		result.append({
			"id": int(entry.get("id", -1)),
			"polygon": polygon(poly),
			"neighbors": Array(entry.get("neighbors", [])).duplicate()
		})
	return result
