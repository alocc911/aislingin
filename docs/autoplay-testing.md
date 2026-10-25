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
- `autoplay.log` — output of the manually dispatched workflow, including one summary line for each map.

**Interpretation:** "winner" means 100% of provinces actually controlled, not simply greatest territory. A map without full control is *unresolved*, not a victory for the largest faction. A boss "ever led" only means boss territory exceeded every individual rival at least once, not that it conquered the map.

**Deliberate limitations:** A fixed, configurable boss spawn turn replaces the normal probabilistic campaign spawning sequence; initial boss takeover uses the live BossSystem with one boss and two acquired provinces, but omits boss-entry UI. No physics, human-shot effects, player-triggered attacks or story events are simulated. Do not equate a no-input result with a typical player campaign. The same seed/settings can be rerun to compare AI versions, but results depend on the source commit being tested.

For normal development, the economy-preview CI also executes a small no-input multi-seed sample and retains the results as an artifact. Use the manual workflow for larger batches. Keep seed lists and boss timing fixed across commits when measuring balance regressions.
