# Construction Automation Plan

This document specifies a construction-choice framework that can be shared by CPU factions and player-facing default selections. It is intentionally implementation-focused, but does not require a broad refactor of the current province system.

## Goals

- Every time a province has available construction actions, the UI can preselect one recommended default.
- CPU factions use the same recommendation method when starting construction automatically.
- Recommendations are deterministic, explainable, and safe: they must never choose an invalid construction order, overbuild past capacity, or replace an active project.
- The method should prioritize urgent economic stability before military or long-term capacity building.
- The framework should support build, upgrade, and repair projects, even if the first implementation mostly starts new buildings.

## Current touchpoints

The current implementation already has the core ingredients:

- `ProvinceSystem.gd` owns building definitions, economy normalization, construction validation, and construction project starts.
- `build_province_construction_actions(province_id)` returns player-available construction actions.
- `_maybe_start_non_player_construction(province_state)` currently applies simple CPU priorities directly.
- `tick_province_economy(province_state)` starts non-player construction before advancing construction.
- `Main.gd` passes construction actions to `UIOverlay.gd` when showing province economy debug UI.

The implementation should extract the decision logic from `_maybe_start_non_player_construction()` into a reusable recommendation function, then have both CPU automation and UI default selection call it.

## Core API

Add a reusable recommendation API to `ProvinceSystem.gd`.

### `build_recommended_construction_order(province_state: Dictionary, candidate_actions: Array[Dictionary] = []) -> Dictionary`

Returns a recommendation dictionary. Empty dictionary means no valid recommendation.

Recommended return shape:

```gdscript
{
	"ok": true,
	"request_type": CONSTRUCTION_PROJECT_BUILD,
	"building_type": BUILDING_FOOD_MAKER,
	"tier": 1,
	"score": 1000.0,
	"reason": "Food deficit",
	"details": {
		"food_surplus": -8.0,
		"projected_food_surplus": -12.5
	}
}
```

Rules:

- Normalize the province economy at the start.
- Return `{}` if the province already has active construction.
- Build candidate actions from `candidate_actions` when provided; otherwise derive all valid build, upgrade, and repair actions from the province state.
- Score only actions that are currently valid according to existing validation helpers.
- Prefer a valid lower-scoring action over an invalid high-priority action.
- Include a short `reason` suitable for UI status text/debug output.
- Keep the function side-effect free. It must not start construction.

### `apply_recommended_construction_order(province_state: Dictionary) -> Dictionary`

Starts the recommended project and returns an outcome dictionary.

Recommended return shape:

```gdscript
{
	"ok": true,
	"building_type": BUILDING_FOOD_MAKER,
	"request_type": CONSTRUCTION_PROJECT_BUILD,
	"tier": 1,
	"reason": "Food deficit"
}
```

Rules:

- Call `build_recommended_construction_order()`.
- Dispatch through `start_building_construction()`, `start_building_upgrade_construction()`, or `start_building_repair_construction()`.
- Return failure if the recommendation cannot be started. This should be rare and should reveal a mismatch between scoring and validation.
- Replace `_maybe_start_non_player_construction()` with this wrapper or have `_maybe_start_non_player_construction()` delegate to it.

### `build_province_construction_actions(province_id: int) -> Array[Dictionary]`

Extend each action with an optional recommendation flag so the UI can preselect it:

```gdscript
{
	"label": "Build Food Maker",
	"request_type": CONSTRUCTION_PROJECT_BUILD,
	"building_type": BUILDING_FOOD_MAKER,
	"tier": 1,
	"recommended": true,
	"recommendation_reason": "Food deficit"
}
```

Rules:

- Preserve existing keys so current UI code keeps working.
- After building the valid action list, call `build_recommended_construction_order(province_state, actions)`.
- Mark exactly one matching action as recommended when a recommendation exists.
- Matching should compare `request_type`, `building_type`, and `tier`.
- If no recommendation exists, return actions without a recommended flag.

### UI default behavior

Update the construction action selector in `UIOverlay.gd` to select the recommended action by default when present.

Rules:

- Do not auto-submit the action for the player; only preselect it.
- Make the recommendation visible by appending text such as `" (recommended: Food deficit)"` to the label or showing the reason in adjacent help text.
- Preserve the player's ability to choose another action before confirming.

## Candidate action generation

Use one canonical helper for valid candidates so CPU and UI cannot diverge.

Suggested helper:

```gdscript
func build_valid_construction_candidates(province_state: Dictionary) -> Array[Dictionary]:
```

It should include:

1. Build actions for every building type that passes `can_add_typed_building(province_state, building_type, 1)`.
2. Upgrade actions for existing buildings below max tier.
3. Repair action if `start_building_repair_construction()` would be valid, but without mutating state.

If the existing `build_province_construction_actions()` remains the only candidate builder, ensure the recommendation function can work from those action dictionaries directly.

## Priority model

The recommendation method should score every valid candidate. Use fixed priority bands so emergency needs always outrank nice-to-have projects.

Recommended bands:

| Band | Score range | Purpose |
| --- | ---: | --- |
| Emergency stability | 9000+ | Current negative food or current overcrowding. |
| Forecast stability | 7000-8999 | Food or accommodation likely to go negative soon. |
| Safety and recovery | 5000-6999 | Front-line defense, damaged buildings, low defense. |
| Strategic capacity | 3000-4999 | Recruitment, construction speed, growth, income, command infrastructure. |
| Filler | 1000-2999 | Any valid action when nothing is urgent. |

Tie-breakers, in order:

1. Higher score.
2. Lower `required_progress`, so short fixes are preferred when needs are equal.
3. Lower build cost if cost is tracked in the future.
4. Stable building catalog order for determinism.

## Stability assessment

### Current food deficit

If `food.surplus` is below `ai_food_deficit_build_threshold`, prioritize Food Maker builds/upgrades.

Scoring example:

```text
9000 + abs(food_surplus) * 20 + food_maker_expected_food_gain
```

Prefer whichever valid food action gives the largest food gain per required progress. This might be upgrading an existing Food Maker instead of building another one.

### Forecast food deficit

Predict whether food will be negative soon before waiting for a crisis.

Suggested forecast horizon: 3 province ticks.

Projected food demand should consider:

- Native population growth.
- Outlander population growth.
- Resident troops if troop food demand is enabled.
- Current food production and food-producing buildings.

The first implementation can use a conservative approximation:

```text
projected_population = current_population + max(0, growth_factor) * horizon
projected_food_demand = projected_population * demand_per_population
projected_food_surplus = current_food_production - projected_food_demand
```

If exact demand helpers already exist, reuse them instead of duplicating formulas.

Prioritize Food Maker actions if projected surplus falls below zero or below a small reserve threshold.

### Current accommodation pressure

For each population class:

```text
overcrowding = population - accommodation_ceiling
```

If overcrowding exceeds `ai_overcrowding_build_threshold`, prioritize the matching accommodation center.

Score the more overcrowded class higher. For example:

```text
9000 + overcrowding * 25 + accommodation_gain
```

If the matching accommodation action is invalid, fall back to the other accommodation type only if it is still beneficial. Do not build unrelated accommodation just because the preferred one is blocked.

### Forecast accommodation pressure

Forecast population against accommodation over the same horizon used for food.

If a class is projected to exceed its ceiling soon, prioritize the matching accommodation center before it becomes an emergency.

Scoring example:

```text
7000 + projected_overcrowding * 20 + accommodation_gain
```

### Low happiness / revolution risk

If the province has low happiness or revolt warning status, prioritize the construction action that directly addresses the root cause:

- Food Maker if food deficit is the largest negative pressure.
- Matching accommodation center if overcrowding is the largest negative pressure.
- Repair or defensive action only if instability is from recent attack damage and no food/accommodation problem exists.

Do not add a generic "happiness building" priority unless such a building exists in the catalog.

## Safety and military assessment

### Front-line detection

Use a helper equivalent to `province_has_non_self_neighbor()`, but rename/generalize it to avoid implying player-centric ownership if CPU factions are compared against each other.

Suggested helper:

```gdscript
func province_has_hostile_or_non_owned_neighbor(province_state: Dictionary) -> bool:
```

For now, using relation-to-player is acceptable for preserving existing behavior, but the final helper should compare faction/owner identity so enemy factions can reason about borders between different enemy factions, rebels, neutrals, and the player.

### Defense priorities

If the province borders a hostile or non-owned neighbor:

- Prefer Defense Nest when the province has low defensive building count/effect.
- Consider Catapult only after minimum local defense exists, because catapults are offensive support and currently less important than avoiding province loss.
- Prefer repairs when damaged low-tier buildings exist and the province is on the front line.

Scoring example:

```text
Defense Nest: 5500 + hostile_neighbor_count * 100 - defense_strength * 50
Repair: 5400 if front-line damaged buildings exist
Catapult: 5000 + hostile_neighbor_count * 75, only if defense_strength >= minimum_frontline_defense
```

### Rear-line capacity

If the province has no hostile/non-owned neighbors and no stability risk:

- Prefer Club Factory when recruitment is low or troop reserves are strategically valuable.
- Prefer Growth Increaser when population is low and food/accommodation forecasts remain safe after growth.
- Prefer Command Center upgrade/build when construction speed is a bottleneck, the province is important, and uniqueness rules allow it.
- Prefer Food Maker or accommodation only if forecasts indicate future pressure.

Avoid building front-line-only defenses in rear provinces unless there are no better valid actions.

## Building effect evaluation

Add small helpers to estimate the marginal value of each action:

```gdscript
func estimate_construction_action_effects(province_state: Dictionary, action: Dictionary) -> Dictionary:
```

Return expected deltas such as:

```gdscript
{
	"food_production": 18.0,
	"native_accommodation": 7.0,
	"outlander_accommodation": 0.0,
	"recruitment": 0.6,
	"construction": 0.0,
	"defense_strength": 1.0,
	"adjacent_damage": 0.0,
	"growth_factor": 0.0
}
```

For build actions, use tier 1 effects. For upgrades, compare target tier effects against source tier effects. For repairs, estimate the tier restoration effect if practical; otherwise score repair mostly through the safety band.

This keeps scoring robust if building values change in `BUILDING_CATALOG`.

## CPU integration

Replace direct CPU construction selection with:

```gdscript
func _maybe_start_non_player_construction(province_state: Dictionary) -> String:
	if _main == null:
		return ""
	if get_relation_to_player_for_province_state(province_state) == RELATION_SELF:
		return ""
	var result: Dictionary = apply_recommended_construction_order(province_state)
	return String(result.get("building_type", "")) if bool(result.get("ok", false)) else ""
```

Later, if friendly automation is desired, remove the relation check and let callers decide whether automation should apply.

## Player default integration

Player-facing flow:

1. Province popup requests construction actions.
2. `build_province_construction_actions()` returns valid actions with one optional recommendation.
3. `UIOverlay.gd` selects that action in the option control by default.
4. Player may submit the default or choose another action.
5. `start_province_construction_order()` remains the only method that mutates state from the player path.

This gives players the same default that CPU factions would choose, while preserving agency.

## Edge cases and safeguards

- **Active project:** no recommendation, no CPU action.
- **No free building slots:** build actions are excluded; upgrades and repairs may still be valid.
- **Unique building already present:** catalog uniqueness validation excludes duplicate builds.
- **Invalid catalog entry:** skip it and continue scoring other actions.
- **Zero or negative construction rate:** recommendations can still be made, but include debug details so stuck provinces are visible.
- **Multiple equal emergencies:** food deficit should outrank accommodation if food surplus is currently negative; otherwise the larger projected happiness/growth harm should win.
- **No valid action in top priority:** fall through to lower priorities instead of returning no recommendation.
- **Province ownership changes:** active construction should still be cancelled/reset by existing ownership-change code before recommendations run.

## Suggested implementation sequence

1. Add candidate-generation helper without changing behavior.
2. Add side-effect-free recommendation helper with scoring and reasons.
3. Change `_maybe_start_non_player_construction()` to apply the recommendation helper.
4. Extend `build_province_construction_actions()` to mark the matching recommendation.
5. Update `UIOverlay.gd` to preselect and label the recommended action.
6. Add or extend self-test coverage for recommendation cases.

## Test plan

Use static self-test style cases rather than relying only on manual play:

- Province with negative food recommends Food Maker.
- Province with projected food deficit recommends Food Maker before deficit occurs.
- Province with native overcrowding recommends Native Accommodation Center.
- Province with outlander overcrowding recommends Outlander Accommodation Center.
- Stable front-line province recommends Defense Nest before Catapult.
- Stable rear-line province recommends Club Factory, Growth Increaser, or Command Center according to scoring.
- Province with active construction returns no recommendation.
- Province with no build slots still recommends a valid upgrade or repair when available.
- Player action list marks the same action CPU automation would start.
- CPU automation starts only valid recommendations and does not mutate player-owned provinces unless explicitly enabled by the caller.

Manual smoke test after implementation:

1. Open a province economy popup with available construction.
2. Confirm one action is preselected and marked recommended.
3. Override the selection and confirm the selected non-default order starts.
4. End turns for CPU factions and confirm they start explainable construction without crashes or overbuilding.
