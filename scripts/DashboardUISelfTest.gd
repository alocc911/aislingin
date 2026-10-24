extends SceneTree
# Run with: godot --headless --path . --script res://scripts/DashboardUISelfTest.gd

func _initialize() -> void:
	call_deferred("_check_ui")


func _fail(message: String) -> void:
	push_error("DashboardUISelfTest: " + message)
	quit(1)


func _check_ui() -> void:
	var packed: PackedScene = load("res://scenes/UIOverlay.tscn") as PackedScene
	if packed == null:
		_fail("UIOverlay scene did not load")
		return
	var overlay: Node = packed.instantiate()
	root.add_child(overlay)
	await process_frame

	var commands: GridContainer = overlay.find_child("SecondaryRow", true, false) as GridContainer
	var actions: GridContainer = overlay.find_child("ActionsRow", true, false) as GridContainer
	var restart: Button = overlay.get("_restart_btn") as Button
	var gold: Control = overlay.get("_gold_shell") as Control
	if commands == null or actions == null or restart == null or gold == null:
		_fail("Dashboard command grid missing")
		return
	if commands.columns != 2 or actions.columns != 1 or restart.get_parent() != commands:
		_fail("Dashboard controls are not in the confined vertical grid")
		return
	if gold.get_parent() == commands:
		_fail("Gold must not share a row with command buttons")
		return
	# Replicate the busy tutorial state from the player's screenshot.
	overlay.call("set_opening_gameplay_tutorial_skip_button", true, "Skip Tutorial")
	await process_frame
	var right_content: Control = overlay.get("_dashboard_right_content") as Control
	if right_content == null or right_content.size.x <= 0.0:
		_fail("Right dashboard column was not laid out")
		return
	var required_width: float = commands.get_combined_minimum_size().x
	if required_width > right_content.size.x + 2.0:
		_fail("Command grid overflows panel: required %.1f, available %.1f" % [required_width, right_content.size.x])
		return

	overlay.call("show_province_management_panel", "Test Province", "Technical info")
	await process_frame
	var province: Window = overlay.find_child("ProvinceManagementDialog", true, false) as Window
	var tabs: TabContainer = overlay.get("_province_panel_tabs") as TabContainer
	var metrics: Label = overlay.get("_province_panel_overview_metrics") as Label
	if province == null or tabs == null or metrics == null:
		_fail("Province popup did not initialize")
		return
	if not province.popup_window or province.exclusive:
		_fail("Province popup is not configured to dismiss on outside click")
		return
	var tabs_font: int = tabs.get_tab_bar().get_theme_font_size("font_size")
	var metrics_font: int = metrics.get_theme_font_size("font_size")
	print("DashboardUISelfTest font sizes: tabs=%d, overview=%d" % [tabs_font, metrics_font])
	if tabs_font < 23 or metrics_font < 24:
		_fail("Province menu fonts are too small (tabs=%d, overview=%d)" % [tabs_font, metrics_font])
		return
	if not bool(overlay.call("dismiss_province_management_on_outside_right_click", Vector2(-10000.0, -10000.0))):
		_fail("Outside right-click did not dismiss province popup")
		return
	if province.visible:
		_fail("Province popup remains visible after dismissal")
		return

	print("DashboardUISelfTest passed: grid, popup sizing, fonts, and dismiss path")
	quit(0)
