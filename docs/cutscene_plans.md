# Cutscene Implementation Plans

## Goal
Add a simple dialogue cutscene with:
- a static background,
- two characters (player at bottom facing up, other at top facing down),
- a short settling animation (~2 seconds),
- dialogue text panel at the bottom.

## Plan 1 — Scene + Tween (Minimal/fastest)
**How it works**
- Create a dedicated `CutsceneOverlay.tscn` on a `CanvasLayer`.
- Add nodes:
  - `TextureRect` background,
  - `Sprite2D` player (bottom, facing up),
  - `Sprite2D` other (top, facing down),
  - bottom dialogue panel (`PanelContainer + Label`).
- On `_ready()`, start a `Tween` that moves one or both sprites from slightly offset positions to final positions in ~2.0s (ease out).
- Advance dialogue lines with input (`ui_accept`) and close when lines are exhausted.

**Expected quality**
- Good enough for early story beats.
- Clean “slide-in and settle” motion, but limited cinematic polish.
- Best if you only need occasional simple dialogue moments.

**Computational demand**
- Very low (a few UI nodes + one tween).
- No per-frame custom logic beyond normal Godot UI draw/update.

**Assets required**
- 1 background image (can reuse map/location art).
- 2 character sprites (existing player/enemy portraits or full-body sprites).
- Optional dialogue panel frame texture (can reuse existing UI frame assets).

---

## Plan 2 — AnimationPlayer Timeline (Balanced quality)
**How it works**
- Same base scene structure as Plan 1.
- Use `AnimationPlayer` with a 2.0s `intro_settle` animation track:
  - character positions,
  - optional slight scale or bob,
  - optional panel fade-in.
- Use animation call tracks or script callbacks to reveal first dialogue line when intro ends.
- Dialogue flow still handled by a small script.

**Expected quality**
- Better consistency and polish than ad-hoc tweens.
- Easier to author/tune exact movement style and timing in editor.
- Strong default choice for maintainable cutscenes.

**Computational demand**
- Low.
- Slightly more authoring complexity than Plan 1, runtime cost still minimal.

**Assets required**
- Same as Plan 1.
- Optional additional portrait variants (neutral/talking) for stronger presentation.

---

## Plan 3 — Data-driven Cutscene System (Reusable/scalable)
**How it works**
- Build a generic `CutsceneController` scene/script + JSON/Resource definition format:
  - background ID,
  - actor slots (`player_bottom`, `other_top`),
  - intro animation params,
  - dialogue line list + speaker tags.
- Controller loads data, binds assets, runs intro animation, and advances dialogue by script state.
- Can support more templates later (e.g., left-right confrontation, ambush angle).

**Expected quality**
- Comparable per-cutscene visual quality to Plan 2 initially.
- Highest long-term consistency and content velocity once framework exists.
- Overkill if you only need 1–2 cutscenes.

**Computational demand**
- Low at runtime; moderate implementation overhead.
- Slightly more memory/logic from data parsing and generic controller structure.

**Assets required**
- Same core assets as Plans 1/2.
- Additional data files per cutscene (JSON/Resource).
- Optional library of backgrounds/portraits to realize scalability benefits.

---

## Comparison Matrix
| Plan | Expected Output Quality | Computational Demand | Asset Demand | Build Complexity | Best For |
|---|---|---|---|---|---|
| 1. Scene + Tween | Basic-to-good | Very low | Low | Very low | Quick MVP this sprint |
| 2. AnimationPlayer | Good-to-very good | Low | Low-to-medium | Low-to-medium | Most teams; balanced choice |
| 3. Data-driven System | Good now, high consistency later | Low runtime / medium dev cost | Medium | Medium-to-high | Many future cutscenes |

## Recommendation
- **Pick Plan 2** for best balance now: strong polish, simple runtime, and manageable authoring.
- If scope is extremely tight, start with **Plan 1** and migrate to Plan 2 later.
- Only choose **Plan 3** if you already know multiple cutscenes will be added soon.
