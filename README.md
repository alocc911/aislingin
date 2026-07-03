# SunnySlopes

SunnySlopes is a Godot 4.7 game project. The source project lives in this repository; editor caches and exported builds are intentionally ignored.

## Quick Start

1. Open Godot 4.7.
2. Import or open this folder: `C:\godot_games\SnowDune\aislingin`.
3. Run the main scene configured in `project.godot`: `res://scenes/MainMenu.tscn`.

If Godot is not already available, check `C:\Users\dever\Downloads` for the local Godot archive noted in `AGENTS.md`.

## Source Layout

- `project.godot`: project settings, autoloads, main scene, input/rendering configuration.
- `scenes/`: Godot scenes for actors, UI, menus, and main game flow.
- `scripts/`: GDScript gameplay systems and controllers.
- `assets/`: grouped source art and UI assets.
- `sprites/`: sprite source assets used by scenes and generated content.
- `docs/`: durable design, workflow, architecture, and testing notes.
- `docs/archive/`: historical debug dumps and raw notes that are not daily reference material.

## Generated Files

Do not commit `.godot/`, `*.import`, `testapp/`, `weboutput/`, build folders, or exported packages. Godot will regenerate import sidecars and editor caches locally.

## Useful Docs

- `docs/ARCHITECTURE.md`: system map and ownership boundaries.
- `docs/WORKFLOW.md`: day-to-day Git, Godot, export, and cleanup workflow.
- `docs/ASSET_PIPELINE.md`: asset placement and import policy.
- `docs/TESTING.md`: available verification paths and self-test notes.

test text
