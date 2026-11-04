extends "res://scripts/ProvinceSystem.gd"

# Measurement-only subclass: every intercepted call still delegates to the
# unmodified ProvinceSystem implementation. Intended for headless benchmark only.
var probe_enabled: bool = false
var probe_calls: Dictionary = {}
var probe_microseconds: Dictionary = {}
var generated_candidates: int = 0
var candidate_lists: int = 0
var scored_candidates: int = 0
var baseline_forecasts: int = 0
var modified_forecasts: int = 0
var no_population_effect_forecasts: int = 0
var auto_queue_provinces: int = 0
var auto_queue_final_slots: int = 0
var auto_queue_replanned: int = 0

func probe_begin() -> void:
	probe_calls.clear()
	probe_microseconds.clear()
	generated_candidates = 0
	candidate_lists = 0
	scored_candidates = 0
	baseline_forecasts = 0
	modified_forecasts = 0
	no_population_effect_forecasts = 0
	auto_queue_provinces = 0
	auto_queue_final_slots = 0
	auto_queue_replanned = 0
	probe_enabled = true

func probe_end() -> Dictionary:
	probe_enabled = false
	return {
		"calls": probe_calls.duplicate(true),
		"inclusive_ms": _millisecond_totals(),
		"generated_candidates": generated_candidates,
		"candidate_lists": candidate_lists,
		"scored_candidates": scored_candidates,
		"baseline_forecasts": baseline_forecasts,
		"modified_forecasts": modified_forecasts,
		"no_population_effect_forecasts": no_population_effect_forecasts,
		"auto_queue_provinces": auto_queue_provinces,
		"auto_queue_replanned": auto_queue_replanned,
		"auto_queue_final_slots": auto_queue_final_slots
	}

func _millisecond_totals() -> Dictionary:
	var out: Dictionary = {}
	for key in probe_microseconds.keys():
		out[key] = float(probe_microseconds[key]) / 1000.0
	return out

func _count(key: String, start_us: int) -> void:
	probe_calls[key] = int(probe_calls.get(key, 0)) + 1
	probe_microseconds[key] = int(probe_microseconds.get(key, 0)) + (Time.get_ticks_usec() - start_us)

func normalize_province_economy_state(province_state: Dictionary) -> Dictionary:
	if not probe_enabled:
		return super.normalize_province_economy_state(province_state)
	var t: int = Time.get_ticks_usec()
	var result: Dictionary = super.normalize_province_economy_state(province_state)
	_count("normalize_province_economy_state", t)
	return result

func recalculate_province_derived_economy(province_state: Dictionary) -> Dictionary:
	if not probe_enabled:
		return super.recalculate_province_derived_economy(province_state)
	var t: int = Time.get_ticks_usec()
	var result: Dictionary = super.recalculate_province_derived_economy(province_state)
	_count("recalculate_province_derived_economy", t)
	return result

func calculate_building_effects(province_state: Dictionary) -> Dictionary:
	if not probe_enabled:
		return super.calculate_building_effects(province_state)
	var t: int = Time.get_ticks_usec()
	var result: Dictionary = super.calculate_building_effects(province_state)
	_count("calculate_building_effects", t)
	return result

func get_typed_building_count(province_state: Dictionary, building_type: String, tier: int = 0) -> int:
	if not probe_enabled:
		return super.get_typed_building_count(province_state, building_type, tier)
	var t: int = Time.get_ticks_usec()
	var result: int = super.get_typed_building_count(province_state, building_type, tier)
	_count("get_typed_building_count", t)
	return result

func calculate_remaining_building_slots(province_state: Dictionary) -> int:
	if not probe_enabled:
		return super.calculate_remaining_building_slots(province_state)
	var t: int = Time.get_ticks_usec()
	var result: int = super.calculate_remaining_building_slots(province_state)
	_count("calculate_remaining_building_slots", t)
	return result

func can_add_typed_building(province_state: Dictionary, building_type: String, tier: int = 1) -> bool:
	if not probe_enabled:
		return super.can_add_typed_building(province_state, building_type, tier)
	var t: int = Time.get_ticks_usec()
	var result: bool = super.can_add_typed_building(province_state, building_type, tier)
	_count("can_add_typed_building", t)
	return result

func _is_construction_action_valid(province_state: Dictionary, action: Dictionary) -> bool:
	if not probe_enabled:
		return super._is_construction_action_valid(province_state, action)
	var t: int = Time.get_ticks_usec()
	var result: bool = super._is_construction_action_valid(province_state, action)
	_count("_is_construction_action_valid", t)
	return result

func estimate_construction_action_effects(province_state: Dictionary, action: Dictionary) -> Dictionary:
	if not probe_enabled:
		return super.estimate_construction_action_effects(province_state, action)
	var t: int = Time.get_ticks_usec()
	var result: Dictionary = super.estimate_construction_action_effects(province_state, action)
	_count("estimate_construction_action_effects", t)
	return result

func _forecast_population_and_pressure(province_state: Dictionary, horizon: int = -1, effect_adjustments: Dictionary = {}) -> Dictionary:
	if not probe_enabled:
		return super._forecast_population_and_pressure(province_state, horizon, effect_adjustments)
	var t: int = Time.get_ticks_usec()
	var result: Dictionary = super._forecast_population_and_pressure(province_state, horizon, effect_adjustments)
	if effect_adjustments.is_empty():
		baseline_forecasts += 1
	else:
		modified_forecasts += 1
		if is_zero_approx(float(effect_adjustments.get("food_production", 0.0))):
			no_population_effect_forecasts += 1
	_count("_forecast_population_and_pressure", t)
	return result

func build_valid_construction_candidates(province_state: Dictionary) -> Array[Dictionary]:
	if not probe_enabled:
		return super.build_valid_construction_candidates(province_state)
	var t: int = Time.get_ticks_usec()
	var result: Array[Dictionary] = super.build_valid_construction_candidates(province_state)
	generated_candidates += result.size()
	candidate_lists += 1
	_count("build_valid_construction_candidates", t)
	return result

func _score_construction_action(province_state: Dictionary, action: Dictionary, action_index: int) -> Dictionary:
	if not probe_enabled:
		return super._score_construction_action(province_state, action, action_index)
	var t: int = Time.get_ticks_usec()
	var result: Dictionary = super._score_construction_action(province_state, action, action_index)
	scored_candidates += 1
	_count("_score_construction_action", t)
	return result

func build_recommended_construction_order(province_state: Dictionary, candidate_actions: Array[Dictionary] = [], affordable_only: bool = false) -> Dictionary:
	if not probe_enabled:
		return super.build_recommended_construction_order(province_state, candidate_actions, affordable_only)
	var t: int = Time.get_ticks_usec()
	var result: Dictionary = super.build_recommended_construction_order(province_state, candidate_actions, affordable_only)
	_count("build_recommended_construction_order", t)
	return result

func _make_construction_reservation_state(province_state: Dictionary) -> Dictionary:
	if not probe_enabled:
		return super._make_construction_reservation_state(province_state)
	var t: int = Time.get_ticks_usec()
	var result: Dictionary = super._make_construction_reservation_state(province_state)
	_count("_make_construction_reservation_state", t)
	return result

func _reserve_construction_action_on_state(province_state: Dictionary, action: Dictionary) -> void:
	if not probe_enabled:
		super._reserve_construction_action_on_state(province_state, action)
		return
	var t: int = Time.get_ticks_usec()
	super._reserve_construction_action_on_state(province_state, action)
	_count("_reserve_construction_action_on_state", t)

func _fill_automatic_construction_queue(province_state: Dictionary) -> void:
	if not probe_enabled:
		super._fill_automatic_construction_queue(province_state)
		return
	var t: int = Time.get_ticks_usec()
	auto_queue_provinces += 1
	var previous_refresh: int = int(province_state.get("queue_ai_refreshed_turn", -9999))
	super._fill_automatic_construction_queue(province_state)
	if previous_refresh != int(_main.turn_number):
		auto_queue_replanned += 1
	auto_queue_final_slots += (province_state.get(PROVINCE_CONSTRUCTION_QUEUE_KEY, []) as Array).size()
	_count("_fill_automatic_construction_queue", t)
