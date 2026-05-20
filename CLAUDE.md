# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Syntax Breaker — 2D top-down roguelite built in Godot 4.4+ / GDScript. Mobile-first (portrait 1080×1920), auto-aim combat, tag-based skill/support system inspired by Path of Exile.

## Architecture

Resource-driven: skills, supports, and passives are .tres data files (scripts in scripts/resources/). Scenes in scenes/ handle visuals/physics. At runtime, SkillInstance (scripts/skills/skill_instance.gd) composes a skill resource + linked supports into computed stats and behaviors.

Five autoload singletons: GameBus (signals), RunManager (run state), InputManager (touch abstraction), BehaviorRegistry (support behaviors), MetaProgression (unlocks/save).

Support behaviors implement the interface in scripts/behaviors/behavior_base.gd: modify_spawn(), on_hit(), on_kill(), modify_stats().

## Adding Content

- New skill: create 1 .tres in resources/skills/ + 1 .tscn in scenes/skills/
- New support (stat-only): create 1 .tres in resources/supports/
- New support (with behavior): create 1 .tres + 1 .gd in scripts/behaviors/, register key in behavior_registry.gd

## Commands

- Run tests: open Godot editor → GUT panel → Run All
- Run single test: GUT panel → select test script → Run
- Run project: F5 in Godot editor, or `godot --path . scenes/main/main.tscn`

## Implementation Plan

docs/superpowers/plans/2026-05-19-syntax-breaker-mvp.md — 19 tasks total.

### Progress

- [x] Task 1: Project scaffold & Godot config
- [x] Task 2: Resource scripts (skill, support, passive, unlock)
- [x] Task 3: TagMatcher & StatCalculator + tests
- [x] Task 4: Behavior system (base + pierce)
- [x] Task 5: Object pool
- [x] Task 6: Input system & virtual joystick
- [x] Task 7: Player character
- [x] Task 8: Skill runtime (SkillInstance, SkillCaster, Targeting)
- [x] Task 9: Fireball — first complete skill
- [x] Task 10: Base enemy & wave spawner
- [x] Task 11: Arena stage & game loop
- [x] Task 12: HUD (HP, gold, stage label)
- [x] Task 13: All 6 MVP skills
- [x] Task 14: Support behaviors, passives, DoT system
- [x] Task 15: Enemy variants — basic ranged & mini-boss
- [x] Task 16: Gold, drops & shop UI
- [x] Task 17: Skill manager UI (support linking)
- [x] Task 18: Meta-progression — unlock checking
- [x] Task 19: Main menu, run summary & full integration

## Migration Roadmap

docs/superpowers/plans/2026-05-19-migration-roadmap.md — Post-MVP phases.

### Post-MVP Progress

- [x] Phase 1: Prototype stabilization (pooling, health bars, balance, screen shake)
- [x] Phase 2: Tag system expansion (visual colors, interactions, tradeoff supports)
- [x] Phase 3: Stage structure & progression (stage map, modifiers, elites, rewards)
- [x] Phase 4: Build identity (keystones, mutations, synergies, combos)
- [x] Phase 5: Meta progression (ascension, regions, codex, save/resume, unlock tree)
- [ ] Phase 6: Performance & mobile optimization
- [ ] Phase 7: First public demo

## Design Spec

docs/superpowers/specs/2026-05-19-syntax-breaker-mvp-design.md
