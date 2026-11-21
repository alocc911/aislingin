extends SceneTree

# Regression for the corrected color mesh: the same region that is painted
# must be returned by a ball landing, and neither the drawn wall nor ocean
# areas may inherit a province owner.
const Generator = preload("res://scripts/LevelGenerator.gd")
const Geometry = preload("res://scripts/CoastalOwnershipGeometry.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const Config = preload("res://scripts/LevelConfig.gd")
const RNGScript = preload("res://scripts/RNG.gd")


func _fail(message: String) -> void:
	push_error("COASTAL_OWNERSHIP_TEST_FAIL: " + message)
	quit(1)


func _initialize() -> void:
	call_deferred("_run")


func _inside_wall(point: Vector2, barriers: Array) -> bool:
	for entry_any in barriers:
		var entry: Dictionary = entry_any
		if (entry["bounds"] as Rect2).has_point(point) and Geometry2D.is_point_in_polygon(point, entry["poly"]):
			return true
	return false


func _province_at(point: Vector2, fills: Array, province_system: Node) -> int:
	var found: int = -1
	for i in range(fills.size()):
		var fill: Polygon2D = fills[i]
		if province_system._point_in_province_fill(point, fill, true):
			if found >= 0:
				return -2
			found = i
	return found


func _run() -> void:
	var generator = Generator.new()
	var province_system = ProvinceSystemScript.new()
	for seed in [71, 447]:
		var data: Dictionary = generator._generate_template_grand_map_data(
			Config.GRAND_MAP_PLAYABLE_HALF_EXTENTS, RNGScript.make_gen_rng(seed), seed, 3)
		var entries: Array = data.get("provinces", [])
		var coastline: Dictionary = data.get("coastline_data", {})
		if entries.is_empty() or coastline.is_empty():
			_fail("no_geometry_%d" % seed)
			return
		var loops: Array = []
		for raw_any in coastline.get("loops", []):
			var raw: PackedVector2Array = raw_any
			loops.append(generator._make_smoothed_province_display_polyline(raw, 0.0))
		var shapes: Dictionary = Geometry._coast_shapes(loops)
		var outers: Array = shapes["outers"]
		var holes: Array = shapes["holes"]
		var barriers: Array = shapes["barriers"]
		var fills: Array = []
		for entry_any in entries:
			var entry: Dictionary = entry_any
			var points: PackedVector2Array = entry.get("coastal_fill_points", PackedVector2Array())
			var indices: Array[PackedInt32Array] = entry.get("coastal_fill_polygons", [])
			if points.is_empty() or indices.is_empty():
				_fail("missing_coastal_fill_%d_%d" % [seed, int(entry.get("id", -1))])
				return
			var fill := Polygon2D.new()
			fill.polygon = points
			fill.polygons = indices
			fills.append(fill)
		var sampled: int = 0
		for loop_any in loops:
			var loop: PackedVector2Array = loop_any
			# Representative samples along each visible wall, not every pixel.
			# Exhaustive checks would repeatedly scan thousands of display triangles.
			var stride: int = maxi(1, int(loop.size() / 12))
			for i in range(0, loop.size(), stride):
				var a: Vector2 = loop[i]
				var b: Vector2 = loop[(i + 1) % loop.size()]
				if a.distance_squared_to(b) < 0.01:
					continue
				var outward: Vector2 = Vector2((b - a).y, -(b - a).x).normalized()
				var mid: Vector2 = (a + b) * 0.5
				for offset in [-40.0, -12.0, 8.0, 25.0, 65.0, 125.0]:
					var point: Vector2 = mid - outward * offset
					var expected: bool = Geometry._point_inside_coast(point, outers, holes) and not _inside_wall(point, barriers)
					var actual: int = _province_at(point, fills, province_system)
					if expected and actual < 0:
						_fail("missing_or_double_%d_at_%s_expected_owner_actual_%d" % [seed, str(point), actual])
						return
					if not expected and actual != -1:
						_fail("fill_outside_wall_%d_at_%s_owner_%d" % [seed, str(point), actual])
						return
					sampled += 1
		for fill_any in fills:
			(fill_any as Polygon2D).free()
		print("COASTAL_OWNERSHIP_SEED_OK ", seed, " samples=", sampled)
	print("COASTAL_OWNERSHIP_TEST_OK")
	quit(0)
