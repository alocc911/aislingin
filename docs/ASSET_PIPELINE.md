# Asset Pipeline Draft

This project currently uses source image assets plus Godot-generated import metadata. Source assets are tracked; generated import sidecars are not.

## Source Asset Locations

- `assets/boss/`: boss source art.
- `assets/caltrops/`: caltrop art and related scene resources.
- `assets/ui/`: dashboard and icon art.
- `sprites/`: general actor, terrain, building, province, background, and dialogue sprites.
- `icon.svg`: project icon source.

## Import Policy

- `*.import` files are ignored and not tracked.
- The tracked sidecars removed during the cleanup contained only default/regenerable Godot import settings.
- If a future asset requires non-default import settings that must be versioned, document the exception here before tracking any `.import` file.

## Adding Art

1. Put the source file in the closest existing asset folder.
2. Use lowercase, descriptive names with underscores.
3. Open the project in Godot and let it regenerate imports locally.
4. Commit only the source asset and any scene/script changes that reference it.

## UI and 9-Slice Assets

- Keep dashboard frame/tray/banner art in `assets/ui/dashboard/`.
- If 9-slice behavior is stored on scene resources or theme resources, commit those scene/theme changes.
- If Godot stores a critical UI import setting only in a `.import` sidecar, add a narrow exception here and in `.gitignore`.

## Generated Output

- Do not store exported web, Android, desktop, or zipped builds in source control.
- Use ignored folders such as `weboutput/`, `exports/`, `build/`, or `dist/`.
