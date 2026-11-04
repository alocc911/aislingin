extends SceneTree

# Lightweight headless fixture: validates the fixed tutorial topology, starting
# balance, deterministic encounter layout, and guided stage transitions.
const TutorialFlow = preload("res://scripts/MainLevelFlow.gd")
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
	for data in layout:
		var poly: PackedVector2Array = data.get("polygon", PackedVector2Array())
		_check(poly.size() == 4, "Expected a quadrilateral province polygon.")
	# Verify all displayed stage handoffs without invoking a rendered game.
	var main := Node.new()
	main.set_meta("opening_gameplay_tutorial_active", true)
	main.set_meta("opening_gameplay_tutorial_stage", "aim")
	flow.setup(main)
	_check(flow.get_opening_gameplay_tutorial_stage() == "aim", "Tutorial did not initialize at aim.")
	flow.on_opening_tutorial_target_entered()
	_check(flow.get_opening_gameplay_tutorial_stage() == "battle", "Correct map landing did not start battle.")
	flow.on_opening_tutorial_first_battle_conquered()
	_check(flow.get_opening_gameplay_tutorial_stage() == "ai", "First conquest did not advance to AI.")
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
