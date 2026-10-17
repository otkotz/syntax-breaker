# Syntax Breaker — Expedition loot, duplicates, pity and Codex

**Date:** 2026-10-17  
**Status:** approved by delegated product decision; ready for implementation planning

## Intent

Add the first persistent reward loop to Expedition: the player chooses a route, earns deterministic
room rewards, carries them as temporary loot, and banks them only after defeating the boss. The
system must make targeted farming understandable, protect against bad luck, and keep Expedition
state completely separate from roguelite progression.

## Scope

This slice covers Burning Grounds and the existing six artifacts. It adds loot-table data, a pure
loot roller, temporary session rewards, atomic/idempotent settlement, duplicate conversion, one
regional material, one boss chase item, pity tracking, and a mobile Codex screen.

It does not add XP, the progression board, more regions, artifact affixes/levels, crafting, special
expedition entry costs, or Fractured Realms.

## Product decisions

- `bloodwritten_sigil` is the first chase item and drops only from the Burning Grounds boss.
- Boss pity guarantees it on the fifth eligible boss victory without receiving it earlier.
- In this slice every Burning Grounds boss victory at difficulty 1 is eligible. Difficulty is fixed
  to `1`; schema-2 sessions migrate to `1`, and no difficulty selector is added yet.
- Pity increments only after an eligible successful boss settlement and resets only when the chase
  item is awarded. Death, abandon, save/reload, and duplicate drops do not reset it.
- `furnace_heart`, `ashen_needle`, and `cinder_crown` form the regional boss/set pool.
- `fractured_prism` and `echoing_hourglass` form the elite/treasure discovery pool.
- Elite and treasure rooms award at most one artifact roll. The boss awards one set-pool roll plus
  the independent chase roll.
- Every completed Expedition awards Ember Shards; duplicate artifacts automatically convert to
  additional Ember Shards. There is no manual salvage screen in this slice.
- Loot is rolled exactly once per room using a stable reward ID derived from session and room. The
  serialized result is stored in the session; resume never rerolls it.
- Temporary loot is banked only by successful boss completion. Death or abandonment discards it.
- Existing owners start with all six artifacts for migration compatibility, but a newly created
  profile starts with no artifacts. Tests and debug fixtures may explicitly seed ownership.
- The Codex lists all six artifacts. Discovered entries show full effect and exact source; unknown
  entries show silhouette/name placeholder, source category, and visible pity progress for the
  chase item. This keeps farming intentional without revealing every description immediately.

## Data model

`ArtifactResource` gains stable loot metadata: `source_tags`, `minimum_difficulty`, `is_chase`, and
`duplicate_shard_value`. Existing resources declare their Burning Grounds sources explicitly.

`LootTableResource` contains an ID and weighted entries. Each entry names an artifact ID, weight,
source tag, minimum difficulty, and optional pity key. Tables are data-only resources.

`ExpeditionProfile` schema 3 adds:

- `ember_shards: int`;
- `discovered_artifact_ids: Array[String]`;
- `pity_counters: Dictionary` keyed by stable pity key;
- `settled_reward_ids: Array[String]` for idempotency.
- `reward_history: Array[Dictionary]`, capped to the newest 100 settlements, retaining reward ID,
  source and rolled artifact IDs even when a resource is unknown.

Schema 1–2 migration preserves existing ownership and marks owned known artifacts discovered.
Fresh schema-3 profiles start empty. Unknown IDs remain preserved in ownership/discovery data and
are ignored by runtime/UI when no resource exists.

`ExpeditionSession` schema 3 adds serialized `pending_rewards`, `rolled_reward_ids`, and
`difficulty`. A pending reward stores stable reward ID, source, artifact IDs, and shard amount.
Malformed entries are skipped individually; valid entries still load.

## Loot rolling

`LootRoller` is a pure service. Given table, seed, source tag, difficulty, owned IDs, and pity
snapshot, it returns a serializable reward without modifying profile/session/global RNG. A local
seed combines expedition seed and stable reward ID, so repeated calls produce the same result.

Rules:

1. Filter entries by source and difficulty.
2. If the relevant chase pity is at guarantee threshold, return the chase item.
3. Otherwise perform a deterministic weighted roll; a no-drop outcome is explicit where allowed.
4. Return artifact IDs, not ownership/material decisions. Duplicate conversion happens only during
   settlement, so temporary UI can still say which artifact was found.

The first tuning values are intentionally simple: elite 35% artifact chance, treasure 65%, boss
set roll 100%, chase 15% with guarantee on eligible victory 5. Entries inside the three-item set
pool and two-item discovery pool have equal weights. All six artifacts have minimum difficulty 1.
Victory grants 10 Ember Shards. A duplicate normal or set artifact grants 5, a duplicate chase item
grants 15, and an unknown artifact reward grants 3.

## Room rewards and resume

After a room is completed, `ExpeditionGameManager` asks the session for its stable reward ID. If it
has already been rolled, the stored pending reward is reused. Otherwise the manager invokes the
roller, appends the result, saves the session atomically, then presents a compact reward overlay.
Navigation unlocks only after that checkpoint succeeds.

Combat rooms do not roll artifacts. Elite and treasure rooms use their tables. The boss creates two
separate pending rewards before settlement, using stable suffixes `:boss_set` and `:boss_chase`,
stores both, then settles the whole expedition. This keeps reroll prevention and pity bookkeeping
independent while allowing the overlay to present both together.

## Settlement and failure safety

`ExpeditionManager.settle_victory()` applies every pending reward to a copy of the profile:

- new known artifact: add to ownership and discovery;
- duplicate known artifact: convert to its configured shard value;
- unknown artifact: convert to a conservative default shard value and preserve the reward record;
- base completion shards: add once;
- update chase pity from the stored boss outcome;
- record each stable reward ID.

The copied profile is written atomically before the session is cleared. If saving fails, neither the
live profile nor session is mutated. Retrying is safe because settled IDs prevent double awards.
After successful profile save, the active session files are removed.

Death/abandonment clears only the session and pending loot. It never changes pity or permanent
inventory.

## Codex UI

The Expedition hub gains a `Codex` button and a dedicated portrait screen. The screen uses large
filter chips (`All`, `Owned`, `Missing`, `Burning Grounds`) and vertically scrolling cards. Each card
shows icon/silhouette, discovery state, set membership, exact or general source, and chase pity.
Selecting a discovered card opens its full description and set thresholds. The screen is read-only;
equipping remains in the artifact loadout screen.

## Isolation and compatibility

Loot code may read `ArtifactCatalog` but never `RunManager`. No Expedition artifacts, shards, pity,
or discoveries enter roguelite saves. Artifact runtime continues to ignore unknown IDs safely.
Existing schema-2 profiles remain playable and retain their current all-artifact ownership.

## Verification

Native tests cover deterministic rolls, source/difficulty filters, weighted/no-drop boundaries,
fifth-win pity, no pity change on death, duplicate conversion, schema migration, corrupt-entry
recovery, reward persistence across resume, idempotent settlement, failed-save rollback, Codex
visibility/filtering/touch targets, real elite/treasure/boss flow, and roguelite isolation.

A simulation runs at least 10,000 deterministic reward sequences and verifies chase acquisition by
the fifth eligible victory, no impossible sources, and stable results for identical inputs. Final
verification includes all existing Expedition and shared combat/save tests plus editor smoke and
log scanning for script/resource/leak errors.

## Completion gate

The slice is complete when a fresh profile can finish an Expedition, see stored room rewards survive
resume, bank new artifacts/shards only after victory, lose pending loot on death, observe chase pity
advance and guarantee correctly, inspect sources/progress in the Codex, and return to roguelite with
its save and runtime unchanged.
