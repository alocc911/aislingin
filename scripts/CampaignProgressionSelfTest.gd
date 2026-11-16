extends SceneTree
# Run via: godot --headless --path . --script res://scripts/CampaignProgressionSelfTest.gd
const MainScript = preload("res://scripts/Main.gd")
const LevelConfig = preload("res://scripts/LevelConfig.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var main = MainScript.new()
	main.campaign_level_progress = 10
	main.campaign_total_boss_progress_steps = 0
	main._rebuild_campaign_runtime_scalars()
	var defensive_bonus: Dictionary = main.get_campaign_boss_defensive_bonus_map()
	var total_extra_hits: int = 0
	for value in defensive_bonus.values():
		total_extra_hits += int(value)
	if total_extra_hits != 9:
		failures.append("direct_level_10_does_not_have_nine_extra_boss_hp")

	main.campaign_total_boss_progress_steps = 20
	main._rebuild_campaign_runtime_scalars()
	if main.get_campaign_boss_defensive_bonus_map() != defensive_bonus:
		failures.append("boss_hp_depends_on_completed_levels")

	main.campaign_level_progress = 1
	main._rebuild_campaign_runtime_scalars()
	for value in main.get_campaign_boss_defensive_bonus_map().values():
		if int(value) != 0:
			failures.append("level_one_boss_has_extra_hp")
			break

	main.campaign_permanent_upgrade_discount_map = main._create_empty_campaign_upgrade_discount_map()
	main._pending_campaign_upgrade_previous_level = 1
	main.campaign_level_progress = 2
	if main._can_protect_campaign_upgrade_price("bigger"):
		failures.append("cannot_protect_an_unchanged_price")
	if not main._can_protect_campaign_upgrade_price("heavier"):
		failures.append("missing_easy_price_increase")

	# A Hard clear from Level 1 to Level 3 must protect the whole jump.
	main.campaign_level_progress = 3
	if not main._protect_campaign_upgrade_price("heavier"):
		failures.append("hard_price_protection_rejected")
	if main.get_discounted_upgrade_cost_for_level("heavier", 3) != 1:
		failures.append("hard_price_increase_not_fully_protected")
	if main.get_discounted_upgrade_cost_for_level("bigger", 3) != 2:
		failures.append("unprotected_upgrade_price_not_increased")
	if main.get_discounted_upgrade_cost_for_level("heavier", 4) != 2:
		failures.append("price_increases_do_not_resume_after_protection")

	# A later choice on the same category should preserve the previously frozen price.
	main._pending_campaign_upgrade_previous_level = 3
	main.campaign_level_progress = 4
	if not main._protect_campaign_upgrade_price("heavier"):
		failures.append("second_price_protection_rejected")
	if main.get_discounted_upgrade_cost_for_level("heavier", 4) != 1:
		failures.append("second_price_protection_not_cumulative")
	if main.get_discounted_upgrade_cost_for_level("heavier", 5) != 2:
		failures.append("price_remains_frozen_after_unprotected_level")

	main.free()
	var result: Dictionary = {"ok": failures.is_empty(), "failures": failures}
	print("Campaign progression tests: ", JSON.stringify(result))
	quit(0 if bool(result.get("ok", false)) else 1)
