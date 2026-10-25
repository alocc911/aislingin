extends RefCounted
# Compact, per-province history stored on the persistence dictionary. No polling or global log.
const MAX_EVENTS: int = 100
const MAX_HAPPINESS_POINTS: int = 100
const EVENTS_KEY := "history_events"
const HAPPINESS_KEY := "history_happiness"

static func add_event(province: Dictionary, turn: int, category: String, title: String, detail: String) -> void:
	if int(province.get("id", -1)) < 0:
		return
	var events: Array = province.get(EVENTS_KEY, [])
	events.append({"turn": turn, "category": category, "title": title, "detail": detail})
	while events.size() > MAX_EVENTS:
		events.pop_front()
	province[EVENTS_KEY] = events


static func record_troop_change(province: Dictionary, turn: int, before: int, after: int, reason: String, origin: String = "", destination: String = "") -> void:
	if before == after:
		return
	var difference: int = after - before
	var title: String = "Troops gained" if difference > 0 else "Troops lost"
	var explanation: String = ""
	if difference > 0 and origin != "":
		title = "Reinforcements arrived"
		explanation = "%d troops arrived from %s." % [difference, origin]
	elif difference < 0 and destination != "":
		title = "Troops departed"
		explanation = "%d troops marched to %s." % [-difference, destination]
	elif difference > 0 and reason.to_lower().find("recruit") >= 0:
		title = "Troops recruited"
		explanation = "%d troops recruited locally." % difference
	elif difference > 0:
		explanation = "%d troops added to the garrison." % difference
	else:
		explanation = "%d troops removed from the garrison." % -difference
	explanation += " Garrison: %d -> %d. Cause: %s." % [before, after, reason]
	add_event(province, turn, "troops", title, explanation)


static func record_happiness(province: Dictionary, turn: int) -> void:
	if turn < 0 or int(province.get("id", -1)) < 0:
		return
	var happiness: Dictionary = province.get("happiness", {})
	if happiness.is_empty():
		return
	var points: Array = province.get(HAPPINESS_KEY, [])
	var entry: Dictionary = {
		"turn": turn,
		"natives": clampf(float(happiness.get("natives", 0.0)), 0.0, 100.0),
		"outlanders": clampf(float(happiness.get("outlanders", 0.0)), 0.0, 100.0)
	}
	# Repeated ticks in one game turn replace that turn's point, not append spam.
	if not points.is_empty() and int(points.back().get("turn", -1)) == turn:
		points[points.size() - 1] = entry
	else:
		points.append(entry)
	while points.size() > MAX_HAPPINESS_POINTS:
		points.pop_front()
	province[HAPPINESS_KEY] = points


static func snapshot(province: Dictionary) -> Dictionary:
	return {
		"type": String(province.get("type", "neutral")),
		"faction_id": int(province.get("faction_id", 0)) if String(province.get("type", "")) == "enemy" else 0,
		"buildings": (province.get("buildings", {}) as Dictionary).duplicate(true),
		"remaining_buildings": int(province.get("remaining_buildings", 0)),
		"remaining_troops": int(province.get("remaining_troops", 0))
	}


static func owner_label(owner_type: String, faction_id: int) -> String:
	if owner_type == "friendly":
		return "Player"
	if owner_type == "neutral":
		return "Neutral"
	if faction_id == 9000:
		return "Rebels"
	if owner_type == "enemy":
		return "Enemy faction %d" % faction_id
	return owner_type.capitalize()


static func _building_totals(buildings: Dictionary) -> Dictionary:
	var totals: Dictionary = {}
	for building_type in buildings:
		var tiers: Variant = buildings[building_type]
		if not (tiers is Dictionary):
			continue
		for tier in (tiers as Dictionary):
			var number: int = maxi(0, int(tiers[tier]))
			if number > 0:
				totals["%s T%s" % [String(building_type).replace("_", " ").capitalize(), str(tier)]] = number
	return totals


static func record_changes(province: Dictionary, before: Dictionary, turn: int, cause: String, detail: String = "") -> Dictionary:
	var old_type: String = String(before.get("type", "neutral"))
	var old_faction: int = int(before.get("faction_id", 0)) if old_type == "enemy" else 0
	var new_type: String = String(province.get("type", "neutral"))
	var new_faction: int = int(province.get("faction_id", 0)) if new_type == "enemy" else 0
	var result: Dictionary = {}
	if old_type != new_type or old_faction != new_faction:
		var from_owner: String = owner_label(old_type, old_faction)
		var to_owner: String = owner_label(new_type, new_faction)
		var title: String = "Rebellion" if cause == "Rebellion" else "Ownership changed"
		var description: String = "%s -> %s. Cause: %s." % [from_owner, to_owner, cause]
		if detail.strip_edges() != "":
			description += " " + detail
		add_event(province, turn, "ownership", title, description)
		if old_type == "friendly" and new_type != "friendly":
			result = {
				"province_id": int(province.get("id", -1)),
				"title": title,
				"detail": description,
				"cause": cause
			}

	# Garrison changes are recorded even when battle/ownership events already exist.
	# Economy recruitment is recorded at its actual application sites so that
	# construction and recruitment gains never get conflated with combat damage.
	var old_troops: int = int(before.get("remaining_troops", 0))
	var new_troops: int = int(province.get("remaining_troops", 0))
	if cause != "Construction":
		if old_type != new_type or old_faction != new_faction:
			if old_troops > 0:
				add_event(province, turn, "troops", "Previous garrison removed", "%d troops of %s ceased defending this province. Cause: %s. %s" % [old_troops, owner_label(old_type, old_faction), cause, detail])
			if new_troops > 0:
				add_event(province, turn, "troops", "New garrison established", "%d troops now hold the province for %s following %s. %s" % [new_troops, owner_label(new_type, new_faction), cause, detail])
		else:
			record_troop_change(province, turn, old_troops, new_troops, cause)

	var old_totals: Dictionary = _building_totals(before.get("buildings", {}))
	var new_totals: Dictionary = _building_totals(province.get("buildings", {}))
	var names: Dictionary = {}
	for name in old_totals:
		names[name] = true
	for name in new_totals:
		names[name] = true
	var changes: Array[String] = []
	for name in names:
		var delta: int = int(new_totals.get(name, 0)) - int(old_totals.get(name, 0))
		if delta != 0:
			changes.append("%s %s%d" % [String(name), "+" if delta > 0 else "", delta])
	if changes.is_empty() and old_totals.is_empty() and new_totals.is_empty():
		var legacy_delta: int = int(province.get("remaining_buildings", 0)) - int(before.get("remaining_buildings", 0))
		if legacy_delta != 0:
			changes.append("Structures %s%d" % ["+" if legacy_delta > 0 else "", legacy_delta])
	if not changes.is_empty():
		changes.sort()
		var building_title: String = "Buildings changed"
		if cause == "Construction":
			building_title = "Construction completed"
		elif cause == "Rebellion":
			building_title = "Buildings reset by rebellion"
		elif cause.to_lower().find("attack") != -1 or cause.to_lower().find("invasion") != -1 or cause == "Combat" or cause == "Boss attack" or cause.to_lower().find("engagement") != -1:
			building_title = "Buildings damaged in combat"
		add_event(province, turn, "buildings", building_title, ", ".join(changes) + ". " + (detail if detail != "" else "Cause: " + cause + "."))
	return result
