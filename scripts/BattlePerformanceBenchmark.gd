extends SceneTree
## CPU-only, fixed-physics-tick battle benchmark using production Pin, Runner,
## Chief, Ball, ZoneTemplate and LevelGenerator code. Never edits gameplay.
##
## Run with --fixed-fps 60: disables real-time synchronization so elapsed
## wall-clock times reflect work, not deliberate 60 Hz sleeping.
##
## godot --headless --fixed-fps 60 --path . --script res://scripts/BattlePerformanceBenchmark.gd -- --ticks 300 --samples 2 --seed-count 2 --output-dir /tmp/battle-bench

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const LevelGeneratorScript = preload("res://scripts/LevelGenerator.gd")
const ZoneTemplateScript = preload("res://scripts/ZoneTemplate.gd")
const WaterAreaRegistryScript = preload("res://scripts/WaterAreaRegistry.gd")
const PinScene: PackedScene = preload("res://scenes/Pin.tscn")
const HeavyScene: PackedScene = preload("res://scenes/HeavyPin.tscn")
const SpikyScene: PackedScene = preload("res://scenes/SpikyPin.tscn")
const RunnerScene: PackedScene = preload("res://scenes/Runner.tscn")
const ChiefScene: PackedScene = preload("res://scenes/Chief.tscn")
const BallScene: PackedScene = preload("res://scenes/Ball.tscn")
const WaterProbe = preload("res://scripts/BattleWaterProbeCounters.gd")
const RunnerProbeScript = preload("res://scripts/BattleWaterProbeRunner.gd")
const ChiefProbeScript = preload("res://scripts/BattleWaterProbeChief.gd")

const SCENARIOS: Array[String] = [
	"small_stationary",
	"large_stationary",
	"large_mobile_dry",
	"large_mobile_water",
	"dense_collisions",
	"full_stress",
	"generated_promoted"
]
const PHYSICS_FPS: int = 60

var _ticks: int = 300
var _warmup_ticks: int = 30
var _samples: int = 2
var _seed_count: int = 2
var _seed_base: int = 71
var _scenario_filter: String = ""
var _output_dir: String = "user://battle-performance-benchmark"
var _strict: bool = false
var _profile_water: bool = false
var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.physics_ticks_per_second = PHYSICS_FPS
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in range(args.size()):
		var key: String = String(args[i])
		if key == "--profile-water":
			_profile_water = true
			continue
		if key == "--strict":
			_strict = true
			continue
		if i + 1 >= args.size():
			continue
		match key:
			"--ticks":
				_ticks = clampi(int(args[i + 1]), 30, 1200)
			"--warmup-ticks":
				_warmup_ticks = clampi(int(args[i + 1]), 1, 120)
			"--samples":
				_samples = clampi(int(args[i + 1]), 2, 10)
			"--seed-count":
				_seed_count = clampi(int(args[i + 1]), 1, 10)
			"--seed-base":
				_seed_base = int(args[i + 1])
			"--scenario":
				_scenario_filter = String(args[i + 1])
			"--output-dir":
				_output_dir = String(args[i + 1])

	if _scenario_filter != "" and not SCENARIOS.has(_scenario_filter):
		printerr("BATTLE_BENCH_ERROR unknown_scenario ", _scenario_filter)
		quit(2)
		return
	var dest: String = ProjectSettings.globalize_path(_output_dir) if _output_dir.begins_with("user://") else _output_dir
	if DirAccess.make_dir_recursive_absolute(dest) != OK:
		printerr("BATTLE_BENCH_ERROR cannot_create_directory ", dest)
		quit(3)
		return

	var cases: Array[Dictionary] = []
	for scenario in SCENARIOS:
		if _scenario_filter != "" and scenario != _scenario_filter:
			continue
		var case_report: Dictionary = await _benchmark_scenario(scenario)
		cases.append(case_report)
		print("BATTLE_BENCH_SCENARIO ", JSON.stringify(case_report))

	var report: Dictionary = {
		"mode": "headless_2d_physics_production_enemy_scripts",
		"engine": Engine.get_version_info().get("string", "unknown"),
		"source_sha": OS.get_environment("GITHUB_SHA"),
		"physics_fps": PHYSICS_FPS,
		"fixed_fps_required": true,
		"ticks_per_replay": _ticks,
		"warmup_ticks_per_replay": _warmup_ticks,
		"samples_per_seed": _samples,
		"seed_count": _seed_count,
		"scenarios": cases,
		"all_deterministic": _failures.is_empty(),
		"profiling_water_scripts": _profile_water,
		"mismatches": _failures,
		"notes": [
			"Uses real pin, ball, zone and native Godot 2D physics code. Synthetic cases replace only the strategic map/UI wrapper.",
			"generated_promoted uses LevelGenerator.generate_into with 300 strategic troops and the production 90-physical-pin limit.",
			"CPU measurements require --fixed-fps 60 to disable 60 Hz waiting. They include physics scripts and native engine step, but not WebGL drawing.",
			"Godot Performance.TIME_PHYSICS_PROCESS reports native+script physics frame cost; elapsed tick timing also includes physics-frame dispatch.",
			"Setup/import time, sprite initialization and collision body creation are measured separately from simulation ticks.",
			"State fingerprints quantize physical coordinates/velocity at 0.01; they are a diagnostic comparison, not proof of pixel-identical browser playback.",
			"Scenarios without a ball measure ambient physics and enemy movement; dense_collisions, full_stress and generated_promoted fire a real Ball."
		]
	}
	var report_path: String = dest.path_join("battle_performance_report.json")
	var file: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		printerr("BATTLE_BENCH_ERROR cannot_write ", report_path)
		quit(4)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	var passed: bool = not _strict or _failures.is_empty()
	print("BATTLE_BENCH_COMPLETE ", JSON.stringify({
		"ok": passed, "report": report_path, "scenarios": cases.size(),
		"all_deterministic": _failures.is_empty(), "mismatches": _failures.size()
	}))
	quit(0 if passed else 5)

func _benchmark_scenario(scenario: String) -> Dictionary:
	var runs: Array[Dictionary] = []
	var reference_hashes: Dictionary = {}
	var matched: bool = true
	var total_times: Array[float] = []
	var physics_times: Array[float] = []
	var pair_maxima: Array[float] = []
	for seed_index in range(_seed_count):
		var fixture_seed: int = _seed_base + seed_index * 1013
		for sample_index in range(_samples):
			var run: Dictionary = await _run_replay(scenario, fixture_seed)
			run["sample"] = sample_index
			runs.append(run)
			var digest: String = String(run.get("state_hash", ""))
			if not reference_hashes.has(fixture_seed):
				reference_hashes[fixture_seed] = digest
			elif reference_hashes[fixture_seed] != digest:
				matched = false
				_failures.append("%s seed=%d sample=%d" % [scenario, fixture_seed, sample_index])
			total_times.append(float(run.get("tick_elapsed_ms_total", 0.0)))
			physics_times.append(float(run.get("physics_monitor_ms_mean", 0.0)))
			pair_maxima.append(float(run.get("physics_pairs_max", 0)))
	return {
		"name": scenario,
		"replays": runs,
		"deterministic": matched,
		"end_hash_by_seed": reference_hashes,
		"tick_elapsed_total_ms": _stats(total_times),
		"physics_monitor_ms_mean": _stats(physics_times),
		"collision_pairs_max": _stats(pair_maxima)
	}

func _run_replay(scenario: String, fixture_seed: int) -> Dictionary:
	seed(fixture_seed * 9187 + SCENARIOS.find(scenario) * 37)
	WaterAreaRegistryScript.invalidate()
	var setup_start: int = Time.get_ticks_usec()
	var fixture: Dictionary = _make_fixture(scenario, fixture_seed)
	var setup_ms: float = _elapsed_ms(setup_start)
	var world: Node2D = fixture["world"] as Node2D
	var pins: Array = fixture["pins"]
	var ball: RigidBody2D = fixture.get("ball", null) as RigidBody2D
	# One process frame flushes Chief.call_deferred and initial overlap registration.
	await process_frame
	# Warmup runs the same production physics but is not included in measurements.
	for _i in range(_warmup_ticks):
		await physics_frame
		await process_frame

	if _profile_water:
		WaterProbe.begin()
	var elapsed_samples: Array[float] = []
	var monitor_samples: Array[float] = []
	var active_samples: Array[float] = []
	var pair_samples: Array[float] = []
	var body_count_at_start: int = 0
	for pin in pins:
		if is_instance_valid(pin):
			body_count_at_start += 1
	for _tick in range(_ticks):
		await physics_frame
		var tick_start: int = Time.get_ticks_usec()
		await process_frame
		elapsed_samples.append(_elapsed_ms(tick_start))
		monitor_samples.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
		active_samples.append(float(Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)))
		pair_samples.append(float(Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS)))

	var water_probe_result: Dictionary = WaterProbe.finish() if _profile_water else {}
	var snapshot: Dictionary = _capture_state(pins, ball)
	var output: Dictionary = {
		"seed": fixture_seed,
		"setup_ms": snappedf(setup_ms, 0.001),
		"pins_spawned": int(fixture.get("pin_count", pins.size())),
		"pins_live_after_warmup": body_count_at_start,
		"enemy_types_spawned": fixture.get("type_counts", {}),
		"water_areas": int(fixture.get("water_count", 0)),
		"obstacles": int(fixture.get("obstacle_count", 0)),
		"ball_spawned": ball != null,
		"tick_elapsed_ms_total": snappedf(_sum(elapsed_samples), 0.001),
		"tick_elapsed_ms": _stats(elapsed_samples),
		"physics_monitor_ms_mean": snappedf(_average(monitor_samples), 0.001),
		"physics_monitor_ms_p95": snappedf(_percentile(monitor_samples, 0.95), 0.001),
		"active_physics_bodies_mean": snappedf(_average(active_samples), 0.01),
		"physics_pairs_mean": snappedf(_average(pair_samples), 0.01),
		"physics_pairs_max": roundi(_max(pair_samples)),
		"end_state": snapshot.get("summary", {}),
		"state_hash": snapshot.get("hash", ""),
		"water_probe": water_probe_result
	}
	world.queue_free()
	await process_frame
	WaterAreaRegistryScript.invalidate()
	return output

func _make_fixture(scenario: String, fixture_seed: int) -> Dictionary:
	var world := Node2D.new()
	world.name = "BattleBenchmarkWorld"
	var zones := Node2D.new()
	zones.name = "Zones"
	var obstacles := Node2D.new()
	obstacles.name = "Obstacles"
	var pins_root := Node2D.new()
	pins_root.name = "Pins"
	var ball_root := Node2D.new()
	ball_root.name = "BallHolder"
	world.add_child(zones)
	world.add_child(obstacles)
	world.add_child(pins_root)
	world.add_child(ball_root)
	root.add_child(world)
	current_scene = world
	_add_bounds(obstacles)
	var setup_rng := RandomNumberGenerator.new()
	setup_rng.seed = fixture_seed
	var water_count: int = 0
	var obstacle_count: int = 0
	if scenario == "generated_promoted":
		var generator = LevelGeneratorScript.new()
		var generated: Dictionary = generator.generate_into(fixture_seed, 10, zones, obstacles, pins_root, null, LevelConfig.PHASE_OFFENSIVE, 0, 300, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)
		if not bool(generated.get("accepted", false)):
			printerr("BATTLE_BENCH_ERROR generated_fixture_not_accepted ", fixture_seed)
		water_count = _count_water_areas(zones)
		obstacle_count = obstacles.get_child_count() - 4
	else:
		if scenario == "large_mobile_water" or scenario == "full_stress":
			_add_water(zones, obstacles, Vector2(-165.0, -150.0), 114.0, 1.20)
			_add_water(zones, obstacles, Vector2(172.0, 135.0), 125.0, 0.72)
			_add_water(zones, obstacles, Vector2(-18.0, 330.0), 78.0, 1.3)
			water_count = 3
		if scenario == "full_stress":
			for i in range(6):
				var pos: Vector2 = Vector2(-240.0 + float(i % 3) * 240.0, -320.0 + float(i / 3) * 560.0)
				ZoneTemplateScript.make_obstacle_island("BenchmarkObstacle", Vector2.ZERO, 34.0).spawn_into(zones, obstacles, pos)
			obstacle_count = 6
		var pin_count: int = 25 if scenario == "small_stationary" else LevelConfig.PROVINCE_PHYSICAL_PIN_LIMIT
		var dense: bool = scenario == "dense_collisions"
		var placed_positions: Array[Vector2] = []
		for i in range(pin_count):
			var scene: PackedScene = _scene_for_index(scenario, i)
			var spawn_at: Vector2 = _place_index(i, pin_count, dense, setup_rng)
			if water_count > 0:
				spawn_at = _find_dry_spawn(spawn_at, zones, placed_positions, setup_rng)
			placed_positions.append(spawn_at)
			var pin: RigidBody2D = scene.instantiate() as RigidBody2D
			if _profile_water and scene == RunnerScene:
				pin.set_script(RunnerProbeScript)
			elif _profile_water and scene == ChiefScene:
				pin.set_script(ChiefProbeScript)
			pins_root.add_child(pin
			pin.global_position = spawn_at
			pin.add_to_group("pins")
			pin.linear_velocity = Vector2.ZERO
			pin.angular_velocity = 0.0
			if pin is Chief:
				pin.call_deferred("_capture_spawn_anchor")

	var pins: Array = []
	var type_counts: Dictionary = {}
	for node in pins_root.get_children():
		if not (node is Pin):
			continue
		pins.append(node)
		var kind: String = _kind(node)
		type_counts[kind] = int(type_counts.get(kind, 0)) + 1

	var launched_ball: RigidBody2D = null
	if scenario in ["dense_collisions", "full_stress", "generated_promoted"]:
		launched_ball = BallScene.instantiate() as RigidBody2D
		ball_root.add_child(launched_ball)
		launched_ball.global_position = Vector2(0.0, -520.0)
		if scenario == "full_stress":
			launched_ball.set_forcefield_level(2)
		launched_ball.set_initial_velocity(Vector2(0.0, 930.0))
	return {
		"world": world, "pins": pins, "ball": launched_ball,
		"pin_count": pins.size(), "type_counts": type_counts,
		"water_count": water_count, "obstacle_count": obstacle_count
	}

func _scene_for_index(scenario: String, i: int) -> PackedScene:
	if scenario == "large_mobile_dry" or scenario == "large_mobile_water":
		return RunnerScene if i % 2 == 0 else ChiefScene
	if scenario == "full_stress":
		match i % 5:
			0, 1:
				return RunnerScene
			2:
				return ChiefScene
			3:
				return SpikyScene
			_:
				return HeavyScene
	if scenario == "dense_collisions":
		match i % 5:
			0, 1:
				return PinScene
			2:
				return HeavyScene
			3:
				return RunnerScene
			_:
				return SpikyScene
	return PinScene if i % 5 != 0 else HeavyScene

func _place_index(i: int, count: int, dense: bool, rng: RandomNumberGenerator) -> Vector2:
	var columns: int = 5 if count <= 25 else 10
	var row: int = i / columns
	var column: int = i % columns
	var x_step: float = 39.0 if dense else 67.0
	var y_step: float = 47.0 if dense else 104.0
	var x: float = (float(column) - float(columns - 1) * 0.5) * x_step
	var rows: int = ceili(float(count) / float(columns))
	var y: float = (float(row) - float(rows - 1) * 0.5) * y_step
	return Vector2(x + rng.randf_range(-3.0, 3.0), y + rng.randf_range(-3.0, 3.0))

func _find_dry_spawn(initial_position: Vector2, zones: Node2D, previous: Array[Vector2], rng: RandomNumberGenerator) -> Vector2:
	# The normal generator rejects water-overlapping spawn points. Mirror that
	# guarantee in synthetic stress cases so all 90 pins start in play.
	if _spawn_is_dry(initial_position, zones) and _spawn_is_separate(initial_position, previous):
		return initial_position
	for _attempt in range(250):
		var candidate := Vector2(rng.randf_range(-315.0, 315.0), rng.randf_range(-470.0, 470.0))
		if _spawn_is_dry(candidate, zones) and _spawn_is_separate(candidate, previous):
			return candidate
	return initial_position


func _spawn_is_dry(position: Vector2, zones: Node2D) -> bool:
	for child in zones.get_children():
		if not (child is Area2D) or str(child.get_meta("zone_type", "")) != "water":
			continue
		var area: Area2D = child as Area2D
		var padding: float = LevelConfig.WATER_SPAWN_CLEARANCE + LevelConfig.PIN_BODY_WIDTH * 0.55
		var radius: float = float(area.get_meta("zone_radius", 0.0)) + padding
		var aspect: float = maxf(0.42, float(area.get_meta("zone_aspect", 1.0)))
		var rx: float = radius * maxf(1.0, aspect)
		var ry: float = radius / maxf(0.42, aspect * 0.92)
		var point: Vector2 = position - area.global_position
		if absf(area.global_rotation) > 0.0001:
			point = point.rotated(-area.global_rotation)
		if rx > 0.0 and ry > 0.0 and pow(point.x / rx, 2.0) + pow(point.y / ry, 2.0) <= 1.0:
			return false
	return true


func _spawn_is_separate(point: Vector2, previous: Array[Vector2]) -> bool:
	for older in previous:
		if older.distance_squared_to(point) < 52.0 * 52.0:
			return false
	return true


func _add_bounds(obstacles: Node2D) -> void:
	for side in range(4):
		var wall := StaticBody2D.new()
		wall.name = "Bounds%d" % side
		wall.collision_layer = LevelConfig.MASK_WALLS
		wall.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		if side < 2:
			wall.position = Vector2(0.0, -600.0 if side == 0 else 600.0)
			rectangle.size = Vector2(800.0, 35.0)
		else:
			wall.position = Vector2(-390.0 if side == 2 else 390.0, 0.0)
			rectangle.size = Vector2(35.0, 1200.0)
		shape.shape = rectangle
		wall.add_child(shape)
		obstacles.add_child(wall)

func _add_water(zones: Node2D, obstacles: Node2D, at: Vector2, radius: float, aspect: float) -> void:
	var template = ZoneTemplateScript.make_water_pool("BenchmarkWater", Vector2.ZERO, radius, aspect)
	template.spawn_into(zones, obstacles, at)

func _count_water_areas(zones: Node2D) -> int:
	var count: int = 0
	for child in zones.get_children():
		if child is Area2D and child.has_meta("zone_type") and str(child.get_meta("zone_type")) == "water":
			count += 1
	return count

func _kind(node: Node) -> String:
	if node is Chief:
		return "Chief"
	if node is Runner:
		return "Runner"
	if node is SpikyPin:
		return "SpikyPin"
	if node is HeavyPin:
		return "HeavyPin"
	return "Pin"

func _capture_state(pins: Array, ball: RigidBody2D) -> Dictionary:
	var data: Array[Dictionary] = []
	var standing: int = 0
	var downed: int = 0
	var sunk: int = 0
	var removed: int = 0
	for pin in pins:
		if not is_instance_valid(pin):
			removed += 1
			data.append({"gone": true})
			continue
		var standing_now: bool = not pin.knocked_over and not pin.is_sunk_in_water()
		if standing_now:
			standing += 1
		elif pin.is_sunk_in_water():
			sunk += 1
		else:
			downed += 1
		data.append({
			"p": [_q(pin.global_position.x), _q(pin.global_position.y)],
			"v": [_q(pin.linear_velocity.x), _q(pin.linear_velocity.y)],
			"r": _q(pin.rotation), "standing": standing_now,
			"knocked": pin.knocked_over, "sunk": pin.is_sunk_in_water()
		})
	var ball_record: Dictionary = {}
	if ball != null and is_instance_valid(ball):
		ball_record = {
			"p": [_q(ball.global_position.x), _q(ball.global_position.y)],
			"v": [_q(ball.linear_velocity.x), _q(ball.linear_velocity.y)],
			"radius": _q(ball.get_radius()), "sunk": ball.is_sunk_in_water()
		}
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(JSON.stringify({"pins": data, "ball": ball_record}).to_utf8_buffer())
	return {
		"hash": ctx.finish().hex_encode(),
		"summary": {
			"standing": standing, "downed": downed, "sunk": sunk,
			"removed": removed, "ball": ball_record
		}
	}

func _q(value: float) -> float:
	return snappedf(value, 0.01)

func _elapsed_ms(started_usec: int) -> float:
	return float(Time.get_ticks_usec() - started_usec) / 1000.0

func _sum(values: Array[float]) -> float:
	var total: float = 0.0
	for v in values:
		total += v
	return total

func _average(values: Array[float]) -> float:
	return _sum(values) / float(maxi(values.size(), 1))

func _max(values: Array[float]) -> float:
	var result: float = 0.0
	for v in values:
		result = maxf(result, v)
	return result

func _percentile(values: Array[float], percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	var index: int = clampi(ceili(float(sorted.size()) * percentile) - 1, 0, sorted.size() - 1)
	return sorted[index]

func _stats(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"samples": 0}
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	var n: int = sorted.size()
	var median: float = sorted[n / 2] if n % 2 == 1 else (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
	return {
		"samples": n, "median": snappedf(median, 0.001),
		"mean": snappedf(_average(values), 0.001),
		"p95": snappedf(_percentile(values, 0.95), 0.001),
		"p99": snappedf(_percentile(values, 0.99), 0.001),
		"min": snappedf(sorted[0], 0.001),
		"max": snappedf(sorted.back(), 0.001)
	}
