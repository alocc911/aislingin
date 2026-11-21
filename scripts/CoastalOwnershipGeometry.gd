extends RefCounted
## Coastal-only correction for province ownership colors and ball landing.
## Canonical province quads remain untouched for shared/interior border drawing.
## The correction tiles the same shared grid, extends nearby sea cells to the
## displayed coastline, and cuts out the actual outer-wall rectangles.
##
## The wall itself is not moved, redrawn, or given different collision geometry.

const OUTER_BARRIER_THICKNESS: float = 96.0
const EXTRA_SEA_CELL_DEPTH: int = 6
const AREA_EPSILON: float = 0.01


static func _cell_key(c: int, r: int) -> String:
	return "%d,%d" % [c, r]


static func _grid_vertex(c: int, r: int, cols: int, rows: int, half: Vector2, shared: Dictionary) -> Vector2:
	var key: String = _cell_key(c, r)
	if shared.has(key):
		return shared[key]
	return Vector2(-half.x + 2.0 * half.x * float(c) / float(cols),
		-half.y + 2.0 * half.y * float(r) / float(rows))


static func _cell_quad(c: int, r: int, cols: int, rows: int, half: Vector2, shared: Dictionary) -> PackedVector2Array:
	return PackedVector2Array([
		_grid_vertex(c, r, cols, rows, half, shared),
		_grid_vertex(c + 1, r, cols, rows, half, shared),
		_grid_vertex(c + 1, r + 1, cols, rows, half, shared),
		_grid_vertex(c, r + 1, cols, rows, half, shared)
	])


static func _bounds(poly: PackedVector2Array) -> Rect2:
	var rect := Rect2(poly[0], Vector2.ZERO)
	for i in range(1, poly.size()):
		rect = rect.expand(poly[i])
	return rect


static func _signed_area(poly: PackedVector2Array) -> float:
	var sum_area: float = 0.0
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		sum_area += a.x * b.y - a.y * b.x
	return sum_area * 0.5


static func _wall_rectangle(a: Vector2, b: Vector2, thickness: float) -> PackedVector2Array:
	var direction: Vector2 = (b - a).normalized()
	var outward := Vector2(direction.y, -direction.x)
	var center: Vector2 = (a + b) * 0.5 + outward * (thickness * 0.5)
	var along: Vector2 = direction * ((a.distance_to(b) + thickness * 1.5) * 0.5)
	var across: Vector2 = outward * (thickness * 0.5)
	return PackedVector2Array([
		center - along - across,
		center + along - across,
		center + along + across,
		center - along + across
	])


static func _coast_shapes(smoothed_loops: Array) -> Dictionary:
	var outers: Array[Dictionary] = []
	var holes: Array[Dictionary] = []
	var barriers: Array[Dictionary] = []
	for loop_any in smoothed_loops:
		var loop: PackedVector2Array = loop_any
		if loop.size() < 3:
			continue
		var entry: Dictionary = {"poly": loop, "bounds": _bounds(loop)}
		if _signed_area(loop) >= 0.0:
			outers.append(entry)
		else:
			holes.append(entry)
		for i in range(loop.size()):
			var a: Vector2 = loop[i]
			var b: Vector2 = loop[(i + 1) % loop.size()]
			if a.distance_squared_to(b) < 0.000001:
				continue
			var footprint: PackedVector2Array = _wall_rectangle(a, b, OUTER_BARRIER_THICKNESS)
			barriers.append({"poly": footprint, "bounds": _bounds(footprint)})
	return {"outers": outers, "holes": holes, "barriers": barriers}


static func _point_inside_coast(point: Vector2, outers: Array, holes: Array) -> bool:
	var inside: bool = false
	for entry_any in outers:
		var entry: Dictionary = entry_any
		var entry_bounds: Rect2 = entry["bounds"]
		if entry_bounds.has_point(point) and Geometry2D.is_point_in_polygon(point, entry["poly"]):
			inside = true
			break
	if not inside:
		return false
	for entry_any in holes:
		var entry: Dictionary = entry_any
		var entry_bounds: Rect2 = entry["bounds"]
		if entry_bounds.has_point(point) and Geometry2D.is_point_in_polygon(point, entry["poly"]):
			return false
	return true


static func _nearest_coastal_owners(assignments: Array, cols: int, rows: int) -> Dictionary:
	# A fixed-distance multi-source flood supplies ownership for the thin strips
	# revealed when the rendered wall bends outside the original grid shoreline.
	var owner: Array = []
	var distance: Array = []
	var queue: Array[Vector2i] = []
	for r in range(rows):
		var owner_row := PackedInt32Array()
		var distance_row := PackedInt32Array()
		owner_row.resize(cols)
		distance_row.resize(cols)
		owner_row.fill(-1)
		distance_row.fill(-1)
		for c in range(cols):
			var region_id: int = int(assignments[r][c])
			if region_id >= 0:
				owner_row[c] = region_id
				distance_row[c] = 0
				queue.append(Vector2i(c, r))
		owner.append(owner_row)
		distance.append(distance_row)
	var cursor: int = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		var current_distances: PackedInt32Array = distance[cell.y]
		var steps: int = current_distances[cell.x]
		if steps >= EXTRA_SEA_CELL_DEPTH:
			continue
		for delta in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var next_cell: Vector2i = cell + delta
			if next_cell.x < 0 or next_cell.x >= cols or next_cell.y < 0 or next_cell.y >= rows:
				continue
			var next_row: PackedInt32Array = distance[next_cell.y]
			if next_row[next_cell.x] >= 0:
				continue
			next_row[next_cell.x] = steps + 1
			distance[next_cell.y] = next_row
			var next_owner: PackedInt32Array = owner[next_cell.y]
			var current_owners: PackedInt32Array = owner[cell.y]
			next_owner[next_cell.x] = current_owners[cell.x]
			owner[next_cell.y] = next_owner
			queue.append(next_cell)
	return {"owner": owner, "distance": distance}


static func _append_polygon(mesh: Dictionary, poly: PackedVector2Array) -> void:
	if poly.size() < 3 or absf(_signed_area(poly)) < AREA_EPSILON:
		return
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	if triangles.size() < 3:
		return
	var points: PackedVector2Array = mesh["points"]
	var polygons: Array[PackedInt32Array] = mesh["polygons"]
	var base: int = points.size()
	points.append_array(poly)
	for i in range(0, triangles.size(), 3):
		polygons.append(PackedInt32Array([base + triangles[i], base + triangles[i + 1], base + triangles[i + 2]]))
	mesh["points"] = points
	mesh["polygons"] = polygons


static func _clip_against_blockers(parts: Array[PackedVector2Array], blockers: Array, tile_bounds: Rect2) -> Array[PackedVector2Array]:
	var surviving: Array[PackedVector2Array] = parts
	for blocker_any in blockers:
		var blocker: Dictionary = blocker_any
		if not tile_bounds.intersects(blocker["bounds"], true):
			continue
		var next_parts: Array[PackedVector2Array] = []
		for part in surviving:
			if not _bounds(part).intersects(blocker["bounds"], true):
				next_parts.append(part)
				continue
			for result_any in Geometry2D.clip_polygons(part, blocker["poly"]):
				var result_poly: PackedVector2Array = result_any
				if result_poly.size() >= 3 and absf(_signed_area(result_poly)) >= AREA_EPSILON:
					next_parts.append(result_poly)
		surviving = next_parts
		if surviving.is_empty():
			break
	return surviving


static func _append_clipped_tile(mesh: Dictionary, quad: PackedVector2Array, outers: Array, holes: Array, barriers: Array) -> void:
	var tile_bounds: Rect2 = _bounds(quad)
	# A coastal cell is split into triangles before boolean subtraction, avoiding
	# a wall-rectangle fully enclosed in a large cell and creating a polygon hole.
	var center: Vector2 = (quad[0] + quad[1] + quad[2] + quad[3]) * 0.25
	for i in range(4):
		var triangle := PackedVector2Array([center, quad[i], quad[(i + 1) % 4]])
		var within_coast: Array[PackedVector2Array] = []
		for outer_any in outers:
			var outer: Dictionary = outer_any
			if not tile_bounds.intersects(outer["bounds"], true):
				continue
			for result_any in Geometry2D.intersect_polygons(triangle, outer["poly"]):
				var result_poly: PackedVector2Array = result_any
				if result_poly.size() >= 3:
					within_coast.append(result_poly)
		if within_coast.is_empty():
			continue
		var without_holes: Array[PackedVector2Array] = _clip_against_blockers(within_coast, holes, tile_bounds)
		var visible: Array[PackedVector2Array] = _clip_against_blockers(without_holes, barriers, tile_bounds)
		for poly in visible:
			_append_polygon(mesh, poly)


static func build(assignments: Array, shared_vertices: Dictionary, old_to_new: Dictionary,
		smoothed_loops: Array, playable_half: Vector2) -> Dictionary:
	var meshes: Dictionary = {}
	var rows: int = assignments.size()
	var cols: int = int((assignments[0] as Array).size()) if rows > 0 else 0
	if cols == 0 or smoothed_loops.is_empty():
		return meshes
	var coast: Dictionary = _coast_shapes(smoothed_loops)
	var outers: Array = coast["outers"]
	var holes: Array = coast["holes"]
	var barriers: Array = coast["barriers"]
	if outers.is_empty() or barriers.is_empty():
		return meshes
	for id_any in old_to_new.values():
		meshes[int(id_any)] = {"points": PackedVector2Array(), "polygons": Array[PackedInt32Array]()}
	var flood: Dictionary = _nearest_coastal_owners(assignments, cols, rows)
	var sea_owner: Array = flood["owner"]
	var sea_distance: Array = flood["distance"]
	for r in range(rows):
		for c in range(cols):
			var original_region: int = int(assignments[r][c])
			var region_id: int = original_region
			if region_id < 0:
				var sea_steps: PackedInt32Array = sea_distance[r]
				if sea_steps[c] < 0:
					continue
				var sea_owners_row: PackedInt32Array = sea_owner[r]
				region_id = sea_owners_row[c]
			if not old_to_new.has(region_id):
				continue
			var province_id: int = int(old_to_new[region_id])
			var mesh: Dictionary = meshes[province_id]
			var quad: PackedVector2Array = _cell_quad(c, r, cols, rows, playable_half, shared_vertices)
			var tile_bounds: Rect2 = _bounds(quad)
			var near_wall: bool = false
			for barrier_any in barriers:
				var barrier_entry: Dictionary = barrier_any
				if tile_bounds.intersects(barrier_entry["bounds"], true):
					near_wall = true
					break
			# Away from the shoreline, this is the exact original canonical
			# quad. No interior border, vertex, or province affiliation moves.
			if not near_wall:
				var center: Vector2 = (quad[0] + quad[1] + quad[2] + quad[3]) * 0.25
				if _point_inside_coast(center, outers, holes):
					var points: PackedVector2Array = mesh["points"]
					var polygon_indices: Array[PackedInt32Array] = mesh["polygons"]
					var base: int = points.size()
					points.append_array(quad)
					polygon_indices.append(PackedInt32Array([base, base + 1, base + 2, base + 3]))
					mesh["points"] = points
					mesh["polygons"] = polygon_indices
				continue
			_append_clipped_tile(mesh, quad, outers, holes, barriers)
	return meshes
