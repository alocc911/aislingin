extends SceneTree

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const MapDiagnostics = preload("res://scripts/MapDiagnostics.gd")


func _initialize() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("MapDiagnosticsSelfTest: " + message)
	quit(1)


func _run() -> void:
	var generator: LevelGenerator = LevelGeneratorScript.new()
	var world := Node2D.new()
	root.add_child(world)
	var zones := Node2D.new()
	var obstacles := Node2D.new()
	var pins := Node2D.new()
	var provinces := Node2D.new()
	for group in [zones, obstacles, pins, provinces]:
		world.add_child(group)

	var generation: Dictionary = generator.generate_into(
		71, 3, zones, obstacles, pins, provinces, LevelConfig.PHASE_GRAND_MAP
	)
	if not bool(generation.get("grand_map", false)):
		_fail("Grand-map generation did not succeed")
		return
	var diagnostics: Dictionary = generator.get_grand_map_diagnostic_snapshot()
	if int(diagnostics.get("requested_seed", -1)) != 71 or int(diagnostics.get("selected_seed", -1)) < 1:
		_fail("Requested/selected seed was not recorded")
		return
	var attempts: Array = diagnostics.get("attempts", [])
	var selected_index: int = int(diagnostics.get("selected_attempt", 0)) - 1
	if selected_index < 0 or selected_index >= attempts.size():
		_fail("Missing selected attempt")
		return
	var selected: Dictionary = attempts[selected_index]
	var stages: Array = selected.get("mask_stages", [])
	if stages.is_empty():
		_fail("No intermediate land masks")
		return
	var found_initial: bool = false
	var found_final: bool = false
	for stage_any in stages:
		var stage: Dictionary = stage_any
		if String(stage.get("stage", "")) == "initial_template":
			found_initial = true
		if String(stage.get("stage", "")) == "final_land_mask":
			found_final = true
		var rows: Array = stage.get("rows", [])
		if rows.is_empty() or String(rows[0]).is_empty():
			_fail("Empty mask stage")
			return
	if not found_initial or not found_final:
		_fail("Missing initial or final land-mask stage")
		return
	if (selected.get("region_assignments", []) as Array).is_empty():
		_fail("No region assignment grid")
		return
	if (selected.get("region_seed_cells", []) as Array).is_empty():
		_fail("No province seed positions")
		return
	if (selected.get("provinces", []) as Array).size() != provinces.get_child_count():
		_fail("Province metadata does not match generated nodes")
		return
	if (selected.get("union_traces", []) as Array).size() < 2:
		_fail("Missing sanity/final wall polygon-union traces")
		return

	var walls: Array = MapDiagnostics.capture_outer_wall_bodies(obstacles)
	if walls.is_empty():
		_fail("No live physical wall geometry")
		return
	var live: Array = MapDiagnostics.capture_live_provinces(provinces)
	if live.size() != (selected.get("provinces", []) as Array).size():
		_fail("Live province snapshots are missing")
		return
	var payload: Dictionary = {
		"generation": diagnostics,
		"outer_wall_bodies": walls,
		"live_provinces": live,
		"terrain_colliders": MapDiagnostics.capture_terrain_colliders(obstacles)
	}
	var encoded: String = JSON.stringify(payload)
	var decoded: Variant = JSON.parse_string(encoded)
	if not (decoded is Dictionary) or (decoded as Dictionary).get("generation", {}).is_empty():
		_fail("JSON diagnostics cannot be decoded")
		return
	print("MAP_DIAGNOSTICS_TEST_OK masks=%d attempts=%d provinces=%d walls=%d bytes=%d" % [stages.size(), attempts.size(), live.size(), walls.size(), encoded.length()])
	world.queue_free()
	quit(0)
