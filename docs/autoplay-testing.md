# Autonomous campaign balance testing

Use **Actions → Autonomous campaign balance lab → Run workflow** in `alocc911/aislingin`, or run the Godot script locally:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://scripts/AutoplayCampaignRunner.gd -- --seeds 5 --first-seed 71 --turns 100 --boss-turn 15 --output-dir "$PWD/autoplay-results"
```

The simulator executes actual seeded Europe-style province generation, province economies, AI movement, automated conquests, pending invasion resolution, and BossSystem combat without player clicks or manual construction orders. Player-owned provinces still use their existing automatic march/construction settings and earn ordinary passive income.

Outputs:

- `autoplay_summary.json` — initial settings and per-map full winner, dominant faction, first majority/80%/100% turns, boss led/won/survived, ending faction territories, march counts, conquest counts and revolt counts.
- `autoplay_timeseries.csv` — one row per faction per turn: ownership, troops, map-leader share, boss share, movement and outcome counters. Useful for graphs or comparing new balancing versions.
- `autoplay_provinces.csv` — one row per province and simulated turn: population by group, both happiness values, food, housing, income, recruitment, buildings, garrisons, shortages, and overcrowding.
- `autoplay_map_economy.csv` — map-wide turn-by-turn totals, including faction count, combined population, food, happiness, and per-turn revolutions.
- `autoplay_ownership_events.csv` — owner transitions with cause, preceding holding duration, and pre-reset happiness for revolutions when available.
- `autoplay_balance_report.md` — human-readable across-map summary and per-map comparison table.
- `autoplay.log` — output of the manually dispatched workflow, including one summary line for each map.

**Interpretation:** "winner" means 100% of provinces actually controlled, not simply greatest territory. A map without full control is *unresolved*, not a victory for the largest faction. A boss "ever led" only means boss territory exceeded every individual rival at least once, not that it conquered the map. **The simulator stops immediately on full control**, even before turn 100: post-victory economic evolution is not measured.

The reported average *completed* holding period includes only ownership spells that ended. The average *observed* holding period also includes ownership spells still in progress at the stopping turn; those are right-censored, so do not interpret it as a complete-lifetime estimate. Neutral ownership periods are excluded. The province ownership event log samples after scripted boss spawn, automated action cycles, and economy ticks. Multiple changes *within* one sampled phase can be condensed. Rebel provinces share one faction ID (9000), but individual revolutions are counted separately. Conquest-related revolt counts are based on automated-action acquisitions rather than boss's scripted starting acquisitions.

**Deliberate limitations:** A fixed, configurable boss spawn turn replaces the normal probabilistic campaign spawning sequence; initial boss takeover uses the live BossSystem with one boss and up to two **adjacent** acquired provinces, but omits boss-entry UI. The test does not reproduce the campaign’s variable boss-count schedule. No physics, human-shot effects, player-triggered attacks or story events are simulated. Do not equate a no-input result with a typical player campaign. The same seed/settings can be rerun to compare AI versions, but results depend on the source commit being tested.

For normal development, the economy-preview CI also executes a small no-input multi-seed sample and retains the results as an artifact. Use the manual workflow for larger batches. Keep seed lists and boss timing fixed across commits when measuring balance regressions.

## Recommended balance workflow

Run one 100-turn seed to inspect individual province histories, then run 50–100 fixed seeds when comparing economy changes. Keep settings, engine version and map seeds identical between commits. Compare final factions, highest individual-province population, total-map population, both observed and completed holding periods, revolution incidence per 100 province-turns, and repeat revolutions. Use `autoplay_provinces.csv` and `autoplay_ownership_events.csv` to diagnose unusual maps rather than relying only on overall means.
