extends RefCounted
class_name ZoneTemplate
"""
Reusable zone template for Sunny Slopes.

Holds component definitions (friction, grade, water, obstacle) and knows how to
spawn visuals + physics areas into the world. All drawing and particle logic is
self-contained for clean separation from LevelGenerator.

OFFENSIVE ENGAGEMENT UPDATE (March 2026):
- No changes required — buildings are now instantiated directly as StaticBody2D
  in LevelGenerator.gd (with visual variety: base + roof + windows/door).
- Zone templates remain unchanged and continue to work perfectly for both
  defensive and offensive (normal-size procedural) maps.
"""

const LevelConfig = preload("res://scripts/LevelConfig.gd")

enum ComponentType { FRICTION, GRADE, WATER, OBSTACLE }

var template_name: String = "Template"
var components: Array[Dictionary] = []

# Performance optimization: single shared *template* material.
# We duplicate it per zone so each grade can have its own direction/speed.
static var _shared_grade_template: ParticleProcessMaterial = null
static var _rock_sprite_texture: Texture2D = null
static var _rock_sprite_region: Rect2 = Rect2()
static var _rock_sprite_attempted_load: bool = false
static var _boardwalk_sprite_cache: Dictionary = {}
static var _boardwalk_sprite_attempted: Dictionary = {}
static var _bush_sprite_cache: Dictionary = {}
static var _bush_sprite_attempted: Dictionary = {}

const BOARDWALK_MASK_NORTH: int = 1
const BOARDWALK_MASK_EAST: int = 2
const BOARDWALK_MASK_SOUTH: int = 4
const BOARDWALK_MASK_WEST: int = 8

const ZONE_DRAW_PRIORITY_FRICTION: int = 10
const ZONE_DRAW_PRIORITY_GRADE: int = 20
const ZONE_DRAW_PRIORITY_WATER: int = 100

func _init(p_name: String = "Template", p_components: Array[Dictionary] = []) -> void:
	template_name = p_name
	components = p_components.duplicate(true)

# ==================== FACTORY HELPERS (used by ZoneLibrary) ====================

static func make_bush_cluster(name: String, local_pos: Vector2, radius: float) -> ZoneTemplate:
	return ZoneTemplate.new(name, [{
		"type": ComponentType.FRICTION,
		"local_pos": local_pos,
		"radius": radius,
		"mu": float(LevelConfig.FRICTION_GRASS)
	}])

static func make_boardwalk_rect(name: String, local_pos: Vector2, radius: float, aspect: float = 1.0) -> ZoneTemplate:
	var comps: Array[Dictionary] = [{
		"type": ComponentType.FRICTION,
		"local_pos": local_pos,
		"radius": radius,
		"mu": float(LevelConfig.FRICTION_OIL),
		"aspect": aspect
	}]
	return ZoneTemplate.new(name, comps)

static func make_grade_patch(name: String, local_pos: Vector2, radius: float, accel: Vector2) -> ZoneTemplate:
	return ZoneTemplate.new(name, [{
		"type": ComponentType.GRADE,
		"local_pos": local_pos,
		"radius": radius,
		"accel": accel
	}])

static func make_water_pool(name: String, local_pos: Vector2, radius: float, aspect: float = 1.0) -> ZoneTemplate:
	return ZoneTemplate.new(name, [{
		"type": ComponentType.WATER,
		"local_pos": local_pos,
		"radius": radius,
		"aspect": aspect
	}])

static func make_obstacle_island(name: String, local_pos: Vector2, radius: float) -> ZoneTemplate:
	return ZoneTemplate.new(name, [{
		"type": ComponentType.OBSTACLE,
		"local_pos": local_pos,
		"radius": radius
	}])

# ==================== VISUAL SHAPES ====================

func _bush_leafy_cluster(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n := 32
	for i in n:
		var a := i * TAU / n
		var offset := 0.82 + 0.29 * sin(a * 5.3) + 0.18 * cos(a * 4.1) + 0.11 * sin(a * 9.7) + 0.07 * cos(a * 13.2)
		var x := cos(a) * radius * offset
		var y := sin(a) * radius * offset * 1.12
		points.append(Vector2(x, y))
	return points

func _boardwalk_planks(radius: float, aspect: float = 1.0) -> PackedVector2Array:
	var w := radius * 2.15 * aspect
	var h := radius * 2.15 / maxf(0.2, aspect)
	var hw := w * 0.5
	var hh := h * 0.5
	var points := PackedVector2Array()
	points.append(Vector2(-hw, -hh))
	points.append(Vector2(hw, -hh))
	points.append(Vector2(hw, hh))
	points.append(Vector2(-hw, hh))
	points.append(Vector2(-hw, -hh))
	return points

func _water_pool_shape(radius: float, aspect: float = 1.0, orientation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n := 40
	for i in n:
		var a := i * TAU / n
		var offset := 0.88 + 0.13 * sin(a * 2.9) + 0.09 * cos(a * 5.1) + 0.05 * sin(a * 8.4)
		var x := cos(a) * radius * offset * aspect
		var y := sin(a) * radius * offset / maxf(0.42, aspect * 0.92)
		points.append(Vector2(x, y).rotated(orientation))
	return points

func _scale_polygon(points: PackedVector2Array, scale_vec: Vector2) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	for p in points:
		scaled.append(Vector2(p.x * scale_vec.x, p.y * scale_vec.y))
	return scaled

func _closed_loop(points: PackedVector2Array) -> PackedVector2Array:
	var loop := PackedVector2Array()
	for p in points:
		loop.append(p)
	if not points.is_empty():
		loop.append(points[0])
	return loop

# ==================== GRADE PARTICLE SYSTEM ====================

func _make_grade_flow_particles(parent: Node2D, accel: Vector2, radius: float) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.global_position = Vector2.ZERO
	particles.amount = LevelConfig.GRADE_FLOW_PARTICLES_BASE_AMOUNT
	particles.lifetime = LevelConfig.GRADE_FLOW_PARTICLES_LIFETIME
	particles.speed_scale = 1.0
	particles.explosiveness = 0.0
	particles.randomness = 0.15
	particles.emitting = true
	particles.one_shot = false
	particles.process_material = _create_grade_flow_material(accel, radius)
	particles.visibility_rect = Rect2(-radius * 1.2, -radius * 1.2, radius * 2.4, radius * 2.4)
	particles.modulate = Color(1.0, 1.0, 1.0, 0.95)
	_set_canvas_item_visual_layer(particles, LevelConfig.VISUAL_LAYER_WORLD_PARTICLES)
	parent.add_child(particles)
	return particles

static func _create_grade_flow_material(accel: Vector2, radius: float) -> ParticleProcessMaterial:
	if _shared_grade_template == null:
		var mat := ParticleProcessMaterial.new()
		mat.gravity = Vector3(0, 0, 0)
		mat.scale_min = LevelConfig.GRADE_FLOW_PARTICLES_SCALE_MIN
		mat.scale_max = LevelConfig.GRADE_FLOW_PARTICLES_SCALE_MAX
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		mat.emission_sphere_radius = radius * 0.82

		var gradient := Gradient.new()
		gradient.add_point(0.0, LevelConfig.GRADE_FLOW_SNOW_COLOR)
		gradient.add_point(0.6, LevelConfig.GRADE_FLOW_SNOW_COLOR)
		gradient.add_point(1.0, LevelConfig.GRADE_FLOW_SNOW_COLOR)
		var gradient_tex := GradientTexture2D.new()
		gradient_tex.gradient = gradient
		mat.color_ramp = gradient_tex

		_shared_grade_template = mat

	var mat: ParticleProcessMaterial = _shared_grade_template.duplicate()

	var strength := accel.length()
	var dir := accel.normalized()
	var speed := lerpf(
		LevelConfig.GRADE_FLOW_PARTICLES_SPEED_MIN,
		LevelConfig.GRADE_FLOW_PARTICLES_SPEED_MAX,
		clampf((strength - LevelConfig.GRADE_ACCEL_MIN) / (LevelConfig.GRADE_ACCEL_MAX - LevelConfig.GRADE_ACCEL_MIN), 0.0, 1.0)
	)

	mat.direction = Vector3(dir.x, dir.y, 0.0)
	mat.spread = LevelConfig.GRADE_FLOW_SPREAD_ANGLE
	mat.initial_velocity_min = speed * 0.92
	mat.initial_velocity_max = speed * 1.08

	return mat

# ==================== SPAWN LOGIC (called by LevelGenerator) ====================

func spawn_into(zones_root: Node2D, obstacles_root: Node2D, origin_world: Vector2, rotation: float = 0.0, scale: float = 1.0) -> void:
	for c: Dictionary in components:
		var t: int = int(c.get("type", -1))
		var lp: Vector2 = c.get("local_pos", Vector2.ZERO) as Vector2
		var r: float = float(c.get("radius", 0.0))
		var wp: Vector2 = origin_world + _rot(lp * scale, rotation)
		var wr: float = max(1.0, r * scale)

		match t:
			ComponentType.FRICTION:
				var mu: float = float(c.get("mu", float(LevelConfig.FRICTION_DEFAULT)))
				var aspect: float = c.get("aspect", 1.0) as float
				_make_friction_area(zones_root, wp, wr, mu, aspect)
			ComponentType.GRADE:
				var accel: Vector2 = c.get("accel", Vector2.ZERO) as Vector2
				_make_grade_area(zones_root, wp, wr, _rot(accel, rotation))
			ComponentType.WATER:
				var water_aspect: float = c.get("aspect", 1.0) as float
				_make_water_area(zones_root, wp, wr, water_aspect, rotation)
			ComponentType.OBSTACLE:
				_make_obstacle_island(obstacles_root, wp, wr)

func _assign_zone_draw_priority(zone_node: Node, priority: int) -> void:
	if zone_node == null:
		return
	zone_node.set_meta("zone_draw_priority", priority)


func _sort_zone_children(parent: Node) -> void:
	if parent == null:
		return
	var ordered_children: Array = parent.get_children()
	ordered_children.sort_custom(func(a, b):
		var a_priority: int = 0
		var b_priority: int = 0
		if a != null and a.has_meta("zone_draw_priority"):
			a_priority = int(a.get_meta("zone_draw_priority"))
		if b != null and b.has_meta("zone_draw_priority"):
			b_priority = int(b.get_meta("zone_draw_priority"))
		if a_priority == b_priority:
			return parent.get_children().find(a) < parent.get_children().find(b)
		return a_priority < b_priority
	)
	for i in range(ordered_children.size()):
		parent.move_child(ordered_children[i], i)


func _rot(v: Vector2, angle: float) -> Vector2:
	return v.rotated(angle) if angle != 0.0 else v


func _set_canvas_item_visual_layer(node: Node, layer: int) -> void:
	if node == null or not (node is CanvasItem):
		return
	var item: CanvasItem = node as CanvasItem
	item.z_as_relative = false
	item.z_index = layer


func _set_canvas_item_visual_layer_recursive(node: Node, layer: int) -> void:
	if node == null:
		return
	_set_canvas_item_visual_layer(node, layer)
	for child in node.get_children():
		_set_canvas_item_visual_layer_recursive(child, layer)

# ==================== AREA CREATION ====================

func _make_grade_area(parent: Node2D, pos: Vector2, radius: float, accel: Vector2) -> Area2D:
	var area := Area2D.new()
	area.global_position = pos
	area.collision_layer = LevelConfig.MASK_ZONES
	area.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
	area.monitoring = true
	area.monitorable = true
	area.set_meta("zone_type", "grade")
	area.set_meta("grade_accel", accel)

	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	cs.shape = shape
	area.add_child(cs)

	_make_grade_flow_particles(area, accel, radius)

	area.body_entered.connect(func(body_node): if body_node and body_node.has_method("register_zone"): body_node.register_zone(area))
	area.body_exited.connect(func(body_node): if body_node and body_node.has_method("unregister_zone"): body_node.unregister_zone(area))

	_assign_zone_draw_priority(area, ZONE_DRAW_PRIORITY_GRADE)
	parent.add_child(area)
	_sort_zone_children(parent)
	return area

func _is_boardwalk_friction(mu: float) -> bool:
	return mu < 0.4


func _is_bush_friction(mu: float) -> bool:
	return mu > 1.5


func _boardwalk_half_extents(radius: float, aspect: float) -> Vector2:
	var safe_aspect := maxf(0.2, aspect)
	var half_extents := Vector2(
		radius * 1.075 * safe_aspect,
		radius * 1.075 / safe_aspect
	)
	half_extents.x = maxf(half_extents.x, LevelConfig.RESORT_BOARDWALK_MIN_FOOTPRINT_HALF_EXTENTS.x)
	half_extents.y = maxf(half_extents.y, LevelConfig.RESORT_BOARDWALK_MIN_FOOTPRINT_HALF_EXTENTS.y)
	return half_extents + Vector2.ONE * LevelConfig.RESORT_BOARDWALK_FOOTPRINT_PADDING


func _make_boardwalk_layout(radius: float, aspect: float) -> Dictionary:
	var cell_size := maxf(24.0, LevelConfig.RESORT_BOARDWALK_CELL_SIZE)
	var half_extents := _boardwalk_half_extents(radius, aspect)
	var cols := maxi(1, int(round((half_extents.x * 2.0) / cell_size)))
	var rows := maxi(1, int(round((half_extents.y * 2.0) / cell_size)))
	var default_width := maxi(1, LevelConfig.RESORT_BOARDWALK_DEFAULT_WIDTH_CELLS)
	var safe_aspect := maxf(0.2, aspect)

	if safe_aspect >= 1.12:
		rows = maxi(1, mini(rows, default_width))
	elif safe_aspect <= 0.88:
		cols = maxi(1, mini(cols, default_width))
	else:
		cols = maxi(cols, default_width)
		rows = maxi(rows, default_width)

	var cells: Dictionary = {}
	for iy in range(rows):
		for ix in range(cols):
			cells[Vector2i(ix, iy)] = true

	return {
		"cells": cells,
		"cols": cols,
		"rows": rows,
		"cell_size": cell_size,
		"half_extents": half_extents,
	}


func _boardwalk_cell_local_center(cell: Vector2i, cols: int, rows: int, cell_size: float) -> Vector2:
	return Vector2(
		(float(cell.x) - float(cols - 1) * 0.5) * cell_size,
		(float(cell.y) - float(rows - 1) * 0.5) * cell_size
	)


func _boardwalk_neighbor_mask(cells: Dictionary, cell: Vector2i) -> int:
	var mask := 0
	if cells.has(cell + Vector2i(0, -1)):
		mask |= BOARDWALK_MASK_NORTH
	if cells.has(cell + Vector2i(1, 0)):
		mask |= BOARDWALK_MASK_EAST
	if cells.has(cell + Vector2i(0, 1)):
		mask |= BOARDWALK_MASK_SOUTH
	if cells.has(cell + Vector2i(-1, 0)):
		mask |= BOARDWALK_MASK_WEST
	return mask


func _boardwalk_neighbor_count(mask: int) -> int:
	var count := 0
	if (mask & BOARDWALK_MASK_NORTH) != 0:
		count += 1
	if (mask & BOARDWALK_MASK_EAST) != 0:
		count += 1
	if (mask & BOARDWALK_MASK_SOUTH) != 0:
		count += 1
	if (mask & BOARDWALK_MASK_WEST) != 0:
		count += 1
	return count


func _boardwalk_first_present_side(mask: int) -> int:
	if (mask & BOARDWALK_MASK_NORTH) != 0:
		return BOARDWALK_MASK_NORTH
	if (mask & BOARDWALK_MASK_EAST) != 0:
		return BOARDWALK_MASK_EAST
	if (mask & BOARDWALK_MASK_SOUTH) != 0:
		return BOARDWALK_MASK_SOUTH
	if (mask & BOARDWALK_MASK_WEST) != 0:
		return BOARDWALK_MASK_WEST
	return 0


func _boardwalk_opposite_side(side_mask: int) -> int:
	match side_mask:
		BOARDWALK_MASK_NORTH:
			return BOARDWALK_MASK_SOUTH
		BOARDWALK_MASK_EAST:
			return BOARDWALK_MASK_WEST
		BOARDWALK_MASK_SOUTH:
			return BOARDWALK_MASK_NORTH
		BOARDWALK_MASK_WEST:
			return BOARDWALK_MASK_EAST
	return 0


func _boardwalk_missing_side(mask: int) -> int:
	var full_mask := BOARDWALK_MASK_NORTH | BOARDWALK_MASK_EAST | BOARDWALK_MASK_SOUTH | BOARDWALK_MASK_WEST
	return full_mask & ~mask


func _boardwalk_dir_from_side(side_mask: int) -> Vector2:
	match side_mask:
		BOARDWALK_MASK_NORTH:
			return Vector2.UP
		BOARDWALK_MASK_EAST:
			return Vector2.RIGHT
		BOARDWALK_MASK_SOUTH:
			return Vector2.DOWN
		BOARDWALK_MASK_WEST:
			return Vector2.LEFT
	return Vector2.ZERO


func _boardwalk_side_axis_rotation(side_mask: int) -> float:
	if side_mask == BOARDWALK_MASK_NORTH or side_mask == BOARDWALK_MASK_SOUTH:
		return PI * 0.5
	return 0.0


func _boardwalk_tee_rotation_for_missing_side(side_mask: int) -> float:
	match side_mask:
		BOARDWALK_MASK_NORTH:
			return 0.0
		BOARDWALK_MASK_EAST:
			return PI * 0.5
		BOARDWALK_MASK_SOUTH:
			return PI
		BOARDWALK_MASK_WEST:
			return -PI * 0.5
	return 0.0


func _boardwalk_corner_rotation(mask: int) -> float:
	match mask:
		BOARDWALK_MASK_NORTH | BOARDWALK_MASK_WEST:
			return 0.0
		BOARDWALK_MASK_NORTH | BOARDWALK_MASK_EAST:
			return PI * 0.5
		BOARDWALK_MASK_EAST | BOARDWALK_MASK_SOUTH:
			return PI
		BOARDWALK_MASK_SOUTH | BOARDWALK_MASK_WEST:
			return -PI * 0.5
	return 0.0


func _choose_boardwalk_piece(mask: int) -> Dictionary:
	var neighbor_count := _boardwalk_neighbor_count(mask)

	if neighbor_count <= 0:
		return {"piece": "half", "rotation": 0.0}

	if neighbor_count == 1:
		var side := _boardwalk_first_present_side(mask)
		return {"piece": "half", "rotation": _boardwalk_side_axis_rotation(side)}

	if neighbor_count == 2:
		var has_vertical := (mask & BOARDWALK_MASK_NORTH) != 0 and (mask & BOARDWALK_MASK_SOUTH) != 0
		var has_horizontal := (mask & BOARDWALK_MASK_EAST) != 0 and (mask & BOARDWALK_MASK_WEST) != 0
		if has_vertical:
			return {"piece": "main", "rotation": 0.0}
		if has_horizontal:
			return {"piece": "main", "rotation": PI * 0.5}
		return {"piece": "corner", "rotation": _boardwalk_corner_rotation(mask)}

	if neighbor_count == 3:
		var missing_side := _boardwalk_missing_side(mask)
		return {"piece": "tee", "rotation": _boardwalk_tee_rotation_for_missing_side(missing_side)}

	return {"piece": "main", "rotation": 0.0}


func _first_existing_resource_path(candidates: PackedStringArray) -> String:
	for candidate in candidates:
		if candidate.is_empty():
			continue
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


func _boardwalk_sprite_path_for_key(piece_key: String) -> String:
	var resolved := _first_existing_resource_path(LevelConfig.get_boardwalk_sprite_candidate_paths(piece_key))
	if not resolved.is_empty():
		return resolved

	match piece_key:
		"main":
			return LevelConfig.RESORT_BOARDWALK_MAIN_SPRITE_PATH
		"corner":
			return LevelConfig.RESORT_BOARDWALK_CORNER_SPRITE_PATH
		"tee":
			return LevelConfig.RESORT_BOARDWALK_TEE_SPRITE_PATH
		"half":
			return LevelConfig.RESORT_BOARDWALK_HALF_SPRITE_PATH
		"plank":
			return LevelConfig.RESORT_BOARDWALK_PLANK_SPRITE_PATH
		"halfplank":
			return LevelConfig.RESORT_BOARDWALK_HALFPLANK_SPRITE_PATH
	return ""


func _boardwalk_target_size_for_key(piece_key: String) -> Vector2:
	match piece_key:
		"main":
			return LevelConfig.RESORT_BOARDWALK_MAIN_TARGET_SIZE
		"corner":
			return LevelConfig.RESORT_BOARDWALK_CORNER_TARGET_SIZE
		"tee":
			return LevelConfig.RESORT_BOARDWALK_TEE_TARGET_SIZE
		"half":
			return LevelConfig.RESORT_BOARDWALK_HALF_TARGET_SIZE
		"plank":
			return LevelConfig.RESORT_BOARDWALK_PLANK_TARGET_SIZE
		"halfplank":
			return LevelConfig.RESORT_BOARDWALK_HALFPLANK_TARGET_SIZE
	return Vector2.ONE


func _ensure_boardwalk_sprite_loaded(piece_key: String) -> void:
	if _boardwalk_sprite_attempted.get(piece_key, false):
		return
	_boardwalk_sprite_attempted[piece_key] = true

	var sprite_path := _boardwalk_sprite_path_for_key(piece_key)
	if sprite_path.is_empty():
		return
	if not ResourceLoader.exists(sprite_path):
		return

	var texture := load(sprite_path) as Texture2D
	if texture == null:
		return

	var region := Rect2(Vector2.ZERO, texture.get_size())
	var image := Image.load_from_file(sprite_path)
	if image != null and not image.is_empty():
		var used_rect: Rect2i = image.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0:
			region = Rect2(used_rect.position, used_rect.size)

	_boardwalk_sprite_cache[piece_key] = {
		"texture": texture,
		"region": region,
	}


func _can_use_boardwalk_sprite(piece_key: String) -> bool:
	_ensure_boardwalk_sprite_loaded(piece_key)
	if not _boardwalk_sprite_cache.has(piece_key):
		return false
	var info: Dictionary = _boardwalk_sprite_cache[piece_key]
	var texture := info.get("texture", null) as Texture2D
	var region: Rect2 = info.get("region", Rect2())
	return texture != null and region.size.x > 0.0 and region.size.y > 0.0


func _make_boardwalk_sprite(piece_key: String, local_pos: Vector2, local_rotation: float = 0.0) -> Sprite2D:
	if not _can_use_boardwalk_sprite(piece_key):
		return null

	var info: Dictionary = _boardwalk_sprite_cache[piece_key]
	var texture := info.get("texture", null) as Texture2D
	var region: Rect2 = info.get("region", Rect2())
	if texture == null:
		return null

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.position = local_pos
	sprite.rotation = local_rotation

	var source_size := region.size
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		source_size = texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		source_size = Vector2.ONE

	var target_size := _boardwalk_target_size_for_key(piece_key) - Vector2.ONE * (LevelConfig.RESORT_BOARDWALK_VISUAL_INSET * 2.0)
	target_size = Vector2(maxf(1.0, target_size.x), maxf(1.0, target_size.y))
	sprite.scale = Vector2(target_size.x / source_size.x, target_size.y / source_size.y)
	_set_canvas_item_visual_layer(sprite, LevelConfig.VISUAL_LAYER_BOARDWALK)
	return sprite


func _make_shadow_sprite_from(source: Sprite2D, offset: Vector2 = Vector2(4.0, 5.0), alpha: float = 0.22) -> Sprite2D:
	if source == null:
		return null
	var shadow := Sprite2D.new()
	shadow.texture = source.texture
	shadow.centered = source.centered
	shadow.region_enabled = source.region_enabled
	shadow.region_rect = source.region_rect
	shadow.position = source.position + offset
	shadow.rotation = source.rotation
	shadow.scale = source.scale
	shadow.modulate = Color(0.0, 0.0, 0.0, alpha)
	_set_canvas_item_visual_layer(shadow, LevelConfig.VISUAL_LAYER_BOARDWALK)
	return shadow

func _make_shadow_sprite_for_layer(source: Sprite2D, offset: Vector2, alpha: float, layer: int) -> Sprite2D:
	if source == null:
		return null
	var shadow := Sprite2D.new()
	shadow.texture = source.texture
	shadow.centered = source.centered
	shadow.region_enabled = source.region_enabled
	shadow.region_rect = source.region_rect
	shadow.position = source.position + offset
	shadow.rotation = source.rotation
	shadow.scale = source.scale
	shadow.modulate = Color(0.0, 0.0, 0.0, alpha)
	_set_canvas_item_visual_layer(shadow, layer)
	return shadow



func _make_boardwalk_fallback_polygon(piece_key: String, local_pos: Vector2, local_rotation: float = 0.0) -> Polygon2D:
	var poly := Polygon2D.new()
	var target_size := _boardwalk_target_size_for_key(piece_key)
	var half := target_size * 0.5
	poly.color = LevelConfig.RESORT_BOARDWALK
	poly.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	poly.position = local_pos
	poly.rotation = local_rotation
	_set_canvas_item_visual_layer(poly, LevelConfig.VISUAL_LAYER_BOARDWALK)
	return poly


func _add_boardwalk_support_pieces(parent: Node2D, local_pos: Vector2, mask: int) -> void:
	var neighbor_count := _boardwalk_neighbor_count(mask)
	var placed := 0

	if neighbor_count == 1 and placed < LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_MAX_PER_CELL:
		var neighbor_side := _boardwalk_first_present_side(mask)
		var open_side := _boardwalk_opposite_side(neighbor_side)
		var open_dir := _boardwalk_dir_from_side(open_side)
		var detail_pos := local_pos + open_dir * LevelConfig.RESORT_BOARDWALK_ENDCAP_INSET
		detail_pos += Vector2(
			randf_range(-LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_JITTER, LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_JITTER),
			randf_range(-LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_JITTER, LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_JITTER)
		)
		var halfplank := _make_boardwalk_sprite("halfplank", detail_pos, _boardwalk_side_axis_rotation(open_side))
		if halfplank != null:
			var halfplank_shadow := _make_shadow_sprite_from(halfplank, Vector2(2.0, 3.0), 0.16)
			if halfplank_shadow != null:
				parent.add_child(halfplank_shadow)
			parent.add_child(halfplank)
			placed += 1

	if neighbor_count == 3 and placed < LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_MAX_PER_CELL:
		var missing_side := _boardwalk_missing_side(mask)
		var missing_dir := _boardwalk_dir_from_side(missing_side)
		var detail_pos := local_pos + missing_dir * LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_INSET
		detail_pos += Vector2(
			randf_range(-LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_JITTER, LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_JITTER),
			randf_range(-LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_JITTER, LevelConfig.RESORT_BOARDWALK_SUPPORT_PLANK_JITTER)
		)
		var plank_rotation := _boardwalk_side_axis_rotation(missing_side)
		var plank := _make_boardwalk_sprite("plank", detail_pos, plank_rotation)
		if plank != null:
			var plank_shadow := _make_shadow_sprite_from(plank, Vector2(2.0, 3.0), 0.14)
			if plank_shadow != null:
				parent.add_child(plank_shadow)
			parent.add_child(plank)


func _add_boardwalk_collision_runs(area: Area2D, layout: Dictionary) -> void:
	var cells: Dictionary = layout.get("cells", {})
	var cols := int(layout.get("cols", 1))
	var rows := int(layout.get("rows", 1))
	var cell_size := float(layout.get("cell_size", LevelConfig.RESORT_BOARDWALK_CELL_SIZE))
	var overlap := LevelConfig.RESORT_BOARDWALK_CELL_OVERLAP
	var margin := LevelConfig.RESORT_BOARDWALK_FRICTION_MARGIN
	var shape_height := maxf(8.0, cell_size + overlap * 2.0 - margin * 2.0)

	for iy in range(rows):
		var run_start := -1
		for ix in range(cols + 1):
			var occupied := ix < cols and cells.has(Vector2i(ix, iy))
			if occupied and run_start < 0:
				run_start = ix
			elif not occupied and run_start >= 0:
				var run_end := ix - 1
				var run_length := run_end - run_start + 1
				var cs := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(
					maxf(8.0, float(run_length) * cell_size + overlap * 2.0 - margin * 2.0),
					shape_height
				)
				cs.shape = rect
				cs.position = Vector2(
					((float(run_start + run_end) * 0.5) - float(cols - 1) * 0.5) * cell_size,
					(float(iy) - float(rows - 1) * 0.5) * cell_size
				)
				area.add_child(cs)
				run_start = -1


func _add_boardwalk_visuals(area: Area2D, layout: Dictionary) -> void:
	var cells: Dictionary = layout.get("cells", {})
	var cols := int(layout.get("cols", 1))
	var rows := int(layout.get("rows", 1))
	var cell_size := float(layout.get("cell_size", LevelConfig.RESORT_BOARDWALK_CELL_SIZE))

	var visual_root := Node2D.new()
	_set_canvas_item_visual_layer(visual_root, LevelConfig.VISUAL_LAYER_BOARDWALK)
	area.add_child(visual_root)

	for key in cells.keys():
		var cell: Vector2i = key
		var local_pos := _boardwalk_cell_local_center(cell, cols, rows, cell_size)
		var mask := _boardwalk_neighbor_mask(cells, cell)
		var piece := _choose_boardwalk_piece(mask)
		var piece_key := str(piece.get("piece", "main"))
		var piece_rotation := float(piece.get("rotation", 0.0))

		var sprite := _make_boardwalk_sprite(piece_key, local_pos, piece_rotation)
		if sprite != null:
			var shadow := _make_shadow_sprite_from(sprite)
			if shadow != null:
				visual_root.add_child(shadow)
			visual_root.add_child(sprite)
		else:
			var fallback := _make_boardwalk_fallback_polygon(piece_key, local_pos, piece_rotation)
			visual_root.add_child(fallback)

		_add_boardwalk_support_pieces(visual_root, local_pos, mask)

	_set_canvas_item_visual_layer_recursive(visual_root, LevelConfig.VISUAL_LAYER_BOARDWALK)



func _rotation_for_side(side_mask: int) -> float:
	match side_mask:
		BOARDWALK_MASK_NORTH:
			return 0.0
		BOARDWALK_MASK_EAST:
			return PI * 0.5
		BOARDWALK_MASK_SOUTH:
			return PI
		BOARDWALK_MASK_WEST:
			return -PI * 0.5
	return 0.0


func _rotation_for_diagonal_index(diagonal_index: int) -> float:
	match diagonal_index:
		0:
			return 0.0
		1:
			return PI * 0.5
		2:
			return PI
		3:
			return -PI * 0.5
	return 0.0


func _stable_cell_hash(cell: Vector2i, zone_seed: int, salt: int = 0) -> int:
	return int(abs(hash("%d:%d:%d:%d" % [cell.x, cell.y, zone_seed, salt])))


func _stable_cell_randf(cell: Vector2i, zone_seed: int, salt: int = 0) -> float:
	return float(_stable_cell_hash(cell, zone_seed, salt) % 1000000) / 999999.0


func _stable_cell_range(cell: Vector2i, zone_seed: int, salt: int, min_value: float, max_value: float) -> float:
	return lerpf(min_value, max_value, _stable_cell_randf(cell, zone_seed, salt))


func _bush_half_extents(radius: float, aspect: float) -> Vector2:
	var safe_aspect := maxf(0.2, aspect)
	var half_extents := Vector2(
		radius * 1.05 * safe_aspect,
		radius * 1.05 / safe_aspect
	)
	half_extents.x = maxf(half_extents.x, LevelConfig.RESORT_BUSH_MIN_FOOTPRINT_HALF_EXTENTS.x)
	half_extents.y = maxf(half_extents.y, LevelConfig.RESORT_BUSH_MIN_FOOTPRINT_HALF_EXTENTS.y)
	return half_extents + Vector2.ONE * LevelConfig.RESORT_BUSH_FOOTPRINT_PADDING


func _make_bush_layout(radius: float, aspect: float) -> Dictionary:
	var cell_size := maxf(20.0, LevelConfig.RESORT_BUSH_CELL_SIZE)
	var half_extents := _bush_half_extents(radius, aspect)
	var cols := maxi(1, int(ceil((half_extents.x * 2.0) / cell_size)))
	var rows := maxi(1, int(ceil((half_extents.y * 2.0) / cell_size)))
	if (cols % 2) == 0:
		cols += 1
	if (rows % 2) == 0:
		rows += 1

	var cells: Dictionary = {}
	var inner_half_x := maxf(cell_size * 0.5, half_extents.x - cell_size * 0.28)
	var inner_half_y := maxf(cell_size * 0.5, half_extents.y - cell_size * 0.28)

	for iy in range(rows):
		for ix in range(cols):
			var cell := Vector2i(ix, iy)
			var center := _boardwalk_cell_local_center(cell, cols, rows, cell_size)
			var nx := center.x / inner_half_x
			var ny := center.y / inner_half_y
			var dist := nx * nx + ny * ny
			var wobble := 0.10 * sin(float(ix + 1) * 1.31) + 0.08 * cos(float(iy + 1) * 1.77) + 0.05 * sin(float(ix + iy + 1) * 2.19)
			if dist <= 1.0 + wobble:
				cells[cell] = true

	if cells.is_empty():
		cells[Vector2i(cols / 2, rows / 2)] = true

	var pruned: Dictionary = {}
	for key in cells.keys():
		var cell: Vector2i = key
		var neighbor_count := _boardwalk_neighbor_count(_boardwalk_neighbor_mask(cells, cell))
		if neighbor_count > 0 or cells.size() == 1:
			pruned[cell] = true
	if pruned.is_empty():
		pruned = cells

	return {
		"cells": pruned,
		"cols": cols,
		"rows": rows,
		"cell_size": cell_size,
		"half_extents": half_extents,
	}


func _bush_diagonal_present(cells: Dictionary, cell: Vector2i, diagonal_index: int) -> bool:
	match diagonal_index:
		0:
			return cells.has(cell + Vector2i(-1, -1))
		1:
			return cells.has(cell + Vector2i(1, -1))
		2:
			return cells.has(cell + Vector2i(1, 1))
		3:
			return cells.has(cell + Vector2i(-1, 1))
	return false


func _bush_choose_piece(cells: Dictionary, cell: Vector2i, zone_seed: int) -> Dictionary:
	var mask := _boardwalk_neighbor_mask(cells, cell)
	var neighbor_count := _boardwalk_neighbor_count(mask)

	if neighbor_count <= 0:
		return {"piece": "endcap", "rotation": 0.0, "mask": mask, "interior": false}

	if neighbor_count == 1:
		var neighbor_side := _boardwalk_first_present_side(mask)
		var open_side := _boardwalk_opposite_side(neighbor_side)
		return {"piece": "endcap", "rotation": _rotation_for_side(open_side), "mask": mask, "interior": false}

	if neighbor_count == 2:
		var has_vertical := (mask & BOARDWALK_MASK_NORTH) != 0 and (mask & BOARDWALK_MASK_SOUTH) != 0
		var has_horizontal := (mask & BOARDWALK_MASK_EAST) != 0 and (mask & BOARDWALK_MASK_WEST) != 0
		if has_vertical:
			return {"piece": "straight", "rotation": 0.0, "mask": mask, "interior": false}
		if has_horizontal:
			return {"piece": "straight", "rotation": PI * 0.5, "mask": mask, "interior": false}
		return {"piece": "convex", "rotation": _boardwalk_corner_rotation(mask), "mask": mask, "interior": false}

	if neighbor_count == 3:
		var missing_side := _boardwalk_missing_side(mask)
		return {"piece": "transition", "rotation": _rotation_for_side(missing_side), "mask": mask, "interior": false}

	var missing_diagonals: Array[int] = []
	for diagonal_index in range(4):
		if not _bush_diagonal_present(cells, cell, diagonal_index):
			missing_diagonals.append(diagonal_index)
	if not missing_diagonals.is_empty():
		var choice_index := _stable_cell_hash(cell, zone_seed, 301) % missing_diagonals.size()
		var diagonal_index := int(missing_diagonals[choice_index])
		return {"piece": "concave", "rotation": _rotation_for_diagonal_index(diagonal_index), "mask": mask, "interior": true}

	return {"piece": "interior_clump", "rotation": _stable_cell_range(cell, zone_seed, 302, -0.10, 0.10), "mask": mask, "interior": true}


func _bush_sprite_cache_key(piece_key: String, variant_index: int) -> String:
	return piece_key + "#" + str(variant_index)


func _bush_sprite_path_for_key(piece_key: String, variant_index: int = -1) -> String:
	var resolved := _first_existing_resource_path(LevelConfig.get_bush_sprite_candidate_paths(piece_key, variant_index))
	if not resolved.is_empty():
		return resolved
	if variant_index >= 0:
		resolved = _first_existing_resource_path(LevelConfig.get_bush_sprite_candidate_paths(piece_key))
		if not resolved.is_empty():
			return resolved
	return ""


func _ensure_bush_sprite_loaded(piece_key: String, variant_index: int = -1) -> void:
	var cache_key := _bush_sprite_cache_key(piece_key, variant_index)
	if _bush_sprite_attempted.get(cache_key, false):
		return
	_bush_sprite_attempted[cache_key] = true

	var sprite_path := _bush_sprite_path_for_key(piece_key, variant_index)
	if sprite_path.is_empty():
		return
	if not ResourceLoader.exists(sprite_path):
		return

	var texture := load(sprite_path) as Texture2D
	if texture == null:
		return

	var region := Rect2(Vector2.ZERO, texture.get_size())
	var image := Image.load_from_file(sprite_path)
	if image != null and not image.is_empty():
		var used_rect: Rect2i = image.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0:
			region = Rect2(used_rect.position, used_rect.size)

	_bush_sprite_cache[cache_key] = {
		"texture": texture,
		"region": region,
	}


func _can_use_bush_sprite(piece_key: String, variant_index: int = -1) -> bool:
	var cache_key := _bush_sprite_cache_key(piece_key, variant_index)
	_ensure_bush_sprite_loaded(piece_key, variant_index)
	if not _bush_sprite_cache.has(cache_key):
		return false
	var info: Dictionary = _bush_sprite_cache[cache_key]
	var texture := info.get("texture", null) as Texture2D
	var region: Rect2 = info.get("region", Rect2())
	return texture != null and region.size.x > 0.0 and region.size.y > 0.0


func _make_bush_sprite(piece_key: String, variant_index: int, local_pos: Vector2, local_rotation: float = 0.0) -> Sprite2D:
	if not _can_use_bush_sprite(piece_key, variant_index):
		return null

	var cache_key := _bush_sprite_cache_key(piece_key, variant_index)
	var info: Dictionary = _bush_sprite_cache[cache_key]
	var texture := info.get("texture", null) as Texture2D
	var region: Rect2 = info.get("region", Rect2())
	if texture == null:
		return null

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.position = local_pos
	sprite.rotation = local_rotation

	var source_size := region.size
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		source_size = texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		source_size = Vector2.ONE

	var target_size := LevelConfig.get_bush_target_size_for_key(piece_key) - Vector2.ONE * (LevelConfig.RESORT_BUSH_VISUAL_INSET * 2.0)
	target_size = Vector2(maxf(1.0, target_size.x), maxf(1.0, target_size.y))
	sprite.scale = Vector2(target_size.x / source_size.x, target_size.y / source_size.y)
	_set_canvas_item_visual_layer(sprite, LevelConfig.VISUAL_LAYER_BUSHES)
	return sprite


func _make_bush_backdrop(layout: Dictionary) -> Node2D:
	var half_extents: Vector2 = layout.get("half_extents", Vector2.ONE * 64.0)
	var backdrop_root := Node2D.new()

	var base_radius := maxf(half_extents.x, half_extents.y)
	var base_poly_points := _bush_leafy_cluster(base_radius)
	var scale_vec := Vector2(
		half_extents.x / maxf(1.0, base_radius),
		half_extents.y / maxf(1.0, base_radius * 1.12)
	)

	var base := Polygon2D.new()
	base.color = Color(LevelConfig.RESORT_BUSHES.r * 0.82, LevelConfig.RESORT_BUSHES.g * 0.82, LevelConfig.RESORT_BUSHES.b * 0.82, 0.88)
	base.polygon = _scale_polygon(base_poly_points, scale_vec)
	_set_canvas_item_visual_layer(base, LevelConfig.VISUAL_LAYER_BUSHES)
	backdrop_root.add_child(base)

	var inner := Polygon2D.new()
	inner.color = Color(LevelConfig.RESORT_BUSHES_INNER.r, LevelConfig.RESORT_BUSHES_INNER.g, LevelConfig.RESORT_BUSHES_INNER.b, 0.58)
	inner.polygon = _scale_polygon(base_poly_points, scale_vec * Vector2(0.78, 0.76))
	inner.position = Vector2(0.0, -half_extents.y * 0.04)
	_set_canvas_item_visual_layer(inner, LevelConfig.VISUAL_LAYER_BUSHES)
	backdrop_root.add_child(inner)

	return backdrop_root


func _make_bush_fallback_polygon(piece_key: String, local_pos: Vector2, local_rotation: float = 0.0) -> Polygon2D:
	var poly := Polygon2D.new()
	var target_size := LevelConfig.get_bush_target_size_for_key(piece_key)
	var radius := maxf(18.0, minf(target_size.x, target_size.y) * 0.34)
	var shape := _bush_leafy_cluster(radius)

	match piece_key:
		"straight":
			shape = _scale_polygon(shape, Vector2(1.10, 0.84))
			poly.color = Color(LevelConfig.RESORT_BUSHES.r, LevelConfig.RESORT_BUSHES.g, LevelConfig.RESORT_BUSHES.b, 0.94)
		"convex":
			shape = _scale_polygon(shape, Vector2(0.92, 0.92))
			poly.color = Color(LevelConfig.RESORT_BUSHES.r * 1.03, LevelConfig.RESORT_BUSHES.g * 1.03, LevelConfig.RESORT_BUSHES.b * 1.03, 0.94)
		"concave":
			shape = _scale_polygon(shape, Vector2(0.98, 0.98))
			poly.color = Color(LevelConfig.RESORT_BUSHES_INNER.r, LevelConfig.RESORT_BUSHES_INNER.g, LevelConfig.RESORT_BUSHES_INNER.b, 0.92)
		"transition":
			shape = _scale_polygon(shape, Vector2(1.00, 0.96))
			poly.color = Color(LevelConfig.RESORT_BUSHES.r * 0.96, LevelConfig.RESORT_BUSHES.g * 0.96, LevelConfig.RESORT_BUSHES.b * 0.96, 0.95)
		"endcap":
			shape = _scale_polygon(shape, Vector2(0.82, 1.06))
			poly.color = Color(LevelConfig.RESORT_BUSHES.r * 1.04, LevelConfig.RESORT_BUSHES.g * 1.04, LevelConfig.RESORT_BUSHES.b * 1.04, 0.96)
		"filler":
			shape = _scale_polygon(shape, Vector2(0.84, 0.78))
			poly.color = Color(LevelConfig.RESORT_BUSHES.r * 0.94, LevelConfig.RESORT_BUSHES.g * 0.94, LevelConfig.RESORT_BUSHES.b * 0.94, 0.82)
		"accent":
			shape = _scale_polygon(shape, Vector2(0.52, 0.52))
			poly.color = Color(LevelConfig.RESORT_BUSHES_INNER.r * 1.08, LevelConfig.RESORT_BUSHES_INNER.g * 1.08, LevelConfig.RESORT_BUSHES_INNER.b * 1.08, 0.84)
		_:
			shape = _scale_polygon(shape, Vector2(0.72, 0.72))
			poly.color = Color(LevelConfig.RESORT_BUSHES_INNER.r, LevelConfig.RESORT_BUSHES_INNER.g, LevelConfig.RESORT_BUSHES_INNER.b, 0.88)

	poly.polygon = shape
	poly.position = local_pos
	poly.rotation = local_rotation
	_set_canvas_item_visual_layer(poly, LevelConfig.VISUAL_LAYER_BUSHES)
	return poly


func _add_bush_collision_runs(area: Area2D, layout: Dictionary) -> void:
	var cells: Dictionary = layout.get("cells", {})
	var cols := int(layout.get("cols", 1))
	var rows := int(layout.get("rows", 1))
	var cell_size := float(layout.get("cell_size", LevelConfig.RESORT_BUSH_CELL_SIZE))
	var overlap := LevelConfig.RESORT_BUSH_CELL_OVERLAP
	var inset := LevelConfig.RESORT_BUSH_VISUAL_INSET
	var shape_height := maxf(8.0, cell_size + overlap * 2.0 - inset * 2.0)

	for iy in range(rows):
		var run_start := -1
		for ix in range(cols + 1):
			var occupied := ix < cols and cells.has(Vector2i(ix, iy))
			if occupied and run_start < 0:
				run_start = ix
			elif not occupied and run_start >= 0:
				var run_end := ix - 1
				var run_length := run_end - run_start + 1
				var cs := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				rect.size = Vector2(
					maxf(8.0, float(run_length) * cell_size + overlap * 2.0 - inset * 2.0),
					shape_height
				)
				cs.shape = rect
				cs.position = Vector2(
					((float(run_start + run_end) * 0.5) - float(cols - 1) * 0.5) * cell_size,
					(float(iy) - float(rows - 1) * 0.5) * cell_size
				)
				area.add_child(cs)
				run_start = -1


func _bush_variant_for_piece(cell: Vector2i, piece_key: String, zone_seed: int, salt: int = 0) -> int:
	var variant_count := maxi(1, int(LevelConfig.get_bush_sprite_variant_count(piece_key)))
	return _stable_cell_hash(cell, zone_seed, salt + int(abs(hash(piece_key)))) % variant_count


func _add_bush_fillers(parent: Node2D, cell: Vector2i, local_pos: Vector2, zone_seed: int, is_interior: bool) -> void:
	var filler_attempts := maxi(1, LevelConfig.RESORT_BUSH_FILLER_MAX_PER_CELL)
	for attempt in range(filler_attempts):
		var threshold := 0.42 if is_interior else 0.24
		if _stable_cell_randf(cell, zone_seed, 410 + attempt) > threshold:
			continue
		var filler_pos := local_pos + Vector2(
			_stable_cell_range(cell, zone_seed, 420 + attempt, -LevelConfig.RESORT_BUSH_FILLER_JITTER, LevelConfig.RESORT_BUSH_FILLER_JITTER),
			_stable_cell_range(cell, zone_seed, 430 + attempt, -LevelConfig.RESORT_BUSH_FILLER_JITTER, LevelConfig.RESORT_BUSH_FILLER_JITTER)
		)
		var filler_rotation := _stable_cell_range(cell, zone_seed, 440 + attempt, -0.35, 0.35)
		var filler_variant := _bush_variant_for_piece(cell, "filler", zone_seed, 450 + attempt)
		var filler := _make_bush_sprite("filler", filler_variant, filler_pos, filler_rotation)
		if filler != null:
			var shadow := _make_shadow_sprite_for_layer(filler, LevelConfig.RESORT_BUSH_SHADOW_OFFSET, LevelConfig.RESORT_BUSH_SHADOW_ALPHA * 0.75, LevelConfig.VISUAL_LAYER_BUSHES)
			if shadow != null:
				parent.add_child(shadow)
			parent.add_child(filler)
		else:
			parent.add_child(_make_bush_fallback_polygon("filler", filler_pos, filler_rotation))


func _add_bush_overlays(parent: Node2D, cell: Vector2i, local_pos: Vector2, zone_seed: int, piece_key: String, is_interior: bool) -> void:
	if is_interior:
		if _stable_cell_randf(cell, zone_seed, 510) <= 0.82:
			var clump_pos := local_pos + Vector2(
				_stable_cell_range(cell, zone_seed, 511, -LevelConfig.RESORT_BUSH_INTERIOR_CLUMP_JITTER, LevelConfig.RESORT_BUSH_INTERIOR_CLUMP_JITTER),
				_stable_cell_range(cell, zone_seed, 512, -LevelConfig.RESORT_BUSH_INTERIOR_CLUMP_JITTER, LevelConfig.RESORT_BUSH_INTERIOR_CLUMP_JITTER)
			)
			var clump_rotation := _stable_cell_range(cell, zone_seed, 513, -0.18, 0.18)
			var clump_variant := _bush_variant_for_piece(cell, "interior_clump", zone_seed, 514)
			var clump := _make_bush_sprite("interior_clump", clump_variant, clump_pos, clump_rotation)
			if clump != null:
				var shadow := _make_shadow_sprite_for_layer(clump, LevelConfig.RESORT_BUSH_SHADOW_OFFSET, LevelConfig.RESORT_BUSH_SHADOW_ALPHA, LevelConfig.VISUAL_LAYER_BUSHES)
				if shadow != null:
					parent.add_child(shadow)
				parent.add_child(clump)
			else:
				parent.add_child(_make_bush_fallback_polygon("interior_clump", clump_pos, clump_rotation))

	var accent_budget := maxi(0, LevelConfig.RESORT_BUSH_ACCENT_MAX_PER_CELL)
	for accent_index in range(accent_budget):
		var threshold := 0.18 if is_interior else 0.54
		if _stable_cell_randf(cell, zone_seed, 610 + accent_index) > threshold:
			continue
		var accent_pos := local_pos + Vector2(
			_stable_cell_range(cell, zone_seed, 620 + accent_index, -LevelConfig.RESORT_BUSH_ACCENT_JITTER, LevelConfig.RESORT_BUSH_ACCENT_JITTER),
			_stable_cell_range(cell, zone_seed, 630 + accent_index, -LevelConfig.RESORT_BUSH_ACCENT_JITTER, LevelConfig.RESORT_BUSH_ACCENT_JITTER)
		)
		var accent_rotation := _stable_cell_range(cell, zone_seed, 640 + accent_index, -0.6, 0.6)
		var accent_variant := _bush_variant_for_piece(cell, "accent", zone_seed, 650 + accent_index + int(abs(hash(piece_key))))
		var accent := _make_bush_sprite("accent", accent_variant, accent_pos, accent_rotation)
		if accent != null:
			parent.add_child(accent)
		else:
			parent.add_child(_make_bush_fallback_polygon("accent", accent_pos, accent_rotation))


func _add_bush_visuals(area: Area2D, layout: Dictionary) -> void:
	var cells: Dictionary = layout.get("cells", {})
	var cols := int(layout.get("cols", 1))
	var rows := int(layout.get("rows", 1))
	var cell_size := float(layout.get("cell_size", LevelConfig.RESORT_BUSH_CELL_SIZE))
	var zone_seed := int(abs(hash("%d:%d" % [int(round(area.global_position.x)), int(round(area.global_position.y))])))

	var visual_root := Node2D.new()
	_set_canvas_item_visual_layer(visual_root, LevelConfig.VISUAL_LAYER_BUSHES)
	area.add_child(visual_root)

	var backdrop := _make_bush_backdrop(layout)
	visual_root.add_child(backdrop)

	var ordered_cells: Array = cells.keys()
	ordered_cells.sort_custom(func(a, b):
		var ca: Vector2i = a
		var cb: Vector2i = b
		if ca.y == cb.y:
			return ca.x < cb.x
		return ca.y < cb.y
	)

	for key in ordered_cells:
		var cell: Vector2i = key
		var local_pos := _boardwalk_cell_local_center(cell, cols, rows, cell_size)
		var piece := _bush_choose_piece(cells, cell, zone_seed)
		var piece_key := str(piece.get("piece", "interior_clump"))
		var piece_rotation := float(piece.get("rotation", 0.0))
		var is_interior := bool(piece.get("interior", false))

		_add_bush_fillers(visual_root, cell, local_pos, zone_seed, is_interior)

		var variant_index := _bush_variant_for_piece(cell, piece_key, zone_seed)
		var sprite := _make_bush_sprite(piece_key, variant_index, local_pos, piece_rotation)
		if sprite != null:
			var shadow := _make_shadow_sprite_for_layer(sprite, LevelConfig.RESORT_BUSH_SHADOW_OFFSET, LevelConfig.RESORT_BUSH_SHADOW_ALPHA, LevelConfig.VISUAL_LAYER_BUSHES)
			if shadow != null:
				visual_root.add_child(shadow)
			visual_root.add_child(sprite)
		else:
			visual_root.add_child(_make_bush_fallback_polygon(piece_key, local_pos, piece_rotation))

		_add_bush_overlays(visual_root, cell, local_pos, zone_seed, piece_key, is_interior)

	_set_canvas_item_visual_layer_recursive(visual_root, LevelConfig.VISUAL_LAYER_BUSHES)


func _make_bush_area(parent: Node2D, pos: Vector2, mu: float, radius: float, aspect: float = 1.0) -> Area2D:
	var area := Area2D.new()
	area.global_position = pos
	area.collision_layer = LevelConfig.MASK_ZONES
	area.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
	area.monitoring = true
	area.monitorable = true
	area.set_meta("zone_type", "friction")
	area.set_meta("friction", mu)
	area.set_meta("bush_cluster", true)
	_set_canvas_item_visual_layer(area, LevelConfig.VISUAL_LAYER_BUSHES)
	area.set_meta("friction_visual_layer", area.z_index)

	var layout := _make_bush_layout(radius, aspect)
	area.set_meta("bush_layout", layout)

	_add_bush_collision_runs(area, layout)
	_add_bush_visuals(area, layout)

	area.body_entered.connect(func(body_node): if body_node and body_node.has_method("register_zone"): body_node.register_zone(area))
	area.body_exited.connect(func(body_node): if body_node and body_node.has_method("unregister_zone"): body_node.unregister_zone(area))

	_assign_zone_draw_priority(area, ZONE_DRAW_PRIORITY_FRICTION)
	parent.add_child(area)
	_sort_zone_children(parent)
	return area


func _make_boardwalk_area(parent: Node2D, pos: Vector2, mu: float, radius: float, aspect: float = 1.0) -> Area2D:
	var area := Area2D.new()
	area.global_position = pos
	area.collision_layer = LevelConfig.MASK_ZONES
	area.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
	area.monitoring = true
	area.monitorable = true
	area.set_meta("zone_type", "friction")
	area.set_meta("friction", mu)
	_set_canvas_item_visual_layer(area, LevelConfig.VISUAL_LAYER_SAND if mu <= 1.5 else LevelConfig.VISUAL_LAYER_BUSHES)
	area.set_meta("boardwalk", true)
	_set_canvas_item_visual_layer(area, LevelConfig.VISUAL_LAYER_BOARDWALK)
	area.set_meta("friction_visual_layer", area.z_index)

	var layout := _make_boardwalk_layout(radius, aspect)
	area.set_meta("boardwalk_layout", layout)

	_add_boardwalk_collision_runs(area, layout)
	_add_boardwalk_visuals(area, layout)

	area.body_entered.connect(func(body_node): if body_node and body_node.has_method("register_zone"): body_node.register_zone(area))
	area.body_exited.connect(func(body_node): if body_node and body_node.has_method("unregister_zone"): body_node.unregister_zone(area))

	_assign_zone_draw_priority(area, ZONE_DRAW_PRIORITY_FRICTION)
	parent.add_child(area)
	_sort_zone_children(parent)
	return area


func _make_friction_area(parent: Node2D, pos: Vector2, radius: float, mu: float, aspect: float = 1.0) -> Area2D:
	if _is_boardwalk_friction(mu):
		return _make_boardwalk_area(parent, pos, mu, radius, aspect)
	if _is_bush_friction(mu):
		return _make_bush_area(parent, pos, mu, radius, aspect)

	var area := Area2D.new()
	area.global_position = pos
	area.collision_layer = LevelConfig.MASK_ZONES
	area.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
	area.monitoring = true
	area.monitorable = true
	area.set_meta("zone_type", "friction")
	area.set_meta("friction", mu)
	_set_canvas_item_visual_layer(area, LevelConfig.VISUAL_LAYER_SAND if mu <= 1.5 else LevelConfig.VISUAL_LAYER_BUSHES)
	area.set_meta("friction_visual_layer", area.z_index)

	var orient := randf_range(0.0, TAU)
	var surface_poly := _sand_dune_texture(radius, aspect, orient)
	area.set_meta("friction_surface_polygon", surface_poly)

	var collision_poly := CollisionPolygon2D.new()
	collision_poly.polygon = surface_poly
	area.add_child(collision_poly)

	var vis := Polygon2D.new()
	vis.polygon = surface_poly
	vis.color = LevelConfig.RESORT_SAND

	var shine := Polygon2D.new()
	shine.color = LevelConfig.RESORT_SAND_HIGHLIGHT
	shine.polygon = _sand_dune_texture(radius * 0.64, aspect * 0.78, orient)
	_set_canvas_item_visual_layer(shine, LevelConfig.VISUAL_LAYER_SAND)
	area.add_child(shine)

	_set_canvas_item_visual_layer(vis, LevelConfig.VISUAL_LAYER_SAND)
	area.add_child(vis)

	var glow := Polygon2D.new()
	glow.polygon = surface_poly
	glow.color = Color(1.0, 0.88, 0.52, 0.19)
	glow.scale = Vector2(1.09, 1.09)
	_set_canvas_item_visual_layer(glow, LevelConfig.VISUAL_LAYER_SAND)
	area.add_child(glow)

	area.body_entered.connect(func(body_node): if body_node and body_node.has_method("register_zone"): body_node.register_zone(area))
	area.body_exited.connect(func(body_node): if body_node and body_node.has_method("unregister_zone"): body_node.unregister_zone(area))

	_assign_zone_draw_priority(area, ZONE_DRAW_PRIORITY_FRICTION)
	parent.add_child(area)
	_sort_zone_children(parent)
	return area


func _make_water_area(parent: Node2D, pos: Vector2, radius: float, aspect: float = 1.0, orientation: float = 0.0) -> Area2D:
	var area := Area2D.new()
	area.global_position = pos
	area.collision_layer = LevelConfig.MASK_ZONES
	area.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
	area.monitoring = true
	area.monitorable = true
	area.set_meta("zone_type", "water")
	area.set_meta("zone_radius", radius)
	area.set_meta("zone_aspect", aspect)
	area.set_meta("water_kill_ratio", LevelConfig.WATER_OVERLAP_KILL_RATIO)
	area.set_meta("water_avoid_padding", LevelConfig.WATER_EDGE_AVOIDANCE_PADDING)
	_set_canvas_item_visual_layer(area, LevelConfig.VISUAL_LAYER_WATER)

	var outer_poly := _water_pool_shape(radius, aspect, orientation)
	area.set_meta("water_surface_polygon", outer_poly)

	# Match the monitored water footprint to the visible water surface.
	# Ball.gd now uses this same polygon for the center-touch sink check,
	# so the forcefield ring never affects water triggering.
	var collision_poly := CollisionPolygon2D.new()
	collision_poly.polygon = outer_poly
	area.add_child(collision_poly)

	var inner_poly := _scale_polygon(outer_poly, Vector2(0.82, 0.80))
	var highlight_poly := _scale_polygon(outer_poly, Vector2(0.48, 0.34))

	var shadow := Polygon2D.new()
	shadow.color = LevelConfig.RESORT_WATER_SHADOW
	shadow.polygon = outer_poly
	shadow.position = Vector2(radius * 0.08, radius * 0.10)
	_set_canvas_item_visual_layer(shadow, LevelConfig.VISUAL_LAYER_WATER)
	area.add_child(shadow)

	var deep := Polygon2D.new()
	deep.color = LevelConfig.RESORT_WATER_DEEP
	deep.polygon = outer_poly
	_set_canvas_item_visual_layer(deep, LevelConfig.VISUAL_LAYER_WATER)
	area.add_child(deep)

	var shallow := Polygon2D.new()
	shallow.color = LevelConfig.RESORT_WATER_SHALLOW
	shallow.polygon = inner_poly
	shallow.position = Vector2(-radius * 0.06, -radius * 0.04)
	_set_canvas_item_visual_layer(shallow, LevelConfig.VISUAL_LAYER_WATER)
	area.add_child(shallow)

	var highlight := Polygon2D.new()
	highlight.color = LevelConfig.RESORT_WATER_HIGHLIGHT
	highlight.polygon = highlight_poly
	highlight.position = Vector2(-radius * 0.16, -radius * 0.22)
	_set_canvas_item_visual_layer(highlight, LevelConfig.VISUAL_LAYER_WATER)
	area.add_child(highlight)

	var foam_outer := Line2D.new()
	foam_outer.width = maxf(3.0, radius * 0.045)
	foam_outer.default_color = LevelConfig.RESORT_WATER_FOAM
	foam_outer.closed = true
	for p in _scale_polygon(outer_poly, Vector2(1.01, 1.01)):
		foam_outer.add_point(p)
	_set_canvas_item_visual_layer(foam_outer, LevelConfig.VISUAL_LAYER_WATER)
	area.add_child(foam_outer)

	var foam_inner := Line2D.new()
	foam_inner.width = maxf(2.2, radius * 0.026)
	foam_inner.default_color = Color(0.95, 0.99, 1.0, 0.42)
	foam_inner.closed = true
	for p in _scale_polygon(inner_poly, Vector2(0.94, 0.94)):
		foam_inner.add_point(p)
	_set_canvas_item_visual_layer(foam_inner, LevelConfig.VISUAL_LAYER_WATER)
	area.add_child(foam_inner)

	for i in range(2):
		var ripple := Line2D.new()
		ripple.width = maxf(1.8, radius * 0.018)
		ripple.default_color = Color(0.92, 0.99, 1.0, 0.26 - i * 0.07)
		ripple.closed = true
		var ripple_scale := 0.58 - i * 0.14
		var ripple_poly := _scale_polygon(outer_poly, Vector2(ripple_scale, ripple_scale * 0.74))
		for p in ripple_poly:
			ripple.add_point(p + Vector2(-radius * 0.08 + i * radius * 0.07, -radius * 0.02 + i * radius * 0.06))
		_set_canvas_item_visual_layer(ripple, LevelConfig.VISUAL_LAYER_WATER)
		area.add_child(ripple)

	area.body_entered.connect(func(body_node): if body_node and body_node.has_method("register_zone"): body_node.register_zone(area))
	area.body_exited.connect(func(body_node): if body_node and body_node.has_method("unregister_zone"): body_node.unregister_zone(area))

	_assign_zone_draw_priority(area, ZONE_DRAW_PRIORITY_WATER)
	parent.add_child(area)
	_sort_zone_children(parent)
	return area

func _ensure_rock_sprite_loaded() -> void:
	if _rock_sprite_attempted_load:
		return
	_rock_sprite_attempted_load = true

	var sprite_path := _first_existing_resource_path(LevelConfig.get_rock_sprite_candidate_paths())
	if sprite_path.is_empty():
		sprite_path = LevelConfig.RESORT_OBSTACLE_ROCK_SPRITE_PATH
	if sprite_path.is_empty():
		return
	if not ResourceLoader.exists(sprite_path):
		return

	_rock_sprite_texture = load(sprite_path) as Texture2D
	if _rock_sprite_texture == null:
		return

	var image := Image.load_from_file(sprite_path)
	if image == null or image.is_empty():
		_rock_sprite_region = Rect2(Vector2.ZERO, _rock_sprite_texture.get_size())
		return

	var used_rect: Rect2i = image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		_rock_sprite_region = Rect2(Vector2.ZERO, _rock_sprite_texture.get_size())
		return

	_rock_sprite_region = Rect2(used_rect.position, used_rect.size)


func _can_use_rock_sprite() -> bool:
	_ensure_rock_sprite_loaded()
	return _rock_sprite_texture != null and _rock_sprite_region.size.x > 0.0 and _rock_sprite_region.size.y > 0.0


func _make_rock_sprite(radius: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _rock_sprite_texture
	sprite.centered = true
	sprite.region_enabled = true
	sprite.region_rect = _rock_sprite_region

	var region_size: Vector2 = _rock_sprite_region.size
	var trimmed_max_dim := maxf(region_size.x, region_size.y)
	if trimmed_max_dim <= 0.0:
		trimmed_max_dim = maxf(_rock_sprite_texture.get_size().x, _rock_sprite_texture.get_size().y)
	if trimmed_max_dim <= 0.0:
		trimmed_max_dim = 1.0

	var target_diameter := radius * 2.0 * LevelConfig.RESORT_OBSTACLE_ROCK_SPRITE_SIZE_MULTIPLIER
	var uniform_scale := target_diameter / trimmed_max_dim
	sprite.scale = Vector2.ONE * uniform_scale
	_set_canvas_item_visual_layer(sprite, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
	return sprite


func _make_obstacle_island(parent: Node2D, pos: Vector2, radius: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.global_position = pos
	body.z_as_relative = false
	body.z_index = LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES
	body.collision_layer = LevelConfig.MASK_WALLS
	body.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS

	var mat := PhysicsMaterial.new()
	mat.friction = 0.0
	mat.bounce = 0.68
	body.physics_material_override = mat

	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	cs.shape = shape
	body.add_child(cs)

	if _can_use_rock_sprite():
		var rock_sprite := _make_rock_sprite(radius)
		body.add_child(rock_sprite)
	else:
		var rock := Polygon2D.new()
		rock.color = LevelConfig.RESORT_OBSTACLE_ROCK
		rock.polygon = _regular_octagon(radius)
		_set_canvas_item_visual_layer(rock, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
		body.add_child(rock)

		var border := Line2D.new()
		border.width = 12.0
		border.default_color = LevelConfig.RESORT_OBSTACLE_HIGHLIGHT
		border.points = _regular_octagon(radius * 1.11)
		_set_canvas_item_visual_layer(border, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
		body.add_child(border)

		var inner_border := Line2D.new()
		inner_border.width = 4.5
		inner_border.default_color = Color(0.78, 0.66, 0.52, 0.65)
		inner_border.points = _regular_octagon(radius * 0.86)
		_set_canvas_item_visual_layer(inner_border, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
		body.add_child(inner_border)

	parent.add_child(body)
	return body


func _regular_octagon(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n := 8
	var rot_offset := PI / 8.0
	for i in n:
		var a := i * TAU / n + rot_offset
		points.append(Vector2(cos(a), sin(a)) * radius)
	return points

func _sand_dune_texture(radius: float, aspect: float = 1.0, orientation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n := 42
	for i in n:
		var a := i * TAU / n
		var offset := 0.88 + 0.17 * sin(a * 3.8) + 0.09 * cos(a * 7.4) + 0.05 * sin(a * 12.1)
		var x := cos(a) * radius * offset * aspect
		var y := sin(a) * radius * offset
		var p := Vector2(x, y).rotated(orientation)
		points.append(p)
	return points
