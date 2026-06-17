class_name StatCalculator
extends RefCounted

const STAT_MINS := {
	"damage": 1.0,
	"cooldown": 0.05,
	"speed": 50.0,
	"range": 50.0,
	"pierce": 0,
	"area_mult": 0.1,
	"projectile_count": 1,
}

const STAT_MAXS := {
	"cooldown": 10.0,
	"pierce": 20,
	"area_mult": 5.0,
	"projectile_count": 8,
	"chain_count": 10,
	"split_count": 5,
	"crit_chance": 0.8,
}

static func compute(skill: SkillResource, supports: Array, passives: Array) -> Dictionary:
	var stats := {
		"damage": skill.base_damage,
		"cooldown": skill.base_cooldown,
		"speed": skill.base_speed,
		"range": skill.base_range,
		"pierce": skill.base_pierce,
		"projectile_count": skill.base_projectile_count,
		"area_mult": 1.0,
		"chain_count": 0,
		"split_count": 0,
		"crit_chance": 0.05,
		"crit_mult": 1.5,
		"echo_count": 0,
		"is_totem": 0,
		"is_mine": 0,
	}

	var mult_totals: Dictionary = {}

	for support: SupportResource in supports:
		_collect_modifiers(stats, support.stat_modifiers, mult_totals)
		if _has_mastery_passive(support.id):
			_collect_modifiers(stats, _get_mastery_bonus(support.id), mult_totals)

	var matching_passives: Array = TagMatcher.get_matching_passives(skill, passives)
	for passive: PassiveResource in matching_passives:
		_collect_modifiers(stats, passive.stat_modifiers, mult_totals)

	# Apply collected multipliers: base * (1 + sum_of_bonuses)
	for key: String in mult_totals:
		if stats.has(key):
			stats[key] *= (1.0 + mult_totals[key])

	for key: String in RunManager.shop_bonuses:
		if stats.has(key):
			stats[key] += RunManager.shop_bonuses[key]

	_clamp_stats(stats)
	return stats

static func _collect_modifiers(stats: Dictionary, modifiers: Dictionary, mult_totals: Dictionary) -> void:
	for key: String in modifiers:
		if key.ends_with("_mult"):
			var base_key: String = key.trim_suffix("_mult")
			var bonus: float = modifiers[key] - 1.0
			if not mult_totals.has(base_key):
				mult_totals[base_key] = 0.0
			mult_totals[base_key] += bonus
		elif key.ends_with("_add"):
			var base_key: String = key.trim_suffix("_add")
			if stats.has(base_key):
				stats[base_key] += modifiers[key]
		elif stats.has(key):
			stats[key] += modifiers[key]

static var _mastery_bonuses := {
	"pierce": {"pierce": 2, "damage_mult": 1.2},
	"returning": {"damage_mult": 1.15},
	"chain": {"chain_count": 2},
	"split": {"split_count": 1},
	"shotgun": {"projectile_count": 2},
	"increased_area": {"area_mult": 1.5},
	"faster_casting": {"cooldown_mult": 0.5},
	"crit_explosion": {"crit_chance_add": 0.1, "area_mult": 1.3},
	"poison_on_hit": {"damage_mult": 1.15},
	"elemental_proliferation": {"area_mult": 1.4},
	"glass_cannon": {"damage_mult": 1.25},
	"overcharge": {"damage_mult": 1.3},
	"spell_echo": {"echo_count": 1, "damage_mult": 1.1},
	"cast_on_kill": {"damage_mult": 1.2},
	"void_rift": {"damage_mult": 1.2},
	"totem": {"cooldown_mult": 0.8},
	"mine": {"damage_mult": 1.25},
	"corpse_bloom": {"damage_mult": 1.15},
	"toxic_burst": {"damage_mult": 1.1},
	"arc_burst": {"crit_chance_add": 0.05},
	"echo_trigger": {"damage_mult": 1.15},
	"plague_carrier": {"damage_mult": 1.1},
	"ricochet_amplifier": {"chain_count": 1, "damage_mult": 1.1},
	"crit_cascade": {"crit_chance_add": 0.05},
}

static func _has_mastery_passive(support_id: String) -> bool:
	var mastery_id := support_id + "_mastery"
	for p: Resource in RunManager.owned_passives:
		if p is PassiveResource and p.id == mastery_id:
			return true
	return false

static func _get_mastery_bonus(support_id: String) -> Dictionary:
	return _mastery_bonuses.get(support_id, {})

static func _clamp_stats(stats: Dictionary) -> void:
	for key: String in STAT_MINS:
		if stats.has(key):
			stats[key] = max(stats[key], STAT_MINS[key])
	for key: String in STAT_MAXS:
		if stats.has(key):
			stats[key] = min(stats[key], STAT_MAXS[key])
