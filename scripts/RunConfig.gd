extends RefCounted

const MODE_NORMAL: String = "normal"
const MODE_BOSS_DEBUG: String = "boss_debug"
const LIMB_NONE: String = ""
const LIMB_LEFT_ARM: String = "left_arm"
const LIMB_RIGHT_ARM: String = "right_arm"
const LIMB_LEFT_LEG: String = "left_leg"
const LIMB_RIGHT_LEG: String = "right_leg"

static var selected_mode: String = MODE_NORMAL
static var boss_debug_focus_limb: String = LIMB_NONE
static var boss_debug_troop_count: int = 50
static var boss_debug_selected_limb_hit_points: int = 1
static var launch_boss_debug_assault_on_start: bool = false


static func set_mode(mode: String) -> void:
	if mode == MODE_BOSS_DEBUG:
		selected_mode = MODE_BOSS_DEBUG
	else:
		selected_mode = MODE_NORMAL


static func is_boss_debug_mode() -> bool:
	return selected_mode == MODE_BOSS_DEBUG


static func normalize_focus_limb(part_name: String) -> String:
	match part_name:
		LIMB_LEFT_ARM, LIMB_RIGHT_ARM, LIMB_LEFT_LEG, LIMB_RIGHT_LEG:
			return part_name
		_:
			return LIMB_NONE


static func set_boss_debug_settings(focus_limb: String, troop_count: int, selected_limb_hit_points: int = 1) -> void:
	boss_debug_focus_limb = normalize_focus_limb(focus_limb)
	boss_debug_troop_count = maxi(1, troop_count)
	boss_debug_selected_limb_hit_points = maxi(1, selected_limb_hit_points)


static func arm_boss_debug_start() -> void:
	launch_boss_debug_assault_on_start = true


static func consume_boss_debug_start() -> bool:
	var armed: bool = launch_boss_debug_assault_on_start
	launch_boss_debug_assault_on_start = false
	return armed
