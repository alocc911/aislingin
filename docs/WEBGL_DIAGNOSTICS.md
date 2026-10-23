# Browser WebGL buffer-error investigation

Chromium and Firefox both report invalid WebGL buffer-target reuse followed by bufferSubData errors. The WebGL 2 specification disallows reusing an element-index buffer as another buffer type. A failed bind can explain the subsequent missing-buffer write, but the underlying rendering command is not yet isolated.

## Godot diagnostics

- F9: toggle the instrumentation HUD (off by default).
- F7: print a fresh-context JSON [PerfSnapshot] with frame average/p95, process/physics timings, draw calls, scene counts, physics contacts, memory, viewport and generation timings.
- F8: while on the Grand Map, cycle through visual-only isolation modes: normal, troop_icons_off, info_panels_off, borders_off, all_provinces_off, and back to normal.

F8 only hides visual CanvasItems; it does not change economy, collisions, ownership or turn state. Visibility is restored when F9 is switched off. A/B testing is intended for stationary scenes, because hiding all provinces makes the map difficult to operate.

The old logging flaw is corrected: only the current gameplay context and current visibility mode are reported. The first second after a context/mode change is excluded; measurements include up to the most recent 240 frames. Note that engine rendering metrics may return zero in a release Web build.

## Pre-engine browser WebGL probe

The newwebgame site loads webgl_probe.js before the Godot engine. The probe is completely inactive by default. Add ?glprobe=1 to the game URL, or &glprobe=1 when other query parameters are present, and reload. It will then trace the WebGL2 buffer target history without calling gl.getError (which could consume Godot errors).

It logs [WebGLProbe] summaries every seven seconds: bindBuffer and bufferSubData counts, draw calls, rAF frame timings, WebGL context details, suspected invalid target reuses, and subsequent writes to unbound buffers. The first 24 error instances include buffer identifiers and JavaScript call stacks. Other failures are counted.

In the browser developer console, run SunnyWebGLProbe.dump() and copy the full JSON text. SunnyWebGLProbe.mark('label') labels a test interval; SunnyWebGLProbe.reset() resets sample counts.

The probe adds diagnostic overhead while enabled. Its results are appropriate for identifying GL failures and comparing layers within the same session, not for quoting absolute uninstrumented FPS.

## Updated cached troop rendering and extended isolation

Troops now use a single cached SVG figure with per-province color and a `MultiMeshInstance2D` batch. The old ten primitive drawing commands per troop have been removed. Positions, counts, faction colors and black outlines are retained. `troop_draw_nodes` now counts batched nodes, and `troop_instances` reports the actual troop-icon count.

Press F8 while the Grand Map is idle to cycle through the following **independent, non-cumulative** tests:

| Mode | Hidden visuals |
| --- | --- |
| `normal` | Nothing |
| `troop_icons_off` | Cached troop batches |
| `info_panels_off` | Province cards and labels |
| `borders_off` | Per-province border and glow |
| `province_overlays_off` | Province highlighting/pattern overlays |
| `shared_borders_off` | SharedProvinceBorderOverlay |
| `background_sprites_off` | Sprite2D/TextureRect/NinePatchRect background visuals under the Zone/World branches, excluding provinces and obstacles |
| `terrain_zones_off` | All Zone-root visuals (including terrain polygons, water, and decorations) |
| `map_obstacles_off` | Obstacle-root visuals (including outer barrier) |
| `all_provinces_off` | Entire Provinces root, including icons, borders, panels, overlays |
| `world_except_provinces_off` | Zones, Obstacles and Bounds roots |
| `all_map_visuals_off` | Provinces, Zones, Obstacles and Bounds roots |

These are visibility-only diagnostic changes; collision geometry, province ownership, and turn logic are not modified. F9 restores original visibility. Because the viewport clear color is rendered by the engine, it cannot be hidden by a CanvasItem toggle; the `background_sprites_off` test concerns scene background artwork only.

For each mode, allow at least 10–15 seconds, then press F7 to record a fresh JSON `[PerfSnapshot]`. Compare `draw_calls`, `render_objects`, `render_primitives`, `process_ms`, frame mean/p95, and `hidden_render_roots`. At the end return to `normal` and capture another baseline. Repeat without `?glprobe=1` for less biased absolute FPS measurements.

## Other confirmed defects

Pin.gd and ZoneTemplate.gd load original PNGs using Image.load_from_file, which can fail in Godot exports even when the imported Texture2D exists. Main.gd creates a preview with z_index 5000 beyond Godot's supported range. These are independent issues to fix after the WebGL experiment.