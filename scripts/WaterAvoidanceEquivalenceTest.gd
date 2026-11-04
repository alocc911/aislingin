extends SceneTree
## Exhaustive-ish equivalence checks against the original Runner/Chief math.
## Deliberately independent implementation of the old water point and path tests.
const Geometry = preload("res://scripts/WaterAvoidanceGeometry.gd")
const LevelConfig = preload("res://scripts/LevelConfig.gd")

var _checks: int = 0
var _failures: int = 0
var _first_failures: Array[String] = []
var _rng := RandomNumberGenerator.new()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_rng.seed = 981794
	var stage := Node2D.new()
	stage.name = "WaterParityArena"
	root.add_child(stage)
	var areas: Array[Area2D] = []
	var definitions: Array[Array] = [
		[Vector2(-210.0, -160.0), 90.0, 1.2, 0.0],
		[Vector2(220.0, 195.0), 130.0, 0.6, 0.42],
		[Vector2(-10.0, 280.0), 115.0, 1.75, -0.73],
		[Vector2(400.0, -320.0), 12.0, 0.42, 1.05],
		[Vector2(-550.0, 150.0), 235.0, 2.3, -1.20],
		[Vector2(80.0, -530.0), 0.0, 1.0, 0.0],
		[Vector2(580.0, 450.0), -4.0, 0.78, 0.003]
	]
	for def in definitions:
		var area := Area2D.new()
		area.position = def[0]
		area.rotation = float(def[3])
		area.set_meta("zone_radius", float(def[1]))
		area.set_meta("zone_aspect", float(def[2]))
		area.set_meta("zone_type", "water")
		stage.add_child(area)
		areas.append(area)

	var snapshot: Array[Dictionary] = Geometry.snapshot(areas)
	var padding: float = LevelConfig.WATER_EDGE_AVOIDANCE_PADDING

	# Far-field random tests, including exact center and near ellipse boundaries.
	for i in range(24000):
		var point: Vector2 = Vector2(_rng.randf_range(-800.0, 800.0), _rng.randf_range(-850.0, 850.0))
		if i % 4 == 0:
			var selected: Dictionary = snapshot[i % snapshot.size()]
			var radius: float = float(selected["rx"])
			var angle: float = _rng.randf_range(-PI, PI)
			var fraction: float = 0.999 if i % 8 == 0 else 1.001
			point = (selected["center"] as Vector2) + Vector2(cos(angle) * radius * fraction, sin(angle) * float(selected["ry"]) * fraction).rotated(float(selected["rotation"]))
		_assert_same("point", _original_contains(areas, point, padding), Geometry.contains(snapshot, point))

	# Route parity for both discretization intervals used by Runner and Chief.
	for i in range(25000):
		var origin: Vector2 = Vector2(_rng.randf_range(-850.0, 850.0), _rng.randf_range(-850.0, 850.0))
		var dest: Vector2 = Vector2(_rng.randf_range(-850.0, 850.0), _rng.randf_range(-850.0, 850.0))
		if i % 5 == 0:
			dest = origin + Vector2(_rng.randf_range(-30.0, 30.0), _rng.randf_range(-30.0, 30.0))
		if i % 11 == 0:
			dest = origin
		for spacing in [26.0, 28.0]:
			var original: bool = _original_path(areas, origin, dest, padding, spacing)
			var optimized: bool = _optimized_path(snapshot, origin, dest, spacing)
			_assert_same("route@%s" % str(spacing), original, optimized)

	# Refresh snapshots after moving a water body: no stale geometry persists
	# after a geometry refresh.
	areas[0].position += Vector2(48.0, -19.0)
	areas[1].rotation += 0.3
	areas[2].set_meta("zone_radius", 163.0)
	snapshot = Geometry.snapshot(areas)
	for i in range(3000):
		var p: Vector2 = Vector2(_rng.randf_range(-800.0, 800.0), _rng.randf_range(-800.0, 800.0))
		_assert_same("geometry_refresh", _original_contains(areas, p, padding), Geometry.contains(snapshot, p))

	# An empty scene must accept all points/routes without false positives.
	var empty: Array[Dictionary] = []
	for i in range(50):
		var p: Vector2 = Vector2(_rng.randf_range(-900.0, 900.0), _rng.randf_range(-900.0, 900.0))
		_assert_same("empty_contains", false, Geometry.contains(empty, p))
		_assert_same("empty_broadphase", false, Geometry.path_might_touch(empty, Vector2.ZERO, p))

	var report: Dictionary = {"ok": _failures == 0, "checks": _checks, "mismatches": _failures, "first_failures": _first_failures}
	print("WATER_PARITY_COMPLETE ", JSON.stringify(report))
	stage.queue_free()
	quit(0 if _failures == 0 else 5)

func _assert_same(label: String, expected: bool, actual: bool) -> void:
	_checks += 1
	if expected != actual:
		_failures += 1
		if _first_failures.size() < 12:
			_first_failures.append("%s original=%s new=%s" % [label, str(expected), str(actual)])

func _original_contains(areas: Array[Area2D], point: Vector2, padding: float) -> bool:
	for area in areas:
		if not is_instance_valid(area) or area.is_queued_for_deletion():
			continue
		if _original_point_inside(point, area, padding):
			return true
	return false

func _original_point_inside(world_point: Vector2, area: Area2D, padding: float) -> bool:
	var center := area.global_position
	var base_radius := float(area.get_meta("zone_radius", 0.0)) + padding
	var aspect := maxf(0.42, float(area.get_meta("zone_aspect", 1.0)))
	if base_radius <= 0.001:
		return false
	var rx := base_radius * maxf(1.0, aspect)
	var ry := base_radius / maxf(0.42, aspect * 0.92)
	if rx <= 0.001 or ry <= 0.001:
		return false
	var local := world_point - center
	if absf(area.global_rotation) > 0.0001:
		local = local.rotated(-area.global_rotation)
	var nx := local.x / rx
	var ny := local.y / ry
	return (nx * nx + ny * ny) <= 1.0

func _original_path(areas: Array[Area2D], a: Vector2, b: Vector2, padding: float, spacing: float) -> bool:
	var travel := b - a
	var dist := travel.length()
	if dist <= 0.001:
		return _original_contains(areas, a, padding)
	var steps := maxi(2, ceili(dist / spacing))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var sample := a.lerp(b, t)
		if _original_contains(areas, sample, padding):
			return true
	return false

func _optimized_path(shapes: Array[Dictionary], a: Vector2, b: Vector2, spacing: float) -> bool:
	var travel := b - a
	var dist := travel.length()
	if dist <= 0.001:
		return Geometry.contains(shapes, a)
	if not Geometry.path_might_touch(shapes, a, b):
		return false
	var steps := maxi(2, ceili(dist / spacing))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var sample := a.lerp(b, t)
		if Geometry.contains(shapes, sample):
			return true
	return false
