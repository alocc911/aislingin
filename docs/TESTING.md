# Testing Draft

This project currently has lightweight GDScript self-tests and manual Godot verification paths. Expand this file as repeatable test commands become available.

## Static Checks

- Run `git status --short --branch` before and after changes.
- Use `rg` to inspect references and affected call paths.
- For source cleanup, verify generated files stay ignored with `git status --short --ignored`.

## Godot Checks

If a Godot executable is needed, check `C:\Users\dever\Downloads` first. The known local archive at draft time is `Godot_v4.7-stable_win64.exe.zip`.

Suggested checks once Godot is available:

```powershell
godot --headless --path . --quit
```

For gameplay changes, also open the project in the editor and run the configured main scene from `project.godot`.

## Province History Regression Tests

Province event recording has a standalone SceneTree runner:

```powershell
godot --headless --path . --script res://scripts/ProvinceHistoryTestRunner.gd
```

The runner returns a nonzero exit code on failures. It covers per-turn happiness de-duplication, ownership changes and their causes, building damage history, lost-province alerts, rebellion classification, bounded history size, and the exact totals and provenance of recruitment, troop arrivals/departures, combat losses, and replacement garrisons. This is a source-level test of the history model; also run a manual game smoke test for the History tab, pending enemy invasions, and toast/menu interactions. When Godot is unavailable, do not report these tests as executed.


## Self-Tests

The repo contains three regression-style scripts:

- `scripts/OwnershipSemanticsSelfTest.gd`
- `scripts/ProvinceOverhaulSelfTest.gd`
- `scripts/InvasionRulesSelfTest.gd`

They expose static `run(...)` functions and are designed to be invoked from debug tooling or a small temporary runner. They are not currently wired into a committed automated test scene. `InvasionRulesSelfTest.run()` checks both directions of zero-garrison invasions, building clearance before conquest, dispersal of non-conquering survivors, and player defensive results.

## Manual Smoke Test Checklist

1. Launch the main menu.
2. Start a run.
3. Confirm the ball, pins, UI overlay, province display, and turn flow initialize.
4. Exercise one interaction that touches the changed system.
5. Check Godot output for warnings or errors introduced by the change.

## TODO

- Add a committed headless test runner scene or script.
- Add a one-command test entry to this file once the runner exists.
- Capture export smoke-test steps for Web and Android separately.
