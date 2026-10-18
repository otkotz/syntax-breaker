class_name BloodOmen
extends RefCounted

const VARIANTS := {
	"crimson_overdrive": {"name": "CRIMSON OVERDRIVE", "hp_cost": 0.12, "damage_mult": 1.55, "area_mult": 1.4, "hp_threshold": 0.9},
	"hematic_reserve": {"name": "HEMATIC RESERVE", "hp_cost": 0.05, "damage_mult": 1.15, "area_mult": 1.15, "hp_threshold": 0.75},
}

static func is_available(profile: ExpeditionProfile) -> bool:
	return profile != null and int(profile.pity_counters.get(ExpeditionLootRoller.CHASE_PITY_KEY, 0)) >= 3

static func get_variant(id: String) -> Dictionary:
	return VARIANTS.get(id, {}).duplicate(true)
