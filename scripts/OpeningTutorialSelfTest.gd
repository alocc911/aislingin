extends SceneTree

# Lightweight headless fixture: validates the fixed tutorial topology, starting
# balance, deterministic encounter layout, and guided stage transitions.
const TutorialFlow = preload("res://scripts/MainLevelFlow.gd")
const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const LevelConfig = preload("res://scripts/LevelConfig.gd")

var errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)


func _ownership(entries: Array[Dictionary]) -> Dictionary:
	var counts: Dictionary = {"player": 0, "enemy": 0, "neutral": 0, "rebel": 0}
	for entry in entries:
		var kind: String = String(entry.get("type", ""))
		if kind == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			counts["player"] += 1
		elif kind == LevelConfig.PROVINCE_TYPE_NEUTRAL:
			counts["neutral"] += 1
		elif int(entry.get("faction_id", 0)) == 9000:
			counts["rebel"] += 1
		else:
			counts["enemy"] += 1
	return counts


func _run_tests() -> void:
	var flow = TutorialFlow.new()
	var entries: Array[Dictionary] = flow._build_opening_gameplay_tutorial_initial_entries()
	_check(entries.size() == 6, "Expected exactly six starting provinces.")
	var counts: Dictionary = _ownership(entries)
	_check(counts == {"player": 1, "enemy": 3, "neutral": 1, "rebel": 1}, "Incorrect starting ownership: %s" % str(counts))
	var by_id: Dictionary = {}
	for entry in entries:
		var id: int = int(entry.get("id", -1))
		_check(not by_id.has(id), "Duplicate province ID %d." % id)
		by_id[id] = entry
		_check(int(entry.get("encounter_level", -1)) == 1, "Province %d must have a fixed encounter level." % id)
		_check(int(entry.get("encounter_seed", 0)) > 0, "Province %d missing fixed encounter seed." % id)
		for neighbor_id in entry.get("neighbors", []):
			_check(int(neighbor_id) != id, "Province %d is adjacent to itself." % id)
	for entry in entries:
		for neighbor_id in entry.get("neighbors", []):
			if by_id.has(int(neighbor_id)):
				_check((by_id[int(neighbor_id)] as Dictionary).get("neighbors", []).has(int(entry.get("id", -1))), "Asymmetric neighbor link %d -> %d" % [int(entry.get("id", -1)), int(neighbor_id)])
			else:
				_check(false, "Neighbor %d is missing." % int(neighbor_id))
	_check(int((by_id.get(1, {}) as Dictionary).get("remaining_troops", 0)) == 6, "First battle must always start with six defenders.")
	_check(int((by_id.get(4, {}) as Dictionary).get("faction_id", -1)) == 9000, "Tutorial Rebel uses wrong faction ID.")
	_check((by_id.get(1, {}) as Dictionary).get("neighbors", []).has(4), "The guided Rebel march must be adjacent.")
	_check((by_id.get(3, {}) as Dictionary).get("neighbors", []).has(2), "AI neutral capture must be adjacent.")
	var layout: Array[Dictionary] = flow._build_opening_gameplay_tutorial_province_layout(entries)
	_check(layout.size() == 6, "Expected six fixed map polygons.")
	var polygon_by_id: Dictionary = {}
	var minimum: Vector2 = Vector2(INF, INF)
	var maximum: Vector2 = Vector2(-INF, -INF)
	for data in layout:
		var poly: PackedVector2Array = data.get("polygon", PackedVector2Array())
		var id: int = int(data.get("id", -1))
		polygon_by_id[id] = poly
		_check(poly.size() == 12, "Tutorial province %d should have winding, non-rectangular boundaries." % id)
		_check(Geometry2D.triangulate_polygon(poly).size() > 0, "Tutorial province %d polygon cannot be triangulated." % id)
		for point in poly:
			minimum = minimum.min(point)
			maximum = maximum.max(point)
	_check(maximum.x - minimum.x > 3500.0, "Tutorial map is still too narrow.")
	_check(maximum.y - minimum.y > 3800.0, "Tutorial map is still too short.")
	# Shared borders must match exactly in both province polygons. Otherwise
	# visual cracks and spurious barrier collision gaps can appear.
	for entry in entries:
		var id: int = int(entry.get("id", -1))
		var poly: PackedVector2Array = polygon_by_id.get(id, PackedVector2Array())
		for neighbor_id_any in entry.get("neighbors", []):
			var neighbor_id: int = int(neighbor_id_any)
			var other: PackedVector2Array = polygon_by_id.get(neighbor_id, PackedVector2Array())
			var common_points: int = 0
			for p in poly:
				if other.has(p):
					common_points += 1
			_check(common_points >= 4, "Province %d and neighbor %d have a mismatched jagged border." % [id, neighbor_id])
	var generator = LevelGeneratorScript.new()
	var tutorial_battle: Dictionary = generator.build_opening_tutorial_first_engagement_layout(440502, 1)
	var tutorial_battle_again: Dictionary = generator.build_opening_tutorial_first_engagement_layout(440502, 1)
	_check(tutorial_battle == tutorial_battle_again, "Retry battle must start from an identical layout.")
	_check((tutorial_battle.get("pins", []) as Array).size() == 6, "First engagement must have exactly six enemies.")
	for key in ["obstacles", "water_zones", "templates", "buildings", "grade_zones"]:
		_check((tutorial_battle.get(key, []) as Array).is_empty(), "Tutorial should not contain '%s' obstacles." % key)
	var pin_positions: Array[Vector2] = []
	for pin_any in tutorial_battle.get("pins", []):
		var pin: Dictionary = pin_any
		var pos: Vector2 = pin.get("pos", Vector2.ZERO)
		pin_positions.append(pos)
		_check(pos.distance_to(Vector2(0.0, -131.0)) <= 65.0, "Pin too far from compact target cluster.")
		_check(String(pin.get("type", "")) == LevelConfig.ENEMY_PIN, "First battle should use basic pins only.")
	for i in range(pin_positions.size()):
		for j in range(i + 1, pin_positions.size()):
			_check(pin_positions[i].distance_to(pin_positions[j]) >= 45.0, "Tutorial enemies overlap at spawn.")
	# Verify all displayed stage handoffs without invoking a rendered game.
	var main := Node.new()
	main.set_meta("opening_gameplay_tutorial_active", true)
	main.set_meta("opening_gameplay_tutorial_stage", "aim")
	flow.setup(main)
	_check(flow.get_opening_gameplay_tutorial_stage() == "aim", "Tutorial did not initialize at aim.")
	_check(flow.should_use_opening_tutorial_first_engagement_layout(1, LevelConfig.PHASE_OFFENSIVE, 6),
		"The first attempt must select the clustered tutorial engagement, even if the stage is still aim.")
	_check(not flow.should_use_opening_tutorial_first_engagement_layout(3, LevelConfig.PHASE_OFFENSIVE, 6),
		"Other enemy provinces must use their normal engagement layouts.")
	_check(not flow.should_use_opening_tutorial_first_engagement_layout(1, LevelConfig.PHASE_OFFENSIVE, 5),
		"Tutorial first engagement layout should be limited to the six-defender fixture.")
	flow.on_opening_tutorial_target_entered()
	_check(flow.get_opening_gameplay_tutorial_stage() == "battle", "Correct map landing did not start battle.")
	_check(flow.should_use_opening_tutorial_first_engagement_layout(1, LevelConfig.PHASE_OFFENSIVE, 6),
		"First attempt and retry should both use the same tutorial layout.")
	# Exercise the real generator entrypoint, rather than only its layout-data
	# builder. This regression catches a stage-ordering bug that previously
	# rendered an entire normal battlefield on the first tutorial shot.
	var scene_root := Node2D.new()
	var terrain_root := Node2D.new()
	var obstacle_root := Node2D.new()
	var pin_root := Node2D.new()
	root.add_child(scene_root)
	scene_root.add_child(terrain_root)
	scene_root.add_child(obstacle_root)
	scene_root.add_child(pin_root)
	var generated: Dictionary = generator.generate_into(
		440502, 1, terrain_root, obstacle_root, pin_root, null,
		LevelConfig.PHASE_OFFENSIVE, 0, 6,
		LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL, [],
		flow.should_use_opening_tutorial_first_engagement_layout(1, LevelConfig.PHASE_OFFENSIVE, 6)
	)
	_check(bool(generated.get("opening_tutorial_first_battle", false)),
		"Actual generator did not select the special tutorial layout.")
	_check(pin_root.get_child_count() == 6, "Actual first engagement must spawn exactly six pins.")
	_check(terrain_root.get_child_count() == 0, "Actual first engagement must not spawn water or terrain.")
	_check(obstacle_root.get_child_count() == 0, "Actual first engagement must not spawn hard blockers.")
	scene_root.free()
	flow.on_opening_tutorial_first_battle_conquered()
	_check(flow.get_opening_gameplay_tutorial_stage() == "ai", "First conquest did not advance to AI.")
	_check(not flow.should_use_opening_tutorial_first_engagement_layout(1, LevelConfig.PHASE_OFFENSIVE, 6),
		"Later battles must not use the initial guided layout.")
	main.set_meta("opening_gameplay_tutorial_stage", "order")
	flow.on_opening_tutorial_rebel_captured()
	_check(flow.get_opening_gameplay_tutorial_stage() == "free", "Rebel conquest did not start free play.")
	main.free()
	if errors.is_empty():
		print("OPENING_TUTORIAL_TEST_OK six provinces and guided stages")
		quit(0)
	else:
		for message in errors:
			push_error("Opening tutorial: " + message)
		quit(1)
