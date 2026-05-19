class_name StatCalculator
extends RefCounted

const STAT_MINS := {
	"damage": 1.0,
	"cooldown": 0.1,
	"speed": 50.0,
	"range": 50.0,
	"pierce": 0,
	"area_mult": 0.1,
}

const STAT_MAXS := {
	"cooldown": 10.0,
	"pierce": 20,
	"area_mult": 5.0,
}

static func compute(skill: SkillResource, supports: Array, passives: Array) -> Dictionary:
	var stats := {
		"damage": skill.base_damage,
		"cooldown": skill.base_cooldown,
		"speed": skill.base_speed,
		"range": skill.base_range,
		"pierce": skill.base_pierce,
		"area_mult": 1.0,
		"chain_count": 0,
		"split_count": 0,
		"crit_chance": 0.05,
		"crit_mult": 1.5,
	}

	for support: SupportResource in supports:
		_apply_modifiers(stats, support.stat_modifiers)

	var matching_passives: Array = TagMatcher.get_matching_passives(skill, passives)
	for passive: PassiveResource in matching_passives:
		_apply_modifiers(stats, passive.stat_modifiers)

	_clamp_stats(stats)
	return stats

static func _apply_modifiers(stats: Dictionary, modifiers: Dictionary) -> void:
	for key: String in modifiers:
		if key.ends_with("_mult"):
			var base_key: String = key.trim_suffix("_mult")
			if stats.has(base_key):
				stats[base_key] *= modifiers[key]
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
