extends RefCounted

const MODE_NORMAL: String = "normal"
const MODE_BOSS_DEBUG: String = "boss_debug"

static var selected_mode: String = MODE_NORMAL


static func set_mode(mode: String) -> void:
	if mode == MODE_BOSS_DEBUG:
		selected_mode = MODE_BOSS_DEBUG
	else:
		selected_mode = MODE_NORMAL


static func is_boss_debug_mode() -> bool:
	return selected_mode == MODE_BOSS_DEBUG
