# Workflow Draft

Use this document as the shared operating rhythm for human and agent work.

## Before Work

1. Run `git status --short --branch`.
2. Identify existing user changes before editing.
3. Read `AGENTS.md` and the relevant docs for the area being changed.
4. If Godot is needed, check `C:\Users\dever\Downloads` for the local Godot 4.7 archive.

## During Work

- Keep source changes focused on `scripts/`, `scenes/`, `assets/`, `sprites/`, `project.godot`, and durable docs.
- Treat `.godot/`, `*.import`, `testapp/`, `weboutput/`, and build packages as generated local state.
- Avoid mixing cleanup, gameplay behavior changes, and formatting churn in one change unless the cleanup is required.
- Prefer small, inspectable commits.

## Export Workflow

- Keep export configuration in `export_presets.cfg`.
- Export outputs should go to ignored folders such as `weboutput/`, `exports/`, `build/`, or `dist/`.
- Do not commit generated `.pck`, `.wasm`, `.apk`, `.aab`, `.zip`, or exported app folders.
- After exporting, run `git status --short --ignored` if you need to confirm outputs are ignored.

## Git Hygiene

- Use `rg --files` or `git ls-files` to confirm whether a file is source or generated.
- If Godot regenerates `.import` or `.godot/`, leave those files untracked.
- If a generated file appears in `git status`, update `.gitignore` or remove it from the index before proceeding.

## Documentation Hygiene

- Keep everyday guidance in Markdown at the top level of `docs/`.
- Put historical dumps, screenshots, and raw debug notes under `docs/archive/`.
- If a binary `.doc` file contains still-useful information, extract it into Markdown and leave the original in `docs/archive/raw-notes/` only as historical backup.

## Release Checklist Draft

1. Confirm `project.godot` version/name/main scene.
2. Confirm `export_presets.cfg` platform settings.
3. Export into an ignored output folder.
4. Smoke test the exported build.
5. Keep release artifacts outside Git or attach them to a release system.
