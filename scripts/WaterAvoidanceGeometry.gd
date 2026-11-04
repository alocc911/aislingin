extends RefCounted
## Snapshot the *static* water avoidance geometry once per movement cache refresh.
## All exact ellipse decisions retain the same math and threshold as the
## original Runner/Chief implementations. Water is not moved during combat.
const LevelConfig = preload("res://scripts/LevelConfig.gd")

static func snapshot(areas: Array[Area2D]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var padding: float = LevelConfig.WATER_EDGE_AVOIDANCE_PADDING
	for area in areas:
		if not is_instance_valid(area) or area.is_queued_for_deletion():
			continue
		var base_radius: float = float(area.get_meta("zone_radius", 0.0)) + padding
		var aspect: float = maxf(0.42, float(area.get_meta("zone_aspect", 1.0)))
		var rx: float = base_radius * maxf(1.0, aspect)
		var ry: float = base_radius / maxf(0.42, aspect * 0.92)
		result.append({
			"area": area,
			"center": area.global_position,
			"rotation": area.global_rotation,
			"rx": rx,
			"ry": ry,
			"valid": base_radius > 0.001 and rx > 0.001 and ry > 0.001,
			# For all rotations a circle of this radius encloses the ellipse.
			# The additional margin is deliberately conservative.
			"bound": maxf(absf(rx), absf(ry)) + 1.0
		})
	return result

static func contains(shapes: Array[Dictionary], point: Vector2) -> bool:
	for shape in shapes:
		var area: Area2D = shape.get("area") as Area2D
		if not is_instance_valid(area) or area.is_queued_for_deletion():
			continue
		if not bool(shape.get("valid", false)):
			continue
		var local: Vector2 = point - (shape["center"] as Vector2)
		# Cheap, conservative rejection: this axis-aligned square encloses
		# the entire rotated ellipse, with an extra unit of clearance.
		var bound: float = float(shape["bound"])
		if absf(local.x) > bound or absf(local.y) > bound:
			continue
		var rotation: float = float(shape["rotation"])
		if absf(rotation) > 0.0001:
			local = local.rotated(-rotation)
		var nx: float = local.x / float(shape["rx"])
		var ny: float = local.y / float(shape["ry"])
		if (nx * nx + ny * ny) <= 1.0:
			return true
	return false

static func path_might_touch(shapes: Array[Dictionary], start: Vector2, finish: Vector2) -> bool:
	var min_x: float = minf(start.x, finish.x)
	var max_x: float = maxf(start.x, finish.x)
	var min_y: float = minf(start.y, finish.y)
	var max_y: float = maxf(start.y, finish.y)
	for shape in shapes:
		var area: Area2D = shape.get("area") as Area2D
		if not is_instance_valid(area) or area.is_queued_for_deletion():
			continue
		if not bool(shape.get("valid", false)):
			continue
		var center: Vector2 = shape["center"] as Vector2
		var bound: float = float(shape["bound"])
		if max_x < center.x - bound or min_x > center.x + bound:
			continue
		if max_y < center.y - bound or min_y > center.y + bound:
			continue
		return true
	return false
