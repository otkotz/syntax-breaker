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

## Design Spec

docs/superpowers/specs/2026-05-19-syntax-breaker-mvp-design.md
