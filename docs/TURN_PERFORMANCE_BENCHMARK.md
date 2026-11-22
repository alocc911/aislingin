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


## Cross-revision gameplay parity (run before performance optimizations)

The separate `scripts/StrategicTurnParityRegression.gd` runner extends this
benchmark without changing production gameplay code. It checks **before vs.
after** outcomes, rather than just checking whether repeated runs of the same
revision agree.

The immutable reference source is commit
`72a7b826f2a4aaa98e89e6f4557b98f33190cdb4` (the pre-optimization
main branch, November 22, 2026). Do **not** advance this reference commit
when changing performance code; doing so would reset the gold standard.

The CI workflow `.github/workflows/strategic-turn-parity.yml`:

1. Checks out the reference commit and the candidate commit in separate
   directories, installs the **same** parity runner into both checkouts,
   and imports both Godot projects using the same Godot 4.7.2 container.
2. Runs `--mode capture` using reference gameplay code. It generates and
   **freezes** five initial states: the prior benchmark's three states
   (mid-game, contested, and boss), plus early-game and late-boss cases.
   The capture writes a binary snapshot containing the starting state and
   every expected turn result, and verifies a second independent replay.
   The baseline fixtures are not regenerated with candidate gameplay code.
3. Runs `--mode verify` with candidate gameplay code, restoring exactly
   those binary starting fixtures, resetting the global RNG to the same
   seed, and comparing each turn's complete persistent province and boss
   data, gold, turn counters, AI march diagnostics (excluding the actual
   system-clock timestamp), automated logs, and the next global RNG draw.
   The first divergent field and turn are printed; **any difference fails**.
4. Compares the existing seeded `AutoplayCampaignRunner.gd` CSV reports
   (ownership, province economy, troop counts, migration, revolts) and the
   existing `PlayerCampaignSimulationRunner.gd` CSV reports from reference
   and candidate runs. These are additional multi-turn consistency checks,
   not a replacement for the exact restored-fixture comparisons.
5. Uploads baseline fixtures, both simulations' reports, per-turn timing
   comparisons, and logs as a GitHub Actions artifact even when a test fails.

The workflow triggers on pushes and pull requests touching strategic source
files, and supports manual dispatch with configurable scenario turn counts
and autoplay seed count. The routine CI parity suite compares 4 successive strategic turns per frozen
fixture, two 30-turn autoplay maps, and a 20-turn Hard level-10
simulated-player scenario. Manual workflow dispatch can increase the exact
strategic replay to 20 or more turns, and extend the autoplay campaigns, when
extra coverage is desired.

### Local parity commands

Use **two copies of the source**, with identical Godot versions. In the
reference source at the pinned commit, copy the *unchanged* candidate
`scripts/StrategicTurnParityRegression.gd` file into the same path, then run:

```bash
godot --headless --path /path/reference --script res://scripts/StrategicTurnParityRegression.gd -- \
  --mode capture --turns 20 --artifact-dir /tmp/strategic-parity
godot --headless --path /path/candidate --script res://scripts/StrategicTurnParityRegression.gd -- \
  --mode verify --artifact-dir /tmp/strategic-parity
```

To freeze an actual browser save as an **additional** scenario, pass
`--save-file /absolute/path/game.ssave` to the reference capture command.
The resulting fixture contains the complete starting game state and can be
replayed by the candidate without the original save. The browser save does
not serialize the global Godot RNG, so the parity runner seeds both runs to
the same controlled continuation, not the historically exact next browser
random draw.

The binary fixture files and manifest in the artifact directory are the
independent reference. Keep them intact while comparing a candidate. The
candidate also writes `parity_comparison_report.json` with first-divergence
information and observed per-turn strategic CPU time. Timing data is not
part of the equality assertion.

### Important limitations

This headless test uses the real strategic subsystems, but the benchmark
harness is not the full `Main.gd` turn flow: live boss-arrival scheduling,
interactive player action/ball physics, UI, map reconstruction, province-node
cache behavior, and animated previews are not reproduced. Those still require
focused unit tests and browser smoke testing. Comparing a fixed random probe
after each strategic turn is a *test-only* RNG check; the extra draw is
deliberate and identical in reference and candidate simulations.

A passing parity suite is strong evidence that gameplay is unchanged in the
covered scenarios, not a proof of equivalence for every reachable state.
