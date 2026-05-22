extends Control

const RunConfig = preload("res://scripts/RunConfig.gd")
const MODE_NORMAL: String = RunConfig.MODE_NORMAL
const MODE_BOSS_DEBUG: String = RunConfig.MODE_BOSS_DEBUG

@onready var main_menu: VBoxContainer = $MainMenu
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

func _ready() -> void:
	_saved_mode = RunConfig.selected_mode
	_saved_focus_limb = RunConfig.normalize_focus_limb(RunConfig.boss_debug_focus_limb)
	_saved_troop_count = maxi(1, int(RunConfig.boss_debug_troop_count))
	_saved_selected_limb_hit_points = maxi(1, int(RunConfig.boss_debug_selected_limb_hit_points))
	_saved_show_hit_box_visual_display = bool(RunConfig.show_hit_box_visual_display)
	_editing_mode = _saved_mode
	_editing_focus_limb = _saved_focus_limb
	_editing_troop_count = _saved_troop_count
	_editing_selected_limb_hit_points = _saved_selected_limb_hit_points
	_editing_show_hit_box_visual_display = _saved_show_hit_box_visual_display
	_apply_mode_to_ui(_editing_mode)
	_apply_boss_debug_settings_to_ui()
	hit_box_visual_display_check.button_pressed = _editing_show_hit_box_visual_display
	show_main_menu()

func _on_start_pressed() -> void:
	RunConfig.set_mode(_saved_mode)
	RunConfig.set_boss_debug_settings(_saved_focus_limb, _saved_troop_count, _saved_selected_limb_hit_points)
	RunConfig.show_hit_box_visual_display = _saved_show_hit_box_visual_display
	if RunConfig.is_boss_debug_mode():
		RunConfig.arm_boss_debug_start()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_options_pressed() -> void:
	_editing_mode = _saved_mode
	_editing_focus_limb = _saved_focus_limb
	_editing_troop_count = _saved_troop_count
	_editing_selected_limb_hit_points = _saved_selected_limb_hit_points
	_editing_show_hit_box_visual_display = _saved_show_hit_box_visual_display
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
	_saved_show_hit_box_visual_display = _editing_show_hit_box_visual_display
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
	boss_debug_settings.visible = normalized_mode == MODE_BOSS_DEBUG
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
