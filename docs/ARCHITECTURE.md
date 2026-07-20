# Architecture Draft

This document maps the current codebase at a practical level. It should be updated whenever systems are split, renamed, or given new responsibilities.

## Runtime Entry Points

- `project.godot` sets the main scene to `res://scenes/MainMenu.tscn`.
- `RunConfig` is autoloaded from `res://scripts/RunConfig.gd`.
- `scenes/MainMenu.tscn` and `scripts/MainMenu.gd` handle menu entry.
- `scenes/main.tscn` / `scenes/Main.tscn` and `scripts/Main.gd` appear to carry the main in-game orchestration layer.

## Major Systems

- `scripts/Main.gd`: top-level gameplay coordinator, debug/reporting utilities, screenshot/log helpers, and broad game-state interactions.
- `scripts/MainLevelFlow.gd`: level lifecycle and placement flow, including boss placement, water conflict handling, and building visuals.
- `scripts/LevelGenerator.gd`: procedural level geometry and template fitting.
- `scripts/LevelConfig.gd`: central constants and tuning values for level generation, provinces, economy, buildings, visuals, and UI-related gameplay data.
- `scripts/ProvinceSystem.gd`: province ownership, economy normalization, construction, revolution, income, and building calculations.
- `scripts/EnemyTurnSystem.gd`: enemy turn behavior and turn log formatting.
- `scripts/EngagementResolver.gd`: ownership/relation validation and engagement resolution helpers.
- `scripts/BossSystem.gd` and `scripts/BossVisualController.gd`: boss logic and visual layout/control.
- `scripts/InputController.gd`: player input and interaction targeting.
- `scripts/MainUIBridge.gd` and `scripts/UIOverlay.gd`: UI binding, bug report/data dump flow, and overlay behavior.
- Province management panel (right-click province on Grand Map): player-facing Overview / Build / Troops / Policies UI in `UIOverlay.gd`, fed by `ProvinceSystem.build_province_management_summary()` plus existing construction/troop/march APIs.

## Actor Scripts

- `Ball.gd`, `Pin.gd`, `Runner.gd`, `Chief.gd`, `HeavyPin.gd`, and `SpikyPin.gd` define actor-specific behavior.
- Actor scenes live in `scenes/` and should stay paired with their script names when possible.

## Data and Template Scripts

- `RNG.gd`: deterministic/random helper.
- `ZoneLibrary.gd` and `ZoneTemplate.gd`: zone definitions and template data.
- `CutsceneLibrary.gd` and `TutorialGuide.gd`: narrative/tutorial data.

## Self-Test Scripts

- `OwnershipSemanticsSelfTest.gd`: matrix checks for province ownership normalization and UI owner text.
- `ProvinceOverhaulSelfTest.gd`: economy/building/revolution regression checks for `ProvinceSystem`.

## Open Architecture TODOs

- Decide whether `Main.gd` should remain the integration hub or be split into smaller feature coordinators.
- Document scene ownership: which scenes are hand-authored, generated, or export-only.
- Add a lightweight diagram of game-state flow after the next feature pass.
