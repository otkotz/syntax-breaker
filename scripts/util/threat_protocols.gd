class_name ThreatProtocols
extends RefCounted

const MAX_LEVEL := 4
const DEFINITIONS := [
	{"id": "normal", "name": "NORMAL", "hp_mult": 1.0, "damage_mult": 1.0, "speed_mult": 1.0, "count_mult": 1.0, "luck_bonus": 0.0, "gold_mult": 1.0},
	{"id": "overclocked", "name": "OVERCLOCKED", "hp_mult": 1.15, "damage_mult": 1.08, "speed_mult": 1.03, "count_mult": 1.12, "luck_bonus": 5.0, "gold_mult": 1.08},
	{"id": "corrupted", "name": "CORRUPTED", "hp_mult": 1.30, "damage_mult": 1.18, "speed_mult": 1.06, "count_mult": 1.25, "luck_bonus": 10.0, "gold_mult": 1.18},
	{"id": "system_failure", "name": "SYSTEM FAILURE", "hp_mult": 1.55, "damage_mult": 1.32, "speed_mult": 1.10, "count_mult": 1.40, "luck_bonus": 18.0, "gold_mult": 1.32},
	{"id": "no_warranty", "name": "NO WARRANTY", "hp_mult": 1.85, "damage_mult": 1.50, "speed_mult": 1.15, "count_mult": 1.60, "luck_bonus": 28.0, "gold_mult": 1.50},
]

static func definition(level: int) -> Dictionary:
	return DEFINITIONS[clampi(level, 0, MAX_LEVEL)].duplicate(true)

static func scaling(level: int) -> Dictionary:
	var source := definition(level)
	return {
		"hp_mult": source.hp_mult,
		"damage_mult": source.damage_mult,
		"speed_mult": source.speed_mult,
		"count_mult": source.count_mult,
		"luck_bonus": source.luck_bonus,
		"gold_mult": source.gold_mult,
	}

static func special_modifiers(level: int, depth: int) -> Array[String]:
	var result: Array[String] = []
	if depth < 2:
		return result
	var clamped := clampi(level, 0, MAX_LEVEL)
	if clamped >= 2:
		result.append("elite_patrol")
	if clamped >= 3:
		result.append("denial_reinforcement")
	if clamped >= 4:
		result.append("shield_reinforcement")
	return result

static func from_legacy_ascension(level: int) -> int:
	if level <= 0:
		return 0
	if level <= 4:
		return 1
	if level <= 9:
		return 2
	if level <= 14:
		return 3
	return 4
