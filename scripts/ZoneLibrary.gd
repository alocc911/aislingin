extends RefCounted
class_name ZoneLibrary
"""
Library of zone templates used by LevelGenerator.

Provides grass/high-friction, oil/low-friction, grade, water, and obstacle templates.
Built once on first access and cached for performance.

OFFENSIVE ENGAGEMENT UPDATE (March 2026):
- No changes required. Buildings are now placed directly as StaticBody2D
  in LevelGenerator.gd with custom visuals (base + roof + windows/door).
- Zone templates remain 100% unchanged and continue to work perfectly for
  both defensive and offensive (normal-size procedural) maps.

BOARDWALK UPDATE (April 2026):
- Boardwalk-friendly oil templates have been retuned around the new sprite-based,
  cell-built boardwalk rendering path in ZoneTemplate.gd.
- The library now favors clearer corridor, crossing, and bank-lane footprints.
"""

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const ZoneTemplate = preload("res://scripts/ZoneTemplate.gd")

static var _templates: Array[ZoneTemplate] = []

static func get_templates() -> Array[ZoneTemplate]:
	if _templates.is_empty():
		_build()
	return _templates

static func get_water_templates() -> Array[ZoneTemplate]:
	var out: Array[ZoneTemplate] = []
	for tpl in get_templates():
		if _has_component(tpl, ZoneTemplate.ComponentType.WATER):
			out.append(tpl)
	return out

static func get_friction_templates() -> Array[ZoneTemplate]:
	var out: Array[ZoneTemplate] = []
	for tpl in get_templates():
		if _has_component(tpl, ZoneTemplate.ComponentType.FRICTION):
			out.append(tpl)
	return out

static func get_grade_templates() -> Array[ZoneTemplate]:
	var out: Array[ZoneTemplate] = []
	for tpl in get_templates():
		if _has_component(tpl, ZoneTemplate.ComponentType.GRADE):
			out.append(tpl)
	return out

static func get_obstacle_templates() -> Array[ZoneTemplate]:
	var out: Array[ZoneTemplate] = []
	for tpl in get_templates():
		if _has_component(tpl, ZoneTemplate.ComponentType.OBSTACLE):
			out.append(tpl)
	return out

static func pick_template(rng: RandomNumberGenerator) -> ZoneTemplate:
	var list := get_templates()
	if list.is_empty():
		return ZoneTemplate.new("Empty", [])
	return list[rng.randi_range(0, list.size() - 1)]

static func _has_component(tpl: ZoneTemplate, comp_type: int) -> bool:
	for c in tpl.components:
		if int(c.get("type", -1)) == comp_type:
			return true
	return false

static func _boardwalk_component(local_pos: Vector2, radius: float, aspect: float) -> Dictionary:
	return {
		"type": ZoneTemplate.ComponentType.FRICTION,
		"local_pos": local_pos,
		"radius": radius,
		"mu": float(LevelConfig.FRICTION_OIL),
		"aspect": aspect,
	}

static func _build() -> void:
	_templates.clear()

	# ==================== HIGH-FRICTION GRASS / BUSH TEMPLATES ====================

	_templates.append(ZoneTemplate.make_bush_cluster("GrassBushHeavy", Vector2.ZERO, 255.0))
	_templates.append(ZoneTemplate.make_bush_cluster("GrassBushWide", Vector2.ZERO, 205.0))
	_templates.append(ZoneTemplate.make_bush_cluster("GrassBushSolo", Vector2.ZERO, 175.0))

	_templates.append(ZoneTemplate.new("GrassBushPatchy", [
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2.ZERO, "radius": 165.0, "mu": float(LevelConfig.FRICTION_GRASS)},
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(85, -60), "radius": 115.0, "mu": float(LevelConfig.FRICTION_GRASS)},
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(-70, 55), "radius": 105.0, "mu": float(LevelConfig.FRICTION_GRASS)},
	]))

	_templates.append(ZoneTemplate.new("GrassBushRing", [
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(-135, 0), "radius": 110.0, "mu": float(LevelConfig.FRICTION_GRASS)},
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(135, 0), "radius": 110.0, "mu": float(LevelConfig.FRICTION_GRASS)},
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(0, -120), "radius": 95.0, "mu": float(LevelConfig.FRICTION_GRASS)},
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(0, 120), "radius": 95.0, "mu": float(LevelConfig.FRICTION_GRASS)},
	]))

	# ==================== LOW-FRICTION OIL / BOARDWALK TEMPLATES ====================

	_templates.append(ZoneTemplate.make_boardwalk_rect("OilBoardwalkLong", Vector2.ZERO, 192.0, 0.44))
	_templates.append(ZoneTemplate.make_boardwalk_rect("OilBoardwalkWide", Vector2.ZERO, 170.0, 1.80))
	_templates.append(ZoneTemplate.make_boardwalk_rect("OilBoardwalkPath", Vector2.ZERO, 150.0, 0.62))
	_templates.append(ZoneTemplate.make_boardwalk_rect("OilBoardwalkShort", Vector2.ZERO, 116.0, 1.0))

	_templates.append(ZoneTemplate.new("OilBoardwalkFork", [
		_boardwalk_component(Vector2(-56, 0), 122.0, 0.46),
		_boardwalk_component(Vector2(72, -70), 104.0, 1.72),
	]))

	_templates.append(ZoneTemplate.new("OilBoardwalkCross", [
		_boardwalk_component(Vector2.ZERO, 132.0, 0.50),
		_boardwalk_component(Vector2.ZERO, 132.0, 1.85),
	]))

	_templates.append(ZoneTemplate.new("OilBoardwalkDogleg", [
		_boardwalk_component(Vector2(-56, 38), 108.0, 0.48),
		_boardwalk_component(Vector2(58, -52), 102.0, 1.68),
	]))

	# ==================== MIXED FRICTION TEMPLATES ====================

	_templates.append(ZoneTemplate.new("GrassOilBushBoardwalkMix", [
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2.ZERO, "radius": 182.0, "mu": float(LevelConfig.FRICTION_GRASS)},
		_boardwalk_component(Vector2(78, 52), 112.0, 0.52),
	]))

	_templates.append(ZoneTemplate.new("GrassOilSplitLanes", [
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(-120, 0), "radius": 135.0, "mu": float(LevelConfig.FRICTION_GRASS)},
		_boardwalk_component(Vector2(135, 12), 118.0, 0.50),
	]))

	_templates.append(ZoneTemplate.new("GrassBoardwalkCauseway", [
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(-132, -18), "radius": 96.0, "mu": float(LevelConfig.FRICTION_GRASS)},
		_boardwalk_component(Vector2.ZERO, 140.0, 0.46),
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(132, 18), "radius": 96.0, "mu": float(LevelConfig.FRICTION_GRASS)},
	]))

	# ==================== WATER TEMPLATES ====================

	_templates.append(ZoneTemplate.make_water_pool("WaterPoolSolo", Vector2.ZERO, 150.0, 1.0))
	_templates.append(ZoneTemplate.make_water_pool("WaterPoolWide", Vector2.ZERO, 165.0, 1.55))
	_templates.append(ZoneTemplate.make_water_pool("WaterPoolNarrow", Vector2.ZERO, 175.0, 0.62))

	_templates.append(ZoneTemplate.new("WaterTwinPools", [
		{"type": ZoneTemplate.ComponentType.WATER, "local_pos": Vector2(-110, -18), "radius": 110.0, "aspect": 1.08},
		{"type": ZoneTemplate.ComponentType.WATER, "local_pos": Vector2(118, 26), "radius": 104.0, "aspect": 0.94},
	]))

	_templates.append(ZoneTemplate.new("WaterCrookedLagoon", [
		{"type": ZoneTemplate.ComponentType.WATER, "local_pos": Vector2(-120, -55), "radius": 92.0, "aspect": 1.15},
		{"type": ZoneTemplate.ComponentType.WATER, "local_pos": Vector2(-10, 18), "radius": 122.0, "aspect": 1.42},
		{"type": ZoneTemplate.ComponentType.WATER, "local_pos": Vector2(128, 66), "radius": 88.0, "aspect": 0.96},
	]))

	_templates.append(ZoneTemplate.new("WaterWithGrassBanks", [
		{"type": ZoneTemplate.ComponentType.WATER, "local_pos": Vector2.ZERO, "radius": 138.0, "aspect": 1.18},
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(-170, 40), "radius": 84.0, "mu": float(LevelConfig.FRICTION_GRASS)},
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(165, -50), "radius": 74.0, "mu": float(LevelConfig.FRICTION_GRASS)},
	]))

	_templates.append(ZoneTemplate.new("WaterBoardwalkCrossing", [
		{"type": ZoneTemplate.ComponentType.WATER, "local_pos": Vector2.ZERO, "radius": 132.0, "aspect": 1.56},
		_boardwalk_component(Vector2.ZERO, 112.0, 0.46),
	]))

	_templates.append(ZoneTemplate.new("WaterBoardwalkBanks", [
		{"type": ZoneTemplate.ComponentType.WATER, "local_pos": Vector2.ZERO, "radius": 144.0, "aspect": 0.88},
		_boardwalk_component(Vector2(-28, 0), 102.0, 1.78),
	]))

	# ==================== GRADE TEMPLATES ====================

	_templates.append(ZoneTemplate.make_grade_patch(
		"GradeSolo",
		Vector2.ZERO,
		255.0,
		Vector2(float(LevelConfig.GRADE_ACCEL_MIN), 0.0)
	))

	_templates.append(ZoneTemplate.new("GradeLongFlow", [
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(-280, 0), "radius": 195.0, "accel": Vector2(float(LevelConfig.GRADE_ACCEL_MAX) * 0.95, 0.0)},
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(-80, 30), "radius": 225.0, "accel": Vector2(float(LevelConfig.GRADE_ACCEL_MAX) * 0.92, 0.0)},
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(130, -20), "radius": 210.0, "accel": Vector2(float(LevelConfig.GRADE_ACCEL_MAX) * 0.90, 0.0)},
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(310, 15), "radius": 185.0, "accel": Vector2(float(LevelConfig.GRADE_ACCEL_MAX) * 0.88, 0.0)},
	]))

	_templates.append(ZoneTemplate.new("GradeDiagonalRiver", [
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(-240, -160), "radius": 175.0, "accel": Vector2(280, 280)},
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(-80, -50), "radius": 215.0, "accel": Vector2(295, 295)},
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(95, 70), "radius": 205.0, "accel": Vector2(290, 290)},
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(255, 185), "radius": 180.0, "accel": Vector2(275, 275)},
	]))

	_templates.append(ZoneTemplate.new("GradeSwerve", [
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(-180, -95), "radius": 150.0, "accel": Vector2(320, 110)},
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(20, 10), "radius": 185.0, "accel": Vector2(260, -70)},
		{"type": ZoneTemplate.ComponentType.GRADE, "local_pos": Vector2(210, 110), "radius": 145.0, "accel": Vector2(305, 88)},
	]))

	# ==================== OBSTACLE TEMPLATES ====================

	_templates.append(ZoneTemplate.new("ObstacleWithGrassBushes", [
		{"type": ZoneTemplate.ComponentType.OBSTACLE, "local_pos": Vector2.ZERO, "radius": 88.0},
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2.ZERO, "radius": 235.0, "mu": float(LevelConfig.FRICTION_GRASS)},
	]))

	_templates.append(ZoneTemplate.new("ObstacleWithWaterMoat", [
		{"type": ZoneTemplate.ComponentType.OBSTACLE, "local_pos": Vector2.ZERO, "radius": 72.0},
		{"type": ZoneTemplate.ComponentType.WATER, "local_pos": Vector2.ZERO, "radius": 145.0, "aspect": 1.05},
	]))

	_templates.append(ZoneTemplate.new("ObstacleSplitHazard", [
		{"type": ZoneTemplate.ComponentType.OBSTACLE, "local_pos": Vector2(-50, 0), "radius": 62.0},
		{"type": ZoneTemplate.ComponentType.OBSTACLE, "local_pos": Vector2(65, 0), "radius": 58.0},
		{"type": ZoneTemplate.ComponentType.WATER, "local_pos": Vector2(14, 112), "radius": 90.0, "aspect": 1.32},
		{"type": ZoneTemplate.ComponentType.FRICTION, "local_pos": Vector2(0, -110), "radius": 105.0, "mu": float(LevelConfig.FRICTION_GRASS)},
	]))
