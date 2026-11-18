extends Control

const RunConfig = preload("res://scripts/RunConfig.gd")
const MODE_NORMAL: String = RunConfig.MODE_NORMAL
const MODE_BOSS_DEBUG: String = RunConfig.MODE_BOSS_DEBUG

@onready var main_menu: VBoxContainer = $MainMenu
@onready var start_level_select: OptionButton = $MainMenu/StartLevel
@onready var load_error_label: Label = $MainMenu/LoadError
@onready var options_menu: VBoxContainer = $OptionsMenu
@onready var normal_check: CheckButton = $OptionsMenu/Normal
@onready var boss_debug_check: CheckButton = $OptionsMenu/BossDebug
@onready var limb_left_arm: CheckButton = $OptionsMenu/BossDebugSettings/LeftArm
@onready var limb_right_arm: CheckButton = $OptionsMenu/BossDebugSettings/RightArm
@onready var limb_left_leg: CheckButton = $OptionsMenu/BossDebugSettings/LeftLeg
@onready var limb_right_leg: CheckButton = $OptionsMenu/BossDebugSettings/RightLeg
@onready var troop_count_spin: SpinBox = $OptionsMenu/BossDebugSettings/TroopCountRow/TroopCount
@onready var boss_debug_settings: VBoxContainer = $OptionsMenu/BossDebugSettings
@onready var selected_limb_hp_row: HBoxContainer = $OptionsMenu/BossDebugSettings/SelectedLimbHpRow
@onready var selected_limb_hp_spin: SpinBox = $OptionsMenu/BossDebugSettings/SelectedLimbHpRow/SelectedLimbHp
@onready var hit_box_visual_display_check: CheckButton = $OptionsMenu/HitBoxVisualDisplay
@onready var developer_tools_check: CheckButton = $OptionsMenu/DeveloperTools
@onready var auto_battles_check: CheckButton = $OptionsMenu/ShowAutoBattles

var _menu_file_import_callback: JavaScriptObject = null
var _saved_mode: String = MODE_NORMAL
var _editing_mode: String = MODE_NORMAL
var _saved_focus_limb: String = RunConfig.LIMB_NONE
var _editing_focus_limb: String = RunConfig.LIMB_NONE
var _saved_troop_count: int = 50
var _editing_troop_count: int = 50
var _saved_selected_limb_hit_points: int = 1
var _editing_selected_limb_hit_points: int = 1
var _saved_show_hit_box_visual_display: bool = false
var _editing_show_hit_box_visual_display: bool = false
var _editing_developer_tools: bool = false
var _saved_developer_tools: bool = false
var _editing_auto_battles: bool = true
var _saved_auto_battles: bool = true

func _ready() -> void:
	for level in range(1, 11):
		start_level_select.add_item("Level %d" % level, level)
	start_level_select.select(clampi(int(RunConfig.starting_campaign_level), 1, 10) - 1)
	_saved_mode = RunConfig.selected_mode
	_saved_focus_limb = RunConfig.normalize_focus_limb(RunConfig.boss_debug_focus_limb)
	_saved_troop_count = maxi(1, int(RunConfig.boss_debug_troop_count))
	_saved_selected_limb_hit_points = maxi(1, int(RunConfig.boss_debug_selected_limb_hit_points))
	_saved_show_hit_box_visual_display = bool(RunConfig.show_hit_box_visual_display)
	_saved_developer_tools = RunConfig.developer_tools_enabled
	_saved_auto_battles = RunConfig.show_auto_battle_visuals
	_editing_mode = _saved_mode
	_editing_focus_limb = _saved_focus_limb
	_editing_troop_count = _saved_troop_count
	_editing_selected_limb_hit_points = _saved_selected_limb_hit_points
	_editing_show_hit_box_visual_display = _saved_show_hit_box_visual_display
	_editing_developer_tools = _saved_developer_tools
	_editing_auto_battles = _saved_auto_battles
	developer_tools_check.set_pressed_no_signal(_editing_developer_tools)
	auto_battles_check.set_pressed_no_signal(_editing_auto_battles)
	_refresh_developer_options_visibility()
	_apply_mode_to_ui(_editing_mode)
	_apply_boss_debug_settings_to_ui()
	hit_box_visual_display_check.button_pressed = _editing_show_hit_box_visual_display
	show_main_menu()

func _on_start_pressed(force_tutorial: bool = false) -> void:
	RunConfig.starting_campaign_level = 1 if force_tutorial else clampi(start_level_select.get_selected_id(), 1, 10)
	RunConfig.pending_loaded_game_payload = {}
	RunConfig.launch_tutorial_next_run = force_tutorial
	RunConfig.set_mode(MODE_NORMAL if force_tutorial else (_saved_mode if _saved_developer_tools else MODE_NORMAL))
	RunConfig.set_boss_debug_settings(_saved_focus_limb, _saved_troop_count, _saved_selected_limb_hit_points)
	RunConfig.show_hit_box_visual_display = _saved_show_hit_box_visual_display if _saved_developer_tools else false
	RunConfig.developer_tools_enabled = _saved_developer_tools
	RunConfig.show_auto_battle_visuals = _saved_auto_battles
	if RunConfig.is_boss_debug_mode():
		RunConfig.arm_boss_debug_start()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_load_game_pressed() -> void:
	load_error_label.visible = false
	if OS.has_feature("web"):
		_menu_file_import_callback = JavaScriptBridge.create_callback(_on_browser_menu_file_loaded)
		var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
		window.sunnyslopesMenuImport = _menu_file_import_callback
		JavaScriptBridge.eval("""
			(() => {
				const input = document.createElement('input');
				input.type = 'file';
				input.accept = '.ssave,application/octet-stream';
				input.style.display = 'none';
				document.body.appendChild(input);
				input.onchange = () => {
					const file = input.files && input.files[0];
					if (!file) { input.remove(); return; }
					const reader = new FileReader();
					reader.onload = () => {
						window.sunnyslopesMenuImport(String(reader.result).split(',').pop());
						input.remove();
					};
					reader.onerror = () => { input.remove(); };
					reader.readAsDataURL(file);
				};
				input.click();
			})()
		""", true)
		return
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.ssave ; SunnySlopes Save"])
	dialog.file_selected.connect(_on_native_menu_file_selected)
	dialog.close_requested.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(700, 450))


func _on_browser_menu_file_loaded(args: Array) -> void:
	if not args.is_empty():
		_try_load_menu_save(Marshalls.base64_to_raw(String(args[0])))


func _on_native_menu_file_selected(path: String) -> void:
	_try_load_menu_save(FileAccess.get_file_as_bytes(path))


func _try_load_menu_save(buffer: PackedByteArray) -> void:
	if buffer.is_empty() or buffer.size() > 20000000:
		_show_menu_load_error("Invalid or oversized saved game.")
		return
	var payload_any: Variant = bytes_to_var(buffer)
	if not (payload_any is Dictionary):
		_show_menu_load_error("Saved game could not be read.")
		return
	var payload: Dictionary = payload_any
	if String(payload.get("format", "")) != "SunnySlopesGame" or int(payload.get("version", 0)) not in [1, 2] or not (payload.get("provinces", null) is Array) or (payload.get("provinces", []) as Array).is_empty() or (payload.get("provinces", []) as Array).size() > 1000:
		_show_menu_load_error("Incompatible or invalid saved game.")
		return
	RunConfig.pending_loaded_game_payload = payload
	RunConfig.launch_tutorial_next_run = false
	RunConfig.set_mode(MODE_NORMAL)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _show_menu_load_error(message: String) -> void:
	load_error_label.text = message
	load_error_label.visible = true


func _on_tutorial_pressed() -> void:
	_on_start_pressed(true)


func _on_options_pressed() -> void:
	_editing_mode = _saved_mode
	_editing_focus_limb = _saved_focus_limb
	_editing_troop_count = _saved_troop_count
	_editing_selected_limb_hit_points = _saved_selected_limb_hit_points
	_editing_show_hit_box_visual_display = _saved_show_hit_box_visual_display
	_editing_developer_tools = _saved_developer_tools
	_editing_auto_battles = _saved_auto_battles
	developer_tools_check.set_pressed_no_signal(_editing_developer_tools)
	auto_battles_check.set_pressed_no_signal(_editing_auto_battles)
	_refresh_developer_options_visibility()
	_apply_mode_to_ui(_editing_mode)
	_apply_boss_debug_settings_to_ui()
	hit_box_visual_display_check.button_pressed = _editing_show_hit_box_visual_display
	main_menu.visible = false
	options_menu.visible = true

func _on_cancel_pressed() -> void:
	show_main_menu()

func _on_save_pressed() -> void:
	_saved_mode = _editing_mode
	_saved_focus_limb = _editing_focus_limb
	_saved_troop_count = maxi(1, _editing_troop_count)
	_saved_selected_limb_hit_points = maxi(1, _editing_selected_limb_hit_points)
	_saved_show_hit_box_visual_display = _editing_show_hit_box_visual_display if _editing_developer_tools else false
	_saved_developer_tools = _editing_developer_tools
	_saved_auto_battles = _editing_auto_battles
	if not _saved_developer_tools:
		_saved_mode = MODE_NORMAL
	RunConfig.developer_tools_enabled = _saved_developer_tools
	RunConfig.show_auto_battle_visuals = _saved_auto_battles
	RunConfig.set_mode(_saved_mode)
	RunConfig.set_boss_debug_settings(_saved_focus_limb, _saved_troop_count, _saved_selected_limb_hit_points)
	RunConfig.show_hit_box_visual_display = _saved_show_hit_box_visual_display
	show_main_menu()

func _on_normal_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_editing_mode = MODE_NORMAL
		_apply_mode_to_ui(_editing_mode)

func _on_boss_debug_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_editing_mode = MODE_BOSS_DEBUG
		_apply_mode_to_ui(_editing_mode)

func _on_left_arm_toggled(button_pressed: bool) -> void:
	_handle_limb_toggle(RunConfig.LIMB_LEFT_ARM, button_pressed)
func _on_right_arm_toggled(button_pressed: bool) -> void:
	_handle_limb_toggle(RunConfig.LIMB_RIGHT_ARM, button_pressed)
func _on_left_leg_toggled(button_pressed: bool) -> void:
	_handle_limb_toggle(RunConfig.LIMB_LEFT_LEG, button_pressed)
func _on_right_leg_toggled(button_pressed: bool) -> void:
	_handle_limb_toggle(RunConfig.LIMB_RIGHT_LEG, button_pressed)

func _on_troop_count_value_changed(value: float) -> void:
	_editing_troop_count = maxi(1, int(round(value)))

func _handle_limb_toggle(limb: String, button_pressed: bool) -> void:
	if button_pressed:
		_editing_focus_limb = limb
	elif _editing_focus_limb == limb:
		_editing_focus_limb = RunConfig.LIMB_NONE
	_apply_boss_debug_settings_to_ui()

func _apply_mode_to_ui(mode: String) -> void:
	var normalized_mode: String = MODE_BOSS_DEBUG if mode == MODE_BOSS_DEBUG else MODE_NORMAL
	normal_check.button_pressed = normalized_mode == MODE_NORMAL
	boss_debug_check.button_pressed = normalized_mode == MODE_BOSS_DEBUG
	boss_debug_settings.visible = _editing_developer_tools and normalized_mode == MODE_BOSS_DEBUG
	_editing_mode = normalized_mode

func _apply_boss_debug_settings_to_ui() -> void:
	limb_left_arm.button_pressed = _editing_focus_limb == RunConfig.LIMB_LEFT_ARM
	limb_right_arm.button_pressed = _editing_focus_limb == RunConfig.LIMB_RIGHT_ARM
	limb_left_leg.button_pressed = _editing_focus_limb == RunConfig.LIMB_LEFT_LEG
	limb_right_leg.button_pressed = _editing_focus_limb == RunConfig.LIMB_RIGHT_LEG
	troop_count_spin.value = float(maxi(1, _editing_troop_count))
	selected_limb_hp_spin.value = float(maxi(1, _editing_selected_limb_hit_points))
	selected_limb_hp_row.visible = _editing_focus_limb != RunConfig.LIMB_NONE

func show_main_menu() -> void:
	main_menu.visible = true
	options_menu.visible = false


func _on_selected_limb_hp_value_changed(value: float) -> void:
	_editing_selected_limb_hit_points = maxi(1, int(round(value)))


func _on_hit_box_visual_display_toggled(button_pressed: bool) -> void:
	_editing_show_hit_box_visual_display = button_pressed


func _on_developer_tools_toggled(enabled: bool) -> void:
	_editing_developer_tools = enabled
	if not enabled:
		_editing_mode = MODE_NORMAL
	_apply_mode_to_ui(_editing_mode)
	_refresh_developer_options_visibility()


func _on_auto_battles_toggled(enabled: bool) -> void:
	_editing_auto_battles = enabled


func _refresh_developer_options_visibility() -> void:
	for control in [normal_check, boss_debug_check, hit_box_visual_display_check]:
		control.visible = _editing_developer_tools
	boss_debug_settings.visible = _editing_developer_tools and _editing_mode == MODE_BOSS_DEBUG
