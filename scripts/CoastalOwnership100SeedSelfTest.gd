extends SceneTree
## Independent area, overlap and landing checks; immutable baseline fingerprints.
const Generator = preload("res://scripts/LevelGenerator.gd")
const Coastal = preload("res://scripts/CoastalOwnershipGeometry.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const Config = preload("res://scripts/LevelConfig.gd")
const RNGScript = preload("res://scripts/RNG.gd")
const Diagnostics = preload("res://scripts/MapDiagnostics.gd")
const HALF: Vector2 = Config.GRAND_MAP_PLAYABLE_HALF_EXTENTS
const BUCKET: float = 240.0
const OVERLAP_TOLERANCE: float = 1.0


func _initialize() -> void:
	call_deferred("_run")


func _fail(message: String) -> bool:
	push_error("COASTAL_100_FAIL " + message)
	return false


func _area(poly: PackedVector2Array) -> float:
	if poly.size() < 3:
		return 0.0
	var origin: Vector2 = poly[0]
	var sum: float = 0.0
	for i in range(1, poly.size() - 1):
		sum += (poly[i] - origin).cross(poly[i + 1] - origin)
	return absf(sum) * 0.5


func _actual_walls(root: Node2D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for body in Diagnostics.capture_outer_wall_bodies(root):
		var center := Vector2(body["center"][0], body["center"][1])
		var half := Vector2(body["size"][0], body["size"][1]) * 0.5
		var angle: float = float(body["angle"])
		var poly := PackedVector2Array()
		for corner in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
				Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
			var v: Vector2 = corner
			poly.append(center + v.rotated(angle))
		result.append({"poly": poly, "bounds": Coastal._bounds(poly)})
	return result


func _expected(point: Vector2, coast: Dictionary, walls: Array[Dictionary]) -> bool:
	if not Coastal._point_inside_coast(point, coast["outers"], coast["holes"]):
		return false
	for wall in walls:
		if (wall["bounds"] as Rect2).has_point(point) and Geometry2D.is_point_in_polygon(point, wall["poly"]):
			return false
	return true


func _near_boundary(point: Vector2, loops: Array, walls: Array[Dictionary]) -> bool:
	for loop_any in loops:
		var loop: PackedVector2Array = loop_any
		for i in range(loop.size()):
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point, loop[i], loop[(i + 1) % loop.size()])) < 0.1:
				return true
	for wall in walls:
		if not (wall["bounds"] as Rect2).grow(0.1).has_point(point):
			continue
		var poly: PackedVector2Array = wall["poly"]
		for i in range(poly.size()):
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point, poly[i], poly[(i + 1) % poly.size()])) < 0.1:
				return true
	return false


func _owner_at(point: Vector2, fills: Array[Polygon2D], system: Node) -> int:
	var owner: int = -1
	for i in range(fills.size()):
		if system._point_in_province_fill(point, fills[i], true):
			if owner >= 0:
				return -2
			owner = i
	return owner


func _reference_area(coast: Dictionary, walls: Array[Dictionary]) -> float:
	# Independent tessellation: triangulate the coastline, not the grid.
	var blockers: Array = (coast["hole_cutters"] as Array).duplicate()
	blockers.append_array(walls)
	var sum: float = 0.0
	for outer in coast["outers"]:
		var poly: PackedVector2Array = outer["poly"]
		for tri in Coastal._triangulate_into_convex(poly):
			var parts: Array[PackedVector2Array] = [tri]
			for fragment in Coastal._clip_against_blockers(parts, blockers, Coastal._bounds(tri)):
				sum += _area(fragment)
	return sum


func _bucket_keys(bounds: Rect2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(floori(bounds.position.x / BUCKET), floori(bounds.end.x / BUCKET) + 1):
		for y in range(floori(bounds.position.y / BUCKET), floori(bounds.end.y / BUCKET) + 1):
			result.append(Vector2i(x, y))
	return result


func _verify_meshes(seed: int, entries: Array, coast: Dictionary, walls: Array[Dictionary],
		loops: Array, system: Node, cols: int, rows: int) -> bool:
	var fills: Array[Polygon2D] = []
	var area: float = 0.0
	var records: Array[Dictionary] = []
	var buckets: Dictionary = {}
	var samples: int = 0
	for entry_any in entries:
		var entry: Dictionary = entry_any
		var id: int = int(entry["id"])
		var points: PackedVector2Array = entry.get("coastal_fill_points", PackedVector2Array())
		var indices: Array[PackedInt32Array] = entry.get("coastal_fill_polygons", [])
		if points.is_empty() or indices.is_empty():
			return _fail("%d empty ownership %d" % [seed, id])
		var fill := Polygon2D.new()
		fill.polygon = points
		fill.polygons = indices
		fills.append(fill)
		for cell in indices:
			var poly := PackedVector2Array()
			for index in cell:
				if index < 0 or index >= points.size():
					return _fail("%d invalid vertex %d" % [seed, id])
				poly.append(points[index])
			var cell_area: float = _area(poly)
			if cell_area <= 0.0:
				return _fail("%d zero-area polygon %d" % [seed, id])
			area += cell_area
			var bounds: Rect2 = Coastal._bounds(poly)
			var keys: Array[Vector2i] = _bucket_keys(bounds)
			var checked: Dictionary = {}
			for key in keys:
				for other_index in buckets.get(key, []):
					if checked.has(other_index):
						continue
					checked[other_index] = true
					var other: Dictionary = records[other_index]
					if not bounds.intersects(other["bounds"]):
						continue
					for overlap in Geometry2D.intersect_polygons(poly, other["poly"]):
						if _area(overlap) > OVERLAP_TOLERANCE:
							return _fail("%d overlap owners %d/%d area %.3f at %s" % [seed, id, int(other["id"]), _area(overlap), str(bounds.position)])
			var record_index: int = records.size()
			records.append({"id": id, "poly": poly, "bounds": bounds})
			for key in keys:
				if not buckets.has(key):
					buckets[key] = []
				(buckets[key] as Array).append(record_index)
			for wall in walls:
				if not bounds.intersects(wall["bounds"]):
					continue
				for overlap in Geometry2D.intersect_polygons(poly, wall["poly"]):
					if _area(overlap) > OVERLAP_TOLERANCE:
						return _fail("%d wall overlap %d area %.3f" % [seed, id, _area(overlap)])
	var expected_area: float = _reference_area(coast, walls)
	var tolerance: float = maxf(30.0, expected_area * 0.00001)
	if expected_area <= 0.0 or absf(area - expected_area) > tolerance:
		return _fail("%d area actual %.3f expected %.3f delta %.3f tolerance %.3f" % [seed, area, expected_area, area - expected_area, tolerance])
	for r in range(rows):
		for c in range(cols):
			var point := Vector2(-HALF.x + 2.0 * HALF.x * (float(c) + 0.371) / float(cols),
				-HALF.y + 2.0 * HALF.y * (float(r) + 0.613) / float(rows))
			var expected: bool = _expected(point, coast, walls)
			var owner: int = _owner_at(point, fills, system)
			if (owner >= 0) != expected or owner == -2:
				if not _near_boundary(point, loops, walls):
					return _fail("%d lattice point %s expected %s owner %d" % [seed, str(point), str(expected), owner])
			samples += 1
	for loop_any in loops:
		var loop: PackedVector2Array = loop_any
		for i in range(loop.size()):
			var a: Vector2 = loop[i]
			var b: Vector2 = loop[(i + 1) % loop.size()]
			if a.distance_squared_to(b) < 0.001:
				continue
			var normal := Vector2((b - a).y, -(b - a).x).normalized()
			for fraction in [0.23, 0.67]:
				for offset in [-135.0, -30.0, -4.0, 4.0, 25.0, 75.0, 140.0, 220.0]:
					var point: Vector2 = a.lerp(b, fraction) - normal * offset
					var expected: bool = _expected(point, coast, walls)
					var owner: int = _owner_at(point, fills, system)
					if (owner >= 0) != expected or owner == -2:
						if not _near_boundary(point, loops, walls):
							return _fail("%d coast point %s expected %s owner %d" % [seed, str(point), str(expected), owner])
					samples += 1
	for entry in entries:
		var id: int = int(entry["id"])
		var points: PackedVector2Array = entry["canonical_mesh_points"]
		for cell in entry["canonical_mesh_polygons"]:
			var point := Vector2.ZERO
			for index in cell:
				point += points[index]
			point /= float(cell.size())
			if _expected(point, coast, walls) and _owner_at(point, fills, system) != id:
				if not _near_boundary(point, loops, walls):
					return _fail("%d original territory reassigned %d at %s" % [seed, id, str(point)])
			samples += 1
	for fill in fills:
		fill.free()
	print("COASTAL_100_SEED_OK ", seed, " samples=", samples, " polygons=", records.size(), " area_delta=", area - expected_area)
	return true


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var shard: int = int(args[0]) if args.size() > 0 else 0
	var baseline: bool = args.size() > 1 and args[1] == "baseline"
	var generator = Generator.new()
	var system = ProvinceSystemScript.new()
	var seeds: Array[int] = [71, 211, 447, 619, 829, 1009, 1201, 1553, 377284793, 147]
	for i in range(90):
		seeds.append(2003 + i * 7919)
	for index in range(shard * 10, shard * 10 + 10):
		var seed: int = seeds[index]
		var start: int = Time.get_ticks_msec()
		var data: Dictionary = generator._generate_template_grand_map_data(HALF, RNGScript.make_gen_rng(seed), seed, 3)
		var entries: Array = data["provinces"]
		var coast_data: Dictionary = data["coastline_data"]
		var raw_loops: Array = coast_data["loops"]
		var loops: Array = []
		for loop in raw_loops:
			loops.append(generator._make_smoothed_province_display_polyline(loop, 0.0))
		var coast: Dictionary = Coastal._coast_shapes(loops)
		var root := Node2D.new()
		get_root().add_child(root)
		generator._spawn_grand_map_outer_barrier(root, entries, raw_loops)
		var walls: Array[Dictionary] = _actual_walls(root)
		var wall_snapshot: Array = Diagnostics.capture_outer_wall_bodies(root)
		for wall in wall_snapshot:
			wall.erase("name")
			wall.erase("path")
		var stable: Dictionary = data.duplicate(true)
		for entry in stable["provinces"]:
			entry.erase("coastal_fill_points")
			entry.erase("coastal_fill_polygons")
		print("COASTAL_PARITY ", seed, " ", var_to_bytes([stable, wall_snapshot]).hex_encode().sha256_text())
		print("COASTAL_GENERATION_MS ", seed, " ", Time.get_ticks_msec() - start)
		if not baseline and not _verify_meshes(seed, entries, coast, walls, loops, system,
				int(coast_data["grid_cols"]), int(coast_data["grid_rows"])):
			root.free()
			generator.free()
			system.free()
			quit(1)
			return
		root.free()
	generator.free()
	system.free()
	print("COASTAL_100_SHARD_OK ", shard, " baseline=", baseline)
	quit(0)
