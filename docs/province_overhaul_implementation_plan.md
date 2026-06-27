# Province Overhaul Implementation Plan

## Purpose

This plan describes a staged overhaul of the province system from the current aggregate model into a richer province economy with food, population classes, happiness, typed buildings, construction, command-center control, raids, and simple revolutions.

The plan assumes the current province system remains playable during the transition and that implementation should prefer small, testable milestones over one large rewrite.

## Confirmed Design Defaults

### Province Economy Tick

Province economy updates should occur on a discrete strategic tick after relevant Grand Map actions resolve. The system should not be continuous real-time simulation.

A tick should recalculate derived values, apply happiness changes, update populations, advance construction, process recruitment/income, and then check for revolution.

### Food

Food is not stored over time. A province displays current food surplus:

```text
food_surplus = current_food_production - current_food_demand
```

Food demand should initially come from commoner population, nobility population, and stationed troops. Buildings should not consume food for the first implementation pass.

Food deficit should reduce both commoner happiness and nobility happiness and should reduce growth. Food surplus should help growth and allow happiness to recover gradually.

### Population

Each province tracks two population classes:

- Commoners
- Nobility

Both population classes can grow each tick. Commoners should grow faster than nobility. Growth should be affected by growth factor, food surplus or deficit, happiness, and accommodation pressure.

### Happiness

Each province tracks two happiness values:

- Commoner happiness
- Nobility happiness

Both should use a `0` to `100` range. New/default province values should start near `60` unless a later balance pass chooses a different baseline.

Commoner happiness should primarily affect construction, recruitment, and growth. Nobility happiness should primarily affect income and growth. Either happiness value can trigger revolution.

### Accommodation

Each class has a soft accommodation ceiling:

- Commoner accommodation ceiling
- Nobility accommodation ceiling

Population may exceed its accommodation ceiling, but overcrowding lowers that class's happiness. Accommodation buildings increase the matching ceiling.

### Revolution

Revolutions should be simple for now.

If either happiness value reaches `0` or below, the province revolts:

```text
commoner_happiness <= 0 OR nobility_happiness <= 0
```

When revolution happens:

- The province changes to a new rebel enemy faction.
- All troops currently in the province convert into rebel troops.
- Those troops become the province's resident rebel troops.
- Existing buildings remain in place for now.
- Population remains in place for now.
- Active construction should be cancelled or paused; the first implementation should cancel it unless a later design calls for rebel construction carryover.

### Buildings

Buildings should initially be represented as typed counts by tier rather than individual object instances.

Example shape:

```gdscript
"buildings": {
    "club_factory": { "1": 1, "2": 0, "3": 0 },
    "food_maker": { "1": 2, "2": 1, "3": 0 }
}
```

Multiple copies of most buildings should be allowed, limited by building cap. Command centers should be limited to one per province.

Initial building types:

- Club factory
- Defense nest
- Catapult
- Command center
- Food maker
- Nobility accommodation center
- Commoner accommodation center
- Growth increaser

### Construction

Each province should support one active construction project at a time for the first implementation pass.

A project should include:

```text
project_type: build / upgrade / repair
building_type
target_tier
progress
required_progress
```

Construction advances each province tick according to construction rate.

### Command Center Control

At the start of a player turn, the player can control troops in the province where the player starts that turn.

If that starting province has a command center, the player can also control troops in every other player-controlled province.

If the starting province does not have a command center, the player cannot globally control troops elsewhere, even if other player-controlled provinces have command centers.

### Raids

When landing in an enemy province, the player may choose raid instead of conquest.

A raid:

- Creates a smaller engagement than a full conquest.
- Uses fewer defending enemy troops than conquest.
- Cannot capture the province.
- Can damage, downgrade, or destroy a limited number of buildings on victory.
- Should have capped rewards so repeated raids are useful but do not replace conquest entirely.

## Current-Code Context

The current province state is aggregate-based. It initializes fields such as `remaining_troops`, `remaining_buildings`, `construction_progress`, `gold_production`, `free_buildings`, and `building_capacity`. The overhaul should add new state without breaking existing province creation, persistence, combat resolution, or UI while the migration is in progress.

## Target Province State Schema

Add a versioned province economy block to each province state.

Recommended top-level shape:

```gdscript
"province_economy_version": 1,
"population": {
    "commoners": 0,
    "nobility": 0
},
"happiness": {
    "commoners": 60,
    "nobility": 60
},
"food": {
    "production": 0,
    "demand": 0,
    "surplus": 0
},
"rates": {
    "growth_factor": 1.0,
    "recruitment": 0.0,
    "construction": 0.0,
    "income": 0.0
},
"accommodation": {
    "commoner_ceiling": 0,
    "nobility_ceiling": 0
},
"buildings": {},
"active_construction": {},
"province_status": {
    "recently_raided_ticks": 0,
    "recently_conquered_ticks": 0,
    "revolt_warning": false
}
```

Keep existing fields during the migration:

- `remaining_troops`
- `remaining_buildings`
- `construction_progress`
- `gold_production`
- `free_buildings`
- `building_capacity`

Eventually, typed buildings can replace `remaining_buildings`, `free_buildings`, and the old construction-progress model.

## Building Catalog

Create a central building catalog with all building definitions and per-tier effects.

Recommended data per building:

```gdscript
{
    "id": "food_maker",
    "display_name": "Food Maker",
    "max_tier": 3,
    "unique_per_province": false,
    "base_build_cost": 100,
    "base_build_progress_required": 100,
    "tier_effects": {
        1: { "food_production": 10 },
        2: { "food_production": 20 },
        3: { "food_production": 35 }
    }
}
```

Initial recommended effects:

### Club Factory

Increases recruitment rate.

### Defense Nest

Improves defensive engagements and creates friendly caltrops or similar defensive hazards when invaded. It may also increase non-player automatic defense strength.

### Catapult

Can kill enemy troops in adjacent territories. This should be implemented cautiously and probably after the core economy is stable because it has cross-province effects.

### Command Center

Enables global player troop control only if present in the province where the player starts the turn.

### Food Maker

Increases food production.

### Nobility Accommodation Center

Increases nobility accommodation ceiling.

### Commoner Accommodation Center

Increases commoner accommodation ceiling.

### Growth Increaser

Increases growth factor.

## Derived Stat Formulas

The first implementation should use simple formulas with constants centralized in configuration.

### Food Production

```text
food_production = base_food_production + food_from_food_makers
```

### Food Demand

```text
food_demand = commoner_population * commoner_food_demand
            + nobility_population * nobility_food_demand
            + resident_troops * troop_food_demand
```

### Food Surplus

```text
food_surplus = food_production - food_demand
```

### Accommodation Pressure

```text
commoner_overcrowding = max(0, commoner_population - commoner_accommodation_ceiling)
nobility_overcrowding = max(0, nobility_population - nobility_accommodation_ceiling)
```

### Happiness Change

```text
happiness_delta = food_happiness_delta - overcrowding_penalty + recovery_bonus
```

Clamp final happiness to a reasonable range after applying deltas:

```text
happiness = clamp(happiness, 0, 100)
```

The revolution check must occur after happiness changes. Because revolution triggers at `0` or below, the code should check the unclamped or post-delta value before forcing display clamps, or explicitly treat `0` as revolt.

### Growth Factor

```text
growth_factor = base_growth_factor
              + growth_building_bonus
              + food_growth_modifier
              + happiness_growth_modifier
```

### Construction Rate

```text
construction_rate = base_construction_rate
                  + commoner_population * commoner_construction_factor
                  * commoner_happiness_multiplier
```

### Recruitment Rate

```text
recruitment_rate = base_recruitment_rate
                 + club_factory_bonus
                 + commoner_population * commoner_recruitment_factor
                 * commoner_happiness_multiplier
```

### Income Rate

```text
income_rate = base_income_rate
            + nobility_population * nobility_income_factor
            * nobility_happiness_multiplier
```

## Province Tick Order

Implement a single orchestration function that updates one province in this order:

1. Normalize/migrate province economy state.
2. Recalculate building effects.
3. Recalculate accommodation ceilings.
4. Recalculate food production, demand, and surplus.
5. Apply food-based happiness deltas.
6. Apply accommodation-based happiness deltas.
7. Apply passive happiness recovery, if any.
8. Check revolution.
9. If no revolution, recalculate growth factor.
10. Update commoner and nobility populations.
11. Recalculate recruitment, construction, and income rates.
12. Apply recruitment gains.
13. Apply income gains.
14. Advance active construction.
15. Persist final derived values for UI display.

## Implementation Phases

### Phase 1: Data Model and Migration

Goals:

- Add economy defaults to province state.
- Preserve old saves and old generated provinces.
- Add schema-version helpers.
- Add normalization helpers.

Tasks:

1. Add constants for economy schema version.
2. Add helper to create default economy state.
3. Add helper to normalize existing province state into the new economy schema.
4. Ensure every province loaded or generated gets the new fields.
5. Do not remove old fields yet.

Acceptance criteria:

- Existing maps load without errors.
- Provinces have default population/happiness/food/building economy fields.
- Existing combat still works.

### Phase 2: Building Catalog and Typed Building Storage

Goals:

- Add building definitions.
- Add typed/tiered building storage.
- Keep existing aggregate building count until typed buildings are integrated with combat/UI.

Tasks:

1. Create building ID constants.
2. Create central building catalog.
3. Add helpers:
   - get building count
   - add building
   - remove building
   - upgrade building
   - calculate occupied building slots
   - calculate remaining building slots
4. Enforce command center uniqueness.
5. Add building cap validation.

Acceptance criteria:

- Province can store typed buildings by tier.
- Building counts survive persistence.
- Building cap prevents overbuilding.
- Command center cannot be duplicated in one province.

### Phase 3: Derived Economy Calculations

Goals:

- Implement food, accommodation, growth, recruitment, construction, and income calculations.
- Keep numbers visible internally before full UI work.

Tasks:

1. Add food calculation helpers.
2. Add accommodation calculation helpers.
3. Add happiness delta calculation helpers.
4. Add growth-factor calculation helper.
5. Add recruitment-rate calculation helper.
6. Add construction-rate calculation helper.
7. Add income-rate calculation helper.
8. Store derived values in province state for UI.

Acceptance criteria:

- Derived values are deterministic.
- Food surplus responds to population/troops/food makers.
- Accommodation ceilings respond to accommodation buildings.
- Rates respond to happiness and building effects.

### Phase 4: Province Tick Orchestration

Goals:

- Add one province tick function.
- Add one all-provinces tick function.
- Ensure updates occur at the correct strategic time.

Tasks:

1. Implement `tick_province_economy(province_state)`.
2. Implement `tick_all_province_economies()`.
3. Wire the all-province tick after strategic actions resolve.
4. Add debug logging for before/after values.
5. Ensure enemy, neutral, rebel, and player provinces can all tick safely.

Acceptance criteria:

- Province economy changes over time.
- Population and happiness update predictably.
- Construction progresses.
- No province type crashes the tick.

### Phase 5: Revolution

Goals:

- Implement simple happiness-collapse revolution.

Tasks:

1. Add revolution check after happiness deltas.
2. If commoner or nobility happiness is `0` or below:
   - create/assign rebel enemy faction
   - change province ownership to rebel enemy
   - convert all resident troops to rebel troops
   - cancel or pause active construction
   - mark capture/revolution source metadata if needed
3. Add simple logging or popup event.
4. Prevent repeated revolution processing on the same already-rebel province in the same tick.

Acceptance criteria:

- A province with happiness at or below `0` revolts.
- All resident troops remain in the province but become rebel troops.
- Province is no longer player-controlled.
- The game remains stable after the ownership transition.

### Phase 6: Construction Orders

Goals:

- Allow player-facing construction orders after data and tick logic are stable.

Tasks:

1. Add action to start building construction.
2. Add action to start upgrade construction.
3. Validate available building slots.
4. Validate max tier.
5. Validate command center uniqueness.
6. Advance active project each tick.
7. Complete project when progress reaches requirement.
8. Convert completed project into building count/tier.

Acceptance criteria:

- Player can start one construction project in a province.
- Project advances according to construction rate.
- Project completes and updates typed buildings.
- Invalid projects are rejected cleanly.

### Phase 7: Command Center Control

Goals:

- Implement corrected command-center control behavior.

Rules:

- At start of player turn, determine the player's starting province.
- Player can control troops in that province.
- If that province has a command center, player can control troops in all player-controlled provinces.
- If that province does not have a command center, player cannot globally control other provinces.

Tasks:

1. Add helper `province_has_command_center(province_state)`.
2. Add helper `get_player_turn_start_province_id()` if not already available.
3. Add helper `can_player_control_troops_in_province(target_province_id)`.
4. Update troop-order UI/rules to use that helper.
5. Update march-threshold controls to obey that helper.
6. Add clear UI indication for locked/uncontrolled provinces.

Acceptance criteria:

- Starting province troops are always controllable at turn start.
- If starting province has command center, all player province troops are controllable.
- If starting province lacks command center, other provinces are locked from direct troop control.

### Phase 8: Raid Mode

Goals:

- Add raid option for enemy province landings.

Tasks:

1. Add raid/conquest choice when player lands in an enemy province.
2. Build raid engagement input with reduced defender count.
3. Ensure raid cannot set province ownership to player.
4. Add raid outcome resolver.
5. On raid victory, select building damage/downgrade/destruction outcome.
6. Apply capped building damage.
7. Apply optional happiness penalty to defender province.
8. Add raid summary popup.

Acceptance criteria:

- Player can choose raid instead of conquest.
- Raid uses fewer defenders than full conquest.
- Winning raid damages buildings but does not capture province.
- Losing raid does not create conquest side effects.

### Phase 9: UI Integration

Goals:

- Make the new province economy understandable and actionable.

Tasks:

1. Update province info panel to show:
   - food surplus
   - growth factor
   - recruitment rate
   - construction rate
   - income rate
   - commoner/nobility population
   - commoner/nobility accommodation ceiling
   - commoner/nobility happiness
   - building cap
   - current buildings
   - active construction
2. Add warnings for:
   - food deficit
   - overcrowding
   - low happiness
   - imminent revolution
3. Add construction controls.
4. Add building upgrade controls.
5. Add command-center control messaging.
6. Add raid/conquest choice UI.

Acceptance criteria:

- Player can inspect all important province economy stats.
- Player can tell why happiness is changing.
- Player can order construction and upgrades.
- Player can understand command-center control limitations.

### Phase 10: AI and Non-Player Behavior

Goals:

- Make enemy/rebel/neutral provinces coherent without deep strategic AI.

Tasks:

1. Let non-player provinces tick economy.
2. Add simple construction priorities:
   - If food negative, build food maker.
   - If overcrowded, build matching accommodation.
   - If border/enemy-adjacent, build defense nest.
   - If stable, build club factory or growth increaser.
3. Let enemies benefit from recruitment/income rates if existing campaign AI uses those values.
4. Let rebel provinces persist as hostile factions.

Acceptance criteria:

- Non-player provinces do not stagnate completely.
- Enemy/rebel provinces can recover from raids over time.
- Simple AI does not crash or overbuild.

### Phase 11: Balance Pass

Goals:

- Tune values after systems are functional.

Tasks:

1. Tune default populations.
2. Tune food demand and production.
3. Tune happiness penalties/recovery.
4. Tune construction speed.
5. Tune recruitment rate.
6. Tune income rate.
7. Tune building effects per tier.
8. Tune raid damage caps.
9. Tune revolution frequency.

Acceptance criteria:

- Province growth feels meaningful but not explosive.
- Revolutions are possible but avoidable with reasonable management.
- Raids are useful but not better than conquest in all cases.
- Command centers are strategically important.

## Testing Plan

### Unit-Level / Helper Tests

If the project has an automated test framework available, add tests for:

- Economy state normalization.
- Food calculations.
- Accommodation calculations.
- Happiness deltas.
- Revolution trigger.
- Building add/remove/upgrade validation.
- Command center control helper.
- Raid building damage cap.

### Manual Scenario Tests

Run manual scenarios for:

1. Existing save/map loads with economy defaults.
2. Province with food deficit loses happiness.
3. Province with food surplus grows over time.
4. Overcrowded commoners lose commoner happiness.
5. Overcrowded nobility lose nobility happiness.
6. Happiness reaching `0` triggers revolution.
7. Troops in revolting province become rebel troops.
8. Construction completes after enough ticks.
9. Command center in starting province unlocks global troop control.
10. Command center outside starting province does not unlock global troop control.
11. Raid damages buildings but does not capture province.
12. Conquest still captures province normally.

## Migration Strategy

Implement migration defensively:

1. Any missing economy block should be created with defaults.
2. Any missing building dictionary should be initialized empty.
3. Any old `remaining_buildings` value should remain untouched until typed buildings replace it.
4. Any old `construction_progress` value should remain untouched until active construction fully replaces it.
5. Province display should tolerate partially migrated provinces.

## Risks and Mitigations

### Risk: Too many interdependent systems at once

Mitigation: implement in phases and keep old aggregate fields until the new systems are stable.

### Risk: Happiness death spirals

Mitigation: add passive recovery, warning UI, and conservative penalties during the first balance pass.

### Risk: Command center rules confuse players

Mitigation: show clear text such as:

```text
Global troop control active: starting province has a Command Center.
```

or:

```text
Only local troops controllable: starting province has no Command Center.
```

### Risk: Raids become better than conquest

Mitigation: cap building damage and prevent province capture through raid outcomes.

### Risk: Save migration breaks existing campaigns

Mitigation: never assume new fields exist; normalize every province before use.

## Recommended First Milestone

The first practical milestone should be:

1. Add economy schema defaults.
2. Add normalization/migration helpers.
3. Add building catalog constants.
4. Add derived calculation helpers.
5. Display debug-only derived values without changing gameplay outcomes.

This gives a safe foundation before enabling construction, revolutions, command-center control, or raids.
