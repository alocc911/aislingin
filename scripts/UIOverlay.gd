extends CanvasLayer
"""
UI overlay for Sunny Slopes.

Handles level display, gold counter, pin summary, upgrade shop buttons,
pause/restart/cancel controls, seed display, retry level, seed loading,
one-tap copy, and the Extra Ball button.

MARCH 2026 UI CLEANUP + UNIFIED ENGAGEMENTS:
- State messages are now treated as either short prompts or multi-line result summaries.
- Multi-line engagement summaries (from the single unified resolver) are rendered in a readable wrapped layout.
- The pins summary is hidden only when a real message is being shown.
- Status filtering is intentionally permissive so the gameplay layer can provide context-specific text.
- Existing shop / seed / pause / retry / extra ball controls are preserved.

MARCH 2026 INLINE SUMMARY UPDATE:
- Engagement and automated skip reports stay in the bottom bar only.
- The blocking summary overlay is suppressed for gameplay reports.
- The skip button becomes a stop button while auto-skipping is active.
"""

signal upgrade_purchased(upgrade_type: String)
signal pause_pressed()
signal cancel_shot_pressed()
signal restart_pressed()
signal retry_level_pressed()
signal load_seed_requested(seed_value: int)
signal extra_ball_pressed()
signal place_magnet_pressed()
signal skip_to_end_pressed()
signal end_engagement_pressed()
signal opening_gameplay_tutorial_skip_pressed()
signal bottom_bar_resized(height: float)
signal campaign_upgrade_selected(upgrade_type: String)
signal campaign_level_mode_selected(level_mode: String)
signal pre_level_debug_config_confirmed(initial_friendly_troops: int, boss_head_hit_points: int, conquered_friendly_troops: int, campaign_enemy_troop_increase_per_level: int, friendly_march_bonus_troops: int, boss_show_up_on_turn: int, bonus_gold_per_turn: int, next_level_override: int)
signal replay_tutorial_requested()
signal field_guide_opened()
signal field_guide_closed()
signal tutorial_step_changed(note_key: String, step_index: int, step_count: int)
signal tutorial_finished()
signal cutscene_finished(cutscene_id: String)
signal field_guide_note_selected(note_key: String)
signal data_dump_requested()
signal troop_debug_dump_requested()
signal friendly_boss_debug_dump_requested()
signal bug_report_submitted(report_payload: Dictionary)

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const SUMMARY_OVERLAY_MIN_LINES: int = 7
const SUMMARY_OVERLAY_MIN_CHARS: int = 260
const SUMMARY_PREVIEW_MAX_LINES: int = 4
const SUMMARY_PREVIEW_MAX_CHARS: int = 220

const DASHBOARD_UI_BASE_PATH: String = "res://assets/ui/dashboard/"
const DASHBOARD_FRAME_TEXTURE_PATH: String = DASHBOARD_UI_BASE_PATH + "bottom_bar_frame_9slice.png"
const DASHBOARD_TRAY_TEXTURE_PATH: String = DASHBOARD_UI_BASE_PATH + "bottom_bar_tray_9slice.png"
const DASHBOARD_BANNER_TEXTURE_PATH: String = DASHBOARD_UI_BASE_PATH + "bottom_bar_banner_9slice.png"
const DASHBOARD_ICON_BASE_PATH: String = "res://assets/ui/icons/"
const DASHBOARD_ICON_GOLD_PATH: String = DASHBOARD_ICON_BASE_PATH + "icon_gold.png"
const DASHBOARD_ICON_SEED_PATH: String = DASHBOARD_ICON_BASE_PATH + "icon_seed.png"
const DASHBOARD_ICON_BIGGER_PATH: String = DASHBOARD_ICON_BASE_PATH + "bigger_ball.png"
const DASHBOARD_ICON_HEAVIER_PATH: String = DASHBOARD_ICON_BASE_PATH + "heavier_ball.png"
const DASHBOARD_ICON_POISON_PATH: String = DASHBOARD_ICON_BASE_PATH + "icon_wind.png"
const DASHBOARD_ICON_FORCEFIELD_PATH: String = DASHBOARD_ICON_BASE_PATH + "icon_forcefield.png"
const DASHBOARD_ICON_MAGNET_PATH: String = DASHBOARD_ICON_BASE_PATH + "icon_magnet.png"
const DASHBOARD_ICON_COPY_PATH: String = DASHBOARD_ICON_BASE_PATH + "icon_copy.png"
const DASHBOARD_ICON_LOAD_PATH: String = DASHBOARD_ICON_BASE_PATH + "icon_load.png"
const DASHBOARD_PATCH_MARGIN: int = 18
const DASHBOARD_FRAME_PATCH_MARGINS: Rect2i = Rect2i(76, 64, 76, 64)
const DASHBOARD_TRAY_PATCH_MARGINS: Rect2i = Rect2i(48, 48, 48, 48)
const DASHBOARD_BANNER_PATCH_MARGINS: Rect2i = Rect2i(44, 20, 44, 20)
const DASHBOARD_UPGRADE_ICON_SIZE: Vector2i = Vector2i(26, 26)
const DASHBOARD_INLINE_ICON_SIZE: Vector2i = Vector2i(22, 22)
const DASHBOARD_SMALL_BUTTON_ICON_SIZE: Vector2i = Vector2i(18, 18)

const DASHBOARD_GLYPH_PAUSE: String = "||"
const DASHBOARD_GLYPH_RESUME: String = ">"
const DASHBOARD_GLYPH_RESTART: String = "R"
const DASHBOARD_GLYPH_RETRY: String = "RL"
const DASHBOARD_GLYPH_SKIP: String = ">>"
const DASHBOARD_GLYPH_STOP: String = "X"
const DASHBOARD_GLYPH_HELP: String = "?"
const DASHBOARD_GLYPH_SUMMARY: String = "S"

const DASHBOARD_FRAME_TINT: Color = Color(0.98, 0.94, 0.84, 1.0)
const DASHBOARD_SECTION_FILL: Color = Color(0.18, 0.11, 0.07, 0.97)
const DASHBOARD_SECTION_BORDER: Color = Color(0.72, 0.56, 0.28, 1.0)
const DASHBOARD_TRAY_FILL: Color = Color(0.10, 0.06, 0.04, 0.95)
const DASHBOARD_TRAY_BORDER: Color = Color(0.44, 0.31, 0.15, 1.0)
const DASHBOARD_BANNER_FILL: Color = Color(0.24, 0.14, 0.08, 0.98)
const DASHBOARD_BANNER_BORDER: Color = Color(0.86, 0.70, 0.34, 1.0)

const DASHBOARD_UPGRADE_BUTTON_FILL: Color = Color(0.20, 0.11, 0.06, 1.0)
const DASHBOARD_UPGRADE_BUTTON_HOVER: Color = Color(0.28, 0.16, 0.09, 1.0)
const DASHBOARD_UPGRADE_BUTTON_PRESSED: Color = Color(0.16, 0.09, 0.05, 1.0)
const DASHBOARD_UPGRADE_BUTTON_DISABLED: Color = Color(0.13, 0.11, 0.10, 1.0)
const DASHBOARD_UPGRADE_BUTTON_BORDER: Color = Color(0.84, 0.66, 0.30, 1.0)

const DASHBOARD_CONTROL_BUTTON_FILL: Color = Color(0.17, 0.11, 0.08, 1.0)
const DASHBOARD_CONTROL_BUTTON_HOVER: Color = Color(0.24, 0.15, 0.11, 1.0)
const DASHBOARD_CONTROL_BUTTON_PRESSED: Color = Color(0.13, 0.08, 0.06, 1.0)
const DASHBOARD_CONTROL_BUTTON_DISABLED: Color = Color(0.12, 0.11, 0.10, 1.0)
const DASHBOARD_CONTROL_BUTTON_BORDER: Color = Color(0.68, 0.53, 0.29, 1.0)

const DASHBOARD_TEXT_PRIMARY: Color = Color(0.98, 0.94, 0.88, 1.0)
const DASHBOARD_TEXT_SECONDARY: Color = Color(0.86, 0.78, 0.67, 1.0)
const DASHBOARD_TEXT_MUTED: Color = Color(0.66, 0.59, 0.52, 1.0)
const DASHBOARD_TEXT_GOLD: Color = Color(1.0, 0.86, 0.42, 1.0)

@onready var _bottom_bar: Control = $Root/BottomBar
@onready var _bottom_bar_margin: Control = $Root/BottomBar/Margin
@onready var _main_layout: Control = $Root/BottomBar/Margin/MainLayout
@onready var _content_block: Control = $Root/BottomBar/Margin/MainLayout/ContentBlock
@onready var _header_row: Control = $Root/BottomBar/Margin/MainLayout/ContentBlock/HeaderRow
@onready var _gold_block: Control = $Root/BottomBar/Margin/MainLayout/ContentBlock/HeaderRow/GoldBlock
@onready var _stats_slot: Control = $Root/BottomBar/Margin/MainLayout/ContentBlock/StatsSlot
@onready var _controls_row: Control = $Root/BottomBar/Margin/MainLayout/ContentBlock/ControlsRow

@onready var _lbl_level: Label = $Root/BottomBar/Margin/MainLayout/ContentBlock/HeaderRow/LevelLabel
@onready var _lbl_gold_value: Label = $Root/BottomBar/Margin/MainLayout/ContentBlock/HeaderRow/GoldBlock/GoldValue
@onready var _pins_summary: Label = $Root/BottomBar/Margin/MainLayout/ContentBlock/StatsSlot/PinsSummaryLabel
@onready var _state_message: Label = $Root/BottomBar/Margin/MainLayout/ContentBlock/StatsSlot/StateMessageLabel
var _scrollable_state_message: RichTextLabel = null

@onready var _shop_block: VBoxContainer = $Root/BottomBar/Margin/MainLayout/ShopBlock
@onready var _bigger_btn: Button = $Root/BottomBar/Margin/MainLayout/ShopBlock/BiggerBallBtn
@onready var _heavier_btn: Button = $Root/BottomBar/Margin/MainLayout/ShopBlock/HeavierBallBtn
@onready var _poison_btn: Button = $Root/BottomBar/Margin/MainLayout/ShopBlock/PoisonBtn

var _forcefield_btn: Button = null
var _magnet_btn: Button = null
var _place_magnet_btn: Button = null
var _skip_to_end_btn: Button = null
var _end_engagement_btn: Button = null
var _opening_gameplay_tutorial_skip_btn: Button = null
var _opening_gameplay_tutorial_skip_active: bool = false
var _opening_gameplay_tutorial_skip_label: String = "Skip Tutorial"

@onready var _utility_block: Control = $Root/BottomBar/Margin/MainLayout/ContentBlock/ControlsRow/UtilityBlock
@onready var _seed_block: Control = $Root/BottomBar/Margin/MainLayout/ContentBlock/ControlsRow/SeedBlock
@onready var _pause_btn: Button = $Root/BottomBar/Margin/MainLayout/ContentBlock/ControlsRow/UtilityBlock/PauseBtn
@onready var _restart_btn: Button = $Root/BottomBar/Margin/MainLayout/ContentBlock/ControlsRow/UtilityBlock/RestartBtn
var _retry_btn: Button = null
@onready var _cancel_btn: Button = $Root/BottomBar/Margin/MainLayout/ContentBlock/ControlsRow/UtilityBlock/CancelBtn

@onready var _seed_label: Label = $Root/BottomBar/Margin/MainLayout/ContentBlock/ControlsRow/SeedBlock/SeedRow/SeedLabel
@onready var _copy_btn: Button = $Root/BottomBar/Margin/MainLayout/ContentBlock/ControlsRow/SeedBlock/SeedRow/CopyBtn
@onready var _seed_edit: LineEdit = $Root/BottomBar/Margin/MainLayout/ContentBlock/ControlsRow/SeedBlock/SeedInputRow/SeedEdit
@onready var _load_btn: Button = $Root/BottomBar/Margin/MainLayout/ContentBlock/ControlsRow/SeedBlock/SeedInputRow/LoadBtn

@onready var _extra_ball_btn: Button = $Root/BottomBar/Margin/MainLayout/ContentBlock/ExtraBallBtn

@onready var _gold_sparkles: GPUParticles2D = $Root/BottomBar/Margin/MainLayout/ContentBlock/HeaderRow/GoldBlock/GoldValue/GoldSparkles
@onready var _win_burst: GPUParticles2D = $Root/BottomBar/WinBurst

var _summary_overlay_backdrop: ColorRect = null
var _summary_overlay_panel: PanelContainer = null
var _summary_overlay_title: Label = null
var _summary_overlay_body: RichTextLabel = null
var _summary_overlay_hint: Label = null
var _summary_overlay_close_btn: Button = null
var _reopen_summary_btn: Button = null
var _last_reopenable_summary_text: String = ""

var _restart_confirm_dialog: ConfirmationDialog = null

var _campaign_upgrade_backdrop: ColorRect = null
var _campaign_upgrade_panel: PanelContainer = null
var _campaign_upgrade_scroll: ScrollContainer = null
var _campaign_upgrade_title: Label = null
var _campaign_upgrade_body: Label = null
var _campaign_upgrade_buttons_row: VBoxContainer = null
var _campaign_upgrade_buttons: Array[Button] = []

var _campaign_level_mode_backdrop: ColorRect = null
var _campaign_level_mode_panel: PanelContainer = null
var _campaign_level_mode_title: Label = null
var _campaign_level_mode_body: RichTextLabel = null
var _campaign_level_mode_buttons_row: HBoxContainer = null
var _campaign_level_mode_easy_btn: Button = null
var _campaign_level_mode_hard_btn: Button = null
var _pre_level_debug_backdrop: ColorRect = null
var _pre_level_debug_panel: PanelContainer = null
var _pre_level_debug_initial_friendly_spin: SpinBox = null
var _pre_level_debug_boss_head_spin: SpinBox = null
var _pre_level_debug_conquered_friendly_spin: SpinBox = null
var _pre_level_debug_campaign_enemy_troop_increase_spin: SpinBox = null
var _pre_level_debug_friendly_march_bonus_spin: SpinBox = null
var _pre_level_debug_boss_show_up_turn_spin: SpinBox = null
var _pre_level_debug_bonus_gold_spin: SpinBox = null
var _pre_level_debug_next_level_spin: SpinBox = null
var _pre_level_debug_confirm_btn: Button = null

var _cached_total_pins: int = 0
var _cached_downed_pins: int = 0
var _cached_gold: int = 0

var _bigger_count: int = 0
var _heavier_count: int = 0
var _poison_count: int = 0
var _forcefield_count: int = 0
var _magnet_count: int = 0
var _upgrade_cost_overrides: Dictionary = {}

var _shop_pulse_tweens: Dictionary = {}
var _low_motion_mode: bool = false

var _dashboard_layout_built: bool = false
var _dashboard_left_section: Control = null
var _dashboard_center_section: Control = null
var _dashboard_right_section: Control = null
var _dashboard_left_content: VBoxContainer = null
var _dashboard_center_content: VBoxContainer = null
var _dashboard_right_content: VBoxContainer = null
var _dashboard_outer_frame_bg: Control = null
var _message_banner_shell: Control = null
var _gold_shell: Control = null
var _seed_shell: Control = null
var _gold_icon_rect: TextureRect = null
var _seed_icon_rect: TextureRect = null
var _dashboard_icon_cache: Dictionary = {}
var _right_utility_layout: VBoxContainer = null
var _right_utility_primary_row: HBoxContainer = null
var _right_utility_secondary_row: HBoxContainer = null
var _right_utility_stop_row: HBoxContainer = null
var _right_utility_actions_row: HBoxContainer = null
var _right_panel_utility_structure_signature: String = ""
var _bottom_bar_resize_notification_queued: bool = false
var _last_bottom_bar_height_emitted: float = -1.0
var _last_responsive_layout_signature: String = ""

var _help_btn: Button = null
var _help_badge: Label = null
var _data_dump_btn: Button = null
var _troop_debug_btn: Button = null
var _friendly_boss_debug_btn: Button = null
var _log_schema_btn: Button = null
var _bug_report_backdrop: ColorRect = null
var _bug_report_title_edit: LineEdit = null
var _bug_report_expected_edit: TextEdit = null
var _bug_report_actual_edit: TextEdit = null
var _bug_report_steps_edit: TextEdit = null
var _bug_report_include_diagnostics_check: CheckBox = null
var _bug_report_data_preview: TextEdit = null

var _tutorial_guide: RefCounted = null
var _tutorial_sequence: Array[Dictionary] = []
var _tutorial_index: int = -1

var _tutorial_backdrop: ColorRect = null
var _tutorial_panel: PanelContainer = null
var _tutorial_step_label: Label = null
var _tutorial_title: Label = null
var _tutorial_body: Label = null
var _tutorial_target_hint: Label = null
var _tutorial_prev_btn: Button = null
var _tutorial_next_btn: Button = null
var _tutorial_close_btn: Button = null
var _cutscene_backdrop: ColorRect = null
var _cutscene_background: TextureRect = null
var _cutscene_player_sprite: TextureRect = null
var _cutscene_other_sprite: TextureRect = null
var _cutscene_dialogue_panel: PanelContainer = null
var _cutscene_dialogue_label: Label = null
var _cutscene_lines: Array[String] = []
var _cutscene_line_index: int = 0
var _cutscene_active_id: String = ""

var _field_guide_backdrop: ColorRect = null
var _field_guide_panel: PanelContainer = null
var _field_guide_category_list: ItemList = null
var _field_guide_note_list: ItemList = null
var _field_guide_title: Label = null
var _field_guide_body: RichTextLabel = null
var _field_guide_empty_label: Label = null
var _field_guide_replay_btn: Button = null
var _field_guide_close_btn: Button = null
var _field_guide_sections: Array[Dictionary] = []
var _field_guide_current_category: String = ""
var _field_guide_current_note_key: String = ""
var _field_guide_forced_pause: bool = false

var _field_guide_toast_panel: PanelContainer = null
var _field_guide_toast_title: Label = null
var _field_guide_toast_body: Label = null
var _field_guide_toast_open_btn: Button = null
var _field_guide_toast_queue: Array[Dictionary] = []
var _field_guide_toast_showing: bool = false
var _field_guide_toast_serial: int = 0
var _field_guide_toast_note_key: String = ""

func _ready() -> void:
	_ensure_forcefield_button()
	_ensure_magnet_button()
	_ensure_place_magnet_button()
	_ensure_skip_to_end_button()
	_ensure_end_engagement_button()
	_ensure_opening_gameplay_tutorial_skip_button()
	_ensure_help_button()
	_ensure_data_dump_button()
	_ensure_troop_debug_button()
	_ensure_friendly_boss_debug_button()
	_ensure_log_schema_button()
	_apply_bottom_bar_dashboard_layout()
	_apply_bottom_bar_visual_style()
	_apply_dashboard_icons()

	_connect_upgrade_button(_bigger_btn, "bigger")
	_connect_upgrade_button(_heavier_btn, "heavier")
	_connect_upgrade_button(_poison_btn, "poison")
	if _forcefield_btn:
		_connect_upgrade_button(_forcefield_btn, "forcefield")
	if _magnet_btn:
		_connect_upgrade_button(_magnet_btn, "magnet")
	if _place_magnet_btn:
		_place_magnet_btn.pressed.connect(func(): emit_signal("place_magnet_pressed"))
	if _skip_to_end_btn:
		_skip_to_end_btn.pressed.connect(func(): emit_signal("skip_to_end_pressed"))
	if _end_engagement_btn:
		_end_engagement_btn.pressed.connect(func(): emit_signal("end_engagement_pressed"))
	if _opening_gameplay_tutorial_skip_btn:
		_opening_gameplay_tutorial_skip_btn.pressed.connect(func(): emit_signal("opening_gameplay_tutorial_skip_pressed"))
	if _data_dump_btn:
		_data_dump_btn.pressed.connect(func():
			print("[BugReportFlow][UIOverlay] Bug Report button pressed; emitting data_dump_requested.")
			emit_signal("data_dump_requested")
		)
	if _friendly_boss_debug_btn:
		_friendly_boss_debug_btn.pressed.connect(func(): emit_signal("friendly_boss_debug_dump_requested"))
	if _troop_debug_btn:
		_troop_debug_btn.pressed.connect(func(): emit_signal("troop_debug_dump_requested"))
	if _log_schema_btn:
		_log_schema_btn.pressed.connect(_on_log_schema_pressed)
	_pause_btn.pressed.connect(func(): emit_signal("pause_pressed"))
	_pause_btn.visible = false
	_pause_btn.disabled = true
	_restart_btn.pressed.connect(_on_restart_pressed)
	if _retry_btn:
		_retry_btn.pressed.connect(func(): emit_signal("retry_level_pressed"))
	_cancel_btn.pressed.connect(func(): emit_signal("cancel_shot_pressed"))
	_cancel_btn.visible = false

	_load_btn.pressed.connect(_on_load_seed_pressed)
	_copy_btn.pressed.connect(_on_copy_seed_pressed)
	_extra_ball_btn.pressed.connect(func(): emit_signal("extra_ball_pressed"))

	if _bottom_bar and _bottom_bar.has_signal("resized"):
		_bottom_bar.resized.connect(_on_bottom_bar_resized)

	self.process_mode = Node.PROCESS_MODE_ALWAYS

	if _pins_summary:
		_pins_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_pins_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pins_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_pins_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_pins_summary.clip_contents = true

	if _state_message:
		_state_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_state_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_state_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_state_message.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_state_message.clip_contents = true

	_ensure_scrollable_state_message()
	_ensure_summary_overlay()
	_ensure_reopen_summary_button()
	_rebuild_right_panel_utility_cluster()
	_ensure_campaign_upgrade_overlay()
	_ensure_campaign_level_mode_overlay()
	_ensure_tutorial_overlay()
	_ensure_field_guide_overlay()
	_ensure_field_guide_toast()
	_ensure_bug_report_overlay()
	_ensure_restart_confirm_dialog()

	set_level_text("Level 1")
	set_gold(0)
	set_pins_counts(0, 0)
	clear_state_message()
	_refresh_shop_buttons()

	if _seed_label:
		_seed_label.text = "0"
	if _seed_edit:
		_seed_edit.text = ""

	_extra_ball_btn.visible = false
	refresh_field_guide_badge()
	_notify_bottom_bar_resized_deferred()

func _connect_upgrade_button(btn: Button, upgrade_type: String) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	btn.pressed.connect(func(): emit_signal("upgrade_purchased", upgrade_type))
	btn.gui_input.connect(func(event: InputEvent): _on_upgrade_button_gui_input(event, upgrade_type))

func _on_upgrade_button_gui_input(event: InputEvent, upgrade_type: String) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index != MOUSE_BUTTON_RIGHT:
		return
	for _i in range(5):
		emit_signal("upgrade_purchased", upgrade_type)
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _apply_bottom_bar_dashboard_layout() -> void:
	if _dashboard_layout_built:
		return
	if _main_layout == null or _shop_block == null or _content_block == null:
		return

	if _bottom_bar != null:
		_bottom_bar.custom_minimum_size = Vector2(0.0, 248.0)
		_strip_legacy_bottom_bar_frame()
		_clear_legacy_bottom_bar_backgrounds()
		var existing_outer_bg: Node = _bottom_bar.get_node_or_null("DashboardOuterFrameBg")
		if existing_outer_bg is Control:
			_dashboard_outer_frame_bg = existing_outer_bg as Control
		else:
			_dashboard_outer_frame_bg = _make_dashboard_background_node(
				"DashboardOuterFrameBg",
				DASHBOARD_FRAME_TEXTURE_PATH,
				Color.WHITE,
				DASHBOARD_SECTION_BORDER,
				24,
				false,
				Color.WHITE
			)
			_dashboard_outer_frame_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_bottom_bar.add_child(_dashboard_outer_frame_bg)
			_bottom_bar.move_child(_dashboard_outer_frame_bg, 0)

	if _bottom_bar_margin is MarginContainer:
		var bottom_margin := _bottom_bar_margin as MarginContainer
		bottom_margin.add_theme_constant_override("margin_left", 6)
		bottom_margin.add_theme_constant_override("margin_top", 12)
		bottom_margin.add_theme_constant_override("margin_right", 6)
		bottom_margin.add_theme_constant_override("margin_bottom", 12)

	if _main_layout is BoxContainer:
		(_main_layout as BoxContainer).add_theme_constant_override("separation", 0)

	_dashboard_left_section = _create_dashboard_section(
		"UpgradeSection",
		"Upgrades",
		float(LevelConfig.get_dashboard_left_section_base_min_width()),
		LevelConfig.get_dashboard_left_section_stretch()
	)
	_dashboard_center_section = _create_dashboard_section(
		"CommandSection",
		"Command Deck",
		float(LevelConfig.get_dashboard_center_section_base_min_width()),
		LevelConfig.get_dashboard_center_section_stretch(),
		false
	)
	_dashboard_right_section = _create_dashboard_section(
		"EconomySection",
		"Economy / Seeds",
		float(LevelConfig.get_dashboard_right_section_base_min_width()),
		LevelConfig.get_dashboard_right_section_stretch()
	)

	if _dashboard_left_section == null or _dashboard_center_section == null or _dashboard_right_section == null:
		return

	_dashboard_left_content = _get_section_content(_dashboard_left_section)
	_dashboard_center_content = _get_section_content(_dashboard_center_section)
	_dashboard_right_content = _get_section_content(_dashboard_right_section)

	if _dashboard_left_content == null or _dashboard_center_content == null or _dashboard_right_content == null:
		return

	_main_layout.add_child(_dashboard_left_section)
	_main_layout.add_child(_dashboard_center_section)
	_main_layout.add_child(_dashboard_right_section)

	_move_control_to_container(_shop_block, _dashboard_left_content)
	_move_control_to_container(_content_block, _dashboard_center_content)
	if _content_block != null:
		_content_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_content_block.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if _shop_block is BoxContainer:
		(_shop_block as BoxContainer).add_theme_constant_override("separation", 8)

	if _content_block is BoxContainer:
		(_content_block as BoxContainer).add_theme_constant_override("separation", 10)
	if _dashboard_center_content is BoxContainer:
		(_dashboard_center_content as BoxContainer).add_theme_constant_override("separation", 0)

	if _header_row is BoxContainer:
		(_header_row as BoxContainer).add_theme_constant_override("separation", 8)

	_move_control_to_container(_gold_block, _dashboard_right_content)
	_move_control_to_container(_utility_block, _dashboard_right_content)
	if _utility_block != null:
		_utility_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_move_control_to_container(_extra_ball_btn, _dashboard_right_content)
	var right_bottom_spacer: Control = _ensure_dashboard_fill_spacer(_dashboard_right_content, "RightBottomSpacer")
	if right_bottom_spacer != null:
		_dashboard_right_content.move_child(right_bottom_spacer, _dashboard_right_content.get_child_count() - 1)
	_move_control_to_container(_seed_block, _dashboard_right_content)

	if _controls_row != null:
		_controls_row.visible = false
		_controls_row.custom_minimum_size = Vector2.ZERO
		_controls_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	_message_banner_shell = _wrap_control_in_dashboard_shell(
		_content_block,
		"MessageBannerShell",
		DASHBOARD_BANNER_TEXTURE_PATH,
		DASHBOARD_BANNER_FILL,
		DASHBOARD_BANNER_BORDER,
		72.0,
		10,
		8,
		10,
		8
	)
	_gold_shell = _wrap_control_in_dashboard_shell(
		_gold_block,
		"GoldInfoShell",
		DASHBOARD_TRAY_TEXTURE_PATH,
		Color(0.16, 0.10, 0.05, 0.98),
		Color(0.83, 0.66, 0.26, 1.0),
		84.0,
		14,
		10,
		14,
		10
	)
	_seed_shell = _wrap_control_in_dashboard_shell(
		_seed_block,
		"SeedInfoShell",
		DASHBOARD_TRAY_TEXTURE_PATH,
		DASHBOARD_TRAY_FILL,
		DASHBOARD_TRAY_BORDER,
		102.0,
		14,
		12,
		14,
		12
	)

	if _dashboard_right_content is BoxContainer:
		(_dashboard_right_content as BoxContainer).add_theme_constant_override("separation", 10)

	_dashboard_layout_built = true


func _apply_bottom_bar_visual_style() -> void:
	if _controls_row is BoxContainer:
		(_controls_row as BoxContainer).add_theme_constant_override("separation", 10)
	if _utility_block is BoxContainer:
		(_utility_block as BoxContainer).add_theme_constant_override("separation", 8)
	if _seed_block is BoxContainer:
		(_seed_block as BoxContainer).add_theme_constant_override("separation", 8)
	if _shop_block is BoxContainer:
		(_shop_block as BoxContainer).add_theme_constant_override("separation", 8)

	if _lbl_level:
		_lbl_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_lbl_level.add_theme_font_size_override("font_size", 26)
		_lbl_level.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
		_lbl_level.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
		_lbl_level.add_theme_constant_override("shadow_offset_x", 0)
		_lbl_level.add_theme_constant_override("shadow_offset_y", 2)
		_lbl_level.custom_minimum_size = Vector2(0.0, 42.0)

	if _lbl_gold_value:
		_lbl_gold_value.add_theme_font_size_override("font_size", 28)
		_lbl_gold_value.add_theme_color_override("font_color", DASHBOARD_TEXT_GOLD)
		_lbl_gold_value.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
		_lbl_gold_value.add_theme_constant_override("shadow_offset_x", 0)
		_lbl_gold_value.add_theme_constant_override("shadow_offset_y", 2)

	if _pins_summary:
		_pins_summary.add_theme_font_size_override("font_size", 18)
		_pins_summary.add_theme_color_override("font_color", DASHBOARD_TEXT_SECONDARY)

	if _state_message:
		_state_message.add_theme_font_size_override("font_size", 18)
		_state_message.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	if _scrollable_state_message:
		_apply_scrollable_state_message_theme(18)

	if _seed_label:
		_seed_label.add_theme_font_size_override("font_size", 16)
		_seed_label.add_theme_color_override("font_color", DASHBOARD_TEXT_SECONDARY)

	if _seed_edit:
		_seed_edit.custom_minimum_size = Vector2(0.0, 42.0)
		_seed_edit.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
		_seed_edit.add_theme_color_override("font_placeholder_color", DASHBOARD_TEXT_MUTED)
		_seed_edit.add_theme_stylebox_override("normal", _make_input_stylebox(false))
		_seed_edit.add_theme_stylebox_override("focus", _make_input_stylebox(true))
		_seed_edit.add_theme_stylebox_override("read_only", _make_input_stylebox(false))

	for btn in [_pause_btn, _restart_btn, _retry_btn, _cancel_btn, _copy_btn, _load_btn, _extra_ball_btn, _place_magnet_btn, _skip_to_end_btn, _end_engagement_btn, _opening_gameplay_tutorial_skip_btn, _data_dump_btn, _help_btn, _reopen_summary_btn]:
		if btn:
			_apply_dashboard_button_style(btn, false)

	for btn in [_bigger_btn, _heavier_btn, _poison_btn, _forcefield_btn, _magnet_btn]:
		if btn:
			_apply_dashboard_button_style(btn, true)

	_apply_dashboard_responsive_layout_metrics()


func _apply_dashboard_responsive_layout_metrics() -> void:
	var viewport: Viewport = get_viewport()
	var width: float = 0.0
	if _bottom_bar != null:
		width = _bottom_bar.size.x
	if width <= 1.0 and viewport != null:
		width = viewport.get_visible_rect().size.x
	if width <= 1.0:
		width = 1280.0

	var very_compact: bool = width < 760.0
	var compact: bool = width < 1040.0
	var left_share: float = maxf(0.01, float(LevelConfig.get_dashboard_left_section_width_share()))
	var center_share: float = maxf(0.01, float(LevelConfig.get_dashboard_center_section_width_share()))
	var right_share: float = maxf(0.01, float(LevelConfig.get_dashboard_right_section_width_share()))
	var layout_signature: String = "%d|%d|%d|%.4f|%.4f|%.4f" % [
		int(round(width)),
		1 if compact else 0,
		1 if very_compact else 0,
		left_share,
		center_share,
		right_share
	]
	if layout_signature == _last_responsive_layout_signature:
		return
	_last_responsive_layout_signature = layout_signature

	var bottom_side_margin: int = 4 if compact else 2
	var section_outer_lr: int = 4 if compact else 3
	var section_outer_tb: int = 8 if compact else 6
	var tray_margin_lr: int = 10 if compact else 8
	var tray_margin_top: int = 10 if compact else 8
	var tray_margin_bottom: int = 12 if compact else 10
	var main_separation: int = 0 if very_compact else (0 if compact else 0)
	var content_separation: int = 8 if compact else 10
	var button_row_separation: int = 8 if compact else 10
	var shop_separation: int = 6 if compact else 8
	var utility_separation: int = 6 if compact else 8

	if _bottom_bar_margin is MarginContainer:
		var bottom_margin := _bottom_bar_margin as MarginContainer
		bottom_margin.add_theme_constant_override("margin_left", bottom_side_margin)
		bottom_margin.add_theme_constant_override("margin_top", 12)
		bottom_margin.add_theme_constant_override("margin_right", bottom_side_margin)
		bottom_margin.add_theme_constant_override("margin_bottom", 12)

	var header_separation: int = 8 if compact else 10
	var seed_block_separation: int = 6 if compact else 8
	var message_min_height: float = 68.0 if compact else 72.0
	var message_margin_lr: int = 6 if compact else 5
	var message_margin_tb: int = 3 if compact else 2
	var gold_min_height: float = 42.0 if compact else 46.0
	var gold_margin_lr: int = 10 if compact else 12
	var gold_margin_tb: int = 6 if compact else 7
	var seed_min_height: float = 94.0 if compact else 98.0
	var seed_margin_lr: int = 10 if compact else 12
	var seed_margin_tb: int = 10 if compact else 11

	if _main_layout is BoxContainer:
		(_main_layout as BoxContainer).add_theme_constant_override("separation", main_separation)
	if _content_block is BoxContainer:
		(_content_block as BoxContainer).add_theme_constant_override("separation", content_separation)
	if _header_row is BoxContainer:
		(_header_row as BoxContainer).add_theme_constant_override("separation", header_separation)
	if _controls_row is BoxContainer:
		(_controls_row as BoxContainer).add_theme_constant_override("separation", button_row_separation)
	if _utility_block is BoxContainer:
		(_utility_block as BoxContainer).add_theme_constant_override("separation", utility_separation)
	if _right_utility_layout != null:
		_right_utility_layout.add_theme_constant_override("separation", 6 if compact else 8)
	for row in [_right_utility_primary_row, _right_utility_secondary_row, _right_utility_actions_row]:
		if row != null:
			row.add_theme_constant_override("separation", 6 if compact else 8)
	if _seed_block is BoxContainer:
		(_seed_block as BoxContainer).add_theme_constant_override("separation", seed_block_separation)
	if _shop_block is BoxContainer:
		(_shop_block as BoxContainer).add_theme_constant_override("separation", shop_separation)

	var available_width: float = maxf(width - float(bottom_side_margin * 2) - float(main_separation * 2), 480.0)
	var share_total: float = left_share + center_share + right_share
	if share_total <= 0.0:
		share_total = 1.0
	left_share /= share_total
	center_share /= share_total
	right_share /= share_total

	var left_min: float = maxf(1.0, floor(available_width * left_share))
	var center_min: float = maxf(1.0, floor(available_width * center_share))
	var right_min: float = maxf(1.0, floor(available_width * right_share))
	var tightened_outer_lr: int = 0
	var center_outer_lr: int = 0
	var center_outer_tb: int = 4 if compact else 3

	if _dashboard_left_section != null:
		_dashboard_left_section.size_flags_stretch_ratio = left_share
	if _dashboard_center_section != null:
		_dashboard_center_section.size_flags_stretch_ratio = center_share
	if _dashboard_right_section != null:
		_dashboard_right_section.size_flags_stretch_ratio = right_share

	_set_dashboard_section_metrics(_dashboard_left_section, left_min, tightened_outer_lr, section_outer_tb, tray_margin_lr, tray_margin_top, tray_margin_bottom)
	_set_dashboard_section_metrics(_dashboard_center_section, center_min, center_outer_lr, center_outer_tb, 0, 0, 0)
	_set_dashboard_section_metrics(_dashboard_right_section, right_min, tightened_outer_lr, section_outer_tb, tray_margin_lr, tray_margin_top, tray_margin_bottom)

	var level_font_size: int = 22 if compact else 26
	var gold_font_size: int = 18 if compact else 20
	var summary_font_size: int = 16 if compact else 18

	if _message_banner_shell != null:
		_set_dashboard_wrapper_metrics(_message_banner_shell, message_min_height, message_margin_lr, message_margin_tb, message_margin_lr, message_margin_tb)
	_apply_message_text_boundaries()
	if _gold_shell != null:
		_set_dashboard_wrapper_metrics(_gold_shell, gold_min_height, gold_margin_lr, gold_margin_tb, gold_margin_lr, gold_margin_tb)
		_gold_shell.custom_minimum_size = Vector2(92.0 if compact else 104.0, gold_min_height)
		_gold_shell.size_flags_horizontal = 0
	if _seed_shell != null:
		_set_dashboard_wrapper_metrics(_seed_shell, seed_min_height, seed_margin_lr, seed_margin_tb, seed_margin_lr, seed_margin_tb)

	if _lbl_level != null:
		_lbl_level.add_theme_font_size_override("font_size", level_font_size)
	if _lbl_gold_value != null:
		_lbl_gold_value.add_theme_font_size_override("font_size", gold_font_size)
	if _pins_summary != null:
		_pins_summary.add_theme_font_size_override("font_size", summary_font_size)
	if _state_message != null:
		_state_message.add_theme_font_size_override("font_size", summary_font_size)
	if _scrollable_state_message != null:
		_apply_scrollable_state_message_theme(summary_font_size)

	for btn in [_pause_btn, _restart_btn, _retry_btn, _cancel_btn, _copy_btn, _load_btn, _extra_ball_btn, _place_magnet_btn, _skip_to_end_btn, _end_engagement_btn, _opening_gameplay_tutorial_skip_btn, _data_dump_btn, _help_btn, _reopen_summary_btn]:
		if btn != null:
			_apply_dashboard_button_style(btn, false)
	for btn in [_bigger_btn, _heavier_btn, _poison_btn, _forcefield_btn, _magnet_btn]:
		if btn != null:
			_apply_dashboard_button_style(btn, true)

	_apply_dashboard_icons()

func _apply_message_text_boundaries() -> void:
	if _stats_slot == null:
		return

	var left: float = float(LevelConfig.get_dashboard_message_text_boundary_left())
	var top: float = float(LevelConfig.get_dashboard_message_text_boundary_top())
	var right: float = float(LevelConfig.get_dashboard_message_text_boundary_right())
	var bottom: float = float(LevelConfig.get_dashboard_message_text_boundary_bottom())

	for node in [_pins_summary, _state_message, _scrollable_state_message]:
		if node == null:
			continue
		node.anchor_left = 0.0
		node.anchor_top = 0.0
		node.anchor_right = 1.0
		node.anchor_bottom = 1.0
		node.offset_left = left
		node.offset_top = top
		node.offset_right = -right
		node.offset_bottom = -bottom
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.size_flags_vertical = Control.SIZE_EXPAND_FILL
		node.clip_contents = true


func _set_dashboard_section_metrics(section: Control, min_width: float, outer_lr: int, outer_tb: int, tray_lr: int, tray_top: int, tray_bottom: int) -> void:
	if section == null:
		return
	section.custom_minimum_size = Vector2(min_width, 0.0)
	var outer_margin: MarginContainer = section.get_node_or_null("OuterMargin") as MarginContainer
	if outer_margin != null:
		outer_margin.add_theme_constant_override("margin_left", outer_lr)
		outer_margin.add_theme_constant_override("margin_top", outer_tb)
		outer_margin.add_theme_constant_override("margin_right", outer_lr)
		outer_margin.add_theme_constant_override("margin_bottom", outer_tb)
	var tray_margin: MarginContainer = section.get_node_or_null("OuterMargin/TrayRoot/TrayMargin") as MarginContainer
	if tray_margin != null:
		tray_margin.add_theme_constant_override("margin_left", tray_lr)
		tray_margin.add_theme_constant_override("margin_top", tray_top)
		tray_margin.add_theme_constant_override("margin_right", tray_lr)
		tray_margin.add_theme_constant_override("margin_bottom", tray_bottom)
	var content: VBoxContainer = section.get_node_or_null("OuterMargin/TrayRoot/TrayMargin/Content") as VBoxContainer
	if content != null:
		content.add_theme_constant_override("separation", 8)


func _set_dashboard_wrapper_metrics(wrapper: Control, min_height: float, margin_left: int, margin_top: int, margin_right: int, margin_bottom: int) -> void:
	if wrapper == null:
		return
	wrapper.custom_minimum_size = Vector2(0.0, min_height)
	var margin: MarginContainer = wrapper.get_node_or_null("Margin") as MarginContainer
	if margin != null:
		margin.add_theme_constant_override("margin_left", margin_left)
		margin.add_theme_constant_override("margin_top", margin_top)
		margin.add_theme_constant_override("margin_right", margin_right)
		margin.add_theme_constant_override("margin_bottom", margin_bottom)


func _create_dashboard_section(name: String, title_text: String, min_width: float, stretch_ratio: float, show_tray_background: bool = true) -> Control:
	var section := Control.new()
	section.name = name
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section.size_flags_stretch_ratio = stretch_ratio
	section.custom_minimum_size = Vector2(min_width, 0.0)
	section.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var outer_margin := MarginContainer.new()
	outer_margin.name = "OuterMargin"
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_theme_constant_override("margin_left", 8)
	outer_margin.add_theme_constant_override("margin_top", 8)
	outer_margin.add_theme_constant_override("margin_right", 8)
	outer_margin.add_theme_constant_override("margin_bottom", 8)
	section.add_child(outer_margin)

	var tray_root := Control.new()
	tray_root.name = "TrayRoot"
	tray_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_child(tray_root)

	if show_tray_background:
		var tray_bg: Control = _make_dashboard_background_node(
			name + "_TrayBg",
			DASHBOARD_TRAY_TEXTURE_PATH,
			DASHBOARD_SECTION_FILL,
			DASHBOARD_SECTION_BORDER,
			20,
			true,
			Color.WHITE
		)
		tray_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tray_root.add_child(tray_bg)
	else:
		section.set_meta("dashboard_banner_section", true)

	var tray_margin := MarginContainer.new()
	tray_margin.name = "TrayMargin"
	tray_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tray_margin.add_theme_constant_override("margin_left", 14)
	tray_margin.add_theme_constant_override("margin_top", 12)
	tray_margin.add_theme_constant_override("margin_right", 14)
	tray_margin.add_theme_constant_override("margin_bottom", 14)
	tray_root.add_child(tray_margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	tray_margin.add_child(content)

	return section


func _get_section_content(section: Control) -> VBoxContainer:
	if section == null:
		return null
	var node: Node = section.get_node_or_null("OuterMargin/TrayRoot/TrayMargin/Content")
	if node is VBoxContainer:
		return node as VBoxContainer
	return null


func _move_control_to_container(target: Control, destination: Node) -> void:
	if target == null or destination == null:
		return
	if target.get_parent() == destination:
		return
	var current_parent: Node = target.get_parent()
	if current_parent != null:
		current_parent.remove_child(target)
	destination.add_child(target)

func _ensure_dashboard_fill_spacer(container: VBoxContainer, spacer_name: String) -> Control:
	if container == null:
		return null
	var existing: Node = container.get_node_or_null(spacer_name)
	if existing is Control:
		var existing_control := existing as Control
		existing_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
		existing_control.custom_minimum_size = Vector2.ZERO
		return existing_control
	var spacer := Control.new()
	spacer.name = spacer_name
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size = Vector2.ZERO
	container.add_child(spacer)
	return spacer


func _wrap_control_in_dashboard_shell(
	target: Control,
	wrapper_name: String,
	texture_path: String,
	fill_color: Color,
	border_color: Color,
	min_height: float,
	margin_left: int,
	margin_top: int,
	margin_right: int,
	margin_bottom: int
) -> Control:
	if target == null:
		return null

	var current_parent: Node = target.get_parent()
	if current_parent == null:
		return null
	if current_parent is Control and (current_parent as Control).name == wrapper_name:
		return current_parent as Control

	var insertion_index: int = target.get_index()
	current_parent.remove_child(target)

	var wrapper := Control.new()
	wrapper.name = wrapper_name
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical = target.size_flags_vertical
	wrapper.custom_minimum_size = Vector2(0.0, maxf(target.custom_minimum_size.y, min_height))
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_parent.add_child(wrapper)
	current_parent.move_child(wrapper, insertion_index)

	var shell_bg: Control = _make_dashboard_background_node(
		wrapper_name + "_Bg",
		texture_path,
		fill_color,
		border_color,
		18,
		true,
		Color.WHITE
	)
	shell_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(shell_bg)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", margin_left)
	margin.add_theme_constant_override("margin_top", margin_top)
	margin.add_theme_constant_override("margin_right", margin_right)
	margin.add_theme_constant_override("margin_bottom", margin_bottom)
	wrapper.add_child(margin)

	target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(target)
	return wrapper


func _apply_dashboard_icons() -> void:
	_rebuild_gold_display_row()
	_insert_seed_row_icon()
	_apply_upgrade_card_content(_bigger_btn, DASHBOARD_ICON_BIGGER_PATH)
	_apply_upgrade_card_content(_heavier_btn, DASHBOARD_ICON_HEAVIER_PATH)
	_apply_upgrade_card_content(_poison_btn, DASHBOARD_ICON_POISON_PATH)
	_apply_upgrade_card_content(_forcefield_btn, DASHBOARD_ICON_FORCEFIELD_PATH)
	_apply_upgrade_card_content(_magnet_btn, DASHBOARD_ICON_MAGNET_PATH)
	_apply_utility_button_icon(_copy_btn, DASHBOARD_ICON_COPY_PATH, "Copy", false)
	_apply_utility_button_icon(_load_btn, DASHBOARD_ICON_LOAD_PATH, "Load", false)
	_rebuild_right_panel_utility_cluster()
	_refresh_right_panel_primary_controls()


func _rebuild_right_panel_utility_cluster() -> void:
	if _utility_block == null:
		return
	_clear_control_background(_utility_block)
	var gold_target: Control = _gold_shell if _gold_shell != null else _gold_block
	var structure_signature: String = _get_right_panel_utility_structure_signature(gold_target)
	var needs_structure_rebuild: bool = false
	if _right_utility_layout == null or not is_instance_valid(_right_utility_layout):
		_right_utility_layout = _utility_block.get_node_or_null("RightUtilityLayout") as VBoxContainer
	if _right_utility_layout == null:
		needs_structure_rebuild = true
	else:
		_right_utility_primary_row = _right_utility_layout.get_node_or_null("PrimaryRow") as HBoxContainer
		_right_utility_secondary_row = _right_utility_layout.get_node_or_null("SecondaryRow") as HBoxContainer
		_right_utility_stop_row = _right_utility_layout.get_node_or_null("StopRow") as HBoxContainer
		_right_utility_actions_row = _right_utility_layout.get_node_or_null("ActionsRow") as HBoxContainer
		if _right_utility_primary_row == null or _right_utility_secondary_row == null or _right_utility_stop_row == null or _right_utility_actions_row == null:
			needs_structure_rebuild = true
		elif structure_signature != _right_panel_utility_structure_signature:
			needs_structure_rebuild = true

	if needs_structure_rebuild:
		if _right_utility_layout == null:
			_right_utility_layout = VBoxContainer.new()
			_right_utility_layout.name = "RightUtilityLayout"
			_right_utility_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_right_utility_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_utility_block.add_child(_right_utility_layout)

		_right_utility_primary_row = _get_or_create_named_hbox(_right_utility_layout, "PrimaryRow")
		_right_utility_secondary_row = _get_or_create_named_hbox(_right_utility_layout, "SecondaryRow")
		_right_utility_stop_row = _get_or_create_named_hbox(_right_utility_layout, "StopRow")
		_right_utility_actions_row = _get_or_create_named_hbox(_right_utility_layout, "ActionsRow")

		_move_control_to_container(gold_target, _right_utility_primary_row)
		_move_control_to_container(_restart_btn, _right_utility_primary_row)
		for btn in [_retry_btn, _skip_to_end_btn, _opening_gameplay_tutorial_skip_btn, _data_dump_btn, _help_btn, _reopen_summary_btn]:
			_move_control_to_container(btn, _right_utility_secondary_row)
		_move_control_to_container(_end_engagement_btn, _right_utility_stop_row)
		if _pause_btn != null:
			_pause_btn.visible = false
			_pause_btn.disabled = true
		for btn in [_data_dump_btn, _troop_debug_btn, _friendly_boss_debug_btn, _cancel_btn, _place_magnet_btn]:
			_move_control_to_container(btn, _right_utility_actions_row)
		_right_panel_utility_structure_signature = structure_signature

	_refresh_right_panel_utility_cluster_visibility()


func _get_right_panel_utility_structure_signature(gold_target: Control) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append(str(gold_target != null))
	parts.append(str(gold_target.get_instance_id()) if gold_target != null else "0")
	for node in [_restart_btn, _retry_btn, _skip_to_end_btn, _end_engagement_btn, _opening_gameplay_tutorial_skip_btn, _data_dump_btn, _troop_debug_btn, _friendly_boss_debug_btn, _help_btn, _reopen_summary_btn, _cancel_btn, _place_magnet_btn]:
		parts.append(str(node != null))
		parts.append(str(node.get_instance_id()) if node != null else "0")
	return "|".join(parts)


func _refresh_right_panel_utility_cluster_visibility() -> void:
	if _right_utility_primary_row != null:
		_right_utility_primary_row.visible = true
	if _right_utility_secondary_row != null:
		_right_utility_secondary_row.visible = true
	if _right_utility_stop_row != null:
		var has_visible_stop: bool = false
		for child in _right_utility_stop_row.get_children():
			if child is CanvasItem and (child as CanvasItem).visible:
				has_visible_stop = true
				break
		_right_utility_stop_row.visible = has_visible_stop
	if _right_utility_actions_row != null:
		var has_visible_action: bool = false
		for child in _right_utility_actions_row.get_children():
			if child is CanvasItem and (child as CanvasItem).visible:
				has_visible_action = true
				break
		_right_utility_actions_row.visible = has_visible_action

func _get_or_create_named_hbox(parent: Node, name: String) -> HBoxContainer:
	if parent == null:
		return null
	var existing: HBoxContainer = parent.get_node_or_null(name) as HBoxContainer
	if existing != null:
		return existing
	var row := HBoxContainer.new()
	row.name = name
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	parent.add_child(row)
	return row


func _refresh_right_panel_primary_controls() -> void:
	_apply_symbol_control_button(_pause_btn, DASHBOARD_GLYPH_RESUME if _pause_btn != null and _pause_btn.text == "Resume" else DASHBOARD_GLYPH_PAUSE, "Resume" if _pause_btn != null and _pause_btn.text == "Resume" else "Pause")
	_apply_symbol_control_button(_restart_btn, DASHBOARD_GLYPH_RESTART, "Restart Run")
	_apply_symbol_control_button(_retry_btn, DASHBOARD_GLYPH_RETRY, "Retry Level")
	_apply_symbol_control_button(_skip_to_end_btn, DASHBOARD_GLYPH_STOP if _skip_to_end_btn != null and _skip_to_end_btn.text == "Stop Skipping" else DASHBOARD_GLYPH_SKIP, "Stop Skipping" if _skip_to_end_btn != null and _skip_to_end_btn.text == "Stop Skipping" else "Skip to End")
	_apply_wide_stop_button(_end_engagement_btn)
	if _opening_gameplay_tutorial_skip_btn != null:
		_opening_gameplay_tutorial_skip_btn.icon = null
		_opening_gameplay_tutorial_skip_btn.tooltip_text = _opening_gameplay_tutorial_skip_label
		_opening_gameplay_tutorial_skip_btn.text = _opening_gameplay_tutorial_skip_label
	_apply_symbol_control_button(_data_dump_btn, "BR", "Bug Report")
	_apply_symbol_control_button(_troop_debug_btn, "TD", "Troop Debug")
	_apply_symbol_control_button(_friendly_boss_debug_btn, "BD", "Boss Debug")
	_apply_symbol_control_button(_log_schema_btn, "LS", "Log Schema")
	_apply_symbol_control_button(_help_btn, DASHBOARD_GLYPH_HELP, "Help")
	_apply_symbol_control_button(_reopen_summary_btn, DASHBOARD_GLYPH_SUMMARY, "Summary")


func _apply_symbol_control_button(btn: Button, glyph: String, tooltip_label: String) -> void:
	if btn == null:
		return
	btn.icon = null
	btn.text = glyph
	btn.tooltip_text = tooltip_label
	btn.clip_text = false
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	var viewport: Viewport = get_viewport()
	var layout_width: float = _bottom_bar.size.x if _bottom_bar != null else 0.0
	if layout_width <= 1.0 and viewport != null:
		layout_width = viewport.get_visible_rect().size.x
	var compact: bool = layout_width > 0.0 and layout_width < 1040.0
	btn.add_theme_font_size_override("font_size", 20 if compact else 22)
	btn.custom_minimum_size = Vector2(44.0 if compact else 48.0, 42.0 if compact else 46.0)


func _apply_wide_stop_button(btn: Button) -> void:
	if btn == null:
		return
	btn.icon = null
	btn.text = "Stop"
	btn.tooltip_text = "Stop"
	btn.clip_text = false
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var viewport: Viewport = get_viewport()
	var layout_width: float = _bottom_bar.size.x if _bottom_bar != null else 0.0
	if layout_width <= 1.0 and viewport != null:
		layout_width = viewport.get_visible_rect().size.x
	var compact: bool = layout_width > 0.0 and layout_width < 1040.0
	btn.add_theme_font_size_override("font_size", 18 if compact else 20)
	btn.custom_minimum_size = Vector2(0.0, 42.0 if compact else 46.0)


func _rebuild_gold_display_row() -> void:
	if _gold_block == null or _lbl_gold_value == null:
		return
	_clear_control_background(_gold_block)
	var row: HBoxContainer = _gold_block.get_node_or_null("DashboardGoldRow") as HBoxContainer
	if row != null and _lbl_gold_value.get_parent() == row:
		_gold_icon_rect = row.get_node_or_null("GoldIcon") as TextureRect
		if _gold_icon_rect != null:
			_gold_icon_rect.texture = _load_dashboard_icon_texture(DASHBOARD_ICON_GOLD_PATH, DASHBOARD_INLINE_ICON_SIZE)
		return

	for child in _gold_block.get_children():
		if child == _lbl_gold_value:
			continue
		if child is HBoxContainer and child.name == "DashboardGoldRow":
			continue
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		_gold_block.remove_child(child)
		child.queue_free()
	if row == null:
		var old_parent: Node = _lbl_gold_value.get_parent()
		if old_parent != null:
			old_parent.remove_child(_lbl_gold_value)
		row = HBoxContainer.new()
		row.name = "DashboardGoldRow"
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_theme_constant_override("separation", 6)
		_gold_block.add_child(row)
		_gold_icon_rect = TextureRect.new()
		_gold_icon_rect.name = "GoldIcon"
		_gold_icon_rect.custom_minimum_size = Vector2(float(DASHBOARD_INLINE_ICON_SIZE.x), float(DASHBOARD_INLINE_ICON_SIZE.y))
		_gold_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_gold_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(_gold_icon_rect)
		_lbl_gold_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_lbl_gold_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(_lbl_gold_value)
	else:
		_gold_icon_rect = row.get_node_or_null("GoldIcon") as TextureRect
	if _gold_icon_rect != null:
		_gold_icon_rect.texture = _load_dashboard_icon_texture(DASHBOARD_ICON_GOLD_PATH, DASHBOARD_INLINE_ICON_SIZE)

func _insert_seed_row_icon() -> void:
	if _seed_label == null:
		return
	var row := _seed_label.get_parent()
	if row == null:
		return
	if row is BoxContainer:
		(row as BoxContainer).add_theme_constant_override("separation", 8)
	var existing: TextureRect = row.get_node_or_null("SeedIcon") as TextureRect
	if existing == null:
		existing = TextureRect.new()
		existing.name = "SeedIcon"
		existing.custom_minimum_size = Vector2(float(DASHBOARD_SMALL_BUTTON_ICON_SIZE.x), float(DASHBOARD_SMALL_BUTTON_ICON_SIZE.y))
		existing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		existing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(existing)
		row.move_child(existing, 0)
	_seed_icon_rect = existing
	_seed_icon_rect.texture = _load_dashboard_icon_texture(DASHBOARD_ICON_SEED_PATH, DASHBOARD_SMALL_BUTTON_ICON_SIZE)


func _get_upgrade_card_layout_metrics() -> Dictionary:
	var viewport: Viewport = get_viewport()
	var layout_width: float = _bottom_bar.size.x if _bottom_bar != null else 0.0
	if layout_width <= 1.0 and viewport != null:
		layout_width = viewport.get_visible_rect().size.x
	if layout_width <= 1.0:
		layout_width = 1280.0

	var compact: bool = layout_width < 1040.0
	var very_compact: bool = layout_width < 760.0
	var target_height: float = _get_upgrade_card_target_height(compact)
	var icon_size: int = 38 if not compact else 34
	var cost_icon_size: int = 16 if not compact else 14
	var level_font_size: int = 16 if not compact else 14
	var cost_font_size: int = 15 if not compact else 13
	var outer_margin_h: int = 12 if target_height >= 64.0 else 10
	var outer_margin_v: int = 8 if target_height >= 64.0 else 6
	var gap: int = 10 if target_height >= 64.0 else 8
	var row_gap: int = 2

	if very_compact:
		icon_size = mini(icon_size, 32)
		cost_icon_size = mini(cost_icon_size, 13)
		level_font_size = mini(level_font_size, 13)
		cost_font_size = mini(cost_font_size, 12)
		outer_margin_h = mini(outer_margin_h, 9)
		outer_margin_v = mini(outer_margin_v, 5)
		gap = mini(gap, 7)

	icon_size = int(clampf(float(icon_size), 28.0, maxf(target_height - 14.0, 28.0)))
	cost_icon_size = int(clampf(float(cost_icon_size), 12.0, maxf(float(icon_size) - 18.0, 12.0)))

	return {
		"icon_size": icon_size,
		"cost_icon_size": cost_icon_size,
		"level_font_size": level_font_size,
		"cost_font_size": cost_font_size,
		"outer_margin_h": outer_margin_h,
		"outer_margin_v": outer_margin_v,
		"gap": gap,
		"row_gap": row_gap,
	}


func _apply_upgrade_card_content(btn: Button, texture_path: String) -> void:
	if btn == null:
		return

	var metrics: Dictionary = _get_upgrade_card_layout_metrics()
	var icon_size: int = int(metrics.get("icon_size", 34))
	var cost_icon_size: int = int(metrics.get("cost_icon_size", 14))
	var outer_margin_h: int = int(metrics.get("outer_margin_h", 10))
	var outer_margin_v: int = int(metrics.get("outer_margin_v", 6))
	var gap: int = int(metrics.get("gap", 8))
	var row_gap: int = int(metrics.get("row_gap", 2))
	var level_font_size: int = int(metrics.get("level_font_size", 14))
	var cost_font_size: int = int(metrics.get("cost_font_size", 13))

	var icon_texture: Texture2D = _load_dashboard_icon_texture(texture_path, Vector2i(icon_size, icon_size))
	var cost_icon_texture: Texture2D = _load_dashboard_icon_texture(DASHBOARD_ICON_GOLD_PATH, Vector2i(cost_icon_size, cost_icon_size))
	if icon_texture == null:
		return

	btn.icon = null
	btn.text = ""
	btn.expand_icon = false
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.set_meta("upgrade_icon_path", texture_path)

	var shell: MarginContainer = btn.get_node_or_null("UpgradeCardShell") as MarginContainer
	if shell == null:
		shell = MarginContainer.new()
		shell.name = "UpgradeCardShell"
		shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.add_child(shell)

	var content: HBoxContainer = shell.get_node_or_null("UpgradeCardContent") as HBoxContainer
	if content == null:
		content = HBoxContainer.new()
		content.name = "UpgradeCardContent"
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		shell.add_child(content)

	var icon_wrap: CenterContainer = content.get_node_or_null("IconWrap") as CenterContainer
	if icon_wrap == null:
		icon_wrap = CenterContainer.new()
		icon_wrap.name = "IconWrap"
		icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon_wrap)

	var icon_rect: TextureRect = icon_wrap.get_node_or_null("UpgradeIcon") as TextureRect
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = "UpgradeIcon"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_wrap.add_child(icon_rect)

	var info_column: VBoxContainer = content.get_node_or_null("InfoColumn") as VBoxContainer
	if info_column == null:
		info_column = VBoxContainer.new()
		info_column.name = "InfoColumn"
		info_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		info_column.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_child(info_column)

	var level_label: Label = info_column.get_node_or_null("LevelLabel") as Label
	if level_label == null:
		level_label = Label.new()
		level_label.name = "LevelLabel"
		level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_column.add_child(level_label)

	var cost_row: HBoxContainer = info_column.get_node_or_null("CostRow") as HBoxContainer
	if cost_row == null:
		cost_row = HBoxContainer.new()
		cost_row.name = "CostRow"
		cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cost_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		info_column.add_child(cost_row)

	var cost_icon_rect: TextureRect = cost_row.get_node_or_null("CostIcon") as TextureRect
	if cost_icon_rect == null:
		cost_icon_rect = TextureRect.new()
		cost_icon_rect.name = "CostIcon"
		cost_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cost_row.add_child(cost_icon_rect)

	var cost_label: Label = cost_row.get_node_or_null("CostLabel") as Label
	if cost_label == null:
		cost_label = Label.new()
		cost_label.name = "CostLabel"
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cost_row.add_child(cost_label)

	shell.add_theme_constant_override("margin_left", outer_margin_h)
	shell.add_theme_constant_override("margin_top", outer_margin_v)
	shell.add_theme_constant_override("margin_right", outer_margin_h)
	shell.add_theme_constant_override("margin_bottom", outer_margin_v)
	content.add_theme_constant_override("separation", gap)
	info_column.add_theme_constant_override("separation", row_gap)
	cost_row.add_theme_constant_override("separation", 4)
	icon_wrap.custom_minimum_size = Vector2(float(icon_size), 0.0)
	icon_rect.custom_minimum_size = Vector2(float(icon_size), float(icon_size))
	icon_rect.texture = icon_texture
	cost_icon_rect.custom_minimum_size = Vector2(float(cost_icon_size), float(cost_icon_size))
	cost_icon_rect.texture = cost_icon_texture
	level_label.add_theme_font_size_override("font_size", level_font_size)
	cost_label.add_theme_font_size_override("font_size", cost_font_size)


func _refresh_upgrade_card_content(btn: Button, display_name: String, level: int, cost: int, can_afford: bool) -> void:
	if btn == null:
		return

	var texture_path: String = str(btn.get_meta("upgrade_icon_path", ""))
	if not btn.has_node("UpgradeCardShell") and texture_path != "":
		_apply_upgrade_card_content(btn, texture_path)

	var level_label: Label = btn.get_node_or_null("UpgradeCardShell/UpgradeCardContent/InfoColumn/LevelLabel") as Label
	var cost_label: Label = btn.get_node_or_null("UpgradeCardShell/UpgradeCardContent/InfoColumn/CostRow/CostLabel") as Label
	var cost_icon_rect: TextureRect = btn.get_node_or_null("UpgradeCardShell/UpgradeCardContent/InfoColumn/CostRow/CostIcon") as TextureRect
	if level_label != null:
		level_label.text = "Lv %d" % maxi(level, 0)
		level_label.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY if can_afford else DASHBOARD_TEXT_MUTED)
	if cost_label != null:
		cost_label.text = str(maxi(cost, 0))
		cost_label.add_theme_color_override("font_color", DASHBOARD_TEXT_GOLD if can_afford else DASHBOARD_TEXT_MUTED)
	if cost_icon_rect != null:
		cost_icon_rect.modulate = Color.WHITE if can_afford else Color(0.62, 0.60, 0.58, 1.0)

	btn.tooltip_text = "%s\nLevel %d • Cost %d" % [display_name, maxi(level, 0), maxi(cost, 0)]


func _apply_utility_button_icon(btn: Button, texture_path: String, label_text: String, icon_only: bool) -> void:
	if btn == null:
		return
	var icon_texture := _load_dashboard_icon_texture(texture_path, DASHBOARD_SMALL_BUTTON_ICON_SIZE)
	if icon_texture == null:
		return
	btn.icon = icon_texture
	btn.expand_icon = false
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT if not icon_only else HORIZONTAL_ALIGNMENT_CENTER
	if icon_only:
		btn.text = ""
		btn.custom_minimum_size = Vector2(42.0, maxf(btn.custom_minimum_size.y, 40.0))
	else:
		btn.text = label_text


func _load_dashboard_icon_texture(texture_path: String, target_size: Vector2i) -> Texture2D:
	var cache_key := "%s|%dx%d" % [texture_path, target_size.x, target_size.y]
	if _dashboard_icon_cache.has(cache_key):
		return _dashboard_icon_cache[cache_key] as Texture2D
	var base_texture := _load_dashboard_texture(texture_path)
	if base_texture == null:
		return null
	var image: Image = base_texture.get_image()
	if image == null:
		return base_texture
	var working: Image = image.duplicate()
	working.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var tex := ImageTexture.create_from_image(working)
	_dashboard_icon_cache[cache_key] = tex
	return tex


func _strip_legacy_bottom_bar_frame() -> void:
	_clear_control_background(_bottom_bar)
	_clear_control_background(_bottom_bar_margin)
	_clear_control_background(_main_layout)
	_clear_control_background(_content_block)
	_clear_control_background(_shop_block)


func _clear_legacy_bottom_bar_backgrounds() -> void:
	if _bottom_bar == null:
		return
	_clear_legacy_bottom_bar_backgrounds_recursive(_bottom_bar)


func _clear_legacy_bottom_bar_backgrounds_recursive(node: Node) -> void:
	for child in node.get_children():
		if child == _bottom_bar_margin or child == _dashboard_outer_frame_bg or child == _win_burst:
			continue
		if child is ColorRect or child is Panel or child is PanelContainer:
			(child as CanvasItem).visible = false
			_clear_control_background(child as Control)
		_clear_legacy_bottom_bar_backgrounds_recursive(child)


func _clear_control_background(control: Control) -> void:
	if control == null:
		return
	var empty_style := StyleBoxEmpty.new()
	control.add_theme_stylebox_override("panel", empty_style)
	control.add_theme_stylebox_override("normal", empty_style)
	control.add_theme_stylebox_override("focus", empty_style)
	if control is Panel:
		(control as Panel).self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	if control is PanelContainer:
		(control as PanelContainer).self_modulate = Color(1.0, 1.0, 1.0, 1.0)


func _make_dashboard_background_node(
	name: String,
	texture_path: String,
	fill_color: Color,
	border_color: Color,
	corner_radius: int,
	draw_center: bool = true,
	texture_modulate: Color = Color.WHITE
) -> Control:
	var texture := _load_dashboard_texture(texture_path)
	if texture != null:
		var patch := NinePatchRect.new()
		patch.name = name
		patch.texture = texture
		patch.draw_center = draw_center
		patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var patch_margins: Rect2i = _get_dashboard_patch_margins_for_texture(texture_path)
		patch.patch_margin_left = patch_margins.position.x
		patch.patch_margin_top = patch_margins.position.y
		patch.patch_margin_right = patch_margins.size.x
		patch.patch_margin_bottom = patch_margins.size.y
		patch.modulate = texture_modulate
		return patch

	var panel := Panel.new()
	panel.name = name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_stylebox(fill_color, border_color, corner_radius, 2))
	return panel


func _load_dashboard_texture(texture_path: String) -> Texture2D:
	if texture_path.strip_edges().is_empty():
		return null
	if not ResourceLoader.exists(texture_path):
		return null
	var resource: Resource = load(texture_path)
	if resource is Texture2D:
		return resource as Texture2D
	return null


func _get_dashboard_patch_margins_for_texture(texture_path: String) -> Rect2i:
	match texture_path:
		DASHBOARD_FRAME_TEXTURE_PATH:
			return DASHBOARD_FRAME_PATCH_MARGINS
		DASHBOARD_TRAY_TEXTURE_PATH:
			return DASHBOARD_TRAY_PATCH_MARGINS
		DASHBOARD_BANNER_TEXTURE_PATH:
			return DASHBOARD_BANNER_PATCH_MARGINS
		_:
			return Rect2i(DASHBOARD_PATCH_MARGIN, DASHBOARD_PATCH_MARGIN, DASHBOARD_PATCH_MARGIN, DASHBOARD_PATCH_MARGIN)


func _make_panel_stylebox(fill_color: Color, border_color: Color, corner_radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style


func _make_button_stylebox(
	fill_color: Color,
	border_color: Color,
	corner_radius: int,
	content_margin_left: int = 12,
	content_margin_top: int = 10,
	content_margin_right: int = 12,
	content_margin_bottom: int = 10
) -> StyleBoxFlat:
	var style := _make_panel_stylebox(fill_color, border_color, corner_radius, 2)
	style.content_margin_left = content_margin_left
	style.content_margin_top = content_margin_top
	style.content_margin_right = content_margin_right
	style.content_margin_bottom = content_margin_bottom
	return style


func _make_input_stylebox(focused: bool) -> StyleBoxFlat:
	var border: Color = DASHBOARD_BANNER_BORDER if focused else DASHBOARD_TRAY_BORDER
	return _make_button_stylebox(Color(0.08, 0.06, 0.05, 0.96), border, 14)


func _apply_dashboard_button_style(btn: Button, is_upgrade_card: bool) -> void:
	if btn == null:
		return

	var normal_fill: Color = DASHBOARD_UPGRADE_BUTTON_FILL if is_upgrade_card else DASHBOARD_CONTROL_BUTTON_FILL
	var hover_fill: Color = DASHBOARD_UPGRADE_BUTTON_HOVER if is_upgrade_card else DASHBOARD_CONTROL_BUTTON_HOVER
	var pressed_fill: Color = DASHBOARD_UPGRADE_BUTTON_PRESSED if is_upgrade_card else DASHBOARD_CONTROL_BUTTON_PRESSED
	var disabled_fill: Color = DASHBOARD_UPGRADE_BUTTON_DISABLED if is_upgrade_card else DASHBOARD_CONTROL_BUTTON_DISABLED
	var border: Color = DASHBOARD_UPGRADE_BUTTON_BORDER if is_upgrade_card else DASHBOARD_CONTROL_BUTTON_BORDER
	var radius: int = 18 if is_upgrade_card else 14

	btn.focus_mode = Control.FOCUS_CLICK
	btn.clip_text = false
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var viewport: Viewport = get_viewport()
	var layout_width: float = _bottom_bar.size.x if _bottom_bar != null else 0.0
	if layout_width <= 1.0 and viewport != null:
		layout_width = viewport.get_visible_rect().size.x
	var compact: bool = layout_width > 0.0 and layout_width < 1040.0
	var button_separation: int = 8 if is_upgrade_card else (6 if compact else 8)
	var control_button_width: float = 84.0 if compact else 92.0
	var control_button_height: float = 42.0 if compact else 46.0
	var is_symbol_control: bool = (not is_upgrade_card) and btn in [_pause_btn, _restart_btn, _retry_btn, _skip_to_end_btn, _end_engagement_btn, _data_dump_btn, _help_btn, _reopen_summary_btn]

	var font_size: int = 14 if compact else (15 if is_upgrade_card else 14)
	var content_margin_left: int = 12
	var content_margin_top: int = 10
	var content_margin_right: int = 12
	var content_margin_bottom: int = 10
	var upgrade_card_height: float = 78.0 if compact else 86.0
	if is_upgrade_card:
		upgrade_card_height = _get_upgrade_card_target_height(compact)
		if upgrade_card_height <= 50.0:
			font_size = 11
			button_separation = 5
			content_margin_left = 9
			content_margin_top = 5
			content_margin_right = 9
			content_margin_bottom = 5
		elif upgrade_card_height <= 58.0:
			font_size = 12
			button_separation = 6
			content_margin_left = 10
			content_margin_top = 6
			content_margin_right = 10
			content_margin_bottom = 6
		elif upgrade_card_height <= 68.0:
			font_size = 13
			button_separation = 7
			content_margin_left = 11
			content_margin_top = 7
			content_margin_right = 11
			content_margin_bottom = 7

	if is_symbol_control:
		button_separation = 0
		control_button_width = 44.0 if compact else 48.0
		font_size = 20 if compact else 22
		content_margin_left = 6
		content_margin_top = 6
		content_margin_right = 6
		content_margin_bottom = 6

	btn.add_theme_constant_override("h_separation", button_separation)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	btn.add_theme_color_override("font_color_hover", DASHBOARD_TEXT_PRIMARY)
	btn.add_theme_color_override("font_color_pressed", DASHBOARD_TEXT_PRIMARY)
	btn.add_theme_color_override("font_color_disabled", DASHBOARD_TEXT_MUTED)
	btn.add_theme_stylebox_override("normal", _make_button_stylebox(normal_fill, border, radius, content_margin_left, content_margin_top, content_margin_right, content_margin_bottom))
	btn.add_theme_stylebox_override("hover", _make_button_stylebox(hover_fill, border.lightened(0.08), radius, content_margin_left, content_margin_top, content_margin_right, content_margin_bottom))
	btn.add_theme_stylebox_override("pressed", _make_button_stylebox(pressed_fill, border, radius, content_margin_left, content_margin_top, content_margin_right, content_margin_bottom))
	btn.add_theme_stylebox_override("disabled", _make_button_stylebox(disabled_fill, border.darkened(0.35), radius, content_margin_left, content_margin_top, content_margin_right, content_margin_bottom))

	if is_upgrade_card:
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0.0, upgrade_card_height)
	else:
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER if is_symbol_control else HORIZONTAL_ALIGNMENT_CENTER
		btn.custom_minimum_size = Vector2(maxf(btn.custom_minimum_size.x, control_button_width), maxf(btn.custom_minimum_size.y, control_button_height))


func _get_upgrade_card_target_height(compact: bool) -> float:
	var button_count: int = 0
	for upgrade_btn in [_bigger_btn, _heavier_btn, _poison_btn, _forcefield_btn, _magnet_btn]:
		if upgrade_btn != null and is_instance_valid(upgrade_btn) and upgrade_btn.visible:
			button_count += 1
	if button_count <= 0:
		return 78.0 if compact else 86.0

	var panel_height: float = 0.0
	if _dashboard_left_section != null and _dashboard_left_section.size.y > 1.0:
		panel_height = _dashboard_left_section.size.y
	elif _bottom_bar != null and _bottom_bar.size.y > 1.0:
		panel_height = _bottom_bar.size.y
	else:
		var viewport: Viewport = get_viewport()
		if viewport != null:
			panel_height = viewport.get_visible_rect().size.y * 0.28

	var compact_spacing: float = 6.0 if compact else 8.0
	var estimated_vertical_overhead: float = 48.0
	var available_for_cards: float = maxf(panel_height - estimated_vertical_overhead - compact_spacing * float(maxi(button_count - 1, 0)), 180.0)
	var target_height: float = floorf(available_for_cards / float(button_count))
	return clampf(target_height, 46.0, 86.0)


func _ensure_forcefield_button() -> void:
	if _shop_block == null:
		return
	if _forcefield_btn != null and is_instance_valid(_forcefield_btn):
		return
	if _shop_block.has_node("ForcefieldBtn"):
		var existing: Node = _shop_block.get_node("ForcefieldBtn")
		if existing is Button:
			_forcefield_btn = existing as Button
			return

	_forcefield_btn = Button.new()
	_forcefield_btn.name = "ForcefieldBtn"
	_forcefield_btn.text = "Forcefield"
	_forcefield_btn.focus_mode = Control.FOCUS_CLICK
	_forcefield_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_forcefield_btn.custom_minimum_size = Vector2(0, 64)
	_shop_block.add_child(_forcefield_btn)




func _ensure_magnet_button() -> void:
	if _shop_block == null:
		return
	if _magnet_btn != null and is_instance_valid(_magnet_btn):
		return
	if _shop_block.has_node("MagnetBtn"):
		var existing: Node = _shop_block.get_node("MagnetBtn")
		if existing is Button:
			_magnet_btn = existing as Button
			return

	_magnet_btn = Button.new()
	_magnet_btn.name = "MagnetBtn"
	_magnet_btn.text = "Magnet"
	_magnet_btn.focus_mode = Control.FOCUS_CLICK
	_magnet_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_magnet_btn.custom_minimum_size = Vector2(0, 64)
	_shop_block.add_child(_magnet_btn)


func _ensure_place_magnet_button() -> void:
	if _utility_block == null:
		return
	if _place_magnet_btn != null and is_instance_valid(_place_magnet_btn):
		return
	if _utility_block.has_node("PlaceMagnetBtn"):
		var existing: Node = _utility_block.get_node("PlaceMagnetBtn")
		if existing is Button:
			_place_magnet_btn = existing as Button
			return

	_place_magnet_btn = Button.new()
	_place_magnet_btn.name = "PlaceMagnetBtn"
	_place_magnet_btn.text = "Place Magnet"
	_place_magnet_btn.visible = false
	_place_magnet_btn.focus_mode = Control.FOCUS_CLICK
	_place_magnet_btn.custom_minimum_size = Vector2(118, 0)
	_utility_block.add_child(_place_magnet_btn)


func _ensure_skip_to_end_button() -> void:
	if _utility_block == null:
		return
	if _skip_to_end_btn != null and is_instance_valid(_skip_to_end_btn):
		return
	if _utility_block.has_node("SkipToEndBtn"):
		var existing: Node = _utility_block.get_node("SkipToEndBtn")
		if existing is Button:
			_skip_to_end_btn = existing as Button
			return

	_skip_to_end_btn = Button.new()
	_skip_to_end_btn.name = "SkipToEndBtn"
	_skip_to_end_btn.text = "Skip to End"
	_skip_to_end_btn.visible = false
	_skip_to_end_btn.disabled = false
	_skip_to_end_btn.focus_mode = Control.FOCUS_CLICK
	_skip_to_end_btn.custom_minimum_size = Vector2(118, 0)
	_utility_block.add_child(_skip_to_end_btn)


func _ensure_end_engagement_button() -> void:
	if _utility_block == null:
		return
	if _end_engagement_btn != null and is_instance_valid(_end_engagement_btn):
		return
	if _utility_block.has_node("EndEngagementBtn"):
		var existing: Node = _utility_block.get_node("EndEngagementBtn")
		if existing is Button:
			_end_engagement_btn = existing as Button
			return

	_end_engagement_btn = Button.new()
	_end_engagement_btn.name = "EndEngagementBtn"
	_end_engagement_btn.text = "End"
	_end_engagement_btn.visible = false
	_end_engagement_btn.disabled = false
	_end_engagement_btn.focus_mode = Control.FOCUS_CLICK
	_end_engagement_btn.custom_minimum_size = Vector2(118, 0)
	_utility_block.add_child(_end_engagement_btn)


func _ensure_opening_gameplay_tutorial_skip_button() -> void:
	if _utility_block == null:
		return
	if _opening_gameplay_tutorial_skip_btn != null and is_instance_valid(_opening_gameplay_tutorial_skip_btn):
		return
	if _utility_block.has_node("OpeningGameplayTutorialSkipBtn"):
		var existing: Node = _utility_block.get_node("OpeningGameplayTutorialSkipBtn")
		if existing is Button:
			_opening_gameplay_tutorial_skip_btn = existing as Button
			return

	_opening_gameplay_tutorial_skip_btn = Button.new()
	_opening_gameplay_tutorial_skip_btn.name = "OpeningGameplayTutorialSkipBtn"
	_opening_gameplay_tutorial_skip_btn.text = _opening_gameplay_tutorial_skip_label
	_opening_gameplay_tutorial_skip_btn.visible = false
	_opening_gameplay_tutorial_skip_btn.disabled = false
	_opening_gameplay_tutorial_skip_btn.focus_mode = Control.FOCUS_CLICK
	_opening_gameplay_tutorial_skip_btn.custom_minimum_size = Vector2(118, 0)
	_utility_block.add_child(_opening_gameplay_tutorial_skip_btn)


func _ensure_help_button() -> void:
	if _utility_block == null:
		return
	if _help_btn != null and is_instance_valid(_help_btn):
		return
	if _utility_block.has_node("HelpBtn"):
		var existing: Node = _utility_block.get_node("HelpBtn")
		if existing is Button:
			_help_btn = existing as Button
		else:
			return
	else:
		_help_btn = Button.new()
		_help_btn.name = "HelpBtn"
		_help_btn.text = "Help"
		_help_btn.focus_mode = Control.FOCUS_CLICK
		_help_btn.custom_minimum_size = Vector2(92, 0)
		_utility_block.add_child(_help_btn)

	if not _help_btn.pressed.is_connected(_on_help_pressed):
		_help_btn.pressed.connect(_on_help_pressed)

	if _help_badge == null or not is_instance_valid(_help_badge):
		_help_badge = Label.new()
		_help_badge.name = "UnreadBadge"
		_help_badge.visible = false
		_help_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_help_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_help_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_help_badge.add_theme_font_size_override("font_size", 12)
		_help_badge.add_theme_color_override("font_color", Color(0.08, 0.04, 0.02, 1.0))
		_help_badge.anchor_left = 1.0
		_help_badge.anchor_top = 0.0
		_help_badge.anchor_right = 1.0
		_help_badge.anchor_bottom = 0.0
		_help_badge.offset_left = -28.0
		_help_badge.offset_top = -4.0
		_help_badge.offset_right = -4.0
		_help_badge.offset_bottom = 18.0
		_help_badge.text = "1"
		var badge_bg := ColorRect.new()
		badge_bg.name = "BadgeBg"
		badge_bg.color = Color(0.96, 0.81, 0.24, 0.98)
		badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_help_badge.add_child(badge_bg)
		_help_badge.move_child(badge_bg, 0)
		_help_btn.add_child(_help_badge)
	_refresh_right_panel_primary_controls()

func _ensure_data_dump_button() -> void:
	if _utility_block == null:
		return
	if _data_dump_btn != null and is_instance_valid(_data_dump_btn):
		_connect_data_dump_button()
		return
	if _utility_block.has_node("DataDumpBtn"):
		var existing: Node = _utility_block.get_node("DataDumpBtn")
		if existing is Button:
			_data_dump_btn = existing as Button
			_connect_data_dump_button()
			return
	_data_dump_btn = Button.new()
	_data_dump_btn.name = "DataDumpBtn"
	_data_dump_btn.text = "Bug Report"
	_data_dump_btn.focus_mode = Control.FOCUS_CLICK
	_data_dump_btn.custom_minimum_size = Vector2(118, 0)
	_utility_block.add_child(_data_dump_btn)
	_connect_data_dump_button()


func _ensure_friendly_boss_debug_button() -> void:
	if _utility_block == null:
		return
	if _friendly_boss_debug_btn != null and is_instance_valid(_friendly_boss_debug_btn):
		return
	var existing: Node = _utility_block.get_node_or_null("FriendlyBossDebugBtn")
	if existing is Button:
		_friendly_boss_debug_btn = existing as Button
		return
	_friendly_boss_debug_btn = Button.new()
	_friendly_boss_debug_btn.name = "FriendlyBossDebugBtn"
	_friendly_boss_debug_btn.text = "BD"
	_friendly_boss_debug_btn.focus_mode = Control.FOCUS_CLICK
	_friendly_boss_debug_btn.custom_minimum_size = Vector2(118, 0)
	_utility_block.add_child(_friendly_boss_debug_btn)


func _ensure_troop_debug_button() -> void:
	if _utility_block == null:
		return
	if _troop_debug_btn != null and is_instance_valid(_troop_debug_btn):
		return
	var existing: Node = _utility_block.get_node_or_null("TroopDebugBtn")
	if existing is Button:
		_troop_debug_btn = existing as Button
		return
	_troop_debug_btn = Button.new()
	_troop_debug_btn.name = "TroopDebugBtn"
	_troop_debug_btn.text = "TD"
	_troop_debug_btn.focus_mode = Control.FOCUS_CLICK
	_troop_debug_btn.custom_minimum_size = Vector2(118, 0)
	_utility_block.add_child(_troop_debug_btn)
	if _data_dump_btn != null and is_instance_valid(_data_dump_btn):
		_utility_block.move_child(_troop_debug_btn, _data_dump_btn.get_index() + 1)



func _ensure_log_schema_button() -> void:
	if _utility_block == null:
		return
	if _log_schema_btn != null and is_instance_valid(_log_schema_btn):
		return
	var existing: Node = _utility_block.get_node_or_null("LogSchemaBtn")
	if existing is Button:
		_log_schema_btn = existing as Button
		return
	_log_schema_btn = Button.new()
	_log_schema_btn.name = "LogSchemaBtn"
	_log_schema_btn.text = "LS"
	_log_schema_btn.focus_mode = Control.FOCUS_CLICK
	_log_schema_btn.custom_minimum_size = Vector2(118, 0)
	_utility_block.add_child(_log_schema_btn)
	if _friendly_boss_debug_btn != null and is_instance_valid(_friendly_boss_debug_btn):
		_utility_block.move_child(_log_schema_btn, _friendly_boss_debug_btn.get_index() + 1)


func _connect_data_dump_button() -> void:
	if _data_dump_btn == null or not is_instance_valid(_data_dump_btn):
		return
	if not _data_dump_btn.pressed.is_connected(_on_data_dump_pressed):
		_data_dump_btn.pressed.connect(_on_data_dump_pressed)

func _ensure_bug_report_overlay() -> void:
	if _bug_report_backdrop != null and is_instance_valid(_bug_report_backdrop):
		return
	_bug_report_backdrop = ColorRect.new()
	_bug_report_backdrop.visible = false
	_bug_report_backdrop.color = Color(0.02, 0.01, 0.01, 0.68)
	_bug_report_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bug_report_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_bug_report_backdrop.z_as_relative = false
	_bug_report_backdrop.z_index = 1000
	$Root.add_child(_bug_report_backdrop)
	var panel := PanelContainer.new()
	panel.name = "BugReportPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = 0.12
	panel.anchor_top = 0.08
	panel.anchor_right = 0.88
	panel.anchor_bottom = 0.92
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bug_report_backdrop.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.custom_minimum_size = Vector2(0, 700)
	vb.add_theme_constant_override("separation", 8)
	scroll.add_child(vb)
	var title := Label.new()
	title.text = "Bug Report Wizard"
	vb.add_child(title)
	_bug_report_title_edit = LineEdit.new()
	_bug_report_title_edit.placeholder_text = "Short title"
	vb.add_child(_bug_report_title_edit)
	_bug_report_expected_edit = TextEdit.new()
	_bug_report_expected_edit.custom_minimum_size = Vector2(0, 64)
	_bug_report_expected_edit.placeholder_text = "Expected behavior"
	vb.add_child(_bug_report_expected_edit)
	_bug_report_actual_edit = TextEdit.new()
	_bug_report_actual_edit.custom_minimum_size = Vector2(0, 64)
	_bug_report_actual_edit.placeholder_text = "Actual behavior"
	vb.add_child(_bug_report_actual_edit)
	_bug_report_steps_edit = TextEdit.new()
	_bug_report_steps_edit.custom_minimum_size = Vector2(0, 96)
	_bug_report_steps_edit.placeholder_text = "Repro steps"
	vb.add_child(_bug_report_steps_edit)
	_bug_report_include_diagnostics_check = CheckBox.new()
	_bug_report_include_diagnostics_check.text = "Include diagnostics in payload"
	_bug_report_include_diagnostics_check.button_pressed = true
	vb.add_child(_bug_report_include_diagnostics_check)
	_bug_report_data_preview = TextEdit.new()
	_bug_report_data_preview.custom_minimum_size = Vector2(0, 128)
	_bug_report_data_preview.editable = false
	vb.add_child(_bug_report_data_preview)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(buttons)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func(): _bug_report_backdrop.visible = false)
	buttons.add_child(cancel_btn)
	var submit_btn := Button.new()
	submit_btn.text = "Submit + Copy"
	submit_btn.pressed.connect(_on_bug_report_submit_pressed)
	buttons.add_child(submit_btn)

func open_bug_report_wizard(data_dump_text: String) -> void:
	print("[BugReportFlow][UIOverlay] open_bug_report_wizard called; payload_len=%d." % data_dump_text.length())
	_ensure_bug_report_overlay()
	if _bug_report_backdrop == null:
		print("[BugReportFlow][UIOverlay] open_bug_report_wizard aborted: backdrop is null.")
		return
	_bug_report_data_preview.text = data_dump_text
	_bug_report_backdrop.visible = true
	_bug_report_backdrop.move_to_front()
	print("[BugReportFlow][UIOverlay] Bug Report wizard is now visible.")

func _on_bug_report_submit_pressed() -> void:
	var payload: Dictionary = {
		"title": _bug_report_title_edit.text.strip_edges() if _bug_report_title_edit != null else "",
		"expected": _bug_report_expected_edit.text.strip_edges() if _bug_report_expected_edit != null else "",
		"actual": _bug_report_actual_edit.text.strip_edges() if _bug_report_actual_edit != null else "",
		"steps": _bug_report_steps_edit.text.strip_edges() if _bug_report_steps_edit != null else "",
		"include_diagnostics": _bug_report_include_diagnostics_check.button_pressed if _bug_report_include_diagnostics_check != null else true,
		"data_dump": _bug_report_data_preview.text if _bug_report_data_preview != null else ""
	}
	DisplayServer.clipboard_set(JSON.stringify(payload, "\t"))
	emit_signal("bug_report_submitted", payload)
	_bug_report_backdrop.visible = false


func _on_data_dump_pressed() -> void:
	print("[BugReportFlow][UIOverlay] _on_data_dump_pressed invoked; emitting data_dump_requested.")
	emit_signal("data_dump_requested")



func _format_schema_value_for_humans(value: Variant, indent: int = 0) -> String:
	var indent_text: String = " ".repeat(indent)
	if value is Dictionary:
		var dict_value: Dictionary = value
		if dict_value.is_empty():
			return "{}"
		var keys: Array = dict_value.keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool:
			return String(a).naturalnocasecmp_to(String(b)) < 0
		)
		var lines: Array[String] = []
		for key_any in keys:
			var child: Variant = dict_value.get(key_any)
			var key_text: String = String(key_any)
			if child is Dictionary or child is Array:
				lines.append("%s%s:" % [indent_text, key_text])
				lines.append(_format_schema_value_for_humans(child, indent + 2))
			else:
				lines.append("%s%s: %s" % [indent_text, key_text, JSON.stringify(child)])
		return "\n".join(lines)
	if value is Array:
		var arr_value: Array = value
		if arr_value.is_empty():
			return "[]"
		var lines: Array[String] = []
		for item in arr_value:
			if item is Dictionary or item is Array:
				lines.append("%s-" % indent_text)
				lines.append(_format_schema_value_for_humans(item, indent + 2))
			else:
				lines.append("%s- %s" % [indent_text, JSON.stringify(item)])
		return "\n".join(lines)
	return "%s%s" % [indent_text, JSON.stringify(value)]


func _format_log_schema_snapshot_for_humans(snapshot: Dictionary) -> String:
	return _format_schema_value_for_humans(snapshot, 0)


func _on_log_schema_pressed() -> void:
	var live_payload: Dictionary = {}
	var root: Node = get_tree().current_scene
	if root != null and root.has_method("get_live_troop_log_schema_snapshot"):
		live_payload = root.call("get_live_troop_log_schema_snapshot")
	if live_payload.is_empty():
		show_state_message("Log schema snapshot unavailable.")
		return
	DisplayServer.clipboard_set(_format_log_schema_snapshot_for_humans(live_payload))
	show_state_message("Live log schema snapshot copied to clipboard (human-readable).")


func _format_campaign_upgrade_label(upgrade_type: String) -> String:
	match upgrade_type:
		"bigger":
			return "Bigger Ball"
		"heavier":
			return "Heavier Ball"
		"poison":
			return "Wind Resist"
		"forcefield":
			return "Forcefield"
		"magnet":
			return "Magnet"
		_:
			return upgrade_type.capitalize()


func _format_campaign_level_mode_label(level_mode: String) -> String:
	match LevelConfig.normalize_campaign_level_mode(level_mode):
		LevelConfig.CAMPAIGN_LEVEL_MODE_HARD:
			return "Hard"
		_:
			return "Easy"


func _ensure_campaign_upgrade_overlay() -> void:
	if _campaign_upgrade_backdrop != null:
		return

	_campaign_upgrade_backdrop = ColorRect.new()
	_campaign_upgrade_backdrop.name = "CampaignUpgradeBackdrop"
	_campaign_upgrade_backdrop.color = Color(0.01, 0.03, 0.06, 0.82)
	_campaign_upgrade_backdrop.visible = false
	_campaign_upgrade_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_campaign_upgrade_backdrop.z_index = 400
	_campaign_upgrade_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_campaign_upgrade_backdrop)
	_layout_campaign_upgrade_backdrop_against_bottom_bar()
	if not _campaign_upgrade_backdrop.gui_input.is_connected(_on_campaign_upgrade_backdrop_gui_input):
		_campaign_upgrade_backdrop.gui_input.connect(_on_campaign_upgrade_backdrop_gui_input)

	_campaign_upgrade_panel = PanelContainer.new()
	_campaign_upgrade_panel.name = "CampaignUpgradePanel"
	_campaign_upgrade_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_campaign_upgrade_panel.z_index = 401
	_campaign_upgrade_panel.anchor_left = 0.12
	_campaign_upgrade_panel.anchor_top = clampf(float(LevelConfig.CAMPAIGN_UPGRADE_MENU_TOP_ANCHOR), 0.0, 0.95)
	_campaign_upgrade_panel.anchor_right = 0.88
	_campaign_upgrade_panel.anchor_bottom = 1.0
	_campaign_upgrade_panel.offset_left = 0.0
	_campaign_upgrade_panel.offset_top = 0.0
	_campaign_upgrade_panel.offset_right = 0.0
	_campaign_upgrade_panel.offset_bottom = -maxf(0.0, float(LevelConfig.CAMPAIGN_UPGRADE_MENU_BOTTOM_PADDING_ABOVE_BAR))
	_campaign_upgrade_backdrop.add_child(_campaign_upgrade_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 20)
	panel_margin.add_theme_constant_override("margin_top", 20)
	panel_margin.add_theme_constant_override("margin_right", 20)
	panel_margin.add_theme_constant_override("margin_bottom", 20)
	_campaign_upgrade_panel.add_child(panel_margin)

	_campaign_upgrade_scroll = ScrollContainer.new()
	_campaign_upgrade_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campaign_upgrade_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_margin.add_child(_campaign_upgrade_scroll)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	layout.add_theme_constant_override("separation", 14)
	_campaign_upgrade_scroll.add_child(layout)

	_campaign_upgrade_title = Label.new()
	_campaign_upgrade_title.text = "Spend permanent upgrade points"
	_campaign_upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_campaign_upgrade_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_campaign_upgrade_title.add_theme_font_size_override("font_size", 22)
	layout.add_child(_campaign_upgrade_title)

	_campaign_upgrade_body = Label.new()
	_campaign_upgrade_body.text = ""
	_campaign_upgrade_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_campaign_upgrade_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_campaign_upgrade_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_campaign_upgrade_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campaign_upgrade_body.add_theme_font_size_override("font_size", 16)
	layout.add_child(_campaign_upgrade_body)

	_campaign_upgrade_buttons_row = VBoxContainer.new()
	_campaign_upgrade_buttons_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campaign_upgrade_buttons_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_campaign_upgrade_buttons_row.add_theme_constant_override("separation", 10)
	layout.add_child(_campaign_upgrade_buttons_row)
	_layout_campaign_upgrade_panel_against_bottom_bar()


func show_campaign_upgrade_choice(options: Array[String], title_text: String = "", body_text: String = "") -> void:
	_ensure_campaign_upgrade_overlay()
	if _campaign_upgrade_backdrop == null or _campaign_upgrade_buttons_row == null:
		return

	_hide_summary_overlay()

	if _campaign_upgrade_title != null:
		_campaign_upgrade_title.text = title_text if title_text.strip_edges() != "" else "Spend permanent upgrade points"
	if _campaign_upgrade_body != null:
		_campaign_upgrade_body.text = body_text

	for child in _campaign_upgrade_buttons_row.get_children():
		child.queue_free()
	_campaign_upgrade_buttons.clear()

	for option in options:
		var btn := Button.new()
		btn.text = "%s\nReduce cost by 1" % _format_campaign_upgrade_label(option)
		btn.focus_mode = Control.FOCUS_CLICK
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 72)
		btn.clip_text = true
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func() -> void:
			emit_signal("campaign_upgrade_selected", option)
		)
		_campaign_upgrade_buttons_row.add_child(btn)
		_campaign_upgrade_buttons.append(btn)

	_campaign_upgrade_backdrop.visible = true
	_layout_campaign_upgrade_backdrop_against_bottom_bar()
	_layout_campaign_upgrade_panel_against_bottom_bar()
	if _campaign_upgrade_scroll != null:
		_campaign_upgrade_scroll.scroll_vertical = 0


func hide_campaign_upgrade_choice() -> void:
	if _campaign_upgrade_backdrop != null:
		_campaign_upgrade_backdrop.visible = false
	if _campaign_upgrade_buttons_row != null:
		for child in _campaign_upgrade_buttons_row.get_children():
			child.queue_free()
	_campaign_upgrade_buttons.clear()


func _layout_campaign_upgrade_panel_against_bottom_bar() -> void:
	if _campaign_upgrade_panel == null:
		return
	_campaign_upgrade_panel.anchor_top = clampf(float(LevelConfig.CAMPAIGN_UPGRADE_MENU_TOP_ANCHOR), 0.0, 0.95)
	var bottom_padding: float = maxf(0.0, float(LevelConfig.CAMPAIGN_UPGRADE_MENU_BOTTOM_PADDING_ABOVE_BAR))
	_campaign_upgrade_panel.anchor_bottom = 1.0
	_campaign_upgrade_panel.offset_bottom = -bottom_padding


func _layout_campaign_upgrade_backdrop_against_bottom_bar() -> void:
	if _campaign_upgrade_backdrop == null:
		return
	_campaign_upgrade_backdrop.anchor_bottom = 1.0
	_campaign_upgrade_backdrop.offset_bottom = -maxf(0.0, get_bottom_bar_height())


func _on_campaign_upgrade_backdrop_gui_input(event: InputEvent) -> void:
	if _campaign_upgrade_backdrop == null or not _campaign_upgrade_backdrop.visible:
		return
	if _campaign_upgrade_scroll == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index != MOUSE_BUTTON_WHEEL_UP and mouse_event.button_index != MOUSE_BUTTON_WHEEL_DOWN:
		return

	var scroll_bar: VScrollBar = _campaign_upgrade_scroll.get_v_scroll_bar()
	if scroll_bar == null:
		return

	var step: float = maxf(36.0, scroll_bar.page * 0.25)
	var next_value: float = scroll_bar.value + (-step if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else step)
	scroll_bar.value = clampf(next_value, scroll_bar.min_value, scroll_bar.max_value)
	get_viewport().set_input_as_handled()


func _ensure_campaign_level_mode_overlay() -> void:
	if _campaign_level_mode_backdrop != null:
		return

	_campaign_level_mode_backdrop = ColorRect.new()
	_campaign_level_mode_backdrop.name = "CampaignLevelModeBackdrop"
	_campaign_level_mode_backdrop.color = Color(0.01, 0.03, 0.06, 0.86)
	_campaign_level_mode_backdrop.visible = false
	_campaign_level_mode_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_campaign_level_mode_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_campaign_level_mode_backdrop)

	_campaign_level_mode_panel = PanelContainer.new()
	_campaign_level_mode_panel.name = "CampaignLevelModePanel"
	_campaign_level_mode_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_campaign_level_mode_panel.anchor_left = 0.14
	_campaign_level_mode_panel.anchor_top = 0.08
	_campaign_level_mode_panel.anchor_right = 0.86
	_campaign_level_mode_panel.anchor_bottom = 0.42
	_campaign_level_mode_backdrop.add_child(_campaign_level_mode_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.08, 0.05, 0.98)
	panel_style.border_color = DASHBOARD_BANNER_BORDER
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.corner_radius_bottom_left = 24
	_campaign_level_mode_panel.add_theme_stylebox_override("panel", panel_style)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 22)
	panel_margin.add_theme_constant_override("margin_top", 22)
	panel_margin.add_theme_constant_override("margin_right", 22)
	panel_margin.add_theme_constant_override("margin_bottom", 22)
	_campaign_level_mode_panel.add_child(panel_margin)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	panel_margin.add_child(layout)

	_campaign_level_mode_title = Label.new()
	_campaign_level_mode_title.text = "Choose next level"
	_campaign_level_mode_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_campaign_level_mode_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_campaign_level_mode_title.add_theme_font_size_override("font_size", 24)
	_campaign_level_mode_title.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	layout.add_child(_campaign_level_mode_title)

	_campaign_level_mode_body = RichTextLabel.new()
	_campaign_level_mode_body.bbcode_enabled = false
	_campaign_level_mode_body.fit_content = true
	_campaign_level_mode_body.scroll_active = false
	_campaign_level_mode_body.selection_enabled = true
	_campaign_level_mode_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campaign_level_mode_body.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_campaign_level_mode_body.custom_minimum_size = Vector2(0.0, 0.0)
	_campaign_level_mode_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_campaign_level_mode_body.scroll_following = false
	_campaign_level_mode_body.focus_mode = Control.FOCUS_CLICK
	_campaign_level_mode_body.add_theme_font_size_override("normal_font_size", 16)
	_campaign_level_mode_body.add_theme_color_override("default_color", DASHBOARD_TEXT_SECONDARY)
	layout.add_child(_campaign_level_mode_body)

	_campaign_level_mode_buttons_row = HBoxContainer.new()
	_campaign_level_mode_buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_campaign_level_mode_buttons_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campaign_level_mode_buttons_row.add_theme_constant_override("separation", 14)
	layout.add_child(_campaign_level_mode_buttons_row)

	_campaign_level_mode_easy_btn = Button.new()
	_campaign_level_mode_easy_btn.name = "EasyModeBtn"
	_campaign_level_mode_easy_btn.text = "Easy\n1 boss • +1 step"
	_campaign_level_mode_easy_btn.clip_text = false
	_campaign_level_mode_easy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campaign_level_mode_easy_btn.custom_minimum_size = Vector2(0.0, 72.0)
	_campaign_level_mode_easy_btn.pressed.connect(func() -> void:
		emit_signal("campaign_level_mode_selected", LevelConfig.CAMPAIGN_LEVEL_MODE_EASY)
	)
	_campaign_level_mode_buttons_row.add_child(_campaign_level_mode_easy_btn)
	_apply_dashboard_button_style(_campaign_level_mode_easy_btn, false)
	_campaign_level_mode_easy_btn.add_theme_font_size_override("font_size", 16)

	_campaign_level_mode_hard_btn = Button.new()
	_campaign_level_mode_hard_btn.name = "HardModeBtn"
	_campaign_level_mode_hard_btn.text = "Hard\n2 bosses • +2 steps"
	_campaign_level_mode_hard_btn.clip_text = false
	_campaign_level_mode_hard_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campaign_level_mode_hard_btn.custom_minimum_size = Vector2(0.0, 72.0)
	_campaign_level_mode_hard_btn.pressed.connect(func() -> void:
		emit_signal("campaign_level_mode_selected", LevelConfig.CAMPAIGN_LEVEL_MODE_HARD)
	)
	_campaign_level_mode_buttons_row.add_child(_campaign_level_mode_hard_btn)
	_apply_dashboard_button_style(_campaign_level_mode_hard_btn, false)
	_campaign_level_mode_hard_btn.add_theme_font_size_override("font_size", 16)


func show_campaign_level_mode_choice(title_text: String = "", body_text: String = "", easy_button_text: String = "", hard_button_text: String = "") -> void:
	_ensure_campaign_level_mode_overlay()
	if _campaign_level_mode_backdrop == null:
		return

	_hide_summary_overlay()
	hide_campaign_upgrade_choice()

	if _campaign_level_mode_title != null:
		_campaign_level_mode_title.text = title_text if title_text.strip_edges() != "" else "Choose next level"

	var resolved_body: String = body_text.strip_edges()
	if resolved_body == "":
		resolved_body = "Pick Easy or Hard before the next level.\n\nEasy uses 1 boss and advances 1 campaign step.\nHard uses 2 bosses and advances 2 campaign steps.\nBoth increase enemy province troops based on campaign steps, and Hard grants double boss power progression."
	if _campaign_level_mode_body != null:
		_campaign_level_mode_body.clear()
		_campaign_level_mode_body.append_text(resolved_body)

	if _campaign_level_mode_easy_btn != null:
		_campaign_level_mode_easy_btn.text = easy_button_text if easy_button_text.strip_edges() != "" else "Easy\n1 boss • +1 step"
	if _campaign_level_mode_hard_btn != null:
		_campaign_level_mode_hard_btn.text = hard_button_text if hard_button_text.strip_edges() != "" else "Hard\n2 bosses • +2 steps"

	_campaign_level_mode_backdrop.visible = true
	if _campaign_level_mode_body != null:
		_campaign_level_mode_body.scroll_to_line(0)
	if _campaign_level_mode_easy_btn != null:
		_campaign_level_mode_easy_btn.grab_focus()


func hide_campaign_level_mode_choice() -> void:
	if _campaign_level_mode_backdrop != null:
		_campaign_level_mode_backdrop.visible = false
	if _campaign_level_mode_body != null:
		_campaign_level_mode_body.clear()


func is_campaign_level_mode_choice_visible() -> bool:
	return _campaign_level_mode_backdrop != null and _campaign_level_mode_backdrop.visible


func _ensure_pre_level_debug_overlay() -> void:
	if _pre_level_debug_backdrop != null:
		return

	_pre_level_debug_backdrop = ColorRect.new()
	_pre_level_debug_backdrop.name = "PreLevelDebugBackdrop"
	_pre_level_debug_backdrop.color = Color(0.01, 0.03, 0.06, 0.86)
	_pre_level_debug_backdrop.visible = false
	_pre_level_debug_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_pre_level_debug_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_pre_level_debug_backdrop)

	_pre_level_debug_panel = PanelContainer.new()
	_pre_level_debug_panel.name = "PreLevelDebugPanel"
	_pre_level_debug_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_pre_level_debug_panel.anchor_left = 0.20
	_pre_level_debug_panel.anchor_top = 0.10
	_pre_level_debug_panel.anchor_right = 0.80
	_pre_level_debug_panel.anchor_bottom = 0.56
	_pre_level_debug_backdrop.add_child(_pre_level_debug_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.08, 0.05, 0.98)
	panel_style.border_color = DASHBOARD_BANNER_BORDER
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.corner_radius_bottom_left = 24
	_pre_level_debug_panel.add_theme_stylebox_override("panel", panel_style)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 22)
	panel_margin.add_theme_constant_override("margin_top", 22)
	panel_margin.add_theme_constant_override("margin_right", 22)
	panel_margin.add_theme_constant_override("margin_bottom", 22)
	_pre_level_debug_panel.add_child(panel_margin)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	panel_margin.add_child(layout)

	var title := Label.new()
	title.text = "Pre-Level Debug Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	layout.add_child(title)

	var body := Label.new()
	body.text = "Adjust these runtime values before starting the level."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", DASHBOARD_TEXT_SECONDARY)
	layout.add_child(body)

	var settings_list := VBoxContainer.new()
	settings_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_list.add_theme_constant_override("separation", 10)
	layout.add_child(settings_list)

	var initial_friendly_row := HBoxContainer.new()
	initial_friendly_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	initial_friendly_row.add_theme_constant_override("separation", 12)
	settings_list.add_child(initial_friendly_row)
	var initial_friendly_label := Label.new()
	initial_friendly_label.text = "INITIAL_PROVINCE_FRIENDLY_TROOPS"
	initial_friendly_label.custom_minimum_size = Vector2(300.0, 0.0)
	initial_friendly_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	initial_friendly_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	initial_friendly_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	initial_friendly_label.clip_text = true
	initial_friendly_label.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	initial_friendly_row.add_child(initial_friendly_label)
	_pre_level_debug_initial_friendly_spin = SpinBox.new()
	_pre_level_debug_initial_friendly_spin.min_value = 1.0
	_pre_level_debug_initial_friendly_spin.max_value = 10000.0
	_pre_level_debug_initial_friendly_spin.step = 1.0
	_pre_level_debug_initial_friendly_spin.rounded = true
	_pre_level_debug_initial_friendly_spin.custom_minimum_size = Vector2(140.0, 0.0)
	initial_friendly_row.add_child(_pre_level_debug_initial_friendly_spin)

	var boss_head_row := HBoxContainer.new()
	boss_head_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_head_row.add_theme_constant_override("separation", 12)
	settings_list.add_child(boss_head_row)
	var boss_head_label := Label.new()
	boss_head_label.text = "BOSS_HEAD_HIT_POINTS"
	boss_head_label.custom_minimum_size = Vector2(300.0, 0.0)
	boss_head_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_head_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	boss_head_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	boss_head_label.clip_text = true
	boss_head_label.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	boss_head_row.add_child(boss_head_label)
	_pre_level_debug_boss_head_spin = SpinBox.new()
	_pre_level_debug_boss_head_spin.min_value = 1.0
	_pre_level_debug_boss_head_spin.max_value = 1000.0
	_pre_level_debug_boss_head_spin.step = 1.0
	_pre_level_debug_boss_head_spin.rounded = true
	_pre_level_debug_boss_head_spin.custom_minimum_size = Vector2(140.0, 0.0)
	boss_head_row.add_child(_pre_level_debug_boss_head_spin)

	var conquered_friendly_row := HBoxContainer.new()
	conquered_friendly_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conquered_friendly_row.add_theme_constant_override("separation", 12)
	settings_list.add_child(conquered_friendly_row)
	var conquered_friendly_label := Label.new()
	conquered_friendly_label.text = "CONQUERED_PROVINCE_FRIENDLY_TROOPS"
	conquered_friendly_label.custom_minimum_size = Vector2(300.0, 0.0)
	conquered_friendly_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conquered_friendly_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	conquered_friendly_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	conquered_friendly_label.clip_text = true
	conquered_friendly_label.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	conquered_friendly_row.add_child(conquered_friendly_label)
	_pre_level_debug_conquered_friendly_spin = SpinBox.new()
	_pre_level_debug_conquered_friendly_spin.min_value = 1.0
	_pre_level_debug_conquered_friendly_spin.max_value = 10000.0
	_pre_level_debug_conquered_friendly_spin.step = 1.0
	_pre_level_debug_conquered_friendly_spin.rounded = true
	_pre_level_debug_conquered_friendly_spin.custom_minimum_size = Vector2(140.0, 0.0)
	conquered_friendly_row.add_child(_pre_level_debug_conquered_friendly_spin)

	var campaign_enemy_increase_row := HBoxContainer.new()
	campaign_enemy_increase_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_enemy_increase_row.add_theme_constant_override("separation", 12)
	settings_list.add_child(campaign_enemy_increase_row)
	var campaign_enemy_increase_label := Label.new()
	campaign_enemy_increase_label.text = "CAMPAIGN_ENEMY_TROOP_INCREASE_PER_LEVEL"
	campaign_enemy_increase_label.custom_minimum_size = Vector2(300.0, 0.0)
	campaign_enemy_increase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_enemy_increase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	campaign_enemy_increase_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	campaign_enemy_increase_label.clip_text = true
	campaign_enemy_increase_label.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	campaign_enemy_increase_row.add_child(campaign_enemy_increase_label)
	_pre_level_debug_campaign_enemy_troop_increase_spin = SpinBox.new()
	_pre_level_debug_campaign_enemy_troop_increase_spin.min_value = 0.0
	_pre_level_debug_campaign_enemy_troop_increase_spin.max_value = 100.0
	_pre_level_debug_campaign_enemy_troop_increase_spin.step = 1.0
	_pre_level_debug_campaign_enemy_troop_increase_spin.rounded = true
	_pre_level_debug_campaign_enemy_troop_increase_spin.custom_minimum_size = Vector2(140.0, 0.0)
	campaign_enemy_increase_row.add_child(_pre_level_debug_campaign_enemy_troop_increase_spin)

	var friendly_march_bonus_row := HBoxContainer.new()
	friendly_march_bonus_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	friendly_march_bonus_row.add_theme_constant_override("separation", 12)
	settings_list.add_child(friendly_march_bonus_row)
	var friendly_march_bonus_label := Label.new()
	friendly_march_bonus_label.text = "BONUS_TROOPS_FRIENDLY_MARCH_CONQUEST"
	friendly_march_bonus_label.custom_minimum_size = Vector2(300.0, 0.0)
	friendly_march_bonus_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	friendly_march_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	friendly_march_bonus_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	friendly_march_bonus_label.clip_text = true
	friendly_march_bonus_label.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	friendly_march_bonus_row.add_child(friendly_march_bonus_label)
	_pre_level_debug_friendly_march_bonus_spin = SpinBox.new()
	_pre_level_debug_friendly_march_bonus_spin.min_value = 0.0
	_pre_level_debug_friendly_march_bonus_spin.max_value = 500.0
	_pre_level_debug_friendly_march_bonus_spin.step = 1.0
	_pre_level_debug_friendly_march_bonus_spin.rounded = true
	_pre_level_debug_friendly_march_bonus_spin.custom_minimum_size = Vector2(140.0, 0.0)
	friendly_march_bonus_row.add_child(_pre_level_debug_friendly_march_bonus_spin)

	var boss_show_up_turn_row := HBoxContainer.new()
	boss_show_up_turn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_show_up_turn_row.add_theme_constant_override("separation", 12)
	settings_list.add_child(boss_show_up_turn_row)
	var boss_show_up_turn_label := Label.new()
	boss_show_up_turn_label.text = "BOSS_SHOW_UP_ON_TURN"
	boss_show_up_turn_label.custom_minimum_size = Vector2(300.0, 0.0)
	boss_show_up_turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_show_up_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	boss_show_up_turn_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	boss_show_up_turn_label.clip_text = true
	boss_show_up_turn_label.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	boss_show_up_turn_row.add_child(boss_show_up_turn_label)
	_pre_level_debug_boss_show_up_turn_spin = SpinBox.new()
	_pre_level_debug_boss_show_up_turn_spin.min_value = 1.0
	_pre_level_debug_boss_show_up_turn_spin.max_value = 100.0
	_pre_level_debug_boss_show_up_turn_spin.step = 1.0
	_pre_level_debug_boss_show_up_turn_spin.rounded = true
	_pre_level_debug_boss_show_up_turn_spin.custom_minimum_size = Vector2(140.0, 0.0)
	boss_show_up_turn_row.add_child(_pre_level_debug_boss_show_up_turn_spin)

	var bonus_gold_row := HBoxContainer.new()
	bonus_gold_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bonus_gold_row.add_theme_constant_override("separation", 12)
	settings_list.add_child(bonus_gold_row)
	var bonus_gold_label := Label.new()
	bonus_gold_label.text = "BONUS_GOLD_PER_TURN"
	bonus_gold_label.custom_minimum_size = Vector2(300.0, 0.0)
	bonus_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bonus_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bonus_gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	bonus_gold_label.clip_text = true
	bonus_gold_label.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	bonus_gold_row.add_child(bonus_gold_label)
	_pre_level_debug_bonus_gold_spin = SpinBox.new()
	_pre_level_debug_bonus_gold_spin.min_value = 0.0
	_pre_level_debug_bonus_gold_spin.max_value = 1000.0
	_pre_level_debug_bonus_gold_spin.step = 1.0
	_pre_level_debug_bonus_gold_spin.rounded = true
	_pre_level_debug_bonus_gold_spin.custom_minimum_size = Vector2(140.0, 0.0)
	bonus_gold_row.add_child(_pre_level_debug_bonus_gold_spin)

	var next_level_row := HBoxContainer.new()
	next_level_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_level_row.add_theme_constant_override("separation", 12)
	settings_list.add_child(next_level_row)
	var next_level_label := Label.new()
	next_level_label.text = "PLAY_NEXT_LEVEL (1-10)"
	next_level_label.custom_minimum_size = Vector2(300.0, 0.0)
	next_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	next_level_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	next_level_label.clip_text = true
	next_level_label.add_theme_color_override("font_color", DASHBOARD_TEXT_PRIMARY)
	next_level_row.add_child(next_level_label)
	_pre_level_debug_next_level_spin = SpinBox.new()
	_pre_level_debug_next_level_spin.min_value = 1.0
	_pre_level_debug_next_level_spin.max_value = 10.0
	_pre_level_debug_next_level_spin.step = 1.0
	_pre_level_debug_next_level_spin.rounded = true
	_pre_level_debug_next_level_spin.custom_minimum_size = Vector2(140.0, 0.0)
	next_level_row.add_child(_pre_level_debug_next_level_spin)

	_pre_level_debug_confirm_btn = Button.new()
	_pre_level_debug_confirm_btn.text = "Apply & Start Level"
	_pre_level_debug_confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pre_level_debug_confirm_btn.custom_minimum_size = Vector2(0.0, 56.0)
	_pre_level_debug_confirm_btn.add_theme_font_size_override("font_size", 18)
	_pre_level_debug_confirm_btn.pressed.connect(func() -> void:
		var initial_friendly_troops: int = int(round(_pre_level_debug_initial_friendly_spin.value)) if _pre_level_debug_initial_friendly_spin != null else LevelConfig.get_runtime_initial_province_friendly_troops()
		var boss_head_hit_points: int = int(round(_pre_level_debug_boss_head_spin.value)) if _pre_level_debug_boss_head_spin != null else LevelConfig.get_runtime_boss_head_hit_points()
		var conquered_friendly_troops: int = int(round(_pre_level_debug_conquered_friendly_spin.value)) if _pre_level_debug_conquered_friendly_spin != null else LevelConfig.get_runtime_conquered_province_friendly_troops()
		var campaign_enemy_troop_increase_per_level: int = int(round(_pre_level_debug_campaign_enemy_troop_increase_spin.value)) if _pre_level_debug_campaign_enemy_troop_increase_spin != null else LevelConfig.get_runtime_campaign_enemy_troop_increase_per_level()
		var friendly_march_bonus_troops: int = int(round(_pre_level_debug_friendly_march_bonus_spin.value)) if _pre_level_debug_friendly_march_bonus_spin != null else LevelConfig.get_runtime_friendly_march_bonus_troops()
		var boss_show_up_on_turn: int = int(round(_pre_level_debug_boss_show_up_turn_spin.value)) if _pre_level_debug_boss_show_up_turn_spin != null else LevelConfig.get_runtime_boss_show_up_on_turn()
		var bonus_gold_per_turn: int = int(round(_pre_level_debug_bonus_gold_spin.value)) if _pre_level_debug_bonus_gold_spin != null else 0
		var next_level_override: int = int(round(_pre_level_debug_next_level_spin.value)) if _pre_level_debug_next_level_spin != null else 1
		emit_signal(
			"pre_level_debug_config_confirmed",
			maxi(1, initial_friendly_troops),
			maxi(1, boss_head_hit_points),
			maxi(1, conquered_friendly_troops),
			maxi(0, campaign_enemy_troop_increase_per_level),
			maxi(0, friendly_march_bonus_troops),
			maxi(1, boss_show_up_on_turn),
			maxi(0, bonus_gold_per_turn),
			clampi(next_level_override, 1, 10)
		)
	)
	layout.add_child(_pre_level_debug_confirm_btn)
	_apply_dashboard_button_style(_pre_level_debug_confirm_btn, false)


func show_pre_level_debug_config_choice(initial_friendly_troops: int, boss_head_hit_points: int, conquered_friendly_troops: int, campaign_enemy_troop_increase_per_level: int, friendly_march_bonus_troops: int = 0, boss_show_up_on_turn: int = 1, bonus_gold_per_turn: int = 0, next_level_override: int = 1) -> void:
	_ensure_pre_level_debug_overlay()
	if _pre_level_debug_backdrop == null:
		return

	_hide_summary_overlay()
	hide_campaign_level_mode_choice()
	hide_campaign_upgrade_choice()

	if _pre_level_debug_initial_friendly_spin != null:
		_pre_level_debug_initial_friendly_spin.value = maxi(1, initial_friendly_troops)
	if _pre_level_debug_boss_head_spin != null:
		_pre_level_debug_boss_head_spin.value = maxi(1, boss_head_hit_points)
	if _pre_level_debug_conquered_friendly_spin != null:
		_pre_level_debug_conquered_friendly_spin.value = maxi(1, conquered_friendly_troops)
	if _pre_level_debug_campaign_enemy_troop_increase_spin != null:
		_pre_level_debug_campaign_enemy_troop_increase_spin.value = maxi(0, campaign_enemy_troop_increase_per_level)
	if _pre_level_debug_friendly_march_bonus_spin != null:
		_pre_level_debug_friendly_march_bonus_spin.value = maxi(0, friendly_march_bonus_troops)
	if _pre_level_debug_boss_show_up_turn_spin != null:
		_pre_level_debug_boss_show_up_turn_spin.value = maxi(1, boss_show_up_on_turn)
	if _pre_level_debug_bonus_gold_spin != null:
		_pre_level_debug_bonus_gold_spin.value = maxi(0, bonus_gold_per_turn)
	if _pre_level_debug_next_level_spin != null:
		_pre_level_debug_next_level_spin.value = clampi(next_level_override, 1, 10)

	_pre_level_debug_backdrop.visible = true
	if _pre_level_debug_confirm_btn != null:
		_pre_level_debug_confirm_btn.grab_focus()


func hide_pre_level_debug_config_choice() -> void:
	if _pre_level_debug_backdrop != null:
		_pre_level_debug_backdrop.visible = false


func is_pre_level_debug_config_choice_visible() -> bool:
	return _pre_level_debug_backdrop != null and _pre_level_debug_backdrop.visible


func get_bottom_bar_height() -> float:
	if _bottom_bar:
		return _bottom_bar.get_global_rect().size.y
	return 0.0

func is_pointer_over_scrollable_banner(screen_pos: Vector2) -> bool:
	if _scrollable_state_message == null or not _scrollable_state_message.visible:
		return false
	if _message_banner_shell != null and _message_banner_shell.visible:
		return _message_banner_shell.get_global_rect().has_point(screen_pos)
	return _scrollable_state_message.get_global_rect().has_point(screen_pos)


func is_pointer_over_modal_overlay(screen_pos: Vector2) -> bool:
	for overlay in [_campaign_upgrade_backdrop, _campaign_level_mode_backdrop, _pre_level_debug_backdrop, _summary_overlay_backdrop, _tutorial_backdrop, _field_guide_backdrop]:
		if overlay != null and overlay.visible and overlay.get_global_rect().has_point(screen_pos):
			return true
	return false


func is_modal_overlay_visible() -> bool:
	for overlay in [_campaign_upgrade_backdrop, _campaign_level_mode_backdrop, _pre_level_debug_backdrop, _summary_overlay_backdrop, _tutorial_backdrop, _field_guide_backdrop]:
		if overlay != null and overlay.visible:
			return true
	return false

func set_level_text(text: String) -> void:
	if _lbl_level:
		if _lbl_level.text == text:
			return
		_lbl_level.text = text
		_notify_bottom_bar_resized_deferred()

func set_gold(amount: int) -> void:
	var changed: bool = _cached_gold != amount
	_cached_gold = amount
	if _lbl_gold_value:
		var amount_text: String = str(amount)
		if _lbl_gold_value.text != amount_text:
			_lbl_gold_value.text = amount_text
		if changed:
			_bounce_gold_label()
			trigger_gold_sparkles()
	_refresh_shop_buttons()

func set_pins_counts(total_pins: int, downed_pins: int) -> void:
	_cached_total_pins = max(0, total_pins)
	_cached_downed_pins = clampi(downed_pins, 0, _cached_total_pins)
	_update_pins_summary()

func set_status(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		clear_state_message()
		return
	if _is_relevant_state_message(trimmed):
		show_state_message(trimmed)
	else:
		clear_state_message()

func show_state_message(text: String) -> void:
	if not _state_message or not _pins_summary:
		return

	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		clear_state_message()
		return

	var is_live_counter := _looks_like_live_counter(trimmed)
	var is_automated_skip_report: bool = _is_automated_skip_report(trimmed)
	var is_summary := _looks_like_summary(trimmed)
	var inline_text: String = trimmed
	var use_scrollable_banner: bool = _should_use_scrollable_banner_message(trimmed, is_summary, is_automated_skip_report)

	if is_summary:
		_last_reopenable_summary_text = trimmed
	_hide_summary_overlay()

	_state_message.scale = Vector2.ONE
	_state_message.modulate = Color.WHITE
	_pins_summary.visible = false

	if use_scrollable_banner:
		_show_scrollable_state_message(inline_text, 15)
		_state_message.visible = false
	else:
		_hide_scrollable_state_message()
		_state_message.text = inline_text
		_state_message.visible = true
		if is_live_counter:
			_state_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_state_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_state_message.add_theme_font_size_override("font_size", 16)
		elif is_summary or is_automated_skip_report:
			_state_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_state_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_state_message.add_theme_font_size_override("font_size", 15)
		else:
			_state_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_state_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_state_message.add_theme_font_size_override("font_size", 18)

	_refresh_reopen_summary_button(trimmed, is_summary, is_live_counter)
	_notify_bottom_bar_resized_deferred()

	if not use_scrollable_banner and not is_summary and _should_pop_message(trimmed):
		var tween := create_tween()
		tween.tween_property(_state_message, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_BACK)
		tween.tween_property(_state_message, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC)

func set_reopenable_summary_text(text: String) -> void:
	_last_reopenable_summary_text = text.strip_edges()
	_refresh_reopen_summary_button(_state_message.text if _state_message != null else "", false, false)

func clear_state_message() -> void:
	_hide_summary_overlay()
	_hide_scrollable_state_message()
	_refresh_reopen_summary_button("", false, false)
	if _state_message and _pins_summary:
		_state_message.visible = false
		_state_message.text = ""
		_state_message.scale = Vector2.ONE
		_state_message.modulate = Color.WHITE
		_state_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_state_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_state_message.add_theme_font_size_override("font_size", 16)
		_pins_summary.visible = _cached_total_pins > 0
		_notify_bottom_bar_resized_deferred()

func show_shop(visible: bool) -> void:
	if _shop_block:
		if _shop_block.visible == visible:
			return
		_shop_block.visible = visible
		_notify_bottom_bar_resized_deferred()

func refresh_upgrades(bigger: int, heavier: int, poison: int, current_gold: int) -> void:
	_bigger_count = bigger
	_heavier_count = heavier
	_poison_count = poison
	_cached_gold = current_gold
	if _lbl_gold_value:
		_lbl_gold_value.text = str(current_gold)
	_refresh_shop_buttons()


func set_upgrade_cost_overrides(cost_map: Dictionary) -> void:
	_upgrade_cost_overrides = cost_map.duplicate(true)
	_refresh_shop_buttons()


func set_forcefield_upgrade_count(forcefield: int, current_gold: int = -1) -> void:
	_forcefield_count = forcefield
	if current_gold >= 0:
		_cached_gold = current_gold
		if _lbl_gold_value:
			_lbl_gold_value.text = str(current_gold)
	_refresh_shop_buttons()


func set_magnet_upgrade_count(magnet: int, current_gold: int = -1) -> void:
	_magnet_count = magnet
	if current_gold >= 0:
		_cached_gold = current_gold
		if _lbl_gold_value:
			_lbl_gold_value.text = str(current_gold)
	_refresh_shop_buttons()

func set_place_magnet_button(show: bool, remaining: int, armed: bool) -> void:
	if _place_magnet_btn == null:
		return

	remaining = maxi(0, remaining)
	var next_visible: bool = show and remaining > 0
	if _place_magnet_btn.visible != next_visible:
		_place_magnet_btn.visible = next_visible
		_notify_bottom_bar_resized_deferred()

	if not next_visible:
		return

	_place_magnet_btn.disabled = false
	if armed:
		_place_magnet_btn.text = "Tap Map\nMagnet (%d left)" % remaining
	else:
		_place_magnet_btn.text = "Place Magnet\n%d left" % remaining
	var text_col := LevelConfig.BUTTON_TEXT_ENABLED
	_place_magnet_btn.add_theme_color_override("font_color", text_col)
	_place_magnet_btn.add_theme_color_override("font_color_hover", text_col.lightened(0.15))
	_place_magnet_btn.add_theme_color_override("font_color_pressed", text_col.darkened(0.1))
	_place_magnet_btn.add_theme_color_override("font_color_disabled", text_col)
	if armed:
		_place_magnet_btn.modulate = Color(0.86, 1.08, 1.18, 1.0)
	else:
		_place_magnet_btn.modulate = Color.WHITE

func set_permanent_counts(_bigger: int, _heavier: int, _poison: int) -> void:
	# Legacy no-op kept for compatibility while the permanent-upgrade path is removed.
	_refresh_shop_buttons()

func set_seed_display(new_seed: int) -> void:
	if _seed_label:
		var next_text: String = str(new_seed)
		if _seed_label.text == next_text:
			return
		_seed_label.text = next_text

func show_extra_ball_button(show: bool) -> void:
	if _extra_ball_btn:
		if _extra_ball_btn.visible == show:
			return
		_extra_ball_btn.visible = show
		_notify_bottom_bar_resized_deferred()

func set_skip_to_end_visible(show: bool) -> void:
	if _skip_to_end_btn == null:
		return
	if _skip_to_end_btn.visible != show:
		_skip_to_end_btn.visible = show
		_notify_bottom_bar_resized_deferred()
	if show:
		_skip_to_end_btn.disabled = false
		_skip_to_end_btn.text = "Skip to End"
	_refresh_right_panel_primary_controls()
	_rebuild_right_panel_utility_cluster()

func show_skip_to_end_button(show: bool) -> void:
	set_skip_to_end_visible(show)

func set_skip_to_end_running(running: bool) -> void:
	if _skip_to_end_btn == null:
		return
	if running and not _skip_to_end_btn.visible:
		_skip_to_end_btn.visible = true
		_notify_bottom_bar_resized_deferred()
	_skip_to_end_btn.disabled = false
	_skip_to_end_btn.text = "Stop Skipping" if running else "Skip to End"
	_refresh_right_panel_primary_controls()
	_rebuild_right_panel_utility_cluster()

func set_end_engagement_visible(show: bool) -> void:
	if _end_engagement_btn == null:
		return
	if _end_engagement_btn.visible != show:
		_end_engagement_btn.visible = show
		_notify_bottom_bar_resized_deferred()
	_end_engagement_btn.disabled = false
	_refresh_right_panel_primary_controls()
	_rebuild_right_panel_utility_cluster()

func set_opening_gameplay_tutorial_skip_button(show: bool, label_text: String = "Skip Tutorial") -> void:
	if _opening_gameplay_tutorial_skip_btn == null:
		return
	_opening_gameplay_tutorial_skip_active = show
	_opening_gameplay_tutorial_skip_label = label_text.strip_edges() if label_text.strip_edges() != "" else "Skip Tutorial"
	if _opening_gameplay_tutorial_skip_btn.visible != show:
		_opening_gameplay_tutorial_skip_btn.visible = show
		_notify_bottom_bar_resized_deferred()
	_opening_gameplay_tutorial_skip_btn.disabled = false
	_opening_gameplay_tutorial_skip_btn.text = _opening_gameplay_tutorial_skip_label
	_refresh_right_panel_primary_controls()
	_rebuild_right_panel_utility_cluster()

func set_restart_only_mode(enabled: bool) -> void:
	if _shop_block:
		_shop_block.visible = not enabled

	if _pause_btn:
		_pause_btn.visible = false
		_pause_btn.disabled = true

	if _retry_btn:
		_retry_btn.visible = not enabled
		_retry_btn.disabled = enabled

	if _cancel_btn:
		_cancel_btn.visible = false
		_cancel_btn.disabled = enabled

	if _seed_block:
		_seed_block.visible = not enabled

	if _copy_btn:
		_copy_btn.disabled = enabled
	if _load_btn:
		_load_btn.disabled = enabled
	if _seed_edit:
		_seed_edit.editable = not enabled
		_seed_edit.editable = not enabled

	if _extra_ball_btn:
		_extra_ball_btn.visible = false if enabled else _extra_ball_btn.visible
		_extra_ball_btn.disabled = enabled

	if _place_magnet_btn:
		_place_magnet_btn.visible = false if enabled else _place_magnet_btn.visible
		_place_magnet_btn.disabled = enabled

	if _skip_to_end_btn:
		_skip_to_end_btn.visible = false if enabled else _skip_to_end_btn.visible
		_skip_to_end_btn.disabled = enabled
		if not enabled and _skip_to_end_btn.text == "Stop Skipping":
			_skip_to_end_btn.text = "Skip to End"

	if _opening_gameplay_tutorial_skip_btn:
		_opening_gameplay_tutorial_skip_btn.visible = false if enabled else (_opening_gameplay_tutorial_skip_active and _opening_gameplay_tutorial_skip_btn.visible)
		_opening_gameplay_tutorial_skip_btn.disabled = enabled
		if not enabled and _opening_gameplay_tutorial_skip_active:
			_opening_gameplay_tutorial_skip_btn.visible = true
			_opening_gameplay_tutorial_skip_btn.text = _opening_gameplay_tutorial_skip_label

	if _restart_btn:
		_restart_btn.visible = true
		_restart_btn.disabled = false

	if _help_btn:
		_help_btn.visible = true
		_help_btn.disabled = false
	if _data_dump_btn:
		_data_dump_btn.visible = true
		_data_dump_btn.disabled = false

	_refresh_right_panel_primary_controls()
	_rebuild_right_panel_utility_cluster()
	_notify_bottom_bar_resized_deferred()

func set_pause_button_paused(paused: bool) -> void:
	if not _pause_btn:
		return
	_pause_btn.text = "Resume" if paused else "Pause"
	_refresh_right_panel_primary_controls()

func show_cancel_button(show: bool) -> void:
	if _cancel_btn:
		var changed: bool = _cancel_btn.visible != show
		_cancel_btn.visible = show
		if changed:
			_notify_bottom_bar_resized_deferred()
		_rebuild_right_panel_utility_cluster()


func set_tutorial_guide(guide: RefCounted) -> void:
	_tutorial_guide = guide
	refresh_field_guide_badge()
	if _field_guide_backdrop != null and _field_guide_backdrop.visible:
		_refresh_field_guide_sections()
		_rebuild_field_guide_lists(_field_guide_current_category, _field_guide_current_note_key)


func refresh_field_guide_badge() -> void:
	_ensure_help_button()
	if _help_badge == null:
		return
	if not LevelConfig.is_tutorial_and_field_guide_enabled():
		_help_badge.visible = false
		return
	var unread_count: int = 0
	if _tutorial_guide != null and _tutorial_guide.has_method("get_unread_unlocked_note_count"):
		unread_count = int(_tutorial_guide.call("get_unread_unlocked_note_count"))
	if unread_count <= 0:
		_help_badge.visible = false
		return
	var cap: int = LevelConfig.get_field_guide_unread_badge_cap()
	_help_badge.visible = true
	_help_badge.text = ("%d+" % cap) if unread_count > cap else str(unread_count)


func show_first_run_tutorial() -> void:
	if not LevelConfig.should_auto_start_first_run_tutorial():
		return
	if _tutorial_guide == null or not _tutorial_guide.has_method("get_first_run_sequence"):
		return
	if _tutorial_guide.has_method("should_auto_start_first_run") and not bool(_tutorial_guide.call("should_auto_start_first_run")):
		return
	var sequence: Array = _tutorial_guide.call("get_first_run_sequence")
	show_tutorial_sequence(_typed_dictionary_array(sequence))


func show_tutorial_sequence(sequence: Array[Dictionary]) -> void:
	if not LevelConfig.is_tutorial_and_field_guide_enabled():
		return
	_tutorial_sequence = sequence.duplicate(true)
	_tutorial_index = -1
	if _tutorial_sequence.is_empty():
		return
	_ensure_tutorial_overlay()
	_show_tutorial_step(0)


func show_cutscene(cutscene_definition: Dictionary) -> void:
	_ensure_cutscene_overlay()
	_cutscene_active_id = String(cutscene_definition.get("id", ""))
	_cutscene_lines.clear()
	var raw_lines: Array = cutscene_definition.get("dialogue", [])
	for line_any in raw_lines:
		var line: String = String(line_any).strip_edges()
		if line != "":
			_cutscene_lines.append(line)
	if _cutscene_lines.is_empty():
		_cutscene_lines.append("...")
	_cutscene_line_index = 0
	_cutscene_dialogue_label.text = _cutscene_lines[0]

	var bg_path: String = String(cutscene_definition.get("background", "res://assets/boss/boss_head_face.jpg"))
	var player_path: String = String(cutscene_definition.get("player_sprite", "res://assets/ui/icons/icon_seed.png"))
	var other_path: String = String(cutscene_definition.get("other_sprite", "res://assets/ui/icons/icon_gold.png"))
	_cutscene_background.texture = load(bg_path) as Texture2D
	_cutscene_player_sprite.texture = load(player_path) as Texture2D
	_cutscene_other_sprite.texture = load(other_path) as Texture2D

	_cutscene_player_sprite.rotation_degrees = 180.0
	_cutscene_other_sprite.rotation_degrees = 0.0
	_cutscene_backdrop.visible = true
	_cutscene_dialogue_panel.visible = false

	var player_final: Vector2 = Vector2(0.42, 0.76)
	var other_final: Vector2 = Vector2(0.58, 0.24)
	_cutscene_player_sprite.anchor_left = player_final.x
	_cutscene_player_sprite.anchor_right = player_final.x
	_cutscene_other_sprite.anchor_left = other_final.x
	_cutscene_other_sprite.anchor_right = other_final.x

	_cutscene_player_sprite.anchor_top = player_final.y + 0.12
	_cutscene_player_sprite.anchor_bottom = player_final.y + 0.12
	_cutscene_other_sprite.anchor_top = other_final.y - 0.10
	_cutscene_other_sprite.anchor_bottom = other_final.y - 0.10
	_cutscene_player_sprite.scale = Vector2(0.88, 0.88)
	_cutscene_other_sprite.scale = Vector2(0.90, 0.90)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_cutscene_player_sprite, "anchor_top", player_final.y, 2.0)
	tween.tween_property(_cutscene_player_sprite, "anchor_bottom", player_final.y, 2.0)
	tween.tween_property(_cutscene_other_sprite, "anchor_top", other_final.y, 2.0)
	tween.tween_property(_cutscene_other_sprite, "anchor_bottom", other_final.y, 2.0)
	tween.tween_property(_cutscene_player_sprite, "scale", Vector2.ONE, 2.0)
	tween.tween_property(_cutscene_other_sprite, "scale", Vector2.ONE, 2.0)
	await tween.finished
	_cutscene_dialogue_panel.visible = true


func _advance_or_finish_cutscene() -> void:
	if _cutscene_backdrop == null or not _cutscene_backdrop.visible:
		return
	_cutscene_line_index += 1
	if _cutscene_line_index >= _cutscene_lines.size():
		var finished_id: String = _cutscene_active_id
		_cutscene_backdrop.visible = false
		_cutscene_active_id = ""
		emit_signal("cutscene_finished", finished_id)
		return
	_cutscene_dialogue_label.text = _cutscene_lines[_cutscene_line_index]


func is_tutorial_visible() -> bool:
	return _tutorial_backdrop != null and _tutorial_backdrop.visible


func is_field_guide_open() -> bool:
	return _field_guide_backdrop != null and _field_guide_backdrop.visible


func advance_tutorial_step() -> void:
	if _tutorial_sequence.is_empty():
		_finish_tutorial_sequence()
		return
	_show_tutorial_step(_tutorial_index + 1)


func queue_unlocked_notes(note_entries: Array[Dictionary]) -> void:
	if not LevelConfig.should_show_field_guide_unlock_toasts():
		return
	for entry in note_entries:
		if entry.is_empty():
			continue
		if _field_guide_toast_queue.size() >= LevelConfig.get_field_guide_popup_queue_limit():
			break
		_field_guide_toast_queue.append(entry.duplicate(true))
	if not _field_guide_toast_showing:
		_show_next_field_guide_toast()


func open_field_guide(preferred_category: String = "", preferred_note_key: String = "") -> void:
	if not LevelConfig.is_tutorial_and_field_guide_enabled():
		return
	_ensure_field_guide_overlay()
	_layout_field_guide_panel_against_bottom_bar()
	_refresh_field_guide_sections()
	_rebuild_field_guide_lists(preferred_category, preferred_note_key)
	if _field_guide_backdrop != null:
		_field_guide_backdrop.visible = true
	_apply_field_guide_pause(true)
	emit_signal("field_guide_opened")


func close_field_guide() -> void:
	if _field_guide_backdrop != null:
		_field_guide_backdrop.visible = false
	_apply_field_guide_pause(false)
	emit_signal("field_guide_closed")


func _ensure_tutorial_overlay() -> void:
	if _tutorial_backdrop != null:
		return

	_tutorial_backdrop = ColorRect.new()
	_tutorial_backdrop.name = "TutorialBackdrop"
	_tutorial_backdrop.visible = false
	_tutorial_backdrop.color = Color(0.02, 0.03, 0.06, LevelConfig.get_tutorial_coach_card_dim_alpha())
	_tutorial_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_backdrop.gui_input.connect(_on_tutorial_backdrop_gui_input)
	add_child(_tutorial_backdrop)

	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.name = "TutorialPanel"
	_tutorial_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_tutorial_panel.custom_minimum_size = Vector2(420, 228)
	_tutorial_backdrop.add_child(_tutorial_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	_tutorial_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	_tutorial_step_label = Label.new()
	_tutorial_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_tutorial_step_label.add_theme_font_size_override("font_size", 13)
	layout.add_child(_tutorial_step_label)

	_tutorial_title = Label.new()
	_tutorial_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_title.add_theme_font_size_override("font_size", 22)
	layout.add_child(_tutorial_title)

	_tutorial_body = Label.new()
	_tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tutorial_body.add_theme_font_size_override("font_size", 16)
	layout.add_child(_tutorial_body)

	_tutorial_target_hint = Label.new()
	_tutorial_target_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_target_hint.add_theme_font_size_override("font_size", 13)
	layout.add_child(_tutorial_target_hint)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 10)
	layout.add_child(buttons)

	_tutorial_prev_btn = Button.new()
	_tutorial_prev_btn.text = "Back"
	_tutorial_prev_btn.custom_minimum_size = Vector2(88, 40)
	_tutorial_prev_btn.pressed.connect(func() -> void:
		_show_tutorial_step(_tutorial_index - 1)
	)
	buttons.add_child(_tutorial_prev_btn)

	_tutorial_next_btn = Button.new()
	_tutorial_next_btn.text = "Next"
	_tutorial_next_btn.custom_minimum_size = Vector2(108, 40)
	_tutorial_next_btn.pressed.connect(advance_tutorial_step)
	buttons.add_child(_tutorial_next_btn)

	_tutorial_close_btn = Button.new()
	_tutorial_close_btn.text = "Close"
	_tutorial_close_btn.custom_minimum_size = Vector2(88, 40)
	_tutorial_close_btn.pressed.connect(_finish_tutorial_sequence)
	buttons.add_child(_tutorial_close_btn)


func _ensure_cutscene_overlay() -> void:
	if _cutscene_backdrop != null:
		return
	_cutscene_backdrop = ColorRect.new()
	_cutscene_backdrop.name = "CutsceneBackdrop"
	_cutscene_backdrop.visible = false
	_cutscene_backdrop.color = Color(0.0, 0.0, 0.0, 0.94)
	_cutscene_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_cutscene_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cutscene_backdrop)

	_cutscene_background = TextureRect.new()
	_cutscene_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cutscene_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cutscene_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_cutscene_backdrop.add_child(_cutscene_background)

	_cutscene_other_sprite = TextureRect.new()
	_cutscene_other_sprite.custom_minimum_size = Vector2(240, 240)
	_cutscene_other_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cutscene_other_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cutscene_other_sprite.offset_left = -120.0
	_cutscene_other_sprite.offset_top = -120.0
	_cutscene_other_sprite.offset_right = 120.0
	_cutscene_other_sprite.offset_bottom = 120.0
	_cutscene_backdrop.add_child(_cutscene_other_sprite)

	_cutscene_player_sprite = TextureRect.new()
	_cutscene_player_sprite.custom_minimum_size = Vector2(240, 240)
	_cutscene_player_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cutscene_player_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cutscene_player_sprite.offset_left = -120.0
	_cutscene_player_sprite.offset_top = -120.0
	_cutscene_player_sprite.offset_right = 120.0
	_cutscene_player_sprite.offset_bottom = 120.0
	_cutscene_backdrop.add_child(_cutscene_player_sprite)

	_cutscene_dialogue_panel = PanelContainer.new()
	_cutscene_dialogue_panel.anchor_left = 0.08
	_cutscene_dialogue_panel.anchor_top = 0.77
	_cutscene_dialogue_panel.anchor_right = 0.92
	_cutscene_dialogue_panel.anchor_bottom = 0.96
	_cutscene_backdrop.add_child(_cutscene_dialogue_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	_cutscene_dialogue_panel.add_child(margin)

	_cutscene_dialogue_label = Label.new()
	_cutscene_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cutscene_dialogue_label.add_theme_font_size_override("font_size", 26)
	margin.add_child(_cutscene_dialogue_label)

	var next_btn: Button = Button.new()
	next_btn.text = "Next"
	next_btn.anchor_left = 0.90
	next_btn.anchor_top = 0.97
	next_btn.anchor_right = 0.98
	next_btn.anchor_bottom = 1.0
	next_btn.pressed.connect(_advance_or_finish_cutscene)
	_cutscene_backdrop.add_child(next_btn)


func _ensure_field_guide_overlay() -> void:
	if _field_guide_backdrop != null:
		return

	_field_guide_backdrop = ColorRect.new()
	_field_guide_backdrop.name = "FieldGuideBackdrop"
	_field_guide_backdrop.visible = false
	_field_guide_backdrop.color = Color(0.01, 0.02, 0.04, 0.84)
	_field_guide_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_field_guide_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_field_guide_backdrop)

	_field_guide_panel = PanelContainer.new()
	_field_guide_panel.name = "FieldGuidePanel"
	_field_guide_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_field_guide_panel.anchor_left = 0.04
	_field_guide_panel.anchor_top = 0.05
	_field_guide_panel.anchor_right = 0.96
	_field_guide_panel.anchor_bottom = 1.0
	_field_guide_panel.offset_bottom = -maxf(0.0, get_bottom_bar_height())
	_field_guide_backdrop.add_child(_field_guide_panel)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 18)
	outer_margin.add_theme_constant_override("margin_top", 16)
	outer_margin.add_theme_constant_override("margin_right", 18)
	outer_margin.add_theme_constant_override("margin_bottom", 16)
	_field_guide_panel.add_child(outer_margin)

	var outer_layout := VBoxContainer.new()
	outer_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_layout.add_theme_constant_override("separation", 12)
	outer_margin.add_child(outer_layout)

	var header_row := HBoxContainer.new()
	outer_layout.add_child(header_row)

	var header_title := Label.new()
	header_title.text = "Field Guide"
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_title.add_theme_font_size_override("font_size", 24)
	header_row.add_child(header_title)

	_field_guide_replay_btn = Button.new()
	_field_guide_replay_btn.text = "Replay Tutorial"
	_field_guide_replay_btn.visible = LevelConfig.can_replay_tutorial_from_help_menu()
	_field_guide_replay_btn.custom_minimum_size = Vector2(142, 42)
	_field_guide_replay_btn.pressed.connect(_on_replay_tutorial_pressed)
	header_row.add_child(_field_guide_replay_btn)

	_field_guide_close_btn = Button.new()
	_field_guide_close_btn.text = "Close"
	_field_guide_close_btn.custom_minimum_size = Vector2(96, 42)
	_field_guide_close_btn.pressed.connect(close_field_guide)
	header_row.add_child(_field_guide_close_btn)

	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	outer_layout.add_child(columns)

	var category_panel := PanelContainer.new()
	category_panel.custom_minimum_size = Vector2(170, 0)
	category_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(category_panel)

	var category_margin := MarginContainer.new()
	category_margin.add_theme_constant_override("margin_left", 8)
	category_margin.add_theme_constant_override("margin_top", 8)
	category_margin.add_theme_constant_override("margin_right", 8)
	category_margin.add_theme_constant_override("margin_bottom", 8)
	category_panel.add_child(category_margin)

	var category_layout := VBoxContainer.new()
	category_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	category_layout.add_theme_constant_override("separation", 8)
	category_margin.add_child(category_layout)

	var category_label := Label.new()
	category_label.text = "Sections"
	category_layout.add_child(category_label)

	_field_guide_category_list = ItemList.new()
	_field_guide_category_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_guide_category_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field_guide_category_list.select_mode = ItemList.SELECT_SINGLE
	_field_guide_category_list.item_selected.connect(_on_field_guide_category_selected)
	category_layout.add_child(_field_guide_category_list)

	var note_panel := PanelContainer.new()
	note_panel.custom_minimum_size = Vector2(240, 0)
	note_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(note_panel)

	var note_margin := MarginContainer.new()
	note_margin.add_theme_constant_override("margin_left", 8)
	note_margin.add_theme_constant_override("margin_top", 8)
	note_margin.add_theme_constant_override("margin_right", 8)
	note_margin.add_theme_constant_override("margin_bottom", 8)
	note_panel.add_child(note_margin)

	var note_layout := VBoxContainer.new()
	note_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	note_layout.add_theme_constant_override("separation", 8)
	note_margin.add_child(note_layout)

	var note_label := Label.new()
	note_label.text = "Notes"
	note_layout.add_child(note_label)

	_field_guide_note_list = ItemList.new()
	_field_guide_note_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_guide_note_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field_guide_note_list.select_mode = ItemList.SELECT_SINGLE
	_field_guide_note_list.item_selected.connect(_on_field_guide_note_selected)
	note_layout.add_child(_field_guide_note_list)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 14)
	detail_margin.add_theme_constant_override("margin_top", 12)
	detail_margin.add_theme_constant_override("margin_right", 14)
	detail_margin.add_theme_constant_override("margin_bottom", 12)
	detail_panel.add_child(detail_margin)

	var detail_layout := VBoxContainer.new()
	detail_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_layout.add_theme_constant_override("separation", 8)
	detail_margin.add_child(detail_layout)

	_field_guide_title = Label.new()
	_field_guide_title.text = "Select a note"
	_field_guide_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_field_guide_title.add_theme_font_size_override("font_size", 22)
	detail_layout.add_child(_field_guide_title)

	_field_guide_body = RichTextLabel.new()
	_field_guide_body.bbcode_enabled = false
	_field_guide_body.scroll_active = true
	_field_guide_body.selection_enabled = true
	_field_guide_body.fit_content = false
	_field_guide_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_guide_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field_guide_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_field_guide_body.add_theme_font_size_override("normal_font_size", 16)
	detail_layout.add_child(_field_guide_body)

	_field_guide_empty_label = Label.new()
	_field_guide_empty_label.visible = false
	_field_guide_empty_label.text = "No notes are unlocked yet. Keep playing and new mechanics will add entries here."
	_field_guide_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_field_guide_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field_guide_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_field_guide_empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_guide_empty_label.add_theme_font_size_override("font_size", 15)
	detail_layout.add_child(_field_guide_empty_label)


func _layout_field_guide_panel_against_bottom_bar() -> void:
	if _field_guide_panel == null:
		return
	_field_guide_panel.anchor_bottom = 1.0
	_field_guide_panel.offset_bottom = -maxf(0.0, get_bottom_bar_height())


func _ensure_field_guide_toast() -> void:
	if _field_guide_toast_panel != null:
		return

	_field_guide_toast_panel = PanelContainer.new()
	_field_guide_toast_panel.name = "FieldGuideToast"
	_field_guide_toast_panel.visible = false
	_field_guide_toast_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_field_guide_toast_panel.anchor_left = 0.66
	_field_guide_toast_panel.anchor_top = 0.05
	_field_guide_toast_panel.anchor_right = 0.97
	_field_guide_toast_panel.anchor_bottom = 0.22
	add_child(_field_guide_toast_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_field_guide_toast_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)

	_field_guide_toast_title = Label.new()
	_field_guide_toast_title.add_theme_font_size_override("font_size", 18)
	_field_guide_toast_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_field_guide_toast_title)

	_field_guide_toast_body = Label.new()
	_field_guide_toast_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_field_guide_toast_body.add_theme_font_size_override("font_size", 14)
	layout.add_child(_field_guide_toast_body)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 8)
	layout.add_child(buttons)

	_field_guide_toast_open_btn = Button.new()
	_field_guide_toast_open_btn.text = "Open"
	_field_guide_toast_open_btn.custom_minimum_size = Vector2(88, 36)
	_field_guide_toast_open_btn.pressed.connect(_on_field_guide_toast_open_pressed)
	buttons.add_child(_field_guide_toast_open_btn)

	var dismiss_btn := Button.new()
	dismiss_btn.text = "Dismiss"
	dismiss_btn.custom_minimum_size = Vector2(88, 36)
	dismiss_btn.pressed.connect(_hide_current_field_guide_toast)
	buttons.add_child(dismiss_btn)


func _on_tutorial_backdrop_gui_input(event: InputEvent) -> void:
	if not is_tutorial_visible():
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if _tutorial_panel == null or not _tutorial_panel.get_global_rect().has_point(mouse_event.global_position):
				_finish_tutorial_sequence()
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			if _tutorial_panel == null or not _tutorial_panel.get_global_rect().has_point(touch_event.position):
				_finish_tutorial_sequence()
				get_viewport().set_input_as_handled()


func _show_tutorial_step(index: int) -> void:
	if _tutorial_sequence.is_empty():
		_finish_tutorial_sequence()
		return
	if index < 0:
		index = 0
	if index >= _tutorial_sequence.size():
		_finish_tutorial_sequence()
		return

	_tutorial_index = index
	_ensure_tutorial_overlay()
	var entry: Dictionary = _tutorial_sequence[_tutorial_index]
	var note_key: String = String(entry.get("key", ""))
	if _tutorial_guide != null and note_key != "":
		if _tutorial_guide.has_method("mark_note_read"):
			_tutorial_guide.call("mark_note_read", note_key)
		refresh_field_guide_badge()

	if _tutorial_step_label != null:
		var step_index: int = int(entry.get("step_index", _tutorial_index + 1))
		var step_count: int = int(entry.get("step_count", _tutorial_sequence.size()))
		_tutorial_step_label.text = "Tutorial %d / %d" % [step_index, step_count]
	if _tutorial_title != null:
		_tutorial_title.text = String(entry.get("title", "Tutorial"))
	if _tutorial_body != null:
		_tutorial_body.text = String(entry.get("body", ""))
	if _tutorial_target_hint != null:
		var target_id: String = String(entry.get("target_id", ""))
		_tutorial_target_hint.text = _describe_tutorial_target(target_id)
	if _tutorial_prev_btn != null:
		_tutorial_prev_btn.disabled = _tutorial_index <= 0
	if _tutorial_next_btn != null:
		_tutorial_next_btn.text = "Done" if _tutorial_index >= _tutorial_sequence.size() - 1 else "Next"

	_position_tutorial_panel(String(entry.get("target_id", "")))
	if _tutorial_backdrop != null:
		_tutorial_backdrop.visible = true

	emit_signal(
		"tutorial_step_changed",
		note_key,
		int(entry.get("step_index", _tutorial_index + 1)),
		int(entry.get("step_count", _tutorial_sequence.size()))
	)


func _finish_tutorial_sequence() -> void:
	if _tutorial_backdrop != null:
		_tutorial_backdrop.visible = false
	if _tutorial_guide != null and _tutorial_guide.has_method("mark_first_run_complete"):
		_tutorial_guide.call("mark_first_run_complete")
	refresh_field_guide_badge()
	emit_signal("tutorial_finished")


func _position_tutorial_panel(target_id: String) -> void:
	if _tutorial_panel == null:
		return
	var viewport: Viewport = get_viewport()
	var viewport_size: Vector2 = viewport.get_visible_rect().size if viewport != null else Vector2(1280.0, 720.0)
	var panel_size: Vector2 = Vector2(minf(460.0, maxf(320.0, viewport_size.x - 32.0)), 232.0)
	_tutorial_panel.size = panel_size

	var target: Control = _get_tutorial_target_control(target_id)
	if target == null or not target.visible:
		_tutorial_panel.position = Vector2(
			(viewport_size.x - panel_size.x) * 0.5,
			clampf(viewport_size.y * 0.12, 16.0, maxf(16.0, viewport_size.y - panel_size.y - 16.0))
		)
		return

	var rect: Rect2 = target.get_global_rect()
	var x: float = clampf(rect.position.x + rect.size.x * 0.5 - panel_size.x * 0.5, 16.0, maxf(16.0, viewport_size.x - panel_size.x - 16.0))
	var place_above: bool = rect.position.y > panel_size.y + 30.0
	var y: float = rect.position.y - panel_size.y - 14.0 if place_above else rect.position.y + rect.size.y + 14.0
	y = clampf(y, 16.0, maxf(16.0, viewport_size.y - panel_size.y - 16.0))
	_tutorial_panel.position = Vector2(x, y)


func _get_tutorial_target_control(target_id: String) -> Control:
	match target_id:
		"pause_button":
			return _pause_btn
		"stats_slot":
			if _state_message != null and _state_message.visible:
				return _state_message
			return _pins_summary
		"shop_block":
			return _shop_block
		"place_magnet_button":
			return _place_magnet_btn
		"campaign_upgrade_panel":
			return _campaign_upgrade_panel
		"campaign_level_mode_panel":
			return _campaign_level_mode_panel
		"header":
			return _lbl_level
		_:
			return null


func _describe_tutorial_target(target_id: String) -> String:
	match target_id:
		"pause_button":
			return "Look near the pause and help controls in the bottom bar."
		"stats_slot":
			return "Watch the live target summary in the center of the bottom bar."
		"shop_block":
			return "The shop buttons on the right side of the bottom bar affect your next shot."
		"place_magnet_button":
			return "After buying Magnet, the Place Magnet button appears in the utility controls."
		"campaign_upgrade_panel":
			return "Permanent campaign rewards appear in a full-screen choice panel."
		"campaign_level_mode_panel":
			return "Before the next level, choose Easy or Hard from the full-screen campaign panel."
		"header":
			return "The header row shows your current level and gold."
		"world_launch_province":
			return "Look for the glowing friendly province on the map. That is your legal launch area."
		"world_drag":
			return "This step refers to the launch gesture in the playfield itself."
		"world_map":
			return "This note is about the board and hazards in the playfield."
		"boss_body":
			return "This note refers to the boss actor in the playfield."
		_:
			return ""


func _refresh_field_guide_sections() -> void:
	_field_guide_sections.clear()
	if _tutorial_guide != null and _tutorial_guide.has_method("get_field_guide_sections"):
		var sections: Array = _tutorial_guide.call("get_field_guide_sections")
		_field_guide_sections = _typed_dictionary_array(sections)


func _rebuild_field_guide_lists(preferred_category: String = "", preferred_note_key: String = "") -> void:
	if _field_guide_category_list == null or _field_guide_note_list == null:
		return

	_field_guide_category_list.clear()
	_field_guide_note_list.clear()

	if _field_guide_sections.is_empty():
		_field_guide_current_category = ""
		_field_guide_current_note_key = ""
		if _field_guide_title != null:
			_field_guide_title.text = "Field Guide"
		if _field_guide_body != null:
			_field_guide_body.clear()
		if _field_guide_empty_label != null:
			_field_guide_empty_label.visible = true
		return

	if _field_guide_empty_label != null:
		_field_guide_empty_label.visible = false

	for i in range(_field_guide_sections.size()):
		var section: Dictionary = _field_guide_sections[i]
		var category_name: String = String(section.get("category", ""))
		var entries: Array = section.get("entries", [])
		var unread_in_section: int = 0
		for raw_entry in entries:
			var entry: Dictionary = raw_entry
			if not bool(entry.get("is_read", false)):
				unread_in_section += 1
		var label: String = category_name
		if unread_in_section > 0:
			label += " (%d)" % unread_in_section
		_field_guide_category_list.add_item(label)
		_field_guide_category_list.set_item_metadata(i, category_name)

	var chosen_category: String = preferred_category
	if chosen_category.strip_edges() == "" and preferred_note_key != "":
		for section in _field_guide_sections:
			for entry in section.get("entries", []):
				if String((entry as Dictionary).get("key", "")) == preferred_note_key:
					chosen_category = String((section as Dictionary).get("category", ""))
					break
			if chosen_category.strip_edges() != "":
				break
	if chosen_category.strip_edges() == "":
		chosen_category = _field_guide_current_category
	if chosen_category.strip_edges() == "":
		chosen_category = String(_field_guide_sections[0].get("category", ""))

	for i in range(_field_guide_sections.size()):
		if String(_field_guide_sections[i].get("category", "")) == chosen_category:
			_field_guide_category_list.select(i)
			_build_field_guide_note_list(chosen_category, preferred_note_key)
			return

	_field_guide_category_list.select(0)
	_build_field_guide_note_list(String(_field_guide_sections[0].get("category", "")), preferred_note_key)


func _build_field_guide_note_list(category_name: String, preferred_note_key: String = "") -> void:
	_field_guide_current_category = category_name
	_field_guide_note_list.clear()

	var chosen_entries: Array = []
	for section in _field_guide_sections:
		if String(section.get("category", "")) == category_name:
			chosen_entries = section.get("entries", [])
			break

	if chosen_entries.is_empty():
		_field_guide_current_note_key = ""
		if _field_guide_title != null:
			_field_guide_title.text = category_name
		if _field_guide_body != null:
			_field_guide_body.clear()
		if _field_guide_empty_label != null:
			_field_guide_empty_label.visible = true
		return

	if _field_guide_empty_label != null:
		_field_guide_empty_label.visible = false

	var selected_index: int = 0
	for i in range(chosen_entries.size()):
		var entry: Dictionary = chosen_entries[i]
		var note_key: String = String(entry.get("key", ""))
		var title: String = String(entry.get("title", note_key))
		if not bool(entry.get("is_read", false)):
			title = "• " + title
		_field_guide_note_list.add_item(title)
		_field_guide_note_list.set_item_metadata(i, note_key)
		if preferred_note_key != "" and note_key == preferred_note_key:
			selected_index = i

	_field_guide_note_list.select(selected_index)
	var selected_key: Variant = _field_guide_note_list.get_item_metadata(selected_index)
	_show_field_guide_note(String(selected_key))


func _show_field_guide_note(note_key: String) -> void:
	_field_guide_current_note_key = note_key
	var note: Dictionary = {}
	if _tutorial_guide != null and _tutorial_guide.has_method("get_note"):
		note = _tutorial_guide.call("get_note", note_key)
	if note.is_empty():
		if _field_guide_title != null:
			_field_guide_title.text = "Select a note"
		if _field_guide_body != null:
			_field_guide_body.clear()
		return

	if _tutorial_guide != null and _tutorial_guide.has_method("mark_note_read"):
		_tutorial_guide.call("mark_note_read", note_key)
	refresh_field_guide_badge()
	_refresh_field_guide_sections()

	var title: String = String(note.get("title", note_key))
	var category_name: String = String(note.get("category", ""))
	var body: String = String(note.get("body", ""))
	var short_body: String = String(note.get("short_body", ""))

	if _field_guide_title != null:
		_field_guide_title.text = title
	if _field_guide_body != null:
		_field_guide_body.clear()
		var text: String = ""
		if category_name != "":
			text += "Section: %s\n\n" % category_name
		if short_body != "":
			text += short_body + "\n\n"
		text += body
		_field_guide_body.append_text(text)
		_field_guide_body.scroll_to_line(0)

	emit_signal("field_guide_note_selected", note_key)


func _show_next_field_guide_toast() -> void:
	if _field_guide_toast_showing:
		return
	if _field_guide_toast_queue.is_empty():
		return
	_ensure_field_guide_toast()

	var entry: Dictionary = _field_guide_toast_queue.pop_front()
	_field_guide_toast_note_key = String(entry.get("key", ""))
	if _field_guide_toast_title != null:
		_field_guide_toast_title.text = "New Note: %s" % String(entry.get("title", "Field Guide"))
	if _field_guide_toast_body != null:
		var body: String = String(entry.get("short_body", ""))
		if body == "" or not LevelConfig.should_show_field_guide_unlock_short_body():
			body = "A new Field Guide entry is available."
		_field_guide_toast_body.text = body

	_field_guide_toast_showing = true
	_field_guide_toast_serial += 1
	var serial: int = _field_guide_toast_serial
	if _field_guide_toast_panel != null:
		_field_guide_toast_panel.visible = true

	await get_tree().create_timer(LevelConfig.get_tutorial_note_toast_seconds()).timeout
	if serial != _field_guide_toast_serial:
		return
	_hide_current_field_guide_toast()


func _hide_current_field_guide_toast() -> void:
	if not _field_guide_toast_showing:
		return
	_field_guide_toast_showing = false
	_field_guide_toast_serial += 1
	_field_guide_toast_note_key = ""
	if _field_guide_toast_panel != null:
		_field_guide_toast_panel.visible = false
	if not _field_guide_toast_queue.is_empty():
		call_deferred("_show_next_field_guide_toast")


func _apply_field_guide_pause(open: bool) -> void:
	if not LevelConfig.should_pause_game_when_field_guide_is_open():
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if open:
		if not tree.paused:
			_field_guide_forced_pause = true
			tree.paused = true
		else:
			_field_guide_forced_pause = false
	else:
		if _field_guide_forced_pause and tree.paused:
			tree.paused = false
		_field_guide_forced_pause = false


func _typed_dictionary_array(raw_entries: Array) -> Array[Dictionary]:
	var typed: Array[Dictionary] = []
	for entry in raw_entries:
		if entry is Dictionary:
			typed.append((entry as Dictionary).duplicate(true))
	return typed


func _on_help_pressed() -> void:
	if is_field_guide_open():
		close_field_guide()
	else:
		open_field_guide(LevelConfig.get_field_guide_default_open_category(), "")


func _on_replay_tutorial_pressed() -> void:
	close_field_guide()
	emit_signal("replay_tutorial_requested")
	if _tutorial_guide != null and _tutorial_guide.has_method("get_first_run_sequence"):
		var sequence: Array = _tutorial_guide.call("get_first_run_sequence")
		show_tutorial_sequence(_typed_dictionary_array(sequence))


func _on_field_guide_category_selected(index: int) -> void:
	if _field_guide_category_list == null:
		return
	var category_name: Variant = _field_guide_category_list.get_item_metadata(index)
	_build_field_guide_note_list(String(category_name), "")


func _on_field_guide_note_selected(index: int) -> void:
	if _field_guide_note_list == null:
		return
	var note_key: Variant = _field_guide_note_list.get_item_metadata(index)
	_show_field_guide_note(String(note_key))
	_rebuild_field_guide_lists(_field_guide_current_category, String(note_key))


func _on_field_guide_toast_open_pressed() -> void:
	var note_key: String = _field_guide_toast_note_key
	_hide_current_field_guide_toast()
	open_field_guide("", note_key)


func _ensure_reopen_summary_button() -> void:
	if _reopen_summary_btn != null or _utility_block == null:
		return

	_reopen_summary_btn = Button.new()
	_reopen_summary_btn.name = "ReopenSummaryBtn"
	_reopen_summary_btn.text = "Summary"
	_reopen_summary_btn.visible = false
	_reopen_summary_btn.focus_mode = Control.FOCUS_CLICK
	_reopen_summary_btn.custom_minimum_size = Vector2(104, 0)
	_reopen_summary_btn.pressed.connect(_on_reopen_summary_pressed)
	_utility_block.add_child(_reopen_summary_btn)
	_apply_dashboard_button_style(_reopen_summary_btn, false)
	_refresh_right_panel_primary_controls()
	_rebuild_right_panel_utility_cluster()

func _refresh_reopen_summary_button(current_text: String, is_summary: bool, is_live_counter: bool) -> void:
	if _reopen_summary_btn == null:
		return

	var should_show: bool = false
	if not _last_reopenable_summary_text.is_empty() and not is_live_counter:
		if is_summary:
			should_show = true
		elif _is_summary_reopen_context(current_text):
			should_show = true

	if _reopen_summary_btn.visible != should_show:
		_reopen_summary_btn.visible = should_show
		_notify_bottom_bar_resized_deferred()
	_refresh_right_panel_primary_controls()
	_rebuild_right_panel_utility_cluster()

func _on_reopen_summary_pressed() -> void:
	if _last_reopenable_summary_text.is_empty():
		return
	_show_summary_overlay(_last_reopenable_summary_text)

func _is_summary_reopen_context(text: String) -> bool:
	var lowered: String = text.to_lower()
	if lowered.is_empty():
		return false
	return (
		"automated engagements since your last shot" in lowered
		or "your next shot starts" in lowered
		or "highlighted province" in lowered
		or "this turn's shot must start" in lowered
		or "province fortified" in lowered
		or lowered.begins_with("turn ")
	)

func trigger_gold_sparkles() -> void:
	if _gold_sparkles:
		_gold_sparkles.amount = 22
		_gold_sparkles.emitting = true
		_bounce_gold_label()

func _bounce_gold_label() -> void:
	if _lbl_gold_value:
		var tween := create_tween()
		tween.tween_property(_lbl_gold_value, "scale", Vector2(1.48, 1.48), 0.11).set_trans(Tween.TRANS_BACK)
		tween.tween_property(_lbl_gold_value, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC)

func trigger_win_burst() -> void:
	if _win_burst:
		_win_burst.amount = LevelConfig.JUICY_WIN_CONFETTI_COUNT
		_win_burst.emitting = true

		var tween := create_tween()
		tween.tween_property(_bottom_bar, "scale", Vector2(1.12, 1.12), 0.08).set_trans(Tween.TRANS_BACK)
		tween.tween_property(_bottom_bar, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_ELASTIC)

func trigger_upgrade_burst() -> void:
	for btn in [_bigger_btn, _heavier_btn, _poison_btn, _forcefield_btn, _magnet_btn]:
		if btn:
			var tween := create_tween()
			tween.tween_property(btn, "modulate", Color(1.6, 1.6, 0.7, 1.0), 0.09)
			tween.tween_property(btn, "modulate", Color.WHITE, 0.28)

	if _win_burst:
		_win_burst.amount = 28
		_win_burst.emitting = true
		await get_tree().create_timer(0.35).timeout
		_win_burst.amount = LevelConfig.JUICY_WIN_CONFETTI_COUNT

func _refresh_shop_buttons() -> void:
	_apply_dashboard_icons()
	_update_button(_bigger_btn, "Bigger Ball", _bigger_count, _get_upgrade_display_cost("bigger", int(LevelConfig.UPGRADE_COST_BIGGER_BALL)))
	_update_button(_heavier_btn, "Heavier Ball", _heavier_count, _get_upgrade_display_cost("heavier", int(LevelConfig.UPGRADE_COST_HEAVIER_BALL)))
	_update_button(_poison_btn, "Wind Resist", _poison_count, _get_upgrade_display_cost("poison", int(LevelConfig.UPGRADE_COST_POISON)))
	_update_button(_forcefield_btn, "Forcefield", _forcefield_count, _get_upgrade_display_cost("forcefield", int(LevelConfig.UPGRADE_COST_FORCEFIELD)))
	_update_button(_magnet_btn, "Magnet", _magnet_count, _get_upgrade_display_cost("magnet", int(LevelConfig.UPGRADE_COST_MAGNET)))


func _get_upgrade_display_cost(upgrade_type: String, fallback_cost: int) -> int:
	if _upgrade_cost_overrides.has(upgrade_type):
		return maxi(0, int(_upgrade_cost_overrides.get(upgrade_type, fallback_cost)))
	return maxi(0, fallback_cost)


func _stop_button_pulse(btn: Button) -> void:
	if btn == null:
		return
	var key: String = str(btn.get_instance_id())
	if _shop_pulse_tweens.has(key):
		var tween: Variant = _shop_pulse_tweens[key]
		if tween != null:
			tween.kill()
		_shop_pulse_tweens.erase(key)

func set_low_motion_mode(enabled: bool) -> void:
	if _low_motion_mode == enabled:
		return
	_low_motion_mode = enabled
	if enabled:
		var keys: Array = _shop_pulse_tweens.keys()
		for key_any in keys:
			var key: String = str(key_any)
			var tween: Variant = _shop_pulse_tweens.get(key, null)
			if tween != null:
				tween.kill()
		_shop_pulse_tweens.clear()
		for btn in [_bigger_btn, _heavier_btn, _poison_btn, _forcefield_btn, _magnet_btn]:
			if btn != null:
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_refresh_shop_buttons()

func _start_button_pulse(btn: Button) -> void:
	if btn == null:
		return
	if _low_motion_mode:
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		return
	_stop_button_pulse(btn)
	btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(btn, "modulate", Color(1.22, 1.18, 1.0, 1.0), 0.75).set_trans(Tween.TRANS_SINE)
	tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.75).set_trans(Tween.TRANS_SINE)
	_shop_pulse_tweens[str(btn.get_instance_id())] = tween

func _update_button(btn: Button, name: String, level: int, cost: int) -> void:
	if not btn:
		return

	var cost_value: int = maxi(0, cost)
	var can_afford: bool = _cached_gold >= cost_value
	btn.disabled = not can_afford
	btn.text = ""
	btn.set_meta("upgrade_display_name", name)
	_refresh_upgrade_card_content(btn, name, level, cost_value, can_afford)

	var text_col := LevelConfig.BUTTON_TEXT_ENABLED if can_afford else LevelConfig.BUTTON_TEXT_DISABLED
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_color_hover", text_col.lightened(0.15))
	btn.add_theme_color_override("font_color_pressed", text_col.darkened(0.1))
	btn.add_theme_color_override("font_color_disabled", text_col)

	if can_afford:
		_start_button_pulse(btn)
	else:
		_stop_button_pulse(btn)
		btn.modulate = Color(0.85, 0.85, 0.85, 1.0)

func _update_pins_summary() -> void:
	if not _pins_summary:
		return
	if _cached_total_pins == 0:
		_pins_summary.visible = false
		return

	var pct := 0
	if _cached_total_pins > 0:
		pct = int(round((float(_cached_downed_pins) / float(_cached_total_pins)) * 100.0))
	_pins_summary.text = "Targets: %d • Downed: %d (%d%%)" % [_cached_total_pins, _cached_downed_pins, pct]
	_pins_summary.visible = not (_state_message and _state_message.visible)

func _ensure_summary_overlay() -> void:
	if _summary_overlay_backdrop != null:
		return

	_summary_overlay_backdrop = ColorRect.new()
	_summary_overlay_backdrop.name = "SummaryOverlayBackdrop"
	_summary_overlay_backdrop.color = Color(0.02, 0.02, 0.05, 0.74)
	_summary_overlay_backdrop.visible = false
	_summary_overlay_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_summary_overlay_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_summary_overlay_backdrop)

	_summary_overlay_panel = PanelContainer.new()
	_summary_overlay_panel.name = "SummaryOverlayPanel"
	_summary_overlay_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_summary_overlay_panel.anchor_left = 0.06
	_summary_overlay_panel.anchor_top = 0.05
	_summary_overlay_panel.anchor_right = 0.94
	_summary_overlay_panel.anchor_bottom = 0.74
	_summary_overlay_panel.offset_left = 0.0
	_summary_overlay_panel.offset_top = 0.0
	_summary_overlay_panel.offset_right = 0.0
	_summary_overlay_panel.offset_bottom = 0.0
	_summary_overlay_backdrop.add_child(_summary_overlay_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 18)
	panel_margin.add_theme_constant_override("margin_top", 18)
	panel_margin.add_theme_constant_override("margin_right", 18)
	panel_margin.add_theme_constant_override("margin_bottom", 14)
	_summary_overlay_panel.add_child(panel_margin)

	var panel_layout := VBoxContainer.new()
	panel_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_layout.add_theme_constant_override("separation", 10)
	panel_margin.add_child(panel_layout)

	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_layout.add_child(header_row)

	_summary_overlay_title = Label.new()
	_summary_overlay_title.text = "Report"
	_summary_overlay_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_summary_overlay_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_summary_overlay_title.add_theme_font_size_override("font_size", 20)
	header_row.add_child(_summary_overlay_title)

	_summary_overlay_close_btn = Button.new()
	_summary_overlay_close_btn.text = "Close"
	_summary_overlay_close_btn.custom_minimum_size = Vector2(96, 40)
	_summary_overlay_close_btn.pressed.connect(_hide_summary_overlay)
	header_row.add_child(_summary_overlay_close_btn)

	_summary_overlay_body = RichTextLabel.new()
	_summary_overlay_body.bbcode_enabled = false
	_summary_overlay_body.fit_content = false
	_summary_overlay_body.scroll_active = true
	_summary_overlay_body.selection_enabled = true
	_summary_overlay_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary_overlay_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary_overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_overlay_body.scroll_following = false
	_summary_overlay_body.focus_mode = Control.FOCUS_CLICK
	_summary_overlay_body.add_theme_font_size_override("normal_font_size", 16)
	panel_layout.add_child(_summary_overlay_body)

	_summary_overlay_hint = Label.new()
	_summary_overlay_hint.text = "Scroll to read the full report. You can reopen it from the Summary button until your next shot."
	_summary_overlay_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_overlay_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_overlay_hint.add_theme_font_size_override("font_size", 14)
	panel_layout.add_child(_summary_overlay_hint)

func _show_summary_overlay(full_text: String) -> void:
	_ensure_summary_overlay()
	if _summary_overlay_backdrop == null or _summary_overlay_body == null:
		return

	if _summary_overlay_title != null:
		_summary_overlay_title.text = _build_summary_overlay_title(full_text)

	_summary_overlay_body.clear()
	_summary_overlay_body.append_text(full_text)
	_summary_overlay_backdrop.visible = true
	call_deferred("_reset_summary_overlay_scroll")

func _hide_summary_overlay() -> void:
	if _summary_overlay_backdrop:
		_summary_overlay_backdrop.visible = false
	if _summary_overlay_body:
		_summary_overlay_body.clear()

func _reset_summary_overlay_scroll() -> void:
	if _summary_overlay_body:
		_summary_overlay_body.scroll_to_line(0)

func _should_use_summary_overlay(text: String) -> bool:
	var lines: PackedStringArray = text.split("
", false)
	return lines.size() >= SUMMARY_OVERLAY_MIN_LINES or text.length() >= SUMMARY_OVERLAY_MIN_CHARS

func _build_inline_summary_preview(text: String) -> String:
	var source_lines: PackedStringArray = text.split("
", false)
	var preview_lines: Array[String] = []
	var char_count: int = 0

	for line in source_lines:
		if preview_lines.size() >= SUMMARY_PREVIEW_MAX_LINES:
			break
		var line_text: String = String(line)
		if char_count > 0 and char_count + line_text.length() + 1 > SUMMARY_PREVIEW_MAX_CHARS:
			break
		preview_lines.append(line_text)
		char_count += line_text.length() + 1

	var preview: String = "
".join(preview_lines)
	if preview.strip_edges().is_empty():
		preview = text.substr(0, mini(text.length(), SUMMARY_PREVIEW_MAX_CHARS))

	var truncated: bool = preview != text
	if truncated:
		preview = preview.rstrip("
") + "
…"

	preview += "
(Use the Summary button to reopen the full report before your next shot.)"
	return preview

func _build_summary_overlay_title(text: String) -> String:
	var lowered: String = text.to_lower()
	if "automated engagements since your last shot" in lowered:
		return "Automated Engagement Report"
	if "tap or click to continue" in lowered or "engagement" in lowered:
		return "Engagement Summary"
	return "Report"

func _on_bottom_bar_resized() -> void:
	_apply_dashboard_responsive_layout_metrics()
	_layout_campaign_upgrade_backdrop_against_bottom_bar()
	_layout_campaign_upgrade_panel_against_bottom_bar()
	_layout_field_guide_panel_against_bottom_bar()
	var height: float = get_bottom_bar_height()
	if absf(height - _last_bottom_bar_height_emitted) > 0.5:
		_last_bottom_bar_height_emitted = height
		emit_signal("bottom_bar_resized", height)

func _flush_bottom_bar_resize_notification() -> void:
	_bottom_bar_resize_notification_queued = false
	_on_bottom_bar_resized()

func _notify_bottom_bar_resized_deferred() -> void:
	if is_inside_tree() and not _bottom_bar_resize_notification_queued:
		_bottom_bar_resize_notification_queued = true
		call_deferred("_flush_bottom_bar_resize_notification")


func _ensure_scrollable_state_message() -> void:
	if _scrollable_state_message != null or _stats_slot == null or _state_message == null:
		return

	_scrollable_state_message = RichTextLabel.new()
	_scrollable_state_message.name = "ScrollableStateMessage"
	_copy_control_layout(_state_message, _scrollable_state_message)
	_scrollable_state_message.bbcode_enabled = false
	_scrollable_state_message.fit_content = false
	_scrollable_state_message.scroll_active = true
	_scrollable_state_message.scroll_following = false
	_scrollable_state_message.selection_enabled = false
	_scrollable_state_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_scrollable_state_message.focus_mode = Control.FOCUS_CLICK
	_scrollable_state_message.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrollable_state_message.visible = false
	_apply_scrollable_state_message_theme(18)
	_stats_slot.add_child(_scrollable_state_message)
	_stats_slot.move_child(_scrollable_state_message, _state_message.get_index())
	_apply_message_text_boundaries()


func _apply_scrollable_state_message_theme(font_size: int) -> void:
	if _scrollable_state_message == null:
		return
	_scrollable_state_message.add_theme_color_override("default_color", DASHBOARD_TEXT_PRIMARY)
	_scrollable_state_message.add_theme_font_size_override("normal_font_size", font_size)
	_scrollable_state_message.add_theme_constant_override("line_separation", 2)


func _copy_control_layout(source: Control, target: Control) -> void:
	if source == null or target == null:
		return
	target.anchor_left = source.anchor_left
	target.anchor_top = source.anchor_top
	target.anchor_right = source.anchor_right
	target.anchor_bottom = source.anchor_bottom
	target.offset_left = source.offset_left
	target.offset_top = source.offset_top
	target.offset_right = source.offset_right
	target.offset_bottom = source.offset_bottom
	target.size_flags_horizontal = source.size_flags_horizontal
	target.size_flags_vertical = source.size_flags_vertical
	target.custom_minimum_size = source.custom_minimum_size
	target.grow_horizontal = source.grow_horizontal
	target.grow_vertical = source.grow_vertical
	target.clip_contents = true


func _show_scrollable_state_message(text: String, font_size: int) -> void:
	_ensure_scrollable_state_message()
	if _scrollable_state_message == null:
		return
	_apply_scrollable_state_message_theme(font_size)
	_scrollable_state_message.visible = true
	_scrollable_state_message.clear()
	_scrollable_state_message.append_text(text)
	_scrollable_state_message.scroll_to_line(0)


func _hide_scrollable_state_message() -> void:
	if _scrollable_state_message == null:
		return
	_scrollable_state_message.visible = false
	_scrollable_state_message.clear()
	_scrollable_state_message.scroll_to_line(0)


func _should_use_scrollable_banner_message(text: String, is_summary: bool, is_automated_skip_report: bool) -> bool:
	if is_summary or is_automated_skip_report:
		return true
	if text.find("\n") != -1:
		return true
	return _should_use_summary_overlay(text)


func _is_relevant_state_message(text: String) -> bool:
	return not text.strip_edges().is_empty()

func _looks_like_live_counter(text: String) -> bool:
	var t := text.to_lower()
	return "pins — standing:" in t and "buildings — standing:" in t

func _looks_like_summary(text: String) -> bool:
	if _looks_like_live_counter(text):
		return false
	if _looks_like_log_report(text):
		return true
	return text.contains("
") or text.length() >= 92 or "tap or click" in text.to_lower()


func _looks_like_log_report(text: String) -> bool:
	var lowered: String = text.to_lower()
	return (
		"automated engagements since your last shot" in lowered
		or lowered.begins_with("log:")
		or "
log:" in lowered
		or "[skiptoendtrace]" in lowered
	)

func _is_automated_skip_report(text: String) -> bool:
	var lowered: String = text.to_lower()
	return (
		"skip to end — resolved turn" in lowered
		and "automated engagements since your last shot" in lowered
	)


func _build_inline_skip_report_preview(text: String) -> String:
	var source_lines: PackedStringArray = text.split("
", false)
	var preview_lines: Array[String] = []
	var char_count: int = 0

	for line in source_lines:
		if preview_lines.size() >= SUMMARY_PREVIEW_MAX_LINES:
			break
		var line_text: String = String(line)
		if char_count > 0 and char_count + line_text.length() + 1 > SUMMARY_PREVIEW_MAX_CHARS:
			break
		preview_lines.append(line_text)
		char_count += line_text.length() + 1

	var preview: String = "
".join(preview_lines)
	if preview.strip_edges().is_empty():
		preview = text.substr(0, mini(text.length(), SUMMARY_PREVIEW_MAX_CHARS))

	if preview != text:
		preview = preview.rstrip("
") + "
…"
	return preview

func _should_pop_message(text: String) -> bool:
	var t := text.to_lower()
	return "pass" in t or "fail" in t or "secured" in t or "conquered" in t or "cleared" in t or "lost the turn" in t or "extra ball" in t or "milestone" in t

func _on_load_seed_pressed() -> void:
	var txt := _seed_edit.text.strip_edges()
	if txt.is_valid_int():
		var seed_val := int(txt)
		if seed_val != 0:
			emit_signal("load_seed_requested", seed_val)
			_seed_edit.text = ""
		else:
			_seed_edit.text = "Seed must be > 0"
	else:
		_seed_edit.text = "Enter a number"

func _on_copy_seed_pressed() -> void:
	if _seed_label == null:
		return
	var seed_str := _seed_label.text.strip_edges()
	if seed_str.is_empty() or seed_str == "Copied!":
		return
	DisplayServer.clipboard_set(seed_str)

	var orig_text := _seed_label.text
	_copy_btn.text = "✅"
	_seed_label.text = "Copied!"
	var tween := create_tween()
	tween.tween_property(_seed_label, "modulate", Color(0.6, 1.0, 0.6), 0.12)
	tween.tween_property(_seed_label, "modulate", Color.WHITE, 0.4)
	await get_tree().create_timer(1.1).timeout
	_seed_label.text = orig_text
	_copy_btn.text = "📋"


func _ensure_restart_confirm_dialog() -> void:
	if _restart_confirm_dialog != null and is_instance_valid(_restart_confirm_dialog):
		return
	_restart_confirm_dialog = ConfirmationDialog.new()
	_restart_confirm_dialog.name = "RestartConfirmDialog"
	_restart_confirm_dialog.title = "Confirm Restart"
	_restart_confirm_dialog.dialog_text = "Restart run and lose current progress?"
	_restart_confirm_dialog.ok_button_text = "Restart"
	_restart_confirm_dialog.get_cancel_button().text = "Cancel"
	_restart_confirm_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	_restart_confirm_dialog.confirmed.connect(func(): emit_signal("restart_pressed"))
	add_child(_restart_confirm_dialog)


func _on_restart_pressed() -> void:
	if _restart_confirm_dialog == null or not is_instance_valid(_restart_confirm_dialog):
		_ensure_restart_confirm_dialog()
	if _restart_confirm_dialog != null:
		_restart_confirm_dialog.popup_centered()
