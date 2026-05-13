extends Node2D
"""
Main coordinator for Sunny Slopes.

Owns shared runtime state, scene references, helper setup, and top-level
loop/orchestration. Gameplay subsystems live in the helper scripts.

NEW MULTI-FACTION ENEMY SYSTEM (March 2026):
- ENEMY_FACTION_COUNT (set in LevelConfig.gd) controls how many enemy factions exist.
- When > 1, enemy provinces of DIFFERENT factions will invade each other on the Grand Map
  using the exact rules you specified: 1-for-1 troop attrition first, then surviving invaders
  destroy buildings (1 troop = 1/3 building floored), full conquest switches faction and gives
  2 buildings + leftover troops.
- Same-faction enemies treat each other as friendly (no invasion).
- Player conquest always turns any enemy province friendly (faction cleared).
- All other logic (pins, ball, camera, UI, etc.) is completely unchanged.

UNIFIED ENGAGEMENTS (March 2026):
- All offensive / defensive / neutral logic removed.
- Every engagement now goes through EngagementResolver.resolve_engagement() with a clean input dict.
- Player results (downed troops + destroyed buildings) + province context determine everything deterministically.
- Non-player invasions still use the exact same 1-for-1 + building damage rules.
"""

const LevelConfig = preload("res://scripts/LevelConfig.gd")
const LevelGenerator = preload("res://scripts/LevelGenerator.gd")
const MainLevelFlowScript = preload("res://scripts/MainLevelFlow.gd")
const ProvinceSystemScript = preload("res://scripts/ProvinceSystem.gd")
const EnemyTurnSystemScript = preload("res://scripts/EnemyTurnSystem.gd")
const EngagementResolverScript = preload("res://scripts/EngagementResolver.gd")
const InputControllerScript = preload("res://scripts/InputController.gd")
const CameraControllerScript = preload("res://scripts/CameraController.gd")
const BossSystemScript = preload("res://scripts/BossSystem.gd")
const MainUIBridgeScript = preload("res://scripts/MainUIBridge.gd")
const TutorialGuideScript = preload("res://scripts/TutorialGuide.gd")

@onready var camera_2d: Camera2D = $Camera2D
@onready var zones_root: Node2D = $World/Zones
@onready var obstacles_root: Node2D = $World/Obstacles
@onready var pins_root: Node2D = $World/Pins
@onready var provinces_root: Node2D = $World/Provinces
@onready var ball_holder: Node2D = $World/BallHolder
@onready var ui = $UIOverlay
@onready var bounds_root: Node2D = $World/Bounds
@onready var wall_top: StaticBody2D = $World/Bounds/WallTop
@onready var wall_bottom: StaticBody2D = $World/Bounds/WallBottom
@onready var wall_left: StaticBody2D = $World/Bounds/WallLeft
@onready var wall_right: StaticBody2D = $World/Bounds/WallRight
@onready var wall_top_shape: CollisionShape2D = $World/Bounds/WallTop/CollisionShape2D
@onready var wall_bottom_shape: CollisionShape2D = $World/Bounds/WallBottom/CollisionShape2D
@onready var wall_left_shape: CollisionShape2D = $World/Bounds/WallLeft/CollisionShape2D
@onready var wall_right_shape: CollisionShape2D = $World/Bounds/WallRight/CollisionShape2D

const GLOBAL_SAND_TILE_BACKDROP_NAME: String = "GlobalSandTileBackdrop"
const OWNERSHIP_PERSISTENCE_SCHEMA_VERSION: int = 2
const OWNERSHIP_PERSISTENCE_SCHEMA_VERSION_LEGACY: int = 1

var aim_line: Line2D
var projection_line: Line2D
var preview_ball: RigidBody2D = null
var ball: RigidBody2D = null

enum GameState { GRAND_MAP, DRAGGING, BALL_IN_FLIGHT, ENGAGEMENT, LEVEL_END, GAME_OVER }
enum DragSource { NONE, TOUCH, MOUSE }

var state: GameState = GameState.GRAND_MAP
var drag_source: DragSource = DragSource.NONE
var is_paused: bool = false

var level_index: int = 1
var map_seed: int = 0
var turn_number: int = 1
var _grand_map_generation_level: int = 1
var gold_balance: int = 0

var campaign_level_progress: int = 1
var campaign_selected_level_mode: String = LevelConfig.CAMPAIGN_LEVEL_MODE_EASY
var campaign_last_completed_level_mode: String = ""
var campaign_total_cleared_levels: int = 0
var campaign_total_easy_clears: int = 0
var campaign_total_hard_clears: int = 0
var campaign_total_boss_progress_steps: int = 0
var campaign_enemy_troop_level_bonus_total: int = 0
var campaign_debug_bonus_gold_per_turn: int = 0
var campaign_boss_defensive_bonus_map: Dictionary = {}
var campaign_boss_offensive_bonus_map: Dictionary = {}
var campaign_between_level_summary_text: String = ""
var campaign_permanent_upgrade_points_unspent: int = 0
var campaign_permanent_upgrade_discount_map: Dictionary = {}
var _awaiting_campaign_level_mode_choice: bool = false
var _awaiting_pre_level_debug_config_choice: bool = false
var _pending_campaign_level_choice_summary_text: String = ""
var _pending_campaign_upgrade_summary_text: String = ""
var _campaign_level_boss_spawn_committed: bool = false

var bigger_count: int = 0
var heavier_count: int = 0
var poison_count: int = 0
var forcefield_count: int = 0
var magnet_count: int = 0

var permanent_bigger_count: int = 0
var permanent_heavier_count: int = 0
var permanent_poison_count: int = 0
var permanent_forcefield_count: int = 0
var permanent_magnet_count: int = 0
var _economy_initialized_turn: int = -1

var dragging: bool = false
var drag_pointer_id: int = -1
var drag_anchor_world: Vector2 = Vector2.ZERO
var drag_current_world: Vector2 = Vector2.ZERO
var _mouse_drag_start_screen: Vector2 = Vector2.ZERO
var _mouse_drag_start_msec: int = 0

const MIN_DRAG_THRESHOLD_PIXELS: float = 18.0
const WALL_GRACE_SECONDS: float = 0.28
const SETTLE_DELAY_SECONDS: float = 2.0
const PINS_UI_REFRESH_INTERVAL: float = 0.12
const IDLE_MAP_THROTTLE_INTERVAL_SECONDS: float = 0.12

var _last_move_time: float = 0.0
var _is_auto_charging: bool = false
var _wall_grace_end_time: float = 0.0
var _drag_pending: bool = false
var _drag_potential_start_screen: Vector2 = Vector2.ZERO
var _last_drag_screen_pos: Vector2 = Vector2.ZERO
var _virtual_screen_pos: Vector2 = Vector2.ZERO
var _final_launch_radius: float = 0.0
var _final_launch_velocity: Vector2 = Vector2.ZERO
var _preview_radius: float = 0.0
var _preview_velocity: Vector2 = Vector2.ZERO

var rest_timer: float = 1.0
var settle_timer: float = 2.0
var flight_timer: float = 8.0
var _pins_ui_accum: float = 0.0
var _idle_map_throttle_accum: float = 0.0
var _ui_low_motion_applied: bool = false

var generator: LevelGenerator
var level_flow = null
var province_system = null
var enemy_turn_system = null
var engagement_resolver = null
var input_controller = null
var camera_controller = null
var boss_system = null
var ui_bridge = null
var tutorial_guide: RefCounted = null
var _opening_gameplay_tutorial_session_started: bool = false
var _opening_gameplay_tutorial_session_consumed: bool = false

var _shake_amount: float = 0.0
var _shake_timer: float = 0.0

var _initial_pin_count: int = 0
var _current_phase: String = "grand_map"
var _hit_location: String = ""

var camera_pan_offset: Vector2 = Vector2.ZERO
var current_camera_zoom: float = 1.0
var _saved_grand_map_pan_offset: Vector2 = Vector2.ZERO
var _saved_grand_map_zoom: float = 1.0
var _has_saved_grand_map_camera: bool = false
var pan_dragging: bool = false
var pan_drag_start_screen: Vector2 = Vector2.ZERO
var pan_drag_start_offset: Vector2 = Vector2.ZERO
var pan_drag_pointer_ids: Array[int] = []
var pan_drag_pointer_positions: Dictionary = {}
var _grand_map_fit_zoom: float = 0.0
var _current_wall_center_half_extents: Vector2 = LevelConfig.WORLD_HALF_EXTENTS
var _current_playable_half_extents: Vector2 = LevelConfig.WORLD_HALF_EXTENTS - Vector2(LevelConfig.WORLD_WALL_THICKNESS * 0.5, LevelConfig.WORLD_WALL_THICKNESS * 0.5)
var _last_touch_distance: float = 0.0
var _last_touch_midpoint: Vector2 = Vector2.ZERO
var _camera_follow_active: bool = false
var _total_active_touches: int = 0
var _post_launch_input_lock_until: float = 0.0
var _right_mouse_pan_active: bool = false
var _input_locked_until: float = 0.0

var _destroyed_buildings_this_level: int = 0
var _engagement_initial_buildings: int = 0

var _poison_live_touched_pins: Dictionary = {}
var _poison_probe_ball_instance_id: int = -1
var _poison_probe_last_ball_pos: Vector2 = Vector2.ZERO
var _poison_probe_has_last_ball_pos: bool = false
var _active_pin_scan_cache: Array = []
var _active_pin_scan_cache_dirty: bool = true
var _magnet_placement_armed: bool = false

var _province_persistence: Array[Dictionary] = []
var _province_persistence_schema_version: int = OWNERSHIP_PERSISTENCE_SCHEMA_VERSION
const FRIENDLY_MARCH_THRESHOLD: int = LevelConfig.FRIENDLY_MARCH_THRESHOLD
const ENEMY_MARCH_THRESHOLD: int = LevelConfig.ENEMY_MARCH_THRESHOLD
const BOSS_MARCH_THRESHOLD: int = LevelConfig.BOSS_MARCH_THRESHOLD
const ENEMY_MARCH_LEAVE_BEHIND: int = LevelConfig.ENEMY_MARCH_LEAVE_BEHIND
const INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT: int = 3

var _locked_province_id_after_win: int = -1
var _active_engagement_province_id: int = -1

var _last_ball_end_world_pos: Vector2 = Vector2.ZERO
var _has_last_ball_end_world_pos: bool = false
var _last_ball_end_reason: String = ""
var _campaign_transition_in_progress: bool = false
var _pending_campaign_completion_status_text: String = ""
var _campaign_loop_depth: int = 0
var _awaiting_campaign_upgrade_choice: bool = false
var _pending_boss_part_hit: String = ""
var _pending_boss_damage_status_text: String = ""
var _pending_boss_grand_map_shot_status_lines: Array[String] = []
var _boss_home_assault_active: bool = false
var _boss_home_assault_province_id: int = -1
var _boss_home_assault_troop_count: int = 0
var _skip_to_end_running: bool = false
var _skip_to_end_cancel_requested: bool = false
var _skip_to_end_suppress_terminal_resolution: bool = false
const SKIP_TO_END_TRACE_LOG_PATH: String = "user://skip_to_end_trace.log"
const BUG_REPORT_LOG_PATH: String = "user://bug_reports.log"
const BUG_RING_BUFFER_MAX_EVENTS: int = 240

# Legacy flags kept for smooth transition (will be removed after full rollout)
var _awaiting_engagement_summary_ack: bool = false
var _pending_post_summary_status_text: String = ""
var _pending_post_summary_lock_province_id: int = -1
var _pending_post_summary_enemy_turns: int = 0
var _pending_post_summary_skip_province_id: int = -1
var _pending_post_summary_preexisting_invaded_ids: Array[int] = []
var _friendly_boss_assist_phase_active: bool = false
var _friendly_boss_assist_province_id: int = -1
var _bug_black_box_events: Array[Dictionary] = []
var _friendly_boss_debug_turns: Array[Dictionary] = []
var _friendly_boss_debug_tick_counter: int = 0
var _troop_debug_turns: Array[Dictionary] = []
var _troop_debug_tick_counter: int = 0
var _troop_debug_previous_end_snapshot: Dictionary = {}


func get_friendly_march_threshold() -> int:
	return maxi(1, FRIENDLY_MARCH_THRESHOLD)


func get_enemy_march_threshold() -> int:
	return maxi(1, ENEMY_MARCH_THRESHOLD)


func get_boss_march_threshold() -> int:
	return maxi(1, BOSS_MARCH_THRESHOLD)


func get_enemy_march_leave_behind() -> int:
	return maxi(0, ENEMY_MARCH_LEAVE_BEHIND)


func record_black_box_event(event_name: String, details: Dictionary = {}) -> void:
	var entry: Dictionary = {
		"t_ms": Time.get_ticks_msec(),
		"event": event_name,
		"state": int(state),
		"phase": String(_current_phase),
		"turn": turn_number,
		"level": level_index,
		"details": details.duplicate(true)
	}
	_bug_black_box_events.append(entry)
	if _bug_black_box_events.size() > BUG_RING_BUFFER_MAX_EVENTS:
		_bug_black_box_events.remove_at(0)


func _vec2_to_array(v: Vector2) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001)]


func _build_ghost_replay_frames() -> Array[Dictionary]:
	var frames: Array[Dictionary] = []
	if ball == null or not is_instance_valid(ball):
		return frames
	if not ball.has_method("get_trail_points"):
		return frames
	var trail_variant: Variant = ball.call("get_trail_points")
	if not (trail_variant is Array):
		return frames
	var trail: Array = trail_variant
	if trail.is_empty():
		return frames
	var velocity: Vector2 = ball.linear_velocity
	var angular_velocity: float = float(ball.angular_velocity)
	for i in range(trail.size()):
		var p_variant: Variant = trail[i]
		if not (p_variant is Vector2):
			continue
		var p: Vector2 = p_variant
		frames.append({
			"i": i,
			"ball_pos": _vec2_to_array(p),
			"ball_linear_velocity": _vec2_to_array(velocity),
			"ball_angular_velocity": snappedf(angular_velocity, 0.001)
		})
	return frames


func _build_ghost_replay_pin_snapshot() -> Array[Dictionary]:
	var pins: Array[Dictionary] = []
	if pins_root == null or not is_instance_valid(pins_root):
		return pins
	for child in pins_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if not (child is Node2D):
			continue
		var pin_node: Node2D = child as Node2D
		var standing: bool = false
		if pin_node.has_method("is_standing"):
			standing = bool(pin_node.call("is_standing"))
		pins.append({
			"name": pin_node.name,
			"standing": standing,
			"position": _vec2_to_array(pin_node.global_position),
			"rotation": snappedf(pin_node.global_rotation, 0.001)
		})
	return pins


func _build_replay_token() -> String:
	var payload: Dictionary = {
		"schema_version": 2,
		"mode": "ghost_replay",
		"captured_utc": Time.get_datetime_string_from_system(true, true),
		"session": {
			"seed": map_seed,
			"turn": turn_number,
			"level": level_index,
			"phase": String(_current_phase),
			"state": int(state),
			"gold": gold_balance,
			"upgrades": {
				"bigger": bigger_count,
				"heavier": heavier_count,
				"poison": poison_count,
				"forcefield": forcefield_count,
				"magnet": magnet_count
			}
		},
		"input_events": _bug_black_box_events.duplicate(true),
		"ghost": {
			"ball_frames": _build_ghost_replay_frames(),
			"pin_snapshot": _build_ghost_replay_pin_snapshot()
		}
	}
	return Marshalls.raw_to_base64(JSON.stringify(payload).to_utf8_buffer())


func _build_data_dump() -> Dictionary:
	return {
		"schema_version": 1,
		"ownership_persistence_schema_version": _province_persistence_schema_version,
		"captured_utc": Time.get_datetime_string_from_system(true, true),
		"build": ProjectSettings.get_setting("application/config/version", "dev"),
		"session": {
			"seed": map_seed,
			"turn": turn_number,
			"level": level_index,
			"phase": String(_current_phase),
			"state": int(state),
			"gold_balance": gold_balance
		},
		"deterministic_replay_token": _build_replay_token(),
		"recent_events": _bug_black_box_events.duplicate(true)
	}


func get_province_persistence_schema_version() -> int:
	return maxi(OWNERSHIP_PERSISTENCE_SCHEMA_VERSION_LEGACY, int(_province_persistence_schema_version))


func set_province_persistence_schema_version(version: int) -> void:
	_province_persistence_schema_version = maxi(OWNERSHIP_PERSISTENCE_SCHEMA_VERSION_LEGACY, int(version))


func _on_data_dump_requested() -> void:
	print("[BugReportFlow][Main] _on_data_dump_requested entered.")
	record_black_box_event("ui_data_dump_requested")
	var dump: Dictionary = _build_data_dump()
	var dump_text: String = JSON.stringify(dump, "\t")
	print("[BugReportFlow][Main] Built data dump; length=%d." % dump_text.length())
	DisplayServer.clipboard_set(dump_text)
	var file := FileAccess.open("user://bug_dump_latest.json", FileAccess.WRITE)
	if file != null:
		file.store_string(dump_text)
		print("[BugReportFlow][Main] Wrote user://bug_dump_latest.json.")
	else:
		print("[BugReportFlow][Main] Failed to open user://bug_dump_latest.json for write.")
	if ui != null and ui.has_method("open_bug_report_wizard"):
		print("[BugReportFlow][Main] Calling ui.open_bug_report_wizard.")
		ui.call("open_bug_report_wizard", dump_text)
	else:
		print("[BugReportFlow][Main] UI missing or open_bug_report_wizard unavailable.")


func _on_bug_report_submitted(report_payload: Dictionary) -> void:
	record_black_box_event("bug_report_submitted", {"title": String(report_payload.get("title", ""))})
	var combined: Dictionary = {
		"report": report_payload.duplicate(true),
		"dump": _build_data_dump()
	}
	var file := FileAccess.open(BUG_REPORT_LOG_PATH, FileAccess.WRITE_READ)
	if file != null:
		file.seek_end()
		file.store_line(JSON.stringify(combined))


func _record_friendly_boss_turn_debug(turn_value: int, log_lines: Array[String]) -> void:
	var friendly_lines: Array[String] = []
	var troop_lines: Array[String] = []
	var move_plan_line: String = ""
	var move_result_line: String = ""
	var lifecycle_events: Array[String] = []
	var has_no_active_boss_line: bool = false
	for line in log_lines:
		var text: String = String(line)
		if text.begins_with("Friendly boss move plan:"):
			move_plan_line = text
		elif text.begins_with("Friendly boss move result:"):
			move_result_line = text
		if text.find("no active friendly boss was found") != -1:
			has_no_active_boss_line = true
		if text.find("Friendly boss move debug:") != -1 or text.find("Friendly boss move result:") != -1:
			lifecycle_events.append(text)
		if text.find("Friendly boss") != -1 or text.find("friendly boss") != -1 or text.find("Boss-home march debug") != -1 or text.find(" moved ") != -1:
			friendly_lines.append(text)
		if text.find(" moved ") != -1 and text.find(" troops from ") != -1:
			troop_lines.append(text)
	if friendly_lines.is_empty():
		if log_lines.is_empty():
			friendly_lines.append("No automated engagement events were recorded for this turn.")
		else:
			friendly_lines.append("No boss-related movement events matched the debug filter this turn.")
	_friendly_boss_debug_tick_counter += 1
	_friendly_boss_debug_turns.append({
		"turn": turn_value,
		"tick_id": _friendly_boss_debug_tick_counter,
		"lines": friendly_lines,
		"move_plan_line": move_plan_line,
		"move_result_line": move_result_line,
		"lifecycle_events": lifecycle_events,
		"lookup_failed_no_active_boss": has_no_active_boss_line
	})
	if _friendly_boss_debug_turns.size() > 64:
		_friendly_boss_debug_turns.remove_at(0)
	_troop_debug_tick_counter += 1
	var end_snapshot: Dictionary = _capture_province_troop_snapshot()
	var start_snapshot: Dictionary = _troop_debug_previous_end_snapshot.duplicate(true)
	if start_snapshot.is_empty() and not end_snapshot.is_empty():
		start_snapshot = end_snapshot.duplicate(true)
	_troop_debug_turns.append({
		"turn": turn_value,
		"tick_id": _troop_debug_tick_counter,
		"lines": troop_lines,
		"start_snapshot": start_snapshot,
		"end_snapshot": end_snapshot
	})
	_troop_debug_previous_end_snapshot = end_snapshot.duplicate(true)
	if _troop_debug_turns.size() > 64:
		_troop_debug_turns.remove_at(0)


func _on_friendly_boss_debug_dump_requested() -> void:
	var out: Array[String] = []
	out.append("Friendly Boss Debug Dump")
	out.append("Captured at: %s" % Time.get_datetime_string_from_system(true, true))
	out.append("Schema: turn/phase envelope + lifecycle hints (v2)")
	var previous_turn: int = -1
	var previous_seen_location: String = "n/a"
	var previous_seen_tick: int = -1
	for entry_any in _friendly_boss_debug_turns:
		var entry: Dictionary = entry_any
		out.append("")
		var turn_number: int = int(entry.get("turn", -1))
		var tick_id: int = int(entry.get("tick_id", -1))
		out.append("Turn %d" % turn_number)
		out.append("- Envelope: turn=%d | phase=end_of_enemy_turn | tick_id=%d" % [turn_number, tick_id])
		if previous_turn >= 0 and turn_number != previous_turn + 1:
			out.append("- Continuity warning: previous turn was %d; expected %d but got %d." % [previous_turn, previous_turn + 1, turn_number])
		var move_plan_line: String = String(entry.get("move_plan_line", ""))
		var move_result_line: String = String(entry.get("move_result_line", ""))
		var plan_fields: Dictionary = _parse_debug_kv_line(move_plan_line)
		var result_fields: Dictionary = _parse_debug_kv_line(move_result_line)
		var start_location: String = String(plan_fields.get("source", "n/a"))
		var start_core_troops: String = String(plan_fields.get("boss_troops", "n/a"))
		var start_other_troops: String = "n/a"
		if plan_fields.has("troops") and plan_fields.has("boss_troops"):
			var total_troops: int = int(plan_fields.get("troops", 0))
			var core_troops: int = int(plan_fields.get("boss_troops", 0))
			start_other_troops = "friendly=%d, enemy=0" % maxi(0, total_troops - core_troops)
		out.append("- Friendly boss location at the start of the turn: %s" % start_location)
		out.append("- Friendly boss hp linked core troops at the start of turn: %s" % start_core_troops)
		out.append("- Other troops in the province he is in (friendly/enemy): %s" % start_other_troops)
		out.append("- Friendly boss movement decision logic: %s" % (move_plan_line if move_plan_line != "" else "n/a"))
		var destination_faction_name: String = _friendly_boss_debug_faction_name(int(result_fields.get("destination_faction", -9999)))
		var destination_total_troops: int = int(result_fields.get("destination_base", 0)) + int(result_fields.get("boss_troops", 0))
		var destination_non_core_troops: int = maxi(0, destination_total_troops - int(result_fields.get("boss_troops", 0)))
		out.append("- Friendly boss movement execution results: Source=%s | Destination=%s | Boss Core HP linked Troops=%s | Destination Type=%s | Destination Faction=%s | Destination Enemy Boss Home=%s | Invasion Pending=%s | Destination Troops (non-core)=%d | Auto-Engagement Results=%s" % [
			String(result_fields.get("source", "n/a")),
			String(result_fields.get("destination", "n/a")),
			String(result_fields.get("boss_troops", "n/a")),
			String(result_fields.get("destination_type", "n/a")),
			destination_faction_name,
			String(result_fields.get("destination_enemy_boss_home", "n/a")),
			String(result_fields.get("invasion_pending", "n/a")),
			destination_non_core_troops,
			(move_result_line if move_result_line != "" else "n/a")
		])
		out.append("- Troop movement in/out of relevant provinces")
		out.append("- Friendly boss location at the end of the turn: %s" % String(result_fields.get("destination", start_location)))
		out.append("- Friendly boss hp linked core troops at the end of turn: %s" % String(result_fields.get("boss_troops", start_core_troops)))
		var lookup_failed_no_active_boss: bool = bool(entry.get("lookup_failed_no_active_boss", false))
		if lookup_failed_no_active_boss:
			out.append("- Cause-coded disappearance diagnostics: last_seen_location=%s | last_seen_tick=%d | registry_contains_id=unknown | province_contains_boss_ref=unknown | faction_boss_pointer=unknown" % [
				previous_seen_location,
				previous_seen_tick
			])
		var lifecycle_any: Variant = entry.get("lifecycle_events", [])
		if lifecycle_any is Array and not (lifecycle_any as Array).is_empty():
			out.append("- Friendly boss lifecycle event stream")
			for event_any in lifecycle_any:
				out.append("  * %s" % String(event_any))
		var lines_any: Variant = entry.get("lines", [])
		if lines_any is Array:
			for line_any in lines_any:
				var line_text: String = String(line_any)
				if line_text.begins_with("Friendly boss move plan:") or line_text.begins_with("Friendly boss move result:"):
					continue
				out.append("  * %s" % line_text)
		var end_location: String = String(result_fields.get("destination", start_location))
		if end_location != "n/a":
			previous_seen_location = end_location
			previous_seen_tick = tick_id
		previous_turn = turn_number
	var payload: String = "\n".join(out)
	DisplayServer.clipboard_set(payload)






func get_live_troop_log_schema_snapshot() -> Dictionary:
	var snapshot_by_province: Dictionary = _capture_province_troop_snapshot()
	var active_boss_id: int = -1
	var active_boss_faction_id: int = -1
	if boss_system != null and boss_system.has_method("get_active_boss_ids"):
		var ids_any: Variant = boss_system.call("get_active_boss_ids")
		if ids_any is Array and not (ids_any as Array).is_empty():
			active_boss_id = int((ids_any as Array)[0])
	if active_boss_id >= 0 and boss_system != null and boss_system.has_method("get_boss_state"):
		var boss_state_any: Variant = boss_system.call("get_boss_state", active_boss_id)
		if boss_state_any is Dictionary:
			active_boss_faction_id = int((boss_state_any as Dictionary).get("faction_id", -1))

	var now_unix: int = int(Time.get_unix_time_from_system())
	var now_ticks: int = int(Time.get_ticks_msec())
	var events: Array = []
	var turns_included: Array[int] = []
	var turn_entries: Array = _troop_debug_turns.duplicate(true)
	if turn_entries.is_empty():
		turn_entries.append({
			"turn": turn_number,
			"start_snapshot": snapshot_by_province.duplicate(true),
			"end_snapshot": snapshot_by_province.duplicate(true)
		})
	for turn_entry_any in turn_entries:
		if not (turn_entry_any is Dictionary):
			continue
		var turn_entry: Dictionary = turn_entry_any
		var entry_turn: int = int(turn_entry.get("turn", turn_number))
		var start_snapshot: Dictionary = turn_entry.get("start_snapshot", {}) as Dictionary
		var end_snapshot: Dictionary = turn_entry.get("end_snapshot", {}) as Dictionary
		var turn_events: Array = _build_live_troop_log_schema_events_for_snapshot_pair(
			start_snapshot,
			end_snapshot,
			entry_turn,
			now_ticks,
			active_boss_id
		)
		if not turn_events.is_empty():
			turns_included.append(entry_turn)
			events.append_array(turn_events)

	var province_ids: Array[int] = []
	for province_id_any in snapshot_by_province.keys():
		province_ids.append(int(province_id_any))
	province_ids.sort()

	return {
		"schema_version": "troop-debug-v1",
		"run_id": "runtime-%d" % now_unix,
		"tick_id": _troop_debug_tick_counter,
		"turn": turn_number,
		"phase": String(_current_phase),
		"subphase": "ui_snapshot",
		"ts_utc": Time.get_datetime_string_from_system(true, true),
		"actor": {
			"type": "boss" if active_boss_id >= 0 else "system",
			"id": active_boss_id,
			"faction_id": active_boss_faction_id
		},
		"bucket_definitions": {
			"garrison": "province stationed troops",
			"invasion_pending": "pending invaders keyed by source"
		},
		"correlation_id": "corr-live-%d-all" % turn_number,
		"event_type": "province_state_delta_batch",
		"province_count": province_ids.size(),
		"turns_included": turns_included,
		"turn_count": turns_included.size(),
		"events": events
	}


func _build_live_troop_log_schema_events_for_snapshot_pair(start_snapshot: Dictionary, end_snapshot: Dictionary, entry_turn: int, now_ticks: int, active_boss_id: int) -> Array:
	var correlation_id: String = "corr-live-%d-all" % entry_turn
	var province_ids: Array[int] = []
	for province_id_any in end_snapshot.keys():
		province_ids.append(int(province_id_any))
	province_ids.sort()
	var events: Array = []
	for province_id in province_ids:
		var province_key: Variant = province_id
		var data: Dictionary = end_snapshot.get(province_key, {}) as Dictionary
		var garrison: int = int(data.get("troops", 0))
		var invading: int = int(data.get("invading_troops", 0))
		var owner_faction_id: int = int(data.get("faction_id", 0))
		var previous_data: Dictionary = start_snapshot.get(province_key, {}) as Dictionary
		var previous_owner_faction_id: int = int(previous_data.get("faction_id", owner_faction_id))
		var previous_garrison: int = int(previous_data.get("troops", garrison))
		var previous_invading: int = int(previous_data.get("invading_troops", invading))
		var event_id: String = "live-%d-%d-%d" % [now_ticks, entry_turn, province_id]
		var troop_buckets: Dictionary = {
			"garrison": garrison,
			"invasion_pending": {
				"aggregate": invading
			}
		}
		var delta: Dictionary = {
			"troop_buckets": {
				"garrison": garrison - previous_garrison,
				"invasion_pending": {
					"aggregate": invading - previous_invading
				}
			},
			"owner_faction_id": owner_faction_id - previous_owner_faction_id
		}
		var ownership_transition: Dictionary = {
			"changed": previous_owner_faction_id != owner_faction_id,
			"previous_owner_faction_id": previous_owner_faction_id,
			"previous_owner_label": _friendly_boss_debug_faction_name(previous_owner_faction_id),
			"new_owner_faction_id": owner_faction_id,
			"new_owner_label": _friendly_boss_debug_faction_name(owner_faction_id)
		}
		events.append({
			"event_id": event_id,
			"correlation_id": correlation_id,
			"event_type": "province_state_delta",
			"order_index": province_id,
			"turn": entry_turn,
			"province": {
				"id": province_id,
				"name": String(data.get("name", "Province %d" % province_id)),
				"selection_reason": "all_provinces"
			},
			"payload": {
				"reason_code": "live_snapshot_all_provinces",
				"snapshot": {
					"owner_faction_id": owner_faction_id,
					"owner_label": _friendly_boss_debug_faction_name(owner_faction_id),
					"occupant_boss_id": active_boss_id,
					"troop_buckets": troop_buckets,
					"derived_totals": {
						"defending_total": garrison,
						"visible_total": garrison + invading
					}
				},
				"delta": delta,
				"ownership_transition": ownership_transition,
				"invariant_checks": [
					{
						"name": "no_negative_visible_totals",
						"status": "pass" if garrison + invading >= 0 else "fail",
						"details": {"visible_total": garrison + invading}
					}
				]
			}
		})
	return events


func _capture_province_troop_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	if _province_persistence is Array and not _province_persistence.is_empty():
		for province_any in _province_persistence:
			if not (province_any is Dictionary):
				continue
			var province_state: Dictionary = province_any
			var province_id: int = int(province_state.get("id", -1))
			if province_id < 0:
				continue
			var province_name: String = "Province %d" % province_id
			if province_system != null and province_system.has_method("get_province_display_name"):
				province_name = String(province_system.call("get_province_display_name", province_id, province_state))
			var fill_color: Color = _get_troop_debug_snapshot_fill_color(province_state, province_id)
			snapshot[province_id] = {
				"name": province_name,
				"troops": maxi(0, int(province_state.get("remaining_troops", province_state.get("troops", 0)))),
				"invading_troops": maxi(0, int(province_state.get("invading_troops", 0))),
				"type": String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
				"faction_id": int(province_state.get("faction_id", 0)),
				"fill_color": _troop_debug_format_color(fill_color)
			}
		return snapshot
	if provinces_root == null or not is_instance_valid(provinces_root):
		return snapshot
	for child in provinces_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if not child.has_meta("province_data"):
			continue
		var province_data: Variant = child.get_meta("province_data")
		if not (province_data is Dictionary):
			continue
		var province_state: Dictionary = province_data
		var province_id: int = int(province_state.get("id", -1))
		if province_id < 0:
			continue
		var fill_color: Color = _get_troop_debug_snapshot_fill_color(province_state, province_id)
		snapshot[province_id] = {
			"name": String(province_state.get("name", "Province %d" % province_id)),
			"troops": maxi(0, int(province_state.get("troops", province_state.get("remaining_troops", 0)))),
			"invading_troops": maxi(0, int(province_state.get("invading_troops", 0))),
			"type": String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)),
			"faction_id": int(province_state.get("faction_id", 0)),
			"fill_color": _troop_debug_format_color(fill_color)
		}
	return snapshot


func _get_troop_debug_snapshot_fill_color(province_state: Dictionary, province_id: int) -> Color:
	if province_system != null and province_system.has_method("_get_cached_province_node_by_id") and province_system.has_method("get_province_fill_node"):
		var province_node_any: Variant = province_system.call("_get_cached_province_node_by_id", province_id)
		if province_node_any is Node and is_instance_valid(province_node_any):
			var fill_node_any: Variant = province_system.call("get_province_fill_node", province_node_any)
			if fill_node_any is Polygon2D and is_instance_valid(fill_node_any):
				return (fill_node_any as Polygon2D).color
	if province_system != null and province_system.has_method("get_base_province_fill_color"):
		return province_system.call("get_base_province_fill_color", province_state, province_id)
	return Color.WHITE


func _troop_debug_format_color(color: Color) -> String:
	return color.to_html(true)


func _troop_debug_owner_type_display(owner_type: String) -> String:
	if owner_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return "friendly"
	if owner_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		return "enemy"
	if owner_type == LevelConfig.PROVINCE_TYPE_NEUTRAL:
		return "neutral"
	return owner_type


func _append_troop_debug_snapshot_lines(out: Array[String], prefix: String, snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		out.append("- %s: unavailable" % prefix)
		return
	var province_ids: Array[int] = []
	for key in snapshot.keys():
		province_ids.append(int(key))
	province_ids.sort()
	out.append("- %s:" % prefix)
	for province_id in province_ids:
		var entry: Dictionary = snapshot.get(province_id, {})
		var province_name: String = String(entry.get("name", "Province %d" % province_id))
		var resident_troops: int = maxi(0, int(entry.get("troops", 0)))
		var invading_troops: int = maxi(0, int(entry.get("invading_troops", 0)))
		var owner_type: String = _troop_debug_owner_type_display(String(entry.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)))
		var faction_id: int = int(entry.get("faction_id", 0))
		var faction_name: String = _friendly_boss_debug_faction_name(faction_id)
		var fill_color: String = String(entry.get("fill_color", _troop_debug_format_color(Color.WHITE)))
		if invading_troops > 0:
			out.append("  * %s: %d (type: %s, faction: %s [%d], fill: #%s, invading: %d)" % [province_name, resident_troops, owner_type, faction_name, faction_id, fill_color, invading_troops])
		else:
			out.append("  * %s: %d (type: %s, faction: %s [%d], fill: #%s)" % [province_name, resident_troops, owner_type, faction_name, faction_id, fill_color])

func _on_troop_debug_dump_requested() -> void:
	var out: Array[String] = []
	out.append("Troop Debug Dump")
	out.append("Captured at: %s" % Time.get_datetime_string_from_system(true, true))
	out.append("Schema: turn-separated troop movement lines + province troop snapshots (v2)")
	var previous_turn: int = -1
	for entry_any in _troop_debug_turns:
		var entry: Dictionary = entry_any
		out.append("")
		var turn_value: int = int(entry.get("turn", -1))
		var tick_id: int = int(entry.get("tick_id", -1))
		out.append("Turn %d" % turn_value)
		out.append("- Envelope: turn=%d | phase=end_of_enemy_turn | tick_id=%d" % [turn_value, tick_id])
		if previous_turn >= 0 and turn_value != previous_turn + 1:
			out.append("- Continuity warning: previous turn was %d; expected %d but got %d." % [previous_turn, previous_turn + 1, turn_value])
		var start_snapshot: Dictionary = entry.get("start_snapshot", {})
		var end_snapshot: Dictionary = entry.get("end_snapshot", {})
		_append_troop_debug_snapshot_lines(out, "Province troops at beginning of turn", start_snapshot)
		_append_troop_debug_snapshot_lines(out, "Province troops at end of turn", end_snapshot)
		var lines_any: Variant = entry.get("lines", [])
		if lines_any is Array and not (lines_any as Array).is_empty():
			for line_any in lines_any:
				out.append("  * %s" % String(line_any))
		else:
			out.append("  * No troop movement lines were recorded this turn.")
		previous_turn = turn_value
	DisplayServer.clipboard_set("\n".join(out))


func _parse_debug_kv_line(line: String) -> Dictionary:
	var fields: Dictionary = {}
	var idx: int = line.find(":")
	if idx < 0:
		return fields
	var body: String = line.substr(idx + 1).strip_edges()
	var segments: PackedStringArray = body.split(" ")
	for segment in segments:
		var eq_index: int = segment.find("=")
		if eq_index <= 0:
			continue
		var key: String = segment.substr(0, eq_index).strip_edges()
		var value: String = segment.substr(eq_index + 1).strip_edges()
		fields[key] = value.trim_suffix(".")
	return fields


func _friendly_boss_debug_faction_name(faction_id: int) -> String:
	if faction_id < 0:
		return "Unknown"
	if faction_id == 0:
		return "Friendly"
	if faction_id == 99:
		return "Enemy 1"
	if faction_id == 100:
		return "Enemy 2"
	if faction_id == 101:
		return "Enemy 3"
	if faction_id == 199:
		return "Friendly Boss"
	return "Faction %d" % faction_id


func get_campaign_current_level_progress() -> int:
	return LevelConfig.clamp_campaign_level_progress(campaign_level_progress)


func get_campaign_total_levels() -> int:
	return LevelConfig.get_campaign_total_levels()


func is_campaign_final_level_active() -> bool:
	return LevelConfig.is_campaign_final_level(get_campaign_current_level_progress())


func get_campaign_selected_level_mode() -> String:
	return LevelConfig.normalize_campaign_level_mode(campaign_selected_level_mode)


func get_campaign_selected_level_mode_display_name() -> String:
	return LevelConfig.get_campaign_level_mode_display_name(get_campaign_selected_level_mode())


func set_campaign_selected_level_mode(level_mode: String) -> void:
	campaign_selected_level_mode = LevelConfig.normalize_campaign_level_mode(level_mode)


func get_campaign_next_boss_count() -> int:
	return LevelConfig.get_campaign_boss_count_for_mode(get_campaign_selected_level_mode(), get_campaign_current_level_progress())


func get_campaign_enemy_troop_level_bonus_total() -> int:
	return maxi(0, campaign_enemy_troop_level_bonus_total)

func get_campaign_enemy_troop_increase_per_level() -> int:
	return LevelConfig.get_campaign_enemy_troop_increase_per_level()


func get_campaign_boss_progress_steps_total() -> int:
	return maxi(0, campaign_total_boss_progress_steps)


func get_campaign_expected_boss_show_up_turn() -> int:
	var level_progress: int = get_campaign_current_level_progress()
	var tutorial_active: bool = false
	if has_method("is_opening_gameplay_tutorial_active"):
		tutorial_active = bool(call("is_opening_gameplay_tutorial_active"))
	return maxi(1, int(LevelConfig.get_boss_show_up_turn_for_level(level_progress, tutorial_active)))




func _has_any_live_boss_presence_on_map_or_runtime() -> bool:
	if boss_system != null:
		if boss_system.has_method("is_boss_active") and bool(boss_system.is_boss_active()):
			return true
		if boss_system.has_method("get_active_boss_ids"):
			var active_ids_variant: Variant = boss_system.call("get_active_boss_ids")
			if active_ids_variant is Array and not active_ids_variant.is_empty():
				return true
	for province_state_any in _province_persistence:
		if not (province_state_any is Dictionary):
			continue
		var province_state: Dictionary = province_state_any
		if bool(province_state.get("is_boss_home", false)):
			return true
		if bool(province_state.get("is_boss_faction_province", false)):
			return true
	return false


func get_campaign_boss_defensive_bonus_map() -> Dictionary:
	return campaign_boss_defensive_bonus_map.duplicate()


func get_campaign_boss_offensive_bonus_map() -> Dictionary:
	return campaign_boss_offensive_bonus_map.duplicate()


func get_campaign_boss_part_extra_hits_to_kill(part_name: String) -> int:
	return maxi(0, int(campaign_boss_defensive_bonus_map.get(String(part_name), 0)))


func get_campaign_boss_offense_bonus_value(bonus_key: String) -> int:
	return maxi(0, int(campaign_boss_offensive_bonus_map.get(String(bonus_key), 0)))


func get_campaign_between_level_summary_text() -> String:
	return String(campaign_between_level_summary_text).strip_edges()


func _create_empty_campaign_upgrade_discount_map() -> Dictionary:
	return {
		"bigger": 0,
		"heavier": 0,
		"poison": 0,
		"forcefield": 0,
		"magnet": 0
	}


func get_campaign_permanent_upgrade_points_unspent() -> int:
	return maxi(0, campaign_permanent_upgrade_points_unspent)


func get_campaign_permanent_upgrade_discount_map() -> Dictionary:
	var sanitized_map: Dictionary = _create_empty_campaign_upgrade_discount_map()
	for upgrade_type in sanitized_map.keys():
		var key: String = String(upgrade_type)
		var max_reduction: int = maxi(0, LevelConfig.get_upgrade_base_cost_for_type(key) - 1)
		sanitized_map[key] = clampi(int(campaign_permanent_upgrade_discount_map.get(key, 0)), 0, max_reduction)
	return sanitized_map


func get_permanent_upgrade_cost_reduction(upgrade_type: String) -> int:
	var key: String = String(upgrade_type)
	var max_reduction: int = maxi(0, LevelConfig.get_upgrade_base_cost_for_type(key) - 1)
	return clampi(int(campaign_permanent_upgrade_discount_map.get(key, 0)), 0, max_reduction)


func get_discounted_upgrade_purchase_cost(upgrade_type: String) -> int:
	var key: String = String(upgrade_type)
	var base_cost: int = LevelConfig.get_upgrade_base_cost_for_type(key)
	if base_cost >= 999999999:
		return base_cost
	return maxi(1, base_cost - get_permanent_upgrade_cost_reduction(key))


func get_discounted_upgrade_purchase_cost_map() -> Dictionary:
	return {
		"bigger": get_discounted_upgrade_purchase_cost("bigger"),
		"heavier": get_discounted_upgrade_purchase_cost("heavier"),
		"poison": get_discounted_upgrade_purchase_cost("poison"),
		"forcefield": get_discounted_upgrade_purchase_cost("forcefield"),
		"magnet": get_discounted_upgrade_purchase_cost("magnet")
	}


func _can_allocate_campaign_upgrade_discount_point(upgrade_type: String) -> bool:
	if get_campaign_permanent_upgrade_points_unspent() <= 0:
		return false
	var key: String = String(upgrade_type)
	var base_cost: int = LevelConfig.get_upgrade_base_cost_for_type(key)
	if base_cost <= 1 or base_cost >= 999999999:
		return false
	return get_permanent_upgrade_cost_reduction(key) < (base_cost - 1)


func _apply_campaign_upgrade_discount_point(upgrade_type: String) -> bool:
	var key: String = String(upgrade_type)
	if not _can_allocate_campaign_upgrade_discount_point(key):
		return false
	campaign_permanent_upgrade_discount_map[key] = get_permanent_upgrade_cost_reduction(key) + 1
	campaign_permanent_upgrade_points_unspent = maxi(0, campaign_permanent_upgrade_points_unspent - 1)
	campaign_permanent_upgrade_discount_map = get_campaign_permanent_upgrade_discount_map()
	_refresh_gold_and_upgrades_ui()
	return true


func _rebuild_campaign_runtime_scalars() -> void:
	campaign_level_progress = LevelConfig.clamp_campaign_level_progress(campaign_level_progress)
	campaign_selected_level_mode = LevelConfig.normalize_campaign_level_mode(campaign_selected_level_mode)
	campaign_total_cleared_levels = maxi(0, campaign_total_cleared_levels)
	campaign_total_easy_clears = maxi(0, campaign_total_easy_clears)
	campaign_total_hard_clears = maxi(0, campaign_total_hard_clears)
	campaign_total_boss_progress_steps = maxi(0, campaign_total_boss_progress_steps)
	campaign_enemy_troop_level_bonus_total = maxi(0, campaign_enemy_troop_level_bonus_total)
	campaign_permanent_upgrade_points_unspent = maxi(0, campaign_permanent_upgrade_points_unspent)
	campaign_permanent_upgrade_discount_map = get_campaign_permanent_upgrade_discount_map()
	campaign_boss_defensive_bonus_map = LevelConfig.build_campaign_boss_defensive_bonus_map(campaign_total_boss_progress_steps)
	campaign_boss_offensive_bonus_map = LevelConfig.build_campaign_boss_offensive_bonus_map(campaign_total_boss_progress_steps)
	LevelConfig.set_runtime_campaign_enemy_troop_level_bonus_total(campaign_enemy_troop_level_bonus_total)


func _reset_campaign_progression_state() -> void:
	campaign_level_progress = 1
	campaign_selected_level_mode = LevelConfig.CAMPAIGN_LEVEL_MODE_EASY
	campaign_last_completed_level_mode = ""
	campaign_total_cleared_levels = 0
	campaign_total_easy_clears = 0
	campaign_total_hard_clears = 0
	campaign_total_boss_progress_steps = 0
	campaign_enemy_troop_level_bonus_total = 0
	campaign_debug_bonus_gold_per_turn = 0
	campaign_between_level_summary_text = ""
	campaign_permanent_upgrade_points_unspent = 0
	campaign_permanent_upgrade_discount_map = _create_empty_campaign_upgrade_discount_map()
	_pending_campaign_upgrade_summary_text = ""
	_campaign_level_boss_spawn_committed = false
	_rebuild_campaign_runtime_scalars()


func _get_campaign_boss_defensive_label_map() -> Dictionary:
	return {
		LevelConfig.BOSS_PART_LEFT_ARM: "Left arm",
		LevelConfig.BOSS_PART_RIGHT_ARM: "Right arm",
		LevelConfig.BOSS_PART_LEFT_LEG: "Left leg",
		LevelConfig.BOSS_PART_RIGHT_LEG: "Right leg",
		LevelConfig.BOSS_PART_HEAD: "Head"
	}


func _get_campaign_boss_offensive_label_map() -> Dictionary:
	return {
		LevelConfig.BOSS_OFFENSE_LEFT_ARM_PUNCH: "Left arm punch kills",
		LevelConfig.BOSS_OFFENSE_RIGHT_ARM_PUNCH: "Right arm punch kills",
		LevelConfig.BOSS_OFFENSE_LEFT_LEG_KICK: "Left leg kick buildings",
		LevelConfig.BOSS_OFFENSE_RIGHT_LEG_KICK: "Right leg kick buildings",
		LevelConfig.BOSS_OFFENSE_RECRUIT: "Boss recruit bonus"
	}


func _get_campaign_upgrade_label_map() -> Dictionary:
	return {
		"bigger": "Bigger Ball",
		"heavier": "Heavier Ball",
		"poison": "Wind Resist",
		"forcefield": "Forcefield",
		"magnet": "Magnet"
	}


func _build_campaign_upgrade_discount_summary_line() -> String:
	var label_map: Dictionary = _get_campaign_upgrade_label_map()
	var ordered_keys: Array[String] = ["bigger", "heavier", "poison", "forcefield", "magnet"]
	var parts: Array[String] = []
	for key in ordered_keys:
		var reduction: int = get_permanent_upgrade_cost_reduction(key)
		if reduction <= 0:
			continue
		var base_cost: int = LevelConfig.get_upgrade_base_cost_for_type(key)
		var discounted_cost: int = get_discounted_upgrade_purchase_cost(key)
		parts.append("%s %d→%d" % [String(label_map.get(key, key.capitalize())), base_cost, discounted_cost])
	if parts.is_empty():
		return "Permanent upgrade discounts: none allocated yet."
	return "Permanent upgrade discounts: %s." % ", ".join(parts)


func _format_campaign_bonus_map_lines(bonus_map: Dictionary, ordered_keys: Array, label_map: Dictionary, suffix: String) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for raw_key in ordered_keys:
		var key: String = String(raw_key)
		var value: int = int(bonus_map.get(key, 0))
		if value <= 0:
			continue
		parts.append("%s +%d%s" % [String(label_map.get(key, key)), value, suffix])
	if parts.is_empty():
		return "None yet"
	return ", ".join(parts)


func _build_campaign_progression_summary(result: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var completed_level: int = int(result.get("completed_level", get_campaign_current_level_progress()))
	var next_level: int = int(result.get("next_level", get_campaign_current_level_progress()))
	var level_mode: String = String(result.get("mode", get_campaign_selected_level_mode()))
	var mode_name: String = LevelConfig.get_campaign_level_mode_display_name(level_mode)
	var step_advance: int = int(result.get("step_advance", 0))
	var boss_step_gain: int = int(result.get("boss_progress_steps_gained", 0))
	var troop_bonus_gain: int = int(result.get("troop_bonus_gained", 0))
	var reward_points_gain: int = int(result.get("reward_points_gained", 0))
	var next_boss_count: int = int(result.get("next_level_boss_count", 1))
	var completed_campaign: bool = bool(result.get("campaign_completed", false))

	lines.append("Level %d cleared on %s." % [completed_level, mode_name])
	if completed_campaign:
		lines.append("Campaign complete. You cleared Level %d/%d." % [completed_level, get_campaign_total_levels()])
	else:
		lines.append("Advance +%d step(s). Next level: %d/%d." % [step_advance, next_level, get_campaign_total_levels()])

	lines.append("Enemy province troop level bonus: +%d total (+%d this clear)." % [get_campaign_enemy_troop_level_bonus_total(), troop_bonus_gain])
	lines.append("Boss progression steps gained this clear: +%d. Total boss boost steps: %d." % [boss_step_gain, get_campaign_boss_progress_steps_total()])
	lines.append("Permanent upgrade points gained this clear: +%d. Unspent total: %d." % [reward_points_gain, get_campaign_permanent_upgrade_points_unspent()])
	lines.append(_build_campaign_upgrade_discount_summary_line())
	if not completed_campaign:
		lines.append("Next level boss count: %d." % next_boss_count)

	var defensive_lines: String = _format_campaign_bonus_map_lines(
		campaign_boss_defensive_bonus_map,
		LevelConfig.get_campaign_boss_defensive_rotation(),
		_get_campaign_boss_defensive_label_map(),
		" hit"
	)
	var offensive_lines: String = _format_campaign_bonus_map_lines(
		campaign_boss_offensive_bonus_map,
		LevelConfig.get_campaign_boss_offensive_rotation(),
		_get_campaign_boss_offensive_label_map(),
		""
	)
	lines.append("Boss defensive boosts so far: %s." % defensive_lines)
	lines.append("Boss offensive boosts so far: %s." % offensive_lines)
	lines.append("Level clears so far — Easy: %d, Hard: %d." % [campaign_total_easy_clears, campaign_total_hard_clears])
	return "\n".join(lines)


func _apply_campaign_level_completion(level_mode: String) -> Dictionary:
	var normalized_mode: String = LevelConfig.normalize_campaign_level_mode(level_mode)
	var completed_level: int = get_campaign_current_level_progress()
	var was_final_level: bool = LevelConfig.is_campaign_final_level(completed_level)
	var step_advance: int = 0 if was_final_level else LevelConfig.get_campaign_step_advance_for_mode(normalized_mode)
	var boss_progress_gain: int = LevelConfig.get_campaign_boss_progress_steps_for_mode(normalized_mode)
	var troop_bonus_gain: int = LevelConfig.get_campaign_enemy_troop_increase_per_level() * maxi(0, LevelConfig.get_campaign_step_advance_for_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_EASY))
	if normalized_mode == LevelConfig.CAMPAIGN_LEVEL_MODE_HARD:
		troop_bonus_gain = LevelConfig.get_campaign_enemy_troop_increase_per_level()
	var reward_points_gain: int = LevelConfig.get_campaign_reward_points_for_mode(normalized_mode)

	campaign_last_completed_level_mode = normalized_mode
	campaign_total_cleared_levels += 1
	if normalized_mode == LevelConfig.CAMPAIGN_LEVEL_MODE_HARD:
		campaign_total_hard_clears += 1
	else:
		campaign_total_easy_clears += 1
	campaign_total_boss_progress_steps += boss_progress_gain
	campaign_enemy_troop_level_bonus_total += troop_bonus_gain
	campaign_permanent_upgrade_points_unspent += reward_points_gain

	if not was_final_level:
		campaign_level_progress = LevelConfig.clamp_campaign_level_progress(completed_level + step_advance)
	else:
		campaign_level_progress = completed_level

	_rebuild_campaign_runtime_scalars()

	var next_level: int = get_campaign_current_level_progress()
	var completed_campaign: bool = was_final_level
	var next_boss_count: int = 1 if completed_campaign else LevelConfig.get_campaign_boss_count_for_mode(get_campaign_selected_level_mode(), next_level)
	var result: Dictionary = {
		"mode": normalized_mode,
		"completed_level": completed_level,
		"step_advance": step_advance,
		"boss_progress_steps_gained": boss_progress_gain,
		"troop_bonus_gained": troop_bonus_gain,
		"reward_points_gained": reward_points_gain,
		"next_level": next_level,
		"next_level_boss_count": next_boss_count,
		"campaign_completed": completed_campaign
	}
	campaign_between_level_summary_text = _build_campaign_progression_summary(result)
	result["summary_text"] = campaign_between_level_summary_text
	return result


func _complete_current_campaign_level_from_conquest() -> void:
	var completion_result: Dictionary = _apply_campaign_level_completion(get_campaign_selected_level_mode())
	var summary_text: String = String(completion_result.get("summary_text", "")).strip_edges()
	if bool(completion_result.get("campaign_completed", false)):
		_enter_campaign_complete_state(summary_text)
		return
	if get_campaign_permanent_upgrade_points_unspent() > 0 and not _get_campaign_reward_upgrade_options().is_empty():
		_begin_campaign_upgrade_choice(summary_text)
		return
	_advance_to_next_campaign_level(summary_text)


func _is_skip_to_end_running() -> bool:
	return _skip_to_end_running


func _can_show_skip_to_end_button() -> bool:
	if _current_phase != LevelConfig.PHASE_GRAND_MAP:
		return false
	if state == GameState.GAME_OVER:
		return false
	if _campaign_transition_in_progress:
		return false
	if _awaiting_campaign_upgrade_choice:
		return false
	if _awaiting_engagement_summary_ack:
		return false
	if _skip_to_end_running:
		return true
	if is_paused:
		return false
	if dragging or _drag_pending:
		return false
	if ball != null and is_instance_valid(ball):
		return false
	if state != GameState.GRAND_MAP:
		return false
	return _count_player_controlled_provinces() > 0 and _count_total_provinces() > 0


func _get_skip_to_end_pause_seconds() -> float:
	return maxf(0.0, float(LevelConfig.GRAND_MAP_SKIP_TO_END_TURN_PAUSE_SECONDS))


func _append_skip_to_end_trace_line(line: String) -> void:
	var trimmed_line: String = line.strip_edges()
	if trimmed_line == "":
		return
	print(trimmed_line)
	var file: FileAccess = FileAccess.open(SKIP_TO_END_TRACE_LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(SKIP_TO_END_TRACE_LOG_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(trimmed_line)


func _reset_skip_to_end_trace_log() -> void:
	var file: FileAccess = FileAccess.open(SKIP_TO_END_TRACE_LOG_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_line("=== Skip-to-End trace started: %s ===" % Time.get_datetime_string_from_system())


func _log_skip_to_end_trace(stage: String, details: String = "") -> void:
	var detail_suffix: String = ""
	if details.strip_edges() != "":
		detail_suffix = " | %s" % details.strip_edges()
	_append_skip_to_end_trace_line("[SkipToEndTrace] %s | turn=%d level=%d phase=%s state=%s player=%d/%d invaded=%d%s" % [
		stage,
		int(turn_number),
		int(level_index),
		String(_current_phase),
		str(state),
		_count_player_controlled_provinces(),
		_count_total_provinces(),
		enemy_turn_system.get_invaded_friendly_province_ids().size() if enemy_turn_system != null and enemy_turn_system.has_method("get_invaded_friendly_province_ids") else -1,
		detail_suffix
	])


func _cancel_skip_to_end() -> void:
	_skip_to_end_cancel_requested = true
	_skip_to_end_running = false
	_skip_to_end_suppress_terminal_resolution = false
	_log_skip_to_end_trace("cancel_requested")
	if ui_bridge != null:
		ui_bridge.sync_ui_button_states()


func _get_skip_to_end_terminal_state() -> String:
	var total_provinces: int = _count_total_provinces()
	if total_provinces <= 0:
		return "defeat"
	var player_controlled: int = _count_player_controlled_provinces()
	if player_controlled <= 0:
		return "defeat"
	if player_controlled >= total_provinces:
		return "victory"
	return ""


func _resolve_skip_to_end_terminal_state(terminal_state: String) -> void:
	match terminal_state:
		"victory":
			if _handle_full_conquest_before_boss_arrival():
				if ui_bridge != null:
					ui_bridge.sync_ui_button_states()
				return
			_complete_current_campaign_level_from_conquest()
		"defeat":
			_enter_game_over_state()
		_:
			if ui_bridge != null:
				ui_bridge.sync_ui_button_states()


func _run_skip_to_end_loop() -> void:
	while _skip_to_end_running and not _skip_to_end_cancel_requested:
		_log_skip_to_end_trace("loop_start")
		var terminal_state_before: String = _get_skip_to_end_terminal_state()
		if terminal_state_before != "":
			_log_skip_to_end_trace("terminal_before", terminal_state_before)
			_skip_to_end_running = false
			_skip_to_end_cancel_requested = false
			_skip_to_end_suppress_terminal_resolution = false
			_resolve_skip_to_end_terminal_state(terminal_state_before)
			return

		if enemy_turn_system == null or level_flow == null:
			_cancel_skip_to_end()
			return

		_clear_engagement_summary_wait_state()
		_set_magnet_placement_armed(false)
		_current_phase = LevelConfig.PHASE_GRAND_MAP
		state = GameState.GRAND_MAP
		_active_engagement_province_id = -1

		_skip_to_end_suppress_terminal_resolution = true
		var next_turn_number: int = turn_number + 1
		_log_skip_to_end_trace("before_advance", "next_turn=%d" % next_turn_number)
		enemy_turn_system.advance_grand_map_turn_after_rest("Skip to End — resolved turn %d automatically." % next_turn_number)
		_skip_to_end_suppress_terminal_resolution = false
		_log_skip_to_end_trace("after_advance")

		await get_tree().process_frame
		_log_skip_to_end_trace("after_frame")

		var pause_seconds: float = _get_skip_to_end_pause_seconds()
		if pause_seconds > 0.0 and _skip_to_end_running and not _skip_to_end_cancel_requested:
			await get_tree().create_timer(pause_seconds).timeout
			_log_skip_to_end_trace("after_pause", "pause_seconds=%.3f" % pause_seconds)

		if not _skip_to_end_running or _skip_to_end_cancel_requested:
			_log_skip_to_end_trace("loop_break", "running=%s cancel=%s" % [str(_skip_to_end_running), str(_skip_to_end_cancel_requested)])
			break

		var terminal_state_after: String = _get_skip_to_end_terminal_state()
		if terminal_state_after != "":
			_log_skip_to_end_trace("terminal_after", terminal_state_after)
			_skip_to_end_running = false
			_skip_to_end_cancel_requested = false
			_skip_to_end_suppress_terminal_resolution = false
			_resolve_skip_to_end_terminal_state(terminal_state_after)
			return

	_skip_to_end_running = false
	_skip_to_end_cancel_requested = false
	_skip_to_end_suppress_terminal_resolution = false
	_log_skip_to_end_trace("loop_exit")
	if ui_bridge != null:
		ui_bridge.sync_ui_button_states()


func _ready() -> void:
	_init_systems()
	_apply_visual_layer_defaults()
	_ensure_global_sand_tile_backdrop()
	_setup_aim_line()
	_setup_projection_line()
	_init_tutorial_guide()

	if ui_bridge != null:
		ui_bridge.setup_ui()

	if ui != null and ui.has_signal("campaign_upgrade_selected") and not ui.campaign_upgrade_selected.is_connected(_on_campaign_upgrade_selected):
		ui.campaign_upgrade_selected.connect(_on_campaign_upgrade_selected)

	self.process_mode = Node.PROCESS_MODE_ALWAYS

	if camera_controller != null:
		var viewport_resize_callable: Callable = Callable(camera_controller, "on_viewport_size_changed")
		if not get_viewport().size_changed.is_connected(viewport_resize_callable):
			get_viewport().size_changed.connect(viewport_resize_callable)

	_new_run_seed()
	_reset_campaign_progression_state()
	if boss_system != null and boss_system.has_method("reset_all_boss_progress"):
		boss_system.reset_all_boss_progress()

	if level_flow != null:
		level_flow.ensure_spawn_roots()

	call_deferred("_begin_opening_game_flow")

	if camera_controller != null:
		camera_controller.call_deferred("apply_camera_fit")
		get_tree().create_timer(0.12).timeout.connect(Callable(camera_controller, "apply_camera_fit"))


func _store_current_grand_map_camera_state() -> void:
	if _current_phase != LevelConfig.PHASE_GRAND_MAP and state != GameState.GRAND_MAP and state != GameState.BALL_IN_FLIGHT:
		return

	var zoom_value: float = current_camera_zoom
	if camera_2d != null and camera_2d.zoom.x > 0.0001:
		zoom_value = camera_2d.zoom.x

	var min_zoom: float = _grand_map_fit_zoom if _grand_map_fit_zoom > 0.0001 else 0.0001
	_saved_grand_map_zoom = clampf(zoom_value, min_zoom, LevelConfig.GRAND_MAP_CAMERA_MAX_ZOOM)
	_saved_grand_map_pan_offset = camera_pan_offset
	_has_saved_grand_map_camera = true


func _restore_saved_grand_map_camera_state() -> void:
	if not _has_saved_grand_map_camera:
		return

	var min_zoom: float = _grand_map_fit_zoom if _grand_map_fit_zoom > 0.0001 else 0.0001
	current_camera_zoom = clampf(_saved_grand_map_zoom, min_zoom, LevelConfig.GRAND_MAP_CAMERA_MAX_ZOOM)
	camera_pan_offset = _saved_grand_map_pan_offset


func _clear_saved_grand_map_camera_state() -> void:
	_has_saved_grand_map_camera = false
	_saved_grand_map_pan_offset = Vector2.ZERO
	_saved_grand_map_zoom = 1.0


func _restore_player_camera_view_after_follow(refresh_now: bool = true) -> void:
	_camera_follow_active = false

	if _current_phase == LevelConfig.PHASE_GRAND_MAP and _has_saved_grand_map_camera:
		_restore_saved_grand_map_camera_state()

	if camera_controller != null and refresh_now:
		camera_controller.apply_camera_fit()
	elif camera_2d != null:
		var bar_h: float = 0.0
		if ui and ui.has_method("get_bottom_bar_height"):
			bar_h = float(ui.call("get_bottom_bar_height"))

		var world_offset_y: float = 0.0
		if camera_controller != null and camera_controller.has_method("get_bottom_bar_world_offset"):
			world_offset_y = float(camera_controller.get_bottom_bar_world_offset(bar_h))

		camera_2d.position = camera_pan_offset + Vector2(0.0, world_offset_y)


func _process(_delta: float) -> void:
	_maybe_finalize_opening_gameplay_tutorial()
	var idle_grand_map: bool = _is_idle_grand_map_state()
	_apply_ui_low_motion_mode(idle_grand_map)
	var allow_noncritical_tick: bool = not idle_grand_map or _consume_idle_map_throttle_tick(_delta)
	if input_controller != null and allow_noncritical_tick:
		input_controller.process_drag_preview()


func _is_idle_grand_map_state() -> bool:
	if _current_phase != LevelConfig.PHASE_GRAND_MAP:
		return false
	if state != GameState.GRAND_MAP:
		return false
	if dragging or pan_dragging or _right_mouse_pan_active:
		return false
	if _camera_follow_active:
		return false
	if _drag_pending or _is_auto_charging:
		return false
	if _total_active_touches > 0:
		return false
	return true


func _consume_idle_map_throttle_tick(delta: float) -> bool:
	_idle_map_throttle_accum += maxf(0.0, delta)
	if _idle_map_throttle_accum < IDLE_MAP_THROTTLE_INTERVAL_SECONDS:
		return false
	_idle_map_throttle_accum = 0.0
	return true


func _apply_ui_low_motion_mode(enable_low_motion: bool) -> void:
	if _ui_low_motion_applied == enable_low_motion:
		return
	_ui_low_motion_applied = enable_low_motion
	if ui != null and ui.has_method("set_low_motion_mode"):
		ui.call("set_low_motion_mode", enable_low_motion)


func _physics_process(delta: float) -> void:
	if is_paused:
		return

	# Always run smooth ball follow during flight
	if _camera_follow_active and camera_controller != null and state == GameState.BALL_IN_FLIGHT:
		camera_controller.update_ball_follow(delta)

	# Settlement detection MUST run every frame during BALL_IN_FLIGHT
	if state == GameState.BALL_IN_FLIGHT:
		if ball == null or not is_instance_valid(ball):
			if level_flow != null:
				level_flow.finalize_ball_flight_now()
			_update_screen_shake(delta)
			return

		if ball.has_method("is_sunk_in_water") and bool(ball.call("is_sunk_in_water")):
			if level_flow != null:
				level_flow.finalize_ball_flight_now()
			_update_screen_shake(delta)
			return

		_record_live_poison_contacts()

		var now: float = Time.get_ticks_msec() / 1000.0
		if now < _wall_grace_end_time:
			ball.collision_mask = LevelConfig.MASK_PINS | LevelConfig.MASK_ZONES
		else:
			ball.collision_mask = LevelConfig.MASK_PINS | LevelConfig.MASK_WALLS | LevelConfig.MASK_ZONES

		flight_timer += delta
		_pins_ui_accum += delta

		if _pins_ui_accum >= PINS_UI_REFRESH_INTERVAL:
			_pins_ui_accum = 0.0
			var live_standing: int = 0
			if level_flow != null:
				live_standing = level_flow.count_standing_pins()
			var live_downed: int = _initial_pin_count - live_standing
			if ui_bridge != null:
				ui_bridge.ui_set_pins_counts(_initial_pin_count, live_downed)
			if level_flow != null:
				level_flow.refresh_engagement_live_counter()

		var speed: float = ball.linear_velocity.length()

		# GRAND MAP SETTLEMENT — DIRECT ROBUST PATH (this fixes the issue)
		if _current_phase == "grand_map":
			if speed <= float(LevelConfig.BALL_REST_SPEED_EPS):
				rest_timer += delta
				if rest_timer >= float(LevelConfig.BALL_REST_DWELL_SECONDS):
					settle_timer += delta
					if settle_timer >= SETTLE_DELAY_SECONDS:
						_last_ball_end_reason = "rest"
						_finalize_ball_flight()
						return
			else:
				rest_timer = 0.0
				settle_timer = 0.0
		else:
			if speed <= float(LevelConfig.BALL_REST_SPEED_EPS):
				rest_timer += delta
				if rest_timer >= float(LevelConfig.BALL_REST_DWELL_SECONDS):
					settle_timer += delta
					if settle_timer >= SETTLE_DELAY_SECONDS:
						_last_ball_end_reason = "rest"
						if level_flow != null:
							level_flow.finalize_ball_flight_now()
						return
			else:
				rest_timer = 0.0
				settle_timer = 0.0

		if flight_timer > 20.0:
			_last_ball_end_reason = "rest"
			if level_flow != null:
				level_flow.finalize_ball_flight_now()
			return

		_update_screen_shake(delta)
		return

	if _camera_follow_active and camera_controller != null:
		camera_controller.update_ball_follow(delta)

	if state != GameState.BALL_IN_FLIGHT:
		_update_screen_shake(delta)
		return
func _input(event: InputEvent) -> void:
	if input_controller != null:
		input_controller.handle_input(event)


func _init_tutorial_guide() -> void:
	tutorial_guide = null
	if not LevelConfig.is_tutorial_and_field_guide_enabled():
		return

	tutorial_guide = TutorialGuideScript.new()
	if tutorial_guide != null and tutorial_guide.has_method("setup"):
		tutorial_guide.call("setup")

	if ui_bridge != null and ui_bridge.has_method("ui_set_tutorial_guide"):
		ui_bridge.call("ui_set_tutorial_guide", tutorial_guide)


func _start_first_run_tutorial_if_needed() -> void:
	if not LevelConfig.should_auto_start_first_run_tutorial():
		return
	if tutorial_guide == null or not tutorial_guide.has_method("should_auto_start_first_run"):
		return
	if not bool(tutorial_guide.call("should_auto_start_first_run")):
		return
	if ui_bridge != null and ui_bridge.has_method("ui_show_first_run_tutorial"):
		ui_bridge.call("ui_show_first_run_tutorial")


func _begin_opening_game_flow() -> void:
	if _try_start_opening_gameplay_tutorial():
		return
	_show_campaign_level_mode_prompt("", true)


func _try_start_opening_gameplay_tutorial() -> bool:
	if level_flow == null:
		return false
	if not level_flow.has_method("should_start_opening_gameplay_tutorial"):
		return false
	if not bool(level_flow.call("should_start_opening_gameplay_tutorial")):
		return false

	_opening_gameplay_tutorial_session_started = true
	_opening_gameplay_tutorial_session_consumed = false

	if ui_bridge != null and ui_bridge.has_method("ui_hide_campaign_level_mode_choice"):
		ui_bridge.ui_hide_campaign_level_mode_choice()
		if ui_bridge.has_method("ui_hide_pre_level_debug_config_choice"):
			ui_bridge.ui_hide_pre_level_debug_config_choice()

	if level_flow.has_method("start_opening_gameplay_tutorial"):
		level_flow.call("start_opening_gameplay_tutorial")
		return true
	return false


func is_opening_gameplay_tutorial_active() -> bool:
	if level_flow != null and level_flow.has_method("is_opening_gameplay_tutorial_active"):
		return bool(level_flow.call("is_opening_gameplay_tutorial_active"))
	return false


func get_opening_gameplay_tutorial_skip_label() -> String:
	if level_flow != null and level_flow.has_method("get_opening_gameplay_tutorial_skip_label"):
		return String(level_flow.call("get_opening_gameplay_tutorial_skip_label"))
	return "Skip Tutorial"


func request_skip_opening_gameplay_tutorial() -> void:
	if not is_opening_gameplay_tutorial_active():
		return
	if level_flow != null and level_flow.has_method("skip_opening_gameplay_tutorial"):
		level_flow.call("skip_opening_gameplay_tutorial")
	_finish_opening_gameplay_tutorial_and_return_to_campaign_start()


func _maybe_finalize_opening_gameplay_tutorial() -> void:
	if not _opening_gameplay_tutorial_session_started or _opening_gameplay_tutorial_session_consumed:
		return
	if level_flow == null:
		return
	if is_opening_gameplay_tutorial_active():
		return
	if not level_flow.has_method("has_opening_gameplay_tutorial_completed"):
		return
	if not bool(level_flow.call("has_opening_gameplay_tutorial_completed")):
		return
	_finish_opening_gameplay_tutorial_and_return_to_campaign_start()


func _finish_opening_gameplay_tutorial_and_return_to_campaign_start() -> void:
	if _opening_gameplay_tutorial_session_consumed:
		return

	_opening_gameplay_tutorial_session_started = false
	_opening_gameplay_tutorial_session_consumed = true

	if tutorial_guide != null and tutorial_guide.has_method("mark_first_run_complete"):
		tutorial_guide.call("mark_first_run_complete")

	_clear_engagement_summary_wait_state()
	_prepare_for_campaign_transition()
	_clear_saved_grand_map_camera_state()
	_clear_boss_home_assault_runtime_state()
	_set_magnet_placement_armed(false)
	_skip_to_end_running = false
	_skip_to_end_cancel_requested = false
	_skip_to_end_suppress_terminal_resolution = false
	_current_phase = LevelConfig.PHASE_GRAND_MAP
	state = GameState.GRAND_MAP
	turn_number = 1
	_locked_province_id_after_win = -1
	_active_engagement_province_id = -1
	_province_persistence.clear()
	_camera_follow_active = false

	if ui_bridge != null and ui_bridge.has_method("ui_hide_campaign_level_mode_choice"):
		ui_bridge.ui_hide_campaign_level_mode_choice()
		if ui_bridge.has_method("ui_hide_pre_level_debug_config_choice"):
			ui_bridge.ui_hide_pre_level_debug_config_choice()

	_new_run_seed()
	_reset_campaign_progression_state()

	if boss_system != null and boss_system.has_method("reset_all_boss_progress"):
		boss_system.reset_all_boss_progress()

	if province_system != null:
		province_system.clear_cached_ball_end_world_pos()

	if get_campaign_current_level_progress() <= 1:
		call_deferred("_show_campaign_level_mode_prompt", "", true)
		return

	call_deferred("_show_campaign_level_mode_prompt", "", true)


func _unlock_tutorial_notes_for_event(event_key: String, show_toasts: bool = true) -> Array[Dictionary]:
	var unlocked_entries: Array[Dictionary] = []
	if event_key.strip_edges() == "":
		return unlocked_entries
	if not LevelConfig.is_tutorial_and_field_guide_enabled():
		return unlocked_entries

	if ui_bridge != null and ui_bridge.has_method("ui_unlock_notes_for_event"):
		var result: Variant = ui_bridge.call("ui_unlock_notes_for_event", event_key, show_toasts)
		if result is Array:
			for entry in result:
				if entry is Dictionary:
					unlocked_entries.append((entry as Dictionary).duplicate(true))
		return unlocked_entries

	if tutorial_guide != null and tutorial_guide.has_method("unlock_notes_for_event"):
		var raw_entries: Variant = tutorial_guide.call("unlock_notes_for_event", event_key)
		if raw_entries is Array:
			for entry in raw_entries:
				if entry is Dictionary:
					unlocked_entries.append((entry as Dictionary).duplicate(true))
		return unlocked_entries

	return unlocked_entries


func _init_systems() -> void:
	level_flow = _init_system(MainLevelFlowScript)
	province_system = _init_system(ProvinceSystemScript)
	enemy_turn_system = _init_system(EnemyTurnSystemScript)
	engagement_resolver = _init_system(EngagementResolverScript)
	input_controller = _init_system(InputControllerScript)
	camera_controller = _init_system(CameraControllerScript)
	boss_system = _init_system(BossSystemScript)
	ui_bridge = _init_system(MainUIBridgeScript)


func _init_system(script_ref: Variant) -> Variant:
	if script_ref == null:
		return null
	var instance: Variant = script_ref.new()
	if instance != null and instance.has_method("setup"):
		instance.call("setup", self)
	return instance


func _set_canvas_item_visual_layer(node: Variant, layer_value: int) -> void:
	if node == null:
		return
	if not (node is CanvasItem):
		return
	var item: CanvasItem = node as CanvasItem
	item.z_as_relative = false
	item.z_index = layer_value


func _apply_visual_layer_defaults() -> void:
	_set_canvas_item_visual_layer(zones_root, LevelConfig.VISUAL_LAYER_SAND)
	_set_canvas_item_visual_layer(provinces_root, LevelConfig.VISUAL_LAYER_PROVINCE_FILL)
	_set_canvas_item_visual_layer(pins_root, LevelConfig.VISUAL_LAYER_TROOPS)
	_set_canvas_item_visual_layer(obstacles_root, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
	_set_canvas_item_visual_layer(bounds_root, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
	_set_canvas_item_visual_layer(wall_top, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
	_set_canvas_item_visual_layer(wall_bottom, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
	_set_canvas_item_visual_layer(wall_left, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
	_set_canvas_item_visual_layer(wall_right, LevelConfig.VISUAL_LAYER_STATIC_OBSTACLES)
	_set_canvas_item_visual_layer(ball_holder, LevelConfig.VISUAL_LAYER_SPECIAL_GAMEPLAY_ACTORS)

	if ui != null:
		if ui is CanvasLayer:
			(ui as CanvasLayer).layer = LevelConfig.UI_CANVAS_LAYER_MAIN_HUD
		elif ui is CanvasItem:
			var ui_item: CanvasItem = ui as CanvasItem
			ui_item.z_as_relative = false
			ui_item.z_index = LevelConfig.VISUAL_LAYER_DISPLAY_WINDOWS + 1000


func _ensure_global_sand_tile_backdrop() -> void:
	if zones_root == null or not is_instance_valid(zones_root):
		return
	var existing: Node = zones_root.get_node_or_null(GLOBAL_SAND_TILE_BACKDROP_NAME)
	if existing != null and is_instance_valid(existing):
		return
	var sand_tile_texture: Texture2D = load(LevelConfig.RESORT_SAND_TILE_TEXTURE_PATH) as Texture2D
	if sand_tile_texture == null:
		return
	var layer := Node2D.new()
	layer.name = GLOBAL_SAND_TILE_BACKDROP_NAME
	layer.z_as_relative = false
	layer.z_index = LevelConfig.VISUAL_LAYER_SAND - 1
	zones_root.add_child(layer)

	var half_extents := Vector2(
		maxf(LevelConfig.WORLD_HALF_EXTENTS.x, LevelConfig.GRAND_MAP_HALF_EXTENTS.x),
		maxf(LevelConfig.WORLD_HALF_EXTENTS.y, LevelConfig.GRAND_MAP_HALF_EXTENTS.y)
	)
	var tile_size := maxf(16.0, LevelConfig.RESORT_SAND_TILE_SIZE)
	var tile_scale := tile_size / maxf(1.0, float(sand_tile_texture.get_width()))
	var rendered_tile_width := maxf(1.0, float(sand_tile_texture.get_width()) * tile_scale)
	var rendered_tile_height := maxf(1.0, float(sand_tile_texture.get_height()) * tile_scale)
	var columns := int(ceil((half_extents.x * 2.0) / rendered_tile_width)) + 1
	var rows := int(ceil((half_extents.y * 2.0) / rendered_tile_height)) + 1
	for row in range(rows):
		for col in range(columns):
			var tile := Sprite2D.new()
			tile.texture = sand_tile_texture
			tile.centered = true
			tile.scale = Vector2.ONE * tile_scale
			tile.position = Vector2(
				-half_extents.x + (float(col) + 0.5) * rendered_tile_width,
				-half_extents.y + (float(row) + 0.5) * rendered_tile_height
			)
			tile.modulate = Color(1.0, 1.0, 1.0, 0.58)
			tile.z_as_relative = false
			tile.z_index = LevelConfig.VISUAL_LAYER_SAND - 1
			layer.add_child(tile)


func _setup_aim_line() -> void:
	aim_line = Line2D.new()
	aim_line.name = "AimLine"
	aim_line.width = 8.0
	aim_line.antialiased = true
	aim_line.z_as_relative = false
	aim_line.z_index = LevelConfig.VISUAL_LAYER_SPECIAL_GAMEPLAY_ACTORS
	aim_line.visible = false
	add_child(aim_line)


func _setup_projection_line() -> void:
	projection_line = Line2D.new()
	projection_line.name = "ProjectionLine"
	projection_line.width = LevelConfig.PROJECTION_LINE_WIDTH
	projection_line.default_color = LevelConfig.PROJECTION_LINE_COLOR
	projection_line.antialiased = true
	projection_line.z_as_relative = false
	projection_line.z_index = LevelConfig.VISUAL_LAYER_SPECIAL_GAMEPLAY_ACTORS
	projection_line.visible = false
	add_child(projection_line)


func _update_screen_shake(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var shake_vec: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amount * (_shake_timer / LevelConfig.JUICY_WIN_SHAKE_TIME)
		camera_2d.offset = shake_vec
	else:
		camera_2d.offset = Vector2.ZERO


func _apply_screen_shake(amount: float, duration: float) -> void:
	_shake_amount = amount
	_shake_timer = duration



func _count_live_player_magnets() -> int:
	var count: int = 0
	for magnet_node in get_tree().get_nodes_in_group("player_magnets"):
		if magnet_node != null and is_instance_valid(magnet_node) and not magnet_node.is_queued_for_deletion():
			count += 1
	return count


func _get_live_player_magnet_positions() -> Array:
	var positions: Array = []
	for magnet_node in get_tree().get_nodes_in_group("player_magnets"):
		if magnet_node == null or not is_instance_valid(magnet_node) or magnet_node.is_queued_for_deletion():
			continue
		if magnet_node is Node2D:
			positions.append((magnet_node as Node2D).global_position)
	return positions


func _get_remaining_magnet_placements() -> int:
	if _current_phase == LevelConfig.PHASE_GRAND_MAP:
		return 0
	return maxi(0, magnet_count - _count_live_player_magnets())


func _can_show_magnet_place_button() -> bool:
	if _current_phase == LevelConfig.PHASE_GRAND_MAP:
		return false
	if state != GameState.ENGAGEMENT:
		return false
	if is_paused:
		return false
	return magnet_count > 0 and _get_remaining_magnet_placements() > 0


func _is_magnet_placement_mode_armed() -> bool:
	return _magnet_placement_armed and _can_show_magnet_place_button()


func _set_magnet_placement_armed(armed: bool) -> void:
	var next_armed: bool = armed and _can_show_magnet_place_button()
	_magnet_placement_armed = next_armed
	if ui_bridge != null:
		ui_bridge.ui_refresh_upgrades()
		ui_bridge.sync_ui_button_states()


func _toggle_magnet_placement_mode() -> void:
	if _is_magnet_placement_mode_armed():
		_set_magnet_placement_armed(false)
		if ui_bridge != null and _current_phase != LevelConfig.PHASE_GRAND_MAP and state == GameState.ENGAGEMENT and level_flow != null:
			level_flow.refresh_engagement_live_counter()
		return

	if not _can_show_magnet_place_button():
		return

	_set_magnet_placement_armed(true)
	if ui_bridge != null:
		ui_bridge.ui_set_status("Magnet placement armed — tap the engagement map to place a magnet.")


func _make_player_magnet_visual(world_pos: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = "PlayerMagnet"
	root.position = world_pos
	root.z_as_relative = false
	root.z_index = LevelConfig.VISUAL_LAYER_SPECIAL_GAMEPLAY_ACTORS
	root.add_to_group("player_magnets")
	root.set_meta("is_player_magnet", true)

	var outer_radius: float = float(LevelConfig.UPGRADE_MAGNET_VISUAL_RADIUS)
	var inner_radius: float = outer_radius * 0.54
	var points: PackedVector2Array = PackedVector2Array()
	var inner_points: PackedVector2Array = PackedVector2Array()
	var segments: int = 28
	for i in range(segments + 1):
		var angle: float = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * outer_radius)
		inner_points.append(Vector2(cos(angle), sin(angle)) * inner_radius)

	var outer_ring := Line2D.new()
	outer_ring.width = 5.0
	outer_ring.default_color = Color(0.35, 0.95, 1.0, 0.95)
	outer_ring.closed = true
	outer_ring.points = points
	root.add_child(outer_ring)

	var inner_ring := Line2D.new()
	inner_ring.width = 3.0
	inner_ring.default_color = Color(1.0, 0.98, 0.78, 0.98)
	inner_ring.closed = true
	inner_ring.points = inner_points
	root.add_child(inner_ring)

	var north_arc := Line2D.new()
	north_arc.width = 6.0
	north_arc.default_color = Color(1.0, 0.26, 0.30, 0.96)
	north_arc.points = PackedVector2Array([
		Vector2(-outer_radius * 0.62, -outer_radius * 0.18),
		Vector2(-outer_radius * 0.18, -outer_radius * 0.62),
		Vector2(outer_radius * 0.18, -outer_radius * 0.62),
		Vector2(outer_radius * 0.62, -outer_radius * 0.18)
	])
	root.add_child(north_arc)

	var south_arc := Line2D.new()
	south_arc.width = 6.0
	south_arc.default_color = Color(0.22, 0.72, 1.0, 0.96)
	south_arc.points = PackedVector2Array([
		Vector2(-outer_radius * 0.62, outer_radius * 0.18),
		Vector2(-outer_radius * 0.18, outer_radius * 0.62),
		Vector2(outer_radius * 0.18, outer_radius * 0.62),
		Vector2(outer_radius * 0.62, outer_radius * 0.18)
	])
	root.add_child(south_arc)

	var core := Polygon2D.new()
	var core_points: PackedVector2Array = PackedVector2Array()
	var core_segments: int = 12
	var core_radius: float = outer_radius * 0.22
	for i in range(core_segments):
		var angle: float = TAU * float(i) / float(core_segments)
		core_points.append(Vector2(cos(angle), sin(angle)) * core_radius)
	core.polygon = core_points
	core.color = Color(1.0, 1.0, 1.0, 0.92)
	root.add_child(core)

	return root


func _place_player_magnet(world_pos: Vector2) -> bool:
	if not _can_show_magnet_place_button():
		return false
	if _get_remaining_magnet_placements() <= 0:
		return false
	if obstacles_root == null or not is_instance_valid(obstacles_root):
		return false

	var magnet_node: Node2D = _make_player_magnet_visual(world_pos)
	obstacles_root.add_child(magnet_node)
	_set_magnet_placement_armed(_get_remaining_magnet_placements() > 0)

	if ui_bridge != null:
		ui_bridge.ui_refresh_upgrades()

	return true


func _is_milestone(lvl: int) -> bool:
	return lvl % LevelConfig.MILESTONE_INTERVAL == 0


func _toggle_pause() -> void:
	if _skip_to_end_running:
		return
	is_paused = not is_paused
	if ui_bridge != null:
		ui_bridge.sync_ui_button_states()
	get_tree().paused = is_paused


func _get_upgrade_level(upgrade_type: String) -> int:
	match upgrade_type:
		"bigger":
			return bigger_count
		"heavier":
			return heavier_count
		"poison":
			return poison_count
		"forcefield":
			return forcefield_count
		"magnet":
			return magnet_count
		_:
			return 0


func _get_upgrade_purchase_cost(upgrade_type: String) -> int:
	return get_discounted_upgrade_purchase_cost(upgrade_type)


func _refresh_gold_and_upgrades_ui() -> void:
	if ui_bridge != null:
		ui_bridge.ui_set_gold(gold_balance)
		ui_bridge.ui_refresh_upgrades()


func _get_current_turn_income() -> int:
	var bonus_gold: int = maxi(0, campaign_debug_bonus_gold_per_turn)
	if province_system != null and province_system.has_method("get_total_friendly_gold_income"):
		return maxi(0, int(province_system.get_total_friendly_gold_income())) + bonus_gold
	return maxi(0, _count_player_controlled_provinces()) + bonus_gold


func _reset_upgrade_counts_to_permanent_baseline() -> void:
	bigger_count = permanent_bigger_count
	heavier_count = permanent_heavier_count
	poison_count = permanent_poison_count
	forcefield_count = permanent_forcefield_count
	magnet_count = permanent_magnet_count


func _reset_turn_gold_and_upgrades_for_current_turn(force: bool = false) -> void:
	if not force and _economy_initialized_turn == turn_number:
		return
	_economy_initialized_turn = turn_number
	gold_balance = _get_current_turn_income()
	_reset_upgrade_counts_to_permanent_baseline()
	_set_magnet_placement_armed(false)
	_refresh_gold_and_upgrades_ui()


func _reset_live_poison_tracking() -> void:
	_poison_live_touched_pins.clear()
	_poison_probe_ball_instance_id = -1
	_poison_probe_last_ball_pos = Vector2.ZERO
	_poison_probe_has_last_ball_pos = false
	_invalidate_active_pin_scan_cache()


func _invalidate_active_pin_scan_cache() -> void:
	_active_pin_scan_cache.clear()
	_active_pin_scan_cache_dirty = true


func _get_active_pin_scan_nodes() -> Array[Pin]:
	var live_pins: Array[Pin] = []
	if pins_root == null or not is_instance_valid(pins_root):
		return live_pins

	if _active_pin_scan_cache_dirty:
		_active_pin_scan_cache.clear()
		for child in pins_root.get_children():
			if child is Pin:
				_active_pin_scan_cache.append(weakref(child))
		_active_pin_scan_cache_dirty = false

	var stale_found: bool = false
	for entry in _active_pin_scan_cache:
		if not (entry is WeakRef):
			stale_found = true
			continue
		var ref_node: Object = (entry as WeakRef).get_ref()
		if ref_node == null or not is_instance_valid(ref_node):
			stale_found = true
			continue
		if not (ref_node is Pin):
			stale_found = true
			continue
		var pin_node: Pin = ref_node as Pin
		if pin_node.is_queued_for_deletion():
			stale_found = true
			continue
		live_pins.append(pin_node)

	if stale_found and live_pins.size() != _active_pin_scan_cache.size():
		_active_pin_scan_cache.clear()
		for pin in live_pins:
			_active_pin_scan_cache.append(weakref(pin))

	return live_pins


func _record_live_poison_contacts() -> void:
	if _current_phase == "grand_map":
		return
	if ball == null or not is_instance_valid(ball):
		return
	var current_ball_id: int = int(ball.get_instance_id())
	var current_ball_pos: Vector2 = ball.global_position
	if _poison_probe_ball_instance_id != current_ball_id:
		_reset_live_poison_tracking()
		_poison_probe_ball_instance_id = current_ball_id
		_poison_probe_last_ball_pos = current_ball_pos
		_poison_probe_has_last_ball_pos = true
	var start_pos: Vector2 = _poison_probe_last_ball_pos if _poison_probe_has_last_ball_pos else current_ball_pos
	var end_pos: Vector2 = current_ball_pos
	var ball_radius: float = 28.0
	if ball.has_method("get_radius"):
		ball_radius = float(ball.call("get_radius"))
	var pin_radius: float = maxf(float(LevelConfig.PIN_BODY_WIDTH) * 0.55 * float(LevelConfig.ENEMY_SCALE_PIN), float(LevelConfig.PIN_HEAD_RADIUS) * 1.15 * float(LevelConfig.ENEMY_SCALE_PIN))
	var touch_threshold: float = ball_radius + pin_radius + 8.0
	for pin in _get_active_pin_scan_nodes():
		var pin_pos: Vector2 = pin.global_position
		if pin_pos.distance_to(end_pos) <= touch_threshold or _distance_point_to_segment(pin_pos, start_pos, end_pos) <= touch_threshold:
			_poison_live_touched_pins[int(pin.get_instance_id())] = pin
			if pin.has_method("mark_touched_by_ball_this_shot"):
				pin.call("mark_touched_by_ball_this_shot")
	_poison_probe_last_ball_pos = current_ball_pos
	_poison_probe_has_last_ball_pos = true
func _distance_point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq <= 0.0001:
		return point.distance_to(a)
	var t: float = clampf((point - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return point.distance_to(closest)


func _collect_touched_pins_from_ball_trail() -> Array[Pin]:
	var touched: Array[Pin] = []
	if ball == null or not is_instance_valid(ball):
		return touched
	if not ball.has_method("get_trail_points"):
		return touched

	var trail: Array = ball.call("get_trail_points")
	if trail.is_empty():
		return touched

	var sampled_points: Array[Vector2] = []
	for entry in trail:
		if entry is Vector2:
			sampled_points.append(entry)
	if sampled_points.is_empty():
		return touched
	if sampled_points[sampled_points.size() - 1].distance_to(ball.global_position) > 0.5:
		sampled_points.append(ball.global_position)

	var ball_radius: float = 28.0
	if ball.has_method("get_radius"):
		ball_radius = float(ball.call("get_radius"))
	var pin_radius: float = maxf(float(LevelConfig.PIN_BODY_WIDTH) * 0.55 * float(LevelConfig.ENEMY_SCALE_PIN), float(LevelConfig.PIN_HEAD_RADIUS) * 1.15 * float(LevelConfig.ENEMY_SCALE_PIN))
	var touch_threshold: float = ball_radius + pin_radius + 6.0

	for pin in _get_active_pin_scan_nodes():
		var pin_pos: Vector2 = pin.global_position
		var was_touched: bool = false
		for i in range(sampled_points.size()):
			if pin_pos.distance_to(sampled_points[i]) <= touch_threshold:
				was_touched = true
				break
			if i > 0 and _distance_point_to_segment(pin_pos, sampled_points[i - 1], sampled_points[i]) <= touch_threshold:
				was_touched = true
				break
		if was_touched:
			touched.append(pin)

	return touched


func _get_player_destroyed_buildings_for_resolution(player_downed_troops: int) -> int:
	if _current_phase == LevelConfig.PHASE_OFFENSIVE:
		return int(LevelConfig.get_offensive_logical_destroyed_buildings(
			_initial_pin_count,
			player_downed_troops,
			_engagement_initial_buildings
		))
	return maxi(0, _destroyed_buildings_this_level)


func _apply_poison_resolution_before_engagement_result() -> Dictionary:
	return {
		"contacted_total": 0,
		"eligible_standing_contacted": 0,
		"poison_limit": 0,
		"poisoned_count": 0,
		"touch_source": "wind_resistance_upgrade"
	}

func _add_engagement_knock_and_poison_breakdown(summary_text: String, knocked_over_count: int, poison_kill_count: int) -> String:
	if summary_text.strip_edges() == "":
		return summary_text
	if summary_text.find("Died by poison:") != -1:
		return summary_text

	var lines: PackedStringArray = summary_text.split("\n", false)
	var breakdown_line: String = "Enemies knocked over: %d • Protected from wind: %d" % [maxi(0, knocked_over_count), maxi(0, poison_kill_count)]
	if lines.is_empty():
		return breakdown_line
	if lines.size() == 1:
		return "%s\n%s" % [lines[0], breakdown_line]

	var rebuilt_lines: PackedStringArray = PackedStringArray([lines[0], breakdown_line])
	for i in range(1, lines.size()):
		rebuilt_lines.append(lines[i])
	return "\n".join(rebuilt_lines)




func _add_poison_debug_breakdown(summary_text: String, poison_debug: Dictionary) -> String:
	if summary_text.strip_edges() == "":
		return summary_text
	if summary_text.find("Wind resist debug:") != -1:
		return summary_text

	var contacted_total: int = int(poison_debug.get("contacted_total", 0))
	var eligible_standing_contacted: int = int(poison_debug.get("eligible_standing_contacted", 0))
	var poison_limit: int = int(poison_debug.get("poison_limit", 0))
	var poisoned_count: int = int(poison_debug.get("poisoned_count", 0))
	var touch_source: String = String(poison_debug.get("touch_source", "none"))
	var debug_line: String = "Wind resist debug: source %s | touched %d | standing+touched %d | poison limit %d | poison kills applied %d" % [touch_source, contacted_total, eligible_standing_contacted, poison_limit, poisoned_count]

	var lines: PackedStringArray = summary_text.split("\n", false)
	if lines.is_empty():
		return debug_line
	if lines.size() == 1:
		return "%s\n%s" % [lines[0], debug_line]

	var rebuilt_lines: PackedStringArray = PackedStringArray([lines[0]])
	if lines.size() >= 2:
		rebuilt_lines.append(lines[1])
	rebuilt_lines.append(debug_line)
	for i in range(2, lines.size()):
		rebuilt_lines.append(lines[i])
	return "\n".join(rebuilt_lines)

func _on_upgrade_purchased(upgrade_type: String) -> void:
	if _skip_to_end_running:
		return
	var cost: int = _get_upgrade_purchase_cost(upgrade_type)
	if gold_balance < cost:
		return

	match upgrade_type:
		"bigger":
			bigger_count += 1
		"heavier":
			heavier_count += 1
		"poison":
			poison_count += 1
		"forcefield":
			forcefield_count += 1
		"magnet":
			magnet_count += 1
		_:
			return

	gold_balance -= cost
	_refresh_gold_and_upgrades_ui()
	if upgrade_type == "magnet" and ui_bridge != null and _can_show_magnet_place_button() and _get_remaining_magnet_placements() > 0:
		ui_bridge.ui_set_status("Magnet purchased — press Place Magnet, then tap the engagement map.")

	if ui and ui.has_method("trigger_upgrade_burst"):
		ui.call("trigger_upgrade_burst")

	_unlock_tutorial_notes_for_event("first_upgrade_purchased", true)
	match upgrade_type:
		"magnet":
			_unlock_tutorial_notes_for_event("first_magnet_available", true)
		"forcefield":
			_unlock_tutorial_notes_for_event("first_forcefield_purchased", true)
		"poison":
			_unlock_tutorial_notes_for_event("first_poison_purchased", true)
		_:
			pass


func _grant_free_upgrade(upgrade_type: String) -> bool:
	match upgrade_type:
		"bigger":
			permanent_bigger_count += 1
			bigger_count += 1
		"heavier":
			permanent_heavier_count += 1
			heavier_count += 1
		"poison":
			permanent_poison_count += 1
			poison_count += 1
		"forcefield":
			permanent_forcefield_count += 1
			forcefield_count += 1
		"magnet":
			permanent_magnet_count += 1
			magnet_count += 1
		_:
			return false

	_refresh_gold_and_upgrades_ui()
	if upgrade_type == "magnet" and ui_bridge != null and _can_show_magnet_place_button() and _get_remaining_magnet_placements() > 0:
		ui_bridge.ui_set_status("Permanent upgrade gained: Magnet. Press Place Magnet, then tap the engagement map.")

	if ui and ui.has_method("trigger_upgrade_burst"):
		ui.call("trigger_upgrade_burst")

	_unlock_tutorial_notes_for_event("first_upgrade_purchased", true)
	match upgrade_type:
		"magnet":
			_unlock_tutorial_notes_for_event("first_magnet_available", true)
		"forcefield":
			_unlock_tutorial_notes_for_event("first_forcefield_purchased", true)
		"poison":
			_unlock_tutorial_notes_for_event("first_poison_purchased", true)
		_:
			pass
	return true


func _get_campaign_reward_upgrade_options() -> Array[String]:
	var ordered_options: Array[String] = ["bigger", "heavier", "poison", "forcefield", "magnet"]
	var eligible_options: Array[String] = []
	for option in ordered_options:
		if _can_allocate_campaign_upgrade_discount_point(option):
			eligible_options.append(option)
	return eligible_options


func _get_campaign_boss_roll_advance_for_cycle(cycle_depth: int) -> int:
	# Boss timing should always respect LevelConfig.BOSS_SHOW_UP_ON_TURN.
	# Keep the helper in place so existing call sites stay stable, but do not
	# pre-advance the roll counter across conquered-map cycles.
	return 0


func _get_campaign_boss_show_up_turn_for_cycle(cycle_depth: int) -> int:
	var advance: int = _get_campaign_boss_roll_advance_for_cycle(cycle_depth)
	var expected_turn: int = get_campaign_expected_boss_show_up_turn()
	return maxi(1, expected_turn - advance)


func _build_campaign_reward_choice_text(summary_text: String = "") -> String:
	var lines: Array[String] = []
	var trimmed_summary: String = summary_text.strip_edges()
	if trimmed_summary != "":
		lines.append(trimmed_summary)
		lines.append("")
	lines.append("Spend %d permanent upgrade point(s). Each point reduces one in-level upgrade cost by 1." % get_campaign_permanent_upgrade_points_unspent())
	lines.append("Upgrades already at cost 1 cannot be selected.")
	lines.append(_build_campaign_upgrade_discount_summary_line())
	return "\n".join(lines)


func _begin_campaign_upgrade_choice(summary_text: String = "") -> void:
	var eligible_options: Array[String] = _get_campaign_reward_upgrade_options()
	if get_campaign_permanent_upgrade_points_unspent() <= 0 or eligible_options.is_empty():
		_advance_to_next_campaign_level(summary_text)
		return
	_skip_to_end_running = false
	_skip_to_end_cancel_requested = false
	_skip_to_end_suppress_terminal_resolution = false

	_awaiting_campaign_upgrade_choice = true
	_pending_campaign_upgrade_summary_text = summary_text.strip_edges()
	state = GameState.LEVEL_END
	_current_phase = LevelConfig.PHASE_GRAND_MAP

	var title_text: String = "Spend %d permanent upgrade point(s)" % get_campaign_permanent_upgrade_points_unspent()
	var body_text: String = _build_campaign_reward_choice_text(_pending_campaign_upgrade_summary_text)
	_unlock_tutorial_notes_for_event("first_campaign_upgrade_choice", true)
	if ui != null and ui.has_method("show_campaign_upgrade_choice"):
		ui.call("show_campaign_upgrade_choice", eligible_options, title_text, body_text)
		if ui_bridge != null:
			ui_bridge.sync_ui_button_states()
		return

	_on_campaign_upgrade_selected(String(eligible_options[0]))


func _advance_to_next_conquered_map_cycle(chosen_upgrade_type: String) -> void:
	if _campaign_transition_in_progress:
		return
	_campaign_transition_in_progress = true

	_campaign_loop_depth += 1
	var next_boss_turn: int = _get_campaign_boss_show_up_turn_for_cycle(_campaign_loop_depth)
	var chosen_label: String = chosen_upgrade_type.capitalize()
	_pending_campaign_completion_status_text = "Permanent upgrade gained: %s. Turn 1 — start from the highlighted friendly province. Boss arrives on turn %d." % [chosen_label, next_boss_turn]

	_clear_engagement_summary_wait_state()
	_prepare_for_campaign_transition()
	_current_phase = LevelConfig.PHASE_GRAND_MAP
	state = GameState.GRAND_MAP
	turn_number = 1
	_campaign_level_boss_spawn_committed = false
	_economy_initialized_turn = -1
	_reset_upgrade_counts_to_permanent_baseline()
	_locked_province_id_after_win = -1
	_active_engagement_province_id = -1
	_clear_boss_home_assault_runtime_state()
	_province_persistence.clear()
	_new_run_seed()

	if boss_system != null and boss_system.has_method("reset_all_boss_progress"):
		boss_system.reset_all_boss_progress()
		if boss_system.has_method("set_completed_grand_map_rolls"):
			boss_system.set_completed_grand_map_rolls(_get_campaign_boss_roll_advance_for_cycle(_campaign_loop_depth))

	if level_flow != null:
		level_flow.generate_grand_map()

	if _pending_campaign_completion_status_text.strip_edges() != "" and ui_bridge != null:
		ui_bridge.ui_set_status(_pending_campaign_completion_status_text)
		ui_bridge.sync_ui_button_states()
	_pending_campaign_completion_status_text = ""

	_campaign_transition_in_progress = false


func _on_campaign_upgrade_selected(upgrade_type: String) -> void:
	if not _awaiting_campaign_upgrade_choice:
		return

	if not _get_campaign_reward_upgrade_options().has(upgrade_type):
		return

	if not _apply_campaign_upgrade_discount_point(upgrade_type):
		return

	var eligible_options: Array[String] = _get_campaign_reward_upgrade_options()
	if get_campaign_permanent_upgrade_points_unspent() > 0 and not eligible_options.is_empty():
		if ui != null and ui.has_method("show_campaign_upgrade_choice"):
			var title_text: String = "Spend %d permanent upgrade point(s)" % get_campaign_permanent_upgrade_points_unspent()
			var body_text: String = _build_campaign_reward_choice_text(_pending_campaign_upgrade_summary_text)
			ui.call("show_campaign_upgrade_choice", eligible_options, title_text, body_text)
			if ui_bridge != null:
				ui_bridge.sync_ui_button_states()
			return
		_on_campaign_upgrade_selected(String(eligible_options[0]))
		return

	_awaiting_campaign_upgrade_choice = false
	if ui != null and ui.has_method("hide_campaign_upgrade_choice"):
		ui.call("hide_campaign_upgrade_choice")

	var summary_text: String = _pending_campaign_upgrade_summary_text
	_pending_campaign_upgrade_summary_text = ""
	_advance_to_next_campaign_level(summary_text)


func _on_place_magnet_pressed() -> void:
	if _skip_to_end_running:
		return
	_toggle_magnet_placement_mode()


func _on_skip_to_end_pressed() -> void:
	if _skip_to_end_running:
		_cancel_skip_to_end()
		if ui_bridge != null:
			ui_bridge.ui_set_status("Skip to End stopped.")
		return
	if not _can_show_skip_to_end_button():
		return
	_reset_skip_to_end_trace_log()
	_skip_to_end_cancel_requested = false
	_skip_to_end_running = true
	_skip_to_end_suppress_terminal_resolution = false
	_set_magnet_placement_armed(false)
	if ui_bridge != null:
		ui_bridge.ui_set_status("Skip to End active — ending turns automatically. Use Stop Skipping to halt.")
		ui_bridge.sync_ui_button_states()
	call_deferred("_run_skip_to_end_loop")


func _on_end_engagement_pressed() -> void:
	if _current_phase == LevelConfig.PHASE_GRAND_MAP:
		return
	if _skip_to_end_running:
		return
	if preview_ball and is_instance_valid(preview_ball):
		preview_ball.queue_free()
		preview_ball = null
	if aim_line:
		aim_line.visible = false
	if projection_line:
		projection_line.visible = false
	dragging = false
	_drag_pending = false
	drag_pointer_id = -1
	drag_source = DragSource.NONE
	_is_auto_charging = false
	if ball != null and is_instance_valid(ball):
		_record_live_poison_contacts()
	_finalize_ball_flight()


func _cancel_shot() -> void:
	if _skip_to_end_running:
		return
	if ball and is_instance_valid(ball):
		ball.queue_free()
		ball = null

	dragging = false
	_drag_pending = false
	drag_pointer_id = -1
	drag_source = DragSource.NONE
	_is_auto_charging = false

	if preview_ball and is_instance_valid(preview_ball):
		preview_ball.queue_free()
		preview_ball = null

	if aim_line:
		aim_line.visible = false
	if projection_line:
		projection_line.visible = false

	_restore_player_camera_view_after_follow()
	_shake_timer = 0.0
	_shake_amount = 0.0

	state = GameState.GRAND_MAP if _current_phase == "grand_map" else GameState.ENGAGEMENT
	_total_active_touches = 0
	_right_mouse_pan_active = false

	if level_flow != null:
		level_flow.refresh_engagement_live_counter()

	if ui_bridge != null:
		ui_bridge.sync_ui_button_states()
func _clear_engagement_summary_wait_state(preserve_active_engagement: bool = false) -> void:
	_awaiting_engagement_summary_ack = false
	_pending_post_summary_status_text = ""
	_pending_post_summary_lock_province_id = -1
	_pending_post_summary_enemy_turns = 0
	_pending_post_summary_skip_province_id = -1
	_pending_post_summary_preexisting_invaded_ids.clear()
	if not preserve_active_engagement:
		_active_engagement_province_id = -1
		_clear_boss_home_assault_runtime_state()
	else:
		_pending_boss_damage_status_text = ""
	_last_ball_end_reason = ""

	if province_system != null:
		province_system.clear_cached_ball_end_world_pos()

	if ui != null and ui.has_method("hide_campaign_upgrade_choice"):
		ui.call("hide_campaign_upgrade_choice")


func _restart_run() -> void:
	if is_paused:
		return

	_cancel_skip_to_end()

	_clear_engagement_summary_wait_state()
	_reset_opening_gameplay_tutorial_session_state()
	_init_tutorial_guide()

	permanent_bigger_count = 0
	permanent_heavier_count = 0
	permanent_poison_count = 0
	permanent_forcefield_count = 0
	permanent_magnet_count = 0
	_reset_upgrade_counts_to_permanent_baseline()
	_set_magnet_placement_armed(false)
	gold_balance = 0
	_economy_initialized_turn = -1
	_clear_saved_grand_map_camera_state()
	level_index = 1
	turn_number = 1
	_reset_campaign_progression_state()
	_pending_campaign_completion_status_text = ""
	_campaign_loop_depth = 0
	_awaiting_campaign_upgrade_choice = false
	_grand_map_generation_level = 1
	_clear_boss_home_assault_runtime_state()
	_province_persistence.clear()
	_locked_province_id_after_win = -1
	_active_engagement_province_id = -1

	if province_system != null:
		province_system.clear_cached_ball_end_world_pos()

	if ui != null and ui.has_method("hide_campaign_upgrade_choice"):
		ui.call("hide_campaign_upgrade_choice")

	_new_run_seed()
	if boss_system != null and boss_system.has_method("reset_all_boss_progress"):
		boss_system.reset_all_boss_progress()

	call_deferred("_begin_opening_game_flow")



func _reset_opening_gameplay_tutorial_session_state() -> void:
	_opening_gameplay_tutorial_session_started = false
	_opening_gameplay_tutorial_session_consumed = false
	for key in [
		"opening_gameplay_tutorial_active",
		"opening_gameplay_tutorial_skipped",
		"opening_gameplay_tutorial_completed",
		"opening_gameplay_tutorial_target_province_id",
		"opening_gameplay_tutorial_origin_province_id"
	]:
		if has_meta(key):
			remove_meta(key)


func _on_retry_level_pressed() -> void:
	if is_paused:
		return

	_cancel_skip_to_end()

	var retrying_engagement: bool = state != GameState.GRAND_MAP and _current_phase != "grand_map" and _active_engagement_province_id != -1
	_clear_engagement_summary_wait_state(retrying_engagement)

	if retrying_engagement:
		if level_flow != null:
			level_flow.retry_current_engagement(_active_engagement_province_id)
		return

	_begin_current_campaign_level()


func _on_load_seed_requested(new_seed: int) -> void:
	if is_paused:
		return

	var normalized_seed: int = maxi(1, int(new_seed))
	var current_cycle_depth: int = maxi(0, _campaign_loop_depth)
	var current_generation_level: int = maxi(1, _grand_map_generation_level)
	var reset_boss_rolls: int = _get_campaign_boss_roll_advance_for_cycle(current_cycle_depth)

	_cancel_skip_to_end()
	_clear_engagement_summary_wait_state()
	_set_magnet_placement_armed(false)
	_clear_saved_grand_map_camera_state()

	turn_number = 1
	level_index = 1
	_campaign_level_boss_spawn_committed = false
	_reset_campaign_progression_state()
	_economy_initialized_turn = -1
	gold_balance = 0
	_pending_campaign_completion_status_text = ""
	_awaiting_campaign_upgrade_choice = false
	_grand_map_generation_level = current_generation_level
	_clear_boss_home_assault_runtime_state()
	_province_persistence.clear()
	_locked_province_id_after_win = -1
	_active_engagement_province_id = -1
	_skip_to_end_running = false
	_skip_to_end_cancel_requested = false
	_skip_to_end_suppress_terminal_resolution = false

	_reset_upgrade_counts_to_permanent_baseline()

	if province_system != null:
		province_system.clear_cached_ball_end_world_pos()

	if ui != null and ui.has_method("hide_campaign_upgrade_choice"):
		ui.call("hide_campaign_upgrade_choice")
		if ui.has_method("set_seed_display"):
			ui.call("set_seed_display", normalized_seed)

	map_seed = normalized_seed
	_current_phase = LevelConfig.PHASE_GRAND_MAP
	state = GameState.GRAND_MAP

	if boss_system != null and boss_system.has_method("reset_all_boss_progress"):
		boss_system.reset_all_boss_progress()
		if boss_system.has_method("set_completed_grand_map_rolls"):
			boss_system.set_completed_grand_map_rolls(reset_boss_rolls)

	_show_campaign_level_mode_prompt("", true)


func _on_extra_ball_pressed() -> void:
	if _skip_to_end_running:
		return
	if state != GameState.LEVEL_END and state != GameState.GAME_OVER:
		return

	state = GameState.GRAND_MAP if _current_phase == "grand_map" else GameState.ENGAGEMENT

	if ui and ui.has_method("show_extra_ball_button"):
		ui.call("show_extra_ball_button", false)

	if ui_bridge != null:
		ui_bridge.ui_set_status("Extra Ball — drag to shoot again")

	if ball and is_instance_valid(ball):
		ball.queue_free()
		ball = null

	_cancel_shot()

	if ui_bridge != null:
		ui_bridge.sync_ui_button_states()


func _new_run_seed() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	map_seed = int(rng.randi() & 0x7fffffff)
	if map_seed == 0:
		map_seed = 1


func _get_boss_home_assault_troops() -> int:
	var fallback: int = 100
	if LevelConfig != null and LevelConfig is Script:
		var cfg: Object = LevelConfig.new()
		if cfg != null and cfg.has_method("get_boss_home_assault_troops"):
			return maxi(1, int(cfg.call("get_boss_home_assault_troops")))
	return fallback


func _clear_boss_home_assault_runtime_state(clear_pending_damage_log: bool = true) -> void:
	_boss_home_assault_active = false
	_boss_home_assault_province_id = -1
	_boss_home_assault_troop_count = 0
	if clear_pending_damage_log:
		_pending_boss_damage_status_text = ""
		_pending_boss_grand_map_shot_status_lines.clear()


func _resolve_and_format_pending_boss_part_hits(shot_label: String) -> Array[String]:
	var lines: Array[String] = []
	var clean_label: String = String(shot_label).strip_edges()
	if String(_pending_boss_part_hit).strip_edges() == "":
		return lines
	if boss_system == null or not boss_system.has_method("register_part_hit"):
		_pending_boss_part_hit = ""
		return lines
	for pending_token in String(_pending_boss_part_hit).split(",", false):
		var clean_token: String = String(pending_token).strip_edges()
		if clean_token == "":
			continue
		var hit_result: Dictionary = boss_system.register_part_hit(clean_token)
		if not bool(hit_result.get("part_destroyed", false)) and level_flow != null and level_flow.has_method("_trigger_boss_part_hit_flash"):
			level_flow.call("_trigger_boss_part_hit_flash", String(hit_result.get("part", clean_token)), int(hit_result.get("boss_id", -1)))
		var hit_text: String = "Boss hit registered: %s" % clean_token
		if boss_system.has_method("make_hit_status_text"):
			hit_text = String(boss_system.make_hit_status_text(hit_result)).strip_edges()
		if hit_text == "":
			continue
		lines.append("%s: %s" % [clean_label, hit_text] if clean_label != "" else hit_text)
	_refresh_live_boss_map_presentation()
	_pending_boss_part_hit = ""
	return lines


func _count_pending_boss_part_hits() -> int:
	var pending_hit_count: int = 0
	var pending_tokens: PackedStringArray = String(_pending_boss_part_hit).split(",", false)
	for token_any in pending_tokens:
		if String(token_any).strip_edges() != "":
			pending_hit_count += 1
	return pending_hit_count


func _queue_boss_home_assault(province_id: int) -> void:
	if province_id < 0:
		_clear_boss_home_assault_runtime_state(false)
		return
	_boss_home_assault_active = true
	_boss_home_assault_province_id = province_id
	_boss_home_assault_troop_count = _get_boss_home_assault_troops()
	if boss_system != null and boss_system.has_method("get_boss_home_troop_count_for_home_province_id"):
		_boss_home_assault_troop_count = maxi(1, int(boss_system.get_boss_home_troop_count_for_home_province_id(province_id)))


func _prepend_status_text(prefix_text: String, base_text: String) -> String:
	var clean_prefix: String = prefix_text.strip_edges()
	var clean_base: String = base_text.strip_edges()
	if clean_prefix == "":
		return clean_base
	if clean_base == "":
		return clean_prefix
	return "%s\n%s" % [clean_prefix, clean_base]

func _append_status_text(base_text: String, suffix_text: String) -> String:
	var clean_base: String = base_text.strip_edges()
	var clean_suffix: String = suffix_text.strip_edges()
	if clean_suffix == "":
		return clean_base
	if clean_base == "":
		return clean_suffix
	return "%s\n%s" % [clean_base, clean_suffix]

func _rewrite_concise_campaign_outcome_row(summary_text: String, conquered: bool, final_type: String) -> String:
	var lines: PackedStringArray = summary_text.split("\n", false)
	if lines.size() < 2:
		return summary_text
	var campaign_row: String = "Province Held"
	if conquered:
		campaign_row = "Conquered Province"
	elif _current_phase == LevelConfig.PHASE_DEFENSIVE and final_type == LevelConfig.PROVINCE_TYPE_ENEMY:
		campaign_row = "Province Lost"
	lines[1] = campaign_row
	return "\n".join(lines)

func _format_concise_hit_row(pool_name: String, start_troops: int, finish_troops: int, suffix: String = "") -> String:
	var safe_start: int = maxi(0, start_troops)
	var safe_finish: int = maxi(0, finish_troops)
	var hit_pct: int = 0
	if safe_start > 0:
		hit_pct = int(round((float(maxi(0, safe_start - safe_finish)) / float(safe_start)) * 100.0))
	var row: String = "%s: Start: %d, Finish: %d, Hit: %d%%" % [pool_name, safe_start, safe_finish, hit_pct]
	if suffix != "":
		row += " %s" % suffix
	return row

func _rewrite_concise_troop_rows(summary_text: String, start_troops: int, final_troops: int, player_only_finish_troops: int) -> String:
	var lines: PackedStringArray = summary_text.split("\n", false)
	if lines.size() < 4:
		return summary_text
	var first_pool_name: String = lines[2].split(":", false, 1)[0].strip_edges()
	if first_pool_name == "":
		return summary_text
	lines[2] = _format_concise_hit_row(first_pool_name, start_troops, final_troops)
	lines[3] = _format_concise_hit_row(first_pool_name, start_troops, player_only_finish_troops, "(Player hit count)")
	return "\n".join(lines)


func _kill_boss_from_home_assault() -> void:
	if level_flow != null and level_flow.has_method("_on_boss_killed_from_grand_map"):
		level_flow.call("_on_boss_killed_from_grand_map")
		return
	if boss_system == null:
		return
	if boss_system.has_method("get_runtime_state") and boss_system.has_method("set_runtime_state"):
		var boss_state: Dictionary = boss_system.get_runtime_state()
		boss_state["active"] = false
		boss_state["dead"] = true
		boss_state["energy_generated_this_turn"] = 0
		boss_state["energy_drained_this_turn"] = 0
		boss_state["energy_available_this_turn"] = 0
		boss_system.set_runtime_state(boss_state)


func _count_player_controlled_provinces() -> int:
	var count: int = 0
	for province_state in _province_persistence:
		if _is_player_allied_province_state(province_state):
			count += 1
	return count


func _is_player_allied_province_state(province_state: Dictionary) -> bool:
	var province_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY:
		return true
	if province_type != LevelConfig.PROVINCE_TYPE_ENEMY:
		return false
	if boss_system != null and boss_system.has_method("is_friendly_boss_faction_id"):
		return bool(boss_system.is_friendly_boss_faction_id(int(province_state.get("faction_id", 0))))
	return false


func _count_total_provinces() -> int:
	return _province_persistence.size()


func _build_campaign_completion_status_text(_reward_gold: int, _eligible_provinces: int) -> String:
	return get_campaign_between_level_summary_text()


func _update_player_capture_source_for_engagement_result(province_id: int, previous_type: String, final_type: String) -> void:
	if province_system == null or province_id < 0:
		return
	if final_type == LevelConfig.PROVINCE_TYPE_FRIENDLY and previous_type != LevelConfig.PROVINCE_TYPE_FRIENDLY:
		province_system.mark_province_captured_by_player_engagement(province_id)
	elif final_type != LevelConfig.PROVINCE_TYPE_FRIENDLY:
		province_system.clear_province_capture_source_by_id(province_id)


func _prepare_for_campaign_transition() -> void:
	if ball and is_instance_valid(ball):
		ball.queue_free()
		ball = null

	if preview_ball and is_instance_valid(preview_ball):
		preview_ball.queue_free()
		preview_ball = null

	dragging = false
	_drag_pending = false
	drag_pointer_id = -1
	drag_source = DragSource.NONE
	_is_auto_charging = false
	pan_dragging = false
	pan_drag_pointer_ids.clear()
	pan_drag_pointer_positions.clear()
	_last_touch_distance = 0.0
	_last_touch_midpoint = Vector2.ZERO
	_total_active_touches = 0
	_right_mouse_pan_active = false

	if aim_line:
		aim_line.visible = false
	if projection_line:
		projection_line.visible = false

	_restore_player_camera_view_after_follow()
	_shake_timer = 0.0
	_shake_amount = 0.0
	_clear_boss_home_assault_runtime_state()

	if province_system != null:
		province_system.clear_cached_ball_end_world_pos()


func _build_campaign_level_mode_prompt_body(summary_text: String = "") -> String:
	var lines: PackedStringArray = PackedStringArray()
	var clean_summary: String = summary_text.strip_edges()
	var level_number: int = get_campaign_current_level_progress()
	var total_levels: int = get_campaign_total_levels()
	var easy_step_gain: int = LevelConfig.get_campaign_step_advance_for_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_EASY)
	var hard_step_gain: int = LevelConfig.get_campaign_step_advance_for_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_HARD)
	var easy_boss_count: int = LevelConfig.get_campaign_boss_count_for_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_EASY, level_number)
	var hard_boss_count: int = LevelConfig.get_campaign_boss_count_for_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_HARD, level_number)
	var easy_boss_step_gain: int = LevelConfig.get_campaign_boss_progress_steps_for_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_EASY)
	var hard_boss_step_gain: int = LevelConfig.get_campaign_boss_progress_steps_for_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_HARD)
	var enemy_troops_per_level: int = LevelConfig.get_campaign_enemy_troop_increase_per_level()
	var easy_troop_bonus_gain: int = enemy_troops_per_level * maxi(0, easy_step_gain)
	var hard_troop_bonus_gain: int = enemy_troops_per_level * maxi(0, hard_step_gain)

	if clean_summary != "":
		lines.append("Previous level summary:")
		lines.append(clean_summary)
		lines.append("")

	lines.append("Choose the mode for Level %d/%d." % [level_number, total_levels])
	lines.append("Easy: %d boss, +%d campaign step, +%d boss boost step, +%d enemy province troops." % [easy_boss_count, easy_step_gain, easy_boss_step_gain, easy_troop_bonus_gain])
	lines.append("Hard: %d bosses, +%d campaign steps, +%d boss boost steps, +%d enemy province troops." % [hard_boss_count, hard_step_gain, hard_boss_step_gain, hard_troop_bonus_gain])
	return "\n".join(lines)


func _build_current_campaign_level_ready_status_text() -> String:
	return "Level %d/%d ready — %s mode selected." % [
		get_campaign_current_level_progress(),
		get_campaign_total_levels(),
		get_campaign_selected_level_mode_display_name()
	]


func _show_campaign_level_mode_prompt(summary_text: String = "", is_first_prompt: bool = false) -> void:
	if LevelConfig.is_campaign_final_level(get_campaign_current_level_progress()):
		_awaiting_campaign_level_mode_choice = false
		_pending_campaign_level_choice_summary_text = summary_text.strip_edges()
		set_campaign_selected_level_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_EASY)
		_show_pre_level_debug_config_prompt(_pending_campaign_level_choice_summary_text)
		return
	_awaiting_campaign_level_mode_choice = true
	_pending_campaign_level_choice_summary_text = summary_text.strip_edges()
	_prepare_for_campaign_transition()
	_current_phase = LevelConfig.PHASE_GRAND_MAP
	state = GameState.GRAND_MAP
	_locked_province_id_after_win = -1
	_active_engagement_province_id = -1

	var title_text: String = "Choose next level"
	if is_first_prompt and campaign_total_cleared_levels <= 0 and get_campaign_current_level_progress() <= 1:
		title_text = "Choose your first level"

	var body_text: String = _build_campaign_level_mode_prompt_body(_pending_campaign_level_choice_summary_text)
	var status_text: String = "Choose Easy or Hard for Level %d/%d." % [get_campaign_current_level_progress(), get_campaign_total_levels()]

	if ui_bridge != null:
		ui_bridge.ui_refresh_header()
		ui_bridge.ui_show_campaign_level_mode_choice(
			title_text,
			body_text,
			"Easy\n1 boss • +1 step",
			"Hard\n2 bosses • +2 steps"
		)
		ui_bridge.ui_set_status(status_text)
		ui_bridge.sync_ui_button_states()


func _show_pre_level_debug_config_prompt(summary_text: String = "") -> void:
	_awaiting_pre_level_debug_config_choice = true
	_pending_campaign_level_choice_summary_text = summary_text.strip_edges()
	var campaign_level: int = get_campaign_current_level_progress()
	var tutorial_active: bool = false
	var initial_friendly_troops: int = LevelConfig.get_runtime_initial_province_friendly_troops_for_level(campaign_level, tutorial_active)
	var boss_head_hit_points: int = LevelConfig.get_runtime_boss_head_hit_points()
	var conquered_friendly_troops: int = LevelConfig.get_runtime_conquered_province_friendly_troops_for_level(campaign_level, tutorial_active)
	var campaign_enemy_troop_increase_per_level: int = LevelConfig.get_runtime_campaign_enemy_troop_increase_per_level()
	var friendly_march_bonus_troops: int = LevelConfig.get_runtime_friendly_march_bonus_troops()
	var boss_show_up_on_turn: int = LevelConfig.get_runtime_boss_show_up_on_turn()
	var bonus_gold_per_turn: int = maxi(0, campaign_debug_bonus_gold_per_turn)
	var next_level_override: int = get_campaign_current_level_progress()
	var status_text: String = "Confirm debug settings for Level %d/%d before starting." % [get_campaign_current_level_progress(), get_campaign_total_levels()]

	if ui_bridge != null and ui_bridge.has_method("ui_show_pre_level_debug_config_choice"):
		ui_bridge.ui_show_pre_level_debug_config_choice(initial_friendly_troops, boss_head_hit_points, conquered_friendly_troops, campaign_enemy_troop_increase_per_level, friendly_march_bonus_troops, boss_show_up_on_turn, bonus_gold_per_turn, next_level_override)
		ui_bridge.ui_set_status(status_text)
		ui_bridge.sync_ui_button_states()
		return

	_on_pre_level_debug_config_confirmed(initial_friendly_troops, boss_head_hit_points, conquered_friendly_troops, campaign_enemy_troop_increase_per_level, friendly_march_bonus_troops, boss_show_up_on_turn, bonus_gold_per_turn, next_level_override)

func _apply_debug_skip_campaign_progression(target_level: int) -> void:
	var clamped_target_level: int = LevelConfig.clamp_campaign_level_progress(target_level)
	var current_level: int = get_campaign_current_level_progress()
	if clamped_target_level <= current_level:
		return
	var hard_step_advance: int = LevelConfig.get_campaign_step_advance_for_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_HARD)
	var level_gap: int = clamped_target_level - current_level
	var virtual_hard_clears: int = int(ceili(float(level_gap) / float(maxi(1, hard_step_advance))))
	var hard_boss_progress_gain: int = LevelConfig.get_campaign_boss_progress_steps_for_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_HARD)
	var hard_reward_points_gain: int = LevelConfig.get_campaign_reward_points_for_mode(LevelConfig.CAMPAIGN_LEVEL_MODE_HARD)
	var troop_bonus_per_step: int = LevelConfig.get_campaign_enemy_troop_increase_per_level()
	var hard_troop_bonus_gain: int = troop_bonus_per_step

	campaign_total_cleared_levels += virtual_hard_clears
	campaign_total_hard_clears += virtual_hard_clears
	campaign_total_boss_progress_steps += hard_boss_progress_gain * virtual_hard_clears
	campaign_enemy_troop_level_bonus_total += hard_troop_bonus_gain * virtual_hard_clears
	campaign_permanent_upgrade_points_unspent += hard_reward_points_gain * virtual_hard_clears
	campaign_level_progress = clamped_target_level

	if campaign_permanent_upgrade_points_unspent > 0:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		while campaign_permanent_upgrade_points_unspent > 0:
			var eligible_options: Array[String] = _get_campaign_reward_upgrade_options()
			if eligible_options.is_empty():
				break
			var selected_option: String = String(eligible_options[rng.randi_range(0, eligible_options.size() - 1)])
			if not _apply_campaign_upgrade_discount_point(selected_option):
				break


func _on_pre_level_debug_config_confirmed(initial_friendly_troops: int, boss_head_hit_points: int, conquered_friendly_troops: int, campaign_enemy_troop_increase_per_level: int, friendly_march_bonus_troops: int, boss_show_up_on_turn: int, bonus_gold_per_turn: int, next_level_override: int) -> void:
	_awaiting_pre_level_debug_config_choice = false
	LevelConfig.set_runtime_debug_balancing(
		maxi(1, initial_friendly_troops),
		maxi(1, boss_head_hit_points),
		maxi(1, conquered_friendly_troops),
		maxi(0, campaign_enemy_troop_increase_per_level),
		maxi(0, friendly_march_bonus_troops),
		maxi(1, boss_show_up_on_turn)
	)
	campaign_debug_bonus_gold_per_turn = maxi(0, bonus_gold_per_turn)
	_apply_debug_skip_campaign_progression(clampi(next_level_override, 1, 10))
	_rebuild_campaign_runtime_scalars()
	_begin_current_campaign_level(_pending_campaign_level_choice_summary_text)


func _spawn_bosses_for_current_campaign_level() -> String:
	if boss_system == null or level_flow == null:
		return ""
	if _campaign_level_boss_spawn_committed:
		return ""
	if _has_any_live_boss_presence_on_map_or_runtime():
		_campaign_level_boss_spawn_committed = true
		return ""
	if not level_flow.has_method("_spawn_live_boss_on_current_map"):
		return ""

	var spawn_result_variant: Variant = level_flow.call("_spawn_live_boss_on_current_map")
	if not (spawn_result_variant is Dictionary):
		return ""
	var spawn_result: Dictionary = spawn_result_variant
	if not bool(spawn_result.get("spawned", false)):
		return ""

	_campaign_level_boss_spawn_committed = true

	if level_flow.has_method("_sanitize_locked_launch_province_for_active_boss"):
		level_flow.call("_sanitize_locked_launch_province_for_active_boss")
	if province_system != null:
		province_system.apply_persistence_to_province_visuals()
	if ui_bridge != null:
		ui_bridge.sync_ui_button_states()

	if level_flow.has_method("_build_boss_spawn_status_text"):
		return String(level_flow.call("_build_boss_spawn_status_text", spawn_result)).strip_edges()
	return "Boss forces deployed."


func _should_spawn_bosses_for_current_turn(require_grand_map_state: bool = true) -> bool:
	if _campaign_transition_in_progress or _awaiting_campaign_level_mode_choice or _awaiting_pre_level_debug_config_choice:
		return false
	if require_grand_map_state:
		if _current_phase != LevelConfig.PHASE_GRAND_MAP:
			return false
		if state != GameState.GRAND_MAP:
			return false
	if turn_number < get_campaign_expected_boss_show_up_turn():
		return false
	if boss_system == null or level_flow == null:
		return false
	if _province_persistence.is_empty():
		return false
	if _campaign_level_boss_spawn_committed:
		return false
	if _has_any_live_boss_presence_on_map_or_runtime():
		_campaign_level_boss_spawn_committed = true
		return false
	return true


func _maybe_spawn_bosses_for_current_turn(update_status_text: bool = true) -> void:
	if not _should_spawn_bosses_for_current_turn():
		return
	var boss_status_text: String = _spawn_bosses_for_current_campaign_level().strip_edges()
	if boss_status_text == "":
		if ui_bridge != null and update_status_text:
			ui_bridge.sync_ui_button_states()
		return
	_campaign_level_boss_spawn_committed = true
	if ui_bridge != null and update_status_text:
		ui_bridge.ui_set_status(boss_status_text)
		ui_bridge.sync_ui_button_states()


func _resolve_due_boss_arrivals_at_turn_end() -> Array[String]:
	var status_lines: Array[String] = []
	# Turn-end resolution can run while UI state is still LEVEL_END/ENGAGEMENT.
	# Do not require GRAND_MAP state here; this keeps scheduled arrivals aligned
	# for normal progression, reinforcement flows, and summary-ack flows.
	if not _should_spawn_bosses_for_current_turn(false):
		return status_lines
	var boss_status_text: String = _spawn_bosses_for_current_campaign_level().strip_edges()
	if boss_status_text == "":
		return status_lines
	status_lines.append(boss_status_text)
	_campaign_level_boss_spawn_committed = true
	return status_lines


func _begin_current_campaign_level(summary_text: String = "") -> void:
	_awaiting_campaign_level_mode_choice = false
	_awaiting_pre_level_debug_config_choice = false
	_pending_campaign_level_choice_summary_text = ""
	_campaign_transition_in_progress = true
	_skip_to_end_running = false
	_skip_to_end_cancel_requested = false
	_skip_to_end_suppress_terminal_resolution = false

	_clear_engagement_summary_wait_state()
	_prepare_for_campaign_transition()
	_current_phase = LevelConfig.PHASE_GRAND_MAP
	state = GameState.GRAND_MAP
	turn_number = 1
	_campaign_level_boss_spawn_committed = false
	_economy_initialized_turn = -1
	_locked_province_id_after_win = -1
	_active_engagement_province_id = -1
	_clear_boss_home_assault_runtime_state()
	_province_persistence.clear()

	if ui_bridge != null:
		ui_bridge.ui_hide_campaign_level_mode_choice()
		if ui_bridge.has_method("ui_hide_pre_level_debug_config_choice"):
			ui_bridge.ui_hide_pre_level_debug_config_choice()

	if boss_system != null and boss_system.has_method("reset_all_boss_progress"):
		boss_system.reset_all_boss_progress()

	if level_flow != null:
		level_flow.generate_grand_map()
	_apply_initial_friendly_province_troop_override_for_turn_start()

	var status_text: String = _build_current_campaign_level_ready_status_text()

	if ui_bridge != null:
		ui_bridge.ui_set_status(status_text)
		ui_bridge.sync_ui_button_states()

	_campaign_transition_in_progress = false
	_maybe_spawn_bosses_for_current_turn(true)


func _apply_initial_friendly_province_troop_override_for_turn_start() -> void:
	if turn_number != 1:
		return
	if _province_persistence.is_empty():
		return
	var desired_troops: int = LevelConfig.get_runtime_initial_province_friendly_troops()
	var changed: bool = false
	for province_state_any in _province_persistence:
		if not (province_state_any is Dictionary):
			continue
		var province_state: Dictionary = province_state_any as Dictionary
		if String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) != LevelConfig.PROVINCE_TYPE_FRIENDLY:
			continue
		if int(province_state.get("remaining_troops", -1)) != desired_troops:
			province_state["remaining_troops"] = desired_troops
			changed = true
	if changed and province_system != null and province_system.has_method("apply_persistence_to_province_visuals"):
		province_system.apply_persistence_to_province_visuals()


func _on_campaign_level_mode_selected(level_mode: String) -> void:
	set_campaign_selected_level_mode(level_mode)
	_show_pre_level_debug_config_prompt(_pending_campaign_level_choice_summary_text)


func _enter_game_over_state() -> void:
	if _campaign_transition_in_progress:
		return
	_skip_to_end_running = false
	_skip_to_end_cancel_requested = false
	_skip_to_end_suppress_terminal_resolution = false
	_campaign_transition_in_progress = true

	_clear_engagement_summary_wait_state()
	_prepare_for_campaign_transition()
	_current_phase = LevelConfig.PHASE_GRAND_MAP
	_locked_province_id_after_win = -1
	_active_engagement_province_id = -1
	state = GameState.GAME_OVER

	if ui_bridge != null:
		ui_bridge.ui_refresh_header()
		ui_bridge.ui_set_status("You Lose")
		ui_bridge.sync_ui_button_states()

	_campaign_transition_in_progress = false


func _enter_campaign_complete_state(summary_text: String = "") -> void:
	if _campaign_transition_in_progress:
		return
	_skip_to_end_running = false
	_skip_to_end_cancel_requested = false
	_skip_to_end_suppress_terminal_resolution = false
	_campaign_transition_in_progress = true

	_pending_campaign_completion_status_text = summary_text

	_clear_engagement_summary_wait_state()
	_prepare_for_campaign_transition()
	_current_phase = LevelConfig.PHASE_GRAND_MAP
	_locked_province_id_after_win = -1
	_active_engagement_province_id = -1
	state = GameState.GAME_OVER

	if ui_bridge != null:
		ui_bridge.ui_refresh_header()
		ui_bridge.ui_set_status("You Win")
		ui_bridge.sync_ui_button_states()

	_pending_campaign_completion_status_text = ""
	_campaign_transition_in_progress = false


func _advance_to_next_campaign_level(completion_status_text: String = "") -> void:
	if _campaign_transition_in_progress:
		return
	_skip_to_end_running = false
	_skip_to_end_cancel_requested = false
	_skip_to_end_suppress_terminal_resolution = false
	_campaign_transition_in_progress = true

	_pending_campaign_completion_status_text = completion_status_text

	_clear_engagement_summary_wait_state()
	_prepare_for_campaign_transition()
	_current_phase = LevelConfig.PHASE_GRAND_MAP
	state = GameState.GRAND_MAP
	turn_number = 1
	_campaign_level_boss_spawn_committed = false
	_grand_map_generation_level += 1
	_locked_province_id_after_win = -1
	_active_engagement_province_id = -1
	_clear_boss_home_assault_runtime_state()
	_province_persistence.clear()

	_new_run_seed()

	if boss_system != null and boss_system.has_method("reset_all_boss_progress"):
		boss_system.reset_all_boss_progress()

	_campaign_transition_in_progress = false
	_show_campaign_level_mode_prompt(String(_pending_campaign_completion_status_text).strip_edges(), false)
	_pending_campaign_completion_status_text = ""


func _advance_to_next_random_level(completion_status_text: String = "") -> void:
	_advance_to_next_campaign_level(completion_status_text)


func _refresh_live_boss_map_presentation() -> void:
	if level_flow == null:
		return
	if level_flow.has_method("refresh_live_boss_map_presentation"):
		level_flow.refresh_live_boss_map_presentation()


func _try_finalize_live_boss_grand_map_settlement(end_world_pos: Vector2, has_live_ball: bool) -> bool:
	if level_flow == null:
		return false
	if not level_flow.has_method("try_finalize_live_boss_grand_map_settlement"):
		return false
	return bool(level_flow.try_finalize_live_boss_grand_map_settlement(end_world_pos, has_live_ball))


func _handle_campaign_map_completion() -> bool:
	if _skip_to_end_suppress_terminal_resolution:
		return false
	var total_provinces: int = _count_total_provinces()
	if total_provinces <= 0:
		return false

	var player_controlled: int = _count_player_controlled_provinces()
	if player_controlled <= 0:
		_enter_game_over_state()
		return true

	if player_controlled >= total_provinces:
		if _handle_full_conquest_before_boss_arrival():
			return true
		_complete_current_campaign_level_from_conquest()
		return true

	return false


func _handle_full_conquest_before_boss_arrival() -> bool:
	if turn_number >= get_campaign_expected_boss_show_up_turn():
		return false
	if _campaign_transition_in_progress or _awaiting_campaign_level_mode_choice or _awaiting_pre_level_debug_config_choice:
		return false
	if _campaign_level_boss_spawn_committed:
		return false
	if boss_system == null or level_flow == null:
		return false
	if _has_any_live_boss_presence_on_map_or_runtime():
		_campaign_level_boss_spawn_committed = true
		return false
	var boss_status_text: String = _spawn_bosses_for_current_campaign_level().strip_edges()
	if boss_status_text == "":
		return false
	state = GameState.GRAND_MAP
	_current_phase = LevelConfig.PHASE_GRAND_MAP
	var status_text: String = "All provinces captured before boss arrival. %s" % boss_status_text
	if ui_bridge != null:
		ui_bridge.ui_set_status(status_text)
		ui_bridge.sync_ui_button_states()
	return true


# =============================================================================
# UNIFIED BALL FLIGHT FINALIZATION — GRAND MAP FIXED
# =============================================================================
func _finalize_ball_flight() -> void:
	var has_live_ball: bool = ball != null and is_instance_valid(ball)
	var has_end_world_pos: bool = _has_last_ball_end_world_pos or has_live_ball
	var end_world_pos: Vector2 = Vector2.ZERO

	if has_end_world_pos:
		if province_system != null:
			end_world_pos = province_system.resolve_ball_end_world_pos()
		else:
			end_world_pos = ball.global_position if has_live_ball else Vector2.ZERO

	if _current_phase == "grand_map":
		if _try_finalize_live_boss_grand_map_settlement(end_world_pos, has_live_ball):
			return
		if not has_end_world_pos:
			_restore_player_camera_view_after_follow()
			state = GameState.GRAND_MAP
			if ui_bridge != null:
				ui_bridge.sync_ui_button_states()
			return

		var data: Dictionary = {}
		if province_system != null:
			data = province_system.get_province_data(end_world_pos)
			province_system.clear_cached_ball_end_world_pos()

		_active_engagement_province_id = int(data.get("id", -1))
		_friendly_boss_assist_phase_active = false
		_friendly_boss_assist_province_id = -1
		var province_type: String = String(data.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		var invading_troops: int = int(data.get("invading_troops", 0))
		var friendly_boss_invasion_pending: bool = bool(data.get("friendly_boss_invasion_pending", false))
		var landed_on_boss_home: bool = false
		var landed_on_friendly_boss_province: bool = false
		var boss_damage_status_text: String = ""
		var existing_boss_damage_status_text: String = String(_pending_boss_damage_status_text).strip_edges()

		if boss_system != null and boss_system.has_method("is_boss_home_province_id"):
			landed_on_boss_home = bool(boss_system.is_boss_home_province_id(_active_engagement_province_id))
		if province_type == LevelConfig.PROVINCE_TYPE_ENEMY and boss_system != null and boss_system.has_method("is_friendly_boss_faction_id"):
			landed_on_friendly_boss_province = bool(boss_system.is_friendly_boss_faction_id(int(data.get("faction_id", 0))))
		var landed_on_hostile_boss_home: bool = landed_on_boss_home and not landed_on_friendly_boss_province

		var grand_map_hit_lines: Array[String] = _resolve_and_format_pending_boss_part_hits("Grand map shot")
		if not grand_map_hit_lines.is_empty():
			boss_damage_status_text = "\n".join(grand_map_hit_lines)
			_pending_boss_grand_map_shot_status_lines = grand_map_hit_lines.duplicate()
		if boss_damage_status_text.strip_edges() != "":
			_pending_boss_damage_status_text = _prepend_status_text(boss_damage_status_text, existing_boss_damage_status_text)
		else:
			_pending_boss_damage_status_text = existing_boss_damage_status_text

		if has_live_ball:
			ball.queue_free()
			ball = null
		_reset_live_poison_tracking()

		_restore_player_camera_view_after_follow()

		var has_active_friendly_boss: bool = false
		if boss_system != null and boss_system.has_method("get_active_boss_states"):
			var active_boss_states_any: Variant = boss_system.get_active_boss_states()
			if active_boss_states_any is Array:
				for boss_state_any in active_boss_states_any:
					if boss_state_any is Dictionary and bool((boss_state_any as Dictionary).get("is_friendly_boss", false)):
						has_active_friendly_boss = true
						break

		if landed_on_hostile_boss_home:
			_queue_boss_home_assault(_active_engagement_province_id)
			_current_phase = "offensive"
		elif friendly_boss_invasion_pending and has_active_friendly_boss:
			_friendly_boss_assist_phase_active = true
			_friendly_boss_assist_province_id = _active_engagement_province_id
			_current_phase = "offensive"
		elif province_type == LevelConfig.PROVINCE_TYPE_ENEMY and not landed_on_friendly_boss_province:
			_clear_boss_home_assault_runtime_state(false)
			_current_phase = "offensive"
		elif province_type == LevelConfig.PROVINCE_TYPE_FRIENDLY or landed_on_friendly_boss_province:
			_clear_boss_home_assault_runtime_state(false)
			if invading_troops > 0:
				_current_phase = "defensive"
			else:
				_current_phase = "grand_map"
				if province_system != null and _active_engagement_province_id != -1:
					var friendly_idx: int = province_system.find_persistence_index_by_id(_active_engagement_province_id)
					if friendly_idx != -1:
						var friendly_state: Dictionary = _province_persistence[friendly_idx]
						var current_buildings: int = int(friendly_state.get("remaining_buildings", 0))
						var building_cap: int = int(LevelConfig.PROVINCE_BUILDING_CAP)
						if province_system != null and province_system.has_method("get_province_building_capacity"):
							building_cap = int(province_system.get_province_building_capacity(friendly_state))
						friendly_state["remaining_buildings"] = min(current_buildings + 1, building_cap)
				var fortify_status_text: String = "Province fortified. +1 building."
				fortify_status_text = _prepend_status_text(_pending_boss_damage_status_text, fortify_status_text)
				_pending_boss_damage_status_text = ""
				if enemy_turn_system != null:
					enemy_turn_system.advance_grand_map_turn_after_rest(fortify_status_text, _active_engagement_province_id)
				else:
					level_index += 1
					turn_number += 1
					_locked_province_id_after_win = _active_engagement_province_id
					if level_flow != null:
						level_flow.generate_grand_map()
					if ui_bridge != null:
						ui_bridge.ui_set_status(fortify_status_text)
						ui_bridge.sync_ui_button_states()
				_active_engagement_province_id = -1
				state = GameState.GRAND_MAP
				return
		else:
			_clear_boss_home_assault_runtime_state(false)
			_current_phase = "neutral"

		if level_flow != null:
			level_flow.spawn_engagement(_active_engagement_province_id)

		state = GameState.ENGAGEMENT
		return

	if has_live_ball and not _has_last_ball_end_world_pos and province_system != null:
		province_system.cache_ball_end_world_pos(ball.global_position)

	var poison_resolution: Dictionary = {
		"contacted_total": 0,
		"eligible_standing_contacted": 0,
		"poison_limit": maxi(0, poison_count),
		"poisoned_count": 0
	}
	var poison_kills_this_shot: int = 0
	var preserve_ball_visual_for_summary: bool = false
	if has_live_ball:
		if ball.has_method("is_sunk_in_water"):
			preserve_ball_visual_for_summary = bool(ball.call("is_sunk_in_water"))
		poison_resolution = _apply_poison_resolution_before_engagement_result()
		poison_kills_this_shot = int(poison_resolution.get("poisoned_count", 0))
		preserve_ball_visual_for_summary = true
		ball.linear_velocity = Vector2.ZERO
		ball.angular_velocity = 0.0
		ball.sleeping = true
		ball.freeze = true
		ball.collision_layer = 0
		ball.collision_mask = 0
		ball.visible = true
		ball.z_as_relative = false
		ball.z_index = max(ball.z_index, LevelConfig.VISUAL_LAYER_SPECIAL_GAMEPLAY_ACTORS)
		if ball.has_method("clear_summary_opacity"):
			ball.call("clear_summary_opacity")
	_reset_live_poison_tracking()

	_restore_player_camera_view_after_follow()

	if engagement_resolver != null:
		var province_id := _active_engagement_province_id
		if province_id == -1:
			push_warning("_finalize_ball_flight called for engagement without an active province id.")
			if province_system != null:
				province_system.clear_cached_ball_end_world_pos()
			_current_phase = "grand_map"
			state = GameState.GRAND_MAP
			if level_flow != null:
				level_flow.generate_grand_map()
			if ui_bridge != null:
				ui_bridge.ui_set_status("Engagement ended, but province context was lost.")
				ui_bridge.sync_ui_button_states()
			return

		var has_active_friendly_boss: bool = false
		if boss_system != null and boss_system.has_method("get_active_boss_states"):
			var engagement_active_boss_states_any: Variant = boss_system.get_active_boss_states()
			if engagement_active_boss_states_any is Array:
				for boss_state_any in engagement_active_boss_states_any:
					if boss_state_any is Dictionary and bool((boss_state_any as Dictionary).get("is_friendly_boss", false)):
						has_active_friendly_boss = true
						break

		var player_downed_troops: int = _initial_pin_count - (level_flow.count_standing_pins() if level_flow != null else 0)
		var player_destroyed_buildings: int = _get_player_destroyed_buildings_for_resolution(player_downed_troops)
		var landed_on_any_boss_home_for_threshold: bool = false
		var landed_on_friendly_boss_province_for_threshold: bool = false
		if boss_system != null and boss_system.has_method("is_boss_home_province_id"):
			landed_on_any_boss_home_for_threshold = bool(boss_system.is_boss_home_province_id(province_id))
		if province_system != null and boss_system != null and boss_system.has_method("is_friendly_boss_faction_id"):
			var threshold_province_idx: int = province_system.find_persistence_index_by_id(province_id)
			if threshold_province_idx != -1:
				var threshold_province_state: Dictionary = _province_persistence[threshold_province_idx]
				if String(threshold_province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_ENEMY:
					landed_on_friendly_boss_province_for_threshold = bool(boss_system.is_friendly_boss_faction_id(int(threshold_province_state.get("faction_id", 0))))
		var boss_part_hit_troop_credit: int = 0
		if landed_on_any_boss_home_for_threshold and not landed_on_friendly_boss_province_for_threshold:
			# Count boss-part hitpoint removals as downed troops for engagement thresholding and outcome persistence.
			boss_part_hit_troop_credit = _count_pending_boss_part_hits() * 5
			player_downed_troops += boss_part_hit_troop_credit
		var input_dict := {
			"player_participating": true,
			"troops_A": 0,
			"troops_B": _initial_pin_count,
			"buildings_A": 0,
			"buildings_B": _engagement_initial_buildings,
			"player_downed_troops": player_downed_troops,
			"player_destroyed_buildings": player_destroyed_buildings,
			"boss_part_hit_troop_credit": 0,
			"province_id": province_id,
			"friendly_boss_assist_mode": _friendly_boss_assist_phase_active and province_id == _friendly_boss_assist_province_id and has_active_friendly_boss
		}

		var preexisting_invaded_province_ids: Array[int] = []
		if enemy_turn_system != null:
			preexisting_invaded_province_ids = enemy_turn_system.get_invaded_friendly_province_ids()

		var gold_before_resolution: int = gold_balance
		var outcome: Dictionary = engagement_resolver.resolve_engagement(input_dict)
		if bool(outcome.get("grant_reward", false)):
			gold_balance = gold_before_resolution

		var runtime_boss_home_assault: bool = _boss_home_assault_active and province_id == _boss_home_assault_province_id
		var landed_on_any_boss_home: bool = false
		var landed_on_friendly_boss_province: bool = false
		if boss_system != null and boss_system.has_method("is_boss_home_province_id"):
			landed_on_any_boss_home = bool(boss_system.is_boss_home_province_id(province_id))
		if province_system != null and boss_system != null and boss_system.has_method("is_friendly_boss_faction_id"):
			var province_idx_for_boss_check: int = province_system.find_persistence_index_by_id(province_id)
			if province_idx_for_boss_check != -1:
				var boss_check_state: Dictionary = _province_persistence[province_idx_for_boss_check]
				if String(boss_check_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)) == LevelConfig.PROVINCE_TYPE_ENEMY:
					landed_on_friendly_boss_province = bool(boss_system.is_friendly_boss_faction_id(int(boss_check_state.get("faction_id", 0))))

		# Keep boss-home troop-to-hitpoint damage reliable even if runtime assault flags are reset while navigating between provinces.
		var is_boss_home_assault: bool = runtime_boss_home_assault or (landed_on_any_boss_home and not landed_on_friendly_boss_province)
		var boss_home_assault_status_text: String = ""
		var boss_home_assault_killed: bool = false
		if is_boss_home_assault:
			var engagement_hit_lines: Array[String] = _resolve_and_format_pending_boss_part_hits("Engagement shot")
			if not engagement_hit_lines.is_empty():
				var existing_engagement_text: String = String(_pending_boss_damage_status_text).strip_edges()
				_pending_boss_damage_status_text = _prepend_status_text("\n".join(engagement_hit_lines), existing_engagement_text)
			var troops_destroyed: int = maxi(0, int(input_dict.get("player_downed_troops", 0)))
			var assault_rng: RandomNumberGenerator = RandomNumberGenerator.new()
			assault_rng.seed = maxi(1, int(map_seed)) * 977 + maxi(0, int(turn_number)) * 131 + maxi(0, province_id) * 17 + troops_destroyed
			var loss_result: Dictionary = {}
			if boss_system != null and boss_system.has_method("apply_home_province_troop_losses_for_home_province_id"):
				loss_result = boss_system.apply_home_province_troop_losses_for_home_province_id(troops_destroyed, assault_rng, province_id)
			var removed_hit_points: int = maxi(0, int(loss_result.get("troop_chunks_applied", 0)))
			var attacking_boss_troops_start: int = 0
			var assault_province_idx: int = -1
			if province_system != null:
				assault_province_idx = province_system.find_persistence_index_by_id(province_id)
				if assault_province_idx != -1:
					var assault_province_state: Dictionary = _province_persistence[assault_province_idx]
					attacking_boss_troops_start = maxi(0, int(assault_province_state.get("friendly_boss_invading_troops", 0)))
			var defending_boss_troops_after_player: int = 0
			if boss_system != null and boss_system.has_method("get_boss_home_troop_count_for_home_province_id"):
				defending_boss_troops_after_player = maxi(0, int(boss_system.get_boss_home_troop_count_for_home_province_id(province_id)))
			else:
				defending_boss_troops_after_player = maxi(0, int(outcome.get("final_troops_B", 0)))
			var mutual_boss_losses: int = mini(attacking_boss_troops_start, defending_boss_troops_after_player)
			var attacking_boss_troops_after: int = maxi(0, attacking_boss_troops_start - mutual_boss_losses)
			var defending_boss_troops_after: int = maxi(0, defending_boss_troops_after_player - mutual_boss_losses)
			if defending_boss_troops_after_player > 0 and boss_system != null and boss_system.has_method("apply_home_province_troop_losses_for_home_province_id"):
				var mutual_rng: RandomNumberGenerator = RandomNumberGenerator.new()
				mutual_rng.seed = maxi(1, int(map_seed)) * 1193 + maxi(0, int(turn_number)) * 173 + maxi(0, province_id) * 41 + attacking_boss_troops_start + defending_boss_troops_after_player
				var mutual_loss_result: Dictionary = boss_system.apply_home_province_troop_losses_for_home_province_id(mutual_boss_losses, mutual_rng, province_id)
				defending_boss_troops_after = maxi(0, int(mutual_loss_result.get("remaining_troops", defending_boss_troops_after)))
			if assault_province_idx != -1:
				var post_assault_state: Dictionary = _province_persistence[assault_province_idx]
				post_assault_state["friendly_boss_invading_troops"] = attacking_boss_troops_after
				# Player intervention resolves the in-progress boss-vs-boss clash immediately;
				# prevent enemy-turn deferred resolution from replaying the same losses.
				post_assault_state["friendly_boss_invasion_pending"] = false
				post_assault_state["friendly_boss_invasion_started_turn"] = -1
				if attacking_boss_troops_after <= 0:
					post_assault_state["friendly_boss_invader_id"] = -1
			outcome["final_troops_B"] = defending_boss_troops_after
			outcome["concise_primary_pool_finish_troops"] = defending_boss_troops_after
			if attacking_boss_troops_start > 0:
				boss_home_assault_status_text = "Troop knock-over damage: %d troops destroyed, %d hitpoint%s removed. Remaining boss troops then fought 1-for-1: friendly boss lost %d troop%s and enemy boss lost %d troop%s. Friendly boss troops left: %d. Enemy boss troops left: %d." % [
					troops_destroyed,
					removed_hit_points,
					"" if removed_hit_points == 1 else "s",
					mutual_boss_losses,
					"" if mutual_boss_losses == 1 else "s",
					mutual_boss_losses,
					"" if mutual_boss_losses == 1 else "s",
					attacking_boss_troops_after,
					defending_boss_troops_after
				]
			else:
				boss_home_assault_status_text = "Troop knock-over damage: %d troops destroyed, %d hitpoint%s removed. Enemy boss troops left: %d." % [
					troops_destroyed,
					removed_hit_points,
					"" if removed_hit_points == 1 else "s",
					defending_boss_troops_after
				]
			if bool(loss_result.get("boss_killed", false)) and level_flow != null and level_flow.has_method("_on_boss_killed_from_grand_map"):
				boss_home_assault_killed = true
				level_flow.call("_on_boss_killed_from_grand_map", int(loss_result.get("boss_id", -1)))
				outcome["province_type_after"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
				outcome["conquered"] = true
				outcome["lock_province_id"] = province_id
			if level_flow != null and level_flow.has_method("sync_active_boss_home_province_stats"):
				level_flow.call("sync_active_boss_home_province_stats")
			_refresh_live_boss_map_presentation()

		var summary_with_breakdown: String = String(outcome.get("summary_text", outcome.get("post_summary_status_text", "")))
		var detailed_summary_with_breakdown: String = String(outcome.get("detailed_summary_text", summary_with_breakdown))
		if is_boss_home_assault and not _pending_boss_grand_map_shot_status_lines.is_empty():
			var boss_lines := "\n".join(_pending_boss_grand_map_shot_status_lines)
			summary_with_breakdown = _append_status_text(summary_with_breakdown, boss_lines)
			detailed_summary_with_breakdown = _append_status_text(detailed_summary_with_breakdown, boss_lines)
			_pending_boss_grand_map_shot_status_lines.clear()
		if boss_home_assault_status_text.strip_edges() != "":
			summary_with_breakdown = _append_status_text(summary_with_breakdown, boss_home_assault_status_text)
			detailed_summary_with_breakdown = _append_status_text(detailed_summary_with_breakdown, boss_home_assault_status_text)
		if _pending_boss_damage_status_text.strip_edges() != "":
			summary_with_breakdown = _append_status_text(summary_with_breakdown, _pending_boss_damage_status_text)
			detailed_summary_with_breakdown = _append_status_text(detailed_summary_with_breakdown, _pending_boss_damage_status_text)
		_pending_boss_damage_status_text = ""
		summary_with_breakdown = _rewrite_concise_campaign_outcome_row(
			summary_with_breakdown,
			bool(outcome.get("conquered", false)),
			String(outcome.get("province_type_after", LevelConfig.PROVINCE_TYPE_NEUTRAL))
		)
		summary_with_breakdown = _rewrite_concise_troop_rows(
			summary_with_breakdown,
			int(outcome.get("engagement_starting_troops_B", 0)),
			int(outcome.get("concise_primary_pool_finish_troops", outcome.get("final_troops_B", 0))),
			int(outcome.get("player_result_ending_troops", 0)) if _current_phase == LevelConfig.PHASE_DEFENSIVE else int(outcome.get("player_only_ending_troops_B", 0))
		)
		outcome["summary_text"] = detailed_summary_with_breakdown
		outcome["post_summary_status_text"] = summary_with_breakdown

		if province_system != null and province_id != -1:
			var idx: int = province_system.find_persistence_index_by_id(province_id)
			if idx != -1:
				var province_state: Dictionary = _province_persistence[idx]
				var previous_type: String = String(province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
				var final_type: String = String(outcome.get("province_type_after", province_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL)))
				var building_cap: int = int(LevelConfig.PROVINCE_BUILDING_CAP)
				if province_system != null and province_system.has_method("get_province_building_capacity"):
					building_cap = int(province_system.get_province_building_capacity(province_state))
				var final_buildings: int = min(int(outcome.get("final_buildings_B", province_state.get("remaining_buildings", 0))), building_cap)
				province_state["remaining_buildings"] = final_buildings
				province_state["construction_progress"] = int(outcome.get("construction_progress_after", province_state.get("construction_progress", 0)))

				if _current_phase == "defensive":
					province_state["type"] = final_type
					province_state["remaining_buildings"] = final_buildings
					province_state["remaining_troops"] = int(outcome.get("final_resident_troops", province_state.get("remaining_troops", 0)))

					if final_type == LevelConfig.PROVINCE_TYPE_ENEMY:
						province_state["remaining_troops"] = int(outcome.get("final_resident_troops", outcome.get("final_troops_B", province_state.get("remaining_troops", 0))))
						province_state["invading_troops"] = 0
						province_state["faction_id"] = int(outcome.get("faction_after", province_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT)))
						province_system.clear_province_capture_source_by_id(province_id)
					else:
						province_state["remaining_troops"] = int(outcome.get("final_resident_troops", province_state.get("remaining_troops", 0)))
						province_state["invading_troops"] = int(outcome.get("final_invading_troops", outcome.get("final_troops_B", province_state.get("invading_troops", 0))))
						if int(province_state.get("invading_troops", 0)) > 0:
							province_state["faction_id"] = int(province_state.get("faction_id", LevelConfig.ENEMY_FACTION_DEFAULT))
						else:
							province_state["faction_id"] = 0
							province_system.clear_province_capture_source_by_id(province_id)
				else:
					province_state["remaining_troops"] = int(outcome.get("final_troops_B", province_state.get("remaining_troops", 0)))
					province_state["type"] = final_type
					province_state["faction_id"] = outcome.get("faction_after", province_state.get("faction_id", 0))
					if outcome.get("conquered", false):
						province_state["invading_troops"] = 0
					_update_player_capture_source_for_engagement_result(province_id, previous_type, final_type)
				if is_boss_home_assault and boss_home_assault_killed:
					province_state["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
					province_state["faction_id"] = 0
					province_state["invading_troops"] = 0
					var player_killed_boss: bool = bool(outcome.get("conquered", false))
					if player_killed_boss:
						province_state["remaining_troops"] = LevelConfig.get_runtime_initial_province_friendly_troops()
					else:
						province_state["remaining_troops"] = maxi(0, int(outcome.get("final_resident_troops", province_state.get("remaining_troops", 0))))
					_update_player_capture_source_for_engagement_result(province_id, previous_type, LevelConfig.PROVINCE_TYPE_FRIENDLY)
					if province_system.has_method("clear_province_capture_source_by_id"):
						province_system.clear_province_capture_source_by_id(province_id)
		if _friendly_boss_assist_phase_active and province_id == _friendly_boss_assist_province_id and has_active_friendly_boss and province_system != null and boss_system != null:
			var assist_idx: int = province_system.find_persistence_index_by_id(province_id)
			if assist_idx >= 0:
				var assist_state: Dictionary = _province_persistence[assist_idx]
				var boss_invading_troops: int = maxi(0, int(assist_state.get("friendly_boss_invading_troops", 0)))
				var enemy_boss_killed_by_player: bool = bool(outcome.get("conquered", false)) and String(outcome.get("province_type_after", assist_state.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))) == LevelConfig.PROVINCE_TYPE_FRIENDLY
				var defending_troops_after_player: int = 0 if enemy_boss_killed_by_player else maxi(0, int(assist_state.get("remaining_troops", 0)))
				var mutual_losses: int = mini(boss_invading_troops, defending_troops_after_player)
				var surviving_boss_troops: int = boss_invading_troops - mutual_losses
				var surviving_defenders: int = defending_troops_after_player - mutual_losses
				if enemy_boss_killed_by_player:
					assist_state["remaining_troops"] = maxi(0, int(assist_state.get("remaining_troops", 0)))
				else:
					assist_state["remaining_troops"] = surviving_defenders
				assist_state["friendly_boss_invasion_pending"] = false
				assist_state["friendly_boss_invading_troops"] = 0
				if not enemy_boss_killed_by_player and surviving_defenders <= 0:
					assist_state["remaining_buildings"] = 0
				if boss_system.has_method("get_active_boss_states") and boss_system.has_method("apply_home_province_troop_losses"):
					var friendly_boss_id: int = -1
					var active_states_any: Variant = boss_system.get_active_boss_states()
					if active_states_any is Array:
						for state_any in active_states_any:
							if state_any is Dictionary:
								var active_boss_state: Dictionary = state_any
								if not bool(active_boss_state.get("is_friendly_boss", false)):
									continue
								friendly_boss_id = int(active_boss_state.get("boss_id", -1))
								break
					if friendly_boss_id >= 0:
						var rng := RandomNumberGenerator.new()
						rng.seed = int(map_seed) * 3343 + int(turn_number) * 31 + province_id
						if enemy_boss_killed_by_player:
							assist_state["type"] = LevelConfig.PROVINCE_TYPE_FRIENDLY
							assist_state["faction_id"] = 0
							assist_state["friendly_boss_resident_id"] = friendly_boss_id
							assist_state["friendly_boss_base_troops"] = maxi(0, int(assist_state.get("remaining_troops", 0)))
							assist_state["friendly_boss_invader_id"] = -1
							assist_state["friendly_boss_invasion_started_turn"] = -1
							if boss_system.has_method("set_boss_current_province_id"):
								boss_system.set_boss_current_province_id(friendly_boss_id, province_id)
						if not enemy_boss_killed_by_player:
							boss_system.apply_home_province_troop_losses(mutual_losses, rng, friendly_boss_id)
						if boss_system.has_method("get_boss_current_province_id"):
							var boss_province_id: int = int(boss_system.get_boss_current_province_id(friendly_boss_id))
							var boss_province_idx: int = province_system.find_persistence_index_by_id(boss_province_id)
							if boss_province_idx >= 0:
								var boss_province_state: Dictionary = _province_persistence[boss_province_idx]
								if enemy_boss_killed_by_player:
									boss_province_state["remaining_troops"] = int(boss_province_state.get("remaining_troops", 0)) + surviving_boss_troops
								else:
									boss_province_state["remaining_troops"] = int(boss_province_state.get("remaining_troops", 0)) - boss_invading_troops + surviving_boss_troops

		if province_system != null:
			province_system.clear_cached_ball_end_world_pos()

		_refresh_gold_and_upgrades_ui()

		if ui_bridge != null:
			ui_bridge.ui_set_status(outcome.get("post_summary_status_text", ""))
			ui_bridge.ui_set_reopenable_summary_text(String(outcome.get("summary_text", outcome.get("post_summary_status_text", ""))))
			ui_bridge.sync_ui_button_states()

		if preserve_ball_visual_for_summary and ball != null and is_instance_valid(ball):
			var enemy_turns_after_result: int = int(outcome.get("enemy_turns", 1))
			var is_winner_visual: bool = enemy_turns_after_result <= 1
			if ball.has_method("clear_summary_opacity"):
				ball.call("clear_summary_opacity")
			if ball.has_method("set_result_visual"):
				ball.call("set_result_visual", is_winner_visual)

		_awaiting_engagement_summary_ack = true
		_pending_post_summary_status_text = outcome.get("post_summary_status_text", "")
		_pending_post_summary_lock_province_id = outcome.get("lock_province_id", -1)
		_pending_post_summary_enemy_turns = outcome.get("enemy_turns", 1)
		_pending_post_summary_skip_province_id = province_id if _current_phase == "defensive" else -1
		_pending_post_summary_preexisting_invaded_ids = preexisting_invaded_province_ids.duplicate()
		_friendly_boss_assist_phase_active = false
		_friendly_boss_assist_province_id = -1

		state = GameState.LEVEL_END


# =============================================================================
# LEGACY COMPATIBILITY
# =============================================================================
func _on_body_entered_building(body: Node) -> void:
	if body.has_meta("is_building"):
		if level_flow != null:
			level_flow.on_ball_body_entered(body)


func _sink_ball_in_water() -> void:
	_last_ball_end_reason = "water"
	_finalize_ball_flight()


# Legacy wrapper
func end_level() -> void:
	_finalize_ball_flight()
