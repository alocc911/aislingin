extends "res://scripts/Chief.gd"
## Research-only profiling subclass; invokes the production implementation unchanged.
const Probe = preload("res://scripts/BattleWaterProbeCounters.gd")

func _physics_process(delta: float) -> void:
	if not Probe.enabled:
		super._physics_process(delta)
		return
	var started: int = Time.get_ticks_usec()
	super._physics_process(delta)
	Probe.record("Chief.physics_total", started)

func _path_crosses_water(from_point: Vector2, to_point: Vector2) -> bool:
	if not Probe.enabled:
		return super._path_crosses_water(from_point, to_point)
	var started: int = Time.get_ticks_usec()
	var value: bool = super._path_crosses_water(from_point, to_point)
	Probe.record("Chief.path_crosses", started)
	return value

func _point_in_known_water(point: Vector2, padding: float = 0.0) -> bool:
	if not Probe.enabled:
		return super._point_in_known_water(point, padding)
	var started: int = Time.get_ticks_usec()
	var value: bool = super._point_in_known_water(point, padding)
	Probe.record("Chief.water_point", started)
	return value

func _point_inside_water_with_padding(world_point: Vector2, area: Area2D, padding: float = 0.0) -> bool:
	if not Probe.enabled:
		return super._point_inside_water_with_padding(world_point, area, padding)
	var started: int = Time.get_ticks_usec()
	var value: bool = super._point_inside_water_with_padding(world_point, area, padding)
	Probe.record("Chief.ellipse", started)
	return value

func _would_step_into_water(dir: Vector2, delta: float) -> bool:
	if not Probe.enabled:
		return super._would_step_into_water(dir, delta)
	var started: int = Time.get_ticks_usec()
	var value: bool = super._would_step_into_water(dir, delta)
	Probe.record("Chief.lookahead", started)
	return value

func _is_target_unsafe(point: Vector2) -> bool:
	if not Probe.enabled:
		return super._is_target_unsafe(point)
	var started: int = Time.get_ticks_usec()
	var value: bool = super._is_target_unsafe(point)
	Probe.record("Chief.target_safety", started)
	return value

func _pick_wander_target() -> void:
	if not Probe.enabled:
		super._pick_wander_target()
		return
	var started: int = Time.get_ticks_usec()
	super._pick_wander_target()
	Probe.record("Chief.target_selection", started)

func _refresh_water_cache() -> void:
	if not Probe.enabled:
		super._refresh_water_cache()
		return
	var started: int = Time.get_ticks_usec()
	super._refresh_water_cache()
	Probe.record("Chief.area_cache_refresh", started)

func _find_nearest_dry_point(origin: Vector2) -> Vector2:
	if not Probe.enabled:
		return super._find_nearest_dry_point(origin)
	var started: int = Time.get_ticks_usec()
	var value: Vector2 = super._find_nearest_dry_point(origin)
	Probe.record("Chief.find_dry_fallback", started)
	return value

func _steer_away_from_water() -> void:
	if not Probe.enabled:
		super._steer_away_from_water()
		return
	var started: int = Time.get_ticks_usec()
	super._steer_away_from_water()
	Probe.record("Chief.steer_away", started)
