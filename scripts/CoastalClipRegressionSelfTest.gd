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


func _test_complete_sea_ownership() -> bool:
	var assignments: Array = [
		[-1, -1, -1, -1, -1],
		[-1, -1, -1, -1, -1],
		[-1, 0, -1, 1, -1],
		[-1, -1, -1, -1, -1],
		[-1, -1, -1, -1, -1]
	]
	var outer := PackedVector2Array([
		Vector2(-180, -210), Vector2(180, -210),
		Vector2(180, 125), Vector2(-180, 125)
	])
	var meshes: Dictionary = Coastal.build(assignments, {}, {0: 0, 1: 1},
		[outer], Vector2(250, 250))
	for point in [Vector2(-20, 0), Vector2(20, 0), Vector2(-20, -180), Vector2(20, -180)]:
		var expected: int = 0 if point.x < 0 else 1
		if not _mesh_contains(point, meshes[expected]) or _mesh_contains(point, meshes[1 - expected]):
			_fail("gap_not_partitioned_%s" % str(point))
			return false
	for point in [Vector2(-200, 0), Vector2(200, 0), Vector2(0, -230)]:
		if _mesh_contains(point, meshes[0]) or _mesh_contains(point, meshes[1]):
			_fail("exterior_gap_claimed_%s" % str(point))
			return false
	print("COASTAL_COMPLETE_SEA_OWNERSHIP_OK")
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
	if not _test_complete_sea_ownership():
		return
	print("COASTAL_CLIP_REGRESSION_OK samples=", samples,
		" triangles=", (mesh["polygons"] as Array).size())
	quit(0)
