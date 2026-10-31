extends SceneTree
# Headless regression for the read-only campaign economy telemetry.

const MetricsScript = preload("res://scripts/AutoplayEconomyMetrics.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var provinces: Array[Dictionary] = [
		_make_province(1, "enemy", 7, 11.0, 3.0),
		_make_province(2, "neutral", 0, 4.0, 3.0)
	]
	var metrics = MetricsScript.new()
	metrics.initialize(71, provinces)
	metrics.record_turn(provinces, 0, 50, 0, 0)

	provinces[0]["faction_id"] = 9
	metrics.track_ownership(provinces, 3, "automated_action")
	provinces[0]["faction_id"] = 9000
	provinces[0]["history_happiness"] = [{"turn": 5, "natives": 0.0, "outlanders": 12.0}]
	var revolted_ids: Array[int] = [1]
	metrics.track_ownership(provinces, 5, "economy", revolted_ids)
	metrics.record_turn(provinces, 5, 50, 1, 0)

	var summary: Dictionary = metrics.summarize(provinces, 5)
	var checks: Dictionary = {
		"ownership_events": metrics.ownership_rows.size() == 2,
		"turn_zero_and_five": metrics.map_rows.size() == 2 and metrics.province_rows.size() == 4,
		"completed_tenures": int(summary["completed_holding_periods"]) == 2,
		"right_censored_tenures": int(summary["censored_holding_periods"]) == 1,
		"revolution_attributed": int(summary["revolts_by_previous_owner"].get("enemy_9", 0)) == 1,
		"recent_capture_revolution": int(summary["revolts_within_5_turns_of_capture"]) == 1,
		"peak_population": is_equal_approx(float(summary["peak_province_population"]), 14.0),
		"zero_happiness_captured": metrics.ownership_rows[1].ends_with(",0.00,12.00"),
		"rebel_faction": MetricsScript.owner_key(provinces[0]) == "enemy_9000"
	}
	var ok: bool = true
	for value in checks.values():
		if not bool(value):
			ok = false
	print("AUTOPLAY_METRICS_SELF_TEST ", JSON.stringify({"ok": ok, "checks": checks}))
	quit(0 if ok else 1)


func _make_province(id: int, kind: String, faction: int, natives: float, outlanders: float) -> Dictionary:
	return {
		"id": id,
		"type": kind,
		"faction_id": faction,
		"population": {"natives": natives, "outlanders": outlanders},
		"happiness": {"natives": 70.0, "outlanders": 60.0},
		"food": {"production": 40.0, "demand": 30.0, "surplus": 10.0},
		"accommodation": {"native_ceiling": 25.0, "outlander_ceiling": 10.0},
		"rates": {"income": 3.0, "recruitment": 1.0},
		"remaining_troops": 5,
		"remaining_buildings": 3
	}
