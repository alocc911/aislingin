extends RefCounted
# Read-only telemetry for the no-human-input full-map campaign simulator.
const LevelConfig = preload("res://scripts/LevelConfig.gd")

var map_seed: int
var current_owners: Dictionary = {}
var ownership_started: Dictionary = {}
var acquisition_causes: Dictionary = {}
var completed_tenures: Array[int] = []
var ownership_rows: Array[String] = []
var province_rows: Array[String] = []
var map_rows: Array[String] = []
var revolts_by_province: Dictionary = {}
var revolts_by_previous_owner: Dictionary = {}
var recent_capture_revolts_5: int = 0
var recent_capture_revolts_10: int = 0
var recent_capture_revolts_20: int = 0
var ownership_changes: int = 0
var captures: int = 0
var food_shortage_province_turns: int = 0
var overcrowded_province_turns: int = 0
var observed_province_turns: int = 0
var happiness_sum: float = 0.0
var happiness_observations: int = 0
var peak_province_population: float = 0.0
var peak_province_id: int = -1
var peak_province_turn: int = -1
var peak_total_population: float = 0.0
var peak_total_population_turn: int = -1
var final_total_population: float = 0.0
var final_natives: float = 0.0
var final_outlanders: float = 0.0


static func owner_key(province: Dictionary) -> String:
	var kind: String = String(province.get("type", LevelConfig.PROVINCE_TYPE_NEUTRAL))
	if kind == LevelConfig.PROVINCE_TYPE_ENEMY:
		var faction: int = int(province.get("faction_id", 1))
		return "boss_%d" % faction if faction >= 99 and faction < 200 else "enemy_%d" % faction
	return kind


func initialize(seed_value: int, provinces: Array[Dictionary]) -> void:
	map_seed = seed_value
	for province in provinces:
		var id: int = int(province.get("id", -1))
		if id < 0:
			continue
		current_owners[id] = owner_key(province)
		ownership_started[id] = 0
		acquisition_causes[id] = "initial"


func track_ownership(provinces: Array[Dictionary], turn: int, default_cause: String, revolted_ids: Array[int] = []) -> void:
	for province in provinces:
		var id: int = int(province.get("id", -1))
		if id < 0:
			continue
		var after: String = owner_key(province)
		if not current_owners.has(id):
			current_owners[id] = after
			ownership_started[id] = turn
			acquisition_causes[id] = "initial"
			continue
		var before: String = String(current_owners[id])
		if before == after:
			continue
		var held: int = maxi(0, turn - int(ownership_started.get(id, 0)))
		var prior_cause: String = String(acquisition_causes.get(id, "initial"))
		var cause: String = "revolution" if revolted_ids.has(id) else default_cause
		var pre_revolt_natives: String = ""
		var pre_revolt_outlanders: String = ""
		if cause == "revolution":
			revolts_by_province[id] = int(revolts_by_province.get(id, 0)) + 1
			revolts_by_previous_owner[before] = int(revolts_by_previous_owner.get(before, 0)) + 1
			if prior_cause == "automated_action":
				if held <= 5:
					recent_capture_revolts_5 += 1
				if held <= 10:
					recent_capture_revolts_10 += 1
				if held <= 20:
					recent_capture_revolts_20 += 1
			# ProvinceSystem writes the collapse immediately before the 50/50 reset.
			var points: Array = province.get("history_happiness", [])
			if not points.is_empty():
				var point: Dictionary = points.back()
				if int(point.get("turn", -1)) == turn:
					pre_revolt_natives = _fmt(float(point.get("natives", 0.0)))
					pre_revolt_outlanders = _fmt(float(point.get("outlanders", 0.0)))
		if before != LevelConfig.PROVINCE_TYPE_NEUTRAL:
			completed_tenures.append(held)
		if cause == "automated_action" and after != LevelConfig.PROVINCE_TYPE_NEUTRAL:
			captures += 1
		ownership_rows.append("%d,%d,%d,%s,%s,%s,%d,%s,%s" % [
			map_seed, turn, id, before, after, cause, held,
			pre_revolt_natives, pre_revolt_outlanders
		])
		ownership_changes += 1
		current_owners[id] = after
		ownership_started[id] = turn
		acquisition_causes[id] = cause


func record_turn(provinces: Array[Dictionary], turn: int, gold: int, revolts: int, conquests: int) -> void:
	var natives_total: float = 0.0
	var outlanders_total: float = 0.0
	var production: float = 0.0
	var demand: float = 0.0
	var income_total: float = 0.0
	var happiness_total: float = 0.0
	var happiness_count: int = 0
	var food_shortages: int = 0
	var overcrowded: int = 0
	var troops_total: int = 0
	var buildings_total: int = 0
	var owners: Dictionary = {}
	for province in provinces:
		var id: int = int(province.get("id", -1))
		var owner: String = owner_key(province)
		owners[owner] = int(owners.get(owner, 0)) + 1
		var population: Dictionary = province.get("population", {})
		var happiness: Dictionary = province.get("happiness", {})
		var food: Dictionary = province.get("food", {})
		var housing: Dictionary = province.get("accommodation", {})
		var rates: Dictionary = province.get("rates", {})
		var natives: float = maxf(0.0, float(population.get("natives", 0.0)))
		var outlanders: float = maxf(0.0, float(population.get("outlanders", 0.0)))
		var hn: float = float(happiness.get("natives", 0.0))
		var ho: float = float(happiness.get("outlanders", 0.0))
		var produced: float = float(food.get("production", 0.0))
		var needed: float = float(food.get("demand", 0.0))
		var surplus: float = float(food.get("surplus", 0.0))
		var native_room: float = float(housing.get("native_ceiling", 0.0))
		var outlander_room: float = float(housing.get("outlander_ceiling", 0.0))
		var income: float = float(rates.get("income", 0.0))
		var troops: int = maxi(0, int(province.get("remaining_troops", 0)))
		var buildings: int = maxi(0, int(province.get("remaining_buildings", 0)))
		var shortage: bool = surplus < 0.0
		var crowded: bool = natives > native_room or outlanders > outlander_room
		if shortage:
			food_shortages += 1
		if crowded:
			overcrowded += 1
		var province_population: float = natives + outlanders
		if province_population > peak_province_population:
			peak_province_population = province_population
			peak_province_id = id
			peak_province_turn = turn
		natives_total += natives
		outlanders_total += outlanders
		production += produced
		demand += needed
		income_total += income
		troops_total += troops
		buildings_total += buildings
		happiness_total += hn + ho
		happiness_count += 2
		happiness_sum += hn + ho
		happiness_observations += 2
		observed_province_turns += 1
		province_rows.append("%d,%d,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d,%d,%d" % [
			map_seed, turn, id, owner, _fmt(natives), _fmt(outlanders), _fmt(hn),
			_fmt(ho), _fmt(produced), _fmt(needed), _fmt(surplus),
			_fmt(native_room), _fmt(outlander_room), _fmt(income),
			_fmt(float(rates.get("recruitment", 0.0))), troops, buildings,
			int(shortage), int(crowded)
		])
	var factions: int = 0
	for owner in owners:
		if String(owner) != LevelConfig.PROVINCE_TYPE_NEUTRAL:
			factions += 1
	var total_population: float = natives_total + outlanders_total
	if total_population > peak_total_population:
		peak_total_population = total_population
		peak_total_population_turn = turn
	final_total_population = total_population
	final_natives = natives_total
	final_outlanders = outlanders_total
	food_shortage_province_turns += food_shortages
	overcrowded_province_turns += overcrowded
	map_rows.append("%d,%d,%d,%d,%d,%s,%s,%s,%s,%s,%s,%s,%d,%d,%d,%d,%d,%d,%d" % [
		map_seed, turn, factions, int(owners.get("neutral", 0)),
		int(owners.get("enemy_9000", 0)), _fmt(total_population),
		_fmt(natives_total), _fmt(outlanders_total),
		_fmt(happiness_total / float(maxi(1, happiness_count))),
		_fmt(production), _fmt(demand), _fmt(income_total), food_shortages,
		overcrowded, troops_total, buildings_total, gold, revolts, conquests
	])


func summarize(provinces: Array[Dictionary], ending_turn: int) -> Dictionary:
	var observed_tenures: Array[int] = completed_tenures.duplicate()
	var censored_count: int = 0
	for province in provinces:
		var id: int = int(province.get("id", -1))
		if not current_owners.has(id) or String(current_owners[id]) == LevelConfig.PROVINCE_TYPE_NEUTRAL:
			continue
		observed_tenures.append(maxi(0, ending_turn - int(ownership_started.get(id, ending_turn))))
		censored_count += 1
	var repeats: int = 0
	for id in revolts_by_province:
		if int(revolts_by_province[id]) > 1:
			repeats += 1
	return {
		"peak_province_population": snapped(peak_province_population, 0.01),
		"peak_province_id": peak_province_id,
		"peak_province_turn": peak_province_turn,
		"peak_total_population": snapped(peak_total_population, 0.01),
		"peak_total_population_turn": peak_total_population_turn,
		"final_total_population": snapped(final_total_population, 0.01),
		"final_natives": snapped(final_natives, 0.01),
		"final_outlanders": snapped(final_outlanders, 0.01),
		"mean_happiness_across_province_turns": snapped(happiness_sum / float(maxi(1, happiness_observations)), 0.01),
		"food_shortage_province_turns": food_shortage_province_turns,
		"overcrowded_province_turns": overcrowded_province_turns,
		"observed_province_turns": observed_province_turns,
		"ownership_changes": ownership_changes,
		"captured_province_events": captures,
		"completed_holding_periods": completed_tenures.size(),
		"censored_holding_periods": censored_count,
		"average_completed_holding_turns": snapped(_mean(completed_tenures), 0.01),
		"median_completed_holding_turns": snapped(_median(completed_tenures), 0.01),
		"average_observed_holding_turns": snapped(_mean(observed_tenures), 0.01),
		"median_observed_holding_turns": snapped(_median(observed_tenures), 0.01),
		"longest_observed_holding_turns": _longest(observed_tenures),
		"revolts_by_previous_owner": revolts_by_previous_owner.duplicate(),
		"provinces_with_repeat_revolts": repeats,
		"revolts_within_5_turns_of_capture": recent_capture_revolts_5,
		"revolts_within_10_turns_of_capture": recent_capture_revolts_10,
		"revolts_within_20_turns_of_capture": recent_capture_revolts_20
	}


static func _fmt(value: float) -> String:
	return "%.2f" % value


static func _mean(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value in values:
		total += value
	return total / float(values.size())


static func _median(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var ordered: Array[int] = values.duplicate()
	ordered.sort()
	var middle: int = int(ordered.size() / 2)
	if ordered.size() % 2 == 1:
		return float(ordered[middle])
	return (float(ordered[middle - 1]) + float(ordered[middle])) * 0.5


static func _longest(values: Array[int]) -> int:
	var longest: int = 0
	for value in values:
		longest = maxi(longest, value)
	return longest
