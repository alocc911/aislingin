extends SceneTree

# Deterministic regression: every playable land cell is represented by one
# visible and hittable ownership quad; neighbors share exactly identical edges.
const Generator = preload("res://scripts/LevelGenerator.gd")
const Config = preload("res://scripts/LevelConfig.gd")
const RNGScript = preload("res://scripts/RNG.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")


func _edge_key(a: Vector2, b: Vector2) -> String:
	var ak: String = "%d,%d" % [roundi(a.x * 1000.0), roundi(a.y * 1000.0)]
	var bk: String = "%d,%d" % [roundi(b.x * 1000.0), roundi(b.y * 1000.0)]
	return ak + "|" + bk if ak < bk else bk + "|" + ak


func _cell_polygon(points: PackedVector2Array, indices: PackedInt32Array) -> PackedVector2Array:
	var cell := PackedVector2Array()
	for index in indices:
		if index >= 0 and index < points.size():
			cell.append(points[index])
	return cell


func _fail(message: String) -> void:
	push_error("CANONICAL_PROVINCE_GEOMETRY_TEST_FAIL: " + message)
	quit(1)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var generator = Generator.new()
	var province_system = ProvinceSystemScript.new()
	for seed in [71, 211, 447, 619, 829, 1009, 1201, 1553, 377284793]:
		var rng: RandomNumberGenerator = RNGScript.make_gen_rng(seed)
		var data: Dictionary = generator._generate_template_grand_map_data(
			Config.GRAND_MAP_PLAYABLE_HALF_EXTENTS, rng, seed, 3)
		var province_entries: Array = data.get("provinces", [])
		var coastline: Dictionary = data.get("coastline_data", {})
		var render_coastline: Array = data.get("canonical_coastline_loops", [])
		if province_entries.is_empty() or render_coastline.is_empty():
			_fail("empty_generated_map_%d" % seed)
			return
		var edge_owners: Dictionary = {}
		var total_quads: int = 0
		var region_fills: Dictionary = {}
		var continuous_fill_count: int = 0
		for entry_any in province_entries:
			var entry: Dictionary = entry_any
			var province_id: int = int(entry.get("id", -1))
			var points: PackedVector2Array = entry.get("canonical_mesh_points", PackedVector2Array())
			var polygons: Array[PackedInt32Array] = entry.get("canonical_mesh_polygons", [])
			if points.is_empty() or polygons.is_empty():
				_fail("missing_mesh_%d_%d" % [seed, province_id])
				return
			var contour: PackedVector2Array = entry.get("polygon", PackedVector2Array())
			var use_mesh: bool = generator._canonical_region_requires_cell_mesh(contour, points, polygons)
			var fill := Polygon2D.new()
			fill.polygon = points if use_mesh else contour
			if use_mesh:
				fill.polygons = polygons
			else:
				continuous_fill_count += 1
			region_fills[province_id] = fill
			for indices in polygons:
				var quad: PackedVector2Array = _cell_polygon(points, indices)
				if quad.size() != 4:
					_fail("malformed_quad_%d_%d" % [seed, province_id])
					return
				var center: Vector2 = (quad[0] + quad[1] + quad[2] + quad[3]) * 0.25
				# Unlike the previous test, verify the ACTUAL rendered fill and
				# hit target, not only the backup cell mesh. This catches the
				# visual coverage failures that the old test missed.
				if not province_system._point_in_province_fill(center, fill, true):
					_fail("invisible_or_unhittable_quad_%d_%d" % [seed, province_id])
					return
				for edge_idx in range(4):
					var a: Vector2 = quad[edge_idx]
					var b: Vector2 = quad[(edge_idx + 1) % 4]
					if a.distance_to(b) < 0.001:
						_fail("collapsed_edge_%d_%d" % [seed, province_id])
						return
					var key: String = _edge_key(a, b)
					if not edge_owners.has(key):
						edge_owners[key] = []
					(edge_owners[key] as Array).append(province_id)
				total_quads += 1
		if total_quads != int(coastline.get("land_cells", -1)):
			_fail("coverage_%d_land_%d_quads_%d" % [seed, int(coastline.get("land_cells", -1)), total_quads])
			return
		# The intended visual mode is continuous region fills, with cell
		# geometry reserved for real holes and disconnected components.
		# Reject a regression that silently brings back an all-quad map.
		if continuous_fill_count < maxi(1, province_entries.size() / 2):
			_fail("continuous_fill_regression_%d_%d_of_%d" % [seed, continuous_fill_count, province_entries.size()])
			return
		var touching_pairs: Dictionary = {}
		var coast_segments: Array = []
		for loop_any in render_coastline:
			var loop: PackedVector2Array = loop_any
			for edge_idx in range(loop.size()):
				coast_segments.append([loop[edge_idx], loop[(edge_idx + 1) % loop.size()]])
		for key_any in edge_owners.keys():
			var owners: Array = edge_owners[key_any]
			if owners.size() < 1 or owners.size() > 2:
				_fail("edge_coverage_%d_%s_%d" % [seed, String(key_any), owners.size()])
				return
			if owners.size() == 2 and int(owners[0]) != int(owners[1]):
				var lo: int = mini(int(owners[0]), int(owners[1]))
				var hi: int = maxi(int(owners[0]), int(owners[1]))
				touching_pairs["%d,%d" % [lo, hi]] = true
		for entry_any in province_entries:
			var entry: Dictionary = entry_any
			var id: int = int(entry.get("id", -1))
			for neighbor_any in entry.get("neighbors", []):
				var neighbor_id: int = int(neighbor_any)
				if not touching_pairs.has("%d,%d" % [mini(id, neighbor_id), maxi(id, neighbor_id)]):
					_fail("missing_shared_edge_%d_%d_%d" % [seed, id, neighbor_id])
					return
		for fill_any in region_fills.values():
			(fill_any as Polygon2D).free()
		print("CANONICAL_PROVINCE_GEOMETRY_SEED_OK ", seed, " cells=", total_quads,
			" provinces=", province_entries.size(), " continuous_fills=", continuous_fill_count,
			" coastline_segments=", coast_segments.size())
	print("CANONICAL_PROVINCE_GEOMETRY_TEST_OK")
	quit(0)
