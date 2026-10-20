# Expedition Loot Hunt Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn Expedition loot from a post-run collection checklist into a mobile-first loot hunt where room rewards change the current build, duplicates create decisions, and permanent progression points toward another run without buying raw power.

**Architecture:** Keep deterministic rolling, pending rewards, pity, and copy-on-write settlement as the trusted persistence boundary. Add run-only Echo/Temper state to `ExpeditionSession`, keep permanent Forge commitments in `ExpeditionProfile`, and make UI submit explicit decisions without owning reward logic. Ship five independently testable milestones: finish the current slice, make loot affect the run, add target farming, add curated synergies/longer chase goals, then apply and verify the approved visual direction.

**Tech Stack:** Godot 4.7.2, typed GDScript, `.tres` resources, portrait Control UI, scene-based headless native tests, atomic JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-17-expedition-loot-codex-design.md`, extended by the approved 2026-10-17 five-perspective loot-hunt review and `docs/progress-2026-10-17.md`.

## Global Constraints

- Preserve deterministic outcomes from expedition seed plus stable reward ID; UI choices must never reroll a stored reward.
- Keep profile settlement copy-on-write and idempotent; failed saves leave live profile and session unchanged.
- Death or abandonment discards pending artifacts and every run-only Echo/Temper effect without advancing pity.
- Expedition systems must not mutate `RunManager`, roguelite saves, or normal-mode balance.
- Permanent progression unlocks options and targeting, never flat damage, health, cooldown, or enemy-stat reductions.
- Each post-room overlay presents at most one decision with two primary actions and touch targets at least 88 px high.
- Unknown future artifact IDs remain round-trippable and are skipped safely by runtime and UI.
- Do not add random numeric rolls, multiple affixes, a second currency, or another region in Milestones 1–3.

## Review Focus

- Resume while an unresolved reward decision is open must restore the same reward and available actions, not silently choose or reroll it (Task 3).
- A failed session checkpoint after choosing Echo/Temper must leave the prior session and combat loadout unchanged (Tasks 2–3).
- Duplicate protection and Forge commitments must not convert a deterministic result into repeated free rerolls (Tasks 5–6).
- A temporary artifact replacing a set piece must recompute set tiers exactly once and restore the frozen pre-run loadout after the expedition (Task 2).
- Curated artifact interactions must respect generation caps and never recursively trigger themselves or another secondary artifact projectile without an explicit rule (Task 7).

---

## Milestone 1 — Finish and validate the current loot slice

### Task 1: Goal-oriented mobile Codex and branch integration

**Files:**
- Create: `scripts/ui/expedition_codex.gd`
- Create: `scenes/ui/expedition_codex.tscn`
- Modify: `scripts/ui/expedition_hub.gd`
- Modify: `scenes/ui/expedition_hub.tscn`
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Create: `tests/expedition_codex_native.gd`
- Create: `tests/expedition_codex_native.tscn`
- Modify: `tests/expedition_flow_native.gd`
- Modify: `tests/run_integrity.gd`
- Modify: `docs/progress-2026-10-17.md`

**Interfaces:**
- Consumes: `ArtifactCatalog`, `ExpeditionProfile.discovered_artifact_ids`, `owned_artifact_ids`, `pity_counters`, and artifact loot metadata.
- Produces: `ExpeditionCodexUI.setup(profile: ExpeditionProfile) -> void`, filters `All/Owned/Missing/Burning Grounds`, and a read-only next-goal summary.

- [ ] **Step 1: Write the failing Codex test** asserting six stable cards, the four filters, unknown/discovered/owned visibility states, source labels, set progress, `Bloodwritten Sigil` pity, back navigation, and 88 px primary touch targets.
- [ ] **Step 2: Add failing goal-summary assertions** for nearest incomplete set, one trackable missing artifact, and no recommendation when the catalog is complete.
- [ ] **Step 3: Run `expedition_codex_native.tscn`** and verify RED because the screen/controller do not exist.
- [ ] **Step 4: Implement the portrait Codex and hub route**; show compact cards first and full details only after tap, while missing resources are skipped safely.
- [ ] **Step 5: Extend real-flow and isolation tests** through elite, treasure, boss settlement, Codex discovery, return to hub, and unchanged roguelite state.
- [ ] **Step 6: Run every Expedition test plus `run_integrity.tscn`, `node_routes_native.tscn`, and `test_controls_native.tscn`**; require exit 0 and no parse/resource/leak failures.
- [ ] **Step 7: Commit** with `feat: complete expedition loot codex`.

---

## Milestone 2 — Make every meaningful drop affect the run

### Task 2: Session-owned Echo loadout

**Files:**
- Modify: `scripts/expedition/expedition_session.gd`
- Modify: `scripts/expedition/artifact_loadout.gd`
- Modify: `scripts/expedition/artifacts/artifact_runtime.gd`
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Create: `tests/expedition_echo_native.gd`
- Create: `tests/expedition_echo_native.tscn`
- Modify: `tests/expedition_session_native.gd`
- Modify: `tests/expedition_artifact_runtime_native.gd`

**Interfaces:**
- Produces: session schema 4 field `echo_artifact_ids: Array[String]`; `ExpeditionSession.effective_artifact_ids() -> Array[String]`; `preview_echo(artifact_id: String, slot: int) -> Dictionary`; `apply_echo(artifact_id: String, slot: int) -> bool`.
- Rule: Echo replaces one of four frozen session slots from the next room onward, is never copied into permanent equipped IDs, and may use a newly found pending artifact before victory.

- [ ] **Step 1: Write failing session tests** for empty schema-3 migration, four-slot normalization, replace/clear behavior, save-resume identity, unknown-ID preservation, and no profile mutation.
- [ ] **Step 2: Write failing runtime tests** proving Echo changes active behaviors and set tiers for the next room, teardown clears it, and a new expedition restores the profile loadout.
- [ ] **Step 3: Run the Echo tests** and verify RED on missing schema/API.
- [ ] **Step 4: Implement schema 4 and effective-loadout calculation** without changing settlement or permanent ownership.
- [ ] **Step 5: Rebuild artifact runtime between rooms only when the effective loadout changed**; disconnect old hooks before installing new ones.
- [ ] **Step 6: Run Echo, session, artifact-runtime, artifact-loadout, and expedition-flow tests** and verify pass.
- [ ] **Step 7: Commit** with `feat: let expedition loot echo into the run`.

### Task 3: Reward decision overlay and atomic choice checkpoint

**Files:**
- Modify: `scripts/ui/expedition_reward_overlay.gd`
- Modify: `scenes/ui/expedition_reward_overlay.tscn`
- Modify: `scripts/expedition/expedition_session.gd`
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Modify: `tests/expedition_artifact_ui_native.gd`
- Modify: `tests/expedition_loot_flow_native.gd`
- Create: `tests/expedition_reward_decision_native.gd`
- Create: `tests/expedition_reward_decision_native.tscn`

**Interfaces:**
- Produces: session schema 5 field `unresolved_reward_id: String`; `resolve_reward(reward_id: String, action: String, slot: int = -1) -> bool`; overlay signal `decision_requested(reward_id: String, action: String, slot: int)`.
- Allowed new-artifact actions: `echo` or `keep_loadout`; duplicate actions are added in Task 4.

- [ ] **Step 1: Write failing UI tests** for `EQUIP ECHO`/`KEEP LOADOUT`, four replace previews, before/after set-tier summary, single-choice protection, portrait scrolling, Android back suppression, and 88 px buttons.
- [ ] **Step 2: Write failing flow tests** proving navigation stays locked until a choice checkpoint succeeds, resume restores the same unresolved decision, and failed save rolls back both session data and runtime loadout.
- [ ] **Step 3: Run reward-decision and loot-flow tests** and verify RED.
- [ ] **Step 4: Implement the serialized decision boundary** in the session; do not mutate runtime until the updated session save succeeds.
- [ ] **Step 5: Implement the overlay state machine** and rebuild runtime after a successful Echo decision.
- [ ] **Step 6: Run reward-decision, loot-flow, session, touch, and run-integrity tests** and verify pass.
- [ ] **Step 7: Commit** with `feat: add expedition loot decisions`.

### Task 4: Duplicate Temper or Shatter and guaranteed consolation

**Files:**
- Create: `scripts/expedition/artifact_temper_data.gd`
- Modify: `scripts/expedition/expedition_session.gd`
- Modify: `scripts/expedition/expedition_reward_settlement.gd`
- Modify: `scripts/expedition/artifacts/artifact_runtime.gd`
- Modify: `scripts/ui/expedition_reward_overlay.gd`
- Modify: `tests/expedition_reward_settlement_native.gd`
- Modify: `tests/expedition_reward_decision_native.gd`
- Create: `tests/expedition_temper_native.gd`
- Create: `tests/expedition_temper_native.tscn`

**Interfaces:**
- Produces: six named, data-only run modifiers via `ArtifactTemperData.get_for_artifact(id: String) -> Dictionary`; session schema 6 field `tempered_artifact_ids: Array[String]`; duplicate actions `temper` and `shatter`.
- Consolation values: elite no-drop `2` pending shards; treasure no-drop `4`; existing victory `10`, normal duplicate `5`, and chase duplicate `15` remain unchanged.

- [ ] **Step 1: Write failing data/runtime tests** asserting one bounded upside/downside Temper definition for each artifact, no recursive secondary triggers, save-resume persistence, and teardown on death/abandon.
- [ ] **Step 2: Write failing decision tests** for `TEMPER`/`SHATTER`, disabled Temper when the artifact is not in the effective loadout, and exactly one action per reward ID.
- [ ] **Step 3: Extend settlement tests** for 2/4 no-drop consolation shards, Shatter conversion, no immediate profile credit before victory, and idempotent retry.
- [ ] **Step 4: Run the three owning test scenes** and verify RED.
- [ ] **Step 5: Implement Temper data and runtime application**, then add pending consolation/shatter amounts to stored reward decisions without changing the original artifact roll.
- [ ] **Step 6: Run all Expedition tests and the 10,000-run loot simulation** and verify pass with unchanged artifact/chase frequencies.
- [ ] **Step 7: Commit** with `feat: make expedition duplicates meaningful`.

### Task 5: Covenant duplicate protection

**Files:**
- Modify: `scripts/expedition/expedition_loot_roller.gd`
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Modify: `tests/expedition_loot_roller_native.gd`
- Modify: `tests/expedition_loot_flow_native.gd`

**Interfaces:**
- Changes: `ExpeditionLootRoller.roll(..., pity: Dictionary, owned_ids: Array[String] = []) -> Dictionary`.
- Rule: before the player owns all three Covenant pieces, missing set entries receive weight `4.0` and owned entries retain weight `1.0`; after completion all entries return to equal weight.

- [ ] **Step 1: Write failing deterministic tests** for the 4:1 weighting, equal post-completion weights, same-input stability, and unchanged global RNG.
- [ ] **Step 2: Add a 10,000-seed distribution assertion** that missing pieces are favored without becoming guaranteed and every set item remains reachable.
- [ ] **Step 3: Run roller and loot-flow tests** and verify RED.
- [ ] **Step 4: Pass the frozen profile ownership snapshot into boss set rolls** and apply weights before the deterministic draw.
- [ ] **Step 5: Run roller, loot-flow, settlement, and simulation tests** and verify pass.
- [ ] **Step 6: Commit** with `feat: protect covenant collection progress`.

---

## Milestone 3 — Give shards a purpose and enable target farming

### Task 6: Ember Forge commitments

**Files:**
- Create: `scripts/expedition/ember_forge.gd`
- Modify: `scripts/expedition/expedition_profile.gd`
- Modify: `scripts/autoloads/expedition_manager.gd`
- Modify: `scripts/expedition/expedition_loot_roller.gd`
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Create: `scripts/ui/ember_forge.gd`
- Create: `scenes/ui/ember_forge.tscn`
- Modify: `scripts/ui/expedition_hub.gd`
- Create: `tests/expedition_ember_forge_native.gd`
- Create: `tests/expedition_ember_forge_native.tscn`

**Interfaces:**
- Produces: profile schema 4 field `forge_commitments: Dictionary`; `ExpeditionManager.buy_forge_commitment(id: String) -> bool`; `consume_forge_commitment(id: String, reward_id: String) -> bool`.
- Exact commitments: `treasure_choice` costs 15 and adds one deterministic alternative; `discovery_ward` costs 20 and excludes owned elite/treasure entries once; `covenant_mark` costs 30 and changes missing-piece weights from 4:1 to deterministic missing-piece selection once.

- [ ] **Step 1: Write failing profile/manager tests** for schema migration, exact costs, insufficient funds, one active copy per commitment, atomic failed-save rollback, and no raw-stat fields.
- [ ] **Step 2: Write failing roller tests** proving alternatives derive from stable suffix IDs, ward/mark consumption is single-use, and resume cannot reroll either result.
- [ ] **Step 3: Write failing mobile UI tests** for three actions, cost/ownership states, confirmation, Android back, and 88 px buttons.
- [ ] **Step 4: Run Forge tests** and verify RED.
- [ ] **Step 5: Implement profile commitments and copy-on-write purchases**, then consume them only after the affected reward and updated session/profile checkpoint both succeed.
- [ ] **Step 6: Implement the hub Forge screen** with no generic reroll or direct chase purchase.
- [ ] **Step 7: Run Forge, profile, roller, settlement, flow, touch, and run-integrity tests** and verify pass.
- [ ] **Step 8: Commit** with `feat: add deterministic ember forge`.

---

## Milestone 4 — Add discovery depth without combinatorial chaos

### Task 7: Three curated artifact-pair synergies

**Files:**
- Create: `scripts/expedition/artifacts/artifact_synergy_registry.gd`
- Modify: `scripts/expedition/artifacts/artifact_runtime.gd`
- Modify: `scripts/expedition/artifacts/artifact_combat_hooks.gd`
- Modify: `scripts/expedition/artifacts/independent_artifact_behaviors.gd`
- Modify: `scripts/expedition/artifacts/ember_artifact_behaviors.gd`
- Modify: `scripts/expedition/artifacts/artifact_vfx.gd`
- Modify: `scripts/expedition/expedition_profile.gd`
- Create: `tests/expedition_artifact_synergies_native.gd`
- Create: `tests/expedition_artifact_synergies_native.tscn`

**Interfaces:**
- Produces: explicit pair registry `get_active_pairs(ids: Array[String]) -> Array[StringName]`; profile schema 5 field `discovered_synergy_ids: Array[String]`.
- Initial pairs: `prism_needle_crossfire`, `hourglass_sigil_blood_echo`, `crown_prism_split_transfer`.

- [ ] **Step 1: Write failing registry tests** for exact pair activation, order independence, duplicate IDs, unknown IDs, and no implicit three-way interaction.
- [ ] **Step 2: Write failing combat tests** pinning each pair's bounded behavior, origin flags, one-generation cap, no second HP payment for blood echo, and no self-recursion.
- [ ] **Step 3: Write failing discovery tests** proving a synergy enters the profile only after triggering and failed save does not reveal it.
- [ ] **Step 4: Run synergy tests** and verify RED.
- [ ] **Step 5: Implement the explicit registry and three behaviors**; reuse existing hook generation/origin metadata rather than creating a generic combination engine.
- [ ] **Step 6: Add one distinct bounded VFX per pair** and expose discovered entries to the Codex.
- [ ] **Step 7: Run synergy, artifact-runtime, damage, performance, settlement, and Codex tests** and verify pass.
- [ ] **Step 8: Commit** with `feat: add curated expedition artifact synergies`.

### Task 8: Blood Omen and post-discovery Sigil variants

**Files:**
- Create: `scripts/expedition/blood_omen.gd`
- Modify: `scripts/expedition/expedition_profile.gd`
- Modify: `scripts/expedition/expedition_session.gd`
- Modify: `scripts/expedition/expedition_loot_roller.gd`
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Modify: `scripts/expedition/artifacts/independent_artifact_behaviors.gd`
- Modify: `scripts/ui/expedition_codex.gd`
- Create: `tests/expedition_blood_omen_native.gd`
- Create: `tests/expedition_blood_omen_native.tscn`

**Interfaces:**
- Produces: `BloodOmen.is_available(profile) -> bool` after three settled eligible misses; profile schema 6 fields for fragments/selected variant; session schema 7 flag `blood_omen_active`; two mutually exclusive Sigil variants unlocked with three `bloodwritten_fragments` after initial ownership.
- Rule: first Sigil retains 15% chance and fifth-victory guarantee; Blood Omen increases encounter risk and chase chance but never delays the existing guarantee.

- [ ] **Step 1: Write failing state tests** for availability after three misses, persistence through death, explicit opt-in, no activation before first eligibility, and reset/display behavior after the guaranteed first Sigil.
- [ ] **Step 2: Write failing roller tests** for deterministic Omen odds, unchanged fifth-win guarantee, and no fragment before initial Sigil ownership.
- [ ] **Step 3: Write failing runtime tests** for the two named Sigil variants, their visible downside, mutual exclusivity, and no second HP payment from echoed casts.
- [ ] **Step 4: Run Blood Omen tests** and verify RED.
- [ ] **Step 5: Implement Omen state and boss modifier plumbing**, then add fragment settlement and one selected pre-run Sigil variant.
- [ ] **Step 6: Add the Codex Omen/fragment display** with a single next-action prompt instead of raw hidden probability details.
- [ ] **Step 7: Run Blood Omen, roller simulation, settlement, runtime, Codex, and flow tests** and verify pass.
- [ ] **Step 8: Commit** with `feat: extend the bloodwritten chase`.

### Task 9: Loot hierarchy, telemetry, and system balance gate

**Files:**
- Modify: `scripts/ui/expedition_reward_overlay.gd`
- Modify: `scripts/expedition/artifacts/artifact_vfx.gd`
- Modify: `scripts/autoloads/run_telemetry.gd`
- Modify: `tests/expedition_artifact_ui_native.gd`
- Modify: `tests/telemetry_native.gd`
- Modify: `tests/expedition_flow_native.gd`
- Modify: `docs/design-overview.md`
- Create: `docs/expedition-loot-hunt-tuning.md`

**Interfaces:**
- Produces: presentation classes `SHARDS`, `DUPLICATE`, `NEW`, `SET_PIECE`, `SET_COMPLETE`, `CHASE`; telemetry events for room source, rolled result, decision, effective loadout delta, Forge commitment, and post-run settlement.

- [ ] **Step 1: Write failing UI tests** for the six presentation classes, skippable reveal, no long ceremony for shards/duplicates, distinctive chase treatment, and reduced-motion fallback.
- [ ] **Step 2: Write failing telemetry tests** for one event per decision/reward ID, bounded payloads, no duplicate event after resume, and no personally identifying/device data.
- [ ] **Step 3: Run UI and telemetry tests** and verify RED.
- [ ] **Step 4: Implement presentation routing and bounded telemetry**, keeping gameplay state independent from animation completion.
- [ ] **Step 5: Run a seeded balance simulation** tracking empty-room rate, new-discovery cadence, Echo/Temper/Shatter choice rates, set completion, shard income/spend, and first-Sigil victory index.
- [ ] **Step 6: Tune only data values** until elite/treasure always produce progress, the first 5–8 successful expeditions regularly reveal something new, and no Forge choice dominates more than 60% of purchases in the synthetic policy set.
- [ ] **Step 7: Run editor smoke, every native test scene, Android debug export, portrait touch smoke, save/resume smoke, and log scan**; require exit 0 and no script/resource/ObjectDB/RID leak errors attributable to the change.
- [ ] **Step 8: Request an independent whole-branch review** focused on save atomicity, deterministic-choice exploits, session/profile isolation, recursive artifact triggers, touch navigation, and late-run power creep; fix all Critical/Important findings and rerun verification.
- [ ] **Step 9: Update documentation and commit** with `test: verify expedition loot hunt expansion`.

---

## Milestone 5 — Approved visual direction: Burned Manuscript / Ember Reliquary

The approved visual target is the three-screen portrait flow `branching Burning Grounds map → Ashen Needle set-piece reveal → Echo slot comparison`. Expedition keeps Syntax Breaker's violet cyber-fantasy foundation but adds soot, smoked black glass, burned copper, ember cracks, code-like occult runes, and blood-written seals. It must not drift into medieval parchment, generic blue holograms, particle-heavy fantasy, or rounded SaaS cards.

**Palette:** coal `#09070D`, soot violet `#120D1B`, smoked glass `#181321`, bone `#E9E2D7`, ash `#9D96A3`, system violet `#8B5CF6`, ember orange `#F26A21`, hot gold `#FFC04A`, Echo cyan `#62D9E8`, Temper magenta `#E34878`, blood crimson `#E52F4F`, shard amber `#FFB02E`.

**Visual grammar:** violet means navigation/system, ember means persistent Expedition loot, cyan means run-only Echo, magenta crack means Temper instability, crimson seal means Omen/chase. Color is always reinforced by a label, icon, and border shape. Enemy telegraphs retain higher contrast and render priority than every friendly artifact effect.

### Task 10: Artifact icon set and reusable Expedition components

**Files:**
- Create: `assets/icons/artifacts/furnace-heart-v1.png`
- Create: `assets/icons/artifacts/ashen-needle-v1.png`
- Create: `assets/icons/artifacts/cinder-crown-v1.png`
- Create: `assets/icons/artifacts/fractured-prism-v1.png`
- Create: `assets/icons/artifacts/echoing-hourglass-v1.png`
- Create: `assets/icons/artifacts/bloodwritten-sigil-v1.png`
- Create: `assets/icons/expedition/ember-shard-v1.png`
- Create: `assets/icons/expedition/source-elite-v1.png`
- Create: `assets/icons/expedition/source-treasure-v1.png`
- Create: `assets/icons/expedition/source-boss-v1.png`
- Modify: `resources/artifacts/*.tres`
- Create: `scripts/ui/expedition_visual_theme.gd`
- Create: `scripts/ui/artifact_card.gd`
- Create: `scripts/ui/covenant_meter.gd`
- Create: `tests/expedition_visual_components_native.gd`
- Create: `tests/expedition_visual_components_native.tscn`

**Interfaces:**
- Produces: `ExpeditionVisualTheme` palette/style helpers; `ArtifactCard.setup(artifact, discovery_state: String, context: Dictionary) -> void`; `CovenantMeter.set_progress(count: int, preview_count: int = -1) -> void`.
- Icon silhouettes: furnace-heart, ember-core needle, broken crown, triangular split prism, doubled hourglass, irregular blood seal; each remains recognizable at 80×80 px and contains no embedded text.

- [ ] **Step 1: Write failing component tests** for all six non-null artifact icons, stable 1:1 source paths, unknown/encountered/owned card states, source glyphs, Covenant `0/3–3/3`, preview delta, and color-plus-label accessibility.
- [ ] **Step 2: Run `expedition_visual_components_native.tscn`** and verify RED on missing icons/classes.
- [ ] **Step 3: Produce the six artifact icons and four utility glyphs** as separate square raster assets with strong silhouettes, dark negative space, and restrained ember/cyan/crimson accents.
- [ ] **Step 4: Implement reusable card, meter, frame, and typography helpers** with clipped corners, smoked-glass fill, 2 px borders, and no fixed 600–760 px desktop widths.
- [ ] **Step 5: Run component, catalog, item-art, and Android asset inclusion tests** and verify pass.
- [ ] **Step 6: Commit** with `feat: establish expedition relic visual language`.

### Task 11: Node map, hub reliquary, Codex, and Forge presentation

**Files:**
- Modify: `scripts/ui/expedition_map.gd`
- Modify: `scenes/ui/expedition_map.tscn`
- Modify: `scripts/ui/expedition_hub.gd`
- Modify: `scenes/ui/expedition_hub.tscn`
- Modify: `scripts/ui/expedition_artifacts.gd`
- Modify: `scenes/ui/expedition_artifacts.tscn`
- Modify: `scripts/ui/expedition_codex.gd`
- Modify: `scenes/ui/expedition_codex.tscn`
- Modify: `scripts/ui/ember_forge.gd`
- Modify: `scenes/ui/ember_forge.tscn`
- Create: `tests/expedition_visual_navigation_native.gd`
- Create: `tests/expedition_visual_navigation_native.tscn`

**Interfaces:**
- Map layout: upper 65–70% for connected nodes, lower 30–35% for a pinned room-detail sheet; selecting a node previews it and a separate `ENTER` button confirms.
- Node shapes: combat circle, elite spiked diamond, treasure hex/chest, boss large seal/gate; minimum node hit area 120×120 px and connector thickness 8 px.
- Hub: `NEW/RESUME` remain primary; four artifact slots form a 2×2 reliquary; Codex and Forge are secondary tiles; one next-hunt objective is visible without scrolling.

- [ ] **Step 1: Write failing navigation tests** for real graph connectors, node state shapes, select-then-enter behavior, pinned threat/reward-family panel, tracked-artifact marker, and no accidental room entry on first tap.
- [ ] **Step 2: Add failing portrait tests** for the hub reliquary, Codex next-hunt priority, 64–72 px filter chips, 136 px compact cards, Forge `READY/ACTIVE/INSUFFICIENT` states, and bottom detail sheets.
- [ ] **Step 3: Run visual-navigation, Codex, artifact-UI, and touch tests** and verify RED.
- [ ] **Step 4: Implement the node map and responsive safe-area layout** using anchors/containers with 24–32 px small-screen margins and bottom CTA gesture padding.
- [ ] **Step 5: Restyle hub, loadout, Codex, and Forge with the shared components**; full descriptions live in a 70–80% bottom sheet instead of long button labels.
- [ ] **Step 6: Implement Android Back hierarchy**: close detail/confirm first, return to parent second, require abandon confirmation on an active map, and never `queue_free()` an unresolved reward decision.
- [ ] **Step 7: Run navigation, node-route, touch, Codex, loadout, Forge, and flow tests** and verify pass at 1080×1920 plus the smallest supported portrait viewport.
- [ ] **Step 8: Commit** with `feat: build expedition reliquary interface`.

### Task 12: Ranked reward reveals and Echo/Temper comparison UI

**Files:**
- Modify: `scripts/ui/expedition_reward_overlay.gd`
- Modify: `scenes/ui/expedition_reward_overlay.tscn`
- Create: `scripts/ui/artifact_comparison.gd`
- Modify: `tests/expedition_artifact_ui_native.gd`
- Modify: `tests/expedition_reward_decision_native.gd`
- Create: `tests/expedition_reveal_timing_native.gd`
- Create: `tests/expedition_reveal_timing_native.tscn`

**Interfaces:**
- Presentation timing caps: shards toast `1.0 s` without pause; duplicate sheet entry `0.22 s`; new reveal `0.8 s`; set piece `0.95 s`; set complete `1.35 s`; chase `1.6 s`. Reveal skip becomes available no later than `0.25 s`.
- `ArtifactComparison.setup(current_ids: Array[String], candidate_id: String, preview_slot: int) -> void` shows lost effect, gained effect, set delta, and at most three changed stats; it never displays a synthetic power score.

- [ ] **Step 1: Write failing timing/state tests** for all six presentation classes, skip-to-final-frame behavior, no modal for shards, one unresolved decision guard, and reduced-motion crossfade without rotation/flash/scale punch.
- [ ] **Step 2: Write failing comparison tests** for four slot targets, actual changed values only, Covenant before→after meter, lost/gained effect labels, disabled Temper reason, and 88/96 px bottom actions.
- [ ] **Step 3: Run reveal and reward-decision tests** and verify RED.
- [ ] **Step 4: Implement the approved Ashen Needle vertical slice first**: `NEW SET PIECE`, 160–192 px icon, copper Covenant card, `● ● ○` meter, source label, one-line effect, and `KEEP LOADOUT/EQUIP ECHO` actions.
- [ ] **Step 5: Generalize the same component tree across NEW, DUPLICATE, SET, CHASE, Echo, Temper, and Shatter states** without duplicating decision logic.
- [ ] **Step 6: Implement reward Back behavior**: Back skips reveal animation; Back during a required decision only returns from slot selection or displays `Choose before continuing`.
- [ ] **Step 7: Run reveal, UI, flow, touch, resume, and reduced-motion tests** and verify pass.
- [ ] **Step 8: Commit** with `feat: add ranked expedition loot reveals`.

### Task 13: Bounded combat VFX, Blood Omen treatment, and phone visual QA

**Files:**
- Modify: `scripts/expedition/artifacts/artifact_vfx.gd`
- Modify: `scripts/expedition/artifacts/artifact_runtime.gd`
- Modify: `scripts/ui/expedition_map.gd`
- Modify: `scripts/ui/expedition_codex.gd`
- Create: `tests/expedition_vfx_budget_native.gd`
- Create: `tests/expedition_vfx_budget_native.tscn`
- Modify: `tests/combat_readability_native.gd`
- Modify: `docs/expedition-loot-hunt-tuning.md`

**Interfaces:**
- Budgets: at most 12 lightweight artifact VFX, 4 trails, and 2 simultaneous synergy events; extra requests merge or drop. Use pooled CanvasItem/Line2D or atlas sprites, one full-screen scrim maximum, 16–24 arc segments, no viewport capture, full-screen blur, GPU particles, persistent chromatic aberration, or continuous screen shake.
- Omen presentation: five-cut seal in hub/Codex, crimson boss-node ring, explicit `+RISK/+CHASE CHANCE`, 6–9% combat vignette, one peripheral rune, and a distinct boss-bar frame.

- [ ] **Step 1: Write failing budget tests** for pool reuse, exact concurrent caps, excess-drop behavior, teardown/reset, generation/origin guards, and enemy telegraph draw priority.
- [ ] **Step 2: Write failing Omen tests** for five visible pity cuts, available/active labels, normal-vs-Omen boss distinction without color, and reduced-motion behavior.
- [ ] **Step 3: Run VFX-budget and combat-readability tests** and verify RED.
- [ ] **Step 4: Replace the generic expanding artifact ring** with short glyph/rune feedback; implement cyan Echo ring, magenta Temper crack, and the three bounded synergy signatures from Task 7.
- [ ] **Step 5: Implement Blood Omen map/HUD/boss treatment** without a red full-screen damage flash.
- [ ] **Step 6: Run performance/readability tests under the densest supported combat fixture** and verify hostile warnings remain more legible than every friendly effect.
- [ ] **Step 7: Export and install the portrait Android build**, then manually verify map tap targets, Echo slot comparison, Temper/Shatter five-second comprehension, reveal skipping, Codex bottom sheet scrolling, Android Back safety, low-brightness Omen contrast, and reduced motion.
- [ ] **Step 8: Record screenshots and measured frame/VFX counts in the tuning document**, fix Critical/Important issues, and rerun the full native suite plus Android export.
- [ ] **Step 9: Commit** with `test: verify expedition visual direction on phone`.

## Milestone 6 — Living Build Visual Identity

This milestone extends the approved Burned Manuscript / Ember Reliquary direction into combat. The
player must be able to identify the dominant skill, support behavior, build power and immediate
hostile danger from shape and motion rather than color or text. The guiding fantasy is a hacker whose
increasingly powerful build compiles progressively more broken reality.

**Visual grammar:** every attack owns four separable layers: stable skill silhouette, elemental
material, one support modifier, and an evolution signature. Friendly spectacle degrades before
gameplay information. Hostile telegraphs and projectiles always retain the strongest contour and
highest draw priority. Player-facing Blade Spin artwork, naming and orbit imagery are forbidden;
`blade_spin` may survive only as the internal save-compatible Rollback ID.

**Shared budgets:** preserve the Task 13 limits of 12 artifact glyphs, 4 long trails, 2 simultaneous
synergy signatures and 1 scrim. Add ceilings of 8 full hit flashes, 8 full death signatures, 24
fully sampled projectile trails and 2 major hero moments. Aggregate ordinary damage numbers per
target/source within 0.15–0.25 seconds. Reduced motion replaces travel/scale flourishes with short
opacity or shape changes; it never removes gameplay feedback.

### Task 14: Combat visual grammar and adaptive clutter budget

**Files:**
- Create: `scripts/effects/combat_visual_budget.gd`
- Create: `scripts/effects/skill_visual_profile.gd`
- Create: `resources/skill_visuals/rollback.tres`
- Create: `resources/skill_visuals/fireball.tres`
- Create: `resources/skill_visuals/static_field.tres`
- Modify: `scripts/effects/hit_effect.gd`
- Modify: `scripts/effects/death_effect.gd`
- Modify: `scripts/ui/damage_number.gd`
- Modify: `scripts/enemies/boss_hazard.gd`
- Create: `tests/combat_visual_grammar_native.gd`
- Create: `tests/combat_visual_grammar_native.tscn`

**Interfaces:**
- `SkillVisualProfile` exposes `skill_id`, `core_shape`, `cast_signature`, `hit_signature`,
  `residue_signature`, `primary_color`, `accent_color`, and `max_screen_coverage`.
- `CombatVisualBudget.request(kind: StringName, priority: int, origin_id: int) -> bool` admits,
  merges or drops cosmetic work; hostile warnings bypass friendly cosmetic limits.
- Draw order remains hostile warning/projectile → player/elite/boss → skill core → cosmetic trail,
  debris and ordinary damage numbers.

- [ ] **Step 1: Write failing profile tests** proving Rollback, Fireball and Static Field have non-color-distinct core shapes and complete cast/travel-or-field/hit identities.
- [ ] **Step 2: Write failing budget tests** for 8 hit flashes, 8 death signatures, 24 full trails, 2 hero moments, target/source damage-number aggregation and hostile-priority bypass.
- [ ] **Step 3: Run the grammar, readability and Task 13 VFX-budget tests** and verify RED on the missing profile and budget interfaces.
- [ ] **Step 4: Implement the shared profiles and adaptive budget**, degrading ambient particles, old trails, ordinary hit sparks and ordinary damage numbers in that order.
- [ ] **Step 5: Replace the generic full hit/death ring for ordinary damage** with a small directional mark; reserve full signatures for crit, execute, kill, synergy and evolution events.
- [ ] **Step 6: Implement telegraph phases without color-only state**: dashed warning, closing imminent segments, hatched active area, inward safe-space chevrons and a single activation impulse.
- [ ] **Step 7: Run grammar, combat-readability, boss and artifact-VFX tests** and verify pass at full and reduced-motion settings.
- [ ] **Step 8: Commit** with `feat: establish living combat visual grammar`.

### Task 15: Three-skill visual identity vertical slice

**Files:**
- Modify: `scripts/skills/rollback.gd`
- Modify: `scenes/skills/rollback.tscn`
- Modify: `scenes/skills/fireball.tscn`
- Modify: `scenes/skills/static_field.tscn`
- Create: `scripts/effects/skill_visual_renderer.gd`
- Create: `scripts/effects/support_visual_modifier.gd`
- Modify: `scripts/skills/skill_caster.gd`
- Modify: `tests/rollback_native.gd`
- Create: `tests/skill_visual_slice_native.gd`
- Create: `tests/skill_visual_slice_native.tscn`

**Interfaces:**
- `SkillVisualRenderer.configure(profile: SkillVisualProfile, support_ids: Array[String], evolution_tier: int) -> void` composes one core silhouette, elemental material, at most one primary support modifier and one bounded evolution signature.
- Support glyphs are shared across skills: Chain nodes, Split `Y`, Pierce notch, Returning reverse arrow,
  Echo offset outline, Mine closing diamond, Totem transmitter brackets and Rubber Duck marker.
- Rollback uses a hooked bracket/boomerang silhouette: continuous cyan outbound trail, turn bracket,
  dashed/reversed magenta return trail and a closing catch glyph. It never uses orbiting knives.

- [ ] **Step 1: Write failing visual-slice tests** for the three distinct silhouettes, Rollback outbound/turn/return/catch phases and absence of player-facing Blade Spin name, icon and orbit scene.
- [ ] **Step 2: Write failing support-modifier tests** proving Chain, Returning, Echo, Mine, Totem and Rubber Duck change geometry while respecting the shared budgets.
- [ ] **Step 3: Run the slice, Rollback, contracts and support-combination tests** and verify RED.
- [ ] **Step 4: Implement Rollback as the poster skill**, including the reversed return language and a Tier III cosmetic rewind of trails/debris only, capped at 120 ms.
- [ ] **Step 5: Implement Fireball** as a compressed square ember core with three tail blocks and a directional compilation-error impact rather than a circular blast.
- [ ] **Step 6: Implement Static Field** as a broken technical perimeter with four anchors and tick-only target arcs rather than a filled aura.
- [ ] **Step 7: Add the six support modifiers** with 120–250 ms identifying punctuation and no repeating combat text.
- [ ] **Step 8: Run the slice and dense-combat fixtures**, verifying each skill remains recognizable in grayscale and under saturated friendly caps.
- [ ] **Step 9: Commit** with `feat: give core skills visible build identity`.

### Task 16: Reactive Breaker avatar and build portrait

**Files:**
- Create: `scripts/player/breaker_visual_loadout.gd`
- Modify: `scripts/util/breaker_sprite.gd`
- Modify: `scripts/player/player.gd`
- Modify: `scripts/ui/hud.gd`
- Modify: `scripts/ui/skill_manager.gd`
- Create: `scripts/ui/build_portrait.gd`
- Create: `tests/breaker_visual_loadout_native.gd`
- Create: `tests/breaker_visual_loadout_native.tscn`

**Interfaces:**
- `BreakerVisualLoadout.resolve(skill_instances: Array, artifact_ids: Array[String]) -> Dictionary`
  returns at most three visible layers selected from `focus`, `back`, `body_accent` and `emblem`.
- Dominant tags map to authored procedural accents: fire ember hand/charred hem, lightning antenna/rune,
  poison respirator/vials, cold crystal shoulder, physical/Rollback hooked forearm/back bracket.
- Covenant, Bloodwritten Sigil and memetic supports may claim the emblem/back slot but never obscure
  the player's feet, canonical hood, 2–3 px dark outline or bright chest/head anchor.
- `BuildPortrait.setup(loadout: Dictionary) -> void` renders a 160–256 px authored bust from the same
  layer data; it does not upscale the combat sprite.

- [ ] **Step 1: Write failing loadout tests** for deterministic dominant-tag selection, three-layer cap, slot conflicts, eight-direction anchors and save-independent cosmetic reconstruction.
- [ ] **Step 2: Write failing portrait/HUD tests** for matching hood, focus, dominant element and Covenant/Omen emblem at portrait scale.
- [ ] **Step 3: Run avatar, skill-manager-art and combat-readability tests** and verify RED.
- [ ] **Step 4: Implement the canonical Breaker layers** without changing collision, animation timing or the base 32×36 gameplay silhouette.
- [ ] **Step 5: Add short cast accents and a segmented shield**, keeping the foot anchor visible through friendly fields.
- [ ] **Step 6: Implement the build portrait** for skill manager and run summary; omit multiple operator/classes until this canonical avatar passes phone QA.
- [ ] **Step 7: Run avatar, UI, save/resume and reduced-motion tests** and verify pass.
- [ ] **Step 8: Commit** with `feat: make the breaker reflect the active build`.

### Task 17: Enemy silhouettes, source deaths and Expedition boss readability

**Files:**
- Modify: `scripts/enemies/enemy_base.gd`
- Modify: `scripts/enemies/regional_boss.gd`
- Modify: `scripts/enemies/boss_hazard.gd`
- Modify: `scripts/effects/death_effect.gd`
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Modify: `scripts/ui/hud.gd`
- Create: `tests/enemy_visual_roles_native.gd`
- Create: `tests/enemy_visual_roles_native.tscn`
- Modify: `tests/boss_native.gd`
- Modify: `tests/combat_readability_native.gd`

**Interfaces:**
- Combat roles use distinct outlines: swarm wedge, melee broad `V`, ranged tall eye/barrel, tank
  square shoulders, support diamond/antennae, charger directional body, elite outer error crown.
- Trash health bars hide at full health and appear after damage; elite/boss bars remain visible.
  Status display shows at most two priority glyphs plus `+N`.
- Source deaths are pooled and last 0.25–0.45 s with at most six fragments: fire ash cracks,
  cold shards, lightning collapse, poison puddle, physical directional cut and void implosion.
- Boss phase change may use one 120–180 ms corruption punctuation but cannot delay room completion,
  settlement or checkpoint teardown.

- [ ] **Step 1: Write failing role tests** for outline distinction at gameplay scale, health-bar policy, status cap and elite/boss recognition without color.
- [ ] **Step 2: Write failing source-death tests** for six signatures, pooling, eight-effect cap and immediate gameplay teardown after the last enemy/boss dies.
- [ ] **Step 3: Write failing boss-telegraph tests** for pose → warning → active order, safe-gap shape, Omen distinction and friendly-VFX overlap.
- [ ] **Step 4: Run enemy, boss, finale-performance and readability tests** and verify RED.
- [ ] **Step 5: Implement role silhouettes and health/status decluttering** without enlarging colliders with their visual bodies.
- [ ] **Step 6: Implement pooled source-death signatures and boss phase punctuation**; cosmetic completion signals observe state and never own it.
- [ ] **Step 7: Add boss/offscreen and last-straggler brackets** so remaining enemies cannot stall the room flow invisibly.
- [ ] **Step 8: Run the dense encounter and stage-end regression fixtures**, verifying no reintroduction of the last-kill freeze.
- [ ] **Step 9: Commit** with `feat: clarify expedition enemies and boss combat`.

### Task 18: Complete skill catalog, loot punctuation and phone stress QA

**Files:**
- Create: `resources/skill_visuals/lightning_bolt.tres`
- Create: `resources/skill_visuals/poison_dart.tres`
- Create: `resources/skill_visuals/flame_wave.tres`
- Create: `resources/skill_visuals/frost_nova.tres`
- Modify: `scenes/skills/lightning_bolt.tscn`
- Modify: `scenes/skills/poison_dart.tscn`
- Modify: `scenes/skills/flame_wave.tscn`
- Modify: `scenes/skills/frost_nova.tscn`
- Modify: `scripts/ui/expedition_reward_overlay.gd`
- Modify: `scripts/ui/skill_manager.gd`
- Create: `tests/skill_visual_catalog_native.gd`
- Create: `tests/combat_visual_stress_native.gd`
- Create: `tests/combat_visual_stress_native.tscn`
- Modify: `docs/expedition-loot-hunt-tuning.md`

**Interfaces:**
- Remaining silhouettes: Lightning jagged trace/network nodes; Poison needle/drop pips; Flame Wave
  broken directional firewall; Frost Nova hexagonal fracture with an empty center.
- Evolution tiers are additive but bounded: Tier I changes hit mark, Tier II adds route/residue,
  Tier III allows one cooldown-governed hero punctuation; damage alone never scales VFX coverage.
- Reward punctuation remains skippable: Shards magnet streak, Duplicate double-image fracture, New
  line-print reveal, Set copper seal assembly, Set Complete three linked relic glyphs, Chase five-cut
  crimson seal. Last-enemy rewards travel to the player automatically.

- [ ] **Step 1: Write failing catalog tests** requiring all seven skill profiles, unique grayscale core shapes, shared support glyphs and base/support/evolution preview states.
- [ ] **Step 2: Write failing reward tests** for all six punctuation classes, automatic collection, skip by 0.25 s and reduced-motion final-frame behavior.
- [ ] **Step 3: Write the failing stress fixture** with 80 enemies, saturated friendly budgets, crossing hostile projectile, active boss telegraph, low-resolution profile and reduced-motion/VFX-density variants.
- [ ] **Step 4: Run catalog, reward, stress, item-art and combat-readability tests** and verify RED.
- [ ] **Step 5: Implement the remaining four profiles and tiered evolution signatures** using pooled Line2D/Polygon2D or atlas sprites with at most 16–20 segments per effect.
- [ ] **Step 6: Implement the six reward punctuation treatments and automatic last-drop travel** without adding blocking animation to settlement.
- [ ] **Step 7: Add the skill-manager `before → after` loop** for a selected support/evolution; stop playback when the panel is hidden and never require hover.
- [ ] **Step 8: Run the full native suite and Android export**, then install without clearing data and test at 1080×1920, smallest supported portrait viewport, 50% brightness and a 30 fps capture.
- [ ] **Step 9: Record screenshots and measurements**: identify player/nearest hostile/safe zone within 200 ms, identify every skill in grayscale, friendly opaque coverage below 20%, and 95th-percentile frame-time regression no worse than 1.5 ms on the target phone.
- [ ] **Step 10: Commit** with `test: verify living build visuals on phone`.

---

## Deferred Follow-up Plans

Create separate specifications and plans only after Milestone 4 telemetry is reviewed:

1. **Covenant Oaths and alternative sets** — prevent 3/4-slot monoculture with meaningful 2+1 decisions.
2. **Difficulty contracts and route modifiers** — expose room threat and reward family before selection.
3. **Second region and 8–12 additional artifacts** — expand only after six current artifacts produce distinct run stories.
4. **Named single-affix artifact variants** — at most one affix, curated blacklist, no random numeric ranges.
5. **Character progression/campaign** — separate from loot power so collection never replaces player skill.

## Completion Gate

The expansion is complete only when a found artifact can alter the next room through a checkpointed Echo, a duplicate offers Temper or Shatter, elite/treasure always advance the player, Covenant collection is protected without becoming guaranteed, Ember Shards have three deterministic non-power sinks, three curated pairs create safe discoverable interactions, the initial Sigil remains guaranteed by victory five, all six artifacts have distinct production icons, the approved node-map/reveal/Echo visual flow remains readable on the target phone, every skill and major support has a recognizable bounded combat silhouette, the Breaker visibly reflects the active build without losing its player anchor, hostile warnings remain readable under the 80-enemy stress fixture, Blade Spin is absent from player-facing content, friendly VFX stay within their budgets and below enemy-warning priority, and the full Expedition/roguelite regression suite plus Android portrait build pass from fresh evidence.
