extends Control
# Two-series, draw-only sparkline with fixed 0..100 happiness scale.
var _points: Array = []

func set_history(points: Array) -> void:
	_points = points.slice(maxi(0, points.size() - 20)).duplicate(true)
	queue_redraw()


func _draw() -> void:
	if _points.is_empty():
		return
	var left: float = 40.0
	var right: float = maxf(left + 90.0, size.x - 12.0)
	var top: float = 10.0
	var bottom: float = maxf(top + 80.0, size.y - 22.0)
	var font: Font = ThemeDB.fallback_font
	for value in [0, 50, 100]:
		var y: float = bottom - float(value) / 100.0 * (bottom - top)
		draw_line(Vector2(left, y), Vector2(right, y), Color(0.65, 0.62, 0.57, 0.27), 1.0)
		draw_string(font, Vector2(3.0, y + 5.0), str(value), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.86, 0.81, 0.73))
	for metric in ["natives", "outlanders"]:
		var line_color: Color = Color(0.30, 0.84, 0.60) if metric == "natives" else Color(1.0, 0.72, 0.28)
		var previous: Vector2 = Vector2.ZERO
		for i in range(_points.size()):
			var fraction: float = float(i) / float(maxi(1, _points.size() - 1))
			var value: float = clampf(float((_points[i] as Dictionary).get(metric, 0.0)), 0.0, 100.0)
			var position: Vector2 = Vector2(lerpf(left, right, fraction), lerpf(bottom, top, value / 100.0))
			if i > 0:
				draw_line(previous, position, line_color, 3.0, true)
			else:
				draw_circle(position, 2.5, line_color)
			previous = position
	draw_string(font, Vector2(left, size.y - 3.0), "Turn %d" % int((_points.front() as Dictionary).get("turn", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.86, 0.81, 0.73))
	draw_string(font, Vector2(right - 75.0, size.y - 3.0), "Turn %d" % int((_points.back() as Dictionary).get("turn", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.86, 0.81, 0.73))
