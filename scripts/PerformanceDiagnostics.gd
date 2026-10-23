extends CanvasLayer
## Opt-in WebGL investigation HUD. F9 toggles, F8 isolates Grand Map layers,
## F7 prints a fresh one-context JSON snapshot. No tracing when switched off.
const REFRESH_SECONDS: float = 0.85
const LOG_SECONDS: float = 7.0
const MAX_SAMPLES: int = 240
const WARMUP_SECONDS: float = 1.0
const ISOLATION_MODES: Array[String] = [
	"normal",
	"troop_icons_off",
	"info_panels_off",
	"borders_off",
	"province_overlays_off",
	"shared_borders_off",
	"background_sprites_off",
	"terrain_zones_off",
	"map_obstacles_off",
	"all_provinces_off",
	"world_except_provinces_off",
	"all_map_visuals_off"
]

var _main: Node = null
var _enabled: bool = false
var _panel: PanelContainer = null
var _label: Label = null
var _context: String = ""
var _samples: Array[float] = []
var _window_elapsed: float = 0.0
var _display_elapsed: float = 0.0
var _log_elapsed: float = 0.0
var _isolation_index: int = 0
var _hidden_nodes: Dictionary = {}
var _recent_transition: String = "none"
var _snapshot_number: int = 0


func setup(main_node: Node) -> void:
	_main = main_node


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.position = Vector2(8.0, 65.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.08, 0.11, 0.88)
	bg.content_margin_left = 9.0
	bg.content_margin_right = 9.0
	bg.content_margin_top = 6.0
	bg.content_margin_bottom = 6.0
	_panel.add_theme_stylebox_override("panel", bg)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(_label)
	add_child(_panel)
	_panel.visible = false
	set_process(false)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_F9:
		_set_enabled(not _enabled)
		get_viewport().set_input_as_handled()
	elif _enabled and key.keycode == KEY_F7:
		_log_snapshot()
		get_viewport().set_input_as_handled()
	elif _enabled and key.keycode == KEY_F8:
		_cycle_isolation()
		get_viewport().set_input_as_handled()


func _set_enabled(value: bool) -> void:
	_enabled = value
	_panel.visible = value
	_reset_samples()
	if not value:
		_isolation_index = 0
		_restore_visuals()
	set_process(value)
	if value:
		print("[Perf] Diagnostics on. F7 JSON snapshot, F8 Grand Map render isolation, F9 off.")
	else:
		print("[Perf] Diagnostics off; original visual visibility restored.")


func _reset_samples() -> void:
	_samples.clear()
	_window_elapsed = 0.0
	_display_elapsed = 0.0
	_log_elapsed = 0.0
	_context = ""


func _cycle_isolation() -> void:
	if _main == null or String(_main.get("_current_phase")) != "grand_map":
		print("[Perf] F8 visual isolation requires Grand Map mode.")
		return
	_isolation_index = (_isolation_index + 1) % ISOLATION_MODES.size()
	_restore_visuals()
	_apply_visual_isolation()
	_reset_samples()
	print("[Perf] ISOLATION: ", ISOLATION_MODES[_isolation_index], " (wait a few seconds, then F7)")


func _restore_visuals() -> void:
	for saved_any in _hidden_nodes.values():
		var saved: Array = saved_any as Array
		var node: CanvasItem = saved[0] as CanvasItem
		if is_instance_valid(node):
			node.visible = bool(saved[1])
	_hidden_nodes.clear()


func _hide_item(item: CanvasItem) -> void:
	if item == null or not is_instance_valid(item):
		return
	var id: int = item.get_instance_id()
	if not _hidden_nodes.has(id):
		_hidden_nodes[id] = [item, item.visible]
	item.visible = false


func _hide_matching_background_sprites(node: Node) -> void:
	# Background texture/sprite pass in the Zone/World scene tree, leaving
	# polygon and line geometry enabled for the next F8 test.
	if node is Sprite2D or node is TextureRect or node is NinePatchRect:
		_hide_item(node as CanvasItem)
	for child in node.get_children():
		_hide_matching_background_sprites(child)


func _hide_province_overlay_nodes(node: Node) -> void:
	for child in node.get_children():
		var name_text: String = String(child.name).to_lower()
		if child is CanvasItem and ("overlay" in name_text or "pattern" in name_text):
			_hide_item(child as CanvasItem)


func _apply_visual_isolation() -> void:
	if _main == null or not is_instance_valid(_main):
		return
	if String(_main.get("_current_phase")) != "grand_map":
		_restore_visuals()
		return
	var mode: String = ISOLATION_MODES[_isolation_index]
	if mode == "normal":
		return
	var provinces: Node2D = _main.get("provinces_root") as Node2D
	var zones: Node2D = _main.get("zones_root") as Node2D
	var obstacles: Node2D = _main.get("obstacles_root") as Node2D
	if mode == "all_provinces_off":
		_hide_item(provinces)
		return
	if mode == "world_except_provinces_off":
		_hide_item(zones)
		_hide_item(obstacles)
		_hide_item(_main.get_node_or_null("World/Bounds") as CanvasItem)
		return
	if mode == "all_map_visuals_off":
		_hide_item(provinces)
		_hide_item(zones)
		_hide_item(obstacles)
		_hide_item(_main.get_node_or_null("World/Bounds") as CanvasItem)
		return
	if mode == "terrain_zones_off":
		_hide_item(zones)
		return
	if mode == "map_obstacles_off":
		_hide_item(obstacles)
		return
	if mode == "background_sprites_off":
		if zones != null:
			_hide_matching_background_sprites(zones)
		var world: Node = _main.get_node_or_null("World")
		if world != null:
			for item in world.get_children():
				if item == provinces or item == obstacles or item == zones:
					continue
				_hide_matching_background_sprites(item)
		return
	if provinces == null:
		return
	if mode == "shared_borders_off":
		_hide_item(provinces.get_node_or_null("SharedProvinceBorderOverlay") as CanvasItem)
		return
	for province in provinces.get_children():
		if not (province is Node2D) or not String(province.name).begins_with("Province_"):
			continue
		if mode == "troop_icons_off":
			_hide_item(province.get_node_or_null("ProvinceTroopVisuals") as CanvasItem)
		elif mode == "info_panels_off":
			_hide_item(province.get_node_or_null("ProvinceInfoPanelRoot") as CanvasItem)
		elif mode == "borders_off":
			for border_name in ["ProvinceBorder", "ProvinceInnerGlow"]:
				_hide_item(province.get_node_or_null(border_name) as CanvasItem)
		elif mode == "province_overlays_off":
			_hide_province_overlay_nodes(province)


func _get_context() -> String:
	if _main == null or not is_instance_valid(_main):
		return "transition"
	if String(_main.get("_current_phase")) == "grand_map":
		if bool(_main.get("pan_dragging")) or bool(_main.get("dragging")) or bool(_main.get("_camera_follow_active")):
			return "grand_map_motion"
		return "grand_map_idle"
	if int(_main.get("state")) == int(_main.GameState.BALL_IN_FLIGHT):
		return "engagement_flight"
	return "engagement_other"


func _process(delta: float) -> void:
	var next_context: String = _get_context()
	if next_context != _context:
		_context = next_context
		_samples.clear()
		_window_elapsed = 0.0
		_log_elapsed = 0.0
		_apply_visual_isolation()
		print("[Perf] Context: ", _context, " | isolation=", ISOLATION_MODES[_isolation_index])
	_window_elapsed += delta
	_display_elapsed += delta
	_log_elapsed += delta
	if _window_elapsed > WARMUP_SECONDS:
		_samples.append(maxf(0.0, delta) * 1000.0)
		if _samples.size() > MAX_SAMPLES:
			_samples.pop_front()
	if _display_elapsed >= REFRESH_SECONDS:
		_display_elapsed = 0.0
		_update_display()
	if _log_elapsed >= LOG_SECONDS:
		_log_elapsed = 0.0
		_log_snapshot()


func _stats() -> Dictionary:
	if _samples.is_empty():
		return {"count": 0, "mean_ms": 0.0, "p95_ms": 0.0}
	var sorted_samples: Array[float] = _samples.duplicate()
	sorted_samples.sort()
	var sum_ms: float = 0.0
	for sample in _samples:
		sum_ms += sample
	var percentile_index: int = clampi(ceili(float(sorted_samples.size()) * 0.95) - 1, 0, sorted_samples.size() - 1)
	return {"count": _samples.size(), "mean_ms": snappedf(sum_ms / _samples.size(), 0.01), "p95_ms": snappedf(sorted_samples[percentile_index], 0.01)}


func _metrics() -> Dictionary:
	var province_nodes: int = 0
	var troop_draw_nodes: int = 0
	var troop_instances: int = 0
	var info_panels: int = 0
	var shared_border_nodes: int = 0
	var zone_nodes: int = 0
	var obstacle_nodes: int = 0
	if _main != null and is_instance_valid(_main):
		var provinces: Node = _main.get("provinces_root") as Node
		if provinces != null:
			var shared: Node = provinces.get_node_or_null("SharedProvinceBorderOverlay")
			if shared != null:
				shared_border_nodes = shared.get_child_count()
			for province in provinces.get_children():
				if not String(province.name).begins_with("Province_"):
					continue
				province_nodes += 1
				var troops: Node = province.get_node_or_null("ProvinceTroopVisuals")
				if troops != null:
					troop_draw_nodes += troops.get_child_count()
					var batch: MultiMeshInstance2D = troops.get_node_or_null("ProvinceTroopBatch") as MultiMeshInstance2D
					if batch != null and batch.multimesh != null:
						troop_instances += batch.multimesh.instance_count
					else:
						troop_instances += troops.get_child_count()
				if province.get_node_or_null("ProvinceInfoPanelRoot") != null:
					info_panels += 1
		var zones: Node = _main.get("zones_root") as Node
		if zones != null:
			zone_nodes = zones.get_child_count()
		var obstacles: Node = _main.get("obstacles_root") as Node
		if obstacles != null:
			obstacle_nodes = obstacles.get_child_count()
	return {
		"fps_engine": Engine.get_frames_per_second(),
		"process_ms": snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01),
		"physics_ms": snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"render_objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"render_primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"physics_2d_active": int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)),
		"physics_2d_pairs": int(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)),
		"memory_static_mib": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"video_memory_mib": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"viewport_px": str(get_viewport().get_visible_rect().size),
		"province_count": province_nodes,
		"troop_draw_nodes": troop_draw_nodes,
		"troop_instances": troop_instances,
		"province_info_panels": info_panels,
		"shared_border_nodes": shared_border_nodes,
		"zone_roots": zone_nodes,
		"obstacle_roots": obstacle_nodes,
		"hidden_render_roots": _hidden_nodes.size()
	}


func _update_display() -> void:
	if _label == null:
		return
	var stats: Dictionary = _stats()
	var m: Dictionary = _metrics()
	_label.text = (
		"WEBGL DIAGNOSTICS (F7 log, F8 isolate, F9 off)\n"
		+ "Context: %s | %s\n" % [_context, ISOLATION_MODES[_isolation_index]]
		+ "FPS %d | avg %.1f ms | p95 %.1f ms | samples %d\n" % [m["fps_engine"], stats["mean_ms"], stats["p95_ms"], stats["count"]]
		+ "Process %.1f ms | Physics %.1f ms | 2D pairs %d\n" % [m["process_ms"], m["physics_ms"], m["physics_2d_pairs"]]
		+ "Draws %d | render objs %d | primitives %d\n" % [m["draw_calls"], m["render_objects"], m["render_primitives"]]
		+ "Nodes %d | provinces %d | troop batches %d / icons %d\n" % [m["node_count"], m["province_count"], m["troop_draw_nodes"], m["troop_instances"]]
		+ "RAM %.0f MiB | VRAM %.0f MiB | last: %s" % [m["memory_static_mib"], m["video_memory_mib"], _recent_transition]
	)


func record_generation(label_text: String, elapsed_usec: int) -> void:
	if not _enabled:
		return
	_recent_transition = "%s: %.1f ms" % [label_text, float(elapsed_usec) / 1000.0]
	print("[Perf] generation ", _recent_transition)


func _log_snapshot() -> void:
	if not _enabled:
		return
	_snapshot_number += 1
	var record: Dictionary = {
		"seq": _snapshot_number, "context": _context,
		"isolation": ISOLATION_MODES[_isolation_index],
		"frame": _stats(), "metrics": _metrics(), "last_generation": _recent_transition
	}
	print("[PerfSnapshot] ", JSON.stringify(record))
