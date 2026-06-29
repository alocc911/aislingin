extends RefCounted

const LevelConfig = preload("res://scripts/LevelConfig.gd")

var _main: Node = null
var _engagement_letterbox_root: Control = null
var _engagement_letterbox_top: ColorRect = null
var _engagement_letterbox_bottom: ColorRect = null
var _engagement_letterbox_left: ColorRect = null
var _engagement_letterbox_right: ColorRect = null


func setup(main_node: Node) -> void:
	_main = main_node
	_ensure_engagement_letterbox_nodes()


func _is_grand_map_phase() -> bool:
	if _main == null:
		return false
	return _main._current_phase == LevelConfig.PHASE_GRAND_MAP or _main._current_phase == "grand_map"


func _get_phase_playable_half_extents() -> Vector2:
	return LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS if _is_grand_map_phase() else LevelConfig.PLAYABLE_HALF_EXTENTS


func _get_phase_target_size() -> Vector2:
	return LevelConfig.GRAND_MAP_PLAYABLE_SIZE if _is_grand_map_phase() else LevelConfig.PLAYABLE_SIZE


func _get_phase_wall_inset() -> float:
	return LevelConfig.GRAND_MAP_WALL_INSET if _is_grand_map_phase() else LevelConfig.WORLD_WALL_INSET


func _get_phase_fit_zoom(avail_w: float, avail_h: float) -> float:
	var target_size: Vector2 = _get_phase_target_size()
	var z_w: float = avail_w / target_size.x
	var z_h: float = avail_h / target_size.y
	var z: float = minf(z_w, z_h)
	if _is_grand_map_phase():
		return maxf(0.0001, z)
	return clampf(z, 0.20, 3.0)


func _get_engagement_screen_shift(rendered_playable_size: Vector2, bar_h: float) -> Vector2:
	if _main == null or _is_grand_map_phase():
		return Vector2.ZERO

	var vp_size: Vector2 = _main.get_viewport().get_visible_rect().size
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		return Vector2.ZERO

	var board_rect := Rect2((vp_size - rendered_playable_size) * 0.5, rendered_playable_size)
	var bar_rect := Rect2(0.0, vp_size.y - maxf(0.0, bar_h), 0.0, maxf(0.0, bar_h))
	if _main.ui != null and _main.ui.has_method("get_bottom_bar_rect"):
		bar_rect = _main.ui.call("get_bottom_bar_rect")

	if bar_rect.size.x <= 1.0 or bar_rect.size.y <= 1.0:
		return Vector2.ZERO

	var padding: float = 12.0
	var vertical_overlap: bool = board_rect.position.y < bar_rect.end.y - padding and board_rect.end.y > bar_rect.position.y + padding
	var horizontal_overlap: bool = board_rect.position.x < bar_rect.end.x + padding and board_rect.end.x > bar_rect.position.x
	if not vertical_overlap or not horizontal_overlap:
		return Vector2.ZERO

	var desired_left: float = bar_rect.end.x + padding
	var wanted_shift_x: float = maxf(0.0, desired_left - board_rect.position.x)
	var max_shift_x: float = maxf(0.0, vp_size.x - board_rect.end.x)
	return Vector2(minf(wanted_shift_x, max_shift_x), 0.0)


func _apply_camera_position(bar_h: float) -> void:
	if _main == null or _main.camera_2d == null:
		return

	var camera_pos: Vector2 = _main.camera_pan_offset
	if _is_grand_map_phase():
		camera_pos.y += get_bottom_bar_world_offset(bar_h)
	else:
		var zoom_value: float = _main.camera_2d.zoom.x
		if zoom_value > 0.0001:
			var rendered_playable_size: Vector2 = LevelConfig.PLAYABLE_SIZE * zoom_value
			var screen_shift: Vector2 = _get_engagement_screen_shift(rendered_playable_size, bar_h)
			camera_pos -= screen_shift / zoom_value
	_main.camera_2d.position = camera_pos


func _should_restore_saved_grand_map_camera() -> bool:
	if _main == null:
		return false
	if not _is_grand_map_phase():
		return false
	if _main._camera_follow_active:
		return false
	if not bool(_main._has_saved_grand_map_camera):
		return false

	var neutral_zoom: bool = absf(_main.current_camera_zoom - 1.0) <= 0.0001
	var neutral_pan: bool = _main.camera_pan_offset.length_squared() <= 0.0001
	var invalid_zoom: bool = _main.current_camera_zoom < maxf(0.0001, _main._grand_map_fit_zoom) - 0.0001

	return (neutral_zoom and neutral_pan) or invalid_zoom


func clamp_camera_pan() -> void:
	if _main == null:
		return
	if _main._camera_follow_active:
		return

	var half_visible: Vector2 = _main._current_playable_half_extents
	var phase_half_extents: Vector2 = _get_phase_playable_half_extents()
	var max_pan_x: float = maxf(0.0, phase_half_extents.x - half_visible.x)
	var max_pan_y: float = maxf(0.0, phase_half_extents.y - half_visible.y)

	if max_pan_x <= 0.001:
		_main.camera_pan_offset.x = 0.0
	else:
		_main.camera_pan_offset.x = clampf(_main.camera_pan_offset.x, -max_pan_x, max_pan_x)

	if max_pan_y <= 0.001:
		_main.camera_pan_offset.y = 0.0
	else:
		_main.camera_pan_offset.y = clampf(_main.camera_pan_offset.y, -max_pan_y, max_pan_y)


func sync_runtime_bounds_to_camera() -> void:
	if _main == null:
		return
	if _main._camera_follow_active:
		return

	var use_grand: bool = _is_grand_map_phase()
	var half_ext: Vector2 = LevelConfig.GRAND_MAP_HALF_EXTENTS if use_grand else LevelConfig.WORLD_HALF_EXTENTS
	var wall_thickness: float = LevelConfig.GRAND_MAP_WALL_THICKNESS if use_grand else LevelConfig.WORLD_WALL_THICKNESS

	if _main.wall_top:
		_main.wall_top.position.y = -half_ext.y
	if _main.wall_bottom:
		_main.wall_bottom.position.y = half_ext.y
	if _main.wall_left:
		_main.wall_left.position.x = -half_ext.x
	if _main.wall_right:
		_main.wall_right.position.x = half_ext.x

	var horizontal_span: float = half_ext.x * 2.0 + wall_thickness * 2.0
	var vertical_span: float = half_ext.y * 2.0 + wall_thickness * 2.0

	if _main.wall_top_shape and _main.wall_top_shape.shape is RectangleShape2D:
		(_main.wall_top_shape.shape as RectangleShape2D).size = Vector2(horizontal_span, wall_thickness)
	if _main.wall_bottom_shape and _main.wall_bottom_shape.shape is RectangleShape2D:
		(_main.wall_bottom_shape.shape as RectangleShape2D).size = Vector2(horizontal_span, wall_thickness)
	if _main.wall_left_shape and _main.wall_left_shape.shape is RectangleShape2D:
		(_main.wall_left_shape.shape as RectangleShape2D).size = Vector2(wall_thickness, vertical_span)
	if _main.wall_right_shape and _main.wall_right_shape.shape is RectangleShape2D:
		(_main.wall_right_shape.shape as RectangleShape2D).size = Vector2(wall_thickness, vertical_span)
	_update_playable_edge_line()


func _update_playable_edge_line() -> void:
	if _main == null or _main.playable_edge_line == null:
		return
	var show_for_engagement: bool = not _is_grand_map_phase()
	_main.playable_edge_line.visible = show_for_engagement
	if not show_for_engagement:
		return
	var half_playable: Vector2 = LevelConfig.PLAYABLE_HALF_EXTENTS
	_main.playable_edge_line.points = PackedVector2Array([
		Vector2(-half_playable.x, -half_playable.y),
		Vector2(half_playable.x, -half_playable.y),
		Vector2(half_playable.x, half_playable.y),
		Vector2(-half_playable.x, half_playable.y),
		Vector2(-half_playable.x, -half_playable.y)
	])


func update_runtime_playable_extents() -> void:
	if _main == null or _main.camera_2d == null:
		return
	if _main._camera_follow_active:
		return

	if not _is_grand_map_phase():
		# Engagements must keep a fixed playable footprint on every device.
		# Do not expand gameplay bounds to fill the viewport.
		_main._current_wall_center_half_extents = LevelConfig.WORLD_HALF_EXTENTS
		_main._current_playable_half_extents = LevelConfig.PLAYABLE_HALF_EXTENTS
		sync_runtime_bounds_to_camera()
		return

	var vp_size: Vector2 = _main.get_viewport().get_visible_rect().size
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		return

	var bar_h: float = 0.0
	if _main.ui and _main.ui.has_method("get_bottom_bar_height"):
		bar_h = float(_main.ui.call("get_bottom_bar_height"))

	var avail_w: float = float(vp_size.x)
	var avail_h: float = maxf(1.0, float(vp_size.y))
	if _is_grand_map_phase():
		avail_h = maxf(1.0, float(vp_size.y) - bar_h)
	var z: float = _main.camera_2d.zoom.x
	if z <= 0.0001:
		return

	_main._current_wall_center_half_extents = Vector2(avail_w / (2.0 * z), avail_h / (2.0 * z))

	var wall_inset: float = _get_phase_wall_inset()
	_main._current_playable_half_extents = _main._current_wall_center_half_extents - Vector2(wall_inset, wall_inset)
	_main._current_playable_half_extents.x = maxf(1.0, _main._current_playable_half_extents.x)
	_main._current_playable_half_extents.y = maxf(1.0, _main._current_playable_half_extents.y)

	sync_runtime_bounds_to_camera()


func get_bottom_bar_world_offset(bar_h: float) -> float:
	if _main == null or _main.camera_2d == null:
		return 0.0
	if _main.camera_2d.zoom.y <= 0.0001:
		return 0.0
	return (bar_h * 0.5) / _main.camera_2d.zoom.y


func apply_camera_fit() -> void:
	if _main == null or _main.camera_2d == null:
		return
	if _main._camera_follow_active:
		var follow_bar_h: float = 0.0
		if _main.ui and _main.ui.has_method("get_bottom_bar_height"):
			follow_bar_h = float(_main.ui.call("get_bottom_bar_height"))
		_refresh_engagement_letterbox(follow_bar_h)
		return

	var vp_size: Vector2 = _main.get_viewport().get_visible_rect().size
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		return

	var bar_h: float = 0.0
	if _main.ui and _main.ui.has_method("get_bottom_bar_height"):
		bar_h = float(_main.ui.call("get_bottom_bar_height"))

	var avail_w: float = float(vp_size.x)
	var avail_h: float = maxf(1.0, float(vp_size.y))
	if _is_grand_map_phase():
		avail_h = maxf(1.0, float(vp_size.y) - bar_h)

	if _is_grand_map_phase():
		_main._grand_map_fit_zoom = _get_phase_fit_zoom(avail_w, avail_h)

		if _should_restore_saved_grand_map_camera() and _main.has_method("_restore_saved_grand_map_camera_state"):
			_main._restore_saved_grand_map_camera_state()

		_main.current_camera_zoom = clampf(_main.current_camera_zoom, _main._grand_map_fit_zoom, LevelConfig.GRAND_MAP_CAMERA_MAX_ZOOM)
		_main.camera_2d.zoom = Vector2(_main.current_camera_zoom, _main.current_camera_zoom)
	else:
		var fit_zoom: float = _get_phase_fit_zoom(avail_w, avail_h)

		# Engagements must always open and remain at the standard fully zoomed-out fit.
		# Never inherit prior grand-map zoom or pan.
		_main.camera_pan_offset = Vector2.ZERO
		_main.current_camera_zoom = fit_zoom
		_main.camera_2d.zoom = Vector2(fit_zoom, fit_zoom)

	update_runtime_playable_extents()
	clamp_camera_pan()

	if _is_grand_map_phase() and _main.level_flow != null:
		_main.level_flow.call_deferred("force_grand_map_wall_reset")

	_apply_camera_position(bar_h)
	_refresh_engagement_letterbox(bar_h)

	if _is_grand_map_phase() and _main.has_method("_store_current_grand_map_camera_state"):
		_main._store_current_grand_map_camera_state()


func on_viewport_size_changed() -> void:
	if _main == null:
		return
	if _main._camera_follow_active:
		var follow_bar_h: float = 0.0
		if _main.ui and _main.ui.has_method("get_bottom_bar_height"):
			follow_bar_h = float(_main.ui.call("get_bottom_bar_height"))
		_refresh_engagement_letterbox(follow_bar_h)
		return

	call_deferred("apply_camera_fit")
	var resize_timer: SceneTreeTimer = _main.get_tree().create_timer(0.12)
	resize_timer.timeout.connect(Callable(self, "apply_camera_fit"))

	if _is_grand_map_phase() and _main.level_flow != null:
		_main.level_flow.call_deferred("force_grand_map_wall_reset")


func on_ui_bottom_bar_resized(height: float) -> void:
	if _main != null and _main._camera_follow_active:
		_refresh_engagement_letterbox(height)
		return
	call_deferred("apply_camera_fit")


func update_ball_follow(delta: float) -> void:
	if _main == null:
		return
	if not _main.ball or not is_instance_valid(_main.ball):
		return

	var target_pos: Vector2 = _main.ball.global_position + Vector2(0.0, LevelConfig.CAMERA_FOLLOW_LEAD_OFFSET_Y)
	_main.camera_2d.position = _main.camera_2d.position.lerp(target_pos, LevelConfig.CAMERA_FOLLOW_LERP_SPEED * delta)


func _ensure_engagement_letterbox_nodes() -> void:
	if _main == null or _main.ui == null or not is_instance_valid(_main.ui):
		return
	if _engagement_letterbox_root != null and is_instance_valid(_engagement_letterbox_root):
		return

	var existing_root: Node = _main.ui.get_node_or_null("EngagementLetterboxRoot")
	if existing_root is Control:
		_engagement_letterbox_root = existing_root as Control
		_engagement_letterbox_top = _engagement_letterbox_root.get_node_or_null("Top") as ColorRect
		_engagement_letterbox_bottom = _engagement_letterbox_root.get_node_or_null("Bottom") as ColorRect
		_engagement_letterbox_left = _engagement_letterbox_root.get_node_or_null("Left") as ColorRect
		_engagement_letterbox_right = _engagement_letterbox_root.get_node_or_null("Right") as ColorRect
		if _engagement_letterbox_top != null and _engagement_letterbox_bottom != null and _engagement_letterbox_left != null and _engagement_letterbox_right != null:
			return
		_engagement_letterbox_root.queue_free()
		_engagement_letterbox_root = null
		_engagement_letterbox_top = null
		_engagement_letterbox_bottom = null
		_engagement_letterbox_left = null
		_engagement_letterbox_right = null

	_engagement_letterbox_root = Control.new()
	_engagement_letterbox_root.name = "EngagementLetterboxRoot"
	_engagement_letterbox_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_engagement_letterbox_root.visible = false
	_engagement_letterbox_root.position = Vector2.ZERO
	_main.ui.add_child(_engagement_letterbox_root)
	_main.ui.move_child(_engagement_letterbox_root, 0)

	_engagement_letterbox_top = _make_letterbox_bar("Top")
	_engagement_letterbox_bottom = _make_letterbox_bar("Bottom")
	_engagement_letterbox_left = _make_letterbox_bar("Left")
	_engagement_letterbox_right = _make_letterbox_bar("Right")

	_engagement_letterbox_root.add_child(_engagement_letterbox_top)
	_engagement_letterbox_root.add_child(_engagement_letterbox_bottom)
	_engagement_letterbox_root.add_child(_engagement_letterbox_left)
	_engagement_letterbox_root.add_child(_engagement_letterbox_right)


func _make_letterbox_bar(bar_name: String) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.name = bar_name
	rect.color = Color.BLACK
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = Vector2.ZERO
	rect.size = Vector2.ZERO
	return rect


func _refresh_engagement_letterbox(bar_h: float) -> void:
	_ensure_engagement_letterbox_nodes()
	if _engagement_letterbox_root == null or not is_instance_valid(_engagement_letterbox_root):
		return
	if _main == null:
		_engagement_letterbox_root.visible = false
		return

	var vp_size: Vector2 = _main.get_viewport().get_visible_rect().size
	_engagement_letterbox_root.position = Vector2.ZERO
	_engagement_letterbox_root.size = vp_size

	if _is_grand_map_phase():
		_engagement_letterbox_root.visible = false
		return

	var avail_w: float = maxf(0.0, vp_size.x)
	var avail_h: float = maxf(0.0, vp_size.y)
	if avail_w <= 0.0 or avail_h <= 0.0:
		_engagement_letterbox_root.visible = false
		return

	var zoom_value: float = 0.0
	if _main.camera_2d != null:
		zoom_value = _main.camera_2d.zoom.x
	if zoom_value <= 0.0001:
		zoom_value = _get_phase_fit_zoom(avail_w, avail_h)

	var rendered_playable_size: Vector2 = LevelConfig.PLAYABLE_SIZE * zoom_value
	var screen_shift: Vector2 = _get_engagement_screen_shift(rendered_playable_size, bar_h)
	var board_pos: Vector2 = ((vp_size - rendered_playable_size) * 0.5) + screen_shift

	var left_w: float = maxf(0.0, floorf(board_pos.x))
	var right_w: float = maxf(0.0, ceilf(vp_size.x - board_pos.x - rendered_playable_size.x))
	var top_h: float = maxf(0.0, floorf(board_pos.y))
	var bottom_h: float = maxf(0.0, ceilf(vp_size.y - board_pos.y - rendered_playable_size.y))

	_engagement_letterbox_top.position = Vector2(0.0, 0.0)
	_engagement_letterbox_top.size = Vector2(vp_size.x, top_h)

	_engagement_letterbox_bottom.position = Vector2(0.0, vp_size.y - bottom_h)
	_engagement_letterbox_bottom.size = Vector2(vp_size.x, bottom_h)

	_engagement_letterbox_left.position = Vector2(0.0, 0.0)
	_engagement_letterbox_left.size = Vector2(left_w, vp_size.y)

	_engagement_letterbox_right.position = Vector2(vp_size.x - right_w, 0.0)
	_engagement_letterbox_right.size = Vector2(right_w, vp_size.y)

	_engagement_letterbox_root.visible = left_w > 0.0 or right_w > 0.0 or top_h > 0.0 or bottom_h > 0.0
