# Expedition Loot and Codex Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add deterministic Expedition artifact drops, temporary loot, safe victory settlement, duplicate shards, chase pity, and a mobile Codex.

**Architecture:** Data-only loot tables feed a pure deterministic `ExpeditionLootRoller`. `ExpeditionSession` owns immutable rolled pending rewards; `ExpeditionManager` alone settles them transactionally into `ExpeditionProfile`. UI reads catalog/profile/session models without owning reward logic.

**Tech Stack:** Godot 4.6.2, typed GDScript, `.tres` resources, scene-based native headless tests, atomic JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-17-expedition-loot-codex-design.md`

## Global Constraints

- Burning Grounds only; session difficulty is fixed to `1` and schema-2 sessions migrate to `1`.
- `bloodwritten_sigil` is boss-only chase: 15% chance, guaranteed on eligible victory 5.
- Elite artifact chance 35%, treasure 65%, boss set roll 100%; entries inside each pool have equal weights.
- Victory grants 10 Ember Shards; duplicate normal/set 5, duplicate chase 15, unknown reward 3.
- Rewards are rolled once, serialized, and never rerolled on resume.
- Pending loot banks only on victory; death/abandon discards it without changing pity.
- No Expedition state may mutate `RunManager` or roguelite saves.
- Preserve unknown IDs in persisted data; runtime and UI skip missing resources safely.

## Review Focus

- A corrupted pending reward among valid rewards must be skipped without invalidating the session (Task 4 test).
- Saving the settled profile fails after rewards are calculated: live profile/session must remain unchanged (Task 5 test).
- Repeating settlement after a crash/retry must not duplicate artifacts, shards, pity, or history (Task 5 test).
- Identical reward IDs/seeds must remain deterministic without changing global RNG state (Task 2 test).
- A schema-2 owner with all artifacts must migrate without losing ownership or receiving duplicate discovery entries (Task 3 test).

---

### Task 1: Loot metadata and tables

**Files:**
- Modify: `scripts/resources/artifact_resource.gd`
- Create: `scripts/resources/loot_table_resource.gd`
- Create: `scripts/expedition/expedition_loot_catalog.gd`
- Modify: `resources/artifacts/*.tres`
- Create: `resources/expedition_loot/*.tres`
- Test: `tests/expedition_loot_catalog_native.gd`
- Create: `tests/expedition_loot_catalog_native.tscn`

**Interfaces:**
- Consumes: `ArtifactCatalog.get_artifact(id)` and the six existing resources.
- Produces: `LootTableResource`, `ExpeditionLootCatalog.get_table(id: String) -> LootTableResource`, `all_table_ids() -> Array[String]`.

- [ ] **Step 1: Write the failing catalog test** asserting the three tables (`burning_elite`, `burning_treasure`, `burning_boss_set`), equal entry weights, source tags, minimum difficulty 1, exact duplicate shard values, and Sigil chase metadata.
- [ ] **Step 2: Run `expedition_loot_catalog_native.tscn`** and verify RED because loot types/catalog do not exist.
- [ ] **Step 3: Add metadata fields and loot resources**; keep table entries plain serializable dictionaries and reject malformed/duplicate IDs in catalog access.
- [ ] **Step 4: Run the catalog test** and verify exit 0 with `failures:[]`.
- [ ] **Step 5: Commit** with `feat: define expedition loot tables`.

### Task 2: Pure deterministic roller and pity rules

**Files:**
- Create: `scripts/expedition/expedition_loot_roller.gd`
- Create: `tests/expedition_loot_roller_native.gd`
- Create: `tests/expedition_loot_roller_native.tscn`

**Interfaces:**
- Consumes: `LootTableResource` and artifact loot metadata from Task 1.
- Produces: `ExpeditionLootRoller.roll(table: LootTableResource, seed_value: int, reward_id: String, source_tag: String, difficulty: int, pity: Dictionary) -> Dictionary` and `roll_chase(...) -> Dictionary`.

- [ ] **Step 1: Write failing roller tests** for same-input determinism, unchanged global RNG sequence, source/difficulty filtering, explicit no-drop, equal-weight reachability, 15% chase outcomes, and guarantee when `pity["burning_boss_sigil"] == 4`.
- [ ] **Step 2: Add a 10,000-sequence simulation test** asserting no chase acquisition later than victory 5 and no artifact from an impossible source.
- [ ] **Step 3: Run the roller scene** and verify RED because `ExpeditionLootRoller` is missing.
- [ ] **Step 4: Implement local seeded rolling** using a stable hash of seed plus reward ID; return dictionaries shaped as `{reward_id, source_tag, artifact_ids, shard_amount, pity_key, chase_awarded}`.
- [ ] **Step 5: Run the roller and catalog tests** and verify both pass.
- [ ] **Step 6: Commit** with `feat: add deterministic expedition loot rolling`.

### Task 3: Profile schema 3, discoveries, shards and history

**Files:**
- Modify: `scripts/expedition/expedition_profile.gd`
- Modify: `scripts/autoloads/expedition_manager.gd`
- Modify: `tests/expedition_profile_native.gd`

**Interfaces:**
- Consumes: artifact catalog metadata and atomic profile storage.
- Produces: schema-3 fields `ember_shards`, `discovered_artifact_ids`, `pity_counters`, `settled_reward_ids`, `reward_history`; `ExpeditionProfile.fresh() -> ExpeditionProfile` for empty new ownership; migration through `from_dict`.

- [ ] **Step 1: Extend profile tests** for a truly fresh empty collection, schema-2 ownership/discovery migration, unknown-ID preservation, nonnegative shards/pity, deduplicated settled IDs, and history capped to newest 100 entries.
- [ ] **Step 2: Run `expedition_profile_native.tscn`** and verify RED on schema/version/defaults.
- [ ] **Step 3: Implement schema 3 and migrations**; preserve `ExpeditionProfile.new()` compatibility only where fixtures require it, while `ExpeditionManager.start_new_profile()` uses `fresh()`.
- [ ] **Step 4: Run profile, artifact-loadout, and artifact-UI tests** and verify pass.
- [ ] **Step 5: Commit** with `feat: persist expedition loot progression`.

### Task 4: Session schema 3 and one-time pending rewards

**Files:**
- Modify: `scripts/expedition/expedition_session.gd`
- Modify: `tests/expedition_session_native.gd`
- Create: `tests/expedition_pending_loot_native.gd`
- Create: `tests/expedition_pending_loot_native.tscn`

**Interfaces:**
- Consumes: roller result dictionaries from Task 2.
- Produces: schema-3 `difficulty`, `pending_rewards`, `rolled_reward_ids`; `reward_id_for(room_id: String, suffix: String = "room") -> String`; `record_reward(reward: Dictionary) -> bool`; `get_reward(reward_id: String) -> Dictionary`.

- [ ] **Step 1: Write failing tests** for difficulty migration, stable room IDs, two distinct boss suffix IDs, duplicate record rejection, roundtrip/resume identity, and one malformed reward being skipped while valid rewards survive.
- [ ] **Step 2: Run session and pending-loot scenes** and verify RED.
- [ ] **Step 3: Implement schema 3 validation and APIs**; `record_reward` accepts only nonempty unique reward IDs and serializable arrays/numbers/strings.
- [ ] **Step 4: Run session, pending-loot, generator, and flow tests** and verify pass.
- [ ] **Step 5: Commit** with `feat: checkpoint expedition pending loot`.

### Task 5: Transactional and idempotent settlement

**Files:**
- Create: `scripts/expedition/expedition_reward_settlement.gd`
- Modify: `scripts/autoloads/expedition_manager.gd`
- Create: `tests/expedition_reward_settlement_native.gd`
- Create: `tests/expedition_reward_settlement_native.tscn`
- Modify: `tests/expedition_profile_native.gd`

**Interfaces:**
- Consumes: schema-3 profile/session and artifact metadata.
- Produces: `ExpeditionRewardSettlement.apply(profile: ExpeditionProfile, rewards: Array[Dictionary]) -> ExpeditionProfile`; `ExpeditionManager.settle_victory() -> bool`.

- [ ] **Step 1: Write failing pure-settlement tests** for new ownership/discovery, 5/15/3 duplicate conversions, +10 victory shards, pity increment/reset, newest-100 history, unknown reward history, and repeated reward IDs having no effect.
- [ ] **Step 2: Write failing manager tests** proving failed profile save leaves both live profile and session unchanged, successful save clears session only afterward, and retry cannot double-award.
- [ ] **Step 3: Run settlement tests** and verify RED.
- [ ] **Step 4: Implement copy-on-write settlement** and make manager replace its live profile only after atomic save succeeds; clear session after success.
- [ ] **Step 5: Run settlement, profile, session, run-integrity, and artifact-loadout tests** and verify pass.
- [ ] **Step 6: Commit** with `feat: settle expedition rewards safely`.

### Task 6: Room reward flow and reward overlay

**Files:**
- Modify: `scripts/expedition/expedition_game_manager.gd`
- Create: `scripts/ui/expedition_reward_overlay.gd`
- Create: `scenes/ui/expedition_reward_overlay.tscn`
- Modify: `tests/expedition_flow_native.gd`
- Create: `tests/expedition_loot_flow_native.gd`
- Create: `tests/expedition_loot_flow_native.tscn`

**Interfaces:**
- Consumes: catalog/roller/session APIs and `settle_victory()`.
- Produces: one-time reward roll/checkpoint after eligible room completion and a read-only overlay confirmation signal.

- [ ] **Step 1: Write failing flow tests** for no combat-room artifact, elite/treasure one-time stored rolls, resume reuse, boss `:boss_set` plus `:boss_chase`, navigation blocked on failed checkpoint, victory settlement, and death/abandon pending-loot loss without pity change.
- [ ] **Step 2: Run loot-flow scene** and verify RED.
- [ ] **Step 3: Implement room-source routing and checkpoint order**: roll → `record_reward` → save session → show overlay → unlock navigation; boss settles after both stored outcomes.
- [ ] **Step 4: Implement the mobile overlay** with artifact name/icon or shard/no-drop result and a minimum 48 px confirmation target.
- [ ] **Step 5: Run loot-flow, expedition-flow, session, node-routes, damage, and run-integrity scenes** and verify pass.
- [ ] **Step 6: Commit** with `feat: award expedition room loot`.

### Task 7: Mobile Codex

**Files:**
- Create: `scripts/ui/expedition_codex.gd`
- Create: `scenes/ui/expedition_codex.tscn`
- Modify: `scripts/ui/expedition_hub.gd`
- Modify: `scenes/ui/expedition_hub.tscn`
- Create: `tests/expedition_codex_native.gd`
- Create: `tests/expedition_codex_native.tscn`

**Interfaces:**
- Consumes: `ArtifactCatalog`, profile discoveries/ownership/pity, and resource loot metadata.
- Produces: read-only Codex with `All`, `Owned`, `Missing`, `Burning Grounds` filters and detail view.

- [ ] **Step 1: Write failing UI tests** asserting six stable cards, filter results, hidden descriptions for unknowns, visible source category, exact discovered source/effect, `4/5` chase pity display, set membership, back navigation, and ≥48 px touch targets.
- [ ] **Step 2: Run Codex test** and verify RED.
- [ ] **Step 3: Build the portrait Codex scene/controller**; skip missing resources without crashing and keep equip actions exclusively in artifact loadout UI.
- [ ] **Step 4: Add the hub entry button** without changing active-session lock behavior.
- [ ] **Step 5: Run Codex, artifact-UI, expedition-flow, and touch-control tests** and verify pass.
- [ ] **Step 6: Commit** with `feat: add expedition artifact codex`.

### Task 8: Integration, isolation and documentation

**Files:**
- Modify: `tests/expedition_flow_native.gd`
- Modify: `tests/run_integrity.gd`
- Modify: `docs/design-overview.md`
- Create: `docs/progress-2026-10-17.md`

**Interfaces:**
- Consumes: Tasks 1–7.
- Produces: verified complete loot vertical slice and documented deferred XP/progression work.

- [ ] **Step 1: Extend the real-arena test** through elite/treasure/boss, save/resume, overlay, settlement, Codex discovery and equip availability.
- [ ] **Step 2: Extend isolation tests** to snapshot every roguelite field before and after Expedition rewards, death, victory, Codex use, and return to roguelite.
- [ ] **Step 3: Run new tests RED if either integration path is not yet wired**, then make only the missing integration corrections.
- [ ] **Step 4: Update documentation** with source pools, exact economy/pity, schema 3, settlement ordering, and explicit deferral of XP/board/campaign expansion.
- [ ] **Step 5: Run editor smoke and every native regression scene**; require exit 0, `failures:[]`, and no script/parse/resource/ObjectDB/RID leak errors. Restore only generated `assets/**/*.import` changes.
- [ ] **Step 6: Request whole-branch review** focused on save atomicity, reroll/idempotency, pity off-by-one errors, source eligibility, UI lock/resume, and roguelite isolation; fix all Critical/Important findings and rerun the suite.
- [ ] **Step 7: Commit** with `test: verify expedition loot and codex`.

---

## Completion Gate

The work is complete only when a fresh profile can earn deterministic temporary loot, resume without
rerolls, lose pending rewards on failure, bank artifacts/shards exactly once on victory, receive the
chase no later than eligible victory five, inspect discovery/source/pity in the Codex, and return to
an unchanged roguelite state with the full native suite green.
