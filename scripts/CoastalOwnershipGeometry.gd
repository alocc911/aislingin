extends RefCounted
## Coastal-only correction for province ownership colors and ball landing.
## Canonical province quads remain untouched for shared/interior border drawing.
## Tile the full shared grid, clip to the actual playable coast, and partition
## newly exposed land without modifying the canonical region assignments.
##
## The wall itself is not moved, redrawn, or given different collision geometry.

const OUTER_BARRIER_THICKNESS: float = 96.0
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


static func _append_polygon(mesh: Dictionary, poly: PackedVector2Array) -> void:
	# All fragments reaching this point are convex. Fan triangulation
	# cannot drop a valid sliver because of a numerical earcut failure.
	if poly.size() < 3 or absf(_signed_area(poly)) < AREA_EPSILON:
		return
	var points: PackedVector2Array = mesh["points"]
	var polygons: Array[PackedInt32Array] = mesh["polygons"]
	var base: int = points.size()
	points.append_array(poly)
	for i in range(1, poly.size() - 1):
		var triangle := PackedVector2Array([poly[0], poly[i], poly[i + 1]])
		if absf(_signed_area(triangle)) < AREA_EPSILON:
			continue
		polygons.append(PackedInt32Array([base, base + i, base + i + 1]))
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
	# Exact boundary intersections can duplicate an endpoint. Remove
	# those zero-length sides before saving/displaying the fragments.
	var cleaned := PackedVector2Array()
	for vertex in clipped:
		if cleaned.is_empty() or cleaned[cleaned.size() - 1].distance_squared_to(vertex) > 0.00000001:
			cleaned.append(vertex)
	if cleaned.size() > 1 and cleaned[0].distance_squared_to(cleaned[cleaned.size() - 1]) <= 0.00000001:
		cleaned.remove_at(cleaned.size() - 1)
	return cleaned


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


# A tile with no boundary crossing is wholly inside or wholly outside.
static func _boundary_segments(loops: Array) -> Array[Rect2]:
	var segments: Array[Rect2] = []
	for loop_any in loops:
		var loop: PackedVector2Array = loop_any
		for i in range(loop.size()):
			segments.append(Rect2(loop[i], Vector2.ZERO).expand(loop[(i + 1) % loop.size()]).grow(0.01))
	return segments


static func _tile_parts(quad: PackedVector2Array, coast: Dictionary, segments: Array[Rect2]) -> Array[PackedVector2Array]:
	var tile_bounds: Rect2 = _bounds(quad)
	var parts: Array[PackedVector2Array] = []
	var boundary: bool = false
	for segment in segments:
		if tile_bounds.intersects(segment, true):
			boundary = true
			break
	if not boundary:
		for wall_any in coast["barriers"]:
			var wall: Dictionary = wall_any
			if tile_bounds.intersects(wall["bounds"], true):
				boundary = true
				break
	if not boundary:
		if _point_inside_coast(quad[0], coast["outers"], coast["holes"]):
			parts.append(quad)
		return parts
	# Triangulate the cell itself, including any concave cells.
	for triangle in _triangulate_into_convex(quad):
		var within_coast: Array[PackedVector2Array] = []
		for outer_any in coast["outers"]:
			var outer: Dictionary = outer_any
			if not tile_bounds.intersects(outer["bounds"], true):
				continue
			for result_any in Geometry2D.intersect_polygons(triangle, outer["poly"]):
				within_coast.append_array(_triangulate_into_convex(result_any))
		var without_holes: Array[PackedVector2Array] = _clip_against_blockers(
			within_coast, coast["hole_cutters"], tile_bounds)
		parts.append_array(_clip_against_blockers(without_holes, coast["barriers"], tile_bounds))
	return parts


static func _append_quad(mesh: Dictionary, quad: PackedVector2Array) -> void:
	var points: PackedVector2Array = mesh["points"]
	var polygons: Array[PackedInt32Array] = mesh["polygons"]
	var base: int = points.size()
	points.append_array(quad)
	polygons.append(PackedInt32Array([base, base + 1, base + 2, base + 3]))
	mesh["points"] = points
	mesh["polygons"] = polygons


# Partition only previously unassigned playable land. The distance bound
# retains every site that could be nearest anywhere inside this tile.
static func _gap_sites(quad: PackedVector2Array, sites: Array[Dictionary]) -> Array[Dictionary]:
	var center: Vector2 = (quad[0] + quad[1] + quad[2] + quad[3]) * 0.25
	var radius: float = 0.0
	for vertex in quad:
		radius = maxf(radius, vertex.distance_to(center))
	var nearest: float = INF
	for site in sites:
		nearest = minf(nearest, center.distance_to(site["point"]))
	var limit_squared: float = pow(nearest + 2.0 * radius + 0.05, 2.0)
	var candidates: Array[Dictionary] = []
	for site in sites:
		if center.distance_squared_to(site["point"]) <= limit_squared:
			candidates.append(site)
	return candidates


static func _clip_nearer(poly: PackedVector2Array, a: Vector2, b: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	var midpoint: Vector2 = (a + b) * 0.5
	var normal: Vector2 = b - a
	for i in range(poly.size()):
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % poly.size()]
		var dp: float = normal.dot(p - midpoint)
		var dq: float = normal.dot(q - midpoint)
		if dp <= 0.0:
			result.append(p)
		if (dp < 0.0 and dq > 0.0) or (dp > 0.0 and dq < 0.0):
			result.append(p.lerp(q, dp / (dp - dq)))
	return result


static func _assign_gap(parts: Array[PackedVector2Array], candidates: Array[Dictionary], meshes: Dictionary) -> void:
	if candidates.is_empty():
		return
	var owner: int = int(candidates[0]["owner"])
	var one_owner: bool = true
	for site in candidates:
		if int(site["owner"]) != owner:
			one_owner = false
			break
	if one_owner:
		for part in parts:
			for triangle in _triangulate_into_convex(part):
				_append_polygon(meshes[owner], triangle)
		return
	for part in parts:
		for triangle in _triangulate_into_convex(part):
			for i in range(candidates.size()):
				var site: Dictionary = candidates[i]
				var a: Vector2 = site["point"]
				var fragment: PackedVector2Array = triangle
				for j in range(candidates.size()):
					if i == j:
						continue
					var b: Vector2 = candidates[j]["point"]
					if a.distance_squared_to(b) < 0.000001:
						if j < i:
							fragment = PackedVector2Array()
							break
						continue
					fragment = _clip_nearer(fragment, a, b)
					if fragment.size() < 3:
						break
				_append_polygon(meshes[int(site["owner"])], fragment)


static func build(assignments: Array, shared_vertices: Dictionary, old_to_new: Dictionary,
		smoothed_loops: Array, playable_half: Vector2, extra_barriers: Array = []) -> Dictionary:
	var meshes: Dictionary = {}
	var rows: int = assignments.size()
	var cols: int = int((assignments[0] as Array).size()) if rows > 0 else 0
	if cols == 0 or smoothed_loops.is_empty():
		return meshes
	var coast: Dictionary = _coast_shapes(smoothed_loops)
	(coast["barriers"] as Array).append_array(extra_barriers)
	if (coast["outers"] as Array).is_empty():
		return meshes
	var segments: Array[Rect2] = _boundary_segments(smoothed_loops)
	for id_any in old_to_new.values():
		var empty_polygons: Array[PackedInt32Array] = []
		meshes[int(id_any)] = {"points": PackedVector2Array(), "polygons": empty_polygons}
	var sites: Array[Dictionary] = []
	for r in range(rows):
		for c in range(cols):
			var region: int = int(assignments[r][c])
			if not old_to_new.has(region):
				continue
			var quad: PackedVector2Array = _cell_quad(c, r, cols, rows, playable_half, shared_vertices)
			var center: Vector2 = (quad[0] + quad[1] + quad[2] + quad[3]) * 0.25
			sites.append({"point": center, "owner": int(old_to_new[region])})
	# Include one padding ring so deformation of the original grid's
	# outside edge cannot hide any part of the unchanged wall interior.
	for r in range(-1, rows + 1):
		for c in range(-1, cols + 1):
			var region: int = int(assignments[r][c]) if r >= 0 and r < rows and c >= 0 and c < cols else -1
			var quad: PackedVector2Array = _cell_quad(c, r, cols, rows, playable_half, shared_vertices)
			var parts: Array[PackedVector2Array] = _tile_parts(quad, coast, segments)
			if parts.is_empty():
				continue
			if old_to_new.has(region):
				var mesh: Dictionary = meshes[int(old_to_new[region])]
				for part in parts:
					if part == quad:
						_append_quad(mesh, quad)
					else:
						_append_polygon(mesh, part)
			else:
				_assign_gap(parts, _gap_sites(quad, sites), meshes)
	return meshes
