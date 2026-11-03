# Mid-turn strategic performance benchmark

## Purpose

Measure the delay caused by strategic calculation after End Turn, without waiting for camera, UI, battle previews, physics, or rendering. This is deliberately not a full browser End Turn latency test, nor a benchmark for large battles.

Entrypoint: scripts/TurnPerformanceBenchmark.gd. It uses the actual ProvinceSystem, EnemyTurnSystem, EngagementResolver, BossSystem, and LevelGenerator, following the core phase order of EnemyTurnSystem.advance_turn_and_run_automation(). No gameplay tuning or gameplay files change.

## Fast default

Run with Godot 4.7:

    godot --headless --path . --script res://scripts/TurnPerformanceBenchmark.gd -- --samples 7 --output-dir /tmp/turn-performance

The runner generates three deterministic fixtures once:

- seed 71, end of turn 5 (mid-stage);
- seed 172, end of turn 8 (different map and economy);
- seed 273, end of turn 8, with a test-only boss activated before warmup turn 5.

Every fixture is restored into a fresh headless instance for every replay. The first replay is excluded as warmup, and the next seven one-turn replays are timed. Setup, clone, RNG reset, hash, and output are outside the timer.

Use --samples 3 for an exploratory check, or --samples 15 --warm-replays 2 for more stable figures.

## Benchmark an actual saved game

Download a .ssave game from the browser Save button at a stable Grand Map turn boundary. Prefer a state with multiple factions, populated construction queues, pending marches, and an active boss. Run:

    godot --headless --path . --script res://scripts/TurnPerformanceBenchmark.gd -- --save-file /absolute/path/sunnyslopes-level-5-turn-8.ssave --samples 9 --output-dir /tmp/saved-turn-performance

The benchmark reads the version-1 SunnySlopesGame binary Variant save unchanged, measuring the next strategic turn after that saved state.

Browser saves do not contain Godot's global RNG state. The benchmark explicitly seeds it before each replay for consistent comparisons rather than claiming to reproduce the exact next browser random draws.

## Timed phases

1. Construction queue planning
2. Pending invasion resolution
3. AI marches (two passes)
4. Legacy construction phase
5. Legacy recruitment phase
6. Boss actions
7. Economy migration, construction progress, population, food, happiness, recruitment and revolts
8. New turn gold income
9. Overall strategic turn

The live Main.gd also handles scheduled boss arrivals, history/debug capture, UI status, map refresh, and battle preview setup. Those are not timed here and must be measured separately in-game if the objective is the entire click-to-animation delay.

## Correctness guard

Each replay begins from the same deep-copied province, boss, treasury, and turn state, with a fixed random seed. After the timer ends, the runner calculates SHA-256 over the complete persistent province state, boss runtime state, treasury, and turn number. It fails if replays from the same fixture yield different hashes.

Save the report from the unmodified version before applying performance changes. Compare end_state_sha256 and all measured phase timings with the updated version. Hash changes across revisions should be investigated, not dismissed. Identical hashes are strong evidence of strategic state parity, but do not replace existing regression tests or validate presentation.

## Interpretation

- Compare median strategic_total first.
- Check p95 strategic_total for slow-tail variability.
- Rank phase medians to decide which optimization is worthwhile.
- Use the same hardware, Godot version, seeds, fixture, and benchmark settings.

The generated boss fixture is a deterministic stress scenario, not an exact reproduction of campaign boss placement. Real saved games are preferable for late-game fidelity.

## Limitations

- It is headless, so no map drawing, camera, UI, physics, or battle animation is included.
- The minimal main mock follows the existing autoplay harness and does not invoke every Main.gd callback, notably some history and boss arrival scheduling.
- A synthetic campaign fixture can become unrepresentative if a faction has already won; for that situation, use a real .ssave.
- For complete user-visible End Turn latency, separately instrument normal gameplay from button click through the first displayed auto-battle frame.
