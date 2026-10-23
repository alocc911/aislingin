extends SceneTree

const WaterAreaRegistry = preload("res://scripts/WaterAreaRegistry.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var root_node: Window = root
	var first := Area2D.new()
	first.set_meta("zone_type", "water")
	first.set_meta("zone_radius", 120.0)
	root_node.add_child(first)
	WaterAreaRegistry.invalidate()
	var initial: Array[Area2D] = WaterAreaRegistry.get_water_areas(self)
	if not initial.has(first):
		failures.append("water_registry_does_not_find_first_zone")
	var repeated: Array[Area2D] = WaterAreaRegistry.get_water_areas(self)
	if repeated.size() != initial.size() or not repeated.has(first):
		failures.append("water_registry_could_not_reuse_result")
	var second := Area2D.new()
	second.set_meta("zone_type", "water")
	root_node.add_child(second)
	WaterAreaRegistry.invalidate()
	var refreshed: Array[Area2D] = WaterAreaRegistry.get_water_areas(self)
	if not refreshed.has(first) or not refreshed.has(second):
		failures.append("water_registry_does_not_discover_new_zone")
	first.queue_free()
	WaterAreaRegistry.invalidate()
	var without_first: Array[Area2D] = WaterAreaRegistry.get_water_areas(self)
	if without_first.has(first) or not without_first.has(second):
		failures.append("water_registry_returns_deleted_zone")
	WaterAreaRegistry.invalidate()
	print("PHASE 2 REGRESSION: ", JSON.stringify({"ok": failures.is_empty(), "failures": failures}))
	quit(0 if failures.is_empty() else 1)
