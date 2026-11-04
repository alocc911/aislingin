# Water avoidance optimization: staged changes and validation

The physical Runner/Chief movement and random target-selection algorithms are
unchanged. Three independently reviewable branches are used to measure each
optimization under identical test conditions:

1. `optimize-water-geometry-step1-2026-11-03`: snapshot stationary water
   area centers/radii/aspects/rotations only when the existing actor water-cache
   refresh fires. The point-in-ellipse decision uses the original formula.
2. `optimize-water-broadphase-step2-2026-11-03`: compare a path's bounding
   rectangle against a conservative circle enclosing each water ellipse, expanded
   by one world unit. If all are disjoint, the path cannot touch water. Otherwise
   perform **the exact original 26/28-unit sampling loop**.
3. `optimize-water-target-cache-step3-2026-11-03`: reuse the current target's
   safe/unsafe result until either the target changes or the existing
   per-actor water-cache refresh runs. Candidate target tests and fallback
   behavior remain unchanged.

## Correctness

`scripts/WaterAvoidanceEquivalenceTest.gd` is a standalone Godot headless
regression test comparing **both old and new implementations** across:
- 24,000 random, near-edge and near-center point tests
- 25,000 random path pairs with both Runner (28 px) and Chief (26 px) sample intervals
- Rotated elliptical shapes, out-of-range aspect, zero/negative radii,
  overlapping water and extremely short/zero-distance routes
- Moved, re-rotated and resized pond geometry after refreshing the snapshot
- Empty-water path rejection

Run:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://scripts/WaterAvoidanceEquivalenceTest.gd
```

A single mismatched Boolean path or point response fails the test.

## Performance

The `.github/workflows/water-avoidance-optimization.yml` job clones the
original `main` code and the three stage branches onto **one CI worker**, and
runs the unchanged `BattlePerformanceBenchmark.gd` across dry mobile, water
mobile, and full-stress scenarios (two fixed seeds × two replays × 180 ticks).
It runs all seven scenarios on the final code as a further regression check.
Reports and raw logs are uploaded as workflow artifacts.

The benchmark has observed non-reproducible exact physics hashes for some
collision-heavy runs on unchanged code. It reports these mismatches; exact
point/path decisions are strict while scenario-level physics hashes are
diagnostic, not blocking. Compare elapsed CPU time and behavioral counters as
well as final state.

## Known boundaries

During normal engagements, water areas are static. If a water geometry object
is changed dynamically, the cached measurements are refreshed at the existing
Runner/Chief refresh interval (0.75/0.85 seconds of game time). The new cache
does **not** alter water collision/drowning detection in Pin.gd or Ball.gd.
The original raw point method is still retained for any special caller whose
padding differs from the configured avoidance padding.

The separate Runner spawn-anchor behavior and repeated failed target-selection
loops are intentionally not changed in this performance patch.

Headless physics timings exclude GPU/WebGL rendering and are not a substitute
for browser testing on a player's device.
