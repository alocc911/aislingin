extends RefCounted

const SAVE_PATH: String = "user://tutorial_guide_state.cfg"
const SAVE_SECTION: String = "tutorial_guide"
const CONTENT_VERSION: int = 1

const CATEGORY_BASICS: String = "Basics"
const CATEGORY_ENGAGEMENTS: String = "Engagements"
const CATEGORY_UPGRADES: String = "Upgrades"
const CATEGORY_HAZARDS: String = "Hazards"
const CATEGORY_BOSS: String = "Boss"
const CATEGORY_PROGRESS: String = "Progress"

const PRESENTATION_COACH: String = "coach"
const PRESENTATION_NOTE: String = "note"

const GAMEPLAY_TUTORIAL_SCENARIO_ID: String = "opening_two_province"
const GAMEPLAY_TUTORIAL_SKIP_LABEL: String = "Skip Tutorial"
const GAMEPLAY_TUTORIAL_CLEAR_RULE_NEUTRAL_TROOPS_ZERO: String = "neutral_troops_zero"

const GAMEPLAY_TUTORIAL_SCENARIO := {
	"scenario_id": GAMEPLAY_TUTORIAL_SCENARIO_ID,
	"title": "Tutorial",
	"description": "Open on a small grand map with one friendly province and one neutral province. Clear the neutral province by knocking down all of its troops.",
	"skip_button_text": GAMEPLAY_TUTORIAL_SKIP_LABEL,
	"can_skip": true,
	"grand_map": {
		"small_map": true,
		"province_count": 2,
		"friendly_province_count": 1,
		"neutral_province_count": 1,
		"enemy_province_count": 0,
		"boss_enabled": false,
		"force_starting_origin_owner": "friendly",
		"force_starting_origin_index": 0,
		"friendly_province_indices": [0],
		"neutral_province_indices": [1],
		"enemy_province_indices": [],
		"force_no_buildings": true
	},
	"clear_condition": {
		"rule": GAMEPLAY_TUTORIAL_CLEAR_RULE_NEUTRAL_TROOPS_ZERO,
		"province_owner": "neutral",
		"province_index": 1,
		"remaining_troops_at_or_below": 0
	}
}

const FIRST_RUN_SEQUENCE: Array[String] = [
	"grand_map_overview",
	"launch_from_highlighted_province",
	"drag_to_shoot",
	"need_half_to_win",
	"pause_and_field_guide"
]

const NOTE_DEFINITIONS := {
	"grand_map_overview": {
		"key": "grand_map_overview",
		"title": "Grand Map",
		"category": CATEGORY_BASICS,
		"order": 10,
		"presentation": PRESENTATION_COACH,
		"target_id": "header",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "The Grand Map is the campaign layer. Each turn you fire exactly one shot from a friendly province, then the world updates based on what happened in the engagement you entered.",
		"short_body": "This is the campaign layer. One shot per turn, then the map updates."
	},
	"launch_from_highlighted_province": {
		"key": "launch_from_highlighted_province",
		"title": "Launch Province",
		"category": CATEGORY_BASICS,
		"order": 20,
		"presentation": PRESENTATION_COACH,
		"target_id": "world_launch_province",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Your shot must begin inside the highlighted friendly province. On later turns the game can lock you to a specific province, so the glowing province is the legal place to start your next shot.",
		"short_body": "Start the shot inside the highlighted friendly province."
	},
	"drag_to_shoot": {
		"key": "drag_to_shoot",
		"title": "Drag to Aim",
		"category": CATEGORY_BASICS,
		"order": 30,
		"presentation": PRESENTATION_COACH,
		"target_id": "world_drag",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Tap or press where the ball should start, then drag backward from the direction you want to travel. Longer drag means more speed. The preview lines show your direction and projected path.",
		"short_body": "Tap a start point, then drag backward to aim and power the shot."
	},
	"need_half_to_win": {
		"key": "need_half_to_win",
		"title": "What Counts as Success",
		"category": CATEGORY_BASICS,
		"order": 40,
		"presentation": PRESENTATION_COACH,
		"target_id": "stats_slot",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Most engagements are passed by knocking down at least half of the defending troops. The bottom bar keeps the live count so you can tell whether the shot is on pace to succeed.",
		"short_body": "Usually you pass by downing at least half the defenders."
	},
	"pause_and_field_guide": {
		"key": "pause_and_field_guide",
		"title": "Help Is Always Available",
		"category": CATEGORY_BASICS,
		"order": 50,
		"presentation": PRESENTATION_COACH,
		"target_id": "pause_button",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "The first-run tutorial is short on purpose. After this, new mechanics will unlock notes in the Field Guide. Players can reopen the guide from the help or pause area whenever they need a reminder.",
		"short_body": "New mechanics unlock notes in the Field Guide."
	},
	"engagement_types": {
		"key": "engagement_types",
		"title": "Engagement Types",
		"category": CATEGORY_ENGAGEMENTS,
		"order": 110,
		"presentation": PRESENTATION_NOTE,
		"target_id": "stats_slot",
		"starts_unlocked": false,
		"auto_popup_on_unlock": true,
		"body": "Not every engagement follows the same context. Offensive enemy, offensive neutral, and defensive engagements can resolve differently, so always read the header and bottom-bar summary before and after the shot.",
		"short_body": "Read the engagement header. Different engagement types resolve differently."
	},
	"upgrades_and_gold": {
		"key": "upgrades_and_gold",
		"title": "Gold and Upgrades",
		"category": CATEGORY_UPGRADES,
		"order": 210,
		"presentation": PRESENTATION_NOTE,
		"target_id": "shop_block",
		"starts_unlocked": false,
		"auto_popup_on_unlock": true,
		"body": "Gold is earned from campaign progress and performance, then spent in the shop for shot modifiers. Bigger Ball, Heavier Ball, Wind Resistance, Forcefield, and Magnet each change the shot in a different way, so the shop is part of turn planning, not just a bonus screen.",
		"short_body": "Gold buys shot modifiers. The shop changes how your next shot behaves."
	},
	"magnet_placement": {
		"key": "magnet_placement",
		"title": "Magnets",
		"category": CATEGORY_UPGRADES,
		"order": 220,
		"presentation": PRESENTATION_NOTE,
		"target_id": "place_magnet_button",
		"starts_unlocked": false,
		"auto_popup_on_unlock": true,
		"body": "After buying Magnet, press Place Magnet and tap the engagement map to deploy one. Magnets pull the ball during the shot, so they are best used to bend the path through tight lanes or keep the ball circulating through dense defenders.",
		"short_body": "Buy Magnet, press Place Magnet, then tap the engagement map to deploy it."
	},
	"forcefield_upgrade": {
		"key": "forcefield_upgrade",
		"title": "Forcefield",
		"category": CATEGORY_UPGRADES,
		"order": 230,
		"presentation": PRESENTATION_NOTE,
		"target_id": "shop_block",
		"starts_unlocked": false,
		"auto_popup_on_unlock": false,
		"body": "Forcefield adds a visible ring around the ball. It can interact with enemies at reduced strength compared with a direct hit, which makes it good for widening your effective impact radius without replacing clean contact.",
		"short_body": "Forcefield widens your effective hit area around the ball."
	},
	"wind_resistance_upgrade": {
		"key": "wind_resistance_upgrade",
		"title": "Wind Resistance",
		"category": CATEGORY_UPGRADES,
		"order": 240,
		"presentation": PRESENTATION_NOTE,
		"target_id": "shop_block",
		"starts_unlocked": false,
		"auto_popup_on_unlock": false,
		"body": "Wind Resistance ignores wind for a short time after launch. Each level adds 0.1 seconds of wind immunity at the start of the shot.",
		"short_body": "Wind Resistance gives brief wind immunity right after launch."
	},
	"water_and_hazards": {
		"key": "water_and_hazards",
		"title": "Water and Hazards",
		"category": CATEGORY_HAZARDS,
		"order": 310,
		"presentation": PRESENTATION_NOTE,
		"target_id": "world_map",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Water, rocks, and other hazards shape both placement and survival. Water can end the shot, rocks can block legal starting positions, and special hazards can punish poor routes, so safe geometry matters as much as raw power.",
		"short_body": "Map geometry matters. Hazards change where you can start and how the shot ends."
	},
	"defensive_engagements": {
		"key": "defensive_engagements",
		"title": "Defensive Engagements",
		"category": CATEGORY_ENGAGEMENTS,
		"order": 120,
		"presentation": PRESENTATION_NOTE,
		"target_id": "stats_slot",
		"starts_unlocked": false,
		"auto_popup_on_unlock": true,
		"body": "In defensive engagements you are protecting your side rather than clearing an enemy province in the usual way. Friendly buildings matter here, so the live counter and end summary should be read as defense results, not just troop knockdowns.",
		"short_body": "Defense runs care about preserving your side, not just downing enemies."
	},
	"boss_parts": {
		"key": "boss_parts",
		"title": "Boss Body Parts",
		"category": CATEGORY_BOSS,
		"order": 410,
		"presentation": PRESENTATION_NOTE,
		"target_id": "boss_body",
		"starts_unlocked": false,
		"auto_popup_on_unlock": true,
		"body": "Boss encounters are built around separate body parts. Limbs can matter independently from the head, so watch what part you actually struck and read the status summary after the hit to understand what changed on the campaign layer.",
		"short_body": "Boss parts matter individually. Read the hit summary after contact."
	},
	"campaign_upgrade_rewards": {
		"key": "campaign_upgrade_rewards",
		"title": "Campaign Upgrade Rewards",
		"category": CATEGORY_PROGRESS,
		"order": 510,
		"presentation": PRESENTATION_NOTE,
		"target_id": "campaign_upgrade_panel",
		"starts_unlocked": false,
		"auto_popup_on_unlock": true,
		"body": "Conquering a map can grant a permanent upgrade choice. Those choices carry into later maps, so this is where the run starts to become a broader campaign build instead of a single isolated board.",
		"short_body": "Map victory can grant permanent upgrades for later maps."
	}
}

const CATEGORY_ORDER: Array[String] = [
	CATEGORY_BASICS,
	CATEGORY_ENGAGEMENTS,
	CATEGORY_UPGRADES,
	CATEGORY_HAZARDS,
	CATEGORY_BOSS,
	CATEGORY_PROGRESS
]

const EVENT_UNLOCKS := {
	"first_engagement_started": ["engagement_types"],
	"first_upgrade_purchased": ["upgrades_and_gold"],
	"first_magnet_available": ["magnet_placement"],
	"first_forcefield_purchased": ["forcefield_upgrade"],
	"first_poison_purchased": ["wind_resistance_upgrade"],
	"first_defensive_engagement_started": ["defensive_engagements"],
	"first_boss_seen": ["boss_parts"],
	"first_campaign_upgrade_choice": ["campaign_upgrade_rewards"]
}

var _first_run_completed: bool = false
var _gameplay_tutorial_completed: bool = false
var _gameplay_tutorial_skipped: bool = false
var _gameplay_tutorial_in_progress: bool = false
var _unlocked_notes: Dictionary = {}
var _read_notes: Dictionary = {}
var _seen_auto_popups: Dictionary = {}


func setup() -> void:
	_load_state()
	_ensure_default_unlocks()


func should_auto_start_first_run() -> bool:
	if should_auto_start_gameplay_tutorial():
		return false
	return not _first_run_completed


func should_auto_start_gameplay_tutorial() -> bool:
	return not _gameplay_tutorial_completed and not _gameplay_tutorial_skipped


func get_gameplay_tutorial_definition() -> Dictionary:
	var definition: Dictionary = GAMEPLAY_TUTORIAL_SCENARIO.duplicate(true)
	definition["is_completed"] = _gameplay_tutorial_completed
	definition["is_skipped"] = _gameplay_tutorial_skipped
	definition["is_in_progress"] = _gameplay_tutorial_in_progress
	definition["should_auto_start"] = should_auto_start_gameplay_tutorial()
	return definition


func get_gameplay_tutorial_skip_button_text() -> String:
	return GAMEPLAY_TUTORIAL_SKIP_LABEL


func mark_gameplay_tutorial_started() -> void:
	_gameplay_tutorial_in_progress = true


func clear_gameplay_tutorial_runtime_state() -> void:
	_gameplay_tutorial_in_progress = false


func is_gameplay_tutorial_in_progress() -> bool:
	return _gameplay_tutorial_in_progress


func is_gameplay_tutorial_completed() -> bool:
	return _gameplay_tutorial_completed


func was_gameplay_tutorial_skipped() -> bool:
	return _gameplay_tutorial_skipped


func should_show_gameplay_tutorial_skip_button() -> bool:
	return _gameplay_tutorial_in_progress and should_auto_start_gameplay_tutorial()


func is_gameplay_tutorial_clear_condition_met(neutral_troops_remaining: int) -> bool:
	if not _gameplay_tutorial_in_progress:
		return false
	return neutral_troops_remaining <= 0


func mark_gameplay_tutorial_completed() -> void:
	_gameplay_tutorial_completed = true
	_gameplay_tutorial_skipped = false
	_gameplay_tutorial_in_progress = false
	mark_first_run_complete()


func mark_gameplay_tutorial_skipped() -> void:
	_gameplay_tutorial_completed = false
	_gameplay_tutorial_skipped = true
	_gameplay_tutorial_in_progress = false
	mark_first_run_complete()


func reset_gameplay_tutorial_progress_for_testing() -> void:
	_gameplay_tutorial_completed = false
	_gameplay_tutorial_skipped = false
	_gameplay_tutorial_in_progress = false
	_first_run_completed = false
	_save_state()


func get_first_run_sequence() -> Array[Dictionary]:
	var sequence: Array[Dictionary] = []
	for i in range(FIRST_RUN_SEQUENCE.size()):
		var note_key: String = String(FIRST_RUN_SEQUENCE[i])
		var entry: Dictionary = get_note(note_key)
		if entry.is_empty():
			continue
		entry["step_index"] = i + 1
		entry["step_count"] = FIRST_RUN_SEQUENCE.size()
		sequence.append(entry)
	return sequence


func mark_first_run_complete() -> void:
	_first_run_completed = true
	for note_key in FIRST_RUN_SEQUENCE:
		_unlock_note(String(note_key))
		mark_note_read(String(note_key))
	_save_state()


func clear_first_run_complete_for_testing() -> void:
	_first_run_completed = false
	_save_state()


func get_note(note_key: String) -> Dictionary:
	if not NOTE_DEFINITIONS.has(note_key):
		return {}
	return (NOTE_DEFINITIONS[note_key] as Dictionary).duplicate(true)


func has_note(note_key: String) -> bool:
	return NOTE_DEFINITIONS.has(note_key)


func is_note_unlocked(note_key: String) -> bool:
	return _unlocked_notes.has(note_key)


func is_note_read(note_key: String) -> bool:
	return _read_notes.has(note_key)


func unlock_notes_for_event(event_key: String) -> Array[Dictionary]:
	var auto_popup_entries: Array[Dictionary] = []
	if not EVENT_UNLOCKS.has(event_key):
		return auto_popup_entries

	var unlock_keys: Array = EVENT_UNLOCKS[event_key]
	for raw_key in unlock_keys:
		var note_key: String = String(raw_key)
		if not NOTE_DEFINITIONS.has(note_key):
			continue
		var was_newly_unlocked: bool = not _unlocked_notes.has(note_key)
		_unlock_note(note_key)
		if not was_newly_unlocked:
			continue
		var entry: Dictionary = get_note(note_key)
		if bool(entry.get("auto_popup_on_unlock", false)) and not _seen_auto_popups.has(note_key):
			_seen_auto_popups[note_key] = true
			auto_popup_entries.append(entry)
	_save_state()
	return auto_popup_entries


func mark_note_read(note_key: String) -> void:
	if note_key.strip_edges() == "":
		return
	if not NOTE_DEFINITIONS.has(note_key):
		return
	_unlock_note(note_key)
	_read_notes[note_key] = true
	_save_state()


func mark_auto_popup_seen(note_key: String) -> void:
	if note_key.strip_edges() == "":
		return
	if not NOTE_DEFINITIONS.has(note_key):
		return
	_seen_auto_popups[note_key] = true
	_save_state()


func get_unread_unlocked_note_count() -> int:
	var count: int = 0
	for note_key in _unlocked_notes.keys():
		if not _read_notes.has(note_key):
			count += 1
	return count


func get_unlocked_note_count() -> int:
	return _unlocked_notes.size()


func get_field_guide_sections() -> Array[Dictionary]:
	var sections: Array[Dictionary] = []
	for category_name in CATEGORY_ORDER:
		var category_entries: Array[Dictionary] = []
		for note_key in NOTE_DEFINITIONS.keys():
			var entry: Dictionary = NOTE_DEFINITIONS[note_key]
			if String(entry.get("category", "")) != category_name:
				continue
			if not _unlocked_notes.has(note_key):
				continue
			var ui_entry: Dictionary = entry.duplicate(true)
			ui_entry["is_unlocked"] = true
			ui_entry["is_read"] = _read_notes.has(note_key)
			ui_entry["is_first_run_step"] = FIRST_RUN_SEQUENCE.has(note_key)
			category_entries.append(ui_entry)
		if category_entries.is_empty():
			continue
		category_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("order", 0)) < int(b.get("order", 0))
		)
		sections.append({
			"category": category_name,
			"entries": category_entries
		})
	return sections


func get_all_known_note_keys() -> Array[String]:
	var keys: Array[String] = []
	for note_key in NOTE_DEFINITIONS.keys():
		keys.append(String(note_key))
	keys.sort()
	return keys


func reset_all_progress_for_testing() -> void:
	_first_run_completed = false
	_gameplay_tutorial_completed = false
	_gameplay_tutorial_skipped = false
	_gameplay_tutorial_in_progress = false
	_unlocked_notes.clear()
	_read_notes.clear()
	_seen_auto_popups.clear()
	_ensure_default_unlocks()
	_save_state()


func _ensure_default_unlocks() -> void:
	for note_key in NOTE_DEFINITIONS.keys():
		var entry: Dictionary = NOTE_DEFINITIONS[note_key]
		if bool(entry.get("starts_unlocked", false)):
			_unlock_note(String(note_key), false)


func _unlock_note(note_key: String, save_after: bool = true) -> void:
	if note_key.strip_edges() == "":
		return
	if not NOTE_DEFINITIONS.has(note_key):
		return
	_unlocked_notes[note_key] = true
	if save_after:
		_save_state()


func _load_state() -> void:
	_first_run_completed = false
	_gameplay_tutorial_completed = false
	_gameplay_tutorial_skipped = false
	_gameplay_tutorial_in_progress = false
	_unlocked_notes.clear()
	_read_notes.clear()
	_seen_auto_popups.clear()

	var cfg := ConfigFile.new()
	var err: int = cfg.load(SAVE_PATH)
	if err != OK:
		return

	var stored_version: int = int(cfg.get_value(SAVE_SECTION, "content_version", 0))
	if stored_version != CONTENT_VERSION:
		return

	_first_run_completed = bool(cfg.get_value(SAVE_SECTION, "first_run_completed", false))
	_gameplay_tutorial_completed = bool(cfg.get_value(SAVE_SECTION, "gameplay_tutorial_completed", false))
	_gameplay_tutorial_skipped = bool(cfg.get_value(SAVE_SECTION, "gameplay_tutorial_skipped", false))
	_unlocked_notes = _array_to_set(cfg.get_value(SAVE_SECTION, "unlocked_notes", []))
	_read_notes = _array_to_set(cfg.get_value(SAVE_SECTION, "read_notes", []))
	_seen_auto_popups = _array_to_set(cfg.get_value(SAVE_SECTION, "seen_auto_popups", []))


func _save_state() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_SECTION, "content_version", CONTENT_VERSION)
	cfg.set_value(SAVE_SECTION, "first_run_completed", _first_run_completed)
	cfg.set_value(SAVE_SECTION, "gameplay_tutorial_completed", _gameplay_tutorial_completed)
	cfg.set_value(SAVE_SECTION, "gameplay_tutorial_skipped", _gameplay_tutorial_skipped)
	cfg.set_value(SAVE_SECTION, "unlocked_notes", _set_to_sorted_array(_unlocked_notes))
	cfg.set_value(SAVE_SECTION, "read_notes", _set_to_sorted_array(_read_notes))
	cfg.set_value(SAVE_SECTION, "seen_auto_popups", _set_to_sorted_array(_seen_auto_popups))
	cfg.save(SAVE_PATH)


func _array_to_set(values: Variant) -> Dictionary:
	var result: Dictionary = {}
	if values is Array:
		for value in values:
			var key: String = String(value)
			if key.strip_edges() == "":
				continue
			result[key] = true
	return result


func _set_to_sorted_array(set_dict: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key in set_dict.keys():
		keys.append(String(key))
	keys.sort()
	return keys
