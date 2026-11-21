extends SceneTree

# Fast, deterministic unit coverage for the coastal clipping primitive.
# No map generation required: sample both sides of overlapping wall
# rectangles, an inset bay, and a shoreline hole.
const Coastal = preload("res://scripts/CoastalOwnershipGeometry.gd")


func _fail(message: String) -> void:
	push_error("COASTAL_CLIP_REGRESSION_FAIL: " + message)
	quit(1)


func _inside(point: Vector2, poly: PackedVector2Array) -> bool:
	return Geometry2D.is_point_in_polygon(point, poly)


func _mesh_contains(point: Vector2, mesh: Dictionary) -> bool:
	var points: PackedVector2Array = mesh["points"]
	var polygons: Array[PackedInt32Array] = mesh["polygons"]
	for indices in polygons:
		var poly := PackedVector2Array()
		for index in indices:
			poly.append(points[index])
		if poly.size() >= 3 and _inside(point, poly):
			return true
	return false


func _initialize() -> void:
	call_deferred("_run")


func _test_conservative_sea_ownership() -> bool:
	# Conflicting shore neighbors must never be awarded to either province.
	var disputed: Array = [
		[-1, -1, -1],
		[0, -1, 1],
		[-1, -1, -1]
	]
	if Coastal._single_adjacent_owner(disputed, 1, 1, 3, 3) != -2:
		_fail("contested_sea_cell_assigned")
		return false
	if Coastal._single_adjacent_owner(disputed, 1, 0, 3, 3) != -1:
		_fail("diagonal_or_distant_owner_assigned")
		return false
	var two_neighbors_same_owner: Array = [
		[-1, -1, -1],
		[0, -1, 0],
		[-1, -1, -1]
	]
	if Coastal._single_adjacent_owner(two_neighbors_same_owner, 1, 1, 3, 3) != 0:
		_fail("same_owner_not_recognized")
		return false

	# The source land cell is at the center of a five-by-five grid.
	# Its northern neighbor is eligible, but the next sea row is not.
	var assignments: Array = []
	for r in range(5):
		var row: Array = [-1, -1, -1, -1, -1]
		if r == 2:
			row[2] = 0
		assignments.append(row)
	if Coastal._single_adjacent_owner(assignments, 2, 1, 5, 5) != 0:
		_fail("direct_sea_neighbor_not_found")
		return false
	if Coastal._single_adjacent_owner(assignments, 2, 0, 5, 5) != -1:
		_fail("distant_sea_cell_claimed")
		return false

	var outer_near := PackedVector2Array([
		Vector2(-180, -125), Vector2(180, -125),
		Vector2(180, 125), Vector2(-180, 125)
	])
	var near_meshes: Dictionary = Coastal.build(assignments, {}, {0: 0},
		[outer_near], Vector2(250, 250))
	var near_mesh: Dictionary = near_meshes[0]
	if not _mesh_contains(Vector2(0, -85), near_mesh):
		_fail("direct_wall_neighbor_not_filled")
		return false

	# Here the wall intersects the second sea row, but there is no
	# direct land neighbor. Previous flood-fill incorrectly colored it.
	var outer_far := PackedVector2Array([
		Vector2(-180, -210), Vector2(180, -210),
		Vector2(180, 125), Vector2(-180, 125)
	])
	var far_meshes: Dictionary = Coastal.build(assignments, {}, {0: 0},
		[outer_far], Vector2(250, 250))
	var far_mesh: Dictionary = far_meshes[0]
	if _mesh_contains(Vector2(0, -180), far_mesh):
		_fail("second_sea_row_colored")
		return false
	print("COASTAL_CONSERVATIVE_SEA_OWNERSHIP_OK")
	return true


func _run() -> void:
	var outer := PackedVector2Array([
		Vector2(-210, -190), Vector2(210, -190),
		Vector2(210, 190), Vector2(-210, 190)
	])
	# A counterclockwise land hole (screen Y-down convention).
	var hole := PackedVector2Array([
		Vector2(-38, -38), Vector2(-38, 38),
		Vector2(38, 38), Vector2(38, -38)
	])
	var coast: Dictionary = Coastal._coast_shapes([outer, hole])
	var barriers: Array = coast["barriers"]
	# This diagonal rectangle intersects two edges of the tile and overlaps
	# with the actual outer-wall footprints, reproducing tricky corners.
	var diagonal: PackedVector2Array = Coastal._wall_rectangle(
		Vector2(-95, -125), Vector2(-60, 100), 96.0)
	barriers.append({"poly": diagonal, "bounds": Coastal._bounds(diagonal)})
	var empty_polygons: Array[PackedInt32Array] = []
	var mesh: Dictionary = {"points": PackedVector2Array(), "polygons": empty_polygons}
	var quad := PackedVector2Array([
		Vector2(-170, -150), Vector2(170, -150),
		Vector2(170, 150), Vector2(-170, 150)
	])
	Coastal._append_clipped_tile(mesh, quad, coast["outers"],
		coast["hole_cutters"], barriers)
	if (mesh["polygons"] as Array).is_empty():
		_fail("missing_mesh")
		return
	var samples: int = 0
	for y in range(-145, 146, 10):
		for x in range(-165, 166, 10):
			var point := Vector2(float(x) + 0.37, float(y) + 0.53)
			var expected: bool = _inside(point, outer) and not _inside(point, hole)
			if expected:
				for wall_any in barriers:
					var wall: Dictionary = wall_any
					if _inside(point, wall["poly"]):
						expected = false
						break
			var actual: bool = _mesh_contains(point, mesh)
			if actual != expected:
				_fail("sample_%s_expected_%s_actual_%s" % [str(point), str(expected), str(actual)])
				return
			samples += 1
	if not _test_conservative_sea_ownership():
		return
	print("COASTAL_CLIP_REGRESSION_OK samples=", samples,
		" triangles=", (mesh["polygons"] as Array).size())
	quit(0)
