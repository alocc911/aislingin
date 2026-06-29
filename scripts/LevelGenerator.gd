extends RefCounted
class_name LevelGenerator

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const RNG = preload("res://scripts/RNG.gd")
const ZoneLibrary = preload("res://scripts/ZoneLibrary.gd")
const ZoneTemplate = preload("res://scripts/ZoneTemplate.gd")
const PinScene: PackedScene = preload("res://scenes/Pin.tscn")
const BossVisualController = preload("res://scripts/BossVisualController.gd")
const ProvinceSystem = preload("res://scripts/ProvinceSystem.gd")

const CONNECT_CELL: float = 80.0
const CONNECT_CLEARANCE: float = 30.0
const PIN_OBSTACLE_CLEARANCE: float = 18.0
const ZONE_SEPARATION_BUFFER: float = 95.0

const BUILDING_MIN_SEPARATION: float = 120.0
const BUILDING_CLEARANCE_FROM_PINS: float = 85.0
const BUILDING_ANCHOR_CLEARANCE: float = 94.0

const BUILDING_SPRITE_PATHS := [
	"res://sprites/building_01.png",
	"res://sprites/building_02.png",
	"res://sprites/building_03.png"
]

var _building_sprite_cache: Dictionary = {}
var _pin_scene_cache: Dictionary = {}
var _level_config_instance = null
var _caltrop_sprite_texture_cache: Dictionary = {}
var _caltrop_sprite_meta_cache: Dictionary = {}
var _province_ui_texture_cache: Dictionary = {}
var _province_owner_badge_fill_shader: Shader = null
var _province_system_display_helper: RefCounted = ProvinceSystem.new()

const PROVINCE_INFO_PANEL_TEXTURE_PATH := "res://sprites/province_info_panel.png"
const PROVINCE_OWNER_BADGE_NEUTRAL_TEXTURE_PATH := "res://sprites/province_owner_badge_neutral.png"
const PROVINCE_OWNER_BADGE_FRIENDLY_TEXTURE_PATH := "res://sprites/province_owner_badge_friendly.png"
const PROVINCE_OWNER_BADGE_ENEMY_TEXTURE_PATH := "res://sprites/province_owner_badge_enemy.png"
const PROVINCE_ICON_TROOPS_TEXTURE_PATH := "res://sprites/icon_troops.png"
const PROVINCE_ICON_BUILDING_TEXTURE_PATH := "res://sprites/icon_building.png"
const PROVINCE_ICON_GOLD_TEXTURE_PATH := "res://sprites/icon_gold.png"
const PROVINCE_ICON_FREE_BUILDING_TEXTURE_PATH := "res://sprites/icon_free_building.png"
const PROVINCE_ICON_CAP_TEXTURE_PATH := "res://sprites/icon_cap.png"
const PROVINCE_ICON_NATIVE_TEXTURE_PATH := "res://sprites/icons/native.png"
const PROVINCE_ICON_OUTLANDER_TEXTURE_PATH := "res://sprites/icons/outlander.png"
const PROVINCE_ICON_HAPPINESS_TEXTURE_PATH := "res://sprites/icons/happiness.png"
const PROVINCE_ICON_FOOD_SURPLUS_TEXTURE_PATH := "res://sprites/icons/food.png"
const PROVINCE_ICON_INVADERS_TEXTURE_PATH := "res://sprites/icon_invaders.png"
const PROVINCE_ICON_BIOME_NORMAL_TEXTURE_PATH := "res://sprites/icon_biome_normal.png"
const PROVINCE_ICON_BIOME_JUNGLE_TEXTURE_PATH := "res://sprites/icon_biome_jungle.png"
const PROVINCE_ICON_BIOME_ROCK_TEXTURE_PATH := "res://sprites/icon_biome_rock.png"
const PROVINCE_ICON_BIOME_SETTLEMENT_TEXTURE_PATH := "res://sprites/icon_biome_settlement.png"

const PROVINCE_INFO_PANEL_ROOT_NAME := "ProvinceInfoPanelRoot"
const PROVINCE_INFO_PANEL_BG_NAME := "ProvinceInfoPanelTexture"
const PROVINCE_INFO_PANEL_OWNER_BADGE_NAME := "ProvinceOwnerBadge"
const PROVINCE_INFO_PANEL_BIOME_ICON_NAME := "ProvinceBiomeIcon"
const PROVINCE_INFO_PANEL_OWNER_LABEL_NAME := "ProvinceOwnerLabel"
const PROVINCE_INFO_PANEL_NAME_LABEL_NAME := "ProvinceNameLabel"
const PROVINCE_INFO_PANEL_INVADERS_ICON_NAME := "ProvinceInvadersIcon"
const PROVINCE_INFO_PANEL_INVADERS_LABEL_NAME := "ProvinceInvadersLabel"
const PROVINCE_INFO_PANEL_TROOPS_ICON_NAME := "ProvinceTroopsIcon"
const PROVINCE_INFO_PANEL_TROOPS_LABEL_NAME := "ProvinceTroopsLabel"
const PROVINCE_INFO_PANEL_BUILDINGS_ICON_NAME := "ProvinceBuildingsIcon"
const PROVINCE_INFO_PANEL_BUILDINGS_LABEL_NAME := "ProvinceBuildingsLabel"
const PROVINCE_INFO_PANEL_GOLD_ICON_NAME := "ProvinceGoldIcon"
const PROVINCE_INFO_PANEL_GOLD_LABEL_NAME := "ProvinceGoldLabel"
const PROVINCE_INFO_PANEL_FREE_ICON_NAME := "ProvinceFreeIcon"
const PROVINCE_INFO_PANEL_FREE_LABEL_NAME := "ProvinceFreeLabel"
const PROVINCE_INFO_PANEL_CAP_ICON_NAME := "ProvinceCapIcon"
const PROVINCE_INFO_PANEL_CAP_LABEL_NAME := "ProvinceCapLabel"

const PROVINCE_INFO_PANEL_DESIRED_WIDTH: float = 190.0
const PROVINCE_INFO_PANEL_FALLBACK_HEIGHT: float = 94.0
const PROVINCE_INFO_PANEL_ICON_CONTENT_NAME := "Content"
const PROVINCE_INFO_PANEL_OWNER_BADGE_SIZE := Vector2(24.0, 24.0)
const PROVINCE_INFO_PANEL_BIOME_ICON_SIZE := Vector2(22.0, 22.0)
const PROVINCE_INFO_PANEL_STAT_ICON_SIZE := Vector2(18.0, 18.0)
const PROVINCE_INFO_PANEL_OWNER_BADGE_VISUAL_SCALE: float = 0.94
const PROVINCE_INFO_PANEL_BIOME_ICON_VISUAL_SCALE: float = 0.92
const PROVINCE_INFO_PANEL_STAT_ICON_VISUAL_SCALE: float = 0.90

const ROLE_CORE: String = "core"
const ROLE_GUARD: String = "guard"
const ROLE_SUPPORT: String = "support"
const ROLE_EXPOSED: String = "exposed"
const ROLE_DECOY: String = "decoy"
const ROLE_LANE: String = "lane"
const ROLE_SPLIT: String = "split"
const ROLE_POCKET: String = "pocket"


const BOSS_VISUAL_ROOT_NAME: String = "BossVisualRoot"
const BOSS_PART_META_KEY: String = "boss_part_name"
const BOSS_PART_GROUP: String = "boss_part"

const BOSS_HEAD_FILL_COLOR := Color(0.88, 0.36, 0.36, 0.95)
const BOSS_ARM_FILL_COLOR := Color(0.74, 0.24, 0.24, 0.95)
const BOSS_LEG_FILL_COLOR := Color(0.62, 0.16, 0.16, 0.95)
const BOSS_TORSO_FILL_COLOR := Color(0.48, 0.10, 0.10, 0.92)
const BOSS_OUTLINE_COLOR := Color(1.0, 0.88, 0.58, 0.95)
const BOSS_CORE_GLOW_COLOR := Color(1.0, 0.56, 0.18, 0.65)
const BOSS_PART_DESTROYED_ALPHA: float = 0.16

const CALTROP_GROUP: String = "caltrop"
const CALTROP_BUTTON_GROUP: String = "caltrop_button"
const CALTROP_META_PROVINCE_ID: String = "caltrop_province_id"
const CALTROP_META_CALTROP_ID: String = "caltrop_id"

const PROVINCE_GOLD_PRODUCTION_KEY := "gold_production"
const PROVINCE_FREE_BUILDINGS_KEY := "free_buildings"
const PROVINCE_BUILDING_CAPACITY_KEY := "building_capacity"
const PROVINCE_ENGAGEMENT_MAP_TYPE_KEY := "engagement_map_type"
const PROVINCE_NAME_KEY := "province_name"

const PROVINCE_NAME_ONSETS := [
	"b", "br", "d", "dr", "f", "g", "gr", "h", "k", "l", "m", "n", "r", "s", "st", "t", "th", "v", "w",
	"b", "d", "g", "k", "l", "m", "n", "r", "s", "t"
]
const PROVINCE_NAME_VOWELS := [
	"a", "e", "i", "o", "u", "ae", "ai", "ea", "ei", "ia", "oa", "ou",
	"a", "e", "o"
]
const PROVINCE_NAME_CODAS := [
	"n", "r", "l", "th", "nd", "rd", "rk", "m", "s", "sh", "k", "t", "ren", "len", "ron", "mar", "vor", "den", "ric", "las",
	"n", "r", "l", "m", "s", "nd", "th"
]
const PROVINCE_NAME_FALLBACKS := [
	"Halen", "Teren", "Morvain", "Velkar", "Soreth", "Daren", "Lethor", "Varen", "Kelmar", "Rovain",
	"Mereth", "Talren", "Norel", "Bramor", "Selvar", "Dorlen", "Vareth", "Caldor", "Torven", "Halvor"
]

const CALTROP_RADIUS_MIN: float = 42.0
const CALTROP_RADIUS_MAX: float = 68.0
const CALTROP_BUTTON_RADIUS: float = 13.0
const CALTROP_WORLD_MARGIN: float = 118.0
const CALTROP_PLACEMENT_ATTEMPTS: int = 42
const CALTROP_HARD_BLOCKER_PADDING: float = 20.0
const CALTROP_WATER_PADDING: float = 28.0
const CALTROP_SOFT_PIN_PADDING: float = 12.0

const CALTROP_FILL_COLOR := Color(0.28, 0.26, 0.30, 0.98)
const CALTROP_EDGE_COLOR := Color(0.78, 0.72, 0.64, 0.96)
const CALTROP_INNER_COLOR := Color(0.16, 0.14, 0.18, 0.92)
const CALTROP_BUTTON_COLOR := Color(0.96, 0.74, 0.28, 0.98)
const CALTROP_BUTTON_RING_COLOR := Color(1.0, 0.94, 0.72, 0.96)

const GRAND_MAP_BARRIER_SANITY_MAX_ATTEMPTS: int = 7
const GRAND_MAP_BARRIER_SANITY_MIN_BAD_SEGMENTS: int = 3
const GRAND_MAP_BARRIER_SANITY_BAD_SEGMENT_RATIO: float = 0.018
const GRAND_MAP_BARRIER_SANITY_SAMPLE_THICKNESS: float = 96.0


func _make_province_name_rng(map_seed: int, province_id: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var mixed: int = int(hash("%d|province_name|%d|%d" % [maxi(1, map_seed), province_id, LevelConfig.GRAND_MAP_PROVINCE_VARIATION]))
	mixed = mixed & 0x7fffffff
	if mixed == 0:
		mixed = (province_id + 1) * 32452843
	rng.seed = mixed
	return rng


func _pick_province_name_part(rng: RandomNumberGenerator, parts: Array) -> String:
	if parts.is_empty():
		return ""
	return String(parts[rng.randi_range(0, parts.size() - 1)])


func _title_case_province_name(raw_name: String) -> String:
	var cleaned: String = String(raw_name).strip_edges().to_lower()
	if cleaned.is_empty():
		return ""
	return cleaned.substr(0, 1).to_upper() + cleaned.substr(1)


func _is_valid_province_name_candidate(candidate: String, existing_names: Dictionary) -> bool:
	var normalized: String = String(candidate).strip_edges().to_lower()
	if normalized.length() < 4 or normalized.length() > 12:
		return false
	if existing_names.has(normalized):
		return false
	for i in range(normalized.length()):
		var ch: String = normalized.substr(i, 1)
		if not ((ch >= "a" and ch <= "z") or ch == " " or ch == "-"):
			return false
	if normalized.find("aaa") >= 0 or normalized.find("eee") >= 0 or normalized.find("iii") >= 0 or normalized.find("ooo") >= 0 or normalized.find("uuu") >= 0:
		return false
	if normalized.find("bbb") >= 0 or normalized.find("ddd") >= 0 or normalized.find("ggg") >= 0 or normalized.find("kkk") >= 0 or normalized.find("lll") >= 0 or normalized.find("mmm") >= 0 or normalized.find("nnn") >= 0 or normalized.find("rrr") >= 0 or normalized.find("sss") >= 0 or normalized.find("ttt") >= 0:
		return false
	return true


func _generate_phoneme_province_name(map_seed: int, province_id: int, existing_names: Dictionary) -> String:
	var rng: RandomNumberGenerator = _make_province_name_rng(map_seed, province_id)
	for _attempt in range(48):
		var syllable_count: int = 2 if rng.randf() < 0.78 else 3
		var parts: Array[String] = []
		for syllable_idx in range(syllable_count):
			var onset: String = ""
			if syllable_idx == 0 or rng.randf() < 0.84:
				onset = _pick_province_name_part(rng, PROVINCE_NAME_ONSETS)
			var vowel: String = _pick_province_name_part(rng, PROVINCE_NAME_VOWELS)
			var coda: String = ""
			if syllable_idx == syllable_count - 1:
				if rng.randf() < 0.82:
					coda = _pick_province_name_part(rng, PROVINCE_NAME_CODAS)
			elif rng.randf() < 0.18:
				coda = _pick_province_name_part(rng, PROVINCE_NAME_CODAS)
			parts.append(onset + vowel + coda)
		var candidate: String = _title_case_province_name("".join(parts))
		if _is_valid_province_name_candidate(candidate, existing_names):
			existing_names[String(candidate).to_lower()] = true
			return candidate
	for fallback_offset in range(PROVINCE_NAME_FALLBACKS.size()):
		var fallback_idx: int = (province_id + fallback_offset) % PROVINCE_NAME_FALLBACKS.size()
		var fallback_name: String = _title_case_province_name(String(PROVINCE_NAME_FALLBACKS[fallback_idx]))
		if _is_valid_province_name_candidate(fallback_name, existing_names):
			existing_names[String(fallback_name).to_lower()] = true
			return fallback_name
	var numeric_fallback: String = "Province %d" % province_id
	existing_names[String(numeric_fallback).to_lower()] = true
	return numeric_fallback


func _get_province_display_name(province_name: String, province_id: int) -> String:
	var cleaned: String = String(province_name).strip_edges()
	if cleaned.is_empty():
		return "Province %d" % province_id
	return cleaned


func _make_province_variation_rng(map_seed: int, province_id: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var mixed: int = int(hash("%d|province_variation|%d|%d" % [maxi(1, map_seed), province_id, LevelConfig.GRAND_MAP_PROVINCE_VARIATION]))
	mixed = mixed & 0x7fffffff
	if mixed == 0:
		mixed = (province_id + 1) * 15485863
	rng.seed = mixed
	return rng


func _roll_province_variation(map_seed: int, province_id: int) -> Dictionary:
	var rng: RandomNumberGenerator = _make_province_variation_rng(map_seed, province_id)
	var engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
	if not LevelConfig.ENGAGEMENT_MAP_TYPE_VALUES.is_empty():
		var map_type_idx: int = rng.randi_range(0, LevelConfig.ENGAGEMENT_MAP_TYPE_VALUES.size() - 1)
		engagement_map_type = String(LevelConfig.ENGAGEMENT_MAP_TYPE_VALUES[map_type_idx])
	return {
		PROVINCE_GOLD_PRODUCTION_KEY: rng.randi_range(LevelConfig.PROVINCE_GOLD_PRODUCTION_MIN, LevelConfig.PROVINCE_GOLD_PRODUCTION_MAX),
		PROVINCE_FREE_BUILDINGS_KEY: rng.randi_range(LevelConfig.PROVINCE_FREE_BUILDINGS_MIN, LevelConfig.PROVINCE_FREE_BUILDINGS_MAX),
		PROVINCE_BUILDING_CAPACITY_KEY: rng.randi_range(LevelConfig.PROVINCE_BUILDING_CAP_MIN, LevelConfig.PROVINCE_BUILDING_CAP_MAX),
		PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: engagement_map_type
	}


func _normalize_province_variation_entry(map_seed: int, province_entry: Dictionary) -> Dictionary:
	var normalized: Dictionary = province_entry.duplicate(true)
	var province_id: int = int(normalized.get("id", -1))
	var rolled: Dictionary = _roll_province_variation(map_seed, province_id)
	normalized[PROVINCE_GOLD_PRODUCTION_KEY] = LevelConfig.clamp_province_gold_production(int(normalized.get(PROVINCE_GOLD_PRODUCTION_KEY, rolled.get(PROVINCE_GOLD_PRODUCTION_KEY, 0))))
	normalized[PROVINCE_FREE_BUILDINGS_KEY] = LevelConfig.clamp_province_free_buildings(int(normalized.get(PROVINCE_FREE_BUILDINGS_KEY, rolled.get(PROVINCE_FREE_BUILDINGS_KEY, 0))))
	normalized[PROVINCE_BUILDING_CAPACITY_KEY] = LevelConfig.clamp_province_building_cap(int(normalized.get(PROVINCE_BUILDING_CAPACITY_KEY, rolled.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN))))
	normalized[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = LevelConfig.normalize_engagement_map_type(String(normalized.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, rolled.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL))))
	return normalized


func generate_into(map_seed: int, level_index: int, zones_root: Node2D, obstacles_root: Node2D, pins_root: Node2D, provinces_root: Node2D = null, phase: String = "defensive", buildings_count: int = 0, troops_count: int = -1, engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL) -> Dictionary:
	var gen_rng := RNG.make_gen_rng(map_seed)
	var normalized_map_type: String = LevelConfig.normalize_engagement_map_type(engagement_map_type)

	if phase == "grand_map":
		return _generate_grand_map(map_seed, level_index, zones_root, obstacles_root, pins_root, provinces_root, gen_rng)

	var has_exact_troop_count: bool = troops_count >= 0
	if has_exact_troop_count:
		return _generate_persistent_engagement(map_seed, level_index, zones_root, obstacles_root, pins_root, gen_rng, phase, buildings_count, troops_count, normalized_map_type)

	var pin_range := _get_pin_range(level_index, phase)
	var pin_count := gen_rng.randi_range(pin_range.min, pin_range.max)
	var layout: Dictionary = _generate_layout_defs(map_seed, level_index, pin_count, gen_rng, phase, normalized_map_type)

	var pin_data := _place_pins(layout, pin_count, level_index, gen_rng, phase)
	layout["pins"] = pin_data

	_instance_layout(layout, zones_root, obstacles_root, pins_root, provinces_root)

	return {
		"accepted": true,
		"attempts": 1,
		"pin_count": pin_data.size(),
		"seed": map_seed,
		"level": level_index,
		"phase": phase,
		"engagement_map_type": normalized_map_type
	}

func _generate_grand_map(map_seed: int, level_index: int, zones_root: Node2D, obstacles_root: Node2D, pins_root: Node2D, provinces_root: Node2D, _gen_rng: RandomNumberGenerator) -> Dictionary:
	var playable_half: Vector2 = LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS
	var selected_seed: int = map_seed
	var selected_attempt: int = 1
	var grand_data: Dictionary = {}
	var provinces: Array = []
	var mainland_polygons: Array = []
	for attempt_idx in range(GRAND_MAP_BARRIER_SANITY_MAX_ATTEMPTS):
		var attempt_seed: int = _derive_grand_map_attempt_seed(map_seed, attempt_idx)
		var attempt_rng: RandomNumberGenerator = RNG.make_gen_rng(attempt_seed)
		var candidate_data: Dictionary = _generate_template_grand_map_data(playable_half, attempt_rng, attempt_seed, level_index)
		var candidate_provinces: Array = candidate_data.get("provinces", [])
		var sanity: Dictionary = _evaluate_grand_map_barrier_sanity(candidate_provinces, GRAND_MAP_BARRIER_SANITY_SAMPLE_THICKNESS)
		grand_data = candidate_data
		provinces = candidate_provinces
		selected_seed = attempt_seed
		selected_attempt = attempt_idx + 1
		if not bool(sanity.get("failed", false)):
			break

	mainland_polygons = _extract_mainland_polygons_from_provinces(provinces)
	var terrain_rng: RandomNumberGenerator = RNG.make_gen_rng(selected_seed ^ 0x5F3759DF)
	var terrain_layout: Dictionary = _generate_grand_map_template_layout_defs(selected_seed, level_index, terrain_rng, mainland_polygons)

	var layout: Dictionary = _base_layout_dict(
		selected_seed,
		level_index,
		playable_half,
		terrain_layout.get("templates", []),
		terrain_layout,
		0,
		LevelConfig.PHASE_GRAND_MAP
	)
	layout["pins"] = []
	layout["buildings"] = []
	layout["provinces"] = provinces
	layout["mountains"] = grand_data.get("mountains", [])
	layout["grand_map_template_id"] = String(grand_data.get("template_id", ""))

	_instance_layout(layout, zones_root, obstacles_root, pins_root, provinces_root)

	return {
		"accepted": true,
		"attempts": selected_attempt,
		"pin_count": 0,
		"seed": selected_seed,
		"level": level_index,
		"phase": LevelConfig.PHASE_GRAND_MAP,
		"grand_map": true,
		"template_id": layout.get("grand_map_template_id", "")
	}


func _derive_grand_map_attempt_seed(base_seed: int, attempt_idx: int) -> int:
	if attempt_idx <= 0:
		return base_seed
	var mixed: int = int(hash("%d|grand_map_reroll|%d" % [base_seed, attempt_idx])) & 0x7fffffff
	if mixed == 0:
		mixed = maxi(1, base_seed) + attempt_idx * 104729
	return mixed


func _evaluate_grand_map_barrier_sanity(province_data: Array, barrier_thickness: float = GRAND_MAP_BARRIER_SANITY_SAMPLE_THICKNESS) -> Dictionary:
	var mainland_polygons: Array = _get_merged_mainland_polygons_from_province_data(province_data)
	if mainland_polygons.is_empty():
		return {"failed": false, "bad_segments": 0, "total_segments": 0, "bad_ratio": 0.0}

	var total_segments: int = 0
	var bad_segments: int = 0
	var sample_offset: float = maxf(10.0, barrier_thickness * 0.35)
	for loop_poly_any in mainland_polygons:
		var loop_poly: PackedVector2Array = loop_poly_any
		var smooth_inner: PackedVector2Array = _make_smoothed_province_display_polyline(loop_poly, 0.0)
		smooth_inner = _ensure_polygon_ccw(smooth_inner)
		if smooth_inner.size() < 3:
			continue
		for i in range(smooth_inner.size()):
			var a: Vector2 = smooth_inner[i]
			var b: Vector2 = smooth_inner[(i + 1) % smooth_inner.size()]
			var dir: Vector2 = b - a
			var seg_len: float = dir.length()
			if seg_len < 0.001:
				continue
			dir /= seg_len
			var outward: Vector2 = Vector2(dir.y, -dir.x)
			var barrier_center: Vector2 = (a + b) * 0.5 + outward * sample_offset
			total_segments += 1
			if _point_inside_any_polygon(barrier_center, mainland_polygons):
				bad_segments += 1

	var bad_ratio: float = float(bad_segments) / maxf(1.0, float(total_segments))
	var failed: bool = bad_segments >= GRAND_MAP_BARRIER_SANITY_MIN_BAD_SEGMENTS and bad_ratio >= GRAND_MAP_BARRIER_SANITY_BAD_SEGMENT_RATIO
	return {
		"failed": failed,
		"bad_segments": bad_segments,
		"total_segments": total_segments,
		"bad_ratio": bad_ratio
	}


func _point_inside_any_polygon(point: Vector2, polygons: Array) -> bool:
	for poly_any in polygons:
		var poly: PackedVector2Array = poly_any
		if poly.size() < 3:
			continue
		if Geometry2D.is_point_in_polygon(point, poly):
			return true
	return false


func _generate_grand_map_template_layout_defs(candidate_seed: int, level_index: int, gen_rng: RandomNumberGenerator, mainland_polygons: Array) -> Dictionary:
	var interior_half: Vector2 = LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS
	var placement_margin := -LevelConfig.ZONE_PLACEMENT_OVERHANG
	var templates_to_place: Array[Dictionary] = []
	var placed_influence: Array[Dictionary] = []

	var obstacle_count := LevelConfig.GRAND_MAP_ZONE_OBSTACLE_BASE
	obstacle_count = clampi(obstacle_count, LevelConfig.GRAND_MAP_ZONE_OBSTACLE_BASE, 24)
	for i in range(obstacle_count):
		var obstacle_tpl := _pick_obstacle_template(gen_rng)
		var obstacle_plc := _make_template_placement_on_mainland_with_separation(obstacle_tpl, interior_half, placement_margin, gen_rng, placed_influence, mainland_polygons)
		if obstacle_plc.is_empty():
			continue
		templates_to_place.append(obstacle_plc)
		_record_influence(obstacle_plc, placed_influence)

	var friction_count := LevelConfig.GRAND_MAP_FRICTION_BASE
	friction_count = clampi(friction_count, LevelConfig.GRAND_MAP_FRICTION_BASE, 32)
	for i in range(friction_count):
		var want_oil := gen_rng.randf() < 0.35
		var friction_tpl := _pick_friction_template(gen_rng, want_oil)
		var friction_plc := _make_template_placement_on_mainland_with_separation(friction_tpl, interior_half, placement_margin, gen_rng, placed_influence, mainland_polygons)
		if friction_plc.is_empty():
			continue
		templates_to_place.append(friction_plc)
		_record_influence(friction_plc, placed_influence)

	var water_count := LevelConfig.GRAND_MAP_WATER_BASE_COUNT
	water_count = clampi(water_count, LevelConfig.GRAND_MAP_WATER_BASE_COUNT, 18)
	for i in range(water_count):
		var water_tpl := _pick_water_template(gen_rng)
		var water_plc := _make_template_placement_on_mainland_with_separation(water_tpl, interior_half, placement_margin, gen_rng, placed_influence, mainland_polygons)
		if water_plc.is_empty():
			continue
		templates_to_place.append(water_plc)
		_record_influence(water_plc, placed_influence)

	if LevelConfig.GRAND_MAP_ENABLE_GRADE_ZONES:
		var grade_count := LevelConfig.GRAND_MAP_GRADE_BASE_COUNT
		grade_count = clampi(grade_count, LevelConfig.GRAND_MAP_GRADE_BASE_COUNT, 12)
		for i in range(grade_count):
			var grade_tpl := _pick_large_grade_template(gen_rng)
			var grade_plc := _make_large_grade_placement_on_mainland(grade_tpl, interior_half, gen_rng, mainland_polygons)
			if grade_plc.is_empty():
				continue
			templates_to_place.append(grade_plc)

	var expanded := _expand_placements_to_components(templates_to_place, gen_rng)
	var out := _base_layout_dict(candidate_seed, level_index, interior_half, templates_to_place, expanded, 0, LevelConfig.PHASE_GRAND_MAP)
	out["motif"] = "generic"
	return out


func _extract_mainland_polygons_from_provinces(provinces: Array) -> Array:
	var polys: Array = []
	for province_any in provinces:
		var province: Dictionary = province_any
		var poly: PackedVector2Array = province.get("polygon", PackedVector2Array())
		if poly.size() >= 3:
			polys.append(poly)
	return polys


func _make_template_placement_on_mainland_with_separation(tpl: ZoneTemplate, interior_half: Vector2, margin: float, gen_rng: RandomNumberGenerator, placed: Array[Dictionary], mainland_polygons: Array) -> Dictionary:
	for attempt in range(180):
		var origin: Vector2 = Vector2(
			gen_rng.randf_range(-interior_half.x + margin, interior_half.x - margin),
			gen_rng.randf_range(-interior_half.y + margin, interior_half.y - margin)
		)
		var rot: float = gen_rng.randf_range(0.0, TAU)
		var sc: float = gen_rng.randf_range(LevelConfig.ZONE_SCALE_MIN, LevelConfig.ZONE_SCALE_MAX)

		var too_close: bool = false
		for p in placed:
			if origin.distance_to(p.origin) < ZONE_SEPARATION_BUFFER * 1.2:
				too_close = true
				break
		if too_close:
			continue

		var plc := {
			"template": tpl,
			"origin": origin,
			"rotation": rot,
			"scale": sc
		}
		if _template_placement_is_on_mainland(plc, mainland_polygons):
			return plc
	return {}


func _make_large_grade_placement_on_mainland(tpl: ZoneTemplate, interior_half: Vector2, gen_rng: RandomNumberGenerator, mainland_polygons: Array) -> Dictionary:
	for attempt in range(120):
		var origin: Vector2 = Vector2(
			gen_rng.randf_range(-interior_half.x * 0.7, interior_half.x * 0.7),
			gen_rng.randf_range(-interior_half.y * 0.7, interior_half.y * 0.7)
		)
		var rot: float = gen_rng.randf_range(0.0, TAU)
		var sc: float = gen_rng.randf_range(LevelConfig.GRADE_SCALE_MIN, LevelConfig.GRADE_SCALE_MAX)
		var plc := {
			"template": tpl,
			"origin": origin,
			"rotation": rot,
			"scale": sc
		}
		if _template_placement_is_on_mainland(plc, mainland_polygons):
			return plc
	return {}


func _template_placement_is_on_mainland(plc: Dictionary, mainland_polygons: Array) -> bool:
	var tpl: ZoneTemplate = plc.get("template", null)
	if tpl == null:
		return false
	var origin: Vector2 = plc.get("origin", Vector2.ZERO)
	var rot: float = float(plc.get("rotation", 0.0))
	var sc: float = float(plc.get("scale", 1.0))
	for c_any in tpl.components:
		var c: Dictionary = c_any
		var local_pos: Vector2 = c.get("local_pos", Vector2.ZERO)
		var radius: float = float(c.get("radius", 0.0)) * sc
		var world_pos: Vector2 = origin + local_pos.rotated(rot) * sc
		var aspect: float = float(c.get("aspect", 1.0))
		if not _component_center_and_extent_on_mainland(world_pos, radius, aspect, rot, mainland_polygons):
			return false
	return true


func _component_center_and_extent_on_mainland(center: Vector2, radius: float, aspect: float, rotation: float, mainland_polygons: Array) -> bool:
	if mainland_polygons.is_empty():
		return false
	if not _point_on_mainland(center, mainland_polygons):
		return false
	var sample_radius_x: float = maxf(8.0, radius * maxf(1.0, aspect) * 0.72)
	var sample_radius_y: float = maxf(8.0, radius / maxf(0.42, aspect) * 0.72)
	var offsets: Array = [
		Vector2(sample_radius_x, 0.0),
		Vector2(-sample_radius_x, 0.0),
		Vector2(0.0, sample_radius_y),
		Vector2(0.0, -sample_radius_y)
	]
	for off_any in offsets:
		var off: Vector2 = off_any
		var sample: Vector2 = center + off.rotated(rotation)
		if not _point_on_mainland(sample, mainland_polygons):
			return false
	return true


func _point_on_mainland(point: Vector2, mainland_polygons: Array) -> bool:
	for poly_any in mainland_polygons:
		var poly: PackedVector2Array = poly_any
		if poly.size() >= 3 and Geometry2D.is_point_in_polygon(point, poly):
			return true
	return false
func _generate_persistent_engagement(map_seed: int, level_index: int, zones_root: Node2D, obstacles_root: Node2D, pins_root: Node2D, gen_rng: RandomNumberGenerator, phase: String, buildings_count: int, troops_count: int, engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL) -> Dictionary:
	var safe_buildings_count: int = maxi(0, buildings_count)
	var safe_troops_count: int = maxi(0, troops_count)
	var spawn_physical_buildings: bool = safe_buildings_count > 0 and phase != LevelConfig.PHASE_OFFENSIVE
	var normalized_map_type: String = LevelConfig.normalize_engagement_map_type(engagement_map_type)

	var layout: Dictionary = _generate_layout_defs(map_seed, level_index, safe_troops_count, gen_rng, phase, normalized_map_type)

	var pin_data := _place_pins(layout, safe_troops_count, level_index, gen_rng, phase)
	layout["pins"] = pin_data
	layout["buildings"] = []

	if spawn_physical_buildings:
		var building_data := _place_buildings(layout, safe_buildings_count, gen_rng)
		layout["buildings"] = building_data

	_instance_layout(layout, zones_root, obstacles_root, pins_root, null)

	return {
		"accepted": true,
		"attempts": 1,
		"pin_count": pin_data.size(),
		"building_count": safe_buildings_count,
		"physical_building_count": int(layout.get("buildings", []).size()),
		"seed": map_seed,
		"level": level_index,
		"phase": phase,
		"engagement_map_type": normalized_map_type
	}

func _is_milestone(level_index: int) -> bool:
	return level_index % LevelConfig.MILESTONE_INTERVAL == 0

func _get_pin_range(level_index: int, phase: String = "defensive") -> Dictionary:
	if phase == "grand_map":
		return { "min": 0, "max": 0 }

	var is_milestone: bool = _is_milestone(level_index)
	var effective_level := mini(level_index - 1, LevelConfig.PIN_GROWTH_STOP_LEVEL)

	var min_pins := LevelConfig.PIN_BASE_MIN + floori(float(effective_level) * LevelConfig.PIN_GROWTH_MIN_PER_LEVEL)
	var max_pins := LevelConfig.PIN_BASE_MAX + floori(float(effective_level) * LevelConfig.PIN_GROWTH_MAX_PER_LEVEL)

	min_pins = clampi(min_pins, LevelConfig.PIN_BASE_MIN, LevelConfig.PIN_PLATEAU_MAX)
	max_pins = clampi(max_pins, min_pins, LevelConfig.PIN_PLATEAU_MAX)

	if level_index > LevelConfig.PIN_GROWTH_STOP_LEVEL:
		min_pins = LevelConfig.PIN_PLATEAU_MIN
		max_pins = LevelConfig.PIN_PLATEAU_MAX

	if is_milestone:
		min_pins = floori(float(min_pins) * LevelConfig.MILESTONE_PIN_MULTIPLIER)
		max_pins = floori(float(max_pins) * LevelConfig.MILESTONE_PIN_MULTIPLIER)
		min_pins = clampi(min_pins, LevelConfig.PIN_PLATEAU_MIN, LevelConfig.PIN_MILESTONE_MAX)
		max_pins = clampi(max_pins, min_pins, LevelConfig.PIN_MILESTONE_MAX)

	return { "min": min_pins, "max": max_pins }

func _generate_layout_defs(candidate_seed: int, level_index: int, pin_count: int, gen_rng: RandomNumberGenerator, phase: String = "defensive", engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL) -> Dictionary:
	var normalized_map_type: String = LevelConfig.normalize_engagement_map_type(engagement_map_type)
	if phase == "grand_map":
		return _generate_generic_layout_defs(candidate_seed, level_index, pin_count, gen_rng, phase, normalized_map_type)
	if phase == LevelConfig.PHASE_OFFENSIVE:
		return _generate_enemy_offense_layout(candidate_seed, level_index, pin_count, gen_rng, normalized_map_type)
	if phase == LevelConfig.PHASE_NEUTRAL:
		return _generate_neutral_offense_layout(candidate_seed, level_index, pin_count, gen_rng, normalized_map_type)
	return _generate_generic_layout_defs(candidate_seed, level_index, pin_count, gen_rng, phase, normalized_map_type)

func _generate_generic_layout_defs(candidate_seed: int, level_index: int, pin_count: int, gen_rng: RandomNumberGenerator, phase: String = "defensive", engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL) -> Dictionary:
	var interior_half: Vector2
	if phase == "grand_map":
		interior_half = LevelConfig.GRAND_MAP_PLAYABLE_HALF_EXTENTS
	else:
		interior_half = LevelConfig.PLAYABLE_HALF_EXTENTS

	var placement_margin := -LevelConfig.ZONE_PLACEMENT_OVERHANG
	var normalized_map_type: String = LevelConfig.normalize_engagement_map_type(engagement_map_type)
	var obstacle_mult: float = 1.0 if phase == "grand_map" else LevelConfig.get_engagement_map_obstacle_multiplier(normalized_map_type)
	var friction_mult: float = 1.0 if phase == "grand_map" else LevelConfig.get_engagement_map_friction_multiplier(normalized_map_type)
	var water_mult: float = 1.0 if phase == "grand_map" else LevelConfig.get_engagement_map_water_multiplier(normalized_map_type)
	var oil_bias: float = 0.0 if phase == "grand_map" else LevelConfig.get_engagement_map_oil_probability_bias(normalized_map_type)

	var templates_to_place: Array[Dictionary] = []
	var placed_influence: Array[Dictionary] = []

	var obstacle_count := 3
	if phase == "grand_map":
		obstacle_count = LevelConfig.GRAND_MAP_ZONE_OBSTACLE_BASE
		obstacle_count = clampi(obstacle_count, LevelConfig.GRAND_MAP_ZONE_OBSTACLE_BASE, 24)
	else:
		obstacle_count = clampi(int(round(float(obstacle_count) * obstacle_mult)), 1, LevelConfig.ZONE_OBSTACLE_HARD_CAP)
	for i in range(obstacle_count):
		var obstacle_tpl := _pick_obstacle_template(gen_rng)
		var obstacle_plc := _make_template_placement_with_separation(obstacle_tpl, interior_half, placement_margin, gen_rng, placed_influence)
		templates_to_place.append(obstacle_plc)
		_record_influence(obstacle_plc, placed_influence)

	var friction_count := 8
	if phase == "grand_map":
		friction_count = LevelConfig.GRAND_MAP_FRICTION_BASE
		friction_count = clampi(friction_count, LevelConfig.GRAND_MAP_FRICTION_BASE, 32)
	else:
		friction_count = clampi(int(round(float(friction_count) * friction_mult)), 4, 14)
	var oil_chance: float = clampf(0.35 + oil_bias, 0.05, 0.95)
	for i in range(friction_count):
		var want_oil := gen_rng.randf() < oil_chance
		var friction_tpl := _pick_friction_template(gen_rng, want_oil)
		var friction_plc := _make_template_placement_with_separation(friction_tpl, interior_half, placement_margin, gen_rng, placed_influence)
		templates_to_place.append(friction_plc)
		_record_influence(friction_plc, placed_influence)

	var water_count := LevelConfig.WATER_ZONE_BASE_COUNT
	if phase == "grand_map":
		water_count = LevelConfig.GRAND_MAP_WATER_BASE_COUNT
		water_count = clampi(water_count, LevelConfig.GRAND_MAP_WATER_BASE_COUNT, 18)
	else:
		water_count = clampi(int(round(float(water_count) * water_mult)), 1, LevelConfig.WATER_ZONE_HARD_CAP)
	for i in range(water_count):
		var water_tpl := _pick_water_template(gen_rng)
		var water_plc := _make_template_placement_with_separation(water_tpl, interior_half, placement_margin, gen_rng, placed_influence)
		templates_to_place.append(water_plc)
		_record_influence(water_plc, placed_influence)

	if phase == "grand_map":
		if LevelConfig.GRAND_MAP_ENABLE_GRADE_ZONES:
			var grand_grade_count := LevelConfig.GRAND_MAP_GRADE_BASE_COUNT
			grand_grade_count = clampi(grand_grade_count, LevelConfig.GRAND_MAP_GRADE_BASE_COUNT, 12)
			for i in range(grand_grade_count):
				var grade_tpl := _pick_large_grade_template(gen_rng)
				var grade_plc := _make_large_grade_placement(grade_tpl, interior_half, gen_rng)
				templates_to_place.append(grade_plc)
	else:
		var grade_count := LevelConfig.GRADE_TEMPLATE_COUNT
		grade_count = clampi(grade_count, LevelConfig.GRADE_TEMPLATE_COUNT, LevelConfig.ZONE_GRADE_HARD_CAP)
		for i in range(grade_count):
			var grade_tpl := _pick_large_grade_template(gen_rng)
			var grade_plc := _make_large_grade_placement(grade_tpl, interior_half, gen_rng)
			templates_to_place.append(grade_plc)

	var expanded := _expand_placements_to_components(templates_to_place, gen_rng)
	var out := _base_layout_dict(candidate_seed, level_index, interior_half, templates_to_place, expanded, pin_count, phase)
	out["motif"] = "generic"
	out[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = normalized_map_type
	return out

func _generate_enemy_offense_layout(candidate_seed: int, level_index: int, pin_count: int, gen_rng: RandomNumberGenerator, engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL) -> Dictionary:
	var interior_half := LevelConfig.PLAYABLE_HALF_EXTENTS
	var templates_to_place: Array[Dictionary] = []
	var placed_influence: Array[Dictionary] = []

	var motif := _pick_weighted_name(LevelConfig.ENEMY_OFFENSE_MOTIF_WEIGHTS, gen_rng)
	var center := _pick_anchor_center(interior_half, gen_rng, 230.0)
	var axis := Vector2.RIGHT.rotated(gen_rng.randf_range(0.0, TAU))
	var perp := Vector2(-axis.y, axis.x)

	var motif_data := _build_enemy_offense_motif(motif, center, axis, perp, interior_half, gen_rng)
	var motif_templates: Array = motif_data.get("templates", [])
	for plc in motif_templates:
		templates_to_place.append(plc)
		_record_influence(plc, placed_influence)

	var building_anchors: Array = motif_data.get("building_anchors", [])
	for anchor_any in building_anchors:
		var anchor: Vector2 = anchor_any
		_record_anchor_influence(anchor, placed_influence)

	_add_structured_ambient_templates(templates_to_place, placed_influence, interior_half, gen_rng, LevelConfig.PHASE_OFFENSIVE, engagement_map_type)

	var expanded := _expand_placements_to_components(templates_to_place, gen_rng)
	var out := _base_layout_dict(candidate_seed, level_index, interior_half, templates_to_place, expanded, pin_count, LevelConfig.PHASE_OFFENSIVE)
	out["motif"] = motif
	out["pin_groups"] = motif_data.get("pin_groups", [])
	out["building_anchors"] = building_anchors
	out["motif_center"] = center
	out["motif_axis"] = axis
	out["motif_perp"] = perp
	out[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = LevelConfig.normalize_engagement_map_type(engagement_map_type)
	return out

func _generate_neutral_offense_layout(candidate_seed: int, level_index: int, pin_count: int, gen_rng: RandomNumberGenerator, engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL) -> Dictionary:
	var interior_half := LevelConfig.PLAYABLE_HALF_EXTENTS
	var templates_to_place: Array[Dictionary] = []
	var placed_influence: Array[Dictionary] = []

	var motif := _pick_weighted_name(LevelConfig.NEUTRAL_OFFENSE_MOTIF_WEIGHTS, gen_rng)
	var center := _pick_anchor_center(interior_half, gen_rng, 210.0)
	var axis := Vector2.RIGHT.rotated(gen_rng.randf_range(0.0, TAU))
	var perp := Vector2(-axis.y, axis.x)

	var motif_data := _build_neutral_offense_motif(motif, center, axis, perp, interior_half, gen_rng)
	var motif_templates: Array = motif_data.get("templates", [])
	for plc in motif_templates:
		templates_to_place.append(plc)
		_record_influence(plc, placed_influence)

	_add_structured_ambient_templates(templates_to_place, placed_influence, interior_half, gen_rng, LevelConfig.PHASE_NEUTRAL, engagement_map_type)

	var expanded := _expand_placements_to_components(templates_to_place, gen_rng)
	var out := _base_layout_dict(candidate_seed, level_index, interior_half, templates_to_place, expanded, pin_count, LevelConfig.PHASE_NEUTRAL)
	out["motif"] = motif
	out["pin_groups"] = motif_data.get("pin_groups", [])
	out["building_anchors"] = []
	out["motif_center"] = center
	out["motif_axis"] = axis
	out["motif_perp"] = perp
	out[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = LevelConfig.normalize_engagement_map_type(engagement_map_type)
	return out

func _base_layout_dict(candidate_seed: int, level_index: int, interior_half: Vector2, templates_to_place: Array[Dictionary], expanded: Dictionary, pin_count: int, phase: String) -> Dictionary:
	return {
		"candidate_seed": candidate_seed,
		"level_index": level_index,
		"interior_half": interior_half,
		"templates": templates_to_place,
		"obstacles": expanded.get("obstacles", []),
		"friction_zones": expanded.get("friction_zones", []),
		"water_zones": expanded.get("water_zones", []),
		"grade_zones": expanded.get("grade_zones", []),
		"pins": [],
		"requested_pin_count": pin_count,
		"phase": phase,
		PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
	}

func _expand_placements_to_components(templates_to_place: Array[Dictionary], gen_rng: RandomNumberGenerator) -> Dictionary:
	var obstacles: Array[Dictionary] = []
	var friction_zones: Array[Dictionary] = []
	var water_zones: Array[Dictionary] = []
	var grade_zones: Array[Dictionary] = []

	for p in templates_to_place:
		var tpl: ZoneTemplate = p.get("template", null)
		if tpl == null:
			continue
		_expand_template_components(p, obstacles, friction_zones, water_zones, grade_zones, gen_rng)

	return {
		"obstacles": obstacles,
		"friction_zones": friction_zones,
		"water_zones": water_zones,
		"grade_zones": grade_zones
	}

func _add_structured_ambient_templates(templates_to_place: Array[Dictionary], placed_influence: Array[Dictionary], interior_half: Vector2, gen_rng: RandomNumberGenerator, phase: String, engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL) -> void:
	var obstacle_count := 0
	var friction_count := 0
	var water_count := 0
	var grade_count := 0
	var oil_chance := 0.35
	var normalized_map_type: String = LevelConfig.normalize_engagement_map_type(engagement_map_type)

	if phase == LevelConfig.PHASE_OFFENSIVE:
		obstacle_count = gen_rng.randi_range(LevelConfig.ENEMY_OFFENSE_TEMPLATE_BUDGET_MIN, LevelConfig.ENEMY_OFFENSE_TEMPLATE_BUDGET_MAX)
		friction_count = gen_rng.randi_range(LevelConfig.ENEMY_OFFENSE_FRICTION_MIN, LevelConfig.ENEMY_OFFENSE_FRICTION_MAX)
		water_count = gen_rng.randi_range(LevelConfig.ENEMY_OFFENSE_WATER_MIN, LevelConfig.ENEMY_OFFENSE_WATER_MAX)
		grade_count = gen_rng.randi_range(LevelConfig.ENEMY_OFFENSE_GRADE_MIN, LevelConfig.ENEMY_OFFENSE_GRADE_MAX)
		oil_chance = 0.55
	else:
		obstacle_count = gen_rng.randi_range(LevelConfig.NEUTRAL_OFFENSE_TEMPLATE_BUDGET_MIN, LevelConfig.NEUTRAL_OFFENSE_TEMPLATE_BUDGET_MAX)
		friction_count = gen_rng.randi_range(LevelConfig.NEUTRAL_OFFENSE_FRICTION_MIN, LevelConfig.NEUTRAL_OFFENSE_FRICTION_MAX)
		water_count = gen_rng.randi_range(LevelConfig.NEUTRAL_OFFENSE_WATER_MIN, LevelConfig.NEUTRAL_OFFENSE_WATER_MAX)
		grade_count = gen_rng.randi_range(LevelConfig.NEUTRAL_OFFENSE_GRADE_MIN, LevelConfig.NEUTRAL_OFFENSE_GRADE_MAX)
		oil_chance = 0.32

	obstacle_count = maxi(1, int(round(float(obstacle_count) * LevelConfig.get_engagement_map_obstacle_multiplier(normalized_map_type))))
	friction_count = maxi(2, int(round(float(friction_count) * LevelConfig.get_engagement_map_friction_multiplier(normalized_map_type))))
	water_count = maxi(1, int(round(float(water_count) * LevelConfig.get_engagement_map_water_multiplier(normalized_map_type))))
	oil_chance = clampf(oil_chance + LevelConfig.get_engagement_map_oil_probability_bias(normalized_map_type), 0.05, 0.95)

	var placement_margin := -LevelConfig.ZONE_PLACEMENT_OVERHANG

	for i in range(obstacle_count):
		var obstacle_tpl := _pick_obstacle_template(gen_rng)
		var obstacle_plc := _make_template_placement_with_separation(obstacle_tpl, interior_half, placement_margin, gen_rng, placed_influence)
		templates_to_place.append(obstacle_plc)
		_record_influence(obstacle_plc, placed_influence)

	for i in range(friction_count):
		var want_oil := gen_rng.randf() < oil_chance
		var friction_tpl := _pick_friction_template(gen_rng, want_oil)
		var friction_plc := _make_template_placement_with_separation(friction_tpl, interior_half, placement_margin, gen_rng, placed_influence)
		templates_to_place.append(friction_plc)
		_record_influence(friction_plc, placed_influence)

	for i in range(water_count):
		var water_tpl := _pick_water_template(gen_rng)
		var water_plc := _make_template_placement_with_separation(water_tpl, interior_half, placement_margin, gen_rng, placed_influence)
		templates_to_place.append(water_plc)
		_record_influence(water_plc, placed_influence)

	for i in range(grade_count):
		var grade_tpl := _pick_large_grade_template(gen_rng)
		var grade_plc := _make_large_grade_placement(grade_tpl, interior_half, gen_rng)
		templates_to_place.append(grade_plc)

func _pick_weighted_name(weights: Dictionary, gen_rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for value in weights.values():
		total += float(value)
	if total <= 0.0:
		for key in weights.keys():
			return String(key)
		return ""
	var roll := gen_rng.randf() * total
	var accum := 0.0
	for key in weights.keys():
		accum += float(weights.get(key, 0.0))
		if roll <= accum:
			return String(key)
	for key in weights.keys():
		return String(key)
	return ""

func _pick_anchor_center(interior_half: Vector2, gen_rng: RandomNumberGenerator, margin: float) -> Vector2:
	var usable_x := maxf(80.0, interior_half.x - margin)
	var usable_y := maxf(80.0, interior_half.y - margin)
	return Vector2(
		gen_rng.randf_range(-usable_x, usable_x),
		gen_rng.randf_range(-usable_y, usable_y)
	)

func _clamp_point_to_interior(point: Vector2, interior_half: Vector2, margin: float = 110.0) -> Vector2:
	return Vector2(
		clampf(point.x, -interior_half.x + margin, interior_half.x - margin),
		clampf(point.y, -interior_half.y + margin, interior_half.y - margin)
	)

func _record_anchor_influence(anchor: Vector2, placed: Array[Dictionary]) -> void:
	placed.append({
		"template": null,
		"origin": anchor,
		"rotation": 0.0,
		"scale": 1.0
	})

func _append_placement(templates_to_place: Array[Dictionary], tpl: ZoneTemplate, origin: Vector2, rotation: float = 0.0, scale: float = 1.0) -> Dictionary:
	var plc := {
		"template": tpl,
		"origin": origin,
		"rotation": rotation,
		"scale": scale
	}
	templates_to_place.append(plc)
	return plc

func _make_obstacle_placement(templates_to_place: Array[Dictionary], origin: Vector2, radius: float) -> Dictionary:
	var tpl := ZoneTemplate.make_obstacle_island("MotifObstacle", Vector2.ZERO, radius)
	return _append_placement(templates_to_place, tpl, origin)

func _make_water_placement(templates_to_place: Array[Dictionary], origin: Vector2, radius: float, aspect: float = 1.0, rotation: float = 0.0) -> Dictionary:
	var tpl := ZoneTemplate.make_water_pool("MotifWater", Vector2.ZERO, radius, aspect)
	return _append_placement(templates_to_place, tpl, origin, rotation)

func _snap_boardwalk_aspect(aspect: float) -> float:
	var safe_aspect := clampf(aspect, 0.24, 4.0)
	if safe_aspect <= 0.40:
		return 0.42
	if safe_aspect <= 0.56:
		return 0.52
	if safe_aspect <= 0.76:
		return 0.68
	if safe_aspect <= 1.28:
		return 1.0
	if safe_aspect <= 1.76:
		return 1.52
	return 2.08

func _tune_boardwalk_radius(radius: float, snapped_aspect: float) -> float:
	var tuned_radius := maxf(radius, 96.0)
	if snapped_aspect < 0.8:
		tuned_radius = maxf(tuned_radius, 108.0)
	elif snapped_aspect > 1.25:
		tuned_radius = maxf(tuned_radius, 104.0)
	return tuned_radius

func _make_boardwalk_placement(templates_to_place: Array[Dictionary], origin: Vector2, radius: float, aspect: float, rotation: float = 0.0) -> Dictionary:
	var snapped_aspect := _snap_boardwalk_aspect(aspect)
	var tuned_radius := _tune_boardwalk_radius(radius, snapped_aspect)
	var tpl := ZoneTemplate.make_boardwalk_rect("MotifBoardwalk", Vector2.ZERO, tuned_radius, snapped_aspect)
	return _append_placement(templates_to_place, tpl, origin, rotation)

func _make_grass_placement(templates_to_place: Array[Dictionary], origin: Vector2, radius: float) -> Dictionary:
	var tpl := ZoneTemplate.make_bush_cluster("MotifGrass", Vector2.ZERO, radius)
	return _append_placement(templates_to_place, tpl, origin)

func _make_grade_placement(templates_to_place: Array[Dictionary], origin: Vector2, radius: float, accel: Vector2) -> Dictionary:
	var tpl := ZoneTemplate.make_grade_patch("MotifGrade", Vector2.ZERO, radius, accel)
	return _append_placement(templates_to_place, tpl, origin)

func _make_pin_group(center: Vector2, radius: float, weight: float, role: String) -> Dictionary:
	return {
		"center": center,
		"radius": radius,
		"weight": weight,
		"role": role
	}

func _build_enemy_offense_motif(motif: String, center: Vector2, axis: Vector2, perp: Vector2, interior_half: Vector2, gen_rng: RandomNumberGenerator) -> Dictionary:
	var templates: Array[Dictionary] = []
	var pin_groups: Array[Dictionary] = []
	var building_anchors: Array[Vector2] = []

	var core_r := gen_rng.randf_range(LevelConfig.ENEMY_OFFENSE_CORE_RADIUS_MIN, LevelConfig.ENEMY_OFFENSE_CORE_RADIUS_MAX)
	var guard_r := gen_rng.randf_range(LevelConfig.ENEMY_OFFENSE_GUARD_RING_RADIUS_MIN, LevelConfig.ENEMY_OFFENSE_GUARD_RING_RADIUS_MAX)
	var lane_w := gen_rng.randf_range(LevelConfig.ENEMY_OFFENSE_LANE_WIDTH_MIN, LevelConfig.ENEMY_OFFENSE_LANE_WIDTH_MAX)
	var bank_offset := gen_rng.randf_range(LevelConfig.ENEMY_OFFENSE_BANK_OFFSET_MIN, LevelConfig.ENEMY_OFFENSE_BANK_OFFSET_MAX)
	var shell_dist := gen_rng.randf_range(LevelConfig.ENEMY_OFFENSE_OFFSET_COVER_DISTANCE_MIN, LevelConfig.ENEMY_OFFENSE_OFFSET_COVER_DISTANCE_MAX)
	var orientation := axis.angle() - PI * 0.5

	match motif:
		LevelConfig.ENEMY_OFFENSE_MOTIF_PROTECTED_CORE:
			var core := center
			var left_anchor := _clamp_point_to_interior(core + perp * (shell_dist * 0.58), interior_half)
			var right_anchor := _clamp_point_to_interior(core - perp * (shell_dist * 0.58), interior_half)
			var rear_obstacle := _clamp_point_to_interior(core + axis * (shell_dist * 0.42), interior_half)
			var exposed := _clamp_point_to_interior(core - axis * (guard_r * 0.95), interior_half)
			var support := _clamp_point_to_interior(core + axis * (core_r * 0.55) + perp * (guard_r * 0.48), interior_half)

			building_anchors.append(left_anchor)
			building_anchors.append(right_anchor)
			_make_obstacle_placement(templates, rear_obstacle, 62.0)
			_make_boardwalk_placement(templates, _clamp_point_to_interior(core - axis * (core_r * 0.92), interior_half), 124.0, 0.46, orientation)
			_make_grass_placement(templates, _clamp_point_to_interior(core + axis * (guard_r * 0.55) - perp * (guard_r * 0.28), interior_half), 86.0)

			pin_groups.append(_make_pin_group(core, core_r * 0.72, 1.55, ROLE_CORE))
			pin_groups.append(_make_pin_group(exposed, lane_w * 0.62, 0.92, ROLE_EXPOSED))
			pin_groups.append(_make_pin_group(support, lane_w * 0.52, 0.62, ROLE_SUPPORT))

		LevelConfig.ENEMY_OFFENSE_MOTIF_LAYERED_SHELL:
			var shell_core := center
			var outer_a := _clamp_point_to_interior(shell_core + axis * (guard_r * 0.78), interior_half)
			var outer_b := _clamp_point_to_interior(shell_core + perp * (guard_r * 0.74), interior_half)
			var outer_c := _clamp_point_to_interior(shell_core - perp * (guard_r * 0.74), interior_half)
			var gap_lane := _clamp_point_to_interior(shell_core - axis * (guard_r * 0.88), interior_half)

			building_anchors.append(_clamp_point_to_interior(shell_core + axis * (core_r * 0.60), interior_half))
			building_anchors.append(_clamp_point_to_interior(shell_core - axis * (core_r * 0.18), interior_half))
			_make_obstacle_placement(templates, outer_b, 54.0)
			_make_obstacle_placement(templates, outer_c, 54.0)
			_make_water_placement(templates, outer_a, 96.0, 1.10, axis.angle())
			_make_boardwalk_placement(templates, gap_lane, 116.0, 0.44, orientation)

			pin_groups.append(_make_pin_group(shell_core, core_r * 0.68, 1.45, ROLE_CORE))
			pin_groups.append(_make_pin_group(gap_lane, lane_w * 0.58, 0.78, ROLE_LANE))
			pin_groups.append(_make_pin_group(_clamp_point_to_interior(shell_core + axis * (guard_r * 0.42), interior_half), lane_w * 0.46, 0.58, ROLE_GUARD))

		LevelConfig.ENEMY_OFFENSE_MOTIF_FLANK_LANE:
			var flank_core := _clamp_point_to_interior(center + perp * 60.0, interior_half)
			var lane_entry := _clamp_point_to_interior(flank_core - perp * (guard_r * 0.92), interior_half)
			var lane_mid := _clamp_point_to_interior(flank_core - perp * (guard_r * 0.38), interior_half)
			var guard_left := _clamp_point_to_interior(flank_core + axis * (shell_dist * 0.42), interior_half)
			var guard_right := _clamp_point_to_interior(flank_core - axis * (shell_dist * 0.42), interior_half)
			var exposed_guard := _clamp_point_to_interior(flank_core + perp * (guard_r * 0.82), interior_half)

			building_anchors.append(guard_left)
			building_anchors.append(guard_right)
			_make_boardwalk_placement(templates, lane_mid, 138.0, 0.44, axis.angle())
			_make_grass_placement(templates, _clamp_point_to_interior(flank_core + perp * (guard_r * 0.24) + axis * 90.0, interior_half), 92.0)
			_make_obstacle_placement(templates, _clamp_point_to_interior(flank_core + perp * (core_r * 0.50), interior_half), 58.0)

			pin_groups.append(_make_pin_group(flank_core, core_r * 0.66, 1.48, ROLE_CORE))
			pin_groups.append(_make_pin_group(lane_entry, lane_w * 0.56, 0.72, ROLE_LANE))
			pin_groups.append(_make_pin_group(exposed_guard, lane_w * 0.60, 0.88, ROLE_EXPOSED))

		LevelConfig.ENEMY_OFFENSE_MOTIF_CHOKE_OPENING:
			var choke_core := _clamp_point_to_interior(center + axis * 55.0, interior_half)
			var choke_left := _clamp_point_to_interior(center + perp * (lane_w * 0.46), interior_half)
			var choke_right := _clamp_point_to_interior(center - perp * (lane_w * 0.46), interior_half)
			var choke_exposed := _clamp_point_to_interior(center - axis * (guard_r * 0.92), interior_half)
			var rear_support := _clamp_point_to_interior(choke_core + axis * (core_r * 0.78), interior_half)

			_make_obstacle_placement(templates, choke_left, 64.0)
			_make_obstacle_placement(templates, choke_right, 64.0)
			building_anchors.append(_clamp_point_to_interior(choke_core + perp * (shell_dist * 0.42), interior_half))
			building_anchors.append(_clamp_point_to_interior(choke_core - perp * (shell_dist * 0.42), interior_half))
			_make_water_placement(templates, rear_support, 86.0, 0.82, axis.angle())
			_make_boardwalk_placement(templates, _clamp_point_to_interior(center - axis * (core_r * 0.42), interior_half), 108.0, 0.44, orientation)

			pin_groups.append(_make_pin_group(choke_core, core_r * 0.70, 1.52, ROLE_CORE))
			pin_groups.append(_make_pin_group(choke_exposed, lane_w * 0.55, 0.82, ROLE_EXPOSED))
			pin_groups.append(_make_pin_group(_clamp_point_to_interior(choke_core + axis * (core_r * 0.48), interior_half), lane_w * 0.44, 0.58, ROLE_SUPPORT))

		LevelConfig.ENEMY_OFFENSE_MOTIF_SPLIT_DEFENSE:
			var split_gap := gen_rng.randf_range(LevelConfig.ENEMY_OFFENSE_SPLIT_GAP_MIN, LevelConfig.ENEMY_OFFENSE_SPLIT_GAP_MAX)
			var left_core := _clamp_point_to_interior(center + perp * (split_gap * 0.52), interior_half)
			var right_core := _clamp_point_to_interior(center - perp * (split_gap * 0.52), interior_half)
			var bridge := _clamp_point_to_interior(center - axis * (core_r * 0.55), interior_half)
			var rear := _clamp_point_to_interior(center + axis * (guard_r * 0.55), interior_half)

			building_anchors.append(_clamp_point_to_interior(left_core + axis * 70.0, interior_half))
			building_anchors.append(_clamp_point_to_interior(right_core + axis * 70.0, interior_half))
			_make_obstacle_placement(templates, _clamp_point_to_interior(center + axis * 36.0, interior_half), 58.0)
			_make_boardwalk_placement(templates, bridge, 112.0, 0.60, orientation)
			_make_grass_placement(templates, rear, 102.0)

			pin_groups.append(_make_pin_group(left_core, core_r * 0.58, 0.95, ROLE_CORE))
			pin_groups.append(_make_pin_group(right_core, core_r * 0.58, 0.95, ROLE_CORE))
			pin_groups.append(_make_pin_group(bridge, lane_w * 0.54, 0.72, ROLE_DECOY))

		_:
			var bank_core := _clamp_point_to_interior(center + axis * 48.0, interior_half)
			var bank_obstacle := _clamp_point_to_interior(bank_core - perp * (bank_offset * 0.48), interior_half)
			var bank_lane := _clamp_point_to_interior(bank_core + perp * (bank_offset * 0.42), interior_half)
			var bank_exposed := _clamp_point_to_interior(center - axis * (guard_r * 0.88), interior_half)
			var bank_support := _clamp_point_to_interior(bank_core + axis * (core_r * 0.68), interior_half)

			_make_obstacle_placement(templates, bank_obstacle, 72.0)
			_make_boardwalk_placement(templates, bank_lane, 132.0, 0.48, axis.angle())
			_make_grade_placement(templates, _clamp_point_to_interior(bank_lane + axis * 26.0, interior_half), 122.0, axis * (LevelConfig.GRADE_ACCEL_MIN * 1.05))
			building_anchors.append(_clamp_point_to_interior(bank_core + perp * (shell_dist * 0.34), interior_half))
			building_anchors.append(_clamp_point_to_interior(bank_support - perp * (shell_dist * 0.28), interior_half))

			pin_groups.append(_make_pin_group(bank_core, core_r * 0.68, 1.48, ROLE_CORE))
			pin_groups.append(_make_pin_group(bank_exposed, lane_w * 0.56, 0.84, ROLE_EXPOSED))
			pin_groups.append(_make_pin_group(bank_support, lane_w * 0.48, 0.62, ROLE_SUPPORT))

	return {
		"templates": templates,
		"pin_groups": pin_groups,
		"building_anchors": building_anchors
	}

func _build_neutral_offense_motif(motif: String, center: Vector2, axis: Vector2, perp: Vector2, interior_half: Vector2, gen_rng: RandomNumberGenerator) -> Dictionary:
	var templates: Array[Dictionary] = []
	var pin_groups: Array[Dictionary] = []

	var cluster_r := gen_rng.randf_range(LevelConfig.NEUTRAL_OFFENSE_CLUSTER_RADIUS_MIN, LevelConfig.NEUTRAL_OFFENSE_CLUSTER_RADIUS_MAX)
	var spread := gen_rng.randf_range(LevelConfig.NEUTRAL_OFFENSE_OPEN_SPREAD_MIN, LevelConfig.NEUTRAL_OFFENSE_OPEN_SPREAD_MAX)
	var stagger_step := gen_rng.randf_range(LevelConfig.NEUTRAL_OFFENSE_STAGGER_STEP_MIN, LevelConfig.NEUTRAL_OFFENSE_STAGGER_STEP_MAX)
	var pocket_offset := gen_rng.randf_range(LevelConfig.NEUTRAL_OFFENSE_POCKET_OFFSET_MIN, LevelConfig.NEUTRAL_OFFENSE_POCKET_OFFSET_MAX)
	var lane_clear := gen_rng.randf_range(LevelConfig.NEUTRAL_OFFENSE_CLEAR_LANE_MIN, LevelConfig.NEUTRAL_OFFENSE_CLEAR_LANE_MAX)
	var orientation := axis.angle() - PI * 0.5

	match motif:
		LevelConfig.NEUTRAL_OFFENSE_MOTIF_OPEN_FAN:
			var fan_a := _clamp_point_to_interior(center - axis * (spread * 0.42), interior_half)
			var fan_b := _clamp_point_to_interior(center + perp * (spread * 0.40), interior_half)
			var fan_c := _clamp_point_to_interior(center - perp * (spread * 0.40), interior_half)
			_make_boardwalk_placement(templates, center, 120.0, 0.62, orientation)
			pin_groups.append(_make_pin_group(fan_a, cluster_r * 0.92, 1.05, ROLE_EXPOSED))
			pin_groups.append(_make_pin_group(fan_b, cluster_r * 0.76, 0.82, ROLE_POCKET))
			pin_groups.append(_make_pin_group(fan_c, cluster_r * 0.76, 0.82, ROLE_POCKET))

		LevelConfig.NEUTRAL_OFFENSE_MOTIF_SOFT_SPLIT:
			var soft_left := _clamp_point_to_interior(center + perp * (spread * 0.32), interior_half)
			var soft_right := _clamp_point_to_interior(center - perp * (spread * 0.32), interior_half)
			_make_grass_placement(templates, _clamp_point_to_interior(center + axis * 58.0, interior_half), 72.0)
			pin_groups.append(_make_pin_group(soft_left, cluster_r * 0.84, 1.00, ROLE_EXPOSED))
			pin_groups.append(_make_pin_group(soft_right, cluster_r * 0.84, 0.95, ROLE_EXPOSED))

		LevelConfig.NEUTRAL_OFFENSE_MOTIF_EXPOSED_POCKET:
			var pocket_main := _clamp_point_to_interior(center - axis * (pocket_offset * 0.55), interior_half)
			var pocket_side := _clamp_point_to_interior(center + perp * (pocket_offset * 0.62), interior_half)
			_make_water_placement(templates, _clamp_point_to_interior(center + axis * (cluster_r * 0.90), interior_half), 76.0, 1.28, axis.angle())
			pin_groups.append(_make_pin_group(pocket_main, cluster_r * 0.96, 1.15, ROLE_EXPOSED))
			pin_groups.append(_make_pin_group(pocket_side, cluster_r * 0.66, 0.72, ROLE_POCKET))

		LevelConfig.NEUTRAL_OFFENSE_MOTIF_CLEAN_RICOCHET:
			var ricochet_left := _clamp_point_to_interior(center + perp * (spread * 0.30), interior_half)
			var ricochet_right := _clamp_point_to_interior(center - perp * (spread * 0.30), interior_half)
			var ricochet_obstacle := _clamp_point_to_interior(center + axis * 22.0, interior_half)
			_make_obstacle_placement(templates, ricochet_obstacle, 48.0)
			_make_boardwalk_placement(templates, _clamp_point_to_interior(center - axis * 62.0, interior_half), 106.0, 0.62, orientation)
			pin_groups.append(_make_pin_group(ricochet_left, cluster_r * 0.78, 0.92, ROLE_EXPOSED))
			pin_groups.append(_make_pin_group(ricochet_right, cluster_r * 0.78, 0.92, ROLE_EXPOSED))
			pin_groups.append(_make_pin_group(_clamp_point_to_interior(center + axis * 92.0, interior_half), cluster_r * 0.56, 0.50, ROLE_POCKET))

		_:
			var stagger_a := _clamp_point_to_interior(center - axis * (lane_clear * 0.42) - perp * (stagger_step * 0.72), interior_half)
			var stagger_b := _clamp_point_to_interior(center, interior_half)
			var stagger_c := _clamp_point_to_interior(center + axis * (lane_clear * 0.42) + perp * (stagger_step * 0.72), interior_half)
			_make_boardwalk_placement(templates, _clamp_point_to_interior(center - perp * 34.0, interior_half), 116.0, 0.60, orientation)
			pin_groups.append(_make_pin_group(stagger_a, cluster_r * 0.72, 0.82, ROLE_EXPOSED))
			pin_groups.append(_make_pin_group(stagger_b, cluster_r * 0.82, 1.02, ROLE_EXPOSED))
			pin_groups.append(_make_pin_group(stagger_c, cluster_r * 0.72, 0.82, ROLE_EXPOSED))

	return {
		"templates": templates,
		"pin_groups": pin_groups,
		"building_anchors": []
	}

func _generate_provinces(playable_half: Vector2, gen_rng: RandomNumberGenerator) -> Array[Dictionary]:
	var grand_data: Dictionary = _generate_template_grand_map_data(playable_half, gen_rng, 1, 1)
	return grand_data.get("provinces", [])



func _generate_template_grand_map_data(playable_half: Vector2, gen_rng: RandomNumberGenerator, map_seed: int = 1, level_index: int = 1) -> Dictionary:
	var grid_cols: int = maxi(30, int(round(float(LevelConfig.GRAND_MAP_LAND_GRID_COLS) * 1.35)))
	var grid_rows: int = maxi(42, int(round(float(LevelConfig.GRAND_MAP_LAND_GRID_ROWS) * 1.35)))
	var template_ids: Array[String] = LevelConfig.GRAND_MAP_TEMPLATE_IDS
	var template_id: String = template_ids[gen_rng.randi_range(0, template_ids.size() - 1)] if not template_ids.is_empty() else LevelConfig.GRAND_MAP_TEMPLATE_AFRICA

	# Regression fix: after the recent template rewrite, the old post-build normalization pass was lost.
	# We now restore that behavior in two stages after carving:
	# 1) uniformly expand the mainland until either width or height nearly maxes out the playable mask;
	# 2) if the shorter axis is too skinny, stretch it outward until it reaches at least half the longer axis.
	var land_mask: Array = _build_template_land_mask(grid_cols, grid_rows, template_id, gen_rng)
	var base_land_mask: Array = land_mask.duplicate(true)
	var profile: Dictionary = LevelConfig.get_grand_map_template_profile(template_id)
	var coast_variance: float = float(profile.get("coast_variance", LevelConfig.GRAND_MAP_TEMPLATE_COAST_VARIANCE))
	var coast_nibbles: int = 2 + gen_rng.randi_range(LevelConfig.GRAND_MAP_TEMPLATE_EXTRA_BITE_MIN, LevelConfig.GRAND_MAP_TEMPLATE_EXTRA_BITE_MAX)
	coast_nibbles += int(round(coast_variance * 2.0))
	for nibble_idx in range(coast_nibbles):
		_apply_light_template_bite(land_mask, grid_cols, grid_rows, template_id, gen_rng)
	if coast_variance > 0.16:
		_carve_template_bays(land_mask, grid_cols, grid_rows, template_id, gen_rng)
	if coast_variance > 0.12:
		_apply_template_identity_carves(land_mask, grid_cols, grid_rows, template_id, gen_rng)
	land_mask = _smooth_land_mask(land_mask, grid_cols, grid_rows)
	_fill_small_land_gaps(land_mask, grid_cols, grid_rows)
	land_mask = _keep_largest_land_component(land_mask, grid_cols, grid_rows)
	land_mask = _expand_and_rebalance_land_mask(land_mask, grid_cols, grid_rows)

	if not _is_valid_mask_grid(land_mask, grid_cols, grid_rows):
		land_mask = _build_fallback_land_mask(grid_cols, grid_rows, template_id, gen_rng, base_land_mask)
		land_mask = _expand_and_rebalance_land_mask(land_mask, grid_cols, grid_rows)

	var land_cells: Array[Vector2i] = _collect_mask_cells(land_mask, true, grid_cols, grid_rows)
	if land_cells.size() < 70:
		land_mask = _build_fallback_land_mask(grid_cols, grid_rows, template_id, gen_rng, base_land_mask)
		land_mask = _expand_and_rebalance_land_mask(land_mask, grid_cols, grid_rows)
		land_cells = _collect_mask_cells(land_mask, true, grid_cols, grid_rows)

	var multiplier: float = LevelConfig.GRAND_MAP_SIZE_MULTIPLIER
	var base: int = int(multiplier * LevelConfig.GRAND_MAP_PROVINCES_PER_MULTIPLIER)
	var var_count: int = LevelConfig.GRAND_MAP_PROVINCE_VARIATION
	var target_count: int = clampi(base + gen_rng.randi_range(-var_count, var_count), 24, 36)
	var max_reasonable: int = maxi(12, land_cells.size() / 18)
	var province_count: int = mini(target_count, max_reasonable)

	var seed_cells: Array[Vector2i] = _pick_region_seed_cells(land_cells, province_count, gen_rng)
	var assignments: Array = _grow_regions_from_seeds(land_mask, seed_cells, grid_cols, grid_rows, gen_rng)
	var province_build: Dictionary = _build_province_dicts_from_assignments(assignments, land_mask, seed_cells, playable_half, gen_rng)
	var provinces: Array[Dictionary] = province_build.get("provinces", [])

	_assign_grand_map_special_provinces(provinces, gen_rng, level_index)
	var existing_province_names: Dictionary = {}
	for i in range(provinces.size()):
		provinces[i] = _normalize_province_variation_entry(map_seed, provinces[i])
		var province_id: int = int(provinces[i].get("id", i))
		provinces[i][PROVINCE_NAME_KEY] = _generate_phoneme_province_name(map_seed, province_id, existing_province_names)

	var mountains: Array[Dictionary] = _build_mountain_bands_from_land_mask(land_mask, grid_cols, grid_rows, playable_half, gen_rng)
	return {
		"template_id": template_id,
		"provinces": provinces,
		"mountains": mountains
	}


func _expand_and_rebalance_land_mask(mask: Array, cols: int, rows: int) -> Array:
	var component: Array[Vector2i] = _largest_mask_component(mask, true, cols, rows)
	if component.size() < 12:
		return mask

	var min_r: int = rows
	var max_r: int = -1
	var min_c: int = cols
	var max_c: int = -1
	for cell in component:
		min_r = mini(min_r, cell.x)
		max_r = maxi(max_r, cell.x)
		min_c = mini(min_c, cell.y)
		max_c = maxi(max_c, cell.y)

	var edge_margin: int = maxi(1, LevelConfig.GRAND_MAP_LAND_EDGE_MARGIN_CELLS)
	var available_w: float = maxf(1.0, float(cols - edge_margin * 2))
	var available_h: float = maxf(1.0, float(rows - edge_margin * 2))
	var current_w: float = maxf(1.0, float(max_c - min_c + 1))
	var current_h: float = maxf(1.0, float(max_r - min_r + 1))
	var target_w: float = available_w * LevelConfig.GRAND_MAP_MAINLAND_TARGET_HALF_WIDTH_RATIO
	var target_h: float = available_h * LevelConfig.GRAND_MAP_MAINLAND_TARGET_HALF_HEIGHT_RATIO

	var uniform_scale: float = minf(target_w / current_w, target_h / current_h)
	uniform_scale = maxf(1.0, uniform_scale)
	var scale_x: float = uniform_scale
	var scale_y: float = uniform_scale

	var scaled_w: float = current_w * scale_x
	var scaled_h: float = current_h * scale_y
	var min_axis_ratio: float = 0.50
	if scaled_w < scaled_h * min_axis_ratio:
		scale_x *= (scaled_h * min_axis_ratio) / maxf(1.0, scaled_w)
	elif scaled_h < scaled_w * min_axis_ratio:
		scale_y *= (scaled_w * min_axis_ratio) / maxf(1.0, scaled_h)

	var expanded: Array = _resample_mask_scaled_about_component_center(mask, cols, rows, component, scale_x, scale_y)
	expanded = _smooth_land_mask(expanded, cols, rows)
	_fill_small_land_gaps(expanded, cols, rows)
	expanded = _keep_largest_land_component(expanded, cols, rows)
	_apply_edge_margin_to_mask(expanded, cols, rows, edge_margin)
	return expanded


func _resample_mask_scaled_about_component_center(mask: Array, cols: int, rows: int, component: Array[Vector2i], scale_x: float, scale_y: float) -> Array:
	var center_r: float = 0.0
	var center_c: float = 0.0
	for cell in component:
		center_r += float(cell.x)
		center_c += float(cell.y)
	center_r /= maxf(1.0, float(component.size()))
	center_c /= maxf(1.0, float(component.size()))

	var out: Array = _make_bool_grid(rows, cols, false)
	for r in range(rows):
		for c in range(cols):
			var src_r: float = center_r + (float(r) - center_r) / maxf(0.001, scale_y)
			var src_c: float = center_c + (float(c) - center_c) / maxf(0.001, scale_x)
			if _sample_mask_nearest(mask, src_r, src_c, cols, rows):
				out[r][c] = true
	return out


func _sample_mask_nearest(mask: Array, sample_r: float, sample_c: float, cols: int, rows: int) -> bool:
	var rr: int = clampi(int(round(sample_r)), 0, rows - 1)
	var cc: int = clampi(int(round(sample_c)), 0, cols - 1)
	return bool(mask[rr][cc])


func _apply_edge_margin_to_mask(mask: Array, cols: int, rows: int, edge_margin: int) -> void:
	for r in range(rows):
		for c in range(cols):
			if not bool(mask[r][c]):
				continue
			if r < edge_margin or r >= rows - edge_margin or c < edge_margin or c >= cols - edge_margin:
				mask[r][c] = false


func _build_template_land_mask(cols: int, rows: int, template_id: String, gen_rng: RandomNumberGenerator) -> Array:
	var mask: Array = _make_bool_grid(rows, cols, false)
	var footprint: Dictionary = _get_template_mainland_footprint(template_id)
	var profile: Dictionary = LevelConfig.get_grand_map_template_profile(template_id)
	var shape_variance: float = float(profile.get("shape_variance", LevelConfig.GRAND_MAP_TEMPLATE_SHAPE_VARIANCE))
	var point_variance: float = float(profile.get("point_variance", shape_variance))
	var bulge_variance: float = float(profile.get("bulge_variance", shape_variance))
	var width_frac: float = float(footprint.get("width_frac", 0.78))
	var height_frac: float = float(footprint.get("height_frac", 0.86))
	width_frac *= gen_rng.randf_range(1.0 - LevelConfig.GRAND_MAP_TEMPLATE_WIDTH_VARIANCE * maxf(0.5, shape_variance), 1.0 + LevelConfig.GRAND_MAP_TEMPLATE_WIDTH_VARIANCE * maxf(0.5, shape_variance))
	height_frac *= gen_rng.randf_range(1.0 - LevelConfig.GRAND_MAP_TEMPLATE_HEIGHT_VARIANCE * maxf(0.5, shape_variance), 1.0 + LevelConfig.GRAND_MAP_TEMPLATE_HEIGHT_VARIANCE * maxf(0.5, shape_variance))
	var placement_bias: Vector2 = _get_template_placement_bias(template_id)
	var placement_center: Vector2 = Vector2(placement_bias.x * 0.16, placement_bias.y * 0.16)
	placement_center += Vector2(
		gen_rng.randf_range(-LevelConfig.GRAND_MAP_TEMPLATE_CENTER_VARIANCE, LevelConfig.GRAND_MAP_TEMPLATE_CENTER_VARIANCE) * shape_variance,
		gen_rng.randf_range(-LevelConfig.GRAND_MAP_TEMPLATE_CENTER_VARIANCE, LevelConfig.GRAND_MAP_TEMPLATE_CENTER_VARIANCE) * shape_variance
	)
	var rotation_max: float = 12.0 + 20.0 * shape_variance
	var angle: float = deg_to_rad(gen_rng.randf_range(-rotation_max, rotation_max))
	var stretch: Vector2 = Vector2(
		gen_rng.randf_range(1.0 - 0.18 * shape_variance, 1.0 + 0.20 * shape_variance),
		gen_rng.randf_range(1.0 - 0.18 * shape_variance, 1.0 + 0.20 * shape_variance)
	)
	var shear: Vector2 = Vector2(
		gen_rng.randf_range(-LevelConfig.GRAND_MAP_TEMPLATE_SHEAR_MAX, LevelConfig.GRAND_MAP_TEMPLATE_SHEAR_MAX) * shape_variance,
		gen_rng.randf_range(-LevelConfig.GRAND_MAP_TEMPLATE_SHEAR_MAX, LevelConfig.GRAND_MAP_TEMPLATE_SHEAR_MAX) * shape_variance * 0.65
	)
	var mirror_x: bool = gen_rng.randf() < 0.5
	var edge_margin: int = maxi(1, LevelConfig.GRAND_MAP_LAND_EDGE_MARGIN_CELLS)
	var skeleton: Dictionary = _get_template_skeleton_spec(template_id)
	var strokes: Array = skeleton.get("strokes", [])
	var bulges: Array = skeleton.get("bulges", [])

	for stroke_idx in range(strokes.size()):
		var stroke: Dictionary = strokes[stroke_idx]
		var raw_points: Array = stroke.get("points", [])
		var mutated_points: Array = _mutate_template_stroke_points(raw_points, point_variance, gen_rng)
		var prepared_points: Array = _prepare_template_points(mutated_points, width_frac, height_frac, placement_center, angle, stretch, shear, mirror_x, point_variance, gen_rng)
		var start_w: float = float(stroke.get("start_w", 0.16))
		var end_w: float = float(stroke.get("end_w", start_w))
		var width_scale_a: float = gen_rng.randf_range(1.0 - 0.18 * shape_variance, 1.0 + 0.18 * shape_variance)
		var width_scale_b: float = gen_rng.randf_range(1.0 - 0.18 * shape_variance, 1.0 + 0.18 * shape_variance)
		var radius_scale: float = gen_rng.randf_range(0.92, 1.12 + 0.10 * shape_variance)
		var start_radius: Vector2 = Vector2(start_w * width_frac * absf(stretch.x) * width_scale_a, start_w * height_frac * absf(stretch.y) * width_scale_b) * radius_scale
		var end_radius: Vector2 = Vector2(end_w * width_frac * absf(stretch.x) * width_scale_b, end_w * height_frac * absf(stretch.y) * width_scale_a) * radius_scale
		_stamp_polyline_to_mask(mask, cols, rows, prepared_points, start_radius, end_radius)

	for bulge_any in bulges:
		var bulge: Dictionary = bulge_any
		var raw_center: Vector2 = bulge.get("center", Vector2.ZERO)
		var transformed_center: Vector2 = _transform_template_point(raw_center, width_frac, height_frac, placement_center, angle, stretch, shear, mirror_x)
		var raw_radius: Vector2 = bulge.get("radius", Vector2(0.18, 0.18))
		var jitter: Vector2 = bulge.get("jitter", Vector2.ZERO)
		var extra_center_var: float = LevelConfig.GRAND_MAP_TEMPLATE_BULGE_CENTER_VARIANCE * maxf(0.5, bulge_variance)
		transformed_center += Vector2(
			gen_rng.randf_range(-jitter.x - extra_center_var, jitter.x + extra_center_var),
			gen_rng.randf_range(-jitter.y - extra_center_var, jitter.y + extra_center_var)
		)
		var radius_scale_xy: Vector2 = Vector2(
			gen_rng.randf_range(1.0 - LevelConfig.GRAND_MAP_TEMPLATE_BULGE_RADIUS_VARIANCE * maxf(0.5, bulge_variance), 1.0 + LevelConfig.GRAND_MAP_TEMPLATE_BULGE_RADIUS_VARIANCE * maxf(0.5, bulge_variance)),
			gen_rng.randf_range(1.0 - LevelConfig.GRAND_MAP_TEMPLATE_BULGE_RADIUS_VARIANCE * maxf(0.5, bulge_variance), 1.0 + LevelConfig.GRAND_MAP_TEMPLATE_BULGE_RADIUS_VARIANCE * maxf(0.5, bulge_variance))
		)
		var transformed_radius: Vector2 = Vector2(raw_radius.x * width_frac * absf(stretch.x) * radius_scale_xy.x, raw_radius.y * height_frac * absf(stretch.y) * radius_scale_xy.y)
		_fill_mask_ellipse_normalized(mask, cols, rows, transformed_center, transformed_radius, angle * 0.4)

	for r in range(rows):
		for c in range(cols):
			if not bool(mask[r][c]):
				continue
			if r < edge_margin or r >= rows - edge_margin or c < edge_margin or c >= cols - edge_margin:
				mask[r][c] = false

	# Guarantee a single connected mainland; unlike the old pipeline, this shape is connected by construction.
	mask = _keep_largest_land_component(mask, cols, rows)
	return mask


func _get_template_skeleton_spec(template_id: String) -> Dictionary:
	match template_id:
		LevelConfig.GRAND_MAP_TEMPLATE_NORTH_AMERICA:
			return {
				"strokes": [
					{"points": [Vector2(-0.78, -0.76), Vector2(-0.60, -0.50), Vector2(-0.42, -0.18), Vector2(-0.28, 0.18), Vector2(-0.12, 0.70)], "start_w": 0.26, "end_w": 0.12},
					{"points": [Vector2(-0.62, -0.64), Vector2(-0.22, -0.68), Vector2(0.10, -0.54)], "start_w": 0.18, "end_w": 0.16},
					{"points": [Vector2(-0.40, -0.16), Vector2(-0.06, -0.06), Vector2(0.20, 0.08)], "start_w": 0.16, "end_w": 0.09}
				],
				"bulges": [
					{"center": Vector2(-0.44, -0.22), "radius": Vector2(0.22, 0.18), "jitter": Vector2(0.03, 0.03)},
					{"center": Vector2(-0.20, 0.30), "radius": Vector2(0.16, 0.22), "jitter": Vector2(0.03, 0.04)}
				]
			}
		LevelConfig.GRAND_MAP_TEMPLATE_SOUTH_AMERICA:
			return {
				"strokes": [
					{"points": [Vector2(-0.16, -0.82), Vector2(-0.08, -0.48), Vector2(0.04, -0.10), Vector2(0.10, 0.28), Vector2(0.02, 0.62), Vector2(-0.06, 0.90)], "start_w": 0.20, "end_w": 0.09},
					{"points": [Vector2(-0.34, -0.62), Vector2(-0.18, -0.36), Vector2(-0.02, -0.18)], "start_w": 0.12, "end_w": 0.10}
				],
				"bulges": [
					{"center": Vector2(-0.06, -0.50), "radius": Vector2(0.18, 0.14), "jitter": Vector2(0.02, 0.02)},
					{"center": Vector2(0.02, 0.08), "radius": Vector2(0.16, 0.20), "jitter": Vector2(0.02, 0.03)}
				]
			}
		LevelConfig.GRAND_MAP_TEMPLATE_EUROPE:
			return {
				"strokes": [
					{"points": [Vector2(-0.82, -0.36), Vector2(-0.52, -0.34), Vector2(-0.18, -0.26), Vector2(0.14, -0.16), Vector2(0.46, -0.04), Vector2(0.76, 0.06)], "start_w": 0.18, "end_w": 0.12},
					{"points": [Vector2(-0.26, -0.24), Vector2(-0.08, 0.00), Vector2(0.04, 0.26)], "start_w": 0.12, "end_w": 0.09},
					{"points": [Vector2(0.18, -0.14), Vector2(0.42, 0.04), Vector2(0.66, 0.22)], "start_w": 0.10, "end_w": 0.07}
				],
				"bulges": [
					{"center": Vector2(-0.34, -0.28), "radius": Vector2(0.16, 0.12), "jitter": Vector2(0.03, 0.02)},
					{"center": Vector2(0.08, -0.14), "radius": Vector2(0.18, 0.12), "jitter": Vector2(0.03, 0.02)}
				]
			}
		LevelConfig.GRAND_MAP_TEMPLATE_AFRICA:
			return {
				"strokes": [
					{"points": [Vector2(-0.02, -0.88), Vector2(-0.04, -0.52), Vector2(-0.02, -0.16), Vector2(0.00, 0.18), Vector2(0.06, 0.56), Vector2(0.02, 0.90)], "start_w": 0.14, "end_w": 0.10},
					{"points": [Vector2(0.00, -0.14), Vector2(0.26, 0.00), Vector2(0.46, 0.12)], "start_w": 0.10, "end_w": 0.06}
				],
				"bulges": [
					{"center": Vector2(-0.02, -0.04), "radius": Vector2(0.22, 0.24), "jitter": Vector2(0.03, 0.03)},
					{"center": Vector2(0.04, 0.44), "radius": Vector2(0.18, 0.22), "jitter": Vector2(0.03, 0.03)}
				]
			}
		LevelConfig.GRAND_MAP_TEMPLATE_ASIA:
			return {
				"strokes": [
					{"points": [Vector2(-0.92, -0.30), Vector2(-0.58, -0.32), Vector2(-0.24, -0.28), Vector2(0.12, -0.22), Vector2(0.48, -0.12), Vector2(0.88, -0.02)], "start_w": 0.16, "end_w": 0.16},
					{"points": [Vector2(0.18, -0.18), Vector2(0.40, 0.06), Vector2(0.58, 0.28)], "start_w": 0.12, "end_w": 0.07},
					{"points": [Vector2(0.02, -0.18), Vector2(0.08, 0.10), Vector2(0.16, 0.42)], "start_w": 0.10, "end_w": 0.06}
				],
				"bulges": [
					{"center": Vector2(-0.44, -0.30), "radius": Vector2(0.18, 0.12), "jitter": Vector2(0.03, 0.02)},
					{"center": Vector2(0.10, -0.20), "radius": Vector2(0.26, 0.16), "jitter": Vector2(0.03, 0.02)},
					{"center": Vector2(0.54, -0.06), "radius": Vector2(0.16, 0.12), "jitter": Vector2(0.02, 0.02)}
				]
			}
		LevelConfig.GRAND_MAP_TEMPLATE_AUSTRALIA:
			return {
				"strokes": [
					{"points": [Vector2(-0.76, -0.14), Vector2(-0.34, -0.22), Vector2(0.08, -0.18), Vector2(0.42, -0.02), Vector2(0.70, 0.10)], "start_w": 0.18, "end_w": 0.14},
					{"points": [Vector2(-0.24, 0.02), Vector2(0.00, 0.18), Vector2(0.24, 0.30)], "start_w": 0.12, "end_w": 0.09}
				],
				"bulges": [
					{"center": Vector2(-0.26, -0.08), "radius": Vector2(0.18, 0.14), "jitter": Vector2(0.02, 0.02)},
					{"center": Vector2(0.18, -0.02), "radius": Vector2(0.20, 0.14), "jitter": Vector2(0.02, 0.02)}
				]
			}
		LevelConfig.GRAND_MAP_TEMPLATE_ANTARCTICA:
			return {
				"strokes": [
					{"points": [Vector2(-0.96, 0.02), Vector2(-0.58, -0.02), Vector2(-0.18, -0.06), Vector2(0.22, -0.04), Vector2(0.62, 0.00), Vector2(0.94, 0.06)], "start_w": 0.10, "end_w": 0.09},
					{"points": [Vector2(-0.36, -0.04), Vector2(-0.28, 0.18)], "start_w": 0.07, "end_w": 0.04},
					{"points": [Vector2(0.18, -0.04), Vector2(0.26, 0.16)], "start_w": 0.07, "end_w": 0.04}
				],
				"bulges": [
					{"center": Vector2(-0.46, 0.00), "radius": Vector2(0.16, 0.08), "jitter": Vector2(0.02, 0.02)},
					{"center": Vector2(0.04, -0.02), "radius": Vector2(0.24, 0.10), "jitter": Vector2(0.02, 0.02)},
					{"center": Vector2(0.54, 0.04), "radius": Vector2(0.16, 0.08), "jitter": Vector2(0.02, 0.02)}
				]
			}
		_:
			return {
				"strokes": [
					{"points": [Vector2(-0.72, -0.24), Vector2(-0.20, -0.10), Vector2(0.28, 0.12), Vector2(0.68, 0.30)], "start_w": 0.18, "end_w": 0.12}
				],
				"bulges": [
					{"center": Vector2(-0.12, -0.04), "radius": Vector2(0.20, 0.16), "jitter": Vector2(0.03, 0.03)}
				]
			}


func _mutate_template_stroke_points(raw_points: Array, point_variance: float, gen_rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	if raw_points.is_empty():
		return out
	var bend_max: float = LevelConfig.GRAND_MAP_TEMPLATE_SEGMENT_BEND_MAX * maxf(0.5, point_variance)
	for idx in range(raw_points.size() - 1):
		var p0: Vector2 = raw_points[idx]
		var p1: Vector2 = raw_points[idx + 1]
		if idx == 0:
			out.append(p0)
		var seg: Vector2 = p1 - p0
		var seg_len: float = seg.length()
		if seg_len > 0.16 and gen_rng.randf() < (0.55 + point_variance * 0.55):
			var mid: Vector2 = p0.lerp(p1, gen_rng.randf_range(0.38, 0.62))
			var normal: Vector2 = Vector2(-seg.y, seg.x).normalized()
			var bend: float = gen_rng.randf_range(-bend_max, bend_max)
			mid += normal * bend
			out.append(mid)
		out.append(p1)
	return out


func _prepare_template_points(raw_points: Array, width_frac: float, height_frac: float, placement_center: Vector2, angle: float, stretch: Vector2, shear: Vector2, mirror_x: bool, point_variance: float, gen_rng: RandomNumberGenerator) -> Array:
	var points: Array = []
	var point_jitter: float = LevelConfig.GRAND_MAP_TEMPLATE_POINT_JITTER_BASE * maxf(0.5, point_variance)
	for idx in range(raw_points.size()):
		var raw_point: Vector2 = raw_points[idx]
		var point: Vector2 = raw_point
		var jitter_scale: float = 1.0 if (idx > 0 and idx < raw_points.size() - 1) else 0.55
		point += Vector2(gen_rng.randf_range(-point_jitter, point_jitter), gen_rng.randf_range(-point_jitter, point_jitter)) * jitter_scale
		points.append(_transform_template_point(point, width_frac, height_frac, placement_center, angle, stretch, shear, mirror_x))
	return points


func _transform_template_point(local_point: Vector2, width_frac: float, height_frac: float, placement_center: Vector2, angle: float, stretch: Vector2, shear: Vector2, mirror_x: bool) -> Vector2:
	var p: Vector2 = local_point
	if mirror_x:
		p.x = -p.x
	p = Vector2(p.x + p.y * shear.x, p.y + p.x * shear.y)
	p = Vector2(p.x * stretch.x, p.y * stretch.y)
	p = p.rotated(angle)
	return Vector2(placement_center.x + p.x * width_frac, placement_center.y + p.y * height_frac)


func _stamp_polyline_to_mask(mask: Array, cols: int, rows: int, points: Array, start_radius: Vector2, end_radius: Vector2) -> void:
	if points.size() < 2:
		return
	var segment_count: int = maxi(1, points.size() - 1)
	for seg_idx in range(segment_count):
		var p0: Vector2 = points[seg_idx]
		var p1: Vector2 = points[seg_idx + 1]
		var seg_len: float = p0.distance_to(p1)
		var steps: int = maxi(4, int(ceil(seg_len * float(maxi(cols, rows)) * 1.6)))
		for step in range(steps + 1):
			var t_local: float = float(step) / float(steps)
			var t_global: float = (float(seg_idx) + t_local) / float(segment_count)
			var center: Vector2 = p0.lerp(p1, t_local)
			var radius: Vector2 = start_radius.lerp(end_radius, t_global)
			_fill_mask_ellipse_normalized(mask, cols, rows, center, radius, 0.0)


func _fill_mask_ellipse_normalized(mask: Array, cols: int, rows: int, center: Vector2, radius: Vector2, rotation: float) -> void:
	var cos_r: float = cos(rotation)
	var sin_r: float = sin(rotation)
	for rr in range(rows):
		for cc in range(cols):
			var pos: Vector2 = _grid_cell_to_normalized(rr, cc, cols, rows)
			var dx: float = pos.x - center.x
			var dy: float = pos.y - center.y
			var rx: float = dx * cos_r - dy * sin_r
			var ry: float = dx * sin_r + dy * cos_r
			var nx: float = rx / maxf(0.001, radius.x)
			var ny: float = ry / maxf(0.001, radius.y)
			if nx * nx + ny * ny <= 1.0:
				mask[rr][cc] = true


func _apply_light_template_bite(mask: Array, cols: int, rows: int, template_id: String, gen_rng: RandomNumberGenerator) -> void:
	var coastal: Array[Vector2i] = _collect_coastal_cells(mask, cols, rows)
	if coastal.is_empty():
		return
	var anchor: Vector2i = _pick_template_coastal_anchor(coastal, cols, rows, template_id, gen_rng)
	var anchor_pos: Vector2 = _grid_cell_to_normalized(anchor.x, anchor.y, cols, rows)
	var inward: Vector2 = (-anchor_pos).normalized()
	if inward.length() < 0.001:
		inward = Vector2.RIGHT
	var tangent: Vector2 = Vector2(-inward.y, inward.x)
	var depth: float = gen_rng.randf_range(0.07, 0.13)
	var radius_x: float = gen_rng.randf_range(0.10, 0.16)
	var radius_y: float = gen_rng.randf_range(0.12, 0.20)
	var offset: float = gen_rng.randf_range(-0.03, 0.03)
	var center: Vector2 = anchor_pos + inward * depth + tangent * offset
	_carve_mask_ellipse_normalized(mask, cols, rows, center, Vector2(radius_x, radius_y), gen_rng.randf_range(-0.4, 0.4))


func _normalize_template_lobes(raw_lobes: Array, aspect_bias: Vector2, center_bias: Vector2) -> Array:
	var lobes: Array = []
	for raw_lobe in raw_lobes:
		var center: Vector2 = raw_lobe.get("center", Vector2.ZERO)
		var radius: Vector2 = raw_lobe.get("radius", Vector2.ONE * 0.25)
		var weight: float = float(raw_lobe.get("weight", 1.0))
		lobes.append({
			"center": Vector2(center.x * aspect_bias.x + center_bias.x, center.y * aspect_bias.y + center_bias.y),
			"radius": Vector2(radius.x * aspect_bias.x, radius.y * aspect_bias.y),
			"weight": weight
		})
	return lobes


func _get_continent_template_lobes(template_id: String) -> Array[Dictionary]:
	match template_id:
		LevelConfig.GRAND_MAP_TEMPLATE_NORTH_AMERICA:
			return [
				{"center": Vector2(-0.44, -0.56), "radius": Vector2(0.30, 0.22), "weight": 1.04},
				{"center": Vector2(-0.26, -0.20), "radius": Vector2(0.34, 0.26), "weight": 1.18},
				{"center": Vector2(-0.18, 0.20), "radius": Vector2(0.28, 0.36), "weight": 0.98},
				{"center": Vector2(-0.04, 0.60), "radius": Vector2(0.14, 0.24), "weight": 0.76},
				{"center": Vector2(0.08, -0.02), "radius": Vector2(0.14, 0.16), "weight": 0.64}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_SOUTH_AMERICA:
			return [
				{"center": Vector2(-0.06, -0.58), "radius": Vector2(0.22, 0.18), "weight": 1.14},
				{"center": Vector2(-0.02, -0.12), "radius": Vector2(0.22, 0.28), "weight": 1.06},
				{"center": Vector2(0.02, 0.32), "radius": Vector2(0.18, 0.34), "weight": 0.98},
				{"center": Vector2(0.08, 0.76), "radius": Vector2(0.12, 0.18), "weight": 0.72}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_EUROPE:
			return [
				{"center": Vector2(-0.28, -0.26), "radius": Vector2(0.16, 0.12), "weight": 1.02},
				{"center": Vector2(-0.06, -0.18), "radius": Vector2(0.20, 0.14), "weight": 1.08},
				{"center": Vector2(0.18, -0.10), "radius": Vector2(0.20, 0.14), "weight": 0.98},
				{"center": Vector2(-0.18, 0.06), "radius": Vector2(0.14, 0.12), "weight": 0.84},
				{"center": Vector2(0.08, 0.16), "radius": Vector2(0.16, 0.14), "weight": 0.78},
				{"center": Vector2(0.28, 0.24), "radius": Vector2(0.12, 0.10), "weight": 0.64}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_AFRICA:
			return [
				{"center": Vector2(-0.02, -0.46), "radius": Vector2(0.18, 0.16), "weight": 0.96},
				{"center": Vector2(-0.04, -0.06), "radius": Vector2(0.26, 0.28), "weight": 1.14},
				{"center": Vector2(0.02, 0.34), "radius": Vector2(0.22, 0.32), "weight": 1.04},
				{"center": Vector2(0.26, -0.06), "radius": Vector2(0.10, 0.12), "weight": 0.70}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_ASIA:
			return [
				{"center": Vector2(-0.54, -0.18), "radius": Vector2(0.26, 0.18), "weight": 0.84},
				{"center": Vector2(-0.22, -0.14), "radius": Vector2(0.32, 0.20), "weight": 0.96},
				{"center": Vector2(0.12, -0.08), "radius": Vector2(0.38, 0.22), "weight": 1.12},
				{"center": Vector2(0.44, 0.02), "radius": Vector2(0.26, 0.20), "weight": 0.96},
				{"center": Vector2(0.24, 0.34), "radius": Vector2(0.18, 0.18), "weight": 0.70}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_AUSTRALIA:
			return [
				{"center": Vector2(-0.18, -0.06), "radius": Vector2(0.22, 0.16), "weight": 1.00},
				{"center": Vector2(0.10, -0.04), "radius": Vector2(0.20, 0.16), "weight": 1.04},
				{"center": Vector2(0.02, 0.18), "radius": Vector2(0.22, 0.14), "weight": 0.92},
				{"center": Vector2(0.28, 0.12), "radius": Vector2(0.10, 0.10), "weight": 0.58}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_ANTARCTICA:
			return [
				{"center": Vector2(-0.62, 0.22), "radius": Vector2(0.28, 0.14), "weight": 0.82},
				{"center": Vector2(-0.22, 0.24), "radius": Vector2(0.34, 0.16), "weight": 1.00},
				{"center": Vector2(0.18, 0.24), "radius": Vector2(0.36, 0.16), "weight": 1.00},
				{"center": Vector2(0.56, 0.22), "radius": Vector2(0.24, 0.12), "weight": 0.72}
			]
		_:
			return [
				{"center": Vector2(-0.10, -0.18), "radius": Vector2(0.30, 0.24), "weight": 1.0},
				{"center": Vector2(0.12, 0.12), "radius": Vector2(0.28, 0.24), "weight": 1.0}
			]


func _score_template_land_point(p: Vector2, lobes: Array) -> float:
	var total: float = 0.0
	for lobe in lobes:
		var center: Vector2 = lobe.get("center", Vector2.ZERO)
		var radius: Vector2 = lobe.get("radius", Vector2.ONE * 0.25)
		var weight: float = float(lobe.get("weight", 1.0))
		var dx: float = (p.x - center.x) / maxf(0.001, radius.x)
		var dy: float = (p.y - center.y) / maxf(0.001, radius.y)
		var dist: float = sqrt(dx * dx + dy * dy)
		var influence: float = maxf(0.0, 1.0 - dist)
		total += influence * weight
	return total

func _apply_template_identity_carves(mask: Array, cols: int, rows: int, template_id: String, gen_rng: RandomNumberGenerator) -> void:
	var specs: Array = _get_template_identity_carve_specs(template_id)
	for spec in specs:
		var center: Vector2 = spec.get("center", Vector2.ZERO)
		var radius: Vector2 = spec.get("radius", Vector2(0.15, 0.12))
		var jitter: Vector2 = spec.get("jitter", Vector2.ZERO)
		var rotation_deg: float = float(spec.get("rotation_deg", 0.0))
		var center_jitter: Vector2 = Vector2(
			gen_rng.randf_range(-jitter.x, jitter.x),
			gen_rng.randf_range(-jitter.y, jitter.y)
		)
		var radius_jitter: float = gen_rng.randf_range(0.92, 1.12)
		_carve_mask_ellipse_normalized(
			mask,
			cols,
			rows,
			center + center_jitter,
			radius * radius_jitter,
			deg_to_rad(rotation_deg + gen_rng.randf_range(-8.0, 8.0))
		)


func _get_template_identity_carve_specs(template_id: String) -> Array:
	match template_id:
		LevelConfig.GRAND_MAP_TEMPLATE_NORTH_AMERICA:
			return [
				{"center": Vector2(0.34, -0.02), "radius": Vector2(0.16, 0.20), "rotation_deg": 8.0, "jitter": Vector2(0.05, 0.04)},
				{"center": Vector2(0.06, 0.52), "radius": Vector2(0.10, 0.16), "rotation_deg": -12.0, "jitter": Vector2(0.04, 0.05)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_SOUTH_AMERICA:
			return [
				{"center": Vector2(-0.28, 0.30), "radius": Vector2(0.11, 0.20), "rotation_deg": -10.0, "jitter": Vector2(0.04, 0.04)},
				{"center": Vector2(0.16, 0.70), "radius": Vector2(0.10, 0.12), "rotation_deg": 6.0, "jitter": Vector2(0.03, 0.04)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_EUROPE:
			return [
				{"center": Vector2(-0.26, 0.08), "radius": Vector2(0.12, 0.12), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.04)},
				{"center": Vector2(0.28, -0.02), "radius": Vector2(0.14, 0.12), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.04)},
				{"center": Vector2(0.04, 0.28), "radius": Vector2(0.12, 0.10), "rotation_deg": 14.0, "jitter": Vector2(0.03, 0.03)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_AFRICA:
			return [
				{"center": Vector2(-0.28, -0.08), "radius": Vector2(0.14, 0.18), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.04)},
				{"center": Vector2(0.22, 0.00), "radius": Vector2(0.10, 0.12), "rotation_deg": 0.0, "jitter": Vector2(0.03, 0.03)},
				{"center": Vector2(0.00, -0.62), "radius": Vector2(0.16, 0.10), "rotation_deg": 0.0, "jitter": Vector2(0.05, 0.03)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_ASIA:
			return [
				{"center": Vector2(-0.44, 0.06), "radius": Vector2(0.16, 0.14), "rotation_deg": 0.0, "jitter": Vector2(0.05, 0.04)},
				{"center": Vector2(0.18, 0.28), "radius": Vector2(0.18, 0.14), "rotation_deg": -10.0, "jitter": Vector2(0.05, 0.04)},
				{"center": Vector2(0.48, -0.06), "radius": Vector2(0.12, 0.12), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.04)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_AUSTRALIA:
			return [
				{"center": Vector2(-0.18, -0.18), "radius": Vector2(0.12, 0.12), "rotation_deg": 0.0, "jitter": Vector2(0.03, 0.03)},
				{"center": Vector2(0.26, 0.10), "radius": Vector2(0.12, 0.10), "rotation_deg": 0.0, "jitter": Vector2(0.03, 0.03)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_ANTARCTICA:
			return [
				{"center": Vector2(-0.44, -0.02), "radius": Vector2(0.14, 0.10), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.03)},
				{"center": Vector2(0.00, -0.06), "radius": Vector2(0.16, 0.12), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.03)},
				{"center": Vector2(0.42, -0.02), "radius": Vector2(0.14, 0.10), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.03)}
			]
		_:
			return [
				{"center": Vector2(0.24, 0.10), "radius": Vector2(0.14, 0.14), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.04)}
			]


func _carve_mask_ellipse_normalized(mask: Array, cols: int, rows: int, center: Vector2, radius: Vector2, rotation: float) -> void:
	var cos_r: float = cos(rotation)
	var sin_r: float = sin(rotation)
	for rr in range(rows):
		for cc in range(cols):
			if not bool(mask[rr][cc]):
				continue
			var pos: Vector2 = _grid_cell_to_normalized(rr, cc, cols, rows)
			var dx: float = pos.x - center.x
			var dy: float = pos.y - center.y
			var rx: float = dx * cos_r - dy * sin_r
			var ry: float = dx * sin_r + dy * cos_r
			var nx: float = rx / maxf(0.001, radius.x)
			var ny: float = ry / maxf(0.001, radius.y)
			if nx * nx + ny * ny <= 1.0:
				mask[rr][cc] = false


func _measure_round_blob_score(mask: Array, cols: int, rows: int) -> float:
	var cells: Array[Vector2i] = _largest_mask_component(mask, true, cols, rows)
	if cells.is_empty():
		return INF
	var min_r: int = rows
	var max_r: int = -1
	var min_c: int = cols
	var max_c: int = -1
	var sum_r: float = 0.0
	var sum_c: float = 0.0
	for cell in cells:
		min_r = mini(min_r, cell.x)
		max_r = maxi(max_r, cell.x)
		min_c = mini(min_c, cell.y)
		max_c = maxi(max_c, cell.y)
		sum_r += float(cell.x)
		sum_c += float(cell.y)
	var area: float = float(cells.size())
	var bbox_w: float = float(maxi(1, max_c - min_c + 1))
	var bbox_h: float = float(maxi(1, max_r - min_r + 1))
	var bbox_area: float = bbox_w * bbox_h
	var fullness: float = area / maxf(1.0, bbox_area)
	var centroid_r: float = sum_r / maxf(1.0, area)
	var centroid_c: float = sum_c / maxf(1.0, area)
	var radial_sum: float = 0.0
	var radial_sq_sum: float = 0.0
	var left_count: int = 0
	var right_count: int = 0
	var top_count: int = 0
	var bottom_count: int = 0
	for cell2 in cells:
		var dr: float = float(cell2.x) - centroid_r
		var dc: float = float(cell2.y) - centroid_c
		var dist: float = sqrt(dr * dr + dc * dc)
		radial_sum += dist
		radial_sq_sum += dist * dist
		if float(cell2.y) < centroid_c:
			left_count += 1
		else:
			right_count += 1
		if float(cell2.x) < centroid_r:
			top_count += 1
		else:
			bottom_count += 1
	var radial_mean: float = radial_sum / maxf(1.0, area)
	var variance: float = radial_sq_sum / maxf(1.0, area) - radial_mean * radial_mean
	variance = maxf(0.0, variance)
	var radial_cv: float = sqrt(variance) / maxf(0.001, radial_mean)
	var aspect: float = bbox_w / maxf(1.0, bbox_h)
	var aspect_penalty: float = 1.0 - clampf(absf(log(aspect)), 0.0, 1.0)
	var asymmetry: float = absf(float(left_count - right_count)) / maxf(1.0, area) + absf(float(top_count - bottom_count)) / maxf(1.0, area)
	return fullness * 1.55 + aspect_penalty * 0.80 + maxf(0.0, 0.24 - radial_cv) * 2.6 + maxf(0.0, 0.22 - asymmetry) * 1.9


func _is_round_mainland_blob(mask: Array, cols: int, rows: int) -> bool:
	var cells: Array[Vector2i] = _largest_mask_component(mask, true, cols, rows)
	if cells.size() < 24:
		return true
	var min_r: int = rows
	var max_r: int = -1
	var min_c: int = cols
	var max_c: int = -1
	for cell in cells:
		min_r = mini(min_r, cell.x)
		max_r = maxi(max_r, cell.x)
		min_c = mini(min_c, cell.y)
		max_c = maxi(max_c, cell.y)
	var bbox_w: float = float(maxi(1, max_c - min_c + 1))
	var bbox_h: float = float(maxi(1, max_r - min_r + 1))
	var bbox_area: float = bbox_w * bbox_h
	var fullness: float = float(cells.size()) / maxf(1.0, bbox_area)
	var score: float = _measure_round_blob_score(mask, cols, rows)
	return fullness > 0.60 and score > 1.95


func _template_directional_bias(template_id: String, p: Vector2) -> float:
	match template_id:
		LevelConfig.GRAND_MAP_TEMPLATE_NORTH_AMERICA:
			return maxf(0.0, -p.x - 0.02) * 0.20 + maxf(0.0, -p.y - 0.06) * 0.10 - maxf(0.0, p.x - 0.30) * 0.10
		LevelConfig.GRAND_MAP_TEMPLATE_SOUTH_AMERICA:
			return maxf(0.0, p.y - 0.06) * 0.18 - absf(p.x) * 0.03
		LevelConfig.GRAND_MAP_TEMPLATE_EUROPE:
			return maxf(0.0, -p.y - 0.04) * 0.14 + maxf(0.0, p.x - 0.08) * 0.06
		LevelConfig.GRAND_MAP_TEMPLATE_AFRICA:
			return maxf(0.0, 0.16 - absf(p.x)) * 0.12 + maxf(0.0, p.y - 0.12) * 0.06
		LevelConfig.GRAND_MAP_TEMPLATE_ASIA:
			return maxf(0.0, p.x - 0.02) * 0.18 + maxf(0.0, -absf(p.y + 0.02) + 0.26) * 0.08
		LevelConfig.GRAND_MAP_TEMPLATE_AUSTRALIA:
			return maxf(0.0, p.y - 0.02) * 0.08 + maxf(0.0, 0.20 - absf(p.x)) * 0.04
		LevelConfig.GRAND_MAP_TEMPLATE_ANTARCTICA:
			return maxf(0.0, p.y + 0.08) * 0.18 - absf(p.x) * 0.01
		_:
			return 0.0


func _carve_template_bays(mask: Array, cols: int, rows: int, template_id: String, gen_rng: RandomNumberGenerator) -> void:
	var profile: Dictionary = LevelConfig.get_grand_map_template_profile(template_id)
	var carve_count: int = gen_rng.randi_range(LevelConfig.GRAND_MAP_COASTAL_CARVE_COUNT_MIN, LevelConfig.GRAND_MAP_COASTAL_CARVE_COUNT_MAX) + int(profile.get("bay_count_bonus", 0))
	for carve_idx in range(carve_count):
		var coastal: Array[Vector2i] = _collect_coastal_cells(mask, cols, rows)
		if coastal.is_empty():
			break
		var anchor: Vector2i = _pick_template_coastal_anchor(coastal, cols, rows, template_id, gen_rng)
		var anchor_pos: Vector2 = _grid_cell_to_normalized(anchor.x, anchor.y, cols, rows)
		var inward: Vector2 = (-anchor_pos).normalized()
		if inward.length() < 0.001:
			inward = Vector2.RIGHT
		var radius_x: float = gen_rng.randf_range(LevelConfig.GRAND_MAP_COASTAL_CARVE_RADIUS_MIN, LevelConfig.GRAND_MAP_COASTAL_CARVE_RADIUS_MAX)
		var radius_y: float = gen_rng.randf_range(LevelConfig.GRAND_MAP_COASTAL_CARVE_RADIUS_MIN, LevelConfig.GRAND_MAP_COASTAL_CARVE_RADIUS_MAX)
		var depth: float = gen_rng.randf_range(LevelConfig.GRAND_MAP_COASTAL_CARVE_DEPTH_MIN, LevelConfig.GRAND_MAP_COASTAL_CARVE_DEPTH_MAX)
		var carve_center: Vector2 = anchor_pos + inward * depth
		for rr in range(rows):
			for cc in range(cols):
				if not bool(mask[rr][cc]):
					continue
				var pos: Vector2 = _grid_cell_to_normalized(rr, cc, cols, rows)
				var dx: float = (pos.x - carve_center.x) / maxf(0.001, radius_x)
				var dy: float = (pos.y - carve_center.y) / maxf(0.001, radius_y)
				if dx * dx + dy * dy <= 1.0:
					mask[rr][cc] = false

	var peninsula_count: int = gen_rng.randi_range(LevelConfig.GRAND_MAP_PENINSULA_CARVE_COUNT_MIN, LevelConfig.GRAND_MAP_PENINSULA_CARVE_COUNT_MAX)
	for peninsula_idx in range(peninsula_count):
		var coastal2: Array[Vector2i] = _collect_coastal_cells(mask, cols, rows)
		if coastal2.is_empty():
			break
		var anchor2: Vector2i = _pick_template_coastal_anchor(coastal2, cols, rows, template_id, gen_rng)
		var anchor2_pos: Vector2 = _grid_cell_to_normalized(anchor2.x, anchor2.y, cols, rows)
		var inward2: Vector2 = (-anchor2_pos).normalized()
		if inward2.length() < 0.001:
			inward2 = Vector2.UP
		var tangent: Vector2 = Vector2(-inward2.y, inward2.x)
		var length_norm: float = gen_rng.randf_range(0.22, 0.34)
		var width_norm: float = gen_rng.randf_range(0.06, 0.11)
		var cut_center: Vector2 = anchor2_pos + inward2 * (length_norm * 0.45)
		for rr in range(rows):
			for cc in range(cols):
				if not bool(mask[rr][cc]):
					continue
				var pos2: Vector2 = _grid_cell_to_normalized(rr, cc, cols, rows)
				var rel: Vector2 = pos2 - cut_center
				var along: float = rel.dot(inward2) / maxf(0.001, length_norm)
				var across: float = rel.dot(tangent) / maxf(0.001, width_norm)
				if along * along + across * across <= 1.0:
					mask[rr][cc] = false


func _pick_template_coastal_anchor(coastal: Array[Vector2i], cols: int, rows: int, template_id: String, gen_rng: RandomNumberGenerator) -> Vector2i:
	if coastal.is_empty():
		return Vector2i(rows / 2, cols / 2)
	var best: Vector2i = coastal[gen_rng.randi_range(0, coastal.size() - 1)]
	var best_score: float = -INF
	for cell in coastal:
		var p: Vector2 = _grid_cell_to_normalized(cell.x, cell.y, cols, rows)
		var score: float = gen_rng.randf() * 0.4
		match template_id:
			LevelConfig.GRAND_MAP_TEMPLATE_NORTH_AMERICA:
				score += maxf(0.0, -p.x) * 0.9 + maxf(0.0, -p.y) * 0.4
			LevelConfig.GRAND_MAP_TEMPLATE_SOUTH_AMERICA:
				score += maxf(0.0, p.y) * 1.0 + absf(p.x) * 0.15
			LevelConfig.GRAND_MAP_TEMPLATE_EUROPE:
				score += maxf(0.0, -p.y) * 0.6 + absf(p.x) * 0.35
			LevelConfig.GRAND_MAP_TEMPLATE_AFRICA:
				score += maxf(0.0, p.y) * 0.4 + absf(p.x) * 0.20
			LevelConfig.GRAND_MAP_TEMPLATE_ASIA:
				score += maxf(0.0, p.x) * 0.9 + maxf(0.0, -p.y) * 0.25
			LevelConfig.GRAND_MAP_TEMPLATE_AUSTRALIA:
				score += maxf(0.0, p.y) * 0.25 + absf(p.x) * 0.20
			LevelConfig.GRAND_MAP_TEMPLATE_ANTARCTICA:
				score += maxf(0.0, p.y) * 0.9 + absf(p.x) * 0.08
			_:
				score += absf(p.x) * 0.2
		if score > best_score:
			best_score = score
			best = cell
	return best


func _add_template_islands(mask: Array, cols: int, rows: int, template_id: String, gen_rng: RandomNumberGenerator) -> void:
	var profile: Dictionary = LevelConfig.get_grand_map_template_profile(template_id)
	var island_bonus: int = int(profile.get("island_bonus", 0))
	var island_count: int = gen_rng.randi_range(LevelConfig.GRAND_MAP_ISLAND_COUNT_MIN, LevelConfig.GRAND_MAP_ISLAND_COUNT_MAX) + island_bonus
	if island_count <= 0:
		return
	var coastal: Array[Vector2i] = _collect_coastal_cells(mask, cols, rows)
	if coastal.is_empty():
		return
	for island_idx in range(island_count):
		var anchor: Vector2i = coastal[gen_rng.randi_range(0, coastal.size() - 1)]
		var anchor_pos: Vector2 = _grid_cell_to_normalized(anchor.x, anchor.y, cols, rows)
		var outward: Vector2 = anchor_pos.normalized()
		if outward.length() < 0.001:
			outward = Vector2.RIGHT.rotated(gen_rng.randf_range(0.0, TAU))
		var distance_norm: float = gen_rng.randf_range(LevelConfig.GRAND_MAP_ISLAND_DISTANCE_MIN, LevelConfig.GRAND_MAP_ISLAND_DISTANCE_MAX)
		var center: Vector2 = anchor_pos + outward * distance_norm
		var scale_norm: float = gen_rng.randf_range(LevelConfig.GRAND_MAP_ISLAND_SCALE_MIN, LevelConfig.GRAND_MAP_ISLAND_SCALE_MAX)
		var scale_x: float = scale_norm * gen_rng.randf_range(0.8, 1.3)
		var scale_y: float = scale_norm * gen_rng.randf_range(0.7, 1.2)
		var cells_added: int = 0
		for rr in range(rows):
			for cc in range(cols):
				var pos: Vector2 = _grid_cell_to_normalized(rr, cc, cols, rows)
				var dx: float = (pos.x - center.x) / maxf(0.001, scale_x)
				var dy: float = (pos.y - center.y) / maxf(0.001, scale_y)
				if dx * dx + dy * dy <= 1.0:
					if not bool(mask[rr][cc]):
						mask[rr][cc] = true
						cells_added += 1
		if cells_added < LevelConfig.GRAND_MAP_ISLAND_MIN_CELLS:
			for rr in range(rows):
				for cc in range(cols):
					var pos2: Vector2 = _grid_cell_to_normalized(rr, cc, cols, rows)
					var dx2: float = (pos2.x - center.x) / maxf(0.001, scale_x * 1.2)
					var dy2: float = (pos2.y - center.y) / maxf(0.001, scale_y * 1.2)
					if dx2 * dx2 + dy2 * dy2 <= 1.0:
						mask[rr][cc] = true


func _prune_land_components(mask: Array, cols: int, rows: int, keep_components: int, min_secondary_cells: int) -> Array:
	var components: Array = _collect_mask_components(mask, true, cols, rows)
	if components.is_empty():
		return mask

	for i in range(components.size()):
		var best_idx: int = i
		var best_size: int = int(components[i].size())
		for j in range(i + 1, components.size()):
			var cand_size: int = int(components[j].size())
			if cand_size > best_size:
				best_size = cand_size
				best_idx = j
		if best_idx != i:
			var tmp = components[i]
			components[i] = components[best_idx]
			components[best_idx] = tmp

	var out: Array = _make_bool_grid(rows, cols, false)
	for i in range(components.size()):
		var component = components[i]
		if i == 0 or (i < keep_components and int(component.size()) >= min_secondary_cells):
			for cell in component:
				out[cell.x][cell.y] = true
	return out


func _collect_mask_components(mask: Array, want_value: bool, cols: int, rows: int) -> Array:
	var visited: Dictionary = {}
	var components: Array = []
	for r in range(rows):
		for c in range(cols):
			if bool(mask[r][c]) != want_value:
				continue
			var key: String = "%d:%d" % [r, c]
			if visited.has(key):
				continue
			var queue: Array[Vector2i] = [Vector2i(r, c)]
			var component: Array[Vector2i] = []
			visited[key] = true
			var head: int = 0
			while head < queue.size():
				var cur: Vector2i = queue[head]
				head += 1
				component.append(cur)
				for neighbor in _grid_neighbors(cur.x, cur.y, cols, rows):
					if bool(mask[neighbor.x][neighbor.y]) != want_value:
						continue
					var nkey: String = "%d:%d" % [neighbor.x, neighbor.y]
					if visited.has(nkey):
						continue
					visited[nkey] = true
					queue.append(neighbor)
			components.append(component)
	return components


func _smooth_land_mask(mask: Array, cols: int, rows: int) -> Array:
	var out: Array = _make_bool_grid(rows, cols, false)
	for r in range(rows):
		for c in range(cols):
			var count: int = _count_mask_neighbors(mask, r, c, cols, rows, true)
			var cur: bool = bool(mask[r][c])
			if cur:
				out[r][c] = count >= 3
			else:
				out[r][c] = count >= 5
	return out


func _fill_small_land_gaps(mask: Array, cols: int, rows: int) -> void:
	for pass_idx in range(2):
		var flips: Array[Vector2i] = []
		for r in range(1, rows - 1):
			for c in range(1, cols - 1):
				if bool(mask[r][c]):
					continue
				if _count_mask_neighbors(mask, r, c, cols, rows, true) >= 6:
					flips.append(Vector2i(r, c))
		for cell in flips:
			mask[cell.x][cell.y] = true


func _keep_largest_land_component(mask: Array, cols: int, rows: int) -> Array:
	var largest: Array[Vector2i] = _largest_mask_component(mask, true, cols, rows)
	if largest.is_empty():
		return mask
	var out: Array = _make_bool_grid(rows, cols, false)
	for cell in largest:
		out[cell.x][cell.y] = true
	return out


func _fit_mainland_to_template_footprint(mask: Array, cols: int, rows: int, template_id: String) -> Array:
	var cells: Array[Vector2i] = _largest_mask_component(mask, true, cols, rows)
	if cells.is_empty():
		return mask

	var min_r: int = rows
	var max_r: int = -1
	var min_c: int = cols
	var max_c: int = -1
	var sum_r: float = 0.0
	var sum_c: float = 0.0
	for cell in cells:
		min_r = mini(min_r, cell.x)
		max_r = maxi(max_r, cell.x)
		min_c = mini(min_c, cell.y)
		max_c = maxi(max_c, cell.y)
		sum_r += float(cell.x)
		sum_c += float(cell.y)

	var current_h: int = maxi(1, max_r - min_r + 1)
	var current_w: int = maxi(1, max_c - min_c + 1)
	var center_r: float = sum_r / float(cells.size())
	var center_c: float = sum_c / float(cells.size())
	var footprint: Dictionary = _get_template_mainland_footprint(template_id)
	var edge_margin: int = maxi(1, LevelConfig.GRAND_MAP_LAND_EDGE_MARGIN_CELLS)
	var target_w: int = clampi(int(round(float(cols) * float(footprint.get("width_frac", 0.72)))), 6, cols - edge_margin * 2)
	var target_h: int = clampi(int(round(float(rows) * float(footprint.get("height_frac", 0.78)))), 6, rows - edge_margin * 2)
	var placement_bias: Vector2 = _get_template_placement_bias(template_id)
	var target_center_r: float = clampf(
		(float(rows - 1) * 0.5) + placement_bias.y * float(rows) * 0.16,
		float(edge_margin) + float(target_h) * 0.5,
		float(rows - edge_margin) - float(target_h) * 0.5
	)
	var target_center_c: float = clampf(
		(float(cols - 1) * 0.5) + placement_bias.x * float(cols) * 0.16,
		float(edge_margin) + float(target_w) * 0.5,
		float(cols - edge_margin) - float(target_w) * 0.5
	)

	# Force the fitted mainland toward the template's intended screen footprint instead of
	# preserving the source aspect too gently, which was letting many templates survive as large ovals.
	var sx: float = float(target_w) / float(current_w)
	var sy: float = float(target_h) / float(current_h)
	var out: Array = _make_bool_grid(rows, cols, false)

	for r in range(rows):
		for c in range(cols):
			if r < edge_margin or r >= rows - edge_margin or c < edge_margin or c >= cols - edge_margin:
				continue
			var src_r: float = (float(r) - target_center_r) / maxf(0.001, sy) + center_r
			var src_c: float = (float(c) - target_center_c) / maxf(0.001, sx) + center_c
			var ir: int = int(round(src_r))
			var ic: int = int(round(src_c))
			if ir < 0 or ir >= rows or ic < 0 or ic >= cols:
				continue
			if bool(mask[ir][ic]):
				out[r][c] = true

	return out


func _get_template_placement_bias(template_id: String) -> Vector2:
	match template_id:
		LevelConfig.GRAND_MAP_TEMPLATE_NORTH_AMERICA:
			return Vector2(-0.10, -0.10)
		LevelConfig.GRAND_MAP_TEMPLATE_SOUTH_AMERICA:
			return Vector2(-0.08, 0.02)
		LevelConfig.GRAND_MAP_TEMPLATE_EUROPE:
			return Vector2(-0.04, -0.16)
		LevelConfig.GRAND_MAP_TEMPLATE_AFRICA:
			return Vector2(0.00, 0.00)
		LevelConfig.GRAND_MAP_TEMPLATE_ASIA:
			return Vector2(0.10, -0.08)
		LevelConfig.GRAND_MAP_TEMPLATE_AUSTRALIA:
			return Vector2(0.04, 0.12)
		LevelConfig.GRAND_MAP_TEMPLATE_ANTARCTICA:
			return Vector2(0.00, 0.22)
		_:
			return Vector2.ZERO


func _apply_template_macro_silhouette(mask: Array, cols: int, rows: int, template_id: String, gen_rng: RandomNumberGenerator) -> void:
	var specs: Array = _get_template_macro_carve_specs(template_id)
	for spec_any in specs:
		var spec: Dictionary = spec_any
		var center: Vector2 = spec.get("center", Vector2.ZERO)
		var radius: Vector2 = spec.get("radius", Vector2(0.20, 0.18))
		var jitter: Vector2 = spec.get("jitter", Vector2.ZERO)
		var rotation_deg: float = float(spec.get("rotation_deg", 0.0))
		var center_jitter: Vector2 = Vector2(
			gen_rng.randf_range(-jitter.x, jitter.x),
			gen_rng.randf_range(-jitter.y, jitter.y)
		)
		var radius_scale: float = gen_rng.randf_range(0.94, 1.10)
		_carve_mask_ellipse_normalized(
			mask,
			cols,
			rows,
			center + center_jitter,
			radius * radius_scale,
			deg_to_rad(rotation_deg + gen_rng.randf_range(-6.0, 6.0))
		)


func _get_template_macro_carve_specs(template_id: String) -> Array:
	match template_id:
		LevelConfig.GRAND_MAP_TEMPLATE_NORTH_AMERICA:
			return [
				{"center": Vector2(0.36, 0.02), "radius": Vector2(0.22, 0.26), "rotation_deg": 8.0, "jitter": Vector2(0.04, 0.04)},
				{"center": Vector2(0.04, 0.58), "radius": Vector2(0.14, 0.20), "rotation_deg": -10.0, "jitter": Vector2(0.03, 0.04)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_SOUTH_AMERICA:
			return [
				{"center": Vector2(-0.30, 0.14), "radius": Vector2(0.18, 0.28), "rotation_deg": -8.0, "jitter": Vector2(0.03, 0.04)},
				{"center": Vector2(0.18, -0.34), "radius": Vector2(0.16, 0.18), "rotation_deg": 10.0, "jitter": Vector2(0.03, 0.03)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_EUROPE:
			return [
				{"center": Vector2(-0.32, 0.08), "radius": Vector2(0.18, 0.18), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.04)},
				{"center": Vector2(0.26, -0.02), "radius": Vector2(0.20, 0.16), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.04)},
				{"center": Vector2(0.02, 0.32), "radius": Vector2(0.18, 0.14), "rotation_deg": 12.0, "jitter": Vector2(0.03, 0.03)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_AFRICA:
			return [
				{"center": Vector2(-0.34, -0.04), "radius": Vector2(0.20, 0.28), "rotation_deg": 2.0, "jitter": Vector2(0.04, 0.04)},
				{"center": Vector2(0.28, -0.02), "radius": Vector2(0.14, 0.16), "rotation_deg": -4.0, "jitter": Vector2(0.03, 0.03)},
				{"center": Vector2(0.00, -0.64), "radius": Vector2(0.20, 0.12), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.03)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_ASIA:
			return [
				{"center": Vector2(-0.46, 0.06), "radius": Vector2(0.18, 0.18), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.04)},
				{"center": Vector2(0.14, 0.34), "radius": Vector2(0.24, 0.18), "rotation_deg": -10.0, "jitter": Vector2(0.05, 0.04)},
				{"center": Vector2(0.56, -0.06), "radius": Vector2(0.14, 0.16), "rotation_deg": 0.0, "jitter": Vector2(0.03, 0.03)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_AUSTRALIA:
			return [
				{"center": Vector2(-0.02, -0.30), "radius": Vector2(0.24, 0.16), "rotation_deg": 0.0, "jitter": Vector2(0.03, 0.03)},
				{"center": Vector2(0.30, 0.18), "radius": Vector2(0.16, 0.14), "rotation_deg": 6.0, "jitter": Vector2(0.03, 0.03)}
			]
		LevelConfig.GRAND_MAP_TEMPLATE_ANTARCTICA:
			return [
				{"center": Vector2(0.00, -0.08), "radius": Vector2(0.28, 0.18), "rotation_deg": 0.0, "jitter": Vector2(0.04, 0.03)},
				{"center": Vector2(-0.54, -0.02), "radius": Vector2(0.16, 0.12), "rotation_deg": 0.0, "jitter": Vector2(0.03, 0.03)},
				{"center": Vector2(0.54, -0.02), "radius": Vector2(0.16, 0.12), "rotation_deg": 0.0, "jitter": Vector2(0.03, 0.03)}
			]
		_:
			return [
				{"center": Vector2(0.28, 0.10), "radius": Vector2(0.20, 0.18), "rotation_deg": 0.0, "jitter": Vector2(0.03, 0.03)}
			]


func _apply_template_coast_push(mask: Array, cols: int, rows: int, template_id: String) -> Array:
	var out: Array = mask
	var profile: Dictionary = LevelConfig.get_grand_map_template_profile(template_id)
	var aspect_bias: Vector2 = profile.get("aspect_bias", Vector2.ONE)
	var center_bias: Vector2 = profile.get("center_bias", Vector2.ZERO)
	var lobes: Array = _normalize_template_lobes(_get_continent_template_lobes(template_id), aspect_bias, center_bias)
	var footprint: Dictionary = _get_template_mainland_footprint(template_id)
	var target_fill: float = float(footprint.get("fill_frac", 0.48))
	var target_cells: int = int(round(float(cols * rows) * target_fill))
	var edge_margin: int = maxi(1, LevelConfig.GRAND_MAP_LAND_EDGE_MARGIN_CELLS)
	var strength: float = LevelConfig.GRAND_MAP_TEMPLATE_COAST_PUSH_STRENGTH
	var thresholds: Array = [0.78, 0.70, 0.62, 0.55, 0.48]
	for threshold_any in thresholds:
		var current_cells: int = int(_collect_mask_cells(out, true, cols, rows).size())
		if current_cells >= target_cells:
			break
		var threshold: float = float(threshold_any)
		var to_add: Array[Vector2i] = []
		for r in range(edge_margin, rows - edge_margin):
			for c in range(edge_margin, cols - edge_margin):
				if bool(out[r][c]):
					continue
				var land_neighbors: int = _count_mask_neighbors(out, r, c, cols, rows, true)
				if land_neighbors <= 0:
					continue
				var p: Vector2 = _grid_cell_to_normalized(r, c, cols, rows)
				var score: float = _score_template_land_point(p, lobes)
				score += _template_directional_bias(template_id, p)
				score += float(land_neighbors) * (0.08 + strength * 0.06)
				if score >= threshold:
					to_add.append(Vector2i(r, c))
		for cell in to_add:
			out[cell.x][cell.y] = true
		out = _keep_largest_land_component(out, cols, rows)
		if to_add.is_empty() and current_cells < target_cells:
			var forced: Array[Dictionary] = []
			for r2 in range(edge_margin, rows - edge_margin):
				for c2 in range(edge_margin, cols - edge_margin):
					if bool(out[r2][c2]):
						continue
					var land_neighbors2: int = _count_mask_neighbors(out, r2, c2, cols, rows, true)
					if land_neighbors2 <= 0:
						continue
					var p2: Vector2 = _grid_cell_to_normalized(r2, c2, cols, rows)
					var force_score: float = _score_template_land_point(p2, lobes)
					force_score += _template_directional_bias(template_id, p2)
					force_score += float(land_neighbors2) * 0.12
					forced.append({"r": r2, "c": c2, "score": force_score})
			forced.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
			var budget: int = mini(18, forced.size())
			for idx in range(budget):
				var entry: Dictionary = forced[idx]
				out[int(entry["r"])][int(entry["c"])] = true
			out = _keep_largest_land_component(out, cols, rows)
	return out


func _get_template_mainland_footprint(template_id: String) -> Dictionary:
	match template_id:
		LevelConfig.GRAND_MAP_TEMPLATE_NORTH_AMERICA:
			return {"width_frac": 0.84, "height_frac": 0.90, "fill_frac": 0.56}
		LevelConfig.GRAND_MAP_TEMPLATE_SOUTH_AMERICA:
			return {"width_frac": 0.62, "height_frac": 0.96, "fill_frac": 0.50}
		LevelConfig.GRAND_MAP_TEMPLATE_EUROPE:
			return {"width_frac": 0.92, "height_frac": 0.68, "fill_frac": 0.50}
		LevelConfig.GRAND_MAP_TEMPLATE_AFRICA:
			return {"width_frac": 0.70, "height_frac": 0.96, "fill_frac": 0.56}
		LevelConfig.GRAND_MAP_TEMPLATE_ASIA:
			return {"width_frac": 0.96, "height_frac": 0.70, "fill_frac": 0.54}
		LevelConfig.GRAND_MAP_TEMPLATE_AUSTRALIA:
			return {"width_frac": 0.88, "height_frac": 0.64, "fill_frac": 0.50}
		LevelConfig.GRAND_MAP_TEMPLATE_ANTARCTICA:
			return {"width_frac": 0.98, "height_frac": 0.48, "fill_frac": 0.46}
		_:
			return {"width_frac": 0.82, "height_frac": 0.84, "fill_frac": 0.52}


func _dilate_land_mask(mask: Array, cols: int, rows: int, passes: int, edge_margin: int) -> Array:
	var out: Array = mask
	for pass_idx in range(passes):
		var next_mask: Array = _make_bool_grid(rows, cols, false)
		for r in range(rows):
			for c in range(cols):
				if r < edge_margin or r >= rows - edge_margin or c < edge_margin or c >= cols - edge_margin:
					next_mask[r][c] = false
					continue
				if bool(out[r][c]) or _count_mask_neighbors(out, r, c, cols, rows, true) >= 3:
					next_mask[r][c] = true
		out = next_mask
	return out


func _build_fallback_land_mask(cols: int, rows: int, template_id: String, gen_rng: RandomNumberGenerator, preferred_mask: Array = []) -> Array:
	var mask: Array = []
	if _is_valid_mask_grid(preferred_mask, cols, rows):
		mask = preferred_mask.duplicate(true)
	else:
		var rng_local: RandomNumberGenerator = RandomNumberGenerator.new()
		rng_local.seed = int(gen_rng.randi()) ^ int(hash(template_id)) ^ 1337
		mask = _build_template_land_mask(cols, rows, template_id, rng_local)
	if not _is_valid_mask_grid(mask, cols, rows):
		mask = _make_bool_grid(rows, cols, false)
		var safe_rng: RandomNumberGenerator = RandomNumberGenerator.new()
		safe_rng.seed = int(gen_rng.randi()) ^ int(hash(template_id)) ^ 424242
		mask = _build_safe_template_land_mask(cols, rows, template_id, safe_rng)
	mask = _smooth_land_mask(mask, cols, rows)
	mask = _keep_largest_land_component(mask, cols, rows)
	_fill_small_land_gaps(mask, cols, rows)
	mask = _keep_largest_land_component(mask, cols, rows)
	var land_cells: Array[Vector2i] = _collect_mask_cells(mask, true, cols, rows)
	if land_cells.size() < 70:
		var safe_rng2: RandomNumberGenerator = RandomNumberGenerator.new()
		safe_rng2.seed = int(gen_rng.randi()) ^ int(hash(template_id)) ^ 987654
		mask = _build_safe_template_land_mask(cols, rows, template_id, safe_rng2)
		mask = _smooth_land_mask(mask, cols, rows)
		mask = _keep_largest_land_component(mask, cols, rows)
	return mask


func _build_safe_template_land_mask(cols: int, rows: int, template_id: String, gen_rng: RandomNumberGenerator) -> Array:
	var mask: Array = _make_bool_grid(rows, cols, false)
	var footprint: Dictionary = _get_template_mainland_footprint(template_id)
	var width_frac: float = clampf(float(footprint.get("width_frac", 0.78)) * 0.98, 0.52, 0.98)
	var height_frac: float = clampf(float(footprint.get("height_frac", 0.86)) * 0.98, 0.52, 0.98)
	var placement_bias: Vector2 = _get_template_placement_bias(template_id)
	var placement_center: Vector2 = Vector2(placement_bias.x * 0.14, placement_bias.y * 0.14)
	var angle: float = deg_to_rad(gen_rng.randf_range(-10.0, 10.0))
	var stretch: Vector2 = Vector2(gen_rng.randf_range(0.94, 1.06), gen_rng.randf_range(0.94, 1.06))
	var shear: Vector2 = Vector2(gen_rng.randf_range(-0.05, 0.05), gen_rng.randf_range(-0.03, 0.03))
	var mirror_x: bool = gen_rng.randf() < 0.5
	var skeleton: Dictionary = _get_template_skeleton_spec(template_id)
	var strokes: Array = skeleton.get("strokes", [])
	var bulges: Array = skeleton.get("bulges", [])
	for stroke_any in strokes:
		var stroke: Dictionary = stroke_any
		var raw_points: Array = stroke.get("points", [])
		var prepared_points: Array = _prepare_template_points(raw_points, width_frac, height_frac, placement_center, angle, stretch, shear, mirror_x, 0.0, gen_rng)
		var start_w: float = float(stroke.get("start_w", 0.16))
		var end_w: float = float(stroke.get("end_w", start_w))
		var start_radius: Vector2 = Vector2(start_w * width_frac * absf(stretch.x), start_w * height_frac * absf(stretch.y))
		var end_radius: Vector2 = Vector2(end_w * width_frac * absf(stretch.x), end_w * height_frac * absf(stretch.y))
		_stamp_polyline_to_mask(mask, cols, rows, prepared_points, start_radius, end_radius)
	for bulge_any in bulges:
		var bulge: Dictionary = bulge_any
		var center: Vector2 = _transform_template_point(bulge.get("center", Vector2.ZERO), width_frac, height_frac, placement_center, angle, stretch, shear, mirror_x)
		var raw_radius: Vector2 = bulge.get("radius", Vector2(0.18, 0.18))
		var radius: Vector2 = Vector2(raw_radius.x * width_frac * absf(stretch.x), raw_radius.y * height_frac * absf(stretch.y))
		_fill_mask_ellipse_normalized(mask, cols, rows, center, radius, angle * 0.25)
	return _keep_largest_land_component(mask, cols, rows)


func _grid_cell_to_normalized(r: int, c: int, cols: int, rows: int) -> Vector2:
	return Vector2(
		((float(c) + 0.5) / float(cols)) * 2.0 - 1.0,
		((float(r) + 0.5) / float(rows)) * 2.0 - 1.0
	)


func _is_valid_mask_grid(mask: Array, cols: int, rows: int) -> bool:
	if mask.size() != rows:
		return false
	for r in range(rows):
		if typeof(mask[r]) != TYPE_ARRAY:
			return false
		var row: Array = mask[r]
		if row.size() != cols:
			return false
	return true


func _collect_mask_cells(mask: Array, want_value: bool, cols: int, rows: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var safe_rows: int = mini(rows, mask.size())
	for r in range(safe_rows):
		if typeof(mask[r]) != TYPE_ARRAY:
			continue
		var row: Array = mask[r]
		var safe_cols: int = mini(cols, row.size())
		for c in range(safe_cols):
			if bool(row[c]) == want_value:
				cells.append(Vector2i(r, c))
	return cells


func _collect_coastal_cells(mask: Array, cols: int, rows: int) -> Array[Vector2i]:
	var coastal: Array[Vector2i] = []
	for r in range(rows):
		for c in range(cols):
			if not bool(mask[r][c]):
				continue
			if _count_mask_neighbors(mask, r, c, cols, rows, false) > 0:
				coastal.append(Vector2i(r, c))
	return coastal


func _largest_mask_component(mask: Array, want_value: bool, cols: int, rows: int) -> Array[Vector2i]:
	var visited: Dictionary = {}
	var best: Array[Vector2i] = []
	for r in range(rows):
		for c in range(cols):
			if bool(mask[r][c]) != want_value:
				continue
			var key: String = "%d:%d" % [r, c]
			if visited.has(key):
				continue
			var component: Array[Vector2i] = []
			var queue: Array[Vector2i] = [Vector2i(r, c)]
			visited[key] = true
			var head: int = 0
			while head < queue.size():
				var cur: Vector2i = queue[head]
				head += 1
				component.append(cur)
				for neighbor in _grid_neighbors(cur.x, cur.y, cols, rows):
					if bool(mask[neighbor.x][neighbor.y]) != want_value:
						continue
					var nkey: String = "%d:%d" % [neighbor.x, neighbor.y]
					if visited.has(nkey):
						continue
					visited[nkey] = true
					queue.append(neighbor)
			if component.size() > best.size():
				best = component
	return best


func _make_bool_grid(rows: int, cols: int, value: bool) -> Array:
	var grid: Array = []
	for r in range(rows):
		var row: Array = []
		row.resize(cols)
		for c in range(cols):
			row[c] = value
		grid.append(row)
	return grid


func _make_int_grid(rows: int, cols: int, value: int) -> Array:
	var grid: Array = []
	for r in range(rows):
		var row: Array = []
		row.resize(cols)
		for c in range(cols):
			row[c] = value
		grid.append(row)
	return grid


func _count_mask_neighbors(mask: Array, r: int, c: int, cols: int, rows: int, want_value: bool) -> int:
	var count: int = 0
	for rr in range(r - 1, r + 2):
		for cc in range(c - 1, c + 2):
			if rr == r and cc == c:
				continue
			if rr < 0 or rr >= rows or cc < 0 or cc >= cols:
				if want_value == false:
					count += 1
				continue
			if bool(mask[rr][cc]) == want_value:
				count += 1
	return count


func _grid_neighbors(r: int, c: int, cols: int, rows: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if r > 0:
		out.append(Vector2i(r - 1, c))
	if r < rows - 1:
		out.append(Vector2i(r + 1, c))
	if c > 0:
		out.append(Vector2i(r, c - 1))
	if c < cols - 1:
		out.append(Vector2i(r, c + 1))
	return out


func _pick_region_seed_cells(land_cells: Array[Vector2i], desired_count: int, gen_rng: RandomNumberGenerator) -> Array[Vector2i]:
	var seeds: Array[Vector2i] = []
	if land_cells.is_empty():
		return seeds

	var first: Vector2i = land_cells[gen_rng.randi_range(0, land_cells.size() - 1)]
	seeds.append(first)

	while seeds.size() < desired_count and seeds.size() < land_cells.size():
		var best_cell: Vector2i = land_cells[0]
		var best_score: float = -1.0
		for cell in land_cells:
			var min_dist: float = INF
			for seed in seeds:
				var d: float = absf(float(cell.x - seed.x)) + absf(float(cell.y - seed.y))
				if d < min_dist:
					min_dist = d
			var score: float = min_dist + gen_rng.randf() * 0.35
			if score > best_score:
				best_score = score
				best_cell = cell
		seeds.append(best_cell)
	return seeds


func _grow_regions_from_seeds(mask: Array, seed_cells: Array[Vector2i], cols: int, rows: int, gen_rng: RandomNumberGenerator) -> Array:
	var assignments: Array = _make_int_grid(rows, cols, -2)
	for r in range(rows):
		for c in range(cols):
			if bool(mask[r][c]):
				assignments[r][c] = -1

	var queue: Array[Dictionary] = []
	for region_id in range(seed_cells.size()):
		var seed: Vector2i = seed_cells[region_id]
		assignments[seed.x][seed.y] = region_id
		for neighbor in _grid_neighbors(seed.x, seed.y, cols, rows):
			if assignments[neighbor.x][neighbor.y] == -1:
				queue.append({
					"r": neighbor.x,
					"c": neighbor.y,
					"region": region_id,
					"prio": 1.0 + gen_rng.randf() * 0.35
				})

	while not queue.is_empty():
		var best_idx: int = 0
		var best_prio: float = float(queue[0].get("prio", 0.0))
		for i in range(1, queue.size()):
			var cand_prio: float = float(queue[i].get("prio", 0.0))
			if cand_prio < best_prio:
				best_prio = cand_prio
				best_idx = i

		var item: Dictionary = queue[best_idx]
		queue.remove_at(best_idx)
		var r: int = int(item.get("r", -1))
		var c: int = int(item.get("c", -1))
		var region_id: int = int(item.get("region", -1))
		var prio: float = float(item.get("prio", 0.0))
		if r < 0 or c < 0 or r >= rows or c >= cols:
			continue
		if assignments[r][c] != -1:
			continue

		assignments[r][c] = region_id
		var seed_ref: Vector2i = seed_cells[region_id]
		for neighbor in _grid_neighbors(r, c, cols, rows):
			if assignments[neighbor.x][neighbor.y] != -1:
				continue
			var dist_bias: float = absf(float(neighbor.x - seed_ref.x)) * 0.012 + absf(float(neighbor.y - seed_ref.y)) * 0.012
			queue.append({
				"r": neighbor.x,
				"c": neighbor.y,
				"region": region_id,
				"prio": prio + 1.0 + gen_rng.randf() * 0.45 + dist_bias
			})

	return assignments


func _build_province_dicts_from_assignments(assignments: Array, land_mask: Array, seed_cells: Array[Vector2i], playable_half: Vector2, gen_rng: RandomNumberGenerator) -> Dictionary:
	var rows: int = assignments.size()
	var cols: int = int(assignments[0].size()) if rows > 0 else 0
	var id_map: Dictionary = {}
	var region_counts: Dictionary = {}
	var adjacency_sets: Dictionary = {}

	for r in range(rows):
		for c in range(cols):
			var region_any = assignments[r][c]
			if region_any == null:
				continue
			var region: int = int(region_any)
			if region < 0:
				continue
			if not id_map.has(region):
				id_map[region] = id_map.size()
				region_counts[region] = 0
				adjacency_sets[region] = {}
			region_counts[region] = int(region_counts.get(region, 0)) + 1
			for neighbor in _grid_neighbors(r, c, cols, rows):
				var other: int = int(assignments[neighbor.x][neighbor.y])
				if other >= 0 and other != region:
					var aset: Dictionary = adjacency_sets.get(region, {})
					aset[other] = true
					adjacency_sets[region] = aset

	var ordered_regions: Array[int] = []
	for key in id_map.keys():
		ordered_regions.append(int(key))
	ordered_regions.sort()

	var cell_w: float = (playable_half.x * 2.0) / float(cols)
	var cell_h: float = (playable_half.y * 2.0) / float(rows)
	var provinces: Array[Dictionary] = []
	var kept_old_regions: Array[int] = []

	for old_region in ordered_regions:
		var poly: PackedVector2Array = _extract_region_polygon(assignments, old_region, cols, rows, cell_w, cell_h, playable_half)
		if poly.size() < 3:
			continue
		var province: Dictionary = {
			"id": provinces.size(),
			"old_region": old_region,
			"polygon": poly,
			"tint_index": gen_rng.randi_range(0, LevelConfig.PROVINCE_FILL_COLORS.size() - 1),
			"type": LevelConfig.PROVINCE_TYPE_NEUTRAL,
			"buildings": LevelConfig.PROVINCE_NEUTRAL_BUILDINGS,
			"troops": LevelConfig.PROVINCE_NEUTRAL_TROOPS,
			"neighbors": [],
			"invading_troops": 0,
			"invasion_fresh": false,
			"faction_id": 0,
			"is_target": false
		}
		provinces.append(province)
		kept_old_regions.append(old_region)

	var old_to_new: Dictionary = {}
	for i in range(kept_old_regions.size()):
		old_to_new[kept_old_regions[i]] = i

	for i in range(provinces.size()):
		var old_region: int = int(provinces[i].get("old_region", -1))
		var neighbor_ids: Array[int] = []
		var seen_neighbors: Dictionary = {}
		var aset_variant: Dictionary = adjacency_sets.get(old_region, {})
		for other_old_any in aset_variant.keys():
			var other_old: int = int(other_old_any)
			if not old_to_new.has(other_old):
				continue
			var mapped_neighbor: int = int(old_to_new[other_old])
			if mapped_neighbor == i:
				continue
			if seen_neighbors.has(mapped_neighbor):
				continue
			seen_neighbors[mapped_neighbor] = true
			neighbor_ids.append(mapped_neighbor)
		neighbor_ids.sort()
		provinces[i]["neighbors"] = neighbor_ids
		provinces[i]["id"] = i
		provinces[i].erase("old_region")

	return {"provinces": provinces}


func _extract_region_polygon(assignments: Array, region_id: int, cols: int, rows: int, cell_w: float, cell_h: float, playable_half: Vector2) -> PackedVector2Array:
	var edges: Array[Dictionary] = []
	for r in range(rows):
		for c in range(cols):
			if int(assignments[r][c]) != region_id:
				continue
			var x0: float = -playable_half.x + float(c) * cell_w
			var y0: float = -playable_half.y + float(r) * cell_h
			var x1: float = x0 + cell_w
			var y1: float = y0 + cell_h
			if r == 0 or int(assignments[r - 1][c]) != region_id:
				edges.append({"a": Vector2(x0, y0), "b": Vector2(x1, y0)})
			if c == cols - 1 or int(assignments[r][c + 1]) != region_id:
				edges.append({"a": Vector2(x1, y0), "b": Vector2(x1, y1)})
			if r == rows - 1 or int(assignments[r + 1][c]) != region_id:
				edges.append({"a": Vector2(x1, y1), "b": Vector2(x0, y1)})
			if c == 0 or int(assignments[r][c - 1]) != region_id:
				edges.append({"a": Vector2(x0, y1), "b": Vector2(x0, y0)})

	var poly: PackedVector2Array = _trace_largest_edge_loop(edges)
	return _collapse_collinear_points(poly)


func _trace_largest_edge_loop(edges: Array[Dictionary]) -> PackedVector2Array:
	if edges.is_empty():
		return PackedVector2Array()

	var outgoing: Dictionary = {}
	for i in range(edges.size()):
		var edge: Dictionary = edges[i]
		var key: String = _vec_key(edge.get("a", Vector2.ZERO))
		if not outgoing.has(key):
			outgoing[key] = []
		var bucket: Array = outgoing[key]
		bucket.append(i)
		outgoing[key] = bucket

	var used: Dictionary = {}
	var best_loop: PackedVector2Array = PackedVector2Array()
	var best_area: float = -1.0

	for i in range(edges.size()):
		if used.has(i):
			continue
		var loop_points: Array[Vector2] = []
		var edge: Dictionary = edges[i]
		var start: Vector2 = edge.get("a", Vector2.ZERO)
		var current: Vector2 = start
		var edge_idx: int = i
		var guard: int = 0

		while guard < 20000:
			guard += 1
			if used.has(edge_idx):
				break
			used[edge_idx] = true
			var active: Dictionary = edges[edge_idx]
			var a: Vector2 = active.get("a", Vector2.ZERO)
			var b: Vector2 = active.get("b", Vector2.ZERO)
			if loop_points.is_empty():
				loop_points.append(a)
			loop_points.append(b)
			current = b
			if current.distance_to(start) < 0.001:
				break
			var key: String = _vec_key(current)
			var next_list: Array = outgoing.get(key, [])
			var next_idx: int = -1
			for candidate in next_list:
				var ci: int = int(candidate)
				if not used.has(ci):
					next_idx = ci
					break
			if next_idx == -1:
				break
			edge_idx = next_idx

		if loop_points.size() >= 4 and loop_points[0].distance_to(loop_points[loop_points.size() - 1]) < 0.001:
			var candidate_poly: PackedVector2Array = PackedVector2Array(loop_points)
			var area: float = absf(_polygon_signed_area(candidate_poly))
			if area > best_area:
				best_area = area
				best_loop = candidate_poly

	if best_loop.size() > 1 and best_loop[0].distance_to(best_loop[best_loop.size() - 1]) < 0.001:
		best_loop.remove_at(best_loop.size() - 1)
	return best_loop


func _collapse_collinear_points(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 4:
		return poly
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(poly.size()):
		var prev: Vector2 = poly[(i - 1 + poly.size()) % poly.size()]
		var cur: Vector2 = poly[i]
		var nxt: Vector2 = poly[(i + 1) % poly.size()]
		var v1: Vector2 = (cur - prev).normalized()
		var v2: Vector2 = (nxt - cur).normalized()
		if absf(v1.cross(v2)) < 0.001 and v1.dot(v2) > 0.999:
			continue
		out.append(cur)
	return out


func _largest_polygon_by_area(polygons: Array) -> PackedVector2Array:
	if polygons.is_empty():
		return PackedVector2Array()
	var best_poly: PackedVector2Array = polygons[0]
	var best_area: float = absf(_polygon_signed_area(best_poly))
	for candidate in polygons:
		var candidate_poly: PackedVector2Array = candidate
		var candidate_area: float = absf(_polygon_signed_area(candidate_poly))
		if candidate_area > best_area:
			best_area = candidate_area
			best_poly = candidate_poly
	return best_poly


func _chaikin_smooth_closed_polygon(poly: PackedVector2Array, ratio: float) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	var clamped_ratio: float = clampf(ratio, 0.05, 0.45)
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		out.append(a.lerp(b, clamped_ratio))
		out.append(a.lerp(b, 1.0 - clamped_ratio))
	return out


func _distance_point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq <= 0.000001:
		return point.distance_to(a)
	var t: float = clampf((point - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return point.distance_to(closest)


func _rdp_simplify_open_polyline(points: PackedVector2Array, epsilon: float) -> PackedVector2Array:
	if points.size() <= 2:
		return points
	var max_distance: float = -1.0
	var max_index: int = -1
	var start_point: Vector2 = points[0]
	var end_point: Vector2 = points[points.size() - 1]
	for i in range(1, points.size() - 1):
		var distance: float = _distance_point_to_segment(points[i], start_point, end_point)
		if distance > max_distance:
			max_distance = distance
			max_index = i
	if max_distance > epsilon and max_index > 0:
		var left_source: PackedVector2Array = PackedVector2Array()
		for i in range(0, max_index + 1):
			left_source.append(points[i])
		var right_source: PackedVector2Array = PackedVector2Array()
		for i in range(max_index, points.size()):
			right_source.append(points[i])
		var left: PackedVector2Array = _rdp_simplify_open_polyline(left_source, epsilon)
		var right: PackedVector2Array = _rdp_simplify_open_polyline(right_source, epsilon)
		var out: PackedVector2Array = PackedVector2Array()
		for i in range(left.size() - 1):
			out.append(left[i])
		for point in right:
			out.append(point)
		return out
	var simple: PackedVector2Array = PackedVector2Array()
	simple.append(start_point)
	simple.append(end_point)
	return simple


func _normalize_closed_polygon_start(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	var working: PackedVector2Array = poly
	if _polygon_signed_area(working) < 0.0:
		var reversed_working: PackedVector2Array = PackedVector2Array()
		for i in range(working.size() - 1, -1, -1):
			reversed_working.append(working[i])
		working = reversed_working
	var best_index: int = 0
	for i in range(1, working.size()):
		var candidate: Vector2 = working[i]
		var best: Vector2 = working[best_index]
		if candidate.x < best.x - 0.001 or (absf(candidate.x - best.x) <= 0.001 and candidate.y < best.y):
			best_index = i
	if best_index == 0:
		return working
	var rotated: PackedVector2Array = PackedVector2Array()
	for i in range(working.size()):
		rotated.append(working[(best_index + i) % working.size()])
	return rotated


func _simplify_closed_polygon(poly: PackedVector2Array, epsilon: float) -> PackedVector2Array:
	if poly.size() < 4 or epsilon <= 0.0:
		return poly
	var working: PackedVector2Array = _normalize_closed_polygon_start(poly)
	var open_points: PackedVector2Array = PackedVector2Array()
	for point in working:
		open_points.append(point)
	open_points.append(working[0])
	var simplified_open: PackedVector2Array = _rdp_simplify_open_polyline(open_points, epsilon)
	if simplified_open.size() <= 3:
		return working
	var simplified_closed: PackedVector2Array = PackedVector2Array()
	for i in range(simplified_open.size() - 1):
		simplified_closed.append(simplified_open[i])
	if simplified_closed.size() >= 3:
		return simplified_closed
	return working


func _make_smoothed_province_display_polyline(poly: PackedVector2Array, inset_distance: float = 0.0) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	var working: PackedVector2Array = poly
	if inset_distance > 0.0:
		var offset_polys: Array = Geometry2D.offset_polygon(working, -inset_distance)
		if not offset_polys.is_empty():
			var inset_poly: PackedVector2Array = _largest_polygon_by_area(offset_polys)
			if inset_poly.size() >= 3:
				working = inset_poly
	working = _collapse_collinear_points(working)
	if bool(LevelConfig.PROVINCE_BORDER_SIMPLIFY_ENABLED):
		var simplify_min_points: int = maxi(3, int(LevelConfig.PROVINCE_BORDER_SIMPLIFY_MIN_POINT_COUNT))
		if working.size() >= simplify_min_points:
			working = _simplify_closed_polygon(working, float(LevelConfig.PROVINCE_BORDER_SIMPLIFY_EPSILON))
			working = _collapse_collinear_points(working)
	if not bool(LevelConfig.PROVINCE_BORDER_SMOOTHING_ENABLED):
		return working
	var min_points: int = maxi(3, int(LevelConfig.PROVINCE_BORDER_SMOOTHING_MIN_POINT_COUNT))
	if working.size() < min_points:
		return working
	var ratio: float = float(LevelConfig.PROVINCE_BORDER_SMOOTHING_CHAIKIN_RATIO)
	var pass_count: int = maxi(0, int(LevelConfig.PROVINCE_BORDER_SMOOTHING_PASSES))
	for _pass_idx in range(pass_count):
		working = _chaikin_smooth_closed_polygon(working, ratio)
	working = _collapse_collinear_points(working)
	return working


func _polygon_signed_area(poly: PackedVector2Array) -> float:
	var area: float = 0.0
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		area += a.x * b.y - b.x * a.y
	return area * 0.5


func _vec_key(v: Vector2) -> String:
	return "%0.3f,%0.3f" % [v.x, v.y]


func _undirected_edge_key(a: Vector2, b: Vector2) -> String:
	if a.x < b.x:
		return "%s|%s" % [_vec_key(a), _vec_key(b)]
	if a.x > b.x:
		return "%s|%s" % [_vec_key(b), _vec_key(a)]
	if a.y <= b.y:
		return "%s|%s" % [_vec_key(a), _vec_key(b)]
	return "%s|%s" % [_vec_key(b), _vec_key(a)]


func _collect_grand_map_outer_edges(province_data: Array) -> Array[Dictionary]:
	var edge_counts: Dictionary = {}
	var edge_entries: Dictionary = {}
	for province_any in province_data:
		if not (province_any is Dictionary):
			continue
		var province: Dictionary = province_any
		var poly: PackedVector2Array = province.get("polygon", PackedVector2Array())
		if poly.size() < 3:
			continue
		for i in range(poly.size()):
			var a: Vector2 = poly[i]
			var b: Vector2 = poly[(i + 1) % poly.size()]
			var key: String = _undirected_edge_key(a, b)
			edge_counts[key] = int(edge_counts.get(key, 0)) + 1
			if not edge_entries.has(key):
				edge_entries[key] = {"a": a, "b": b}
	var outer_edges: Array[Dictionary] = []
	for key_any in edge_counts.keys():
		var key: String = String(key_any)
		if int(edge_counts.get(key, 0)) == 1 and edge_entries.has(key):
			outer_edges.append(edge_entries.get(key, {}))
	return outer_edges



func _trace_all_edge_loops(edges: Array[Dictionary]) -> Array[PackedVector2Array]:
	var loops: Array[PackedVector2Array] = []
	if edges.is_empty():
		return loops
	var adjacency: Dictionary = {}
	for i in range(edges.size()):
		var edge: Dictionary = edges[i]
		var a: Vector2 = edge.get("a", Vector2.ZERO)
		var b: Vector2 = edge.get("b", Vector2.ZERO)
		var a_key: String = _vec_key(a)
		var b_key: String = _vec_key(b)
		if not adjacency.has(a_key):
			adjacency[a_key] = []
		var a_bucket: Array = adjacency.get(a_key, [])
		a_bucket.append(i)
		adjacency[a_key] = a_bucket
		if not adjacency.has(b_key):
			adjacency[b_key] = []
		var b_bucket: Array = adjacency.get(b_key, [])
		b_bucket.append(i)
		adjacency[b_key] = b_bucket
	var used: Dictionary = {}
	for i in range(edges.size()):
		if used.has(i):
			continue
		var start_edge: Dictionary = edges[i]
		var start_a: Vector2 = start_edge.get("a", Vector2.ZERO)
		var start_b: Vector2 = start_edge.get("b", Vector2.ZERO)
		var loop_points: Array[Vector2] = [start_a, start_b]
		used[i] = true
		var prev: Vector2 = start_a
		var current: Vector2 = start_b
		var guard: int = 0
		while guard < 20000:
			guard += 1
			if current.distance_to(start_a) < 0.001:
				break
			var next_idx: int = -1
			var next_point: Vector2 = Vector2.ZERO
			var connected: Array = adjacency.get(_vec_key(current), [])
			for candidate_any in connected:
				var candidate: int = int(candidate_any)
				if used.has(candidate):
					continue
				var edge: Dictionary = edges[candidate]
				var ea: Vector2 = edge.get("a", Vector2.ZERO)
				var eb: Vector2 = edge.get("b", Vector2.ZERO)
				var other: Vector2 = eb if ea.distance_to(current) < 0.001 else ea
				if other.distance_to(prev) < 0.001 and connected.size() > 1:
					continue
				next_idx = candidate
				next_point = other
				break
			if next_idx == -1:
				for candidate_any in connected:
					var candidate: int = int(candidate_any)
					if used.has(candidate):
						continue
					var edge: Dictionary = edges[candidate]
					var ea: Vector2 = edge.get("a", Vector2.ZERO)
					var eb: Vector2 = edge.get("b", Vector2.ZERO)
					next_idx = candidate
					next_point = eb if ea.distance_to(current) < 0.001 else ea
					break
			if next_idx == -1:
				break
			used[next_idx] = true
			loop_points.append(next_point)
			prev = current
			current = next_point
		if loop_points.size() >= 4 and loop_points[0].distance_to(loop_points[loop_points.size() - 1]) < 0.001:
			var loop_poly: PackedVector2Array = PackedVector2Array(loop_points)
			loop_poly.remove_at(loop_poly.size() - 1)
			loop_poly = _collapse_collinear_points(loop_poly)
			loop_poly = _ensure_polygon_ccw(loop_poly)
			if loop_poly.size() >= 3:
				loops.append(loop_poly)
	return loops


func _ensure_polygon_ccw(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	if _polygon_signed_area(poly) >= 0.0:
		return poly
	var reversed_poly: PackedVector2Array = PackedVector2Array()
	for i in range(poly.size() - 1, -1, -1):
		reversed_poly.append(poly[i])
	return reversed_poly


func _spawn_outer_barrier_segment(parent: Node2D, a: Vector2, b: Vector2, thickness: float, color: Color) -> void:
	var dir: Vector2 = b - a
	var seg_len: float = dir.length()
	if seg_len < 0.001:
		return
	dir /= seg_len
	var outward: Vector2 = Vector2(dir.y, -dir.x)
	var body := StaticBody2D.new()
	body.collision_layer = LevelConfig.MASK_WALLS
	body.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
	body.set_meta("is_grand_map_outer_barrier", true)
	body.position = (a + b) * 0.5 + outward * (thickness * 0.5)
	body.rotation = dir.angle()
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(seg_len + thickness * 1.5, thickness)
	collision.shape = rect
	body.add_child(collision)
	var half_len: float = rect.size.x * 0.5
	var half_thick: float = rect.size.y * 0.5
	var fill := Polygon2D.new()
	fill.polygon = PackedVector2Array([
		Vector2(-half_len, -half_thick),
		Vector2(half_len, -half_thick),
		Vector2(half_len, half_thick),
		Vector2(-half_len, half_thick)
	])
	fill.color = color
	fill.z_index = 0
	body.add_child(fill)
	parent.add_child(body)


func _merge_polygon_collection(polygons: Array) -> Array:
	var merged: Array = []
	for poly_any in polygons:
		var source_poly: PackedVector2Array = poly_any
		if source_poly.size() < 3:
			continue
		var pending: Array = [_ensure_polygon_ccw(source_poly)]
		var merge_guard: int = 0
		while not pending.is_empty() and merge_guard < 1024:
			merge_guard += 1
			var candidate: PackedVector2Array = pending.pop_back()
			var merged_into_existing: bool = false
			for i in range(merged.size()):
				var existing: PackedVector2Array = merged[i]
				var union_parts: Array = Geometry2D.merge_polygons(existing, candidate)
				if union_parts.size() == 1:
					merged.remove_at(i)
					pending.append(_ensure_polygon_ccw(union_parts[0]))
					merged_into_existing = true
					break
			if not merged_into_existing:
				merged.append(_ensure_polygon_ccw(candidate))
		if merge_guard >= 1024:
			for pending_poly_any in pending:
				var pending_poly: PackedVector2Array = pending_poly_any
				if pending_poly.size() >= 3:
					merged.append(_ensure_polygon_ccw(pending_poly))
	return merged


func _get_merged_mainland_polygons_from_province_data(province_data: Array) -> Array:
	var province_polygons: Array = []
	for province_any in province_data:
		if not (province_any is Dictionary):
			continue
		var province: Dictionary = province_any
		var poly: PackedVector2Array = province.get("polygon", PackedVector2Array())
		if poly.size() >= 3:
			province_polygons.append(poly)
	return _merge_polygon_collection(province_polygons)


func _spawn_grand_map_side_edge_bar(parent: Node2D, name: String, center: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.name = name
	body.collision_layer = LevelConfig.MASK_WALLS
	body.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
	body.set_meta("is_grand_map_outer_barrier", true)
	body.position = center
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	collision.shape = rect
	body.add_child(collision)
	var half_size: Vector2 = size * 0.5
	var fill := Polygon2D.new()
	fill.name = "EdgeBarrierFill"
	fill.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
	fill.color = color
	fill.z_index = 0
	body.add_child(fill)
	parent.add_child(body)


func _spawn_grand_map_side_edge_bars(parent: Node2D, color: Color) -> void:
	var thickness: float = LevelConfig.GRAND_MAP_WALL_THICKNESS
	var safety: float = LevelConfig.GRAND_MAP_WALL_SAFETY_BUFFER
	var half_x: float = LevelConfig.GRAND_MAP_HALF_EXTENTS.x
	var full_height: float = LevelConfig.GRAND_MAP_WORLD_SIZE.y + thickness * 2.0 + safety * 2.0
	var side_size := Vector2(thickness, full_height)
	_spawn_grand_map_side_edge_bar(parent, "GrandMapLeftEdgeBar", Vector2(-half_x, 0.0), side_size, color)
	_spawn_grand_map_side_edge_bar(parent, "GrandMapRightEdgeBar", Vector2(half_x, 0.0), side_size, color)


func _spawn_grand_map_outer_barrier(obstacles_root: Node2D, province_data: Array) -> void:
	if obstacles_root == null or not is_instance_valid(obstacles_root):
		return
	var existing: Node = obstacles_root.get_node_or_null("GrandMapOuterBarrier")
	if existing != null:
		existing.queue_free()
	var barrier_root := Node2D.new()
	barrier_root.name = "GrandMapOuterBarrier"
	barrier_root.z_as_relative = false
	barrier_root.z_index = LevelConfig.VISUAL_LAYER_GRAND_MAP_EDGE_BARS
	obstacles_root.add_child(barrier_root)
	var barrier_color: Color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color", Color(0.96, 0.82, 0.55, 1.0))
	_spawn_grand_map_side_edge_bars(barrier_root, barrier_color)
	if province_data.is_empty():
		return
	var mainland_polygons: Array = _get_merged_mainland_polygons_from_province_data(province_data)
	if mainland_polygons.is_empty():
		return
	var mainland_barrier_root := Node2D.new()
	mainland_barrier_root.name = "MainlandOuterBarrier"
	mainland_barrier_root.z_index = LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES - LevelConfig.VISUAL_LAYER_GRAND_MAP_EDGE_BARS
	barrier_root.add_child(mainland_barrier_root)
	var barrier_thickness: float = 96.0
	for loop_poly_any in mainland_polygons:
		var loop_poly: PackedVector2Array = loop_poly_any
		var smooth_inner: PackedVector2Array = _make_smoothed_province_display_polyline(loop_poly, 0.0)
		smooth_inner = _ensure_polygon_ccw(smooth_inner)
		if smooth_inner.size() < 3:
			continue
		for i in range(smooth_inner.size()):
			var a: Vector2 = smooth_inner[i]
			var b: Vector2 = smooth_inner[(i + 1) % smooth_inner.size()]
			_spawn_outer_barrier_segment(mainland_barrier_root, a, b, barrier_thickness, barrier_color)


func _assign_grand_map_special_provinces(provinces: Array[Dictionary], gen_rng: RandomNumberGenerator, level_index: int = 1) -> void:
	if provinces.is_empty():
		return

	var centroids: Array[Vector2] = []
	var areas: Array[float] = []
	var total_area: float = 0.0
	for province in provinces:
		var poly: PackedVector2Array = province.get("polygon", PackedVector2Array())
		var centroid: Vector2 = _polygon_vertex_average(poly)
		var area: float = absf(_polygon_signed_area(poly))
		centroids.append(centroid)
		areas.append(area)
		total_area += area
	var avg_area: float = total_area / maxf(1.0, float(provinces.size()))

	var start_idx: int = -1
	var best_start_score: float = -INF
	for i in range(provinces.size()):
		var area: float = areas[i]
		if area < avg_area * LevelConfig.GRAND_MAP_START_AREA_MIN_FACTOR:
			continue
		var centroid: Vector2 = centroids[i]
		var score: float = centroid.x * 1.2 + centroid.y * 0.15 + gen_rng.randf() * 30.0
		if score > best_start_score:
			best_start_score = score
			start_idx = i
	if start_idx == -1:
		start_idx = provinces.size() - 1

	provinces[start_idx]["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
	provinces[start_idx]["buildings"] = LevelConfig.PROVINCE_FRIENDLY_BUILDINGS
	provinces[start_idx]["troops"] = LevelConfig.get_runtime_initial_province_friendly_troops_for_level(level_index)
	provinces[start_idx]["faction_id"] = 0

	var distances: Dictionary = _compute_graph_distances_from(provinces, start_idx)
	var enemy_candidates: Array[int] = []
	for i in range(provinces.size()):
		if i == start_idx:
			continue
		enemy_candidates.append(i)
	enemy_candidates.sort_custom(func(a: int, b: int) -> bool:
		var da: int = int(distances.get(a, -1))
		var db: int = int(distances.get(b, -1))
		if da == db:
			return centroids[a].x < centroids[b].x
		return da > db
	)

	var chosen_enemy_indices: Array[int] = []
	if not enemy_candidates.is_empty():
		chosen_enemy_indices.append(enemy_candidates[0])

	for candidate in enemy_candidates:
		if chosen_enemy_indices.size() >= LevelConfig.ENEMY_FACTION_COUNT:
			break
		if chosen_enemy_indices.has(candidate):
			continue
		var candidate_distance: int = int(distances.get(candidate, 0))
		if candidate_distance < LevelConfig.GRAND_MAP_ENEMY_START_MIN_GRAPH_DISTANCE:
			continue
		var okay: bool = true
		for chosen in chosen_enemy_indices:
			var sep: int = _graph_distance_between(provinces, chosen, candidate)
			if sep >= 0 and sep < 2:
				okay = false
				break
		if okay:
			chosen_enemy_indices.append(candidate)

	for idx in range(chosen_enemy_indices.size()):
		var province_idx: int = chosen_enemy_indices[idx]
		provinces[province_idx]["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
		provinces[province_idx]["buildings"] = LevelConfig.PROVINCE_ENEMY_BUILDINGS
		provinces[province_idx]["troops"] = LevelConfig.PROVINCE_ENEMY_TROOPS
		provinces[province_idx]["faction_id"] = idx + 1

	var target_idx: int = _select_target_province_index(provinces, start_idx, gen_rng)
	if target_idx >= 0:
		provinces[target_idx]["is_target"] = true
		provinces[target_idx]["type"] = LevelConfig.PROVINCE_TYPE_NEUTRAL
		provinces[target_idx]["buildings"] = LevelConfig.PROVINCE_NEUTRAL_BUILDINGS
		provinces[target_idx]["troops"] = LevelConfig.PROVINCE_NEUTRAL_TROOPS
		provinces[target_idx]["faction_id"] = 0


func _polygon_vertex_average(poly: PackedVector2Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var sum: Vector2 = Vector2.ZERO
	for p in poly:
		sum += p
	return sum / float(poly.size())


func _graph_distance_between(provinces: Array[Dictionary], a_idx: int, b_idx: int) -> int:
	var distances: Dictionary = _compute_graph_distances_from(provinces, a_idx)
	return int(distances.get(b_idx, -1))


func _build_mountain_bands_from_land_mask(land_mask: Array, cols: int, rows: int, playable_half: Vector2, gen_rng: RandomNumberGenerator) -> Array[Dictionary]:
	var mountains: Array[Dictionary] = []
	var cell_w: float = (playable_half.x * 2.0) / float(cols)
	var cell_h: float = (playable_half.y * 2.0) / float(rows)
	for r in range(rows):
		var c: int = 0
		while c < cols:
			if bool(land_mask[r][c]):
				c += 1
				continue
			var start_c: int = c
			while c + 1 < cols and not bool(land_mask[r][c + 1]):
				c += 1
			var end_c: int = c
			var poly: PackedVector2Array = _make_mountain_band_polygon(r, start_c, end_c, cell_w, cell_h, playable_half)
			poly = _densify_polygon(poly, 8)
			mountains.append({
				"polygon": poly,
				"shade": Color(0.24 + gen_rng.randf() * 0.06, 0.25 + gen_rng.randf() * 0.05, 0.28 + gen_rng.randf() * 0.05, 0.98),
				"ridge": Color(0.44, 0.46, 0.50, 0.26),
				"row": r,
				"start_c": start_c,
				"end_c": end_c
			})
			c += 1
	return mountains


func _make_mountain_band_polygon(row: int, start_c: int, end_c: int, cell_w: float, cell_h: float, playable_half: Vector2) -> PackedVector2Array:
	var x0: float = -playable_half.x + float(start_c) * cell_w
	var x1: float = -playable_half.x + float(end_c + 1) * cell_w
	var y0: float = -playable_half.y + float(row) * cell_h
	var y1: float = y0 + cell_h
	return PackedVector2Array([
		Vector2(x0, y0),
		Vector2(x1, y0),
		Vector2(x1, y1),
		Vector2(x0, y1)
	])


func _densify_polygon(poly: PackedVector2Array, min_points: int) -> PackedVector2Array:
	var out: PackedVector2Array = poly
	while out.size() < min_points and out.size() >= 3:
		var next: PackedVector2Array = PackedVector2Array()
		for i in range(out.size()):
			var a: Vector2 = out[i]
			var b: Vector2 = out[(i + 1) % out.size()]
			next.append(a)
			next.append(a.lerp(b, 0.5))
		out = next
	return out

func _select_target_province_index(provinces: Array[Dictionary], start_idx: int, gen_rng: RandomNumberGenerator) -> int:
	if provinces.is_empty() or start_idx < 0 or start_idx >= provinces.size():
		return -1

	var distances: Dictionary = _compute_graph_distances_from(provinces, start_idx)
	var preferred: Array[int] = []
	var neutral_fallback: Array[int] = []

	for i in range(provinces.size()):
		if i == start_idx:
			continue
		var province_type: String = str(provinces[i].get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		if province_type != LevelConfig.PROVINCE_TYPE_NEUTRAL:
			continue
		neutral_fallback.append(i)
		var distance := int(distances.get(i, -1))
		if distance >= LevelConfig.TARGET_PROVINCE_MIN_GRAPH_DISTANCE_FROM_START:
			preferred.append(i)

	if not preferred.is_empty():
		return _pick_target_candidate_by_distance(preferred, distances, gen_rng)
	if not neutral_fallback.is_empty():
		return _pick_target_candidate_by_distance(neutral_fallback, distances, gen_rng)
	return -1

func _pick_target_candidate_by_distance(candidates: Array[int], distances: Dictionary, gen_rng: RandomNumberGenerator) -> int:
	if candidates.is_empty():
		return -1
	if not LevelConfig.TARGET_PROVINCE_PREFER_FARTHEST_FROM_START:
		return candidates[gen_rng.randi_range(0, candidates.size() - 1)]

	var best_distance: int = -1
	var best: Array[int] = []
	for candidate in candidates:
		var dist := int(distances.get(candidate, -1))
		if dist > best_distance:
			best_distance = dist
			best.clear()
			best.append(candidate)
		elif dist == best_distance:
			best.append(candidate)

	if best.is_empty():
		return candidates[gen_rng.randi_range(0, candidates.size() - 1)]
	return best[gen_rng.randi_range(0, best.size() - 1)]

func _compute_graph_distances_from(provinces: Array[Dictionary], start_idx: int) -> Dictionary:
	var distances: Dictionary = {}
	if provinces.is_empty() or start_idx < 0 or start_idx >= provinces.size():
		return distances

	var queue: Array[int] = [start_idx]
	distances[start_idx] = 0
	var head: int = 0

	while head < queue.size():
		var current: int = queue[head]
		head += 1
		var current_distance: int = int(distances.get(current, 0))
		var neighbors_variant = provinces[current].get("neighbors", [])
		for neighbor_any in neighbors_variant:
			var neighbor: int = int(neighbor_any)
			if distances.has(neighbor):
				continue
			distances[neighbor] = current_distance + 1
			queue.append(neighbor)

	return distances

func _template_has_component(tpl: ZoneTemplate, comp_type: int) -> bool:
	for c in tpl.components:
		if int(c.get("type", -1)) == comp_type:
			return true
	return false

func _pick_obstacle_template(gen_rng: RandomNumberGenerator) -> ZoneTemplate:
	var list: Array = ZoneLibrary.get_obstacle_templates()
	if list.is_empty():
		list = ZoneLibrary.get_templates()
	if list.is_empty():
		return ZoneTemplate.new("Empty", [])
	return list[gen_rng.randi_range(0, list.size() - 1)]

func _pick_friction_template(gen_rng: RandomNumberGenerator, want_oil: bool) -> ZoneTemplate:
	var list: Array = ZoneLibrary.get_friction_templates()
	if list.is_empty():
		list = ZoneLibrary.get_templates()
	if list.is_empty():
		return ZoneTemplate.new("Empty", [])

	for k in range(8):
		var t: ZoneTemplate = list[gen_rng.randi_range(0, list.size() - 1)]
		if not _template_has_component(t, ZoneTemplate.ComponentType.FRICTION):
			continue
		var name: String = t.template_name.to_lower()
		if want_oil and name.find("oil") != -1:
			return t
		if (not want_oil) and name.find("grass") != -1:
			return t
	return list[gen_rng.randi_range(0, list.size() - 1)]

func _pick_water_template(gen_rng: RandomNumberGenerator) -> ZoneTemplate:
	var list: Array = ZoneLibrary.get_water_templates()
	if list.is_empty():
		list = ZoneLibrary.get_templates()
	if list.is_empty():
		return ZoneTemplate.new("Empty", [])
	return list[gen_rng.randi_range(0, list.size() - 1)]

func _pick_large_grade_template(gen_rng: RandomNumberGenerator) -> ZoneTemplate:
	var list: Array = ZoneLibrary.get_grade_templates()
	if list.is_empty():
		list = ZoneLibrary.get_templates()

	var large: Array[ZoneTemplate] = []
	for t in list:
		if _template_has_component(t, ZoneTemplate.ComponentType.GRADE):
			large.append(t)
	if large.is_empty():
		return list[0] if not list.is_empty() else ZoneTemplate.new("Empty", [])
	return large[gen_rng.randi_range(0, large.size() - 1)]

func _make_template_placement_with_separation(tpl: ZoneTemplate, interior_half: Vector2, margin: float, gen_rng: RandomNumberGenerator, placed: Array[Dictionary]) -> Dictionary:
	for attempt in range(120):
		var origin: Vector2 = Vector2(
			gen_rng.randf_range(-interior_half.x + margin, interior_half.x - margin),
			gen_rng.randf_range(-interior_half.y + margin, interior_half.y - margin)
		)
		var rot: float = gen_rng.randf_range(0.0, TAU)
		var sc: float = gen_rng.randf_range(LevelConfig.ZONE_SCALE_MIN, LevelConfig.ZONE_SCALE_MAX)

		var too_close: bool = false
		for p in placed:
			if origin.distance_to(p.origin) < ZONE_SEPARATION_BUFFER * 1.2:
				too_close = true
				break
		if too_close:
			continue

		return {
			"template": tpl,
			"origin": origin,
			"rotation": rot,
			"scale": sc
		}
	return {
		"template": tpl,
		"origin": Vector2.ZERO,
		"rotation": 0.0,
		"scale": 1.0
	}

func _record_influence(plc: Dictionary, placed: Array[Dictionary]) -> void:
	placed.append(plc)

func _expand_template_components(plc: Dictionary, obstacles: Array[Dictionary], friction_zones: Array[Dictionary], water_zones: Array[Dictionary], grade_zones: Array[Dictionary], gen_rng: RandomNumberGenerator) -> void:
	var tpl: ZoneTemplate = plc.template
	var origin: Vector2 = plc.origin
	var rot: float = plc.rotation
	var sc: float = plc.scale

	for c in tpl.components:
		var t: int = int(c.get("type", -1))
		var lp: Vector2 = c.get("local_pos", Vector2.ZERO)
		var r: float = float(c.get("radius", 0.0))
		var wp: Vector2 = origin + lp.rotated(rot) * sc
		var wr: float = r * sc

		match t:
			ZoneTemplate.ComponentType.FRICTION:
				var mu: float = float(c.get("mu", LevelConfig.FRICTION_DEFAULT))
				var aspect: float = float(c.get("aspect", 1.0))
				friction_zones.append({"pos": wp, "radius": wr, "mu": mu, "aspect": aspect})
			ZoneTemplate.ComponentType.GRADE:
				var accel: Vector2 = c.get("accel", Vector2.ZERO)
				grade_zones.append({"pos": wp, "radius": wr, "accel": accel.rotated(rot)})
			ZoneTemplate.ComponentType.WATER:
				var aspect: float = float(c.get("aspect", 1.0))
				water_zones.append({"pos": wp, "radius": wr, "aspect": aspect})
			ZoneTemplate.ComponentType.OBSTACLE:
				obstacles.append({"pos": wp, "radius": wr})

func _make_large_grade_placement(tpl: ZoneTemplate, interior_half: Vector2, gen_rng: RandomNumberGenerator) -> Dictionary:
	for attempt in range(80):
		var origin: Vector2 = Vector2(
			gen_rng.randf_range(-interior_half.x * 0.7, interior_half.x * 0.7),
			gen_rng.randf_range(-interior_half.y * 0.7, interior_half.y * 0.7)
		)
		var rot: float = gen_rng.randf_range(0.0, TAU)
		var sc: float = gen_rng.randf_range(LevelConfig.GRADE_SCALE_MIN, LevelConfig.GRADE_SCALE_MAX)

		return {
			"template": tpl,
			"origin": origin,
			"rotation": rot,
			"scale": sc
		}
	return {
		"template": tpl,
		"origin": Vector2.ZERO,
		"rotation": 0.0,
		"scale": 1.0
	}


func _spawn_mountain_band(obstacles_root: Node2D, mountain_data: Dictionary) -> void:
	if obstacles_root == null or not is_instance_valid(obstacles_root):
		return
	var poly: PackedVector2Array = mountain_data.get("polygon", PackedVector2Array())
	if poly.size() < 3:
		return

	var mountain := StaticBody2D.new()
	mountain.z_index = LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES
	mountain.collision_layer = LevelConfig.MASK_WALLS
	mountain.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
	mountain.set_meta("is_mountain", true)

	var mat := PhysicsMaterial.new()
	mat.friction = 0.15
	mat.bounce = 0.42
	mountain.physics_material_override = mat

	var collision := CollisionPolygon2D.new()
	collision.polygon = poly
	mountain.add_child(collision)

	var fill := Polygon2D.new()
	fill.polygon = poly
	fill.color = mountain_data.get("shade", Color(0.26, 0.28, 0.31, 0.98))
	fill.z_index = 0
	mountain.add_child(fill)

	var border := Line2D.new()
	border.points = poly
	border.closed = true
	border.width = 3.0
	border.default_color = Color(0.10, 0.12, 0.14, 0.92)
	border.antialiased = true
	border.z_index = 1
	mountain.add_child(border)

	var bounds: Rect2 = _polygon_bounds(poly)
	var peak_count: int = clampi(int(round(bounds.size.x / 280.0)), 1, 6)
	for i in range(peak_count):
		var ridge := Polygon2D.new()
		var t: float = (float(i) + 0.5) / float(peak_count)
		var mid_x: float = lerpf(bounds.position.x + 18.0, bounds.end.x - 18.0, t)
		var peak_w: float = maxf(34.0, bounds.size.x / float(peak_count) * 0.35)
		var peak_h: float = maxf(20.0, bounds.size.y * 0.58)
		var ridge_top: float = bounds.position.y + bounds.size.y * 0.18
		var ridge_bottom: float = bounds.position.y + bounds.size.y * 0.88
		ridge.polygon = PackedVector2Array([
			Vector2(mid_x - peak_w, ridge_bottom),
			Vector2(mid_x, ridge_top),
			Vector2(mid_x + peak_w, ridge_bottom)
		])
		ridge.color = mountain_data.get("ridge", Color(0.44, 0.46, 0.50, 0.24))
		ridge.z_index = 2
		mountain.add_child(ridge)

	obstacles_root.add_child(mountain)


func _polygon_bounds(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var min_x: float = poly[0].x
	var max_x: float = poly[0].x
	var min_y: float = poly[0].y
	var max_y: float = poly[0].y
	for p in poly:
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func _place_pins(layout: Dictionary, pin_count: int, level_index: int, gen_rng: RandomNumberGenerator, phase: String = "defensive") -> Array[Dictionary]:
	if phase == "grand_map" or pin_count <= 0:
		return []

	if (phase == LevelConfig.PHASE_OFFENSIVE or phase == LevelConfig.PHASE_NEUTRAL) and layout.has("pin_groups"):
		return _place_structured_pins(layout, pin_count, level_index, gen_rng, phase)

	var interior_half: Vector2 = layout.get("interior_half", LevelConfig.PLAYABLE_HALF_EXTENTS)
	var obstacles: Array = layout.get("obstacles", [])
	var water_zones: Array = layout.get("water_zones", [])

	var is_milestone: bool = _is_milestone(level_index)
	var cluster_count: int = gen_rng.randi_range(2, 4)
	var cluster_radius: float = LevelConfig.PIN_CLUSTER_RADIUS
	if is_milestone:
		cluster_count = gen_rng.randi_range(3, 6)
		cluster_radius *= 0.78

	var cluster_centers: Array[Vector2] = []
	for i in range(cluster_count):
		cluster_centers.append(_random_open_point(interior_half, obstacles, water_zones, gen_rng))

	var attempts_per_pin: int = 80
	var pins_data: Array[Dictionary] = []
	for i in range(pin_count):
		var placed: bool = false
		for t in range(attempts_per_pin):
			var use_cluster: bool = gen_rng.randf() < 0.85 and not cluster_centers.is_empty()
			var p: Vector2
			if use_cluster:
				var c: Vector2 = cluster_centers[gen_rng.randi_range(0, cluster_centers.size() - 1)]
				var dx: float = gen_rng.randfn(0.0, float(cluster_radius) * 0.35)
				var dy: float = gen_rng.randfn(0.0, float(cluster_radius) * 0.35)
				p = c + Vector2(dx, dy)
			else:
				p = _random_open_point(interior_half, obstacles, water_zones, gen_rng)

			p.x = clamp(p.x, -interior_half.x + LevelConfig.PIN_SPAWN_MARGIN, interior_half.x - LevelConfig.PIN_SPAWN_MARGIN)
			p.y = clamp(p.y, -interior_half.y + LevelConfig.PIN_SPAWN_MARGIN, interior_half.y - LevelConfig.PIN_SPAWN_MARGIN)

			if not _point_clear_of_obstacles(p, obstacles):
				continue
			if not _point_clear_of_water(p, water_zones, LevelConfig.PIN_BODY_WIDTH * 0.55):
				continue
			if not _point_clear_of_enemies(p, pins_data):
				continue

			var etype: String = _pick_enemy_type(level_index, gen_rng, is_milestone)
			pins_data.append({"pos": p, "type": etype})
			placed = true
			break

		if not placed:
			var fp: Vector2 = _random_open_point(interior_half, obstacles, water_zones, gen_rng)
			if _point_clear_of_enemies(fp, pins_data) and _point_clear_of_water(fp, water_zones, LevelConfig.PIN_BODY_WIDTH * 0.55):
				var etype: String = _pick_enemy_type(level_index, gen_rng, is_milestone)
				pins_data.append({"pos": fp, "type": etype})

	if is_milestone and phase != "grand_map":
		_enforce_milestone_guarantees(pins_data, level_index, gen_rng)

	return pins_data

func _place_structured_pins(layout: Dictionary, pin_count: int, level_index: int, gen_rng: RandomNumberGenerator, phase: String) -> Array[Dictionary]:
	var interior_half: Vector2 = layout.get("interior_half", LevelConfig.PLAYABLE_HALF_EXTENTS)
	var obstacles: Array = layout.get("obstacles", [])
	var water_zones: Array = layout.get("water_zones", [])
	var pin_groups: Array = layout.get("pin_groups", [])
	var building_anchors: Array = layout.get("building_anchors", [])
	var is_milestone: bool = _is_milestone(level_index)

	if pin_groups.is_empty():
		return []

	var counts: Array = _allocate_group_counts(pin_count, pin_groups, gen_rng)
	var pins_data: Array[Dictionary] = []

	for group_idx in range(pin_groups.size()):
		var group: Dictionary = pin_groups[group_idx]
		var group_count: int = counts[group_idx]
		var center: Vector2 = group.get("center", Vector2.ZERO)
		var radius: float = float(group.get("radius", LevelConfig.PIN_CLUSTER_RADIUS * 0.5))
		var role: String = String(group.get("role", ROLE_EXPOSED))

		for i in range(group_count):
			var placed: bool = false
			for attempt in range(90):
				var p: Vector2 = center + Vector2(
					gen_rng.randfn(0.0, radius * 0.32),
					gen_rng.randfn(0.0, radius * 0.32)
				)
				p = _clamp_point_to_interior(p, interior_half, LevelConfig.PIN_SPAWN_MARGIN)

				if not _point_clear_of_obstacles(p, obstacles):
					continue
				if not _point_clear_of_water(p, water_zones, LevelConfig.PIN_BODY_WIDTH * 0.55):
					continue
				if not _point_clear_of_enemies(p, pins_data):
					continue
				if not _point_clear_of_building_anchors(p, building_anchors, BUILDING_ANCHOR_CLEARANCE):
					continue

				var etype := _pick_enemy_type_for_role(level_index, gen_rng, is_milestone, phase, role)
				pins_data.append({"pos": p, "type": etype})
				placed = true
				break

			if not placed:
				for fallback_attempt in range(40):
					var fp: Vector2 = _random_open_point(interior_half, obstacles, water_zones, gen_rng)
					if fp == Vector2.ZERO:
						continue
					if not _point_clear_of_enemies(fp, pins_data):
						continue
					if not _point_clear_of_building_anchors(fp, building_anchors, BUILDING_ANCHOR_CLEARANCE):
						continue
					var ftype := _pick_enemy_type_for_role(level_index, gen_rng, is_milestone, phase, role)
					pins_data.append({"pos": fp, "type": ftype})
					break

	if is_milestone:
		_enforce_milestone_guarantees(pins_data, level_index, gen_rng)

	return pins_data

func _allocate_group_counts(pin_count: int, pin_groups: Array, gen_rng: RandomNumberGenerator) -> Array[int]:
	var counts: Array[int] = []
	for i in range(pin_groups.size()):
		counts.append(0)
	if pin_count <= 0 or pin_groups.is_empty():
		return counts

	var sorted_indices: Array[int] = []
	for i in range(pin_groups.size()):
		sorted_indices.append(i)
	sorted_indices.sort_custom(func(a, b):
		return float(pin_groups[a].get("weight", 1.0)) > float(pin_groups[b].get("weight", 1.0))
	)

	var seed_groups := mini(pin_count, sorted_indices.size())
	for i in range(seed_groups):
		counts[sorted_indices[i]] += 1

	var remaining := pin_count - seed_groups
	var total_weight := 0.0
	for group_any in pin_groups:
		var group: Dictionary = group_any
		total_weight += float(group.get("weight", 1.0))
	if total_weight <= 0.0:
		total_weight = float(pin_groups.size())

	for i in range(remaining):
		var roll := gen_rng.randf() * total_weight
		var accum := 0.0
		for idx in range(pin_groups.size()):
			var group: Dictionary = pin_groups[idx]
			accum += float(group.get("weight", 1.0))
			if roll <= accum:
				counts[idx] += 1
				break

	return counts

func _get_enemy_weights(level_index: int, is_milestone: bool) -> Dictionary:
	var weights := {
		LevelConfig.ENEMY_PIN: LevelConfig.ENEMY_WEIGHT_PIN,
		LevelConfig.ENEMY_HEAVY_PIN: LevelConfig.ENEMY_WEIGHT_HEAVY_PIN,
		LevelConfig.ENEMY_SPIKY_PIN: LevelConfig.ENEMY_WEIGHT_SPIKY_PIN,
		LevelConfig.ENEMY_RUNNER: LevelConfig.ENEMY_WEIGHT_RUNNER,
		LevelConfig.ENEMY_CHIEF: LevelConfig.ENEMY_WEIGHT_CHIEF,
	}
	return weights

func _roll_enemy_type_from_weights(weights: Dictionary, gen_rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for w in weights.values():
		total += float(w)
	if total <= 0.0:
		return LevelConfig.ENEMY_PIN
	var roll := gen_rng.randf() * total
	var accum := 0.0
	for t in LevelConfig.ENEMY_DIFFICULTY_ORDER:
		accum += float(weights.get(t, 0.0))
		if roll <= accum:
			return t
	return LevelConfig.ENEMY_PIN

func _pick_enemy_type(level_index: int, gen_rng: RandomNumberGenerator, is_milestone: bool) -> String:
	return _pick_enemy_type_for_role(level_index, gen_rng, is_milestone, LevelConfig.PHASE_DEFENSIVE, ROLE_EXPOSED)

func _pick_enemy_type_for_role(level_index: int, gen_rng: RandomNumberGenerator, is_milestone: bool, phase: String, role: String) -> String:
	var weights := _get_enemy_weights(level_index, is_milestone)

	if phase == LevelConfig.PHASE_OFFENSIVE:
		weights[LevelConfig.ENEMY_HEAVY_PIN] *= LevelConfig.ENEMY_OFFENSE_HEAVY_ROLE_WEIGHT_MULTIPLIER
		weights[LevelConfig.ENEMY_SPIKY_PIN] *= LevelConfig.ENEMY_OFFENSE_SPIKY_ROLE_WEIGHT_MULTIPLIER
		weights[LevelConfig.ENEMY_RUNNER] *= LevelConfig.ENEMY_OFFENSE_RUNNER_ROLE_WEIGHT_MULTIPLIER
		weights[LevelConfig.ENEMY_CHIEF] *= LevelConfig.ENEMY_OFFENSE_CHIEF_ROLE_WEIGHT_MULTIPLIER

		match role:
			ROLE_CORE:
				weights[LevelConfig.ENEMY_PIN] *= 0.78
				weights[LevelConfig.ENEMY_HEAVY_PIN] *= 1.28
				weights[LevelConfig.ENEMY_SPIKY_PIN] *= 1.15
				weights[LevelConfig.ENEMY_RUNNER] *= 0.52
				weights[LevelConfig.ENEMY_CHIEF] *= 1.08
			ROLE_GUARD:
				weights[LevelConfig.ENEMY_PIN] *= 0.90
				weights[LevelConfig.ENEMY_HEAVY_PIN] *= 1.18
				weights[LevelConfig.ENEMY_SPIKY_PIN] *= 1.06
				weights[LevelConfig.ENEMY_RUNNER] *= 0.60
				weights[LevelConfig.ENEMY_CHIEF] *= 0.92
			ROLE_LANE:
				weights[LevelConfig.ENEMY_PIN] *= 0.95
				weights[LevelConfig.ENEMY_HEAVY_PIN] *= 1.10
				weights[LevelConfig.ENEMY_SPIKY_PIN] *= 0.82
				weights[LevelConfig.ENEMY_RUNNER] *= 0.50
				weights[LevelConfig.ENEMY_CHIEF] *= 0.62
			ROLE_SUPPORT:
				weights[LevelConfig.ENEMY_PIN] *= 1.00
				weights[LevelConfig.ENEMY_HEAVY_PIN] *= 1.06
				weights[LevelConfig.ENEMY_SPIKY_PIN] *= 0.90
				weights[LevelConfig.ENEMY_RUNNER] *= 0.58
				weights[LevelConfig.ENEMY_CHIEF] *= 0.72
			ROLE_EXPOSED, ROLE_DECOY, ROLE_SPLIT:
				weights[LevelConfig.ENEMY_PIN] *= 1.28
				weights[LevelConfig.ENEMY_HEAVY_PIN] *= 0.94
				weights[LevelConfig.ENEMY_SPIKY_PIN] *= 0.68
				weights[LevelConfig.ENEMY_RUNNER] *= 0.36
				weights[LevelConfig.ENEMY_CHIEF] *= 0.38

	elif phase == LevelConfig.PHASE_NEUTRAL:
		weights[LevelConfig.ENEMY_HEAVY_PIN] *= LevelConfig.NEUTRAL_OFFENSE_HEAVY_ROLE_WEIGHT_MULTIPLIER
		weights[LevelConfig.ENEMY_SPIKY_PIN] *= LevelConfig.NEUTRAL_OFFENSE_SPIKY_ROLE_WEIGHT_MULTIPLIER
		weights[LevelConfig.ENEMY_RUNNER] *= LevelConfig.NEUTRAL_OFFENSE_RUNNER_ROLE_WEIGHT_MULTIPLIER
		weights[LevelConfig.ENEMY_CHIEF] *= LevelConfig.NEUTRAL_OFFENSE_CHIEF_ROLE_WEIGHT_MULTIPLIER
		weights[LevelConfig.ENEMY_PIN] *= 1.18

		match role:
			ROLE_EXPOSED:
				weights[LevelConfig.ENEMY_PIN] *= 1.26
				weights[LevelConfig.ENEMY_HEAVY_PIN] *= 0.90
				weights[LevelConfig.ENEMY_SPIKY_PIN] *= 0.55
				weights[LevelConfig.ENEMY_RUNNER] *= 0.45
				weights[LevelConfig.ENEMY_CHIEF] *= 0.30
			ROLE_POCKET, ROLE_LANE:
				weights[LevelConfig.ENEMY_PIN] *= 1.12
				weights[LevelConfig.ENEMY_HEAVY_PIN] *= 0.95
				weights[LevelConfig.ENEMY_SPIKY_PIN] *= 0.62
				weights[LevelConfig.ENEMY_RUNNER] *= 0.50
				weights[LevelConfig.ENEMY_CHIEF] *= 0.34
			ROLE_DECOY, ROLE_SPLIT:
				weights[LevelConfig.ENEMY_PIN] *= 1.22
				weights[LevelConfig.ENEMY_HEAVY_PIN] *= 0.84
				weights[LevelConfig.ENEMY_SPIKY_PIN] *= 0.48
				weights[LevelConfig.ENEMY_RUNNER] *= 0.38
				weights[LevelConfig.ENEMY_CHIEF] *= 0.28

	return _roll_enemy_type_from_weights(weights, gen_rng)

func _enforce_milestone_guarantees(pins_data: Array[Dictionary], level_index: int, gen_rng: RandomNumberGenerator) -> void:
	return

func _place_buildings(layout: Dictionary, buildings_count: int, gen_rng: RandomNumberGenerator) -> Array[Dictionary]:
	var phase: String = layout.get("phase", LevelConfig.PHASE_DEFENSIVE)
	if phase == LevelConfig.PHASE_OFFENSIVE:
		return []
	var building_size_mult: float = LevelConfig.get_building_size_multiplier_for_phase(phase)

	var interior_half: Vector2 = layout.get("interior_half", LevelConfig.PLAYABLE_HALF_EXTENTS)
	var obstacles: Array = layout.get("obstacles", [])
	var water_zones: Array = layout.get("water_zones", [])
	var pins_data: Array = layout.get("pins", [])

	var building_data: Array[Dictionary] = []
	var attempts := 120

	for i in range(buildings_count):
		var placed: bool = false
		for t in range(attempts):
			var p := _random_open_point(interior_half, obstacles, water_zones, gen_rng)
			if p == Vector2.ZERO:
				continue

			p.x = clamp(p.x, -interior_half.x + 140.0, interior_half.x - 140.0)
			p.y = clamp(p.y, -interior_half.y + 140.0, interior_half.y - 140.0)

			if not _point_clear_of_obstacles(p, obstacles):
				continue
			if not _point_clear_of_water(p, water_zones, 90.0):
				continue
			if not _point_clear_of_buildings(p, building_data):
				continue
			if not _point_clear_of_enemies(p, pins_data, BUILDING_CLEARANCE_FROM_PINS):
				continue

			building_data.append(_make_building_entry(p, gen_rng, building_size_mult))
			placed = true
			break

		if not placed:
			var fp: Vector2 = _random_open_point(interior_half, obstacles, water_zones, gen_rng)
			if fp != Vector2.ZERO:
				building_data.append(_make_building_entry(fp, gen_rng, building_size_mult, true))

	return building_data

func _place_structured_buildings(layout: Dictionary, buildings_count: int, gen_rng: RandomNumberGenerator) -> Array[Dictionary]:
	var phase: String = layout.get("phase", LevelConfig.PHASE_DEFENSIVE)
	var building_size_mult: float = LevelConfig.get_building_size_multiplier_for_phase(phase)
	var interior_half: Vector2 = layout.get("interior_half", LevelConfig.PLAYABLE_HALF_EXTENTS)
	var obstacles: Array = layout.get("obstacles", [])
	var water_zones: Array = layout.get("water_zones", [])
	var pins_data: Array = layout.get("pins", [])
	var anchors: Array = layout.get("building_anchors", [])

	var building_data: Array[Dictionary] = []
	if anchors.is_empty():
		return building_data

	var anchor_indices: Array[int] = []
	for i in range(anchors.size()):
		anchor_indices.append(i)

	for i in range(mini(buildings_count, anchor_indices.size())):
		var anchor: Vector2 = anchors[anchor_indices[i]]
		var placed: bool = false
		for attempt in range(22):
			var p: Vector2 = anchor + Vector2(
				gen_rng.randf_range(-18.0, 18.0),
				gen_rng.randf_range(-18.0, 18.0)
			)
			p = _clamp_point_to_interior(p, interior_half, 140.0)
			if not _point_clear_of_obstacles(p, obstacles):
				continue
			if not _point_clear_of_water(p, water_zones, 90.0):
				continue
			if not _point_clear_of_buildings(p, building_data):
				continue
			if not _point_clear_of_enemies(p, pins_data, maxf(BUILDING_CLEARANCE_FROM_PINS - 18.0, 60.0)):
				continue
			building_data.append(_make_building_entry(p, gen_rng, building_size_mult))
			placed = true
			break

		if not placed:
			for ring_attempt in range(28):
				var angle := gen_rng.randf_range(0.0, TAU)
				var dist := gen_rng.randf_range(20.0, 56.0)
				var fallback_p: Vector2 = _clamp_point_to_interior(anchor + Vector2.RIGHT.rotated(angle) * dist, interior_half, 140.0)
				if not _point_clear_of_obstacles(fallback_p, obstacles):
					continue
				if not _point_clear_of_water(fallback_p, water_zones, 90.0):
					continue
				if not _point_clear_of_buildings(fallback_p, building_data):
					continue
				if not _point_clear_of_enemies(fallback_p, pins_data, maxf(BUILDING_CLEARANCE_FROM_PINS - 18.0, 60.0)):
					continue
				building_data.append(_make_building_entry(fallback_p, gen_rng, building_size_mult))
				placed = true
				break

	var remainder := buildings_count - building_data.size()
	if remainder > 0:
		var fallback_layout := layout.duplicate(true)
		fallback_layout["phase"] = LevelConfig.PHASE_DEFENSIVE
		fallback_layout["pins"] = pins_data
		var extras := _place_buildings(fallback_layout, remainder, gen_rng)
		for b in extras:
			if _point_clear_of_buildings(b.get("pos", Vector2.ZERO), building_data):
				building_data.append(b)

	return building_data

func _make_building_entry(p: Vector2, gen_rng: RandomNumberGenerator, building_size_mult: float = 1.0, compact: bool = false) -> Dictionary:
	var safe_building_size_mult: float = maxf(0.05, building_size_mult)
	var w := 85.0 * safe_building_size_mult
	var h := 115.0 * safe_building_size_mult
	if not compact:
		w = gen_rng.randf_range(LevelConfig.BUILDING_WIDTH_MIN, LevelConfig.BUILDING_WIDTH_MAX) * safe_building_size_mult
		h = gen_rng.randf_range(LevelConfig.BUILDING_HEIGHT_MIN, LevelConfig.BUILDING_HEIGHT_MAX) * safe_building_size_mult
	var col := LevelConfig.BUILDING_BASE_COLOR.lightened(gen_rng.randf_range(-0.15, 0.15))
	var num_windows := 2 + (gen_rng.randi() % 3)
	var sprite_variant: int = 0
	if not BUILDING_SPRITE_PATHS.is_empty():
		sprite_variant = int(gen_rng.randi() % BUILDING_SPRITE_PATHS.size())
	return {
		"pos": p,
		"width": w,
		"height": h,
		"color": col,
		"windows": num_windows,
		"sprite_variant": sprite_variant,
		"sprite_flip_h": bool(gen_rng.randi() & 1)
	}

func _get_building_sprite_texture(variant_index: int) -> Texture2D:
	if BUILDING_SPRITE_PATHS.is_empty():
		return null
	var safe_index: int = wrapi(variant_index, 0, BUILDING_SPRITE_PATHS.size())
	if _building_sprite_cache.has(safe_index):
		return _building_sprite_cache[safe_index] as Texture2D
	var path: String = BUILDING_SPRITE_PATHS[safe_index]
	var tex: Texture2D = load(path) as Texture2D
	_building_sprite_cache[safe_index] = tex
	return tex

func _point_clear_of_buildings(p: Vector2, buildings: Array[Dictionary]) -> bool:
	for b in buildings:
		if p.distance_to(b.pos) < BUILDING_MIN_SEPARATION:
			return false
	return true

func _point_clear_of_building_anchors(p: Vector2, anchors: Array, clearance: float) -> bool:
	for a_any in anchors:
		var a: Vector2 = a_any
		if p.distance_to(a) < clearance:
			return false
	return true

func _random_open_point(interior_half: Vector2, obstacles: Array, water_zones: Array, gen_rng: RandomNumberGenerator) -> Vector2:
	for i in range(120):
		var p := Vector2(
			gen_rng.randf_range(-interior_half.x + LevelConfig.PIN_SPAWN_MARGIN, interior_half.x - LevelConfig.PIN_SPAWN_MARGIN),
			gen_rng.randf_range(-interior_half.y + LevelConfig.PIN_SPAWN_MARGIN, interior_half.y - LevelConfig.PIN_SPAWN_MARGIN)
		)
		if _point_clear_of_obstacles(p, obstacles) and _point_clear_of_water(p, water_zones, LevelConfig.PIN_BODY_WIDTH * 0.55):
			return p
	return Vector2.ZERO

func _point_clear_of_obstacles(p: Vector2, obstacles: Array) -> bool:
	for o in obstacles:
		var c: Vector2 = o.get("pos", Vector2.ZERO)
		var r: float = float(o.get("radius", 0.0)) + PIN_OBSTACLE_CLEARANCE
		if p.distance_to(c) <= r:
			return false
	return true

func _point_clear_of_water(p: Vector2, water_zones: Array, body_radius: float = 0.0) -> bool:
	for wz in water_zones:
		if _point_inside_water_with_clearance(p, wz, body_radius + LevelConfig.WATER_SPAWN_CLEARANCE):
			return false
	return true

func _point_inside_water_with_clearance(p: Vector2, water_zone: Dictionary, clearance: float = 0.0) -> bool:
	var center: Vector2 = water_zone.get("pos", Vector2.ZERO)
	var base_radius := float(water_zone.get("radius", 0.0)) + clearance
	var aspect := maxf(0.42, float(water_zone.get("aspect", 1.0)))

	var rx := base_radius * maxf(1.0, aspect)
	var ry := base_radius / maxf(0.42, aspect * 0.92)

	if rx <= 0.001 or ry <= 0.001:
		return false

	var d: Vector2 = p - center
	var nx := d.x / rx
	var ny := d.y / ry
	return (nx * nx + ny * ny) <= 1.0

func _point_clear_of_enemies(p: Vector2, enemies: Array[Dictionary], extra_clearance: float = 0.0) -> bool:
	for e in enemies:
		var q: Vector2 = e.get("pos", Vector2.ZERO)
		if p.distance_to(q) < (float(LevelConfig.PIN_MIN_SEPARATION) + extra_clearance):
			return false
	return true

func _get_polygon_visual_center(poly: PackedVector2Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	var count := 0
	var limit := poly.size()
	if poly.size() >= 2 and poly[0].distance_to(poly[poly.size() - 1]) <= 0.01:
		limit -= 1
	for i in range(limit):
		sum += poly[i]
		count += 1
	if count <= 0:
		return Vector2.ZERO
	return sum / float(count)

func _apply_visual_layer_to_node(node: Node, layer_value: int) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is CanvasItem:
		var canvas_item: CanvasItem = node as CanvasItem
		canvas_item.z_as_relative = false
		canvas_item.z_index = layer_value


func _apply_visual_layer_recursive(node: Node, layer_value: int) -> void:
	if node == null or not is_instance_valid(node):
		return
	_apply_visual_layer_to_node(node, layer_value)
	for child in node.get_children():
		_apply_visual_layer_recursive(child, layer_value)



func _get_trimmed_ui_texture(path: String, allow_trim: bool = true) -> Texture2D:
	var cache_key := "%s|%s" % [path, "trim" if allow_trim else "raw"]
	if _province_ui_texture_cache.has(cache_key):
		return _province_ui_texture_cache[cache_key]
	var loaded = load(path)
	if loaded == null or not (loaded is Texture2D):
		_province_ui_texture_cache[cache_key] = null
		return null
	var texture: Texture2D = loaded as Texture2D
	var resolved: Texture2D = texture
	if allow_trim:
		var image: Image = texture.get_image()
		if image != null:
			var used_rect: Rect2i = image.get_used_rect()
			if used_rect.size.x > 0 and used_rect.size.y > 0 and (used_rect.position.x != 0 or used_rect.position.y != 0 or used_rect.size.x != image.get_width() or used_rect.size.y != image.get_height()):
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(float(used_rect.position.x), float(used_rect.position.y), float(used_rect.size.x), float(used_rect.size.y))
				resolved = atlas
	_province_ui_texture_cache[cache_key] = resolved
	return resolved
func _get_province_info_panel_size() -> Vector2:
	var desired_width: float = maxf(64.0, LevelConfig.PROVINCE_INFO_PANEL_DESIRED_WIDTH)
	var fallback_height: float = maxf(48.0, LevelConfig.PROVINCE_INFO_PANEL_FALLBACK_HEIGHT)
	var panel_texture: Texture2D = _get_trimmed_ui_texture(PROVINCE_INFO_PANEL_TEXTURE_PATH, true)
	if panel_texture == null:
		return Vector2(desired_width, fallback_height)
	var texture_size: Vector2 = panel_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2(desired_width, fallback_height)
	var scaled_height: float = desired_width * (texture_size.y / texture_size.x)
	return Vector2(desired_width, maxf(fallback_height, scaled_height))
func _build_owner_state(province_type: String, faction_id: int) -> Dictionary:
	return {"type": String(province_type), "faction_id": int(faction_id)}


func _get_province_owner_badge_texture_path(province_type: String, faction_id: int) -> String:
	var relation: String = _province_system_display_helper.get_relation_to_player(String(province_type), int(faction_id))
	if relation == _province_system_display_helper.RELATION_HOSTILE:
		return PROVINCE_OWNER_BADGE_ENEMY_TEXTURE_PATH
	if relation == _province_system_display_helper.RELATION_NEUTRAL:
		return PROVINCE_OWNER_BADGE_NEUTRAL_TEXTURE_PATH
	return PROVINCE_OWNER_BADGE_FRIENDLY_TEXTURE_PATH


func _get_province_owner_badge_fill_color(province_type: String, faction_id: int) -> Color:
	var relation: String = _province_system_display_helper.get_relation_to_player(String(province_type), int(faction_id))
	if relation == _province_system_display_helper.RELATION_HOSTILE:
		return LevelConfig.color_with_alpha(LevelConfig.get_enemy_faction_color(faction_id), 1.0)
	if relation == _province_system_display_helper.RELATION_NEUTRAL:
		return LevelConfig.color_with_alpha(LevelConfig.PROVINCE_NEUTRAL_BORDER_COLOR, 1.0)
	return LevelConfig.color_with_alpha(LevelConfig.PROVINCE_FRIENDLY_FILL_RGB, 1.0)


func _get_province_owner_badge_fill_shader() -> Shader:
	if _province_owner_badge_fill_shader != null:
		return _province_owner_badge_fill_shader
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float white_threshold = 0.82;
uniform float chroma_threshold = 0.18;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float max_c = max(tex.r, max(tex.g, tex.b));
	float min_c = min(tex.r, min(tex.g, tex.b));
	float chroma = max_c - min_c;
	bool tint_fill = tex.a > 0.001 && min_c >= white_threshold && chroma <= chroma_threshold;
	if (tint_fill) {
		float value = clamp((tex.r + tex.g + tex.b) / 3.0, 0.0, 1.0);
		vec3 shaded = clamp(fill_color.rgb * mix(0.82, 1.05, value), 0.0, 1.0);
		COLOR = vec4(shaded, tex.a * fill_color.a);
	} else {
		COLOR = tex;
	}
}
"""
	_province_owner_badge_fill_shader = shader
	return _province_owner_badge_fill_shader


func _apply_province_owner_badge_fill(icon: TextureRect, province_type: String, faction_id: int) -> void:
	if icon == null:
		return
	var material := icon.material as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		icon.material = material
	material.shader = _get_province_owner_badge_fill_shader()
	material.set_shader_parameter("fill_color", _get_province_owner_badge_fill_color(province_type, faction_id))


func _get_province_biome_texture_path(engagement_map_type: String) -> String:
	match LevelConfig.normalize_engagement_map_type(engagement_map_type):
		LevelConfig.ENGAGEMENT_MAP_TYPE_JUNGLE:
			return PROVINCE_ICON_BIOME_JUNGLE_TEXTURE_PATH
		LevelConfig.ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING:
			return PROVINCE_ICON_BIOME_ROCK_TEXTURE_PATH
		LevelConfig.ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return PROVINCE_ICON_BIOME_SETTLEMENT_TEXTURE_PATH
		_:
			return PROVINCE_ICON_BIOME_NORMAL_TEXTURE_PATH
func _get_province_panel_icon_texture(texture_path: String) -> Texture2D:
	return _get_trimmed_ui_texture(texture_path, LevelConfig.PROVINCE_INFO_PANEL_TRIM_ICON_TEXTURES)


func _get_province_panel_stat_icon_scale(icon_name: String) -> float:
	match icon_name:
		PROVINCE_INFO_PANEL_TROOPS_ICON_NAME:
			return LevelConfig.PROVINCE_INFO_PANEL_TROOPS_ICON_SCALE
		PROVINCE_INFO_PANEL_BUILDINGS_ICON_NAME:
			return LevelConfig.PROVINCE_INFO_PANEL_BUILDINGS_ICON_SCALE
		PROVINCE_INFO_PANEL_GOLD_ICON_NAME:
			return LevelConfig.PROVINCE_INFO_PANEL_GOLD_ICON_SCALE
		PROVINCE_INFO_PANEL_FREE_ICON_NAME:
			return LevelConfig.PROVINCE_INFO_PANEL_FREE_ICON_SCALE
		PROVINCE_INFO_PANEL_CAP_ICON_NAME:
			return LevelConfig.PROVINCE_INFO_PANEL_CAP_ICON_SCALE
		_:
			return LevelConfig.PROVINCE_INFO_PANEL_STAT_ICON_SCALE_DEFAULT


func _layout_province_panel_icon(icon: TextureRect, position: Vector2, slot_size: Vector2, visual_scale: float = 1.0) -> void:
	if icon == null:
		return
	var safe_slot := Vector2(maxf(1.0, slot_size.x), maxf(1.0, slot_size.y))
	var safe_scale: float = clampf(visual_scale, 0.05, 1.0)
	var visual_size := safe_slot * safe_scale
	icon.position = position + (safe_slot - visual_size) * 0.5
	icon.size = visual_size
	icon.custom_minimum_size = Vector2.ZERO
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.clip_contents = true
	if LevelConfig.PROVINCE_INFO_PANEL_FORCE_ICON_IGNORE_TEXTURE_SIZE:
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	else:
		icon.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED



func _configure_province_panel_label(label: Label, font_size: int, font_color: Color, h_align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, v_align: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER) -> void:
	if label == null:
		return
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.horizontal_alignment = h_align
	label.vertical_alignment = v_align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_constant_override("outline_size", max(1, LevelConfig.PROVINCE_INFO_OUTLINE_SIZE))
	label.add_theme_color_override("font_outline_color", LevelConfig.PROVINCE_INFO_OUTLINE_COLOR)


func _fit_province_panel_icon(slot: Control, texture_path: String, visual_scale: float = 1.0) -> void:
	if slot == null:
		return
	var texture: Texture2D = _get_province_panel_icon_texture(texture_path)
	var safe_scale: float = clampf(visual_scale, 0.05, 1.0)
	if slot is TextureRect:
		var rect: TextureRect = slot as TextureRect
		rect.texture = texture
		_layout_province_panel_icon(rect, Vector2.ZERO, rect.size, safe_scale)
		return
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.clip_contents = true
	var content: TextureRect = slot.get_node_or_null(PROVINCE_INFO_PANEL_ICON_CONTENT_NAME) as TextureRect
	if content == null:
		content = TextureRect.new()
		content.name = PROVINCE_INFO_PANEL_ICON_CONTENT_NAME
		slot.add_child(content)
	content.texture = texture
	_layout_province_panel_icon(content, Vector2.ZERO, slot.size, safe_scale)
func _create_province_panel_icon(name: String, texture_path: String, position: Vector2, slot_size: Vector2, visual_scale: float = 1.0) -> Control:
	var icon := TextureRect.new()
	icon.name = name
	icon.texture = _get_province_panel_icon_texture(texture_path)
	_layout_province_panel_icon(icon, position, slot_size, visual_scale)
	return icon
func _create_province_panel_stat_label(name: String, position: Vector2, size: Vector2) -> Label:
	var label := Label.new()
	label.name = name
	label.position = position
	label.size = size
	_configure_province_panel_label(label, max(11, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE - 3), LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	return label
func _get_province_panel_owner_line(province_type: String, faction_id: int, is_target: bool, invading_troops: int, is_boss_home: bool, province_id: int = -1) -> String:
	var parts: Array[String] = []
	if is_target:
		parts.append(LevelConfig.TARGET_PROVINCE_LABEL_TEXT)
	parts.append(_format_province_owner_text(province_type, faction_id))
	return " - ".join(parts)

func _format_province_counts_text(troops: int, buildings: int, invading_troops: int = 0, province_type: String = LevelConfig.PROVINCE_TYPE_NEUTRAL) -> String:
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
		return "T:%d  B:%d  INV:%d" % [troops, buildings, invading_troops]
	return "T:%d  B:%d" % [troops, buildings]

func _format_province_owner_text(province_type: String, faction_id: int = 0) -> String:
	return _province_system_display_helper.get_province_owner_text(_build_owner_state(province_type, faction_id))


func _get_province_panel_bg_color(province_type: String, faction_id: int, is_target: bool, is_boss_home: bool) -> Color:
	var base_color: Color = Color(1.0, 1.0, 1.0, 1.0)
	if is_boss_home:
		base_color = Color(1.0, 0.94, 0.94, 1.0)
	elif is_target:
		base_color = Color(1.0, 0.98, 0.92, 1.0)

	match province_type:
		LevelConfig.PROVINCE_TYPE_FRIENDLY:
			var friendly_tint: Color = LevelConfig.color_with_alpha(LevelConfig.PROVINCE_FRIENDLY_FILL_RGB, 1.0)
			base_color = base_color.lerp(friendly_tint, 0.08)
		LevelConfig.PROVINCE_TYPE_ENEMY:
			var enemy_tint: Color = LevelConfig.color_with_alpha(LevelConfig.get_enemy_faction_color(faction_id), 1.0)
			var tint_weight: float = 0.22 if is_boss_home else 0.12
			base_color = base_color.lerp(enemy_tint, tint_weight)
		_:
			pass

	base_color.a = LevelConfig.get_province_info_panel_bg_alpha()
	return base_color


func _get_province_panel_owner_color(province_type: String, faction_id: int, is_boss_home: bool) -> Color:
	if is_boss_home:
		var boss_color: Color = LevelConfig.color_with_alpha(LevelConfig.get_enemy_faction_color(faction_id), 1.0)
		return boss_color.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.30)
	match province_type:
		LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return Color(0.88, 0.98, 0.88, 1.0)
		LevelConfig.PROVINCE_TYPE_ENEMY:
			var enemy_color: Color = LevelConfig.color_with_alpha(LevelConfig.get_enemy_faction_color(faction_id), 1.0)
			return enemy_color.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.42)
		_:
			return LevelConfig.PROVINCE_INFO_TEXT_COLOR

func _format_province_info_text(province_id: int, troops: int, buildings: int, invading_troops: int = 0, province_type: String = LevelConfig.PROVINCE_TYPE_NEUTRAL, faction_id: int = 0, is_target: bool = false, gold_production: int = 0, free_buildings: int = 0, building_capacity: int = LevelConfig.PROVINCE_BUILDING_CAP_MIN, engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL) -> String:
	var lines: Array[String] = []
	if is_target:
		lines.append(LevelConfig.TARGET_PROVINCE_LABEL_TEXT)
	lines.append(_format_province_owner_text(province_type, faction_id))
	lines.append("Province %d" % province_id)
	lines.append("--  --")
	lines.append("--  --")
	lines.append("--")
	return "\n".join(lines)

func _add_province_counts_display(province_node: Node2D, poly: PackedVector2Array, province_id: int, troops: int, buildings: int, invading_troops: int = 0, province_type: String = LevelConfig.PROVINCE_TYPE_NEUTRAL, faction_id: int = 0, is_target: bool = false, gold_production: int = 0, free_buildings: int = 0, building_capacity: int = LevelConfig.PROVINCE_BUILDING_CAP_MIN, engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL, is_boss_home: bool = false, province_name: String = "") -> void:
	if province_node == null:
		return
	var center := _get_polygon_visual_center(poly)
	var panel_size: Vector2 = _get_province_info_panel_size()
	var panel_root := Control.new()
	panel_root.name = PROVINCE_INFO_PANEL_ROOT_NAME
	panel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_root.clip_contents = true
	panel_root.position = center - panel_size * 0.5
	panel_root.size = panel_size
	panel_root.z_as_relative = false
	panel_root.z_index = LevelConfig.VISUAL_LAYER_PROVINCE_INFO_CARDS
	province_node.add_child(panel_root)

	var bg := TextureRect.new()
	bg.name = PROVINCE_INFO_PANEL_BG_NAME
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.clip_contents = true
	bg.texture = _get_trimmed_ui_texture(PROVINCE_INFO_PANEL_TEXTURE_PATH, true)
	bg.position = Vector2.ZERO
	bg.size = panel_size
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	var bg_color: Color = _get_province_panel_bg_color(province_type, faction_id, is_target, is_boss_home)
	bg.modulate = bg_color
	panel_root.add_child(bg)

	var owner_badge_pos: Vector2 = LevelConfig.PROVINCE_INFO_PANEL_OWNER_BADGE_POS
	var owner_badge_size: Vector2 = LevelConfig.PROVINCE_INFO_PANEL_OWNER_BADGE_SLOT_SIZE
	var owner_badge := _create_province_panel_icon(PROVINCE_INFO_PANEL_OWNER_BADGE_NAME, _get_province_owner_badge_texture_path(province_type, faction_id), owner_badge_pos, owner_badge_size, LevelConfig.PROVINCE_INFO_PANEL_OWNER_BADGE_SCALE) as TextureRect
	_apply_province_owner_badge_fill(owner_badge, province_type, faction_id)
	panel_root.add_child(owner_badge)

	var biome_slot_size: Vector2 = LevelConfig.PROVINCE_INFO_PANEL_BIOME_ICON_SLOT_SIZE
	var biome_pos := Vector2(panel_size.x - LevelConfig.PROVINCE_INFO_PANEL_BIOME_ICON_RIGHT_MARGIN - biome_slot_size.x, LevelConfig.PROVINCE_INFO_PANEL_BIOME_ICON_TOP)
	var biome_icon := _create_province_panel_icon(PROVINCE_INFO_PANEL_BIOME_ICON_NAME, _get_province_biome_texture_path(engagement_map_type), biome_pos, biome_slot_size, LevelConfig.PROVINCE_INFO_PANEL_BIOME_ICON_SCALE)
	biome_icon.visible = false
	panel_root.add_child(biome_icon)

	var owner_label := Label.new()
	owner_label.name = PROVINCE_INFO_PANEL_OWNER_LABEL_NAME
	owner_label.position = LevelConfig.PROVINCE_INFO_PANEL_OWNER_LABEL_POS
	owner_label.size = Vector2(maxf(24.0, panel_size.x - LevelConfig.PROVINCE_INFO_PANEL_OWNER_LABEL_POS.x - LevelConfig.PROVINCE_INFO_PANEL_OWNER_LABEL_RIGHT_MARGIN), 16.0)
	var owner_color: Color = _get_province_panel_owner_color(province_type, faction_id, is_boss_home)
	_configure_province_panel_label(owner_label, max(11, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE - 5), owner_color, HORIZONTAL_ALIGNMENT_LEFT)
	owner_label.text = _get_province_panel_owner_line(province_type, faction_id, is_target, invading_troops, is_boss_home, province_id)
	panel_root.add_child(owner_label)

	var show_invaders: bool = province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0
	var invaders_icon := _create_province_panel_icon(PROVINCE_INFO_PANEL_INVADERS_ICON_NAME, PROVINCE_ICON_INVADERS_TEXTURE_PATH, LevelConfig.PROVINCE_INFO_PANEL_INVADERS_ICON_POS, LevelConfig.PROVINCE_INFO_PANEL_INVADERS_ICON_SLOT_SIZE, LevelConfig.PROVINCE_INFO_PANEL_INVADERS_ICON_SCALE)
	invaders_icon.visible = show_invaders
	panel_root.add_child(invaders_icon)

	var invaders_label := Label.new()
	invaders_label.name = PROVINCE_INFO_PANEL_INVADERS_LABEL_NAME
	invaders_label.position = LevelConfig.PROVINCE_INFO_PANEL_INVADERS_LABEL_POS
	invaders_label.size = LevelConfig.PROVINCE_INFO_PANEL_INVADERS_LABEL_SIZE
	_configure_province_panel_label(invaders_label, max(11, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE - 5), LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	invaders_label.text = str(max(0, invading_troops))
	invaders_label.visible = show_invaders
	panel_root.add_child(invaders_label)

	var name_label := Label.new()
	name_label.name = PROVINCE_INFO_PANEL_NAME_LABEL_NAME
	name_label.position = LevelConfig.PROVINCE_INFO_PANEL_NAME_LABEL_POS
	name_label.size = Vector2(maxf(24.0, panel_size.x - LevelConfig.PROVINCE_INFO_PANEL_NAME_LABEL_POS.x - LevelConfig.PROVINCE_INFO_PANEL_NAME_LABEL_RIGHT_MARGIN), 24.0)
	_configure_province_panel_label(name_label, max(13, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE - 1), LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.text = _get_province_display_name(province_name, province_id)
	panel_root.add_child(name_label)

	var row_y: float = 60.0
	var row_gap: float = 32.0
	var slot_size := Vector2(31.0, 31.0)
	var happiness_slot_size := Vector2(28.0, 28.0)
	var food_slot_size := Vector2(28.0, 28.0)
	var primary_icon_x: float = 17.0
	var primary_label_x: float = 55.0
	var happiness_icon_x: float = 104.0
	var happiness_label_x: float = 137.0
	var food_icon_x: float = panel_size.x - 64.0
	var food_label_x: float = panel_size.x - 37.0
	var primary_label_size := Vector2(48.0, 27.0)
	var happiness_label_size := Vector2(50.0, 27.0)

	panel_root.add_child(_create_province_panel_icon(PROVINCE_INFO_PANEL_TROOPS_ICON_NAME, PROVINCE_ICON_NATIVE_TEXTURE_PATH, Vector2(primary_icon_x, row_y), slot_size, 1.0))
	var troops_label := _create_province_panel_stat_label(PROVINCE_INFO_PANEL_TROOPS_LABEL_NAME, Vector2(primary_label_x, row_y + 2.0), primary_label_size)
	troops_label.text = "--"
	panel_root.add_child(troops_label)

	var buildings_icon := _create_province_panel_icon(PROVINCE_INFO_PANEL_BUILDINGS_ICON_NAME, PROVINCE_ICON_HAPPINESS_TEXTURE_PATH, Vector2(happiness_icon_x, row_y + 1.0), happiness_slot_size, 1.0)
	buildings_icon.visible = true
	panel_root.add_child(buildings_icon)
	var buildings_label := _create_province_panel_stat_label(PROVINCE_INFO_PANEL_BUILDINGS_LABEL_NAME, Vector2(happiness_label_x, row_y + 2.0), happiness_label_size)
	buildings_label.text = "--"
	buildings_label.visible = true
	panel_root.add_child(buildings_label)

	panel_root.add_child(_create_province_panel_icon(PROVINCE_INFO_PANEL_GOLD_ICON_NAME, PROVINCE_ICON_FOOD_SURPLUS_TEXTURE_PATH, Vector2(food_icon_x, 7.0), food_slot_size, 1.0))
	var gold_label := _create_province_panel_stat_label(PROVINCE_INFO_PANEL_GOLD_LABEL_NAME, Vector2(food_label_x, 10.0), Vector2(36.0, 20.0))
	gold_label.text = "--"
	panel_root.add_child(gold_label)

	var free_icon := _create_province_panel_icon(PROVINCE_INFO_PANEL_FREE_ICON_NAME, PROVINCE_ICON_HAPPINESS_TEXTURE_PATH, Vector2(happiness_icon_x, row_y + row_gap + 1.0), happiness_slot_size, 1.0)
	free_icon.visible = true
	panel_root.add_child(free_icon)
	var free_label := _create_province_panel_stat_label(PROVINCE_INFO_PANEL_FREE_LABEL_NAME, Vector2(happiness_label_x, row_y + row_gap + 2.0), happiness_label_size)
	free_label.text = "--"
	free_label.visible = true
	panel_root.add_child(free_label)

	panel_root.add_child(_create_province_panel_icon(PROVINCE_INFO_PANEL_CAP_ICON_NAME, PROVINCE_ICON_OUTLANDER_TEXTURE_PATH, Vector2(primary_icon_x, row_y + row_gap), slot_size, 1.0))
	var cap_label := _create_province_panel_stat_label(PROVINCE_INFO_PANEL_CAP_LABEL_NAME, Vector2(primary_label_x, row_y + row_gap + 2.0), primary_label_size)
	cap_label.text = "--"
	panel_root.add_child(cap_label)
func _instance_layout(layout: Dictionary, zones_root: Node2D, obstacles_root: Node2D, pins_root: Node2D, provinces_root: Node2D = null) -> void:
	_apply_visual_layer_to_node(zones_root, LevelConfig.VISUAL_LAYER_SAND)
	_apply_visual_layer_to_node(obstacles_root, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
	_apply_visual_layer_to_node(pins_root, LevelConfig.VISUAL_LAYER_TROOPS)
	_apply_visual_layer_to_node(provinces_root, LevelConfig.VISUAL_LAYER_PROVINCE_FILL)
	var placements: Array = layout.get("templates", [])
	for p in placements:
		var tpl: ZoneTemplate = p.get("template", null)
		if tpl == null:
			continue
		var origin: Vector2 = p.get("origin", Vector2.ZERO)
		var rot: float = float(p.get("rotation", 0.0))
		var sc: float = float(p.get("scale", 1.0))
		tpl.spawn_into(zones_root, obstacles_root, origin, rot, sc)

	var province_data: Array = layout.get("provinces", [])
	var mountain_data: Array = layout.get("mountains", [])
	if province_data.is_empty():
		for m in mountain_data:
			_spawn_mountain_band(obstacles_root, m)

	var pins_data: Array = layout.get("pins", [])
	for data in pins_data:
		var pos: Vector2 = data.get("pos", Vector2.ZERO)
		var etype: String = data.get("type", LevelConfig.ENEMY_PIN)

		var packed: PackedScene = _get_pin_scene_for_type(etype)
		var enemy = packed.instantiate()
		pins_root.add_child(enemy)
		(enemy as Node2D).global_position = pos
		if enemy is CanvasItem:
			(enemy as CanvasItem).z_as_relative = false
			(enemy as CanvasItem).z_index = LevelConfig.VISUAL_LAYER_TROOPS

		if enemy is RigidBody2D:
			(enemy as RigidBody2D).linear_velocity = Vector2.ZERO
			(enemy as RigidBody2D).angular_velocity = 0.0

		enemy.add_to_group("pins")

		if enemy is Chief:
			enemy.call_deferred("_capture_spawn_anchor")

	var layout_phase: String = layout.get("phase", LevelConfig.PHASE_DEFENSIVE)
	var building_data: Array = layout.get("buildings", [])
	if layout_phase == LevelConfig.PHASE_OFFENSIVE:
		building_data = []
	for b in building_data:
		var pos: Vector2 = b.pos
		var w: float = b.width
		var h: float = b.height
		var base_col: Color = b.color
		var num_windows: int = b.get("windows", 2)

		var building := StaticBody2D.new()
		building.z_as_relative = false
		building.z_index = LevelConfig.VISUAL_LAYER_BUILDINGS
		building.global_position = pos
		building.collision_layer = LevelConfig.MASK_WALLS
		building.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS

		var mat := PhysicsMaterial.new()
		mat.friction = 0.0
		mat.bounce = LevelConfig.BUILDING_BOUNCE
		building.physics_material_override = mat

		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(w * 0.92, h * 0.88)
		cs.shape = shape
		building.add_child(cs)

		var sprite_variant: int = int(b.get("sprite_variant", 0))
		var sprite_texture: Texture2D = _get_building_sprite_texture(sprite_variant)
		if sprite_texture != null:
			var shadow := Polygon2D.new()
			shadow.color = Color(0, 0, 0, 0.18)
			shadow.polygon = PackedVector2Array([
				Vector2(-w * 0.40, h * 0.38),
				Vector2(w * 0.40, h * 0.38),
				Vector2(w * 0.28, h * 0.50),
				Vector2(-w * 0.28, h * 0.50)
			])
			building.add_child(shadow)

			var sprite := Sprite2D.new()
			sprite.texture = sprite_texture
			sprite.centered = true
			sprite.flip_h = bool(b.get("sprite_flip_h", false))
			var tex_size: Vector2 = sprite_texture.get_size()
			if tex_size.x > 0.0 and tex_size.y > 0.0:
				var sx: float = w / tex_size.x
				var sy: float = h / tex_size.y
				var uniform_scale: float = minf(sx, sy)
				sprite.scale = Vector2.ONE * uniform_scale
			sprite.position = Vector2(0, -h * 0.06)
			building.add_child(sprite)
		else:
			var base_poly := Polygon2D.new()
			base_poly.color = base_col
			base_poly.polygon = PackedVector2Array([
				Vector2(-w * 0.5, -h * 0.5),
				Vector2(w * 0.5, -h * 0.5),
				Vector2(w * 0.5, h * 0.38),
				Vector2(-w * 0.5, h * 0.38)
			])
			building.add_child(base_poly)

			var roof_poly := Polygon2D.new()
			roof_poly.color = base_col.darkened(LevelConfig.BUILDING_ROOF_DARKEN)
			roof_poly.polygon = PackedVector2Array([
				Vector2(-w * 0.52, -h * 0.5),
				Vector2(w * 0.52, -h * 0.5),
				Vector2(0, -h * 0.92)
			])
			building.add_child(roof_poly)

			for wx in range(num_windows):
				var win := Polygon2D.new()
				win.color = LevelConfig.BUILDING_WINDOW_COLOR
				var wx_pos := -w * 0.35 + wx * (w * 0.7 / float(num_windows))
				win.polygon = PackedVector2Array([
					Vector2(wx_pos - 9, -h * 0.25),
					Vector2(wx_pos + 9, -h * 0.25),
					Vector2(wx_pos + 9, -h * 0.05),
					Vector2(wx_pos - 9, -h * 0.05)
				])
				building.add_child(win)

			var door := Polygon2D.new()
			door.color = LevelConfig.BUILDING_DOOR_COLOR
			door.polygon = PackedVector2Array([
				Vector2(-8, h * 0.35),
				Vector2(8, h * 0.35),
				Vector2(8, h * 0.48),
				Vector2(-8, h * 0.48)
			])
			building.add_child(door)

		building.set_meta("is_building", true)
		building.add_to_group("buildings")
		obstacles_root.add_child(building)

	if provinces_root != null and is_instance_valid(provinces_root) and not province_data.is_empty():
		for p in province_data:
			var poly: PackedVector2Array = p.get("polygon", PackedVector2Array())
			var tint_idx: int = p.get("tint_index", 0)
			var ptype: String = p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)
			var province_id: int = int(p.get("id", -1))
			var troops: int = int(p.get("troops", 0))
			var buildings: int = int(p.get("buildings", 0))
			var invading_troops: int = int(p.get("invading_troops", 0))
			var faction_id: int = int(p.get("faction_id", 0))
			var is_target: bool = bool(p.get("is_target", false))
			var is_boss_home: bool = bool(p.get("is_boss_home", false))
			var province_name: String = String(p.get(PROVINCE_NAME_KEY, "")).strip_edges()
			var gold_production: int = LevelConfig.clamp_province_gold_production(int(p.get(PROVINCE_GOLD_PRODUCTION_KEY, 0)))
			var free_buildings: int = LevelConfig.clamp_province_free_buildings(int(p.get(PROVINCE_FREE_BUILDINGS_KEY, 0)))
			var building_capacity: int = LevelConfig.clamp_province_building_cap(int(p.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN)))
			var engagement_map_type: String = LevelConfig.normalize_engagement_map_type(String(p.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)))

			var province_node := Node2D.new()
			province_node.name = "Province_%d" % province_id
			province_node.z_index = LevelConfig.VISUAL_LAYER_PROVINCE_FILL
			province_node.set_meta("province_data", {
				"id": province_id,
				PROVINCE_NAME_KEY: _get_province_display_name(province_name, province_id),
				"type": ptype,
				"tint_index": tint_idx,
				"troops": troops,
				"buildings": buildings,
				"invading_troops": invading_troops,
				"neighbors": p.get("neighbors", []),
				"faction_id": faction_id,
				"is_target": is_target,
				"is_boss_home": is_boss_home,
				PROVINCE_GOLD_PRODUCTION_KEY: gold_production,
				PROVINCE_FREE_BUILDINGS_KEY: free_buildings,
				PROVINCE_BUILDING_CAPACITY_KEY: building_capacity,
				PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: engagement_map_type
			})
			province_node.set_meta("province_polygon", poly)
			provinces_root.add_child(province_node)

			var display_poly: PackedVector2Array = _collapse_collinear_points(_ensure_polygon_ccw(poly))
			var fill := Polygon2D.new()
			fill.name = "ProvinceFill"
			fill.polygon = display_poly
			province_node.set_meta("province_logical_polygon", poly)
			province_node.set_meta("province_display_polygon", display_poly)
			fill.z_index = 0

			if ptype == LevelConfig.PROVINCE_TYPE_ENEMY:
				fill.color = LevelConfig.get_enemy_faction_color(faction_id)
			elif ptype == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
				fill.color = LevelConfig.get_friendly_invaded_province_fill_color()
			elif ptype == LevelConfig.PROVINCE_TYPE_FRIENDLY:
				fill.color = LevelConfig.get_friendly_province_fill_color()
			else:
				fill.color = LevelConfig.PROVINCE_FILL_COLORS[tint_idx % LevelConfig.PROVINCE_FILL_COLORS.size()]

			province_node.add_child(fill)

			if is_target:
				var target_overlay := Polygon2D.new()
				target_overlay.name = "ProvinceTargetOverlay"
				target_overlay.polygon = display_poly
				target_overlay.color = LevelConfig.TARGET_PROVINCE_FILL_TINT
				target_overlay.z_index = LevelConfig.VISUAL_LAYER_BORDER_OVERLAYS - LevelConfig.VISUAL_LAYER_PROVINCE_FILL
				province_node.add_child(target_overlay)

			var border := Line2D.new()
			border.name = "ProvinceBorder"
			border.width = LevelConfig.PROVINCE_BORDER_WIDTH + (LevelConfig.TARGET_PROVINCE_BORDER_WIDTH_BONUS if is_target else 0.0)
			border.default_color = LevelConfig.TARGET_PROVINCE_BORDER_COLOR if is_target else LevelConfig.PROVINCE_BORDER_COLOR
			border.antialiased = true
			border.closed = true
			var border_points: PackedVector2Array = _make_smoothed_province_display_polyline(display_poly, maxf(0.5, border.width * 0.5))
			border.points = border_points
			border.z_index = LevelConfig.VISUAL_LAYER_BORDERS - LevelConfig.VISUAL_LAYER_PROVINCE_FILL
			province_node.set_meta("province_display_border_points", border_points)
			province_node.add_child(border)

			var inner := Line2D.new()
			inner.name = "ProvinceInnerGlow"
			inner.width = LevelConfig.TARGET_PROVINCE_INNER_GLOW_WIDTH if is_target else 2.8
			inner.default_color = LevelConfig.TARGET_PROVINCE_INNER_GLOW_COLOR if is_target else Color(1.0, 0.96, 0.72, 0.22)
			inner.antialiased = true
			inner.closed = true
			var inner_inset: float = maxf(0.5, border.width * 0.5 + (LevelConfig.TARGET_PROVINCE_INNER_GLOW_WIDTH if is_target else 2.4))
			var inner_points: PackedVector2Array = _make_smoothed_province_display_polyline(display_poly, inner_inset)
			inner.points = inner_points
			inner.z_index = LevelConfig.VISUAL_LAYER_BORDER_OVERLAYS - LevelConfig.VISUAL_LAYER_PROVINCE_FILL
			province_node.set_meta("province_display_inner_points", inner_points)
			province_node.add_child(inner)

			_add_province_counts_display(province_node, poly, province_id, troops, buildings, invading_troops, ptype, faction_id, is_target, gold_production, free_buildings, building_capacity, engagement_map_type, is_boss_home, province_name)

		_spawn_grand_map_outer_barrier(obstacles_root, province_data)


func spawn_persistent_caltrops_for_engagement(province_id: int, caltrops: Array, zones_root: Node2D, obstacles_root: Node2D, pins_root: Node2D = null) -> Array[Dictionary]:
	var placed_results: Array[Dictionary] = []
	if obstacles_root == null or not is_instance_valid(obstacles_root):
		return placed_results

	var hard_blockers: Array[Dictionary] = _collect_caltrop_hard_blockers(obstacles_root)
	var water_blockers: Array[Dictionary] = _collect_caltrop_water_blockers(zones_root)
	var pin_blockers: Array[Dictionary] = _collect_caltrop_pin_blockers(pins_root)

	for caltrop_any in caltrops:
		if not (caltrop_any is Dictionary):
			continue
		var caltrop: Dictionary = caltrop_any
		if bool(caltrop.get("destroyed", false)):
			continue

		var placement: Dictionary = _build_caltrop_placement(caltrop, hard_blockers, water_blockers, pin_blockers)
		if placement.is_empty():
			continue

		var caltrop_id: int = int(caltrop.get("id", -1))
		var node: StaticBody2D = _spawn_caltrop_node(obstacles_root, province_id, caltrop_id, placement)
		if node == null:
			continue

		hard_blockers.append({
			"pos": placement.get("pos", Vector2.ZERO),
			"radius": float(placement.get("clearance_radius", 0.0))
		})

		placed_results.append({
			"province_id": province_id,
			"caltrop_id": caltrop_id,
			"node": node,
			"button_area": node.get_node_or_null("ButtonArea")
		})

	return placed_results


func _build_caltrop_placement(caltrop: Dictionary, hard_blockers: Array[Dictionary], water_blockers: Array[Dictionary], pin_blockers: Array[Dictionary]) -> Dictionary:
	var seed: int = int(caltrop.get("seed", 1))
	if seed == 0:
		seed = int(caltrop.get("id", 1)) + 1

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var spec: Dictionary = _make_caltrop_spec(rng, bool(caltrop.get("is_friendly", false)))
	var interior_half: Vector2 = LevelConfig.PLAYABLE_HALF_EXTENTS
	var margin: float = float(spec.get("clearance_radius", CALTROP_RADIUS_MAX)) + CALTROP_WORLD_MARGIN

	var best_pos: Vector2 = Vector2.ZERO
	var best_score: float = INF
	var found_any: bool = false

	for _attempt in range(CALTROP_PLACEMENT_ATTEMPTS):
		var candidate := Vector2(
			rng.randf_range(-interior_half.x + margin, interior_half.x - margin),
			rng.randf_range(-interior_half.y + margin, interior_half.y - margin)
		)
		var score: float = _score_caltrop_candidate(candidate, float(spec.get("clearance_radius", 0.0)), hard_blockers, water_blockers, pin_blockers)
		if score < best_score:
			best_score = score
			best_pos = candidate
			found_any = true
		if score <= 0.001:
			break

	if not found_any:
		return {}

	var placement: Dictionary = spec.duplicate(true)
	placement["is_friendly"] = bool(caltrop.get("is_friendly", false))
	placement["pos"] = best_pos
	placement["placement_score"] = best_score
	return placement


func _score_caltrop_candidate(candidate: Vector2, clearance_radius: float, hard_blockers: Array[Dictionary], water_blockers: Array[Dictionary], pin_blockers: Array[Dictionary]) -> float:
	var score: float = 0.0

	for blocker in hard_blockers:
		var blocker_pos: Vector2 = blocker.get("pos", Vector2.ZERO)
		var blocker_radius: float = float(blocker.get("radius", 0.0))
		var gap: float = candidate.distance_to(blocker_pos) - (clearance_radius + blocker_radius + CALTROP_HARD_BLOCKER_PADDING)
		if gap < 0.0:
			score += 100000.0 + absf(gap) * 140.0
		elif gap < 36.0:
			score += (36.0 - gap) * 5.0

	for blocker in water_blockers:
		var blocker_pos: Vector2 = blocker.get("pos", Vector2.ZERO)
		var blocker_radius: float = float(blocker.get("radius", 0.0))
		var gap: float = candidate.distance_to(blocker_pos) - (clearance_radius + blocker_radius + CALTROP_WATER_PADDING)
		if gap < 0.0:
			score += 140000.0 + absf(gap) * 180.0
		elif gap < 44.0:
			score += (44.0 - gap) * 6.0

	for blocker in pin_blockers:
		var blocker_pos: Vector2 = blocker.get("pos", Vector2.ZERO)
		var blocker_radius: float = float(blocker.get("radius", LevelConfig.PIN_BODY_WIDTH * 0.5))
		var gap: float = candidate.distance_to(blocker_pos) - (clearance_radius + blocker_radius + CALTROP_SOFT_PIN_PADDING)
		if gap < 0.0:
			score += 120.0 + absf(gap) * 18.0
		elif gap < 18.0:
			score += (18.0 - gap) * 1.2

	score += absf(candidate.x) * 0.002 + absf(candidate.y) * 0.002
	return score


func _collect_caltrop_hard_blockers(obstacles_root: Node2D) -> Array[Dictionary]:
	var blockers: Array[Dictionary] = []
	if obstacles_root == null or not is_instance_valid(obstacles_root):
		return blockers

	for child_any in obstacles_root.get_children():
		var child: Node = child_any
		if not is_instance_valid(child):
			continue
		var blocker: Dictionary = _extract_caltrop_blocker_from_node(child)
		if blocker.is_empty():
			continue
		blockers.append(blocker)

	return blockers


func _extract_caltrop_blocker_from_node(node: Node) -> Dictionary:
	if node == null or not is_instance_valid(node):
		return {}

	if not (node is Node2D):
		return {}

	var node_2d: Node2D = node as Node2D
	var radius: float = 0.0

	if node.has_meta("caltrop_clearance_radius"):
		radius = maxf(radius, float(node.get_meta("caltrop_clearance_radius")))

	for child_any in node.get_children():
		var child: Node = child_any
		if child is CollisionShape2D:
			var shape: Shape2D = (child as CollisionShape2D).shape
			radius = maxf(radius, _approx_shape_radius(shape))
		elif child is CollisionPolygon2D:
			var poly: PackedVector2Array = (child as CollisionPolygon2D).polygon
			for point in poly:
				radius = maxf(radius, point.length())

	if radius <= 0.001:
		return {}

	return {
		"pos": node_2d.global_position,
		"radius": radius
	}


func _collect_caltrop_water_blockers(zones_root: Node2D) -> Array[Dictionary]:
	var blockers: Array[Dictionary] = []
	if zones_root == null or not is_instance_valid(zones_root):
		return blockers

	for child_any in zones_root.get_children():
		if not (child_any is Area2D):
			continue
		var area: Area2D = child_any as Area2D
		if String(area.get_meta("zone_type", "")) != "water":
			continue

		var radius: float = float(area.get_meta("zone_radius", 0.0))
		var aspect: float = maxf(1.0, float(area.get_meta("zone_aspect", 1.0)))
		blockers.append({
			"pos": area.global_position,
			"radius": radius * aspect
		})

	return blockers


func _collect_caltrop_pin_blockers(pins_root: Node2D) -> Array[Dictionary]:
	var blockers: Array[Dictionary] = []
	if pins_root == null or not is_instance_valid(pins_root):
		return blockers

	for child_any in pins_root.get_children():
		if not (child_any is Node2D):
			continue
		var pin_node: Node2D = child_any as Node2D
		blockers.append({
			"pos": pin_node.global_position,
			"radius": LevelConfig.PIN_BODY_WIDTH * 0.44
		})

	return blockers


func _approx_shape_radius(shape: Shape2D) -> float:
	if shape == null:
		return 0.0
	if shape is CircleShape2D:
		return float((shape as CircleShape2D).radius)
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size.length() * 0.5
	if shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = shape as CapsuleShape2D
		return capsule.radius + capsule.height * 0.5
	if shape is SegmentShape2D:
		return ((shape as SegmentShape2D).a - (shape as SegmentShape2D).b).length() * 0.5
	return 0.0



func _get_caltrop_sprite_candidate_paths() -> PackedStringArray:
	return LevelConfig.get_caltrop_sprite_candidate_paths()


func _get_friendly_caltrop_sprite_candidate_paths() -> PackedStringArray:
	return LevelConfig.get_friendly_caltrop_sprite_candidate_paths()


func _get_caltrop_sprite_alpha() -> float:
	return clampf(float(LevelConfig.get_caltrop_sprite_alpha()), 0.0, 1.0)


func _get_caltrop_sprite_scale_min() -> float:
	return maxf(0.05, float(LevelConfig.get_caltrop_sprite_scale_min()))


func _get_caltrop_sprite_scale_max() -> float:
	return maxf(_get_caltrop_sprite_scale_min(), float(LevelConfig.get_caltrop_sprite_scale_max()))


func _load_caltrop_texture(path: String) -> Texture2D:
	var clean_path: String = String(path).strip_edges()
	if clean_path.is_empty():
		return null
	if _caltrop_sprite_texture_cache.has(clean_path):
		var cached: Variant = _caltrop_sprite_texture_cache.get(clean_path, null)
		return cached as Texture2D
	var texture := load(clean_path) as Texture2D
	if texture == null and not clean_path.ends_with(".png"):
		texture = load("%s.png" % clean_path) as Texture2D
	_caltrop_sprite_texture_cache[clean_path] = texture
	return texture


func _is_caltrop_button_red(pixel: Color) -> bool:
	if pixel.a < 0.10:
		return false
	var hue: float = pixel.h
	var sat: float = pixel.s
	var val: float = pixel.v
	return (hue <= 0.05 or hue >= 0.95) and sat >= 0.45 and val >= 0.32


func _vector2i_to_centered_local(point: Vector2i, image_size: Vector2i) -> Vector2:
	return Vector2(
		(float(point.x) + 0.5) - float(image_size.x) * 0.5,
		(float(point.y) + 0.5) - float(image_size.y) * 0.5
	)


func _make_default_caltrop_collision_polygon(image_size: Vector2i) -> PackedVector2Array:
	var half_size := Vector2(float(image_size.x), float(image_size.y)) * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])


func _analyze_caltrop_texture(path: String) -> Dictionary:
	var clean_path: String = String(path).strip_edges()
	if clean_path.is_empty():
		return {}
	if _caltrop_sprite_meta_cache.has(clean_path):
		var cached: Variant = _caltrop_sprite_meta_cache.get(clean_path, {})
		if cached is Dictionary:
			return (cached as Dictionary).duplicate(true)

	var texture: Texture2D = _load_caltrop_texture(clean_path)
	if texture == null:
		return {}

	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return {}

	var image_size: Vector2i = image.get_size()
	if image_size.x <= 0 or image_size.y <= 0:
		return {}

	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, 0.12)
	var poly_rect := Rect2i(Vector2i.ZERO, image_size)
	var opaque_polygons_any: Variant = bitmap.opaque_to_polygons(poly_rect, 1.4)

	var centered_collision_polygons: Array[PackedVector2Array] = []
	if opaque_polygons_any is Array:
		for poly_any in opaque_polygons_any:
			if not (poly_any is PackedVector2Array):
				continue
			var src_poly: PackedVector2Array = poly_any
			if src_poly.size() < 3:
				continue
			var centered_poly := PackedVector2Array()
			for point in src_poly:
				centered_poly.append(Vector2(
					point.x - float(image_size.x) * 0.5,
					point.y - float(image_size.y) * 0.5
				))
			centered_collision_polygons.append(centered_poly)

	if centered_collision_polygons.is_empty():
		centered_collision_polygons.append(_make_default_caltrop_collision_polygon(image_size))

	var button_min := Vector2i(image_size.x, image_size.y)
	var button_max := Vector2i(-1, -1)
	var button_sum := Vector2.ZERO
	var button_count: int = 0

	for y in range(image_size.y):
		for x in range(image_size.x):
			var pixel: Color = image.get_pixel(x, y)
			if not _is_caltrop_button_red(pixel):
				continue
			button_min.x = mini(button_min.x, x)
			button_min.y = mini(button_min.y, y)
			button_max.x = maxi(button_max.x, x)
			button_max.y = maxi(button_max.y, y)
			button_sum += Vector2(float(x) + 0.5, float(y) + 0.5)
			button_count += 1

	var button_center_local: Vector2 = Vector2(0.0, float(image_size.y) * 0.20)
	var button_radius_local: float = maxf(8.0, float(LevelConfig.get_caltrop_button_radius()))
	if button_count > 0:
		var button_center_px: Vector2 = button_sum / float(button_count)
		button_center_local = Vector2(
			button_center_px.x - float(image_size.x) * 0.5,
			button_center_px.y - float(image_size.y) * 0.5
		)
		var button_span_x: float = float(button_max.x - button_min.x + 1)
		var button_span_y: float = float(button_max.y - button_min.y + 1)
		button_radius_local = maxf(6.0, maxf(button_span_x, button_span_y) * 0.5)

	var local_max_radius: float = 0.0
	for poly in centered_collision_polygons:
		for point in poly:
			local_max_radius = maxf(local_max_radius, point.length())
	local_max_radius = maxf(local_max_radius, button_center_local.length() + button_radius_local)

	var meta := {
		"path": clean_path,
		"texture": texture,
		"image_size": image_size,
		"collision_polygons": centered_collision_polygons,
		"button_center_local": button_center_local,
		"button_radius_local": button_radius_local,
		"local_max_radius": local_max_radius
	}
	_caltrop_sprite_meta_cache[clean_path] = meta.duplicate(true)
	return meta.duplicate(true)


func _pick_caltrop_sprite_metadata(rng: RandomNumberGenerator, friendly: bool = false) -> Dictionary:
	var paths: PackedStringArray = _get_friendly_caltrop_sprite_candidate_paths() if friendly else _get_caltrop_sprite_candidate_paths()
	if paths.is_empty():
		return {}
	var clean_paths: Array[String] = []
	for path in paths:
		var clean_path: String = String(path).strip_edges()
		if not clean_path.is_empty():
			clean_paths.append(clean_path)
	if clean_paths.is_empty():
		return {}
	var selected_path: String = clean_paths[rng.randi_range(0, clean_paths.size() - 1)]
	return _analyze_caltrop_texture(selected_path)


func _scale_caltrop_polygons(polygons: Array[PackedVector2Array], scale_value: float) -> Array[PackedVector2Array]:
	var scaled_polygons: Array[PackedVector2Array] = []
	for poly in polygons:
		var scaled_poly := PackedVector2Array()
		for point in poly:
			scaled_poly.append(point * scale_value)
		scaled_polygons.append(scaled_poly)
	return scaled_polygons


func _make_procedural_caltrop_spec(rng: RandomNumberGenerator) -> Dictionary:
	var base_radius: float = rng.randf_range(LevelConfig.get_caltrop_radius_min(), LevelConfig.get_caltrop_radius_max())
	var point_count: int = rng.randi_range(7, 10)
	var angle_offset: float = rng.randf_range(0.0, TAU)

	var poly := PackedVector2Array()
	for i in range(point_count):
		var edge_angle: float = angle_offset + TAU * float(i) / float(point_count)
		edge_angle += rng.randf_range(-TAU / float(point_count) * 0.12, TAU / float(point_count) * 0.12)

		var radial_variation: float = rng.randf_range(0.82, 1.18)
		if i % 2 == 0:
			radial_variation *= rng.randf_range(1.03, 1.16)
		else:
			radial_variation *= rng.randf_range(0.86, 0.98)

		poly.append(Vector2.RIGHT.rotated(edge_angle) * (base_radius * radial_variation))

	var center: Vector2 = _polygon_vertex_average(poly)
	var button_edge_index: int = rng.randi_range(0, point_count - 1)
	var edge_start: Vector2 = poly[button_edge_index]
	var edge_end: Vector2 = poly[(button_edge_index + 1) % point_count]
	var edge_mid: Vector2 = (edge_start + edge_end) * 0.5
	var edge_dir: Vector2 = edge_end - edge_start
	var normal_a := Vector2(-edge_dir.y, edge_dir.x).normalized()
	var normal_b := -normal_a
	var outward_normal: Vector2 = normal_a
	if normal_a.dot(center - edge_mid) > normal_b.dot(center - edge_mid):
		outward_normal = normal_b

	var button_radius: float = LevelConfig.get_caltrop_button_radius()
	var button_local_pos: Vector2 = edge_mid + outward_normal * (button_radius * 0.55)
	var clearance_radius: float = base_radius + button_radius + 10.0
	for point in poly:
		clearance_radius = maxf(clearance_radius, point.length() + 8.0)
	clearance_radius = maxf(clearance_radius, button_local_pos.length() + button_radius + 8.0)

	return {
		"use_sprite": false,
		"polygon": poly,
		"button_local_pos": button_local_pos,
		"button_radius": button_radius,
		"base_radius": base_radius,
		"clearance_radius": clearance_radius
	}


func _make_caltrop_spec(rng: RandomNumberGenerator, friendly: bool = false) -> Dictionary:
	var sprite_meta: Dictionary = _pick_caltrop_sprite_metadata(rng, friendly)
	if not sprite_meta.is_empty():
		var base_radius: float = rng.randf_range(LevelConfig.get_caltrop_radius_min(), LevelConfig.get_caltrop_radius_max())
		var sprite_scale_mult: float = rng.randf_range(_get_caltrop_sprite_scale_min(), _get_caltrop_sprite_scale_max())
		var local_max_radius: float = maxf(1.0, float(sprite_meta.get("local_max_radius", 1.0)))
		var sprite_scale: float = (base_radius / local_max_radius) * sprite_scale_mult
		var collision_polygons_local: Array[PackedVector2Array] = sprite_meta.get("collision_polygons", [])
		var collision_polygons_scaled: Array[PackedVector2Array] = _scale_caltrop_polygons(collision_polygons_local, sprite_scale)
		var button_local_pos: Vector2 = Vector2(sprite_meta.get("button_center_local", Vector2.ZERO)) * sprite_scale
		var button_radius: float = maxf(6.0, float(sprite_meta.get("button_radius_local", 8.0)) * sprite_scale)
		var clearance_radius: float = local_max_radius * sprite_scale
		clearance_radius = maxf(clearance_radius, button_local_pos.length() + button_radius + 8.0)

		return {
			"use_sprite": true,
			"texture_path": String(sprite_meta.get("path", "")),
			"texture": sprite_meta.get("texture", null),
			"sprite_scale": sprite_scale,
			"collision_polygons": collision_polygons_scaled,
			"button_local_pos": button_local_pos,
			"button_radius": button_radius,
			"base_radius": base_radius,
			"clearance_radius": clearance_radius
		}

	return _make_procedural_caltrop_spec(rng)



func _spawn_caltrop_node(parent: Node2D, province_id: int, caltrop_id: int, placement: Dictionary) -> StaticBody2D:
	if parent == null or not is_instance_valid(parent):
		return null

	var root := StaticBody2D.new()
	root.name = "Caltrop_%d_%d" % [province_id, caltrop_id]
	root.z_index = LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES
	root.global_position = placement.get("pos", Vector2.ZERO)
	root.collision_layer = LevelConfig.MASK_WALLS
	root.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS
	root.set_meta("is_caltrop", true)
	root.set_meta("is_friendly_caltrop", bool(placement.get("is_friendly", false)))
	root.set_meta(CALTROP_META_PROVINCE_ID, province_id)
	root.set_meta(CALTROP_META_CALTROP_ID, caltrop_id)
	root.set_meta("caltrop_clearance_radius", float(placement.get("clearance_radius", 0.0)))
	root.add_to_group(CALTROP_GROUP)

	var mat := PhysicsMaterial.new()
	mat.friction = 0.0
	mat.bounce = 0.72
	root.physics_material_override = mat

	var use_sprite: bool = bool(placement.get("use_sprite", false))
	var button_radius: float = maxf(1.0, float(placement.get("button_radius", LevelConfig.get_caltrop_button_radius())))

	if use_sprite:
		var collision_polygons: Array[PackedVector2Array] = placement.get("collision_polygons", [])
		if collision_polygons.is_empty():
			return null

		for poly in collision_polygons:
			if poly.size() < 3:
				continue
			var collision := CollisionPolygon2D.new()
			collision.polygon = poly
			root.add_child(collision)

		var texture: Texture2D = placement.get("texture", null) as Texture2D
		if texture == null:
			texture = _load_caltrop_texture(String(placement.get("texture_path", "")))

		if texture != null:
			var shadow_sprite := Sprite2D.new()
			shadow_sprite.texture = texture
			shadow_sprite.centered = true
			shadow_sprite.scale = Vector2.ONE * float(placement.get("sprite_scale", 1.0))
			shadow_sprite.modulate = Color(0.0, 0.0, 0.0, 0.22)
			shadow_sprite.position = Vector2(5.0, 6.0)
			shadow_sprite.z_index = -1
			root.add_child(shadow_sprite)

			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.centered = true
			sprite.scale = Vector2.ONE * float(placement.get("sprite_scale", 1.0))
			sprite.modulate = Color(1.0, 1.0, 1.0, _get_caltrop_sprite_alpha())
			sprite.z_index = 0
			root.add_child(sprite)
	else:
		var poly: PackedVector2Array = placement.get("polygon", PackedVector2Array())
		if poly.is_empty():
			return null

		var collision := CollisionPolygon2D.new()
		collision.polygon = poly
		root.add_child(collision)

		var shadow := Polygon2D.new()
		shadow.polygon = poly
		shadow.color = Color(0.05, 0.03, 0.03, 0.18)
		shadow.position = Vector2(5.0, 6.0)
		shadow.z_index = -1
		root.add_child(shadow)

		var fill := Polygon2D.new()
		fill.polygon = poly
		fill.color = CALTROP_FILL_COLOR
		fill.z_index = 0
		root.add_child(fill)

		var inner := Polygon2D.new()
		inner.polygon = _caltrop_scale_polygon(poly, Vector2(0.62, 0.62))
		inner.color = CALTROP_INNER_COLOR
		inner.z_index = 1
		root.add_child(inner)

		var outline := Line2D.new()
		outline.closed = true
		outline.width = 5.0
		outline.default_color = CALTROP_EDGE_COLOR
		outline.antialiased = true
		outline.points = poly
		outline.z_index = 2
		root.add_child(outline)

	var button_area := Area2D.new()
	button_area.name = "ButtonArea"
	button_area.position = placement.get("button_local_pos", Vector2.ZERO)
	button_area.collision_layer = LevelConfig.MASK_ZONES
	button_area.collision_mask = LevelConfig.MASK_BALL
	button_area.monitoring = true
	button_area.monitorable = true
	button_area.set_meta("is_caltrop_button", true)
	button_area.set_meta(CALTROP_META_PROVINCE_ID, province_id)
	button_area.set_meta(CALTROP_META_CALTROP_ID, caltrop_id)
	button_area.add_to_group(CALTROP_BUTTON_GROUP)

	var button_cs := CollisionShape2D.new()
	var button_shape := CircleShape2D.new()
	button_shape.radius = button_radius
	button_cs.shape = button_shape
	button_area.add_child(button_cs)

	if not use_sprite:
		var button_fill := Polygon2D.new()
		button_fill.polygon = _make_round_polygon(button_radius, 14)
		button_fill.color = CALTROP_BUTTON_COLOR
		button_fill.z_index = 4
		button_area.add_child(button_fill)

		var button_ring := Line2D.new()
		button_ring.closed = true
		button_ring.width = 3.0
		button_ring.default_color = CALTROP_BUTTON_RING_COLOR
		button_ring.antialiased = true
		button_ring.points = _make_round_polygon(button_radius + 2.0, 14)
		button_ring.z_index = 5
		button_area.add_child(button_ring)

	root.add_child(button_area)
	parent.add_child(root)
	return root


func _caltrop_scale_polygon(points: PackedVector2Array, scale_vec: Vector2) -> PackedVector2Array:
	var scaled := PackedVector2Array()
	for point in points:
		scaled.append(Vector2(point.x * scale_vec.x, point.y * scale_vec.y))
	return scaled


func _make_round_polygon(radius: float, point_count: int = 12) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n: int = maxi(3, point_count)
	for i in range(n):
		var angle: float = TAU * float(i) / float(n)
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points


func clear_boss_visuals(provinces_root: Node2D) -> void:
	if provinces_root == null or not is_instance_valid(provinces_root):
		return
	for child in provinces_root.get_children():
		if not is_instance_valid(child):
			continue
		if String(child.name) == BOSS_VISUAL_ROOT_NAME:
			child.queue_free()


func build_or_refresh_boss_visuals(provinces_root: Node2D, home_polygon: PackedVector2Array, part_state_map: Dictionary = {}, is_friendly_boss: bool = false, use_friendly_invading_sprite: bool = false) -> Node2D:
	if provinces_root == null or not is_instance_valid(provinces_root):
		return null

	clear_boss_visuals(provinces_root)

	if home_polygon.is_empty():
		return null

	var root := BossVisualController.new()
	root.configure(180.0)
	root.name = BOSS_VISUAL_ROOT_NAME
	root.z_as_relative = false
	root.z_index = LevelConfig.VISUAL_LAYER_GRAND_MAP_PROVINCE_TROOPS + 40
	provinces_root.add_child(root)

	var bounds: Rect2 = _boss_compute_polygon_bounds(home_polygon)
	var center: Vector2 = bounds.get_center()
	var scale_size: float = minf(bounds.size.x, bounds.size.y)
	if scale_size <= 1.0:
		scale_size = maxf(bounds.size.x, bounds.size.y)
	if scale_size <= 1.0:
		scale_size = 180.0
	root.configure(scale_size)

	var part_layouts: Dictionary = _make_boss_part_layouts(center, scale_size, part_state_map)
	var fill_colors: Dictionary = {
		"head": BOSS_HEAD_FILL_COLOR,
		"left_arm": BOSS_ARM_FILL_COLOR,
		"right_arm": BOSS_ARM_FILL_COLOR,
		"left_leg": BOSS_LEG_FILL_COLOR,
		"right_leg": BOSS_LEG_FILL_COLOR
	}

	var draw_order: Array[String] = []
	if is_friendly_boss:
		draw_order.append("head")
	else:
		draw_order.append("left_leg")
		draw_order.append("right_leg")
		draw_order.append("left_arm")
		draw_order.append("right_arm")
		draw_order.append("head")
	for part_name in draw_order:
		var layout: Dictionary = part_layouts.get(part_name, {})
		var poly: PackedVector2Array = layout.get("polygon", PackedVector2Array())
		if poly.is_empty():
			continue
		var pivot_point: Vector2 = layout.get("pivot", Vector2.ZERO)
		var collision_points: Array = layout.get("collision_points", [])
		var collision_widths: Array = layout.get("collision_widths", [])
		var destroyed: bool = false
		if part_state_map.has(part_name):
			var part_state: Dictionary = part_state_map.get(part_name, {})
			destroyed = bool(part_state.get("destroyed", false))
		_add_boss_part_visual(root, part_name, poly, pivot_point, Color(fill_colors.get(part_name, BOSS_HEAD_FILL_COLOR)), destroyed, scale_size, collision_points, collision_widths, is_friendly_boss, use_friendly_invading_sprite)

	root.call_deferred("refresh_animation_setup")
	return root


func _add_boss_part_visual(root: Node2D, part_name: String, poly: PackedVector2Array, pivot_point: Vector2, fill_color: Color, destroyed: bool, scale_size: float, collision_points: Array = [], collision_widths: Array = [], is_friendly_boss: bool = false, use_friendly_invading_sprite: bool = false) -> void:
	if root == null or poly.is_empty():
		return

	var local_poly := PackedVector2Array()
	for point in poly:
		local_poly.append(point - pivot_point)

	var local_collision_points: Array[Vector2] = []
	for point in collision_points:
		if point is Vector2:
			local_collision_points.append(point - pivot_point)

	var body := AnimatableBody2D.new()
	body.name = "BossPart_%s" % part_name
	body.position = pivot_point
	body.rotation = 0.0
	body.sync_to_physics = true
	body.collision_layer = LevelConfig.MASK_WALLS if not destroyed else 0
	body.collision_mask = LevelConfig.MASK_BALL | LevelConfig.MASK_PINS if not destroyed else 0
	body.set_meta("is_boss_part", true)
	body.set_meta("boss_destroyed", destroyed)
	body.set_meta("boss_base_position", pivot_point)
	body.set_meta(BOSS_PART_META_KEY, part_name)
	body.add_to_group(BOSS_PART_GROUP)
	body.z_index = 5 if part_name == "head" else 4

	var mat := PhysicsMaterial.new()
	mat.friction = 0.08
	mat.bounce = maxf(0.42, float(LevelConfig.BUILDING_BOUNCE))
	body.physics_material_override = mat

	root.add_child(body)

	var limb_texture: Texture2D = null
	var head_texture: Texture2D = null
	var head_uses_sprite: bool = false
	if part_name == "head":
		var head_image_path: String = _get_boss_head_image_path()
		if is_friendly_boss:
			head_image_path = _get_boss_friendly_invading_image_path() if use_friendly_invading_sprite else _get_boss_friendly_image_path()
		if _get_boss_head_image_enabled() or is_friendly_boss:
			head_texture = _load_boss_texture(head_image_path)
		if head_texture == null and is_friendly_boss:
			head_texture = _load_boss_texture(_get_boss_head_image_path())
		if head_texture != null:
			var head_visual_bounds: Rect2 = _get_boss_head_visual_bounds(local_poly)
			if _add_boss_sprite_collision_shapes(body, head_texture, head_visual_bounds, destroyed):
				head_uses_sprite = true
			else:
				head_texture = null
	elif part_name != "head":
		limb_texture = _load_boss_texture(_get_boss_limb_sprite_path(part_name))
		if limb_texture != null:
			var limb_visual_bounds: Rect2 = _get_boss_sprite_visual_bounds(local_poly, _get_boss_limb_sprite_scale_padding())
			if part_name == "left_leg" or part_name == "right_leg":
				limb_visual_bounds = _get_boss_leg_visual_bounds(local_poly)
			# Grand-map leg sprite textures are already authored in the same handedness as their
			# visual placement. Mirroring the collision silhouette in X inverts the hitboxes.
			# Keep arm behavior untouched and do not affect engagement/home-assault collisions
			# (those are generated through MainLevelFlow.gd).
			var mirror_leg_collision_x: bool = false
			if not _add_boss_sprite_collision_shapes(body, limb_texture, limb_visual_bounds, destroyed, mirror_leg_collision_x):
				limb_texture = null

	if not head_uses_sprite and limb_texture == null:
		if local_collision_points.size() >= 2 and local_collision_points.size() == collision_widths.size():
			_add_boss_segment_collision_shapes(body, local_collision_points, collision_widths, destroyed)
		else:
			var collision := CollisionPolygon2D.new()
			collision.name = "BodyCollision"
			collision.polygon = local_poly
			collision.disabled = destroyed
			body.add_child(collision)

	var swing_root := Node2D.new()
	swing_root.name = "SwingRoot"
	swing_root.position = Vector2.ZERO
	swing_root.rotation = 0.0
	body.add_child(swing_root)

	var added_limb_sprite: bool = false
	var added_head_sprite: bool = false
	if part_name == "head":
		if is_friendly_boss and use_friendly_invading_sprite:
			var invaded_enemy_texture: Texture2D = _load_boss_texture(_get_boss_head_image_path())
			added_head_sprite = _add_dual_boss_head_sprite_visual(swing_root, local_poly, destroyed, head_texture, invaded_enemy_texture)
		if not added_head_sprite:
			added_head_sprite = _add_boss_head_sprite_visual(swing_root, local_poly, destroyed, head_texture)
		if not added_head_sprite:
			var shadow := Polygon2D.new()
			shadow.name = "Shadow"
			shadow.polygon = local_poly
			shadow.color = Color(0.05, 0.01, 0.01, 0.22 if not destroyed else 0.08)
			shadow.position += Vector2(scale_size * 0.018, scale_size * 0.03)
			shadow.z_index = -1
			swing_root.add_child(shadow)

			var fill := Polygon2D.new()
			fill.name = "Fill"
			fill.polygon = local_poly
			fill.color = fill_color if not destroyed else Color(fill_color.r, fill_color.g, fill_color.b, BOSS_PART_DESTROYED_ALPHA)
			fill.z_index = 0
			swing_root.add_child(fill)
			_add_boss_head_image_visual(swing_root, local_poly, destroyed)
	else:
		var shadow := Polygon2D.new()
		shadow.name = "Shadow"
		shadow.polygon = local_poly
		shadow.color = Color(0.05, 0.01, 0.01, 0.22 if not destroyed else 0.08)
		shadow.position += Vector2(scale_size * 0.018, scale_size * 0.03)
		shadow.z_index = -1
		swing_root.add_child(shadow)

		added_limb_sprite = _add_boss_limb_sprite_visual(swing_root, part_name, local_poly, destroyed, limb_texture)
		if not added_limb_sprite:
			var fill := Polygon2D.new()
			fill.name = "Fill"
			fill.polygon = local_poly
			fill.color = fill_color if not destroyed else Color(fill_color.r, fill_color.g, fill_color.b, BOSS_PART_DESTROYED_ALPHA)
			fill.z_index = 0
			swing_root.add_child(fill)

	if destroyed:
		var crack := Line2D.new()
		crack.name = "DestroyedMark"
		crack.width = maxf(2.0, scale_size * 0.01)
		crack.default_color = Color(0.94, 0.84, 0.76, 0.68)
		crack.antialiased = true
		var crack_bounds: Rect2 = _boss_compute_polygon_bounds(local_poly)
		crack.points = PackedVector2Array([
			crack_bounds.position + Vector2(crack_bounds.size.x * 0.18, crack_bounds.size.y * 0.20),
			crack_bounds.position + Vector2(crack_bounds.size.x * 0.52, crack_bounds.size.y * 0.50),
			crack_bounds.position + Vector2(crack_bounds.size.x * 0.82, crack_bounds.size.y * 0.78)
		])
		crack.z_index = 2
		swing_root.add_child(crack)


func _count_destroyed_boss_limbs(part_state_map: Dictionary) -> int:
	var count: int = 0
	for part_name in ["left_arm", "right_arm", "left_leg", "right_leg"]:
		if not part_state_map.has(part_name):
			continue
		var part_state: Dictionary = part_state_map.get(part_name, {})
		if bool(part_state.get("destroyed", false)):
			count += 1
	return count


func _get_level_config_instance():
	if _level_config_instance == null:
		_level_config_instance = LevelConfig.new()
	return _level_config_instance


func _get_pin_scene_for_type(pin_type: String) -> PackedScene:
	var normalized_type: String = String(pin_type).strip_edges()
	if normalized_type.is_empty():
		normalized_type = LevelConfig.ENEMY_PIN
	if _pin_scene_cache.has(normalized_type):
		var cached_scene = _pin_scene_cache.get(normalized_type, null)
		if cached_scene is PackedScene:
			return cached_scene as PackedScene
		return PinScene
	var scene_path := "res://scenes/" + normalized_type + ".tscn"
	var packed := load(scene_path) as PackedScene
	if packed == null:
		packed = PinScene
	_pin_scene_cache[normalized_type] = packed
	return packed


func _get_boss_head_size_scale() -> float:
	var cfg = _get_level_config_instance()
	if cfg != null:
		if cfg.has_method("get_boss_head_size_scale"):
			return maxf(0.01, float(cfg.call("get_boss_head_size_scale")))
		if cfg.has_method("get_boss_head_scale"):
			return maxf(0.01, float(cfg.call("get_boss_head_scale")))
	return 1.0


func _get_boss_arm_size_scale() -> float:
	var cfg = _get_level_config_instance()
	if cfg != null and cfg.has_method("get_boss_arm_size_scale"):
		return maxf(0.10, float(cfg.call("get_boss_arm_size_scale")))
	return 1.0


func _get_boss_leg_size_scale() -> float:
	var cfg = _get_level_config_instance()
	if cfg != null and cfg.has_method("get_boss_leg_size_scale"):
		return maxf(0.10, float(cfg.call("get_boss_leg_size_scale")))
	return 1.0


func _get_boss_head_vertical_offset_factor() -> float:
	var cfg = _get_level_config_instance()
	if cfg != null and cfg.has_method("get_boss_head_vertical_offset_factor"):
		return float(cfg.call("get_boss_head_vertical_offset_factor"))
	return -0.110


func _get_boss_head_image_enabled() -> bool:
	return bool(LevelConfig.get_boss_head_image_enabled())


func _get_boss_head_image_path() -> String:
	return String(LevelConfig.get_boss_head_image_path())


func _get_boss_friendly_image_path() -> String:
	return String(LevelConfig.get_boss_friendly_image_path())


func _get_boss_friendly_invading_image_path() -> String:
	return String(LevelConfig.get_boss_friendly_invading_image_path())


func _get_boss_head_image_scale() -> float:
	return maxf(0.01, float(LevelConfig.get_boss_head_image_scale()))


func _get_boss_head_image_offset() -> Vector2:
	return Vector2(LevelConfig.get_boss_head_image_offset())


func _get_boss_head_image_alpha() -> float:
	return clampf(float(LevelConfig.get_boss_head_image_alpha()), 0.0, 1.0)


func _get_boss_limb_sprite_path(part_name: String) -> String:
	return String(LevelConfig.get_boss_limb_sprite_path(part_name)).strip_edges()


func _get_boss_limb_sprite_alpha() -> float:
	return clampf(float(LevelConfig.get_boss_limb_sprite_alpha()), 0.0, 1.0)


func _get_boss_limb_sprite_scale_padding() -> float:
	return maxf(0.25, float(LevelConfig.get_boss_limb_sprite_scale_padding()))


func _get_boss_head_bumpiness_enabled() -> bool:
	return bool(LevelConfig.get_boss_head_bumpiness_enabled())


func _get_boss_head_bump_count_min() -> int:
	return maxi(0, int(LevelConfig.get_boss_head_bump_count_min()))


func _get_boss_head_bump_count_max() -> int:
	return maxi(_get_boss_head_bump_count_min(), int(LevelConfig.get_boss_head_bump_count_max()))


func _get_boss_head_bump_depth_min() -> float:
	return maxf(0.0, float(LevelConfig.get_boss_head_bump_depth_min()))


func _get_boss_head_bump_depth_max() -> float:
	return maxf(_get_boss_head_bump_depth_min(), float(LevelConfig.get_boss_head_bump_depth_max()))


func _get_boss_head_bump_width_ratio_min() -> float:
	return clampf(float(LevelConfig.get_boss_head_bump_width_ratio_min()), 0.01, 0.49)


func _get_boss_head_bump_width_ratio_max() -> float:
	return clampf(maxf(_get_boss_head_bump_width_ratio_min(), float(LevelConfig.get_boss_head_bump_width_ratio_max())), 0.01, 0.49)


func _get_boss_head_bump_corner_exclusion_ratio() -> float:
	return clampf(float(LevelConfig.get_boss_head_bump_corner_exclusion_ratio()), 0.0, 0.45)


func _get_boss_head_bump_outward_chance() -> float:
	return clampf(float(LevelConfig.get_boss_head_bump_outward_chance()), 0.0, 1.0)


func _get_boss_head_bump_edge_jitter_min() -> float:
	return maxf(0.0, float(LevelConfig.get_boss_head_bump_edge_jitter_min()))


func _get_boss_head_bump_edge_jitter_max() -> float:
	return maxf(_get_boss_head_bump_edge_jitter_min(), float(LevelConfig.get_boss_head_bump_edge_jitter_max()))


func _get_boss_head_bump_min_edge_points() -> int:
	return maxi(2, int(LevelConfig.get_boss_head_bump_min_edge_points()))


func _load_boss_texture(path: String) -> Texture2D:
	var clean_path: String = String(path).strip_edges()
	if clean_path.is_empty():
		return null
	var texture := load(clean_path) as Texture2D
	if texture != null:
		return texture
	if not clean_path.ends_with(".png"):
		texture = load("%s.png" % clean_path) as Texture2D
	return texture


func _get_boss_sprite_visual_bounds(local_poly: PackedVector2Array, padded_bounds_scale: float = 1.0) -> Rect2:
	var poly_bounds: Rect2 = _boss_compute_polygon_bounds(local_poly)
	if poly_bounds.size.x <= 0.0 or poly_bounds.size.y <= 0.0:
		return Rect2()
	var padded_scale: float = maxf(0.01, padded_bounds_scale)
	var padded_size: Vector2 = poly_bounds.size * padded_scale
	var padded_pos: Vector2 = poly_bounds.get_center() - (padded_size * 0.5)
	return Rect2(padded_pos, padded_size)


func _add_boss_sprite_collision_shapes(parent_node: Node, texture: Texture2D, visual_bounds: Rect2, destroyed: bool, mirror_x: bool = false) -> bool:
	if parent_node == null or texture == null:
		return false
	if visual_bounds.size.x <= 0.0 or visual_bounds.size.y <= 0.0:
		return false
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return false
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, 0.03)
	var image_size: Vector2i = image.get_size()
	if image_size.x <= 0 or image_size.y <= 0:
		return false
	var alpha_polys: Array = bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, image_size), 1.0)
	var added: bool = false
	for alpha_poly in alpha_polys:
		if not (alpha_poly is PackedVector2Array):
			continue
		var tex_poly: PackedVector2Array = alpha_poly
		if tex_poly.size() < 3:
			continue
		var local_collision_poly := PackedVector2Array()
		var poly_center := Vector2.ZERO
		for tex_point_any in tex_poly:
			poly_center += tex_point_any
		poly_center /= float(tex_poly.size())
		for tex_point in tex_poly:
			var expanded_tex_point: Vector2 = poly_center + (tex_point - poly_center) * 1.04
			var normalized_x: float = expanded_tex_point.x / float(image_size.x)
			if mirror_x:
				normalized_x = 1.0 - normalized_x
			local_collision_poly.append(Vector2(
				visual_bounds.position.x + normalized_x * visual_bounds.size.x,
				visual_bounds.position.y + (expanded_tex_point.y / float(image_size.y)) * visual_bounds.size.y
			))
		if local_collision_poly.size() < 3:
			continue
		var collision := CollisionPolygon2D.new()
		collision.name = "SpriteCollision"
		collision.polygon = local_collision_poly
		collision.disabled = destroyed
		parent_node.add_child(collision)
		added = true
	return added


func _add_boss_limb_sprite_visual(swing_root: Node2D, part_name: String, local_poly: PackedVector2Array, destroyed: bool, texture_override: Texture2D = null) -> bool:
	if swing_root == null or local_poly.is_empty():
		return false
	var texture: Texture2D = texture_override
	if texture == null:
		texture = _load_boss_texture(_get_boss_limb_sprite_path(part_name))
	if texture == null:
		return false
	var visual_bounds: Rect2 = _get_boss_sprite_visual_bounds(local_poly, _get_boss_limb_sprite_scale_padding())
	if visual_bounds.size.x <= 0.0 or visual_bounds.size.y <= 0.0:
		return false
	var tex_size: Vector2 = texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return false
	var sprite := Sprite2D.new()
	sprite.name = "SpriteFill"
	sprite.texture = texture
	sprite.centered = true
	sprite.position = visual_bounds.get_center()
	sprite.scale = Vector2(visual_bounds.size.x / tex_size.x, visual_bounds.size.y / tex_size.y)
	sprite.z_index = 0
	var alpha: float = _get_boss_limb_sprite_alpha()
	if destroyed:
		alpha *= BOSS_PART_DESTROYED_ALPHA
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	swing_root.add_child(sprite)
	return true


func _get_boss_head_visual_bounds(local_poly: PackedVector2Array) -> Rect2:
	var poly_bounds: Rect2 = _boss_compute_polygon_bounds(local_poly)
	if poly_bounds.size.x <= 0.0 or poly_bounds.size.y <= 0.0:
		return Rect2()
	var target_size: Vector2 = poly_bounds.size * _get_boss_head_image_scale()
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		return Rect2()
	var center: Vector2 = poly_bounds.get_center() + _get_boss_head_image_offset()
	return Rect2(center - (target_size * 0.5), target_size)


func _get_boss_leg_visual_bounds(local_poly: PackedVector2Array) -> Rect2:
	var poly_bounds: Rect2 = _boss_compute_polygon_bounds(local_poly)
	if poly_bounds.size.x <= 0.0 or poly_bounds.size.y <= 0.0:
		return Rect2()
	var target_size: Vector2 = poly_bounds.size
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		return Rect2()
	var center: Vector2 = poly_bounds.get_center()
	return Rect2(center - (target_size * 0.5), target_size)






func _add_dual_boss_head_sprite_visual(swing_root: Node2D, local_poly: PackedVector2Array, destroyed: bool, friendly_texture: Texture2D, enemy_texture: Texture2D) -> bool:
	if swing_root == null or local_poly.is_empty() or friendly_texture == null or enemy_texture == null:
		return false
	var visual_bounds: Rect2 = _get_boss_head_visual_bounds(local_poly)
	if visual_bounds.size.x <= 0.0 or visual_bounds.size.y <= 0.0:
		return false
	var friendly_tex_size: Vector2 = friendly_texture.get_size()
	var enemy_tex_size: Vector2 = enemy_texture.get_size()
	if friendly_tex_size.x <= 0.0 or friendly_tex_size.y <= 0.0 or enemy_tex_size.x <= 0.0 or enemy_tex_size.y <= 0.0:
		return false
	var alpha: float = _get_boss_head_image_alpha()
	if destroyed:
		alpha *= BOSS_PART_DESTROYED_ALPHA
	var shadow_alpha: float = 0.18 if not destroyed else 0.08

	# Keep enemy head exactly as the normal single-head presentation (full bounds, centered).
	_add_head_sprite_with_shadow(
		swing_root,
		"Enemy",
		enemy_texture,
		visual_bounds.get_center(),
		Vector2(visual_bounds.size.x / enemy_tex_size.x, visual_bounds.size.y / enemy_tex_size.y),
		alpha,
		shadow_alpha
	)

	# Place friendly invading head above enemy head as an overlay indicator.
	var friendly_width: float = visual_bounds.size.x * 0.58
	var friendly_height: float = visual_bounds.size.y * 0.58
	var friendly_center: Vector2 = visual_bounds.get_center() + Vector2(0.0, -visual_bounds.size.y * 0.60)
	_add_head_sprite_with_shadow(
		swing_root,
		"FriendlyInvading",
		friendly_texture,
		friendly_center,
		Vector2(friendly_width / friendly_tex_size.x, friendly_height / friendly_tex_size.y),
		alpha,
		shadow_alpha
	)
	return true


func _add_head_sprite_with_shadow(parent: Node2D, suffix: String, texture: Texture2D, center: Vector2, scale: Vector2, alpha: float, shadow_alpha: float) -> void:
	var shadow := Sprite2D.new()
	shadow.name = "HeadShadow%s" % suffix
	shadow.texture = texture
	shadow.centered = true
	shadow.position = center + Vector2(6.0, 8.0)
	shadow.scale = scale
	shadow.z_index = -1
	shadow.modulate = Color(0.0, 0.0, 0.0, shadow_alpha)
	parent.add_child(shadow)

	var sprite := Sprite2D.new()
	sprite.name = "HeadSprite%s" % suffix
	sprite.texture = texture
	sprite.centered = true
	sprite.position = center
	sprite.scale = scale
	sprite.z_index = 0
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	parent.add_child(sprite)
func _add_boss_head_sprite_visual(swing_root: Node2D, local_poly: PackedVector2Array, destroyed: bool, texture_override: Texture2D = null) -> bool:
	if swing_root == null or local_poly.is_empty():
		return false
	var texture: Texture2D = texture_override
	if texture == null:
		if not _get_boss_head_image_enabled():
			return false
		texture = _load_boss_texture(_get_boss_head_image_path())
	if texture == null:
		return false
	var visual_bounds: Rect2 = _get_boss_head_visual_bounds(local_poly)
	if visual_bounds.size.x <= 0.0 or visual_bounds.size.y <= 0.0:
		return false
	var tex_size: Vector2 = texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return false

	var shadow := Sprite2D.new()
	shadow.name = "HeadShadow"
	shadow.texture = texture
	shadow.centered = true
	shadow.position = visual_bounds.get_center() + Vector2(6.0, 8.0)
	shadow.scale = Vector2(visual_bounds.size.x / tex_size.x, visual_bounds.size.y / tex_size.y)
	shadow.z_index = -1
	shadow.modulate = Color(0.0, 0.0, 0.0, 0.18 if not destroyed else 0.08)
	swing_root.add_child(shadow)

	var sprite := Sprite2D.new()
	sprite.name = "HeadSprite"
	sprite.texture = texture
	sprite.centered = true
	sprite.position = visual_bounds.get_center()
	sprite.scale = Vector2(visual_bounds.size.x / tex_size.x, visual_bounds.size.y / tex_size.y)
	sprite.z_index = 0
	var alpha: float = _get_boss_head_image_alpha()
	if destroyed:
		alpha *= BOSS_PART_DESTROYED_ALPHA
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	swing_root.add_child(sprite)
	return true


func _make_boss_head_rng(head_center: Vector2, head_half: Vector2, scale_size: float) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var seed_key: String = "%d|%d|%d|%d|%d" % [
		int(round(head_center.x * 10.0)),
		int(round(head_center.y * 10.0)),
		int(round(head_half.x * 10.0)),
		int(round(head_half.y * 10.0)),
		int(round(scale_size * 10.0))
	]
	rng.seed = int(seed_key.hash())
	return rng


func _pick_weighted_edge_index(rng: RandomNumberGenerator, lengths: Array[float]) -> int:
	var total: float = 0.0
	for length in lengths:
		total += maxf(0.001, float(length))
	if total <= 0.0:
		return 0
	var pick: float = rng.randf() * total
	var accum: float = 0.0
	for i in range(lengths.size()):
		accum += maxf(0.001, float(lengths[i]))
		if pick <= accum:
			return i
	return max(0, lengths.size() - 1)


func _make_boss_head_polygon(head_center: Vector2, head_half: Vector2, scale_size: float) -> PackedVector2Array:
	var rect := PackedVector2Array([
		head_center + Vector2(-head_half.x, -head_half.y),
		head_center + Vector2(head_half.x, -head_half.y),
		head_center + Vector2(head_half.x, head_half.y),
		head_center + Vector2(-head_half.x, head_half.y)
	])
	if not _get_boss_head_bumpiness_enabled():
		return rect

	var rng: RandomNumberGenerator = _make_boss_head_rng(head_center, head_half, scale_size)
	var total_bumps: int = rng.randi_range(_get_boss_head_bump_count_min(), _get_boss_head_bump_count_max())
	var edge_defs: Array[Dictionary] = [
		{
			"a": head_center + Vector2(-head_half.x, -head_half.y),
			"b": head_center + Vector2(head_half.x, -head_half.y),
			"normal": Vector2(0.0, -1.0),
			"length": head_half.x * 2.0
		},
		{
			"a": head_center + Vector2(head_half.x, -head_half.y),
			"b": head_center + Vector2(head_half.x, head_half.y),
			"normal": Vector2(1.0, 0.0),
			"length": head_half.y * 2.0
		},
		{
			"a": head_center + Vector2(head_half.x, head_half.y),
			"b": head_center + Vector2(-head_half.x, head_half.y),
			"normal": Vector2(0.0, 1.0),
			"length": head_half.x * 2.0
		},
		{
			"a": head_center + Vector2(-head_half.x, head_half.y),
			"b": head_center + Vector2(-head_half.x, -head_half.y),
			"normal": Vector2(-1.0, 0.0),
			"length": head_half.y * 2.0
		}
	]
	var edge_lengths: Array[float] = []
	for edge_def in edge_defs:
		edge_lengths.append(float(edge_def.get("length", 1.0)))
	var edge_bumps: Array = [[], [], [], []]
	var corner_exclusion: float = _get_boss_head_bump_corner_exclusion_ratio()
	for _i in range(total_bumps):
		var edge_index: int = _pick_weighted_edge_index(rng, edge_lengths)
		var center_t: float = rng.randf_range(corner_exclusion, 1.0 - corner_exclusion)
		var half_width: float = rng.randf_range(_get_boss_head_bump_width_ratio_min(), _get_boss_head_bump_width_ratio_max()) * 0.5
		var amplitude: float = rng.randf_range(_get_boss_head_bump_depth_min(), _get_boss_head_bump_depth_max())
		if rng.randf() >= _get_boss_head_bump_outward_chance():
			amplitude *= -1.0
		edge_bumps[edge_index].append({
			"center_t": center_t,
			"half_width": half_width,
			"amplitude": amplitude
		})

	var poly := PackedVector2Array()
	var min_edge_points: int = _get_boss_head_bump_min_edge_points()
	var jitter_min: float = _get_boss_head_bump_edge_jitter_min()
	var jitter_max: float = _get_boss_head_bump_edge_jitter_max()
	for edge_index in range(edge_defs.size()):
		var edge_def: Dictionary = edge_defs[edge_index]
		var a: Vector2 = Vector2(edge_def.get("a", Vector2.ZERO))
		var b: Vector2 = Vector2(edge_def.get("b", Vector2.ZERO))
		var normal: Vector2 = Vector2(edge_def.get("normal", Vector2.ZERO))
		var tangent: Vector2 = (b - a).normalized()
		var bumps: Array = edge_bumps[edge_index]
		var samples: int = maxi(min_edge_points, 4 + (bumps.size() * 3))
		for sample_index in range(samples):
			if edge_index > 0 and sample_index == 0:
				continue
			if edge_index == edge_defs.size() - 1 and sample_index == samples - 1:
				continue
			var denom: float = maxf(1.0, float(samples - 1))
			var t: float = float(sample_index) / denom
			var base_point: Vector2 = a.lerp(b, t)
			var offset: float = 0.0
			for bump in bumps:
				var bump_center: float = float(bump.get("center_t", 0.5))
				var bump_half_width: float = maxf(0.001, float(bump.get("half_width", 0.1)))
				var tri: float = 1.0 - (absf(t - bump_center) / bump_half_width)
				if tri > 0.0:
					offset += float(bump.get("amplitude", 0.0)) * tri
			if jitter_max > 0.0 and t > corner_exclusion and t < 1.0 - corner_exclusion:
				var jitter_mag: float = rng.randf_range(jitter_min, jitter_max)
				if rng.randf() < 0.5:
					jitter_mag *= -1.0
				offset += jitter_mag
			var point: Vector2 = base_point + (normal * offset)
			point += tangent * rng.randf_range(-scale_size * 0.0025, scale_size * 0.0025)
			poly.append(point)
	if poly.size() < 4:
		return rect
	return poly


func _add_boss_head_image_visual(swing_root: Node2D, local_poly: PackedVector2Array, destroyed: bool) -> void:
	if swing_root == null or local_poly.is_empty():
		return
	if not _get_boss_head_image_enabled():
		return

	var image_path: String = _get_boss_head_image_path().strip_edges()
	if image_path.is_empty():
		return

	var texture: Texture2D = _load_boss_texture(image_path)
	if texture == null:
		return

	var poly_bounds: Rect2 = _boss_compute_polygon_bounds(local_poly)
	if poly_bounds.size.x <= 0.0 or poly_bounds.size.y <= 0.0:
		return

	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var target_size: Vector2 = poly_bounds.size * _get_boss_head_image_scale()
	var uniform_scale: float = minf(target_size.x / texture_size.x, target_size.y / texture_size.y)
	if uniform_scale <= 0.0:
		return

	var sprite := Sprite2D.new()
	sprite.name = "HeadImage"
	sprite.texture = texture
	sprite.centered = true
	sprite.position = poly_bounds.get_center() + _get_boss_head_image_offset()
	sprite.scale = Vector2.ONE * uniform_scale
	sprite.z_index = 0
	var alpha: float = _get_boss_head_image_alpha()
	if destroyed:
		alpha *= BOSS_PART_DESTROYED_ALPHA
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	swing_root.add_child(sprite)


func _make_boss_part_layouts(center: Vector2, scale_size: float, part_state_map: Dictionary) -> Dictionary:
	var destroyed_limb_count: int = _count_destroyed_boss_limbs(part_state_map)
	var exposure_t: float = clampf(float(destroyed_limb_count) / 4.0, 0.0, 1.0)
	var min_ball_radius: float = float(LevelConfig.BALL_RADIUS_MIN_GRAND_MAP)
	var head_scale: float = _get_boss_head_size_scale()
	var arm_scale: float = _get_boss_arm_size_scale()
	var leg_scale: float = _get_boss_leg_size_scale()
	var head_vertical_offset_factor: float = _get_boss_head_vertical_offset_factor()
	var default_head_vertical_offset_factor: float = -0.110

	# Keep the limb scaffold anchored to a stable reference pose so the head-specific knobs
	# do not distort the arms or legs. The user-facing vertical-offset knob should only move
	# the head up/down, and the head-size knob should only resize the head rectangle itself.
	var attachment_head_center: Vector2 = center + Vector2(0.0, scale_size * default_head_vertical_offset_factor)
	var attachment_head_half: Vector2 = Vector2(
		maxf(scale_size * 0.128, min_ball_radius * 2.30),
		maxf(scale_size * 0.138, min_ball_radius * 1.42)
	) * 0.84
	var attachment_top_gap_half: float = minf(
		attachment_head_half.x - maxf(scale_size * 0.022, min_ball_radius * 0.34),
		min_ball_radius * 2.0 + (exposure_t * scale_size * 0.045)
	)

	var head_center: Vector2 = center + Vector2(0.0, scale_size * head_vertical_offset_factor)
	var head_half: Vector2 = attachment_head_half * head_scale

	var left_mid: Vector2 = attachment_head_center + Vector2(-attachment_head_half.x, 0.0)
	var bottom_mid: Vector2 = attachment_head_center + Vector2(0.0, attachment_head_half.y)
	var right_mid: Vector2 = attachment_head_center + Vector2(attachment_head_half.x, 0.0)
	var top_left_break: Vector2 = attachment_head_center + Vector2(-attachment_top_gap_half, -attachment_head_half.y)
	var top_right_break: Vector2 = attachment_head_center + Vector2(attachment_top_gap_half, -attachment_head_half.y)

	var left_arm_points: Array[Vector2] = [
		center + Vector2(-scale_size * 0.235, -scale_size * 0.300),
		center + Vector2(-scale_size * 0.175, -scale_size * 0.205),
		top_left_break + Vector2(-scale_size * 0.012, -scale_size * 0.008),
		left_mid + Vector2(-scale_size * 0.010, 0.0)
	]
	var right_arm_points: Array[Vector2] = [
		center + Vector2(scale_size * 0.235, -scale_size * 0.300),
		center + Vector2(scale_size * 0.175, -scale_size * 0.205),
		top_right_break + Vector2(scale_size * 0.012, -scale_size * 0.008),
		right_mid + Vector2(scale_size * 0.010, 0.0)
	]

	var left_arm_anchor: Vector2 = left_mid
	var right_arm_anchor: Vector2 = right_mid
	for i in range(left_arm_points.size()):
		left_arm_points[i] = left_arm_anchor + (left_arm_points[i] - left_arm_anchor) * arm_scale
	for i in range(right_arm_points.size()):
		right_arm_points[i] = right_arm_anchor + (right_arm_points[i] - right_arm_anchor) * arm_scale

	var left_leg_points: Array[Vector2] = [
		left_mid + Vector2(-scale_size * 0.004, scale_size * 0.014),
		bottom_mid + Vector2(-scale_size * 0.014, scale_size * 0.012),
		center + Vector2(-scale_size * 0.185, scale_size * 0.235),
		center + Vector2(-scale_size * 0.115, scale_size * 0.395)
	]
	var right_leg_points: Array[Vector2] = [
		right_mid + Vector2(scale_size * 0.004, scale_size * 0.014),
		bottom_mid + Vector2(scale_size * 0.014, scale_size * 0.012),
		center + Vector2(scale_size * 0.185, scale_size * 0.235),
		center + Vector2(scale_size * 0.115, scale_size * 0.395)
	]

	var left_leg_anchor: Vector2 = bottom_mid + Vector2(-scale_size * 0.010, scale_size * 0.010)
	var right_leg_anchor: Vector2 = bottom_mid + Vector2(scale_size * 0.010, scale_size * 0.010)
	for i in range(left_leg_points.size()):
		left_leg_points[i] = left_leg_anchor + (left_leg_points[i] - left_leg_anchor) * leg_scale
	for i in range(right_leg_points.size()):
		right_leg_points[i] = right_leg_anchor + (right_leg_points[i] - right_leg_anchor) * leg_scale

	var arm_widths: Array[float] = [
		scale_size * 0.086 * arm_scale,
		scale_size * 0.078 * arm_scale,
		scale_size * 0.068 * arm_scale,
		scale_size * 0.078 * arm_scale
	]
	var leg_widths: Array[float] = [
		scale_size * 0.082 * leg_scale,
		scale_size * 0.076 * leg_scale,
		scale_size * 0.088 * leg_scale,
		scale_size * 0.094 * leg_scale
	]

	var head_poly: PackedVector2Array = _make_boss_head_polygon(head_center, head_half, scale_size)

	var left_arm_joint: Vector2 = top_left_break.lerp(left_mid, 0.58)
	var right_arm_joint: Vector2 = top_right_break.lerp(right_mid, 0.58)
	var left_leg_joint: Vector2 = left_leg_points[0].lerp(left_leg_points[1], 0.40)
	var right_leg_joint: Vector2 = right_leg_points[0].lerp(right_leg_points[1], 0.40)

	return {
		"head": {
			"polygon": head_poly,
			"pivot": head_center
		},
		"left_arm": {
			"polygon": _make_boss_limb_polygon(left_arm_points, arm_widths),
			"pivot": left_arm_joint,
			"collision_points": left_arm_points,
			"collision_widths": arm_widths
		},
		"right_arm": {
			"polygon": _make_boss_limb_polygon(right_arm_points, arm_widths),
			"pivot": right_arm_joint,
			"collision_points": right_arm_points,
			"collision_widths": arm_widths
		},
		"left_leg": {
			"polygon": _make_boss_leg_polygon(left_leg_points, leg_widths, scale_size, false),
			"pivot": left_leg_joint,
			"collision_points": left_leg_points,
			"collision_widths": leg_widths
		},
		"right_leg": {
			"polygon": _make_boss_leg_polygon(right_leg_points, leg_widths, scale_size, true),
			"pivot": right_leg_joint,
			"collision_points": right_leg_points,
			"collision_widths": leg_widths
		}
	}


func _add_boss_segment_collision_shapes(parent_node: Node, local_points: Array[Vector2], widths: Array, destroyed: bool) -> void:
	if parent_node == null or local_points.size() < 2 or local_points.size() != widths.size():
		return

	for i in range(local_points.size()):
		var circle := CollisionShape2D.new()
		var circle_shape := CircleShape2D.new()
		circle_shape.radius = maxf(2.0, float(widths[i]) * 0.5)
		circle.shape = circle_shape
		circle.position = local_points[i]
		circle.disabled = destroyed
		parent_node.add_child(circle)

	for i in range(local_points.size() - 1):
		var a: Vector2 = local_points[i]
		var b: Vector2 = local_points[i + 1]
		var seg: Vector2 = b - a
		var seg_len: float = seg.length()
		if seg_len <= 0.001:
			continue
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(seg_len, maxf(2.0, maxf(float(widths[i]), float(widths[i + 1]))))
		var rect := CollisionShape2D.new()
		rect.shape = rect_shape
		rect.position = (a + b) * 0.5
		rect.rotation = seg.angle()
		rect.disabled = destroyed
		parent_node.add_child(rect)




func _make_boss_leg_polygon(points: Array[Vector2], widths: Array, scale_size: float, is_right_leg: bool) -> PackedVector2Array:
	var base_poly: PackedVector2Array = _make_boss_limb_polygon(points, widths)
	if base_poly.is_empty():
		return base_poly
	var bounds: Rect2 = _boss_compute_polygon_bounds(base_poly)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return base_poly
	var center: Vector2 = bounds.get_center()
	var half: Vector2 = bounds.size * 0.5
	var rng := RandomNumberGenerator.new()
	var seed_key: String = "%d|%d|%d|%d|%d|%d" % [
		int(round(center.x * 10.0)),
		int(round(center.y * 10.0)),
		int(round(half.x * 10.0)),
		int(round(half.y * 10.0)),
		int(round(scale_size * 10.0)),
		1 if is_right_leg else 0
	]
	rng.seed = int(seed_key.hash())
	var side_sign: float = 1.0 if is_right_leg else -1.0
	var leg_poly := PackedVector2Array()
	for p in base_poly:
		var radial: Vector2 = p - center
		var x_ratio: float = absf(radial.x) / maxf(0.001, half.x)
		var y_ratio: float = clampf((p.y - bounds.position.y) / maxf(0.001, bounds.size.y), 0.0, 1.0)
		var outer_bias: float = clampf((radial.x * side_sign) / maxf(0.001, half.x), 0.0, 1.0)
		var top_taper: float = clampf(1.0 - y_ratio, 0.0, 1.0)
		var base_push: float = scale_size * (0.004 + (0.006 * y_ratio)) * outer_bias
		var knee_bulge: float = scale_size * 0.010 * (1.0 - absf(y_ratio - 0.62) / 0.30) * outer_bias
		if knee_bulge < 0.0:
			knee_bulge = 0.0
		var shin_taper: float = scale_size * 0.006 * maxf(0.0, y_ratio - 0.75) * (1.0 - outer_bias * 0.4)
		var jitter: float = rng.randf_range(-0.003, 0.003) * scale_size * maxf(0.0, x_ratio - 0.2)
		var offset_x: float = side_sign * (base_push + knee_bulge) + jitter
		offset_x -= signf(radial.x) * shin_taper * top_taper
		leg_poly.append(Vector2(p.x + offset_x, p.y))
	return leg_poly
func _make_boss_limb_polygon(points: Array[Vector2], widths: Array) -> PackedVector2Array:
	if points.size() < 2 or points.size() != widths.size():
		return PackedVector2Array()

	var left_side := PackedVector2Array()
	var right_side := PackedVector2Array()
	for i in range(points.size()):
		var tangent := Vector2.ZERO
		if i == 0:
			tangent = points[1] - points[0]
		elif i == points.size() - 1:
			tangent = points[i] - points[i - 1]
		else:
			tangent = points[i + 1] - points[i - 1]
		if tangent.length_squared() <= 0.0001:
			tangent = Vector2.RIGHT
		var normal := tangent.normalized().orthogonal()
		var half_width: float = maxf(2.0, float(widths[i]) * 0.5)
		left_side.append(points[i] + normal * half_width)
		right_side.append(points[i] - normal * half_width)

	var poly := PackedVector2Array()
	for p in left_side:
		poly.append(p)
	for i in range(right_side.size() - 1, -1, -1):
		poly.append(right_side[i])
	return poly


func _boss_compute_polygon_bounds(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var min_x: float = poly[0].x
	var min_y: float = poly[0].y
	var max_x: float = poly[0].x
	var max_y: float = poly[0].y
	for point in poly:
		min_x = minf(min_x, point.x)
		min_y = minf(min_y, point.y)
		max_x = maxf(max_x, point.x)
		max_y = maxf(max_y, point.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func get_boss_head_spawn_bounds(home_polygon: PackedVector2Array, buffer: float = 0.0) -> Rect2:
	if home_polygon.is_empty():
		return Rect2()

	var bounds: Rect2 = _boss_compute_polygon_bounds(home_polygon)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001:
		return Rect2()

	var center: Vector2 = bounds.get_center()
	var scale_size: float = minf(bounds.size.x, bounds.size.y)
	var part_layouts: Dictionary = _make_boss_part_layouts(center, scale_size, {})
	var head_layout: Dictionary = part_layouts.get("head", {})
	var head_polygon: PackedVector2Array = head_layout.get("polygon", PackedVector2Array())
	if head_polygon.is_empty():
		return Rect2()

	var head_bounds: Rect2 = _boss_compute_polygon_bounds(head_polygon)
	if buffer > 0.0:
		head_bounds.position -= Vector2.ONE * buffer
		head_bounds.size += Vector2.ONE * (buffer * 2.0)
	return head_bounds
