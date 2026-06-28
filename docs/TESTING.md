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

## Self-Tests

The repo contains two regression-style scripts:

- `scripts/OwnershipSemanticsSelfTest.gd`
- `scripts/ProvinceOverhaulSelfTest.gd`

They expose static `run(...)` functions and are designed to be invoked from debug tooling or a small temporary runner. They are not currently wired into a committed automated test scene.

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
