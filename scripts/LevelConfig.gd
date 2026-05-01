extends RefCounted
class_name LevelConfig
"""
Centralized constants for Sunny Slopes gameplay and visuals.

ENGAGEMENT GENERATION / RESOLUTION (March 2026):
- Campaign persistence and resolution remain deterministic and shared.
- Engagement generation is allowed to branch by phase so offensive enemy, offensive neutral,
  and defensive boards can feel meaningfully different.
- The one-shot-per-engagement structure is preserved.
- Province troop/building counts remain the source of truth for persistent engagements.
"""

# ==================== PHYSICS LAYERS & MASKS ====================
const LAYER_BALL: int = 1
const LAYER_PINS: int = 2
const LAYER_WALLS: int = 3
const LAYER_ZONES: int = 4

const MASK_BALL: int = 1 << (LAYER_BALL - 1)
const MASK_PINS: int = 1 << (LAYER_PINS - 1)
const MASK_WALLS: int = 1 << (LAYER_WALLS - 1)
const MASK_ZONES: int = 1 << (LAYER_ZONES - 1)

const BALL_COLLIDES_WITH: int = MASK_PINS | MASK_WALLS
const PIN_COLLIDES_WITH: int = MASK_BALL | MASK_PINS | MASK_WALLS

# ==================== WORLD BOUNDS ====================
const WORLD_SIZE: Vector2 = Vector2(760, 1192)
const WORLD_HALF_EXTENTS: Vector2 = WORLD_SIZE * 0.5
const WORLD_WALL_THICKNESS: float = 40.0

const WORLD_WALL_INSET: float = WORLD_WALL_THICKNESS * 0.5
const PLAYABLE_HALF_EXTENTS: Vector2 = WORLD_HALF_EXTENTS - Vector2(WORLD_WALL_INSET, WORLD_WALL_INSET)
const PLAYABLE_SIZE: Vector2 = PLAYABLE_HALF_EXTENTS * 2.0

static func get_outer_world_rect() -> Rect2:
	return Rect2(-WORLD_HALF_EXTENTS, WORLD_SIZE)

static func get_playable_rect() -> Rect2:
	return Rect2(-PLAYABLE_HALF_EXTENTS, PLAYABLE_SIZE)

static func get_playable_half_extents_for_radius(radius: float) -> Vector2:
	return PLAYABLE_HALF_EXTENTS - Vector2(radius, radius)

static func is_inside_playable_rect(pos: Vector2, margin: float = 0.0) -> bool:
	return absf(pos.x) <= PLAYABLE_HALF_EXTENTS.x - margin and absf(pos.y) <= PLAYABLE_HALF_EXTENTS.y - margin

# ==================== VISUAL DRAW LAYERS (back to front) ====================
# These are canonical world-space visual layer slots.
# Higher numbers draw in front of lower numbers.
# The order below matches the requested front-to-back stack when read bottom-up.
# Notes:
# - The outer wall / map-edge mask should live with the static-obstacle family unless explicitly split later.
# - Aim guides, preview ball, launched ball, boss visuals, magnets, and similar interactive overlays should live in the special-gameplay layer.
const VISUAL_LAYER_SAND: int = 100
const VISUAL_LAYER_PROVINCE_FILL: int = 1250
const VISUAL_LAYER_BOARDWALK: int = 400
const VISUAL_LAYER_BUSHES: int = 300
const VISUAL_LAYER_TROOPS: int = 500
const VISUAL_LAYER_GRAND_MAP_PROVINCE_TROOPS: int = 1400
const VISUAL_LAYER_BUILDINGS: int = 600
const VISUAL_LAYER_WATER: int = 700
const VISUAL_LAYER_STATIC_OBSTACLES: int = 800
const VISUAL_LAYER_BORDERS: int = 900
const VISUAL_LAYER_BORDER_OVERLAYS: int = 1000
const VISUAL_LAYER_SPECIAL_GAMEPLAY_ACTORS: int = 1100
const VISUAL_LAYER_WORLD_PARTICLES: int = 1200
const VISUAL_LAYER_DISPLAY_WINDOWS: int = 1300
# Province info cards intentionally sit above world-space masks like the grand-map outer wall.
const VISUAL_LAYER_PROVINCE_INFO_CARDS: int = 2300

# Canvas/UI layers.
# World visuals remain on the default world canvas. The main HUD stays above that via CanvasLayer.
const UI_CANVAS_LAYER_MAIN_HUD: int = 1

# ==================== TUTORIAL / FIELD GUIDE ====================
# Hybrid onboarding: short first-run coach cards plus a persistent Field Guide.
# These knobs let the game stay newcomer-friendly without forcing long interruptions on repeat players.
const TUTORIAL_AND_FIELD_GUIDE_ENABLED: bool = true
const TUTORIAL_AUTO_START_ON_FIRST_RUN: bool = true
const TUTORIAL_REPLAY_AVAILABLE_IN_HELP_MENU: bool = true
const TUTORIAL_AUTO_UNLOCK_NOTES_FROM_EVENTS: bool = true
const TUTORIAL_SHOW_UNLOCK_NOTES_AS_TOASTS: bool = true
const TUTORIAL_SHOW_UNLOCKED_NOTE_SHORT_BODY: bool = true
const TUTORIAL_NOTE_TOAST_SECONDS: float = 4.5
const TUTORIAL_COACH_CARD_DIM_ALPHA: float = 0.36
const TUTORIAL_TARGET_PULSE_SECONDS: float = 1.15
const TUTORIAL_FIRST_RUN_AUTO_ADVANCE_SECONDS: float = 0.0
const FIELD_GUIDE_UNREAD_BADGE_CAP: int = 9
const FIELD_GUIDE_POPUP_QUEUE_LIMIT: int = 4
const FIELD_GUIDE_PAUSES_GAME: bool = true
const FIELD_GUIDE_DEFAULT_OPEN_CATEGORY: String = "Basics"

static func is_tutorial_and_field_guide_enabled() -> bool:
	return TUTORIAL_AND_FIELD_GUIDE_ENABLED

static func should_auto_start_first_run_tutorial() -> bool:
	return is_tutorial_and_field_guide_enabled() and TUTORIAL_AUTO_START_ON_FIRST_RUN

static func can_replay_tutorial_from_help_menu() -> bool:
	return is_tutorial_and_field_guide_enabled() and TUTORIAL_REPLAY_AVAILABLE_IN_HELP_MENU

static func should_auto_unlock_field_guide_notes() -> bool:
	return is_tutorial_and_field_guide_enabled() and TUTORIAL_AUTO_UNLOCK_NOTES_FROM_EVENTS

static func should_show_field_guide_unlock_toasts() -> bool:
	return is_tutorial_and_field_guide_enabled() and TUTORIAL_SHOW_UNLOCK_NOTES_AS_TOASTS

static func should_show_field_guide_unlock_short_body() -> bool:
	return TUTORIAL_SHOW_UNLOCKED_NOTE_SHORT_BODY

static func get_tutorial_note_toast_seconds() -> float:
	return maxf(0.5, TUTORIAL_NOTE_TOAST_SECONDS)

static func get_tutorial_coach_card_dim_alpha() -> float:
	return clampf(TUTORIAL_COACH_CARD_DIM_ALPHA, 0.0, 0.9)

static func get_tutorial_target_pulse_seconds() -> float:
	return maxf(0.1, TUTORIAL_TARGET_PULSE_SECONDS)

static func get_tutorial_first_run_auto_advance_seconds() -> float:
	return maxf(0.0, TUTORIAL_FIRST_RUN_AUTO_ADVANCE_SECONDS)

static func get_field_guide_unread_badge_cap() -> int:
	return maxi(1, FIELD_GUIDE_UNREAD_BADGE_CAP)

static func get_field_guide_popup_queue_limit() -> int:
	return maxi(1, FIELD_GUIDE_POPUP_QUEUE_LIMIT)

static func should_pause_game_when_field_guide_is_open() -> bool:
	return FIELD_GUIDE_PAUSES_GAME

static func get_field_guide_default_open_category() -> String:
	return FIELD_GUIDE_DEFAULT_OPEN_CATEGORY

# Zone-template child ordering inside the zones root.
# These values are only used to keep same-parent zone children deterministic before explicit z-indices are applied.
const ZONE_DRAW_PRIORITY_SAND: int = 10
const ZONE_DRAW_PRIORITY_BOARDWALK: int = 20
const ZONE_DRAW_PRIORITY_BUSHES: int = 30
const ZONE_DRAW_PRIORITY_WATER: int = 40
const ZONE_DRAW_PRIORITY_GRADE: int = 50

# ==================== GRAND MAP (OVERHAUL - 3x procedural world, no pins) ====================
const GRAND_MAP_SIZE_MULTIPLIER: float = 6.0
const GRAND_MAP_WORLD_SIZE: Vector2 = WORLD_SIZE * GRAND_MAP_SIZE_MULTIPLIER
const GRAND_MAP_HALF_EXTENTS: Vector2 = GRAND_MAP_WORLD_SIZE * 0.5
const GRAND_MAP_WALL_INSET: float = WORLD_WALL_INSET
const GRAND_MAP_PLAYABLE_HALF_EXTENTS: Vector2 = GRAND_MAP_HALF_EXTENTS - Vector2(GRAND_MAP_WALL_INSET, GRAND_MAP_WALL_INSET)
const GRAND_MAP_PLAYABLE_SIZE: Vector2 = GRAND_MAP_PLAYABLE_HALF_EXTENTS * 2.0

const GRAND_MAP_CAMERA_MIN_ZOOM: float = 0.12
const GRAND_MAP_CAMERA_MAX_ZOOM: float = 2.5

const GRAND_MAP_ZONE_OBSTACLE_BASE: int = 12
const GRAND_MAP_WATER_BASE_COUNT: int = 8
const GRAND_MAP_GRADE_BASE_COUNT: int = 6
const GRAND_MAP_ENABLE_GRADE_ZONES: bool = false
const GRAND_MAP_FRICTION_BASE: int = 18
const GRAND_MAP_PIN_COUNT: int = 0

const GRAND_MAP_WALL_THICKNESS: float = 40.0
const GRAND_MAP_WALL_INSET_SAFETY: float = 20.0
const GRAND_MAP_WALL_SAFETY_BUFFER: float = 80.0

const GRAND_MAP_SKIP_TO_END_TURN_PAUSE_SECONDS: float = 0.5

# ==================== PROVINCES (visual borders only - Grand Map only) ====================
const GRAND_MAP_PROVINCES_PER_MULTIPLIER: int = 5
const GRAND_MAP_PROVINCE_VARIATION: int = 3

const PROVINCE_BORDER_WIDTH: float = 7.5
const PROVINCE_SHARED_BORDER_WIDTH: float = 6.0
const PROVINCE_LAUNCH_LOCK_PULSE_WIDTH: float = 9.72
const PROVINCE_BORDER_COLOR: Color = Color(0.85, 0.72, 0.48, 0.92)
const PROVINCE_NEUTRAL_BORDER_COLOR: Color = Color(0.70, 0.78, 0.86, 0.98)
const PROVINCE_FILL_COLORS: Array[Color] = [
	Color(0.96, 0.82, 0.55, 0.18),
	Color(0.92, 0.78, 0.45, 0.16),
	Color(0.94, 0.85, 0.62, 0.14),
	Color(0.89, 0.75, 0.38, 0.19),
	Color(0.97, 0.88, 0.68, 0.13)
]


const PROVINCE_BORDER_SMOOTHING_ENABLED: bool = true
const PROVINCE_BORDER_SIMPLIFY_ENABLED: bool = true
const PROVINCE_BORDER_SIMPLIFY_EPSILON: float = 42.0
const PROVINCE_BORDER_SIMPLIFY_MIN_POINT_COUNT: int = 4
const PROVINCE_BORDER_SMOOTHING_PASSES: int = 2
const PROVINCE_BORDER_SMOOTHING_CHAIKIN_RATIO: float = 0.20
const PROVINCE_BORDER_SMOOTHING_MIN_POINT_COUNT: int = 4

# Scales the small troop pips shown on grand-map provinces to represent stationed troops.
# Increase to make each pip larger; decrease to make them smaller.
const GRAND_MAP_PROVINCE_TROOP_VISUAL_SIZE_MULTIPLIER: float = 1000.0
const GRAND_MAP_PROVINCE_TROOP_VISUAL_STACK_DIRECTION: String = "pile" # "pile", "horizontal", or "vertical"
const GRAND_MAP_PROVINCE_TROOP_VISUAL_COLOR: Color = Color(0.161, 1.0, 1.0, 1.0)
const GRAND_MAP_PROVINCE_TROOP_VISUAL_OPACITY: float = 1.0
# Positive values move troop visuals down; negative values move them up.
const GRAND_MAP_PROVINCE_TROOP_VISUAL_CENTER_Y_OFFSET: float = -80.0

static func get_grand_map_province_troop_visual_size_multiplier() -> float:
	return clampf(GRAND_MAP_PROVINCE_TROOP_VISUAL_SIZE_MULTIPLIER, 0.25, 4.0)

static func get_grand_map_province_troop_visual_stack_direction() -> String:
	var stack_direction: String = GRAND_MAP_PROVINCE_TROOP_VISUAL_STACK_DIRECTION.strip_edges().to_lower()
	if stack_direction == "pile":
		return "pile"
	if stack_direction == "vertical":
		return "vertical"
	return "horizontal"

static func get_grand_map_province_troop_visual_color() -> Color:
	return GRAND_MAP_PROVINCE_TROOP_VISUAL_COLOR

static func get_grand_map_province_troop_visual_opacity() -> float:
	return clampf(GRAND_MAP_PROVINCE_TROOP_VISUAL_OPACITY, 0.05, 1.0)

static func get_grand_map_province_troop_visual_center_y_offset() -> float:
	return clampf(GRAND_MAP_PROVINCE_TROOP_VISUAL_CENTER_Y_OFFSET, -256.0, 256.0)

# ==================== ENEMY FACTIONS (NEW MARCH 2026 - configurable multi-faction invasions) ====================
# Number of distinct enemy factions.
# Set to 1 to keep original single-faction behavior (no inter-enemy fighting).
# Higher values allow enemy provinces of DIFFERENT factions to invade each other on the Grand Map.
# Invasion resolution exactly follows the spec: 1-for-1 troop attrition first, then surviving invaders destroy buildings (1 troop = 1/3 building floored).
const ENEMY_FACTION_COUNT: int = 6
const ENEMY_FACTION_DEFAULT: int = 1
const ENEMY_FACTION_START_COUNT: int = 2
const ENEMY_FACTIONS_ADDED_PER_GRAND_MAP: int = 1


# DISTINCT FACTION COLORS (NEW - bold, high-saturation, clearly different)
# These are the colors used for enemy province backgrounds on the Grand Map.
# Index 0 is unused (fallback safety).
const ENEMY_FACTION_COLORS: Array[Color] = [
	Color(0.0, 0.0, 0.0, 0.0),           # index 0 unused
	Color(0.95, 0.15, 0.15, 0.45),       # faction 1 - bright red
	Color(0.33, 0.40, 0.52, 0.45),       # faction 2 - steel slate (kept distinct from boss faction palette)
	Color(0.10, 0.85, 0.25, 0.45),       # faction 3 - bright emerald green
	Color(0.98, 0.55, 0.05, 0.45),       # faction 4 - vivid orange
	Color(0.05, 0.75, 0.98, 0.45),       # faction 5 - bright cyan
	# Add more colors here if you increase ENEMY_FACTION_COUNT beyond 5
]

static func get_enemy_faction_count_for_grand_map(grand_map_index: int) -> int:
	var safe_index: int = maxi(1, grand_map_index)
	return maxi(1, ENEMY_FACTION_START_COUNT + (safe_index - 1) * ENEMY_FACTIONS_ADDED_PER_GRAND_MAP)


static func get_enemy_faction_color(faction_id: int) -> Color:
	if faction_id <= 0:
		return ENEMY_FACTION_COLORS[1] if ENEMY_FACTION_COLORS.size() > 1 else Color(0.92, 0.28, 0.25, 0.22)
	if faction_id < ENEMY_FACTION_COLORS.size():
		return ENEMY_FACTION_COLORS[faction_id]
	var hue: float = fmod(0.137508 * float(faction_id), 1.0)
	return Color.from_hsv(hue, 0.82, 0.98, 0.45)


const PROVINCE_FORCE_EDGE_SNAP: bool = true
const PROVINCE_JITTER_MAX_FACTOR: float = 0.38

# ==================== CONTINENT-TEMPLATE GRAND MAP GENERATION (NEW MARCH 2026) ====================
# The grand map now uses continent-inspired landmass archetypes instead of a simple rectangular grid.
# Templates are intentionally coarse and heavily deformed so the final result does not read as Earth.
const GRAND_MAP_TEMPLATE_NORTH_AMERICA: String = "north_america"
const GRAND_MAP_TEMPLATE_SOUTH_AMERICA: String = "south_america"
const GRAND_MAP_TEMPLATE_EUROPE: String = "europe"
const GRAND_MAP_TEMPLATE_AFRICA: String = "africa"
const GRAND_MAP_TEMPLATE_ASIA: String = "asia"
const GRAND_MAP_TEMPLATE_AUSTRALIA: String = "australia"
const GRAND_MAP_TEMPLATE_ANTARCTICA: String = "antarctica"

const GRAND_MAP_TEMPLATE_IDS: Array[String] = [
	GRAND_MAP_TEMPLATE_NORTH_AMERICA,
	GRAND_MAP_TEMPLATE_SOUTH_AMERICA,
	GRAND_MAP_TEMPLATE_EUROPE,
	GRAND_MAP_TEMPLATE_AFRICA,
	GRAND_MAP_TEMPLATE_ASIA,
	GRAND_MAP_TEMPLATE_AUSTRALIA,
	GRAND_MAP_TEMPLATE_ANTARCTICA,
]

# Interior template space is normalized to roughly [-1, 1] on each axis before it is scaled into the
# grand-map playable rectangle. The generator then mirrors, rotates, stretches, carves, and jitters it.
# The next-pass template generator intentionally uses stronger deformation than the first attempt so the
# seven template families stay visually distinct after cleanup.
const GRAND_MAP_TEMPLATE_ROTATION_MAX_DEGREES: float = 42.0
const GRAND_MAP_TEMPLATE_STRETCH_MIN: float = 0.68
const GRAND_MAP_TEMPLATE_STRETCH_MAX: float = 1.48
const GRAND_MAP_TEMPLATE_VERTEX_JITTER: float = 0.16
const GRAND_MAP_TEMPLATE_COAST_PUSH_STRENGTH: float = 0.30
const GRAND_MAP_TEMPLATE_SHAPE_VARIANCE: float = 0.62
const GRAND_MAP_TEMPLATE_COAST_VARIANCE: float = 0.28
const GRAND_MAP_TEMPLATE_CENTER_VARIANCE: float = 0.10
const GRAND_MAP_TEMPLATE_WIDTH_VARIANCE: float = 0.16
const GRAND_MAP_TEMPLATE_HEIGHT_VARIANCE: float = 0.16
const GRAND_MAP_TEMPLATE_SHEAR_MAX: float = 0.18
const GRAND_MAP_TEMPLATE_POINT_JITTER_BASE: float = 0.08
const GRAND_MAP_TEMPLATE_SEGMENT_BEND_MAX: float = 0.18
const GRAND_MAP_TEMPLATE_BULGE_CENTER_VARIANCE: float = 0.08
const GRAND_MAP_TEMPLATE_BULGE_RADIUS_VARIANCE: float = 0.22
const GRAND_MAP_TEMPLATE_EXTRA_BITE_MIN: int = 1
const GRAND_MAP_TEMPLATE_EXTRA_BITE_MAX: int = 4

# Grand-map land-grid resolution. This is separate from province count.
const GRAND_MAP_LAND_GRID_COLS: int = 44
const GRAND_MAP_LAND_GRID_ROWS: int = 62
const GRAND_MAP_LAND_EDGE_MARGIN_CELLS: int = 2

# Landmass silhouette tuning.
const GRAND_MAP_MAINLAND_TARGET_HALF_WIDTH_RATIO: float = 0.86
const GRAND_MAP_MAINLAND_TARGET_HALF_HEIGHT_RATIO: float = 0.84
const GRAND_MAP_MAINLAND_EDGE_MARGIN: float = 220.0
const GRAND_MAP_MAINLAND_BOUNDARY_SAMPLE_COUNT: int = 96
const GRAND_MAP_MAINLAND_SMOOTHING_PASSES: int = 1
const GRAND_MAP_MAINLAND_KEEP_MAX_COMPONENTS: int = 3
const GRAND_MAP_MAINLAND_MIN_SECONDARY_COMPONENT_CELLS: int = 18

# Coastal carving / bay generation.
const GRAND_MAP_COASTAL_CARVE_COUNT_MIN: int = 3
const GRAND_MAP_COASTAL_CARVE_COUNT_MAX: int = 7
const GRAND_MAP_COASTAL_CARVE_RADIUS_MIN: float = 0.14
const GRAND_MAP_COASTAL_CARVE_RADIUS_MAX: float = 0.34
const GRAND_MAP_COASTAL_CARVE_DEPTH_MIN: float = 0.08
const GRAND_MAP_COASTAL_CARVE_DEPTH_MAX: float = 0.28
const GRAND_MAP_PENINSULA_CARVE_COUNT_MIN: int = 1
const GRAND_MAP_PENINSULA_CARVE_COUNT_MAX: int = 3
const GRAND_MAP_COAST_WOBBLE_AMPLITUDE_MIN: float = 0.040
const GRAND_MAP_COAST_WOBBLE_AMPLITUDE_MAX: float = 0.115

# Optional offshore islands.
const GRAND_MAP_ISLAND_COUNT_MIN: int = 0
const GRAND_MAP_ISLAND_COUNT_MAX: int = 4
const GRAND_MAP_ISLAND_SCALE_MIN: float = 0.14
const GRAND_MAP_ISLAND_SCALE_MAX: float = 0.32
const GRAND_MAP_ISLAND_DISTANCE_MIN: float = 0.16
const GRAND_MAP_ISLAND_DISTANCE_MAX: float = 0.42
const GRAND_MAP_ISLAND_MIN_CELLS: int = 6

# Province field generation inside the selected landmass.
const GRAND_MAP_PROVINCE_SEED_GRID_COLS: int = 7
const GRAND_MAP_PROVINCE_SEED_GRID_ROWS: int = 9
const GRAND_MAP_PROVINCE_CENTER_JITTER: float = 0.42
const GRAND_MAP_PROVINCE_VERTEX_JITTER: float = 0.24
const GRAND_MAP_PROVINCE_MIN_AREA: float = 85000.0
const GRAND_MAP_PROVINCE_MAX_AREA_FACTOR: float = 2.15
const GRAND_MAP_PROVINCE_MAX_BOUNDARY_PULL_PASSES: int = 5
const GRAND_MAP_PROVINCE_COASTAL_BIAS: float = 0.32

# Mountains outside the playable landmass are visible, bounceable, and no-spawn.
const GRAND_MAP_MOUNTAIN_RING_THICKNESS_CELLS: int = 3
const GRAND_MAP_MOUNTAIN_NOISE_STEPS: int = 2
const GRAND_MAP_MOUNTAIN_BASE_SHADE: Color = Color(0.23, 0.25, 0.29, 0.98)
const GRAND_MAP_MOUNTAIN_RIDGE_SHADE: Color = Color(0.45, 0.47, 0.51, 0.24)

# Start / enemy / target placement constraints on irregular landmasses.
const GRAND_MAP_START_AREA_MIN_FACTOR: float = 0.72
const GRAND_MAP_ENEMY_START_MIN_GRAPH_DISTANCE: int = 3
const GRAND_MAP_ENEMY_START_PREFERRED_GRAPH_DISTANCE: int = 5

# Per-template structural profiles. These are intentionally coarse archetypes; the generator deforms them
# hard enough that the result should feel continent-like without reading as Earth.
static func get_grand_map_template_profile(template_id: String) -> Dictionary:
	match template_id:
		GRAND_MAP_TEMPLATE_NORTH_AMERICA:
			return {
				"aspect_bias": Vector2(0.92, 0.82),
				"center_bias": Vector2(-0.12, -0.06),
				"fragmentation": 0.28,
				"east_west_bias": -0.18,
				"north_south_bias": -0.04,
				"bay_count_bonus": 1,
				"peninsula_bias": 0.50,
				"island_bonus": 1,
				"shape_variance": 0.34,
				"coast_variance": 0.38,
				"point_variance": 0.30,
				"bulge_variance": 0.24,
				"retain_secondary_components": 2,
			}
		GRAND_MAP_TEMPLATE_SOUTH_AMERICA:
			return {
				"aspect_bias": Vector2(0.70, 1.12),
				"center_bias": Vector2(-0.04, 0.04),
				"fragmentation": 0.10,
				"east_west_bias": 0.06,
				"north_south_bias": 0.10,
				"bay_count_bonus": 0,
				"peninsula_bias": 0.30,
				"island_bonus": 0,
				"shape_variance": 0.24,
				"coast_variance": 0.22,
				"point_variance": 0.20,
				"bulge_variance": 0.18,
				"retain_secondary_components": 1,
			}
		GRAND_MAP_TEMPLATE_EUROPE:
			return {
				"aspect_bias": Vector2(0.94, 0.72),
				"center_bias": Vector2(-0.02, -0.14),
				"fragmentation": 0.72,
				"east_west_bias": 0.04,
				"north_south_bias": -0.18,
				"bay_count_bonus": 2,
				"peninsula_bias": 0.62,
				"island_bonus": 2,
				"shape_variance": 0.40,
				"coast_variance": 0.46,
				"point_variance": 0.36,
				"bulge_variance": 0.22,
				"retain_secondary_components": 3,
			}
		GRAND_MAP_TEMPLATE_AFRICA:
			return {
				"aspect_bias": Vector2(0.82, 1.02),
				"center_bias": Vector2(0.02, 0.00),
				"fragmentation": 0.16,
				"east_west_bias": 0.10,
				"north_south_bias": 0.02,
				"bay_count_bonus": 1,
				"peninsula_bias": 0.34,
				"island_bonus": 0,
				"shape_variance": 0.28,
				"coast_variance": 0.26,
				"point_variance": 0.22,
				"bulge_variance": 0.20,
				"retain_secondary_components": 1,
			}
		GRAND_MAP_TEMPLATE_ASIA:
			return {
				"aspect_bias": Vector2(1.20, 0.80),
				"center_bias": Vector2(0.08, -0.02),
				"fragmentation": 0.46,
				"east_west_bias": 0.24,
				"north_south_bias": -0.06,
				"bay_count_bonus": 2,
				"peninsula_bias": 0.46,
				"island_bonus": 1,
				"shape_variance": 0.38,
				"coast_variance": 0.36,
				"point_variance": 0.34,
				"bulge_variance": 0.26,
				"retain_secondary_components": 2,
			}
		GRAND_MAP_TEMPLATE_AUSTRALIA:
			return {
				"aspect_bias": Vector2(0.94, 0.74),
				"center_bias": Vector2(0.02, 0.18),
				"fragmentation": 0.22,
				"east_west_bias": 0.02,
				"north_south_bias": 0.16,
				"bay_count_bonus": 1,
				"peninsula_bias": 0.22,
				"island_bonus": 1,
				"shape_variance": 0.26,
				"coast_variance": 0.24,
				"point_variance": 0.20,
				"bulge_variance": 0.16,
				"retain_secondary_components": 2,
			}
		GRAND_MAP_TEMPLATE_ANTARCTICA:
			return {
				"aspect_bias": Vector2(1.36, 0.56),
				"center_bias": Vector2(0.00, 0.26),
				"fragmentation": 0.44,
				"east_west_bias": 0.00,
				"north_south_bias": 0.28,
				"bay_count_bonus": 2,
				"peninsula_bias": 0.18,
				"island_bonus": 1,
				"shape_variance": 0.42,
				"coast_variance": 0.34,
				"point_variance": 0.34,
				"bulge_variance": 0.18,
				"retain_secondary_components": 3,
			}
		_:
			return {
				"aspect_bias": Vector2.ONE,
				"center_bias": Vector2.ZERO,
				"fragmentation": 0.25,
				"east_west_bias": 0.0,
				"north_south_bias": 0.0,
				"bay_count_bonus": 0,
				"peninsula_bias": 0.25,
				"island_bonus": 0,
				"shape_variance": 0.28,
				"coast_variance": 0.28,
				"point_variance": 0.24,
				"bulge_variance": 0.20,
				"retain_secondary_components": 1,
			}

# ==================== PROVINCE TYPES FOR ENGAGEMENT ROUTING (NEW) ====================
const PROVINCE_TYPE_NEUTRAL: String = "neutral"
const PROVINCE_TYPE_ENEMY: String = "enemy"
const PROVINCE_TYPE_FRIENDLY: String = "friendly"

const PROVINCE_ENEMY_COLOR: Color = Color(0.92, 0.28, 0.25, 0.22)  # legacy fallback
const PROVINCE_FRIENDLY_FILL_RGB: Color = Color(1.0, 1.0, 1.0, 1.0)
const PROVINCE_FRIENDLY_FILL_ALPHA: float = 0.42
const PROVINCE_FRIENDLY_INVADED_FILL_RGB: Color = Color(0.956, 0.961, 0.855, 1.0)
const PROVINCE_FRIENDLY_INVADED_FILL_ALPHA: float = 0.64
const PROVINCE_FRIENDLY_COLOR: Color = Color(1.0, 1.0, 1.0, 0.22)
const PROVINCE_FRIENDLY_INVADED_COLOR: Color = Color(0.907, 0.901, 0.773, 0.24)

static func color_with_alpha(base_color: Color, alpha: float) -> Color:
	var result := base_color
	result.a = clampf(alpha, 0.0, 1.0)
	return result

static func get_friendly_province_fill_color() -> Color:
	return color_with_alpha(PROVINCE_FRIENDLY_FILL_RGB, PROVINCE_FRIENDLY_FILL_ALPHA)

static func get_friendly_invaded_province_fill_color() -> Color:
	return color_with_alpha(PROVINCE_FRIENDLY_INVADED_FILL_RGB, PROVINCE_FRIENDLY_INVADED_FILL_ALPHA)

# ==================== TARGET PROVINCE (NEW - special non-contiguous capture point) ====================
# The target province always starts neutral, must not start contiguous to the player's launch province,
# and can be annexed without a friendly neighbor. Once captured it behaves like any other friendly province
# for ordinary contiguous expansion.
const TARGET_PROVINCE_FORCE_NEUTRAL_START: bool = true
const TARGET_PROVINCE_MIN_GRAPH_DISTANCE_FROM_START: int = 2
const TARGET_PROVINCE_PREFER_FARTHEST_FROM_START: bool = true
const TARGET_PROVINCE_LABEL_TEXT: String = "ANCESTRAL HOMELAND"
const TARGET_PROVINCE_FILL_TINT: Color = Color(1.0, 0.84, 0.20, 0.12)
const TARGET_PROVINCE_BORDER_COLOR: Color = Color(1.0, 0.83, 0.24, 0.98)
const TARGET_PROVINCE_BORDER_WIDTH_BONUS: float = 2.5
const TARGET_PROVINCE_INNER_GLOW_COLOR: Color = Color(1.0, 0.94, 0.56, 0.82)
const TARGET_PROVINCE_INNER_GLOW_WIDTH: float = 4.2
const TARGET_PROVINCE_INFO_BOX_BG_COLOR: Color = Color(0.22, 0.16, 0.02, 0.84)
const TARGET_PROVINCE_INFO_TEXT_COLOR: Color = Color(1.0, 0.95, 0.72, 1.0)

const PROVINCE_COUNTS_BOX_SIZE: Vector2 = Vector2(118, 24)
const PROVINCE_COUNTS_BOX_SIZE_INVADED: Vector2 = Vector2(176, 24)

# Grand-map province info labels (owner + province id + counts).
# Keep legacy counts-only constants above for compatibility while the UI is being upgraded.
const PROVINCE_INFO_BOX_SIZE: Vector2 = Vector2(156, 66)
const PROVINCE_INFO_BOX_SIZE_INVADED: Vector2 = Vector2(188, 66)
const PROVINCE_INFO_BOX_BG_COLOR: Color = Color(0.06, 0.08, 0.12, 0.62)
const PROVINCE_INFO_TEXT_COLOR: Color = Color(1.0, 0.97, 0.86, 0.98)
const PROVINCE_INFO_OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.85)
const PROVINCE_INFO_OUTLINE_SIZE: int = 3
const PROVINCE_INFO_OWNER_FONT_SIZE: int = 14
const PROVINCE_INFO_ID_FONT_SIZE: int = 13
const PROVINCE_INFO_COUNTS_FONT_SIZE: int = 15
const PROVINCE_INFO_LINE_HEIGHT: float = 19.0

# Province sprite-panel layout / icon normalization knobs.
# These let you dial in icon fit without changing code.
const PROVINCE_INFO_PANEL_DESIRED_WIDTH: float = 190.0
const PROVINCE_INFO_PANEL_FALLBACK_HEIGHT: float = 94.0
const PROVINCE_INFO_PANEL_OWNER_BADGE_POS: Vector2 = Vector2(8.0, 8.0)
const PROVINCE_INFO_PANEL_OWNER_BADGE_SLOT_SIZE: Vector2 = Vector2(24.0, 24.0)
const PROVINCE_INFO_PANEL_OWNER_BADGE_SCALE: float = 1.2
const PROVINCE_INFO_PANEL_BIOME_ICON_TOP: float = 3.0
const PROVINCE_INFO_PANEL_BIOME_ICON_RIGHT_MARGIN: float = 21.0
const PROVINCE_INFO_PANEL_BIOME_ICON_SLOT_SIZE: Vector2 = Vector2(40.0, 40.0)
const PROVINCE_INFO_PANEL_BIOME_ICON_SCALE: float = 6
const PROVINCE_INFO_PANEL_OWNER_LABEL_POS: Vector2 = Vector2(34.0, 11.0)
const PROVINCE_INFO_PANEL_OWNER_LABEL_RIGHT_MARGIN: float = 68.0
const PROVINCE_INFO_PANEL_NAME_LABEL_POS: Vector2 = Vector2(20.0, 29.0)
const PROVINCE_INFO_PANEL_NAME_LABEL_RIGHT_MARGIN: float = 40.0
const PROVINCE_INFO_PANEL_INVADERS_ICON_POS: Vector2 = Vector2(86.0, 6.0)
const PROVINCE_INFO_PANEL_INVADERS_ICON_SLOT_SIZE: Vector2 = Vector2(28.0, 28.0)
const PROVINCE_INFO_PANEL_INVADERS_ICON_SCALE: float = 1.35
const PROVINCE_INFO_PANEL_INVADERS_LABEL_POS: Vector2 = Vector2(112.0, 9.0)
const PROVINCE_INFO_PANEL_INVADERS_LABEL_SIZE: Vector2 = Vector2(24.0, 16.0)
const PROVINCE_INFO_PANEL_STAT_ROW_BOTTOM_MARGIN: float = 45.0
const PROVINCE_INFO_PANEL_STAT_ICON_X_OFFSETS := [10.0, 35.0, 64.0, 98.0, 135.0]
const PROVINCE_INFO_PANEL_STAT_ICON_SLOT_SIZE: Vector2 = Vector2(40.0, 40.0)
const PROVINCE_INFO_PANEL_STAT_ICON_SCALE_DEFAULT: float = 9
const PROVINCE_INFO_PANEL_TROOPS_ICON_SCALE: float = 1.5
const PROVINCE_INFO_PANEL_BUILDINGS_ICON_SCALE: float = 1.5
const PROVINCE_INFO_PANEL_GOLD_ICON_SCALE: float = 9
const PROVINCE_INFO_PANEL_FREE_ICON_SCALE: float = 1.5
const PROVINCE_INFO_PANEL_CAP_ICON_SCALE: float = 1.5
const PROVINCE_INFO_PANEL_STAT_LABEL_Y_OFFSET: float = -3.0
const PROVINCE_INFO_PANEL_STAT_VALUE_OFFSET_X: float = 14.0
const PROVINCE_INFO_PANEL_STAT_VALUE_WIDTH: float = 22.0
const PROVINCE_INFO_PANEL_FORCE_ICON_IGNORE_TEXTURE_SIZE: bool = true
const PROVINCE_INFO_PANEL_TRIM_ICON_TEXTURES: bool = true
# Controls the opacity of the sprite-based province info card background.
# 0.0 is fully transparent and 1.0 is fully opaque.
const PROVINCE_INFO_PANEL_BG_ALPHA: float = 0.82

static func get_province_info_panel_bg_alpha() -> float:
	return clampf(PROVINCE_INFO_PANEL_BG_ALPHA, 0.0, 1.0)

# ==================== PROCEDURAL PROVINCE NAMES (PHONEME-BASED) ====================
# The generator below is intentionally phoneme-based rather than prefix/suffix based.
# It builds province names from weighted onset / vowel / coda tables and then validates
# the result so names stay readable and grounded.
const PROVINCE_NAME_MIN_SYLLABLES: int = 2
const PROVINCE_NAME_MAX_SYLLABLES: int = 3
const PROVINCE_NAME_MIN_LENGTH: int = 4
const PROVINCE_NAME_MAX_LENGTH: int = 12
const PROVINCE_NAME_GENERATION_ATTEMPTS: int = 12
const PROVINCE_NAME_INITIAL_ONSETS := [
	"b", "br", "c", "d", "dr", "f", "g", "gr", "h", "k", "l", "m", "n", "r", "s", "st", "t", "th", "v", "w"
]
const PROVINCE_NAME_MEDIAL_ONSETS := [
	"b", "br", "c", "d", "dr", "f", "g", "gr", "h", "k", "l", "m", "n", "r", "s", "st", "t", "th", "v", "w",
	"bl", "cl", "gl", "pr", "tr"
]
const PROVINCE_NAME_VOWELS := [
	"a", "a", "e", "e", "i", "o", "o", "u", "ae", "ai", "ea", "ei", "ia", "oa", "ou"
]
const PROVINCE_NAME_MEDIAL_CODAS := [
	"", "", "", "n", "r", "l", "m", "s", "th", "nd", "rd", "rn", "sh", "k"
]
const PROVINCE_NAME_FINAL_CODAS := [
	"n", "r", "l", "m", "s", "th", "nd", "rd", "rn", "rk", "ld", "st", "sh", "ck", "t", "x"
]
const PROVINCE_NAME_FALLBACKS := [
	"Teren", "Morvain", "Dareth", "Velcor", "Halen", "Sorren", "Caldor", "Merin", "Bramor", "Torven"
]

static func _pick_province_name_table_entry(rng: RandomNumberGenerator, table: Array) -> String:
	if table.is_empty():
		return ""
	var index: int = rng.randi_range(0, table.size() - 1)
	return String(table[index])

static func _is_province_name_vowel(ch: String) -> bool:
	return ch == "a" or ch == "e" or ch == "i" or ch == "o" or ch == "u" or ch == "y"

static func _province_name_has_too_many_consecutive_consonants(candidate: String) -> bool:
	var consonant_run: int = 0
	for i in range(candidate.length()):
		var ch: String = candidate.substr(i, 1).to_lower()
		if _is_province_name_vowel(ch):
			consonant_run = 0
		else:
			consonant_run += 1
			if consonant_run > 3:
				return true
	return false

static func _province_name_has_triple_repeated_letters(candidate: String) -> bool:
	if candidate.length() < 3:
		return false
	for i in range(candidate.length() - 2):
		var a: String = candidate.substr(i, 1).to_lower()
		var b: String = candidate.substr(i + 1, 1).to_lower()
		var c: String = candidate.substr(i + 2, 1).to_lower()
		if a == b and b == c:
			return true
	return false

static func _province_name_has_duplicate_adjacent_syllables(candidate: String) -> bool:
	var lowered: String = candidate.to_lower()
	for size in range(2, 5):
		if lowered.length() < size * 2:
			continue
		for i in range(lowered.length() - size * 2 + 1):
			var left: String = lowered.substr(i, size)
			var right: String = lowered.substr(i + size, size)
			if left == right:
				return true
	return false

static func _normalize_generated_province_name(raw_name: String) -> String:
	var candidate: String = raw_name.strip_edges()
	while candidate.find("''") != -1:
		candidate = candidate.replace("''", "'")
	for repeated_letter in ["aa", "ee", "ii", "uu"]:
		if candidate.find(repeated_letter) != -1:
			candidate = candidate.replace(repeated_letter, repeated_letter.substr(0, 1))
	if candidate.length() <= 1:
		return candidate.capitalize()
	return candidate.substr(0, 1).to_upper() + candidate.substr(1).to_lower()

static func _is_valid_generated_province_name(candidate: String) -> bool:
	var lowered: String = candidate.to_lower()
	if lowered.length() < PROVINCE_NAME_MIN_LENGTH or lowered.length() > PROVINCE_NAME_MAX_LENGTH:
		return false
	if _province_name_has_too_many_consecutive_consonants(lowered):
		return false
	if _province_name_has_triple_repeated_letters(lowered):
		return false
	if _province_name_has_duplicate_adjacent_syllables(lowered):
		return false
	if not _is_province_name_vowel(lowered.substr(0, 1)):
		var has_any_vowel: bool = false
		for i in range(lowered.length()):
			if _is_province_name_vowel(lowered.substr(i, 1)):
				has_any_vowel = true
				break
		if not has_any_vowel:
			return false
	return true

static func _hash_province_name_seed(world_seed: int, province_id: int) -> int:
	var value: int = int(world_seed)
	value = int((value * 1103515245 + 12345 + province_id * 7919) & 0x7fffffff)
	if value == 0:
		value = province_id + 1
	return value

static func _generate_province_name_candidate(rng: RandomNumberGenerator) -> String:
	var syllable_count: int = PROVINCE_NAME_MIN_SYLLABLES
	if PROVINCE_NAME_MAX_SYLLABLES > PROVINCE_NAME_MIN_SYLLABLES and rng.randf() < 0.34:
		syllable_count += 1
	var parts: Array[String] = []
	for syllable_index in range(syllable_count):
		var onset_table = PROVINCE_NAME_INITIAL_ONSETS if syllable_index == 0 else PROVINCE_NAME_MEDIAL_ONSETS
		var coda_table = PROVINCE_NAME_FINAL_CODAS if syllable_index == syllable_count - 1 else PROVINCE_NAME_MEDIAL_CODAS
		var onset: String = _pick_province_name_table_entry(rng, onset_table)
		var vowel: String = _pick_province_name_table_entry(rng, PROVINCE_NAME_VOWELS)
		var coda: String = _pick_province_name_table_entry(rng, coda_table)
		if syllable_index > 0 and parts.size() > 0:
			var previous: String = parts[parts.size() - 1]
			if previous.length() > 0 and onset.length() > 0 and previous.substr(previous.length() - 1, 1).to_lower() == onset.substr(0, 1).to_lower():
				onset = onset.substr(1)
		parts.append(onset + vowel + coda)
	return "".join(parts)

static func generate_province_name(world_seed: int, province_id: int) -> String:
	var base_seed: int = _hash_province_name_seed(world_seed, province_id)
	for attempt in range(PROVINCE_NAME_GENERATION_ATTEMPTS):
		var rng := RandomNumberGenerator.new()
		rng.seed = int((base_seed + attempt * 104729) & 0x7fffffff)
		var candidate: String = _normalize_generated_province_name(_generate_province_name_candidate(rng))
		if _is_valid_generated_province_name(candidate):
			return candidate
	return String(PROVINCE_NAME_FALLBACKS[abs(province_id + base_seed) % PROVINCE_NAME_FALLBACKS.size()])

# ==================== PROVINCE BUILDING / TROOP COUNTS (INITIAL SPAWN VS. NEWLY CONQUERED) ====================
# These are intentionally split so first-turn grand-map setup can diverge from what a province gets
# when it is newly conquered later in the run.
const INITIAL_PROVINCE_ENEMY_BUILDINGS: int = 3
const INITIAL_PROVINCE_ENEMY_TROOPS: int = 16
const INITIAL_PROVINCE_FRIENDLY_BUILDINGS: int = 2
const INITIAL_PROVINCE_FRIENDLY_TROOPS: int = 16
const FIRST_LEVEL_INITIAL_PROVINCE_FRIENDLY_TROOPS_BONUS: int = 10
const INITIAL_PROVINCE_NEUTRAL_BUILDINGS: int = 0
const INITIAL_PROVINCE_NEUTRAL_TROOPS: int = 6
const INITIAL_PROVINCE_BOSS_BUILDINGS: int = 4
const INITIAL_PROVINCE_BOSS_TROOPS: int = 20

# Conquered-province defaults. Some conquest paths preserve surviving troops instead of replacing them,
# but these knobs exist so conquest-specific seeding can be tuned independently from the map-start state.
const CONQUERED_PROVINCE_ENEMY_BUILDINGS: int = 3
const CONQUERED_PROVINCE_ENEMY_TROOPS: int = 12
const CONQUERED_PROVINCE_FRIENDLY_BUILDINGS: int = 3
const CONQUERED_PROVINCE_FRIENDLY_TROOPS: int = 16
const FIRST_LEVEL_CONQUERED_PROVINCE_FRIENDLY_TROOPS_BONUS: int = 10
const CONQUERED_ANCESTRAL_HOMELAND_FRIENDLY_BUILDINGS: int = 5
const CONQUERED_ANCESTRAL_HOMELAND_FRIENDLY_TROOPS: int = 20
const CONQUERED_PROVINCE_BOSS_BUILDINGS: int = 3
const CONQUERED_PROVINCE_BOSS_TROOPS: int = 14
static var _runtime_initial_province_friendly_troops: int = INITIAL_PROVINCE_FRIENDLY_TROOPS
static var _runtime_conquered_province_friendly_troops: int = CONQUERED_PROVINCE_FRIENDLY_TROOPS
static var _runtime_campaign_enemy_troop_increase_per_level: int = CAMPAIGN_ENEMY_TROOP_INCREASE_PER_LEVEL
static var _runtime_campaign_enemy_troop_level_bonus_total: int = 0

static func get_initial_province_buildings(province_type: String) -> int:
	match province_type:
		PROVINCE_TYPE_ENEMY:
			return INITIAL_PROVINCE_ENEMY_BUILDINGS
		PROVINCE_TYPE_FRIENDLY:
			return INITIAL_PROVINCE_FRIENDLY_BUILDINGS
		_:
			return INITIAL_PROVINCE_NEUTRAL_BUILDINGS

static func is_numbered_campaign_level_one(campaign_level: int, opening_tutorial_active: bool) -> bool:
	return campaign_level == 1 and not opening_tutorial_active


static func get_first_level_initial_province_friendly_troops_bonus() -> int:
	return maxi(0, FIRST_LEVEL_INITIAL_PROVINCE_FRIENDLY_TROOPS_BONUS)


static func get_first_level_conquered_province_friendly_troops_bonus() -> int:
	return maxi(0, FIRST_LEVEL_CONQUERED_PROVINCE_FRIENDLY_TROOPS_BONUS)


static func get_runtime_initial_province_friendly_troops_for_level(campaign_level: int, opening_tutorial_active: bool = false) -> int:
	var troops: int = get_runtime_initial_province_friendly_troops()
	if is_numbered_campaign_level_one(campaign_level, opening_tutorial_active):
		troops += get_first_level_initial_province_friendly_troops_bonus()
	return maxi(1, troops)


static func get_runtime_conquered_province_friendly_troops_for_level(campaign_level: int, opening_tutorial_active: bool = false) -> int:
	var troops: int = get_runtime_conquered_province_friendly_troops()
	if is_numbered_campaign_level_one(campaign_level, opening_tutorial_active):
		troops += get_first_level_conquered_province_friendly_troops_bonus()
	return maxi(1, troops)


static func get_initial_province_troops(province_type: String) -> int:
	match province_type:
		PROVINCE_TYPE_ENEMY:
			return maxi(0, INITIAL_PROVINCE_ENEMY_TROOPS + _runtime_campaign_enemy_troop_level_bonus_total)
		PROVINCE_TYPE_FRIENDLY:
			return get_runtime_initial_province_friendly_troops()
		_:
			return INITIAL_PROVINCE_NEUTRAL_TROOPS

static func get_conquered_province_buildings(province_type: String) -> int:
	match province_type:
		PROVINCE_TYPE_ENEMY:
			return CONQUERED_PROVINCE_ENEMY_BUILDINGS
		PROVINCE_TYPE_FRIENDLY:
			return CONQUERED_PROVINCE_FRIENDLY_BUILDINGS
		_:
			return INITIAL_PROVINCE_NEUTRAL_BUILDINGS

static func get_conquered_province_troops(province_type: String) -> int:
	match province_type:
		PROVINCE_TYPE_ENEMY:
			return CONQUERED_PROVINCE_ENEMY_TROOPS
		PROVINCE_TYPE_FRIENDLY:
			return get_runtime_conquered_province_friendly_troops()
		_:
			return INITIAL_PROVINCE_NEUTRAL_TROOPS

static func get_default_initial_province_friendly_troops() -> int:
	return maxi(1, INITIAL_PROVINCE_FRIENDLY_TROOPS)

static func get_default_conquered_province_friendly_troops() -> int:
	return maxi(1, CONQUERED_PROVINCE_FRIENDLY_TROOPS)

static func get_runtime_initial_province_friendly_troops() -> int:
	return maxi(1, _runtime_initial_province_friendly_troops)

static func get_runtime_conquered_province_friendly_troops() -> int:
	return maxi(1, _runtime_conquered_province_friendly_troops)

static func get_runtime_campaign_enemy_troop_increase_per_level() -> int:
	return maxi(0, _runtime_campaign_enemy_troop_increase_per_level)

static func get_runtime_campaign_enemy_troop_level_bonus_total() -> int:
	return maxi(0, _runtime_campaign_enemy_troop_level_bonus_total)

static func set_runtime_campaign_enemy_troop_level_bonus_total(total_bonus: int) -> void:
	_runtime_campaign_enemy_troop_level_bonus_total = maxi(0, total_bonus)

static func get_conquered_ancestral_homeland_buildings() -> int:
	return CONQUERED_ANCESTRAL_HOMELAND_FRIENDLY_BUILDINGS

static func get_conquered_ancestral_homeland_troops() -> int:
	return CONQUERED_ANCESTRAL_HOMELAND_FRIENDLY_TROOPS

static func get_initial_boss_province_buildings() -> int:
	return INITIAL_PROVINCE_BOSS_BUILDINGS

static func get_initial_boss_province_troops() -> int:
	return INITIAL_PROVINCE_BOSS_TROOPS

static func get_conquered_boss_province_buildings() -> int:
	return CONQUERED_PROVINCE_BOSS_BUILDINGS

static func get_conquered_boss_province_troops() -> int:
	return CONQUERED_PROVINCE_BOSS_TROOPS

# Legacy compatibility aliases. Existing runtime code may still reference these while the rest of the
# change set is being applied file-by-file. They currently mean "initial province counts."
const PROVINCE_ENEMY_BUILDINGS: int = INITIAL_PROVINCE_ENEMY_BUILDINGS
const PROVINCE_ENEMY_TROOPS: int = INITIAL_PROVINCE_ENEMY_TROOPS
const PROVINCE_FRIENDLY_BUILDINGS: int = INITIAL_PROVINCE_FRIENDLY_BUILDINGS
const PROVINCE_FRIENDLY_TROOPS: int = INITIAL_PROVINCE_FRIENDLY_TROOPS
const PROVINCE_NEUTRAL_BUILDINGS: int = INITIAL_PROVINCE_NEUTRAL_BUILDINGS
const PROVINCE_NEUTRAL_TROOPS: int = INITIAL_PROVINCE_NEUTRAL_TROOPS

# Province construction economy (NEW - dynamic building growth on the Grand Map).
# Applies to friendly, enemy, and neutral provinces. A province only contributes labor
# if it has at least this many resident troops. Labor is stored persistently as troop-turns.
# Every full labor threshold converts into +1 building and any remainder carries forward.
const PROVINCE_BUILDING_MIN_TROOPS_TO_BUILD: int = 10
const PROVINCE_BUILDING_TROOP_TURNS_PER_BUILDING: int = 30
const PROVINCE_BUILDING_CAP: int = 8

# Province variability ratings.
# These are intended to be rolled once per province from the grand-map seed and then stored
# in persistence so they remain stable for the whole campaign loop.
const PROVINCE_GOLD_PRODUCTION_MIN: int = 0
const PROVINCE_GOLD_PRODUCTION_MAX: int = 4
const PROVINCE_FREE_BUILDINGS_MIN: int = 0
const PROVINCE_FREE_BUILDINGS_MAX: int = 3
const PROVINCE_BUILDING_CAP_MIN: int = 5
const PROVINCE_BUILDING_CAP_MAX: int = 15

const ENGAGEMENT_MAP_TYPE_NORMAL: String = "normal"
const ENGAGEMENT_MAP_TYPE_JUNGLE: String = "jungle"
const ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING: String = "rock_outcropping"
const ENGAGEMENT_MAP_TYPE_SETTLEMENT: String = "settlement"

const ENGAGEMENT_MAP_TYPE_VALUES := [
	ENGAGEMENT_MAP_TYPE_NORMAL,
	ENGAGEMENT_MAP_TYPE_JUNGLE,
	ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING,
	ENGAGEMENT_MAP_TYPE_SETTLEMENT,
]

static func clamp_province_gold_production(value: int) -> int:
	return clampi(value, PROVINCE_GOLD_PRODUCTION_MIN, PROVINCE_GOLD_PRODUCTION_MAX)

static func clamp_province_free_buildings(value: int) -> int:
	return clampi(value, PROVINCE_FREE_BUILDINGS_MIN, PROVINCE_FREE_BUILDINGS_MAX)

static func clamp_province_building_cap(value: int) -> int:
	return clampi(value, PROVINCE_BUILDING_CAP_MIN, PROVINCE_BUILDING_CAP_MAX)

static func normalize_engagement_map_type(map_type: String) -> String:
	var normalized: String = String(map_type).strip_edges().to_lower()
	match normalized:
		ENGAGEMENT_MAP_TYPE_JUNGLE, ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING, ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return normalized
		_:
			return ENGAGEMENT_MAP_TYPE_NORMAL

static func get_engagement_map_type_display_name(map_type: String) -> String:
	match normalize_engagement_map_type(map_type):
		ENGAGEMENT_MAP_TYPE_JUNGLE:
			return "Jungle"
		ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING:
			return "Rock Outcropping"
		ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return "Settlement"
		_:
			return "Normal"

static func get_engagement_map_obstacle_multiplier(map_type: String) -> float:
	match normalize_engagement_map_type(map_type):
		ENGAGEMENT_MAP_TYPE_JUNGLE:
			return 0.72
		ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING:
			return 1.75
		ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return 0.70
		_:
			return 1.0

static func get_engagement_map_friction_multiplier(map_type: String) -> float:
	match normalize_engagement_map_type(map_type):
		ENGAGEMENT_MAP_TYPE_JUNGLE:
			return 1.28
		ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING:
			return 0.58
		ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return 0.86
		_:
			return 1.0

static func get_engagement_map_water_multiplier(map_type: String) -> float:
	match normalize_engagement_map_type(map_type):
		ENGAGEMENT_MAP_TYPE_JUNGLE:
			return 1.18
		ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING:
			return 0.55
		ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return 0.86
		_:
			return 1.0

# Positive values bias ambient friction zones toward oil / boardwalk templates.
# Negative values bias toward grass / bushes.
static func get_engagement_map_oil_probability_bias(map_type: String) -> float:
	match normalize_engagement_map_type(map_type):
		ENGAGEMENT_MAP_TYPE_JUNGLE:
			return -0.24
		ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING:
			return -0.08
		ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return 0.34
		_:
			return 0.0

# ==================== ENGAGEMENT GENERATION IDENTITIES ====================
const PHASE_OFFENSIVE: String = "offensive"
const PHASE_DEFENSIVE: String = "defensive"
const PHASE_NEUTRAL: String = "neutral"
const PHASE_GRAND_MAP: String = "grand_map"

# ==================== OFFENSIVE LOGICAL BUILDING DAMAGE ====================
# Offensive engagements no longer need physical building objects on the map.
# Instead, building destruction is computed from the percentage of enemy pins
# knocked down during the shot, then capped by how many buildings the province
# currently has.
const OFFENSIVE_LOGICAL_BUILDING_DAMAGE_START_PERCENT: int = 50
const OFFENSIVE_LOGICAL_BUILDING_DAMAGE_STEP_PERCENT: int = 10
const OFFENSIVE_LOGICAL_BUILDING_DAMAGE_MAX: int = 5

static func get_offensive_pin_downed_fraction(total_pins: int, downed_pins: int) -> float:
	if total_pins <= 0:
		return 0.0
	return clampf(float(maxi(0, downed_pins)) / float(total_pins), 0.0, 1.0)

static func get_offensive_logical_destroyed_buildings(total_pins: int, downed_pins: int, available_buildings: int) -> int:
	var safe_available_buildings: int = maxi(0, available_buildings)
	if safe_available_buildings <= 0:
		return 0

	var downed_percent: float = get_offensive_pin_downed_fraction(total_pins, downed_pins) * 100.0
	if downed_percent < float(OFFENSIVE_LOGICAL_BUILDING_DAMAGE_START_PERCENT):
		return 0

	var threshold_steps: int = int(floor((downed_percent - float(OFFENSIVE_LOGICAL_BUILDING_DAMAGE_START_PERCENT)) / float(OFFENSIVE_LOGICAL_BUILDING_DAMAGE_STEP_PERCENT)))
	var destroyed_buildings: int = 1 + threshold_steps
	return mini(safe_available_buildings, mini(OFFENSIVE_LOGICAL_BUILDING_DAMAGE_MAX, destroyed_buildings))

# ==================== PHASE-SPECIFIC PIN PLACEMENT TUNING ====================
# These values are added on top of the shared base pin spacing / obstacle-clearance rules.
# Use them to spread out or tighten troops independently for neutral, enemy-offense, and defensive boards.
const PHASE_PIN_EXTRA_SEPARATION_OFFENSIVE: float = 0.0
const PHASE_PIN_EXTRA_SEPARATION_DEFENSIVE: float = 0.0
const PHASE_PIN_EXTRA_SEPARATION_NEUTRAL: float = 24.0

const PHASE_PIN_EXTRA_OBSTACLE_CLEARANCE_OFFENSIVE: float = 0.0
const PHASE_PIN_EXTRA_OBSTACLE_CLEARANCE_DEFENSIVE: float = 0.0
const PHASE_PIN_EXTRA_OBSTACLE_CLEARANCE_NEUTRAL: float = 52.0

# For structured group-based layouts, this tunes how tightly troops cluster around a group center.
# Higher values spread them farther within the same motif.
const PHASE_PIN_GROUP_SIGMA_MULT_OFFENSIVE: float = 0.32
const PHASE_PIN_GROUP_SIGMA_MULT_DEFENSIVE: float = 0.32
const PHASE_PIN_GROUP_SIGMA_MULT_NEUTRAL: float = 0.40

static func get_phase_pin_extra_separation(phase: String) -> float:
	match phase:
		PHASE_OFFENSIVE:
			return PHASE_PIN_EXTRA_SEPARATION_OFFENSIVE
		PHASE_DEFENSIVE:
			return PHASE_PIN_EXTRA_SEPARATION_DEFENSIVE
		PHASE_NEUTRAL:
			return PHASE_PIN_EXTRA_SEPARATION_NEUTRAL
		_:
			return 0.0

static func get_phase_pin_extra_obstacle_clearance(phase: String) -> float:
	match phase:
		PHASE_OFFENSIVE:
			return PHASE_PIN_EXTRA_OBSTACLE_CLEARANCE_OFFENSIVE
		PHASE_DEFENSIVE:
			return PHASE_PIN_EXTRA_OBSTACLE_CLEARANCE_DEFENSIVE
		PHASE_NEUTRAL:
			return PHASE_PIN_EXTRA_OBSTACLE_CLEARANCE_NEUTRAL
		_:
			return 0.0

static func get_phase_pin_group_sigma_multiplier(phase: String) -> float:
	match phase:
		PHASE_OFFENSIVE:
			return PHASE_PIN_GROUP_SIGMA_MULT_OFFENSIVE
		PHASE_DEFENSIVE:
			return PHASE_PIN_GROUP_SIGMA_MULT_DEFENSIVE
		PHASE_NEUTRAL:
			return PHASE_PIN_GROUP_SIGMA_MULT_NEUTRAL
		_:
			return PHASE_PIN_GROUP_SIGMA_MULT_DEFENSIVE

static func get_building_size_multiplier_for_phase(phase: String) -> float:
	if phase == PHASE_DEFENSIVE:
		return maxf(0.05, DEFENSIVE_ENGAGEMENT_BUILDING_SIZE_MULT)
	return 1.0

# Enemy offense should feel like an intentional defended position.
# The player can launch from anywhere, so these motifs are built around protected
# relationships, offset cover, channels, banks, and exposed-vs-shielded value
# rather than assuming a single frontal approach.
const ENEMY_OFFENSE_MOTIF_PROTECTED_CORE: String = "protected_core"
const ENEMY_OFFENSE_MOTIF_LAYERED_SHELL: String = "layered_shell"
const ENEMY_OFFENSE_MOTIF_FLANK_LANE: String = "flank_lane"
const ENEMY_OFFENSE_MOTIF_CHOKE_OPENING: String = "choke_opening"
const ENEMY_OFFENSE_MOTIF_SPLIT_DEFENSE: String = "split_defense"
const ENEMY_OFFENSE_MOTIF_BANK_AND_COLLAPSE: String = "bank_and_collapse"

const ENEMY_OFFENSE_MOTIF_WEIGHTS: Dictionary = {
	ENEMY_OFFENSE_MOTIF_PROTECTED_CORE: 1.10,
	ENEMY_OFFENSE_MOTIF_LAYERED_SHELL: 1.00,
	ENEMY_OFFENSE_MOTIF_FLANK_LANE: 1.00,
	ENEMY_OFFENSE_MOTIF_CHOKE_OPENING: 0.90,
	ENEMY_OFFENSE_MOTIF_SPLIT_DEFENSE: 1.00,
	ENEMY_OFFENSE_MOTIF_BANK_AND_COLLAPSE: 0.85,
}

# Neutral offense should feel cleaner and more inviting, with easier-to-read value.
const NEUTRAL_OFFENSE_MOTIF_OPEN_FAN: String = "open_fan"
const NEUTRAL_OFFENSE_MOTIF_SOFT_SPLIT: String = "soft_split"
const NEUTRAL_OFFENSE_MOTIF_EXPOSED_POCKET: String = "exposed_pocket"
const NEUTRAL_OFFENSE_MOTIF_CLEAN_RICOCHET: String = "clean_ricochet"
const NEUTRAL_OFFENSE_MOTIF_LIGHT_STAGGER: String = "light_stagger"

const NEUTRAL_OFFENSE_MOTIF_WEIGHTS: Dictionary = {
	NEUTRAL_OFFENSE_MOTIF_OPEN_FAN: 1.15,
	NEUTRAL_OFFENSE_MOTIF_SOFT_SPLIT: 1.00,
	NEUTRAL_OFFENSE_MOTIF_EXPOSED_POCKET: 1.05,
	NEUTRAL_OFFENSE_MOTIF_CLEAN_RICOCHET: 0.90,
	NEUTRAL_OFFENSE_MOTIF_LIGHT_STAGGER: 1.10,
}

# Defense is intentionally left on its current generator for now.
# These values support only offensive/neutral differentiation in this pass.
const ENEMY_OFFENSE_TEMPLATE_BUDGET_MIN: int = 4
const ENEMY_OFFENSE_TEMPLATE_BUDGET_MAX: int = 6
const ENEMY_OFFENSE_FRICTION_MIN: int = 6
const ENEMY_OFFENSE_FRICTION_MAX: int = 8
const ENEMY_OFFENSE_WATER_MIN: int = 1
const ENEMY_OFFENSE_WATER_MAX: int = 2
const ENEMY_OFFENSE_GRADE_MIN: int = 1
const ENEMY_OFFENSE_GRADE_MAX: int = 2

const NEUTRAL_OFFENSE_TEMPLATE_BUDGET_MIN: int = 2
const NEUTRAL_OFFENSE_TEMPLATE_BUDGET_MAX: int = 4
const NEUTRAL_OFFENSE_FRICTION_MIN: int = 4
const NEUTRAL_OFFENSE_FRICTION_MAX: int = 6
const NEUTRAL_OFFENSE_WATER_MIN: int = 0
const NEUTRAL_OFFENSE_WATER_MAX: int = 1
const NEUTRAL_OFFENSE_GRADE_MIN: int = 0
const NEUTRAL_OFFENSE_GRADE_MAX: int = 1

const ENEMY_OFFENSE_CORE_RADIUS_MIN: float = 70.0
const ENEMY_OFFENSE_CORE_RADIUS_MAX: float = 120.0
const ENEMY_OFFENSE_GUARD_RING_RADIUS_MIN: float = 120.0
const ENEMY_OFFENSE_GUARD_RING_RADIUS_MAX: float = 210.0
const ENEMY_OFFENSE_OFFSET_COVER_DISTANCE_MIN: float = 110.0
const ENEMY_OFFENSE_OFFSET_COVER_DISTANCE_MAX: float = 250.0
const ENEMY_OFFENSE_LANE_WIDTH_MIN: float = 105.0
const ENEMY_OFFENSE_LANE_WIDTH_MAX: float = 180.0
const ENEMY_OFFENSE_SPLIT_GAP_MIN: float = 120.0
const ENEMY_OFFENSE_SPLIT_GAP_MAX: float = 210.0
const ENEMY_OFFENSE_BANK_OFFSET_MIN: float = 130.0
const ENEMY_OFFENSE_BANK_OFFSET_MAX: float = 220.0

const NEUTRAL_OFFENSE_CLUSTER_RADIUS_MIN: float = 75.0
const NEUTRAL_OFFENSE_CLUSTER_RADIUS_MAX: float = 135.0
const NEUTRAL_OFFENSE_OPEN_SPREAD_MIN: float = 150.0
const NEUTRAL_OFFENSE_OPEN_SPREAD_MAX: float = 270.0
const NEUTRAL_OFFENSE_STAGGER_STEP_MIN: float = 70.0
const NEUTRAL_OFFENSE_STAGGER_STEP_MAX: float = 125.0
const NEUTRAL_OFFENSE_POCKET_OFFSET_MIN: float = 100.0
const NEUTRAL_OFFENSE_POCKET_OFFSET_MAX: float = 180.0
const NEUTRAL_OFFENSE_CLEAR_LANE_MIN: float = 150.0
const NEUTRAL_OFFENSE_CLEAR_LANE_MAX: float = 240.0

const ENEMY_OFFENSE_HEAVY_ROLE_WEIGHT_MULTIPLIER: float = 1.45
const ENEMY_OFFENSE_SPIKY_ROLE_WEIGHT_MULTIPLIER: float = 1.15
const ENEMY_OFFENSE_RUNNER_ROLE_WEIGHT_MULTIPLIER: float = 0.75
const ENEMY_OFFENSE_CHIEF_ROLE_WEIGHT_MULTIPLIER: float = 0.95

const NEUTRAL_OFFENSE_HEAVY_ROLE_WEIGHT_MULTIPLIER: float = 0.82
const NEUTRAL_OFFENSE_SPIKY_ROLE_WEIGHT_MULTIPLIER: float = 0.55
const NEUTRAL_OFFENSE_RUNNER_ROLE_WEIGHT_MULTIPLIER: float = 0.65
const NEUTRAL_OFFENSE_CHIEF_ROLE_WEIGHT_MULTIPLIER: float = 0.45

# ==================== ENGAGEMENT WIN CONDITIONS (UNIFIED - March 2026) ====================
const ENGAGEMENT_WIN_THRESHOLD: float = 0.50  # 50% of enemies downed for ALL player engagements
const NEUTRAL_WIN_THRESHOLD: float = 1.0      # 100% required for neutral provinces (conquest trigger)

# ==================== ENEMY RECRUITMENT (NEW - after every player turn) ====================
const ENEMY_RECRUITMENT_PER_BUILDING: int = 1

# ==================== ENEMY / FRIENDLY / BOSS MARCH (NEW - after recruitment on every enemy turn) ====================
const FRIENDLY_MARCH_THRESHOLD: int = 20
const ENEMY_MARCH_THRESHOLD: int = 15
const BOSS_MARCH_THRESHOLD: int = 15
const ENEMY_MARCH_LEAVE_BEHIND: int = 5
const ENEMY_MARCH_CAPTURE_BUILDINGS: int = 2

# ==================== INVASION RESOLUTION (NEW - occupied friendly provinces) ====================
const INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT: int = 3

# ==================== STATIC BUILDINGS (visual variety - irrelevant for win) ====================
const BUILDING_WIDTH_MIN: float = 65.0
const BUILDING_WIDTH_MAX: float = 105.0
const BUILDING_HEIGHT_MIN: float = 95.0
const BUILDING_HEIGHT_MAX: float = 135.0

# Multiplies physical building width/height only for defensive engagement boards.
# 1.0 preserves the current size, values below 1.0 shrink buildings, values above 1.0 enlarge them.
const DEFENSIVE_ENGAGEMENT_BUILDING_SIZE_MULT: float = 1.8

const BUILDING_SLOWDOWN_FACTOR: float = 0.68
const BUILDING_BOUNCE: float = 0.35
const BUILDING_DESTRUCTION_THRESHOLD: float = 72.0  # NEW: pretty easy to break (tuned for satisfying one-hit feel)
const BUILDING_WINDOW_COLOR: Color = Color(0.95, 0.98, 1.0, 1.0)
const BUILDING_DOOR_COLOR: Color = Color(0.25, 0.18, 0.12, 1.0)
const BUILDING_ROOF_DARKEN: float = 0.35
const BUILDING_IMPRINT_COLOR: Color = Color(0.3, 0.22, 0.12, 0.35)

# ==================== ZONE PLACEMENT ====================
const ZONE_SCALE_MIN: float = 0.55
const ZONE_SCALE_MAX: float = 1.75
const GRASS_ASPECT_MIN: float = 0.45
const GRASS_ASPECT_MAX: float = 2.20
const OIL_ASPECT_MIN: float = 0.60
const OIL_ASPECT_MAX: float = 2.50
const WATER_ASPECT_MIN: float = 0.70
const WATER_ASPECT_MAX: float = 2.30
const ZONE_PLACEMENT_OVERHANG: float = 220.0

const WATER_OVERLAP_KILL_RATIO: float = 0.50
# Ball water trigger: 0.0 means the ball sinks when its center first touches visible water.
# Positive values expand the trigger outward (earlier sink); negative values shrink it inward (deeper overlap before sink).
const WATER_BALL_CENTER_TRIGGER_OFFSET: float = 0.0
const WATER_EDGE_AVOIDANCE_PADDING: float = 44.0
const WATER_SPAWN_CLEARANCE: float = 14.0
const WATER_ZONE_BASE_COUNT: int = 2
const WATER_ZONE_EXTRA_PER_LEVEL: float = 0.08
const WATER_ZONE_HARD_CAP: int = 4

# Shared obstacle-pressure tuning for both water and rocks.
# These values are intended to keep the current generator structure intact while
# making edge-case choke maps much less common without any expensive validation pass.
# Larger obstacle templates consume more pressure through component count and footprint size.
const MAJOR_OBSTACLE_SOFT_BUDGET: float = 10.5
const MAJOR_OBSTACLE_ACCEPT_SCORE: float = 1.8
const MAJOR_OBSTACLE_RANGE_SCALE: float = 1.18
const MAJOR_OBSTACLE_HARD_OVERLAP_SCALE: float = 0.74
const MAJOR_OBSTACLE_GLOBAL_PRESSURE_SCALE: float = 0.42
const MAJOR_OBSTACLE_COMPONENT_BASE_WEIGHT: float = 0.85
const MAJOR_OBSTACLE_RADIUS_WEIGHT_DIVISOR: float = 120.0

static func get_major_obstacle_soft_budget() -> float:
	return maxf(0.0, MAJOR_OBSTACLE_SOFT_BUDGET)

static func get_major_obstacle_accept_score() -> float:
	return maxf(0.0, MAJOR_OBSTACLE_ACCEPT_SCORE)

static func get_major_obstacle_range_scale() -> float:
	return maxf(0.1, MAJOR_OBSTACLE_RANGE_SCALE)

static func get_major_obstacle_hard_overlap_scale() -> float:
	return clampf(MAJOR_OBSTACLE_HARD_OVERLAP_SCALE, 0.1, 2.0)

static func get_major_obstacle_global_pressure_scale() -> float:
	return maxf(0.0, MAJOR_OBSTACLE_GLOBAL_PRESSURE_SCALE)

static func get_major_obstacle_component_base_weight() -> float:
	return maxf(0.0, MAJOR_OBSTACLE_COMPONENT_BASE_WEIGHT)

static func get_major_obstacle_radius_weight_divisor() -> float:
	return maxf(1.0, MAJOR_OBSTACLE_RADIUS_WEIGHT_DIVISOR)

# ==================== GRADE VISUALS ====================
const GRADE_ARROW_BASE_COLOR: Color = Color(1.0, 0.85, 0.2, 0.95)
const GRADE_ARROW_DARK_COLOR: Color = Color(0.9, 0.6, 0.0, 0.8)
const GRADE_ARROW_DARK_MULTIPLIER: float = 0.58
const GRADE_ARROW_MIN_STRENGTH_FOR_DARK: float = 280.0
const GRADE_TEMPLATE_COUNT: int = 1
const GRADE_LARGE_BASE_RADIUS: float = 520.0
const GRADE_SCALE_MIN: float = 1.1
const GRADE_SCALE_MAX: float = 2.4

# ==================== BALL PHYSICS & INPUT ====================
const BALL_RADIUS_MIN_GRAND_MAP: float = 18.0

# ==================== CAMPAIGN LEVEL PROGRESSION ====================
# The run now tracks a fixed-length 10-step campaign. Each completed map advances
# toward the final level. Easy clears advance 1 step. Hard clears advance 2 steps.
# Level 10 is still a normal map for now, but the progression scaffolding is in
# place so a custom final-boss map can be swapped in later.
const CAMPAIGN_TOTAL_LEVELS: int = 10
const CAMPAIGN_FINAL_LEVEL_INDEX: int = 10
const CAMPAIGN_LEVEL_MODE_EASY: String = "easy"
const CAMPAIGN_LEVEL_MODE_HARD: String = "hard"
const CAMPAIGN_EASY_STEP_ADVANCE: int = 1
const CAMPAIGN_HARD_STEP_ADVANCE: int = 2
const CAMPAIGN_ENEMY_TROOP_INCREASE_PER_LEVEL: int = 2
const CAMPAIGN_EASY_BOSS_PROGRESS_STEPS: int = 1
const CAMPAIGN_HARD_BOSS_PROGRESS_STEPS: int = 2
const CAMPAIGN_EASY_REWARD_POINTS: int = 2
const CAMPAIGN_HARD_REWARD_POINTS: int = 5
# Campaign upgrade modal layout knobs.
# Top anchor is normalized viewport space [0..1].
# Bottom padding is pixels above the top edge of the bottom bar.
const CAMPAIGN_UPGRADE_MENU_TOP_ANCHOR: float = -10.10
const CAMPAIGN_UPGRADE_MENU_BOTTOM_PADDING_ABOVE_BAR: float = 50.0

const BOSS_PART_HEAD: String = "head"
const BOSS_PART_LEFT_ARM: String = "left_arm"
const BOSS_PART_RIGHT_ARM: String = "right_arm"
const BOSS_PART_LEFT_LEG: String = "left_leg"
const BOSS_PART_RIGHT_LEG: String = "right_leg"

const CAMPAIGN_BOSS_DEFENSIVE_ROTATION: Array[String] = [
	BOSS_PART_LEFT_ARM,
	BOSS_PART_RIGHT_ARM,
	BOSS_PART_LEFT_LEG,
	BOSS_PART_RIGHT_LEG,
	BOSS_PART_HEAD
]

const BOSS_OFFENSE_LEFT_ARM_PUNCH: String = "left_arm_punch_kills"
const BOSS_OFFENSE_RIGHT_ARM_PUNCH: String = "right_arm_punch_kills"
const BOSS_OFFENSE_LEFT_LEG_KICK: String = "left_leg_kick_buildings"
const BOSS_OFFENSE_RIGHT_LEG_KICK: String = "right_leg_kick_buildings"
const BOSS_OFFENSE_RECRUIT: String = "boss_recruit_bonus"

const CAMPAIGN_BOSS_OFFENSIVE_ROTATION: Array[String] = [
	BOSS_OFFENSE_LEFT_ARM_PUNCH,
	BOSS_OFFENSE_RIGHT_ARM_PUNCH,
	BOSS_OFFENSE_LEFT_LEG_KICK,
	BOSS_OFFENSE_RIGHT_LEG_KICK,
	BOSS_OFFENSE_RECRUIT
]

static func get_campaign_total_levels() -> int:
	return maxi(1, CAMPAIGN_TOTAL_LEVELS)

static func get_campaign_final_level_index() -> int:
	return clampi(CAMPAIGN_FINAL_LEVEL_INDEX, 1, get_campaign_total_levels())

static func normalize_campaign_level_mode(level_mode: String) -> String:
	var normalized: String = String(level_mode).strip_edges().to_lower()
	match normalized:
		CAMPAIGN_LEVEL_MODE_HARD:
			return CAMPAIGN_LEVEL_MODE_HARD
		_:
			return CAMPAIGN_LEVEL_MODE_EASY

static func get_campaign_level_mode_display_name(level_mode: String) -> String:
	match normalize_campaign_level_mode(level_mode):
		CAMPAIGN_LEVEL_MODE_HARD:
			return "Hard"
		_:
			return "Easy"

static func get_campaign_step_advance_for_mode(level_mode: String) -> int:
	match normalize_campaign_level_mode(level_mode):
		CAMPAIGN_LEVEL_MODE_HARD:
			return maxi(1, CAMPAIGN_HARD_STEP_ADVANCE)
		_:
			return maxi(1, CAMPAIGN_EASY_STEP_ADVANCE)

static func get_campaign_boss_progress_steps_for_mode(level_mode: String) -> int:
	match normalize_campaign_level_mode(level_mode):
		CAMPAIGN_LEVEL_MODE_HARD:
			return maxi(1, CAMPAIGN_HARD_BOSS_PROGRESS_STEPS)
		_:
			return maxi(1, CAMPAIGN_EASY_BOSS_PROGRESS_STEPS)

static func get_campaign_enemy_troop_increase_per_level() -> int:
	return maxi(0, _runtime_campaign_enemy_troop_increase_per_level)

static func get_default_campaign_enemy_troop_increase_per_level() -> int:
	return maxi(0, CAMPAIGN_ENEMY_TROOP_INCREASE_PER_LEVEL)

static func get_campaign_reward_points_for_mode(level_mode: String) -> int:
	match normalize_campaign_level_mode(level_mode):
		CAMPAIGN_LEVEL_MODE_HARD:
			return maxi(0, CAMPAIGN_HARD_REWARD_POINTS)
		_:
			return maxi(0, CAMPAIGN_EASY_REWARD_POINTS)

static func clamp_campaign_level_progress(progress_value: int) -> int:
	return clampi(progress_value, 1, get_campaign_total_levels())

static func is_campaign_final_level(progress_value: int) -> bool:
	return clamp_campaign_level_progress(progress_value) >= get_campaign_final_level_index()

static func get_campaign_boss_count_for_mode(level_mode: String, progress_value: int = 1) -> int:
	var clamped_progress: int = clamp_campaign_level_progress(progress_value)
	if clamped_progress >= get_campaign_final_level_index():
		return 4
	return 2 if normalize_campaign_level_mode(level_mode) == CAMPAIGN_LEVEL_MODE_HARD else 1

static func get_campaign_boss_defensive_rotation() -> Array[String]:
	return CAMPAIGN_BOSS_DEFENSIVE_ROTATION.duplicate()

static func get_campaign_boss_offensive_rotation() -> Array[String]:
	return CAMPAIGN_BOSS_OFFENSIVE_ROTATION.duplicate()

static func get_campaign_boss_defensive_rotation_size() -> int:
	return maxi(1, CAMPAIGN_BOSS_DEFENSIVE_ROTATION.size())

static func get_campaign_boss_offensive_rotation_size() -> int:
	return maxi(1, CAMPAIGN_BOSS_OFFENSIVE_ROTATION.size())

static func get_campaign_boss_defensive_target_for_step(step_index: int) -> String:
	var rotation_size: int = get_campaign_boss_defensive_rotation_size()
	var safe_index: int = posmod(step_index, rotation_size)
	return String(CAMPAIGN_BOSS_DEFENSIVE_ROTATION[safe_index])

static func get_campaign_boss_offensive_target_for_step(step_index: int) -> String:
	var rotation_size: int = get_campaign_boss_offensive_rotation_size()
	var safe_index: int = posmod(step_index, rotation_size)
	return String(CAMPAIGN_BOSS_OFFENSIVE_ROTATION[safe_index])

static func build_campaign_boss_defensive_bonus_map(total_steps: int) -> Dictionary:
	var safe_steps: int = maxi(0, total_steps)
	var bonus_map: Dictionary = {
		BOSS_PART_LEFT_ARM: 0,
		BOSS_PART_RIGHT_ARM: 0,
		BOSS_PART_LEFT_LEG: 0,
		BOSS_PART_RIGHT_LEG: 0,
		BOSS_PART_HEAD: 0
	}
	for step in range(safe_steps):
		var key: String = get_campaign_boss_defensive_target_for_step(step)
		bonus_map[key] = int(bonus_map.get(key, 0)) + 1
	return bonus_map

static func build_campaign_boss_offensive_bonus_map(total_steps: int) -> Dictionary:
	var safe_steps: int = maxi(0, total_steps)
	var bonus_map: Dictionary = {
		BOSS_OFFENSE_LEFT_ARM_PUNCH: 0,
		BOSS_OFFENSE_RIGHT_ARM_PUNCH: 0,
		BOSS_OFFENSE_LEFT_LEG_KICK: 0,
		BOSS_OFFENSE_RIGHT_LEG_KICK: 0,
		BOSS_OFFENSE_RECRUIT: 0
	}
	for step in range(safe_steps):
		var key: String = get_campaign_boss_offensive_target_for_step(step)
		bonus_map[key] = int(bonus_map.get(key, 0)) + 1
	return bonus_map

# ==================== BOSS SPAWN TIMING ====================
# The boss becomes eligible to appear at the start of this grand-map turn.
# Examples:
# 1  -> eligible immediately on the first grand-map turn
# 10 -> eligible at the start of turn 10, after turn 9 resolves
const BOSS_SHOW_UP_ON_TURN: int = 1
const FIRST_LEVEL_BOSS_SHOW_UP_TURN_DELAY: int = 5

# Multiplies the boss head rectangle size while preserving the same shield layout.
# 1.0 keeps the current size, values below 1.0 shrink it, values above 1.0 enlarge it.
const BOSS_HEAD_SIZE_SCALE: float = 0.8

# Multiplies boss arm and leg thickness/overall footprint during visual + collision layout generation.
# 1.0 keeps the current shape, values below 1.0 slim the limb, values above 1.0 bulk it up.
const BOSS_ARM_SIZE_SCALE: float = 1.0
const BOSS_LEG_SIZE_SCALE: float = 1.0

# Vertical placement of the boss head, expressed as a fraction of the local boss scale.
# More-negative values move the head upward; less-negative / positive values move it downward.
const BOSS_HEAD_VERTICAL_OFFSET_FACTOR: float = -0.110

# Instant visual response when a live boss part is contacted on the grand map.
const BOSS_HIT_FLASH_DURATION_SECONDS: float = 0.12
const BOSS_HIT_FLASH_PEAK_WHITE_BLEND: float = 1.0
const BOSS_SPAWN_TRANSFER_FLASH_DURATION_SECONDS: float = 0.5

# Boss durability knobs.
# These values control how many registered hits each boss part can take before it is destroyed.
const BOSS_HEAD_HIT_POINTS: int = 5
const FRIENDLY_BOSS_HIT_POINTS: int = 50
const BOSS_LEFT_ARM_HIT_POINTS: int = 1
const BOSS_RIGHT_ARM_HIT_POINTS: int = 1
const BOSS_LEFT_LEG_HIT_POINTS: int = 1
const BOSS_RIGHT_LEG_HIT_POINTS: int = 1
static var _runtime_boss_head_hit_points: int = BOSS_HEAD_HIT_POINTS

# Optional face art overlay drawn inside the boss head rectangle.
# Use the image as-is for now. The file should be imported into the Godot project at this path.
const BOSS_HEAD_IMAGE_ENABLED: bool = true
const BOSS_HEAD_IMAGE_PATH: String = "res://sprites/boss_head.png"
const BOSS_FRIENDLY_IMAGE_PATH: String = "res://sprites/boss_friendly.png"
const BOSS_FRIENDLY_INVADING_IMAGE_PATH: String = "res://sprites/boss_friendly_invading.png"
const BOSS_HEAD_IMAGE_SCALE: float = 1.7
const BOSS_HEAD_IMAGE_OFFSET: Vector2 = Vector2.ZERO
const BOSS_HEAD_IMAGE_ALPHA: float = 1.0
const BOSS_LIMB_SPRITE_ALPHA: float = 1.0
const BOSS_LIMB_SPRITE_SCALE_PADDING: float = 1.0
# Positive values pull spawned boss-home assault limbs farther toward the corner with the head.
# Negative values push them away from that corner.
const BOSS_HOME_ASSAULT_LEFT_ARM_CORNER_PULL: float = 3.0
const BOSS_HOME_ASSAULT_RIGHT_ARM_CORNER_PULL: float = 3.0
const BOSS_HOME_ASSAULT_LEFT_LEG_CORNER_PULL: float = -5.0
const BOSS_HOME_ASSAULT_RIGHT_LEG_CORNER_PULL: float = -5.0

# Visual-only per-limb rotation offsets for spawned boss-home assault parts.
const BOSS_HOME_ASSAULT_LEFT_ARM_ROTATION_DEGREES: float = 0.0
const BOSS_HOME_ASSAULT_RIGHT_ARM_ROTATION_DEGREES: float = 0.0
const BOSS_HOME_ASSAULT_LEFT_LEG_ROTATION_DEGREES: float = 180.0
const BOSS_HOME_ASSAULT_RIGHT_LEG_ROTATION_DEGREES: float = 180.0
const BOSS_LIMB_LEFT_SPRITE_PATH: String = "res://sprites/boss_arm_left.png"
const BOSS_LIMB_RIGHT_SPRITE_PATH: String = "res://sprites/boss_arm_right.png"
const BOSS_LIMB_LEFT_LEG_SPRITE_PATH: String = "res://sprites/boss_leg_left.png"
const BOSS_LIMB_RIGHT_LEG_SPRITE_PATH: String = "res://sprites/boss_leg_right.png"

const BOSS_HEAD_BUMPINESS_ENABLED: bool = false
const BOSS_HEAD_BUMP_COUNT_MIN: int = 6
const BOSS_HEAD_BUMP_COUNT_MAX: int = 10
const BOSS_HEAD_BUMP_DEPTH_MIN: float = 6.0
const BOSS_HEAD_BUMP_DEPTH_MAX: float = 14.0
const BOSS_HEAD_BUMP_WIDTH_RATIO_MIN: float = 0.08
const BOSS_HEAD_BUMP_WIDTH_RATIO_MAX: float = 0.18
const BOSS_HEAD_BUMP_CORNER_EXCLUSION_RATIO: float = 0.10
const BOSS_HEAD_BUMP_OUTWARD_CHANCE: float = 0.50
const BOSS_HEAD_BUMP_EDGE_JITTER_MIN: float = 0.0
const BOSS_HEAD_BUMP_EDGE_JITTER_MAX: float = 3.0
const BOSS_HEAD_BUMP_MIN_EDGE_POINTS: int = 6

# Number of special boss-guard troops spawned when the ball comes to rest in the boss home province.
# These troops are used for the boss-home assault engagement and are reset fresh each attempt.
const BOSS_HOME_ASSAULT_TROOPS: int = 100
const BOSS_ATTACK_PROVINCE_OPACITY_PULSE_SECONDS: float = 3.0

static func get_boss_show_up_turn_for_level(campaign_level: int, opening_tutorial_active: bool = false) -> int:
	var show_up_turn: int = BOSS_SHOW_UP_ON_TURN
	if is_numbered_campaign_level_one(campaign_level, opening_tutorial_active):
		show_up_turn += maxi(0, FIRST_LEVEL_BOSS_SHOW_UP_TURN_DELAY)
	return maxi(1, show_up_turn)


static func get_boss_spawn_roll_threshold_for_level(campaign_level: int, opening_tutorial_active: bool = false) -> int:
	return maxi(0, get_boss_show_up_turn_for_level(campaign_level, opening_tutorial_active) - 1)


static func get_boss_spawn_roll_threshold() -> int:
	return get_boss_spawn_roll_threshold_for_level(2)

static func get_boss_head_size_scale() -> float:
	return maxf(0.05, BOSS_HEAD_SIZE_SCALE)

static func get_boss_head_scale() -> float:
	return get_boss_head_size_scale()

static func get_boss_arm_size_scale() -> float:
	return maxf(0.10, BOSS_ARM_SIZE_SCALE)

static func get_boss_leg_size_scale() -> float:
	return maxf(0.10, BOSS_LEG_SIZE_SCALE)

static func get_boss_head_vertical_offset_factor() -> float:
	return BOSS_HEAD_VERTICAL_OFFSET_FACTOR

static func get_boss_hit_flash_duration_seconds() -> float:
	return maxf(0.0, BOSS_HIT_FLASH_DURATION_SECONDS)

static func get_boss_hit_flash_peak_white_blend() -> float:
	return clampf(BOSS_HIT_FLASH_PEAK_WHITE_BLEND, 0.0, 1.0)

static func get_boss_spawn_transfer_flash_duration_seconds() -> float:
	return maxf(0.05, BOSS_SPAWN_TRANSFER_FLASH_DURATION_SECONDS)

static func get_boss_attack_province_opacity_pulse_seconds() -> float:
	return maxf(0.0, BOSS_ATTACK_PROVINCE_OPACITY_PULSE_SECONDS)

static func get_touch_single_finger_commit_delay_msec() -> int:
	return maxi(0, TOUCH_SINGLE_FINGER_COMMIT_DELAY_MSEC)

static func set_runtime_debug_balancing(initial_friendly_troops: int, boss_head_hit_points: int, conquered_friendly_troops: int, campaign_enemy_troop_increase_per_level: int = CAMPAIGN_ENEMY_TROOP_INCREASE_PER_LEVEL) -> void:
	_runtime_initial_province_friendly_troops = maxi(1, initial_friendly_troops)
	_runtime_boss_head_hit_points = maxi(1, boss_head_hit_points)
	_runtime_conquered_province_friendly_troops = maxi(1, conquered_friendly_troops)
	_runtime_campaign_enemy_troop_increase_per_level = maxi(0, campaign_enemy_troop_increase_per_level)

static func get_default_boss_head_hit_points() -> int:
	return maxi(1, BOSS_HEAD_HIT_POINTS)

static func get_runtime_boss_head_hit_points() -> int:
	return maxi(1, _runtime_boss_head_hit_points)

static func get_boss_head_hit_points() -> int:
	return get_runtime_boss_head_hit_points()

static func get_friendly_boss_hit_points() -> int:
	return get_boss_head_hit_points()

static func get_boss_left_arm_hit_points() -> int:
	return maxi(1, BOSS_LEFT_ARM_HIT_POINTS)

static func get_boss_right_arm_hit_points() -> int:
	return maxi(1, BOSS_RIGHT_ARM_HIT_POINTS)

static func get_boss_left_leg_hit_points() -> int:
	return maxi(1, BOSS_LEFT_LEG_HIT_POINTS)

static func get_boss_right_leg_hit_points() -> int:
	return maxi(1, BOSS_RIGHT_LEG_HIT_POINTS)

static func get_boss_part_hit_points(part_name: String) -> int:
	match String(part_name).strip_edges():
		"head":
			return get_boss_head_hit_points()
		"left_arm":
			return get_boss_left_arm_hit_points()
		"right_arm":
			return get_boss_right_arm_hit_points()
		"left_leg":
			return get_boss_left_leg_hit_points()
		"right_leg":
			return get_boss_right_leg_hit_points()
		_:
			return 1

static func get_boss_head_image_enabled() -> bool:
	return BOSS_HEAD_IMAGE_ENABLED

static func get_boss_head_image_path() -> String:
	return BOSS_HEAD_IMAGE_PATH

static func get_boss_friendly_image_path() -> String:
	return BOSS_FRIENDLY_IMAGE_PATH

static func get_boss_friendly_invading_image_path() -> String:
	return BOSS_FRIENDLY_INVADING_IMAGE_PATH

static func get_boss_head_image_scale() -> float:
	return maxf(0.05, BOSS_HEAD_IMAGE_SCALE)

static func get_boss_head_image_offset() -> Vector2:
	return BOSS_HEAD_IMAGE_OFFSET

static func get_boss_head_image_alpha() -> float:
	return clampf(BOSS_HEAD_IMAGE_ALPHA, 0.0, 1.0)

static func get_boss_limb_sprite_path(part_name: String) -> String:
	match String(part_name).strip_edges():
		"left_arm":
			return BOSS_LIMB_LEFT_SPRITE_PATH
		"right_arm":
			return BOSS_LIMB_RIGHT_SPRITE_PATH
		"left_leg":
			return BOSS_LIMB_LEFT_LEG_SPRITE_PATH
		"right_leg":
			return BOSS_LIMB_RIGHT_LEG_SPRITE_PATH
		_:
			return ""

static func get_boss_limb_sprite_alpha() -> float:
	return clampf(BOSS_LIMB_SPRITE_ALPHA, 0.0, 1.0)

static func get_boss_limb_sprite_scale_padding() -> float:
	return maxf(0.25, BOSS_LIMB_SPRITE_SCALE_PADDING)

static func get_boss_home_assault_limb_corner_pull(part_name: String) -> float:
	match String(part_name).strip_edges():
		"left_arm":
			return BOSS_HOME_ASSAULT_LEFT_ARM_CORNER_PULL
		"right_arm":
			return BOSS_HOME_ASSAULT_RIGHT_ARM_CORNER_PULL
		"left_leg":
			return BOSS_HOME_ASSAULT_LEFT_LEG_CORNER_PULL
		"right_leg":
			return BOSS_HOME_ASSAULT_RIGHT_LEG_CORNER_PULL
		_:
			return 0.0

static func get_boss_home_assault_limb_visual_rotation_radians(part_name: String) -> float:
	match String(part_name).strip_edges():
		"left_arm":
			return deg_to_rad(BOSS_HOME_ASSAULT_LEFT_ARM_ROTATION_DEGREES)
		"right_arm":
			return deg_to_rad(BOSS_HOME_ASSAULT_RIGHT_ARM_ROTATION_DEGREES)
		"left_leg":
			return deg_to_rad(BOSS_HOME_ASSAULT_LEFT_LEG_ROTATION_DEGREES)
		"right_leg":
			return deg_to_rad(BOSS_HOME_ASSAULT_RIGHT_LEG_ROTATION_DEGREES)
		_:
			return PI

static func get_boss_head_bumpiness_enabled() -> bool:
	return BOSS_HEAD_BUMPINESS_ENABLED

static func get_boss_head_bump_count_min() -> int:
	return maxi(0, BOSS_HEAD_BUMP_COUNT_MIN)

static func get_boss_head_bump_count_max() -> int:
	return maxi(get_boss_head_bump_count_min(), BOSS_HEAD_BUMP_COUNT_MAX)

static func get_boss_head_bump_depth_min() -> float:
	return maxf(0.0, BOSS_HEAD_BUMP_DEPTH_MIN)

static func get_boss_head_bump_depth_max() -> float:
	return maxf(get_boss_head_bump_depth_min(), BOSS_HEAD_BUMP_DEPTH_MAX)

static func get_boss_head_bump_width_ratio_min() -> float:
	return clampf(BOSS_HEAD_BUMP_WIDTH_RATIO_MIN, 0.01, 0.49)

static func get_boss_head_bump_width_ratio_max() -> float:
	return clampf(maxf(get_boss_head_bump_width_ratio_min(), BOSS_HEAD_BUMP_WIDTH_RATIO_MAX), 0.01, 0.49)

static func get_boss_head_bump_corner_exclusion_ratio() -> float:
	return clampf(BOSS_HEAD_BUMP_CORNER_EXCLUSION_RATIO, 0.0, 0.45)

static func get_boss_head_bump_outward_chance() -> float:
	return clampf(BOSS_HEAD_BUMP_OUTWARD_CHANCE, 0.0, 1.0)

static func get_boss_head_bump_edge_jitter_min() -> float:
	return maxf(0.0, BOSS_HEAD_BUMP_EDGE_JITTER_MIN)

static func get_boss_head_bump_edge_jitter_max() -> float:
	return maxf(get_boss_head_bump_edge_jitter_min(), BOSS_HEAD_BUMP_EDGE_JITTER_MAX)

static func get_boss_head_bump_min_edge_points() -> int:
	return maxi(2, BOSS_HEAD_BUMP_MIN_EDGE_POINTS)

static func get_boss_home_assault_troops() -> int:
	return maxi(1, BOSS_HOME_ASSAULT_TROOPS)

const BALL_FORCE_STOP_SPEED_THRESHOLD: float = 12.0
const BALL_FORCE_STOP_DWELL_SECONDS: float = 0.6

# ==================== BOSS CALTROPS ====================
# Each surviving boss limb spawns this many persistent caltrops per enemy turn.
# Limbs are the two arms and two legs; the head is not counted as a limb for this purpose.
const BOSS_CALTROPS_ENABLED: bool = true
const BOSS_CALTROPS_PER_SURVIVING_LIMB: int = 1

# Engagement-side caltrop visuals.
const CALTROP_SPRITE_VARIANT_PATHS: Array[String] = [
	"res://sprites/caltrop1.png",
	"res://sprites/caltrop2.png",
	"res://sprites/caltrop3.png",
	"res://sprites/caltrop4.png",
]
const CALTROP_SPRITE_ALPHA: float = 1.0
const CALTROP_SPRITE_SCALE_MIN: float = 0.90
const CALTROP_SPRITE_SCALE_MAX: float = 1.08

# Engagement-side caltrop generation tuning.
# These are the intended shared knobs for irregular caltrop obstacle size, edge button size,
# and placement clearances when a province's persistent caltrops are overlaid onto an
# already-generated engagement board.
const CALTROP_RADIUS_MIN: float = 42.0
const CALTROP_RADIUS_MAX: float = 68.0
const CALTROP_BUTTON_RADIUS: float = 13.0
const CALTROP_WORLD_MARGIN: float = 118.0
const CALTROP_PLACEMENT_ATTEMPTS: int = 42
const CALTROP_HARD_BLOCKER_PADDING: float = 20.0
const CALTROP_WATER_PADDING: float = 28.0
const CALTROP_SOFT_PIN_PADDING: float = 12.0
const CALTROP_POINT_COUNT_MIN: int = 7
const CALTROP_POINT_COUNT_MAX: int = 10
const CALTROP_POINT_JITTER_FRACTION: float = 0.12
const CALTROP_OUTER_SPIKE_SCALE_MIN: float = 1.03
const CALTROP_OUTER_SPIKE_SCALE_MAX: float = 1.16
const CALTROP_INNER_SPIKE_SCALE_MIN: float = 0.86
const CALTROP_INNER_SPIKE_SCALE_MAX: float = 0.98
const CALTROP_RADIAL_VARIATION_MIN: float = 0.82
const CALTROP_RADIAL_VARIATION_MAX: float = 1.18
const CALTROP_BUTTON_OUTSET_FACTOR: float = 0.55
const CALTROP_CLEARANCE_EXTRA: float = 10.0
const CALTROP_VERTEX_CLEARANCE_EXTRA: float = 8.0
const CALTROP_BUTTON_CLEARANCE_EXTRA: float = 8.0

const CALTROP_FILL_COLOR: Color = Color(0.28, 0.26, 0.30, 0.98)
const CALTROP_EDGE_COLOR: Color = Color(0.78, 0.72, 0.64, 0.96)
const CALTROP_INNER_COLOR: Color = Color(0.16, 0.14, 0.18, 0.92)
const CALTROP_BUTTON_COLOR: Color = Color(0.96, 0.74, 0.28, 0.98)
const CALTROP_BUTTON_RING_COLOR: Color = Color(1.0, 0.94, 0.72, 0.96)

static func get_boss_caltrops_enabled() -> bool:
	return BOSS_CALTROPS_ENABLED

static func get_boss_caltrops_per_surviving_limb() -> int:
	return maxi(0, BOSS_CALTROPS_PER_SURVIVING_LIMB)

static func get_caltrop_sprite_candidate_paths() -> PackedStringArray:
	return PackedStringArray(CALTROP_SPRITE_VARIANT_PATHS)

static func get_caltrop_sprite_alpha() -> float:
	return clampf(CALTROP_SPRITE_ALPHA, 0.0, 1.0)

static func get_caltrop_sprite_scale_min() -> float:
	return maxf(0.05, CALTROP_SPRITE_SCALE_MIN)

static func get_caltrop_sprite_scale_max() -> float:
	return maxf(get_caltrop_sprite_scale_min(), CALTROP_SPRITE_SCALE_MAX)

static func get_caltrop_radius_min() -> float:
	return maxf(1.0, CALTROP_RADIUS_MIN)

static func get_caltrop_radius_max() -> float:
	return maxf(get_caltrop_radius_min(), CALTROP_RADIUS_MAX)

static func get_caltrop_button_radius() -> float:
	return maxf(1.0, CALTROP_BUTTON_RADIUS)

static func get_caltrop_placement_attempts() -> int:
	return maxi(1, CALTROP_PLACEMENT_ATTEMPTS)

# ==================== BOSS LIMB SWAY ====================
# Rotational sway values are in degrees.
# Random sway values are world-unit offsets applied as smooth drifting motion.
const BOSS_LEFT_ARM_ROTATIONAL_SWAY_RANGE_DEGREES: float = 90.0
const BOSS_RIGHT_ARM_ROTATIONAL_SWAY_RANGE_DEGREES: float = 38.0
const BOSS_LEFT_LEG_ROTATIONAL_SWAY_RANGE_DEGREES: float = 8.0
const BOSS_RIGHT_LEG_ROTATIONAL_SWAY_RANGE_DEGREES: float = 8.0

const BOSS_LEFT_ARM_RANDOM_SWAY_RANGE: float = 2.5
const BOSS_RIGHT_ARM_RANDOM_SWAY_RANGE: float = 2.5
const BOSS_LEFT_LEG_RANDOM_SWAY_RANGE: float = 1.25
const BOSS_RIGHT_LEG_RANDOM_SWAY_RANGE: float = 1.25

# Per-limb rotational sway speeds. Higher values produce faster back-and-forth rotation.
const BOSS_LEFT_ARM_ROTATIONAL_SWAY_SPEED: float = 1.9
const BOSS_RIGHT_ARM_ROTATIONAL_SWAY_SPEED: float = 1.42
const BOSS_LEFT_LEG_ROTATIONAL_SWAY_SPEED: float = 1.00
const BOSS_RIGHT_LEG_ROTATIONAL_SWAY_SPEED: float = 1.00

static func get_boss_left_arm_rotational_sway_range_degrees() -> float:
	return maxf(0.0, BOSS_LEFT_ARM_ROTATIONAL_SWAY_RANGE_DEGREES)

static func get_boss_right_arm_rotational_sway_range_degrees() -> float:
	return maxf(0.0, BOSS_RIGHT_ARM_ROTATIONAL_SWAY_RANGE_DEGREES)

static func get_boss_left_leg_rotational_sway_range_degrees() -> float:
	return maxf(0.0, BOSS_LEFT_LEG_ROTATIONAL_SWAY_RANGE_DEGREES)

static func get_boss_right_leg_rotational_sway_range_degrees() -> float:
	return maxf(0.0, BOSS_RIGHT_LEG_ROTATIONAL_SWAY_RANGE_DEGREES)

static func get_boss_left_arm_random_sway_range() -> float:
	return maxf(0.0, BOSS_LEFT_ARM_RANDOM_SWAY_RANGE)

static func get_boss_right_arm_random_sway_range() -> float:
	return maxf(0.0, BOSS_RIGHT_ARM_RANDOM_SWAY_RANGE)

static func get_boss_left_leg_random_sway_range() -> float:
	return maxf(0.0, BOSS_LEFT_LEG_RANDOM_SWAY_RANGE)

static func get_boss_right_leg_random_sway_range() -> float:
	return maxf(0.0, BOSS_RIGHT_LEG_RANDOM_SWAY_RANGE)

static func get_boss_left_arm_rotational_sway_speed() -> float:
	return maxf(0.0, BOSS_LEFT_ARM_ROTATIONAL_SWAY_SPEED)

static func get_boss_right_arm_rotational_sway_speed() -> float:
	return maxf(0.0, BOSS_RIGHT_ARM_ROTATIONAL_SWAY_SPEED)

static func get_boss_left_leg_rotational_sway_speed() -> float:
	return maxf(0.0, BOSS_LEFT_LEG_ROTATIONAL_SWAY_SPEED)

static func get_boss_right_leg_rotational_sway_speed() -> float:
	return maxf(0.0, BOSS_RIGHT_LEG_ROTATIONAL_SWAY_SPEED)

const BALL_RADIUS_BASE_GRAND_MAP: float = 192.0
const BALL_RADIUS_MIN_ENGAGEMENT: float = 18.0
const BALL_RADIUS_BASE_ENGAGEMENT: float = 192.0

# Back-compat aliases for older call sites that still read the unsplit names.
const BALL_RADIUS_MIN: float = BALL_RADIUS_MIN_ENGAGEMENT
const BALL_RADIUS_BASE: float = BALL_RADIUS_BASE_ENGAGEMENT
const BALL_RADIUS_MAX_GROWTH_PER_LEVEL: float = 0
const BALL_BASE_MASS: float = 2.4
const BALL_BOUNCE: float = 0.2
const BALL_SPAWN_MARGIN: float = 120.0

const BALL_REST_SPEED_EPS: float = 5.0
const BALL_REST_DWELL_SECONDS: float = 0.15
const BALL_CREEP_STOP_THRESHOLD: float = 8.0
const BALL_SETTLING_DURATION: float = 1.0

const LAUNCH_DRAG_MAX_PIXELS: float = 340.0
const LAUNCH_SPEED_MIN: float = 400.0
const LAUNCH_SPEED_MAX: float = 1600.0
const TOUCH_SINGLE_FINGER_COMMIT_DELAY_MSEC: int = 120
const AUTO_CHARGE_DELAY_SECONDS: float = 4.0
const AUTO_CHARGE_RATE: float = 1.0

const PROJECTION_LINE_WIDTH: float = 6.0
const PROJECTION_LINE_COLOR: Color = Color(1.0, 0.95, 0.45, 0.75)
const PROJECTION_LENGTH_FACTOR: float = 0.28

# ==================== FRICTION & GRADE FORCES ====================
const FRICTION_DECEL_SCALE: float = 250.0
const FRICTION_DEFAULT: float = 1
const FRICTION_OIL: float = 0.1
const FRICTION_GRASS: float = 5
const GRADE_ACCEL_MIN: float = 220.0
const GRADE_ACCEL_MAX: float = 420.0

# ==================== PIN PHYSICS ====================
const PIN_BODY_WIDTH: float = 32.0
const PIN_BODY_HEIGHT: float = 64.0
const PIN_HEAD_RADIUS: float = 16.0
const PIN_MIN_SEPARATION: float = 56.0
const PIN_CLUSTER_RADIUS: float = 160.0
const PIN_SPAWN_MARGIN: float = 100.0
const PIN_OBSTACLE_CLEARANCE: float = 22.0
const PIN_HARD_CAP: int = 45

const PIN_BASE_MIN: int = 7
const PIN_BASE_MAX: int = 10
const PIN_GROWTH_MIN_PER_LEVEL: float = 0.9
const PIN_GROWTH_MAX_PER_LEVEL: float = 1.45

const PIN_KNOCK_VELOCITY_THRESHOLD: float = 220.0
const PIN_STANDING_LINEAR_DAMP: float = 0.98
const PIN_STANDING_ANGULAR_DAMP: float = 0.92
const PIN_KNOCKED_DAMP_LINEAR: float = 0.75
const PIN_KNOCKED_DAMP_ANGULAR: float = 0.68

const MAX_SIMULTANEOUS_KNOCKED_PINS: int = 12

# ==================== DIFFICULTY PLATEAU & QUALITY SHIFT ====================
const PIN_GROWTH_STOP_LEVEL: int = 16
const PIN_PLATEAU_MIN: int = 22
const PIN_PLATEAU_MAX: int = 29
const PIN_MILESTONE_MAX: int = 37

const ENEMY_ELITE_RAMP_START_LEVEL: int = 8
const ENEMY_ELITE_WEIGHT_BOOST_PER_LEVEL: float = 2.35

const ZONE_OBSTACLE_EXTRA_PER_LEVEL: float = 0.22
const ZONE_OBSTACLE_HARD_CAP: int = 7
const ZONE_GRADE_EXTRA_PER_LEVEL: float = 0.18
const ZONE_GRADE_HARD_CAP: int = 4

const KNOCKED_PIN_CLEANUP_DELAY_MIN: float = 0.40
const KNOCKED_PIN_CLEANUP_DELAY_MAX: float = 0.80

# ==================== ENEMY TYPES & DIFFICULTY ====================
const ENEMY_PIN: String = "Pin"
const ENEMY_HEAVY_PIN: String = "HeavyPin"
const ENEMY_SPIKY_PIN: String = "SpikyPin"
const ENEMY_RUNNER: String = "Runner"
const ENEMY_CHIEF: String = "Chief"

const ENEMY_DIFFICULTY_ORDER: Array[String] = [
	ENEMY_PIN, ENEMY_HEAVY_PIN, ENEMY_SPIKY_PIN, ENEMY_RUNNER, ENEMY_CHIEF
]

const ENEMY_KNOCK_MULTIPLIER_HEAVY: float = 1.4
const ENEMY_KNOCK_MULTIPLIER_CHIEF: float = 1.8
const ENEMY_SLOWDOWN_SPIKY: float = 0.65
const ENEMY_SLOWDOWN_CHIEF: float = 0.45

const RUNNER_BASE_SPEED: float = 180.0
const RUNNER_PATH_UPDATE_INTERVAL: float = 0.45
const RUNNER_MAX_DISTANCE_FROM_SPAWN: float = 280.0

const CHIEF_WANDER_SPEED: float = 120.0
const CHIEF_MAX_WANDER_OFFSET: float = 140.0

const ENEMY_WEIGHT_PIN: float = 300.0
const ENEMY_WEIGHT_HEAVY_PIN: float = 300.0
const ENEMY_WEIGHT_SPIKY_PIN: float = 20.0
const ENEMY_WEIGHT_RUNNER: float = 12.0
const ENEMY_WEIGHT_CHIEF: float = 4.0
const ENEMY_WEIGHT_RAMP_PER_LEVEL: float = 0.85

const ENEMY_SCALE_PIN: float = 1.00
const ENEMY_SCALE_HEAVY: float = 1.18
const ENEMY_SCALE_SPIKY: float = 1.12
const ENEMY_SCALE_RUNNER: float = 0.92
const ENEMY_SCALE_CHIEF: float = 1.35

# Standing-sprite asset paths.
const ENEMY_STANDING_SPRITE_PATH_PIN: String = "res://sprites/pin_standing.png"
const ENEMY_STANDING_SPRITE_PATH_HEAVY: String = "res://sprites/heavy_pin_standing.png"
const ENEMY_STANDING_SPRITE_PATH_SPIKY: String = "res://sprites/spiky_pin_standing.png"
const ENEMY_STANDING_SPRITE_PATH_RUNNER: String = "res://sprites/runner_standing.png"
const ENEMY_STANDING_SPRITE_PATH_CHIEF: String = "res://sprites/chief_standing.png"

# Downed-sprite asset paths.
# These are the new knocked-over enemy art assets.
const ENEMY_DOWNED_SPRITE_PATH_PIN: String = "res://sprites/pin_downed.png"
const ENEMY_DOWNED_SPRITE_PATH_HEAVY: String = "res://sprites/heavy_pin_downed.png"
const ENEMY_DOWNED_SPRITE_PATH_SPIKY: String = "res://sprites/spiky_pin_downed.png"
const ENEMY_DOWNED_SPRITE_PATH_RUNNER: String = "res://sprites/runner_downed.png"
const ENEMY_DOWNED_SPRITE_PATH_CHIEF: String = "res://sprites/chief_downed.png"

# Standing-sprite size knobs.
# These let you tune how large the standing sprite appears on screen without changing collisions or gameplay.
# Values are target visual heights in world pixels after transparent margins are auto-trimmed.
const ENEMY_STANDING_SPRITE_HEIGHT_PIN: float = 168.0
const ENEMY_STANDING_SPRITE_HEIGHT_HEAVY: float = 178.0
const ENEMY_STANDING_SPRITE_HEIGHT_SPIKY: float = 172.0
const ENEMY_STANDING_SPRITE_HEIGHT_RUNNER: float = 160.0
const ENEMY_STANDING_SPRITE_HEIGHT_CHIEF: float = 198.0

# Downed-sprite size knobs.
# These are target visual widths in world pixels after transparent margins are auto-trimmed.
# They only affect the knocked-over art; collision and gameplay remain unchanged.
const ENEMY_DOWNED_SPRITE_WIDTH_PIN: float = 128.0
const ENEMY_DOWNED_SPRITE_WIDTH_HEAVY: float = 146.0
const ENEMY_DOWNED_SPRITE_WIDTH_SPIKY: float = 132.0
const ENEMY_DOWNED_SPRITE_WIDTH_RUNNER: float = 124.0
const ENEMY_DOWNED_SPRITE_WIDTH_CHIEF: float = 166.0

const ENEMY_SHADOW_OFFSET: Vector2 = Vector2(3.0, 5.0)
const ENEMY_SHADOW_ALPHA: float = 0.45

# ==================== MILESTONE PROGRESSION ====================
const MILESTONE_INTERVAL: int = 5
const MILESTONE_PIN_MULTIPLIER: float = 1.55
const MILESTONE_GOLD_BONUS_MULTIPLIER: float = 1.30
const MILESTONE_BALL_SIZE_MULTIPLIER: float = 1.0

const MILESTONE_WEIGHT_MULTIPLIERS: Dictionary = {
	ENEMY_PIN: 0.40,
	ENEMY_HEAVY_PIN: 0.40,
	ENEMY_SPIKY_PIN: 2.60,
	ENEMY_RUNNER: 3.30,
	ENEMY_CHIEF: 4.80,
}

const MILESTONE_GUARANTEED_SPIKY: int = 3
const MILESTONE_GUARANTEED_RUNNER: int = 2
const MILESTONE_GUARANTEED_CHIEF: int = 1

# ==================== RUN ECONOMY ====================
const PLAYER_STARTING_GOLD: int = 50

# ==================== UPGRADES ====================
const UPGRADE_COST_BIGGER_BALL: int = 3
const UPGRADE_COST_HEAVIER_BALL: int = 5
const UPGRADE_COST_POISON: int = 5
const UPGRADE_COST_FORCEFIELD: int = 5
const UPGRADE_COST_MAGNET: int = 10
const UPGRADE_BIGGER_RADIUS_PER: float = 15.0
const UPGRADE_HEAVIER_MASS_PER: float = 0.35

# Magnet upgrade:
# - Each level grants one pre-shot placement on engagement maps.
# - Each placed magnet pulls the launched ball toward itself.
# - UPGRADE_MAGNET_PULL_STRENGTH is the primary gameplay knob for how strong the pull feels.
const UPGRADE_MAGNET_PULL_STRENGTH: float = 680.0
const UPGRADE_MAGNET_VISUAL_RADIUS: float = 26.0
const UPGRADE_MAGNET_PLACEMENT_RADIUS: float = 34.0
const UPGRADE_MAGNET_MIN_SPACING: float = 92.0

# Forcefield sits outside the ball, only interacts with pins, never pushes the ball back,
# and uses this multiplier as its hit strength relative to a direct ball hit.
# This is the primary gameplay knob for the requested "50% strength" behavior.
const UPGRADE_FORCEFIELD_PIN_STRENGTH_MULT: float = 0.40

# Visual / collision band tuning for the visible forcefield ring.
const UPGRADE_FORCEFIELD_RING_OUTSET: float = 18.0
const UPGRADE_FORCEFIELD_RING_THICKNESS: float = 10.0
const UPGRADE_FORCEFIELD_RING_PULSE_SPEED: float = 6.0
const UPGRADE_FORCEFIELD_RING_ALPHA: float = 0.78

# Prevents the ring from re-hitting the same pin every single physics frame while overlapping it.
const UPGRADE_FORCEFIELD_PIN_REHIT_COOLDOWN: float = 0.10

static func get_upgrade_base_cost_for_type(upgrade_type: String) -> int:
	match String(upgrade_type):
		"bigger":
			return int(UPGRADE_COST_BIGGER_BALL)
		"heavier":
			return int(UPGRADE_COST_HEAVIER_BALL)
		"poison":
			return int(UPGRADE_COST_POISON)
		"forcefield":
			return int(UPGRADE_COST_FORCEFIELD)
		"magnet":
			return int(UPGRADE_COST_MAGNET)
		_:
			return 999999999

# ==================== RESORT THEME COLORS ====================
const RESORT_SAND: Color = Color(0.96, 0.82, 0.55, 0.94)
const RESORT_SAND_TILE_TEXTURE_PATH: String = "res://sprites/sand.png"
const RESORT_SAND_TILE_SIZE: float = 256.0
const RESORT_BUSHES: Color = Color(0.24, 0.52, 0.19, 0.87)
const RESORT_BOARDWALK: Color = Color(0.52, 0.36, 0.22, 0.96)

const RESORT_SAND_HIGHLIGHT: Color = Color(1.0, 0.90, 0.62, 0.52)
const RESORT_BUSHES_INNER: Color = Color(0.15, 0.38, 0.12, 0.65)
const RESORT_BOARDWALK_PLANK: Color = Color(0.68, 0.48, 0.28, 1.0)
const RESORT_BOARDWALK_NAILS: Color = Color(0.18, 0.14, 0.09, 1.0)
const RESORT_BOARDWALK_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.22)

# ==================== RESORT BOARDWALK SPRITE AUTOTILE ====================
const RESORT_BOARDWALK_MAIN_SPRITE_PATH: String = "res://sprites/boardwalk_main.png"
const RESORT_BOARDWALK_CORNER_SPRITE_PATH: String = "res://sprites/boardwalk_corner.png"
const RESORT_BOARDWALK_TEE_SPRITE_PATH: String = "res://sprites/boardwalk_tee.png"
const RESORT_BOARDWALK_HALF_SPRITE_PATH: String = "res://sprites/boardwalk_half.png"
const RESORT_BOARDWALK_PLANK_SPRITE_PATH: String = "res://sprites/boardwalk_plank.png"
const RESORT_BOARDWALK_HALFPLANK_SPRITE_PATH: String = "res://sprites/boardwalk_halfplank.png"

# Core boardwalk autotile footprint and sizing knobs.
const RESORT_BOARDWALK_CELL_SIZE: float = 78.0
const RESORT_BOARDWALK_DEFAULT_WIDTH_CELLS: int = 2
const RESORT_BOARDWALK_CELL_OVERLAP: float = 7.0
const RESORT_BOARDWALK_VISUAL_INSET: float = 4.0
const RESORT_BOARDWALK_FRICTION_MARGIN: float = 8.0
const RESORT_BOARDWALK_MAIN_TARGET_SIZE: Vector2 = Vector2(162.0, 184.0)
const RESORT_BOARDWALK_CORNER_TARGET_SIZE: Vector2 = Vector2(138.0, 138.0)
const RESORT_BOARDWALK_TEE_TARGET_SIZE: Vector2 = Vector2(150.0, 154.0)
const RESORT_BOARDWALK_HALF_TARGET_SIZE: Vector2 = Vector2(164.0, 96.0)
const RESORT_BOARDWALK_PLANK_TARGET_SIZE: Vector2 = Vector2(52.0, 128.0)
const RESORT_BOARDWALK_HALFPLANK_TARGET_SIZE: Vector2 = Vector2(44.0, 72.0)
const RESORT_BOARDWALK_SUPPORT_PLANK_MAX_PER_CELL: int = 2
const RESORT_BOARDWALK_SUPPORT_PLANK_INSET: float = 14.0
const RESORT_BOARDWALK_SUPPORT_PLANK_JITTER: float = 4.0
const RESORT_BOARDWALK_ENDCAP_INSET: float = 16.0
const RESORT_BOARDWALK_MIN_FOOTPRINT_HALF_EXTENTS: Vector2 = Vector2(44.0, 44.0)
const RESORT_BOARDWALK_FOOTPRINT_PADDING: float = 18.0

static func get_boardwalk_sprite_candidate_paths(piece_key: String) -> PackedStringArray:
	match piece_key:
		"main":
			return PackedStringArray([
				RESORT_BOARDWALK_MAIN_SPRITE_PATH,
				"res://sprites/boardwalks/boardwalk_main.png",
				"res://sprites/boardwalk/boardwalk_main.png",
				"res://boardwalk_main.png",
				"res://art/boardwalk_main.png",
				"res://assets/boardwalk_main.png",
			])
		"corner":
			return PackedStringArray([
				RESORT_BOARDWALK_CORNER_SPRITE_PATH,
				"res://sprites/boardwalks/boardwalk_corner.png",
				"res://sprites/boardwalk/boardwalk_corner.png",
				"res://boardwalk_corner.png",
				"res://art/boardwalk_corner.png",
				"res://assets/boardwalk_corner.png",
			])
		"tee":
			return PackedStringArray([
				RESORT_BOARDWALK_TEE_SPRITE_PATH,
				"res://sprites/boardwalks/boardwalk_tee.png",
				"res://sprites/boardwalk/boardwalk_tee.png",
				"res://boardwalk_tee.png",
				"res://art/boardwalk_tee.png",
				"res://assets/boardwalk_tee.png",
			])
		"half":
			return PackedStringArray([
				RESORT_BOARDWALK_HALF_SPRITE_PATH,
				"res://sprites/boardwalks/boardwalk_half.png",
				"res://sprites/boardwalk/boardwalk_half.png",
				"res://boardwalk_half.png",
				"res://art/boardwalk_half.png",
				"res://assets/boardwalk_half.png",
			])
		"plank":
			return PackedStringArray([
				RESORT_BOARDWALK_PLANK_SPRITE_PATH,
				"res://sprites/boardwalks/boardwalk_plank.png",
				"res://sprites/boardwalk/boardwalk_plank.png",
				"res://boardwalk_plank.png",
				"res://art/boardwalk_plank.png",
				"res://assets/boardwalk_plank.png",
			])
		"halfplank":
			return PackedStringArray([
				RESORT_BOARDWALK_HALFPLANK_SPRITE_PATH,
				"res://sprites/boardwalks/boardwalk_halfplank.png",
				"res://sprites/boardwalk/boardwalk_halfplank.png",
				"res://boardwalk_halfplank.png",
				"res://art/boardwalk_halfplank.png",
				"res://assets/boardwalk_halfplank.png",
			])
	return PackedStringArray()

static func get_rock_sprite_candidate_paths() -> PackedStringArray:
	return PackedStringArray([
		"res://sprites/rock.png",
		"res://sprites/obstacles/rock.png",
		"res://sprites/rocks/rock.png",
		"res://rock.png",
		"res://art/rock.png",
		"res://assets/rock.png",
	])

# ==================== RESORT BUSH SPRITE AUTOTILE ====================
# Bush sprites now use a single configurable root path and a fixed filename contract.
# Default root: res://sprites/bush
const RESORT_BUSH_SPRITE_ROOT: String = "res://sprites/bush"

# Core bush footprint and visual sizing knobs.
const RESORT_BUSH_CELL_SIZE: float = 72.0
const RESORT_BUSH_CELL_OVERLAP: float = 10.0
const RESORT_BUSH_VISUAL_INSET: float = 4.0
const RESORT_BUSH_MIN_FOOTPRINT_HALF_EXTENTS: Vector2 = Vector2(52.0, 52.0)
const RESORT_BUSH_FOOTPRINT_PADDING: float = 18.0
const RESORT_BUSH_SHADOW_OFFSET: Vector2 = Vector2(6.0, 8.0)
const RESORT_BUSH_SHADOW_ALPHA: float = 0.26
const RESORT_BUSH_FILLER_MAX_PER_CELL: int = 2
const RESORT_BUSH_FILLER_JITTER: float = 10.0
const RESORT_BUSH_INTERIOR_CLUMP_JITTER: float = 8.0
const RESORT_BUSH_ACCENT_MAX_PER_CELL: int = 2
const RESORT_BUSH_ACCENT_JITTER: float = 12.0

# Variant counts per fixed bush piece family. These must match the files present
# under RESORT_BUSH_SPRITE_ROOT using the naming scheme defined below.
const RESORT_BUSH_STRAIGHT_VARIANTS: int = 4
const RESORT_BUSH_CONVEX_CORNER_VARIANTS: int = 4
const RESORT_BUSH_CONCAVE_CORNER_VARIANTS: int = 4
const RESORT_BUSH_TRANSITION_VARIANTS: int = 4
const RESORT_BUSH_ENDCAP_VARIANTS: int = 4
const RESORT_BUSH_GROUND_FILLER_COVER_VARIANTS: int = 3
const RESORT_BUSH_INTERIOR_CLUMP_VARIANTS: int = 3
const RESORT_BUSH_ACCENT_VARIANTS: int = 3

# Target draw sizes for the procedural bush piece families.
const RESORT_BUSH_STRAIGHT_TARGET_SIZE: Vector2 = Vector2(118.0, 118.0)
const RESORT_BUSH_CONVEX_CORNER_TARGET_SIZE: Vector2 = Vector2(122.0, 122.0)
const RESORT_BUSH_CONCAVE_CORNER_TARGET_SIZE: Vector2 = Vector2(122.0, 122.0)
const RESORT_BUSH_TRANSITION_TARGET_SIZE: Vector2 = Vector2(118.0, 118.0)
const RESORT_BUSH_ENDCAP_TARGET_SIZE: Vector2 = Vector2(114.0, 114.0)
const RESORT_BUSH_GROUND_FILLER_COVER_TARGET_SIZE: Vector2 = Vector2(88.0, 88.0)
const RESORT_BUSH_INTERIOR_CLUMP_TARGET_SIZE: Vector2 = Vector2(104.0, 104.0)
const RESORT_BUSH_ACCENT_TARGET_SIZE: Vector2 = Vector2(76.0, 76.0)

static func get_bush_sprite_variant_count(piece_key: String) -> int:
	match piece_key:
		"straight":
			return RESORT_BUSH_STRAIGHT_VARIANTS
		"convex":
			return RESORT_BUSH_CONVEX_CORNER_VARIANTS
		"concave":
			return RESORT_BUSH_CONCAVE_CORNER_VARIANTS
		"transition":
			return RESORT_BUSH_TRANSITION_VARIANTS
		"endcap":
			return RESORT_BUSH_ENDCAP_VARIANTS
		"filler":
			return RESORT_BUSH_GROUND_FILLER_COVER_VARIANTS
		"interior_clump":
			return RESORT_BUSH_INTERIOR_CLUMP_VARIANTS
		"accent":
			return RESORT_BUSH_ACCENT_VARIANTS
	return 0

static func _get_bush_piece_basename(piece_key: String) -> String:
	match piece_key:
		"straight":
			return "bush_straight"
		"convex":
			return "bush_convex_corner"
		"concave":
			return "bush_concave_corner"
		"transition":
			return "bush_transition"
		"endcap":
			return "bush_endcap"
		"filler":
			return "bush_ground_filler_cover"
		"interior_clump":
			return "bush_interior_clump"
		"accent":
			return "bush_accent"
	return ""

static func get_bush_expected_filename(piece_key: String, variant_index: int) -> String:
	var basename := _get_bush_piece_basename(piece_key)
	if basename.is_empty():
		return ""
	var variant_count := maxi(1, get_bush_sprite_variant_count(piece_key))
	var safe_variant := clampi(variant_index, 0, variant_count - 1) + 1
	return "%s_%02d.png" % [basename, safe_variant]

static func get_bush_sprite_candidate_paths(piece_key: String, variant_index: int = -1) -> PackedStringArray:
	var basename := _get_bush_piece_basename(piece_key)
	if basename.is_empty():
		return PackedStringArray()
	var variant_count := get_bush_sprite_variant_count(piece_key)
	if variant_count <= 0:
		return PackedStringArray()
	var safe_variant := 0 if variant_index < 0 else clampi(variant_index, 0, variant_count - 1)
	return PackedStringArray([RESORT_BUSH_SPRITE_ROOT + "/" + get_bush_expected_filename(piece_key, safe_variant)])

static func get_all_expected_bush_filenames() -> PackedStringArray:
	var files := PackedStringArray()
	for piece_key in ["straight", "convex", "concave", "transition", "endcap", "filler", "interior_clump", "accent"]:
		var count := get_bush_sprite_variant_count(piece_key)
		for variant_index in range(count):
			files.append(get_bush_expected_filename(piece_key, variant_index))
	return files

static func get_bush_target_size_for_key(piece_key: String) -> Vector2:
	match piece_key:
		"straight":
			return RESORT_BUSH_STRAIGHT_TARGET_SIZE
		"convex":
			return RESORT_BUSH_CONVEX_CORNER_TARGET_SIZE
		"concave":
			return RESORT_BUSH_CONCAVE_CORNER_TARGET_SIZE
		"transition":
			return RESORT_BUSH_TRANSITION_TARGET_SIZE
		"endcap":
			return RESORT_BUSH_ENDCAP_TARGET_SIZE
		"filler":
			return RESORT_BUSH_GROUND_FILLER_COVER_TARGET_SIZE
		"interior_clump":
			return RESORT_BUSH_INTERIOR_CLUMP_TARGET_SIZE
		"accent":
			return RESORT_BUSH_ACCENT_TARGET_SIZE
	return Vector2(LevelConfig.RESORT_BUSH_CELL_SIZE, LevelConfig.RESORT_BUSH_CELL_SIZE)

const RESORT_WATER_DEEP: Color = Color(0.16, 0.42, 0.92, 0.92)
const RESORT_WATER_SHALLOW: Color = Color(0.34, 0.72, 0.98, 0.88)
const RESORT_WATER_HIGHLIGHT: Color = Color(0.82, 0.96, 1.0, 0.42)
const RESORT_WATER_FOAM: Color = Color(0.95, 0.99, 1.0, 0.70)
const RESORT_WATER_SHADOW: Color = Color(0.02, 0.08, 0.22, 0.20)

const RESORT_OBSTACLE_ROCK: Color = Color(0.0, 0.0, 0.0, 1.0)
const RESORT_OBSTACLE_HIGHLIGHT: Color = Color(0.92, 0.78, 0.55, 0.55)
const RESORT_OBSTACLE_ROCK_SPRITE_PATH: String = "res://sprites/rock.png"
const RESORT_OBSTACLE_ROCK_SPRITE_SIZE_MULTIPLIER: float = 1.08

const BUILDING_BASE_COLOR: Color = Color(0.55, 0.38, 0.22, 1.0)
const BUILDING_ACCENT_COLOR: Color = Color(0.85, 0.65, 0.35, 1.0)

const SKI_PIN_SUIT_PRIMARY: Color = Color(0.95, 0.28, 0.22, 1.0)
const SKI_PIN_SUIT_SECONDARY: Color = Color(0.18, 0.62, 0.95, 1.0)
const SKI_PIN_HELMET: Color = Color(0.98, 0.98, 0.98, 1.0)
const SKI_PIN_GOGGLES: Color = Color(0.08, 0.12, 0.45, 1.0)
const SKI_PIN_ACCENT: Color = Color(1.0, 0.92, 0.35, 1.0)

const SKI_HEAVY_SUIT: Color = Color(0.22, 0.28, 0.85, 1.0)
const SKI_SPIKY_SUIT: Color = Color(1.0, 0.45, 0.15, 1.0)
const SKI_RUNNER_SUIT: Color = Color(0.12, 0.75, 0.38, 1.0)
const SKI_CHIEF_SUIT: Color = Color(0.92, 0.78, 0.18, 1.0)
const SKI_CHIEF_ACCENT: Color = Color(0.98, 0.22, 0.22, 1.0)

const SKI_BALL_SNOW: Color = Color(0.99, 0.99, 1.0, 1.0)
const SKI_BALL_GLOW: Color = Color(1.0, 0.96, 0.68, 0.65)
const SKI_SPARKLE_COLOR: Color = Color(1.0, 0.98, 0.65, 1.0)

# ==================== JUICY EFFECTS ====================
const JUICY_KNOCK_POP_SCALE: float = 1.55
const JUICY_KNOCK_SQUASH_DURATION: float = 0.09
const JUICY_KNOCK_PARTICLES: int = 32
const JUICY_POISON_PARTICLES: int = 40
const JUICY_UPGRADE_BURST: int = 22
const JUICY_WIN_SHAKE_AMOUNT: float = 9.5
const JUICY_WIN_SHAKE_TIME: float = 0.55
const JUICY_GOLD_BOUNCE_DURATION: float = 0.32
const JUICY_GOLD_SPARKLE_COUNT: int = 36
const JUICY_LAUNCH_SPARKLE_COUNT: int = 18
const JUICY_WIN_CONFETTI_COUNT: int = 120

var JUICY_CONFETTI_COLORS := PackedColorArray([
	Color(1.0, 0.25, 0.25), Color(0.25, 1.0, 0.25), Color(0.25, 0.25, 1.0),
	Color(1.0, 1.0, 0.25), Color(1.0, 0.5, 1.0), Color(1.0, 0.65, 0.25)
])

# ==================== CARTOON ENEMY DRAWING ====================
const SKI_CARTOON_EYE_BASE_COLOR: Color = Color(0.08, 0.12, 0.45, 1.0)
const SKI_CARTOON_PUPIL_COLOR: Color = Color(0.05, 0.08, 0.32, 1.0)
const SKI_CARTOON_EYE_HIGHLIGHT: Color = Color(1.0, 1.0, 1.0, 0.92)
const SKI_CARTOON_BLUSH_COLOR: Color = Color(1.0, 0.62, 0.68, 0.65)
const SKI_CARTOON_MOUTH_COLOR: Color = Color(0.92, 0.28, 0.22, 1.0)
const SKI_CARTOON_MOUTH_SMILE_COLOR: Color = Color(0.98, 0.45, 0.38, 1.0)

const ENEMY_CARTOON_EYE_RADIUS: float = 7.8
const ENEMY_CARTOON_PUPIL_RADIUS: float = 3.1
const ENEMY_CARTOON_EYE_OFFSET_Y: float = -3.5
const ENEMY_CARTOON_BLUSH_RADIUS: float = 4.4
const ENEMY_CARTOON_BLUSH_OFFSET: Vector2 = Vector2(7.5, 3.0)
const ENEMY_CARTOON_MOUTH_WIDTH: float = 9.5
const ENEMY_CARTOON_MOUTH_HEIGHT: float = 2.8
const ENEMY_CARTOON_SPARKLE_COUNT_STANDING: int = 3
const ENEMY_CARTOON_SPARKLE_COUNT_KNOCKED: int = 8

const ENEMY_CARTOON_DIZZY_STAR_COLOR: Color = Color(1.0, 0.95, 0.35, 0.95)
const ENEMY_CARTOON_DIZZY_STAR_SIZE: float = 3.8

# ==================== GRADE PARTICLE FLOW ====================
const GRADE_FLOW_PARTICLES_BASE_AMOUNT: int = 12
const GRADE_FLOW_PARTICLES_LIFETIME: float = 1.35
const GRADE_FLOW_PARTICLES_SPEED_MIN: float = 180.0
const GRADE_FLOW_PARTICLES_SPEED_MAX: float = 520.0
const GRADE_FLOW_PARTICLES_SCALE_MIN: float = 6.9
const GRADE_FLOW_PARTICLES_SCALE_MAX: float = 8.1
const GRADE_FLOW_SNOW_COLOR: Color = Color(0.412, 0.0, 0.91, 0.949)
const GRADE_FLOW_SPREAD_ANGLE: float = 12.0

const GRADE_FLOW_REUSE_MATERIAL: bool = true
const GRADE_FLOW_PARTICLES_LOW_PERF: int = 8

# ==================== NUANCED BODY & FACE CONSTANTS ====================
const ENEMY_BODY_SHOULDER_ROUNDNESS: float = 14.5
const ENEMY_BODY_TORSO_TOP_WIDTH_RATIO: float = 0.82
const ENEMY_BODY_TORSO_BOTTOM_WIDTH_RATIO: float = 1.28
const ENEMY_BODY_WAIST_PINCH: float = 0.74
const ENEMY_BODY_FOLD_LINE_COUNT: int = 4
const ENEMY_BODY_FOLD_THICKNESS: float = 3.2
const ENEMY_BODY_SEAM_COLOR: Color = Color(0.12, 0.12, 0.18, 0.95)

const ENEMY_HEAD_HELMET_RIM_OVERHANG: float = 4.8
const ENEMY_HEAD_ASYMMETRY_OFFSET: float = 2.5

const ENEMY_FACE_EYEBROW_LIFT: float = 3.2
const ENEMY_FACE_EYEBROW_THICKNESS: float = 3.1
const ENEMY_FACE_EYEBROW_LENGTH: float = 11.5
const ENEMY_FACE_EYEBROW_ASYMMETRY: float = 2.8

const ENEMY_FACE_NOSE_WIDTH: float = 5.5
const ENEMY_FACE_NOSE_OFFSET: float = 1.8
const ENEMY_FACE_NOSE_SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.35)

const ENEMY_FACE_MOUTH_CURVE_RADIUS: float = 6.2
const ENEMY_FACE_MOUTH_TILT: float = 1.2
const ENEMY_FACE_MOUTH_LIP_COLOR: Color = Color(0.85, 0.22, 0.18, 1.0)

const ENEMY_FACE_DIMPLE_COLOR: Color = Color(1.0, 0.65, 0.62, 0.45)
const ENEMY_FACE_DIMPLE_ASYMMETRY: float = 1.4

const ENEMY_FACE_HELMET_STRAP_COLOR: Color = Color(0.75, 0.78, 0.82, 0.9)
const ENEMY_FACE_VISOR_RIM_COLOR: Color = Color(0.95, 0.98, 1.0, 0.6)

const ENEMY_FACE_HEAVY_BROW_SOFTNESS: float = 0.7
const ENEMY_FACE_CHIEF_BROW_RAISE: float = 3.5
const ENEMY_FACE_RUNNER_BROW_ANGLE: float = 0.8
const ENEMY_FACE_SPIKY_BROW_SHARP: float = 1.2

# ==================== DASHBOARD UI LAYOUT ====================
# Bottom HUD dashboard knobs used by UIOverlay.gd.
# Edit these values to tune the ornate bottom-bar layout without touching the UI script.
const DASHBOARD_BOTTOM_BAR_MIN_HEIGHT: int = 248
const DASHBOARD_OUTER_MARGIN_LEFT: int = 24
const DASHBOARD_OUTER_MARGIN_TOP: int = 14
const DASHBOARD_OUTER_MARGIN_RIGHT: int = 24
const DASHBOARD_OUTER_MARGIN_BOTTOM: int = 14
const DASHBOARD_SECTION_GAP: int = 5
const DASHBOARD_LEFT_SECTION_BASE_MIN_WIDTH: int = 180
const DASHBOARD_CENTER_SECTION_BASE_MIN_WIDTH: int = 280
const DASHBOARD_RIGHT_SECTION_BASE_MIN_WIDTH: int = 180
const DASHBOARD_LEFT_SECTION_FLOOR_MIN_WIDTH: int = 132
const DASHBOARD_CENTER_SECTION_FLOOR_MIN_WIDTH: int = 210
const DASHBOARD_RIGHT_SECTION_FLOOR_MIN_WIDTH: int = 132
# Width-share knobs for the three dashboard columns.
# These do not need to add up to exactly 1.0; UIOverlay normalizes them.
const DASHBOARD_LEFT_SECTION_WIDTH_SHARE: float = 0.17
const DASHBOARD_CENTER_SECTION_WIDTH_SHARE: float = 0.53
const DASHBOARD_RIGHT_SECTION_WIDTH_SHARE: float = 0.3
const DASHBOARD_LEFT_SECTION_STRETCH: float = 0.90
const DASHBOARD_CENTER_SECTION_STRETCH: float = 1.35
const DASHBOARD_RIGHT_SECTION_STRETCH: float = 0.90
const DASHBOARD_DISPLAY_BANNER_WIDTH_SHARE: float = 0.40
const DASHBOARD_DISPLAY_BANNER_FRAME_THICKNESS_SCALE: float = 0.55
const DASHBOARD_SECTION_INNER_MARGIN_LEFT: int = 16
const DASHBOARD_SECTION_INNER_MARGIN_TOP: int = 14
const DASHBOARD_SECTION_INNER_MARGIN_RIGHT: int = 16
const DASHBOARD_SECTION_INNER_MARGIN_BOTTOM: int = 16
const DASHBOARD_SECTION_CONTENT_SEPARATION: int = 8

const DASHBOARD_SECTION_TITLE_FONT_SIZE: int = 13
const DASHBOARD_LEVEL_FONT_SIZE: int = 24
const DASHBOARD_GOLD_FONT_SIZE: int = 24
const DASHBOARD_SUMMARY_FONT_SIZE: int = 16
const DASHBOARD_MESSAGE_FONT_SIZE: int = 17
const DASHBOARD_SEED_FONT_SIZE: int = 15
const DASHBOARD_BUTTON_FONT_SIZE: int = 14
const DASHBOARD_UPGRADE_BUTTON_FONT_SIZE: int = 15

const DASHBOARD_MESSAGE_BANNER_MIN_HEIGHT: int = 112
const DASHBOARD_MESSAGE_CONTENT_MIN_HEIGHT: int = 70
const DASHBOARD_MESSAGE_BANNER_MARGIN_LEFT: int = 28
const DASHBOARD_MESSAGE_BANNER_MARGIN_TOP: int = 20
const DASHBOARD_MESSAGE_BANNER_MARGIN_RIGHT: int = 28
const DASHBOARD_MESSAGE_BANNER_MARGIN_BOTTOM: int = 22
# Additional inset inside the display banner's visible text area.
# These let UIOverlay clamp banner text away from the ornate frame and keep
# scrollable summaries fully inside the readable window.
const DASHBOARD_MESSAGE_TEXT_BOUNDARY_LEFT: int = 12
const DASHBOARD_MESSAGE_TEXT_BOUNDARY_TOP: int = 10
const DASHBOARD_MESSAGE_TEXT_BOUNDARY_RIGHT: int = 12
const DASHBOARD_MESSAGE_TEXT_BOUNDARY_BOTTOM: int = 58

const DASHBOARD_GOLD_SHELL_MIN_HEIGHT: int = 78
const DASHBOARD_GOLD_SHELL_MARGIN_LEFT: int = 16
const DASHBOARD_GOLD_SHELL_MARGIN_TOP: int = 14
const DASHBOARD_GOLD_SHELL_MARGIN_RIGHT: int = 16
const DASHBOARD_GOLD_SHELL_MARGIN_BOTTOM: int = 14

const DASHBOARD_SEED_SHELL_MIN_HEIGHT: int = 102
const DASHBOARD_SEED_SHELL_MARGIN_LEFT: int = 16
const DASHBOARD_SEED_SHELL_MARGIN_TOP: int = 16
const DASHBOARD_SEED_SHELL_MARGIN_RIGHT: int = 16
const DASHBOARD_SEED_SHELL_MARGIN_BOTTOM: int = 16

const DASHBOARD_UPGRADE_BUTTON_MIN_HEIGHT: int = 84
const DASHBOARD_CONTROL_BUTTON_MIN_WIDTH: int = 92
const DASHBOARD_CONTROL_BUTTON_MIN_HEIGHT: int = 46
const DASHBOARD_SMALL_BUTTON_MIN_WIDTH: int = 64
const DASHBOARD_SMALL_BUTTON_MIN_HEIGHT: int = 40

const DASHBOARD_HELP_BADGE_MIN_WIDTH: int = 26
const DASHBOARD_HELP_BADGE_MIN_HEIGHT: int = 20
const DASHBOARD_HELP_BADGE_OFFSET_LEFT: float = -30.0
const DASHBOARD_HELP_BADGE_OFFSET_TOP: float = -6.0
const DASHBOARD_HELP_BADGE_OFFSET_RIGHT: float = -4.0
const DASHBOARD_HELP_BADGE_OFFSET_BOTTOM: float = 18.0

static func get_dashboard_bottom_bar_min_height() -> int:
	return maxi(140, DASHBOARD_BOTTOM_BAR_MIN_HEIGHT)

static func get_dashboard_outer_margin_left() -> int:
	return maxi(0, DASHBOARD_OUTER_MARGIN_LEFT)

static func get_dashboard_outer_margin_top() -> int:
	return maxi(0, DASHBOARD_OUTER_MARGIN_TOP)

static func get_dashboard_outer_margin_right() -> int:
	return maxi(0, DASHBOARD_OUTER_MARGIN_RIGHT)

static func get_dashboard_outer_margin_bottom() -> int:
	return maxi(0, DASHBOARD_OUTER_MARGIN_BOTTOM)

static func get_dashboard_section_gap() -> int:
	return maxi(0, DASHBOARD_SECTION_GAP)

static func get_dashboard_left_section_base_min_width() -> int:
	return maxi(80, DASHBOARD_LEFT_SECTION_BASE_MIN_WIDTH)

static func get_dashboard_center_section_base_min_width() -> int:
	return maxi(120, DASHBOARD_CENTER_SECTION_BASE_MIN_WIDTH)

static func get_dashboard_right_section_base_min_width() -> int:
	return maxi(80, DASHBOARD_RIGHT_SECTION_BASE_MIN_WIDTH)

static func get_dashboard_left_section_floor_min_width() -> int:
	return maxi(64, DASHBOARD_LEFT_SECTION_FLOOR_MIN_WIDTH)

static func get_dashboard_center_section_floor_min_width() -> int:
	return maxi(96, DASHBOARD_CENTER_SECTION_FLOOR_MIN_WIDTH)

static func get_dashboard_right_section_floor_min_width() -> int:
	return maxi(64, DASHBOARD_RIGHT_SECTION_FLOOR_MIN_WIDTH)

static func get_dashboard_left_section_width_share() -> float:
	return maxf(0.01, DASHBOARD_LEFT_SECTION_WIDTH_SHARE)

static func get_dashboard_center_section_width_share() -> float:
	return maxf(0.01, DASHBOARD_CENTER_SECTION_WIDTH_SHARE)

static func get_dashboard_right_section_width_share() -> float:
	return maxf(0.01, DASHBOARD_RIGHT_SECTION_WIDTH_SHARE)

static func get_dashboard_left_section_stretch() -> float:
	return maxf(0.1, DASHBOARD_LEFT_SECTION_STRETCH)

static func get_dashboard_center_section_stretch() -> float:
	return maxf(0.1, DASHBOARD_CENTER_SECTION_STRETCH)

static func get_dashboard_right_section_stretch() -> float:
	return maxf(0.1, DASHBOARD_RIGHT_SECTION_STRETCH)

static func get_dashboard_display_banner_width_share() -> float:
	return clampf(DASHBOARD_DISPLAY_BANNER_WIDTH_SHARE, 0.20, 0.70)

static func get_dashboard_display_banner_frame_thickness_scale() -> float:
	return clampf(DASHBOARD_DISPLAY_BANNER_FRAME_THICKNESS_SCALE, 0.25, 2.0)

static func get_dashboard_section_inner_margin_left() -> int:
	return maxi(0, DASHBOARD_SECTION_INNER_MARGIN_LEFT)

static func get_dashboard_section_inner_margin_top() -> int:
	return maxi(0, DASHBOARD_SECTION_INNER_MARGIN_TOP)

static func get_dashboard_section_inner_margin_right() -> int:
	return maxi(0, DASHBOARD_SECTION_INNER_MARGIN_RIGHT)

static func get_dashboard_section_inner_margin_bottom() -> int:
	return maxi(0, DASHBOARD_SECTION_INNER_MARGIN_BOTTOM)

static func get_dashboard_section_content_separation() -> int:
	return maxi(0, DASHBOARD_SECTION_CONTENT_SEPARATION)

static func get_dashboard_section_title_font_size() -> int:
	return maxi(8, DASHBOARD_SECTION_TITLE_FONT_SIZE)

static func get_dashboard_level_font_size() -> int:
	return maxi(10, DASHBOARD_LEVEL_FONT_SIZE)

static func get_dashboard_gold_font_size() -> int:
	return maxi(10, DASHBOARD_GOLD_FONT_SIZE)

static func get_dashboard_summary_font_size() -> int:
	return maxi(8, DASHBOARD_SUMMARY_FONT_SIZE)

static func get_dashboard_message_font_size() -> int:
	return maxi(8, DASHBOARD_MESSAGE_FONT_SIZE)

static func get_dashboard_seed_font_size() -> int:
	return maxi(8, DASHBOARD_SEED_FONT_SIZE)

static func get_dashboard_button_font_size() -> int:
	return maxi(8, DASHBOARD_BUTTON_FONT_SIZE)

static func get_dashboard_upgrade_button_font_size() -> int:
	return maxi(8, DASHBOARD_UPGRADE_BUTTON_FONT_SIZE)

static func get_dashboard_message_banner_min_height() -> int:
	return maxi(40, DASHBOARD_MESSAGE_BANNER_MIN_HEIGHT)

static func get_dashboard_message_content_min_height() -> int:
	return maxi(24, DASHBOARD_MESSAGE_CONTENT_MIN_HEIGHT)

static func get_dashboard_message_banner_margin_left() -> int:
	return maxi(0, DASHBOARD_MESSAGE_BANNER_MARGIN_LEFT)

static func get_dashboard_message_banner_margin_top() -> int:
	return maxi(0, DASHBOARD_MESSAGE_BANNER_MARGIN_TOP)

static func get_dashboard_message_banner_margin_right() -> int:
	return maxi(0, DASHBOARD_MESSAGE_BANNER_MARGIN_RIGHT)

static func get_dashboard_message_banner_margin_bottom() -> int:
	return maxi(0, DASHBOARD_MESSAGE_BANNER_MARGIN_BOTTOM)

static func get_dashboard_message_text_boundary_left() -> int:
	return maxi(0, DASHBOARD_MESSAGE_TEXT_BOUNDARY_LEFT)

static func get_dashboard_message_text_boundary_top() -> int:
	return maxi(0, DASHBOARD_MESSAGE_TEXT_BOUNDARY_TOP)

static func get_dashboard_message_text_boundary_right() -> int:
	return maxi(0, DASHBOARD_MESSAGE_TEXT_BOUNDARY_RIGHT)

static func get_dashboard_message_text_boundary_bottom() -> int:
	return maxi(0, DASHBOARD_MESSAGE_TEXT_BOUNDARY_BOTTOM)

static func get_dashboard_gold_shell_min_height() -> int:
	return maxi(32, DASHBOARD_GOLD_SHELL_MIN_HEIGHT)

static func get_dashboard_gold_shell_margin_left() -> int:
	return maxi(0, DASHBOARD_GOLD_SHELL_MARGIN_LEFT)

static func get_dashboard_gold_shell_margin_top() -> int:
	return maxi(0, DASHBOARD_GOLD_SHELL_MARGIN_TOP)

static func get_dashboard_gold_shell_margin_right() -> int:
	return maxi(0, DASHBOARD_GOLD_SHELL_MARGIN_RIGHT)

static func get_dashboard_gold_shell_margin_bottom() -> int:
	return maxi(0, DASHBOARD_GOLD_SHELL_MARGIN_BOTTOM)

static func get_dashboard_seed_shell_min_height() -> int:
	return maxi(40, DASHBOARD_SEED_SHELL_MIN_HEIGHT)

static func get_dashboard_seed_shell_margin_left() -> int:
	return maxi(0, DASHBOARD_SEED_SHELL_MARGIN_LEFT)

static func get_dashboard_seed_shell_margin_top() -> int:
	return maxi(0, DASHBOARD_SEED_SHELL_MARGIN_TOP)

static func get_dashboard_seed_shell_margin_right() -> int:
	return maxi(0, DASHBOARD_SEED_SHELL_MARGIN_RIGHT)

static func get_dashboard_seed_shell_margin_bottom() -> int:
	return maxi(0, DASHBOARD_SEED_SHELL_MARGIN_BOTTOM)

static func get_dashboard_upgrade_button_min_height() -> int:
	return maxi(28, DASHBOARD_UPGRADE_BUTTON_MIN_HEIGHT)

static func get_dashboard_control_button_min_width() -> int:
	return maxi(48, DASHBOARD_CONTROL_BUTTON_MIN_WIDTH)

static func get_dashboard_control_button_min_height() -> int:
	return maxi(24, DASHBOARD_CONTROL_BUTTON_MIN_HEIGHT)

static func get_dashboard_small_button_min_width() -> int:
	return maxi(36, DASHBOARD_SMALL_BUTTON_MIN_WIDTH)

static func get_dashboard_small_button_min_height() -> int:
	return maxi(20, DASHBOARD_SMALL_BUTTON_MIN_HEIGHT)

static func get_dashboard_help_badge_min_width() -> int:
	return maxi(12, DASHBOARD_HELP_BADGE_MIN_WIDTH)

static func get_dashboard_help_badge_min_height() -> int:
	return maxi(12, DASHBOARD_HELP_BADGE_MIN_HEIGHT)

static func get_dashboard_help_badge_offset_left() -> float:
	return DASHBOARD_HELP_BADGE_OFFSET_LEFT

static func get_dashboard_help_badge_offset_top() -> float:
	return DASHBOARD_HELP_BADGE_OFFSET_TOP

static func get_dashboard_help_badge_offset_right() -> float:
	return DASHBOARD_HELP_BADGE_OFFSET_RIGHT

static func get_dashboard_help_badge_offset_bottom() -> float:
	return DASHBOARD_HELP_BADGE_OFFSET_BOTTOM

# ==================== SHOP UI ====================
const BUTTON_TEXT_ENABLED: Color = Color.WHITE
const BUTTON_TEXT_DISABLED: Color = Color.BLACK

# ==================== LAUNCH VALIDATION ====================
const INVALID_LAUNCH_MESSAGE: String = "Ball won't fit here — try another spot!"

# ==================== CAMERA FOLLOW ====================
const CAMERA_FOLLOW_LERP_SPEED: float = 7.2
const CAMERA_FOLLOW_LEAD_OFFSET_Y: float = -95.0
const CAMERA_FOLLOW_FIXED_ZOOM: bool = true

# ==================== PROVINCE LAUNCH LOCK (NEW - March 2026) ====================
# Used for both post-win engagements and neutral-province settlement on Grand Map
const PROVINCE_LOCK_MESSAGE: String = "Must shoot from the secured province!"
