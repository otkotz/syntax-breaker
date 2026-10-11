# Threat Protocol and Run-Flow Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Ascension with five pre-run Threat Protocols and ship the skill explanations, complete option artwork, smooth stage cleanup, serialized decisions, useful death recap, and safer contact damage defined by the approved design.

**Architecture:** Centralize difficulty rules in a new immutable `ThreatProtocols` utility consumed by progression, run state, stage generation, rewards, and menu UI. Add focused helpers for option artwork, modal sequencing, cleanup batching, and damage history rather than expanding already-large UI/game-manager methods. Preserve legacy save and telemetry reads through explicit migration adapters.

**Tech Stack:** Godot 4.7.2, GDScript, `.tres` resources, native scene tests, Android portrait validation.

**Spec:** `docs/superpowers/specs/2026-10-11-threat-protocol-polish-design.md`

## Global Constraints

- Threat Protocol is selected before a run; it is not an in-run reward.
- Protocol levels and names are exactly: `0 NORMAL`, `1 OVERCLOCKED`, `2 CORRUPTED`, `3 SYSTEM FAILURE`, `4 NO WARRANTY`.
- Unlocks are regional and victory unlocks only the next protocol.
- Existing Ascension saves migrate idempotently using bands 0, 1–4, 5–9, 10–14, and 15–20.
- Every interactive choice resolves non-null artwork; malformed content uses a deliberate fallback.
- Only one modal decision can be active at a time.
- Stage cleanup is bounded across frames and disables combat immediately.
- Preserve unrelated worktree changes, especially generated `.import` metadata and local logs.
- Do not rebalance individual skills from the two-run sample.

## Review Focus

- A legacy save containing mixed string/int regional keys and Ascension 20 migrates once, clamps correctly, and is not remigrated after restart; covered in Task 1.
- A terminal completes on the exact frame combat ends while another picker is exiting; the terminal offer remains first and every later decision appears once; covered in Task 5.
- Cleanup encounters pooled enemies already externally freed and still completes without duplicate signals or combat damage; covered in Task 6.
- A pooled enemy that hit before deactivation can hit normally after reuse but cannot multi-hit during one overlap; covered in Task 8.
- An offer with a missing or failed texture import remains selectable and displays fallback art without leaking locked Codex art; covered in Task 4.

---

## File Map

- `scripts/util/threat_protocols.gd`: canonical names, stable IDs, scaling, special rules, and legacy mapping.
- `scripts/autoloads/meta_progression.gd`: selected/unlocked protocol persistence and migration.
- `scripts/autoloads/run_manager.gd`: active protocol snapshot, run save compatibility, luck and inter-stage healing.
- `scripts/ui/main_menu.gd`: protocol selector, locked state, and exact risk/reward copy.
- `scripts/stages/stage_generator.gd`, `scripts/enemies/spawner.gd`: protocol stage rules and population scaling.
- `scripts/combat/evolution_data.gd`: observable descriptions and icon paths for all evolution tiers.
- `scripts/ui/skill_manager.gd`: tappable skill details drawer.
- `scripts/ui/option_art.gd`: one artwork resolver for every dictionary/resource offer.
- picker and chest scripts: consume `OptionArt.resolve()` and render tier/mastery badges.
- `scripts/main/decision_queue.gd`, `scripts/main/game_manager.gd`, `scripts/stages/compilation_terminal.gd`: serialized post-stage decisions.
- `scripts/stages/cleanup_batch.gd`, `scripts/enemies/spawner.gd`: bounded cleanup state.
- `scripts/autoloads/run_manager.gd`, `scripts/player/player.gd`, `scripts/ui/run_summary.gd`, `scripts/autoloads/run_telemetry.gd`: bounded death sequence.
- `scripts/enemies/enemy_base.gd`, `scripts/player/player.gd`, and `scenes/enemies/tank_enemy.tscn`: per-attacker cooldown, separation, and pool reset.

### Task 1: Threat Protocol Rules, Persistence, and Migration

**Files:**
- Create: `scripts/util/threat_protocols.gd`
- Modify: `scripts/autoloads/meta_progression.gd`
- Modify: `scripts/autoloads/run_manager.gd`
- Replace test: `tests/ascension_rules_native.gd`
- Rename scene references logically in: `tests/ascension_rules_native.tscn`
- Test: `tests/run_integrity.gd`

**Interfaces:**
- Produces: `ThreatProtocols.definition(level: int) -> Dictionary`, `ThreatProtocols.scaling(level: int) -> Dictionary`, `ThreatProtocols.special_modifiers(level: int, depth: int) -> Array[String]`, `ThreatProtocols.from_legacy_ascension(level: int) -> int`.
- Produces: `MetaProgression.threat_protocol_level`, `get_max_threat_protocol(region)`, `set_threat_protocol(level, region)`, `record_victory(region, level)`.
- Produces: `RunManager.threat_protocol_level` serialized under `threat_protocol_level`.

- [ ] **Step 1: Write failing protocol and migration tests**

Replace Ascension assertions with exact checks for all five definitions and scaling values. Write legacy JSON to the test save path with Ascension values `0, 4, 5, 10, 15, 20`, load twice, and assert the migrated regional maxima are `0, 1, 2, 3, 4, 4` and remain unchanged on the second load. Add corrupt `99` and `-5` clamps and regional-independence checks.

- [ ] **Step 2: Run the native tests and observe RED**

Run: `& 'D:\Pobrane\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --scene res://tests/ascension_rules_native.tscn`

Expected: FAIL because `ThreatProtocols` and the new progression API do not exist.

- [ ] **Step 3: Implement canonical rules and migration**

Define the five dictionaries with exact spec values, clamp all public lookups to `0..4`, and return duplicated dictionaries. In `MetaProgression.load_progress()`, prefer `highest_threat_protocol_unlocked`; otherwise convert every `highest_ascension_unlocked` entry and selected `ascension_level`, then save the new keys. Keep legacy read aliases only for active-run compatibility. Update `RunManager.start_run(region, protocol)` and save/load to snapshot the selected protocol.

- [ ] **Step 4: Run protocol and integrity tests GREEN**

Run both native scenes: `ascension_rules_native.tscn` and `run_integrity.tscn`.

Expected: both exit `0`; output names Threat Protocol and confirms idempotent migration.

- [ ] **Step 5: Commit**

Stage only the files named in this task and commit `feat: replace ascension data with threat protocols`.

### Task 2: Menu Preview and Runtime Risk/Reward Scaling

**Files:**
- Modify: `scripts/ui/main_menu.gd`
- Modify: `scripts/main/main.gd`
- Modify: `scripts/main/game_manager.gd`
- Modify: `scripts/stages/stage_generator.gd`
- Modify: `scripts/enemies/spawner.gd`
- Modify: `scripts/ui/reward_roller.gd`
- Modify: `tests/main_menu_touch_native.gd`
- Modify: `tests/balance_native.gd`
- Modify: `tests/telemetry_native.gd`

**Interfaces:**
- Consumes: Task 1 protocol definitions and progression methods.
- Produces: menu methods `_change_threat_protocol(delta)` and `_refresh_threat_protocol()`; runtime scaling includes `count_mult`, `luck_bonus`, and positive `gold_mult`.

- [ ] **Step 1: Add failing menu and scaling tests**

Assert locked protocols are visible but arrows cannot select beyond the regional maximum; selecting a preview does not mutate `RunManager`; starting does. For each level assert HP/damage/speed/count/gold/luck exact values, depth-one special-rule exemption, role caps, and telemetry keys `threat_protocol_level` plus stable ID. Assert higher protocols cannot reduce reward rarity under a fixed RNG seed.

- [ ] **Step 2: Run focused scenes RED**

Run: `main_menu_touch_native.tscn`, `balance_native.tscn`, and `telemetry_native.tscn` with the Godot console.

Expected: failures reference missing Threat Protocol UI/runtime fields.

- [ ] **Step 3: Replace menu copy and connect runtime consumers**

Rename labels and methods, display exact percentages and unlock requirement, and pass the selected protocol into `RunManager.start_run`. Replace Ascension scaling/modifier calls in stage generation and spawner. Multiply only normal population budget by `count_mult`, retaining entity/role caps. Add `luck_bonus` to the existing rarity luck calculation and apply positive gold multiplier. Emit new telemetry fields while retaining legacy-reader support.

- [ ] **Step 4: Run focused scenes GREEN**

Expected: all three exit `0`, and the menu test confirms portrait touch targets remain at least 48 px.

- [ ] **Step 5: Commit**

Commit `feat: add pre-run threat protocol selector`.

### Task 3: Skill Detail Drawer and Evolution Tier Copy

**Files:**
- Modify: `scripts/combat/evolution_data.gd`
- Modify: `scripts/ui/skill_manager.gd`
- Modify: `tests/evolutions_native.gd`
- Modify: `tests/skill_manager_art_native.gd`

**Interfaces:**
- Produces: `EvolutionData.tier_description(evolution_id: String, tier: int) -> String` and `EvolutionData.all_tier_descriptions(skill_id: String) -> Array[String]`.
- Produces: `SkillManagerUI._show_skill_info_drawer(skill: SkillInstance)`.

- [ ] **Step 1: Add failing content and touch tests**

Enumerate all seven evolution IDs and tiers 1–3, asserting non-empty unique observable descriptions. Instantiate a common and evolved skill; press its card header and assert the drawer contains description, current stats, rarity multiplier table, all three tier descriptions, current-tier marker, and linked support descriptions. Pressing a support slot must still open assignment rather than skill details.

- [ ] **Step 2: Run both scenes RED**

Expected: missing tier-description API and no skill-card touch drawer.

- [ ] **Step 3: Add centralized tier descriptions and drawer rendering**

Extend each `EvolutionData.BY_SKILL` entry with three exact descriptions matching runtime behaviors. Wrap the card header in a full-width accessible button or overlay that excludes socket rows. Reuse the existing drawer, clearing actions in read-only mode, and render all required sections with wrapped portrait-safe labels.

- [ ] **Step 4: Run both scenes GREEN**

Expected: exit `0`; no description contains only generic “more/stronger” wording.

- [ ] **Step 5: Commit**

Commit `feat: explain skill rarity and evolution tiers`.

### Task 4: Complete Option Artwork

**Files:**
- Create: `scripts/ui/option_art.gd`
- Create raster assets under: `assets/icons/evolutions/`, `assets/icons/mutations/`, `assets/icons/system/`
- Modify: `scripts/combat/evolution_data.gd`
- Modify: `scripts/combat/mutation_data.gd`
- Modify: `scripts/ui/ui_theme.gd`
- Modify: `scripts/ui/skill_picker.gd`
- Modify: `scripts/ui/reward_picker.gd`
- Modify: `scripts/ui/chest_reward.gd`
- Modify: `scripts/ui/mutation_picker.gd`
- Modify: `scripts/ui/legendary_picker.gd`
- Modify: `scripts/ui/compilation_picker.gd`
- Modify: `scripts/ui/shop.gd`
- Modify: `tests/item_art_native.gd`
- Modify: `tests/evolution_ui_touch_native.gd`

**Interfaces:**
- Consumes: Task 3 evolution metadata.
- Produces: `OptionArt.resolve(offer: Variant) -> Texture2D`, `OptionArt.badge(offer: Variant) -> String`, and a guaranteed fallback texture.

- [ ] **Step 1: Add failing exhaustive artwork tests**

Enumerate starter skills, supports, passives, mutations, evolutions, Hot Socket, gold/heal/fallback rewards, target-selection cards, and shop upgrades. Assert `resolve()` returns non-null and production card trees contain that texture. Add a malformed offer and failed resource path case; assert fallback art appears and the button remains selectable. Retain Codex locked-art privacy checks.

- [ ] **Step 2: Run art scenes RED**

Expected: missing resolver and missing mutation/evolution/system icons.

- [ ] **Step 3: Generate and bind artwork**

Use the image-generation workflow to create square transparent raster icons matching the existing dark neon/pixel-computer visual family: seven evolutions, every mutation lacking art, Hot Socket, gold, heal, generic fallback, and any remaining system choice. Store source PNGs in the named directories. Add icon metadata to evolution/mutation definitions and implement deterministic resolution order: explicit resource icon, metadata path, semantic system icon, fallback.

- [ ] **Step 4: Route every picker through `OptionArt`**

Replace picker-specific empty-icon branches with the resolver and render tier/mastery badges without intercepting input. Preserve existing icon size limits.

- [ ] **Step 5: Run art scenes GREEN**

Expected: `item_art_native.tscn`, `evolution_ui_touch_native.tscn`, `skill_picker_touch_native.tscn`, and `shop_touch_native.tscn` all exit `0`.

- [ ] **Step 6: Commit**

Commit `feat: illustrate every selectable option` without staging unrelated pre-existing `.import` modifications.

### Task 5: FIFO Decision Queue and Terminal Regression

**Files:**
- Create: `scripts/main/decision_queue.gd`
- Modify: `scripts/main/game_manager.gd`
- Modify: `scripts/stages/compilation_terminal.gd`
- Modify: `scripts/ui/compilation_picker.gd`
- Modify: `tests/compilation_terminal_native.gd`
- Modify: `tests/node_routes_native.gd`
- Modify: `tests/telemetry_native.gd`

**Interfaces:**
- Produces: `DecisionQueue.enqueue(kind: StringName, payload: Dictionary, priority: int)`, `complete_active(result: Dictionary)`, `cancel_active(reason: String)`, `clear()` and signal `decision_ready(request)`.
- Produces priorities terminal `400`, mutation/legendary `300`, reward `200`, map `100` while preserving FIFO within equal priority.

- [ ] **Step 1: Add failing queue and exact regression tests**

Unit-test order, equal-priority FIFO, clear, duplicate completion, and explicit cancellation. In a real `GameManager`, complete a terminal on the same frame as `_on_stage_completed()`, queue reward and map, and assert terminal appears first, its tier-III offer remains selectable, then reward and map each appear once. Queue another picker while the old one is `tree_exiting`; assert it cannot cancel the new decision. Assert telemetry opens only active decisions.

- [ ] **Step 2: Run terminal, route, and telemetry scenes RED**

Expected: current direct picker creation cancels or overlaps the terminal decision.

- [ ] **Step 3: Implement the queue and route modal creation**

Keep decision data as callables or stable payloads, but instantiate UI only in `GameManager` when `decision_ready` fires. Convert terminal completion into an enqueue request. Make every completion schedule queue advance with `call_deferred`; only explicit close buttons call cancellation. Clear the queue in `end_run`, new run, resume teardown, and manager exit.

- [ ] **Step 4: Run all three scenes GREEN**

Expected: terminal-at-stage-end regression passes and telemetry contains no teardown cancellation.

- [ ] **Step 5: Commit**

Commit `fix: serialize terminal and stage decisions`.

### Task 6: Bounded End-of-Stage Cleanup

**Files:**
- Create: `scripts/stages/cleanup_batch.gd`
- Modify: `scripts/enemies/spawner.gd`
- Modify: `scripts/stages/arena.gd`
- Modify: `scripts/autoloads/run_telemetry.gd`
- Create: `tests/stage_cleanup_native.gd`
- Create: `tests/stage_cleanup_native.tscn`
- Modify: `tests/stage_cleanup_native.gd`

**Interfaces:**
- Produces: `CleanupBatch.start(nodes: Array[Node], max_per_frame: int, max_usec: int)`, signal `finished(metrics: Dictionary)`.
- Produces cleanup metrics: `objects`, `batches`, `duration_ms`, `worst_batch_ms`.

- [ ] **Step 1: Write failing cleanup-state tests**

Populate an arena with more than two batches of pooled enemies, projectiles, boss hazards, denial zones, and one node freed externally between batches. Assert combat/spawning stops immediately, no damage is accepted during cleanup, at most the configured count is processed per frame, completion emits exactly once, role counters clear, and metrics are recorded.

- [ ] **Step 2: Run cleanup scene RED**

Expected: current `clear_transients()` processes everything synchronously and has no batching metrics.

- [ ] **Step 3: Implement detach-first batched release**

Snapshot valid cleanup targets, disable their process/physics/collision immediately, and process release/free operations in `_process` while respecting both count and microsecond limits. Skip invalid/freed instances. Keep `Spawner._completed` idempotence and emit `all_waves_cleared` only from the batch's one-shot `finished` handler. Record metrics through telemetry.

- [ ] **Step 4: Run cleanup and route scenes GREEN**

Run: `stage_cleanup_native.tscn` and `node_routes_native.tscn` with the Godot 4.7.2 console. The cleanup scene directly exercises `ObjectPool.release_all()` and validates pool counts before and after batching, avoiding the unavailable optional GUT plugin.

Expected: all exit `0`; route UI begins after cleanup, not before.

- [ ] **Step 5: Commit**

Commit `perf: batch combat cleanup across frames`.

### Task 7: Five-Hit Death Sequence and Summary

**Files:**
- Modify: `scripts/autoloads/run_manager.gd`
- Modify: `scripts/player/player.gd`
- Modify: `scripts/autoloads/run_telemetry.gd`
- Modify: `scripts/ui/run_summary.gd`
- Modify: `tests/damage_native.gd`
- Modify: `tests/telemetry_native.gd`
- Create: `tests/run_summary_native.gd`
- Create: `tests/run_summary_native.tscn`

**Interfaces:**
- Produces: `RunManager.record_damage_event(event: Dictionary)`, `RunManager.get_death_sequence() -> Array[Dictionary]`, max length `5`.
- Produces telemetry/run summary field `death_sequence`; preserves `death_source`.

- [ ] **Step 1: Add failing ring-buffer and UI tests**

Record seven accepted hits containing HP damage and shield-only damage plus one rejected hit. Assert the last five accepted events remain in chronological order, rejected events do not displace them, lethal source remains compatible, and start/new run clears history. Build the summary and assert “Final blow”, five compact rows, and burst damage/shield totals appear with wrapped text.

- [ ] **Step 2: Run damage, telemetry, and summary scenes RED**

Expected: no death sequence API or UI exists.

- [ ] **Step 3: Record accepted damage and render recap**

Record after mitigation in `Player.take_damage`, including shield-only accepted hits. Copy the bounded sequence into run-end telemetry. Add readable source normalization in `RunSummary` while keeping raw stable IDs in telemetry.

- [ ] **Step 4: Run all three scenes GREEN**

Expected: tank-tank-projectile sequence identifies projectile as final blow and tanks as the dominant preceding burst.

- [ ] **Step 5: Commit**

Commit `feat: explain the final damage burst`.

### Task 8: Per-Attacker Contact Cooldown and Pool Reset

**Files:**
- Modify: `scripts/enemies/enemy_base.gd`
- Modify: `scripts/player/player.gd`
- Modify: `scenes/enemies/tank_enemy.tscn`
- Create: `tests/contact_damage_native.gd`
- Create: `tests/contact_damage_native.tscn`
- Modify: `tests/player_shield_native.gd`

**Interfaces:**
- Produces: enemy field `contact_damage_cooldown` default `0.9`, floor `0.75` for normal enemies, and resettable last-contact state.
- Produces: `Player.apply_contact_separation(from_position: Vector2, strength: float)`.

- [ ] **Step 1: Add failing overlap and pooling tests**

Hold one medium enemy overlapping for two seconds and assert no more than the cooldown permits; place two enemies together and assert each can independently hit; assert shield-only hits start cooldown; deactivate/reset/reuse the enemy and assert it can hit immediately once but not repeatedly. Assert tank cooldown is at least `0.9` and separation impulse points away from the attacker.

- [ ] **Step 2: Run contact and shield scenes RED**

Expected: one overlapping enemy currently damages around every 0.52 seconds and pooled state has no cooldown contract.

- [ ] **Step 3: Implement attacker-owned cooldown and separation**

Gate the base contact callback using a monotonic per-enemy timestamp or timer reset on pooling. Clamp exported normal cooldowns to at least `0.75`; configure tanks to a longer explicit value. Start cooldown on any accepted HP or shield hit. Apply a small velocity-safe separation impulse without teleporting or granting global invulnerability.

- [ ] **Step 4: Run contact, shield, and encounter scenes GREEN**

Expected: all exit `0`; independent attackers still produce a legitimate burst.

- [ ] **Step 5: Commit**

Commit `fix: prevent contact overlap damage spam`.

### Task 9: Compatibility Sweep, Full Verification, and Android Evidence

**Files:**
- Modify only failures directly caused by Tasks 1–8.
- Modify: `tests/telemetry_report.gd`
- Update test documentation if the repository has a canonical verification list.

**Interfaces:**
- Consumes every preceding task's public interfaces.
- Produces a green native suite, import-clean Android export, and a phone test checklist tied to telemetry fields.

- [ ] **Step 1: Add legacy/current telemetry cohort test**

Feed the report one legacy run with `ascension` and one current run with `threat_protocol_level`; assert separate cohort labels, valid aggregation, and cleanup/death-sequence fields when present.

- [ ] **Step 2: Run report test RED then implement compatibility**

Expected RED: reporter currently groups only by Ascension. Update it to prefer Threat Protocol and label legacy values explicitly without rewriting old files; rerun GREEN.

- [ ] **Step 3: Run the complete native suite**

Enumerate all `tests/*_native.tscn` and other canonical project test scenes, execute each with Godot 4.7.2, save output outside tracked source, and require every exit code to be `0`. Run `tests/balance_audit.py` using the repository's Python command.

- [ ] **Step 4: Import and export Android**

Run a headless import, then the configured Android debug export. Verify no missing texture/resource errors and that the APK package/version are correct. Do not stage incidental `.import` timestamp churn unless required for new source assets.

- [ ] **Step 5: Install and perform portrait phone smoke test**

Install the APK on the already-authorized phone, then manually verify all five protocol states, skill details scrolling, every picker image class, dense stage transition, terminal-at-stage-end order, and death recap. Pull the new telemetry and confirm cleanup metrics contain multiple bounded batches with no conspicuous final-frame spike.

- [ ] **Step 6: Commit verification-only compatibility changes**

Commit `test: verify threat protocol polish on android`; leave generated APKs and pulled telemetry untracked/ignored.

## Completion Criteria

- All nine task commits exist and touch only scoped files.
- Every focused RED was observed before its implementation GREEN.
- Full native suite and balance audit pass under Godot 4.7.2.
- Android export installs and launches in portrait.
- Phone telemetry proves serialized terminal decisions and records cleanup metrics/death sequence.
- Final whole-branch review finds no Critical or Important issue left unresolved.
