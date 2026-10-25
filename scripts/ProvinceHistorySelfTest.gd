extends RefCounted
# Run via: godot --headless --path . --script res://scripts/ProvinceHistoryTestRunner.gd
const History = preload("res://scripts/ProvinceHistory.gd")

static func run() -> Dictionary:
	var failures: Array[String] = []
	var p: Dictionary = {
		"id": 9, "type": "friendly", "faction_id": 0,
		"remaining_troops": 30, "remaining_buildings": 2,
		"buildings": {"farm": {"1": 2}},
		"happiness": {"natives": 55.0, "outlanders": 65.0}
	}
	var prior: Dictionary = History.snapshot(p)
	History.record_happiness(p, 1)
	p["happiness"]["natives"] = 34.0
	History.record_happiness(p, 2)
	History.record_happiness(p, 2)
	if p[History.HAPPINESS_KEY].size() != 2:
		failures.append("duplicate_happiness_turn")
	if float(p[History.HAPPINESS_KEY][1]["natives"]) != 34.0:
		failures.append("happiness_values_not_preserved")

	History.add_event(p, 2, "invasion_attempt", "Invasion attempt", "40 attackers from province 5")
	p["type"] = "enemy"
	p["faction_id"] = 7
	p["remaining_buildings"] = 1
	p["buildings"]["farm"]["1"] = 1
	var loss: Dictionary = History.record_changes(p, prior, 2, "Enemy invasion", "40 attackers from province 5; 12 survived.")
	if int(loss.get("province_id", -1)) != 9 or String(loss.get("cause", "")) != "Enemy invasion":
		failures.append("capture_lost_notification_missing")
	var ownership_events: int = 0
	var building_events: int = 0
	for event in p[History.EVENTS_KEY]:
		if String(event.get("category", "")) == "ownership":
			ownership_events += 1
			if String(event.get("detail", "")).find("province 5") < 0:
				failures.append("origin_province_missing")
		if String(event.get("category", "")) == "buildings":
			building_events += 1
	if ownership_events != 1 or building_events != 1:
		failures.append("invasion_event_breakdown")
	if not History.record_changes(p, History.snapshot(p), 3, "Enemy invasion").is_empty():
		failures.append("unchanged_province_generates_loss")

	# Every troop source produces its own comprehensible accounting entry.
	var troop_test: Dictionary = {"id": 22, "type": "friendly", "remaining_troops": 0, "buildings": {}}
	History.record_troop_change(troop_test, 2, 0, 16, "Normal local recruitment")
	History.record_troop_change(troop_test, 2, 16, 24, "Friendly march", "A neighboring province")
	History.record_troop_change(troop_test, 2, 24, 19, "Friendly march", "", "Southern front")
	var troop_events: Array = troop_test.get(History.EVENTS_KEY, [])
	if troop_events.size() != 3:
		failures.append("troop_provenance_event_count")
	else:
		if String(troop_events[0].get("title", "")) != "Troops recruited" or String(troop_events[0].get("detail", "")).find("0 -> 16") < 0:
			failures.append("recruitment_delta_missing")
		if String(troop_events[1].get("detail", "")).find("A neighboring province") < 0 or String(troop_events[1].get("detail", "")).find("16 -> 24") < 0:
			failures.append("incoming_provenance_missing")
		if String(troop_events[2].get("detail", "")).find("Southern front") < 0 or String(troop_events[2].get("detail", "")).find("24 -> 19") < 0:
			failures.append("outgoing_destination_missing")
	troop_test["remaining_troops"] = 19
	var combat_before: Dictionary = History.snapshot(troop_test)
	troop_test["remaining_troops"] = 8
	History.record_changes(troop_test, combat_before, 3, "Enemy invasion")
	if String((troop_test[History.EVENTS_KEY] as Array).back().get("title", "")) != "Troops lost":
		failures.append("combat_troop_losses_missing")
	var capture_before: Dictionary = History.snapshot(troop_test)
	troop_test["type"] = "enemy"
	troop_test["faction_id"] = 11
	troop_test["remaining_troops"] = 6
	History.record_changes(troop_test, capture_before, 4, "Enemy invasion", "From province North")
	var new_owner_ledger: String = JSON.stringify(troop_test[History.EVENTS_KEY])
	if new_owner_ledger.find("Previous garrison removed") < 0 or new_owner_ledger.find("New garrison established") < 0:
		failures.append("capture_replacement_troops_missing")

	var revolution_before: Dictionary = History.snapshot(p)
	p["faction_id"] = 9000
	History.record_changes(p, revolution_before, 4, "Rebellion", "Happiness collapsed.")
	var rebellion_found: bool = false
	for event_any in p[History.EVENTS_KEY]:
		if String(event_any.get("title", "")) == "Rebellion" and int(event_any.get("turn", -1)) == 4:
			rebellion_found = true
	if not rebellion_found:
		failures.append("rebellion_not_distinguished")

	for i in range(140):
		History.add_event(p, i + 5, "battle", "Test battle", "Testing capacity")
		History.record_happiness(p, i + 5)
	if p[History.EVENTS_KEY].size() != History.MAX_EVENTS:
		failures.append("event_history_unbounded")
	if p[History.HAPPINESS_KEY].size() != History.MAX_HAPPINESS_POINTS:
		failures.append("happiness_history_unbounded")
	if int(p[History.EVENTS_KEY][0]["turn"]) < 40:
		failures.append("event_order_corrupted")
	return {"ok": failures.is_empty(), "failures": failures}
