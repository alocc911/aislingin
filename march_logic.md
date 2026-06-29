# Smarter CPU March Logic

## Purpose

CPU marches should feel deliberate instead of automatic. The opponent should still be readable and fair, but it should prefer attacks that can succeed, reinforce pressure that is already working, avoid wasting large armies into doomed fights, and protect important territory when the front line is unstable.

This document proposes a replacement decision system for the current threshold-first march behavior in `scripts/EnemyTurnSystem.gd`.

## Current Behavior Summary

The current march phase is mostly:

1. Build a snapshot of provinces.
2. Collect friendly/enemy sources whose troop count is at or above that side's march threshold.
3. Shuffle the eligible sources.
4. For each source, send all marchable troops minus `ENEMY_MARCH_LEAVE_BEHIND`.
5. Find the first reachable frontline target with `_find_frontline_path`.
6. Resolve arrival through `resolve_march_arrival`.

Important current rules to preserve:

- Same-owner marches reinforce rather than fight.
- Enemy marches into friendly territory can create or reinforce pending invasions.
- Non-player battles use the unified engagement rules: 1-for-1 troop losses, then surviving attackers damage buildings at `INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT`.
- Active boss homes have special movement/targeting exceptions.
- Friendly boss support and enemy boss home assaults have dedicated handling.
- Marches happen against live state, so earlier moves in the same phase can change later decisions.

The main weakness is that target selection is path-first, not outcome-first. A province can march just because it has enough troops, even when the selected engagement is low-value, unwinnable, or worse than reinforcing another front.

## Design Goals

- Prefer winnable attacks without making the CPU omniscient or passive.
- Make pressure coherent: reinforce existing invasions, exploit weak fronts, and finish damaged provinces.
- Keep fronts active even when no clean win exists.
- Avoid draining interior or strategically important provinces too aggressively.
- Keep behavior deterministic enough to debug, with controlled randomness for variety.
- Keep the first implementation small enough to fit inside the existing `EnemyTurnSystem.gd` march phase.

## Core Model

Replace "find a frontline path" with "score candidate march plans."

A march plan is:

```gdscript
{
	"source_id": int,
	"destination_id": int,
	"path": Array[int],
	"moving_troops": int,
	"score": float,
	"reason": String
}
```

For each eligible source, the CPU should evaluate reachable targets and choose the highest-scoring plan above a minimum action score. If no plan clears that score, the source holds position.

## Source Eligibility

A source may consider marching when all of these are true:

- It is friendly or enemy owned, using the same ownership semantics as the current march code.
- It is not an ignored boss-home source.
- It has more troops than its reserve requirement.
- It has at least one reachable target or reinforcement destination.

The old fixed threshold can remain as the first-pass minimum, but the smarter system should derive a reserve:

```text
reserve = max(
	side_leave_behind,
	local_defense_need,
	boss_or_home_guard_need
)
```

`moving_troops = available_troops - reserve`

Recommended first-pass reserve rules:

- Interior province: keep current leave-behind, usually 5 for enemies.
- Frontline province: keep enough to avoid becoming an easy counterattack target.
- Province adjacent to a stronger hostile stack: keep more.
- Boss home or boss-adjacent province: use existing boss exceptions first; if movement is allowed, keep a larger guard.

## Target Categories

Candidate destinations should be one of:

- **Attack:** hostile province that can be fought immediately.
- **Pending invasion:** friendly-owned province already under invasion by this CPU faction.
- **Reinforce ally:** same-owner province on or near the front.
- **Staging move:** same-owner province closer to a valuable target when no direct attack is good.

The current `_is_frontline_target_for_owner` remains useful, but it should become only one part of candidate discovery. The CPU should also consider same-owner reinforcement and staging destinations, not only hostile endpoints.

## Winnability Estimate

For every attack candidate, estimate outcome before committing.

Definitions:

```text
attackers = moving_troops
defenders = destination.remaining_troops
buildings = destination.remaining_buildings
survivors = attackers - defenders
building_damage = floor(max(survivors, 0) / INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT)
will_clear_troops = attackers > defenders
will_conquer = will_clear_troops and building_damage >= buildings
```

Classify attack confidence:

- **Decisive win:** conquers and keeps a useful survivor count.
- **Attrition win:** does not conquer, but meaningfully reduces buildings or defenders.
- **Pending pressure:** against friendly territory, creates/reinforces a pending invasion with enough troops to matter.
- **Trade:** near-even troop loss with strategic value.
- **Bad attack:** loses all attackers with little or no durable damage.

Recommended scoring should heavily prefer decisive wins and avoid bad attacks unless the strategic value is very high.

## Target Scoring

A candidate plan's score should be the sum of military value, strategic value, and safety, minus costs.

### Military Value

Add points for:

- Conquest is expected.
- Destination defenders are weak relative to attackers.
- Existing pending invasion from the same faction can be reinforced into a likely conquest.
- Destination has low buildings and can be finished.
- Attack removes a large hostile stack from the border.

Subtract points for:

- Expected attackers all die.
- Attack leaves the source dangerously weak.
- Attack only creates a tiny pending invasion.
- Destination already has a rival pending invasion that would cause the new army to waste itself.

### Strategic Value

Add points for:

- Target is adjacent to multiple CPU provinces and can consolidate a border.
- Target is adjacent to player/friendly territory and creates pressure.
- Target opens a path toward a boss home or important front.
- Target is a neutral province with low defenders and cheap expansion value.
- Target has high buildings or economy value if the economy system exposes that cleanly.

Subtract points for:

- Target is isolated and hard to reinforce.
- Capturing it would create an overextended pocket.
- March path crosses through provinces that should be protected.

### Safety Value

Add points for:

- Source remains above its local defense need after marching.
- Nearby allied provinces can cover the source.
- Destination, if conquered, would have enough troops to survive immediate neighboring pressure.

Subtract points for:

- Source becomes undefended.
- Source is adjacent to a stronger hostile stack.
- March would drain the last strong province on a front.

## Suggested First-Pass Weights

These are intentionally simple and can be tuned from logs:

```text
+1000 expected conquest
+350 expected pending invasion with survivors > defenders * 0.5
+250 finishes province with 0 buildings or 0 troops
+180 reinforces same-faction pending invasion
+120 attacks neutral province
+100 attacks player/friendly province
+20 per expected survivor
+10 per building damage
-600 all attackers die with no building damage
-300 source becomes undefended
-200 destination would be isolated after conquest
-100 per path step after the first
```

Use a small random jitter, such as `randf_range(-25, 25)`, only after scoring. This keeps decisions varied without letting randomness dominate obvious choices.

## Candidate Discovery

For each source:

1. Build a bounded BFS out to a small radius, such as 3 to 5 steps.
2. Keep paths through same-owner provinces.
3. Stop on hostile frontline provinces, but record them as attack candidates.
4. Record same-owner frontline provinces as reinforcement/staging candidates.
5. Respect the existing boss-home bridge rules and friendly boss exceptions.

The old full-map frontline path can remain as a fallback when no bounded candidates exist.

## March Amount

Do not always send every available troop.

Recommended first pass:

- For a decisive win, send only enough to win plus a survivor margin.
- For a pending invasion, send enough to exceed a useful pressure threshold.
- For reinforcement, send enough to bring the destination to a target defense level.
- For desperate pressure, cap the march to avoid emptying the source.

Example:

```text
needed_for_conquest = defenders + buildings * INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT + desired_survivors
moving_troops = min(available_after_reserve, needed_for_conquest)
```

If `available_after_reserve` is less than the needed amount, the plan can still be considered, but it should score as attrition or pending pressure rather than conquest.

## Turn-Level Coordination

The march phase should avoid each source making a totally local choice.

Minimum coordination:

- Keep the current live-state recalculation after each move.
- After each successful march, mark the destination/source as changed.
- Re-score later sources against the updated state.
- Prevent repeated trickle attacks into the same bad target.

Better coordination later:

- Build all candidate plans first.
- Sort plans globally by score.
- Execute the best plan, update state, then re-score affected nearby sources.

The first-pass implementation can stay source-by-source to keep risk low.

## Boss and Special-Case Policy

Preserve existing boss behavior before adding new scoring:

- Active enemy boss homes should still be ignored as ordinary march sources/destinations unless an existing special route allows them.
- Friendly boss movement should continue to use its dedicated post-march path.
- Friendly boss support marches should not be treated as ordinary enemy attacks against friendly provinces.
- Enemy boss homes should only be attacked by friendly-side logic through the existing assault path.

The scoring system should call the existing policy helpers instead of duplicating these rules.

## Player-Facing Personality

The CPU should look smarter through consistent patterns:

- It piles onto weak borders instead of wandering.
- It finishes provinces it has already damaged.
- It avoids attacking a strong province with a small stack.
- It reinforces threatened fronts before launching marginal attacks.
- It occasionally makes a risky attack when the strategic reward is high.

This should create a more competent opponent without requiring deep long-term planning.

## Debug Logging

Add optional high-priority debug output for march decisions:

```text
March plan: source=A troops=32 reserve=8 candidates=5 chosen=B score=1280 reason=expected_conquest moving=24
March hold: source=C troops=18 reserve=10 best_score=-40 reason=no_winnable_target
```

For rejected high-value targets, log compact reasons:

```text
Rejected target=D reason=unwinnable attackers=13 defenders=30 buildings=2 score=-520
```

This will make balancing much easier than trying to infer intent from only the final movement log.

## Implementation Plan

1. Add helper methods in `EnemyTurnSystem.gd` for source reserve, candidate discovery, outcome estimation, and plan scoring.
2. Keep `resolve_march_arrival` unchanged for the first pass.
3. Replace the `_find_frontline_path` call inside `run_enemy_march_phase` with `_choose_best_march_plan`.
4. Continue recalculating `live_snapshot_by_id` before each source acts.
5. Add debug logs behind the existing troop debug stream or a simple local toggle.
6. Tune weights with a few manual campaign turns.

## Verification Plan

- Run static Godot parse/headless checks if the local Godot executable is available.
- Exercise several manual campaign turns and compare logs.
- Confirm enemies still reinforce same-owner provinces.
- Confirm enemies avoid obviously unwinnable attacks when another winnable target exists.
- Confirm pending invasions are reinforced instead of ignored.
- Confirm boss-home exceptions still block or route movement as before.
- Confirm generated/export files do not enter Git.

