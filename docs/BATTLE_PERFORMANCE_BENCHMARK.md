# Large-battle physics benchmark

This standalone benchmark drives **actual Godot 4.7.2 physics, production enemy
scripts, production Ball.gd, and real ZoneTemplate water areas**. It does **not**
approximate pin collisions, replace enemy movement with analytical calculations,
change gameplay rules, or touch the Grand Map or its save format.

## Run

Import assets once:

```sh
godot --headless --path . --editor --import
```

Then run (the `--fixed-fps 60` flag is essential):

```sh
godot --headless --fixed-fps 60 --path . \
  --script res://scripts/BattlePerformanceBenchmark.gd -- \
  --ticks 600 --warmup-ticks 30 --samples 3 --seed-count 3 \
  --output-dir /tmp/sunnyslopes-battle-benchmark
```

Godot's `--fixed-fps` disables real-time synchronization. Without it, a
10-second battle could appear to cost ~10 seconds merely because the engine
waits for real time. The benchmark samples elapsed time between physics and
process-frame signals as well as the engine's own
`Performance.TIME_PHYSICS_PROCESS` monitor. Include both metrics in any
comparison. We run 60 fixed physics steps per virtual second.

For a focused scenario:

```sh
godot --headless --fixed-fps 60 --path . \
  --script res://scripts/BattlePerformanceBenchmark.gd -- \
  --scenario large_mobile_water --ticks 600 --samples 4 --seed-count 3 \
  --output-dir /tmp/battle-water
```

Use `--strict` to return a nonzero exit code if two replays of the same
scenario/seed produce different quantized final-state hashes. The default CI
run *reports* nondeterminism but does not fail on it, because physics scheduling
and cleanup timers need their own repeatability baseline before an exact
checksum can be used to gate optimizations.

## Scenarios

| Name | Bodies | What it exercises |
|---|---:|---|
| small_stationary | 25 | Low-cost Pin/HeavyPin control |
| large_stationary | 90 | Native solver and base pin callbacks without movement AI |
| large_mobile_dry | 90 | 45 Runners + 45 Chiefs, no water |
| large_mobile_water | 90 | Same composition, with three production water pools |
| dense_collisions | 90 + ball | Tight five-type grid, high-speed ball collision chain |
| full_stress | 90 + ball | Runners, Chiefs, elites, water, six obstacles, forcefield |
| generated_promoted | up to 90 + ball | Real LevelGenerator offensive encounter, 300 strategic troops promoted into elite pins |

Each scenario runs several independent fixed seeds, and each seed is replayed
multiple times. The benchmark constructs a fresh scene tree for each replay,
spawns the real `.tscn` files, lets a warmup pass finish, and then measures a
fixed number of physics frames. Setup time is reported separately.

## Output

`battle_performance_report.json` contains per-replay:

- Setup milliseconds, actual spawned physical enemies, and type composition
- Total elapsed measured milliseconds and per-tick median/p95/p99
- Godot `TIME_PHYSICS_PROCESS` mean/p95 (native engine + physics scripts)
- Mean/max 2D collision pairs, mean active physics bodies
- Standing/knocked/removed/water-sunk enemy counts and ball position/velocity
- Final state SHA-256 (positions, rotations, velocities rounded to 0.01)
- Per-seed repeatability and mismatch records

One `BATTLE_BENCH_SCENARIO` JSON record prints for each scenario; the runner
prints `BATTLE_BENCH_COMPLETE` after writing the full report.

GitHub Actions workflow:
`.github/workflows/battle-performance-benchmark.yml`
imports assets, checks script parsing, exercises all seven scenarios, uploads
the JSON report and execution log, and supports manual full-length dispatch.

## Interpretation and limitations

- Compare **on the same runner** to avoid host CPU variability. Physics render
  costs are **not** represented by headless measurements. Re-run stressful
  encounters in the game's browser build with its existing F9 diagnostics.
- The synthetic fixtures use exact production Pin/Runner/Chief and Ball scripts
  but not the real strategic battle lifecycle/UI. The generated-promoted case
  includes real generation and promotion behavior. Fixture generation is not
  counted in physics-tick totals.
- The per-tick wall cost includes signal scheduling and engine execution, not
  just script callbacks. The Godot physics monitor is a helpful second view.
- A matching state hash is a **strong regression indicator for the fixture**,
  not a proof of gameplay equivalence for every possible shot.
- Repeatability should be established before using `--strict` or stored
  baseline fingerprints as blocking tests. Cross-OS engine physics may differ.
- This test is not a browser graphics benchmark; it cannot directly measure
  GPU rendering or browser WebGL overhead.

## Comparison plan

1. Run on unchanged `main` and save its report.
2. Identify whether mobile, water, dense or generated-promoted battles cause
   the largest cost.
3. Add *optional* per-function counters in separate instrumentation branch for
   the most costly case (e.g. Runner/Chief water path checks, pin scans).
4. Optimize one suspected hot path. Re-run identical seeds and compare timing,
   physical outcomes and final-state hashes (tolerances if hashes unstable).
5. Only then consider native physics settings such as CCD/sleeping or collision
   layers, since those risk changing knock-over chains.
