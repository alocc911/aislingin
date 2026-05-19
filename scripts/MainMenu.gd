extends Control

@onready var main_menu: VBoxContainer = $MainMenu
@onready var options_menu: VBoxContainer = $OptionsMenu


func _ready() -> void:
	show_main_menu()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_options_pressed() -> void:
	main_menu.visible = false
	options_menu.visible = true


func _on_back_pressed() -> void:
	show_main_menu()


func show_main_menu() -> void:
	main_menu.visible = true
	options_menu.visible = false
