# Friendly Boss Logging Assessment

## Overall viability
The current logging format is already useful for debugging this class of bug because it captures:
- Start-of-turn and end-of-turn boss presence.
- A movement intent record (decision logic) and movement outcome record (execution results).
- Per-turn combat and troop movement events that can explain state changes.

From this sample, the logs provide enough signal to infer that the boss existed and moved correctly on Turn 3, then was missing by Turn 5 without an explicit death/removal event.

## What works well in this log
- **Decision + execution split**: You can distinguish planning errors from runtime mutation errors.
- **Cross-system context**: Troop movement and invasion lines help correlate boss behavior with broader turn resolution.
- **Rich move-plan payload**: `active_bosses`, `path`, and `reason` are strong clues when pathfinding/targeting is involved.

## Gaps that limit root-cause analysis
1. **Missing turn continuity metadata**
   - Turn numbers are duplicated (`Turn 2` appears twice), and `Turn 4` is absent.
   - There is no strict sequence/tick identifier to prove ordering.

2. **No explicit lifecycle events for the boss entity**
   - There is no canonical line for `spawn`, `despawn`, `death`, `ownership change`, or `invalidated reference`.
   - "No active friendly boss found" is an observation, not a cause.

3. **No stable entity identity trace across systems**
   - `boss_id=5` appears in move logs, but not in every related line.
   - Other events (province capture, combat resolution, ownership transfer) are not consistently keyed by boss id.

4. **Insufficient phase visibility**
   - It is unclear in which exact phase boss lookup occurs versus troop movement resolution, invasion merge, province ownership updates, and cleanup.

5. **No invariant checks / assertions in logs**
   - The system does not log violated expectations (e.g., "boss exists at start but missing before cleanup without death event").

## High-value data to add
1. **Turn and phase envelope (required)**
   - `match_id`, `seed`, `turn_number`, `phase_name`, `phase_index`, and monotonic `tick_id`.
   - Example phases: `start_snapshot`, `orders`, `movement`, `combat`, `capture`, `boss_update`, `cleanup`, `end_snapshot`.

2. **Boss lifecycle event stream (required)**
   - Emit structured events:
     - `boss_spawned`
     - `boss_moved`
     - `boss_damaged`
     - `boss_killed`
     - `boss_removed`
     - `boss_reassigned`
   - Each event should include: `boss_id`, `faction_id`, `province_id`, `cause`, `source_system`, `turn`, `phase`, `tick_id`.

3. **Cause-coded disappearance diagnostics**
   - When "no active boss" is logged, include a causal probe:
     - `last_seen_turn`
     - `last_seen_phase`
     - `last_lifecycle_event`
     - `alive_flag`
     - `registry_contains_id`
     - `province_contains_boss_ref`
     - `faction_boss_pointer`

4. **Pre/post snapshots for boss state (diff-friendly)**
   - At minimum per turn:
     - `boss_registry_snapshot_before`
     - `boss_registry_snapshot_after`
   - Include only relevant fields: ids, alive flags, location, linked troop count, owning faction.

5. **Reference integrity checks**
   - Log validation results for relationships:
     - Boss registry ↔ faction current boss pointer
     - Boss location ↔ province occupant list
     - Core linked troop source ↔ boss hp mirror

6. **Deterministic replay hooks**
   - Record RNG draws used by boss-related decisions/combat or at least RNG state checkpoints per phase.

## Format recommendations
- Prefer **structured JSON logs** over free-form text for machine diffing and automated anomaly detection.
- Keep current human-readable summary, but generate it from structured events.
- Add a per-turn "boss timeline" section auto-assembled from lifecycle events.

## Example minimal additional lines that would likely solve this case
- `turn=4 phase=cleanup event=boss_removed boss_id=5 cause=province_entity_prune source_system=ProvinceCleanup`
- `turn=5 phase=start_snapshot event=boss_lookup_failed boss_id=5 registry_contains_id=false faction_boss_pointer=5 province_ref_present=false last_event=boss_removed@turn4.cleanup`

These two lines alone would usually turn a "mystery disappearance" into a directly actionable defect.
