extends RefCounted

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const BallScene: PackedScene = preload("res://scenes/Ball.tscn")

var _main: Node = null
var _active_touch_positions: Dictionary = {}
var _active_touch_ids: Array[int] = []
var _pending_cancel_touch_id: int = -1
var _pending_cancel_touch_start_pos: Vector2 = Vector2.ZERO
var _pending_cancel_touch_max_move: float = 0.0
var _touch_drag_start_msec: int = 0

const TOUCH_CANCEL_TAP_MOVE_THRESHOLD_PIXELS: float = 18.0
const TOUCH_SINGLE_FINGER_COMMIT_DELAY_MSEC: int = 120


func setup(main_node: Node) -> void:
	_main = main_node
	_active_touch_positions.clear()
	_active_touch_ids.clear()
	_clear_pending_cancel_touch()
	if Input.has_method("set_emulate_mouse_from_touch"):
		Input.set_emulate_mouse_from_touch(true)


func handle_input(event: InputEvent) -> void:
	if _main == null:
		return

	_enforce_engagement_camera_lock_state()

	if _main._awaiting_engagement_summary_ack:
		if event is InputEventScreenTouch:
			var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
			if touch_event.pressed:
				if _is_summary_ack_pointer_over_ui(touch_event.position):
					return
				if _main.engagement_resolver != null:
					_main.engagement_resolver.finalize_engagement_summary_ack()
				_main.get_viewport().set_input_as_handled()
			return
		elif event is InputEventMouseButton:
			var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
			if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
				if _is_summary_ack_pointer_over_ui(mouse_button_event.position):
					return
				if _main.engagement_resolver != null:
					_main.engagement_resolver.finalize_engagement_summary_ack()
				_main.get_viewport().set_input_as_handled()
			return
		return

	if _main.is_paused or _main.state == _main.GameState.LEVEL_END or _main.state == _main.GameState.GAME_OVER:
		return

	if event is InputEventScreenTouch:
		handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		handle_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventPanGesture:
		handle_pan_gesture(event as InputEventPanGesture)


func process_drag_preview() -> void:
	if _main == null:
		return
	if not _main.dragging or _main.state != _main.GameState.DRAGGING:
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	var time_since_move: float = now - _main._last_move_time
	if time_since_move >= LevelConfig.AUTO_CHARGE_DELAY_SECONDS:
		_main._is_auto_charging = true
	else:
		_main._is_auto_charging = false

	_main.drag_current_world = screen_to_world(_main._virtual_screen_pos)
	update_aim_line()
	update_projection_line()
	apply_preview_radius_from_drag()
	_main._preview_radius = compute_ball_radius_for_current_drag()
	_main._preview_velocity = compute_launch_velocity_for_current_drag()

	if _main.preview_ball and _main.preview_ball.has_method("set_aim_direction"):
		var aim_dir: Vector2 = (_main.drag_anchor_world - _main.drag_current_world).normalized()
		_main.preview_ball.call("set_aim_direction", aim_dir)


func _camera_controls_allowed() -> bool:
	if _main == null:
		return false
	return _main._current_phase == LevelConfig.PHASE_GRAND_MAP


func _enforce_engagement_camera_lock_state() -> void:
	if _main == null:
		return
	if _camera_controls_allowed():
		return

	_main._right_mouse_pan_active = false
	if _main.pan_dragging or not _main.pan_drag_pointer_ids.is_empty() or not _main.pan_drag_pointer_positions.is_empty() or _main._last_touch_distance != 0.0 or _main._last_touch_midpoint != Vector2.ZERO:
		clear_pan_drag_state()


func _pointer_is_over_bottom_bar(screen_pos: Vector2) -> bool:
	if _main == null or _main.ui == null:
		return false
	if not _main.ui.has_method("get_bottom_bar_height"):
		return false

	var bottom_bar_height: float = float(_main.ui.call("get_bottom_bar_height"))
	if bottom_bar_height <= 0.0:
		return false

	var viewport_size: Vector2 = _main.get_viewport_rect().size
	var bottom_bar_top: float = viewport_size.y - bottom_bar_height
	return screen_pos.y >= bottom_bar_top


func _is_summary_ack_pointer_over_ui(screen_pos: Vector2) -> bool:
	return _pointer_is_over_bottom_bar(screen_pos)


func _pointer_is_over_scrollable_banner(screen_pos: Vector2) -> bool:
	if _main == null or _main.ui == null:
		return false
	if not _main.ui.has_method("is_pointer_over_scrollable_banner"):
		return false
	return bool(_main.ui.call("is_pointer_over_scrollable_banner", screen_pos))


func _pointer_is_over_modal_overlay(screen_pos: Vector2) -> bool:
	if _main == null or _main.ui == null:
		return false
	if not _main.ui.has_method("is_pointer_over_modal_overlay"):
		return false
	return bool(_main.ui.call("is_pointer_over_modal_overlay", screen_pos))


func _is_modal_overlay_visible() -> bool:
	if _main == null or _main.ui == null:
		return false
	if not _main.ui.has_method("is_modal_overlay_visible"):
		return false
	return bool(_main.ui.call("is_modal_overlay_visible"))


func _should_place_magnet_on_press(screen_pos: Vector2) -> bool:
	if _main == null:
		return false
	if _pointer_is_over_bottom_bar(screen_pos):
		return false
	if not _main.has_method("_is_magnet_placement_mode_armed"):
		return false
	return bool(_main.call("_is_magnet_placement_mode_armed"))



func _should_cancel_touch_shot_from_extra_tap(touch_index: int, screen_pos: Vector2) -> bool:
	if _main == null:
		return false
	if _pointer_is_over_bottom_bar(screen_pos):
		return false
	if _main.drag_source != _main.DragSource.TOUCH:
		return false
	if not _main._drag_pending and (not _main.dragging or _main.state != _main.GameState.DRAGGING):
		return false
	return _main.drag_pointer_id != -1 and touch_index != _main.drag_pointer_id


func _begin_pending_cancel_touch(touch_index: int, screen_pos: Vector2) -> void:
	_pending_cancel_touch_id = touch_index
	_pending_cancel_touch_start_pos = screen_pos
	_pending_cancel_touch_max_move = 0.0


func _clear_pending_cancel_touch() -> void:
	_pending_cancel_touch_id = -1
	_pending_cancel_touch_start_pos = Vector2.ZERO
	_pending_cancel_touch_max_move = 0.0


func _has_pending_cancel_touch() -> bool:
	return _pending_cancel_touch_id != -1


func _is_pending_cancel_touch(touch_index: int) -> bool:
	return _pending_cancel_touch_id == touch_index


func _update_pending_cancel_touch_motion(screen_pos: Vector2) -> void:
	if not _has_pending_cancel_touch():
		return
	_pending_cancel_touch_max_move = maxf(_pending_cancel_touch_max_move, screen_pos.distance_to(_pending_cancel_touch_start_pos))


func _pending_cancel_touch_has_become_camera_gesture() -> bool:
	return _pending_cancel_touch_max_move > TOUCH_CANCEL_TAP_MOVE_THRESHOLD_PIXELS


func _cancel_touch_shot_from_extra_tap() -> void:
	if _main == null:
		return
	_main._cancel_shot()
	clear_all_touch_tracking()
	if _main.ui_bridge != null:
		_main.ui_bridge.ui_set_status("Shot canceled.")


func _try_place_magnet_from_screen_pos(screen_pos: Vector2) -> bool:
	if not _should_place_magnet_on_press(screen_pos):
		return false

	var magnet_world: Vector2 = screen_to_world(screen_pos)
	var reasons: PackedStringArray = get_bad_magnet_place_reasons(magnet_world, float(LevelConfig.UPGRADE_MAGNET_PLACEMENT_RADIUS))
	if not reasons.is_empty():
		var reason_text: String = reasons[0]
		if reasons.size() >= 2:
			reason_text = "%s and %s" % [reasons[0], reasons[1]]
		if _main.ui_bridge != null:
			_main.ui_bridge.ui_set_status("Magnet blocked: %s." % reason_text)
		return true

	var placed: bool = false
	if _main.has_method("_place_player_magnet"):
		placed = bool(_main.call("_place_player_magnet", magnet_world))

	if placed and _main.ui_bridge != null:
		var remaining: int = 0
		if _main.has_method("_get_remaining_magnet_placements"):
			remaining = int(_main.call("_get_remaining_magnet_placements"))
		if remaining > 0:
			_main.ui_bridge.ui_set_status("Magnet placed. %d placement%s left." % [remaining, "" if remaining == 1 else "s"])
		else:
			_main.ui_bridge.ui_set_status("Magnet placed.")
	return true


func handle_touch(event: InputEventScreenTouch) -> void:
	if _main == null:
		return

	if event.pressed:
		if _pointer_is_over_bottom_bar(event.position):
			return
		if _try_place_magnet_from_screen_pos(event.position):
			_main.get_viewport().set_input_as_handled()
			return
		if _should_cancel_touch_shot_from_extra_tap(event.index, event.position):
			_register_touch_pointer(event.index, event.position)
			_begin_pending_cancel_touch(event.index, event.position)
			_main.get_viewport().set_input_as_handled()
			return
		_register_touch_pointer(event.index, event.position)
		if _active_touch_ids.size() >= 2:
			if _camera_controls_allowed():
				begin_multitouch_camera_gesture()
				_main.get_viewport().set_input_as_handled()
		else:
			start_drag_touch(event.index, event.position)
	else:
		var was_pan_pointer: bool = _main.pan_drag_pointer_ids.has(event.index)
		var was_drag_pointer: bool = (_main.drag_pointer_id == event.index)
		var was_pending_cancel_pointer: bool = _is_pending_cancel_touch(event.index)
		_unregister_touch_pointer(event.index)
		if was_pending_cancel_pointer:
			if not _pending_cancel_touch_has_become_camera_gesture():
				_cancel_touch_shot_from_extra_tap()
				_main.get_viewport().set_input_as_handled()
				return
			_clear_pending_cancel_touch()
		elif was_pan_pointer:
			end_pan_drag(event.index, event.position)
		elif was_drag_pointer:
			end_drag_touch(event.index, event.position)
		if _active_touch_ids.size() >= 2 and _camera_controls_allowed():
			begin_multitouch_camera_gesture()
		elif _active_touch_ids.is_empty():
			clear_all_touch_tracking()
		else:
			clear_pan_drag_state()


func handle_drag(event: InputEventScreenDrag) -> void:
	if _main == null:
		return

	if _active_touch_positions.has(event.index):
		_active_touch_positions[event.index] = event.position

	if _active_touch_ids.size() >= 2 and _has_pending_cancel_touch():
		if _camera_controls_allowed():
			if _is_pending_cancel_touch(event.index):
				_update_pending_cancel_touch_motion(event.position)
				if not _pending_cancel_touch_has_become_camera_gesture():
					return
			else:
				_clear_pending_cancel_touch()
			begin_multitouch_camera_gesture()
			update_pan_drag(event.index, event.position)
			_main.get_viewport().set_input_as_handled()
			return
		if _main.drag_pointer_id == event.index:
			update_drag_touch(event.index, event.position)
		return

	if _active_touch_ids.size() >= 2:
		if _camera_controls_allowed():
			if not _main.pan_drag_pointer_ids.has(event.index):
				begin_multitouch_camera_gesture()
			update_pan_drag(event.index, event.position)
			_main.get_viewport().set_input_as_handled()
			return
		if _main.drag_pointer_id == event.index:
			update_drag_touch(event.index, event.position)
		return

	if _main.pan_drag_pointer_ids.has(event.index):
		update_pan_drag(event.index, event.position)
	elif _main.drag_pointer_id == event.index:
		update_drag_touch(event.index, event.position)


func handle_mouse_button(event: InputEventMouseButton) -> void:
	if _main == null:
		return
	if OS.has_feature("mobile"):
		return
	if not _active_touch_ids.is_empty() or _main.drag_source == _main.DragSource.TOUCH:
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _try_place_magnet_from_screen_pos(event.position):
				_main.get_viewport().set_input_as_handled()
				return
			if event.double_click:
				if _try_move_launch_province_from_screen_pos(event.position):
					_main.get_viewport().set_input_as_handled()
					return
				_main._cancel_shot()
				return
			start_drag_mouse(event.position)
		else:
			end_drag_mouse(event.position)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if _main._drag_pending or (_main.dragging and _main.state == _main.GameState.DRAGGING):
				_main._cancel_shot()
				_main.get_viewport().set_input_as_handled()
				return
			if not _camera_controls_allowed():
				_main._right_mouse_pan_active = false
				return
			_main._right_mouse_pan_active = true
			_main.pan_drag_start_screen = event.position
			_main.pan_drag_start_offset = _main.camera_pan_offset
		else:
			_main._right_mouse_pan_active = false
			_store_grand_map_camera_state_if_relevant()
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if _pointer_is_over_scrollable_banner(event.position):
			return
		if _is_modal_overlay_visible():
			return
		if _pointer_is_over_modal_overlay(event.position):
			return
		handle_mouse_wheel_zoom(event)


func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _main == null:
		return
	if OS.has_feature("mobile"):
		return
	if not _active_touch_ids.is_empty() or _main.drag_source == _main.DragSource.TOUCH:
		return

	if _main._right_mouse_pan_active:
		if not _camera_controls_allowed():
			_main._right_mouse_pan_active = false
			return
		_main.camera_pan_offset = _main.pan_drag_start_offset + (_main.pan_drag_start_screen - event.position) / _main.camera_2d.zoom.x
		if _main.camera_controller != null:
			_main.camera_controller.clamp_camera_pan()
			_main.camera_controller.apply_camera_fit()
		_store_grand_map_camera_state_if_relevant()
	elif _main.drag_source == _main.DragSource.MOUSE or _main.dragging:
		update_drag_mouse(event.position)


func handle_pan_gesture(event: InputEventPanGesture) -> void:
	if _main == null:
		return
	if not _camera_controls_allowed():
		return

	_main.camera_pan_offset -= event.delta / _main.camera_2d.zoom.x
	if _main.camera_controller != null:
		_main.camera_controller.clamp_camera_pan()
		_main.camera_controller.apply_camera_fit()
	_store_grand_map_camera_state_if_relevant()


func _register_touch_pointer(pointer_id: int, screen_pos: Vector2) -> void:
	_active_touch_positions[pointer_id] = screen_pos
	if not _active_touch_ids.has(pointer_id):
		_active_touch_ids.append(pointer_id)
	if _main != null:
		_main._total_active_touches = _active_touch_ids.size()


func _unregister_touch_pointer(pointer_id: int) -> void:
	_active_touch_positions.erase(pointer_id)
	_active_touch_ids.erase(pointer_id)
	if _main != null:
		_main._total_active_touches = _active_touch_ids.size()


func clear_all_touch_tracking() -> void:
	_active_touch_positions.clear()
	_active_touch_ids.clear()
	_clear_pending_cancel_touch()
	_touch_drag_start_msec = 0
	clear_pan_drag_state()
	if _main != null:
		_main._total_active_touches = 0


func clear_pan_drag_state() -> void:
	if _main == null:
		return
	_main.pan_dragging = false
	_main.pan_drag_pointer_ids.clear()
	_main.pan_drag_pointer_positions.clear()
	_main._last_touch_distance = 0.0
	_main._last_touch_midpoint = Vector2.ZERO
	_store_grand_map_camera_state_if_relevant()


func begin_multitouch_camera_gesture() -> void:
	if _main == null:
		return
	if not _camera_controls_allowed():
		return
	if _active_touch_ids.size() < 2:
		return
	_clear_pending_cancel_touch()
	promote_touch_drag_to_pan_if_needed()
	clear_pan_drag_state()
	var first_id: int = _active_touch_ids[_active_touch_ids.size() - 2]
	var second_id: int = _active_touch_ids[_active_touch_ids.size() - 1]
	start_pan_drag(first_id, _active_touch_positions.get(first_id, Vector2.ZERO))
	start_pan_drag(second_id, _active_touch_positions.get(second_id, Vector2.ZERO))


func promote_touch_drag_to_pan_if_needed() -> void:
	if _main == null:
		return
	if _main.drag_source != _main.DragSource.TOUCH:
		return
	if _main.drag_pointer_id == -1:
		return
	if _main.pan_drag_pointer_ids.has(_main.drag_pointer_id):
		return

	var primary_pointer_id: int = _main.drag_pointer_id
	var primary_screen_pos: Vector2 = _main._drag_potential_start_screen if _main._drag_pending else _main._last_drag_screen_pos

	clear_touch_drag_for_pan()
	start_pan_drag(primary_pointer_id, primary_screen_pos)


func clear_touch_drag_for_pan() -> void:
	if _main == null:
		return

	_main.dragging = false
	_main._drag_pending = false
	_main.drag_pointer_id = -1
	_main.drag_source = _main.DragSource.NONE
	_main._is_auto_charging = false

	if _main.preview_ball and is_instance_valid(_main.preview_ball):
		_main.preview_ball.queue_free()
		_main.preview_ball = null

	if _main.aim_line:
		_main.aim_line.visible = false
	if _main.projection_line:
		_main.projection_line.visible = false

	if _main.state == _main.GameState.DRAGGING:
		_main.state = _main.GameState.GRAND_MAP if _main._current_phase == "grand_map" else _main.GameState.ENGAGEMENT

	if _main.ui_bridge != null:
		_main.ui_bridge.sync_ui_button_states()


func start_pan_drag(pointer_id: int, screen_pos: Vector2) -> void:
	if _main == null:
		return
	if not _camera_controls_allowed():
		return

	_main.pan_dragging = true
	if not _main.pan_drag_pointer_ids.has(pointer_id):
		_main.pan_drag_pointer_ids.append(pointer_id)
	_main.pan_drag_pointer_positions[pointer_id] = screen_pos
	if _main.pan_drag_pointer_ids.size() == 2:
		_main._last_touch_distance = get_real_touch_distance()
		_main._last_touch_midpoint = get_touch_midpoint()


func update_pan_drag(pointer_id: int, screen_pos: Vector2) -> void:
	if _main == null:
		return
	if not _camera_controls_allowed():
		return

	_main.pan_drag_pointer_positions[pointer_id] = screen_pos
	if _main.pan_drag_pointer_ids.size() == 2:
		process_pinch_zoom_and_pan()


func process_pinch_zoom_and_pan() -> void:
	if _main == null:
		return
	if not _camera_controls_allowed():
		return

	var current_dist: float = get_real_touch_distance()
	var current_mid: Vector2 = get_touch_midpoint()

	if _main._last_touch_distance > 0.0:
		var factor: float = current_dist / _main._last_touch_distance
		var proposed: float = _main.current_camera_zoom * factor

		if absf(factor - 1.0) > 0.02:
			if proposed < _main._grand_map_fit_zoom:
				_main.current_camera_zoom = _main._grand_map_fit_zoom
				recenter_on_zoom_clamp()
			else:
				_main.current_camera_zoom = clampf(proposed, _main._grand_map_fit_zoom, LevelConfig.GRAND_MAP_CAMERA_MAX_ZOOM)
			if _main.camera_controller != null:
				_main.camera_controller.apply_camera_fit()

		var mid_delta: Vector2 = current_mid - _main._last_touch_midpoint
		_main.camera_pan_offset -= mid_delta / _main.camera_2d.zoom.x
		if _main.camera_controller != null:
			_main.camera_controller.clamp_camera_pan()

	_main._last_touch_distance = current_dist
	_main._last_touch_midpoint = current_mid
	if _main.camera_controller != null:
		_main.camera_controller.apply_camera_fit()
	_store_grand_map_camera_state_if_relevant()
	_main.get_viewport().set_input_as_handled()


func get_real_touch_distance() -> float:
	if _main == null or _main.pan_drag_pointer_ids.size() != 2:
		return 0.0

	var p1: Vector2 = _main.pan_drag_pointer_positions.get(_main.pan_drag_pointer_ids[0], Vector2.ZERO)
	var p2: Vector2 = _main.pan_drag_pointer_positions.get(_main.pan_drag_pointer_ids[1], Vector2.ZERO)
	return p1.distance_to(p2) if p1 != Vector2.ZERO and p2 != Vector2.ZERO else 200.0


func get_touch_midpoint() -> Vector2:
	if _main == null or _main.pan_drag_pointer_ids.size() != 2:
		return Vector2.ZERO

	var p1: Vector2 = _main.pan_drag_pointer_positions.get(_main.pan_drag_pointer_ids[0], Vector2.ZERO)
	var p2: Vector2 = _main.pan_drag_pointer_positions.get(_main.pan_drag_pointer_ids[1], Vector2.ZERO)
	return (p1 + p2) * 0.5


func end_pan_drag(pointer_id: int, _screen_pos: Vector2) -> void:
	if _main == null:
		return

	_main.pan_drag_pointer_ids.erase(pointer_id)
	_main.pan_drag_pointer_positions.erase(pointer_id)
	if _active_touch_ids.size() >= 2:
		begin_multitouch_camera_gesture()
	elif _main.pan_drag_pointer_ids.is_empty():
		clear_pan_drag_state()
	_store_grand_map_camera_state_if_relevant()


func handle_mouse_wheel_zoom(event: InputEventMouseButton) -> void:
	if _main == null:
		return
	if _main._current_phase != "grand_map":
		return

	var delta_zoom: float = 0.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.12
	var proposed: float = _main.current_camera_zoom + delta_zoom
	var cursor_world_before: Vector2 = screen_to_world(event.position)

	if proposed < _main._grand_map_fit_zoom:
		_main.current_camera_zoom = _main._grand_map_fit_zoom
		recenter_on_zoom_clamp()
	else:
		_main.current_camera_zoom = clampf(proposed, _main._grand_map_fit_zoom, LevelConfig.GRAND_MAP_CAMERA_MAX_ZOOM)

	if _main.camera_controller != null:
		_main.camera_controller.apply_camera_fit()

		if proposed >= _main._grand_map_fit_zoom:
			var cursor_world_after: Vector2 = screen_to_world(event.position)
			_main.camera_pan_offset += cursor_world_before - cursor_world_after
			_main.camera_controller.clamp_camera_pan()
			_main.camera_controller.apply_camera_fit()

	_store_grand_map_camera_state_if_relevant()
	_main.get_viewport().set_input_as_handled()


func recenter_on_zoom_clamp() -> void:
	if _main == null or _main._current_phase != "grand_map":
		return

	var vp_size: Vector2 = _main.get_viewport().get_visible_rect().size
	var bar_h: float = 0.0
	if _main.ui and _main.ui.has_method("get_bottom_bar_height"):
		bar_h = float(_main.ui.call("get_bottom_bar_height"))

	var avail_h: float = maxf(1.0, float(vp_size.y) - bar_h)
	var fit_ratio_x: float = float(vp_size.x) / float(LevelConfig.GRAND_MAP_PLAYABLE_SIZE.x)
	var fit_ratio_y: float = avail_h / float(LevelConfig.GRAND_MAP_PLAYABLE_SIZE.y)

	if fit_ratio_x <= fit_ratio_y:
		_main.camera_pan_offset.x = 0.0
	if fit_ratio_y <= fit_ratio_x:
		_main.camera_pan_offset.y = 0.0

	if _main.camera_controller != null:
		_main.camera_controller.clamp_camera_pan()


func screen_to_world(screen_pos: Vector2) -> Vector2:
	if _main == null:
		return Vector2.ZERO

	var inv: Transform2D = _main.get_viewport().get_canvas_transform().affine_inverse()
	return inv * screen_pos


func start_drag_touch(touch_index: int, screen_pos: Vector2) -> void:
	if _main == null:
		return

	_main.drag_source = _main.DragSource.TOUCH
	_touch_drag_start_msec = Time.get_ticks_msec()
	start_drag_pending(touch_index, screen_pos)


func start_drag_mouse(screen_pos: Vector2) -> void:
	if _main == null:
		return

	_main.drag_source = _main.DragSource.MOUSE
	_main._mouse_drag_start_screen = screen_pos
	_main._mouse_drag_start_msec = Time.get_ticks_msec()
	start_drag_pending(-1, screen_pos)


func start_drag_pending(pointer_id: int, screen_pos: Vector2) -> void:
	if _main == null:
		return
	if _main.state != _main.GameState.GRAND_MAP and _main.state != _main.GameState.ENGAGEMENT:
		return
	if _pointer_is_over_bottom_bar(screen_pos):
		return

	if _main.drag_source == _main.DragSource.MOUSE and not _can_start_shot_from_screen_pos(screen_pos):
		return

	_main._drag_pending = true
	_main._drag_potential_start_screen = screen_pos
	_main.drag_pointer_id = pointer_id
	_main.drag_anchor_world = screen_to_world(screen_pos)
	_main._last_drag_screen_pos = screen_pos
	_main._last_move_time = Time.get_ticks_msec() / 1000.0
	_main._is_auto_charging = false
	_main._virtual_screen_pos = screen_pos
	if _main._current_phase == LevelConfig.PHASE_GRAND_MAP:
		_store_grand_map_camera_state_if_relevant()
	if _main.ui_bridge != null:
		_main.ui_bridge.sync_ui_button_states()


func _can_start_shot_from_screen_pos(screen_pos: Vector2) -> bool:
	if _main == null:
		return false
	if _main._locked_province_id_after_win == -1 or _main._current_phase != "grand_map":
		return true

	var anchor_world: Vector2 = screen_to_world(screen_pos)
	var data: Dictionary = {}
	if _main.province_system != null:
		data = _main.province_system.get_province_data(anchor_world)
	var origin_province_id: int = int(data.get("id", -1))
	if origin_province_id == _main._locked_province_id_after_win:
		return true

	if _main.province_system != null and _main.province_system.has_method("flash_province_faction_fill_if_visible"):
		_main.province_system.call("flash_province_faction_fill_if_visible", _main._locked_province_id_after_win, 1.0)
	if _main.ui_bridge != null:
		_main.ui_bridge.ui_set_status("This turn's shot must start inside the highlighted province.")
	return false


func _try_move_launch_province_from_screen_pos(screen_pos: Vector2) -> bool:
	if _main == null:
		return false
	if _main._current_phase != LevelConfig.PHASE_GRAND_MAP:
		return false
	if _main._locked_province_id_after_win < 0:
		return false
	if _main.province_system == null:
		return false

	var target_data: Dictionary = _main.province_system.get_province_data(screen_to_world(screen_pos))
	var target_province_id: int = int(target_data.get("id", -1))
	if target_province_id < 0:
		return false
	if target_province_id != _main._locked_province_id_after_win:
		var neighbors: Array[int] = _main.province_system.normalize_neighbor_ids(target_data.get("neighbors", []))
		if not neighbors.has(_main._locked_province_id_after_win):
			if _main.ui_bridge != null:
				_main.ui_bridge.ui_set_status("Double-click the origin province or a directly adjacent province to move there.")
			return false
	else:
		if _main.ui_bridge != null:
			_main.ui_bridge.ui_set_status("Replaying turn from the origin province.")

	_main._cancel_shot()
	var target_world: Vector2 = screen_to_world(screen_pos)
	_main.province_system.cache_ball_end_world_pos(target_world)
	if _main.has_method("_finalize_ball_flight"):
		_main.call("_finalize_ball_flight")
	return true


func commit_to_drag(screen_pos: Vector2) -> void:
	if _main == null:
		return
	if _main.drag_source == _main.DragSource.TOUCH:
		if _active_touch_ids.size() != 1:
			return
		var touch_commit_delay_msec: int = LevelConfig.get_touch_single_finger_commit_delay_msec()
		if _touch_drag_start_msec > 0 and Time.get_ticks_msec() - _touch_drag_start_msec < touch_commit_delay_msec:
			return
	if not _can_start_shot_from_screen_pos(screen_pos):
		_main._drag_pending = false
		return

	_main._drag_pending = false
	_main.dragging = true
	_main.state = _main.GameState.DRAGGING
	_main._virtual_screen_pos = screen_pos
	_main._last_drag_screen_pos = screen_pos
	_main._last_move_time = Time.get_ticks_msec() / 1000.0
	_main._is_auto_charging = false
	_main.drag_current_world = screen_to_world(_main._virtual_screen_pos)

	if _main.preview_ball == null:
		if _main.level_flow != null:
			_main.level_flow.ensure_spawn_roots()
		_main.preview_ball = BallScene.instantiate() as RigidBody2D
		_main.ball_holder.add_child(_main.preview_ball)
		_main.preview_ball.global_position = _main.drag_anchor_world
		_main.preview_ball.collision_layer = 0
		_main.preview_ball.collision_mask = 0
		_main.preview_ball.freeze = true
		_main.preview_ball.sleeping = true
		_main.preview_ball.process_mode = Node.PROCESS_MODE_DISABLED

	_main.projection_line.visible = true
	_main.aim_line.visible = true
	update_aim_line()
	update_projection_line()
	apply_preview_radius_from_drag()
	if _main.ui_bridge != null:
		_main.ui_bridge.sync_ui_button_states()
	_main._preview_radius = compute_ball_radius_for_current_drag()
	_main._preview_velocity = compute_launch_velocity_for_current_drag()


func update_drag_touch(touch_index: int, screen_pos: Vector2) -> void:
	if _main == null:
		return

	if _main._drag_pending:
		var dist: float = screen_pos.distance_to(_main._drag_potential_start_screen)
		if dist > _main.MIN_DRAG_THRESHOLD_PIXELS:
			commit_to_drag(screen_pos)
		return

	if not _main.dragging or _main.state != _main.GameState.DRAGGING or _main.drag_pointer_id != touch_index:
		return

	update_drag_common(screen_pos)


func update_drag_mouse(screen_pos: Vector2) -> void:
	if _main == null:
		return

	if _main._drag_pending:
		var dist: float = screen_pos.distance_to(_main._drag_potential_start_screen)
		if dist > _main.MIN_DRAG_THRESHOLD_PIXELS:
			commit_to_drag(screen_pos)
		return

	if not _main.dragging or _main.state != _main.GameState.DRAGGING:
		return

	update_drag_common(screen_pos)


func update_drag_common(screen_pos: Vector2) -> void:
	if _main == null:
		return

	if screen_pos.distance_to(_main._last_drag_screen_pos) > 3.0:
		_main._last_move_time = Time.get_ticks_msec() / 1000.0
		_main._is_auto_charging = false

	_main._last_drag_screen_pos = screen_pos
	_main._virtual_screen_pos = screen_pos
	_main.drag_current_world = screen_to_world(_main._virtual_screen_pos)
	update_aim_line()
	update_projection_line()
	apply_preview_radius_from_drag()
	_main._preview_radius = compute_ball_radius_for_current_drag()
	_main._preview_velocity = compute_launch_velocity_for_current_drag()

	if _main.preview_ball and _main.preview_ball.has_method("set_aim_direction"):
		var aim_dir: Vector2 = (_main.drag_anchor_world - _main.drag_current_world).normalized()
		_main.preview_ball.call("set_aim_direction", aim_dir)


func end_drag_touch(touch_index: int, screen_pos: Vector2) -> void:
	end_drag_common(touch_index, screen_pos)


func end_drag_mouse(screen_pos: Vector2) -> void:
	end_drag_common(-1, screen_pos)


func end_drag_common(pointer_id: int, screen_pos: Vector2) -> void:
	if _main == null:
		return

	if _main._drag_pending:
		_main._drag_pending = false
		_main.drag_pointer_id = -1
		_main.drag_source = _main.DragSource.NONE
		_touch_drag_start_msec = 0
		if _main.ui_bridge != null:
			_main.ui_bridge.sync_ui_button_states()
		return

	if not _main.dragging or _main.state != _main.GameState.DRAGGING or _main.drag_pointer_id != pointer_id:
		return

	var blocked_reasons: PackedStringArray = get_bad_shot_block_reasons(_main.drag_anchor_world, _main._preview_radius)
	if not blocked_reasons.is_empty():
		block_bad_shot(blocked_reasons)
		return

	_main._final_launch_radius = _main._preview_radius
	_main._final_launch_velocity = _main._preview_velocity
	launch_ball_from_drag()
	_main.dragging = false
	_main.drag_pointer_id = -1
	_main.drag_source = _main.DragSource.NONE
	_main._is_auto_charging = false
	_main.aim_line.visible = false
	_main.projection_line.visible = false
	_main._input_locked_until = Time.get_ticks_msec() / 1000.0 + 0.25
	_main._locked_province_id_after_win = -1
	_touch_drag_start_msec = 0



func get_bad_magnet_place_reasons(magnet_center: Vector2, magnet_radius: float) -> PackedStringArray:
	var reasons: PackedStringArray = PackedStringArray()
	if _main == null:
		return reasons

	if not is_ball_fully_inside_current_map(magnet_center, magnet_radius):
		reasons.append("part of the magnet would be outside the map")

	if does_circle_overlap_any_obstacle(magnet_center, magnet_radius, true):
		reasons.append("the magnet would overlap an obstacle")

	if does_circle_overlap_any_pin(magnet_center, magnet_radius):
		reasons.append("the magnet would overlap a troop")

	if does_circle_overlap_any_water(magnet_center, magnet_radius):
		reasons.append("the magnet would overlap water")

	if does_circle_overlap_any_player_magnet(magnet_center, maxf(magnet_radius, float(LevelConfig.UPGRADE_MAGNET_MIN_SPACING) * 0.5)):
		reasons.append("the magnet would be too close to another magnet")

	return reasons


func get_bad_shot_block_reasons(ball_center: Vector2, ball_radius: float) -> PackedStringArray:
	var reasons: PackedStringArray = PackedStringArray()
	if _main == null:
		return reasons

	if not is_ball_fully_inside_current_map(ball_center, ball_radius):
		reasons.append("part of the ball would be outside the map")

	if does_ball_overlap_any_rock(ball_center, ball_radius):
		reasons.append("part of the ball would overlap a rock")

	if does_ball_overlap_any_caltrop(ball_center, ball_radius):
		reasons.append("part of the ball would overlap a caltrop")

	return reasons


func block_bad_shot(reasons: PackedStringArray) -> void:
	if _main == null:
		return

	if _main.has_method("_cancel_shot"):
		_main._cancel_shot()

	var reason_text: String = ""
	if reasons.size() == 1:
		reason_text = reasons[0]
	elif reasons.size() >= 2:
		reason_text = "%s and %s" % [reasons[0], reasons[1]]

	if _main.ui_bridge != null:
		_main.ui_bridge.ui_set_status("Bad shot blocked: %s. Adjust the start point or ball size. You are free to shoot." % reason_text)


func is_ball_fully_inside_current_map(ball_center: Vector2, ball_radius: float) -> bool:
	var half_extents: Vector2 = get_current_map_half_extents()
	return absf(ball_center.x) + ball_radius <= half_extents.x and absf(ball_center.y) + ball_radius <= half_extents.y


func get_current_map_half_extents() -> Vector2:
	if _main == null:
		return LevelConfig.WORLD_HALF_EXTENTS
	if _main._current_phase == LevelConfig.PHASE_GRAND_MAP:
		return LevelConfig.GRAND_MAP_HALF_EXTENTS
	return LevelConfig.WORLD_HALF_EXTENTS



func does_circle_overlap_any_obstacle(center: Vector2, radius: float, include_buildings: bool = true) -> bool:
	if _main == null or not is_instance_valid(_main.obstacles_root):
		return false

	for child in _main.obstacles_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if child.get_meta("is_player_magnet", false):
			continue
		if not include_buildings and child.has_meta("is_building"):
			continue
		if child is Node2D and does_ball_overlap_rock(center, radius, child as Node2D):
			return true

	return false


func does_circle_overlap_any_pin(center: Vector2, radius: float) -> bool:
	if _main == null or not is_instance_valid(_main.pins_root):
		return false

	for child in _main.pins_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if not (child is Node2D):
			continue
		var pin_scale: float = 1.0
		if child.has_method("_get_draw_scale"):
			var draw_scale_variant: Variant = child.call("_get_draw_scale")
			if typeof(draw_scale_variant) == TYPE_FLOAT or typeof(draw_scale_variant) == TYPE_INT:
				pin_scale = maxf(0.35, float(draw_scale_variant))
		var pin_radius: float = maxf(float(LevelConfig.PIN_HEAD_RADIUS) * 1.15 * pin_scale, float(LevelConfig.PIN_BODY_WIDTH) * 0.58 * pin_scale)
		if (child as Node2D).global_position.distance_to(center) < (radius + pin_radius + 6.0):
			return true

	return false


func does_circle_overlap_any_water(center: Vector2, radius: float) -> bool:
	if _main == null or not is_instance_valid(_main.zones_root):
		return false

	for child in _main.zones_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if not (child is Area2D):
			continue
		if not child.has_meta("zone_type"):
			continue
		if String(child.get_meta("zone_type")) != "water":
			continue
		if _point_inside_water_like_zone(center, child as Area2D, radius):
			return true

	return false


func does_circle_overlap_any_player_magnet(center: Vector2, min_spacing_radius: float) -> bool:
	if _main == null:
		return false
	for magnet_node in _main.get_tree().get_nodes_in_group("player_magnets"):
		if magnet_node == null or not is_instance_valid(magnet_node) or magnet_node.is_queued_for_deletion():
			continue
		if not (magnet_node is Node2D):
			continue
		if (magnet_node as Node2D).global_position.distance_to(center) < min_spacing_radius * 2.0:
			return true
	return false


func _point_inside_water_like_zone(world_point: Vector2, area: Area2D, boundary_offset: float = 0.0) -> bool:
	var center := area.global_position
	var base_radius := float(area.get_meta("zone_radius", 0.0))
	var aspect := maxf(0.42, float(area.get_meta("zone_aspect", 1.0)))

	if base_radius <= 0.001:
		return false

	var rx := base_radius * maxf(1.0, aspect) + boundary_offset
	var ry := base_radius / maxf(0.42, aspect * 0.92) + boundary_offset
	if rx <= 0.001 or ry <= 0.001:
		return false

	var local := world_point - center
	if absf(area.global_rotation) > 0.0001:
		local = local.rotated(-area.global_rotation)

	var nx := local.x / rx
	var ny := local.y / ry
	return nx * nx + ny * ny <= 1.0


func does_ball_overlap_any_rock(ball_center: Vector2, ball_radius: float) -> bool:
	return does_circle_overlap_any_obstacle(ball_center, ball_radius, false)


func does_ball_overlap_any_caltrop(ball_center: Vector2, ball_radius: float) -> bool:
	if _main == null or not is_instance_valid(_main.obstacles_root):
		return false

	for child in _main.obstacles_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if not (child is Node2D):
			continue
		if not bool(child.get_meta("is_caltrop", false)):
			continue
		if does_ball_overlap_caltrop(ball_center, ball_radius, child as Node2D):
			return true

	return false


func does_ball_overlap_caltrop(ball_center: Vector2, ball_radius: float, caltrop_node: Node2D) -> bool:
	var clearance_radius: float = float(caltrop_node.get_meta("caltrop_clearance_radius", 0.0))
	if clearance_radius > 0.0 and caltrop_node.global_position.distance_to(ball_center) < (ball_radius + clearance_radius):
		return true

	for child in caltrop_node.get_children():
		if child is CollisionPolygon2D:
			var poly_node: CollisionPolygon2D = child as CollisionPolygon2D
			var local_polygon: PackedVector2Array = poly_node.polygon
			if local_polygon.size() < 3:
				continue
			var world_polygon: PackedVector2Array = PackedVector2Array()
			for local_point in local_polygon:
				world_polygon.append(poly_node.to_global(local_point))
			if Geometry2D.is_point_in_polygon(ball_center, world_polygon):
				return true
			for i in range(world_polygon.size()):
				var a: Vector2 = world_polygon[i]
				var b: Vector2 = world_polygon[(i + 1) % world_polygon.size()]
				if distance_point_to_segment(ball_center, a, b) < ball_radius:
					return true
		elif child is CollisionShape2D:
			var collision_shape: CollisionShape2D = child as CollisionShape2D
			if collision_shape.shape is CircleShape2D:
				var circle_shape: CircleShape2D = collision_shape.shape as CircleShape2D
				var max_scale: float = maxf(absf(collision_shape.global_scale.x), absf(collision_shape.global_scale.y))
				var circle_radius: float = circle_shape.radius * maxf(0.001, max_scale)
				if collision_shape.global_position.distance_to(ball_center) < (ball_radius + circle_radius):
					return true

	return false


func does_ball_overlap_rock(ball_center: Vector2, ball_radius: float, rock_node: Node2D) -> bool:
	if bool(rock_node.get_meta("is_boss_part", false)):
		return does_ball_overlap_collision_shapes(ball_center, ball_radius, rock_node)
	var rock_polygon: PackedVector2Array = get_rock_polygon_world_points(rock_node)
	if not rock_polygon.is_empty():
		if Geometry2D.is_point_in_polygon(ball_center, rock_polygon):
			return true
		for i in range(rock_polygon.size()):
			var a: Vector2 = rock_polygon[i]
			var b: Vector2 = rock_polygon[(i + 1) % rock_polygon.size()]
			if distance_point_to_segment(ball_center, a, b) < ball_radius:
				return true
		return false

	var rock_radius: float = get_rock_collision_radius(rock_node)
	if rock_radius <= 0.0:
		return false
	return ball_center.distance_to(rock_node.global_position) < (ball_radius + rock_radius)


func does_ball_overlap_collision_shapes(ball_center: Vector2, ball_radius: float, root_node: Node) -> bool:
	if root_node == null or not is_instance_valid(root_node):
		return false
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		for child_any in current.get_children():
			var child: Node = child_any
			stack.append(child)
			if child is CollisionPolygon2D:
				var poly_node: CollisionPolygon2D = child as CollisionPolygon2D
				if poly_node.disabled or poly_node.polygon.size() < 3:
					continue
				var world_polygon: PackedVector2Array = PackedVector2Array()
				for local_point in poly_node.polygon:
					world_polygon.append(poly_node.to_global(local_point))
				if Geometry2D.is_point_in_polygon(ball_center, world_polygon):
					return true
				for i in range(world_polygon.size()):
					var a: Vector2 = world_polygon[i]
					var b: Vector2 = world_polygon[(i + 1) % world_polygon.size()]
					if distance_point_to_segment(ball_center, a, b) < ball_radius:
						return true
			elif child is CollisionShape2D:
				var shape_node: CollisionShape2D = child as CollisionShape2D
				if shape_node.disabled or shape_node.shape == null:
					continue
				if shape_node.shape is CircleShape2D:
					var circle: CircleShape2D = shape_node.shape as CircleShape2D
					var max_scale: float = maxf(absf(shape_node.global_scale.x), absf(shape_node.global_scale.y))
					var radius: float = circle.radius * maxf(0.001, max_scale)
					if shape_node.global_position.distance_to(ball_center) < (ball_radius + radius):
						return true
	return false


func get_rock_polygon_world_points(rock_node: Node2D) -> PackedVector2Array:
	for child in rock_node.get_children():
		if child is Polygon2D:
			var poly_node: Polygon2D = child as Polygon2D
			if poly_node.polygon.size() >= 8:
				var world_points: PackedVector2Array = PackedVector2Array()
				for local_point in poly_node.polygon:
					world_points.append(poly_node.to_global(local_point))
				return world_points
	return PackedVector2Array()


func get_rock_collision_radius(rock_node: Node2D) -> float:
	for child in rock_node.get_children():
		if child is CollisionShape2D:
			var collision_shape: CollisionShape2D = child as CollisionShape2D
			if collision_shape.shape is CircleShape2D:
				return (collision_shape.shape as CircleShape2D).radius * maxf(rock_node.global_scale.x, rock_node.global_scale.y)
	return 0.0


func distance_point_to_segment(point: Vector2, seg_a: Vector2, seg_b: Vector2) -> float:
	var seg: Vector2 = seg_b - seg_a
	var seg_len_sq: float = seg.length_squared()
	if seg_len_sq <= 0.000001:
		return point.distance_to(seg_a)
	var t: float = clampf((point - seg_a).dot(seg) / seg_len_sq, 0.0, 1.0)
	var closest: Vector2 = seg_a + seg * t
	return point.distance_to(closest)


func apply_preview_radius_from_drag() -> void:
	if _main == null:
		return
	if _main.preview_ball == null or not _main.preview_ball.has_method("set_radius"):
		return

	var min_r: float = get_current_min_ball_radius()
	var r: float = compute_ball_radius_for_current_drag()
	if _main.preview_ball.has_method("set_min_radius"):
		_main.preview_ball.call("set_min_radius", min_r)
	_main.preview_ball.call("set_radius", r)
	_main.preview_ball.queue_redraw()


func get_current_strength() -> float:
	if _main == null:
		return 0.0

	var base_strength: float = clampf((_main.drag_current_world - _main.drag_anchor_world).length() / float(LevelConfig.LAUNCH_DRAG_MAX_PIXELS), 0.0, 1.0)
	var now: float = Time.get_ticks_msec() / 1000.0
	var time_since_move: float = now - _main._last_move_time

	if time_since_move >= LevelConfig.AUTO_CHARGE_DELAY_SECONDS:
		var charge_time: float = time_since_move - LevelConfig.AUTO_CHARGE_DELAY_SECONDS
		var progress: float = clampf(charge_time * LevelConfig.AUTO_CHARGE_RATE, 0.0, 1.0)
		return lerpf(base_strength, 1.0, progress)

	return base_strength


func update_aim_line() -> void:
	if _main == null or _main.aim_line == null:
		return

	_main.aim_line.clear_points()
	_main.aim_line.add_point(_main.drag_anchor_world)
	_main.aim_line.add_point(_main.drag_current_world)


func update_projection_line() -> void:
	if _main == null or _main.projection_line == null:
		return

	var strength01: float = get_current_strength()
	var dir: Vector2 = (_main.drag_anchor_world - _main.drag_current_world).normalized()
	if dir.length() < 0.001:
		dir = Vector2.RIGHT

	var proj_length: float = strength01 * (LevelConfig.PROJECTION_LENGTH_FACTOR * 3400.0)
	var proj_end: Vector2 = _main.drag_anchor_world + dir * proj_length

	_main.projection_line.clear_points()
	_main.projection_line.add_point(_main.drag_anchor_world)
	_main.projection_line.add_point(proj_end)


func _is_grand_map_ball_sizing() -> bool:
	return _main != null and _main._current_phase == "grand_map"


func get_current_min_ball_radius() -> float:
	if _is_grand_map_ball_sizing():
		return float(LevelConfig.BALL_RADIUS_MIN_GRAND_MAP)
	return float(LevelConfig.BALL_RADIUS_MIN_ENGAGEMENT)


func get_current_base_ball_radius() -> float:
	if _is_grand_map_ball_sizing():
		return float(LevelConfig.BALL_RADIUS_BASE_GRAND_MAP)
	return float(LevelConfig.BALL_RADIUS_BASE_ENGAGEMENT)


func get_current_max_ball_radius() -> float:
	if _main == null:
		return get_current_base_ball_radius()

	var effective_bigger: int = _main.bigger_count
	var max_r: float = get_current_base_ball_radius() + float(_main.level_index - 1) * LevelConfig.BALL_RADIUS_MAX_GROWTH_PER_LEVEL + float(effective_bigger) * LevelConfig.UPGRADE_BIGGER_RADIUS_PER
	if _main._is_milestone(_main.level_index):
		max_r *= LevelConfig.MILESTONE_BALL_SIZE_MULTIPLIER
	return max_r


func compute_ball_radius_for_current_drag() -> float:
	var strength01: float = get_current_strength()
	var max_r: float = get_current_max_ball_radius()
	return lerpf(max_r, get_current_min_ball_radius(), strength01)


func get_launch_speed_strength_for_current_drag() -> float:
	var max_r: float = get_current_max_ball_radius()
	var min_r: float = get_current_min_ball_radius()
	var current_r: float = compute_ball_radius_for_current_drag()

	# Launch speed is driven by how much the player has shrunk the ball during aiming,
	# not just by the final radius alone. Because this uses a fixed baseline shrink range
	# for the current mode, a larger base ball that is aimed down to the same final size
	# will launch faster than a smaller base ball.
	var baseline_max_r: float = get_current_base_ball_radius()
	var baseline_shrink_range: float = maxf(0.001, baseline_max_r - min_r)
	var shrink_amount: float = maxf(0.0, max_r - current_r)
	return clampf(shrink_amount / baseline_shrink_range, 0.0, 1.0)


func compute_launch_velocity_for_current_drag() -> Vector2:
	var speed_strength01: float = get_launch_speed_strength_for_current_drag()
	var dir: Vector2 = (_main.drag_anchor_world - _main.drag_current_world).normalized()
	if dir.length() < 0.001:
		dir = Vector2.RIGHT

	var speed: float = lerpf(float(LevelConfig.LAUNCH_SPEED_MIN), float(LevelConfig.LAUNCH_SPEED_MAX), speed_strength01)
	return dir * speed


func launch_ball_from_drag() -> void:
	if _main == null:
		return

	if _main._current_phase == LevelConfig.PHASE_GRAND_MAP:
		_store_grand_map_camera_state_if_relevant()

	if _main.province_system != null:
		_main.province_system.clear_cached_ball_end_world_pos()

	if _main.ball and is_instance_valid(_main.ball):
		_main.ball.queue_free()

	if _main.preview_ball and is_instance_valid(_main.preview_ball):
		_main.preview_ball.queue_free()
		_main.preview_ball = null

	_main.ball = BallScene.instantiate() as RigidBody2D
	if _main.level_flow != null:
		_main.level_flow.ensure_spawn_roots()
	_main.ball_holder.add_child(_main.ball)
	_main.ball.global_position = _main.drag_anchor_world
	_main.ball.visible = true

	var launch_min_r: float = get_current_min_ball_radius()
	var launch_r: float = _main._final_launch_radius
	if _main.ball.has_method("set_min_radius"):
		_main.ball.call("set_min_radius", launch_min_r)
	_main.ball.call("set_radius", launch_r)

	var effective_heavier: int = _main.heavier_count
	_main.ball.mass = 1.0 + float(effective_heavier) * LevelConfig.UPGRADE_HEAVIER_MASS_PER

	if _main.ball.has_method("apply_upgrades"):
		_main.ball.call(
			"apply_upgrades",
			_main.bigger_count,
			_main.heavier_count,
			_main.poison_count
		)

	if _main.ball.has_method("set_forcefield_level"):
		_main.ball.call("set_forcefield_level", _main.forcefield_count)

	if _main.ball.has_method("set_magnet_positions") and _main.has_method("_get_live_player_magnet_positions"):
		_main.ball.call("set_magnet_positions", _main.call("_get_live_player_magnet_positions"))

	if _main.has_method("_set_magnet_placement_armed"):
		_main.call("_set_magnet_placement_armed", false)

	if _main.level_flow != null:
		if _main.ball.has_signal("sunk_in_water") and not _main.ball.is_connected("sunk_in_water", Callable(_main.level_flow, "on_ball_sunk_in_water")):
			_main.ball.connect("sunk_in_water", Callable(_main.level_flow, "on_ball_sunk_in_water"))

		if not _main.ball.is_connected("body_entered", Callable(_main.level_flow, "on_ball_body_entered")):
			_main.ball.connect("body_entered", Callable(_main.level_flow, "on_ball_body_entered"))

	if _main.ball.has_method("set_initial_velocity"):
		_main.ball.call("set_initial_velocity", _main._final_launch_velocity)
	else:
		_main.ball.linear_velocity = _main._final_launch_velocity

	_main.ball.collision_mask = LevelConfig.MASK_PINS | LevelConfig.MASK_WALLS | LevelConfig.MASK_ZONES

	# Preserve the player's remembered grand-map view; ball follow can take over
	# temporarily without zeroing the saved pan/zoom back to a neutral state.
	_main._camera_follow_active = true
	_main._wall_grace_end_time = Time.get_ticks_msec() / 1000.0 + _main.WALL_GRACE_SECONDS
	_main.state = _main.GameState.BALL_IN_FLIGHT

	if _main.level_flow != null:
		_main.level_flow.call_deferred("activate_ball_follow")
	if _main.ui_bridge != null:
		_main.ui_bridge.sync_ui_button_states()
	_main.rest_timer = 0.0
	_main.settle_timer = 0.0
	_main.flight_timer = 0.0
	_main._pins_ui_accum = 0.0
	_main._post_launch_input_lock_until = Time.get_ticks_msec() / 1000.0 + 0.15


func _store_grand_map_camera_state_if_relevant() -> void:
	if _main == null:
		return
	if _main._current_phase != LevelConfig.PHASE_GRAND_MAP:
		return
	if _main._camera_follow_active:
		return
	if not _main.has_method("_store_current_grand_map_camera_state"):
		return
	_main._store_current_grand_map_camera_state()
