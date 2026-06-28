# Agent Instructions

This is a Godot 4.7 project. Keep changes small, source-focused, and easy to review.

## Local Tooling

- If you need a Godot executable, check `C:\Users\dever\Downloads\Godot_v4.7-stable_win64` first.
- Prefer headless Godot checks when possible. If Godot is not installed or unpacked, say that clearly before falling back to static inspection.

## Repository Hygiene

- Do not commit `.godot/`, `*.import`, exported builds, build packages, or generated web output.
- `weboutput/` is treated as local export output. Leave it alone unless the user explicitly asks to work on exported files.
- Keep `project.godot`, `export_presets.cfg`, `scenes/`, `scripts/`, `assets/`, and `sprites/` as source-of-truth project files.
- Before large changes, run `git status --short --branch` and distinguish user changes from your own.

## Coding Guidance

- Follow the existing GDScript style: tabs for indentation, explicit return types where the surrounding file uses them, and conservative helper extraction.
- Prefer existing systems before adding new global state. Key systems are documented in `docs/ARCHITECTURE.md`.
- Avoid broad refactors while fixing gameplay bugs. This codebase has several large orchestration scripts, so narrowly scoped changes are easier to verify.

## Verification

- Review `docs/TESTING.md` before claiming a behavior is verified.
- If a change touches province ownership or economy behavior, run or reason through the self-tests in `scripts/OwnershipSemanticsSelfTest.gd` and `scripts/ProvinceOverhaulSelfTest.gd`.
- If a change touches exports or assets, confirm ignored generated files did not re-enter Git.
