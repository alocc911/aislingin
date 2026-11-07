extends RefCounted
## Exact coastline extraction from the FINAL playable land mask.
## Land is always on the right of a directed edge (Godot's Y-down coordinates).
## Consequently, mainland outlines are clockwise in screen space and holes
## are counterclockwise. Wall normals MUST preserve those orientations.
##
## All calculations are deterministic; no RNG, provinces, or game state mutate.


static func build(mask: Array, playable_half: Vector2) -> Dictionary:
	var rows: int = mask.size()
	var cols: int = int(mask[0].size()) if rows > 0 else 0
	if rows == 0 or cols == 0:
		return _invalid_result("empty_land_mask")
	for row_any in mask:
		if not (row_any is Array) or row_any.size() != cols:
			return _invalid_result("non_rectangular_land_mask")

	var edges: Array[Dictionary] = _collect_edges(mask, cols, rows)
	if edges.is_empty():
		return _invalid_result("no_exposed_land_edges")
	var outbound: Dictionary = {}
	for i in range(edges.size()):
		var source: Vector2i = edges[i]["from"]
		if not outbound.has(source):
			outbound[source] = []
		var indices: Array = outbound[source]
		indices.append(i)
		outbound[source] = indices

	var visited := PackedByteArray()
	visited.resize(edges.size())
	visited.fill(0)
	var grid_loops: Array = []
	var loop_edge_counts: Array[int] = []
	var open_loops: int = 0
	var traced_edges: int = 0
	for start_idx in range(edges.size()):
		if visited[start_idx] != 0:
			continue
		var first: Vector2i = edges[start_idx]["from"]
		var current_idx: int = start_idx
		var corners: Array[Vector2i] = []
		var closed: bool = false
		var loop_edges: int = 0
		while loop_edges <= edges.size():
			if visited[current_idx] != 0:
				break
			var edge: Dictionary = edges[current_idx]
			visited[current_idx] = 1
			traced_edges += 1
			loop_edges += 1
			corners.append(edge["from"])
			var vertex: Vector2i = edge["to"]
			if vertex == first:
				closed = true
				break
			var heading: Vector2i = vertex - Vector2i(edge["from"])
			var next_idx: int = -1
			var best_turn: int = -1
			for candidate_any in outbound.get(vertex, []):
				var candidate_idx: int = int(candidate_any)
				if visited[candidate_idx] != 0:
					continue
				var onward: Dictionary = edges[candidate_idx]
				var next_heading: Vector2i = Vector2i(onward["to"]) - vertex
				var cross: int = heading.x * next_heading.y - heading.y * next_heading.x
				var dot: int = heading.dot(next_heading)
				# At diagonal corner contacts, follow the right-hand coast,
				# rather than accidentally joining two different contours.
				var turn_rank: int = 3 if cross == 1 else (2 if dot == 1 else (1 if cross == -1 else 0))
				if turn_rank > best_turn:
					best_turn = turn_rank
					next_idx = candidate_idx
			if next_idx < 0:
				break
			current_idx = next_idx
		if not closed or corners.size() < 4:
			open_loops += 1
			continue
		grid_loops.append(corners)
		loop_edge_counts.append(loop_edges)

	var cell_width: float = 2.0 * playable_half.x / float(cols)
	var cell_height: float = 2.0 * playable_half.y / float(rows)
	var polygons: Array = []
	var holes: int = 0
	var signed_cell_area: float = 0.0
	for corners_any in grid_loops:
		var corners: Array = corners_any
		var raw_poly := PackedVector2Array()
		var grid_area: float = 0.0
		for i in range(corners.size()):
			var p: Vector2i = corners[i]
			var q: Vector2i = corners[(i + 1) % corners.size()]
			grid_area += float(p.x * q.y - p.y * q.x)
			raw_poly.append(Vector2(
				-playable_half.x + float(p.x) * cell_width,
				-playable_half.y + float(p.y) * cell_height
			))
		signed_cell_area += grid_area * 0.5
		if grid_area < 0.0:
			holes += 1
		polygons.append(_collapse_straight_grid_points(raw_poly))

	var land_cells: int = 0
	for r in range(rows):
		for c in range(cols):
			if bool(mask[r][c]):
				land_cells += 1

	var result: Dictionary = {
		"source": "final_land_mask",
		"loops": polygons,
		"grid_loops": grid_loops,
		"grid_cols": cols,
		"grid_rows": rows,
		"land_cells": land_cells,
		"expected_edges": edges.size(),
		"traced_edges": traced_edges,
		"open_loops": open_loops,
		"hole_count": holes,
		"loop_edge_counts": loop_edge_counts,
		"signed_cell_area": signed_cell_area
	}
	result["validation"] = validate(mask, result)
	return result


static func validate(mask: Array, coastline: Dictionary) -> Dictionary:
	var rows: int = mask.size()
	var cols: int = int(mask[0].size()) if rows > 0 else 0
	if rows <= 0 or cols <= 0:
		return {"failed": true, "reason": "empty_land_mask", "bad_segments": 1, "total_segments": 0, "bad_ratio": 1.0}

	var expected: Dictionary = {}
	for edge in _collect_edges(mask, cols, rows):
		expected[_edge_key(edge["from"], edge["to"])] = true
	var observed: Dictionary = {}
	var duplicate_edges: int = 0
	var invalid_edges: int = 0
	var malformed_loops: int = 0
	var area: float = 0.0
	for corners_any in coastline.get("grid_loops", []):
		var corners: Array = corners_any
		if corners.size() < 4:
			malformed_loops += 1
			continue
		for i in range(corners.size()):
			var a: Vector2i = corners[i]
			var b: Vector2i = corners[(i + 1) % corners.size()]
			var key: String = _edge_key(a, b)
			if not expected.has(key):
				invalid_edges += 1
			if observed.has(key):
				duplicate_edges += 1
			observed[key] = true
			area += float(a.x * b.y - a.y * b.x) * 0.5
	var missing_edges: int = 0
	for key in expected:
		if not observed.has(key):
			missing_edges += 1

	var land_cells: int = 0
	for row in mask:
		for cell in row:
			if bool(cell):
				land_cells += 1
	var bad: int = missing_edges + invalid_edges + duplicate_edges + malformed_loops + int(coastline.get("open_loops", 0))
	var area_error: float = absf(area - float(land_cells))
	var area_mismatch: bool = area_error > maxf(0.01, float(land_cells) * 0.0001)
	if area_mismatch:
		bad += 1
	var mismatch: bool = coastline.get("grid_cols", -1) != cols or coastline.get("grid_rows", -1) != rows
	if mismatch:
		bad += 1
	var loop_count: int = (coastline.get("loops", []) as Array).size()
	if loop_count == 0:
		bad += 1
	var reason: String = "ok"
	if bad > 0:
		reason = "unclosed_or_noncoast_boundary"
	return {
		"failed": bad > 0,
		"reason": reason,
		"bad_segments": bad,
		"total_segments": expected.size(),
		"bad_ratio": float(bad) / maxf(1.0, float(expected.size())),
		"expected_edges": expected.size(),
		"traced_edges": observed.size(),
		"missing_edges": missing_edges,
		"invalid_edges": invalid_edges,
		"duplicate_edges": duplicate_edges,
		"open_loops": int(coastline.get("open_loops", 0)),
		"loop_count": loop_count,
		"hole_count": int(coastline.get("hole_count", 0)),
		"signed_cell_area": area,
		"land_cells": land_cells
	}


static func _invalid_result(reason: String) -> Dictionary:
	return {
		"source": "final_land_mask",
		"loops": [],
		"grid_loops": [],
		"validation": {"failed": true, "reason": reason, "bad_segments": 1, "total_segments": 0, "bad_ratio": 1.0}
	}


static func _collect_edges(mask: Array, cols: int, rows: int) -> Array[Dictionary]:
	var edges: Array[Dictionary] = []
	for r in range(rows):
		for c in range(cols):
			if not bool(mask[r][c]):
				continue
			if r == 0 or not bool(mask[r - 1][c]):
				edges.append({"from": Vector2i(c, r), "to": Vector2i(c + 1, r)})
			if c == cols - 1 or not bool(mask[r][c + 1]):
				edges.append({"from": Vector2i(c + 1, r), "to": Vector2i(c + 1, r + 1)})
			if r == rows - 1 or not bool(mask[r + 1][c]):
				edges.append({"from": Vector2i(c + 1, r + 1), "to": Vector2i(c, r + 1)})
			if c == 0 or not bool(mask[r][c - 1]):
				edges.append({"from": Vector2i(c, r + 1), "to": Vector2i(c, r)})
	return edges


static func _edge_key(a: Vector2i, b: Vector2i) -> String:
	return "%d,%d>%d,%d" % [a.x, a.y, b.x, b.y]


static func _collapse_straight_grid_points(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 4:
		return poly
	var compact := PackedVector2Array()
	var n: int = poly.size()
	for i in range(n):
		var previous: Vector2 = poly[(i - 1 + n) % n]
		var current: Vector2 = poly[i]
		var following: Vector2 = poly[(i + 1) % n]
		var a: Vector2 = current - previous
		var b: Vector2 = following - current
		if absf(a.cross(b)) < 0.01 and a.dot(b) > 0.0:
			continue
		compact.append(current)
	return compact if compact.size() >= 3 else poly
