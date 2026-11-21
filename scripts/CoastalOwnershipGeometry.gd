extends RefCounted
## Coastal-only correction for province ownership colors and ball landing.
## Canonical province quads remain untouched for shared/interior border drawing.
## The correction tiles the same shared grid, extends nearby sea cells to the
## displayed coastline, and cuts out the actual outer-wall rectangles.
##
## The wall itself is not moved, redrawn, or given different collision geometry.

const OUTER_BARRIER_THICKNESS: float = 96.0
const EXTRA_SEA_CELL_DEPTH: int = 3
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
	var hole_cutters: Array[Dictionary] = []
	for hole_any in holes:
		var hole: Dictionary = hole_any
		var hole_poly: PackedVector2Array = hole["poly"]
		var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(hole_poly)
		for i in range(0, triangles.size(), 3):
			var cut := PackedVector2Array([
				hole_poly[triangles[i]], hole_poly[triangles[i + 1]], hole_poly[triangles[i + 2]]
			])
			hole_cutters.append({"poly": cut, "bounds": _bounds(cut)})
	return {"outers": outers, "holes": holes, "hole_cutters": hole_cutters, "barriers": barriers}


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


# Cut a convex fragment with one directed half-plane. Unlike a general
# polygon-boolean result, both output pieces stay convex and hole-free.
static func _clip_halfplane(poly: PackedVector2Array, a: Vector2, b: Vector2,
		winding: float, keep_inside: bool) -> PackedVector2Array:
	var clipped := PackedVector2Array()
	if poly.size() < 3:
		return clipped
	var edge: Vector2 = b - a
	for i in range(poly.size()):
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % poly.size()]
		var dp: float = winding * edge.cross(p - a)
		var dq: float = winding * edge.cross(q - a)
		var p_kept: bool = dp >= -0.00001 if keep_inside else dp <= 0.00001
		var q_kept: bool = dq >= -0.00001 if keep_inside else dq <= 0.00001
		if p_kept:
			clipped.append(p)
		if p_kept != q_kept:
			var denominator: float = dp - dq
			if absf(denominator) > 0.0000001:
				var t: float = clampf(dp / denominator, 0.0, 1.0)
				clipped.append(p.lerp(q, t))
	return clipped


static func _subtract_convex_cutter(poly: PackedVector2Array,
		cutter: PackedVector2Array) -> Array[PackedVector2Array]:
	var outside: Array[PackedVector2Array] = []
	if poly.size() < 3 or cutter.size() < 3:
		if poly.size() >= 3:
			outside.append(poly)
		return outside
	var inside: Array[PackedVector2Array] = [poly]
	var winding: float = 1.0 if _signed_area(cutter) >= 0.0 else -1.0
	for i in range(cutter.size()):
		var a: Vector2 = cutter[i]
		var b: Vector2 = cutter[(i + 1) % cutter.size()]
		var next_inside: Array[PackedVector2Array] = []
		for fragment in inside:
			var rejected: PackedVector2Array = _clip_halfplane(fragment, a, b, winding, false)
			if rejected.size() >= 3 and absf(_signed_area(rejected)) >= AREA_EPSILON:
				outside.append(rejected)
			var accepted: PackedVector2Array = _clip_halfplane(fragment, a, b, winding, true)
			if accepted.size() >= 3 and absf(_signed_area(accepted)) >= AREA_EPSILON:
				next_inside.append(accepted)
		inside = next_inside
		if inside.is_empty():
			break
	return outside


static func _triangulate_into_convex(poly: PackedVector2Array) -> Array[PackedVector2Array]:
	var fragments: Array[PackedVector2Array] = []
	if poly.size() < 3:
		return fragments
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	for i in range(0, indices.size(), 3):
		var triangle := PackedVector2Array([
			poly[indices[i]], poly[indices[i + 1]], poly[indices[i + 2]]
		])
		if absf(_signed_area(triangle)) >= AREA_EPSILON:
			fragments.append(triangle)
	return fragments


static func _clip_against_blockers(parts: Array[PackedVector2Array], blockers: Array,
		tile_bounds: Rect2) -> Array[PackedVector2Array]:
	var surviving: Array[PackedVector2Array] = parts
	for blocker_any in blockers:
		var blocker: Dictionary = blocker_any
		if not tile_bounds.intersects(blocker["bounds"], true):
			continue
		var next_parts: Array[PackedVector2Array] = []
		var cutter: PackedVector2Array = blocker["poly"]
		for part in surviving:
			if not _bounds(part).intersects(blocker["bounds"], true):
				next_parts.append(part)
				continue
			# Every input is convex. Convex half-plane subtraction cannot
			# introduce polygon holes, reversed rings, or stray fill triangles.
			next_parts.append_array(_subtract_convex_cutter(part, cutter))
		surviving = next_parts
		if surviving.is_empty():
			break
	return surviving


static func _append_clipped_tile(mesh: Dictionary, quad: PackedVector2Array,
		outers: Array, hole_cutters: Array, barriers: Array) -> void:
	var tile_bounds: Rect2 = _bounds(quad)
	# The original quad is split into convex triangles so concave coastlines
	# and overlapping physical wall rectangles can be subtracted reliably.
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
				# General boolean intersections can be concave: turn them
				# into convex pieces before applying the wall subtraction.
				within_coast.append_array(_triangulate_into_convex(result_poly))
		if within_coast.is_empty():
			continue
		var without_holes: Array[PackedVector2Array] = _clip_against_blockers(
			within_coast, hole_cutters, tile_bounds)
		var visible: Array[PackedVector2Array] = _clip_against_blockers(
			without_holes, barriers, tile_bounds)
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
	var hole_cutters: Array = coast["hole_cutters"]
	if outers.is_empty() or barriers.is_empty():
		return meshes
	for id_any in old_to_new.values():
		var empty_polygons: Array[PackedInt32Array] = []
		meshes[int(id_any)] = {"points": PackedVector2Array(), "polygons": empty_polygons}
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
			# Unassigned sea cells are NEVER accepted solely because their
			# center lies inside the coast: that created stray colored wedges.
			# Land cells touching the sea are clipped as well, even if no
			# rectangle happens to overlap their bounding box.
			var coastal_cell: bool = original_region < 0
			if original_region >= 0:
				for delta in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var nc: int = c + delta.x
					var nr: int = r + delta.y
					if nr < 0 or nr >= rows or nc < 0 or nc >= cols or int(assignments[nr][nc]) < 0:
						coastal_cell = true
						break
			if not near_wall and not coastal_cell:
				# Do not touch the interior quad; it defines all interior borders.
				var points: PackedVector2Array = mesh["points"]
				var polygon_indices: Array[PackedInt32Array] = mesh["polygons"]
				var base: int = points.size()
				points.append_array(quad)
				polygon_indices.append(PackedInt32Array([base, base + 1, base + 2, base + 3]))
				mesh["points"] = points
				mesh["polygons"] = polygon_indices
				continue
			_append_clipped_tile(mesh, quad, outers, hole_cutters, barriers)
	return meshes
