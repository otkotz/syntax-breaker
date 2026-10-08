# Stage Finale, Complete Art, and Mobile Shop Design

Date: 2026-10-08
Status: Approved design

## Objective

Improve the phone build in four connected areas:

1. Remove the visible hitch when a stage ends.
2. Guarantee visible artwork for every enemy role, every passive, and every shop upgrade.
3. Make the entire shop offer card a safe touch target.
4. Turn the final regional encounter into a distinct boss fight that ends immediately when the boss dies.

The work must preserve existing player saves and the current regional identities.

## Stage Completion and Performance

Stage completion becomes an explicit, idempotent transition rather than an incidental result of the timer and enemy counter reaching zero.

Normal stages retain their current timed spawning rules. When their completion condition is met, the spawner first enters a completed state and stops all new or deferred spawning. Arena cleanup then releases pooled enemies and projectiles, clears transient effects, hazards, pending split/add requests, and stale callbacks through bounded collection-level operations. Cleanup must not simulate a normal death for every remaining transient object and must not award combat rewards twice.

The transition emits `all_waves_cleared` and `stage_completed` at most once. Deferred split fragments or boss-add callbacks from an older spawn generation cannot revive the encounter after completion.

Tests will exercise a high-object-count cleanup, assert bounded collections and a single completion signal, and verify that no enemy, projectile, hazard, or effect remains active after the transition. Real-device profiling remains the authority for the perceived hitch; native tests prove lifecycle and work bounds.

## Final Boss Encounter

Final regional stages use a dedicated boss-only encounter mode:

- No ordinary wave budget or periodic formations are spawned.
- The regional boss is present from the beginning.
- Only mechanic-specific adds may appear, with a hard cap of four and a preferred active count of two.
- Adds do not gate victory.
- Boss death immediately stops the encounter, cancels deferred spawns, clears adds, hostile projectiles and hazards, and emits stage completion once.
- The stage timer may remain visible as encounter duration telemetry, but it cannot gate victory or spawn normal enemies.

The final boss is visually and mechanically distinct from a miniboss:

- visual footprint approximately 35–45% larger;
- physical hitbox enlarged conservatively, not in direct proportion to the art;
- final-boss HP scaling increases from 3x to approximately 5x the stage-scaled base;
- movement is approximately 25% faster than the current final-boss configuration;
- three phases begin at 100%, 65%, and 30% HP;
- attack recovery shortens by phase while every dangerous attack retains a harmless telegraph;
- active hazards remain capped to prevent visual overload and frame-time spikes.

All regions gain a shared avoidable projectile pattern using bright, opaque hostile projectiles drawn above floor effects. Regional behavior remains distinct:

- Burning Grounds alternates fire walls, safe sectors, and aimed/fan projectile volleys.
- Storm Spire combines rotating beams, a rotating safe wedge, and spiral projectile volleys.
- Toxic Depths combines lower-opacity pools, moving safe islands, projectile volleys, and two to four cleansing adds.

Ground hazards use lower fill alpha in their active state, while borders, telegraphs, and activation flashes stay readable. Damage geometry and timing do not become less explicit merely because the fill is lighter.

## Complete Enemy Artwork

Every spawnable enemy role must present a non-null, readable production texture:

- melee;
- ranged;
- tank;
- swarm;
- charger;
- denial caster;
- shield support;
- splitter;
- split fragment;
- miniboss/elite;
- Burning Grounds boss;
- Storm Spire boss;
- Toxic Depths boss.

Artwork follows the established pixel-art language and uses distinct silhouettes that remain legible on a phone. Regional bosses receive distinct palettes and silhouettes rather than relying only on tint. Visual scaling must not silently scale collision shapes or break pool reuse.

An exhaustive native test instantiates every production enemy scene, confirms a usable texture and minimum visible dimensions, and verifies the texture survives reset/reinitialization. The Android export is also checked so referenced assets cannot disappear only in the APK.

## Complete Passive and Upgrade Artwork

Every non-mastery passive resource, including legendary passives, must have a non-null icon. A mastery passive may intentionally reuse the matching support icon, but every renderer must overlay a readable `MASTERY` badge so the shared art is not ambiguous.

Artwork must be visible consistently in:

- stage rewards;
- shop offers;
- skill/build management;
- owned passive lists;
- Codex entries after discovery;
- unlock collection cards;
- legendary selection.

Shop stat upgrades receive three dedicated icons: flat damage, haste/cooldown, and critical chance. These are explicit resources or a stable icon registry, not ad-hoc text glyphs.

The art regression test iterates the full resource catalog rather than a hand-selected sample. It fails for every missing passive/support/skill icon, verifies mastery mapping, verifies all three upgrade icons, and checks the principal renderers. Existing uncommitted artwork in the main checkout is preserved, audited, and completed rather than overwritten wholesale.

## Mobile Shop Interaction

Each shop offer becomes one full-card `Button` or equivalent single semantic action target. Touching the icon, title, description, price region, or empty card padding purchases the offer. Child visual controls ignore mouse/touch input so they cannot block the parent action.

The separate narrow buy button is removed to avoid two competing purchase targets. The card displays its price and disabled/insufficient-gold state directly, retains pressed feedback, and keeps a minimum height of 130 pixels.

The shop remains inside a scroll container. A drag beyond the platform touch threshold scrolls without purchasing; a completed tap purchases exactly once. Refreshing the offer list cannot leave a stale card able to purchase an offer that is no longer present.

Native touch tests tap the icon, text, price, and padding for skill, support, passive, and stat-upgrade cards. They also perform a drag gesture and assert that gold and offerings remain unchanged.

## Cleanup and Error Handling

Completion methods are safe to call repeatedly. They reject work from stale spawn generations and disconnect or invalidate deferred boss/add callbacks. Boss death cleanup removes combat objects without issuing extra kill credit, gold, cosmetic points, or telemetry events.

Missing optional artwork is not replaced silently in production. Catalog validation fails during tests and development builds. Runtime rendering may retain a neutral fallback only to avoid a crash from damaged or old user content.

## Verification

Implementation follows test-driven development. Required evidence includes:

- focused RED-to-GREEN tests for stage cleanup, boss victory flow, boss phases/projectiles, shop touch behavior, and exhaustive art coverage;
- the complete native regression suite with log scanning for script/runtime errors;
- catalog and balance validation;
- a debug Android export with asset references verified;
- installation on the connected phone without clearing application data;
- a device smoke test covering a shop purchase and final-boss start/death transition;
- a short real-device observation of end-of-stage responsiveness.

## Out of Scope

- Replacing the regional map structure.
- Redesigning the overall economy or shop prices.
- Adding more than three final-boss phases.
- Allowing ordinary waves during the final regional boss encounter.
- Treating mechanic adds as mandatory kill targets after the boss dies.
