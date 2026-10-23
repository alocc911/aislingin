# Conquest and Europe-inspired strategic geography

## Player engagements

- Standard offensive provinces (enemy and neutral) become friendly once **every defending troop is down**, including a province with no standing garrison. The existing 50% knockout threshold still controls the win/lose verdict and turn consequence for incomplete battles.
- Building loss is calculated deterministically: `round(start_buildings * knocked_down_troops / start_troops)`, clamped to the initial building count. For zero defending troops, infrastructure is fully destroyed if the player successfully occupies the undefended province.
- Normal captures have **zero surviving buildings** after a full clear. There are no free "half the old buildings" replacements. Building state goes through `Main.gd`'s persistent province synchronization.
- Boss homes remain under the boss system's special capture rules: wiping visible garrison troops alone cannot annex the boss before its defeat.
- The player is permitted to retain any successfully conquered ordinary province, even without an existing friendly border; access to battles is still determined by the game's launch/navigation mechanics. Other autonomous engagement rules are left unchanged.

## Grand-map generation

- A single family of **Europe-inspired mainlands** replaces random selection across seven global continent types.
- Every fallback silhouette is finalized *before* strategic sculpting, so retries cannot erase peninsulas.
- Late-stage coastline sculpting cuts elongated gulfs into the existing mainland and adds tapered, connected peninsulas directed toward distinct compass sectors. Parameters and seeds produce repeatable but distinctive maps, without forcing real-world outlines.
- Seed placement now prioritizes several narrow passages before the ordinary farthest-point region seeding. This can turn land bridges into one- or two-province gateways.
- All required provinces remain on a single accessible mainland, with graph adjacency derived from actual shared land cells. Separate naval mechanics and disconnected island rules are not introduced.
- A map's `strategic_geography` metadata records gulfs, peninsula arms, land count, blob score, and province articulation points.

## Validation and remaining balance questions

- `scripts/ConquestAndGeographySelfTest.gd` verifies 0%, 25%, 50%, 75%, 100% partial/full offensive outcomes, special boss exclusions, no-adjacency captures, and empty-garrison captures.
- The same runner generates eight seeded 24–36-province maps, checking repeatable geography, mutual land adjacency, connected graphs, and an expected frequency of choke points.
- `conquest-europe-preview.yml` runs the full province-economy regression suite and 100-turn simulations as well as these new checks; it produces a browser preview artifact without publishing to `slinggame`.
- **Out of scope:** comprehensive naval invasion mechanics; changes to enemy-vs-enemy troop/combat ratios; changes to base economic tuning; merging/publishing prior to gameplay acceptance.
