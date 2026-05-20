# Syntax Breaker — Solo Dev Migration Roadmap

Created: 2026-05-19

## Overview

Transform the existing working prototype into a scalable stage-based roguelite.
Inspired by Path of Exile, The Binding of Isaac, and Brotato.
Core fantasy: the player progressively "breaks the system" through insane build synergies.

---

## PHASE 1 — Prototype Stabilization (1-2 weeks)

Goal: Fix gaps that will bite in Phase 2-4. Don't overengineer.

- [x] 1.1 Enemy pooling (spawner pools enemies by scene, recycles on death)
- [x] 1.2 Extract `_draw_body()` override point so subclasses don't lose health bars
- [x] 1.3 Centralize balance constants into `GameBalance` resource
- [x] 1.4 Clean up dead wave signals in spawner + GameBus
- [x] 1.5 Add screen shake + hit stop (CameraShake + arena hit_stop)

DO NOT: refactor to scenes/components, add unit tests for gameplay, create more singletons.

---

## PHASE 2 — Skill Tag System Expansion (2-3 weeks)

Goal: Make supports feel meaningfully different through tag interactions.

- [x] 2.1 Tag-driven visual differentiation (TagColors — fire=orange, lightning=blue, poison=green)
- [x] 2.2 Tag interaction rules (fire+poison=ignite burst, lightning=arc, poison+burn=toxic cloud)
- [x] 2.3 Support stacking rules (additive multipliers with diminishing returns, stat caps)
- [x] 2.4 Negative/tradeoff supports (Glass Cannon, Shotgun, Overcharge)

DO NOT: build visual node graph, add >12 supports, create skills that bypass tags.

---

## PHASE 3 — Stage Structure & Progression (2-3 weeks)

Goal: Make each run feel like a journey with meaningful choices.

- [x] 3.1 Stage map (pick between 2-3 next stages: combat/elite/shop/treasure/boss)
- [x] 3.2 Stage modifiers (enemy buffs/debuffs per stage)
- [x] 3.3 Elite encounters (fewer but harder enemies with abilities)
- [x] 3.4 Reward variety (skill/support/passive/gold picks after clear)
- [x] 3.5 Difficulty scaling curve

DO NOT: procedural generation, environmental hazards, more than 1 boss, minimap.

---

## PHASE 4 — Build Identity & "Breaking the System" (3-4 weeks)

Goal: Create viral clip moments through emergent synergies.

- [x] 4.1 Keystone supports (Spell Echo, Totems, Mines, Cast on Kill, Void Rift)
- [x] 4.2 Mutation system (permanent skill modifications after boss stages)
- [x] 4.3 Synergy triggers (Overload, Shatter, Frostblight cross-element combos)
- [x] 4.4 Escalation curve (+5% damage/stage, combo multiplier up to 2x)
- [x] 4.5 Kill combo counter, damage number scaling

DO NOT: balance for PvP, prevent broken builds, add >5 keystones initially.

---

## PHASE 5 — Meta Progression (2-3 weeks)

Goal: Unlock possibilities, never raw power.

- [ ] 5.1 Unlock tree visualization
- [ ] 5.2 Region system (Burning Grounds, Storm Spire, Toxic Depths)
- [ ] 5.3 Ascension system (endgame difficulty scaling)
- [ ] 5.4 Persistent codex (collection tracking)
- [ ] 5.5 Run save/resume for mobile

DO NOT: premium currency, >5 runs per unlock, gate core mechanics.

---

## PHASE 6 — Performance & Mobile Optimization (2 weeks)

Goal: 60fps during craziest builds on mid-range Android.

- [ ] 6.1 Pool all frequently-created objects
- [ ] 6.2 Replace `_draw()` with sprite atlas
- [ ] 6.3 Spatial partitioning for targeting
- [ ] 6.4 Hard cap active projectiles (50-80)
- [ ] 6.5 Reduce physics bodies for stationary enemies
- [ ] 6.6 VFX budget (pool damage numbers, shared hit shader)
- [ ] 6.7 Low-end Android fallbacks (720p, reduced entities)

---

## PHASE 7 — First Public Demo (1-2 weeks)

Goal: 50-100 real players testing the core loop.

Minimum content: 3 skills, 5 supports, 3 passives, 8 stages/run, 1 boss, 1 region.
Run length: 10-12 minutes.

---

## Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| 1 — Stabilization | 1-2 weeks | 2 weeks |
| 2 — Tag expansion | 2-3 weeks | 5 weeks |
| 3 — Stage structure | 2-3 weeks | 8 weeks |
| 4 — Build identity | 3-4 weeks | 12 weeks |
| 5 — Meta progression | 2-3 weeks | 15 weeks |
| 6 — Mobile optimization | 2 weeks | 17 weeks |
| 7 — Demo | 1-2 weeks | 19 weeks |

TEST WITH PLAYERS AFTER PHASE 4. Don't wait for Phase 7.
