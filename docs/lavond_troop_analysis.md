# Lavond troop movement analysis (from `docs/ddump.doc` and `docs/fbossdbug.doc`)

## Method
- Both `.doc` files are legacy Word binaries; values below were extracted with `strings -el` and aligned by turn/tick sequence.

## What happened at Lavond

### 1) Why Lavond initially had 25
- Turn 2: `Enemy 1 moved 31 troops from Botheiiam into Lavond (Neutral-owned). Lavond was conquered and 25 troops remain.`
- This is normal conquest attrition of 6 (31 -> 25).

### 2) Why Lavond later had 11 before boss arrival
- Turn 3: `Enemy 1 moved 25 troops from Lavond into Rofi ... 19 troops remain.` Lavond therefore drops to 0.
- Turn 5: `Enemy 1 moved 11 troops from Lavond into Totaimar ... 5 troops remain.` This implies Lavond had been refilled before the move (from other unseen steps), then spent 11 out.
- Turn 7: `Enemy 1 moved 12 troops from Lavond into Havoreith ... pending invasion reinforced to 24 troops.`
- Turn 9: `Enemy 1 moved 12 troops from Lavond into Botheiiam ... invasion is pending.`
- Turn 10: `Friendly moved 18 troops from Botheiiam into Lavond ... province held with 0 troops, 4 buildings remaining.` This means Lavond had defenders removed to 0 by the attack resolution.
- Turn 11 event stream then includes `Friendly moved 5 troops from Botheiiam into Lavond ... province held with 11 troops, 5 buildings remaining.` So at that point Lavond has 11 non-boss troops.

### 3) Why it looked like too many when boss entered Lavond
- Turn 11 start: friendly boss at Botheiiam with `boss_troops=145`, province troops `troops=150` (i.e., 145 core + 5 local).
- Boss moves Botheiiam -> Lavond.
- Move resolution says: `immediate battle at Lavond removed 11 troops each side; boss survives with 134 troops.`
- The destination summary logs `destination_base=80` for Lavond when boss arrives.

Interpretation:
- There are **three different troop buckets** being combined in logs:
  1. **Boss core troops** (`boss_troops`, tied to boss HP): 145 -> 134 after immediate battle.
  2. **Province resident marker** (`destination_resident=5`), likely the guard/minimum stack tied to occupancy logic.
  3. **Province base/non-core troops** (`destination_base`, `Destination Troops (non-core)`), which can include troops produced by standard province movement/combat outcomes.
- So the apparent "too many" at Lavond is largely that the debug output is mixing boss-core and non-core counts shown in adjacent lines, not a single canonical stack number.

### 4) Why too many seemed to remain after boss left
- Turn 12 start at Lavond: boss has 134, but province troop count shown as `troops=139` (again boss 134 + resident/base 5).
- Boss moves Lavond -> Totaimar and keeps `boss_troops=134` (no immediate battle this hop).
- Same turn troop phase: `Friendly moved 75 troops from Lavond into Totaimar ... Totaimar was conquered and 75 troops remain.`

Interpretation:
- Boss departure does **not** drain the province’s non-core troop bucket to zero; only boss-core follows the boss.
- Separate autonomous troop movement logic then moves large provincial stacks (here 75) independently of boss movement.
- So the "too many stayed behind" perception is consistent with current architecture: boss-core moved; provincial stack remained and then moved via normal troop AI.

## What is working
1. Boss core troop tracking appears internally consistent across the Lavond segment:
   - 145 at Botheiiam start (T11) -> 134 after immediate battle at Lavond -> 134 after moving to Totaimar on T12.
2. Immediate battle application against destination defenders is occurring (11-vs-11 event) and reflected in boss core.
3. Province-level troop AI continues to issue separate moves from Lavond after/around boss movement.

## What is not working / likely buggy or confusing
1. **Logging semantics are ambiguous/inconsistent**:
   - `Destination Faction` alternates labels (`Friendly`, `Friendly Boss`, numeric faction IDs) in ways that do not map cleanly to ownership semantics.
   - `Destination Type=friendly` can appear with conflicting faction labels in other turns.
2. **Mixed troop buckets are reported side-by-side without explicit total formula**:
   - `boss_troops`, `troops`, `destination_base`, and `destination_resident` are easy to misread as one stack.
3. **Timeline continuity is broken across dump sections** (multiple continuity warnings / reset from turn 32 to turn 2 in same stream), making causal analysis harder and potentially indicating instrumentation stitching issues.
4. **Possible province-state carryover confusion**:
   - Several events imply Lavond had troops available after prior depletion; this may be valid due to reinforcement/production not fully shown in this dump slice, but without explicit per-turn province snapshot it looks like spontaneous troop appearance.

## Bottom line for the Lavond question
- The boss did enter Lavond with a large core army, but the province already had its own non-core troop context, and the logger reports both.
- After the boss left, province troops still existed because they are tracked separately from boss-core troops and can continue moving independently.
- So the main problem is not necessarily arithmetic loss/gain in boss troops; it is **unclear instrumentation and mixed accounting domains** that make it look like overcounting.


## Specific answer: why Lavond jumped from 4 to 214 on turn 11
If you read Lavond as a **single** number, the jump looks impossible. The dump is actually layering three counters:

- **Boss core troops that entered Lavond**: the boss starts turn 11 at 145 and loses 11 in immediate combat, so **134** core troops remain with the boss in Lavond.
- **Province base/non-core stack at Lavond**: inferred as **75** by the immediately following turn’s move (`Friendly moved 75 troops from Lavond into Totaimar`), which means those 75 were already present as Lavond’s non-core stack at the end of turn 11.
- **Resident/minimum province marker**: **5** (`destination_resident=5`).

That yields: **134 + 75 + 5 = 214**.

So the “extra 210” did not come from one spawning event. It came from **mixing troop domains** in one mental total:
- boss-core troops newly present in province view,
- existing/non-core province troops,
- and the resident floor marker.

If your “beginning of turn 11 = 4” is the non-core/province-visible count, then the delta to 214 includes the boss core entering the province view plus the non-core stack and resident marker being counted together.


## Clarification: where the Lavond non-core/base troops likely came from
Short answer: from the evidence in these dumps, they do **not** have a clean, legitimate movement trail into Lavond immediately before the jump. That is why this looks like a bug, not just a reporting misunderstanding.

What the logs show:
- At turn 10, Lavond is fought over and can be reduced to 0 defenders (`Friendly moved 18 troops from Botheiiam into Lavond ... held with 0 troops`).
- At turn 11, boss arrival logs `destination_base=80` at Lavond, but no preceding Lavond inbound move in the same slice accounts for an 80-stack appearing there.
- Later in the same turn, other Lavond events are much smaller (`Friendly moved 5 ...`, `Enemy 99 moved 20 ... Lavond was conquered and 16 remain`), which also do not explain an 80-stack source.
- On turn 12, a `Friendly moved 75 troops from Lavond into Totaimar` event implies a large Lavond non-core stack existed, but the previous turn’s event trail does not show where that stack was assembled.

Most plausible interpretation:
- `destination_base`/province non-core is being hydrated from a stale/incorrect province-state snapshot (or merged from another accounting bucket) during/after boss movement resolution.
- In other words, the jump is not traceable to visible troop moves; it is likely state-accounting leakage or snapshot ordering error.

So when asked “where did those troops come from?”, the honest dump-backed answer is: **the logs do not provide a valid causal troop movement path; the stack appears to be synthesized by buggy state reconciliation.**
