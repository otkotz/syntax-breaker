# Threat Protocol and Run-Flow Polish Design

**Date:** 2026-10-11
**Status:** Approved in conversation; awaiting written-spec review

## Intent

Make build decisions understandable on a portrait phone, replace the opaque twenty-step Ascension ladder with five memorable pre-run difficulty modes, and remove the run-flow defects visible in phone telemetry. The result should preserve the game's memetic computer theme while making increased difficulty an explicit risk/reward choice.

Success means:

- tapping an active skill explains what it does, what its rarity changes, and what every evolution tier does;
- every selectable reward card displays relevant artwork;
- ending a dense stage no longer produces a conspicuous single-frame cleanup hitch;
- terminal, stage reward, mutation, legendary reward, and map screens cannot replace one another;
- defeat explains the burst that killed the player rather than naming only the final hit;
- one enemy cannot repeatedly apply contact damage every half second while overlapping the player;
- players choose one of five clearly differentiated Threat Protocols before a run, with higher modes unlocking per region after victories.

## Scope

This package changes the skill manager, choice-card artwork, stage cleanup, post-stage UI sequencing, death telemetry/summary, repeated contact damage, and meta difficulty selection. It does not rebalance individual skills from the two current-build test runs, redesign combat controls, add new regions, or turn difficulty into an in-run reward.

## 1. Threat Protocol

### Player-facing model

Ascension is replaced in the interface by five named protocols selected before starting a run:

| Level | Name | Enemy HP | Damage | Speed | Spawn budget | Reward quality | Gold | Special rule |
|---:|---|---:|---:|---:|---:|---:|---:|---|
| 0 | NORMAL | +0% | +0% | +0% | +0% | +0 | x1.00 | none |
| 1 | OVERCLOCKED | +15% | +8% | +3% | +12% | +5 luck | x1.08 | none |
| 2 | CORRUPTED | +30% | +18% | +6% | +25% | +10 luck | x1.18 | elite patrol from depth 2 |
| 3 | SYSTEM FAILURE | +55% | +32% | +10% | +40% | +18 luck | x1.32 | elite patrol and denial reinforcement |
| 4 | NO WARRANTY | +85% | +50% | +15% | +60% | +28 luck | x1.50 | elite patrol, denial and shield reinforcements |

Reward quality is implemented through the existing luck-based rarity roll, not a separate rarity system. Spawn budget affects normal encounter population; role caps, boss caps, and performance entity caps remain authoritative. Gold is a positive multiplier, replacing Ascension's current gold penalty.

The menu shows the selected name, exact modifiers, reward upside, and special rules. Locked protocols remain visible with a lock state and the requirement “Win [previous protocol] in this region.” Arrow controls cycle only through unlocked protocols.

### Unlocking and persistence

- NORMAL is always unlocked.
- Winning a region on the highest currently unlocked protocol unlocks the next protocol for that region only.
- Selecting a protocol never mutates the active run until the run starts.
- Save data uses `threat_protocol_level` and `highest_threat_protocol_unlocked`.
- Compatibility aliases may remain internally for one migration release, but new UI, telemetry, and saves use Threat Protocol terminology.

### Save migration

Legacy per-region Ascension progress maps monotonically:

- Ascension 0 -> NORMAL
- Ascension 1–4 -> OVERCLOCKED
- Ascension 5–9 -> CORRUPTED
- Ascension 10–14 -> SYSTEM FAILURE
- Ascension 15–20 -> NO WARRANTY

The selected legacy Ascension value is mapped with the same bands and clamped to the migrated regional unlock. Migration is idempotent: once Threat Protocol keys exist, legacy fields cannot overwrite them.

### Challenges and telemetry

Challenge records store `threat_protocol` instead of `ascension`. Run telemetry metadata records both the numeric level and stable protocol ID. Historical telemetry remains readable; the report tool labels legacy cohorts separately instead of silently combining them.

## 2. Skill Manager Details

The whole skill card header becomes a touch target. Tapping it opens the existing bottom drawer in read-only detail mode; support sockets retain their current linking behavior.

The detail drawer contains:

1. skill art, name, rarity, and tags;
2. plain-language base description;
3. current computed damage, cooldown, range, projectile count/pierce when applicable, and estimated DPS;
4. rarity explanation showing the current multiplier and the exact effect of Common through Legendary;
5. the skill's evolution name and tier I, II, and III descriptions;
6. a clear marker on the currently owned evolution tier;
7. linked supports with their descriptions.

Evolution descriptions live in central data owned by `EvolutionData`, not duplicated in UI code. Each tier description must describe observable behavior rather than “stronger effect.” Skills without an evolution show a neutral “No evolution available” state.

## 3. Artwork Completeness

Every interactive option in starter, normal reward, treasure/chest, mutation, legendary, terminal-evolution, target-selection, and shop flows displays an image.

Rules:

- skills, supports, and passives use their resource icon;
- mastery passives continue sharing the matching support art with a mastery badge;
- mutations receive dedicated icon metadata and assets;
- each evolution receives dedicated art shared across its three tiers, with a tier badge;
- Hot Socket and any other system/fallback offer receive dedicated system art;
- a deliberate generic fallback texture is always available if malformed content lacks an icon, so no card renders as an empty text-only option.

Automated coverage enumerates all offer-producing content and fails when an option cannot resolve artwork. The existing user-owned `.import` changes are preserved and not used as source-of-truth edits.

## 4. Hitch-Free Stage Completion

The current spawner releases every active enemy, pooled object, and hazard synchronously before emitting completion. Dense stages can therefore create a visible end-of-stage hitch.

Stage completion becomes a short state machine:

1. immediately stop spawning, split requests, AI updates, attacks, and player damage;
2. emit a lightweight “combat finished” state for HUD/audio feedback;
3. detach or deactivate active combat objects immediately so they cannot affect gameplay;
4. release enemies, pool contents, projectiles, and hazards in bounded batches across process frames;
5. emit `all_waves_cleared` only after cleanup completes, then transition to queued post-stage choices.

The cleanup budget is measured by count and elapsed microseconds, with a conservative mobile default. Tests verify that no batch exceeds the configured object limit and that completion emits once. Telemetry records cleanup duration, objects released, batch count, and worst batch time so future phone runs can distinguish cleanup cost from UI cost.

## 5. Serialized Post-Stage Decisions

Only one modal decision may be active. `GameManager` owns a FIFO queue of decision requests. Terminal evolution is queued when earned; it cannot instantiate its picker directly over a stage reward.

Default priority after combat is:

1. pending terminal evolution;
2. boss mutation and legendary reward, where applicable;
3. normal/elite/boss stage reward;
4. stage map.

Completing or explicitly canceling one decision advances the queue on the next frame. Tree exit caused by teardown is not treated as a player cancellation. Telemetry opens a decision only when its modal becomes active and records a cancellation only for an explicit user action. This prevents the observed loss of Cloud Outage III when terminal completion coincided with stage completion.

## 6. Death Context

`RunManager` maintains a bounded ring buffer of the latest five accepted player-damage events. Each entry stores relative time, source, attacker role, HP damage, shield absorbed, and HP remaining. Rejected hits and zero-effect events do not displace real damage unless they absorbed shield.

On defeat, the summary displays:

- “Final blow” for the lethal source;
- a compact chronological “Last hits” list for the final burst;
- total damage and shield absorbed in that burst.

The existing `death_source` field remains for compatibility. Telemetry adds `death_sequence` so reports can distinguish the final projectile from preceding tank contacts.

## 7. Repeated Contact Damage

Contact damage uses a per-attacker/per-player cooldown rather than depending only on continuous overlap callbacks. The default cooldown is 0.9 seconds. Heavy enemies may specify a longer value; no normal enemy may specify less than 0.75 seconds. A successful contact hit adds a small separation impulse when safe to do so.

The rule does not provide global invulnerability: separate attackers can still hit independently. Shield-only hits count as contact hits and start the cooldown. Tests cover repeated overlap, two independent enemies, shield absorption, deactivation/reactivation, and pooled-enemy state reset.

## 8. Error Handling and Compatibility

- Missing artwork resolves to the fallback texture and logs one content warning.
- Missing evolution description renders a safe placeholder in development and fails content-validation tests.
- Corrupt protocol values clamp to the highest unlocked valid level.
- An interrupted post-stage queue is discarded when leaving or ending a run.
- Loading an old in-progress run maps its Ascension level to Threat Protocol without changing the rest of the build.
- Cleanup continues safely if nodes are freed externally during batching.

## 9. Verification

Automated native tests cover:

- protocol scaling, unlock progression, regional independence, migration, persistence, and menu preview;
- skill-detail drawer content, touch targets, rarity table, and all evolution-tier descriptions;
- artwork resolution for every selectable option and fallback behavior;
- bounded cleanup batches, single completion emission, and inactive combat during cleanup;
- FIFO modal order and the exact terminal-at-stage-end regression;
- five-hit death history and final-blow compatibility;
- contact cooldown semantics and pool reset;
- existing run save/resume and telemetry report compatibility.

Manual portrait-phone verification covers text wrapping, drawer scrolling, locked-protocol readability, every picker type, perceived end-stage smoothness on a dense late stage, and a terminal completion coinciding with the stage timer.

## 10. Delivery Order

Implementation should proceed in independently testable slices: Threat Protocol data/migration, menu and runtime scaling, skill details, artwork resolution/assets, decision serialization, batched cleanup, death context/contact cooldown, then full phone validation. Existing unrelated worktree changes must remain untouched.
