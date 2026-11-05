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
	var gold: Control = overlay.get("_gold_block") as Control
	if commands == null or actions == null or restart == null or gold == null:
		_fail("Dashboard command grid missing")
		return
	if commands.columns != 1 or actions.columns != 1 or restart.get_parent() != commands:
		_fail("Dashboard option controls must use one full-width column")
		return
	var action_scroll: ScrollContainer = overlay.get("_right_controls_scroll") as ScrollContainer
	var right_content: Control = overlay.get("_dashboard_right_content") as Control
	var left_section: Control = overlay.get("_dashboard_left_section") as Control
	var right_section: Control = overlay.get("_dashboard_right_section") as Control
	var utility_block: Control = overlay.get("_utility_block") as Control
	if action_scroll == null or right_content == null or utility_block == null or left_section == null or right_section == null:
		_fail("The left and right trays and action scroll must exist")
		return
	if gold.get_parent() != right_content or action_scroll.get_parent() != right_content:
		_fail("Gold and all commands belong in the same right-side tray")
		return
	if utility_block.get_parent() != action_scroll:
		_fail("All contextual controls must scroll inside the right-side tray")
		return
	if overlay.get("_gold_shell") != null:
		_fail("Gold has an unnecessary nested plaque")
		return
	var left_art: NinePatchRect = left_section.get_node_or_null("OuterMargin/TrayRoot/UpgradeSection_TrayBg") as NinePatchRect
	var right_art: NinePatchRect = right_section.get_node_or_null("OuterMargin/TrayRoot/EconomySection_TrayBg") as NinePatchRect
	if left_art == null or right_art == null:
		_fail("Both HUD sides must use their own original tray artwork")
		return
	if left_art.texture == null or right_art.texture == null:
		_fail("A HUD tray is missing its nine-slice texture")
		return
	if left_art.patch_margin_left != 24 or right_art.patch_margin_left != 24:
		_fail("Side tray borders must use the compact, half-sized geometry")
		return
	if left_art.texture != right_art.texture:
		_fail("Left and right sections should reuse one cached tray image")
		return
	# Replicate the busy tutorial state from the player's screenshot.
	overlay.call("set_opening_gameplay_tutorial_skip_button", true, "Skip Tutorial")
	await process_frame
	if right_content.size.x <= 0.0:
		_fail("Right dashboard column was not laid out")
		return
	var required_width: float = maxf(commands.get_combined_minimum_size().x, actions.get_combined_minimum_size().x)
	if required_width > right_content.size.x + 2.0:
		_fail("Command grid overflows panel: required %.1f, available %.1f" % [required_width, right_content.size.x])
		return
	# Keep all five cards inside the 720x444 logical dashboard. Older
	# self-tests missed the clipped Magnet card entirely.
	var hud: Control = overlay.get("_bottom_bar") as Control
	var upgrade_shop: VBoxContainer = overlay.get("_shop_block") as VBoxContainer
	if hud == null or upgrade_shop == null:
		_fail("Dashboard frame or upgrade column missing")
		return
	var hud_rect: Rect2 = hud.get_global_rect()
	var cards: Array[Button] = []
	for child in upgrade_shop.get_children():
		if child is Button and child.visible:
			cards.append(child as Button)
	if cards.size() != 5:
		_fail("Expected five visible upgrade cards, found %d" % cards.size())
		return
	var previous_card_bottom: float = -INF
	for card in cards:
		var card_rect: Rect2 = card.get_global_rect()
		if card_rect.position.y < hud_rect.position.y + 3.0 or card_rect.end.y > hud_rect.end.y - 3.0:
			_fail("%s clipped outside the HUD: %s / %s" % [card.name, card_rect, hud_rect])
			return
		if card_rect.position.y < previous_card_bottom:
			_fail("%s overlaps the preceding upgrade card" % card.name)
			return
		previous_card_bottom = card_rect.end.y
	# The title must straddle, not paint over, the ornate crown.
	overlay.call("set_level_text", "Level 1 — Turn 2")
	await process_frame
	var level_caption: Label = overlay.get("_lbl_level") as Label
	var turn_caption: Label = overlay.get("_dashboard_turn_label") as Label
	if level_caption == null or turn_caption == null:
		_fail("Split level and turn title controls missing")
		return
	if level_caption.text != "Level 1" or turn_caption.text != "Turn 2":
		_fail("Level/turn title was not split around center ornament")
		return
	if turn_caption.get_global_rect().position.x - level_caption.get_global_rect().end.x < 35.0:
		_fail("Level/turn title has insufficient clearance for the frame ornament")
		return
	var help_badge: Label = overlay.get("_help_badge") as Label
	if help_badge == null or help_badge.has_node("BadgeBg"):
		_fail("Field Guide unread badge must draw its background behind the number")
		return
	var skip: Button = overlay.get("_skip_to_end_btn") as Button
	var build: Button = overlay.get("_build_mode_btn") as Button
	var right_layout: VBoxContainer = overlay.get("_right_utility_layout") as VBoxContainer
	var help: Button = overlay.get("_help_btn") as Button
	var menu: Button = overlay.get("_game_settings_btn") as Button
	var recap: Button = overlay.get("_reopen_summary_btn") as Button
	if skip == null or skip.get_parent() != actions or build != null:
		_fail("Context actions must remain available in the shared tray")
		return
	if help == null or menu == null or recap == null:
		_fail("Core and contextual controls are missing")
		return
	if help.get_parent() != commands or menu.get_parent() != commands or recap.get_parent() != actions:
		_fail("Restart/Help/Menu and Recap must share one tray in distinct rows")
		return
	if right_layout.get_children().find(commands) >= right_layout.get_children().find(actions):
		_fail("Core commands should appear above recap and contextual actions")
		return
	await process_frame
	var tray_hud_rect: Rect2 = hud.get_global_rect()
	for tray in [left_art, right_art]:
		var frame: Rect2 = tray.get_global_rect()
		if frame.position.x < tray_hud_rect.position.x + 8.0 or frame.end.x > tray_hud_rect.end.x - 8.0:
			_fail("%s collides with the outer frame horizontally" % tray.name)
			return
		if frame.position.y < tray_hud_rect.position.y + 18.0 or frame.end.y > tray_hud_rect.end.y - 18.0:
			_fail("%s collides with the outer frame vertically" % tray.name)
			return
	if gold.get_global_rect().end.y >= action_scroll.get_global_rect().position.y:
		_fail("Gold stat overlaps the action list")
		return
	if action_scroll.get_global_rect().end.y > right_art.get_global_rect().end.y - 8.0:
		_fail("Right action list is not contained by the right tray")
		return
	for card in cards:
		var bounds: Rect2 = card.get_global_rect()
		var tray_bounds: Rect2 = left_art.get_global_rect()
		if bounds.position.x < tray_bounds.position.x + 3.0 or bounds.end.x > tray_bounds.end.x - 3.0:
			_fail("%s escapes the left tray horizontally" % card.name)
			return
		if bounds.position.y < tray_bounds.position.y + 3.0 or bounds.end.y > tray_bounds.end.y - 3.0:
			_fail("%s escapes the left tray vertically" % card.name)
			return

	# Long status text must never produce a second automatic popup.
	overlay.call("show_state_message", "Victory — 24 troops downed\nBattle log details")
	var backdrop: Control = overlay.get("_summary_overlay_backdrop") as Control
	if backdrop.visible:
		_fail("Routine status messages unexpectedly opened a modal")
		return
	var confirmations: Array[int] = []
	overlay.engagement_result_continue_requested.connect(func(): confirmations.append(1))
	var result := {
		"headline": "Win and Conquer",
		"subtitle": "Attack resolved",
		"troops": "24 / 24",
		"buildings": "4 / 4",
		"territory": "Captured",
		"next": "Next: Enemy advances 1 turn",
		"detail": "Win and Conquer\nTroops downed 24/24\nBuildings 0/4"
	}
	overlay.call("show_engagement_result", result)
	await process_frame
	if not bool(overlay.call("is_engagement_result_open")):
		_fail("Explicit battle result did not display")
		return
	var result_button: Button = overlay.get("_summary_overlay_close_btn") as Button
	var result_body: RichTextLabel = overlay.get("_summary_overlay_body") as RichTextLabel
	var metrics_row: HBoxContainer = overlay.get("_summary_overlay_metrics") as HBoxContainer
	if result_button.text != "Continue" or result_body.visible or metrics_row.get_child_count() != 3:
		_fail("Battle result is not compact with a single Continue control")
		return
	overlay.call("show_state_message", "A routine status update")
	if not bool(overlay.call("is_engagement_result_open")):
		_fail("A status update dismissed the battle result")
		return
	result_button.emit_signal("pressed")
	await process_frame
	if confirmations.size() != 1 or bool(overlay.call("is_engagement_result_open")):
		_fail("Continue did not acknowledge exactly once")
		return
	result_button.emit_signal("pressed")
	if confirmations.size() != 1:
		_fail("Result was acknowledged more than once")
		return
	overlay.call("_on_reopen_summary_pressed")
	await process_frame
	if result_button.text != "Close" or not result_body.visible:
		_fail("Recap did not open the full report in review-only mode")
		return
	result_button.emit_signal("pressed")
	if confirmations.size() != 1:
		_fail("Closing a recap advanced the game")
		return

	overlay.call("show_province_management_panel", "Test Province", "Technical info", 321, [], [], 0, {}, {
		"is_player_owned": true,
		"construction_queue": [{"request_type": "build", "building_type": "farm", "tier": 1, "prepaid": true}],
		"construction_queue_limit": 5
	})
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
	var queue_header: Label = overlay.get("_province_panel_queue_header") as Label
	var queue_list: VBoxContainer = overlay.get("_province_panel_queue_list") as VBoxContainer
	if queue_header == null or queue_list == null or queue_header.text != "Pending orders (1/5)" or queue_list.get_child_count() != 2:
		_fail("Province Build tab did not render the construction queue")
		return
	var clear_all: Button = queue_list.get_child(0) as Button
	if clear_all == null or clear_all.text != "Cancel All":
		_fail("Missing queue Cancel All control")
		return
	var cancel_row: HBoxContainer = queue_list.get_child(1) as HBoxContainer
	var cancel_btn: Button = null
	var up_btn: Button = null
	var down_btn: Button = null
	if cancel_row != null:
		for child in cancel_row.get_children():
			if child is Button:
				if String(child.text) == "Cancel":
					cancel_btn = child
				elif up_btn == null:
					up_btn = child
				else:
					down_btn = child
	if up_btn == null or down_btn == null or up_btn.icon == null or down_btn.icon == null or not up_btn.disabled or not down_btn.disabled:
		_fail("Queue reorder icon controls not initialized with correct bounds")
		return
	var cancellation: Array[int] = []
	overlay.province_construction_queue_cancel_requested.connect(func(province_id: int, queue_index: int):
		if province_id == 321:
			cancellation.append(queue_index))
	if cancel_btn == null:
		_fail("Queued project has no cancel action")
		return
	cancel_btn.emit_signal("pressed")
	if cancellation != [0]:
		_fail("Queue cancellation emitted the wrong province or index")
		return
	var cleared: Array[int] = []
	overlay.province_construction_queue_cancel_all_requested.connect(func(province_id: int): cleared.append(province_id))
	clear_all.emit_signal("pressed")
	if cleared != [321]:
		_fail("Cancel All did not send the current province ID")
		return
	if not bool(overlay.call("dismiss_province_management_on_outside_right_click", Vector2(-10000.0, -10000.0))):
		_fail("Outside right-click did not dismiss province popup")
		return
	if province.visible:
		_fail("Province popup remains visible after dismissal")
		return

	# The standalone tutorial must show its longer copy in a scrollable
	# panel. Clicking the backdrop dismisses the message but not the game.
	overlay.call("show_opening_gameplay_tutorial_instruction", "Welcome", "First paragraph.\n\nSecond paragraph.")
	await process_frame
	var tutorial_backdrop: ColorRect = overlay.get("_opening_instruction_backdrop") as ColorRect
	var tutorial_panel: PanelContainer = overlay.get("_opening_instruction_panel") as PanelContainer
	var tutorial_body: RichTextLabel = overlay.get("_opening_instruction_body") as RichTextLabel
	if tutorial_backdrop == null or tutorial_panel == null or tutorial_body == null or not tutorial_backdrop.visible:
		_fail("Standalone tutorial instruction panel failed to open")
		return
	if not tutorial_body.scroll_active or tutorial_body.text.find("Second paragraph.") < 0:
		_fail("Tutorial copy is missing or the text panel cannot scroll")
		return
	var inside_click := InputEventMouseButton.new()
	inside_click.button_index = MOUSE_BUTTON_LEFT
	inside_click.pressed = true
	inside_click.global_position = tutorial_panel.get_global_rect().get_center()
	overlay.call("_on_opening_instruction_backdrop_gui_input", inside_click)
	if not tutorial_backdrop.visible:
		_fail("Clicking inside a tutorial menu dismissed it")
		return
	var outside_click := InputEventMouseButton.new()
	outside_click.button_index = MOUSE_BUTTON_LEFT
	outside_click.pressed = true
	outside_click.global_position = Vector2(-10000.0, -10000.0)
	overlay.call("_on_opening_instruction_backdrop_gui_input", outside_click)
	if tutorial_backdrop.visible:
		_fail("Clicking outside a tutorial menu did not dismiss it")
		return
	overlay.call("show_opening_gameplay_tutorial_instruction", "Again", "Continue button test")
	var continue_button: Button = tutorial_backdrop.find_child("OpeningGameplayInstructionContinue", true, false) as Button
	if continue_button == null:
		_fail("Tutorial menu has no Continue button")
		return
	continue_button.emit_signal("pressed")
	if tutorial_backdrop.visible:
		_fail("Tutorial Continue button did not close the message")
		return
	overlay.call("show_province_management_panel", "Test Province", "Technical info", 321, [], [], 0, {}, {"is_player_owned": true})
	await process_frame
	if not bool(overlay.call("dismiss_province_management_on_outside_click", Vector2(-10000.0, -10000.0))) or province.visible:
		_fail("Outside left-click did not dismiss province management")
		return
	print("DashboardUISelfTest passed: dashboard, scrollable tutorial messages and outside-click dismissal")
	quit(0)
