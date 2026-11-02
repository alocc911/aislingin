# Five-map 25/75 happiness floor validation

This file triggers the one-time comparison workflow on commit. The workflow can also be
run manually from GitHub Actions for future balancing checks.

## Change being evaluated

- When a province has **fewer than 75 combined native and outlander residents**, both
  happiness values have a floor of **25** during the regular province economy tick.
- At a total population of **75 or more**, the normal happiness decline and zero-point
  revolution behavior apply.
- Every province, including those devastated by a conquest, is evaluated from its
  **current population** every turn.
- Happiness movement remains capped at 30 points per turn before applying the floor.
- Shared rebel faction ID 9000 and rebel revolution immunity are unchanged.
- Full-map autoplay still ends immediately when one faction controls all provinces.

## Reproduction settings

- Map seeds: 71, 172, 273, 374, 475
- Simulation: actual generated map, no player input
- Maximum turns: 100 per map; stop on victory
- Boss enters: turn 10
- Engine: Godot 4.7.2 headless

## Recorded baseline, before applying the rule

| Seed | Final turn | Winner | Revolutions |
|---:|---:|---|---:|
| 71 | 15 | enemy_9000 | 50 |
| 172 | 18 | enemy_9000 | 46 |
| 273 | 17 | enemy_9000 | 53 |
| 374 | 17 | enemy_9000 | 59 |
| 475 | 18 | enemy_9000 | 72 |

Across five maps: 280 total revolutions; mean final faction count 1.0,
mean observed province holding duration 3.04 turns, mean peak individual-province
population 642.18, and all five victories belonged to the shared rebel faction.

The validation workflow uploads its new simulation JSON, CSV files, Markdown report
and test logs as the artifact `sunnyslopes-happiness-floor-five-seed-results`.

## Current-code no-input rerun (2026-11-01)

This documentation-only update triggers the existing five-seed, up-to-100-turn
headless campaign simulation on the latest `main` source code. Results from this
rerun evaluate the combined current balance rules; they do not isolate the original
25/75 happiness-floor change. The workflow uses seeds 71, 172, 273, 374, 475,
a forced boss entry on turn 10, and stops each map at full conquest or turn 100.
