extends RigidBody2D
"""
Ball behavior for Sunny Slopes.

Handles physics, zone interactions (friction and grade forces), settling detection,
poison contact tracking for upgrades, and sprite-driven ball presentation.

Water support:
- Tracks active water zones through the same register/unregister flow as other zones.
- The ball now sinks when its center reaches the configured water trigger boundary.
- By default, that trigger boundary matches the visible water edge exactly.
- For water-collision testing, a sunk ball stays visibly frozen at its last position until the level is cleared.

NEW FOR OFFENSIVE MAPS:
- Buildings are StaticBody2D on the WALLS layer (already collided with).
- When the ball hits a building, Main.gd calls apply_hit_slowdown() directly.
- This file now safely ignores "map_target" zones (Grand Map) and adds a no-op for building hits.
- Updated: buildings now cause a strong speed loss on bounce (easy "break" feel) while still bouncing reliably.

PERSISTENCE UPDATE (March 2026):
- One extra line in map_target handling to ensure Main.gd can reliably read the exact world position
  on Grand Map settlement (for province lookup and troop/building persistence).

NEUTRAL PROVINCE LOCK EXTENSION (March 2026):
- Settlement in neutral province now sets a launch lock in Main.gd (same mechanism as post-win).
- No functional change here — just a comment for future maintainers.

FORCEFIELD UPDATE (March 2026):
- A visible forcefield ring can be enabled as an upgrade.
- The ring only affects pins, never pushes the ball back, and ignores walls / rocks completely.
- Hit strength is scaled by LevelConfig.UPGRADE_FORCEFIELD_PIN_STRENGTH_MULT.

MAGNET UPDATE (March 2026):
- Magnets are ball-only.
- They apply direct force only to this ball rigid body.
- They must never pull pins or any other object.
"""

signal sunk_in_water

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const BALL_FLYING_TEXTURE: Texture2D = preload("res://sprites/ball_flying.png")
const BALL_TUMBLING_TEXTURE: Texture2D = preload("res://sprites/ball_tumbling.png")
const BALL_LOSER_TEXTURE: Texture2D = preload("res://sprites/ball_loser.png")
const BALL_WINNER_TEXTURE: Texture2D = preload("res://sprites/ball_winner.png")

const SPRITE_FILL_MULT: float = 1.52
const SPRITE_MIN_DRAW_SIZE: float = 18.0
const BALL_OUTLINE_WIDTH: float = 2.5
const CENTER_DOT_RADIUS: float = 6.0
const CENTER_DOT_COLOR := Color(0.86, 0.12, 0.12, 1.0)

enum VisualState {
	FLYING,
	TUMBLING,
	WINNER,
	LOSER
}

@onready var _shape: CollisionShape2D = $CollisionShape2D

var _radius: float = 28.0
var _min_radius: float = LevelConfig.BALL_RADIUS_MIN_ENGAGEMENT
var _launched: bool = false

var _friction_zones: Array[Area2D] = []
var _grade_forces: Array[Vector2] = []
var _water_zones: Array[Area2D] = []

var _settling_timer: float = 0.0
var _low_speed_force_stop_timer: float = 0.0
var _forced_settle_hold_active: bool = false

var _poison_level: int = 0
var _forcefield_level: int = 0

var _contacted_pins: Dictionary = {}
var _forcefield_pin_cooldowns: Dictionary = {}
var _forcefield_scan_pins_cache: Array = []
var _forcefield_scan_cache_populated: bool = false
var _trail_points: Array[Vector2] = []
var _magnet_positions: Array[Vector2] = []
var _trail_record_step: float = 10.0

var _aim_dir: Vector2 = Vector2.RIGHT
var _sunk: bool = false
var _summary_alpha_override: float = -1.0
var _visual_state: int = VisualState.FLYING
var _has_registered_first_bounce: bool = false
var _tumble_visual_rotation: float = 0.0
var _last_physics_visual_pos: Vector2 = Vector2.ZERO
var _has_last_physics_visual_pos: bool = false

func _ready() -> void:
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.0
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)
	mass = LevelConfig.BALL_BASE_MASS
	visible = true  # safety reset so ball is never hidden on first frame of camera follow (mobile/desktop)
	_reset_visual_state_for_idle()
	_tumble_visual_rotation = 0.0
	_last_physics_visual_pos = global_position
	_has_last_physics_visual_pos = true
	_update_visuals()

func set_min_radius(r: float) -> void:
	_min_radius = maxf(1.0, r)
	_radius = maxf(_radius, _min_radius)
	_update_visuals()
	queue_redraw()


func set_radius(r: float) -> void:
	_radius = clamp(r, _min_radius, 999.0)
	_update_visuals()
	queue_redraw()

func shrink_radius(factor: float = 0.92) -> void:
	if not _launched or _sunk:
		return
	_radius = max(_min_radius, _radius * factor)
	_update_visuals()
	queue_redraw()

func apply_upgrades(bigger: int, heavier: int, poison: int) -> void:
	_poison_level = poison

func set_forcefield_level(level: int) -> void:
	_forcefield_level = maxi(0, level)
	_forcefield_pin_cooldowns.clear()
	_invalidate_forcefield_pin_cache()
	_low_speed_force_stop_timer = 0.0
	queue_redraw()

func set_magnet_positions(positions: Array) -> void:
	_magnet_positions.clear()
	for pos in positions:
		if pos is Vector2:
			_magnet_positions.append(pos)

func set_aim_direction(dir: Vector2) -> void:
	if dir.length() > 0.01:
		_aim_dir = dir.normalized()

func set_initial_velocity(v: Vector2) -> void:
	_launched = true
	_sunk = false
	visible = true
	_summary_alpha_override = -1.0
	freeze = false
	sleeping = false
	linear_velocity = v
	_settling_timer = 0.0
	_low_speed_force_stop_timer = 0.0
	_forced_settle_hold_active = false
	_contacted_pins.clear()
	_forcefield_pin_cooldowns.clear()
	_invalidate_forcefield_pin_cache()
	_trail_points.clear()
	_trail_points.append(global_position)
	_visual_state = VisualState.FLYING
	_has_registered_first_bounce = false
	_tumble_visual_rotation = 0.0
	_last_physics_visual_pos = global_position
	_has_last_physics_visual_pos = true
	queue_redraw()

func set_result_visual(is_winner: bool) -> void:
	_visual_state = VisualState.WINNER if is_winner else VisualState.LOSER
	_launched = false
	_has_registered_first_bounce = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_summary_alpha_override = 1.0
	_has_last_physics_visual_pos = false
	queue_redraw()

func get_radius() -> float:
	return _radius

func is_sunk_in_water() -> bool:
	return _sunk

func set_summary_opacity(alpha: float) -> void:
	_summary_alpha_override = clampf(alpha, 0.0, 1.0)
	queue_redraw()

func clear_summary_opacity() -> void:
	_summary_alpha_override = -1.0
	queue_redraw()

func _reset_visual_state_for_idle() -> void:
	_visual_state = VisualState.FLYING
	_has_registered_first_bounce = false
	_tumble_visual_rotation = 0.0
	_last_physics_visual_pos = global_position
	_has_last_physics_visual_pos = true

func _mark_first_bounce() -> void:
	if not _launched or _sunk or _has_registered_first_bounce:
		return
	_has_registered_first_bounce = true
	_visual_state = VisualState.TUMBLING
	_last_physics_visual_pos = global_position
	_has_last_physics_visual_pos = true
	queue_redraw()

func _get_tumble_spin_direction(motion: Vector2) -> float:
	if motion.length_squared() <= 0.000001:
		return 1.0
	if absf(motion.x) >= absf(motion.y):
		return -1.0 if motion.x >= 0.0 else 1.0
	return 1.0 if motion.y >= 0.0 else -1.0

func _update_tumbling_visual_rotation(delta: float) -> void:
	if _visual_state != VisualState.TUMBLING:
		_last_physics_visual_pos = global_position
		_has_last_physics_visual_pos = true
		return

	if not _has_last_physics_visual_pos:
		_last_physics_visual_pos = global_position
		_has_last_physics_visual_pos = true
		return

	var angular_step: float = angular_velocity * delta
	if absf(angular_step) > 0.0001:
		_tumble_visual_rotation += angular_step
	else:
		var displacement: Vector2 = global_position - _last_physics_visual_pos
		var travel: float = displacement.length()
		if travel > 0.0001:
			var motion_for_sign: Vector2 = linear_velocity if linear_velocity.length_squared() > 0.000001 else displacement / maxf(delta, 0.0001)
			var spin_direction: float = _get_tumble_spin_direction(motion_for_sign)
			_tumble_visual_rotation += spin_direction * (travel / maxf(_radius, 1.0))

	_last_physics_visual_pos = global_position

func _get_current_ball_texture() -> Texture2D:
	match _visual_state:
		VisualState.TUMBLING:
			return BALL_TUMBLING_TEXTURE
		VisualState.WINNER:
			return BALL_WINNER_TEXTURE
		VisualState.LOSER:
			return BALL_LOSER_TEXTURE
		_:
			return BALL_FLYING_TEXTURE

func _get_contacted_pin_from_entry(entry: Variant) -> RigidBody2D:
	var pin_node: Object = null
	if entry == null:
		return null
	if entry is WeakRef:
		pin_node = (entry as WeakRef).get_ref()
	elif entry is Object:
		pin_node = entry as Object
	if pin_node == null or not is_instance_valid(pin_node):
		return null
	if pin_node is Node and (pin_node as Node).is_queued_for_deletion():
		return null
	if not (pin_node is RigidBody2D):
		return null
	return pin_node as RigidBody2D

func _prune_contacted_pins() -> void:
	var stale_ids: Array[int] = []
	for pin_id in _contacted_pins.keys():
		var pin_node: RigidBody2D = _get_contacted_pin_from_entry(_contacted_pins[pin_id])
		if pin_node == null:
			stale_ids.append(int(pin_id))
	for pin_id in stale_ids:
		_contacted_pins.erase(pin_id)

func register_pin_contact(pin: RigidBody2D) -> void:
	if pin == null or not is_instance_valid(pin) or pin.is_queued_for_deletion():
		return
	var pin_id: int = int(pin.get_instance_id())
	_contacted_pins[pin_id] = weakref(pin)
	if pin.has_method("mark_touched_by_ball_this_shot"):
		pin.call("mark_touched_by_ball_this_shot")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("pins") and body is RigidBody2D:
		register_pin_contact(body as RigidBody2D)
	if body != null:
		_mark_first_bounce()
	# Buildings are handled by Main.gd calling apply_hit_slowdown directly

func get_contacted_pins() -> Array:
	_prune_contacted_pins()
	var pins: Array = []
	for entry in _contacted_pins.values():
		var pin_node: RigidBody2D = _get_contacted_pin_from_entry(entry)
		if pin_node != null:
			pins.append(pin_node)
	return pins

func get_trail_points() -> Array[Vector2]:
	return _trail_points.duplicate()

func _record_trail_point() -> void:
	if _trail_points.is_empty():
		_trail_points.append(global_position)
		return
	if _trail_points[_trail_points.size() - 1].distance_to(global_position) >= _trail_record_step:
		_trail_points.append(global_position)

func _invalidate_forcefield_pin_cache() -> void:
	_forcefield_scan_pins_cache.clear()
	_forcefield_scan_cache_populated = false

func _refresh_forcefield_pin_cache() -> void:
	_forcefield_scan_pins_cache.clear()
	for pin_node in get_tree().get_nodes_in_group("pins"):
		if pin_node is RigidBody2D:
			_forcefield_scan_pins_cache.append(weakref(pin_node))
	_forcefield_scan_cache_populated = true

func _get_forcefield_scan_pins() -> Array:
	if not _forcefield_scan_cache_populated:
		_refresh_forcefield_pin_cache()
	var live_pins: Array = []
	var stale_found: bool = false
	for entry in _forcefield_scan_pins_cache:
		if not (entry is WeakRef):
			stale_found = true
			continue
		var ref_node: Object = (entry as WeakRef).get_ref()
		if ref_node == null or not is_instance_valid(ref_node):
			stale_found = true
			continue
		if not (ref_node is RigidBody2D):
			stale_found = true
			continue
		var pin_node: RigidBody2D = ref_node as RigidBody2D
		if pin_node.is_queued_for_deletion():
			stale_found = true
			continue
		live_pins.append(pin_node)
	if stale_found and live_pins.size() != _forcefield_scan_pins_cache.size():
		_forcefield_scan_pins_cache.clear()
		for pin in live_pins:
			_forcefield_scan_pins_cache.append(weakref(pin))
	return live_pins

func _should_redraw_during_physics() -> bool:
	if _sunk:
		return false
	if _forcefield_level > 0:
		return true
	return _visual_state == VisualState.TUMBLING

func _update_visuals() -> void:
	if _shape and _shape.shape is CircleShape2D:
		var cs := _shape.shape as CircleShape2D
		cs.radius = _radius

func _draw() -> void:
	visible = true  # one-line visibility safety reset (ensures ball is drawn on camera follow frame)

	var result_visual_active: bool = _visual_state == VisualState.WINNER or _visual_state == VisualState.LOSER
	var alpha: float = 1.0 if (_launched or result_visual_active) else 0.72
	if _summary_alpha_override >= 0.0:
		alpha = _summary_alpha_override
	var r := _radius

	if _launched and _forcefield_level > 0 and not _sunk:
		_draw_forcefield_ring(alpha)

	var fill_alpha: float = clampf(alpha * 0.98, 0.0, 1.0)
	var outline_alpha: float = clampf(alpha * 0.72, 0.0, 1.0)
	draw_circle(Vector2.ZERO, r, Color(1.0, 1.0, 1.0, fill_alpha))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.0, 0.0, 0.0, outline_alpha), BALL_OUTLINE_WIDTH)

	var ball_texture: Texture2D = _get_current_ball_texture()
	if ball_texture != null:
		_draw_centered_ball_texture(ball_texture, alpha)

	if _visual_state == VisualState.FLYING or _visual_state == VisualState.TUMBLING:
		draw_circle(Vector2.ZERO, CENTER_DOT_RADIUS, Color(CENTER_DOT_COLOR.r, CENTER_DOT_COLOR.g, CENTER_DOT_COLOR.b, alpha))

func _draw_centered_ball_texture(texture: Texture2D, alpha: float) -> void:
	var tex_size: Vector2 = texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var target_max_dim: float = maxf(SPRITE_MIN_DRAW_SIZE, _radius * SPRITE_FILL_MULT)
	var scale: float = target_max_dim / maxf(tex_size.x, tex_size.y)
	var draw_size: Vector2 = tex_size * scale
	var draw_rect := Rect2(-draw_size * 0.5, draw_size)
	var texture_rotation: float = _tumble_visual_rotation if _visual_state == VisualState.TUMBLING else 0.0

	draw_set_transform(Vector2.ZERO, texture_rotation, Vector2.ONE)
	draw_texture_rect(texture, draw_rect, false, Color(1.0, 1.0, 1.0, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_forcefield_ring(alpha: float) -> void:
	var pulse_phase: float = Time.get_ticks_msec() * 0.001 * float(LevelConfig.UPGRADE_FORCEFIELD_RING_PULSE_SPEED)
	var pulse: float = 0.5 + 0.5 * sin(pulse_phase)
	var inner_r: float = _get_forcefield_inner_radius()
	var outer_r: float = _get_forcefield_outer_radius()
	var mid_r: float = (inner_r + outer_r) * 0.5
	var thickness: float = maxf(2.0, outer_r - inner_r)
	var ring_alpha: float = clampf(float(LevelConfig.UPGRADE_FORCEFIELD_RING_ALPHA), 0.0, 1.0) * alpha
	var cyan := Color(0.45, 0.95, 1.0, ring_alpha * (0.78 + 0.22 * pulse))
	var white := Color(1.0, 1.0, 1.0, ring_alpha * (0.22 + 0.18 * pulse))
	var glow := Color(0.35, 0.85, 1.0, ring_alpha * 0.18)

	draw_arc(Vector2.ZERO, mid_r, 0.0, TAU, 72, glow, thickness + 8.0)
	draw_arc(Vector2.ZERO, mid_r, 0.0, TAU, 72, cyan, thickness)
	draw_arc(Vector2.ZERO, mid_r, 0.0, TAU, 72, white, maxf(1.0, thickness * 0.22))

	var spark_count: int = 4 + _forcefield_level * 2
	for i in range(spark_count):
		var a := pulse_phase * 0.9 + float(i) * (TAU / float(spark_count))
		var p := Vector2(cos(a), sin(a)) * (mid_r + thickness * 0.12)
		draw_circle(p, maxf(1.6, thickness * 0.12), Color(1.0, 1.0, 1.0, ring_alpha * 0.72))

func apply_hit_slowdown(multiplier: float) -> void:
	if not _launched or _sunk:
		return
	var speed := linear_velocity.length()
	if speed > 30.0:
		linear_velocity *= clampf(multiplier, 0.05, 1.0)
		_settling_timer = 0.0
		_low_speed_force_stop_timer = 0.0
		if not _forced_settle_hold_active:
			freeze = false
			sleeping = false
	_mark_first_bounce()

func register_zone(area: Area2D) -> void:
	if not area or not area.has_meta("zone_type"):
		return
	var ztype := area.get_meta("zone_type") as String

	if ztype == "friction" and area.has_meta("friction"):
		if not _friction_zones.has(area):
			_friction_zones.append(area)

	elif ztype == "grade" and area.has_meta("grade_accel"):
		var accel: Vector2 = area.get_meta("grade_accel")
		if not _grade_forces.has(accel):
			_grade_forces.append(accel)

	elif ztype == "water":
		if not _water_zones.has(area):
			_water_zones.append(area)

	elif ztype == "map_target":
		# Grand Map target zones are handled directly by Main.gd
		# NEW (persistence): ensure exact world position is available for province lookup on settle
		# NEUTRAL PROVINCE LOCK EXTENSION (March 2026): Main.gd now also sets launch lock for neutral settlements here
		pass

func unregister_zone(area: Area2D) -> void:
	if not area or not area.has_meta("zone_type"):
		return
	var ztype := area.get_meta("zone_type") as String

	if ztype == "friction" and area.has_meta("friction"):
		_friction_zones.erase(area)

	elif ztype == "grade" and area.has_meta("grade_accel"):
		var accel: Vector2 = area.get_meta("grade_accel")
		_grade_forces.erase(accel)

	elif ztype == "water":
		_water_zones.erase(area)

	elif ztype == "map_target":
		# Grand Map target zones are handled directly by Main.gd
		pass

func _prune_friction_zones() -> void:
	for i in range(_friction_zones.size() - 1, -1, -1):
		var area := _friction_zones[i]
		if area == null or not is_instance_valid(area) or area.is_queued_for_deletion():
			_friction_zones.remove_at(i)


func _get_friction_zone_sort_layer(area: Area2D) -> int:
	if area == null:
		return -2147483648
	if area.has_meta("friction_visual_layer"):
		return int(area.get_meta("friction_visual_layer"))
	return area.z_index


func _get_top_visible_friction_mu() -> float:
	_prune_friction_zones()
	if _friction_zones.is_empty():
		return float(LevelConfig.FRICTION_DEFAULT)

	var best_area: Area2D = null
	var best_layer: int = -2147483648
	var best_index: int = -2147483648
	for area in _friction_zones:
		if area == null or not is_instance_valid(area) or area.is_queued_for_deletion():
			continue
		if not area.has_meta("friction"):
			continue
		var layer := _get_friction_zone_sort_layer(area)
		var sibling_index := area.get_index() if area.get_parent() != null else 0
		if best_area == null or layer > best_layer or (layer == best_layer and sibling_index > best_index):
			best_area = area
			best_layer = layer
			best_index = sibling_index

	if best_area != null and best_area.has_meta("friction"):
		return float(best_area.get_meta("friction"))
	return float(LevelConfig.FRICTION_DEFAULT)



func _physics_process(delta: float) -> void:
	if not _launched or _sunk:
		return

	_record_trail_point()
	_advance_forcefield_cooldowns(delta)

	collision_mask = LevelConfig.MASK_PINS | LevelConfig.MASK_WALLS | LevelConfig.MASK_ZONES

	if not _has_registered_first_bounce and get_contact_count() > 0:
		_mark_first_bounce()

	_update_tumbling_visual_rotation(delta)

	if _is_ball_center_in_water_trigger():
		_sink_into_water()
		return

	var speed := linear_velocity.length()

	if _forced_settle_hold_active:
		# Keep the ball hard-clamped at rest until the normal settlement path consumes the shot.
		# Avoid using freeze here; that regressed the stop gate in some runs by interfering
		# with the body update lifecycle before Main.gd finished its dwell-based finalization.
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		sleeping = false
		freeze = false
		if _should_redraw_during_physics():
			queue_redraw()
		return

	if _settling_timer > 0.0:
		_settling_timer -= delta
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		sleeping = true
		if _should_redraw_during_physics():
			queue_redraw()
		return

	var on_grade := not _grade_forces.is_empty()

	var force_stop_speed: float = maxf(0.0, float(LevelConfig.BALL_FORCE_STOP_SPEED_THRESHOLD))
	var force_stop_dwell: float = maxf(0.0, float(LevelConfig.BALL_FORCE_STOP_DWELL_SECONDS))
	if force_stop_speed > 0.0 and speed <= force_stop_speed:
		_low_speed_force_stop_timer += delta
		if _low_speed_force_stop_timer >= force_stop_dwell:
			_begin_forced_settle()
			return
	else:
		_low_speed_force_stop_timer = 0.0

	if speed < LevelConfig.BALL_CREEP_STOP_THRESHOLD or (on_grade and speed < 12.0):
		_begin_forced_settle()
		return

	var total_grade := Vector2.ZERO
	for g in _grade_forces:
		total_grade += g

	if total_grade.length() > 0.01:
		apply_central_force(total_grade)

	_apply_ball_only_magnet_pull()

	var current_mu: float = _get_top_visible_friction_mu()

	if speed > 0.01:
		var decel := current_mu * LevelConfig.FRICTION_DECEL_SCALE
		var friction_dir := -linear_velocity.normalized()
		apply_central_force(friction_dir * decel * mass)

	if _forcefield_level > 0:
		_apply_forcefield_hits()

	if _should_redraw_during_physics():
		queue_redraw()


func _begin_forced_settle() -> void:
	# Hold the ball fully stopped until Main.gd's settlement logic consumes the shot.
	# This is implemented as an explicit velocity clamp, not a body freeze, so it works
	# the same on the grand map and in engagements while still letting Main.gd observe
	# a stable zero-speed ball for its normal dwell-based settlement logic.
	_forced_settle_hold_active = true
	_settling_timer = 0.0
	_low_speed_force_stop_timer = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = false
	freeze = false
	queue_redraw()


func _can_receive_ball_only_magnet_pull() -> bool:
	return _launched and not _sunk and not freeze and visible and is_instance_valid(self)


func _apply_ball_only_magnet_pull() -> void:
	# Magnets are implemented strictly as direct force applied to this ball body.
	# They do not use area gravity, do not touch pins, and do not affect any other object.
	if not _can_receive_ball_only_magnet_pull():
		return
	if _magnet_positions.is_empty():
		return

	var pull_strength: float = maxf(0.0, float(LevelConfig.UPGRADE_MAGNET_PULL_STRENGTH))
	if pull_strength <= 0.0:
		return

	for magnet_pos in _magnet_positions:
		var to_magnet: Vector2 = magnet_pos - global_position
		var dist: float = to_magnet.length()
		if dist <= 0.001:
			continue
		var dir: Vector2 = to_magnet / dist
		var falloff: float = clampf(240.0 / maxf(240.0, dist), 0.18, 1.0)
		apply_central_force(dir * pull_strength * falloff)


func _advance_forcefield_cooldowns(delta: float) -> void:
	if _forcefield_pin_cooldowns.is_empty():
		return
	var expired: Array[int] = []
	for pin_id in _forcefield_pin_cooldowns.keys():
		var remaining: float = float(_forcefield_pin_cooldowns[pin_id]) - delta
		if remaining <= 0.0:
			expired.append(int(pin_id))
		else:
			_forcefield_pin_cooldowns[pin_id] = remaining
	for pin_id in expired:
		_forcefield_pin_cooldowns.erase(pin_id)

func _apply_forcefield_hits() -> void:
	if _forcefield_level <= 0:
		return
	if linear_velocity.length() <= 0.01:
		return

	var inner_r: float = _get_forcefield_inner_radius()
	var outer_r: float = _get_forcefield_outer_radius()
	var outer_r_sq: float = outer_r * outer_r

	for pin_node in _get_forcefield_scan_pins():
		if not (pin_node is RigidBody2D):
			continue
		var pin := pin_node as RigidBody2D
		if pin == null or not is_instance_valid(pin) or pin.is_queued_for_deletion():
			continue

		var pin_id: int = int(pin.get_instance_id())
		if _forcefield_pin_cooldowns.has(pin_id):
			continue

		var proxy_r: float = _get_forcefield_pin_proxy_radius(pin)
		var to_pin: Vector2 = pin.global_position - global_position
		var dist_sq: float = to_pin.length_squared()
		var max_touch_r: float = outer_r + proxy_r
		if dist_sq > max_touch_r * max_touch_r:
			continue

		var min_touch_r: float = maxf(0.0, inner_r - proxy_r)
		if min_touch_r > 0.0 and dist_sq < min_touch_r * min_touch_r:
			continue

		if dist_sq > outer_r_sq and dist_sq > max_touch_r * max_touch_r:
			continue

		# Forcefield contact should count as poison-contact exactly the same way as a direct ball touch.
		# Registering here ensures poison resolution sees these pins even when the ball body itself never reaches them.
		register_pin_contact(pin)

		if pin.has_method("apply_forcefield_hit"):
			pin.call(
				"apply_forcefield_hit",
				global_position,
				linear_velocity,
				_get_forcefield_strength_mult()
			)
			_forcefield_pin_cooldowns[pin_id] = float(LevelConfig.UPGRADE_FORCEFIELD_PIN_REHIT_COOLDOWN)

func _get_forcefield_strength_mult() -> float:
	return maxf(0.0, float(LevelConfig.UPGRADE_FORCEFIELD_PIN_STRENGTH_MULT))

func _get_forcefield_inner_radius() -> float:
	var base_outset: float = float(LevelConfig.UPGRADE_FORCEFIELD_RING_OUTSET)
	var per_level_growth: float = float(LevelConfig.UPGRADE_FORCEFIELD_RING_THICKNESS)
	var extra_outset: float = maxf(0.0, float(_forcefield_level - 1)) * per_level_growth
	return _radius + base_outset + extra_outset

func _get_forcefield_outer_radius() -> float:
	return _get_forcefield_inner_radius() + float(LevelConfig.UPGRADE_FORCEFIELD_RING_THICKNESS)

func _get_forcefield_pin_proxy_radius(pin: RigidBody2D) -> float:
	var scale_mult: float = 1.0
	if pin.has_method("_get_draw_scale"):
		var draw_scale_variant: Variant = pin.call("_get_draw_scale")
		var scale_type: int = typeof(draw_scale_variant)
		if scale_type == TYPE_FLOAT or scale_type == TYPE_INT:
			scale_mult = maxf(0.35, float(draw_scale_variant))
	return maxf(12.0, float(LevelConfig.PIN_HEAD_RADIUS) * 1.35 * scale_mult + 14.0 * scale_mult)

func _sink_into_water() -> void:
	if _sunk:
		return

	_record_trail_point()
	_sunk = true
	_launched = false
	_forced_settle_hold_active = false
	_settling_timer = 0.0
	_low_speed_force_stop_timer = 0.0
	visible = true
	_summary_alpha_override = -1.0
	_has_last_physics_visual_pos = false

	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = true
	freeze = true

	collision_layer = 0
	collision_mask = 0
	set_deferred("monitorable", false)

	_friction_zones.clear()
	_grade_forces.clear()
	_water_zones.clear()
	_forcefield_pin_cooldowns.clear()
	_invalidate_forcefield_pin_cache()

	queue_redraw()
	emit_signal("sunk_in_water")

func _is_ball_center_in_water_trigger() -> bool:
	if _water_zones.is_empty():
		return false

	# Water sinking is driven only by the ball center touching visible water.
	# The forcefield ring never participates in this check.
	var trigger_offset := float(LevelConfig.WATER_BALL_CENTER_TRIGGER_OFFSET)
	for area in _water_zones:
		if is_instance_valid(area) and not area.is_queued_for_deletion():
			if _point_inside_water_zone(global_position, area, trigger_offset):
				return true
	return false

func _point_inside_water_zone(world_point: Vector2, area: Area2D, boundary_offset: float = 0.0) -> bool:
	var local_point: Vector2 = area.to_local(world_point)
	var surface_polygon: PackedVector2Array = _get_water_surface_polygon(area)
	if surface_polygon.size() >= 3:
		return _point_with_boundary_offset_in_polygon(local_point, surface_polygon, boundary_offset)

	var base_radius := float(area.get_meta("zone_radius", 0.0))
	var aspect := maxf(0.42, float(area.get_meta("zone_aspect", 1.0)))
	if base_radius <= 0.001:
		return false

	var rx := base_radius * maxf(1.0, aspect) + boundary_offset
	var ry := base_radius / maxf(0.42, aspect * 0.92) + boundary_offset
	if rx <= 0.001 or ry <= 0.001:
		return false

	var nx := local_point.x / rx
	var ny := local_point.y / ry
	return nx * nx + ny * ny <= 1.0

func _get_water_surface_polygon(area: Area2D) -> PackedVector2Array:
	var poly_variant: Variant = area.get_meta("water_surface_polygon", PackedVector2Array())
	if poly_variant is PackedVector2Array:
		return poly_variant as PackedVector2Array
	return PackedVector2Array()

func _point_with_boundary_offset_in_polygon(local_point: Vector2, polygon: PackedVector2Array, boundary_offset: float = 0.0) -> bool:
	var is_inside: bool = Geometry2D.is_point_in_polygon(local_point, polygon)
	if absf(boundary_offset) <= 0.001:
		return is_inside

	var edge_distance: float = _distance_to_polygon_edges(local_point, polygon)
	if boundary_offset > 0.0:
		return is_inside or edge_distance <= boundary_offset

	return is_inside and edge_distance >= absf(boundary_offset) - 0.0001

func _distance_to_polygon_edges(point: Vector2, polygon: PackedVector2Array) -> float:
	if polygon.size() < 2:
		return INF

	var best: float = INF
	for i in range(polygon.size()):
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		best = minf(best, _distance_point_to_segment(point, a, b))
	return best

func _distance_point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq <= 0.000001:
		return point.distance_to(a)
	var t: float = clampf((point - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return point.distance_to(closest)

func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	pass
