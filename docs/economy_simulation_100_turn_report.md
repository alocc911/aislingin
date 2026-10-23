# Province economy: 100-turn simulation report

**Baseline:** `economy-persistent-gold-paid-buildings-2026-10-22` development branch.  
**Runner:** `scripts/EconomySimulationRunner.gd`.  
**Verification:** [GitHub Actions run 39890910424](https://github.com/alocc911/aislingin/actions/runs/39890910424) — Godot import, economy regression suite, simulation, Web export and artifacts succeeded. Runtime script errors are CI failures.

## Method

Four independent, deterministic single-province simulations advanced `ProvinceSystem.tick_province_economy()` for **100 turns each** (400 observations). All scenarios use the game's production, population-growth, food-shortage, happiness, recruitment, construction, pricing, and revolt mechanics. Treasury income is credited once per friendly turn. Construction uses the game's charged-project path and, where applicable, autonomous recommendations. Gold persists between turns.

- **Neglected:** No player construction or automated building investments; starts with 40 gold.
- **Managed:** Starts with 40 gold; scripted intervention prioritizes food/housing, with normal affordable autonomous recommendations otherwise.
- **Growth-first:** Starts with 75 gold; prioritizes Growth Increasers and production above safety margins.
- **War-damaged:** Starts with 40 gold; follows managed priorities but suffers one repairable building loss every eight turns when friendly, and prioritizes repairs.

The simulator deliberately does *not* vary game tuning. It exercises one isolated province without neighbors, bosses, conquests, full combat, or external migration. Scheduled damage in the war scenario is a controlled economic stressor, not a simulation of battles. The management policies are heuristics, not optimal strategies.

## Results

| Measure | Neglected | Managed | Growth-first | War-damaged |
|---|---:|---:|---:|---:|
| Revolutions | 0 | 0 | 1 | 1 |
| Food-deficit turns / 100 | 98 | 73 | 58 | 57 |
| Overcrowded turns / 100 | 0 | 9 | 85 | 76 |
| Peak income per turn | 7.17 | 70.95 | 54.15 | 50.39 |
| Peak construction rate | 18.44 | 55.69 | 55.70 | 55.68 |
| Peak recruitment rate | 3.82 | 6.30 | 9.90 | 6.30 |
| Peak total population | 47.98 | 277.87 | 218.88 | 286.52 |
| Cumulative friendly gold income | 604 | 3,769 | 774 | 1,375 |
| End treasury | 644 | 3,556 | 688 | 1,155 |
| End owner | Friendly | Friendly | Rebel/enemy | Rebel/enemy |
| End troops | 305 | 1,811 | 519 | 594 |
| Manually started projects | 0 | 12 | 12 | 18 |
| Simulated building losses | 0 | 0 | 0 | 6 |

## Interpretation

1. **Severe recurring food shortages are survivable.** A neglected province experiences a negative food balance on 98% of turns without ever revolting; famine produces a smaller lower-output equilibrium rather than necessarily triggering political collapse. Whether this is sufficiently unstable for the desired design requires a separate balance decision.
2. **Excellent productivity is possible.** Managed investment reaches a peak income of about 71 gold per turn and a total population near 278 without hard production caps or revolt. This is consistent with the high-upside design target.
3. **Aggressive growth can implode.** Growth-first overbuilds its population before securing stability: it is overcrowded on 85 turns and eventually revolts. Repeated building damage also causes a managed-ish economy to revolt.
4. **The persistent treasury becomes very large.** The managed scenario receives 3,769 gold income, spends only about 253 gold and still ends with 3,556. Existing building prices are likely too low *relative to demonstrated income*, though this experiment excludes real campaign expenses such as ball upgrades.
5. **Troops accumulate independently of food and population costs.** The neglected province finishes with 305 soldiers despite almost permanent food shortages; managed reaches 1,811. Under the current code troop food demand is zero and recruiting does not deplete native population.

## Questions for subsequent balancing

- Should a *long sequence* of food shortages impose unrest in addition to contemporaneous shortages, so chronic famine threatens rule even when the population shrinks to an equilibrium?
- Should construction prices, particularly high tiers, scale with the prosperous economy, while keeping emergency farms and basic housing accessible?
- Should troop recruitment require native population and should standing troops consume food, to avoid armies growing indefinitely without economic cost?
- How much should repeated war damage erode the long-run productivity of otherwise successful provinces?

**No tuning changes are made by this report or the simulation runner.** The two prior priorities—damage persistence/combat integration and player/AI construction spending—are implemented separately in this same branch.

## Reproducing and accessing raw results

Run Godot 4.7.2 headlessly:

```bash
godot --headless --path . --editor --import
godot --headless --path . --script res://scripts/EconomyRegressionRunner.gd
godot --headless --path . --script res://scripts/EconomySimulationRunner.gd -- --output-dir /absolute/output/path
```

The runner creates `economy_100_turn_summary.json` and `economy_100_turn_timeseries.csv`. The associated GitHub Actions workflow uploads them in the `sunnyslopes-economy-100-turn-results` artifact, alongside an independent `sunnyslopes-economy-browser-preview` artifact.
