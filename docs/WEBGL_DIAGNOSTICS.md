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

## Repeatable five-mode experiment

1. Use one map, window size, zoom level and browser. Open it with ?glprobe=1, press F9, and let normal mode run stationary 15 seconds. Press F7.
2. Press F8 for troop_icons_off, leave idle 15 seconds, then press F7.
3. Repeat for info_panels_off, borders_off, and all_provinces_off.
4. Press F8 again to return to normal, and repeat the baseline.
5. Repeat a standard engagement, capturing the moment buffer warnings first occur.
6. Copy [PerfSnapshot], [WebGLProbe], and SunnyWebGLProbe.dump() output and note any visual corruption.

If illegal buffers disappear only when a specific render layer is off, that layer is the strongest lead. If errors persist even with all provinces hidden, inspect shared terrain/canvas rendering and the Godot Compatibility backend.

## Other confirmed defects

Pin.gd and ZoneTemplate.gd load original PNGs using Image.load_from_file, which can fail in Godot exports even when the imported Texture2D exists. Main.gd creates a preview with z_index 5000 beyond Godot's supported range. These are independent issues to fix after the WebGL experiment.