# Brotato Run Curve Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore rising run tension and reward excitement while removing encounter stalls.

**Architecture:** Keep pacing rules in `Spawner`, derive terminal pressure through a pure build-power function, persist shop reroll pressure in `RunManager`, and add a capped per-skill overclock reward in `SkillInstance`/`EvolutionData`.

**Tech Stack:** Godot 4.7, GDScript, native headless scene tests.

**Spec:** `docs/superpowers/specs/2026-10-17-brotato-run-curve-design.md`

## Global Constraints

- Preserve Android portrait behavior and existing saves.
- Use deterministic pure functions for balance rules.
- Do not add a new currency or screen.

## Review Focus

- A single surviving enemy must not prevent the next normal pulse.
- Terminal pressure must be lower at stage 1 and higher for a strong late build.
- Terminal-only scaling must not alter normal encounter enemies.
- Reroll costs must persist across shop visits and survive save/resume.
- Overclock must cap and survive save/resume without breaking old saves.

---

### Task 1: Continuous encounter cadence

**Files:**
- Modify: `scripts/enemies/spawner.gd`
- Test: `tests/cadence_native.gd`

**Interfaces:**
- Produces: `Spawner.can_spawn_next_pulse(alive: int) -> bool`

- [ ] Add a failing test that one survivor permits another pulse while the concurrent soft cap blocks crowd overflow.
- [ ] Run `cadence_native.tscn` and confirm RED.
- [ ] Implement the soft-cap predicate and use it in `_process`.
- [ ] Run the test and commit.

### Task 2: Adaptive terminal pressure

**Files:**
- Create: `scripts/combat/run_power.gd`
- Modify: `scripts/stages/compilation_terminal.gd`
- Modify: `scripts/enemies/spawner.gd`
- Test: `tests/compilation_terminal_native.gd`

**Interfaces:**
- Produces: `RunPower.score(skills) -> float`
- Produces: `CompilationTerminal.scaled_encounter(base, depth, power) -> Dictionary`

- [ ] Add failing deterministic tests for early, baseline, and high-power late encounters plus terminal-only multipliers.
- [ ] Run the terminal test and confirm RED.
- [ ] Implement scoring, scaling, and per-terminal enemy multipliers.
- [ ] Run the test and commit.

### Task 3: Shop reroll pressure

**Files:**
- Modify: `scripts/autoloads/run_manager.gd`
- Modify: `scripts/ui/shop.gd`
- Test: `tests/shop_affinity_native.gd`

**Interfaces:**
- Produces: `RunManager.next_reroll_cost() -> int`

- [ ] Add failing tests for the persistent `2, 4, 7, 11` curve and save/resume.
- [ ] Run the shop test and confirm RED.
- [ ] Stop resetting rerolls in each shop and implement triangular escalation.
- [ ] Run the test and commit.

### Task 4: Max-tier jackpot progression

**Files:**
- Modify: `scripts/skills/skill_instance.gd`
- Modify: `scripts/combat/evolution_data.gd`
- Modify: `scripts/ui/compilation_picker.gd`
- Modify: `scripts/main/game_manager.gd`
- Test: `tests/compilation_terminal_native.gd`

**Interfaces:**
- Produces: `SkillInstance.overclock_level: int`
- Produces: `SkillInstance.grant_overclock() -> bool`

- [ ] Add failing tests for max-tier offers, capped stat growth, selection, and serialization fields.
- [ ] Run the terminal test and confirm RED.
- [ ] Implement three overclock levels, each granting `+20%` damage and `-6%` cooldown multiplicatively.
- [ ] Replace exhausted fallback slots with overclocks before using support slots.
- [ ] Run targeted and full native suites, then commit.
