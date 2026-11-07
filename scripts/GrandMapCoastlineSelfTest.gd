extends SceneTree

const Coastline = preload("res://scripts/GrandMapCoastline.gd")
const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const LevelConfig = preload("res://scripts/LevelConfig.gd")
const RNG = preload("res://scripts/RNG.gd")


func _initialize() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("GrandMapCoastlineSelfTest: " + message)
	quit(1)


func _mask(text_rows: Array[String]) -> Array:
	var result: Array = []
	for line in text_rows:
		var cells: Array = []
		for i in range(line.length()):
			cells.append(line.substr(i, 1) == "1")
		result.append(cells)
	return result


func _run() -> void:
	var simple: Dictionary = Coastline.build(_mask(["1111", "1111"]), Vector2(200, 100))
	if bool(simple.get("validation", {}).get("failed", true)) or (simple.get("loops", []) as Array).size() != 1:
		_fail("simple rectangle failed exact coastline validation")
		return
	var donut: Dictionary = Coastline.build(_mask(["11111", "10001", "10001", "11111"]), Vector2(250, 200))
	if bool(donut.get("validation", {}).get("failed", true)) or int(donut.get("hole_count", -1)) != 1:
		_fail("a valid interior exterior hole was lost")
		return
	var diagonal: Dictionary = Coastline.build(_mask(["10", "01"]), Vector2(100, 100))
	if bool(diagonal.get("validation", {}).get("failed", true)) or (diagonal.get("loops", []) as Array).size() != 2:
		_fail("diagonal corner contact must not join two coastlines")
		return
	var corrupt: Dictionary = donut.duplicate(true)
	var corrupted_loops: Array = corrupt["grid_loops"]
	var first: Array = corrupted_loops[0]
	first[0] = Vector2i(9999, 9999)
	if not bool(Coastline.validate(_mask(["11111", "10001", "10001", "11111"]), corrupt).get("failed", false)):
		_fail("strict validator incorrectly accepted a fabricated wall edge")
		return

	var generator: LevelGenerator = LevelGeneratorScript.new()
	# Selected attempt 7 from the uploaded interiorWalls diagnostic. Before
	# the fix, this connected map was incorrectly merged into 3 province
	# polygon groups and walled around two legitimate province groups.
	var failing_seed: int = 377284793
	var rng: RandomNumberGenerator = RNG.make_gen_rng(failing_seed)
	var generated: Dictionary = generator._generate_template_grand_map_data(
		LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS, rng, failing_seed, 1
	)
	var coast: Dictionary = generated.get("coastline_data", {})
	var validation: Dictionary = coast.get("validation", {})
	if bool(validation.get("failed", true)):
		_fail("historic failing seed rejected: %s" % str(validation))
		return
	if int(coast.get("land_cells", -1)) != 799 or int(coast.get("expected_edges", -1)) != 406:
		_fail("historic seed's original land shape changed")
		return
	if int(coast.get("hole_count", -1)) != 2:
		_fail("historic seed should retain its 2 genuine non-land holes")
		return
	if (coast.get("loops", []) as Array).size() != 3:
		_fail("historic seed should have 1 real exterior contour and 2 real hole contours")
		return
	var legacy_groups: Array = generator._get_merged_mainland_polygons_from_province_data(generated.get("provinces", []))
	if legacy_groups.size() != 3:
		_fail("historical polygon-union failure no longer reproduced; inspect regression fixture")
		return

	for seed in [71, 211, 447, 619, 829, 1009, 1201, 1553, 1847390374]:
		var seeded_rng: RandomNumberGenerator = RNG.make_gen_rng(seed)
		var data: Dictionary = generator._generate_template_grand_map_data(LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS, seeded_rng, seed, 3)
		var boundary: Dictionary = data.get("coastline_data", {})
		if bool(boundary.get("validation", {}).get("failed", true)):
			_fail("coastline validation failed for seed %d" % seed)
			return

	print("GRAND_MAP_COASTLINE_TEST_OK seed=%d provinces=%d coastline_edges=%d holes=%d" % [
		failing_seed,
		(generated.get("provinces", []) as Array).size(),
		int(coast.get("expected_edges", -1)),
		int(coast.get("hole_count", -1))
	])
	quit(0)
