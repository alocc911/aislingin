extends RefCounted

const SAVE_PATH: String = "user://tutorial_guide_state.cfg"
const SAVE_SECTION: String = "tutorial_guide"
const CONTENT_VERSION: int = 5

const CATEGORY_GENERAL: String = "General"
const CATEGORY_ENGAGEMENTS: String = "Engagements"
const CATEGORY_UPGRADES_TOOLS: String = "Upgrades & Tools"
const CATEGORY_TERRAIN: String = "Terrain & Obstacles"
const CATEGORY_BOSS_EVENTS: String = "Boss & Special Events"
const CATEGORY_CAMPAIGN: String = "Campaign & Progression"

const PRESENTATION_COACH: String = "coach"
const PRESENTATION_NOTE: String = "note"

const GAMEPLAY_TUTORIAL_SCENARIO_ID: String = "opening_two_province"
const GAMEPLAY_TUTORIAL_SKIP_LABEL: String = "Skip Tutorial"
const GAMEPLAY_TUTORIAL_CLEAR_RULE_NEUTRAL_TROOPS_ZERO: String = "neutral_troops_zero"

const GAMEPLAY_TUTORIAL_SCENARIO := {

	"scenario_id": GAMEPLAY_TUTORIAL_SCENARIO_ID,
	"title": "Tutorial",
	"description": "Open on a small grand map with one friendly province and one neutral province. Clear the neutral province by knocking down all of its troops.",
	"skip_button_text": GAMEPLAY_TUTORIAL_SKIP_LABEL,
	"can_skip": true,
	"grand_map": {
		"small_map": true,
		"province_count": 2,
		"friendly_province_count": 1,
		"neutral_province_count": 1,
		"enemy_province_count": 0,
		"boss_enabled": false,
		"force_starting_origin_owner": "friendly",
		"force_starting_origin_index": 0,
		"friendly_province_indices": [0],
		"neutral_province_indices": [1],
		"enemy_province_indices": [],
		"force_no_buildings": true
	},
	"clear_condition": {
		"rule": GAMEPLAY_TUTORIAL_CLEAR_RULE_NEUTRAL_TROOPS_ZERO,
		"province_owner": "neutral",
		"province_index": 1,
		"remaining_troops_at_or_below": 0
	}
}

const FIRST_RUN_SEQUENCE: Array[String] = [
	"core_loop",
	"legal_launch_origin",
	"launch_input",
	"success_thresholds",
	"help_field_guide"
]

const NOTE_DEFINITIONS := {
	"core_loop": {
		"key": "core_loop",
		"title": "Turn Sequence",
		"category": CATEGORY_GENERAL,
		"order": 10,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Each turn resolves in a fixed sequence managed by campaign flow and resolver systems:\n1) The game determines the legal launch context for the current turn.\n2) The player launches one shot (press, drag, release).\n3) Real-time simulation runs until shot termination (movement, collisions, hazards, upgrade effects).\n4) If the turn entered an engagement, the engagement resolver evaluates thresholds and context rules.\n5) Persistent state is written back (troops, buildings, ownership/faction, progression fields, and related summaries).\n\nThe turn is not final until the post-shot resolution step completes.",
		"short_body": "Each turn resolves in a fixed sequence managed by campaign flow and resolver systems:"
	},
	"legal_launch_origin": {
		"key": "legal_launch_origin",
		"title": "Where Launch Is Allowed",
		"category": CATEGORY_GENERAL,
		"order": 20,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "A launch is valid only when the start position is inside legal launch space for the active turn.\nThe legal origin can be constrained by campaign state (for example, a specific highlighted friendly province).\n\nIf the start point is outside legal space:\n- launch is rejected,\n- the shot does not resolve,\n- and turn progression is not consumed.",
		"short_body": "A launch is valid only when the start position is inside legal launch space for the active turn."
	},
	"launch_input": {
		"key": "launch_input",
		"title": "Press, Drag, Release",
		"category": CATEGORY_GENERAL,
		"order": 30,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Input is press-and-drag launch control:\n- Press/tap sets launch origin.\n- Drag vector sets launch direction.\n- Drag magnitude sets initial launch speed.\n- Release starts simulation.\n\nAfter release, shot behavior is no longer direct input-driven; physics and rulesystems determine outcome.",
		"short_body": "Input is press-and-drag launch control:"
	},
	"success_thresholds": {
		"key": "success_thresholds",
		"title": "Engagement Pass Condition",
		"category": CATEGORY_GENERAL,
		"order": 40,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Player-side engagements evaluate a downed-troop threshold at shot end.\nThe baseline win threshold is 50% of defender troops, implemented as `ceil(total_defenders * 0.50)`.\n\nThis threshold is evaluated in engagement context; then resolver logic applies persistent updates.\nResult persistence can include troop deltas, building deltas, ownership/faction changes, and context-specific follow-up data.",
		"short_body": "Player-side engagements evaluate a downed-troop threshold at shot end."
	},
	"hud_reference": {
		"key": "hud_reference",
		"title": "Reading Status UI",
		"category": CATEGORY_GENERAL,
		"order": 50,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "The HUD exposes live and post-shot state needed to interpret outcomes:\n- engagement context label,\n- live encounter counters,\n- resources and upgrade levels,\n- and final summary text rows.\n\nDuring defensive contexts, summaries can show both \"player hit count\" and \"full result\" counts because additional post-shot troop-vs-troop processing may occur.",
		"short_body": "The HUD exposes live and post-shot state needed to interpret outcomes:"
	},
	"help_field_guide": {
		"key": "help_field_guide",
		"title": "How Help Content Is Used",
		"category": CATEGORY_GENERAL,
		"order": 60,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "The Field Guide is persistent reference content accessible from Help/Pause.\nIt is intended to describe currently implemented mechanics, including engagement routing, resolver behavior, upgrades, hazard systems, boss flow, and progression state.\n\nGuide notes support unlock/read tracking and unread badges, so newly introduced systems can be surfaced in UI as they appear.",
		"short_body": "The Field Guide is persistent reference content accessible from Help/Pause."
	},
	"engagement_framework": {
		"key": "engagement_framework",
		"title": "How Engagement Context Works",
		"category": CATEGORY_ENGAGEMENTS,
		"order": 70,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Engagements are one-shot contexts whose rules depend on province type and turn routing.\nThe same physics shot can resolve differently depending on active context because post-shot logic differs.\n\nPrimary implemented contexts:\n- Offensive vs Enemy Province\n- Offensive vs Neutral Province\n- Defensive Engagement\n- Enemy Boss Home Assault\n- Friendly Boss Assist context\n\nResolver outputs include summary text plus normalized persistent values written back to campaign state.",
		"short_body": "Engagements are one-shot contexts whose rules depend on province type and turn routing."
	},
	"offensive_vs_enemy_province": {
		"key": "offensive_vs_enemy_province",
		"title": "Enemy Offensive Engagement Rules",
		"category": CATEGORY_ENGAGEMENTS,
		"order": 80,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Enemy offensive engagements use enemy-side persistent troop/building/map metadata for resolution inputs.\nPhysical building actors are not spawned on the offensive engagement board; building loss is computed logically.\n\nLogical offensive building destruction uses pin-down percentage:\n- below 50% downed: 0 buildings destroyed,\n- at 50%: 1 building destroyed,\n- +1 building for each additional 10% downed,\n- capped by available buildings and a max logical damage cap (5).\n\nThis is computed by `get_offensive_logical_destroyed_buildings(total_pins, downed_pins, available_buildings)` and then applied in resolver persistence.",
		"short_body": "Enemy offensive engagements use enemy-side persistent troop/building/map metadata for resolution inputs."
	},
	"offensive_vs_neutral_province": {
		"key": "offensive_vs_neutral_province",
		"title": "Neutral Offensive Engagement Rules",
		"category": CATEGORY_ENGAGEMENTS,
		"order": 90,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Neutral offensive engagements use the same one-shot framework with neutral province state.\nThe resolver applies player-downed troop results and building deltas, then evaluates whether ownership transitions this turn.\n\nAs with other player engagements, threshold checks are evaluated at shot end and then converted into persistent state updates.",
		"short_body": "Neutral offensive engagements use the same one-shot framework with neutral province state."
	},
	"defensive_engagement": {
		"key": "defensive_engagement",
		"title": "Friendly Defense Context",
		"category": CATEGORY_ENGAGEMENTS,
		"order": 100,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Defensive engagements represent an invasion into a friendly province.\nIn defensive phase, physical building actors may spawn based on building count and phase rules.\n\nResolution sequence in this context:\n1) Player shot downs invading troops and may reduce buildings during shot resolution.\n2) Remaining invaders and friendly defenders then fight 1-for-1 (mutual losses = `min(remaining_invaders, defenders_before)`).\n3) If invaders still remain, they apply additional building damage using\n   `floor(surviving_invaders / INVASION_BUILDING_DAMAGE_TROOPS_PER_POINT)`.\n4) If buildings reach zero while invaders remain, the province flips to enemy ownership.\n\nThis is why defensive summaries can report both post-player invader count and full post-combat invader count.",
		"short_body": "Defensive engagements represent an invasion into a friendly province."
	},
	"enemy_boss_home_assault": {
		"key": "enemy_boss_home_assault",
		"title": "Boss Home Engagement Context",
		"category": CATEGORY_ENGAGEMENTS,
		"order": 110,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "If the active target province is flagged as an enemy boss home province, the turn routes through boss-home resolution handling.\nThe engagement still resolves shot outcomes first, then boss-system-specific post-processing runs.\n\nBoss-home post-processing can include troop-to-hitpoint conversion and boss force accounting, and the resulting status text is appended to engagement/campaign output.",
		"short_body": "If the active target province is flagged as an enemy boss home province, the turn routes through boss-home resolution handling."
	},
	"friendly_boss_assist": {
		"key": "friendly_boss_assist",
		"title": "Friendly Boss Contribution Context",
		"category": CATEGORY_ENGAGEMENTS,
		"order": 120,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "When friendly boss assist mode is active in the relevant boss-home context, resolver flow includes additional friendly-boss and enemy-boss force accounting.\n\nThe status/summaries can include:\n- troop knock-over contribution,\n- per-side troop losses from boss-force clashes,\n- and remaining boss-force counts persisted for future turns.\n\nAssist mode is context-gated; it is not a global modifier for all engagement types.",
		"short_body": "When friendly boss assist mode is active in the relevant boss-home context, resolver flow includes additional friendly-boss and enemy-boss force accounting."
	},
	"end_of_shot_resolution": {
		"key": "end_of_shot_resolution",
		"title": "What Is Persisted",
		"category": CATEGORY_ENGAGEMENTS,
		"order": 130,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "After a shot ends, resolver output can persist:\n- remaining troops,\n- remaining buildings,\n- final owner type and faction,\n- final resident troops vs invading troops,\n- annex/conquer flags,\n- and context-specific summary blocks.\n\nIn defensive outcomes, persistent state can keep a province friendly with pending invaders, or flip to enemy if structural collapse conditions are met.",
		"short_body": "After a shot ends, resolver output can persist:"
	},
	"gold": {
		"key": "gold",
		"title": "Upgrade Currency",
		"category": CATEGORY_UPGRADES_TOOLS,
		"order": 140,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Gold is persistent campaign currency used for purchasing upgrades.\nUpgrade purchases increase stored upgrade levels, and those levels are reapplied when configuring subsequent shots.\n\nUpgrade costs can be shown through standard/base costs or campaign-adjusted discounted cost maps, depending on active systems.",
		"short_body": "Gold is persistent campaign currency used for purchasing upgrades."
	},
	"bigger_ball": {
		"key": "bigger_ball",
		"title": "Radius Scaling Upgrade",
		"category": CATEGORY_UPGRADES_TOOLS,
		"order": 150,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Bigger Ball increases the ball’s effective radius scale.\nA larger radius changes collision/contact footprint and can alter interaction timing with pins, hazards, and other actors.\n\nThe effect is simulation-level (shape/contacts), not a separate post-shot resolver bonus.",
		"short_body": "Bigger Ball increases the ball’s effective radius scale."
	},
	"heavier_ball": {
		"key": "heavier_ball",
		"title": "Mass Scaling Upgrade",
		"category": CATEGORY_UPGRADES_TOOLS,
		"order": 160,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Heavier Ball increases effective mass scaling.\nMass scaling changes collision response and momentum exchange behavior during live simulation.\n\nLike Bigger Ball, this is applied during physics resolution, then downstream outcomes reflect those contacts.",
		"short_body": "Heavier Ball increases effective mass scaling."
	},
	"poison": {
		"key": "poison",
		"title": "Poison Processing Upgrade",
		"category": CATEGORY_UPGRADES_TOOLS,
		"order": 170,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Poison enables poison-related damage handling in engagement processing before final outcome determination.\nThis means some damage accounting can occur in resolver flow even if not represented as direct immediate knock-over events alone.\n\nPoison state is stored as an upgrade level and applied in encounter processing when active.",
		"short_body": "Poison enables poison-related damage handling in engagement processing before final outcome determination."
	},
	"wind_resistance": {
		"key": "wind_resistance",
		"title": "Temporary Wind Immunity",
		"category": CATEGORY_UPGRADES_TOOLS,
		"order": 180,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Wind Resistance provides a temporary immunity window to wind immediately after launch.\nThe duration is level-scaled; after the window expires, normal wind effects resume for the remainder of the shot.\n\nThis is a time-window modifier applied during flight simulation rather than a post-shot result modifier.",
		"short_body": "Wind Resistance provides a temporary immunity window to wind immediately after launch."
	},
	"forcefield": {
		"key": "forcefield",
		"title": "Auxiliary Ring Contacts",
		"category": CATEGORY_UPGRADES_TOOLS,
		"order": 190,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Forcefield enables a ring around the ball that can register additional contacts.\nRing contacts are processed separately from core-body impacts and use dedicated interaction tuning.\n\nThis creates auxiliary hit processing while the main ball still resolves normal collision flow.",
		"short_body": "Forcefield enables a ring around the ball that can register additional contacts."
	},
	"magnet": {
		"key": "magnet",
		"title": "Magnet Placement and Pull",
		"category": CATEGORY_UPGRADES_TOOLS,
		"order": 200,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Magnet unlocks pre-shot placement of magnets on engagement maps.\nPlaced magnets persist for that engagement and apply in-flight pull forces that curve trajectory.\n\nPlacement legality is checked before spawn, including map bounds and overlap/spacing constraints.\nIf placement is invalid, magnet spawn is rejected for that location.",
		"short_body": "Magnet unlocks pre-shot placement of magnets on engagement maps."
	},
	"magnet_placement": {
		"key": "magnet_placement",
		"title": "Placement Lifecycle",
		"category": CATEGORY_UPGRADES_TOOLS,
		"order": 210,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Magnet lifecycle:\n1) Magnet upgrade level enables placement capacity.\n2) Player enters placement mode.\n3) Magnet nodes are placed in legal positions on the active engagement board.\n4) Shot begins; magnets influence flight until shot termination.\n5) Engagement resolves; magnet effects do not persist beyond that engagement instance.",
		"short_body": "Magnet lifecycle:"
	},
	"terrain_system": {
		"key": "terrain_system",
		"title": "Simulation-Relevant Map Features",
		"category": CATEGORY_TERRAIN,
		"order": 220,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Terrain is simulation-active, not visual-only.\nZone/templates generate hazard and surface components that can change movement, collision flow, and shot termination behavior.\n\nEngagement map generation assembles these components according to phase and map-type configuration.",
		"short_body": "Terrain is simulation-active, not visual-only."
	},
	"water": {
		"key": "water",
		"title": "Water Hazard Behavior",
		"category": CATEGORY_TERRAIN,
		"order": 230,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Water is represented as hazard-zone content in board generation.\nContact with water can terminate the active shot early, ending further collision opportunities for that launch.\n\nWater quantity/distribution can vary by engagement map type via configured multipliers.",
		"short_body": "Water is represented as hazard-zone content in board generation."
	},
	"obstacles": {
		"key": "obstacles",
		"title": "Solid Blocking Geometry",
		"category": CATEGORY_TERRAIN,
		"order": 240,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Obstacle geometry is generated as blocking/static collision structures.\nThese structures constrain valid movement paths and can cause deflections or dead stops depending on collision angle and speed.\n\nObstacle count and layout style are generation outputs influenced by phase/map-type parameters.",
		"short_body": "Obstacle geometry is generated as blocking/static collision structures."
	},
	"friction": {
		"key": "friction",
		"title": "Surface Friction Components",
		"category": CATEGORY_TERRAIN,
		"order": 250,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Friction zones/components alter velocity decay during movement.\nHigher friction density or stronger friction placement can reduce carry distance before the shot terminates.\n\nFriction distribution is not fixed globally; generation can scale it by engagement map type.",
		"short_body": "Friction zones/components alter velocity decay during movement."
	},
	"grade": {
		"key": "grade",
		"title": "Directional Grade Components",
		"category": CATEGORY_TERRAIN,
		"order": 260,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Grade components add directional movement influence in generated map surfaces.\nThis can affect effective travel behavior depending on movement direction through the zone.\n\nGrade presence and coverage are generation outputs, not player toggles.",
		"short_body": "Grade components add directional movement influence in generated map surfaces."
	},
	"oil_surface_variants": {
		"key": "oil_surface_variants",
		"title": "Additional Surface Modifiers",
		"category": CATEGORY_TERRAIN,
		"order": 270,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Oil/surface modifier probability can be adjusted through engagement map type biases.\nThese modifiers are introduced during template generation and then resolved during live simulation.\n\nBecause they are generation-driven, presence and placement can vary per engagement.",
		"short_body": "Oil/surface modifier probability can be adjusted through engagement map type biases."
	},
	"hazard_actors": {
		"key": "hazard_actors",
		"title": "Caltrops and Related Hazards",
		"category": CATEGORY_TERRAIN,
		"order": 280,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Caltrop and related hazard actors participate in live collision/hit processing.\nTheir state can be tracked in province/campaign data (including destroyed flags where relevant systems use them).\n\nHazard interactions can change contact chains, movement continuity, and shot end-state conditions.",
		"short_body": "Caltrop and related hazard actors participate in live collision/hit processing."
	},
	"map_type_variation": {
		"key": "map_type_variation",
		"title": "Engagement Map Type Multipliers",
		"category": CATEGORY_TERRAIN,
		"order": 290,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Each province carries engagement map type metadata.\nThat map type is normalized and fed into generation multipliers/biases (obstacle, friction, water, oil, and related counts/chances).\n\nAs a result, two engagements with similar troop counts can still produce different traversal conditions.",
		"short_body": "Each province carries engagement map type metadata."
	},
	"boss_runtime_state": {
		"key": "boss_runtime_state",
		"title": "Boss State Tracking",
		"category": CATEGORY_BOSS_EVENTS,
		"order": 300,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Boss systems persist structured runtime state that includes:\n- active/dead flags,\n- boss/home/faction identifiers,\n- energy generated/drained/available fields,\n- and current/home province references.\n\nRuntime state can support multiple bosses with primary-boss selection and synchronized legacy fields.",
		"short_body": "Boss systems persist structured runtime state that includes:"
	},
	"boss_parts": {
		"key": "boss_parts",
		"title": "Per-Part Boss Data",
		"category": CATEGORY_BOSS_EVENTS,
		"order": 310,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Boss state contains per-part data records (for example head/arms/legs in configured part sets).\nHit processing can update part-specific state and produce part-aware summary output.\n\nPart data is persisted in boss runtime state, so effects can carry across turns as designed by boss systems.",
		"short_body": "Boss state contains per-part data records (for example head/arms/legs in configured part sets)."
	},
	"boss_home_province": {
		"key": "boss_home_province",
		"title": "Home Province Flags and Routing",
		"category": CATEGORY_BOSS_EVENTS,
		"order": 320,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Province metadata includes boss-home and boss-faction flags.\nThese flags are used by routing logic to decide whether a province engagement should enter boss-home-specific handling.\n\nBoss-home routing changes downstream resolution and summary behavior compared with non-boss provinces.",
		"short_body": "Province metadata includes boss-home and boss-faction flags."
	},
	"friendly_boss": {
		"key": "friendly_boss",
		"title": "Friendly Boss State Model",
		"category": CATEGORY_BOSS_EVENTS,
		"order": 330,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Boss runtime supports friendly-boss entities with dedicated identifiers and `is_friendly_boss` state.\nFriendly boss state includes home/current province references and participates in context-specific combat accounting.\n\nFriendly boss participation appears only when the active encounter context enables it.",
		"short_body": "Boss runtime supports friendly-boss entities with dedicated identifiers and `is_friendly_boss` state."
	},
	"spawn_and_lifecycle": {
		"key": "spawn_and_lifecycle",
		"title": "Activation, Primary Boss, Death",
		"category": CATEGORY_BOSS_EVENTS,
		"order": 340,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Boss lifecycle supports activation, append/spawn of multiple bosses, primary boss selection, and death marking.\nLifecycle transitions update runtime arrays, active boss lists/counts, and campaign-facing summaries/events.\n\nKilled/deactivated bosses are persisted as state transitions rather than temporary runtime-only effects.",
		"short_body": "Boss lifecycle supports activation, append/spawn of multiple bosses, primary boss selection, and death marking."
	},
	"persistent_campaign_state": {
		"key": "persistent_campaign_state",
		"title": "What Persists Across Turns",
		"category": CATEGORY_CAMPAIGN,
		"order": 350,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Campaign state persists across turns and map flow.\nCommon persisted fields include owner type, faction, troops, buildings, invading troop overlays, map type, and boss-linked metadata.\n\nResolver output writes normalized persistent values after each engagement or automated resolution step.",
		"short_body": "Campaign state persists across turns and map flow."
	},
	"province_ownership": {
		"key": "province_ownership",
		"title": "Ownership and Capture Source",
		"category": CATEGORY_CAMPAIGN,
		"order": 360,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Province ownership uses type/faction fields and can include capture-source metadata.\nOwnership transitions occur through engagement resolution and automated campaign systems.\n\nOn owner change, related normalization can reset or remap additional fields such as construction progress or baseline troops/buildings.",
		"short_body": "Province ownership uses type/faction fields and can include capture-source metadata."
	},
	"troops": {
		"key": "troops",
		"title": "Troop Persistence",
		"category": CATEGORY_CAMPAIGN,
		"order": 370,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Troop counts are persistent campaign values and may be split by context into resident vs invading representations.\nDuring defensive contexts, both defending friendly troops and invading troops can be tracked after resolution.\n\nThis is why some province states can remain friendly while still storing nonzero invading troop values.",
		"short_body": "Troop counts are persistent campaign values and may be split by context into resident vs invading representations."
	},
	"buildings": {
		"key": "buildings",
		"title": "Building Persistence Model",
		"category": CATEGORY_CAMPAIGN,
		"order": 380,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Building count is persistent province state with capacity/free-building metadata.\nEngagement behavior is phase-dependent:\n- offensive engagements use logical building damage computation,\n- defensive engagements may spawn physical building actors and can take both shot and invasion follow-up damage.\n\nFinal building count can directly determine whether a defended province is lost when invaders remain.",
		"short_body": "Building count is persistent province state with capacity/free-building metadata."
	},
	"province_map_type": {
		"key": "province_map_type",
		"title": "Engagement Map Type Metadata",
		"category": CATEGORY_CAMPAIGN,
		"order": 390,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Province map-type metadata is persisted and normalized.\nWhen that province is used for engagement generation, map type feeds configuration multipliers and biases used by layout/template generation.\n\nThis ties campaign province identity to future encounter geometry.",
		"short_body": "Province map-type metadata is persisted and normalized."
	},
	"campaign_upgrade_rewards": {
		"key": "campaign_upgrade_rewards",
		"title": "Permanent Upgrade Choice Flow",
		"category": CATEGORY_CAMPAIGN,
		"order": 400,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Campaign flow can present reward-choice panels that grant permanent upgrade progression.\nChosen values are stored as baseline progression and reapplied for later campaign cycles/maps.\n\nThese permanent values are separate from one-map transient shot state.",
		"short_body": "Campaign flow can present reward-choice panels that grant permanent upgrade progression."
	},
	"tutorial_and_unlock_notes": {
		"key": "tutorial_and_unlock_notes",
		"title": "Guide Unlock/Read State",
		"category": CATEGORY_CAMPAIGN,
		"order": 410,
		"presentation": PRESENTATION_NOTE,
		"target_id": "field_guide",
		"starts_unlocked": true,
		"auto_popup_on_unlock": false,
		"body": "Field Guide notes support:\n- unlock-by-event mapping,\n- read/unread tracking,\n- first-run/tutorial completion markers,\n- and unread count badge display.\n\nThis allows the game to surface mechanics documentation progressively while keeping all unlocked notes re-readable from Help.",
		"short_body": "Field Guide notes support:"
	}
}

const CATEGORY_ORDER: Array[String] = [
	CATEGORY_GENERAL,
	CATEGORY_ENGAGEMENTS,
	CATEGORY_UPGRADES_TOOLS,
	CATEGORY_TERRAIN,
	CATEGORY_BOSS_EVENTS,
	CATEGORY_CAMPAIGN,
]

const EVENT_UNLOCKS := {}

var _first_run_completed: bool = false
var _gameplay_tutorial_completed: bool = false
var _gameplay_tutorial_skipped: bool = false
var _gameplay_tutorial_in_progress: bool = false
var _unlocked_notes: Dictionary = {}
var _read_notes: Dictionary = {}
var _seen_auto_popups: Dictionary = {}


func setup() -> void:
	_load_state()
	_ensure_default_unlocks()


func should_auto_start_first_run() -> bool:
	if should_auto_start_gameplay_tutorial():
		return false
	return not _first_run_completed


func should_auto_start_gameplay_tutorial() -> bool:
	return not _gameplay_tutorial_completed and not _gameplay_tutorial_skipped


func get_gameplay_tutorial_definition() -> Dictionary:
	var definition: Dictionary = GAMEPLAY_TUTORIAL_SCENARIO.duplicate(true)
	definition["is_completed"] = _gameplay_tutorial_completed
	definition["is_skipped"] = _gameplay_tutorial_skipped
	definition["is_in_progress"] = _gameplay_tutorial_in_progress
	definition["should_auto_start"] = should_auto_start_gameplay_tutorial()
	return definition


func get_gameplay_tutorial_skip_button_text() -> String:
	return GAMEPLAY_TUTORIAL_SKIP_LABEL


func mark_gameplay_tutorial_started() -> void:
	_gameplay_tutorial_in_progress = true


func clear_gameplay_tutorial_runtime_state() -> void:
	_gameplay_tutorial_in_progress = false


func is_gameplay_tutorial_in_progress() -> bool:
	return _gameplay_tutorial_in_progress


func is_gameplay_tutorial_completed() -> bool:
	return _gameplay_tutorial_completed


func was_gameplay_tutorial_skipped() -> bool:
	return _gameplay_tutorial_skipped


func should_show_gameplay_tutorial_skip_button() -> bool:
	return _gameplay_tutorial_in_progress and should_auto_start_gameplay_tutorial()


func is_gameplay_tutorial_clear_condition_met(neutral_troops_remaining: int) -> bool:
	if not _gameplay_tutorial_in_progress:
		return false
	return neutral_troops_remaining <= 0


func mark_gameplay_tutorial_completed() -> void:
	_gameplay_tutorial_completed = true
	_gameplay_tutorial_skipped = false
	_gameplay_tutorial_in_progress = false
	mark_first_run_complete()


func mark_gameplay_tutorial_skipped() -> void:
	_gameplay_tutorial_completed = false
	_gameplay_tutorial_skipped = true
	_gameplay_tutorial_in_progress = false
	mark_first_run_complete()


func reset_gameplay_tutorial_progress_for_testing() -> void:
	_gameplay_tutorial_completed = false
	_gameplay_tutorial_skipped = false
	_gameplay_tutorial_in_progress = false
	_first_run_completed = false
	_save_state()


func get_first_run_sequence() -> Array[Dictionary]:
	var sequence: Array[Dictionary] = []
	for i in range(FIRST_RUN_SEQUENCE.size()):
		var note_key: String = String(FIRST_RUN_SEQUENCE[i])
		var entry: Dictionary = get_note(note_key)
		if entry.is_empty():
			continue
		entry["step_index"] = i + 1
		entry["step_count"] = FIRST_RUN_SEQUENCE.size()
		sequence.append(entry)
	return sequence


func mark_first_run_complete() -> void:
	_first_run_completed = true
	for note_key in FIRST_RUN_SEQUENCE:
		_unlock_note(String(note_key))
		mark_note_read(String(note_key))
	_save_state()


func clear_first_run_complete_for_testing() -> void:
	_first_run_completed = false
	_save_state()


func get_note(note_key: String) -> Dictionary:
	if not NOTE_DEFINITIONS.has(note_key):
		return {}
	return (NOTE_DEFINITIONS[note_key] as Dictionary).duplicate(true)


func has_note(note_key: String) -> bool:
	return NOTE_DEFINITIONS.has(note_key)


func is_note_unlocked(note_key: String) -> bool:
	return _unlocked_notes.has(note_key)


func is_note_read(note_key: String) -> bool:
	return _read_notes.has(note_key)


func unlock_notes_for_event(event_key: String) -> Array[Dictionary]:
	var auto_popup_entries: Array[Dictionary] = []
	if not EVENT_UNLOCKS.has(event_key):
		return auto_popup_entries

	var unlock_keys: Array = EVENT_UNLOCKS[event_key]
	for raw_key in unlock_keys:
		var note_key: String = String(raw_key)
		if not NOTE_DEFINITIONS.has(note_key):
			continue
		var was_newly_unlocked: bool = not _unlocked_notes.has(note_key)
		_unlock_note(note_key)
		if not was_newly_unlocked:
			continue
		var entry: Dictionary = get_note(note_key)
		if bool(entry.get("auto_popup_on_unlock", false)) and not _seen_auto_popups.has(note_key):
			_seen_auto_popups[note_key] = true
			auto_popup_entries.append(entry)
	_save_state()
	return auto_popup_entries


func mark_note_read(note_key: String) -> void:
	if note_key.strip_edges() == "":
		return
	if not NOTE_DEFINITIONS.has(note_key):
		return
	_unlock_note(note_key)
	_read_notes[note_key] = true
	_save_state()


func mark_auto_popup_seen(note_key: String) -> void:
	if note_key.strip_edges() == "":
		return
	if not NOTE_DEFINITIONS.has(note_key):
		return
	_seen_auto_popups[note_key] = true
	_save_state()


func get_unread_unlocked_note_count() -> int:
	var count: int = 0
	for note_key in _unlocked_notes.keys():
		if not _read_notes.has(note_key):
			count += 1
	return count


func get_unlocked_note_count() -> int:
	return _unlocked_notes.size()


func get_field_guide_sections() -> Array[Dictionary]:
	var sections: Array[Dictionary] = []
	for category_name in CATEGORY_ORDER:
		var category_entries: Array[Dictionary] = []
		for note_key in NOTE_DEFINITIONS.keys():
			var entry: Dictionary = NOTE_DEFINITIONS[note_key]
			if String(entry.get("category", "")) != category_name:
				continue
			if not _unlocked_notes.has(note_key):
				continue
			var ui_entry: Dictionary = entry.duplicate(true)
			ui_entry["is_unlocked"] = true
			ui_entry["is_read"] = _read_notes.has(note_key)
			ui_entry["is_first_run_step"] = FIRST_RUN_SEQUENCE.has(note_key)
			category_entries.append(ui_entry)
		if category_entries.is_empty():
			continue
		category_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("order", 0)) < int(b.get("order", 0))
		)
		sections.append({
			"category": category_name,
			"entries": category_entries
		})
	return sections


func get_all_known_note_keys() -> Array[String]:
	var keys: Array[String] = []
	for note_key in NOTE_DEFINITIONS.keys():
		keys.append(String(note_key))
	keys.sort()
	return keys


func reset_all_progress_for_testing() -> void:
	_first_run_completed = false
	_gameplay_tutorial_completed = false
	_gameplay_tutorial_skipped = false
	_gameplay_tutorial_in_progress = false
	_unlocked_notes.clear()
	_read_notes.clear()
	_seen_auto_popups.clear()
	_ensure_default_unlocks()
	_save_state()


func _ensure_default_unlocks() -> void:
	for note_key in NOTE_DEFINITIONS.keys():
		_unlock_note(String(note_key), false)


func _unlock_note(note_key: String, save_after: bool = true) -> void:
	if note_key.strip_edges() == "":
		return
	if not NOTE_DEFINITIONS.has(note_key):
		return
	_unlocked_notes[note_key] = true
	if save_after:
		_save_state()


func _load_state() -> void:
	_first_run_completed = false
	_gameplay_tutorial_completed = false
	_gameplay_tutorial_skipped = false
	_gameplay_tutorial_in_progress = false
	_unlocked_notes.clear()
	_read_notes.clear()
	_seen_auto_popups.clear()

	var cfg := ConfigFile.new()
	var err: int = cfg.load(SAVE_PATH)
	if err != OK:
		return

	var stored_version: int = int(cfg.get_value(SAVE_SECTION, "content_version", 0))
	if stored_version != CONTENT_VERSION:
		return

	_first_run_completed = bool(cfg.get_value(SAVE_SECTION, "first_run_completed", false))
	_gameplay_tutorial_completed = bool(cfg.get_value(SAVE_SECTION, "gameplay_tutorial_completed", false))
	_gameplay_tutorial_skipped = bool(cfg.get_value(SAVE_SECTION, "gameplay_tutorial_skipped", false))
	_unlocked_notes = _array_to_set(cfg.get_value(SAVE_SECTION, "unlocked_notes", []))
	_read_notes = _array_to_set(cfg.get_value(SAVE_SECTION, "read_notes", []))
	_seen_auto_popups = _array_to_set(cfg.get_value(SAVE_SECTION, "seen_auto_popups", []))


func _save_state() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_SECTION, "content_version", CONTENT_VERSION)
	cfg.set_value(SAVE_SECTION, "first_run_completed", _first_run_completed)
	cfg.set_value(SAVE_SECTION, "gameplay_tutorial_completed", _gameplay_tutorial_completed)
	cfg.set_value(SAVE_SECTION, "gameplay_tutorial_skipped", _gameplay_tutorial_skipped)
	cfg.set_value(SAVE_SECTION, "unlocked_notes", _set_to_sorted_array(_unlocked_notes))
	cfg.set_value(SAVE_SECTION, "read_notes", _set_to_sorted_array(_read_notes))
	cfg.set_value(SAVE_SECTION, "seen_auto_popups", _set_to_sorted_array(_seen_auto_popups))
	cfg.save(SAVE_PATH)


func _array_to_set(values: Variant) -> Dictionary:
	var result: Dictionary = {}
	if values is Array:
		for value in values:
			var key: String = String(value)
			if key.strip_edges() == "":
				continue
			result[key] = true
	return result


func _set_to_sorted_array(set_dict: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key in set_dict.keys():
		keys.append(String(key))
	keys.sort()
	return keys
