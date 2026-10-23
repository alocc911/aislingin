# Browser performance profiling (Phase 2)

This is an opt-in diagnostic for the exported Godot Web build. It is off by default and makes no gameplay changes.

## Using the profiler

1. Open the browser build and begin a game.
2. Press **F9** to show the diagnostic panel. Press F9 again to disable measurements.
3. Run three repeatable scenarios for at least 10–20 seconds each:
   - **grand_map_idle**: no scrolling or input
   - **grand_map_motion**: pan/drag the map
   - **engagement_flight**: fire balls with a representative number of runners, chiefs and buildings
4. Press **F7** to print a snapshot to the browser developer console. The panel also logs summaries approximately every five seconds while enabled. Copy the `[Perf]` console lines.
5. With F9 enabled before a level transition, the panel logs the synchronous **grand_map** and **engagement_spawn** generation times.
6. Compare like-for-like seeds, browser versions, window sizes, and zoom levels with browser hardware acceleration enabled.

The panel shows approximate FPS, average frame time and p95 frame time (milliseconds), Godot process/physics timings, 2D draw calls, scene node count, active 2D physics objects, and reported static memory. Frame summaries are sampled over at most 240 recent frames **per context**. A p95 value is the approximate 95th percentile (not maximum). A `0` or unusual performance monitor value can mean that the Web platform does not supply that metric.

## Interpretation

- If **grand_map_idle** or **grand_map_motion** still has poor frame times, prioritize reducing per-province draw nodes and unnecessary province visual updates.
- If **engagement_flight** performs worse primarily with more Runner/Chief enemies, investigate path sampling, physics and other enemy per-frame work.
- If engagement flight slows in building-heavy provinces, investigate the precise visual collision check and/or spatial indexing.
- If gameplay is smooth but transitions freeze, compare the reported synchronous generation times.
- Diagnose spikes with the browser's Performance profiler; this HUD is a low-overhead survey, **not** a precise CPU/GPU flame graph or a measured before/after benchmark.

## Code implementation notes

`scripts/WaterAreaRegistry.gd` shares discovered water `Area2D` nodes across Runner and Chief instances for 500 ms at most, and immediately invalidates on scene changes or invalid nodes. Each enemy's water avoidance/ellipse/path calculations are unchanged.

`MainLevelFlow.gd` now maintains a building-only node roster via obstacle-root child-enter/exit signals. The Phase 1 world bounds broad phase runs on candidates before the original exact overlap code. Building destruction and collision effects are unchanged.

If shared water areas are modified in place by future gameplay systems, call `WaterAreaRegistry.invalidate()` when modifying them; newly created or removed water zones are otherwise reflected by the periodic refresh.
