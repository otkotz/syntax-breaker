"""Static balance audit against the resource data and GDScript stat rules.

Run: python tests/balance_audit.py

This enumerates every legal support loadout (0..max_supports) for every skill,
crossed with every currently relevant single passive and every applicable
single mutation. It also checks passive pairs and mutation pairs on each skill.
The output is a stat audit, not a claim that a build wins a live run: hit rate,
enemy movement, DoT, triggered effects, area coverage, and survival are not
simulated here.
"""

from __future__ import annotations

import ast
import argparse
import itertools
import json
import math
import re
import statistics
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _literal(source: str, marker: str, left: str, right: str):
    start = source.index(marker) + len(marker)
    start = source.index(left, start)
    depth = 0
    quoted = False
    escaped = False
    for pos in range(start, len(source)):
        char = source[pos]
        if escaped:
            escaped = False
            continue
        if char == "\\" and quoted:
            escaped = True
            continue
        if char == '"':
            quoted = not quoted
            continue
        if quoted:
            continue
        if char == left:
            depth += 1
        elif char == right:
            depth -= 1
            if depth == 0:
                return ast.literal_eval(source[start:pos + 1])
    raise ValueError(f"Unclosed literal after {marker}")


STAT_SOURCE = (ROOT / "scripts/util/stat_calculator.gd").read_text(encoding="utf-8")
STAT_MINS = _literal(STAT_SOURCE, "const STAT_MINS :=", "{", "}")
STAT_MAXS = _literal(STAT_SOURCE, "const STAT_MAXS :=", "{", "}")


def _value(raw: str):
    if raw.startswith("Array[String]("):
        raw = raw[len("Array[String]("):-1]
    return ast.literal_eval(raw)


def _resources(kind: str) -> list[dict]:
    result = []
    for path in sorted((ROOT / "resources" / kind).glob("*.tres")):
        assert not path.read_bytes().startswith(b"\xef\xbb\xbf"), f"Godot cannot load UTF-8 BOM: {path}"
        body = path.read_text(encoding="utf-8").split("[resource]", 1)[1]
        item = {"path": str(path.relative_to(ROOT))}
        for line in body.splitlines():
            if " = " not in line:
                continue
            key, raw = line.split(" = ", 1)
            if key in {"id", "name", "rarity", "behavior_key", "tags",
                       "item_type", "item_id",
                       "required_tags", "excluded_tags", "added_tags",
                       "affected_tags", "stat_modifiers", "base_damage",
                       "base_cooldown", "base_speed", "base_range",
                       "base_pierce", "base_projectile_count", "max_supports"}:
                item[key] = _value(raw)
        result.append(item)
    return result


def _can_link(skill: dict, support: dict) -> bool:
    tags = set(skill["tags"])
    return not tags.intersection(support.get("excluded_tags", [])) and (
        not support.get("required_tags") or bool(tags.intersection(support["required_tags"]))
    )


def _legal_support_loadout(loadout: tuple[dict, ...]) -> bool:
    ids = {support["id"] for support in loadout}
    mine_incompatible = {"chain", "pierce", "returning", "ricochet_amplifier", "shotgun", "split"}
    return (
        len(ids.intersection({"mine", "totem", "spell_echo"})) <= 1
        and not ("mine" in ids and ids.intersection(mine_incompatible))
    )


def _relevant(skill: dict, supports: tuple[dict, ...], passive: dict) -> bool:
    pid = passive["id"]
    if pid.endswith("_mastery") and not passive.get("affected_tags"):
        return any(s["id"] == pid.removesuffix("_mastery") for s in supports)
    if pid == "arcane_tempo":
        return False  # Requires at least two equipped skills.
    tags = passive.get("affected_tags", [])
    return not tags or bool(set(tags).intersection(skill["tags"]))


def _can_mutate(skill: dict, mutation: dict, supports: tuple[dict, ...] = ()) -> bool:
    ids = {support["id"] for support in supports}
    mutation_id = mutation["id"]
    if mutation_id in {"piercing", "scatter"}:
        return "projectile" in skill["tags"] and "mine" not in ids
    if mutation_id == "concentrated":
        return "aoe" in skill["tags"]
    if mutation_id == "close_quarters":
        return bool({"projectile", "melee"}.intersection(skill["tags"]))
    return True


def _collect(stats: dict, mult_totals: dict, modifiers: dict) -> None:
    for key, value in modifiers.items():
        if key.endswith("_mult"):
            base = key[:-5]
            mult_totals[base] += value - 1.0
        elif key.endswith("_add"):
            base = key[:-4]
            if base in stats:
                stats[base] += value
        elif key in stats:
            stats[key] += value


def compute(skill: dict, supports: tuple[dict, ...], passives: tuple[dict, ...],
            mutation: dict | None, masteries: dict, rarity_damage: dict) -> dict:
    stats = {
        "damage": skill.get("base_damage", 10.0),
        "cooldown": skill.get("base_cooldown", 1.0),
        "speed": skill.get("base_speed", 300.0),
        "range": skill.get("base_range", 400.0),
        "pierce": skill.get("base_pierce", 0),
        "projectile_count": skill.get("base_projectile_count", 1),
        "area_mult": 1.0, "chain_count": 0, "split_count": 0,
        "crit_chance": 0.05, "crit_mult": 1.5, "echo_count": 0,
        "is_totem": 0, "is_mine": 0,
    }
    totals = defaultdict(float)
    passive_ids = {p["id"] for p in passives}
    for support in supports:
        _collect(stats, totals, support.get("stat_modifiers", {}))
        if support["id"] + "_mastery" in passive_ids:
            _collect(stats, totals, masteries.get(support["id"], {}))
    for passive in passives:
        if not _relevant(skill, supports, passive):
            continue
        modifiers = passive.get("stat_modifiers", {})
        if passive["id"] == "swift_feet":
            modifiers = {k: v for k, v in modifiers.items() if k != "speed_mult"}
        _collect(stats, totals, modifiers)
    for key, bonus in totals.items():
        if key in stats:
            stats[key] *= 1.0 + bonus
    for key, minimum in STAT_MINS.items():
        stats[key] = max(stats[key], minimum)
    for key, maximum in STAT_MAXS.items():
        stats[key] = min(stats[key], maximum)
    stats["damage"] *= rarity_damage[skill.get("rarity", "common")]
    if mutation:
        for key, value in mutation["stats"].items():
            if key.endswith("_mult"):
                base = key[:-5]
                if base in stats:
                    stats[base] *= value
            elif key.endswith("_add"):
                base = key[:-4]
                if base in stats:
                    stats[base] += value
            elif key in stats:
                stats[key] += value
    for key, minimum in STAT_MINS.items():
        stats[key] = max(stats[key], minimum)
    for key, maximum in STAT_MAXS.items():
        stats[key] = min(stats[key], maximum)
    return stats


def _direct_proxy(skill: dict, stats: dict) -> float:
    """Expected direct damage per second at 100% hit rate; excludes effects."""
    crit = max(0.0, min(0.8, stats["crit_chance"]))
    per_hit = stats["damage"] * (1.0 + crit * (stats["crit_mult"] - 1.0))
    if stats["is_totem"]:
        return per_hit * stats["projectile_count"] * 2.0 / stats["cooldown"]
    if stats["is_mine"]:
        return per_hit * 1.5 / stats["cooldown"]
    projectiles = stats["projectile_count"] if "projectile" in skill["tags"] else 1
    return per_hit * projectiles * (1 + stats["echo_count"]) / stats["cooldown"]


def _projectile_occupancy(skill: dict, supports: tuple[dict, ...], stats: dict) -> float:
    """Approximate simultaneous projectiles if they fly their full range."""
    if "projectile" not in skill["tags"] or (stats["is_mine"] and not stats["is_totem"]):
        return 0.0
    ids = {s["id"] for s in supports}
    per_cast = stats["projectile_count"] * (2 if stats["is_totem"] else 1 + stats["echo_count"])
    if "split" in ids:
        per_cast *= 1 + stats["split_count"]
    flight_time = stats["range"] / max(stats["speed"], 1.0)
    if "returning" in ids:
        flight_time *= 2.0
    return per_cast * flight_time / stats["cooldown"]


def _percentile(values: list[float], fraction: float) -> float:
    values = sorted(values)
    return values[min(len(values) - 1, int((len(values) - 1) * fraction))]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--starter-only", action="store_true",
                        help="Audit only the initially unlocked catalog")
    args = parser.parse_args()
    all_skills = _resources("skills")
    all_supports = _resources("supports")
    all_passives = _resources("passives")
    meta_source = (ROOT / "scripts/autoloads/meta_progression.gd").read_text(encoding="utf-8")
    initial = _literal(meta_source, "var unlocked_items: Dictionary =", "{", "}")
    unlocks = _resources("unlocks")
    grants = defaultdict(set)
    for unlock in unlocks:
        grants[unlock["item_type"]].add(unlock["item_id"])
    source_catalog = {"skills": all_skills, "supports": all_supports, "passives": all_passives}
    unreachable_catalog = {}
    for kind, items in source_catalog.items():
        ids = {item["id"] for item in items}
        assert grants[kind] <= ids, sorted(grants[kind] - ids)
        unreachable_catalog[kind] = sorted(ids - set(initial[kind]) - grants[kind])
    if args.starter_only:
        skills = [s for s in all_skills if s["id"] in initial["skills"]]
        supports = [s for s in all_supports if s["id"] in initial["supports"]]
        passives = [p for p in all_passives if p["id"] in initial["passives"]]
    else:
        skills, supports, passives = all_skills, all_supports, all_passives
    masteries = _literal(STAT_SOURCE, "_mastery_bonuses :=", "{", "}")
    rarity_source = (ROOT / "scripts/util/rarity_tiers.gd").read_text(encoding="utf-8")
    rarity_damage = _literal(rarity_source, "const DAMAGE_MULT :=", "{", "}")
    mutation_source = (ROOT / "scripts/combat/mutation_data.gd").read_text(encoding="utf-8")
    mutations = _literal(mutation_source, "const POOL :=", "[", "]")
    mine_source = (ROOT / "scripts/combat/skill_mine.gd").read_text(encoding="utf-8")
    assert "skill_instance.notify_hit" in mine_source, "Mines must dispatch support hit effects"
    assert "skill_instance.notify_kill" in mine_source, "Mines must dispatch support kill effects"
    caster_source = (ROOT / "scripts/skills/skill_caster.gd").read_text(encoding="utf-8")
    assert caster_source.index('get("is_totem", 0)') < caster_source.index('get("is_mine", 0)')
    support_ids = {s["id"] for s in supports}
    passive_ids = {p["id"] for p in passives}
    mutation_ids = {m["id"] for m in mutations}
    assert len({s["id"] for s in skills}) == len(skills)
    assert len(support_ids) == len(supports)
    assert len(passive_ids) == len(passives)
    assert len(mutation_ids) == len(mutations)
    all_support_ids = {s["id"] for s in all_supports}
    assert all(p["id"].removesuffix("_mastery") in all_support_ids
               for p in passives if p["id"].endswith("_mastery") and not p.get("affected_tags"))
    if not args.starter_only:
        fireball = next(s for s in skills if s["id"] == "fireball")
        chain = next(s for s in supports if s["id"] == "chain")
        fire_mastery = next(p for p in passives if p["id"] == "fire_mastery")
        assert compute(fireball, (chain,), (fire_mastery,), None, masteries, rarity_damage)["damage"] == 10.0

    count = 0
    variants_per_skill = Counter()
    support_coverage = Counter()
    passive_coverage = Counter()
    mutation_coverage = Counter()
    clamped = Counter()
    ranges = defaultdict(list)
    extremes = {"low": [], "high": []}
    weird = []
    base_by_skill = {}
    pair_checks = 0
    pair_clamps = Counter()
    pair_clamp_examples = []
    projectile_risk = Counter()
    projectile_peak = []
    mode_conflicts = Counter()
    mutation_mode_conflicts = Counter()
    support_loadout_count = 0

    for skill in skills:
        sid = skill["id"]
        compatible = [s for s in supports if _can_link(skill, s)]
        baseline = compute(skill, (), (), None, masteries, rarity_damage)
        base_by_skill[sid] = round(_direct_proxy(skill, baseline), 3)
        for size in range(min(skill.get("max_supports", 3), len(compatible)) + 1):
            for loadout in itertools.combinations(compatible, size):
                if not _legal_support_loadout(loadout):
                    continue
                support_loadout_count += 1
                loadout_ids = {s["id"] for s in loadout}
                if "totem" in loadout_ids and "mine" in loadout_ids:
                    mode_conflicts["mine_ignored_by_totem"] += 1
                if "spell_echo" in loadout_ids and "totem" in loadout_ids:
                    mode_conflicts["echo_ignored_by_totem"] += 1
                if "spell_echo" in loadout_ids and "mine" in loadout_ids and "totem" not in loadout_ids:
                    mode_conflicts["echo_ignored_by_mine"] += 1
                applicable_mutations = [m for m in mutations if _can_mutate(skill, m, loadout)]
                for support in loadout:
                    support_coverage[support["id"]] += 1
                relevant = [p for p in passives if _relevant(skill, loadout, p)]
                for passive in (None, *relevant):
                    if passive:
                        passive_coverage[passive["id"]] += 1
                    selected = (passive,) if passive else ()
                    for mutation in (None, *applicable_mutations):
                        if mutation:
                            mutation_coverage[mutation["id"]] += 1
                        if "mine" in loadout_ids and "totem" not in loadout_ids and mutation and mutation["id"] in {"piercing", "scatter"}:
                            mutation_mode_conflicts["projectile_mutation_ignored_by_mine"] += 1
                        stats = compute(skill, loadout, selected, mutation, masteries, rarity_damage)
                        dps = _direct_proxy(skill, stats)
                        occupancy = _projectile_occupancy(skill, loadout, stats)
                        if occupancy > 40:
                            projectile_risk["over_low_cap_40"] += 1
                        if occupancy > 50:
                            projectile_risk["over_medium_cap_50"] += 1
                        if occupancy > 60:
                            projectile_risk["over_high_cap_60"] += 1
                        if occupancy > 0:
                            projectile_peak.append((round(occupancy, 1), sid,
                                                    [s["id"] for s in loadout],
                                                    passive["id"] if passive else None,
                                                    mutation["id"] if mutation else None))
                            projectile_peak.sort(key=lambda e: e[0], reverse=True)
                            del projectile_peak[5:]
                        count += 1
                        variants_per_skill[sid] += 1
                        if mutation is None and passive is None:
                            ranges[sid].append(dps)
                        if stats["damage"] <= 1.00001:
                            clamped["damage_min"] += 1
                        if stats["cooldown"] <= 0.05001:
                            clamped["cooldown_min"] += 1
                        if stats["projectile_count"] >= 8:
                            clamped["projectile_max"] += 1
                        if stats["crit_chance"] >= 0.8:
                            clamped["crit_max"] += 1
                        if not math.isfinite(dps) or dps < 0:
                            weird.append([sid, [s["id"] for s in loadout], passive and passive["id"], mutation and mutation["id"], dps])
                        entry = (round(dps, 2), sid, [s["id"] for s in loadout],
                                 passive["id"] if passive else None,
                                 mutation["id"] if mutation else None)
                        for which in ("low", "high"):
                            board = extremes[which]
                            board.append(entry)
                            board.sort(key=lambda e: e[0], reverse=which == "high")
                            del board[5:]

                # Exhaust every relevant pair of passives with this support set.
                for a, b in itertools.combinations(relevant, 2):
                    stats = compute(skill, loadout, (a, b), None, masteries, rarity_damage)
                    assert math.isfinite(_direct_proxy(skill, stats))
                    pair_checks += 1
                    if stats["cooldown"] <= 0.05001:
                        pair_clamps["cooldown_min"] += 1
                        if len(pair_clamp_examples) < 5:
                            pair_clamp_examples.append([sid, [s["id"] for s in loadout], a["id"], b["id"]])
                    if stats["damage"] <= 1.00001:
                        pair_clamps["damage_min"] += 1

                # Exhaust mutation pairs on every legal support set.
                for a, b in itertools.combinations(applicable_mutations, 2):
                    stats = compute(skill, loadout, (), a, masteries, rarity_damage)
                    for key, value in b["stats"].items():
                        if key.endswith("_mult") and key[:-5] in stats:
                            stats[key[:-5]] *= value
                        elif key.endswith("_add") and key[:-4] in stats:
                            stats[key[:-4]] += value
                        elif key in stats:
                            stats[key] += value
                    assert math.isfinite(_direct_proxy(skill, stats))
                    pair_checks += 1

    # Arcane Tempo is a two-skill passive. Check every pair at its zero-stack
    # and maximum-stack cooldown, with the limit read from the runtime code.
    engine_source = (ROOT / "scripts/combat/engine_tracker.gd").read_text(encoding="utf-8")
    stacks = int(re.search(r"const TEMPO_MAX_STACKS := (\d+)", engine_source).group(1))
    bonus = float(re.search(r"const TEMPO_BONUS_PER_STACK := ([\d.]+)", engine_source).group(1))
    tempo_cooldown = 1.0 - stacks * bonus
    assert 0.0 < tempo_cooldown < 1.0
    tempo_checks = 0
    for first, second in itertools.combinations(skills, 2):
        base = base_by_skill[first["id"]] + base_by_skill[second["id"]]
        assert base / tempo_cooldown > base
        tempo_checks += 1
    if "arcane_tempo" in passive_ids:
        passive_coverage["arcane_tempo"] = tempo_checks

    assert set(support_coverage) == support_ids, sorted(support_ids - set(support_coverage))
    unreachable_passives = sorted(passive_ids - set(passive_coverage))
    if not args.starter_only:
        assert not unreachable_passives, unreachable_passives
    assert set(mutation_coverage) == mutation_ids, sorted(mutation_ids - set(mutation_coverage))
    assert not weird, weird[:5]
    mine_no_positive_supports = []
    for support in supports:
        if support["id"] in {"mine", "totem"}:
            continue
        if not any("projectile" in skill["tags"] and _can_link(skill, support) for skill in skills):
            continue
        mods = support.get("stat_modifiers", {})
        positive = (
            mods.get("damage_mult", 1.0) > 1.0
            or mods.get("cooldown_mult", 1.0) < 1.0
            or mods.get("range_mult", 1.0) > 1.0
            or mods.get("area_mult", 1.0) > 1.0
            or mods.get("crit_chance_add", 0.0) > 0.0
            or mods.get("crit_mult_add", 0.0) > 0.0
        )
        if not positive:
            mine_no_positive_supports.append(support["id"])
    report = {
        "scope": {"catalog": "starter" if args.starter_only else "all",
                  "skills": len(skills), "supports": len(supports), "passives": len(passives),
                  "mutations": len(mutations), "variants_tested": count,
                  "support_loadouts": support_loadout_count,
                  "pairwise_passive_or_mutation_checks": pair_checks,
                  "two_skill_arcane_tempo_checks": tempo_checks if "arcane_tempo" in passive_ids else 0,
                  "unreachable_passives_in_catalog": unreachable_passives},
        "progression_unreachable": unreachable_catalog,
        "per_skill": {sid: {"variants": variants_per_skill[sid],
                             "base_direct_dps": base_by_skill[sid],
                             "support_loadout_direct_dps_p05": round(_percentile(values, 0.05), 3),
                             "support_loadout_direct_dps_median": round(statistics.median(values), 3),
                             "support_loadout_direct_dps_p95": round(_percentile(values, 0.95), 3)}
                      for sid, values in ranges.items()},
        "clamps": dict(clamped),
        "pair_clamps": dict(pair_clamps),
        "pair_clamp_examples": pair_clamp_examples,
        "projectile_occupancy_risk_counts": dict(projectile_risk),
        "projectile_occupancy_peak_examples": projectile_peak,
        "mode_conflicts_per_support_loadout": dict(mode_conflicts),
        "mutation_mode_conflicts_per_variant": dict(mutation_mode_conflicts),
        "mine_supports_without_positive_direct_effect": mine_no_positive_supports,
        "arcane_tempo_max_stack_direct_gain_percent": (
            round((1.0 / tempo_cooldown - 1.0) * 100.0, 1)
            if "arcane_tempo" in passive_ids else None),
        "lowest_direct_proxy": extremes["low"],
        "highest_direct_proxy": extremes["high"],
        "limits": "100% hit direct DPS proxy; totem assumes 2 sustained totems; flight occupancy assumes full-range travel; excludes area coverage, DoT, most support behaviors, player survival and live win rate",
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
