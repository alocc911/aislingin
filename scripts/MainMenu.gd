extends Control

const RunConfig = preload("res://scripts/RunConfig.gd")
const MODE_NORMAL: String = RunConfig.MODE_NORMAL
const MODE_BOSS_DEBUG: String = RunConfig.MODE_BOSS_DEBUG

@onready var main_menu: VBoxContainer = $MainMenu
@onready var options_menu: VBoxContainer = $OptionsMenu
@onready var normal_check: CheckButton = $OptionsMenu/Normal
@onready var boss_debug_check: CheckButton = $OptionsMenu/BossDebug

var _saved_mode: String = MODE_NORMAL
var _editing_mode: String = MODE_NORMAL


func _ready() -> void:
	_saved_mode = RunConfig.selected_mode
	_editing_mode = _saved_mode
	_apply_mode_to_ui(_editing_mode)
	show_main_menu()


func _on_start_pressed() -> void:
	RunConfig.set_mode(_saved_mode)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_options_pressed() -> void:
	_editing_mode = _saved_mode
	_apply_mode_to_ui(_editing_mode)
	main_menu.visible = false
	options_menu.visible = true


func _on_cancel_pressed() -> void:
	_editing_mode = _saved_mode
	_apply_mode_to_ui(_editing_mode)
	show_main_menu()


func _on_save_pressed() -> void:
	_saved_mode = _editing_mode
	RunConfig.set_mode(_saved_mode)
	show_main_menu()


func _on_normal_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_editing_mode = MODE_NORMAL
		_apply_mode_to_ui(_editing_mode)
	elif _editing_mode == MODE_NORMAL:
		normal_check.button_pressed = true


func _on_boss_debug_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_editing_mode = MODE_BOSS_DEBUG
		_apply_mode_to_ui(_editing_mode)
	elif _editing_mode == MODE_BOSS_DEBUG:
		boss_debug_check.button_pressed = true


func _apply_mode_to_ui(mode: String) -> void:
	var normalized_mode: String = MODE_BOSS_DEBUG if mode == MODE_BOSS_DEBUG else MODE_NORMAL
	if normal_check != null:
		normal_check.button_pressed = normalized_mode == MODE_NORMAL
	if boss_debug_check != null:
		boss_debug_check.button_pressed = normalized_mode == MODE_BOSS_DEBUG
	_editing_mode = normalized_mode


func show_main_menu() -> void:
	main_menu.visible = true
	options_menu.visible = false
