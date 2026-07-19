extends RefCounted

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const CAPTURE_SOURCE_NONE := ""
const CAPTURE_SOURCE_PLAYER_ENGAGEMENT := "player_engagement"
const CAPTURE_SOURCE_FRIENDLY_MARCH := "friendly_march"
const BOSS_HOME_FLAG_KEY := "is_boss_home"
const CALTROPS_KEY := "caltrops"
const MAX_ACTIVE_CALTROPS_PER_PROVINCE: int = 5
const PROVINCE_GOLD_PRODUCTION_KEY := "gold_production"
const PROVINCE_FREE_BUILDINGS_KEY := "free_buildings"
const PROVINCE_BUILDING_CAPACITY_KEY := "building_capacity"
const PROVINCE_ENGAGEMENT_MAP_TYPE_KEY := "engagement_map_type"
const PROVINCE_NAME_KEY := "province_name"
const PROVINCE_ECONOMY_SCHEMA_VERSION: int = 2
const PROVINCE_ECONOMY_VERSION_KEY := "province_economy_version"
const PROVINCE_POPULATION_KEY := "population"
const PROVINCE_HAPPINESS_KEY := "happiness"
const PROVINCE_FOOD_KEY := "food"
const PROVINCE_RATES_KEY := "rates"
const PROVINCE_ACCOMMODATION_KEY := "accommodation"
const PROVINCE_BUILDINGS_KEY := "buildings"
const PROVINCE_ACTIVE_CONSTRUCTION_KEY := "active_construction"
const PROVINCE_CONSTRUCTION_QUEUE_KEY := "construction_queue"
const PROVINCE_STATUS_KEY := "province_status"
const POPULATION_NATIVES_KEY := "natives"
const POPULATION_OUTLANDER_KEY := "outlanders"
const ACCOMMODATION_NATIVE_CEILING_KEY := "native_ceiling"
const ACCOMMODATION_OUTLANDER_CEILING_KEY := "outlander_ceiling"
const BUILDING_CLUB_FACTORY := "club_factory"
const BUILDING_TRAP_FACTORY := "trap_factory"
const BUILDING_CATAPULT := "catapult"
const BUILDING_HOME_CAVE := "home_cave"
const BUILDING_FARM := "farm"
const BUILDING_MANSION := "mansion"
const BUILDING_TENEMENT := "tenement"
const BUILDING_GROWTH_INCREASER := "growth_increaser"
const BUILDING_DEFENSE_NEST := BUILDING_TRAP_FACTORY
const BUILDING_COMMAND_CENTER := BUILDING_HOME_CAVE
const BUILDING_FOOD_MAKER := BUILDING_FARM
const BUILDING_OUTLANDER_ACCOMMODATION := BUILDING_MANSION
const BUILDING_NATIVE_ACCOMMODATION := BUILDING_TENEMENT
const CONSTRUCTION_PROJECT_BUILD := "build"
const CONSTRUCTION_PROJECT_UPGRADE := "upgrade"
const CONSTRUCTION_PROJECT_DEMOLISH := "demolish"
const CONSTRUCTION_PROJECT_REPAIR := "repair"
const CONSTRUCTION_PROJECT_RECRUITMENT := "recruitment"
const CONSTRUCTION_RECRUITMENT_CONVERSION_RATE: float = 0.5
const PLAYER_LANDING_CONSTRUCTION_BONUS: float = 10.0
const REBEL_FACTION_ID: int = 9000
const REBELLION_RESET_HAPPINESS: float = 50.0
const DEFAULT_NATIVE_POPULATION: float = 24.0
const DEFAULT_OUTLANDER_POPULATION: float = 4.0
const DEFAULT_HAPPINESS: float = 60.0
const NATIVE_POPULATION_CAP: float = 150.0
const OUTLANDER_POPULATION_CAP: float = 30.0
const NATIVE_GROWTH_TAPER_BASE_CAP: float = 50.0
const OUTLANDER_GROWTH_TAPER_BASE_CAP: float = 30.0
const NATIVE_GROWTH_TAPER_CAP_PER_TENEMENT: float = 30.0
const OUTLANDER_GROWTH_TAPER_CAP_PER_MANSION: float = 30.0
const CONSTRUCTION_RATE_CAP: float = 10.0
const RECRUITMENT_RATE_CAP: float = 8.0
const BASE_FOOD_PRODUCTION: float = 0.0
const NATIVE_FOOD_DEMAND: float = 0.35
const OUTLANDER_FOOD_DEMAND: float = 0.8
const TROOP_FOOD_DEMAND: float = 0.0
const BASE_NATIVE_ACCOMMODATION: float = 0.0
const BASE_OUTLANDER_ACCOMMODATION: float = 0.0
const BASE_GROWTH_FACTOR: float = 5.0
const BASE_RECRUITMENT_RATE: float = 3.0
const BASE_CONSTRUCTION_RATE: float = 6.2
const BASE_INCOME_RATE: float = 5.0
const NATIVE_GROWTH_RATE: float = 0.08
const OUTLANDER_GROWTH_RATE: float = 0.04
const NATIVE_CONSTRUCTION_FACTOR: float = 0.45
const NATIVE_RECRUITMENT_FACTOR: float = 0.03
const OUTLANDER_INCOME_FACTOR: float = 0.55
const REPAIR_PROGRESS_REQUIRED: float = 12.0
const FOOD_SURPLUS_HAPPINESS_RECOVERY: float = 1.0
const FOOD_DEFICIT_HAPPINESS_PENALTY_PER_POINT: float = 0.6
const FOOD_GROWTH_MODIFIER_PER_POINT: float = 0.6
const OVERCROWDING_HAPPINESS_PENALTY_PER_PERSON: float = 0.5
const PASSIVE_HAPPINESS_RECOVERY: float = 1.0

# Province tuning defaults mirror the pre-tuning constants. Change these values to tune
# specific mechanics; raise master_dynamic_pace toward 1.0 to move the whole system faster.
const PROVINCE_TUNING := {
	"master_dynamic_pace": 0.0,
	"default_native_population": DEFAULT_NATIVE_POPULATION,
	"default_outlander_population": DEFAULT_OUTLANDER_POPULATION,
	"default_happiness": DEFAULT_HAPPINESS,
	"native_population_cap": NATIVE_POPULATION_CAP,
	"outlander_population_cap": OUTLANDER_POPULATION_CAP,
	"construction_rate_cap": CONSTRUCTION_RATE_CAP,
	"recruitment_rate_cap": RECRUITMENT_RATE_CAP,
	"enemy_starting_population_multiplier": 1.0,
	"friendly_starting_population_multiplier": 1.0,
	"base_food_production": BASE_FOOD_PRODUCTION,
	"native_food_demand": NATIVE_FOOD_DEMAND,
	"outlander_food_demand": OUTLANDER_FOOD_DEMAND,
	"troop_food_demand": TROOP_FOOD_DEMAND,
	"base_native_accommodation": BASE_NATIVE_ACCOMMODATION,
	"base_outlander_accommodation": BASE_OUTLANDER_ACCOMMODATION,
	"base_growth_factor": BASE_GROWTH_FACTOR,
	"base_recruitment_rate": BASE_RECRUITMENT_RATE,
	"base_construction_rate": BASE_CONSTRUCTION_RATE,
	"base_income_rate": BASE_INCOME_RATE,
	"native_growth_rate": NATIVE_GROWTH_RATE,
	"outlander_growth_rate": OUTLANDER_GROWTH_RATE,
	"native_construction_factor": NATIVE_CONSTRUCTION_FACTOR,
	"native_recruitment_factor": NATIVE_RECRUITMENT_FACTOR,
	"outlander_income_factor": OUTLANDER_INCOME_FACTOR,
	"building_build_progress_required_multiplier": 1.0,
	"building_upgrade_progress_required_multiplier": 1.0,
	"repair_progress_required": REPAIR_PROGRESS_REQUIRED,
	"building_food_production_multiplier": 1.0,
	"building_native_accommodation_multiplier": 1.0,
	"building_outlander_accommodation_multiplier": 1.0,
	"building_growth_factor_multiplier": 3.0,
	"building_recruitment_multiplier": 3.0,
	"building_construction_multiplier": 3.0,
	"building_income_multiplier": 3.0,
	"building_defense_strength_multiplier": 3.0,
	"building_adjacent_damage_multiplier": 3.0,
	"food_surplus_happiness_recovery": FOOD_SURPLUS_HAPPINESS_RECOVERY,
	"food_deficit_happiness_penalty_per_point": FOOD_DEFICIT_HAPPINESS_PENALTY_PER_POINT,
	"food_growth_modifier_per_point": FOOD_GROWTH_MODIFIER_PER_POINT,
	"food_deficit_population_growth_multiplier": 0.35,
	"overcrowding_happiness_penalty_per_person": OVERCROWDING_HAPPINESS_PENALTY_PER_PERSON,
	"passive_happiness_recovery": PASSIVE_HAPPINESS_RECOVERY,
	"happiness_rate_effect_multiplier": 1.0,
	"revolt_warning_happiness_threshold": 15.0,
	"revolt_happiness_threshold": 0.0,
	"max_active_caltrops_per_province": MAX_ACTIVE_CALTROPS_PER_PROVINCE,
	"catapult_adjacent_damage_multiplier": 1.0,
	"trap_factory_caltrop_multiplier": 1.0,
	"low_happiness_warning_threshold": 35.0,
	"ai_food_deficit_build_threshold": 0.0,
	"ai_overcrowding_build_threshold": 0.0,
	"ai_forecast_horizon_ticks": 2.0,
	"ai_forecast_food_surplus_threshold": -2.0,
	"ai_forecast_overcrowding_threshold": 10.0,
	"ai_forecast_score_base": 6200.0,
	"ai_forecast_food_pressure_score_per_point": 12.0,
	"ai_forecast_overcrowding_score_per_person": 14.0,
	"ai_forecast_min_relief": 0.1
}

const PROVINCE_DYNAMIC_TUNING := {
	"default_native_population": DEFAULT_NATIVE_POPULATION,
	"default_outlander_population": DEFAULT_OUTLANDER_POPULATION,
	"default_happiness": DEFAULT_HAPPINESS - 5.0,
	"native_population_cap": NATIVE_POPULATION_CAP,
	"outlander_population_cap": OUTLANDER_POPULATION_CAP,
	"construction_rate_cap": CONSTRUCTION_RATE_CAP,
	"recruitment_rate_cap": RECRUITMENT_RATE_CAP,
	"enemy_starting_population_multiplier": 1.0,
	"friendly_starting_population_multiplier": 1.15,
	"base_food_production": BASE_FOOD_PRODUCTION,
	"native_food_demand": NATIVE_FOOD_DEMAND * 1.15,
	"outlander_food_demand": OUTLANDER_FOOD_DEMAND * 1.15,
	"troop_food_demand": TROOP_FOOD_DEMAND * 1.25,
	"base_native_accommodation": BASE_NATIVE_ACCOMMODATION,
	"base_outlander_accommodation": BASE_OUTLANDER_ACCOMMODATION,
	"base_growth_factor": BASE_GROWTH_FACTOR * 1.25,
	"base_recruitment_rate": BASE_RECRUITMENT_RATE + 0.2,
	"base_construction_rate": BASE_CONSTRUCTION_RATE * 1.8,
	"base_income_rate": BASE_INCOME_RATE * 1.8,
	"native_growth_rate": NATIVE_GROWTH_RATE * 0.8,
	"outlander_growth_rate": OUTLANDER_GROWTH_RATE * 2.0,
	"native_construction_factor": NATIVE_CONSTRUCTION_FACTOR * 1.8,
	"native_recruitment_factor": NATIVE_RECRUITMENT_FACTOR * 1.8,
	"outlander_income_factor": OUTLANDER_INCOME_FACTOR * 1.8,
	"building_build_progress_required_multiplier": 0.55,
	"building_upgrade_progress_required_multiplier": 0.55,
	"repair_progress_required": REPAIR_PROGRESS_REQUIRED * 0.55,
	"building_food_production_multiplier": 1.35,
	"building_native_accommodation_multiplier": 1.25,
	"building_outlander_accommodation_multiplier": 1.25,
	"building_growth_factor_multiplier": 1.75,
	"building_recruitment_multiplier": 1.8,
	"building_construction_multiplier": 1.8,
	"building_income_multiplier": 1.8,
	"building_defense_strength_multiplier": 1.35,
	"building_adjacent_damage_multiplier": 1.5,
	"food_surplus_happiness_recovery": FOOD_SURPLUS_HAPPINESS_RECOVERY * 1.6,
	"food_deficit_happiness_penalty_per_point": FOOD_DEFICIT_HAPPINESS_PENALTY_PER_POINT * 1.6,
	"food_growth_modifier_per_point": FOOD_GROWTH_MODIFIER_PER_POINT * 1.7,
	"food_deficit_population_growth_multiplier": 0.2,
	"overcrowding_happiness_penalty_per_person": OVERCROWDING_HAPPINESS_PENALTY_PER_PERSON * 1.6,
	"passive_happiness_recovery": PASSIVE_HAPPINESS_RECOVERY * 1.6,
	"happiness_rate_effect_multiplier": 1.5,
	"revolt_warning_happiness_threshold": 20.0,
	"revolt_happiness_threshold": 0.0,
	"max_active_caltrops_per_province": MAX_ACTIVE_CALTROPS_PER_PROVINCE + 2.0,
	"catapult_adjacent_damage_multiplier": 1.5,
	"trap_factory_caltrop_multiplier": 1.4,
	"low_happiness_warning_threshold": 45.0,
	"ai_food_deficit_build_threshold": 2.0,
	"ai_overcrowding_build_threshold": 2.0,
	"ai_forecast_horizon_ticks": 3.0,
	"ai_forecast_food_surplus_threshold": 1.0,
	"ai_forecast_overcrowding_threshold": 4.0,
	"ai_forecast_score_base": 7000.0,
	"ai_forecast_food_pressure_score_per_point": 15.0,
	"ai_forecast_overcrowding_score_per_person": 20.0,
	"ai_forecast_min_relief": 0.1
}

const DEFAULT_PROVINCE_STARTING_BUILDINGS := {
	"farm": {"1": 1},
	"tenement": {"1": 1},
	"mansion": {"1": 1}
}

const LEGACY_BUILDING_ID_ALIASES := {
	"defense_nest": BUILDING_TRAP_FACTORY,
	"command_center": BUILDING_HOME_CAVE,
	"food_maker": BUILDING_FARM,
	"outlander_accommodation_center": BUILDING_MANSION,
	"native_accommodation_center": BUILDING_TENEMENT
}

const BUILDING_SPRITE_PATHS := {
	BUILDING_CLUB_FACTORY: "res://sprites/club_factory.png",
	BUILDING_TRAP_FACTORY: "res://sprites/trap_factory.png",
	BUILDING_CATAPULT: "res://sprites/catapult.png",
	BUILDING_HOME_CAVE: "res://sprites/home_cave.png",
	BUILDING_FARM: "res://sprites/farm.png",
	BUILDING_MANSION: "res://sprites/mansion.png",
	BUILDING_TENEMENT: "res://sprites/tenement.png"
}

const BUILDING_CATALOG := {
	"club_factory": {
		"id": BUILDING_CLUB_FACTORY,
		"display_name": "Club Factory",
		"max_tier": 3,
		"unique_per_province": false,
		"base_build_cost": 5,
		"base_build_progress_required": 14,
		"tier_effects": {
			"1": {"recruitment": 0.6},
			"2": {"recruitment": 1.25},
			"3": {"recruitment": 2.1}
		}
	},
	"trap_factory": {
		"id": BUILDING_TRAP_FACTORY,
		"display_name": "Trap Factory",
		"max_tier": 3,
		"unique_per_province": false,
		"base_build_cost": 7,
		"base_build_progress_required": 16,
		"tier_effects": {
			"1": {"defense_strength": 1.0},
			"2": {"defense_strength": 2.0},
			"3": {"defense_strength": 3.0}
		}
	},
	"catapult": {
		"id": BUILDING_CATAPULT,
		"display_name": "Catapult",
		"max_tier": 3,
		"unique_per_province": false,
		"base_build_cost": 15,
		"base_build_progress_required": 30,
		"tier_effects": {
			"1": {"adjacent_damage": 10.0},
			"2": {"adjacent_damage": 20.0},
			"3": {"adjacent_damage": 30.0}
		}
	},
	"home_cave": {
		"id": BUILDING_HOME_CAVE,
		"display_name": "Home Cave",
		"max_tier": 3,
		"unique_per_province": true,
		"base_build_cost": 20,
		"base_build_progress_required": 36,
		"tier_effects": {
			"1": {"command_center": true},
			"2": {"command_center": true, "construction": 0.8},
			"3": {"command_center": true, "construction": 1.5}
		}
	},
	"farm": {
		"id": BUILDING_FARM,
		"display_name": "Farm",
		"max_tier": 3,
		"unique_per_province": false,
		"base_build_cost": 3,
		"base_build_progress_required": 12,
		"tier_effects": {
			"1": {"food_production": 18.0},
			"2": {"food_production": 34.0},
			"3": {"food_production": 56.0}
		}
	},
	"mansion": {
		"id": BUILDING_MANSION,
		"display_name": "Mansion",
		"max_tier": 3,
		"unique_per_province": false,
		"base_build_cost": 5,
		"base_build_progress_required": 14,
		"tier_effects": {
			"1": {"outlander_accommodation": 7.0},
			"2": {"outlander_accommodation": 15.0},
			"3": {"outlander_accommodation": 26.0}
		}
	},
	"tenement": {
		"id": BUILDING_TENEMENT,
		"display_name": "Tenement",
		"max_tier": 3,
		"unique_per_province": false,
		"base_build_cost": 4,
		"base_build_progress_required": 14,
		"tier_effects": {
			"1": {"native_accommodation": 50.0},
			"2": {"native_accommodation": 100.0},
			"3": {"native_accommodation": 150.0}
		}
	},
	"growth_increaser": {
		"id": BUILDING_GROWTH_INCREASER,
		"display_name": "Growth Increaser",
		"max_tier": 3,
		"unique_per_province": false,
		"base_build_cost": 6,
		"base_build_progress_required": 18,
		"tier_effects": {
			"1": {"growth_factor": 0.12},
			"2": {"growth_factor": 0.28},
			"3": {"growth_factor": 0.5}
		}
	}
}

const BOSS_HOME_FILL_COLOR := Color(0.62, 0.14, 0.78, 0.62)
const BOSS_HOME_BORDER_COLOR := Color(1.0, 0.54, 0.22, 0.98)
const BOSS_HOME_INNER_GLOW_COLOR := Color(1.0, 0.76, 0.32, 0.72)
const BOSS_HOME_INFO_BOX_BG_COLOR := Color(0.20, 0.08, 0.24, 0.88)
const BOSS_HOME_INFO_TEXT_COLOR := Color(1.0, 0.92, 0.72, 1.0)
const PROVINCE_FILL_Z_INDEX := LevelConfig.VISUAL_LAYER_PROVINCE_FILL
const PROVINCE_BORDERS_Z_INDEX := LevelConfig.VISUAL_LAYER_BORDERS
const PROVINCE_BORDER_OVERLAYS_Z_INDEX := LevelConfig.VISUAL_LAYER_BORDER_OVERLAYS
const PROVINCE_COUNTS_BACKGROUND_Z_INDEX := LevelConfig.VISUAL_LAYER_PROVINCE_INFO_CARDS
const PROVINCE_COUNTS_LABEL_Z_INDEX := LevelConfig.VISUAL_LAYER_PROVINCE_INFO_CARDS + 1
const PROVINCE_BUILD_MODE_VISUALS_Z_INDEX := LevelConfig.VISUAL_LAYER_AUTO_ENGAGEMENT_PREVIEW_TROOPS + 10
const PROVINCE_TROOP_VISUALS_Z_INDEX := LevelConfig.VISUAL_LAYER_GRAND_MAP_PROVINCE_TROOPS
const PROVINCE_TROOP_VISUALS_ROOT_NAME := "ProvinceTroopVisuals"
const PROVINCE_BUILDING_VISUALS_ROOT_NAME := "ProvinceBuildingVisuals"
const PROVINCE_BUILD_MODE_VISUALS_ROOT_NAME := "ProvinceBuildModeVisuals"
const PROVINCE_BUILD_MODE_CANVAS_LAYER_NAME := "ProvinceBuildModeCanvasLayer"
const PROVINCE_BUILD_MODE_OVERLAY_ROOT_NAME := "ProvinceBuildModeOverlayRoot"
const PROVINCE_BUILD_MODE_DEBUG_ROOT_NAME := "ProvinceBuildModeDebugRoot"
const PROVINCE_BUILD_QUEUE_LIMIT: int = 5
const PROVINCE_BUILD_MODE_CHOICE_ICON_SIZE: float = 210.0
const PROVINCE_BUILD_MODE_QUEUE_ICON_SIZE: float = 72.0
const PROVINCE_BUILD_MODE_CHOICE_SPACING: float = 120.0
const PROVINCE_BUILD_MODE_QUEUE_SPACING: float = 62.0
const PROVINCE_TROOP_VISUALS_MAX_COUNT: int = 50
const PROVINCE_TROOP_VISUALS_REDUCED_COUNT: int = 24
const PROVINCE_TROOP_VISUALS_ICON_SIZE: float = 3.2
const PROVINCE_TROOP_VISUALS_ICON_SPACING: float = 8.0
const PROVINCE_TROOP_VISUALS_ROW_WIDTH: int = 10
const PROVINCE_TROOP_VISUALS_PILE_MIN_RADIUS_MULTIPLIER: float = 0.35
const PROVINCE_TROOP_VISUALS_PILE_MAX_RADIUS_MULTIPLIER: float = 2.1
const PROVINCE_TROOP_VISUALS_PILE_SWIRL_TURNS: float = 2.55
const PROVINCE_BUILDING_VISUALS_ICON_SIZE: float = 42.0
const PROVINCE_BUILDING_VISUALS_ICON_SPACING: float = 52.0
const PROVINCE_BUILDING_VISUALS_ROW_WIDTH: int = 4
const PROVINCE_BUILDING_VISUALS_CARD_GAP: float = 24.0
const LOCKED_PROVINCE_INNER_OVERLAY_NAME := "LockedProvinceInnerOverlay"
const LOCKED_PROVINCE_PATTERN_OVERLAY_NAME := "LockedProvincePatternOverlay"
const PENDING_INVASION_PATTERN_OVERLAY_NAME := "PendingInvasionPatternOverlay"
const PROVINCE_INFO_PANEL_TEXTURE_PATH := "res://sprites/province_info_panel.png"
const PROVINCE_OWNER_BADGE_NEUTRAL_TEXTURE_PATH := "res://sprites/province_owner_badge_neutral.png"
const PROVINCE_OWNER_BADGE_FRIENDLY_TEXTURE_PATH := "res://sprites/province_owner_badge_friendly.png"
const PROVINCE_OWNER_BADGE_ENEMY_TEXTURE_PATH := "res://sprites/province_owner_badge_enemy.png"
const RELATION_SELF := "self"
const RELATION_ALLY := "ally"
const RELATION_HOSTILE := "hostile"
const RELATION_NEUTRAL := "neutral"
# Canonical owner-relation semantics for province ownership:
# - RELATION_SELF: player-owned province (friendly type, non-friendly-boss faction id).
# - RELATION_ALLY: non-player friendly ownership (friendly-boss faction).
# - RELATION_HOSTILE: enemy ownership (enemy type, non-friendly-boss faction id).
# - RELATION_NEUTRAL: unowned/neutral province (neutral type, faction_id normalized to 0).
const PROVINCE_ICON_TROOPS_TEXTURE_PATH := "res://sprites/icon_troops.png"
const PROVINCE_ICON_BUILDING_TEXTURE_PATH := "res://sprites/icon_building.png"
const PROVINCE_ICON_GOLD_TEXTURE_PATH := "res://sprites/icon_gold.png"
const PROVINCE_ICON_FREE_BUILDING_TEXTURE_PATH := "res://sprites/icon_free_building.png"
const PROVINCE_ICON_CAP_TEXTURE_PATH := "res://sprites/icon_cap.png"
const PROVINCE_ICON_NATIVE_TEXTURE_PATH := "res://sprites/icons/native.png"
const PROVINCE_ICON_OUTLANDER_TEXTURE_PATH := "res://sprites/icons/outlander.png"
const PROVINCE_ICON_HAPPINESS_TEXTURE_PATH := "res://sprites/icons/happiness.png"
const PROVINCE_ICON_FOOD_SURPLUS_TEXTURE_PATH := "res://sprites/icons/food.png"
const PROVINCE_ICON_FAILURE_X_TEXTURE_PATH := "res://sprites/x_icon.png"
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
const PROVINCE_INFO_PANEL_ECONOMY_LABEL_NAME := "ProvinceEconomyLabel"
const PROVINCE_INFO_PANEL_METRIC_FOOD_ICON_NAME := "ProvinceMetricFoodIcon"
const PROVINCE_INFO_PANEL_METRIC_FOOD_X_NAME := "ProvinceMetricFoodX"
const PROVINCE_INFO_PANEL_METRIC_ACCOMMODATION_ICON_NAME := "ProvinceMetricAccommodationIcon"
const PROVINCE_INFO_PANEL_METRIC_ACCOMMODATION_X_NAME := "ProvinceMetricAccommodationX"
const PROVINCE_INFO_PANEL_METRIC_HAPPINESS_ICON_NAME := "ProvinceMetricHappinessIcon"
const PROVINCE_INFO_PANEL_METRIC_HAPPINESS_X_NAME := "ProvinceMetricHappinessX"
const PROVINCE_INFO_PANEL_METRIC_CONSTRUCTION_ICON_NAME := "ProvinceMetricConstructionIcon"
const PROVINCE_INFO_PANEL_DESIRED_WIDTH: float = 190.0
const PROVINCE_INFO_PANEL_FALLBACK_HEIGHT: float = 94.0
const FRIENDLY_BOSS_FACTION_DISPLAY_COLOR := Color(0.95, 0.84, 0.22, 0.45)
const FACTION_NAME_ID_OFFSET: int = 1000000
const ENABLE_LAUNCH_PROVINCE_PULSE: bool = true
const LAUNCH_PULSE_QUANTIZE_STEP_SECONDS: float = 0.10
const LAUNCH_PROVINCE_PATTERN_TINT: Color = Color(1.0, 0.93, 0.55, 0.36)

var _main: Node = null
var _province_ui_texture_cache: Dictionary = {}
var _province_owner_badge_fill_shader: Shader = null
var _province_node_cache_dirty: bool = true
var _cached_province_nodes: Array = []
var _province_node_by_id: Dictionary = {}
var _last_locked_launch_province_id: int = -1
var _shared_border_overlay_geometry_signature: int = 0
var _shared_border_overlay_cached_display_runs: Array = []
var _shared_border_overlay_children_geometry_signature: int = -1
var _shared_border_overlay_last_locked_province_id: int = -2
var _faction_name_cache: Dictionary = {}
var _launch_pulse_last_quantized_step: int = -1
var _locked_province_pattern_texture: Texture2D = null
var _locked_province_pattern_texture_cell_size: int = -1
var _locked_province_pattern_texture_line_thickness: int = -1
var _pending_invasion_pattern_texture: Texture2D = null
var _pending_invasion_pattern_texture_cell_size: int = -1
var _pending_invasion_pattern_texture_line_thickness: int = -1
var _build_mode_debug_visuals_enabled: bool = false

class ProvinceBuildModeDebugVisuals extends Node2D:
	var panel_rects: Array[Rect2] = []
	var icon_rects: Array[Rect2] = []
	var caption_lines: Array[String] = []

	func set_debug_data(new_panel_rects: Array[Rect2], new_icon_rects: Array[Rect2], new_caption_lines: Array[String]) -> void:
		panel_rects = new_panel_rects
		icon_rects = new_icon_rects
		caption_lines = new_caption_lines
		queue_redraw()

	func _draw() -> void:
		for panel_rect in panel_rects:
			draw_rect(panel_rect, Color(1.0, 0.2, 0.2, 0.95), false, 4.0)
			draw_rect(panel_rect.grow(-2.0), Color(1.0, 0.2, 0.2, 0.12), true)
		for icon_rect in icon_rects:
			draw_rect(icon_rect, Color(0.2, 1.0, 0.35, 0.95), false, 4.0)
			draw_rect(icon_rect.grow(-2.0), Color(0.2, 1.0, 0.35, 0.18), true)
		var line_y: float = 12.0
		for line in caption_lines:
			draw_string(ThemeDB.fallback_font, Vector2(12.0, line_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.95, 0.2, 0.98))
			line_y += 18.0

class ProvinceTroopVisual extends Node2D:
	var icon_size: float = PROVINCE_TROOP_VISUALS_ICON_SIZE
	var icon_color: Color = Color.WHITE
	var icon_opacity: float = 1.0

	func update_visual(new_icon_size: float, new_icon_color: Color, new_icon_opacity: float) -> void:
		icon_size = maxf(0.5, new_icon_size)
		icon_color = new_icon_color
		icon_opacity = clampf(new_icon_opacity, 0.05, 1.0)
		queue_redraw()

	func _draw() -> void:
		var draw_color: Color = icon_color
		draw_color.a *= icon_opacity
		var stroke: float = maxf(1.0, icon_size * 0.24)
		var outline_stroke: float = stroke * 1.9
		var outline_color: Color = Color.BLACK
		outline_color.a = draw_color.a
		var head_center: Vector2 = Vector2(0.0, -icon_size * 0.58)
		var neck_y: float = -icon_size * 0.34
		var hip_y: float = icon_size * 0.30
		draw_circle(head_center, icon_size * 0.33, outline_color)
		draw_line(Vector2(0.0, neck_y), Vector2(0.0, hip_y), outline_color, outline_stroke, true)
		draw_line(Vector2(-icon_size * 0.38, -icon_size * 0.05), Vector2(icon_size * 0.38, -icon_size * 0.05), outline_color, outline_stroke * 0.85, true)
		draw_line(Vector2(0.0, hip_y), Vector2(-icon_size * 0.28, icon_size * 0.88), outline_color, outline_stroke * 0.85, true)
		draw_line(Vector2(0.0, hip_y), Vector2(icon_size * 0.28, icon_size * 0.88), outline_color, outline_stroke * 0.85, true)
		draw_circle(head_center, icon_size * 0.24, draw_color)
		draw_line(Vector2(0.0, neck_y), Vector2(0.0, hip_y), draw_color, stroke, true)
		draw_line(Vector2(-icon_size * 0.38, -icon_size * 0.05), Vector2(icon_size * 0.38, -icon_size * 0.05), draw_color, stroke * 0.85, true)
		draw_line(Vector2(0.0, hip_y), Vector2(-icon_size * 0.28, icon_size * 0.88), draw_color, stroke * 0.85, true)
		draw_line(Vector2(0.0, hip_y), Vector2(icon_size * 0.28, icon_size * 0.88), draw_color, stroke * 0.85, true)

class ProvinceBuildingVisual extends Node2D:
	var icon_size: float = PROVINCE_TROOP_VISUALS_ICON_SIZE
	var icon_color: Color = Color.WHITE
	var icon_opacity: float = 1.0
	var sprite: Sprite2D = null
	var sprite_path: String = ""

	func update_visual(new_icon_size: float, new_icon_color: Color, new_icon_opacity: float, new_sprite_path: String = "") -> void:
		icon_size = maxf(0.5, new_icon_size)
		icon_color = new_icon_color
		icon_opacity = clampf(new_icon_opacity, 0.05, 1.0)
		if new_sprite_path != sprite_path:
			sprite_path = new_sprite_path
			_update_sprite()
		_update_sprite_scale()
		queue_redraw()

	func _draw() -> void:
		if sprite != null and sprite.texture != null:
			return
		var draw_color: Color = icon_color
		draw_color.a *= icon_opacity
		var outline_color: Color = Color.BLACK
		outline_color.a = draw_color.a
		var half_w: float = icon_size * 0.42
		var body_top: float = -icon_size * 0.18
		var body_bottom: float = icon_size * 0.55
		var roof_peak: Vector2 = Vector2(0.0, -icon_size * 0.70)
		var roof_left: Vector2 = Vector2(-half_w * 1.12, body_top)
		var roof_right: Vector2 = Vector2(half_w * 1.12, body_top)
		var body_rect := Rect2(Vector2(-half_w, body_top), Vector2(half_w * 2.0, body_bottom - body_top))
		var door_rect := Rect2(Vector2(-icon_size * 0.12, icon_size * 0.10), Vector2(icon_size * 0.24, icon_size * 0.45))
		draw_polygon(PackedVector2Array([roof_peak, roof_right, roof_left]), [outline_color])
		draw_rect(body_rect.grow(0.85), outline_color, true)
		draw_polygon(PackedVector2Array([roof_peak, roof_right, roof_left]), [draw_color])
		draw_rect(body_rect, draw_color, true)
		var door_color: Color = Color(0.16, 0.12, 0.08, draw_color.a)
		draw_rect(door_rect, door_color, true)

	func _update_sprite() -> void:
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = "Sprite"
			sprite.centered = true
			add_child(sprite)
		var texture: Texture2D = load(sprite_path) as Texture2D if sprite_path != "" else null
		sprite.texture = texture
		sprite.visible = texture != null
		_update_sprite_scale()

	func _update_sprite_scale() -> void:
		if sprite == null:
			return
		sprite.modulate = Color(1.0, 1.0, 1.0, icon_opacity)
		var texture: Texture2D = sprite.texture
		if texture == null:
			return
		var tex_size: Vector2 = texture.get_size()
		if tex_size.x <= 0.0 or tex_size.y <= 0.0:
			return
		var longest_edge: float = maxf(tex_size.x, tex_size.y)
		sprite.scale = Vector2.ONE * (icon_size / longest_edge)



func setup(main_node: Node) -> void:
	_main = main_node
	_province_node_cache_dirty = true
	_cached_province_nodes.clear()
	_province_node_by_id.clear()
	_last_locked_launch_province_id = -1
	_shared_border_overlay_geometry_signature = 0
	_shared_border_overlay_cached_display_runs.clear()
	_shared_border_overlay_children_geometry_signature = -1
	_shared_border_overlay_last_locked_province_id = -2
	_faction_name_cache.clear()


func _mark_province_node_cache_dirty() -> void:
	_province_node_cache_dirty = true


func _is_cached_province_node_live(province_node: Variant) -> bool:
	if province_node == null:
		return false
	if not (province_node is Object):
		return false
	if not is_instance_valid(province_node):
		return false
	if not (province_node is Node):
		return false
	if _main == null or not is_instance_valid(_main.provinces_root):
		return false
	var node: Node = province_node
	return node.get_parent() == _main.provinces_root and node.has_meta("province_data")


func _rebuild_province_node_cache() -> void:
	_cached_province_nodes.clear()
	_province_node_by_id.clear()
	if _main == null or not is_instance_valid(_main.provinces_root):
		_province_node_cache_dirty = false
		return
	for child_any in _main.provinces_root.get_children():
		var province_node: Node = child_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		if province_node.name == "SharedProvinceBorderOverlay":
			continue
		if not province_node.has_meta("province_data"):
			continue
		_cached_province_nodes.append(province_node)
		var province_meta: Dictionary = province_node.get_meta("province_data")
		var province_id: int = int(province_meta.get("id", -1))
		if province_id >= 0:
			_province_node_by_id[province_id] = province_node
	_province_node_cache_dirty = false


func _get_expected_cached_province_node_count() -> int:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return 0
	var count: int = 0
	for child_any in _main.provinces_root.get_children():
		var province_node: Node = child_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		if province_node.name == "SharedProvinceBorderOverlay":
			continue
		if not province_node.has_meta("province_data"):
			continue
		count += 1
	return count


func get_province_node_by_id(province_id: int) -> Node:
	_get_cached_province_nodes()
	return _province_node_by_id.get(int(province_id), null)


func _get_cached_province_nodes() -> Array:
	if _province_node_cache_dirty:
		_rebuild_province_node_cache()
	elif _cached_province_nodes.size() != _get_expected_cached_province_node_count():
		_rebuild_province_node_cache()
	else:
		for province_node in _cached_province_nodes:
			if not _is_cached_province_node_live(province_node):
				_rebuild_province_node_cache()
				break
	return _cached_province_nodes


func _get_cached_province_node_by_id(province_id: int) -> Node:
	if province_id < 0:
		return null
	_get_cached_province_nodes()
	var province_node_any: Variant = _province_node_by_id.get(province_id, null)
	if _is_cached_province_node_live(province_node_any):
		return province_node_any as Node
	_rebuild_province_node_cache()
	province_node_any = _province_node_by_id.get(province_id, null)
	return province_node_any as Node if _is_cached_province_node_live(province_node_any) else null


func _compute_polygon_signature(poly: PackedVector2Array) -> int:
	var hash_value: int = poly.size() * 486187739
	for point in poly:
		var px: int = int(round(point.x * 100.0))
		var py: int = int(round(point.y * 100.0))
		hash_value = int(hash("%d|%d|%d" % [hash_value, px, py])) & 0x7fffffff
	return hash_value


func _ensure_cached_province_display_geometry(province_node: Node, fill_node: Polygon2D) -> Dictionary:
	if province_node == null or not is_instance_valid(province_node) or fill_node == null:
		return {
			"border_points": PackedVector2Array(),
			"inner_points": PackedVector2Array()
		}
	var polygon_signature: int = _compute_polygon_signature(fill_node.polygon)
	var cached_signature: int = int(province_node.get_meta("province_display_geometry_signature") if province_node.has_meta("province_display_geometry_signature") else -1)
	var cached_border: PackedVector2Array = province_node.get_meta("province_display_border_points") if province_node.has_meta("province_display_border_points") else PackedVector2Array()
	var cached_inner: PackedVector2Array = province_node.get_meta("province_display_inner_points") if province_node.has_meta("province_display_inner_points") else PackedVector2Array()
	if cached_signature == polygon_signature and cached_border.size() > 0 and cached_inner.size() > 0:
		return {
			"border_points": cached_border,
			"inner_points": cached_inner
		}
	var border_points: PackedVector2Array = make_smoothed_province_display_polyline(fill_node.polygon, maxf(0.5, get_province_outer_line_width() * 0.5))
	var inner_points: PackedVector2Array = make_smoothed_province_display_polyline(fill_node.polygon, maxf(0.5, get_province_outer_line_width() * 0.5 + get_province_inner_line_inset()))
	province_node.set_meta("province_display_geometry_signature", polygon_signature)
	province_node.set_meta("province_display_border_points", border_points)
	province_node.set_meta("province_display_inner_points", inner_points)
	return {
		"border_points": border_points,
		"inner_points": inner_points
	}


func _compute_shared_border_overlay_geometry_signature(province_nodes: Array) -> int:
	var hash_value: int = province_nodes.size() * 92821
	for province_node_any in province_nodes:
		var province_node: Node = province_node_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		var province_meta: Dictionary = province_node.get_meta("province_data") if province_node.has_meta("province_data") else {}
		var province_id: int = int(province_meta.get("id", -1))
		var logical_poly: PackedVector2Array = _ensure_polygon_ccw(_get_logical_province_polygon(province_node))
		hash_value = int(hash("%d|%d|%d" % [hash_value, province_id, _compute_polygon_signature(logical_poly)])) & 0x7fffffff
	return hash_value


func _build_cached_shared_border_display_runs(province_nodes: Array) -> Array:
	var province_centers: Dictionary = {}
	for province_node_any in province_nodes:
		var province_node: Node = province_node_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		var province_data: Dictionary = province_node.get_meta("province_data") if province_node.has_meta("province_data") else {}
		var province_id: int = int(province_data.get("id", -1))
		var logical_poly: PackedVector2Array = _ensure_polygon_ccw(_get_logical_province_polygon(province_node))
		province_centers[province_id] = _get_province_center_from_polygon(logical_poly)
	var border_graph: Dictionary = _collect_province_border_segments(province_nodes)
	var raw_display_runs: Array = _collect_shared_border_display_runs(border_graph, province_centers)
	var cached_runs: Array = []
	var center_inset: float = get_province_shared_border_center_inset()
	for raw_run_any in raw_display_runs:
		var run_data: Dictionary = raw_run_any
		var raw_points: PackedVector2Array = run_data.get("points", PackedVector2Array())
		var closed: bool = bool(run_data.get("closed", false))
		var center_points: PackedVector2Array = _build_shared_border_centerline(raw_points, closed)
		if closed:
			if center_points.size() < 3:
				continue
		else:
			if center_points.size() < 2:
				continue
		var left_points: PackedVector2Array = _build_shared_border_side_line(center_points, center_inset, closed)
		var right_points: PackedVector2Array = _build_shared_border_side_line(center_points, -center_inset, closed)
		cached_runs.append({
			"left_id": int(run_data.get("left_id", -1)),
			"right_id": int(run_data.get("right_id", -1)),
			"closed": closed,
			"left_points": left_points,
			"right_points": right_points
		})
	return cached_runs


func _set_province_inner_glow_visible(province_id: int, visible: bool) -> void:
	var province_node: Node = _get_cached_province_node_by_id(province_id)
	if province_node == null:
		return
	var inner_glow: Line2D = get_province_inner_glow_node(province_node)
	if inner_glow != null:
		inner_glow.visible = visible


func _set_active_locked_launch_province(active_locked_id: int) -> void:
	if _last_locked_launch_province_id == active_locked_id:
		return
	if _last_locked_launch_province_id >= 0:
		_set_province_inner_glow_visible(_last_locked_launch_province_id, false)
	_last_locked_launch_province_id = active_locked_id


func _set_canvas_item_layer(item: CanvasItem, layer_value: int, relative: bool = false) -> void:
	if item == null:
		return
	item.z_as_relative = relative
	item.z_index = layer_value


func _make_empty_province_context(province_id: int = -1) -> Dictionary:
	var context: Dictionary = {
		"id": province_id,
		"type": LevelConfig.PROVINCE_TYPE_NEUTRAL,
		"remaining_troops": 0,
		"remaining_buildings": 0,
		"invading_troops": 0,
		"faction_id": 0,
		"construction_progress": 0,
		"is_target": false,
		"capture_source": CAPTURE_SOURCE_NONE,
		"neighbors": [],
		"is_boss_home": false,
		"caltrops": [],
		"active_caltrop_count": 0,
		"gold_production": 0,
		"free_buildings": 0,
		"building_capacity": LevelConfig.PROVINCE_BUILDING_CAP_MIN,
		"engagement_map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL,
		PROVINCE_NAME_KEY: ""
	}
	_copy_economy_fields_to_dictionary(context, context)
	return context


func _normalize_caltrop_entries(raw_entries) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if raw_entries is Array:
		for entry_any in raw_entries:
			if not (entry_any is Dictionary):
				continue
			var entry: Dictionary = entry_any
			var caltrop_id: int = int(entry.get("id", -1))
			if caltrop_id < 0:
				continue
			var seed: int = int(entry.get("seed", 0))
			if seed == 0:
				seed = caltrop_id + 1
			out.append({
				"id": caltrop_id,
				"seed": seed,
				"destroyed": bool(entry.get("destroyed", false)),
				"is_friendly": bool(entry.get("is_friendly", false))
			})
	return out


func _make_province_variation_rng(province_id: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var map_seed: int = 1
	if _main != null:
		map_seed = maxi(1, int(_main.map_seed))
	var mixed: int = int(hash("%d|province_variation|%d|%d" % [map_seed, province_id, LevelConfig.GRAND_MAP_PROVINCE_VARIATION]))
	mixed = mixed & 0x7fffffff
	if mixed == 0:
		mixed = (province_id + 1) * 15485863
	rng.seed = mixed
	return rng


static func get_province_tuning_value(key: String) -> float:
	var stable_value: float = float(PROVINCE_TUNING.get(key, 0.0))
	var master: float = clampf(float(PROVINCE_TUNING.get("master_dynamic_pace", 0.0)), 0.0, 1.0)
	var dynamic_value: float = float(PROVINCE_DYNAMIC_TUNING.get(key, stable_value))
	return lerpf(stable_value, dynamic_value, master)


static func get_province_tuning_int(key: String) -> int:
	return maxi(0, int(round(get_province_tuning_value(key))))


static func get_province_tuning_profile() -> Dictionary:
	var profile: Dictionary = {}
	for key in PROVINCE_TUNING.keys():
		profile[key] = get_province_tuning_value(String(key))
	return profile


func _roll_province_variation(province_id: int) -> Dictionary:
	var rng: RandomNumberGenerator = _make_province_variation_rng(province_id)
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


func normalize_province_variation_state(province_id: int, province_state: Dictionary) -> Dictionary:
	var rolled: Dictionary = _roll_province_variation(province_id)
	province_state[PROVINCE_GOLD_PRODUCTION_KEY] = LevelConfig.clamp_province_gold_production(int(province_state.get(PROVINCE_GOLD_PRODUCTION_KEY, rolled.get(PROVINCE_GOLD_PRODUCTION_KEY, 0))))
	province_state[PROVINCE_FREE_BUILDINGS_KEY] = LevelConfig.clamp_province_free_buildings(int(province_state.get(PROVINCE_FREE_BUILDINGS_KEY, rolled.get(PROVINCE_FREE_BUILDINGS_KEY, 0))))
	province_state[PROVINCE_BUILDING_CAPACITY_KEY] = LevelConfig.clamp_province_building_cap(int(province_state.get(PROVINCE_BUILDING_CAPACITY_KEY, rolled.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN))))
	province_state[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = LevelConfig.normalize_engagement_map_type(String(province_state.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, rolled.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL))))
	return province_state


func get_province_gold_production(province_state: Dictionary) -> int:
	return 0


func get_province_economy_income(province_state: Dictionary) -> int:
	normalize_province_economy_state(province_state)
	var rates: Dictionary = province_state.get(PROVINCE_RATES_KEY, {})
	return maxi(0, int(floor(float(rates.get("income", 0.0)))))


func get_province_total_income(province_state: Dictionary) -> int:
	return get_province_economy_income(province_state)


func get_province_free_buildings(province_state: Dictionary) -> int:
	return 0


func get_province_building_capacity(province_state: Dictionary) -> int:
	return LevelConfig.clamp_province_building_cap(int(province_state.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN)))


func get_province_engagement_map_type(province_state: Dictionary) -> String:
	return LevelConfig.normalize_engagement_map_type(String(province_state.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)))


func get_province_map_type_info_text(province_state: Dictionary) -> String:
	match get_province_engagement_map_type(province_state):
		LevelConfig.ENGAGEMENT_MAP_TYPE_JUNGLE:
			return "Jungle"
		LevelConfig.ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING:
			return "Rock Outcrop"
		LevelConfig.ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return "Settlement"
		_:
			return "Normal"


func create_default_province_economy_state(province_type: String = LevelConfig.PROVINCE_TYPE_NEUTRAL) -> Dictionary:
	var population_multiplier: float = 1.0
	if province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		population_multiplier = get_province_tuning_value("enemy_starting_population_multiplier")
	elif province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		population_multiplier = get_province_tuning_value("friendly_starting_population_multiplier")
	return {
		PROVINCE_ECONOMY_VERSION_KEY: PROVINCE_ECONOMY_SCHEMA_VERSION,
		PROVINCE_POPULATION_KEY: {
			POPULATION_NATIVES_KEY: get_province_tuning_value("default_native_population") * population_multiplier,
			POPULATION_OUTLANDER_KEY: get_province_tuning_value("default_outlander_population") * population_multiplier
		},
		PROVINCE_HAPPINESS_KEY: {
			POPULATION_NATIVES_KEY: get_province_tuning_value("default_happiness"),
			POPULATION_OUTLANDER_KEY: get_province_tuning_value("default_happiness")
		},
		PROVINCE_FOOD_KEY: {
			"production": 0.0,
			"demand": 0.0,
			"surplus": 0.0
		},
		PROVINCE_RATES_KEY: {
			"growth_factor": get_province_tuning_value("base_growth_factor"),
			"recruitment": get_province_tuning_value("base_recruitment_rate"),
			"construction": get_province_tuning_value("base_construction_rate"),
			"income": get_province_tuning_value("base_income_rate")
		},
		PROVINCE_ACCOMMODATION_KEY: {
			ACCOMMODATION_NATIVE_CEILING_KEY: get_province_tuning_value("base_native_accommodation"),
			ACCOMMODATION_OUTLANDER_CEILING_KEY: get_province_tuning_value("base_outlander_accommodation")
		},
		PROVINCE_BUILDINGS_KEY: {},
		PROVINCE_ACTIVE_CONSTRUCTION_KEY: {},
		PROVINCE_CONSTRUCTION_QUEUE_KEY: [],
		PROVINCE_STATUS_KEY: {
			"recently_conquered_ticks": 0,
			"revolt_warning": false
		}
	}


func _normalize_population_block(raw_population: Variant, defaults: Dictionary) -> Dictionary:
	var raw: Dictionary = raw_population if raw_population is Dictionary else {}
	var default_population: Dictionary = defaults.get(PROVINCE_POPULATION_KEY, {})
	return _clamp_population_block({
		POPULATION_NATIVES_KEY: maxf(0.0, float(raw.get(POPULATION_NATIVES_KEY, default_population.get(POPULATION_NATIVES_KEY, 0.0)))),
		POPULATION_OUTLANDER_KEY: maxf(0.0, float(raw.get(POPULATION_OUTLANDER_KEY, default_population.get(POPULATION_OUTLANDER_KEY, 0.0))))
	})


static func _clamp_population_block(population: Dictionary) -> Dictionary:
	population[POPULATION_NATIVES_KEY] = maxf(0.0, float(population.get(POPULATION_NATIVES_KEY, 0.0)))
	population[POPULATION_OUTLANDER_KEY] = maxf(0.0, float(population.get(POPULATION_OUTLANDER_KEY, 0.0)))
	return population


func _normalize_happiness_block(raw_happiness: Variant, defaults: Dictionary) -> Dictionary:
	var raw: Dictionary = raw_happiness if raw_happiness is Dictionary else {}
	var default_happiness: Dictionary = defaults.get(PROVINCE_HAPPINESS_KEY, {})
	return {
		POPULATION_NATIVES_KEY: clampf(float(raw.get(POPULATION_NATIVES_KEY, default_happiness.get(POPULATION_NATIVES_KEY, get_province_tuning_value("default_happiness")))), 0.0, 100.0),
		POPULATION_OUTLANDER_KEY: clampf(float(raw.get(POPULATION_OUTLANDER_KEY, default_happiness.get(POPULATION_OUTLANDER_KEY, get_province_tuning_value("default_happiness")))), 0.0, 100.0)
	}


func _normalize_number_block(raw_block: Variant, defaults: Dictionary, block_key: String) -> Dictionary:
	var raw: Dictionary = raw_block if raw_block is Dictionary else {}
	var default_block: Dictionary = defaults.get(block_key, {})
	var out: Dictionary = {}
	for key in default_block.keys():
		out[key] = float(raw.get(key, default_block[key]))
	return out


func _normalize_building_tier_counts(raw_tiers: Variant) -> Dictionary:
	var raw: Dictionary = raw_tiers if raw_tiers is Dictionary else {}
	return {
		"1": maxi(0, int(raw.get("1", raw.get(1, 0)))),
		"2": maxi(0, int(raw.get("2", raw.get(2, 0)))),
		"3": maxi(0, int(raw.get("3", raw.get(3, 0))))
	}


func normalize_typed_buildings(raw_buildings: Variant) -> Dictionary:
	var raw: Dictionary = raw_buildings if raw_buildings is Dictionary else {}
	var out: Dictionary = {}
	for legacy_id in LEGACY_BUILDING_ID_ALIASES.keys():
		if not raw.has(legacy_id):
			continue
		var canonical_id: String = String(LEGACY_BUILDING_ID_ALIASES.get(legacy_id, legacy_id))
		var merged_tiers: Dictionary = _normalize_building_tier_counts(raw.get(canonical_id, {}))
		var legacy_tiers: Dictionary = _normalize_building_tier_counts(raw.get(legacy_id, {}))
		for tier_key in legacy_tiers.keys():
			merged_tiers[tier_key] = int(merged_tiers.get(tier_key, 0)) + int(legacy_tiers.get(tier_key, 0))
		raw[canonical_id] = merged_tiers
	for building_id in BUILDING_CATALOG.keys():
		var tiers: Dictionary = _normalize_building_tier_counts(raw.get(building_id, {}))
		var definition: Dictionary = BUILDING_CATALOG[building_id]
		if bool(definition.get("unique_per_province", false)):
			var kept: bool = false
			for tier in ["3", "2", "1"]:
				var count: int = int(tiers.get(tier, 0))
				tiers[tier] = 1 if count > 0 and not kept else 0
				if int(tiers[tier]) > 0:
					kept = true
		out[building_id] = tiers
	return out


func _merge_default_starting_buildings(raw_buildings: Variant) -> Dictionary:
	var out: Dictionary = normalize_typed_buildings(raw_buildings)
	for building_type in DEFAULT_PROVINCE_STARTING_BUILDINGS.keys():
		var starting_tiers: Dictionary = DEFAULT_PROVINCE_STARTING_BUILDINGS.get(building_type, {})
		var tiers: Dictionary = out.get(building_type, _normalize_building_tier_counts({}))
		for tier_key in starting_tiers.keys():
			tiers[str(tier_key)] = maxi(int(tiers.get(str(tier_key), 0)), int(starting_tiers.get(tier_key, 0)))
		out[building_type] = tiers
	return out


func normalize_active_construction(raw_project: Variant) -> Dictionary:
	var raw: Dictionary = raw_project if raw_project is Dictionary else {}
	if raw.is_empty():
		return {}
	var project_type: String = String(raw.get("project_type", "")).strip_edges()
	var building_type: String = get_canonical_building_type(String(raw.get("building_type", "")).strip_edges())
	if not [CONSTRUCTION_PROJECT_BUILD, CONSTRUCTION_PROJECT_UPGRADE, CONSTRUCTION_PROJECT_DEMOLISH, CONSTRUCTION_PROJECT_REPAIR, CONSTRUCTION_PROJECT_RECRUITMENT].has(project_type):
		return {}
	if project_type == CONSTRUCTION_PROJECT_RECRUITMENT:
		return {
			"project_type": project_type,
			"building_type": "",
			"target_tier": 1,
			"progress": maxf(0.0, float(raw.get("progress", 0.0))),
			"required_progress": 1.0
		}
	if project_type != CONSTRUCTION_PROJECT_REPAIR and not BUILDING_CATALOG.has(building_type):
		return {}
	if project_type == CONSTRUCTION_PROJECT_REPAIR and not BUILDING_CATALOG.has(building_type):
		building_type = BUILDING_DEFENSE_NEST
	var building_definition: Dictionary = BUILDING_CATALOG.get(building_type, {})
	var max_tier: int = int(building_definition.get("max_tier", 3))
	var target_tier: int = clampi(int(raw.get("target_tier", 1)), 1, max_tier)
	var default_required: float = get_province_tuning_value("repair_progress_required") if project_type == CONSTRUCTION_PROJECT_REPAIR else get_building_progress_required(building_type, target_tier)
	if project_type == CONSTRUCTION_PROJECT_DEMOLISH:
		default_required *= 0.5
	var required_progress: float = maxf(1.0, float(raw.get("required_progress", default_required)))
	return {
		"project_type": project_type,
		"building_type": building_type,
		"target_tier": target_tier,
		"progress": clampf(float(raw.get("progress", 0.0)), 0.0, required_progress),
		"required_progress": required_progress
	}


func normalize_construction_queue(raw_queue: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if not (raw_queue is Array):
		return normalized
	for item_any in raw_queue:
		if normalized.size() >= PROVINCE_BUILD_QUEUE_LIMIT:
			break
		if not (item_any is Dictionary):
			continue
		var item: Dictionary = item_any
		var request_type: String = String(item.get("request_type", item.get("project_type", CONSTRUCTION_PROJECT_BUILD)))
		if not [CONSTRUCTION_PROJECT_BUILD, CONSTRUCTION_PROJECT_UPGRADE, CONSTRUCTION_PROJECT_DEMOLISH, CONSTRUCTION_PROJECT_REPAIR].has(request_type):
			continue
		var building_type: String = get_canonical_building_type(String(item.get("building_type", "")))
		if request_type == CONSTRUCTION_PROJECT_REPAIR and not BUILDING_CATALOG.has(building_type):
			building_type = BUILDING_DEFENSE_NEST
		if request_type != CONSTRUCTION_PROJECT_REPAIR and not BUILDING_CATALOG.has(building_type):
			continue
		var tier: int = 1
		if request_type == CONSTRUCTION_PROJECT_UPGRADE:
			tier = maxi(1, int(item.get("tier", item.get("target_tier", 2))) - (1 if item.has("target_tier") and not item.has("tier") else 0))
		elif request_type == CONSTRUCTION_PROJECT_DEMOLISH:
			tier = maxi(1, int(item.get("tier", item.get("target_tier", 1))))
		normalized.append({
			"request_type": request_type,
			"building_type": building_type,
			"tier": tier
		})
	return normalized


func normalize_province_status(raw_status: Variant, defaults: Dictionary) -> Dictionary:
	var raw: Dictionary = raw_status if raw_status is Dictionary else {}
	var default_status: Dictionary = defaults.get(PROVINCE_STATUS_KEY, {})
	return {
		"recently_conquered_ticks": maxi(0, int(raw.get("recently_conquered_ticks", default_status.get("recently_conquered_ticks", 0)))),
		"revolt_warning": bool(raw.get("revolt_warning", default_status.get("revolt_warning", false)))
	}


func normalize_province_economy_state(province_state: Dictionary) -> Dictionary:
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var defaults: Dictionary = create_default_province_economy_state(province_type)
	var previous_schema_version: int = int(province_state.get(PROVINCE_ECONOMY_VERSION_KEY, 0))
	var should_seed_starting_buildings: bool = int(province_state.get("id", -1)) >= 0 and previous_schema_version < PROVINCE_ECONOMY_SCHEMA_VERSION
	province_state[PROVINCE_ECONOMY_VERSION_KEY] = PROVINCE_ECONOMY_SCHEMA_VERSION
	province_state[PROVINCE_POPULATION_KEY] = _normalize_population_block(province_state.get(PROVINCE_POPULATION_KEY, {}), defaults)
	province_state[PROVINCE_HAPPINESS_KEY] = _normalize_happiness_block(province_state.get(PROVINCE_HAPPINESS_KEY, {}), defaults)
	province_state[PROVINCE_FOOD_KEY] = _normalize_number_block(province_state.get(PROVINCE_FOOD_KEY, {}), defaults, PROVINCE_FOOD_KEY)
	province_state[PROVINCE_RATES_KEY] = _normalize_number_block(province_state.get(PROVINCE_RATES_KEY, {}), defaults, PROVINCE_RATES_KEY)
	province_state[PROVINCE_ACCOMMODATION_KEY] = _normalize_number_block(province_state.get(PROVINCE_ACCOMMODATION_KEY, {}), defaults, PROVINCE_ACCOMMODATION_KEY)
	if should_seed_starting_buildings:
		province_state[PROVINCE_BUILDINGS_KEY] = _merge_default_starting_buildings(province_state.get(PROVINCE_BUILDINGS_KEY, {}))
	else:
		province_state[PROVINCE_BUILDINGS_KEY] = normalize_typed_buildings(province_state.get(PROVINCE_BUILDINGS_KEY, {}))
	province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = normalize_active_construction(province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}))
	province_state[PROVINCE_CONSTRUCTION_QUEUE_KEY] = normalize_construction_queue(province_state.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []))
	province_state[PROVINCE_STATUS_KEY] = normalize_province_status(province_state.get(PROVINCE_STATUS_KEY, {}), defaults)
	recalculate_province_derived_economy(province_state)
	sync_legacy_building_count_from_typed(province_state)
	return province_state


func _copy_economy_fields_to_dictionary(source: Dictionary, target: Dictionary) -> void:
	normalize_province_economy_state(source)
	target[PROVINCE_ECONOMY_VERSION_KEY] = int(source.get(PROVINCE_ECONOMY_VERSION_KEY, PROVINCE_ECONOMY_SCHEMA_VERSION))
	target[PROVINCE_POPULATION_KEY] = source.get(PROVINCE_POPULATION_KEY, {}).duplicate(true)
	target[PROVINCE_HAPPINESS_KEY] = source.get(PROVINCE_HAPPINESS_KEY, {}).duplicate(true)
	target[PROVINCE_FOOD_KEY] = source.get(PROVINCE_FOOD_KEY, {}).duplicate(true)
	target[PROVINCE_RATES_KEY] = source.get(PROVINCE_RATES_KEY, {}).duplicate(true)
	target[PROVINCE_ACCOMMODATION_KEY] = source.get(PROVINCE_ACCOMMODATION_KEY, {}).duplicate(true)
	target[PROVINCE_BUILDINGS_KEY] = source.get(PROVINCE_BUILDINGS_KEY, {}).duplicate(true)
	target[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = source.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).duplicate(true)
	target[PROVINCE_CONSTRUCTION_QUEUE_KEY] = source.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []).duplicate(true)
	target[PROVINCE_STATUS_KEY] = source.get(PROVINCE_STATUS_KEY, {}).duplicate(true)


func get_building_definition(building_type: String) -> Dictionary:
	return BUILDING_CATALOG.get(get_canonical_building_type(building_type), {})


func get_canonical_building_type(building_type: String) -> String:
	var clean_type: String = String(building_type).strip_edges()
	if LEGACY_BUILDING_ID_ALIASES.has(clean_type):
		return String(LEGACY_BUILDING_ID_ALIASES.get(clean_type, clean_type))
	return clean_type


func get_building_sprite_path(building_type: String) -> String:
	return String(BUILDING_SPRITE_PATHS.get(get_canonical_building_type(building_type), ""))


func get_building_visual_types(province_state: Dictionary) -> Array[String]:
	normalize_province_economy_state(province_state)
	var result: Array[String] = []
	for entry in get_building_visual_entries(province_state):
		result.append(String(entry.get("building_type", "")))
	return result


func get_building_visual_entries(province_state: Dictionary) -> Array[Dictionary]:
	normalize_province_economy_state(province_state)
	var result: Array[Dictionary] = []
	var buildings: Dictionary = province_state.get(PROVINCE_BUILDINGS_KEY, {})
	for building_type in BUILDING_CATALOG.keys():
		var tiers: Dictionary = buildings.get(building_type, {})
		for tier_key in ["3", "2", "1"]:
			for _i in range(maxi(0, int(tiers.get(tier_key, 0)))):
				result.append({
					"building_type": String(building_type),
					"tier": int(tier_key)
				})
	return result


func get_building_progress_required(building_type: String, tier: int) -> float:
	var definition: Dictionary = get_building_definition(building_type)
	var base_required: float = float(definition.get("base_build_progress_required", 100.0))
	var multiplier_key: String = "building_build_progress_required_multiplier" if tier <= 1 else "building_upgrade_progress_required_multiplier"
	return maxf(1.0, base_required * maxf(1.0, float(tier)) * get_province_tuning_value(multiplier_key))


func get_typed_building_count(province_state: Dictionary, building_type: String, tier: int = 0) -> int:
	normalize_province_economy_state(province_state)
	building_type = get_canonical_building_type(building_type)
	var buildings: Dictionary = province_state.get(PROVINCE_BUILDINGS_KEY, {})
	var tiers: Dictionary = buildings.get(building_type, {})
	if tier > 0:
		return maxi(0, int(tiers.get(str(tier), 0)))
	var total: int = 0
	for tier_key in tiers.keys():
		total += maxi(0, int(tiers.get(tier_key, 0)))
	return total


func calculate_occupied_building_slots(province_state: Dictionary) -> int:
	normalize_province_economy_state(province_state)
	return _calculate_occupied_building_slots_without_normalize(province_state)


func _calculate_occupied_building_slots_without_normalize(province_state: Dictionary) -> int:
	var occupied: int = 0
	var buildings: Dictionary = province_state.get(PROVINCE_BUILDINGS_KEY, {})
	for building_type in buildings.keys():
		var tiers: Dictionary = buildings.get(building_type, {})
		for tier_key in tiers.keys():
			occupied += maxi(0, int(tiers.get(tier_key, 0)))
	return occupied


func calculate_remaining_building_slots(province_state: Dictionary) -> int:
	return maxi(0, get_province_building_capacity(province_state) - calculate_occupied_building_slots(province_state))


func sync_legacy_building_count_from_typed(province_state: Dictionary) -> int:
	var occupied: int = _calculate_occupied_building_slots_without_normalize(province_state)
	province_state["remaining_buildings"] = occupied
	return occupied


func province_has_command_center(province_state: Dictionary) -> bool:
	return get_home_cave_tier(province_state) >= 1


func get_home_cave_tier(province_state: Dictionary) -> int:
	var highest_tier: int = 0
	for tier in range(1, int(BUILDING_CATALOG[BUILDING_HOME_CAVE].get("max_tier", 3)) + 1):
		if get_typed_building_count(province_state, BUILDING_HOME_CAVE, tier) > 0:
			highest_tier = tier
	return highest_tier


func can_player_control_construction_in_province(province_id: int) -> bool:
	if _main == null or province_id < 0:
		return false
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return false
	var province_state: Dictionary = _main._province_persistence[index]
	return get_relation_to_player_for_province_state(province_state) == RELATION_SELF


func get_building_display_name(building_type: String) -> String:
	building_type = get_canonical_building_type(building_type)
	var definition: Dictionary = BUILDING_CATALOG.get(building_type, {})
	return String(definition.get("display_name", building_type.capitalize()))


func can_add_typed_building(province_state: Dictionary, building_type: String, tier: int = 1) -> bool:
	building_type = get_canonical_building_type(building_type)
	if not BUILDING_CATALOG.has(building_type):
		return false
	var definition: Dictionary = BUILDING_CATALOG[building_type]
	if tier < 1 or tier > int(definition.get("max_tier", 3)):
		return false
	if calculate_remaining_building_slots(province_state) <= 0:
		return false
	if bool(definition.get("unique_per_province", false)) and get_typed_building_count(province_state, building_type) > 0:
		return false
	return true


func add_typed_building(province_state: Dictionary, building_type: String, tier: int = 1) -> bool:
	building_type = get_canonical_building_type(building_type)
	if not can_add_typed_building(province_state, building_type, tier):
		return false
	normalize_province_economy_state(province_state)
	var buildings: Dictionary = province_state[PROVINCE_BUILDINGS_KEY]
	var tiers: Dictionary = buildings.get(building_type, _normalize_building_tier_counts({}))
	var tier_key: String = str(tier)
	tiers[tier_key] = maxi(0, int(tiers.get(tier_key, 0))) + 1
	buildings[building_type] = tiers
	province_state[PROVINCE_BUILDINGS_KEY] = buildings
	recalculate_province_derived_economy(province_state)
	sync_legacy_building_count_from_typed(province_state)
	return true


func remove_typed_building(province_state: Dictionary, building_type: String, tier: int = 0) -> bool:
	building_type = get_canonical_building_type(building_type)
	normalize_province_economy_state(province_state)
	var buildings: Dictionary = province_state[PROVINCE_BUILDINGS_KEY]
	var tiers: Dictionary = buildings.get(building_type, {})
	if tiers.is_empty():
		return false
	var tier_order: Array = [str(tier)] if tier > 0 else ["1", "2", "3"]
	for tier_key in tier_order:
		var count: int = maxi(0, int(tiers.get(tier_key, 0)))
		if count <= 0:
			continue
		tiers[tier_key] = count - 1
		buildings[building_type] = tiers
		province_state[PROVINCE_BUILDINGS_KEY] = buildings
		recalculate_province_derived_economy(province_state)
		sync_legacy_building_count_from_typed(province_state)
		return true
	return false


func upgrade_typed_building(province_state: Dictionary, building_type: String, from_tier: int = 1) -> bool:
	building_type = get_canonical_building_type(building_type)
	if not BUILDING_CATALOG.has(building_type):
		return false
	var definition: Dictionary = BUILDING_CATALOG[building_type]
	var target_tier: int = from_tier + 1
	if from_tier < 1 or target_tier > int(definition.get("max_tier", 3)):
		return false
	normalize_province_economy_state(province_state)
	var buildings: Dictionary = province_state[PROVINCE_BUILDINGS_KEY]
	var tiers: Dictionary = buildings.get(building_type, {})
	var from_key: String = str(from_tier)
	var target_key: String = str(target_tier)
	if int(tiers.get(from_key, 0)) <= 0:
		return false
	tiers[from_key] = int(tiers.get(from_key, 0)) - 1
	tiers[target_key] = int(tiers.get(target_key, 0)) + 1
	buildings[building_type] = tiers
	province_state[PROVINCE_BUILDINGS_KEY] = buildings
	recalculate_province_derived_economy(province_state)
	sync_legacy_building_count_from_typed(province_state)
	return true


func damage_typed_buildings(province_state: Dictionary, max_damage: int) -> int:
	normalize_province_economy_state(province_state)
	var remaining_damage: int = maxi(0, max_damage)
	var applied: int = 0
	while remaining_damage > 0:
		var changed: bool = false
		for tier in [3, 2, 1]:
			for building_type in BUILDING_CATALOG.keys():
				if get_typed_building_count(province_state, building_type, tier) <= 0:
					continue
				var buildings: Dictionary = province_state[PROVINCE_BUILDINGS_KEY]
				var tiers: Dictionary = buildings[building_type]
				if tier > 1:
					tiers[str(tier)] = int(tiers.get(str(tier), 0)) - 1
					tiers[str(tier - 1)] = int(tiers.get(str(tier - 1), 0)) + 1
				else:
					tiers[str(tier)] = maxi(0, int(tiers.get(str(tier), 0)) - 1)
				buildings[building_type] = tiers
				province_state[PROVINCE_BUILDINGS_KEY] = buildings
				applied += 1
				remaining_damage -= 1
				changed = true
				break
			if changed:
				break
		if not changed:
			break
	recalculate_province_derived_economy(province_state)
	sync_legacy_building_count_from_typed(province_state)
	return applied


func set_typed_building_count_ceiling(province_state: Dictionary, target_count: int) -> int:
	normalize_province_economy_state(province_state)
	var desired: int = maxi(0, target_count)
	var current: int = _calculate_occupied_building_slots_without_normalize(province_state)
	while current > desired:
		var removed: bool = false
		for tier in [1, 2, 3]:
			for building_type in BUILDING_CATALOG.keys():
				var buildings: Dictionary = province_state.get(PROVINCE_BUILDINGS_KEY, {})
				var tiers: Dictionary = buildings.get(building_type, {})
				var tier_key: String = str(tier)
				if int(tiers.get(tier_key, 0)) <= 0:
					continue
				tiers[tier_key] = int(tiers.get(tier_key, 0)) - 1
				buildings[building_type] = tiers
				province_state[PROVINCE_BUILDINGS_KEY] = buildings
				removed = true
				break
			if removed:
				break
		if not removed:
			break
		current = _calculate_occupied_building_slots_without_normalize(province_state)
	recalculate_province_derived_economy(province_state)
	sync_legacy_building_count_from_typed(province_state)
	return int(province_state.get("remaining_buildings", 0))


func get_captured_building_survivor_count(province_state: Dictionary) -> int:
	normalize_province_economy_state(province_state)
	var current: int = _calculate_occupied_building_slots_without_normalize(province_state)
	return maxi(0, current - int(floor(float(current) * 0.5)))


func reset_rebel_province_buildings(province_state: Dictionary) -> void:
	province_state[PROVINCE_BUILDINGS_KEY] = normalize_typed_buildings({
		BUILDING_FARM: {"1": 1},
		BUILDING_MANSION: {"1": 1},
		BUILDING_TENEMENT: {"1": 1}
	})
	recalculate_province_derived_economy(province_state)
	sync_legacy_building_count_from_typed(province_state)


func clear_typed_buildings(province_state: Dictionary) -> void:
	province_state[PROVINCE_BUILDINGS_KEY] = normalize_typed_buildings({})
	recalculate_province_derived_economy(province_state)
	sync_legacy_building_count_from_typed(province_state)


func repair_typed_building(province_state: Dictionary) -> bool:
	normalize_province_economy_state(province_state)
	for tier in [1, 2]:
		for building_type in BUILDING_CATALOG.keys():
			if get_typed_building_count(province_state, building_type, tier) <= 0:
				continue
			if upgrade_typed_building(province_state, building_type, tier):
				sync_legacy_building_count_from_typed(province_state)
				return true
	return false


func calculate_building_effects(province_state: Dictionary) -> Dictionary:
	var effects: Dictionary = {
		"food_production": 0.0,
		"native_accommodation": 0.0,
		"outlander_accommodation": 0.0,
		"native_taper_cap": 0.0,
		"outlander_taper_cap": 0.0,
		"growth_factor": 0.0,
		"recruitment": 0.0,
		"construction": 0.0,
		"income": 0.0,
		"defense_strength": 0.0,
		"adjacent_damage": 0.0,
		"command_center": false
	}
	var buildings: Dictionary = province_state.get(PROVINCE_BUILDINGS_KEY, {})
	for building_type in buildings.keys():
		var definition: Dictionary = BUILDING_CATALOG.get(building_type, {})
		var tier_effects: Dictionary = definition.get("tier_effects", {})
		var tiers: Dictionary = buildings.get(building_type, {})
		for tier_key in tiers.keys():
			var count: int = maxi(0, int(tiers.get(tier_key, 0)))
			if count <= 0:
				continue
			var effect: Dictionary = tier_effects.get(str(tier_key), {})
			for effect_key in effect.keys():
				if effect_key == "command_center":
					effects["command_center"] = bool(effects["command_center"]) or bool(effect.get(effect_key, false))
				else:
					var multiplier_key: String = "building_%s_multiplier" % String(effect_key)
					effects[effect_key] = float(effects.get(effect_key, 0.0)) + float(effect.get(effect_key, 0.0)) * float(count) * get_province_tuning_value(multiplier_key)
	return effects


func _get_total_typed_building_count_without_normalize(province_state: Dictionary, building_type: String) -> int:
	var buildings: Dictionary = province_state.get(PROVINCE_BUILDINGS_KEY, {})
	var tiers: Dictionary = buildings.get(get_canonical_building_type(building_type), {})
	var total: int = 0
	for tier_key in tiers.keys():
		total += maxi(0, int(tiers.get(tier_key, 0)))
	return total


func get_population_taper_caps(province_state: Dictionary) -> Dictionary:
	var tenement_count: int = _get_total_typed_building_count_without_normalize(province_state, BUILDING_TENEMENT)
	var mansion_count: int = _get_total_typed_building_count_without_normalize(province_state, BUILDING_MANSION)
	return {
		POPULATION_NATIVES_KEY: NATIVE_GROWTH_TAPER_BASE_CAP + float(tenement_count) * NATIVE_GROWTH_TAPER_CAP_PER_TENEMENT,
		POPULATION_OUTLANDER_KEY: OUTLANDER_GROWTH_TAPER_BASE_CAP + float(mansion_count) * OUTLANDER_GROWTH_TAPER_CAP_PER_MANSION
	}


func _clamp_population_to_taper_caps(province_state: Dictionary) -> Dictionary:
	var population: Dictionary = _clamp_population_block(province_state.get(PROVINCE_POPULATION_KEY, {}))
	var taper_caps: Dictionary = get_population_taper_caps(province_state)
	population[POPULATION_NATIVES_KEY] = minf(float(population.get(POPULATION_NATIVES_KEY, 0.0)), maxf(0.0, float(taper_caps.get(POPULATION_NATIVES_KEY, NATIVE_GROWTH_TAPER_BASE_CAP))))
	population[POPULATION_OUTLANDER_KEY] = minf(float(population.get(POPULATION_OUTLANDER_KEY, 0.0)), maxf(0.0, float(taper_caps.get(POPULATION_OUTLANDER_KEY, OUTLANDER_GROWTH_TAPER_BASE_CAP))))
	province_state[PROVINCE_POPULATION_KEY] = population
	return population


func get_province_defense_strength(province_state: Dictionary) -> int:
	normalize_province_economy_state(province_state)
	var effects: Dictionary = calculate_building_effects(province_state)
	return maxi(0, int(floor(float(effects.get("defense_strength", 0.0)))))


func get_province_catapult_adjacent_damage(province_state: Dictionary) -> int:
	normalize_province_economy_state(province_state)
	var effects: Dictionary = calculate_building_effects(province_state)
	return maxi(0, int(floor(float(effects.get("adjacent_damage", 0.0)) * get_province_tuning_value("catapult_adjacent_damage_multiplier"))))


func recalculate_accommodation(province_state: Dictionary, building_effects: Dictionary = {}) -> Dictionary:
	if building_effects.is_empty():
		building_effects = calculate_building_effects(province_state)
	var accommodation: Dictionary = {
		ACCOMMODATION_NATIVE_CEILING_KEY: get_province_tuning_value("base_native_accommodation") + float(building_effects.get("native_accommodation", 0.0)),
		ACCOMMODATION_OUTLANDER_CEILING_KEY: get_province_tuning_value("base_outlander_accommodation") + float(building_effects.get("outlander_accommodation", 0.0))
	}
	province_state[PROVINCE_ACCOMMODATION_KEY] = accommodation
	return accommodation


func recalculate_food(province_state: Dictionary, building_effects: Dictionary = {}) -> Dictionary:
	if building_effects.is_empty():
		building_effects = calculate_building_effects(province_state)
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var natives: float = maxf(0.0, float(population.get(POPULATION_NATIVES_KEY, 0.0)))
	var outlanders: float = maxf(0.0, float(population.get(POPULATION_OUTLANDER_KEY, 0.0)))
	var resident_troops: float = maxf(0.0, float(province_state.get("remaining_troops", province_state.get("troops", 0))))
	var food: Dictionary = {
		"production": get_province_tuning_value("base_food_production") + float(building_effects.get("food_production", 0.0)),
		"demand": natives * get_province_tuning_value("native_food_demand") + outlanders * get_province_tuning_value("outlander_food_demand") + resident_troops * get_province_tuning_value("troop_food_demand"),
		"surplus": 0.0
	}
	food["surplus"] = float(food["production"]) - float(food["demand"])
	province_state[PROVINCE_FOOD_KEY] = food
	return food


func _get_happiness_multiplier(happiness_value: float) -> float:
	return clampf(happiness_value / 100.0, 0.0, 1.25)


func calculate_growth_factor(province_state: Dictionary, building_effects: Dictionary = {}) -> float:
	if building_effects.is_empty():
		building_effects = calculate_building_effects(province_state)
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var default_happiness: float = get_province_tuning_value("default_happiness")
	var average_happiness: float = (float(happiness.get(POPULATION_NATIVES_KEY, default_happiness)) + float(happiness.get(POPULATION_OUTLANDER_KEY, default_happiness))) * 0.5
	var food_modifier: float = clampf(float(food.get("surplus", 0.0)) * get_province_tuning_value("food_growth_modifier_per_point"), -0.6, 0.6)
	var happiness_modifier: float = ((average_happiness - default_happiness) / 100.0) * get_province_tuning_value("happiness_rate_effect_multiplier")
	return maxf(0.0, get_province_tuning_value("base_growth_factor") + float(building_effects.get("growth_factor", 0.0)) + food_modifier + happiness_modifier)


func calculate_construction_rate(province_state: Dictionary, building_effects: Dictionary = {}) -> float:
	if building_effects.is_empty():
		building_effects = calculate_building_effects(province_state)
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var natives: float = float(population.get(POPULATION_NATIVES_KEY, 0.0))
	var native_happiness: float = float(happiness.get(POPULATION_NATIVES_KEY, get_province_tuning_value("default_happiness")))
	var uncapped_rate: float = maxf(0.0, get_province_tuning_value("base_construction_rate") + float(building_effects.get("construction", 0.0)) + natives * get_province_tuning_value("native_construction_factor") * _get_happiness_multiplier(native_happiness))
	return uncapped_rate


func calculate_recruitment_rate(province_state: Dictionary, building_effects: Dictionary = {}) -> float:
	if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return 0.0
	if building_effects.is_empty():
		building_effects = calculate_building_effects(province_state)
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var natives: float = float(population.get(POPULATION_NATIVES_KEY, 0.0))
	var native_happiness: float = float(happiness.get(POPULATION_NATIVES_KEY, get_province_tuning_value("default_happiness")))
	var uncapped_rate: float = maxf(0.0, get_province_tuning_value("base_recruitment_rate") + float(building_effects.get("recruitment", 0.0)) + natives * get_province_tuning_value("native_recruitment_factor") * _get_happiness_multiplier(native_happiness))
	return uncapped_rate


func calculate_income_rate(province_state: Dictionary, building_effects: Dictionary = {}) -> float:
	if building_effects.is_empty():
		building_effects = calculate_building_effects(province_state)
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var outlanders: float = float(population.get(POPULATION_OUTLANDER_KEY, 0.0))
	var outlander_happiness: float = float(happiness.get(POPULATION_OUTLANDER_KEY, get_province_tuning_value("default_happiness")))
	return maxf(0.0, get_province_tuning_value("base_income_rate") + float(building_effects.get("income", 0.0)) + outlanders * get_province_tuning_value("outlander_income_factor") * _get_happiness_multiplier(outlander_happiness))


func recalculate_province_derived_economy(province_state: Dictionary) -> Dictionary:
	province_state[PROVINCE_POPULATION_KEY] = _clamp_population_block(province_state.get(PROVINCE_POPULATION_KEY, {}))
	var buildings: Dictionary = province_state.get(PROVINCE_BUILDINGS_KEY, {})
	if buildings.is_empty() or not buildings.has(BUILDING_FOOD_MAKER):
		province_state[PROVINCE_BUILDINGS_KEY] = normalize_typed_buildings(buildings)
	var building_effects: Dictionary = calculate_building_effects(province_state)
	_clamp_population_to_taper_caps(province_state)
	recalculate_accommodation(province_state, building_effects)
	recalculate_food(province_state, building_effects)
	var rates: Dictionary = province_state.get(PROVINCE_RATES_KEY, {})
	rates["growth_factor"] = calculate_growth_factor(province_state, building_effects)
	rates["recruitment"] = calculate_recruitment_rate(province_state, building_effects)
	rates["construction"] = calculate_construction_rate(province_state, building_effects)
	rates["income"] = calculate_income_rate(province_state, building_effects)
	province_state[PROVINCE_RATES_KEY] = rates
	return building_effects


func _apply_province_happiness_deltas(province_state: Dictionary) -> bool:
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var accommodation: Dictionary = province_state.get(PROVINCE_ACCOMMODATION_KEY, {})
	var food_surplus: float = float(food.get("surplus", 0.0))
	var food_delta: float = get_province_tuning_value("food_surplus_happiness_recovery") if food_surplus >= 0.0 else food_surplus * get_province_tuning_value("food_deficit_happiness_penalty_per_point")
	var native_overcrowding: float = maxf(0.0, float(population.get(POPULATION_NATIVES_KEY, 0.0)) - float(accommodation.get(ACCOMMODATION_NATIVE_CEILING_KEY, get_province_tuning_value("base_native_accommodation"))))
	var outlander_overcrowding: float = maxf(0.0, float(population.get(POPULATION_OUTLANDER_KEY, 0.0)) - float(accommodation.get(ACCOMMODATION_OUTLANDER_CEILING_KEY, get_province_tuning_value("base_outlander_accommodation"))))
	var default_happiness: float = get_province_tuning_value("default_happiness")
	var native_current: float = float(happiness.get(POPULATION_NATIVES_KEY, default_happiness))
	var outlander_current: float = float(happiness.get(POPULATION_OUTLANDER_KEY, default_happiness))
	var native_next: float = native_current + food_delta - native_overcrowding * get_province_tuning_value("overcrowding_happiness_penalty_per_person")
	var outlander_next: float = outlander_current + food_delta - outlander_overcrowding * get_province_tuning_value("overcrowding_happiness_penalty_per_person")
	if food_surplus >= 0.0:
		native_next += get_province_tuning_value("passive_happiness_recovery")
		outlander_next += get_province_tuning_value("passive_happiness_recovery")
	var revolt_threshold: float = get_province_tuning_value("revolt_happiness_threshold")
	var revolt_triggered: bool = native_current <= revolt_threshold or outlander_current <= revolt_threshold or native_next <= revolt_threshold or outlander_next <= revolt_threshold
	happiness[POPULATION_NATIVES_KEY] = clampf(native_next, 0.0, 100.0)
	happiness[POPULATION_OUTLANDER_KEY] = clampf(outlander_next, 0.0, 100.0)
	province_state[PROVINCE_HAPPINESS_KEY] = happiness
	var status: Dictionary = province_state.get(PROVINCE_STATUS_KEY, {})
	var warning_threshold: float = get_province_tuning_value("revolt_warning_happiness_threshold")
	status["revolt_warning"] = float(happiness.get(POPULATION_NATIVES_KEY, default_happiness)) <= warning_threshold or float(happiness.get(POPULATION_OUTLANDER_KEY, default_happiness)) <= warning_threshold
	province_state[PROVINCE_STATUS_KEY] = status
	return revolt_triggered


func _apply_food_shortage_population_loss(province_state: Dictionary) -> bool:
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	if float(food.get("surplus", 0.0)) >= 0.0:
		return false
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var natives: float = maxf(0.0, float(population.get(POPULATION_NATIVES_KEY, 0.0)))
	var outlanders: float = maxf(0.0, float(population.get(POPULATION_OUTLANDER_KEY, 0.0)))
	var native_food_demand: float = maxf(0.0, get_province_tuning_value("native_food_demand"))
	var outlander_food_demand: float = maxf(0.0, get_province_tuning_value("outlander_food_demand"))
	var troop_food_demand: float = maxf(0.0, get_province_tuning_value("troop_food_demand"))
	var troop_demand: float = maxf(0.0, float(province_state.get("remaining_troops", province_state.get("troops", 0)))) * troop_food_demand
	var current_population_demand: float = natives * native_food_demand + outlanders * outlander_food_demand
	if current_population_demand <= 0.0:
		return false
	var available_population_food: float = maxf(0.0, float(food.get("production", 0.0)) - troop_demand)
	var sustainable_ratio: float = clampf(available_population_food / current_population_demand, 0.0, 1.0)
	var target_natives: float = natives * sustainable_ratio
	var target_outlanders: float = outlanders * sustainable_ratio
	population[POPULATION_NATIVES_KEY] = (natives + target_natives) * 0.5
	population[POPULATION_OUTLANDER_KEY] = (outlanders + target_outlanders) * 0.5
	province_state[PROVINCE_POPULATION_KEY] = population
	_clamp_population_to_taper_caps(province_state)
	return true


func _apply_tapered_population_growth(current_population: float, growth_rate: float, growth_factor: float, food_growth_multiplier: float, happiness_multiplier: float, taper_cap: float) -> float:
	var current: float = maxf(0.0, current_population)
	var cap: float = maxf(0.0, taper_cap)
	if cap <= 0.0:
		return 0.0
	if current >= cap:
		return cap
	var taper_multiplier: float = clampf((cap - current) / cap, 0.0, 1.0)
	var growth_multiplier: float = maxf(0.0, growth_rate * growth_factor * food_growth_multiplier * happiness_multiplier * taper_multiplier)
	return minf(cap, current * (1.0 + growth_multiplier))


func _update_province_population(province_state: Dictionary) -> void:
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var rates: Dictionary = province_state.get(PROVINCE_RATES_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var growth_factor: float = float(rates.get("growth_factor", get_province_tuning_value("base_growth_factor")))
	var food_growth_multiplier: float = 1.0 if float(food.get("surplus", 0.0)) >= 0.0 else get_province_tuning_value("food_deficit_population_growth_multiplier")
	var default_happiness: float = get_province_tuning_value("default_happiness")
	var native_happiness_multiplier: float = _get_happiness_multiplier(float(happiness.get(POPULATION_NATIVES_KEY, default_happiness)))
	var outlander_happiness_multiplier: float = _get_happiness_multiplier(float(happiness.get(POPULATION_OUTLANDER_KEY, default_happiness)))
	var taper_caps: Dictionary = get_population_taper_caps(province_state)
	population[POPULATION_NATIVES_KEY] = _apply_tapered_population_growth(float(population.get(POPULATION_NATIVES_KEY, 0.0)), get_province_tuning_value("native_growth_rate"), growth_factor, food_growth_multiplier, native_happiness_multiplier, float(taper_caps.get(POPULATION_NATIVES_KEY, NATIVE_GROWTH_TAPER_BASE_CAP)))
	population[POPULATION_OUTLANDER_KEY] = _apply_tapered_population_growth(float(population.get(POPULATION_OUTLANDER_KEY, 0.0)), get_province_tuning_value("outlander_growth_rate"), growth_factor, food_growth_multiplier, outlander_happiness_multiplier, float(taper_caps.get(POPULATION_OUTLANDER_KEY, OUTLANDER_GROWTH_TAPER_BASE_CAP)))
	province_state[PROVINCE_POPULATION_KEY] = population


func _apply_recruitment_and_income(province_state: Dictionary) -> void:
	var rates: Dictionary = province_state.get(PROVINCE_RATES_KEY, {})
	var recruitment_gain: int = int(floor(float(rates.get("recruitment", 0.0))))
	if recruitment_gain > 0:
		province_state["remaining_troops"] = maxi(0, int(province_state.get("remaining_troops", 0))) + recruitment_gain
	var income_gain: int = int(floor(float(rates.get("income", 0.0))))
	if income_gain > 0:
		province_state["economy_income_pending"] = maxi(0, int(province_state.get("economy_income_pending", 0))) + income_gain


func _add_active_construction_progress(province_state: Dictionary, points: float) -> bool:
	if points <= 0.0:
		return false
	var project: Dictionary = normalize_active_construction(province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}))
	if project.is_empty():
		province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {}
		return false
	project["progress"] = float(project.get("progress", 0.0)) + points
	province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = project
	return true


func _advance_active_construction(province_state: Dictionary) -> void:
	var project: Dictionary = normalize_active_construction(province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}))
	if project.is_empty():
		province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {}
		return
	var rates: Dictionary = province_state.get(PROVINCE_RATES_KEY, {})
	var construction_points: float = float(project.get("progress", 0.0)) + float(rates.get("construction", 0.0))
	if String(project.get("project_type", "")) == CONSTRUCTION_PROJECT_RECRUITMENT:
		var recruitment_gain: int = int(floor(construction_points * CONSTRUCTION_RECRUITMENT_CONVERSION_RATE))
		if recruitment_gain > 0:
			province_state["remaining_troops"] = maxi(0, int(province_state.get("remaining_troops", 0))) + recruitment_gain
		province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {}
		return
	project["progress"] = construction_points
	if float(project.get("progress", 0.0)) < float(project.get("required_progress", 1.0)):
		province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = project
		return
	var project_type: String = String(project.get("project_type", ""))
	var building_type: String = String(project.get("building_type", ""))
	var target_tier: int = int(project.get("target_tier", 1))
	if project_type == CONSTRUCTION_PROJECT_BUILD:
		add_typed_building(province_state, building_type, target_tier)
	elif project_type == CONSTRUCTION_PROJECT_UPGRADE:
		upgrade_typed_building(province_state, building_type, target_tier - 1)
	elif project_type == CONSTRUCTION_PROJECT_DEMOLISH:
		remove_typed_building(province_state, building_type, target_tier)
	elif project_type == CONSTRUCTION_PROJECT_REPAIR:
		repair_typed_building(province_state)
	sync_legacy_building_count_from_typed(province_state)
	province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {}


func _apply_catapult_adjacent_damage(province_state: Dictionary) -> int:
	if _main == null:
		return 0
	var damage: int = get_province_catapult_adjacent_damage(province_state)
	if damage <= 0:
		return 0
	var source_relation: String = get_relation_to_player_for_province_state(province_state)
	var applied: int = 0
	for neighbor_id in normalize_neighbor_ids(province_state.get("neighbors", [])):
		var neighbor_index: int = find_persistence_index_by_id(int(neighbor_id))
		if neighbor_index == -1:
			continue
		var neighbor_state: Dictionary = _main._province_persistence[neighbor_index]
		if get_relation_to_player_for_province_state(neighbor_state) == source_relation:
			continue
		var before_troops: int = maxi(0, int(neighbor_state.get("remaining_troops", 0)))
		if before_troops <= 0:
			continue
		var dealt: int = mini(damage, before_troops)
		neighbor_state["remaining_troops"] = before_troops - dealt
		applied += dealt
	return applied


func ensure_defense_nest_caltrops(province_id: int) -> int:
	if _main == null or province_id < 0:
		return 0
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return 0
	var province_state: Dictionary = _main._province_persistence[index]
	var defense_strength: int = get_province_defense_strength(province_state)
	if defense_strength <= 0:
		return 0
	var active_count: int = count_active_province_caltrops(province_id)
	var target_count: int = mini(get_province_tuning_int("max_active_caltrops_per_province"), int(floor(float(defense_strength) * get_province_tuning_value("trap_factory_caltrop_multiplier"))))
	var to_add: int = maxi(0, target_count - active_count)
	if to_add <= 0:
		return 0
	var caltrops: Array[Dictionary] = _normalize_caltrop_entries(province_state.get(CALTROPS_KEY, []))
	var next_id: int = 0
	for caltrop in caltrops:
		next_id = maxi(next_id, int(caltrop.get("id", -1)) + 1)
	for i in range(to_add):
		var caltrop_id: int = next_id + i
		caltrops.append({
			"id": caltrop_id,
			"seed": _make_caltrop_spawn_seed(province_id, caltrop_id),
			"destroyed": false,
			"is_friendly": true
		})
	province_state[CALTROPS_KEY] = caltrops
	return to_add


func province_has_non_self_neighbor(province_state: Dictionary) -> bool:
	if _main == null:
		return false
	var relation: String = get_relation_to_player_for_province_state(province_state)
	for neighbor_id in normalize_neighbor_ids(province_state.get("neighbors", [])):
		var neighbor_index: int = find_persistence_index_by_id(int(neighbor_id))
		if neighbor_index == -1:
			continue
		var neighbor_state: Dictionary = _main._province_persistence[neighbor_index]
		if get_relation_to_player_for_province_state(neighbor_state) != relation:
			return true
	return false


func province_has_hostile_or_non_owned_neighbor(province_state: Dictionary) -> bool:
	if _main == null:
		return false
	var province_faction: int = get_province_faction(province_state)
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	for neighbor_id in normalize_neighbor_ids(province_state.get("neighbors", [])):
		var neighbor_index: int = find_persistence_index_by_id(int(neighbor_id))
		if neighbor_index == -1:
			continue
		var neighbor_state: Dictionary = _main._province_persistence[neighbor_index]
		if String(neighbor_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != province_type:
			return true
		if get_province_faction(neighbor_state) != province_faction:
			return true
	return false


func build_valid_construction_candidates(province_state: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	normalize_province_economy_state(province_state)
	if not province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).is_empty():
		return candidates
	candidates.append({
		"label": "Recruitment focus",
		"request_type": CONSTRUCTION_PROJECT_RECRUITMENT,
		"building_type": "",
		"tier": 1
	})
	for building_type in BUILDING_CATALOG.keys():
		var definition: Dictionary = BUILDING_CATALOG.get(building_type, {})
		var display_name: String = String(definition.get("display_name", building_type))
		if can_add_typed_building(province_state, building_type, 1):
			candidates.append({
				"label": "Build %s" % display_name,
				"request_type": CONSTRUCTION_PROJECT_BUILD,
				"building_type": building_type,
				"tier": 1
			})
		var max_tier: int = int(definition.get("max_tier", 3))
		for from_tier in range(1, max_tier):
			if get_typed_building_count(province_state, building_type, from_tier) <= 0:
				continue
			candidates.append({
				"label": "Upgrade %s T%d -> T%d" % [display_name, from_tier, from_tier + 1],
				"request_type": CONSTRUCTION_PROJECT_UPGRADE,
				"building_type": building_type,
				"tier": from_tier
			})
		for demolish_tier in range(1, max_tier + 1):
			if get_typed_building_count(province_state, building_type, demolish_tier) <= 0:
				continue
			candidates.append({
				"label": "Demolish %s T%d" % [display_name, demolish_tier],
				"request_type": CONSTRUCTION_PROJECT_DEMOLISH,
				"building_type": building_type,
				"tier": demolish_tier
			})
	var can_repair: bool = false
	for repair_tier in [1, 2]:
		for repair_building_type in BUILDING_CATALOG.keys():
			if get_typed_building_count(province_state, repair_building_type, repair_tier) > 0:
				can_repair = true
				break
		if can_repair:
			break
	if can_repair:
		candidates.append({
			"label": "Repair damaged building tier",
			"request_type": CONSTRUCTION_PROJECT_REPAIR,
			"building_type": BUILDING_DEFENSE_NEST,
			"tier": 1
		})
	return candidates


func _is_construction_action_valid(province_state: Dictionary, action: Dictionary) -> bool:
	var request_type: String = String(action.get("request_type", ""))
	var building_type: String = get_canonical_building_type(String(action.get("building_type", "")))
	var tier: int = int(action.get("tier", 1))
	if request_type == CONSTRUCTION_PROJECT_BUILD:
		return can_add_typed_building(province_state, building_type, tier)
	if request_type == CONSTRUCTION_PROJECT_UPGRADE:
		if not BUILDING_CATALOG.has(building_type):
			return false
		var definition: Dictionary = BUILDING_CATALOG[building_type]
		return tier >= 1 and tier + 1 <= int(definition.get("max_tier", 3)) and get_typed_building_count(province_state, building_type, tier) > 0
	if request_type == CONSTRUCTION_PROJECT_DEMOLISH:
		return BUILDING_CATALOG.has(building_type) and tier >= 1 and get_typed_building_count(province_state, building_type, tier) > 0
	if request_type == CONSTRUCTION_PROJECT_REPAIR:
		for repair_tier in [1, 2]:
			for repair_building_type in BUILDING_CATALOG.keys():
				if get_typed_building_count(province_state, repair_building_type, repair_tier) > 0:
					return true
	if request_type == CONSTRUCTION_PROJECT_RECRUITMENT:
		return String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_NEUTRAL
	return false


func _get_tier_effects_for_building(building_type: String, tier: int) -> Dictionary:
	building_type = get_canonical_building_type(building_type)
	var definition: Dictionary = BUILDING_CATALOG.get(building_type, {})
	var tier_effects: Dictionary = definition.get("tier_effects", {})
	return tier_effects.get(str(tier), {})


func _scale_construction_effects(raw_effects: Dictionary) -> Dictionary:
	var effects: Dictionary = {
		"food_production": 0.0,
		"native_accommodation": 0.0,
		"outlander_accommodation": 0.0,
		"native_taper_cap": 0.0,
		"outlander_taper_cap": 0.0,
		"growth_factor": 0.0,
		"recruitment": 0.0,
		"construction": 0.0,
		"income": 0.0,
		"defense_strength": 0.0,
		"adjacent_damage": 0.0
	}
	for effect_key in effects.keys():
		var multiplier_key: String = "building_%s_multiplier" % String(effect_key)
		effects[effect_key] = float(raw_effects.get(effect_key, 0.0)) * get_province_tuning_value(multiplier_key)
	return effects


func estimate_construction_action_effects(province_state: Dictionary, action: Dictionary) -> Dictionary:
	normalize_province_economy_state(province_state)
	var request_type: String = String(action.get("request_type", ""))
	var building_type: String = get_canonical_building_type(String(action.get("building_type", "")))
	var tier: int = int(action.get("tier", 1))
	if request_type == CONSTRUCTION_PROJECT_RECRUITMENT:
		return _scale_construction_effects({"recruitment": get_province_tuning_value("base_construction_rate") * CONSTRUCTION_RECRUITMENT_CONVERSION_RATE})
	if request_type == CONSTRUCTION_PROJECT_REPAIR:
		return _scale_construction_effects(_get_tier_effects_for_building(BUILDING_DEFENSE_NEST, 1))
	if not BUILDING_CATALOG.has(building_type):
		return _scale_construction_effects({})
	if request_type == CONSTRUCTION_PROJECT_BUILD:
		var build_effects: Dictionary = _scale_construction_effects(_get_tier_effects_for_building(building_type, tier))
		if building_type == BUILDING_TENEMENT:
			build_effects["native_taper_cap"] = NATIVE_GROWTH_TAPER_CAP_PER_TENEMENT
		elif building_type == BUILDING_MANSION:
			build_effects["outlander_taper_cap"] = OUTLANDER_GROWTH_TAPER_CAP_PER_MANSION
		return build_effects
	if request_type == CONSTRUCTION_PROJECT_UPGRADE:
		var from_effects: Dictionary = _get_tier_effects_for_building(building_type, tier)
		var to_effects: Dictionary = _get_tier_effects_for_building(building_type, tier + 1)
		var delta_effects: Dictionary = {}
		for effect_key in to_effects.keys():
			if effect_key == "command_center":
				continue
			delta_effects[effect_key] = float(to_effects.get(effect_key, 0.0)) - float(from_effects.get(effect_key, 0.0))
		return _scale_construction_effects(delta_effects)
	if request_type == CONSTRUCTION_PROJECT_DEMOLISH:
		var remove_effects: Dictionary = _scale_construction_effects(_get_tier_effects_for_building(building_type, tier))
		for effect_key in remove_effects.keys():
			remove_effects[effect_key] = -float(remove_effects.get(effect_key, 0.0))
		return remove_effects
	return _scale_construction_effects({})


func _get_action_required_progress(action: Dictionary) -> float:
	var request_type: String = String(action.get("request_type", ""))
	if request_type == CONSTRUCTION_PROJECT_RECRUITMENT:
		return 1.0
	if request_type == CONSTRUCTION_PROJECT_REPAIR:
		return maxf(1.0, get_province_tuning_value("repair_progress_required"))
	var building_type: String = String(action.get("building_type", ""))
	var target_tier: int = int(action.get("tier", 1))
	if request_type == CONSTRUCTION_PROJECT_UPGRADE:
		target_tier += 1
	var required: float = get_building_progress_required(building_type, target_tier)
	if request_type == CONSTRUCTION_PROJECT_DEMOLISH:
		required *= 0.5
	return required


func _construction_action_catalog_index(action: Dictionary) -> int:
	var keys: Array = BUILDING_CATALOG.keys()
	var building_type: String = String(action.get("building_type", ""))
	var index: int = keys.find(building_type)
	return index if index >= 0 else 999


func _construction_actions_match(a: Dictionary, b: Dictionary) -> bool:
	return (
		String(a.get("request_type", "")) == String(b.get("request_type", ""))
		and String(a.get("building_type", "")) == String(b.get("building_type", ""))
		and int(a.get("tier", 1)) == int(b.get("tier", 1))
	)


func _forecast_population_and_pressure(province_state: Dictionary, horizon: int = -1, effect_adjustments: Dictionary = {}) -> Dictionary:
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var accommodation: Dictionary = province_state.get(PROVINCE_ACCOMMODATION_KEY, {})
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var rates: Dictionary = province_state.get(PROVINCE_RATES_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var forecast_horizon: int = maxi(0, horizon if horizon >= 0 else get_province_tuning_int("ai_forecast_horizon_ticks"))
	var growth_factor: float = maxf(0.0, float(rates.get("growth_factor", 0.0)) + float(effect_adjustments.get("growth_factor", 0.0)))
	var projected_natives: float = maxf(0.0, float(population.get(POPULATION_NATIVES_KEY, 0.0)))
	var projected_outlanders: float = maxf(0.0, float(population.get(POPULATION_OUTLANDER_KEY, 0.0)))
	var resident_troops: float = maxf(0.0, float(province_state.get("remaining_troops", province_state.get("troops", 0))))
	var projected_food_production: float = float(food.get("production", 0.0)) + float(effect_adjustments.get("food_production", 0.0))
	var default_happiness: float = get_province_tuning_value("default_happiness")
	var native_happiness_multiplier: float = _get_happiness_multiplier(float(happiness.get(POPULATION_NATIVES_KEY, default_happiness)))
	var outlander_happiness_multiplier: float = _get_happiness_multiplier(float(happiness.get(POPULATION_OUTLANDER_KEY, default_happiness)))
	var taper_caps: Dictionary = get_population_taper_caps(province_state)
	var projected_native_taper_cap: float = maxf(0.0, float(taper_caps.get(POPULATION_NATIVES_KEY, NATIVE_GROWTH_TAPER_BASE_CAP)) + float(effect_adjustments.get("native_taper_cap", 0.0)))
	var projected_outlander_taper_cap: float = maxf(0.0, float(taper_caps.get(POPULATION_OUTLANDER_KEY, OUTLANDER_GROWTH_TAPER_BASE_CAP)) + float(effect_adjustments.get("outlander_taper_cap", 0.0)))
	projected_natives = minf(projected_natives, projected_native_taper_cap)
	projected_outlanders = minf(projected_outlanders, projected_outlander_taper_cap)
	for _i in range(forecast_horizon):
		var step_demand: float = projected_natives * get_province_tuning_value("native_food_demand") + projected_outlanders * get_province_tuning_value("outlander_food_demand") + resident_troops * get_province_tuning_value("troop_food_demand")
		var food_growth_multiplier: float = 1.0 if projected_food_production - step_demand >= 0.0 else get_province_tuning_value("food_deficit_population_growth_multiplier")
		projected_natives = _apply_tapered_population_growth(projected_natives, get_province_tuning_value("native_growth_rate"), growth_factor, food_growth_multiplier, native_happiness_multiplier, projected_native_taper_cap)
		projected_outlanders = _apply_tapered_population_growth(projected_outlanders, get_province_tuning_value("outlander_growth_rate"), growth_factor, food_growth_multiplier, outlander_happiness_multiplier, projected_outlander_taper_cap)
	var projected_demand: float = projected_natives * get_province_tuning_value("native_food_demand") + projected_outlanders * get_province_tuning_value("outlander_food_demand") + resident_troops * get_province_tuning_value("troop_food_demand")
	var projected_native_ceiling: float = float(accommodation.get(ACCOMMODATION_NATIVE_CEILING_KEY, 0.0)) + float(effect_adjustments.get("native_accommodation", 0.0))
	var projected_outlander_ceiling: float = float(accommodation.get(ACCOMMODATION_OUTLANDER_CEILING_KEY, 0.0)) + float(effect_adjustments.get("outlander_accommodation", 0.0))
	return {
		"projected_food_surplus": projected_food_production - projected_demand,
		"projected_native_overcrowding": projected_natives - projected_native_ceiling,
		"projected_outlander_overcrowding": projected_outlanders - projected_outlander_ceiling
	}


func _score_construction_action(province_state: Dictionary, action: Dictionary, action_index: int) -> Dictionary:
	var request_type: String = String(action.get("request_type", ""))
	var building_type: String = String(action.get("building_type", ""))
	var effects: Dictionary = estimate_construction_action_effects(province_state, action)
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var accommodation: Dictionary = province_state.get(PROVINCE_ACCOMMODATION_KEY, {})
	var rates: Dictionary = province_state.get(PROVINCE_RATES_KEY, {})
	var food_surplus: float = float(food.get("surplus", 0.0))
	var native_overcrowding: float = float(population.get(POPULATION_NATIVES_KEY, 0.0)) - float(accommodation.get(ACCOMMODATION_NATIVE_CEILING_KEY, 0.0))
	var outlander_overcrowding: float = float(population.get(POPULATION_OUTLANDER_KEY, 0.0)) - float(accommodation.get(ACCOMMODATION_OUTLANDER_CEILING_KEY, 0.0))
	var forecast: Dictionary = _forecast_population_and_pressure(province_state)
	var forecast_after_action: Dictionary = _forecast_population_and_pressure(province_state, -1, effects)
	var score: float = 1000.0
	var reason: String = "Available construction"
	var food_gain: float = float(effects.get("food_production", 0.0))
	var native_accommodation_gain: float = float(effects.get("native_accommodation", 0.0))
	var outlander_accommodation_gain: float = float(effects.get("outlander_accommodation", 0.0))
	var defense_gain: float = float(effects.get("defense_strength", 0.0))
	var recruitment_gain: float = float(effects.get("recruitment", 0.0))
	var construction_gain: float = float(effects.get("construction", 0.0))
	var growth_gain: float = float(effects.get("growth_factor", 0.0))
	var income_gain: float = float(effects.get("income", 0.0))
	var adjacent_damage_gain: float = float(effects.get("adjacent_damage", 0.0))
	var food_threshold: float = get_province_tuning_value("ai_food_deficit_build_threshold")
	var overcrowding_threshold: float = get_province_tuning_value("ai_overcrowding_build_threshold")
	var forecast_food_threshold: float = get_province_tuning_value("ai_forecast_food_surplus_threshold")
	var forecast_overcrowding_threshold: float = get_province_tuning_value("ai_forecast_overcrowding_threshold")
	var forecast_score_base: float = get_province_tuning_value("ai_forecast_score_base")
	var forecast_food_score_per_point: float = get_province_tuning_value("ai_forecast_food_pressure_score_per_point")
	var forecast_overcrowding_score_per_person: float = get_province_tuning_value("ai_forecast_overcrowding_score_per_person")
	var forecast_min_relief: float = get_province_tuning_value("ai_forecast_min_relief")
	var projected_food_surplus: float = float(forecast.get("projected_food_surplus", 0.0))
	var projected_native_overcrowding: float = float(forecast.get("projected_native_overcrowding", 0.0))
	var projected_outlander_overcrowding: float = float(forecast.get("projected_outlander_overcrowding", 0.0))
	var projected_food_surplus_after_action: float = float(forecast_after_action.get("projected_food_surplus", 0.0))
	var projected_native_overcrowding_after_action: float = float(forecast_after_action.get("projected_native_overcrowding", 0.0))
	var projected_outlander_overcrowding_after_action: float = float(forecast_after_action.get("projected_outlander_overcrowding", 0.0))
	var forecast_food_relief: float = projected_food_surplus_after_action - projected_food_surplus
	var forecast_native_relief: float = projected_native_overcrowding - projected_native_overcrowding_after_action
	var forecast_outlander_relief: float = projected_outlander_overcrowding - projected_outlander_overcrowding_after_action
	if food_surplus < food_threshold and food_gain > 0.0:
		score = 9000.0 + absf(food_surplus) * 20.0 + food_gain
		reason = "Food deficit"
	elif native_overcrowding > overcrowding_threshold and native_accommodation_gain > 0.0:
		score = 9000.0 + native_overcrowding * 25.0 + native_accommodation_gain
		reason = "Native overcrowding"
	elif outlander_overcrowding > overcrowding_threshold and outlander_accommodation_gain > 0.0:
		score = 9000.0 + outlander_overcrowding * 25.0 + outlander_accommodation_gain
		reason = "Outlander overcrowding"
	elif projected_food_surplus < forecast_food_threshold and food_gain > 0.0 and forecast_food_relief >= forecast_min_relief:
		score = forecast_score_base + maxf(0.0, forecast_food_threshold - projected_food_surplus) * forecast_food_score_per_point + food_gain
		reason = "Forecast food pressure"
	elif projected_native_overcrowding > forecast_overcrowding_threshold and native_accommodation_gain > 0.0 and forecast_native_relief >= forecast_min_relief:
		score = forecast_score_base + projected_native_overcrowding * forecast_overcrowding_score_per_person + native_accommodation_gain
		reason = "Forecast native overcrowding"
	elif projected_outlander_overcrowding > forecast_overcrowding_threshold and outlander_accommodation_gain > 0.0 and forecast_outlander_relief >= forecast_min_relief:
		score = forecast_score_base + projected_outlander_overcrowding * forecast_overcrowding_score_per_person + outlander_accommodation_gain
		reason = "Forecast outlander overcrowding"
	elif request_type == CONSTRUCTION_PROJECT_RECRUITMENT:
		score = 3400.0 + float(rates.get("construction", 0.0)) * CONSTRUCTION_RECRUITMENT_CONVERSION_RATE * 20.0
		reason = "Recruitment focus"
	elif request_type == CONSTRUCTION_PROJECT_REPAIR and province_has_hostile_or_non_owned_neighbor(province_state):
		score = 5400.0
		reason = "Front-line repair"
	elif province_has_hostile_or_non_owned_neighbor(province_state) and building_type == BUILDING_DEFENSE_NEST:
		score = 5500.0 + defense_gain * 150.0 - float(get_province_defense_strength(province_state)) * 50.0
		reason = "Front-line defense"
	elif province_has_hostile_or_non_owned_neighbor(province_state) and building_type == BUILDING_CATAPULT and get_province_defense_strength(province_state) > 0:
		score = 5000.0 + adjacent_damage_gain * 100.0
		reason = "Front-line support"
	elif building_type == BUILDING_CLUB_FACTORY:
		score = 3500.0 + recruitment_gain * 100.0
		reason = "Recruitment capacity"
	elif building_type == BUILDING_COMMAND_CENTER:
		score = 3300.0 + construction_gain * 100.0
		reason = "Command infrastructure"
	elif building_type == BUILDING_GROWTH_INCREASER and food_surplus > 0.0:
		score = 3200.0 + growth_gain * 100.0
		reason = "Growth capacity"
	elif income_gain > 0.0:
		score = 3100.0 + income_gain * 100.0
		reason = "Income capacity"
	var required_progress: float = _get_action_required_progress(action)
	return {
		"ok": true,
		"request_type": request_type,
		"building_type": building_type,
		"tier": int(action.get("tier", 1)),
		"score": score,
		"reason": reason,
		"required_progress": required_progress,
		"catalog_index": _construction_action_catalog_index(action),
		"action_index": action_index,
		"details": {
			"food_surplus": food_surplus,
			"projected_food_surplus": projected_food_surplus,
			"projected_food_surplus_after_action": projected_food_surplus_after_action,
			"native_overcrowding": native_overcrowding,
			"outlander_overcrowding": outlander_overcrowding,
			"projected_native_overcrowding": projected_native_overcrowding,
			"projected_outlander_overcrowding": projected_outlander_overcrowding,
			"projected_native_overcrowding_after_action": projected_native_overcrowding_after_action,
			"projected_outlander_overcrowding_after_action": projected_outlander_overcrowding_after_action,
			"construction_rate": float(rates.get("construction", 0.0))
		}
	}


func _is_recommendation_better(candidate: Dictionary, incumbent: Dictionary) -> bool:
	if incumbent.is_empty():
		return true
	var score_delta: float = float(candidate.get("score", 0.0)) - float(incumbent.get("score", 0.0))
	if absf(score_delta) > 0.001:
		return score_delta > 0.0
	var progress_delta: float = float(candidate.get("required_progress", 0.0)) - float(incumbent.get("required_progress", 0.0))
	if absf(progress_delta) > 0.001:
		return progress_delta < 0.0
	var catalog_delta: int = int(candidate.get("catalog_index", 999)) - int(incumbent.get("catalog_index", 999))
	if catalog_delta != 0:
		return catalog_delta < 0
	return int(candidate.get("action_index", 9999)) < int(incumbent.get("action_index", 9999))


func build_recommended_construction_order(province_state: Dictionary, candidate_actions: Array[Dictionary] = []) -> Dictionary:
	normalize_province_economy_state(province_state)
	if not province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).is_empty():
		return {}
	var actions: Array[Dictionary] = []
	if candidate_actions.is_empty():
		actions = build_valid_construction_candidates(province_state)
	else:
		for action_any in candidate_actions:
			if action_any is Dictionary:
				actions.append((action_any as Dictionary).duplicate(true))
	var best: Dictionary = {}
	for i in range(actions.size()):
		var action: Dictionary = actions[i]
		if String(action.get("request_type", "")) == CONSTRUCTION_PROJECT_DEMOLISH:
			continue
		if not _is_construction_action_valid(province_state, action):
			continue
		var scored: Dictionary = _score_construction_action(province_state, action, i)
		if _is_recommendation_better(scored, best):
			best = scored
	if best.is_empty():
		return {}
	best.erase("catalog_index")
	best.erase("action_index")
	best.erase("required_progress")
	return best


func apply_recommended_construction_order(province_state: Dictionary) -> Dictionary:
	var recommendation: Dictionary = build_recommended_construction_order(province_state)
	if recommendation.is_empty():
		return {"ok": false, "message": "No valid construction recommendation."}
	var request_type: String = String(recommendation.get("request_type", ""))
	var building_type: String = String(recommendation.get("building_type", ""))
	var tier: int = int(recommendation.get("tier", 1))
	var ok: bool = false
	if request_type == CONSTRUCTION_PROJECT_BUILD:
		ok = start_building_construction(province_state, building_type, tier)
	elif request_type == CONSTRUCTION_PROJECT_UPGRADE:
		ok = start_building_upgrade_construction(province_state, building_type, tier)
	elif request_type == CONSTRUCTION_PROJECT_REPAIR:
		ok = start_building_repair_construction(province_state)
	elif request_type == CONSTRUCTION_PROJECT_RECRUITMENT:
		ok = start_recruitment_focus_construction(province_state)
	if not ok:
		return {
			"ok": false,
			"message": "Recommended construction could not be started.",
			"request_type": request_type,
			"building_type": building_type,
			"tier": tier,
			"reason": String(recommendation.get("reason", ""))
		}
	return {
		"ok": true,
		"request_type": request_type,
		"building_type": building_type,
		"tier": tier,
		"reason": String(recommendation.get("reason", ""))
	}


func _maybe_start_non_player_construction(province_state: Dictionary) -> String:
	if _main == null:
		return ""
	if get_relation_to_player_for_province_state(province_state) == RELATION_SELF:
		return ""
	var result: Dictionary = apply_recommended_construction_order(province_state)
	return String(result.get("building_type", "")) if bool(result.get("ok", false)) else ""


func _maybe_start_player_recommended_construction(province_state: Dictionary) -> String:
	if _main == null:
		return ""
	if get_relation_to_player_for_province_state(province_state) != RELATION_SELF:
		return ""
	var started_building: String = _try_start_next_queued_construction(province_state)
	if started_building != "":
		return started_building
	if not province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).is_empty():
		return ""
	var queue: Array[Dictionary] = normalize_construction_queue(province_state.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []))
	if not queue.is_empty():
		province_state[PROVINCE_CONSTRUCTION_QUEUE_KEY] = queue
		return ""
	var recommendation: Dictionary = build_recommended_construction_order(province_state)
	if recommendation.is_empty():
		province_state[PROVINCE_CONSTRUCTION_QUEUE_KEY] = []
		return ""
	province_state[PROVINCE_CONSTRUCTION_QUEUE_KEY] = [_make_construction_queue_item(recommendation)]
	return _try_start_next_queued_construction(province_state)


func trigger_province_revolution(province_state: Dictionary) -> bool:
	if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_ENEMY and int(province_state.get("faction_id", 0)) == REBEL_FACTION_ID:
		return false
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	happiness[POPULATION_NATIVES_KEY] = REBELLION_RESET_HAPPINESS
	happiness[POPULATION_OUTLANDER_KEY] = REBELLION_RESET_HAPPINESS
	province_state[PROVINCE_HAPPINESS_KEY] = happiness
	province_state["type"] = LevelConfig.PROVINCE_TYPE_ENEMY
	province_state["faction_id"] = REBEL_FACTION_ID
	province_state["capture_source"] = "revolution"
	province_state["remaining_troops"] = maxi(0, int(province_state.get("remaining_troops", 0)))
	province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {}
	reset_rebel_province_buildings(province_state)
	var status: Dictionary = province_state.get(PROVINCE_STATUS_KEY, {})
	status["revolt_warning"] = false
	status["revolted"] = true
	province_state[PROVINCE_STATUS_KEY] = status
	return true


func tick_province_economy(province_state: Dictionary, landing_construction_bonus: float = 0.0) -> Dictionary:
	normalize_province_economy_state(province_state)
	var before_food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {}).duplicate(true)
	var before_happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {}).duplicate(true)
	var ai_started_building: String = ""
	var player_auto_started_building: String = ""
	var landing_construction_bonus_applied: bool = false
	var building_effects: Dictionary = calculate_building_effects(province_state)
	recalculate_accommodation(province_state, building_effects)
	recalculate_food(province_state, building_effects)
	if _apply_food_shortage_population_loss(province_state):
		recalculate_food(province_state, building_effects)
	var should_revolt: bool = _apply_province_happiness_deltas(province_state)
	if should_revolt:
		var revolted: bool = trigger_province_revolution(province_state)
		recalculate_province_derived_economy(province_state)
		return {
			"province_id": int(province_state.get("id", -1)),
			"revolted": revolted,
			"ai_started_building": "",
			"player_auto_started_building": "",
			"food_before": before_food,
			"food_after": province_state.get(PROVINCE_FOOD_KEY, {}).duplicate(true),
			"happiness_before": before_happiness,
			"happiness_after": province_state.get(PROVINCE_HAPPINESS_KEY, {}).duplicate(true)
		}
	recalculate_province_derived_economy(province_state)
	if get_relation_to_player_for_province_state(province_state) == RELATION_SELF:
		player_auto_started_building = _maybe_start_player_recommended_construction(province_state)
	else:
		ai_started_building = _maybe_start_non_player_construction(province_state)
	landing_construction_bonus_applied = _add_active_construction_progress(province_state, landing_construction_bonus)
	_update_province_population(province_state)
	recalculate_province_derived_economy(province_state)
	_apply_recruitment_and_income(province_state)
	_advance_active_construction(province_state)
	recalculate_province_derived_economy(province_state)
	var catapult_damage: int = _apply_catapult_adjacent_damage(province_state)
	var status: Dictionary = province_state.get(PROVINCE_STATUS_KEY, {})
	status["recently_conquered_ticks"] = maxi(0, int(status.get("recently_conquered_ticks", 0)) - 1)
	province_state[PROVINCE_STATUS_KEY] = status
	return {
		"province_id": int(province_state.get("id", -1)),
		"revolted": false,
		"ai_started_building": ai_started_building,
		"ai_started_building_name": get_building_display_name(ai_started_building) if ai_started_building != "" else "",
		"player_auto_started_building": player_auto_started_building,
		"player_auto_started_building_name": get_building_display_name(player_auto_started_building) if player_auto_started_building != "" else "",
		"landing_construction_bonus_applied": landing_construction_bonus_applied,
		"catapult_damage": catapult_damage,
		"food_before": before_food,
		"food_after": province_state.get(PROVINCE_FOOD_KEY, {}).duplicate(true),
		"happiness_before": before_happiness,
		"happiness_after": province_state.get(PROVINCE_HAPPINESS_KEY, {}).duplicate(true)
	}


func _should_defer_persistence_visual_refresh() -> bool:
	if _main == null:
		return false
	if _main.has_method("is_auto_engagement_preview_active") and bool(_main.call("is_auto_engagement_preview_active")):
		return true
	if _main.has_method("should_defer_province_visual_refresh_during_automation") and bool(_main.call("should_defer_province_visual_refresh_during_automation")):
		return true
	return false


func apply_persistence_to_province_visuals_respecting_deferral() -> void:
	if _should_defer_persistence_visual_refresh():
		if _main != null and _main.has_method("mark_automated_turn_visual_flush_pending"):
			_main.call("mark_automated_turn_visual_flush_pending")
		return
	apply_persistence_to_province_visuals()


func tick_all_province_economies(player_landing_province_id: int = -1) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if _main == null:
		return results
	for province_state in _main._province_persistence:
		if province_state is Dictionary:
			var bonus: float = 0.0
			if int(province_state.get("id", -1)) == player_landing_province_id and get_relation_to_player_for_province_state(province_state) == RELATION_SELF:
				bonus = PLAYER_LANDING_CONSTRUCTION_BONUS
			results.append(tick_province_economy(province_state, bonus))
	apply_persistence_to_province_visuals_respecting_deferral()
	return results


func start_building_construction(province_state: Dictionary, building_type: String, target_tier: int = 1) -> bool:
	building_type = get_canonical_building_type(building_type)
	normalize_province_economy_state(province_state)
	if not province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).is_empty():
		return false
	if not can_add_typed_building(province_state, building_type, target_tier):
		return false
	province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {
		"project_type": CONSTRUCTION_PROJECT_BUILD,
		"building_type": building_type,
		"target_tier": target_tier,
		"progress": 0.0,
		"required_progress": get_building_progress_required(building_type, target_tier)
	}
	return true


func start_building_upgrade_construction(province_state: Dictionary, building_type: String, from_tier: int = 1) -> bool:
	building_type = get_canonical_building_type(building_type)
	normalize_province_economy_state(province_state)
	if not province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).is_empty():
		return false
	if not BUILDING_CATALOG.has(building_type):
		return false
	var target_tier: int = from_tier + 1
	var definition: Dictionary = BUILDING_CATALOG[building_type]
	if target_tier > int(definition.get("max_tier", 3)):
		return false
	if get_typed_building_count(province_state, building_type, from_tier) <= 0:
		return false
	province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {
		"project_type": CONSTRUCTION_PROJECT_UPGRADE,
		"building_type": building_type,
		"target_tier": target_tier,
		"progress": 0.0,
		"required_progress": get_building_progress_required(building_type, target_tier)
	}
	return true


func start_building_demolish_construction(province_state: Dictionary, building_type: String, tier: int = 1) -> bool:
	building_type = get_canonical_building_type(building_type)
	normalize_province_economy_state(province_state)
	if not province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).is_empty():
		return false
	if not BUILDING_CATALOG.has(building_type):
		return false
	if tier < 1 or get_typed_building_count(province_state, building_type, tier) <= 0:
		return false
	province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {
		"project_type": CONSTRUCTION_PROJECT_DEMOLISH,
		"building_type": building_type,
		"target_tier": tier,
		"progress": 0.0,
		"required_progress": get_building_progress_required(building_type, tier) * 0.5
	}
	return true


func start_building_repair_construction(province_state: Dictionary) -> bool:
	normalize_province_economy_state(province_state)
	if not province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).is_empty():
		return false
	var can_repair: bool = false
	for tier in [1, 2]:
		for building_type in BUILDING_CATALOG.keys():
			if get_typed_building_count(province_state, building_type, tier) > 0:
				can_repair = true
				break
		if can_repair:
			break
	if not can_repair:
		return false
	province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {
		"project_type": CONSTRUCTION_PROJECT_REPAIR,
		"building_type": BUILDING_DEFENSE_NEST,
		"target_tier": 1,
		"progress": 0.0,
		"required_progress": get_province_tuning_value("repair_progress_required")
	}
	return true


func start_recruitment_focus_construction(province_state: Dictionary) -> bool:
	normalize_province_economy_state(province_state)
	if not province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).is_empty():
		return false
	if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return false
	province_state[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {
		"project_type": CONSTRUCTION_PROJECT_RECRUITMENT,
		"building_type": "",
		"target_tier": 1,
		"progress": 0.0,
		"required_progress": 1.0
	}
	return true


func _reserve_construction_action_on_state(province_state: Dictionary, action: Dictionary) -> void:
	var request_type: String = String(action.get("request_type", action.get("project_type", "")))
	var building_type: String = get_canonical_building_type(String(action.get("building_type", "")))
	var tier: int = int(action.get("tier", action.get("target_tier", 1)))
	if request_type == CONSTRUCTION_PROJECT_UPGRADE and action.has("target_tier") and not action.has("tier"):
		tier = maxi(1, tier - 1)
	if request_type == CONSTRUCTION_PROJECT_BUILD and BUILDING_CATALOG.has(building_type):
		add_typed_building(province_state, building_type, tier)
	elif request_type == CONSTRUCTION_PROJECT_UPGRADE and BUILDING_CATALOG.has(building_type):
		upgrade_typed_building(province_state, building_type, tier)
	elif request_type == CONSTRUCTION_PROJECT_DEMOLISH and BUILDING_CATALOG.has(building_type):
		remove_typed_building(province_state, building_type, tier)


func _start_construction_action(province_state: Dictionary, action: Dictionary) -> bool:
	var request_type: String = String(action.get("request_type", action.get("project_type", "")))
	var building_type: String = get_canonical_building_type(String(action.get("building_type", "")))
	var tier: int = int(action.get("tier", 1))
	if request_type == CONSTRUCTION_PROJECT_BUILD:
		return start_building_construction(province_state, building_type, tier)
	if request_type == CONSTRUCTION_PROJECT_UPGRADE:
		return start_building_upgrade_construction(province_state, building_type, tier)
	if request_type == CONSTRUCTION_PROJECT_DEMOLISH:
		return start_building_demolish_construction(province_state, building_type, tier)
	if request_type == CONSTRUCTION_PROJECT_REPAIR:
		return start_building_repair_construction(province_state)
	if request_type == CONSTRUCTION_PROJECT_RECRUITMENT:
		return start_recruitment_focus_construction(province_state)
	return false


func _make_construction_queue_item(action: Dictionary) -> Dictionary:
	var request_type: String = String(action.get("request_type", action.get("project_type", CONSTRUCTION_PROJECT_BUILD)))
	var building_type: String = get_canonical_building_type(String(action.get("building_type", "")))
	if request_type == CONSTRUCTION_PROJECT_REPAIR and not BUILDING_CATALOG.has(building_type):
		building_type = BUILDING_DEFENSE_NEST
	return {
		"request_type": request_type,
		"building_type": building_type,
		"tier": maxi(1, int(action.get("tier", 1)))
	}


func _make_construction_reservation_state(province_state: Dictionary) -> Dictionary:
	var reserved: Dictionary = province_state.duplicate(true)
	normalize_province_economy_state(reserved)
	var active: Dictionary = reserved.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).duplicate(true)
	if not active.is_empty():
		_reserve_construction_action_on_state(reserved, active)
	var queue: Array[Dictionary] = normalize_construction_queue(reserved.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []))
	for action in queue:
		_reserve_construction_action_on_state(reserved, action)
	reserved[PROVINCE_ACTIVE_CONSTRUCTION_KEY] = {}
	reserved[PROVINCE_CONSTRUCTION_QUEUE_KEY] = []
	return reserved


func _try_start_next_queued_construction(province_state: Dictionary) -> String:
	normalize_province_economy_state(province_state)
	if not province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).is_empty():
		return ""
	var queue: Array[Dictionary] = normalize_construction_queue(province_state.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []))
	while not queue.is_empty():
		var action: Dictionary = queue.pop_front()
		province_state[PROVINCE_CONSTRUCTION_QUEUE_KEY] = queue
		var building_type: String = get_canonical_building_type(String(action.get("building_type", "")))
		var ok: bool = _start_construction_action(province_state, action)
		if ok:
			return building_type
	return ""


func build_province_build_mode_actions(province_id: int) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if _main == null:
		return actions
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return actions
	var province_state: Dictionary = _main._province_persistence[index]
	normalize_province_economy_state(province_state)
	if not can_player_control_construction_in_province(province_id):
		return actions
	var queue: Array[Dictionary] = normalize_construction_queue(province_state.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []))
	if queue.size() >= PROVINCE_BUILD_QUEUE_LIMIT:
		return actions
	var reserved_state: Dictionary = _make_construction_reservation_state(province_state)
	for building_type_any in BUILDING_CATALOG.keys():
		var building_type: String = String(building_type_any)
		var sprite_path: String = get_building_sprite_path(building_type)
		if sprite_path == "":
			continue
		if not can_add_typed_building(reserved_state, building_type, 1):
			continue
		var definition: Dictionary = BUILDING_CATALOG.get(building_type, {})
		actions.append({
			"label": "Build %s" % String(definition.get("display_name", building_type)),
			"request_type": CONSTRUCTION_PROJECT_BUILD,
			"building_type": building_type,
			"tier": 1
		})
	return actions


func enqueue_province_construction_order(province_id: int, action: Dictionary) -> Dictionary:
	if _main == null:
		return {"ok": false, "message": "Construction queue unavailable."}
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return {"ok": false, "message": "Construction queue unavailable: province %d was not found." % province_id}
	var province_state: Dictionary = _main._province_persistence[index]
	normalize_province_economy_state(province_state)
	if not can_player_control_construction_in_province(province_id):
		return {"ok": false, "message": "Construction queue rejected: this province is not player-controlled."}
	var queue: Array[Dictionary] = normalize_construction_queue(province_state.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []))
	if queue.size() >= PROVINCE_BUILD_QUEUE_LIMIT:
		return {"ok": false, "message": "Construction queue is full."}
	var request_type: String = String(action.get("request_type", ""))
	var building_type: String = get_canonical_building_type(String(action.get("building_type", "")))
	var tier: int = maxi(1, int(action.get("tier", 1)))
	if not [CONSTRUCTION_PROJECT_BUILD, CONSTRUCTION_PROJECT_UPGRADE, CONSTRUCTION_PROJECT_DEMOLISH].has(request_type) or not BUILDING_CATALOG.has(building_type):
		return {"ok": false, "message": "Construction queue rejected: invalid building."}
	var reserved_state: Dictionary = _make_construction_reservation_state(province_state)
	if request_type == CONSTRUCTION_PROJECT_BUILD:
		if not can_add_typed_building(reserved_state, building_type, tier):
			return {"ok": false, "message": "Construction queue rejected: no available building slot."}
	elif request_type == CONSTRUCTION_PROJECT_UPGRADE:
		if not _is_construction_action_valid(reserved_state, action):
			return {"ok": false, "message": "Construction queue rejected: no upgradeable building."}
	elif request_type == CONSTRUCTION_PROJECT_DEMOLISH:
		if not _is_construction_action_valid(reserved_state, action):
			return {"ok": false, "message": "Construction queue rejected: no matching building to demolish."}
	queue.append({
		"request_type": request_type,
		"building_type": building_type,
		"tier": tier
	})
	province_state[PROVINCE_CONSTRUCTION_QUEUE_KEY] = queue
	apply_persistence_to_province_visuals()
	var action_label: String = "Queued %s" % get_building_display_name(building_type)
	if request_type == CONSTRUCTION_PROJECT_UPGRADE:
		action_label = "Queued upgrade for %s T%d" % [get_building_display_name(building_type), tier]
	elif request_type == CONSTRUCTION_PROJECT_DEMOLISH:
		action_label = "Queued demolition of %s T%d" % [get_building_display_name(building_type), tier]
	return {
		"ok": true,
		"message": "%s in %s (%d/%d)." % [action_label, get_province_display_name(province_id, province_state), queue.size(), PROVINCE_BUILD_QUEUE_LIMIT]
	}


func remove_queued_province_construction_order(province_id: int, queue_index: int) -> Dictionary:
	if _main == null:
		return {"ok": false, "message": "Construction queue unavailable."}
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return {"ok": false, "message": "Construction queue unavailable: province %d was not found." % province_id}
	var province_state: Dictionary = _main._province_persistence[index]
	normalize_province_economy_state(province_state)
	var queue: Array[Dictionary] = normalize_construction_queue(province_state.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []))
	if queue_index < 0 or queue_index >= queue.size():
		return {"ok": false, "message": "No queued construction at that slot."}
	var removed: Dictionary = queue[queue_index]
	queue.remove_at(queue_index)
	province_state[PROVINCE_CONSTRUCTION_QUEUE_KEY] = queue
	apply_persistence_to_province_visuals()
	var building_type: String = String(removed.get("building_type", ""))
	var removed_type: String = String(removed.get("request_type", CONSTRUCTION_PROJECT_BUILD))
	var removed_label: String = get_building_display_name(building_type)
	if removed_type == CONSTRUCTION_PROJECT_UPGRADE:
		removed_label = "upgrade for %s" % removed_label
	elif removed_type == CONSTRUCTION_PROJECT_DEMOLISH:
		removed_label = "demolition of %s" % removed_label
	return {
		"ok": true,
		"message": "Removed %s from %s's construction queue." % [removed_label, get_province_display_name(province_id, province_state)]
	}


func build_province_construction_actions(province_id: int) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if _main == null:
		return actions
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return actions
	var province_state: Dictionary = _main._province_persistence[index]
	normalize_province_economy_state(province_state)
	if not can_player_control_construction_in_province(province_id):
		return actions
	actions = build_valid_construction_candidates(province_state)
	var recommendation: Dictionary = build_recommended_construction_order(province_state, actions)
	if not recommendation.is_empty():
		for i in range(actions.size()):
			if not _construction_actions_match(actions[i], recommendation):
				continue
			actions[i]["recommended"] = true
			actions[i]["recommendation_reason"] = String(recommendation.get("reason", "Recommended"))
			break
	return actions


func start_province_construction_order(province_id: int, request_type: String, building_type: String, tier: int = 1) -> Dictionary:
	if _main == null:
		return {"ok": false, "message": "Construction unavailable: no active main node."}
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return {"ok": false, "message": "Construction unavailable: province %d was not found." % province_id}
	var province_state: Dictionary = _main._province_persistence[index]
	normalize_province_economy_state(province_state)
	if not can_player_control_construction_in_province(province_id):
		return {"ok": false, "message": "Construction rejected: %s is not player-controlled." % get_province_display_name(province_id, province_state)}
	if not province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {}).is_empty():
		return {"ok": false, "message": "Construction rejected: this province already has an active project."}
	building_type = get_canonical_building_type(building_type)
	if request_type != CONSTRUCTION_PROJECT_RECRUITMENT and not BUILDING_CATALOG.has(building_type):
		return {"ok": false, "message": "Construction rejected: unknown building type '%s'." % building_type}
	var definition: Dictionary = BUILDING_CATALOG.get(building_type, {})
	var display_name: String = "Recruitment focus" if request_type == CONSTRUCTION_PROJECT_RECRUITMENT else String(definition.get("display_name", building_type))
	var ok: bool = false
	if request_type == CONSTRUCTION_PROJECT_BUILD:
		ok = start_building_construction(province_state, building_type, tier)
	elif request_type == CONSTRUCTION_PROJECT_UPGRADE:
		ok = start_building_upgrade_construction(province_state, building_type, tier)
	elif request_type == CONSTRUCTION_PROJECT_DEMOLISH:
		ok = start_building_demolish_construction(province_state, building_type, tier)
	elif request_type == CONSTRUCTION_PROJECT_REPAIR:
		ok = start_building_repair_construction(province_state)
	elif request_type == CONSTRUCTION_PROJECT_RECRUITMENT:
		ok = start_recruitment_focus_construction(province_state)
	else:
		return {"ok": false, "message": "Construction rejected: unknown request type '%s'." % request_type}
	if not ok:
		return {"ok": false, "message": "Construction rejected: validation failed for %s." % display_name}
	if _main != null and _main.province_system != null:
		apply_persistence_to_province_visuals()
	var project: Dictionary = province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {})
	var target_tier: int = int(project.get("target_tier", tier))
	if request_type == CONSTRUCTION_PROJECT_RECRUITMENT:
		return {
			"ok": true,
			"message": "Started recruitment focus in %s." % get_province_display_name(province_id, province_state)
		}
	var verb: String = "Started repair" if request_type == CONSTRUCTION_PROJECT_REPAIR else ("Started demolition" if request_type == CONSTRUCTION_PROJECT_DEMOLISH else ("Started upgrade" if request_type == CONSTRUCTION_PROJECT_UPGRADE else "Started construction"))
	return {
		"ok": true,
		"message": "%s in %s." % [verb, get_province_display_name(province_id, province_state)] if request_type == CONSTRUCTION_PROJECT_REPAIR else "%s: %s T%d in %s." % [verb, display_name, target_tier, get_province_display_name(province_id, province_state)]
	}


func get_player_turn_start_province_id() -> int:
	if _main == null:
		return -1
	if int(_main.get("_locked_province_id_after_win")) >= 0:
		return int(_main.get("_locked_province_id_after_win"))
	return find_nearest_friendly_province_id(-1)


func can_player_control_troops_in_province(target_province_id: int) -> bool:
	if _main == null or target_province_id < 0:
		return false
	var start_province_id: int = get_player_turn_start_province_id()
	var target_index: int = find_persistence_index_by_id(target_province_id)
	if target_index == -1:
		return false
	var target_state: Dictionary = _main._province_persistence[target_index]
	if get_relation_to_player_for_province_state(target_state) != RELATION_SELF:
		return false
	if target_province_id == start_province_id:
		return true
	if _get_player_highest_home_cave_tier() >= 3:
		return true
	var start_index: int = find_persistence_index_by_id(start_province_id)
	if start_index == -1:
		return false
	var start_state: Dictionary = _main._province_persistence[start_index]
	return province_has_command_center(start_state)


func _get_player_highest_home_cave_tier() -> int:
	if _main == null:
		return 0
	var highest_tier: int = 0
	for province_state_any in _main._province_persistence:
		if not (province_state_any is Dictionary):
			continue
		var province_state: Dictionary = province_state_any
		if get_relation_to_player_for_province_state(province_state) != RELATION_SELF:
			continue
		highest_tier = maxi(highest_tier, get_home_cave_tier(province_state))
	return highest_tier


func get_player_march_threshold_authority(target_province_id: int = -1) -> Dictionary:
	if _main == null:
		return {"can_set": false, "tier": 0, "status": "March threshold controls unavailable: no active campaign."}
	var highest_tier: int = _get_player_highest_home_cave_tier()
	if highest_tier >= 3:
		return {
			"can_set": true,
			"tier": highest_tier,
			"status": "Home Cave T3 active: march thresholds can be changed from any province."
		}
	var start_province_id: int = get_player_turn_start_province_id()
	var start_index: int = find_persistence_index_by_id(start_province_id)
	if start_index == -1:
		return {
			"can_set": false,
			"tier": highest_tier,
			"status": "March threshold controls locked: no turn-start province is set."
		}
	var start_state: Dictionary = _main._province_persistence[start_index]
	var start_name: String = get_province_display_name(start_province_id, start_state)
	var start_tier: int = get_home_cave_tier(start_state)
	if start_tier >= 2:
		return {
			"can_set": true,
			"tier": start_tier,
			"status": "Home Cave T%d active in %s: march thresholds affect all provinces until changed." % [start_tier, start_name]
		}
	if start_tier >= 1:
		return {
			"can_set": false,
			"tier": start_tier,
			"status": "Home Cave T1 in %s keeps current troop-control behavior. Upgrade to T2 to set march thresholds." % start_name
		}
	return {
		"can_set": false,
		"tier": highest_tier,
		"status": "March threshold controls locked: %s has no Home Cave. Start in a province with Home Cave T2, or upgrade one to T3." % start_name
	}


func get_player_troop_control_status_text() -> String:
	if _main == null:
		return "Troop control unavailable: no active campaign."
	var start_province_id: int = get_player_turn_start_province_id()
	var start_index: int = find_persistence_index_by_id(start_province_id)
	if start_index == -1:
		return "Troop control unavailable: no turn-start province is set."
	var start_state: Dictionary = _main._province_persistence[start_index]
	var start_name: String = get_province_display_name(start_province_id, start_state)
	if _get_player_highest_home_cave_tier() >= 3:
		return "Global troop control active: Home Cave T3 allows troop orders from any player province."
	if province_has_command_center(start_state):
		return "Global troop control active: %s has a Home Cave." % start_name
	return "Only local troops controllable: %s has no Home Cave." % start_name


func get_player_troop_control_denial_text(target_province_id: int) -> String:
	var status_text: String = get_player_troop_control_status_text()
	if target_province_id < 0:
		return "%s Start inside a controllable province." % status_text
	var index: int = find_persistence_index_by_id(target_province_id)
	var target_name: String = "Province %d" % target_province_id
	if index != -1:
		target_name = get_province_display_name(target_province_id, _main._province_persistence[index])
	return "%s %s is locked for direct troop control this turn." % [status_text, target_name]


func get_player_troop_order_max_count(source_province_id: int) -> int:
	if _main == null:
		return 0
	var source_index: int = find_persistence_index_by_id(source_province_id)
	if source_index == -1:
		return 0
	var source_state: Dictionary = _main._province_persistence[source_index]
	if get_relation_to_player_for_province_state(source_state) != RELATION_SELF:
		return 0
	if not can_player_control_troops_in_province(source_province_id):
		return 0
	return maxi(0, int(source_state.get("remaining_troops", 0)))


func build_player_troop_order_targets(source_province_id: int) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if _main == null:
		return targets
	var source_index: int = find_persistence_index_by_id(source_province_id)
	if source_index == -1:
		return targets
	var source_state: Dictionary = _main._province_persistence[source_index]
	if get_player_troop_order_max_count(source_province_id) <= 0:
		return targets
	for neighbor_id in normalize_neighbor_ids(source_state.get("neighbors", [])):
		var neighbor_index: int = find_persistence_index_by_id(neighbor_id)
		if neighbor_index == -1:
			continue
		var neighbor_state: Dictionary = _main._province_persistence[neighbor_index]
		targets.append({
			"id": neighbor_id,
			"label": "%s (%s)" % [get_province_display_name(neighbor_id, neighbor_state), get_province_owner_text(neighbor_state)]
		})
	return targets


func validate_player_troop_order(source_province_id: int, target_province_id: int, troop_count: int) -> Dictionary:
	if _main == null:
		return {"ok": false, "message": "Troop order unavailable: no active campaign."}
	var source_index: int = find_persistence_index_by_id(source_province_id)
	if source_index == -1:
		return {"ok": false, "message": "Troop order rejected: source province was not found."}
	var target_index: int = find_persistence_index_by_id(target_province_id)
	if target_index == -1:
		return {"ok": false, "message": "Troop order rejected: target province was not found."}
	var source_state: Dictionary = _main._province_persistence[source_index]
	if get_relation_to_player_for_province_state(source_state) != RELATION_SELF:
		return {"ok": false, "message": "Troop order rejected: source province is not player-controlled."}
	if not can_player_control_troops_in_province(source_province_id):
		return {"ok": false, "message": get_player_troop_control_denial_text(source_province_id)}
	var neighbors: Array[int] = normalize_neighbor_ids(source_state.get("neighbors", []))
	if not neighbors.has(target_province_id):
		return {"ok": false, "message": "Troop order rejected: destination must be adjacent to the source province."}
	var available_troops: int = maxi(0, int(source_state.get("remaining_troops", 0)))
	if troop_count <= 0:
		return {"ok": false, "message": "Troop order rejected: choose at least 1 troop."}
	if troop_count > available_troops:
		return {"ok": false, "message": "Troop order rejected: only %d troop%s available." % [available_troops, "" if available_troops == 1 else "s"]}
	var target_state: Dictionary = _main._province_persistence[target_index]
	return {
		"ok": true,
		"message": "Sending %d troop%s from %s to %s." % [
			troop_count,
			"" if troop_count == 1 else "s",
			get_province_display_name(source_province_id, source_state),
			get_province_display_name(target_province_id, target_state)
		]
	}


func get_province_economy_debug_lines(province_state: Dictionary) -> Array[String]:
	normalize_province_economy_state(province_state)
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var rates: Dictionary = province_state.get(PROVINCE_RATES_KEY, {})
	var accommodation: Dictionary = province_state.get(PROVINCE_ACCOMMODATION_KEY, {})
	return [
		"Pop Nat:%.1f Out:%.1f" % [float(population.get(POPULATION_NATIVES_KEY, 0.0)), float(population.get(POPULATION_OUTLANDER_KEY, 0.0))],
		"Happy Nat:%.0f Out:%.0f" % [float(happiness.get(POPULATION_NATIVES_KEY, 0.0)), float(happiness.get(POPULATION_OUTLANDER_KEY, 0.0))],
		"Food %.1f/%.1f (%+.1f)" % [float(food.get("production", 0.0)), float(food.get("demand", 0.0)), float(food.get("surplus", 0.0))],
		"Rates G:%.2f R:%.2f C:%.2f I:%.2f" % [float(rates.get("growth_factor", 0.0)), float(rates.get("recruitment", 0.0)), float(rates.get("construction", 0.0)), float(rates.get("income", 0.0))],
		"Acc Nat:%.0f Out:%.0f Slots:%d/%d" % [float(accommodation.get(ACCOMMODATION_NATIVE_CEILING_KEY, 0.0)), float(accommodation.get(ACCOMMODATION_OUTLANDER_CEILING_KEY, 0.0)), calculate_occupied_building_slots(province_state), get_province_building_capacity(province_state)]
	]


func get_province_economy_warning_lines(province_state: Dictionary) -> Array[String]:
	normalize_province_economy_state(province_state)
	var lines: Array[String] = []
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var accommodation: Dictionary = province_state.get(PROVINCE_ACCOMMODATION_KEY, {})
	var status: Dictionary = province_state.get(PROVINCE_STATUS_KEY, {})
	var natives: float = float(population.get(POPULATION_NATIVES_KEY, 0.0))
	var outlanders: float = float(population.get(POPULATION_OUTLANDER_KEY, 0.0))
	var native_ceiling: float = float(accommodation.get(ACCOMMODATION_NATIVE_CEILING_KEY, 0.0))
	var outlander_ceiling: float = float(accommodation.get(ACCOMMODATION_OUTLANDER_CEILING_KEY, 0.0))
	var default_happiness: float = get_province_tuning_value("default_happiness")
	var native_happiness: float = float(happiness.get(POPULATION_NATIVES_KEY, default_happiness))
	var outlander_happiness: float = float(happiness.get(POPULATION_OUTLANDER_KEY, default_happiness))
	if float(food.get("surplus", 0.0)) < 0.0:
		lines.append("Food deficit")
	if natives > native_ceiling or outlanders > outlander_ceiling:
		lines.append("Overcrowded")
	if native_happiness < get_province_tuning_value("low_happiness_warning_threshold") or outlander_happiness < get_province_tuning_value("low_happiness_warning_threshold"):
		lines.append("Low happiness")
	if native_happiness <= 10.0 or outlander_happiness <= 10.0 or bool(status.get("revolt_warning", false)):
		lines.append("Revolt risk")
	return lines


func _format_active_construction_panel_text(province_state: Dictionary) -> String:
	normalize_province_economy_state(province_state)
	var active: Dictionary = province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {})
	if active.is_empty():
		return "Build: Idle"
	if String(active.get("project_type", "")) == CONSTRUCTION_PROJECT_RECRUITMENT:
		return "Build: Recruitment focus"
	if String(active.get("project_type", "")) == CONSTRUCTION_PROJECT_REPAIR:
		var repair_progress: float = float(active.get("progress", 0.0))
		var repair_required: float = maxf(1.0, float(active.get("required_progress", 1.0)))
		return "Repair: %.0f%%" % clampf((repair_progress / repair_required) * 100.0, 0.0, 999.0)
	var building_type: String = get_canonical_building_type(String(active.get("building_type", "")))
	var catalog: Dictionary = BUILDING_CATALOG.get(building_type, {})
	var display_name: String = String(catalog.get("display_name", building_type.capitalize()))
	var progress: float = float(active.get("progress", 0.0))
	var required: float = maxf(1.0, float(active.get("required_progress", 1.0)))
	if String(active.get("project_type", "")) == CONSTRUCTION_PROJECT_DEMOLISH:
		return "Demolish: %s %.0f%%" % [display_name, clampf((progress / required) * 100.0, 0.0, 999.0)]
	return "Build: %s %.0f%%" % [display_name, clampf((progress / required) * 100.0, 0.0, 999.0)]


func get_province_economy_panel_text(province_state: Dictionary) -> String:
	normalize_province_economy_state(province_state)
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var rates: Dictionary = province_state.get(PROVINCE_RATES_KEY, {})
	var accommodation: Dictionary = province_state.get(PROVINCE_ACCOMMODATION_KEY, {})
	var natives: float = float(population.get(POPULATION_NATIVES_KEY, 0.0))
	var outlanders: float = float(population.get(POPULATION_OUTLANDER_KEY, 0.0))
	var native_ceiling: float = float(accommodation.get(ACCOMMODATION_NATIVE_CEILING_KEY, 0.0))
	var outlander_ceiling: float = float(accommodation.get(ACCOMMODATION_OUTLANDER_CEILING_KEY, 0.0))
	var warning_lines: Array[String] = get_province_economy_warning_lines(province_state)
	var warning_text: String = ""
	if not warning_lines.is_empty():
		warning_text = "Warn: %s\n" % ", ".join(warning_lines)
	var control_text: String = get_player_troop_control_status_text() if get_relation_to_player_for_province_state(province_state) == RELATION_SELF else ""
	if control_text != "":
		control_text = "\n%s" % control_text
	return "%sFood:%+.1f  Pop:%.0f/%.0f %.0f/%.0f\nHappy:%.0f/%.0f  G:%.2f R:%.2f C:%.2f I:%.2f\n%s%s" % [
		warning_text,
		float(food.get("surplus", 0.0)),
		natives,
		native_ceiling,
		outlanders,
		outlander_ceiling,
		float(happiness.get(POPULATION_NATIVES_KEY, 0.0)),
		float(happiness.get(POPULATION_OUTLANDER_KEY, 0.0)),
		float(rates.get("growth_factor", 0.0)),
		float(rates.get("recruitment", 0.0)),
		float(rates.get("construction", 0.0)),
		float(rates.get("income", 0.0)),
		_format_active_construction_panel_text(province_state),
		control_text
	]


func _format_typed_building_debug_lines(province_state: Dictionary) -> Array[String]:
	normalize_province_economy_state(province_state)
	var lines: Array[String] = []
	var buildings: Dictionary = province_state.get(PROVINCE_BUILDINGS_KEY, {})
	for building_type in BUILDING_CATALOG.keys():
		var definition: Dictionary = BUILDING_CATALOG.get(building_type, {})
		var tiers: Dictionary = buildings.get(building_type, {})
		var tier_parts: Array[String] = []
		for tier in [1, 2, 3]:
			var count: int = maxi(0, int(tiers.get(str(tier), 0)))
			if count > 0:
				tier_parts.append("T%d x%d" % [tier, count])
		if tier_parts.is_empty():
			continue
		lines.append("%s: %s" % [String(definition.get("display_name", building_type)), ", ".join(tier_parts)])
	if lines.is_empty():
		lines.append("None")
	return lines


func _format_active_construction_debug_text(province_state: Dictionary) -> String:
	normalize_province_economy_state(province_state)
	var project: Dictionary = province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {})
	if project.is_empty():
		return "None"
	if String(project.get("project_type", "")) == CONSTRUCTION_PROJECT_RECRUITMENT:
		return "Recruitment focus: %.1f construction points banked" % float(project.get("progress", 0.0))
	if String(project.get("project_type", "")) == CONSTRUCTION_PROJECT_REPAIR:
		return "Repair structural building: %.1f / %.1f" % [
			float(project.get("progress", 0.0)),
			float(project.get("required_progress", 1.0))
		]
	var building_type: String = get_canonical_building_type(String(project.get("building_type", "")))
	var definition: Dictionary = BUILDING_CATALOG.get(building_type, {})
	var display_name: String = String(definition.get("display_name", building_type))
	return "%s %s T%d: %.1f / %.1f" % [
		String(project.get("project_type", "")).capitalize(),
		display_name,
		int(project.get("target_tier", 1)),
		float(project.get("progress", 0.0)),
		float(project.get("required_progress", 1.0))
	]


func build_province_economy_debug_text(province_id: int) -> String:
	if _main == null:
		return "Province economy debug unavailable: no active main node."
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return "Province economy debug unavailable: province %d was not found." % province_id
	var province_state: Dictionary = _main._province_persistence[index]
	normalize_province_economy_state(province_state)
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var rates: Dictionary = province_state.get(PROVINCE_RATES_KEY, {})
	var accommodation: Dictionary = province_state.get(PROVINCE_ACCOMMODATION_KEY, {})
	var status: Dictionary = province_state.get(PROVINCE_STATUS_KEY, {})
	var lines: Array[String] = []
	lines.append("%s (Province %d)" % [get_province_display_name(province_id, province_state), province_id])
	lines.append("Owner: %s | Faction: %d" % [get_province_owner_text(province_state), int(province_state.get("faction_id", 0))])
	lines.append("Troops / typed buildings: %d troops, %d buildings, cap %d" % [maxi(0, int(province_state.get("remaining_troops", 0))), calculate_occupied_building_slots(province_state), get_province_building_capacity(province_state)])
	lines.append("")
	lines.append("Population")
	lines.append("  Natives: %.2f" % float(population.get(POPULATION_NATIVES_KEY, 0.0)))
	lines.append("  Outlanders: %.2f" % float(population.get(POPULATION_OUTLANDER_KEY, 0.0)))
	lines.append("")
	lines.append("Happiness")
	lines.append("  Natives: %.2f / 100" % float(happiness.get(POPULATION_NATIVES_KEY, 0.0)))
	lines.append("  Outlanders: %.2f / 100" % float(happiness.get(POPULATION_OUTLANDER_KEY, 0.0)))
	lines.append("  Revolt warning: %s" % str(bool(status.get("revolt_warning", false))))
	lines.append("")
	lines.append("Food")
	lines.append("  Production: %.2f" % float(food.get("production", 0.0)))
	lines.append("  Demand: %.2f" % float(food.get("demand", 0.0)))
	lines.append("  Surplus: %+.2f" % float(food.get("surplus", 0.0)))
	lines.append("")
	lines.append("Accommodation")
	lines.append("  Native ceiling: %.2f" % float(accommodation.get(ACCOMMODATION_NATIVE_CEILING_KEY, 0.0)))
	lines.append("  Outlander ceiling: %.2f" % float(accommodation.get(ACCOMMODATION_OUTLANDER_CEILING_KEY, 0.0)))
	lines.append("")
	lines.append("Rates")
	lines.append("  Growth factor: %.3f" % float(rates.get("growth_factor", 0.0)))
	lines.append("  Recruitment: %.3f / tick" % float(rates.get("recruitment", 0.0)))
	lines.append("  Construction: %.3f / tick" % float(rates.get("construction", 0.0)))
	lines.append("  Income: %.3f / tick" % float(rates.get("income", 0.0)))
	lines.append("")
	lines.append("Typed Buildings (%d / %d slots)" % [calculate_occupied_building_slots(province_state), get_province_building_capacity(province_state)])
	for building_line in _format_typed_building_debug_lines(province_state):
		lines.append("  %s" % building_line)
	lines.append("")
	lines.append("Active Construction")
	lines.append("  %s" % _format_active_construction_debug_text(province_state))
	lines.append("")
	lines.append("Status")
	lines.append("  Recently conquered ticks: %d" % int(status.get("recently_conquered_ticks", 0)))
	lines.append("  Home cave present: %s" % str(province_has_command_center(province_state)))
	lines.append("  Player can control troops here: %s" % str(can_player_control_troops_in_province(province_id)))
	lines.append("  Control rule: %s" % get_player_troop_control_status_text())
	return "\n".join(lines)



func _get_trimmed_ui_texture(path: String) -> Texture2D:
	if _province_ui_texture_cache.has(path):
		return _province_ui_texture_cache[path]
	var loaded = load(path)
	if loaded == null or not (loaded is Texture2D):
		_province_ui_texture_cache[path] = null
		return null
	var texture: Texture2D = loaded as Texture2D
	var trimmed: Texture2D = texture
	var image: Image = texture.get_image()
	if image != null:
		var used_rect: Rect2i = image.get_used_rect()
		if used_rect.size.x > 0 and used_rect.size.y > 0 and (used_rect.position.x != 0 or used_rect.position.y != 0 or used_rect.size.x != image.get_width() or used_rect.size.y != image.get_height()):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(float(used_rect.position.x), float(used_rect.position.y), float(used_rect.size.x), float(used_rect.size.y))
			trimmed = atlas
	_province_ui_texture_cache[path] = trimmed
	return trimmed


func _get_province_panel_icon_texture(path: String) -> Texture2D:
	if LevelConfig.PROVINCE_INFO_PANEL_TRIM_ICON_TEXTURES:
		return _get_trimmed_ui_texture(path)
	var loaded = load(path)
	return loaded as Texture2D if loaded is Texture2D else null


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


func _configure_panel_icon(icon: TextureRect, texture_path: String, position: Vector2, size: Vector2, visual_scale: float = 1.0) -> void:
	if icon == null:
		return
	icon.texture = _get_province_panel_icon_texture(texture_path)
	icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_layout_province_panel_icon(icon, position, size, visual_scale)


func _ensure_province_panel_texture_rect(panel_root: Control, node_name: String) -> TextureRect:
	if panel_root == null:
		return null
	var rect: TextureRect = panel_root.get_node_or_null(node_name) as TextureRect
	if rect == null:
		rect = TextureRect.new()
		rect.name = node_name
		panel_root.add_child(rect)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _configure_province_metric_icon(panel_root: Control, icon_name: String, texture_path: String, position: Vector2, slot_size: Vector2, visual_scale: float = 1.0, visible: bool = true) -> TextureRect:
	var icon: TextureRect = _ensure_province_panel_texture_rect(panel_root, icon_name)
	if icon != null:
		if texture_path == "":
			icon.texture = null
			_layout_province_panel_icon(icon, position, slot_size, visual_scale)
		else:
			_configure_panel_icon(icon, texture_path, position, slot_size, visual_scale)
		icon.clip_contents = true
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.visible = visible and texture_path != ""
	return icon


func _configure_province_metric_failure_x(panel_root: Control, icon_name: String, position: Vector2, slot_size: Vector2, visible: bool) -> void:
	var icon: TextureRect = _configure_province_metric_icon(panel_root, icon_name, PROVINCE_ICON_FAILURE_X_TEXTURE_PATH, position, slot_size, 0.88, visible)
	if icon != null:
		icon.modulate = Color(1.0, 0.12, 0.08, 0.92)


func _get_active_construction_building_sprite_path(province_state: Dictionary) -> String:
	var project: Dictionary = province_state.get(PROVINCE_ACTIVE_CONSTRUCTION_KEY, {})
	if project.is_empty():
		return ""
	var project_type: String = String(project.get("project_type", "")).strip_edges()
	if project_type == "" or project_type == CONSTRUCTION_PROJECT_RECRUITMENT:
		return ""
	var building_type: String = get_canonical_building_type(String(project.get("building_type", "")))
	if building_type == "" or not BUILDING_CATALOG.has(building_type):
		return ""
	return get_building_sprite_path(building_type)


func _refresh_province_metric_bar(panel_root: Control, province_state: Dictionary, panel_size: Vector2) -> void:
	if panel_root == null:
		return
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var accommodation: Dictionary = province_state.get(PROVINCE_ACCOMMODATION_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var natives: float = float(population.get(POPULATION_NATIVES_KEY, 0.0))
	var outlanders: float = float(population.get(POPULATION_OUTLANDER_KEY, 0.0))
	var native_ceiling: float = float(accommodation.get(ACCOMMODATION_NATIVE_CEILING_KEY, get_province_tuning_value("base_native_accommodation")))
	var outlander_ceiling: float = float(accommodation.get(ACCOMMODATION_OUTLANDER_CEILING_KEY, get_province_tuning_value("base_outlander_accommodation")))
	var native_happiness: float = float(happiness.get(POPULATION_NATIVES_KEY, get_province_tuning_value("default_happiness")))
	var outlander_happiness: float = float(happiness.get(POPULATION_OUTLANDER_KEY, get_province_tuning_value("default_happiness")))
	var food_failed: bool = float(food.get("surplus", 0.0)) < 0.0
	var accommodation_failed: bool = natives > native_ceiling or outlanders > outlander_ceiling
	var happiness_failed: bool = native_happiness < 30.0 or outlander_happiness < 30.0
	var slot_size := Vector2(27.0, 27.0)
	var slot_gap: float = 16.0
	var total_width: float = slot_size.x * 4.0 + slot_gap * 3.0
	var start_x: float = maxf(4.0, (panel_size.x - total_width) * 0.5)
	var top_y: float = 4.0
	var food_pos := Vector2(start_x, top_y)
	var accommodation_pos := Vector2(start_x + slot_size.x + slot_gap, top_y)
	var happiness_pos := Vector2(start_x + (slot_size.x + slot_gap) * 2.0, top_y)
	var construction_pos := Vector2(start_x + (slot_size.x + slot_gap) * 3.0, top_y)
	_configure_province_metric_icon(panel_root, PROVINCE_INFO_PANEL_METRIC_FOOD_ICON_NAME, PROVINCE_ICON_FOOD_SURPLUS_TEXTURE_PATH, food_pos, slot_size, 0.92)
	_configure_province_metric_failure_x(panel_root, PROVINCE_INFO_PANEL_METRIC_FOOD_X_NAME, food_pos, slot_size, food_failed)
	_configure_province_metric_icon(panel_root, PROVINCE_INFO_PANEL_METRIC_ACCOMMODATION_ICON_NAME, PROVINCE_ICON_NATIVE_TEXTURE_PATH, accommodation_pos, slot_size, 0.92)
	_configure_province_metric_failure_x(panel_root, PROVINCE_INFO_PANEL_METRIC_ACCOMMODATION_X_NAME, accommodation_pos, slot_size, accommodation_failed)
	_configure_province_metric_icon(panel_root, PROVINCE_INFO_PANEL_METRIC_HAPPINESS_ICON_NAME, PROVINCE_ICON_HAPPINESS_TEXTURE_PATH, happiness_pos, slot_size, 0.92)
	_configure_province_metric_failure_x(panel_root, PROVINCE_INFO_PANEL_METRIC_HAPPINESS_X_NAME, happiness_pos, slot_size, happiness_failed)
	var construction_sprite_path: String = _get_active_construction_building_sprite_path(province_state)
	_configure_province_metric_icon(panel_root, PROVINCE_INFO_PANEL_METRIC_CONSTRUCTION_ICON_NAME, construction_sprite_path, construction_pos, slot_size, 0.96, construction_sprite_path != "")


func _get_province_info_panel_size() -> Vector2:
	var desired_width: float = maxf(64.0, LevelConfig.PROVINCE_INFO_PANEL_DESIRED_WIDTH)
	var fallback_height: float = maxf(48.0, LevelConfig.PROVINCE_INFO_PANEL_FALLBACK_HEIGHT)
	var economy_height: float = 166.0
	var panel_texture: Texture2D = _get_trimmed_ui_texture(PROVINCE_INFO_PANEL_TEXTURE_PATH)
	if panel_texture == null:
		return Vector2(desired_width, maxf(fallback_height, economy_height))
	var texture_size: Vector2 = panel_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2(desired_width, maxf(fallback_height, economy_height))
	var scaled_height: float = desired_width * (texture_size.y / texture_size.x)
	return Vector2(desired_width, maxf(economy_height, maxf(fallback_height, scaled_height)))


func _get_province_info_panel_root(province_node: Node) -> Control:
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is Control and String(child.name) == PROVINCE_INFO_PANEL_ROOT_NAME:
			return child as Control
	return null


func _get_province_owner_badge_texture_path(province_state: Dictionary) -> String:
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	match province_type:
		LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return PROVINCE_OWNER_BADGE_FRIENDLY_TEXTURE_PATH
		LevelConfig.PROVINCE_TYPE_ENEMY:
			return PROVINCE_OWNER_BADGE_ENEMY_TEXTURE_PATH
		_:
			return PROVINCE_OWNER_BADGE_NEUTRAL_TEXTURE_PATH

func _get_province_owner_badge_fill_color(province_state: Dictionary) -> Color:
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var faction_id: int = int(province_state.get("faction_id", 0))
	match province_type:
		LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return LevelConfig.color_with_alpha(LevelConfig.PROVINCE_FRIENDLY_FILL_RGB, 1.0)
		LevelConfig.PROVINCE_TYPE_ENEMY:
			return LevelConfig.color_with_alpha(_get_enemy_faction_display_color(faction_id), 1.0)
		_:
			return LevelConfig.color_with_alpha(LevelConfig.PROVINCE_NEUTRAL_BORDER_COLOR, 1.0)


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


func _apply_province_owner_badge_fill(icon: TextureRect, province_state: Dictionary) -> void:
	if icon == null:
		return
	var material := icon.material as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		icon.material = material
	material.shader = _get_province_owner_badge_fill_shader()
	material.set_shader_parameter("fill_color", _get_province_owner_badge_fill_color(province_state))


func _get_province_biome_texture_path(province_state: Dictionary) -> String:
	match get_province_engagement_map_type(province_state):
		LevelConfig.ENGAGEMENT_MAP_TYPE_JUNGLE:
			return PROVINCE_ICON_BIOME_JUNGLE_TEXTURE_PATH
		LevelConfig.ENGAGEMENT_MAP_TYPE_ROCK_OUTCROPPING:
			return PROVINCE_ICON_BIOME_ROCK_TEXTURE_PATH
		LevelConfig.ENGAGEMENT_MAP_TYPE_SETTLEMENT:
			return PROVINCE_ICON_BIOME_SETTLEMENT_TEXTURE_PATH
		_:
			return PROVINCE_ICON_BIOME_NORMAL_TEXTURE_PATH


func _get_province_panel_owner_line(province_state: Dictionary) -> String:
	var parts: Array[String] = []
	if is_target_province_state(province_state):
		parts.append(LevelConfig.TARGET_PROVINCE_LABEL_TEXT)
	parts.append(get_province_owner_text(province_state))
	var invading_troops: int = int(province_state.get("invading_troops", 0))
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
		parts.append("Inv %d" % invading_troops)
	return " - ".join(parts)


func _format_province_card_count(value: float) -> String:
	var safe_value: float = maxf(0.0, value)
	if safe_value >= 1000.0:
		return "%.1fk" % (safe_value / 1000.0)
	return "%.0f" % safe_value


func _format_province_card_happiness(value: float) -> String:
	return "%.0f%%" % clampf(value, 0.0, 100.0)


func _format_province_card_food_surplus(value: float) -> String:
	return "%+.1f" % value


func _configure_panel_label(label: Label, font_size: int, font_color: Color, h_align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if label == null:
		return
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.horizontal_alignment = h_align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_constant_override("outline_size", max(1, LevelConfig.PROVINCE_INFO_OUTLINE_SIZE))
	label.add_theme_color_override("font_outline_color", LevelConfig.PROVINCE_INFO_OUTLINE_COLOR)


func _get_province_info_panel_bg_modulate(province_state: Dictionary) -> Color:
	var panel_alpha: float = LevelConfig.get_province_info_panel_bg_alpha()
	if is_boss_home_province_state(province_state):
		return Color(1.0, 0.94, 0.94, panel_alpha)
	if is_target_province_state(province_state):
		return Color(1.0, 0.98, 0.92, panel_alpha)
	return Color(1.0, 1.0, 1.0, panel_alpha)


func _refresh_province_info_panel(panel_root: Control, province_id: int, province_state: Dictionary) -> void:
	if panel_root == null:
		return
	normalize_province_economy_state(province_state)
	var panel_size: Vector2 = _get_province_info_panel_size()
	panel_root.size = panel_size

	var bg: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_BG_NAME) as TextureRect
	if bg != null:
		bg.texture = _get_trimmed_ui_texture(PROVINCE_INFO_PANEL_TEXTURE_PATH)
		bg.position = Vector2.ZERO
		bg.size = panel_size
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.modulate = _get_province_info_panel_bg_modulate(province_state)

	_refresh_province_metric_bar(panel_root, province_state, panel_size)
	var content_offset := Vector2(0.0, 30.0)
	var owner_badge: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_OWNER_BADGE_NAME) as TextureRect
	_configure_panel_icon(owner_badge, _get_province_owner_badge_texture_path(province_state), LevelConfig.PROVINCE_INFO_PANEL_OWNER_BADGE_POS + content_offset, LevelConfig.PROVINCE_INFO_PANEL_OWNER_BADGE_SLOT_SIZE, LevelConfig.PROVINCE_INFO_PANEL_OWNER_BADGE_SCALE)
	_apply_province_owner_badge_fill(owner_badge, province_state)

	var biome_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_BIOME_ICON_NAME) as TextureRect
	if biome_icon != null:
		biome_icon.visible = false

	var row_y: float = 90.0
	var row_gap: float = 32.0
	var stat_icon_size := Vector2(31.0, 31.0)
	var happiness_icon_size := Vector2(28.0, 28.0)
	var food_icon_size := Vector2(28.0, 28.0)
	var primary_icon_x: float = 17.0
	var primary_label_x: float = 55.0
	var happiness_icon_x: float = 104.0
	var happiness_label_x: float = 137.0
	var food_icon_x: float = panel_size.x - 64.0
	var food_label_x: float = panel_size.x - 37.0
	var primary_label_size := Vector2(48.0, 27.0)
	var happiness_label_size := Vector2(50.0, 27.0)

	var troops_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_TROOPS_ICON_NAME) as TextureRect
	_configure_panel_icon(troops_icon, PROVINCE_ICON_NATIVE_TEXTURE_PATH, Vector2(primary_icon_x, row_y), stat_icon_size, 1.0)
	if troops_icon != null:
		troops_icon.visible = true

	var buildings_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_BUILDINGS_ICON_NAME) as TextureRect
	if buildings_icon != null:
		_configure_panel_icon(buildings_icon, PROVINCE_ICON_HAPPINESS_TEXTURE_PATH, Vector2(happiness_icon_x, row_y + 1.0), happiness_icon_size, 1.0)
		buildings_icon.visible = true

	var gold_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_GOLD_ICON_NAME) as TextureRect
	_configure_panel_icon(gold_icon, PROVINCE_ICON_FOOD_SURPLUS_TEXTURE_PATH, Vector2(food_icon_x, 37.0), food_icon_size, 1.0)
	if gold_icon != null:
		gold_icon.visible = true

	var free_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_FREE_ICON_NAME) as TextureRect
	if free_icon != null:
		_configure_panel_icon(free_icon, PROVINCE_ICON_HAPPINESS_TEXTURE_PATH, Vector2(happiness_icon_x, row_y + row_gap + 1.0), happiness_icon_size, 1.0)
		free_icon.visible = true

	var cap_icon: TextureRect = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_CAP_ICON_NAME) as TextureRect
	_configure_panel_icon(cap_icon, PROVINCE_ICON_OUTLANDER_TEXTURE_PATH, Vector2(primary_icon_x, row_y + row_gap), stat_icon_size, 1.0)
	if cap_icon != null:
		cap_icon.visible = true

	var owner_color: Color = LevelConfig.PROVINCE_INFO_TEXT_COLOR
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if is_boss_home_province_state(province_state):
		owner_color = BOSS_HOME_INFO_TEXT_COLOR
	elif province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		owner_color = Color(0.88, 0.98, 0.88, 1.0)
	elif province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		owner_color = Color(1.0, 0.90, 0.82, 1.0)

	var owner_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_OWNER_LABEL_NAME) as Label
	if owner_label != null:
		owner_label.position = LevelConfig.PROVINCE_INFO_PANEL_OWNER_LABEL_POS + content_offset
		owner_label.size = Vector2(maxf(24.0, panel_size.x - LevelConfig.PROVINCE_INFO_PANEL_OWNER_LABEL_POS.x - LevelConfig.PROVINCE_INFO_PANEL_OWNER_LABEL_RIGHT_MARGIN), 16.0)
		_configure_panel_label(owner_label, max(11, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE - 5), owner_color, HORIZONTAL_ALIGNMENT_LEFT)
		owner_label.text = _get_province_panel_owner_line(province_state)

	var name_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_NAME_LABEL_NAME) as Label
	if name_label != null:
		name_label.position = LevelConfig.PROVINCE_INFO_PANEL_NAME_LABEL_POS + content_offset
		name_label.size = Vector2(maxf(24.0, panel_size.x - LevelConfig.PROVINCE_INFO_PANEL_NAME_LABEL_POS.x - LevelConfig.PROVINCE_INFO_PANEL_NAME_LABEL_RIGHT_MARGIN), 24.0)
		_configure_panel_label(name_label, max(13, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE - 1), LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		name_label.text = get_province_display_name(province_id, province_state)

	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	var natives: float = float(population.get(POPULATION_NATIVES_KEY, 0.0))
	var outlanders: float = float(population.get(POPULATION_OUTLANDER_KEY, 0.0))
	var native_happiness: float = float(happiness.get(POPULATION_NATIVES_KEY, get_province_tuning_value("default_happiness")))
	var outlander_happiness: float = float(happiness.get(POPULATION_OUTLANDER_KEY, get_province_tuning_value("default_happiness")))
	var food_surplus: float = float(food.get("surplus", 0.0))
	var stat_font_size: int = max(17, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE + 3)
	var food_font_size: int = max(13, LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE - 1)

	var troops_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_TROOPS_LABEL_NAME) as Label
	if troops_label != null:
		troops_label.visible = true
		troops_label.position = Vector2(primary_label_x, row_y + 2.0)
		troops_label.size = primary_label_size
		_configure_panel_label(troops_label, stat_font_size, LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		troops_label.text = _format_province_card_count(natives)

	var buildings_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_BUILDINGS_LABEL_NAME) as Label
	if buildings_label != null:
		buildings_label.visible = true
		buildings_label.position = Vector2(happiness_label_x, row_y + 2.0)
		buildings_label.size = happiness_label_size
		_configure_panel_label(buildings_label, stat_font_size, LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		buildings_label.text = _format_province_card_happiness(native_happiness)

	var gold_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_GOLD_LABEL_NAME) as Label
	if gold_label != null:
		gold_label.visible = true
		gold_label.position = Vector2(food_label_x, 40.0)
		gold_label.size = Vector2(36.0, 20.0)
		_configure_panel_label(gold_label, food_font_size, LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		gold_label.text = _format_province_card_food_surplus(food_surplus)

	var free_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_FREE_LABEL_NAME) as Label
	if free_label != null:
		free_label.visible = true
		free_label.position = Vector2(happiness_label_x, row_y + row_gap + 2.0)
		free_label.size = happiness_label_size
		_configure_panel_label(free_label, stat_font_size, LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		free_label.text = _format_province_card_happiness(outlander_happiness)

	var cap_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_CAP_LABEL_NAME) as Label
	if cap_label != null:
		cap_label.visible = true
		cap_label.position = Vector2(primary_label_x, row_y + row_gap + 2.0)
		cap_label.size = primary_label_size
		_configure_panel_label(cap_label, stat_font_size, LevelConfig.PROVINCE_INFO_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		cap_label.text = _format_province_card_count(outlanders)

	var economy_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_ECONOMY_LABEL_NAME) as Label
	if economy_label == null:
		economy_label = Label.new()
		economy_label.name = PROVINCE_INFO_PANEL_ECONOMY_LABEL_NAME
		panel_root.add_child(economy_label)
	economy_label.visible = false


func clamp_province_buildings_to_capacity(province_state: Dictionary) -> void:
	normalize_province_economy_state(province_state)
	sync_legacy_building_count_from_typed(province_state)


func get_province_variation_info_lines(province_state: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	lines.append("Income:%d  Slots:%d" % [get_province_total_income(province_state), calculate_remaining_building_slots(province_state)])
	lines.append("Cap:%d" % get_province_building_capacity(province_state))
	lines.append("Map:%s" % get_province_map_type_info_text(province_state))
	lines.append_array(get_province_economy_debug_lines(province_state))
	return lines


func _make_caltrop_spawn_seed(province_id: int, caltrop_id: int, gen_rng: RandomNumberGenerator = null) -> int:
	var salt: int = 0
	if gen_rng != null:
		salt = int(gen_rng.randi())
	var map_seed: int = 1
	var turn_number: int = 0
	if _main != null:
		map_seed = maxi(1, int(_main.map_seed))
		turn_number = maxi(0, int(_main.turn_number))
	var mixed: int = int(hash("%d|%d|%d|boss_caltrop|%d|%d" % [map_seed, turn_number, province_id, caltrop_id, salt]))
	mixed = mixed & 0x7fffffff
	return mixed if mixed != 0 else (province_id + 1) * 7919 + caltrop_id + 1


func get_province_caltrops(province_id: int) -> Array[Dictionary]:
	if _main == null or province_id < 0:
		return []
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return []
	return _normalize_caltrop_entries(_main._province_persistence[index].get(CALTROPS_KEY, []))


func count_active_province_caltrops(province_id: int) -> int:
	var count: int = 0
	for caltrop in get_province_caltrops(province_id):
		if not bool(caltrop.get("destroyed", false)):
			count += 1
	return count


func mark_caltrop_destroyed(province_id: int, caltrop_id: int) -> bool:
	if _main == null or province_id < 0 or caltrop_id < 0:
		return false
	var province_index: int = find_persistence_index_by_id(province_id)
	if province_index == -1:
		return false
	var province_state: Dictionary = _main._province_persistence[province_index]
	var caltrops: Array[Dictionary] = _normalize_caltrop_entries(province_state.get(CALTROPS_KEY, []))
	for i in range(caltrops.size()):
		if int(caltrops[i].get("id", -1)) != caltrop_id:
			continue
		if bool(caltrops[i].get("destroyed", false)):
			return false
		caltrops[i]["destroyed"] = true
		province_state[CALTROPS_KEY] = caltrops
		return true
	return false


func spawn_boss_caltrops(province_spawn_count: int, gen_rng: RandomNumberGenerator) -> Array[Dictionary]:
	var spawned: Array[Dictionary] = []
	if _main == null or province_spawn_count <= 0:
		return spawned
	var eligible_ids: Array[int] = []
	for province_state in _main._province_persistence:
		var province_id: int = int(province_state.get("id", -1))
		if province_id < 0:
			continue
		eligible_ids.append(province_id)
	if eligible_ids.is_empty():
		return spawned
	for _i in range(province_spawn_count):
		var spawnable_ids: Array[int] = []
		for candidate_id in eligible_ids:
			if count_active_province_caltrops(candidate_id) < get_province_tuning_int("max_active_caltrops_per_province"):
				spawnable_ids.append(candidate_id)
		if spawnable_ids.is_empty():
			break
		var province_id: int = spawnable_ids[gen_rng.randi_range(0, spawnable_ids.size() - 1)]
		var province_index: int = find_persistence_index_by_id(province_id)
		if province_index == -1:
			continue
		var province_state: Dictionary = _main._province_persistence[province_index]
		var caltrops: Array[Dictionary] = _normalize_caltrop_entries(province_state.get(CALTROPS_KEY, []))
		var next_id: int = 0
		for caltrop in caltrops:
			next_id = maxi(next_id, int(caltrop.get("id", -1)) + 1)
		var seed: int = _make_caltrop_spawn_seed(province_id, next_id, gen_rng)
		caltrops.append({
			"id": next_id,
			"seed": seed,
			"destroyed": false,
			"is_friendly": false
		})
		province_state[CALTROPS_KEY] = caltrops
		spawned.append({
			"province_id": province_id,
			"caltrop_id": next_id,
			"seed": seed
		})
	return spawned


func spawn_friendly_boss_caltrops(province_spawn_count: int, gen_rng: RandomNumberGenerator) -> Array[Dictionary]:
	var spawned: Array[Dictionary] = spawn_boss_caltrops(province_spawn_count, gen_rng)
	for i in range(spawned.size()):
		var entry: Dictionary = spawned[i]
		var province_id: int = int(entry.get("province_id", -1))
		var caltrop_id: int = int(entry.get("caltrop_id", -1))
		if province_id < 0 or caltrop_id < 0:
			continue
		var province_index: int = find_persistence_index_by_id(province_id)
		if province_index == -1:
			continue
		var province_state: Dictionary = _main._province_persistence[province_index]
		var caltrops: Array[Dictionary] = _normalize_caltrop_entries(province_state.get(CALTROPS_KEY, []))
		for j in range(caltrops.size()):
			if int(caltrops[j].get("id", -1)) != caltrop_id:
				continue
			caltrops[j]["is_friendly"] = true
			province_state[CALTROPS_KEY] = caltrops
			break
	return spawned



func find_persistence_index_by_id(province_id: int) -> int:
	if _main == null:
		return -1
	for i in range(_main._province_persistence.size()):
		if int(_main._province_persistence[i].get("id", -1)) == province_id:
			return i
	return -1


func get_province_faction(province_state: Dictionary) -> int:
	return int(province_state.get("faction_id", 0))


func is_boss_home_province_state(province_state: Dictionary) -> bool:
	return bool(province_state.get(BOSS_HOME_FLAG_KEY, false))


func is_boss_home_province_id(province_id: int) -> bool:
	if _main == null or province_id < 0:
		return false
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return false
	return is_boss_home_province_state(_main._province_persistence[index])


func get_boss_home_province_id_from_persistence() -> int:
	var boss_home_ids: Array[int] = get_boss_home_province_ids_from_persistence()
	if boss_home_ids.is_empty():
		return -1
	return int(boss_home_ids[0])


func get_boss_home_province_ids_from_persistence() -> Array[int]:
	var home_ids: Array[int] = []
	if _main == null:
		return home_ids
	for province_state in _main._province_persistence:
		if is_boss_home_province_state(province_state):
			home_ids.append(int(province_state.get("id", -1)))
	return home_ids


func _get_all_boss_faction_ids() -> Array[int]:
	var out: Array[int] = []
	if _main == null or _main.boss_system == null:
		return out
	if _main.boss_system.has_method("get_all_boss_faction_ids"):
		var ids_any: Variant = _main.boss_system.call("get_all_boss_faction_ids")
		if ids_any is Array:
			for id_any in ids_any:
				var faction_id: int = int(id_any)
				if faction_id > 0 and not out.has(faction_id):
					out.append(faction_id)
	if out.is_empty() and _main.boss_system.has_method("get_boss_faction_id"):
		var fallback_id: int = int(_main.boss_system.call("get_boss_faction_id"))
		if fallback_id > 0:
			out.append(fallback_id)
	return out


func is_boss_faction_province_state(province_state: Dictionary) -> bool:
	if _main == null or _main.boss_system == null:
		return false
	if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_ENEMY:
		return false
	var province_faction_id: int = int(province_state.get("faction_id", 0))
	for boss_faction_id in _get_all_boss_faction_ids():
		if province_faction_id == int(boss_faction_id):
			return true
	return false


func get_initial_province_counts(province_type: String) -> Dictionary:
	var campaign_enemy_troop_bonus_total: int = _get_campaign_enemy_troop_level_bonus_total()
	match province_type:
		LevelConfig.PROVINCE_TYPE_ENEMY:
			return {
				"remaining_buildings": LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_ENEMY),
				"remaining_troops": maxi(0, LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY) + campaign_enemy_troop_bonus_total),
				"faction_id": LevelConfig.ENEMY_FACTION_DEFAULT,
				"construction_progress": 0
			}
		LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return {
				"remaining_buildings": LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_FRIENDLY),
				"remaining_troops": LevelConfig.get_runtime_initial_province_friendly_troops_for_level(_get_campaign_current_level_progress(), _is_opening_gameplay_tutorial_active()),
				"faction_id": 0,
				"construction_progress": 0
			}
		_:
			return {
				"remaining_buildings": LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_NEUTRAL),
				"remaining_troops": LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_NEUTRAL),
				"faction_id": 0,
				"construction_progress": 0
			}



func _get_campaign_current_level_progress() -> int:
	if _main != null and _main.has_method("get_campaign_current_level_progress"):
		return maxi(1, int(_main.call("get_campaign_current_level_progress")))
	return 1


func _is_opening_gameplay_tutorial_active() -> bool:
	if _main != null and _main.has_method("is_opening_gameplay_tutorial_active"):
		return bool(_main.call("is_opening_gameplay_tutorial_active"))
	return false


func _get_campaign_enemy_troop_level_bonus_total() -> int:
	if _main == null:
		return 0
	if _main.has_method("get_campaign_enemy_troop_level_bonus_total"):
		return maxi(0, int(_main.call("get_campaign_enemy_troop_level_bonus_total")))
	return 0


func get_conquered_province_counts(province_type: String, province_state: Dictionary = {}) -> Dictionary:
	var counts: Dictionary = {}
	match province_type:
		LevelConfig.PROVINCE_TYPE_ENEMY:
			counts = {
				"remaining_buildings": 0,
				"remaining_troops": LevelConfig.get_conquered_province_troops(LevelConfig.PROVINCE_TYPE_ENEMY),
				"faction_id": LevelConfig.ENEMY_FACTION_DEFAULT,
				"construction_progress": 0
			}
		LevelConfig.PROVINCE_TYPE_FRIENDLY:
			counts = {
				"remaining_buildings": 0,
				"remaining_troops": LevelConfig.get_runtime_conquered_province_friendly_troops_for_level(_get_campaign_current_level_progress(), _is_opening_gameplay_tutorial_active()),
				"faction_id": 0,
				"construction_progress": 0
			}
		_:
			counts = {
				"remaining_buildings": 0,
				"remaining_troops": LevelConfig.get_conquered_province_troops(LevelConfig.PROVINCE_TYPE_NEUTRAL),
				"faction_id": 0,
				"construction_progress": 0
			}
	if not province_state.is_empty():
		normalize_province_economy_state(province_state)
		counts["remaining_buildings"] = get_captured_building_survivor_count(province_state)
	counts[PROVINCE_GOLD_PRODUCTION_KEY] = 0
	counts[PROVINCE_FREE_BUILDINGS_KEY] = 0
	counts[PROVINCE_BUILDING_CAPACITY_KEY] = get_province_building_capacity(province_state)
	counts[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = get_province_engagement_map_type(province_state)
	_copy_economy_fields_to_dictionary(province_state if not province_state.is_empty() else counts, counts)
	if not province_state.is_empty():
		set_typed_building_count_ceiling(counts, int(counts.get("remaining_buildings", 0)))
	counts["remaining_buildings"] = _calculate_occupied_building_slots_without_normalize(counts)
	return counts

func get_default_province_counts(province_type: String) -> Dictionary:
	return get_initial_province_counts(province_type)


func get_province_fill_node(province_node: Node) -> Polygon2D:
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is Polygon2D:
			return child as Polygon2D
	return null


func get_province_counts_label_node(province_node: Node) -> Label:
	if not is_instance_valid(province_node):
		return null
	var panel_root: Control = _get_province_info_panel_root(province_node)
	if panel_root != null:
		var name_label: Label = panel_root.get_node_or_null(PROVINCE_INFO_PANEL_NAME_LABEL_NAME) as Label
		if name_label != null:
			return name_label
	for child in province_node.get_children():
		if child is Label and child.name == "ProvinceCountsLabel":
			return child as Label
	return null

func get_province_counts_background_node(province_node: Node) -> Control:
	var panel_root: Control = _get_province_info_panel_root(province_node)
	if panel_root != null:
		return panel_root
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is ColorRect and child.name == "ProvinceCountsBackground":
			return child as ColorRect
	return null

func ensure_province_counts_draw_order(counts_bg: Control, counts_label: Label) -> void:
	if counts_bg != null:
		_set_canvas_item_layer(counts_bg, PROVINCE_COUNTS_BACKGROUND_Z_INDEX + 1, false)
	if counts_label != null and counts_bg == null:
		_set_canvas_item_layer(counts_label, PROVINCE_COUNTS_LABEL_Z_INDEX + 1, false)


func flash_province_faction_fill_if_visible(province_id: int, flash_seconds: float = 1.0) -> void:
	if _main == null or province_id < 0:
		return
	var province_node: Node = _get_cached_province_node_by_id(province_id)
	if province_node == null or not is_instance_valid(province_node):
		return
	var fill: Polygon2D = get_province_fill_node(province_node)
	if fill == null:
		return
	var duration: float = maxf(0.05, flash_seconds)
	var base_color: Color = fill.color
	if fill.has_meta("province_fill_flash_base_color"):
		var stored_base_variant: Variant = fill.get_meta("province_fill_flash_base_color")
		if stored_base_variant is Color:
			base_color = stored_base_variant as Color
		else:
			fill.remove_meta("province_fill_flash_base_color")
	else:
		fill.set_meta("province_fill_flash_base_color", base_color)
	var existing_tween: Variant = fill.get_meta("province_fill_flash_tween", null) if fill.has_meta("province_fill_flash_tween") else null
	if existing_tween is Tween:
		var tween_to_kill: Tween = existing_tween as Tween
		if tween_to_kill != null and is_instance_valid(tween_to_kill):
			tween_to_kill.kill()
	fill.color = base_color
	var restore_tween: Tween = _main.create_tween()
	fill.set_meta("province_fill_flash_tween", restore_tween)
	var flash_color: Color = base_color
	flash_color.a = 1.0
	fill.color = flash_color
	restore_tween.tween_property(fill, "color", base_color, duration)
	restore_tween.tween_callback(func() -> void:
		if is_instance_valid(fill):
			fill.color = base_color
			if fill.has_meta("province_fill_flash_tween"):
				fill.remove_meta("province_fill_flash_tween")
			if fill.has_meta("province_fill_flash_base_color"):
				fill.remove_meta("province_fill_flash_base_color")
	)


func get_province_target_overlay_node(province_node: Node) -> Polygon2D:
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is Polygon2D and child.name == "ProvinceTargetOverlay":
			return child as Polygon2D
	return null


func _get_locked_province_pattern_texture() -> Texture2D:
	var cell_radius: int = LevelConfig.get_province_launch_pattern_cell_size()
	var line_thickness: int = LevelConfig.get_province_launch_pattern_line_thickness()
	if _locked_province_pattern_texture != null and _locked_province_pattern_texture_cell_size == cell_radius and _locked_province_pattern_texture_line_thickness == line_thickness:
		return _locked_province_pattern_texture
	var size: int = maxi(24, cell_radius * 5)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 0))
	var half: int = int(size / 2)
	var line_softness: int = maxi(0, line_thickness - 1)
	for y in range(size):
		for x in range(size):
			var local_x: int = ((x + half) % (cell_radius * 2)) - cell_radius
			var local_y: int = ((y + half) % (cell_radius * 2)) - cell_radius
			var distance_to_diamond_edge: int = abs(abs(local_x) + abs(local_y) - cell_radius)
			if distance_to_diamond_edge <= line_softness:
				var alpha: float = 0.92 if distance_to_diamond_edge == 0 else 0.58
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	_locked_province_pattern_texture = ImageTexture.create_from_image(image)
	_locked_province_pattern_texture_cell_size = cell_radius
	_locked_province_pattern_texture_line_thickness = line_thickness
	return _locked_province_pattern_texture

func _get_pending_invasion_pattern_texture() -> Texture2D:
	var stripe_spacing: int = LevelConfig.get_province_pending_invasion_pattern_cell_size()
	var line_thickness: int = LevelConfig.get_province_pending_invasion_pattern_line_thickness()
	if _pending_invasion_pattern_texture != null and _pending_invasion_pattern_texture_cell_size == stripe_spacing and _pending_invasion_pattern_texture_line_thickness == line_thickness:
		return _pending_invasion_pattern_texture
	var size: int = maxi(24, stripe_spacing * 4)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 0))
	var line_softness: int = maxi(0, line_thickness - 1)
	for y in range(size):
		for x in range(size):
			var stripe_offset: int = (x + y) % stripe_spacing
			var distance_to_stripe: int = mini(stripe_offset, stripe_spacing - stripe_offset)
			if distance_to_stripe <= line_softness:
				var alpha: float = 0.86 if distance_to_stripe == 0 else 0.52
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	_pending_invasion_pattern_texture = ImageTexture.create_from_image(image)
	_pending_invasion_pattern_texture_cell_size = stripe_spacing
	_pending_invasion_pattern_texture_line_thickness = line_thickness
	return _pending_invasion_pattern_texture


func _ensure_pending_invasion_pattern_overlay_node(province_node: Node) -> Polygon2D:
	if province_node == null:
		return null
	var existing: Polygon2D = province_node.get_node_or_null(PENDING_INVASION_PATTERN_OVERLAY_NAME) as Polygon2D
	if existing != null:
		return existing
	var overlay := Polygon2D.new()
	overlay.name = PENDING_INVASION_PATTERN_OVERLAY_NAME
	province_node.add_child(overlay)
	return overlay

func _ensure_locked_province_pattern_overlay_node(province_node: Node) -> Polygon2D:
	if province_node == null:
		return null
	var existing: Polygon2D = province_node.get_node_or_null(LOCKED_PROVINCE_PATTERN_OVERLAY_NAME) as Polygon2D
	if existing != null:
		return existing
	var overlay := Polygon2D.new()
	overlay.name = LOCKED_PROVINCE_PATTERN_OVERLAY_NAME
	province_node.add_child(overlay)
	return overlay


func get_province_troop_visuals_root(province_node: Node) -> Node2D:
	if not is_instance_valid(province_node):
		return null
	return province_node.get_node_or_null(PROVINCE_TROOP_VISUALS_ROOT_NAME) as Node2D


func ensure_province_troop_visuals_root(province_node: Node) -> Node2D:
	if not is_instance_valid(province_node):
		return null
	var root: Node2D = get_province_troop_visuals_root(province_node)
	if root != null:
		return root
	root = Node2D.new()
	root.name = PROVINCE_TROOP_VISUALS_ROOT_NAME
	_set_canvas_item_layer(root, PROVINCE_TROOP_VISUALS_Z_INDEX, false)
	province_node.add_child(root)
	return root


func get_province_building_visuals_root(province_node: Node) -> Node2D:
	if not is_instance_valid(province_node):
		return null
	return province_node.get_node_or_null(PROVINCE_BUILDING_VISUALS_ROOT_NAME) as Node2D


func ensure_province_building_visuals_root(province_node: Node) -> Node2D:
	if not is_instance_valid(province_node):
		return null
	var root: Node2D = get_province_building_visuals_root(province_node)
	if root != null:
		return root
	root = Node2D.new()
	root.name = PROVINCE_BUILDING_VISUALS_ROOT_NAME
	_set_canvas_item_layer(root, PROVINCE_TROOP_VISUALS_Z_INDEX, false)
	province_node.add_child(root)
	return root


func _is_build_mode_enabled() -> bool:
	return _main != null and bool(_main.get("_construction_build_mode_enabled"))


func _get_province_build_mode_canvas_layer() -> CanvasLayer:
	if _main == null:
		return null
	var node: Node = _main.get_node_or_null(PROVINCE_BUILD_MODE_CANVAS_LAYER_NAME)
	if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
		return null
	return node as CanvasLayer if node is CanvasLayer else null


func _ensure_province_build_mode_canvas_layer() -> CanvasLayer:
	if _main == null:
		return null
	var layer: CanvasLayer = _get_province_build_mode_canvas_layer()
	if layer != null:
		layer.layer = LevelConfig.UI_CANVAS_LAYER_BUILD_MODE_WORLD
		layer.follow_viewport_enabled = true
		return layer
	layer = CanvasLayer.new()
	layer.name = PROVINCE_BUILD_MODE_CANVAS_LAYER_NAME
	layer.layer = LevelConfig.UI_CANVAS_LAYER_BUILD_MODE_WORLD
	layer.follow_viewport_enabled = true
	_main.add_child(layer)
	var ui_overlay: Node = _main.get_node_or_null("UIOverlay")
	if ui_overlay != null and is_instance_valid(ui_overlay):
		_main.move_child(layer, ui_overlay.get_index())
	return layer


func _get_province_build_mode_overlay_root() -> Node2D:
	var layer: CanvasLayer = _get_province_build_mode_canvas_layer()
	if layer == null:
		return null
	var node: Node = layer.get_node_or_null(PROVINCE_BUILD_MODE_OVERLAY_ROOT_NAME)
	if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
		return null
	return node as Node2D


func _ensure_province_build_mode_overlay_root() -> Node2D:
	var layer: CanvasLayer = _ensure_province_build_mode_canvas_layer()
	if layer == null:
		return null
	var root: Node2D = _get_province_build_mode_overlay_root()
	if root != null:
		_set_canvas_item_layer(root, PROVINCE_BUILD_MODE_VISUALS_Z_INDEX, false)
		return root
	root = Node2D.new()
	root.name = PROVINCE_BUILD_MODE_OVERLAY_ROOT_NAME
	_set_canvas_item_layer(root, PROVINCE_BUILD_MODE_VISUALS_Z_INDEX, false)
	layer.add_child(root)
	return root


func _get_province_build_mode_debug_root() -> ProvinceBuildModeDebugVisuals:
	var layer: CanvasLayer = _get_province_build_mode_canvas_layer()
	if layer == null:
		return null
	var node: Node = layer.get_node_or_null(PROVINCE_BUILD_MODE_DEBUG_ROOT_NAME)
	return node as ProvinceBuildModeDebugVisuals if node is ProvinceBuildModeDebugVisuals else null


func _ensure_province_build_mode_debug_root() -> ProvinceBuildModeDebugVisuals:
	var layer: CanvasLayer = _ensure_province_build_mode_canvas_layer()
	if layer == null:
		return null
	var root: ProvinceBuildModeDebugVisuals = _get_province_build_mode_debug_root()
	if root != null:
		return root
	root = ProvinceBuildModeDebugVisuals.new()
	root.name = PROVINCE_BUILD_MODE_DEBUG_ROOT_NAME
	_set_canvas_item_layer(root, PROVINCE_BUILD_MODE_VISUALS_Z_INDEX + 20, false)
	layer.add_child(root)
	return root


func _clear_province_build_mode_overlay() -> void:
	if _main == null:
		return
	var layer: CanvasLayer = _get_province_build_mode_canvas_layer()
	if layer != null and is_instance_valid(layer):
		_main.remove_child(layer)
		layer.queue_free()


func _clear_legacy_province_build_mode_visual_roots() -> void:
	for province_node_any in _get_cached_province_nodes():
		var province_node: Node = province_node_any
		if not is_instance_valid(province_node):
			continue
		var stale_root: Node = province_node.get_node_or_null(PROVINCE_BUILD_MODE_VISUALS_ROOT_NAME)
		if stale_root == null:
			continue
		province_node.remove_child(stale_root)
		stale_root.queue_free()


func _to_province_world_position(province_node: Node, local_position: Vector2) -> Vector2:
	if province_node is Node2D:
		return (province_node as Node2D).to_global(local_position)
	return local_position


func _get_control_global_rect(control: Control) -> Rect2:
	if control == null or not is_instance_valid(control):
		return Rect2()
	return Rect2(control.global_position, control.size)


func _get_build_mode_sprite_hit_rect(icon: Sprite2D) -> Rect2:
	if icon == null or not is_instance_valid(icon):
		return Rect2()
	var icon_size: float = float(icon.get_meta("build_mode_icon_size", PROVINCE_BUILD_MODE_QUEUE_ICON_SIZE))
	var half_extent: float = icon_size * 0.5
	return Rect2(icon.global_position - Vector2(half_extent, half_extent), Vector2(icon_size, icon_size))


func _get_build_mode_layout_center(province_node: Node, province_state: Dictionary) -> Dictionary:
	var box_size: Vector2 = get_province_info_box_size(province_state)
	var counts_bg: Control = get_province_counts_background_node(province_node)
	var counts_label: Label = get_province_counts_label_node(province_node)
	var center: Vector2 = get_label_display_center(province_node, counts_bg, counts_label, box_size)
	return {
		"box_size": box_size,
		"center": center,
		"card_top": center.y - box_size.y * 0.5,
		"card_rect_local": Rect2(center - box_size * 0.5, box_size)
	}


func _make_troop_visual_icon() -> ProvinceTroopVisual:
	var icon := ProvinceTroopVisual.new()
	var visual_size_multiplier: float = LevelConfig.get_grand_map_province_troop_visual_size_multiplier()
	var icon_size: float = PROVINCE_TROOP_VISUALS_ICON_SIZE * visual_size_multiplier
	icon.update_visual(icon_size, LevelConfig.get_grand_map_province_troop_visual_color(), LevelConfig.get_grand_map_province_troop_visual_opacity())
	return icon


func _make_building_visual_icon() -> ProvinceBuildingVisual:
	var icon := ProvinceBuildingVisual.new()
	var icon_size: float = PROVINCE_BUILDING_VISUALS_ICON_SIZE
	icon.update_visual(icon_size, LevelConfig.get_grand_map_province_troop_visual_color(), LevelConfig.get_grand_map_province_troop_visual_opacity())
	return icon


func _pseudo_random_01(seed_value: int) -> float:
	var v: float = sin(float(seed_value) * 12.9898 + 78.233) * 43758.5453
	return v - floor(v)


func _compute_visual_icon_offset(idx: int, required_icons: int, row_width: int, stack_direction: String, icon_spacing: float, pile_radius: float, province_id: int) -> Vector2:
	var col: int = 0
	var row: int = 0
	var x_offset: float = 0.0
	var y_offset: float = 0.0
	if stack_direction == "pile":
		var seed_base: int = province_id * 911 + required_icons * 131 + idx * 37
		var angle_jitter: float = _pseudo_random_01(seed_base + 7) * TAU
		var radial_jitter: float = _pseudo_random_01(seed_base + 19)
		var irregularity: float = lerpf(0.72, 1.22, _pseudo_random_01(seed_base + 43))
		var swirl_angle: float = float(idx) * (TAU * PROVINCE_TROOP_VISUALS_PILE_SWIRL_TURNS / float(maxi(1, required_icons)))
		var angle: float = swirl_angle + angle_jitter * 0.6
		var radial_fraction: float = pow(radial_jitter, 0.72)
		var radius: float = pile_radius * radial_fraction * irregularity
		x_offset = cos(angle) * radius
		y_offset = sin(angle) * radius * lerpf(0.88, 1.12, _pseudo_random_01(seed_base + 101))
	elif stack_direction == "vertical":
		row = idx % row_width
		col = idx / row_width
		var column_count: int = int(ceil(float(required_icons) / float(row_width)))
		var column_item_count: int = mini(row_width, required_icons - col * row_width)
		x_offset = (float(col) - (float(column_count - 1) * 0.5)) * icon_spacing
		y_offset = (float(row) - (float(column_item_count - 1) * 0.5)) * icon_spacing
	else:
		col = idx % row_width
		row = idx / row_width
		var row_count: int = mini(row_width, required_icons - row * row_width)
		x_offset = (float(col) - (float(row_count - 1) * 0.5)) * icon_spacing
		var total_rows: int = int(ceil(float(required_icons) / float(row_width)))
		y_offset = (float(row) - (float(total_rows - 1) * 0.5)) * icon_spacing
	return Vector2(x_offset, y_offset)


func _layout_province_troop_visuals(province_node: Node, province_state: Dictionary, base_color: Color) -> void:
	var troop_visuals_root: Node2D = ensure_province_troop_visuals_root(province_node)
	if troop_visuals_root == null:
		return
	var fill: Polygon2D = get_province_fill_node(province_node)
	var poly: PackedVector2Array = fill.polygon if fill != null else PackedVector2Array()
	var center: Vector2 = _find_polygon_label_center(poly, Vector2.ZERO) if poly.size() > 0 else Vector2.ZERO
	center.y += LevelConfig.get_grand_map_province_troop_visual_center_y_offset()
	var troop_visual_cap: int = _get_dynamic_troop_visual_cap()
	var troop_count: int = clampi(int(province_state.get("remaining_troops", 0)), 0, troop_visual_cap)
	var required_icons: int = troop_count
	var existing_icons: int = troop_visuals_root.get_child_count()
	while existing_icons < required_icons:
		troop_visuals_root.add_child(_make_troop_visual_icon())
		existing_icons += 1
	while existing_icons > required_icons:
		var child: Node = troop_visuals_root.get_child(existing_icons - 1)
		troop_visuals_root.remove_child(child)
		child.queue_free()
		existing_icons -= 1
	var icon_color: Color = base_color
	if icon_color.a <= 0.0:
		icon_color = LevelConfig.get_grand_map_province_troop_visual_color()
	else:
		icon_color.a = 1.0
	var icon_opacity: float = LevelConfig.get_grand_map_province_troop_visual_opacity()
	var row_width: int = maxi(1, PROVINCE_TROOP_VISUALS_ROW_WIDTH)
	var stack_direction: String = LevelConfig.get_grand_map_province_troop_visual_stack_direction()
	var visual_size_multiplier: float = LevelConfig.get_grand_map_province_troop_visual_size_multiplier()
	var icon_size: float = PROVINCE_TROOP_VISUALS_ICON_SIZE * visual_size_multiplier
	var icon_spacing: float = PROVINCE_TROOP_VISUALS_ICON_SPACING * visual_size_multiplier
	var province_meta: Dictionary = province_node.get_meta("province_data") if province_node.has_meta("province_data") else {}
	var province_id: int = int(province_meta.get("id", 0))
	var pile_growth: float = sqrt(float(required_icons) / float(maxi(1, troop_visual_cap))) if required_icons > 0 else 0.0
	var pile_radius: float = icon_spacing * lerpf(PROVINCE_TROOP_VISUALS_PILE_MIN_RADIUS_MULTIPLIER, PROVINCE_TROOP_VISUALS_PILE_MAX_RADIUS_MULTIPLIER, pile_growth)
	for idx in range(required_icons):
		var icon: ProvinceTroopVisual = troop_visuals_root.get_child(idx) as ProvinceTroopVisual
		if icon == null:
			var stale_icon: Node = troop_visuals_root.get_child(idx)
			troop_visuals_root.remove_child(stale_icon)
			stale_icon.queue_free()
			icon = _make_troop_visual_icon()
			troop_visuals_root.add_child(icon)
			troop_visuals_root.move_child(icon, idx)
		icon.update_visual(icon_size, icon_color, icon_opacity)
		var offset: Vector2 = _compute_visual_icon_offset(idx, required_icons, row_width, stack_direction, icon_spacing, pile_radius, province_id)
		icon.position = center + offset
		_set_canvas_item_layer(icon, PROVINCE_TROOP_VISUALS_Z_INDEX, false)

func _layout_province_building_visuals(province_node: Node, province_state: Dictionary, panel_top_left: Vector2, panel_size: Vector2, base_color: Color) -> void:
	var building_visuals_root: Node2D = ensure_province_building_visuals_root(province_node)
	if building_visuals_root == null:
		return
	var building_entries: Array[Dictionary] = get_building_visual_entries(province_state)
	var required_icons: int = building_entries.size()
	var existing_icons: int = building_visuals_root.get_child_count()
	while existing_icons < required_icons:
		building_visuals_root.add_child(_make_building_visual_icon())
		existing_icons += 1
	while existing_icons > required_icons:
		var child: Node = building_visuals_root.get_child(existing_icons - 1)
		building_visuals_root.remove_child(child)
		child.queue_free()
		existing_icons -= 1
	if required_icons <= 0:
		return
	var icon_opacity: float = LevelConfig.get_grand_map_province_troop_visual_opacity()
	var icon_size: float = PROVINCE_BUILDING_VISUALS_ICON_SIZE
	var icon_spacing: float = maxf(icon_size, PROVINCE_BUILDING_VISUALS_ICON_SPACING)
	var row_width: int = mini(maxi(1, PROVINCE_BUILDING_VISUALS_ROW_WIDTH), required_icons)
	var total_rows: int = int(ceil(float(required_icons) / float(row_width)))
	var offsets: Array[Vector2] = []
	var mirrored_min_y: float = INF
	for idx in range(required_icons):
		var row: int = idx / row_width
		var col: int = idx % row_width
		var row_item_count: int = mini(row_width, required_icons - row * row_width)
		var offset := Vector2(
			(float(col) - (float(row_item_count - 1) * 0.5)) * icon_spacing,
			(float(row) - (float(total_rows - 1) * 0.5)) * icon_spacing
		)
		offsets.append(offset)
		mirrored_min_y = minf(mirrored_min_y, offset.y)
	var panel_bottom: float = panel_top_left.y + panel_size.y
	var desired_min_y: float = panel_bottom + PROVINCE_BUILDING_VISUALS_CARD_GAP + icon_size
	var center := Vector2(panel_top_left.x + panel_size.x * 0.5, desired_min_y - mirrored_min_y)
	var province_meta: Dictionary = province_node.get_meta("province_data") if province_node.has_meta("province_data") else {}
	var province_id: int = int(province_meta.get("id", province_state.get("id", 0)))
	for idx in range(required_icons):
		var icon: ProvinceBuildingVisual = building_visuals_root.get_child(idx) as ProvinceBuildingVisual
		if icon == null:
			var stale_icon: Node = building_visuals_root.get_child(idx)
			building_visuals_root.remove_child(stale_icon)
			stale_icon.queue_free()
			icon = _make_building_visual_icon()
			building_visuals_root.add_child(icon)
			building_visuals_root.move_child(icon, idx)
		var building_entry: Dictionary = building_entries[idx]
		var building_type: String = String(building_entry.get("building_type", ""))
		var tier: int = maxi(1, int(building_entry.get("tier", 1)))
		icon.update_visual(icon_size, Color.WHITE, icon_opacity, get_building_sprite_path(building_type))
		icon.position = center + offsets[idx]
		icon.set_meta("province_id", province_id)
		icon.set_meta("building_type", building_type)
		icon.set_meta("building_tier", tier)
		icon.set_meta("building_visual_icon_size", icon_size)
		_set_canvas_item_layer(icon, PROVINCE_TROOP_VISUALS_Z_INDEX, false)


func _make_build_mode_icon(province_id: int, action: Dictionary, world_position: Vector2, icon_size: float, is_queue_item: bool, queue_index: int = -1) -> Sprite2D:
	var icon := Sprite2D.new()
	var building_type: String = String(action.get("building_type", ""))
	var sprite_path: String = get_building_sprite_path(building_type)
	var texture: Texture2D = load(sprite_path) as Texture2D
	icon.texture = texture
	icon.centered = true
	icon.position = world_position
	icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if texture != null:
		var tex_size: Vector2 = texture.get_size()
		var longest_edge: float = maxf(tex_size.x, tex_size.y)
		if longest_edge > 0.0:
			icon.scale = Vector2.ONE * (icon_size / longest_edge)
	icon.set_meta("province_id", province_id)
	icon.set_meta("building_type", building_type)
	icon.set_meta("construction_action", action.duplicate(true))
	icon.set_meta("build_mode_icon_size", icon_size)
	icon.set_meta("build_mode_sprite_path", sprite_path)
	icon.set_meta("build_mode_queue_item", is_queue_item)
	icon.set_meta("build_mode_queue_index", queue_index)
	_set_canvas_item_layer(icon, PROVINCE_BUILD_MODE_VISUALS_Z_INDEX, false)
	return icon


func _layout_province_build_mode_visuals_for_province(overlay_root: Node2D, province_node: Node, province_id: int, province_state: Dictionary) -> void:
	if overlay_root == null or not is_instance_valid(province_node):
		return
	var actions: Array[Dictionary] = build_province_build_mode_actions(province_id)
	var queue: Array[Dictionary] = normalize_construction_queue(province_state.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []))
	if actions.is_empty() and queue.is_empty():
		return
	var layout: Dictionary = _get_build_mode_layout_center(province_node, province_state)
	var center: Vector2 = layout.get("center", Vector2.ZERO)
	var card_top: float = float(layout.get("card_top", center.y))
	var choice_count: int = actions.size()
	var choice_y: float = card_top - PROVINCE_BUILD_MODE_CHOICE_ICON_SIZE * 0.35
	for idx in range(choice_count):
		var action: Dictionary = actions[idx]
		var x_offset: float = (float(idx) - float(choice_count - 1) * 0.5) * PROVINCE_BUILD_MODE_CHOICE_SPACING
		var world_position: Vector2 = _to_province_world_position(province_node, Vector2(center.x + x_offset, choice_y))
		var icon := _make_build_mode_icon(province_id, action, world_position, PROVINCE_BUILD_MODE_CHOICE_ICON_SIZE, false)
		overlay_root.add_child(icon)
	var queue_count: int = queue.size()
	var queue_y: float = choice_y + PROVINCE_BUILD_MODE_CHOICE_ICON_SIZE * 0.55
	for queue_index in range(queue_count):
		var queue_action: Dictionary = queue[queue_index]
		var queue_x_offset: float = (float(queue_index) - float(PROVINCE_BUILD_QUEUE_LIMIT - 1) * 0.5) * PROVINCE_BUILD_MODE_QUEUE_SPACING
		var queue_world_position: Vector2 = _to_province_world_position(province_node, Vector2(center.x + queue_x_offset, queue_y))
		var queue_icon := _make_build_mode_icon(province_id, queue_action, queue_world_position, PROVINCE_BUILD_MODE_QUEUE_ICON_SIZE, true, queue_index)
		overlay_root.add_child(queue_icon)


func _refresh_build_mode_debug_visuals() -> void:
	if not _build_mode_debug_visuals_enabled or not _is_build_mode_enabled():
		return
	var debug_root: ProvinceBuildModeDebugVisuals = _ensure_province_build_mode_debug_root()
	if debug_root == null:
		return
	var panel_rects: Array[Rect2] = []
	var icon_rects: Array[Rect2] = []
	var caption_lines: Array[String] = []
	caption_lines.append("Build-mode debug: red=info cards, green=build sprites")
	var overlay_root: Node2D = _get_province_build_mode_overlay_root()
	var icon_count: int = overlay_root.get_child_count() if overlay_root != null else 0
	caption_lines.append("Overlay icons: %d | canvas layer: %d | sprite z: %d" % [
		icon_count,
		LevelConfig.UI_CANVAS_LAYER_BUILD_MODE_WORLD,
		PROVINCE_BUILD_MODE_VISUALS_Z_INDEX
	])
	for province_node_any in _get_cached_province_nodes():
		if not is_instance_valid(province_node_any):
			continue
		var province_node: Node = province_node_any
		var province_id: int = -1
		if province_node.has_meta("province_data"):
			province_id = int(province_node.get_meta("province_data").get("id", -1))
		var panel_root: Control = _get_province_info_panel_root(province_node)
		if panel_root != null:
			panel_rects.append(_get_control_global_rect(panel_root))
		elif province_id >= 0:
			var province_index: int = find_persistence_index_by_id(province_id)
			if province_index >= 0:
				var province_state: Dictionary = _main._province_persistence[province_index]
				var layout: Dictionary = _get_build_mode_layout_center(province_node, province_state)
				var card_rect_local: Rect2 = layout.get("card_rect_local", Rect2())
				panel_rects.append(Rect2(_to_province_world_position(province_node, card_rect_local.position), card_rect_local.size))
	if overlay_root != null:
		for child_any in overlay_root.get_children():
			if child_any is Sprite2D:
				icon_rects.append(_get_build_mode_sprite_hit_rect(child_any as Sprite2D))
	debug_root.set_debug_data(panel_rects, icon_rects, caption_lines)


func _refresh_province_build_mode_overlay() -> void:
	_clear_province_build_mode_overlay()
	_clear_legacy_province_build_mode_visual_roots()
	if not _is_build_mode_enabled():
		return
	var overlay_root: Node2D = _ensure_province_build_mode_overlay_root()
	if overlay_root == null:
		return
	for province_node_any in _get_cached_province_nodes():
		if not is_instance_valid(province_node_any):
			continue
		var province_node: Node = province_node_any
		var province_id: int = -1
		if province_node.has_meta("province_data"):
			var meta_data: Dictionary = province_node.get_meta("province_data")
			province_id = int(meta_data.get("id", -1))
		var province_index: int = find_persistence_index_by_id(province_id)
		if province_index == -1:
			continue
		var province_state: Dictionary = _main._province_persistence[province_index]
		_layout_province_build_mode_visuals_for_province(overlay_root, province_node, province_id, province_state)
	_refresh_build_mode_debug_visuals()


func set_build_mode_debug_visuals_enabled(enabled: bool) -> void:
	_build_mode_debug_visuals_enabled = enabled
	if not enabled:
		var debug_root: ProvinceBuildModeDebugVisuals = _get_province_build_mode_debug_root()
		if debug_root != null and is_instance_valid(debug_root):
			debug_root.queue_free()
		return
	_refresh_build_mode_debug_visuals()


func is_build_mode_debug_visuals_enabled() -> bool:
	return _build_mode_debug_visuals_enabled


func collect_build_mode_layer_debug_report() -> Dictionary:
	var build_mode_enabled: bool = _is_build_mode_enabled()
	var canvas_layer: CanvasLayer = _get_province_build_mode_canvas_layer()
	var overlay_root: Node2D = _get_province_build_mode_overlay_root()
	var overlay_icons: Array[Dictionary] = []
	if overlay_root != null:
		for child_any in overlay_root.get_children():
			if not (child_any is Sprite2D):
				continue
			var icon: Sprite2D = child_any
			var hit_rect: Rect2 = _get_build_mode_sprite_hit_rect(icon)
			overlay_icons.append({
				"province_id": int(icon.get_meta("province_id", -1)),
				"building_type": String(icon.get_meta("building_type", "")),
				"queue_item": bool(icon.get_meta("build_mode_queue_item", false)),
				"queue_index": int(icon.get_meta("build_mode_queue_index", -1)),
				"sprite_path": String(icon.get_meta("build_mode_sprite_path", "")),
				"texture_loaded": icon.texture != null,
				"global_position": {"x": icon.global_position.x, "y": icon.global_position.y},
				"z_index": icon.z_index,
				"z_as_relative": icon.z_as_relative,
				"top_level": icon.top_level,
				"scale": {"x": icon.scale.x, "y": icon.scale.y},
				"hit_rect": {
					"x": hit_rect.position.x,
					"y": hit_rect.position.y,
					"w": hit_rect.size.x,
					"h": hit_rect.size.y
				}
			})
	var province_reports: Array[Dictionary] = []
	for province_node_any in _get_cached_province_nodes():
		if not is_instance_valid(province_node_any):
			continue
		var province_node: Node = province_node_any
		var province_id: int = -1
		if province_node.has_meta("province_data"):
			province_id = int(province_node.get_meta("province_data").get("id", -1))
		var province_index: int = find_persistence_index_by_id(province_id)
		if province_index < 0:
			continue
		var province_state: Dictionary = _main._province_persistence[province_index]
		var layout: Dictionary = _get_build_mode_layout_center(province_node, province_state)
		var panel_root: Control = _get_province_info_panel_root(province_node)
		var panel_rect: Rect2 = _get_control_global_rect(panel_root) if panel_root != null else Rect2(
			_to_province_world_position(province_node, layout.get("card_rect_local", Rect2()).position),
			layout.get("card_rect_local", Rect2()).size
		)
		var panel_z_index: int = panel_root.z_index if panel_root != null else -1
		var actions: Array[Dictionary] = build_province_build_mode_actions(province_id) if build_mode_enabled else []
		var queue: Array[Dictionary] = normalize_construction_queue(province_state.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []))
		province_reports.append({
			"province_id": province_id,
			"province_name": get_province_display_name(province_id, province_state),
			"player_can_build": can_player_control_construction_in_province(province_id),
			"build_actions_available": actions.size(),
			"queue_size": queue.size(),
			"layout_center": {"x": float(layout.get("center", Vector2.ZERO).x), "y": float(layout.get("center", Vector2.ZERO).y)},
			"card_top": float(layout.get("card_top", 0.0)),
			"panel_rect": {"x": panel_rect.position.x, "y": panel_rect.position.y, "w": panel_rect.size.x, "h": panel_rect.size.y},
			"panel_z_index": panel_z_index,
			"panel_z_as_relative": panel_root.z_as_relative if panel_root != null else null,
			"legacy_build_mode_child": province_node.get_node_or_null(PROVINCE_BUILD_MODE_VISUALS_ROOT_NAME) != null
		})
	var overlapping_pairs: Array[Dictionary] = []
	for icon_report_any in overlay_icons:
		var icon_report: Dictionary = icon_report_any
		var icon_rect := Rect2(
			float(icon_report.get("hit_rect", {}).get("x", 0.0)),
			float(icon_report.get("hit_rect", {}).get("y", 0.0)),
			float(icon_report.get("hit_rect", {}).get("w", 0.0)),
			float(icon_report.get("hit_rect", {}).get("h", 0.0))
		)
		for province_report_any in province_reports:
			var province_report: Dictionary = province_report_any
			if int(icon_report.get("province_id", -1)) != int(province_report.get("province_id", -1)):
				continue
			var panel_rect_data: Dictionary = province_report.get("panel_rect", {})
			var panel_rect := Rect2(
				float(panel_rect_data.get("x", 0.0)),
				float(panel_rect_data.get("y", 0.0)),
				float(panel_rect_data.get("w", 0.0)),
				float(panel_rect_data.get("h", 0.0))
			)
			if icon_rect.intersects(panel_rect):
				overlapping_pairs.append({
					"province_id": int(province_report.get("province_id", -1)),
					"building_type": String(icon_report.get("building_type", "")),
					"icon_z_index": int(icon_report.get("z_index", 0)),
					"panel_z_index": int(province_report.get("panel_z_index", 0)),
					"overlap_area": icon_rect.intersection(panel_rect).get_area()
				})
	return {
		"schema": "build_mode_layer_debug_v1",
		"captured_utc": Time.get_datetime_string_from_system(true, true),
		"build_mode_enabled": build_mode_enabled,
		"debug_visuals_enabled": _build_mode_debug_visuals_enabled,
		"rendering_notes": [
			"Province info cards are Control nodes parented under province Node2D nodes.",
			"Build sprites render on a follow_viewport CanvasLayer above the default world canvas.",
			"Red debug boxes mark info-card bounds; green boxes mark build-sprite hit bounds."
		],
		"canvas_layer": {
			"exists": canvas_layer != null,
			"name": PROVINCE_BUILD_MODE_CANVAS_LAYER_NAME,
			"layer": LevelConfig.UI_CANVAS_LAYER_BUILD_MODE_WORLD,
			"follow_viewport_enabled": canvas_layer.follow_viewport_enabled if canvas_layer != null else false
		},
		"overlay": {
			"exists": overlay_root != null,
			"icon_count": overlay_icons.size(),
			"target_sprite_z_index": PROVINCE_BUILD_MODE_VISUALS_Z_INDEX,
			"province_info_card_z_index": PROVINCE_COUNTS_BACKGROUND_Z_INDEX + 1,
			"icons": overlay_icons
		},
		"provinces": province_reports,
		"icon_panel_overlaps": overlapping_pairs
	}


func get_build_mode_layer_debug_summary() -> String:
	var report: Dictionary = collect_build_mode_layer_debug_report()
	var overlay: Dictionary = report.get("overlay", {})
	var overlaps: Array = report.get("icon_panel_overlaps", [])
	var actionable_provinces: int = 0
	for province_report_any in report.get("provinces", []):
		if int(province_report_any.get("build_actions_available", 0)) > 0 or int(province_report_any.get("queue_size", 0)) > 0:
			actionable_provinces += 1
	return "Build debug: enabled=%s icons=%d actionable_provinces=%d overlaps=%d canvas_layer=%s" % [
		str(report.get("build_mode_enabled", false)),
		int(overlay.get("icon_count", 0)),
		actionable_provinces,
		overlaps.size(),
		"yes" if bool((report.get("canvas_layer", {}) as Dictionary).get("exists", false)) else "no"
	]


func _find_existing_building_icon_at(world_pos: Vector2) -> Node2D:
	var best_icon: Node2D = null
	var best_distance: float = INF
	for province_node_any in _get_cached_province_nodes():
		var province_node: Node = province_node_any
		var root: Node2D = get_province_building_visuals_root(province_node)
		if root == null:
			continue
		for child_any in root.get_children():
			if not (child_any is Node2D):
				continue
			var icon: Node2D = child_any
			var icon_size: float = float(icon.get_meta("building_visual_icon_size", PROVINCE_BUILDING_VISUALS_ICON_SIZE))
			var hit_radius: float = maxf(18.0, icon_size * 0.52)
			var distance: float = icon.global_position.distance_to(world_pos)
			if distance <= hit_radius and distance < best_distance:
				best_icon = icon
				best_distance = distance
	return best_icon


func _queue_existing_building_action(icon: Node2D, request_type: String) -> Dictionary:
	if icon == null:
		return {}
	var province_id: int = int(icon.get_meta("province_id", -1))
	var building_type: String = get_canonical_building_type(String(icon.get_meta("building_type", "")))
	var tier: int = maxi(1, int(icon.get_meta("building_tier", 1)))
	if province_id < 0 or not BUILDING_CATALOG.has(building_type):
		return {}
	if request_type == CONSTRUCTION_PROJECT_UPGRADE:
		var definition: Dictionary = BUILDING_CATALOG.get(building_type, {})
		if tier + 1 > int(definition.get("max_tier", 3)):
			return {"ok": false, "message": "%s is already at its maximum tier." % get_building_display_name(building_type)}
	elif request_type != CONSTRUCTION_PROJECT_DEMOLISH:
		return {}
	return enqueue_province_construction_order(province_id, {
		"request_type": request_type,
		"building_type": building_type,
		"tier": tier
	})


func try_handle_build_mode_click(world_pos: Vector2, mouse_button: int = MOUSE_BUTTON_LEFT, is_double_click: bool = false) -> Dictionary:
	if _main == null or not bool(_main.get("_construction_build_mode_enabled")):
		return {}
	if not is_instance_valid(_main.provinces_root):
		return {}
	if mouse_button == MOUSE_BUTTON_RIGHT:
		var demolish_icon: Node2D = _find_existing_building_icon_at(world_pos)
		if demolish_icon != null:
			return _queue_existing_building_action(demolish_icon, CONSTRUCTION_PROJECT_DEMOLISH)
		return {}
	if mouse_button == MOUSE_BUTTON_LEFT and is_double_click:
		var upgrade_icon: Node2D = _find_existing_building_icon_at(world_pos)
		if upgrade_icon != null:
			return _queue_existing_building_action(upgrade_icon, CONSTRUCTION_PROJECT_UPGRADE)
	var best_icon: Sprite2D = null
	var best_distance: float = INF
	var overlay_root: Node2D = _get_province_build_mode_overlay_root()
	if overlay_root != null:
		for child_any in overlay_root.get_children():
			if not (child_any is Sprite2D):
				continue
			var icon: Sprite2D = child_any
			var icon_size: float = float(icon.get_meta("build_mode_icon_size", PROVINCE_BUILD_MODE_QUEUE_ICON_SIZE))
			var hit_radius: float = maxf(24.0, icon_size * 0.42)
			var distance: float = icon.global_position.distance_to(world_pos)
			if distance <= hit_radius and distance < best_distance:
				best_icon = icon
				best_distance = distance
	if best_icon == null:
		return {}
	var province_id: int = int(best_icon.get_meta("province_id", -1))
	if bool(best_icon.get_meta("build_mode_queue_item", false)):
		return remove_queued_province_construction_order(province_id, int(best_icon.get_meta("build_mode_queue_index", -1)))
	var action: Dictionary = best_icon.get_meta("construction_action", {})
	return enqueue_province_construction_order(province_id, action)


func _get_dynamic_troop_visual_cap() -> int:
	var cap: int = PROVINCE_TROOP_VISUALS_REDUCED_COUNT
	if _main != null and _main.has_method("get"):
		var camera_zoom_value: float = float(_main.get("current_camera_zoom"))
		if camera_zoom_value >= 0.85:
			cap = min(PROVINCE_TROOP_VISUALS_REDUCED_COUNT, 14)
		elif camera_zoom_value >= 0.65:
			cap = min(PROVINCE_TROOP_VISUALS_REDUCED_COUNT, 18)
	return clampi(cap, 8, PROVINCE_TROOP_VISUALS_MAX_COUNT)


func is_target_province_state(province_state: Dictionary) -> bool:
	return bool(province_state.get("is_target", false))


func get_province_info_box_size(province_state: Dictionary) -> Vector2:
	return _get_province_info_panel_size()

func _compute_polygon_average(poly: PackedVector2Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var sum: Vector2 = Vector2.ZERO
	for point in poly:
		sum += point
	return sum / float(poly.size())


func _compute_polygon_centroid(poly: PackedVector2Array) -> Vector2:
	if poly.size() < 3:
		return _compute_polygon_average(poly)
	var signed_area: float = 0.0
	var cx: float = 0.0
	var cy: float = 0.0
	for i in range(poly.size()):
		var p0: Vector2 = poly[i]
		var p1: Vector2 = poly[(i + 1) % poly.size()]
		var cross: float = p0.x * p1.y - p1.x * p0.y
		signed_area += cross
		cx += (p0.x + p1.x) * cross
		cy += (p0.y + p1.y) * cross
	if absf(signed_area) < 0.0001:
		return _compute_polygon_average(poly)
	signed_area *= 0.5
	return Vector2(cx / (6.0 * signed_area), cy / (6.0 * signed_area))


func _compute_polygon_bounds(poly: PackedVector2Array) -> Rect2:
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


func _distance_point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq <= 0.0001:
		return point.distance_to(a)
	var t: float = clampf((point - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return point.distance_to(closest)


func _distance_to_polygon_edges(point: Vector2, poly: PackedVector2Array) -> float:
	if poly.size() < 2:
		return 0.0
	var best: float = INF
	for i in range(poly.size()):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		best = minf(best, _distance_point_to_segment(point, a, b))
	return 0.0 if best == INF else best


func _score_label_candidate(point: Vector2, poly: PackedVector2Array, desired_center: Vector2, box_size: Vector2, bounds: Rect2) -> float:
	if not Geometry2D.is_point_in_polygon(point, poly):
		return -INF
	var edge_distance: float = _distance_to_polygon_edges(point, poly)
	var score: float = edge_distance * 4.0 - point.distance_to(desired_center) * 0.35
	if box_size != Vector2.ZERO:
		var half: Vector2 = box_size * 0.5
		var overflow_x: float = maxf(0.0, bounds.position.x - (point.x - half.x)) + maxf(0.0, (point.x + half.x) - (bounds.position.x + bounds.size.x))
		var overflow_y: float = maxf(0.0, bounds.position.y - (point.y - half.y)) + maxf(0.0, (point.y + half.y) - (bounds.position.y + bounds.size.y))
		score -= (overflow_x + overflow_y) * 3.5
	return score


func _find_polygon_label_center(poly: PackedVector2Array, box_size: Vector2 = Vector2.ZERO) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var bounds: Rect2 = _compute_polygon_bounds(poly)
	var centroid: Vector2 = _compute_polygon_centroid(poly)
	var average: Vector2 = _compute_polygon_average(poly)
	var desired_center: Vector2 = centroid if Geometry2D.is_point_in_polygon(centroid, poly) else average
	var candidates: Array[Vector2] = [desired_center, average, bounds.get_center()]
	var steps_x: int = 9
	var steps_y: int = 9
	for yi in range(steps_y):
		var fy: float = 0.0 if steps_y <= 1 else float(yi) / float(steps_y - 1)
		for xi in range(steps_x):
			var fx: float = 0.0 if steps_x <= 1 else float(xi) / float(steps_x - 1)
			candidates.append(Vector2(
				bounds.position.x + bounds.size.x * fx,
				bounds.position.y + bounds.size.y * fy
			))
	var best_point: Vector2 = desired_center
	var best_score: float = -INF
	for candidate in candidates:
		var score: float = _score_label_candidate(candidate, poly, desired_center, box_size, bounds)
		if score > best_score:
			best_score = score
			best_point = candidate
	if best_score == -INF:
		return average
	return best_point


func get_label_display_center(province_node: Node, counts_bg: Control, counts_label: Label, box_size: Vector2 = Vector2.ZERO) -> Vector2:
	if counts_bg != null and counts_bg.has_meta("manual_center"):
		return counts_bg.get_meta("manual_center")
	if counts_label != null and counts_label.has_meta("manual_center"):
		return counts_label.get_meta("manual_center")
	var fill: Polygon2D = get_province_fill_node(province_node)
	if fill != null and fill.polygon.size() > 0:
		return _find_polygon_label_center(fill.polygon, box_size)
	if counts_bg != null:
		return counts_bg.position + counts_bg.size * 0.5
	if counts_label != null:
		return counts_label.position + counts_label.size * 0.5
	return Vector2.ZERO


func get_province_owner_text(province_state: Dictionary) -> String:
	if is_boss_home_province_state(province_state):
		var boss_faction: int = int(province_state.get("faction_id", 0))
		if boss_faction <= 0 and _main != null and _main.boss_system != null:
			var province_id: int = int(province_state.get("id", -1))
			if province_id >= 0 and _main.boss_system.has_method("get_boss_id_for_home_province_id") and _main.boss_system.has_method("get_boss_faction_id"):
				var boss_id: int = int(_main.boss_system.get_boss_id_for_home_province_id(province_id))
				if boss_id >= 0:
					boss_faction = int(_main.boss_system.get_boss_faction_id(boss_id))
		return get_faction_display_name(maxi(1, boss_faction))
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var relation: String = get_relation_to_player_for_province_state(province_state)
	if relation == RELATION_SELF:
		return "Friendly"
	if relation == RELATION_ALLY:
		return "Ally %d" % int(province_state.get("faction_id", 0))
	if relation == RELATION_HOSTILE:
		var faction: int = maxi(1, int(province_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
		return get_faction_display_name(faction)
	if province_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return "Neutral"
	return "Friendly"


func _get_name_generation_world_seed() -> int:
	if _main == null:
		return 1
	return maxi(1, int(_main.map_seed))


func _get_generated_faction_name_candidate(faction_id: int) -> String:
	var world_seed: int = _get_name_generation_world_seed()
	var generated_name_id: int = FACTION_NAME_ID_OFFSET + absi(faction_id)
	var generated: String = String(LevelConfig.generate_province_name(world_seed, generated_name_id)).strip_edges()
	if generated.is_empty():
		return "Faction %d" % faction_id
	return generated


func get_faction_display_name(faction_id: int) -> String:
	var safe_faction_id: int = int(faction_id)
	if safe_faction_id <= 0:
		return "Neutral"
	var cache_key: String = "%d|%d" % [_get_name_generation_world_seed(), safe_faction_id]
	if _faction_name_cache.has(cache_key):
		return String(_faction_name_cache.get(cache_key, "Faction %d" % safe_faction_id))
	var generated: String = _get_generated_faction_name_candidate(safe_faction_id)
	_faction_name_cache[cache_key] = generated
	return generated


func _is_friendly_boss_faction_id(faction_id: int) -> bool:
	if faction_id <= 0 or _main == null or _main.boss_system == null:
		return false
	if not _main.boss_system.has_method("is_friendly_boss_faction_id"):
		return false
	return bool(_main.boss_system.call("is_friendly_boss_faction_id", faction_id))


func is_player_owned(owner_type: String, faction_id: int) -> bool:
	return owner_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and not _is_friendly_boss_faction_id(faction_id)


func is_ally_owned(owner_type: String, faction_id: int) -> bool:
	return faction_id > 0 and _is_friendly_boss_faction_id(faction_id)


func is_hostile_owned(owner_type: String, faction_id: int) -> bool:
	return owner_type == LevelConfig.PROVINCE_TYPE_ENEMY and not _is_friendly_boss_faction_id(faction_id)


func normalize_owner_fields(province_state: Dictionary) -> Dictionary:
	var normalized: Dictionary = province_state.duplicate(true)
	var owner_type: String = String(normalized.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var faction_id: int = int(normalized.get("faction_id", 0))
	var is_friendly_boss_faction: bool = faction_id > 0 and _is_friendly_boss_faction_id(faction_id)
	if owner_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		if is_friendly_boss_faction:
			normalized["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
			normalized["faction_id"] = faction_id
		else:
			normalized["faction_id"] = 0
	elif owner_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		if is_friendly_boss_faction:
			normalized["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
			normalized["faction_id"] = faction_id
		else:
			normalized["faction_id"] = maxi(1, faction_id if faction_id != 0 else LevelConfig.ENEMY_FACTION_DEFAULT)
	elif owner_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		normalized["faction_id"] = 0
	else:
		normalized["type"] = LevelConfig.PROVINCE_TYPE_NEUTRAL
		normalized["faction_id"] = 0
	return normalized


func get_relation_to_player(owner_type: String, faction_id: int) -> String:
	if owner_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return RELATION_NEUTRAL
	if is_player_owned(owner_type, faction_id):
		return RELATION_SELF
	if is_ally_owned(owner_type, faction_id):
		return RELATION_ALLY
	if is_hostile_owned(owner_type, faction_id):
		return RELATION_HOSTILE
	return RELATION_NEUTRAL


func get_relation_to_player_for_province_state(province_state: Dictionary) -> String:
	return get_relation_to_player(
		String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
		int(province_state.get("faction_id", 0))
	)


func _get_enemy_faction_display_color(faction_id: int) -> Color:
	if _is_friendly_boss_faction_id(faction_id):
		return FRIENDLY_BOSS_FACTION_DISPLAY_COLOR
	return LevelConfig.get_enemy_faction_color(faction_id)


func _get_nonempty_province_name_from_dict(source: Dictionary) -> String:
	if source.is_empty():
		return ""
	return String(source.get(PROVINCE_NAME_KEY, "")).strip_edges()


func _generate_fallback_province_name(province_id: int) -> String:
	var map_seed: int = 1
	if _main != null:
		map_seed = maxi(1, int(_main.map_seed))
	var generated: String = String(LevelConfig.generate_province_name(map_seed, province_id)).strip_edges()
	if generated.is_empty():
		return "Province %d" % province_id
	return generated


func _resolve_province_name(province_id: int, province_state: Dictionary, province_meta: Dictionary = {}) -> String:
	var state_name: String = _get_nonempty_province_name_from_dict(province_state)
	if not state_name.is_empty():
		return state_name
	var meta_name: String = _get_nonempty_province_name_from_dict(province_meta)
	if not meta_name.is_empty():
		return meta_name
	return _generate_fallback_province_name(province_id)


func get_province_display_name(province_id: int, province_state: Dictionary) -> String:
	return _resolve_province_name(province_id, province_state)



func get_province_info_text(province_id: int, province_state: Dictionary) -> String:
	normalize_province_economy_state(province_state)
	var lines: Array[String] = []
	if is_target_province_state(province_state):
		lines.append(LevelConfig.TARGET_PROVINCE_LABEL_TEXT)
	lines.append(get_province_owner_text(province_state))
	lines.append(get_province_display_name(province_id, province_state))
	var population: Dictionary = province_state.get(PROVINCE_POPULATION_KEY, {})
	var happiness: Dictionary = province_state.get(PROVINCE_HAPPINESS_KEY, {})
	var food: Dictionary = province_state.get(PROVINCE_FOOD_KEY, {})
	lines.append("%s  %s" % [_format_province_card_count(float(population.get(POPULATION_NATIVES_KEY, 0.0))), _format_province_card_happiness(float(happiness.get(POPULATION_NATIVES_KEY, get_province_tuning_value("default_happiness"))))])
	lines.append("%s  %s" % [_format_province_card_count(float(population.get(POPULATION_OUTLANDER_KEY, 0.0))), _format_province_card_happiness(float(happiness.get(POPULATION_OUTLANDER_KEY, get_province_tuning_value("default_happiness"))))])
	lines.append(_format_province_card_food_surplus(float(food.get("surplus", 0.0))))
	return "\n".join(lines)

func get_province_border_node(province_node: Node) -> Line2D:
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is Line2D and String(child.name) == "ProvinceBorder":
			return child as Line2D
	for child in province_node.get_children():
		if child is Line2D and String(child.name) != "ProvinceInnerGlow":
			return child as Line2D
	return null


func get_province_inner_glow_node(province_node: Node) -> Line2D:
	if not is_instance_valid(province_node):
		return null
	for child in province_node.get_children():
		if child is Line2D and String(child.name) == "ProvinceInnerGlow":
			return child as Line2D
	var line_count: int = 0
	for child in province_node.get_children():
		if child is Line2D:
			line_count += 1
			if line_count == 2:
				return child as Line2D
	return null


func ensure_province_inner_glow_node(province_node: Node) -> Line2D:
	if not is_instance_valid(province_node):
		return null
	var existing: Line2D = get_province_inner_glow_node(province_node)
	if existing != null:
		return existing
	var inner_glow := Line2D.new()
	inner_glow.name = "ProvinceInnerGlow"
	inner_glow.antialiased = true
	inner_glow.closed = true
	_set_canvas_item_layer(inner_glow, PROVINCE_BORDER_OVERLAYS_Z_INDEX, false)
	province_node.add_child(inner_glow)
	return inner_glow


func _enforce_province_line_visibility(province_node: Node, keep_inner_glow_visible: bool) -> void:
	if not is_instance_valid(province_node):
		return
	for child in province_node.get_children():
		if child is Line2D:
			var line := child as Line2D
			if String(line.name) == "ProvinceInnerGlow":
				line.visible = keep_inner_glow_visible
			else:
				line.visible = false


func get_base_province_fill_color(province_state: Dictionary, tint_idx: int) -> Color:
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var invading_troops: int = int(province_state.get("invading_troops", 0))
	var faction_id: int = int(province_state.get("faction_id", 0))
	
	if is_boss_home_province_state(province_state):
		var boss_home_faction: int = int(province_state.get("faction_id", 0))
		if boss_home_faction > 0:
			return _get_enemy_faction_display_color(boss_home_faction)
		return BOSS_HOME_FILL_COLOR
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and faction_id == BossSystem.FRIENDLY_BOSS_FACTION_ID:
		var friendly_boss_fill: Color = _get_enemy_faction_display_color(faction_id)
		if invading_troops > 0:
			var invaded_friendly_boss_fill: Color = friendly_boss_fill.lightened(0.2)
			invaded_friendly_boss_fill.a = friendly_boss_fill.a
			return invaded_friendly_boss_fill
		return friendly_boss_fill
	if province_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		var faction: int = int(province_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT))
		return _get_enemy_faction_display_color(faction)
	
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
		return LevelConfig.get_friendly_invaded_province_fill_color()
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return LevelConfig.get_friendly_province_fill_color()
	return LevelConfig.PROVINCE_FILL_COLORS[tint_idx % LevelConfig.PROVINCE_FILL_COLORS.size()]


func _colors_match_for_border_selection(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) <= 0.002 and absf(a.g - b.g) <= 0.002 and absf(a.b - b.b) <= 0.002 and absf(a.a - b.a) <= 0.01


func get_province_border_line_color(base_fill_color: Color) -> Color:
	for neutral_color in LevelConfig.PROVINCE_FILL_COLORS:
		if _colors_match_for_border_selection(base_fill_color, neutral_color):
			return LevelConfig.PROVINCE_NEUTRAL_BORDER_COLOR
	if _colors_match_for_border_selection(base_fill_color, BOSS_HOME_FILL_COLOR):
		return BOSS_HOME_BORDER_COLOR
	var line_color: Color = base_fill_color
	line_color.a = 1.0
	return line_color


func get_province_outer_line_width() -> float:
	return LevelConfig.PROVINCE_BORDER_WIDTH


func get_province_inner_line_width() -> float:
	return maxf(2.0, LevelConfig.PROVINCE_BORDER_WIDTH * 0.42)


func get_province_inner_line_inset() -> float:
	return maxf(get_province_inner_line_width() * 0.7, LevelConfig.PROVINCE_BORDER_WIDTH * 0.55)


func get_province_shared_border_width() -> float:
	return maxf(1.0, float(LevelConfig.PROVINCE_SHARED_BORDER_WIDTH))


func get_province_shared_border_band_width() -> float:
	return maxf(get_province_shared_border_width() * 2.35, get_province_shared_border_width() + 5.0)


func get_province_shared_border_center_inset() -> float:
	return maxf(0.5, get_province_shared_border_band_width() * 0.5 + 0.2)


func get_province_shared_border_band_depth() -> float:
	return get_province_shared_border_band_width()


func get_province_shared_ownership_fill_width() -> float:
	return maxf(get_province_shared_border_band_width() + get_province_shared_border_center_inset() * 2.0 + 1.0, get_province_shared_border_band_width() + 4.0)


func get_province_shared_border_run_extension() -> float:
	return maxf(1.25, get_province_shared_border_band_width() * 0.35)


func _polygon_signed_area(poly: PackedVector2Array) -> float:
	var area: float = 0.0
	var count: int = poly.size()
	if count < 3:
		return 0.0
	for i in range(count):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % count]
		area += a.x * b.y - b.x * a.y
	return area * 0.5

func _ensure_polygon_ccw(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	if _polygon_signed_area(poly) >= 0.0:
		return poly
	var reversed_poly: PackedVector2Array = PackedVector2Array()
	for i in range(poly.size() - 1, -1, -1):
		reversed_poly.append(poly[i])
	return reversed_poly


func make_inset_polyline(poly: PackedVector2Array, inset_distance: float) -> PackedVector2Array:
	if poly.size() < 3 or inset_distance <= 0.0:
		return poly
	var offset_polys: Array = Geometry2D.offset_polygon(poly, -inset_distance)
	if offset_polys.is_empty():
		return poly
	var best_poly: PackedVector2Array = offset_polys[0]
	var best_area: float = absf(_polygon_signed_area(best_poly))
	for candidate in offset_polys:
		var candidate_poly: PackedVector2Array = candidate
		var candidate_area: float = absf(_polygon_signed_area(candidate_poly))
		if candidate_area > best_area:
			best_area = candidate_area
			best_poly = candidate_poly
	if best_poly.size() >= 3:
		return best_poly
	return poly

func _collapse_collinear_points(poly: PackedVector2Array) -> PackedVector2Array:
	if poly.size() < 4:
		return poly
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(poly.size()):
		var prev: Vector2 = poly[(i - 1 + poly.size()) % poly.size()]
		var cur: Vector2 = poly[i]
		var nxt: Vector2 = poly[(i + 1) % poly.size()]
		var edge_a: Vector2 = cur - prev
		var edge_b: Vector2 = nxt - cur
		if edge_a.length_squared() <= 0.000001 or edge_b.length_squared() <= 0.000001:
			continue
		var v1: Vector2 = edge_a.normalized()
		var v2: Vector2 = edge_b.normalized()
		if absf(v1.cross(v2)) < 0.001 and v1.dot(v2) > 0.999:
			continue
		out.append(cur)
	return out


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


func make_smoothed_province_display_polyline(poly: PackedVector2Array, inset_distance: float = 0.0) -> PackedVector2Array:
	if poly.size() < 3:
		return poly
	var working: PackedVector2Array = poly
	if inset_distance > 0.0:
		working = make_inset_polyline(working, inset_distance)
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


func _chaikin_smooth_open_polyline(points: PackedVector2Array, ratio: float) -> PackedVector2Array:
	if points.size() < 2:
		return points
	var clamped_ratio: float = clampf(ratio, 0.05, 0.45)
	var out: PackedVector2Array = PackedVector2Array()
	out.append(points[0])
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		out.append(a.lerp(b, clamped_ratio))
		out.append(a.lerp(b, 1.0 - clamped_ratio))
	out.append(points[points.size() - 1])
	return out


func _smooth_open_province_polyline(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 2:
		return points
	var working: PackedVector2Array = PackedVector2Array()
	for point in points:
		if working.is_empty() or working[working.size() - 1].distance_to(point) > 0.001:
			working.append(point)
	if working.size() < 2:
		return working
	if not bool(LevelConfig.PROVINCE_BORDER_SMOOTHING_ENABLED):
		return working
	var ratio: float = float(LevelConfig.PROVINCE_BORDER_SMOOTHING_CHAIKIN_RATIO)
	var pass_count: int = maxi(0, int(LevelConfig.PROVINCE_BORDER_SMOOTHING_PASSES))
	for _pass_idx in range(pass_count):
		working = _chaikin_smooth_open_polyline(working, ratio)
	return working


func _vector_key(point: Vector2, snap: float = 0.25) -> String:
	var snapped_x: int = int(round(point.x / snap))
	var snapped_y: int = int(round(point.y / snap))
	return "%d,%d" % [snapped_x, snapped_y]


func _edge_key(a: Vector2, b: Vector2) -> String:
	var ka: String = _vector_key(a)
	var kb: String = _vector_key(b)
	if ka <= kb:
		return ka + "|" + kb
	return kb + "|" + ka


func _province_pair_key(a_id: int, b_id: int) -> String:
	if a_id <= b_id:
		return "%d|%d" % [a_id, b_id]
	return "%d|%d" % [b_id, a_id]


func _merge_polygon_collection(polygons: Array) -> Array:
	var merged: Array = []
	for poly_any in polygons:
		var source_poly: PackedVector2Array = poly_any
		if source_poly.size() < 3:
			continue
		var pending: Array = [_normalize_closed_polygon_start(source_poly)]
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
					pending.append(_normalize_closed_polygon_start(union_parts[0]))
					merged_into_existing = true
					break
			if not merged_into_existing:
				merged.append(_normalize_closed_polygon_start(candidate))
		if merge_guard >= 1024:
			for pending_poly_any in pending:
				var pending_poly: PackedVector2Array = pending_poly_any
				if pending_poly.size() >= 3:
					merged.append(_normalize_closed_polygon_start(pending_poly))
	return merged


func _get_merged_mainland_polygons_from_nodes(province_nodes: Array) -> Array:
	var province_polygons: Array = []
	for province_node_any in province_nodes:
		var province_node: Node = province_node_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		var poly: PackedVector2Array = _get_logical_province_polygon(province_node)
		if poly.size() >= 3:
			province_polygons.append(poly)
	return _merge_polygon_collection(province_polygons)


func _get_logical_province_polygon(province_node: Node) -> PackedVector2Array:
	if province_node != null and province_node.has_meta("province_polygon"):
		var meta_poly: PackedVector2Array = province_node.get_meta("province_polygon")
		if meta_poly.size() >= 3:
			return meta_poly
	var fill: Polygon2D = get_province_fill_node(province_node)
	if fill != null and fill.polygon.size() >= 3:
		return fill.polygon
	return PackedVector2Array()


func _get_province_center_from_polygon(poly: PackedVector2Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for point in poly:
		sum += point
	return sum / float(poly.size())



func _points_match(a: Vector2, b: Vector2, tolerance: float = 0.25) -> bool:
	return a.distance_to(b) <= tolerance


func _is_point_on_segment(point: Vector2, a: Vector2, b: Vector2, tolerance: float = 0.25) -> bool:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq <= 0.000001:
		return point.distance_to(a) <= tolerance
	var cross_amount: float = absf((point - a).cross(ab))
	if cross_amount > tolerance * sqrt(ab_len_sq):
		return false
	var t: float = (point - a).dot(ab) / ab_len_sq
	return t >= -0.001 and t <= 1.001


func _add_unique_breakpoint(points: Array, point: Vector2, t: float, tolerance: float = 0.25) -> Array:
	for i in range(points.size()):
		var existing: Dictionary = points[i]
		var existing_point: Vector2 = existing.get("point", Vector2.ZERO)
		if existing_point.distance_to(point) <= tolerance:
			var existing_t: float = float(existing.get("t", 0.0))
			existing["point"] = existing_point.lerp(point, 0.5)
			existing["t"] = (existing_t + t) * 0.5
			points[i] = existing
			return points
	points.append({"point": point, "t": t})
	return points


func _sort_breakpoints(points: Array) -> Array:
	var sorted_points: Array = points.duplicate(true)
	sorted_points.sort_custom(func(a, b):
		return float(a.get("t", 0.0)) < float(b.get("t", 0.0))
	)
	return sorted_points


func _get_collinear_overlap(a: Vector2, b: Vector2, c: Vector2, d: Vector2, tolerance: float = 0.25) -> Dictionary:
	var ab: Vector2 = b - a
	var cd: Vector2 = d - c
	var ab_len_sq: float = ab.length_squared()
	var cd_len_sq: float = cd.length_squared()
	if ab_len_sq <= 0.000001 or cd_len_sq <= 0.000001:
		return {"valid": false}
	var parallel_measure: float = absf(ab.cross(cd))
	var parallel_limit: float = tolerance * sqrt(ab_len_sq * cd_len_sq)
	if parallel_measure > parallel_limit:
		return {"valid": false}
	var line_limit: float = tolerance * sqrt(ab_len_sq)
	if absf((c - a).cross(ab)) > line_limit or absf((d - a).cross(ab)) > line_limit:
		return {"valid": false}
	var inv_ab_len_sq: float = 1.0 / ab_len_sq
	var t0: float = (c - a).dot(ab) * inv_ab_len_sq
	var t1: float = (d - a).dot(ab) * inv_ab_len_sq
	var start_t: float = maxf(0.0, minf(t0, t1))
	var end_t: float = minf(1.0, maxf(t0, t1))
	if end_t - start_t <= 0.001:
		return {"valid": false}
	var p0: Vector2 = a.lerp(b, start_t)
	var p1: Vector2 = a.lerp(b, end_t)
	var inv_cd_len_sq: float = 1.0 / cd_len_sq
	var u0: float = (p0 - c).dot(cd) * inv_cd_len_sq
	var u1: float = (p1 - c).dot(cd) * inv_cd_len_sq
	return {
		"valid": true,
		"a_p0": p0,
		"a_p1": p1,
		"a_t0": start_t,
		"a_t1": end_t,
		"b_p0": c.lerp(d, u0),
		"b_p1": c.lerp(d, u1),
		"b_t0": u0,
		"b_t1": u1
	}


func _append_point_if_distinct(points: PackedVector2Array, point: Vector2) -> PackedVector2Array:
	if points.is_empty() or points[points.size() - 1].distance_to(point) > 0.001:
		points.append(point)
	return points


func _append_fragment_to_runs(runs: Array, current_points: PackedVector2Array, a: Vector2, b: Vector2) -> Dictionary:
	var working: PackedVector2Array = current_points
	if working.is_empty():
		working.append(a)
		working.append(b)
		return {"runs": runs, "current": working}
	var tail: Vector2 = working[working.size() - 1]
	if tail.distance_to(a) <= 0.001:
		working = _append_point_if_distinct(working, b)
		return {"runs": runs, "current": working}
	if tail.distance_to(b) <= 0.001:
		working = _append_point_if_distinct(working, a)
		return {"runs": runs, "current": working}
	runs.append({"points": working, "closed": false})
	var restarted: PackedVector2Array = PackedVector2Array([a, b])
	return {"runs": runs, "current": restarted}


func _finalize_shared_runs(runs: Array, current_points: PackedVector2Array) -> Array:
	if not current_points.is_empty():
		runs.append({"points": current_points, "closed": false})
	if runs.size() > 1:
		var first: Dictionary = runs[0]
		var last: Dictionary = runs[runs.size() - 1]
		var first_points: PackedVector2Array = first.get("points", PackedVector2Array())
		var last_points: PackedVector2Array = last.get("points", PackedVector2Array())
		if first_points.size() >= 2 and last_points.size() >= 2 and last_points[last_points.size() - 1].distance_to(first_points[0]) <= 0.001:
			var merged: PackedVector2Array = PackedVector2Array()
			for point in last_points:
				merged = _append_point_if_distinct(merged, point)
			for i in range(1, first_points.size()):
				merged = _append_point_if_distinct(merged, first_points[i])
			runs[runs.size() - 1] = {"points": merged, "closed": false}
			runs.remove_at(0)
	for i in range(runs.size()):
		var entry: Dictionary = runs[i]
		var points: PackedVector2Array = entry.get("points", PackedVector2Array())
		if points.size() >= 3 and points[0].distance_to(points[points.size() - 1]) <= 0.001:
			points.remove_at(points.size() - 1)
			entry["points"] = points
			entry["closed"] = true
			runs[i] = entry
	return runs


func _build_province_shared_runs_from_graph(province_data: Dictionary, edge_fragment_map: Dictionary, atomic_segments: Dictionary) -> Array:
	var runs: Array = []
	var current_points: PackedVector2Array = PackedVector2Array()
	var poly: PackedVector2Array = province_data.get("polygon", PackedVector2Array())
	for edge_index in range(poly.size()):
		var fragments: Array = edge_fragment_map.get(edge_index, [])
		if fragments.is_empty():
			if not current_points.is_empty():
				runs.append({"points": current_points, "closed": false})
				current_points = PackedVector2Array()
			continue
		var sorted_fragments: Array = fragments.duplicate(true)
		sorted_fragments.sort_custom(func(a, b):
			return float(a.get("t0", 0.0)) < float(b.get("t0", 0.0))
		)
		for fragment_any in sorted_fragments:
			var fragment: Dictionary = fragment_any
			var atomic_key: String = String(fragment.get("key", ""))
			var atomic_entry: Dictionary = atomic_segments.get(atomic_key, {})
			var province_ids: Array = atomic_entry.get("province_ids", [])
			if province_ids.size() < 2:
				if not current_points.is_empty():
					runs.append({"points": current_points, "closed": false})
					current_points = PackedVector2Array()
				continue
			var a: Vector2 = fragment.get("a", Vector2.ZERO)
			var b: Vector2 = fragment.get("b", Vector2.ZERO)
			var result: Dictionary = _append_fragment_to_runs(runs, current_points, a, b)
			runs = result.get("runs", runs)
			current_points = result.get("current", PackedVector2Array())
	return _finalize_shared_runs(runs, current_points)


func _collect_province_border_segments(province_nodes: Array) -> Dictionary:
	var provinces: Array = []
	var edge_records: Array = []
	var tolerance: float = 0.25
	for province_node_any in province_nodes:
		var province_node: Node = province_node_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		if not province_node.has_meta("province_data"):
			continue
		var province_state: Dictionary = province_node.get_meta("province_data")
		var province_id: int = int(province_state.get("id", -1))
		var poly: PackedVector2Array = _ensure_polygon_ccw(_get_logical_province_polygon(province_node))
		if poly.size() < 3:
			continue
		var province_entry := {
			"id": province_id,
			"polygon": poly,
			"node": province_node
		}
		provinces.append(province_entry)
		for edge_index in range(poly.size()):
			var a: Vector2 = poly[edge_index]
			var b: Vector2 = poly[(edge_index + 1) % poly.size()]
			if a.distance_to(b) <= 0.001:
				continue
			edge_records.append({
				"province_id": province_id,
				"edge_index": edge_index,
				"a": a,
				"b": b,
				"breakpoints": [
					{"point": a, "t": 0.0},
					{"point": b, "t": 1.0}
				]
			})
	for i in range(edge_records.size()):
		for j in range(i + 1, edge_records.size()):
			var rec_a: Dictionary = edge_records[i]
			var rec_b: Dictionary = edge_records[j]
			if int(rec_a.get("province_id", -1)) == int(rec_b.get("province_id", -1)):
				continue
			var overlap: Dictionary = _get_collinear_overlap(
				rec_a.get("a", Vector2.ZERO),
				rec_a.get("b", Vector2.ZERO),
				rec_b.get("a", Vector2.ZERO),
				rec_b.get("b", Vector2.ZERO),
				tolerance
			)
			if not bool(overlap.get("valid", false)):
				continue
			var rec_a_breakpoints: Array = rec_a.get("breakpoints", [])
			rec_a_breakpoints = _add_unique_breakpoint(rec_a_breakpoints, overlap.get("a_p0", Vector2.ZERO), float(overlap.get("a_t0", 0.0)), tolerance)
			rec_a_breakpoints = _add_unique_breakpoint(rec_a_breakpoints, overlap.get("a_p1", Vector2.ZERO), float(overlap.get("a_t1", 1.0)), tolerance)
			rec_a["breakpoints"] = rec_a_breakpoints
			edge_records[i] = rec_a
			var rec_b_breakpoints: Array = rec_b.get("breakpoints", [])
			rec_b_breakpoints = _add_unique_breakpoint(rec_b_breakpoints, overlap.get("b_p0", Vector2.ZERO), float(overlap.get("b_t0", 0.0)), tolerance)
			rec_b_breakpoints = _add_unique_breakpoint(rec_b_breakpoints, overlap.get("b_p1", Vector2.ZERO), float(overlap.get("b_t1", 1.0)), tolerance)
			rec_b["breakpoints"] = rec_b_breakpoints
			edge_records[j] = rec_b
	var atomic_segments: Dictionary = {}
	var province_edge_fragments: Dictionary = {}
	var shared_edge_keys: Dictionary = {}
	for record_any in edge_records:
		var record: Dictionary = record_any
		var province_id: int = int(record.get("province_id", -1))
		var edge_index: int = int(record.get("edge_index", -1))
		var breakpoints: Array = _sort_breakpoints(record.get("breakpoints", []))
		for point_index in range(breakpoints.size() - 1):
			var bp_a: Dictionary = breakpoints[point_index]
			var bp_b: Dictionary = breakpoints[point_index + 1]
			var a: Vector2 = bp_a.get("point", Vector2.ZERO)
			var b: Vector2 = bp_b.get("point", Vector2.ZERO)
			if a.distance_to(b) <= 0.001:
				continue
			var midpoint: Vector2 = (a + b) * 0.5
			if not _is_point_on_segment(midpoint, record.get("a", Vector2.ZERO), record.get("b", Vector2.ZERO), tolerance):
				continue
			var key: String = _edge_key(a, b)
			var entry: Dictionary = atomic_segments.get(key, {
				"a": a,
				"b": b,
				"province_ids": [],
				"fragments": []
			})
			var province_ids: Array = entry.get("province_ids", [])
			var present: bool = false
			for existing_id_any in province_ids:
				if int(existing_id_any) == province_id:
					present = true
					break
			if not present:
				province_ids.append(province_id)
			entry["province_ids"] = province_ids
			var fragments: Array = entry.get("fragments", [])
			fragments.append({
				"province_id": province_id,
				"edge_index": edge_index,
				"a": a,
				"b": b,
				"t0": float(bp_a.get("t", 0.0)),
				"t1": float(bp_b.get("t", 1.0))
			})
			entry["fragments"] = fragments
			atomic_segments[key] = entry
			var by_province: Dictionary = province_edge_fragments.get(province_id, {})
			var edge_fragments: Array = by_province.get(edge_index, [])
			edge_fragments.append({
				"key": key,
				"a": a,
				"b": b,
				"t0": float(bp_a.get("t", 0.0)),
				"t1": float(bp_b.get("t", 1.0))
			})
			by_province[edge_index] = edge_fragments
			province_edge_fragments[province_id] = by_province
	for atomic_key_any in atomic_segments.keys():
		var atomic_key: String = String(atomic_key_any)
		var atomic_entry: Dictionary = atomic_segments.get(atomic_key, {})
		var province_ids: Array = atomic_entry.get("province_ids", [])
		if province_ids.size() >= 2:
			shared_edge_keys[atomic_key] = true
	var province_runs: Dictionary = {}
	for province_any in provinces:
		var province_entry: Dictionary = province_any
		var province_id: int = int(province_entry.get("id", -1))
		var edge_fragment_map: Dictionary = province_edge_fragments.get(province_id, {})
		province_runs[province_id] = _build_province_shared_runs_from_graph(province_entry, edge_fragment_map, atomic_segments)
	return {
		"provinces": provinces,
		"atomic_segments": atomic_segments,
		"shared_edge_keys": shared_edge_keys,
		"province_runs": province_runs
	}


func _get_shared_segment_left_right_ids(a: Vector2, b: Vector2, province_ids: Array, province_centers: Dictionary) -> Dictionary:
	if province_ids.size() < 2:
		return {"left_id": -1, "right_id": -1}
	var tangent: Vector2 = b - a
	if tangent.length_squared() <= 0.000001:
		return {"left_id": int(province_ids[0]), "right_id": int(province_ids[1])}
	var normal: Vector2 = Vector2(-tangent.y, tangent.x).normalized()
	var mid: Vector2 = (a + b) * 0.5
	var id_a: int = int(province_ids[0])
	var id_b: int = int(province_ids[1])
	var center_a: Vector2 = province_centers.get(id_a, Vector2.ZERO)
	var center_b: Vector2 = province_centers.get(id_b, Vector2.ZERO)
	var score_a: float = (center_a - mid).dot(normal)
	var score_b: float = (center_b - mid).dot(normal)
	if score_a > score_b:
		return {"left_id": id_a, "right_id": id_b}
	if score_b > score_a:
		return {"left_id": id_b, "right_id": id_a}
	if id_a <= id_b:
		return {"left_id": id_a, "right_id": id_b}
	return {"left_id": id_b, "right_id": id_a}


func _walk_shared_display_run(start_node_key: String, start_segment_key: String, adjacency: Dictionary, atomic_segments: Dictionary, province_centers: Dictionary, visited: Dictionary) -> Dictionary:
	var segments: Array = []
	var current_node_key: String = start_node_key
	var current_segment_key: String = start_segment_key
	var closed: bool = false
	var guard: int = 0
	while current_segment_key != "" and guard < 4096:
		guard += 1
		if visited.has(current_segment_key):
			break
		visited[current_segment_key] = true
		var atomic_entry: Dictionary = atomic_segments.get(current_segment_key, {})
		var a: Vector2 = atomic_entry.get("a", Vector2.ZERO)
		var b: Vector2 = atomic_entry.get("b", Vector2.ZERO)
		var a_key: String = _vector_key(a)
		var b_key: String = _vector_key(b)
		var from_point: Vector2 = a
		var to_point: Vector2 = b
		var next_node_key: String = b_key
		if current_node_key == b_key:
			from_point = b
			to_point = a
			next_node_key = a_key
		var side_ids: Dictionary = _get_shared_segment_left_right_ids(from_point, to_point, atomic_entry.get("province_ids", []), province_centers)
		segments.append({
			"a": from_point,
			"b": to_point,
			"left_id": int(side_ids.get("left_id", -1)),
			"right_id": int(side_ids.get("right_id", -1))
		})
		if next_node_key == start_node_key:
			closed = true
			break
		var incident: Array = adjacency.get(next_node_key, [])
		if incident.size() != 2:
			break
		var next_segment_key: String = ""
		for incident_any in incident:
			var incident_entry: Dictionary = incident_any
			var candidate_key: String = String(incident_entry.get("segment_key", ""))
			if not visited.has(candidate_key):
				next_segment_key = candidate_key
				break
		if next_segment_key == "":
			break
		current_node_key = next_node_key
		current_segment_key = next_segment_key
	return {
		"segments": segments,
		"closed": closed
	}


func _split_shared_display_segments(oriented_segments: Array, closed: bool) -> Array:
	var runs: Array = []
	if oriented_segments.is_empty():
		return runs
	var current_left_id: int = int(oriented_segments[0].get("left_id", -1))
	var current_right_id: int = int(oriented_segments[0].get("right_id", -1))
	var current_points: PackedVector2Array = PackedVector2Array()
	current_points.append(oriented_segments[0].get("a", Vector2.ZERO))
	current_points.append(oriented_segments[0].get("b", Vector2.ZERO))
	for i in range(1, oriented_segments.size()):
		var segment: Dictionary = oriented_segments[i]
		var seg_left_id: int = int(segment.get("left_id", -1))
		var seg_right_id: int = int(segment.get("right_id", -1))
		var seg_a: Vector2 = segment.get("a", Vector2.ZERO)
		var seg_b: Vector2 = segment.get("b", Vector2.ZERO)
		var same_side_ids: bool = seg_left_id == current_left_id and seg_right_id == current_right_id
		var connects_to_tail: bool = current_points[current_points.size() - 1].distance_to(seg_a) <= 0.001
		if same_side_ids and connects_to_tail:
			current_points = _append_point_if_distinct(current_points, seg_b)
			continue
		var current_closed: bool = false
		if closed and current_points.size() >= 3 and current_points[0].distance_to(current_points[current_points.size() - 1]) <= 0.001:
			current_points.remove_at(current_points.size() - 1)
			current_closed = true
		runs.append({
			"points": current_points,
			"closed": current_closed,
			"left_id": current_left_id,
			"right_id": current_right_id
		})
		current_left_id = seg_left_id
		current_right_id = seg_right_id
		current_points = PackedVector2Array([seg_a, seg_b])
	var final_closed: bool = false
	if closed and current_points.size() >= 3 and current_points[0].distance_to(current_points[current_points.size() - 1]) <= 0.001:
		current_points.remove_at(current_points.size() - 1)
		final_closed = true
	runs.append({
		"points": current_points,
		"closed": final_closed,
		"left_id": current_left_id,
		"right_id": current_right_id
	})
	return runs


func _collect_shared_border_display_runs(border_graph: Dictionary, province_centers: Dictionary) -> Array:
	var runs: Array = []
	var atomic_segments: Dictionary = border_graph.get("atomic_segments", {})
	var adjacency: Dictionary = {}
	for atomic_key_any in atomic_segments.keys():
		var atomic_key: String = String(atomic_key_any)
		var atomic_entry: Dictionary = atomic_segments.get(atomic_key, {})
		var province_ids: Array = atomic_entry.get("province_ids", [])
		if province_ids.size() < 2:
			continue
		var a: Vector2 = atomic_entry.get("a", Vector2.ZERO)
		var b: Vector2 = atomic_entry.get("b", Vector2.ZERO)
		var a_key: String = _vector_key(a)
		var b_key: String = _vector_key(b)
		if not adjacency.has(a_key):
			adjacency[a_key] = []
		if not adjacency.has(b_key):
			adjacency[b_key] = []
		adjacency[a_key].append({"segment_key": atomic_key})
		adjacency[b_key].append({"segment_key": atomic_key})
	var visited: Dictionary = {}
	for node_key_any in adjacency.keys():
		var node_key: String = String(node_key_any)
		var incident: Array = adjacency.get(node_key, [])
		if incident.size() == 2:
			continue
		for incident_any in incident:
			var incident_entry: Dictionary = incident_any
			var segment_key: String = String(incident_entry.get("segment_key", ""))
			if segment_key == "" or visited.has(segment_key):
				continue
			var walked: Dictionary = _walk_shared_display_run(node_key, segment_key, adjacency, atomic_segments, province_centers, visited)
			var oriented_segments: Array = walked.get("segments", [])
			if oriented_segments.is_empty():
				continue
			for run_any in _split_shared_display_segments(oriented_segments, bool(walked.get("closed", false))):
				runs.append(run_any)
	for atomic_key_any in atomic_segments.keys():
		var atomic_key: String = String(atomic_key_any)
		var atomic_entry: Dictionary = atomic_segments.get(atomic_key, {})
		var province_ids: Array = atomic_entry.get("province_ids", [])
		if province_ids.size() < 2 or visited.has(atomic_key):
			continue
		var a: Vector2 = atomic_entry.get("a", Vector2.ZERO)
		var loop_walked: Dictionary = _walk_shared_display_run(_vector_key(a), atomic_key, adjacency, atomic_segments, province_centers, visited)
		var loop_segments: Array = loop_walked.get("segments", [])
		if loop_segments.is_empty():
			continue
		for run_any in _split_shared_display_segments(loop_segments, bool(loop_walked.get("closed", false))):
			runs.append(run_any)
	return runs


func _build_shared_border_centerline(points: PackedVector2Array, closed: bool) -> PackedVector2Array:
	if closed:
		if points.size() < 3:
			return PackedVector2Array()
		return make_smoothed_province_display_polyline(_ensure_polygon_ccw(points), 0.0)
	if points.size() < 2:
		return PackedVector2Array()
	var smooth: PackedVector2Array = _smooth_open_province_polyline(points)
	return _extend_open_polyline(smooth, get_province_shared_border_run_extension())


func _build_shared_border_side_line(center_points: PackedVector2Array, offset: float, closed: bool) -> PackedVector2Array:
	if closed:
		return center_points
	return _offset_open_polyline(center_points, offset)


func _polyline_side_score(points: PackedVector2Array, probe_point: Vector2) -> float:
	if points.size() < 2:
		return 0.0
	var score: float = 0.0
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var tangent: Vector2 = b - a
		if tangent.length_squared() <= 0.000001:
			continue
		var normal: Vector2 = Vector2(-tangent.y, tangent.x).normalized()
		var mid: Vector2 = (a + b) * 0.5
		score += (probe_point - mid).dot(normal)
	return score


func _offset_open_polyline(points: PackedVector2Array, offset: float) -> PackedVector2Array:
	if points.size() < 2 or absf(offset) <= 0.001:
		return points
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(points.size()):
		var prev: Vector2 = points[maxi(i - 1, 0)]
		var nxt: Vector2 = points[mini(i + 1, points.size() - 1)]
		var tangent: Vector2 = nxt - prev
		if tangent.length_squared() <= 0.000001 and i < points.size() - 1:
			tangent = points[i + 1] - points[i]
		elif tangent.length_squared() <= 0.000001 and i > 0:
			tangent = points[i] - points[i - 1]
		if tangent.length_squared() <= 0.000001:
			out.append(points[i])
			continue
		var normal: Vector2 = Vector2(-tangent.y, tangent.x).normalized()
		out.append(points[i] + normal * offset)
	return out


func _extend_open_polyline(points: PackedVector2Array, extension: float) -> PackedVector2Array:
	if points.size() < 2 or extension <= 0.001:
		return points
	var out: PackedVector2Array = PackedVector2Array(points)
	var first_dir: Vector2 = points[1] - points[0]
	if first_dir.length_squared() > 0.000001:
		out[0] = points[0] - first_dir.normalized() * extension
	var last_index: int = points.size() - 1
	var last_dir: Vector2 = points[last_index] - points[last_index - 1]
	if last_dir.length_squared() > 0.000001:
		out[last_index] = points[last_index] + last_dir.normalized() * extension
	return out


func _add_shared_border_line(parent: Node2D, name: String, points: PackedVector2Array, width: float, color: Color, z_index: int, closed: bool = false) -> void:
	if parent == null:
		return
	if closed:
		if points.size() < 3:
			return
	else:
		if points.size() < 2:
			return
	var line := Line2D.new()
	line.name = name
	line.points = points
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.closed = closed
	line.z_index = z_index
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.round_precision = 8
	parent.add_child(line)

func _add_shared_border_underlay_line(parent: Node2D, name: String, points: PackedVector2Array, width: float, color: Color, z_index: int, closed: bool = false) -> void:
	var underlay_color: Color = color
	underlay_color.a = clampf(color.a, 0.0, 1.0)
	_add_shared_border_line(parent, name, points, width, underlay_color, z_index, closed)


func _add_shared_border_ownership_fill_line(parent: Node2D, name: String, points: PackedVector2Array, width: float, color: Color, z_index: int, closed: bool = false) -> void:
	var fill_color: Color = color
	fill_color.a = clampf(color.a, 0.0, 1.0)
	_add_shared_border_line(parent, name, points, width, fill_color, z_index, closed)


func _collect_province_shared_boundary_runs(province_node: Node, border_graph: Dictionary) -> Array:
	var runs: Array = []
	if province_node == null or not is_instance_valid(province_node):
		return runs
	if not province_node.has_meta("province_data"):
		return runs
	var province_data: Dictionary = province_node.get_meta("province_data")
	var province_id: int = int(province_data.get("id", -1))
	var province_runs: Dictionary = border_graph.get("province_runs", {})
	return province_runs.get(province_id, [])


func _build_province_shared_inset_data(points: PackedVector2Array, province_center: Vector2, inset_distance: float, closed: bool) -> Dictionary:
	if closed:
		if points.size() < 3:
			return {"points": PackedVector2Array(), "inward_sign": 1.0}
		return {
			"points": make_smoothed_province_display_polyline(_ensure_polygon_ccw(points), inset_distance),
			"inward_sign": 1.0
		}
	if points.size() < 2:
		return {"points": PackedVector2Array(), "inward_sign": 1.0}
	var smooth: PackedVector2Array = _smooth_open_province_polyline(points)
	if smooth.size() < 2:
		return {"points": PackedVector2Array(), "inward_sign": 1.0}
	smooth = _extend_open_polyline(smooth, get_province_shared_border_run_extension())
	var inward_score: float = _polyline_side_score(smooth, province_center)
	var offset_sign: float = 1.0 if inward_score >= 0.0 else -1.0
	return {
		"points": _offset_open_polyline(smooth, inset_distance * offset_sign),
		"inward_sign": offset_sign
	}


func _build_province_shared_inset_line(points: PackedVector2Array, province_center: Vector2, inset_distance: float, closed: bool) -> PackedVector2Array:
	var inset_data: Dictionary = _build_province_shared_inset_data(points, province_center, inset_distance, closed)
	return inset_data.get("points", PackedVector2Array())

func _build_open_ribbon_polygon(points: PackedVector2Array, start_offset: float, end_offset: float) -> PackedVector2Array:
	if points.size() < 2:
		return PackedVector2Array()
	var side_a: PackedVector2Array = _offset_open_polyline(points, start_offset)
	var side_b: PackedVector2Array = _offset_open_polyline(points, end_offset)
	if side_a.size() < 2 or side_b.size() < 2:
		return PackedVector2Array()
	var poly: PackedVector2Array = PackedVector2Array()
	for point in side_a:
		poly.append(point)
	for i in range(side_b.size() - 1, -1, -1):
		poly.append(side_b[i])
	return poly


func _add_shared_border_strip(parent: Node2D, name: String, center_points: PackedVector2Array, inner_offset: float, outer_offset: float, color: Color, z_index: int) -> void:
	if parent == null or center_points.size() < 2:
		return
	var poly_points: PackedVector2Array = _build_open_ribbon_polygon(center_points, inner_offset, outer_offset)
	if poly_points.size() < 3:
		return
	var poly := Polygon2D.new()
	poly.name = name
	poly.polygon = poly_points
	poly.color = color
	poly.z_index = z_index
	parent.add_child(poly)


func _add_locked_province_inner_line(parent: Node2D, name: String, points: PackedVector2Array, width: float, color: Color, z_index: int) -> void:
	if parent == null or points.size() < 2:
		return
	var line := Line2D.new()
	line.name = name
	line.points = points
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.closed = false
	line.z_index = z_index
	parent.add_child(line)


func _set_locked_province_inner_overlay_color(color: Color) -> void:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return
	var overlay: Node2D = _main.provinces_root.get_node_or_null("SharedProvinceBorderOverlay") as Node2D
	if overlay == null:
		return
	var locked_overlay: Node2D = overlay.get_node_or_null(LOCKED_PROVINCE_INNER_OVERLAY_NAME) as Node2D
	if locked_overlay == null:
		return
	for child in locked_overlay.get_children():
		if child is Line2D:
			(child as Line2D).default_color = color


func _refresh_locked_province_inner_overlay(parent: Node2D, display_runs: Array, active_locked_id: int, base_color: Color) -> void:
	if parent == null:
		return
	var locked_overlay: Node2D = parent.get_node_or_null(LOCKED_PROVINCE_INNER_OVERLAY_NAME) as Node2D
	if locked_overlay == null:
		locked_overlay = Node2D.new()
		locked_overlay.name = LOCKED_PROVINCE_INNER_OVERLAY_NAME
		_set_canvas_item_layer(locked_overlay, PROVINCE_BORDER_OVERLAYS_Z_INDEX, false)
		parent.add_child(locked_overlay)
	for child in locked_overlay.get_children():
		locked_overlay.remove_child(child)
		child.free()
	if active_locked_id < 0:
		return
	var pulse_width: float = maxf(0.1, LevelConfig.PROVINCE_SHARED_BORDER_WIDTH)
	for run_idx in range(display_runs.size()):
		var run_data: Dictionary = display_runs[run_idx]
		var closed: bool = bool(run_data.get("closed", false))
		var left_id: int = int(run_data.get("left_id", -1))
		var right_id: int = int(run_data.get("right_id", -1))
		var line_points: PackedVector2Array = PackedVector2Array()
		if left_id == active_locked_id:
			line_points = run_data.get("left_points", PackedVector2Array())
		elif right_id == active_locked_id:
			line_points = run_data.get("right_points", PackedVector2Array())
		else:
			continue
		if closed and line_points.size() < 3:
			continue
		if not closed and line_points.size() < 2:
			continue
		_add_shared_border_line(locked_overlay, "LockedProvinceInner_%d" % run_idx, line_points, pulse_width, base_color, 0, closed)

func _collect_shared_border_overlay_color_maps(province_nodes: Array) -> Dictionary:
	var province_colors: Dictionary = {}
	var province_fill_colors: Dictionary = {}
	for province_node_any in province_nodes:
		var province_node: Node = province_node_any
		if province_node == null or not is_instance_valid(province_node):
			continue
		var province_data: Dictionary = province_node.get_meta("province_data") if province_node.has_meta("province_data") else {}
		var province_id: int = int(province_data.get("id", -1))
		var fill_node: Polygon2D = get_province_fill_node(province_node)
		var fill_color: Color = fill_node.color if fill_node != null else LevelConfig.PROVINCE_BORDER_COLOR
		province_fill_colors[province_id] = fill_color
		province_colors[province_id] = get_province_border_line_color(fill_color)
	return {
		"province_colors": province_colors,
		"province_fill_colors": province_fill_colors
	}


func _update_shared_border_overlay_line_colors(overlay: Node2D, display_runs: Array, province_colors: Dictionary, province_fill_colors: Dictionary) -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	for run_idx in range(display_runs.size()):
		var run_data: Dictionary = display_runs[run_idx]
		var closed: bool = bool(run_data.get("closed", false))
		var left_id: int = int(run_data.get("left_id", -1))
		var right_id: int = int(run_data.get("right_id", -1))
		var left_points: PackedVector2Array = run_data.get("left_points", PackedVector2Array())
		var right_points: PackedVector2Array = run_data.get("right_points", PackedVector2Array())
		if left_id >= 0 and ((closed and left_points.size() >= 3) or (not closed and left_points.size() >= 2)):
			var left_border_color: Color = province_colors.get(left_id, LevelConfig.PROVINCE_BORDER_COLOR)
			var left_fill_color: Color = province_fill_colors.get(left_id, left_border_color)
			var left_ownership: Node = overlay.get_node_or_null("SharedProvinceOwnershipLeft_%d" % run_idx)
			if left_ownership is Line2D:
				(left_ownership as Line2D).default_color = left_fill_color
			var left_band: Node = overlay.get_node_or_null("SharedProvinceBandLeft_%d" % run_idx)
			if left_band is Line2D:
				(left_band as Line2D).default_color = left_border_color
			var left_border: Node = overlay.get_node_or_null("SharedProvinceBorderLeft_%d" % run_idx)
			if left_border is Line2D:
				(left_border as Line2D).default_color = left_border_color
		if right_id >= 0 and ((closed and right_points.size() >= 3) or (not closed and right_points.size() >= 2)):
			var right_border_color: Color = province_colors.get(right_id, LevelConfig.PROVINCE_BORDER_COLOR)
			var right_fill_color: Color = province_fill_colors.get(right_id, right_border_color)
			var right_ownership: Node = overlay.get_node_or_null("SharedProvinceOwnershipRight_%d" % run_idx)
			if right_ownership is Line2D:
				(right_ownership as Line2D).default_color = right_fill_color
			var right_band: Node = overlay.get_node_or_null("SharedProvinceBandRight_%d" % run_idx)
			if right_band is Line2D:
				(right_band as Line2D).default_color = right_border_color
			var right_border: Node = overlay.get_node_or_null("SharedProvinceBorderRight_%d" % run_idx)
			if right_border is Line2D:
				(right_border as Line2D).default_color = right_border_color


func _clear_shared_border_overlay_children(overlay: Node2D) -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.free()
	_shared_border_overlay_children_geometry_signature = -1
	_shared_border_overlay_last_locked_province_id = -2


func _refresh_shared_province_border_overlay() -> void:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return
	var overlay: Node2D = _main.provinces_root.get_node_or_null("SharedProvinceBorderOverlay") as Node2D
	if overlay == null:
		overlay = Node2D.new()
		overlay.name = "SharedProvinceBorderOverlay"
		_set_canvas_item_layer(overlay, PROVINCE_BORDERS_Z_INDEX, false)
		_main.provinces_root.add_child(overlay)
	_mark_province_node_cache_dirty()
	var province_nodes: Array = _get_cached_province_nodes()
	var geometry_signature: int = _compute_shared_border_overlay_geometry_signature(province_nodes)
	if geometry_signature != _shared_border_overlay_geometry_signature or _shared_border_overlay_cached_display_runs.is_empty():
		_shared_border_overlay_cached_display_runs = _build_cached_shared_border_display_runs(province_nodes)
		_shared_border_overlay_geometry_signature = geometry_signature
	var color_maps: Dictionary = _collect_shared_border_overlay_color_maps(province_nodes)
	var province_colors: Dictionary = color_maps.get("province_colors", {})
	var province_fill_colors: Dictionary = color_maps.get("province_fill_colors", {})
	var active_locked_id: int = _main._locked_province_id_after_win if _main._current_phase == "grand_map" else -1
	var locked_inner_color := Color(1.0, 1.0, 1.0, 0.95)
	var can_recolor_existing_overlay: bool = (
		geometry_signature == _shared_border_overlay_children_geometry_signature
		and overlay.get_child_count() > 0
		and not _shared_border_overlay_cached_display_runs.is_empty()
	)
	if can_recolor_existing_overlay:
		_update_shared_border_overlay_line_colors(overlay, _shared_border_overlay_cached_display_runs, province_colors, province_fill_colors)
		if active_locked_id != _shared_border_overlay_last_locked_province_id:
			_refresh_locked_province_inner_overlay(overlay, _shared_border_overlay_cached_display_runs, active_locked_id, locked_inner_color)
			_shared_border_overlay_last_locked_province_id = active_locked_id
		return

	_clear_shared_border_overlay_children(overlay)
	var line_width: float = get_province_shared_border_width()
	var band_width: float = get_province_shared_border_band_width()
	var ownership_fill_width: float = get_province_shared_ownership_fill_width()
	for run_idx in range(_shared_border_overlay_cached_display_runs.size()):
		var run_data: Dictionary = _shared_border_overlay_cached_display_runs[run_idx]
		var closed: bool = bool(run_data.get("closed", false))
		var left_id: int = int(run_data.get("left_id", -1))
		var right_id: int = int(run_data.get("right_id", -1))
		var left_points: PackedVector2Array = run_data.get("left_points", PackedVector2Array())
		var right_points: PackedVector2Array = run_data.get("right_points", PackedVector2Array())
		if left_id >= 0 and ((closed and left_points.size() >= 3) or (not closed and left_points.size() >= 2)):
			var left_border_color: Color = province_colors.get(left_id, LevelConfig.PROVINCE_BORDER_COLOR)
			var left_fill_color: Color = province_fill_colors.get(left_id, left_border_color)
			_add_shared_border_ownership_fill_line(overlay, "SharedProvinceOwnershipLeft_%d" % run_idx, left_points, ownership_fill_width, left_fill_color, 2, closed)
			_add_shared_border_underlay_line(overlay, "SharedProvinceBandLeft_%d" % run_idx, left_points, band_width, left_border_color, 3, closed)
			_add_shared_border_line(overlay, "SharedProvinceBorderLeft_%d" % run_idx, left_points, line_width, left_border_color, 0, closed)
		if right_id >= 0 and ((closed and right_points.size() >= 3) or (not closed and right_points.size() >= 2)):
			var right_border_color: Color = province_colors.get(right_id, LevelConfig.PROVINCE_BORDER_COLOR)
			var right_fill_color: Color = province_fill_colors.get(right_id, right_border_color)
			_add_shared_border_ownership_fill_line(overlay, "SharedProvinceOwnershipRight_%d" % run_idx, right_points, ownership_fill_width, right_fill_color, 2, closed)
			_add_shared_border_underlay_line(overlay, "SharedProvinceBandRight_%d" % run_idx, right_points, band_width, right_border_color, 3, closed)
			_add_shared_border_line(overlay, "SharedProvinceBorderRight_%d" % run_idx, right_points, line_width, right_border_color, 0, closed)
	_refresh_locked_province_inner_overlay(overlay, _shared_border_overlay_cached_display_runs, active_locked_id, locked_inner_color)
	_shared_border_overlay_children_geometry_signature = geometry_signature
	_shared_border_overlay_last_locked_province_id = active_locked_id


func format_province_counts_text(province_state: Dictionary) -> String:
	var troops: int = int(province_state.get("remaining_troops", 0))
	var buildings: int = int(province_state.get("remaining_buildings", 0))
	var invading_troops: int = int(province_state.get("invading_troops", 0))
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
		return "T:%d  B:%d  INV:%d" % [troops, buildings, invading_troops]
	return "T:%d  B:%d" % [troops, buildings]


func refresh_province_label_layout(province_node: Node, province_id: int, province_state: Dictionary) -> void:
	var counts_bg: Control = get_province_counts_background_node(province_node)
	var counts_label: Label = get_province_counts_label_node(province_node)
	if counts_bg == null and counts_label == null:
		return
	ensure_province_counts_draw_order(counts_bg, counts_label)

	var box_size: Vector2 = get_province_info_box_size(province_state)
	var center: Vector2 = get_label_display_center(province_node, counts_bg, counts_label, box_size)
	var top_left: Vector2 = center - box_size * 0.5
	var fill: Polygon2D = get_province_fill_node(province_node)
	var visuals_color: Color = fill.color if fill != null else get_base_province_fill_color(province_state, province_id)

	var panel_root: Control = _get_province_info_panel_root(province_node)
	if panel_root != null:
		panel_root.position = top_left
		_refresh_province_info_panel(panel_root, province_id, province_state)
		_layout_province_building_visuals(province_node, province_state, top_left, box_size, visuals_color)
		return

	if counts_bg != null:
		counts_bg.position = top_left
		counts_bg.size = box_size

	if counts_label != null:
		counts_label.position = top_left
		counts_label.size = box_size
		counts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		counts_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		counts_label.clip_text = false
		counts_label.text = get_province_info_text(province_id, province_state)
	_layout_province_building_visuals(province_node, province_state, top_left, box_size, visuals_color)

func cache_ball_end_world_pos(pos: Vector2) -> void:
	if _main == null:
		return
	_main._last_ball_end_world_pos = pos
	_main._has_last_ball_end_world_pos = true


func resolve_ball_end_world_pos() -> Vector2:
	if _main == null:
		return Vector2.ZERO
	if _main._has_last_ball_end_world_pos:
		return _main._last_ball_end_world_pos
	if _main.ball and is_instance_valid(_main.ball):
		return _main.ball.global_position
	return Vector2.ZERO


func clear_cached_ball_end_world_pos() -> void:
	if _main == null:
		return
	_main._has_last_ball_end_world_pos = false
	_main._last_ball_end_world_pos = Vector2.ZERO

func get_province_capture_source_by_id(province_id: int) -> String:
	if _main == null:
		return CAPTURE_SOURCE_NONE
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return CAPTURE_SOURCE_NONE
	var state: Dictionary = _main._province_persistence[index]
	return String(state.get("capture_source", CAPTURE_SOURCE_NONE))


func set_province_capture_source_by_id(province_id: int, capture_source: String) -> void:
	if _main == null:
		return
	var index: int = find_persistence_index_by_id(province_id)
	if index == -1:
		return
	var normalized: String = String(capture_source)
	var state: Dictionary = _main._province_persistence[index]
	state["capture_source"] = normalized
	if is_instance_valid(_main.provinces_root):
		var province_node: Node = _get_cached_province_node_by_id(province_id)
		if province_node != null and province_node.has_meta("province_data"):
			var meta_data: Dictionary = province_node.get_meta("province_data")
			meta_data["capture_source"] = normalized
			province_node.set_meta("province_data", meta_data)


func clear_province_capture_source_by_id(province_id: int) -> void:
	set_province_capture_source_by_id(province_id, CAPTURE_SOURCE_NONE)


func mark_province_captured_by_player_engagement(province_id: int) -> void:
	set_province_capture_source_by_id(province_id, CAPTURE_SOURCE_PLAYER_ENGAGEMENT)


func mark_province_captured_by_friendly_march(province_id: int) -> void:
	set_province_capture_source_by_id(province_id, CAPTURE_SOURCE_FRIENDLY_MARCH)


func count_friendly_provinces_captured_by_player_engagement() -> int:
	if _main == null:
		return 0
	var count: int = 0
	for province_state in _main._province_persistence:
		if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		if String(province_state.get("capture_source", CAPTURE_SOURCE_NONE)) == CAPTURE_SOURCE_PLAYER_ENGAGEMENT:
			count += 1
	return count



func get_province_type_from_node(province_node: Node) -> String:
	if not is_instance_valid(province_node):
		return LevelConfig.PROVINCE_TYPE_NEUTRAL
	if province_node.has_meta("province_data"):
		var meta_data: Dictionary = province_node.get_meta("province_data")
		return String(meta_data.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	var fill: Polygon2D = get_province_fill_node(province_node)
	if fill == null:
		return LevelConfig.PROVINCE_TYPE_NEUTRAL
	if fill.color == LevelConfig.PROVINCE_FRIENDLY_INVADED_COLOR:
		return LevelConfig.PROVINCE_TYPE_FRIENDLY
	if fill.color == LevelConfig.PROVINCE_FRIENDLY_COLOR:
		return LevelConfig.PROVINCE_TYPE_FRIENDLY
	for neutral_color in LevelConfig.PROVINCE_FILL_COLORS:
		if fill.color == neutral_color:
			return LevelConfig.PROVINCE_TYPE_NEUTRAL
	return LevelConfig.PROVINCE_TYPE_ENEMY


func normalize_neighbor_ids(raw_neighbors) -> Array[int]:
	var out: Array[int] = []
	if raw_neighbors is Array:
		for n in raw_neighbors:
			out.append(int(n))
	return out


func province_has_friendly_neighbor(province_state: Dictionary) -> bool:
	if _main == null:
		return false
	for neighbor_id in normalize_neighbor_ids(province_state.get("neighbors", [])):
		var neighbor_index: int = find_persistence_index_by_id(int(neighbor_id))
		if neighbor_index == -1:
			continue
		var neighbor_state: Dictionary = _main._province_persistence[neighbor_index]
		if String(neighbor_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return true
	return false


func get_total_friendly_gold_income() -> int:
	if _main == null:
		return 0
	var total: int = 0
	for province_state in _main._province_persistence:
		if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		total += get_province_total_income(province_state)
	return total


func polygons_share_edge(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() < 2 or b.size() < 2:
		return false
	var shared_points: Array[Vector2] = []
	for pa in a:
		var va: Vector2 = pa
		var already_counted: bool = false
		for sp in shared_points:
			if va.distance_to(sp) <= 0.5:
				already_counted = true
				break
		if already_counted:
			continue
		for pb in b:
			var vb: Vector2 = pb
			if va.distance_to(vb) <= 0.5:
				shared_points.append(va)
				if shared_points.size() >= 2:
					return true
				break
	return false


func apply_persistence_to_province_visuals() -> void:
	if _main == null or not is_instance_valid(_main.provinces_root):
		return

	var province_nodes: Array = _get_cached_province_nodes()
	for province_node in province_nodes:
		if not is_instance_valid(province_node):
			continue

		var province_id: int = -1
		var tint_idx: int = 0
		if province_node.has_meta("province_data"):
			var meta_data: Dictionary = province_node.get_meta("province_data")
			province_id = int(meta_data.get("id", -1))
			tint_idx = int(meta_data.get("tint_index", 0))

		var province_index: int = find_persistence_index_by_id(province_id)
		if province_index == -1:
			continue

		var province_state: Dictionary = _main._province_persistence[province_index]
		normalize_province_economy_state(province_state)
		var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		var invading_troops: int = int(province_state.get("invading_troops", 0))
		var is_target: bool = is_target_province_state(province_state)
		var is_boss_home: bool = is_boss_home_province_state(province_state)
		var base_fill_color: Color = get_base_province_fill_color(province_state, tint_idx)
		var is_locked_launch_province: bool = (_main._current_phase == "grand_map" and province_id == _main._locked_province_id_after_win)
		var has_pending_friendly_invasion: bool = province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0

		if province_node.has_meta("province_data"):
			var synced_meta: Dictionary = province_node.get_meta("province_data")
			synced_meta["type"] = province_type
			synced_meta[PROVINCE_NAME_KEY] = _resolve_province_name(province_id, province_state, synced_meta)
			synced_meta["troops"] = int(province_state.get("remaining_troops", 0))
			synced_meta["buildings"] = int(province_state.get("remaining_buildings", 0))
			synced_meta["invading_troops"] = invading_troops
			synced_meta["faction_id"] = int(province_state.get("faction_id", 0))
			synced_meta["construction_progress"] = int(province_state.get("construction_progress", 0))
			synced_meta["neighbors"] = normalize_neighbor_ids(province_state.get("neighbors", []))
			synced_meta["is_target"] = is_target
			synced_meta["capture_source"] = String(province_state.get("capture_source", CAPTURE_SOURCE_NONE))
			synced_meta[BOSS_HOME_FLAG_KEY] = is_boss_home
			synced_meta[CALTROPS_KEY] = _normalize_caltrop_entries(province_state.get(CALTROPS_KEY, []))
			synced_meta[PROVINCE_GOLD_PRODUCTION_KEY] = get_province_gold_production(province_state)
			synced_meta[PROVINCE_FREE_BUILDINGS_KEY] = get_province_free_buildings(province_state)
			synced_meta[PROVINCE_BUILDING_CAPACITY_KEY] = get_province_building_capacity(province_state)
			synced_meta[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = get_province_engagement_map_type(province_state)
			_copy_economy_fields_to_dictionary(province_state, synced_meta)
			province_node.set_meta("province_data", synced_meta)

		var fill: Polygon2D = get_province_fill_node(province_node)
		var cached_geometry: Dictionary = {}
		if fill != null:
			fill.name = "ProvinceFill"
			_set_canvas_item_layer(fill, PROVINCE_FILL_Z_INDEX, false)
			if is_locked_launch_province:
				var highlighted_fill: Color = base_fill_color.lightened(0.38)
				highlighted_fill.a = minf(0.72, base_fill_color.a + 0.24)
				fill.color = highlighted_fill
			else:
				fill.color = base_fill_color
			cached_geometry = _ensure_cached_province_display_geometry(province_node, fill)
			var pending_invasion_overlay: Polygon2D = _ensure_pending_invasion_pattern_overlay_node(province_node)
			if pending_invasion_overlay != null:
				pending_invasion_overlay.polygon = fill.polygon
				pending_invasion_overlay.texture = _get_pending_invasion_pattern_texture()
				pending_invasion_overlay.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
				pending_invasion_overlay.texture_scale = Vector2.ONE
				var pending_pattern_color: Color = LevelConfig.get_province_pending_invasion_pattern_color()
				pending_pattern_color.a = LevelConfig.get_province_pending_invasion_pattern_opacity()
				pending_invasion_overlay.color = pending_pattern_color
				pending_invasion_overlay.antialiased = true
				_set_canvas_item_layer(pending_invasion_overlay, PROVINCE_FILL_Z_INDEX + 1, false)
				pending_invasion_overlay.visible = has_pending_friendly_invasion

			var pattern_overlay: Polygon2D = _ensure_locked_province_pattern_overlay_node(province_node)
			if pattern_overlay != null:
				pattern_overlay.polygon = fill.polygon
				pattern_overlay.texture = _get_locked_province_pattern_texture()
				pattern_overlay.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
				pattern_overlay.texture_scale = Vector2.ONE
				var pattern_color: Color = LevelConfig.get_province_launch_pattern_color()
				pattern_color.a = LevelConfig.get_province_launch_pattern_opacity()
				pattern_overlay.color = pattern_color
				pattern_overlay.antialiased = true
				_set_canvas_item_layer(pattern_overlay, PROVINCE_FILL_Z_INDEX + 2, false)
				pattern_overlay.visible = is_locked_launch_province

		var target_overlay: Polygon2D = get_province_target_overlay_node(province_node)
		if target_overlay != null:
			_set_canvas_item_layer(target_overlay, PROVINCE_BORDER_OVERLAYS_Z_INDEX, false)
			target_overlay.visible = is_target
			if is_target:
				var overlay_color: Color = LevelConfig.TARGET_PROVINCE_FILL_TINT
				if is_locked_launch_province:
					overlay_color = overlay_color.lightened(0.15)
				target_overlay.color = overlay_color

		var fill_node: Polygon2D = get_province_fill_node(province_node)
		var border_line_color: Color = get_province_border_line_color(base_fill_color)
		if is_locked_launch_province:
			border_line_color = border_line_color.lightened(0.08)

		var border: Line2D = get_province_border_node(province_node)
		if border != null:
			border.name = "ProvinceBorder"
			_set_canvas_item_layer(border, PROVINCE_BORDERS_Z_INDEX, false)
			border.default_color = border_line_color
			border.width = get_province_outer_line_width()
			border.visible = false
			if fill_node != null:
				var border_points: PackedVector2Array = cached_geometry.get("border_points", PackedVector2Array())
				if border_points.is_empty():
					border_points = make_smoothed_province_display_polyline(fill_node.polygon, maxf(0.5, get_province_outer_line_width() * 0.5))
				border.points = border_points

		var inner_glow: Line2D = ensure_province_inner_glow_node(province_node)
		if inner_glow != null:
			inner_glow.name = "ProvinceInnerGlow"
			inner_glow.width = get_province_inner_line_width()
			inner_glow.antialiased = true
			inner_glow.closed = true
			_set_canvas_item_layer(inner_glow, PROVINCE_BORDER_OVERLAYS_Z_INDEX, false)
			if fill_node != null:
				var inner_points: PackedVector2Array = cached_geometry.get("inner_points", PackedVector2Array())
				if inner_points.is_empty():
					inner_points = make_smoothed_province_display_polyline(fill_node.polygon, maxf(0.5, get_province_outer_line_width() * 0.5 + get_province_inner_line_inset()))
				inner_glow.points = inner_points
			var pulse_base_color: Color = border_line_color
			pulse_base_color.a = 1.0
			inner_glow.default_color = pulse_base_color
			inner_glow.visible = false

		_layout_province_troop_visuals(province_node, province_state, base_fill_color)
		_enforce_province_line_visibility(province_node, false)

		var counts_bg: Control = get_province_counts_background_node(province_node)
		var counts_label: Label = get_province_counts_label_node(province_node)
		ensure_province_counts_draw_order(counts_bg, counts_label)

		var panel_root: Control = _get_province_info_panel_root(province_node)
		if panel_root == null:
			var legacy_bg: ColorRect = counts_bg as ColorRect
			if legacy_bg != null:
				if is_boss_home:
					legacy_bg.color = BOSS_HOME_INFO_BOX_BG_COLOR.lightened(0.06) if is_locked_launch_province else BOSS_HOME_INFO_BOX_BG_COLOR
				elif is_target:
					legacy_bg.color = LevelConfig.TARGET_PROVINCE_INFO_BOX_BG_COLOR.lightened(0.08) if is_locked_launch_province else LevelConfig.TARGET_PROVINCE_INFO_BOX_BG_COLOR
				else:
					legacy_bg.color = Color(0.22, 0.18, 0.06, 0.82) if is_locked_launch_province else LevelConfig.PROVINCE_INFO_BOX_BG_COLOR

			if counts_label != null:
				counts_label.add_theme_font_size_override("font_size", LevelConfig.PROVINCE_INFO_COUNTS_FONT_SIZE)
				var label_color: Color = LevelConfig.PROVINCE_INFO_TEXT_COLOR
				if is_boss_home:
					label_color = BOSS_HOME_INFO_TEXT_COLOR
				elif is_target:
					label_color = LevelConfig.TARGET_PROVINCE_INFO_TEXT_COLOR
				counts_label.add_theme_color_override("font_color", label_color)
				counts_label.add_theme_constant_override("outline_size", LevelConfig.PROVINCE_INFO_OUTLINE_SIZE)
				counts_label.add_theme_color_override("font_outline_color", LevelConfig.PROVINCE_INFO_OUTLINE_COLOR)

		refresh_province_label_layout(province_node, province_id, province_state)

	_refresh_province_build_mode_overlay()
	_refresh_shared_province_border_overlay()


func play_boss_attack_province_opacity_pulses(province_ids: Array[int]) -> void:
	if _main == null or province_ids.is_empty():
		return
	var pulse_seconds: float = LevelConfig.get_boss_attack_province_opacity_pulse_seconds()
	if pulse_seconds <= 0.0:
		return
	for province_id in province_ids:
		_play_single_boss_attack_province_opacity_pulse(int(province_id), pulse_seconds)


func _play_single_boss_attack_province_opacity_pulse(province_id: int, pulse_seconds: float) -> void:
	if province_id < 0:
		return
	var province_node: Node = _get_cached_province_node_by_id(province_id)
	if province_node == null or not is_instance_valid(province_node):
		return

	var province_index: int = find_persistence_index_by_id(province_id)
	if province_index < 0 or province_index >= _main._province_persistence.size():
		return
	var province_state: Dictionary = _main._province_persistence[province_index]
	var tint_idx: int = 0
	if province_node.has_meta("province_data"):
		var meta_data: Dictionary = province_node.get_meta("province_data")
		tint_idx = int(meta_data.get("tint_index", 0))

	var fill: Polygon2D = get_province_fill_node(province_node)
	if fill == null:
		return

	var current_alpha: float = clampf(fill.color.a, 0.0, 1.0)
	var base_color: Color = get_base_province_fill_color(province_state, tint_idx)
	base_color.a = current_alpha
	fill.color = base_color

	var peak_color: Color = base_color
	peak_color.a = 1.0

	var half_duration: float = maxf(0.01, pulse_seconds * 0.5)
	var tween: Tween = _main.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(fill, "color", peak_color, half_duration)
	tween.tween_property(fill, "color", base_color, half_duration)


func update_launch_province_pulse(time_seconds: float) -> void:
	# Kept for compatibility with existing callers; launch highlighting now uses
	# a persistent diamond fill pattern instead of a pulsing border line.
	_launch_pulse_last_quantized_step = int(floor(time_seconds / maxf(0.01, LAUNCH_PULSE_QUANTIZE_STEP_SECONDS)))


# =============================================================================
# UNIFIED CONTEXT HELPER (used by resolver and Main)
# =============================================================================
func get_province_context(province_id: int) -> Dictionary:
	if _main == null or province_id == -1:
		return _make_empty_province_context(province_id)

	var index := find_persistence_index_by_id(province_id)
	if index == -1:
		return _make_empty_province_context(province_id)

	var state: Dictionary = _main._province_persistence[index]
	normalize_province_economy_state(state)
	var caltrops: Array[Dictionary] = _normalize_caltrop_entries(state.get(CALTROPS_KEY, []))
	var active_caltrop_count: int = 0
	for caltrop in caltrops:
		if not bool(caltrop.get("destroyed", false)):
			active_caltrop_count += 1

	var context: Dictionary = {
		"id": int(state.get("id", province_id)),
		"type": String(state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
		PROVINCE_NAME_KEY: _resolve_province_name(province_id, state),
		"remaining_troops": int(state.get("remaining_troops", 0)),
		"remaining_buildings": int(state.get("remaining_buildings", 0)),
		"invading_troops": int(state.get("invading_troops", 0)),
		"faction_id": int(state.get("faction_id", 0)),
		"construction_progress": int(state.get("construction_progress", 0)),
		"is_target": bool(state.get("is_target", false)),
		"capture_source": String(state.get("capture_source", CAPTURE_SOURCE_NONE)),
		"neighbors": normalize_neighbor_ids(state.get("neighbors", [])),
		"is_boss_home": bool(state.get(BOSS_HOME_FLAG_KEY, false)),
		"caltrops": caltrops,
		"active_caltrop_count": active_caltrop_count,
		PROVINCE_GOLD_PRODUCTION_KEY: get_province_gold_production(state),
		PROVINCE_FREE_BUILDINGS_KEY: get_province_free_buildings(state),
		PROVINCE_BUILDING_CAPACITY_KEY: get_province_building_capacity(state),
		PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: get_province_engagement_map_type(state)
	}
	_copy_economy_fields_to_dictionary(state, context)
	return context

func find_first_province_id_for_phase(requested_phase: String = "") -> int:
	if _main == null:
		return -1

	var enemy_fallback: int = -1
	var invaded_friendly_fallback: int = -1
	var neutral_fallback: int = -1
	var friendly_fallback: int = -1

	for p in _main._province_persistence:
		var province_id: int = int(p.get("id", -1))
		var province_type: String = String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		var invading_troops: int = int(p.get("invading_troops", 0))
		var relation: String = get_relation_to_player_for_province_state(p)

		match requested_phase:
			"offensive":
				if relation == RELATION_HOSTILE or relation == RELATION_ALLY:
					return province_id
			"defensive":
				if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
					return province_id
			"neutral":
				if province_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
					return province_id
			"grand_map":
				if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
					return province_id

		if enemy_fallback == -1 and (relation == RELATION_HOSTILE or relation == RELATION_ALLY):
			enemy_fallback = province_id
		if invaded_friendly_fallback == -1 and province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and invading_troops > 0:
			invaded_friendly_fallback = province_id
		if neutral_fallback == -1 and province_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
			neutral_fallback = province_id
		if friendly_fallback == -1 and province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			friendly_fallback = province_id

	match requested_phase:
		"offensive":
			return enemy_fallback
		"defensive":
			return invaded_friendly_fallback
		"neutral":
			return neutral_fallback
		"grand_map":
			if friendly_fallback != -1:
				return friendly_fallback
			return invaded_friendly_fallback

	if enemy_fallback != -1:
		return enemy_fallback
	if invaded_friendly_fallback != -1:
		return invaded_friendly_fallback
	if neutral_fallback != -1:
		return neutral_fallback
	return friendly_fallback


func make_stable_province_encounter_seed(province_id: int) -> int:
	if _main == null:
		return 1
	var mixed: int = int(hash("%d|province_encounter|%d" % [_main.map_seed, province_id]))
	mixed = mixed & 0x7fffffff
	return mixed if mixed != 0 else 1


func ensure_province_encounter_layout(province_id: int) -> Dictionary:
	if _main == null:
		return {
			"seed": 1,
			"level": 1,
			"map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		}

	var encounter_seed: int = make_stable_province_encounter_seed(province_id)
	var encounter_level: int = maxi(1, _main.level_index)
	var province_index: int = find_persistence_index_by_id(province_id)

	if province_index == -1:
		return {
			"seed": encounter_seed,
			"level": encounter_level,
			"map_type": LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		}

	var province_state: Dictionary = _main._province_persistence[province_index]

	encounter_seed = int(province_state.get("encounter_seed", 0))
	if encounter_seed == 0:
		encounter_seed = make_stable_province_encounter_seed(province_id)
		province_state["encounter_seed"] = encounter_seed

	encounter_level = int(province_state.get("encounter_level", 0))
	if encounter_level <= 0:
		encounter_level = maxi(1, _main.level_index)
		province_state["encounter_level"] = encounter_level

	return {
		"seed": encounter_seed,
		"level": encounter_level,
		"map_type": get_province_engagement_map_type(province_state)
	}

func sync_province_persistence() -> void:
	if _main == null:
		return

	if not is_instance_valid(_main.provinces_root):
		_main._province_persistence.clear()
		return

	var previous_by_id: Dictionary = {}
	for p in _main._province_persistence:
		var pid: int = int(p.get("id", -1))
		var previous_entry: Dictionary = {
			"id": pid,
			"type": String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			PROVINCE_NAME_KEY: String(p.get(PROVINCE_NAME_KEY, "")).strip_edges(),
			"remaining_buildings": int(p.get("remaining_buildings", LevelConfig.get_initial_province_buildings(LevelConfig.PROVINCE_TYPE_NEUTRAL))),
			"remaining_troops": int(p.get("remaining_troops", LevelConfig.get_initial_province_troops(LevelConfig.PROVINCE_TYPE_NEUTRAL))),
			"neighbors": normalize_neighbor_ids(p.get("neighbors", [])),
			"invading_troops": int(p.get("invading_troops", 0)),
			"encounter_seed": int(p.get("encounter_seed", 0)),
			"encounter_level": int(p.get("encounter_level", 0)),
			"faction_id": int(p.get("faction_id", 0)),
			"construction_progress": int(p.get("construction_progress", 0)),
			"is_target": bool(p.get("is_target", false)),
			"capture_source": String(p.get("capture_source", CAPTURE_SOURCE_NONE)),
			"is_boss_home": bool(p.get(BOSS_HOME_FLAG_KEY, false)),
			"caltrops": _normalize_caltrop_entries(p.get(CALTROPS_KEY, [])),
			PROVINCE_GOLD_PRODUCTION_KEY: LevelConfig.clamp_province_gold_production(int(p.get(PROVINCE_GOLD_PRODUCTION_KEY, 0))),
			PROVINCE_FREE_BUILDINGS_KEY: LevelConfig.clamp_province_free_buildings(int(p.get(PROVINCE_FREE_BUILDINGS_KEY, 0))),
			PROVINCE_BUILDING_CAPACITY_KEY: LevelConfig.clamp_province_building_cap(int(p.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN))),
			PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: LevelConfig.normalize_engagement_map_type(String(p.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)))
		}
		_copy_economy_fields_to_dictionary(p, previous_entry)
		previous_by_id[pid] = previous_entry

	var runtime_entries: Array[Dictionary] = []
	var polygons: Array[PackedVector2Array] = []

	for idx in range(_main.provinces_root.get_child_count()):
		var province_node: Node = _main.provinces_root.get_child(idx)
		if not is_instance_valid(province_node):
			continue
		if String(province_node.name) == "BossVisualRoot":
			continue
		var province_id: int = idx
		var province_type: String = get_province_type_from_node(province_node)
		var neighbors: Array[int] = []
		var meta_buildings: int = 0
		var meta_troops: int = 0
		var meta_province_name: String = ""
		var meta_invading_troops: int = 0
		var meta_faction_id: int = 0
		var meta_is_target: bool = false
		var meta_capture_source: String = CAPTURE_SOURCE_NONE
		var meta_construction_progress: int = 0
		var meta_is_boss_home: bool = false
		var meta_caltrops: Array[Dictionary] = []
		var meta_gold_production: int = 0
		var meta_free_buildings: int = 0
		var meta_building_capacity: int = LevelConfig.PROVINCE_BUILDING_CAP_MIN
		var meta_engagement_map_type: String = LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		var meta_economy_source: Dictionary = {}

		if province_node.has_meta("province_data"):
			var meta_data: Dictionary = province_node.get_meta("province_data")
			meta_economy_source = meta_data.duplicate(true)
			province_id = int(meta_data.get("id", idx))
			province_type = String(meta_data.get("type", province_type))
			neighbors = normalize_neighbor_ids(meta_data.get("neighbors", []))
			meta_buildings = int(meta_data.get("buildings", 0))
			meta_troops = int(meta_data.get("troops", 0))
			meta_province_name = String(meta_data.get(PROVINCE_NAME_KEY, "")).strip_edges()
			meta_invading_troops = int(meta_data.get("invading_troops", 0))
			meta_faction_id = int(meta_data.get("faction_id", 0))
			meta_is_target = bool(meta_data.get("is_target", false))
			meta_capture_source = String(meta_data.get("capture_source", CAPTURE_SOURCE_NONE))
			meta_construction_progress = int(meta_data.get("construction_progress", 0))
			meta_is_boss_home = bool(meta_data.get(BOSS_HOME_FLAG_KEY, false))
			meta_caltrops = _normalize_caltrop_entries(meta_data.get(CALTROPS_KEY, []))
			meta_gold_production = LevelConfig.clamp_province_gold_production(int(meta_data.get(PROVINCE_GOLD_PRODUCTION_KEY, 0)))
			meta_free_buildings = LevelConfig.clamp_province_free_buildings(int(meta_data.get(PROVINCE_FREE_BUILDINGS_KEY, 0)))
			meta_building_capacity = LevelConfig.clamp_province_building_cap(int(meta_data.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN)))
			meta_engagement_map_type = LevelConfig.normalize_engagement_map_type(String(meta_data.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)))
			if province_type == LevelConfig.PROVINCE_TYPE_ENEMY and not meta_is_boss_home and not previous_by_id.has(province_id):
				meta_troops += _get_campaign_enemy_troop_level_bonus_total()

		var defaults: Dictionary = get_default_province_counts(province_type)
		if meta_buildings <= 0 and province_type != LevelConfig.PROVINCE_TYPE_NEUTRAL:
			meta_buildings = int(defaults.get("remaining_buildings", 0))
		if meta_troops <= 0 and province_type != LevelConfig.PROVINCE_TYPE_NEUTRAL:
			meta_troops = int(defaults.get("remaining_troops", 0))
		if province_type == LevelConfig.PROVINCE_TYPE_ENEMY and meta_faction_id <= 0:
			meta_faction_id = int(defaults.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT))

		var entry: Dictionary = {
			"id": province_id,
			"type": province_type,
			PROVINCE_NAME_KEY: meta_province_name if province_node.has_meta("province_data") else "",
			"remaining_buildings": meta_buildings if province_node.has_meta("province_data") else int(defaults.get("remaining_buildings", 0)),
			"remaining_troops": meta_troops if province_node.has_meta("province_data") else int(defaults.get("remaining_troops", 0)),
			"neighbors": neighbors,
			"invading_troops": meta_invading_troops if province_node.has_meta("province_data") else 0,
			"encounter_seed": 0,
			"encounter_level": 0,
			"faction_id": meta_faction_id if province_node.has_meta("province_data") else int(defaults.get("faction_id", 0)),
			"construction_progress": meta_construction_progress if province_node.has_meta("province_data") else int(defaults.get("construction_progress", 0)),
			"is_target": meta_is_target if province_node.has_meta("province_data") else false,
			"capture_source": meta_capture_source if province_node.has_meta("province_data") else CAPTURE_SOURCE_NONE,
			"is_boss_home": meta_is_boss_home if province_node.has_meta("province_data") else false,
			"caltrops": meta_caltrops if province_node.has_meta("province_data") else [],
			PROVINCE_GOLD_PRODUCTION_KEY: meta_gold_production if province_node.has_meta("province_data") else 0,
			PROVINCE_FREE_BUILDINGS_KEY: meta_free_buildings if province_node.has_meta("province_data") else 0,
			PROVINCE_BUILDING_CAPACITY_KEY: meta_building_capacity if province_node.has_meta("province_data") else LevelConfig.PROVINCE_BUILDING_CAP_MIN,
			PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: meta_engagement_map_type if province_node.has_meta("province_data") else LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		}

		if previous_by_id.has(province_id):
			var prev: Dictionary = previous_by_id[province_id]
			entry["type"] = String(prev.get("type", entry["type"]))
			if String(entry.get(PROVINCE_NAME_KEY, "")).strip_edges().is_empty():
				entry[PROVINCE_NAME_KEY] = String(prev.get(PROVINCE_NAME_KEY, "")).strip_edges()
			entry["remaining_buildings"] = int(prev.get("remaining_buildings", entry["remaining_buildings"]))
			entry["remaining_troops"] = int(prev.get("remaining_troops", entry["remaining_troops"]))
			entry["invading_troops"] = int(prev.get("invading_troops", 0))
			entry["encounter_seed"] = int(prev.get("encounter_seed", 0))
			entry["encounter_level"] = int(prev.get("encounter_level", 0))
			entry["faction_id"] = int(prev.get("faction_id", entry["faction_id"]))
			entry["construction_progress"] = int(prev.get("construction_progress", entry["construction_progress"]))
			entry["is_target"] = bool(prev.get("is_target", entry["is_target"]))
			entry["capture_source"] = String(prev.get("capture_source", entry.get("capture_source", CAPTURE_SOURCE_NONE)))
			entry["is_boss_home"] = bool(prev.get("is_boss_home", entry.get("is_boss_home", false)))
			entry["caltrops"] = _normalize_caltrop_entries(prev.get(CALTROPS_KEY, entry.get(CALTROPS_KEY, [])))
			entry[PROVINCE_GOLD_PRODUCTION_KEY] = LevelConfig.clamp_province_gold_production(int(prev.get(PROVINCE_GOLD_PRODUCTION_KEY, entry.get(PROVINCE_GOLD_PRODUCTION_KEY, 0))))
			entry[PROVINCE_FREE_BUILDINGS_KEY] = LevelConfig.clamp_province_free_buildings(int(prev.get(PROVINCE_FREE_BUILDINGS_KEY, entry.get(PROVINCE_FREE_BUILDINGS_KEY, 0))))
			entry[PROVINCE_BUILDING_CAPACITY_KEY] = LevelConfig.clamp_province_building_cap(int(prev.get(PROVINCE_BUILDING_CAPACITY_KEY, entry.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN))))
			entry[PROVINCE_ENGAGEMENT_MAP_TYPE_KEY] = LevelConfig.normalize_engagement_map_type(String(prev.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, entry.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL))))
			_copy_economy_fields_to_dictionary(prev, entry)

			var prev_neighbors: Array[int] = normalize_neighbor_ids(prev.get("neighbors", []))
			if neighbors.is_empty() and not prev_neighbors.is_empty():
				entry["neighbors"] = prev_neighbors
		elif not meta_economy_source.is_empty():
			_copy_economy_fields_to_dictionary(meta_economy_source, entry)

		entry[PROVINCE_NAME_KEY] = _resolve_province_name(province_id, entry)
		entry[CALTROPS_KEY] = _normalize_caltrop_entries(entry.get(CALTROPS_KEY, []))
		normalize_province_variation_state(province_id, entry)
		normalize_province_economy_state(entry)
		clamp_province_buildings_to_capacity(entry)
		runtime_entries.append(entry)

		var fill: Polygon2D = get_province_fill_node(province_node)
		if fill != null:
			polygons.append(fill.polygon)
		else:
			polygons.append(PackedVector2Array())

	for i in range(runtime_entries.size()):
		var existing_neighbors: Array[int] = normalize_neighbor_ids(runtime_entries[i].get("neighbors", []))
		if not existing_neighbors.is_empty():
			runtime_entries[i]["neighbors"] = existing_neighbors
			continue

		var inferred_neighbors: Array[int] = []
		for j in range(runtime_entries.size()):
			if i == j:
				continue
			if polygons_share_edge(polygons[i], polygons[j]):
				inferred_neighbors.append(int(runtime_entries[j].get("id", j)))
		runtime_entries[i]["neighbors"] = inferred_neighbors

	_main._province_persistence = runtime_entries
	apply_persistence_to_province_visuals()


func get_province_data(world_pos: Vector2) -> Dictionary:
	if _main == null or not is_instance_valid(_main.provinces_root):
		var empty_data: Dictionary = {
			"id": -1,
			"type": LevelConfig.PROVINCE_TYPE_NEUTRAL,
			"buildings": 0,
			"troops": 0,
			"neighbors": [],
			"invading_troops": 0,
			"faction_id": 0,
			"construction_progress": 0,
			PROVINCE_NAME_KEY: "",
			"is_target": false,
			"capture_source": CAPTURE_SOURCE_NONE,
			"is_boss_home": false,
			PROVINCE_GOLD_PRODUCTION_KEY: 0,
			PROVINCE_FREE_BUILDINGS_KEY: 0,
			PROVINCE_BUILDING_CAPACITY_KEY: LevelConfig.PROVINCE_BUILDING_CAP_MIN,
			PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
		}
		_copy_economy_fields_to_dictionary(empty_data, empty_data)
		return empty_data

	var idx: int = 0
	for p_node in _main.provinces_root.get_children():
		var fill: Polygon2D = get_province_fill_node(p_node)
		if fill != null:
			var poly: PackedVector2Array = fill.polygon
			var local_pos: Vector2 = world_pos - p_node.global_position
			if Geometry2D.is_point_in_polygon(local_pos, poly):
				var province_id: int = idx
				var meta_data: Dictionary = {}
				if p_node.has_meta("province_data"):
					meta_data = p_node.get_meta("province_data")
					province_id = int(meta_data.get("id", idx))

				var province_index: int = find_persistence_index_by_id(province_id)
				if province_index != -1:
					var pers: Dictionary = _main._province_persistence[province_index]
					normalize_province_economy_state(pers)
					var persisted_data: Dictionary = {
						"id": int(pers.get("id", province_id)),
						"type": String(pers.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
						PROVINCE_NAME_KEY: _resolve_province_name(province_id, pers, meta_data),
						"buildings": int(pers.get("remaining_buildings", 0)),
						"troops": int(pers.get("remaining_troops", 0)),
						"neighbors": normalize_neighbor_ids(pers.get("neighbors", [])),
						"invading_troops": int(pers.get("invading_troops", 0)),
						"faction_id": int(pers.get("faction_id", 0)),
						"construction_progress": int(pers.get("construction_progress", 0)),
						"is_target": bool(pers.get("is_target", false)),
						"capture_source": String(pers.get("capture_source", CAPTURE_SOURCE_NONE)),
						"is_boss_home": bool(pers.get(BOSS_HOME_FLAG_KEY, false)),
						"caltrops": _normalize_caltrop_entries(pers.get(CALTROPS_KEY, [])),
						PROVINCE_GOLD_PRODUCTION_KEY: get_province_gold_production(pers),
						PROVINCE_FREE_BUILDINGS_KEY: get_province_free_buildings(pers),
						PROVINCE_BUILDING_CAPACITY_KEY: get_province_building_capacity(pers),
						PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: get_province_engagement_map_type(pers)
					}
					_copy_economy_fields_to_dictionary(pers, persisted_data)
					return persisted_data

				var fallback_data: Dictionary = {
					"id": province_id,
					"type": get_province_type_from_node(p_node),
					PROVINCE_NAME_KEY: _resolve_province_name(province_id, {}, meta_data),
					"buildings": 0,
					"troops": 0,
					"neighbors": [],
					"invading_troops": 0,
					"faction_id": 0,
					"construction_progress": int(meta_data.get("construction_progress", 0)),
					"is_target": bool(meta_data.get("is_target", false)),
					"capture_source": String(meta_data.get("capture_source", CAPTURE_SOURCE_NONE)),
					"is_boss_home": bool(meta_data.get(BOSS_HOME_FLAG_KEY, false)),
					"caltrops": _normalize_caltrop_entries(meta_data.get(CALTROPS_KEY, [])),
					PROVINCE_GOLD_PRODUCTION_KEY: LevelConfig.clamp_province_gold_production(int(meta_data.get(PROVINCE_GOLD_PRODUCTION_KEY, 0))),
					PROVINCE_FREE_BUILDINGS_KEY: LevelConfig.clamp_province_free_buildings(int(meta_data.get(PROVINCE_FREE_BUILDINGS_KEY, 0))),
					PROVINCE_BUILDING_CAPACITY_KEY: LevelConfig.clamp_province_building_cap(int(meta_data.get(PROVINCE_BUILDING_CAPACITY_KEY, LevelConfig.PROVINCE_BUILDING_CAP_MIN))),
					PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: LevelConfig.normalize_engagement_map_type(String(meta_data.get(PROVINCE_ENGAGEMENT_MAP_TYPE_KEY, LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL)))
				}
				_copy_economy_fields_to_dictionary(meta_data if not meta_data.is_empty() else fallback_data, fallback_data)
				return fallback_data
		idx += 1

	var no_hit_data: Dictionary = {
		"id": -1,
		"type": LevelConfig.PROVINCE_TYPE_NEUTRAL,
		"buildings": 0,
		"troops": 0,
		"neighbors": [],
		"invading_troops": 0,
		"faction_id": 0,
		"construction_progress": 0,
		PROVINCE_NAME_KEY: "",
		"is_target": false,
		"is_boss_home": false,
		"caltrops": [],
		PROVINCE_GOLD_PRODUCTION_KEY: 0,
		PROVINCE_FREE_BUILDINGS_KEY: 0,
		PROVINCE_BUILDING_CAPACITY_KEY: LevelConfig.PROVINCE_BUILDING_CAP_MIN,
		PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: LevelConfig.ENGAGEMENT_MAP_TYPE_NORMAL
	}
	_copy_economy_fields_to_dictionary(no_hit_data, no_hit_data)
	return no_hit_data

func make_province_snapshot_by_id() -> Dictionary:
	var snapshot_by_id: Dictionary = {}
	if _main == null:
		return snapshot_by_id

	for p in _main._province_persistence:
		var pid: int = int(p.get("id", -1))
		normalize_province_economy_state(p)
		var snapshot_entry: Dictionary = {
			"id": pid,
			"type": String(p.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			PROVINCE_NAME_KEY: _resolve_province_name(pid, p),
			"remaining_buildings": int(p.get("remaining_buildings", 0)),
			"remaining_troops": int(p.get("remaining_troops", 0)),
			"neighbors": normalize_neighbor_ids(p.get("neighbors", [])),
			"invading_troops": int(p.get("invading_troops", 0)),
			"encounter_seed": int(p.get("encounter_seed", 0)),
			"encounter_level": int(p.get("encounter_level", 0)),
			"faction_id": int(p.get("faction_id", 0)),
			"construction_progress": int(p.get("construction_progress", 0)),
			"is_target": bool(p.get("is_target", false)),
			"capture_source": String(p.get("capture_source", CAPTURE_SOURCE_NONE)),
			"is_boss_home": bool(p.get(BOSS_HOME_FLAG_KEY, false)),
			"caltrops": _normalize_caltrop_entries(p.get(CALTROPS_KEY, [])),
			PROVINCE_GOLD_PRODUCTION_KEY: get_province_gold_production(p),
			PROVINCE_FREE_BUILDINGS_KEY: get_province_free_buildings(p),
			PROVINCE_BUILDING_CAPACITY_KEY: get_province_building_capacity(p),
			PROVINCE_ENGAGEMENT_MAP_TYPE_KEY: get_province_engagement_map_type(p)
		}
		_copy_economy_fields_to_dictionary(p, snapshot_entry)
		snapshot_by_id[pid] = snapshot_entry
	return snapshot_by_id

func find_path_to_nearest_non_own_faction(source_id: int, snapshot_by_id: Dictionary) -> Array[int]:
	if not snapshot_by_id.has(source_id):
		return []

	var source_faction: int = get_province_faction(snapshot_by_id[source_id])

	var visited: Dictionary = {}
	var parent: Dictionary = {}
	var queue: Array[int] = [source_id]
	visited[source_id] = true

	var queue_index: int = 0
	while queue_index < queue.size():
		var current_id: int = int(queue[queue_index])
		queue_index += 1

		var current_state: Dictionary = snapshot_by_id.get(current_id, {})
		if current_id != source_id:
			var current_faction: int = get_province_faction(current_state)
			if current_faction != source_faction:   # allows neutrals (faction 0) AND different enemy factions
				var path: Array[int] = [current_id]
				var walk_id: int = current_id
				while parent.has(walk_id):
					walk_id = int(parent[walk_id])
					path.push_front(walk_id)
				return path

		var neighbors: Array[int] = normalize_neighbor_ids(current_state.get("neighbors", []))
		neighbors.sort()
		for neighbor_id in neighbors:
			if not snapshot_by_id.has(neighbor_id):
				continue
			if visited.has(neighbor_id):
				continue
			visited[neighbor_id] = true
			parent[neighbor_id] = current_id
			queue.append(neighbor_id)

	return []


func find_nearest_friendly_province_id(source_id: int) -> int:
	if _main == null or _main._province_persistence.is_empty():
		return -1

	var snapshot_by_id: Dictionary = make_province_snapshot_by_id()
	var visited: Dictionary = {}
	var queue: Array[int] = []

	if snapshot_by_id.has(source_id):
		queue.append(source_id)
		visited[source_id] = true
	else:
		for p in _main._province_persistence:
			var province_id: int = int(p.get("id", -1))
			queue.append(province_id)
			visited[province_id] = true

	var queue_index: int = 0
	while queue_index < queue.size():
		var current_id: int = int(queue[queue_index])
		queue_index += 1

		if snapshot_by_id.has(current_id):
			var current_state: Dictionary = snapshot_by_id.get(current_id, {})
			if String(current_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
				return current_id

			var neighbors: Array[int] = normalize_neighbor_ids(current_state.get("neighbors", []))
			neighbors.sort()
			for neighbor_id in neighbors:
				if visited.has(neighbor_id):
					continue
				if not snapshot_by_id.has(neighbor_id):
					continue
				visited[neighbor_id] = true
				queue.append(neighbor_id)

	for province_state in _main._province_persistence:
		if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_FRIENDLY:
			return int(province_state.get("id", -1))

	return -1
