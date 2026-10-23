extends CanvasLayer
## Browser-friendly, opt-in profiler. F9 toggles the HUD; F7 prints summary
## samples to the browser developer console (including transition timings).
## Disabled by default: no per-frame samples and no continuous logging.
const REFRESH_SECONDS: float = 0.75
const LOG_SECONDS: float = 5.0
const MAX_SAMPLES_PER_CONTEXT: int = 240

var _main: Node = null
var _enabled: bool = false
var _panel: PanelContainer = null
var _label: Label = null
var _context_samples: Dictionary = {}
var _elapsed: float = 0.0
var _log_elapsed: float = 0.0
var _recent_transition: String = "none"


func setup(main_node: Node) -> void:
	_main = main_node


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.position = Vector2(8.0, 66.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.08, 0.11, 0.87)
	bg.content_margin_left = 9.0
	bg.content_margin_right = 9.0
	bg.content_margin_top = 7.0
	bg.content_margin_bottom = 7.0
	_panel.add_theme_stylebox_override("panel", bg)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 15)
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
	elif key.keycode == KEY_F7 and _enabled:
		_log_snapshot()
		get_viewport().set_input_as_handled()


func _set_enabled(value: bool) -> void:
	_enabled = value
	_panel.visible = value
	_elapsed = 0.0
	_log_elapsed = 0.0
	_context_samples.clear()
	set_process(value)
	if value:
		print("[Perf] HUD enabled. F9 hides; F7 logs context summaries. Values are approximate.")


func _process(delta: float) -> void:
	var context: String = _get_context()
	var samples: Array = _context_samples.get(context, [])
	samples.append(maxf(delta, 0.0) * 1000.0)
	if samples.size() > MAX_SAMPLES_PER_CONTEXT:
		samples.pop_front()
	_context_samples[context] = samples
	_elapsed += delta
	_log_elapsed += delta
	if _elapsed >= REFRESH_SECONDS:
		_elapsed = 0.0
		_update_display(context, samples)
	if _log_elapsed >= LOG_SECONDS:
		_log_elapsed = 0.0
		_log_snapshot()


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


func _summarize(samples: Array) -> Dictionary:
	if samples.is_empty():
		return {"mean": 0.0, "p95": 0.0, "count": 0}
	var ordered: Array = samples.duplicate()
	ordered.sort()
	var total: float = 0.0
	for value in samples:
		total += float(value)
	var p95_index: int = clampi(int(ceil(float(ordered.size()) * 0.95)) - 1, 0, ordered.size() - 1)
	return {"mean": total / float(samples.size()), "p95": float(ordered[p95_index]), "count": samples.size()}


func _update_display(context: String, samples: Array) -> void:
	if _label == null:
		return
	var summary: Dictionary = _summarize(samples)
	var process_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var bodies: int = int(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS))
	var memory_mib: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	_label.text = (
		"PERFORMANCE (F9 hide / F7 log)\n"
		+ "Context: %s\n" % context
		+ "FPS: %d  frame avg: %.1f ms  p95: %.1f ms\n" % [Engine.get_frames_per_second(), float(summary.mean), float(summary.p95)]
		+ "Process: %.1f ms  physics: %.1f ms\n" % [process_ms, physics_ms]
		+ "Draw calls: %d  nodes: %d  active 2D: %d\n" % [draw_calls, nodes, bodies]
		+ "Static memory: %.1f MiB\n" % memory_mib
		+ "Last generation: %s" % _recent_transition
	)


func record_generation(label_text: String, elapsed_usec: int) -> void:
	if not _enabled:
		return
	_recent_transition = "%s: %.1f ms" % [label_text, float(elapsed_usec) / 1000.0]
	print("[Perf] generation ", _recent_transition)


func _log_snapshot() -> void:
	if not _enabled:
		return
	for context in _context_samples:
		var summary: Dictionary = _summarize(_context_samples[context])
		print("[Perf] %s: frame avg %.2f ms, p95 %.2f ms (%d samples)" % [String(context), float(summary.mean), float(summary.p95), int(summary.count)])
	print("[Perf] latest generation: ", _recent_transition)
