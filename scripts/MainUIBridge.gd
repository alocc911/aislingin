extends RefCounted

const LevelConfig = preload("res://scripts/LevelConfig.gd")

var _main: Node = null

var _has_last_level_text: bool = false
var _last_level_text: String = ""
var _has_last_status_text: bool = false
var _last_status_text: String = ""
var _has_last_gold_amount: bool = false
var _last_gold_amount: int = 0
var _has_last_pins_counts: bool = false
var _last_total_pins: int = 0
var _last_downed_pins: int = 0
var _has_last_upgrade_signature: bool = false
var _last_upgrade_signature: Dictionary = {}
var _has_last_magnet_button_state: bool = false
var _last_magnet_button_show: bool = false
var _last_magnet_button_remaining: int = 0
var _last_magnet_button_armed: bool = false
var _has_last_skip_button_state: bool = false
var _last_skip_button_show: bool = false
var _last_skip_button_running: bool = false
var _has_last_end_engagement_button_visible: bool = false
var _last_end_engagement_button_visible: bool = false
var _has_last_restart_only_mode: bool = false
var _last_restart_only_mode: bool = false
var _has_last_pause_button_paused: bool = false
var _last_pause_button_paused: bool = false
var _has_last_cancel_button_visible: bool = false
var _last_cancel_button_visible: bool = false
var _has_last_opening_tutorial_skip_button_state: bool = false
var _last_opening_tutorial_skip_button_show: bool = false
var _last_opening_tutorial_skip_button_label: String = ""


func setup(main_node: Node) -> void:
	_main = main_node
	_reset_ui_caches()


func setup_ui() -> void:
	if _main == null or _main.ui == null:
		return

	if _main.ui.has_signal("upgrade_purchased") and not _main.ui.upgrade_purchased.is_connected(_main._on_upgrade_purchased):
		_main.ui.upgrade_purchased.connect(_main._on_upgrade_purchased)

	if _main.ui.has_signal("pause_pressed") and not _main.ui.pause_pressed.is_connected(_main._toggle_pause):
		_main.ui.pause_pressed.connect(_main._toggle_pause)

	if _main.ui.has_signal("cancel_shot_pressed") and not _main.ui.cancel_shot_pressed.is_connected(_main._cancel_shot):
		_main.ui.cancel_shot_pressed.connect(_main._cancel_shot)

	if _main.ui.has_signal("restart_pressed") and not _main.ui.restart_pressed.is_connected(_main._restart_run):
		_main.ui.restart_pressed.connect(_main._restart_run)

	if _main.ui.has_signal("retry_level_pressed") and not _main.ui.retry_level_pressed.is_connected(_main._on_retry_level_pressed):
		_main.ui.retry_level_pressed.connect(_main._on_retry_level_pressed)

	if _main.ui.has_signal("load_seed_requested") and not _main.ui.load_seed_requested.is_connected(_main._on_load_seed_requested):
		_main.ui.load_seed_requested.connect(_main._on_load_seed_requested)

	if _main.ui.has_signal("extra_ball_pressed") and not _main.ui.extra_ball_pressed.is_connected(_main._on_extra_ball_pressed):
		_main.ui.extra_ball_pressed.connect(_main._on_extra_ball_pressed)
	if _main.ui.has_signal("place_magnet_pressed") and not _main.ui.place_magnet_pressed.is_connected(_main._on_place_magnet_pressed):
		_main.ui.place_magnet_pressed.connect(_main._on_place_magnet_pressed)
	if _main.ui.has_signal("skip_to_end_pressed") and not _main.ui.skip_to_end_pressed.is_connected(_main._on_skip_to_end_pressed):
		_main.ui.skip_to_end_pressed.connect(_main._on_skip_to_end_pressed)
	if _main.ui.has_signal("grand_map_auto_engagement_visuals_toggled") and not _main.ui.grand_map_auto_engagement_visuals_toggled.is_connected(_main._on_grand_map_auto_engagement_visuals_toggled):
		_main.ui.grand_map_auto_engagement_visuals_toggled.connect(_main._on_grand_map_auto_engagement_visuals_toggled)
	if _main.ui.has_signal("end_engagement_pressed") and not _main.ui.end_engagement_pressed.is_connected(_main._on_end_engagement_pressed):
		_main.ui.end_engagement_pressed.connect(_main._on_end_engagement_pressed)
	if _main.ui.has_signal("data_dump_requested") and not _main.ui.data_dump_requested.is_connected(_main._on_data_dump_requested):
		_main.ui.data_dump_requested.connect(_main._on_data_dump_requested)
		print("[BugReportFlow][MainUIBridge] Connected ui.data_dump_requested -> Main._on_data_dump_requested.")
	elif _main.ui.has_signal("data_dump_requested"):
		print("[BugReportFlow][MainUIBridge] ui.data_dump_requested already connected.")
	else:
		print("[BugReportFlow][MainUIBridge] ui missing data_dump_requested signal.")
	if _main.ui.has_signal("bug_report_submitted") and not _main.ui.bug_report_submitted.is_connected(_main._on_bug_report_submitted):
		_main.ui.bug_report_submitted.connect(_main._on_bug_report_submitted)
	if _main.ui.has_signal("province_construction_requested") and _main.has_method("_on_province_construction_requested"):
		var province_construction_callable: Callable = Callable(_main, "_on_province_construction_requested")
		if not _main.ui.province_construction_requested.is_connected(province_construction_callable):
			_main.ui.province_construction_requested.connect(province_construction_callable)
	if _main.ui.has_signal("province_troop_order_requested") and _main.has_method("_on_province_troop_order_requested"):
		var province_troop_order_callable: Callable = Callable(_main, "_on_province_troop_order_requested")
		if not _main.ui.province_troop_order_requested.is_connected(province_troop_order_callable):
			_main.ui.province_troop_order_requested.connect(province_troop_order_callable)
	if _main.ui.has_signal("province_march_thresholds_requested") and _main.has_method("_on_province_march_thresholds_requested"):
		var province_march_thresholds_callable: Callable = Callable(_main, "_on_province_march_thresholds_requested")
		if not _main.ui.province_march_thresholds_requested.is_connected(province_march_thresholds_callable):
			_main.ui.province_march_thresholds_requested.connect(province_march_thresholds_callable)
	if _main.ui.has_signal("build_mode_toggled") and _main.has_method("_on_build_mode_toggled"):
		var build_mode_callable: Callable = Callable(_main, "_on_build_mode_toggled")
		if not _main.ui.build_mode_toggled.is_connected(build_mode_callable):
			_main.ui.build_mode_toggled.connect(build_mode_callable)
	if _main.ui.has_signal("friendly_boss_debug_dump_requested") and not _main.ui.friendly_boss_debug_dump_requested.is_connected(_main._on_friendly_boss_debug_dump_requested):
		_main.ui.friendly_boss_debug_dump_requested.connect(_main._on_friendly_boss_debug_dump_requested)
	if _main.ui.has_signal("troop_debug_dump_requested") and not _main.ui.troop_debug_dump_requested.is_connected(_main._on_troop_debug_dump_requested):
		_main.ui.troop_debug_dump_requested.connect(_main._on_troop_debug_dump_requested)
	if _main.ui.has_signal("march_debug_dump_requested") and _main.has_method("_on_march_debug_dump_requested") and not _main.ui.march_debug_dump_requested.is_connected(_main._on_march_debug_dump_requested):
		_main.ui.march_debug_dump_requested.connect(_main._on_march_debug_dump_requested)

	if _main.ui.has_signal("bottom_bar_resized") and _main.camera_controller != null:
		var resize_callable: Callable = Callable(_main.camera_controller, "on_ui_bottom_bar_resized")
		if not _main.ui.bottom_bar_resized.is_connected(resize_callable):
			_main.ui.bottom_bar_resized.connect(resize_callable)

	_connect_tutorial_ui_signals()
	_sync_tutorial_guide_reference()

	if _main.ui.has_signal("campaign_level_mode_selected"):
		var campaign_level_mode_callable: Callable = Callable(self, "_on_campaign_level_mode_selected")
		if not _main.ui.campaign_level_mode_selected.is_connected(campaign_level_mode_callable):
			_main.ui.campaign_level_mode_selected.connect(campaign_level_mode_callable)
	if _main.ui.has_signal("pre_level_debug_config_confirmed"):
		var pre_level_debug_callable: Callable = Callable(self, "_on_pre_level_debug_config_confirmed")
		if not _main.ui.pre_level_debug_config_confirmed.is_connected(pre_level_debug_callable):
			_main.ui.pre_level_debug_config_confirmed.connect(pre_level_debug_callable)

	_reset_ui_caches()
	ui_refresh_header()
	ui_set_gold(_main.gold_balance)
	ui_set_pins_counts(0, 0)
	ui_clear_state_message()
	ui_hide_campaign_level_mode_choice()
	ui_hide_pre_level_debug_config_choice()
	ui_hide_campaign_upgrade_choice()
	ui_refresh_upgrades()
	ui_refresh_field_guide_badge()
	sync_ui_button_states()


func _reset_ui_caches() -> void:
	_has_last_level_text = false
	_last_level_text = ""
	_has_last_status_text = false
	_last_status_text = ""
	_has_last_gold_amount = false
	_last_gold_amount = 0
	_has_last_pins_counts = false
	_last_total_pins = 0
	_last_downed_pins = 0
	_has_last_upgrade_signature = false
	_last_upgrade_signature = {}
	_has_last_magnet_button_state = false
	_last_magnet_button_show = false
	_last_magnet_button_remaining = 0
	_last_magnet_button_armed = false
	_has_last_skip_button_state = false
	_last_skip_button_show = false
	_last_skip_button_running = false
	_has_last_end_engagement_button_visible = false
	_last_end_engagement_button_visible = false
	_has_last_restart_only_mode = false
	_last_restart_only_mode = false
	_has_last_pause_button_paused = false
	_last_pause_button_paused = false
	_has_last_cancel_button_visible = false
	_last_cancel_button_visible = false
	_has_last_opening_tutorial_skip_button_state = false
	_last_opening_tutorial_skip_button_show = false
	_last_opening_tutorial_skip_button_label = ""


func _get_engagement_type_label() -> String:
	if _main == null:
		return "Engagement"

	match String(_main._current_phase):
		LevelConfig.PHASE_OFFENSIVE:
			return "Offensive-Enemy"
		LevelConfig.PHASE_DEFENSIVE:
			return "Defensive"
		LevelConfig.PHASE_NEUTRAL:
			return "Offensive-Neutral"
		_:
			return "Engagement"


func _get_engagement_troop_label() -> String:
	if _main == null:
		return "Enemy"

	if String(_main._current_phase) == LevelConfig.PHASE_NEUTRAL:
		return "Neutral"
	return "Enemy"


func _get_engagement_building_label() -> String:
	if _main == null:
		return "Buildings"

	if String(_main._current_phase) == LevelConfig.PHASE_DEFENSIVE:
		return "Friendly buildings"
	return "Buildings"


func ui_refresh_header() -> void:
	if _main == null or _main.ui == null:
		return

	var level_text: String = ""
	if _main._current_phase == "grand_map":
		level_text = "Level %d — Turn %d" % [_main.get_campaign_current_level_progress(), _main.turn_number]
	else:
		level_text = _get_engagement_type_label()

	_set_level_text_if_changed(level_text)


func ui_set_level_number(level_num: int) -> void:
	if _main == null or _main.ui == null:
		return

	var txt: String = "Level %d" % level_num
	if _main._is_milestone(level_num):
		txt = "Level %d • Milestone" % level_num

	_set_level_text_if_changed(txt)


func ui_set_status(t: String) -> void:
	if _main == null or _main.ui == null:
		return
	if not _main.ui.has_method("set_status"):
		return
	if _has_last_status_text and _last_status_text == t:
		return
	_main.ui.call("set_status", t)
	_has_last_status_text = true
	_last_status_text = t

func ui_set_reopenable_summary_text(t: String) -> void:
	if _main == null or _main.ui == null:
		return
	if not _main.ui.has_method("set_reopenable_summary_text"):
		return
	_main.ui.call("set_reopenable_summary_text", t)


func ui_set_gold(amount: int) -> void:
	if _main == null or _main.ui == null:
		return

	if _main.ui.has_method("set_gold"):
		if (not _has_last_gold_amount) or _last_gold_amount != amount:
			_main.ui.call("set_gold", amount)
			_has_last_gold_amount = true
			_last_gold_amount = amount

	if _main.ui.has_method("trigger_gold_sparkles"):
		_main.ui.call("trigger_gold_sparkles")


func ui_set_pins_counts(total_pins: int, downed_pins: int) -> void:
	if _main == null or _main.ui == null:
		return
	if not _main.ui.has_method("set_pins_counts"):
		return
	if _has_last_pins_counts and _last_total_pins == total_pins and _last_downed_pins == downed_pins:
		return
	_main.ui.call("set_pins_counts", total_pins, downed_pins)
	_has_last_pins_counts = true
	_last_total_pins = total_pins
	_last_downed_pins = downed_pins


func ui_show_engagement_live_counter(total_pins: int, downed_pins: int, total_buildings: int, destroyed_buildings: int) -> void:
	if _main == null or _main.ui == null:
		return
	if _main._awaiting_engagement_summary_ack:
		return

	var standing_pins: int = maxi(0, total_pins - downed_pins)
	var standing_buildings: int = maxi(0, total_buildings - destroyed_buildings)
	var engagement_type_label: String = _get_engagement_type_label()
	var troop_label: String = _get_engagement_troop_label()
	var building_label: String = _get_engagement_building_label()
	var counter_text: String = "%s\n%s troops — Start: %d • Remaining: %d • Downed: %d\n%s — Start: %d • Remaining: %d • Destroyed: %d" % [
		engagement_type_label,
		troop_label,
		total_pins,
		standing_pins,
		downed_pins,
		building_label,
		total_buildings,
		standing_buildings,
		destroyed_buildings
	]

	ui_set_status(counter_text)


func ui_clear_state_message() -> void:
	if _main == null or _main.ui == null:
		return
	if _main.ui.has_method("clear_state_message"):
		_main.ui.call("clear_state_message")
	_has_last_status_text = true
	_last_status_text = ""


func ui_show_campaign_level_mode_choice(title_text: String = "", body_text: String = "", easy_button_text: String = "", hard_button_text: String = "") -> void:
	if _main == null or _main.ui == null:
		return
	if _main.ui.has_method("show_campaign_level_mode_choice"):
		_main.ui.call("show_campaign_level_mode_choice", title_text, body_text, easy_button_text, hard_button_text)


func ui_hide_campaign_level_mode_choice() -> void:
	if _main == null or _main.ui == null:
		return
	if _main.ui.has_method("hide_campaign_level_mode_choice"):
		_main.ui.call("hide_campaign_level_mode_choice")


func ui_is_campaign_level_mode_choice_visible() -> bool:
	if _main == null or _main.ui == null:
		return false
	if _main.ui.has_method("is_campaign_level_mode_choice_visible"):
		return bool(_main.ui.call("is_campaign_level_mode_choice_visible"))
	return false


func ui_show_pre_level_debug_config_choice(initial_friendly_troops: int, boss_head_hit_points: int, conquered_friendly_troops: int, campaign_enemy_troop_increase_per_level: int, friendly_march_bonus_troops: int, boss_show_up_on_turn: int, bonus_gold_per_turn: int, next_level_override: int) -> void:
	if _main == null or _main.ui == null:
		return
	if _main.ui.has_method("show_pre_level_debug_config_choice"):
		_main.ui.call("show_pre_level_debug_config_choice", initial_friendly_troops, boss_head_hit_points, conquered_friendly_troops, campaign_enemy_troop_increase_per_level, friendly_march_bonus_troops, boss_show_up_on_turn, bonus_gold_per_turn, next_level_override)


func ui_hide_pre_level_debug_config_choice() -> void:
	if _main == null or _main.ui == null:
		return
	if _main.ui.has_method("hide_pre_level_debug_config_choice"):
		_main.ui.call("hide_pre_level_debug_config_choice")


func ui_is_pre_level_debug_config_choice_visible() -> bool:
	if _main == null or _main.ui == null:
		return false
	if _main.ui.has_method("is_pre_level_debug_config_choice_visible"):
		return bool(_main.ui.call("is_pre_level_debug_config_choice_visible"))
	return false


func ui_show_campaign_upgrade_choice(options: Array[String], title_text: String = "", body_text: String = "") -> void:
	if _main == null or _main.ui == null:
		return
	if _main.ui.has_method("show_campaign_upgrade_choice"):
		_main.ui.call("show_campaign_upgrade_choice", options, title_text, body_text)


func ui_hide_campaign_upgrade_choice() -> void:
	if _main == null or _main.ui == null:
		return
	if _main.ui.has_method("hide_campaign_upgrade_choice"):
		_main.ui.call("hide_campaign_upgrade_choice")


func ui_is_campaign_upgrade_choice_visible() -> bool:
	if _main == null or _main.ui == null:
		return false
	if _main.ui.has_method("is_campaign_upgrade_choice_visible"):
		return bool(_main.ui.call("is_campaign_upgrade_choice_visible"))
	return false


func ui_show_between_level_summary(summary_text: String) -> void:
	if summary_text.strip_edges() == "":
		return
	ui_set_status(summary_text)


func _get_discounted_upgrade_cost_map() -> Dictionary:
	if _main == null:
		return {}

	if _main.has_method("get_discounted_upgrade_purchase_cost_map"):
		var cost_map: Variant = _main.call("get_discounted_upgrade_purchase_cost_map")
		if cost_map is Dictionary:
			return (cost_map as Dictionary).duplicate(true)

	var fallback_map: Dictionary = {}
	var upgrade_types: Array[String] = ["bigger", "heavier", "poison", "forcefield", "magnet"]
	for upgrade_type in upgrade_types:
		var cost_value: int = LevelConfig.get_upgrade_base_cost_for_type(upgrade_type)
		if _main.has_method("get_discounted_upgrade_purchase_cost"):
			cost_value = int(_main.call("get_discounted_upgrade_purchase_cost", upgrade_type))
		fallback_map[upgrade_type] = cost_value
	return fallback_map


func ui_refresh_upgrades() -> void:
	if _main == null or _main.ui == null:
		return

	var discounted_cost_map: Dictionary = _get_discounted_upgrade_cost_map()
	var upgrade_signature: Dictionary = {
		"bigger": _main.bigger_count,
		"heavier": _main.heavier_count,
		"poison": _main.poison_count,
		"forcefield": _main.forcefield_count,
		"magnet": _main.magnet_count,
		"gold": _main.gold_balance,
		"costs": discounted_cost_map.duplicate(true)
	}
	if _has_last_upgrade_signature and _last_upgrade_signature == upgrade_signature:
		_refresh_magnet_controls()
		return

	if _main.ui.has_method("set_upgrade_cost_overrides"):
		_main.ui.call("set_upgrade_cost_overrides", discounted_cost_map)

	if _main.ui.has_method("refresh_upgrades"):
		_main.ui.call("refresh_upgrades", _main.bigger_count, _main.heavier_count, _main.poison_count, _main.gold_balance)

	if _main.ui.has_method("set_forcefield_upgrade_count"):
		_main.ui.call("set_forcefield_upgrade_count", _main.forcefield_count, _main.gold_balance)

	if _main.ui.has_method("set_magnet_upgrade_count"):
		_main.ui.call("set_magnet_upgrade_count", _main.magnet_count, _main.gold_balance)

	_has_last_upgrade_signature = true
	_last_upgrade_signature = upgrade_signature
	_refresh_magnet_controls()


func ui_set_tutorial_guide(guide: RefCounted) -> void:
	if _main == null or _main.ui == null:
		return
	if not LevelConfig.is_tutorial_and_field_guide_enabled():
		return
	if _main.ui.has_method("set_tutorial_guide"):
		_main.ui.call("set_tutorial_guide", guide)
	if _main_has_property("tutorial_guide"):
		_main.set("tutorial_guide", guide)
	ui_refresh_field_guide_badge()


func ui_refresh_field_guide_badge() -> void:
	if _main == null or _main.ui == null:
		return
	if _main.ui.has_method("refresh_field_guide_badge"):
		_main.ui.call("refresh_field_guide_badge")


func ui_show_first_run_tutorial() -> void:
	if _main == null or _main.ui == null:
		return
	if not LevelConfig.should_auto_start_first_run_tutorial():
		return
	_sync_tutorial_guide_reference()
	if _main.ui.has_method("show_first_run_tutorial"):
		_main.ui.call("show_first_run_tutorial")


func ui_show_tutorial_sequence(sequence: Array[Dictionary]) -> void:
	if _main == null or _main.ui == null:
		return
	if not LevelConfig.is_tutorial_and_field_guide_enabled():
		return
	if _main.ui.has_method("show_tutorial_sequence"):
		_main.ui.call("show_tutorial_sequence", sequence)


func ui_is_tutorial_visible() -> bool:
	if _main == null or _main.ui == null:
		return false
	if _main.ui.has_method("is_tutorial_visible"):
		return bool(_main.ui.call("is_tutorial_visible"))
	return false


func ui_queue_unlocked_notes(note_entries: Array[Dictionary]) -> void:
	if _main == null or _main.ui == null:
		return
	if note_entries.is_empty():
		ui_refresh_field_guide_badge()
		return
	if _main.ui.has_method("queue_unlocked_notes"):
		_main.ui.call("queue_unlocked_notes", note_entries)
	ui_refresh_field_guide_badge()


func ui_open_field_guide(preferred_category: String = "", preferred_note_key: String = "") -> void:
	if _main == null or _main.ui == null:
		return
	_sync_tutorial_guide_reference()
	if _main.ui.has_method("open_field_guide"):
		_main.ui.call("open_field_guide", preferred_category, preferred_note_key)


func ui_close_field_guide() -> void:
	if _main == null or _main.ui == null:
		return
	if _main.ui.has_method("close_field_guide"):
		_main.ui.call("close_field_guide")


func ui_is_field_guide_open() -> bool:
	if _main == null or _main.ui == null:
		return false
	if _main.ui.has_method("is_field_guide_open"):
		return bool(_main.ui.call("is_field_guide_open"))
	return false


func ui_unlock_notes_for_event(event_key: String, show_toasts: bool = true) -> Array[Dictionary]:
	var unlocked_entries: Array[Dictionary] = []
	if not LevelConfig.should_auto_unlock_field_guide_notes():
		return unlocked_entries

	var guide: RefCounted = _get_tutorial_guide()
	if guide == null or not guide.has_method("unlock_notes_for_event"):
		return unlocked_entries

	var raw_entries: Array = guide.call("unlock_notes_for_event", event_key)
	unlocked_entries = _typed_dictionary_array(raw_entries)
	if show_toasts and not unlocked_entries.is_empty():
		ui_queue_unlocked_notes(unlocked_entries)
	else:
		ui_refresh_field_guide_badge()
	return unlocked_entries


func ui_mark_field_guide_note_read(note_key: String) -> void:
	var guide: RefCounted = _get_tutorial_guide()
	if guide == null or not guide.has_method("mark_note_read"):
		return
	guide.call("mark_note_read", note_key)
	ui_refresh_field_guide_badge()


func ui_mark_first_run_tutorial_complete() -> void:
	var guide: RefCounted = _get_tutorial_guide()
	if guide == null or not guide.has_method("mark_first_run_complete"):
		return
	guide.call("mark_first_run_complete")
	ui_refresh_field_guide_badge()


func _refresh_magnet_controls() -> void:
	if _main == null or _main.ui == null:
		return
	if not _main.ui.has_method("set_place_magnet_button"):
		return

	var show: bool = false
	var remaining: int = 0
	var armed: bool = false

	if _main.has_method("_can_show_magnet_place_button"):
		show = bool(_main.call("_can_show_magnet_place_button"))
	if _main.has_method("_get_remaining_magnet_placements"):
		remaining = int(_main.call("_get_remaining_magnet_placements"))
	if _main.has_method("_is_magnet_placement_mode_armed"):
		armed = bool(_main.call("_is_magnet_placement_mode_armed"))

	if _has_last_magnet_button_state and _last_magnet_button_show == show and _last_magnet_button_remaining == remaining and _last_magnet_button_armed == armed:
		return

	_main.ui.call("set_place_magnet_button", show, remaining, armed)
	_has_last_magnet_button_state = true
	_last_magnet_button_show = show
	_last_magnet_button_remaining = remaining
	_last_magnet_button_armed = armed


func _refresh_skip_to_end_controls(restart_only: bool = false) -> void:
	if _main == null or _main.ui == null:
		return
	if not _main.ui.has_method("set_skip_to_end_visible"):
		return

	var show: bool = false
	var running: bool = false

	if not restart_only:
		show = String(_main._current_phase) == LevelConfig.PHASE_GRAND_MAP
		if _main.has_method("_can_show_skip_to_end_button"):
			show = show and bool(_main.call("_can_show_skip_to_end_button"))
		if _main.has_method("_is_skip_to_end_running"):
			running = bool(_main.call("_is_skip_to_end_running"))

	if (not _has_last_skip_button_state) or _last_skip_button_show != show:
		_main.ui.call("set_skip_to_end_visible", show)
	if _main.ui.has_method("set_skip_to_end_running"):
		if (not _has_last_skip_button_state) or _last_skip_button_running != running:
			_main.ui.call("set_skip_to_end_running", running)

	_has_last_skip_button_state = true
	_last_skip_button_show = show
	_last_skip_button_running = running


func _refresh_end_engagement_controls(restart_only: bool = false) -> void:
	if _main == null or _main.ui == null:
		return
	if not _main.ui.has_method("set_end_engagement_visible"):
		return

	var show: bool = false
	if not restart_only:
		show = String(_main._current_phase) != LevelConfig.PHASE_GRAND_MAP
		show = show and String(_main._current_phase) != LevelConfig.PHASE_DEFENSIVE
		show = show and _main.state != _main.GameState.GAME_OVER
		show = show and not _main.is_paused

	if (not _has_last_end_engagement_button_visible) or _last_end_engagement_button_visible != show:
		_main.ui.call("set_end_engagement_visible", show)
		_has_last_end_engagement_button_visible = true
		_last_end_engagement_button_visible = show


func _refresh_opening_gameplay_tutorial_skip_controls(restart_only: bool = false) -> void:
	if _main == null or _main.ui == null:
		return
	if not _main.ui.has_method("set_opening_gameplay_tutorial_skip_button"):
		return

	var show: bool = false
	var label: String = "Skip Tutorial"

	if not restart_only:
		if _main.has_method("is_opening_gameplay_tutorial_active"):
			show = bool(_main.call("is_opening_gameplay_tutorial_active"))
		if show and _main.has_method("get_opening_gameplay_tutorial_skip_label"):
			label = String(_main.call("get_opening_gameplay_tutorial_skip_label"))

	if (not _has_last_opening_tutorial_skip_button_state) or _last_opening_tutorial_skip_button_show != show or _last_opening_tutorial_skip_button_label != label:
		_main.ui.call("set_opening_gameplay_tutorial_skip_button", show, label)
		_has_last_opening_tutorial_skip_button_state = true
		_last_opening_tutorial_skip_button_show = show
		_last_opening_tutorial_skip_button_label = label


func sync_ui_button_states() -> void:
	if _main == null or _main.ui == null:
		return

	var restart_only: bool = _main.state == _main.GameState.GAME_OVER
	if _main.ui.has_method("set_restart_only_mode"):
		if (not _has_last_restart_only_mode) or _last_restart_only_mode != restart_only:
			_main.ui.call("set_restart_only_mode", restart_only)
			_has_last_restart_only_mode = true
			_last_restart_only_mode = restart_only

	if restart_only:
		if _main.ui.has_method("show_extra_ball_button"):
			_main.ui.call("show_extra_ball_button", false)
		_refresh_magnet_controls()
		_refresh_skip_to_end_controls(true)
		_refresh_end_engagement_controls(true)
		_refresh_opening_gameplay_tutorial_skip_controls(true)
		return

	if _main.ui.has_method("set_pause_button_paused"):
		if (not _has_last_pause_button_paused) or _last_pause_button_paused != _main.is_paused:
			_main.ui.call("set_pause_button_paused", _main.is_paused)
			_has_last_pause_button_paused = true
			_last_pause_button_paused = _main.is_paused

	if _main.ui.has_method("show_cancel_button"):
		var show: bool = ((_main.state == _main.GameState.DRAGGING or _main._drag_pending) and not _main.is_paused)
		if (not _has_last_cancel_button_visible) or _last_cancel_button_visible != show:
			_main.ui.call("show_cancel_button", show)
			_has_last_cancel_button_visible = true
			_last_cancel_button_visible = show

	_refresh_magnet_controls()
	_refresh_skip_to_end_controls(false)
	_refresh_end_engagement_controls(false)
	_refresh_opening_gameplay_tutorial_skip_controls(false)
	ui_refresh_field_guide_badge()


func _connect_tutorial_ui_signals() -> void:
	if _main == null or _main.ui == null:
		return

	if _main.ui.has_signal("tutorial_finished"):
		var tutorial_finished_callable: Callable = Callable(self, "_on_tutorial_finished")
		if not _main.ui.tutorial_finished.is_connected(tutorial_finished_callable):
			_main.ui.tutorial_finished.connect(tutorial_finished_callable)

	if _main.ui.has_signal("field_guide_note_selected"):
		var note_selected_callable: Callable = Callable(self, "_on_field_guide_note_selected")
		if not _main.ui.field_guide_note_selected.is_connected(note_selected_callable):
			_main.ui.field_guide_note_selected.connect(note_selected_callable)

	if _main.ui.has_signal("replay_tutorial_requested"):
		var replay_callable: Callable = Callable(self, "_on_replay_tutorial_requested")
		if not _main.ui.replay_tutorial_requested.is_connected(replay_callable):
			_main.ui.replay_tutorial_requested.connect(replay_callable)

	if _main.ui.has_signal("opening_gameplay_tutorial_skip_pressed"):
		var skip_tutorial_callable: Callable = Callable(self, "_on_opening_gameplay_tutorial_skip_pressed")
		if not _main.ui.opening_gameplay_tutorial_skip_pressed.is_connected(skip_tutorial_callable):
			_main.ui.opening_gameplay_tutorial_skip_pressed.connect(skip_tutorial_callable)


func _sync_tutorial_guide_reference() -> void:
	if _main == null or _main.ui == null:
		return
	if not LevelConfig.is_tutorial_and_field_guide_enabled():
		return
	var guide: RefCounted = _get_tutorial_guide()
	if guide == null:
		return
	if _main.ui.has_method("set_tutorial_guide"):
		_main.ui.call("set_tutorial_guide", guide)


func _get_tutorial_guide() -> RefCounted:
	if _main == null:
		return null
	if not _main_has_property("tutorial_guide"):
		return null
	var guide: Variant = _main.get("tutorial_guide")
	if guide is RefCounted:
		return guide as RefCounted
	return null


func _main_has_property(property_name: String) -> bool:
	if _main == null:
		return false
	for prop in _main.get_property_list():
		if String(prop.get("name", "")) == property_name:
			return true
	return false


func _typed_dictionary_array(raw_entries: Array) -> Array[Dictionary]:
	var typed_entries: Array[Dictionary] = []
	for entry in raw_entries:
		if entry is Dictionary:
			typed_entries.append((entry as Dictionary).duplicate(true))
	return typed_entries


func _set_level_text_if_changed(level_text: String) -> void:
	if _main == null or _main.ui == null:
		return
	if not _main.ui.has_method("set_level_text"):
		return
	if _has_last_level_text and _last_level_text == level_text:
		return
	_main.ui.call("set_level_text", level_text)
	_has_last_level_text = true
	_last_level_text = level_text


func _on_tutorial_finished() -> void:
	ui_mark_first_run_tutorial_complete()
	if _main != null and _main.ui != null and _main.ui.has_method("is_field_guide_open") and not bool(_main.ui.call("is_field_guide_open")):
		ui_set_status("Tutorial complete. Open Help any time to review notes in the Field Guide.")


func _on_field_guide_note_selected(note_key: String) -> void:
	ui_mark_field_guide_note_read(note_key)


func _on_replay_tutorial_requested() -> void:
	var guide: RefCounted = _get_tutorial_guide()
	if guide == null or not guide.has_method("get_first_run_sequence"):
		return
	var raw_sequence: Array = guide.call("get_first_run_sequence")
	var sequence: Array[Dictionary] = _typed_dictionary_array(raw_sequence)
	ui_show_tutorial_sequence(sequence)


func _on_opening_gameplay_tutorial_skip_pressed() -> void:
	if _main == null:
		return
	if _main.has_method("request_skip_opening_gameplay_tutorial"):
		_main.call("request_skip_opening_gameplay_tutorial")


func _on_campaign_level_mode_selected(level_mode: String) -> void:
	var normalized_mode: String = LevelConfig.normalize_campaign_level_mode(level_mode)
	if _main == null:
		return

	if _main.has_method("set_campaign_selected_level_mode"):
		_main.call("set_campaign_selected_level_mode", normalized_mode)
	elif _main_has_property("campaign_selected_level_mode"):
		_main.set("campaign_selected_level_mode", normalized_mode)

	ui_hide_campaign_level_mode_choice()

	if _main.has_method("_on_campaign_level_mode_selected"):
		_main.call("_on_campaign_level_mode_selected", normalized_mode)
		return

	var status_text: String = ""
	if _main.has_method("get_campaign_current_level_progress") and _main.has_method("get_campaign_total_levels") and _main.has_method("get_campaign_selected_level_mode_display_name"):
		status_text = "Level %d/%d ready — %s mode selected." % [
			int(_main.call("get_campaign_current_level_progress")),
			int(_main.call("get_campaign_total_levels")),
			String(_main.call("get_campaign_selected_level_mode_display_name"))
		]
	elif _main.has_method("get_campaign_selected_level_mode_display_name"):
		status_text = "%s mode selected." % String(_main.call("get_campaign_selected_level_mode_display_name"))

	if status_text != "":
		ui_set_status(status_text)
	else:
		ui_clear_state_message()

	sync_ui_button_states()


func _on_pre_level_debug_config_confirmed(initial_friendly_troops: int, boss_head_hit_points: int, conquered_friendly_troops: int, campaign_enemy_troop_increase_per_level: int, friendly_march_bonus_troops: int, boss_show_up_on_turn: int, bonus_gold_per_turn: int, next_level_override: int) -> void:
	if _main == null:
		return
	ui_hide_pre_level_debug_config_choice()
	if _main.has_method("_on_pre_level_debug_config_confirmed"):
		_main.call("_on_pre_level_debug_config_confirmed", initial_friendly_troops, boss_head_hit_points, conquered_friendly_troops, campaign_enemy_troop_increase_per_level, friendly_march_bonus_troops, boss_show_up_on_turn, bonus_gold_per_turn, next_level_override)
