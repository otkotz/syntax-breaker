class_name StatCalculator
extends RefCounted

const STAT_MINS := {
	"damage": 1.0,
	"cooldown": 0.1,
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
	}

	# Collect multipliers additively then apply once (diminishing returns)
	var mult_totals: Dictionary = {}

	for support: SupportResource in supports:
		_collect_modifiers(stats, support.stat_modifiers, mult_totals)

	var matching_passives: Array = TagMatcher.get_matching_passives(skill, passives)
	for passive: PassiveResource in matching_passives:
		_collect_modifiers(stats, passive.stat_modifiers, mult_totals)

	# Apply collected multipliers: base * (1 + sum_of_bonuses)
	for key: String in mult_totals:
		if stats.has(key):
			stats[key] *= (1.0 + mult_totals[key])

	_clamp_stats(stats)
	return stats

static func _collect_modifiers(stats: Dictionary, modifiers: Dictionary, mult_totals: Dictionary) -> void:
	for key: String in modifiers:
		if key.ends_with("_mult"):
			var base_key: String = key.trim_suffix("_mult")
			# Convert multiplicative (0.75 = -25%) to additive bonus (-0.25)
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

static func _clamp_stats(stats: Dictionary) -> void:
	for key: String in STAT_MINS:
		if stats.has(key):
			stats[key] = max(stats[key], STAT_MINS[key])
	for key: String in STAT_MAXS:
		if stats.has(key):
			stats[key] = min(stats[key], STAT_MAXS[key])
