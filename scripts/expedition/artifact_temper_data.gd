class_name ArtifactTemperData
extends RefCounted

const DEFINITIONS := {
	"furnace_heart": {"name": "White-Hot Core", "upside": "Stronger direct hits", "downside": "Shorter burn window", "parameter_multipliers": {"direct_hit_mult": 1.2, "burn_duration": 0.8}},
	"ashen_needle": {"name": "Barbed Wake", "upside": "Hotter trails", "downside": "Shorter trails", "parameter_multipliers": {"trail_damage_mult": 1.25, "trail_duration": 0.75}},
	"cinder_crown": {"name": "Greedy Flame", "upside": "More transfers", "downside": "Weaker transferred burns", "parameter_multipliers": {"transfer_count": 1.5, "transfer_damage_mult": 0.75}},
	"fractured_prism": {"name": "Overfracture", "upside": "More fragments", "downside": "Weaker fragments", "parameter_multipliers": {"fragment_count": 1.5, "fragment_damage_mult": 0.8}},
	"echoing_hourglass": {"name": "Cracked Second", "upside": "Echoes more often", "downside": "Longer cooldown tax", "parameter_multipliers": {"cast_interval": 0.67, "cooldown_mult": 1.1}},
	"bloodwritten_sigil": {"name": "Open Vein", "upside": "Higher blood damage", "downside": "Higher health cost", "parameter_multipliers": {"damage_mult": 1.15, "hp_cost": 1.25}},
}

static func get_for_artifact(id: String) -> Dictionary:
	var result: Dictionary = DEFINITIONS.get(id, {}).duplicate(true)
	if not result.is_empty(): result["allow_secondary_triggers"] = false
	return result
