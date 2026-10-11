class_name EvolutionData
extends RefCounted

const BY_SKILL := {
	"fireball": {"id": "solar_flare", "name": "Solar Flare"},
	"flame_wave": {"id": "firewall_breach", "name": "Firewall Breach"},
	"frost_nova": {"id": "absolute_zero", "name": "Absolute Zero"},
	"lightning_bolt": {"id": "cloud_outage", "name": "Cloud Outage"},
	"poison_dart": {"id": "ransomware", "name": "Ransomware"},
	"static_field": {"id": "daemon_process", "name": "Daemon Process"},
	"blade_spin": {"id": "recursive_rollback", "name": "Recursive Rollback"},
}

const BEHAVIORS := {
	"solar_flare": preload("res://scripts/evolutions/solar_flare.gd"),
	"firewall_breach": preload("res://scripts/evolutions/firewall_breach.gd"),
	"absolute_zero": preload("res://scripts/evolutions/absolute_zero.gd"),
	"cloud_outage": preload("res://scripts/evolutions/cloud_outage.gd"),
	"ransomware": preload("res://scripts/evolutions/ransomware.gd"),
	"daemon_process": preload("res://scripts/evolutions/daemon_process.gd"),
	"recursive_rollback": preload("res://scripts/evolutions/recursive_rollback.gd"),
}

const TIER_DESCRIPTIONS := {
	"solar_flare": [
		"Hits create a burning sun that repeatedly damages nearby enemies.",
		"Each cast also fires 3 child fireballs at 45% damage around the main shot.",
		"The sun grows larger and ends with a supernova pulse while keeping the child shots.",
	],
	"firewall_breach": [
		"The first hit raises a damaging firewall across the impact point.",
		"When the wave expires it returns through the arena in the opposite direction.",
		"The returning wave also creates a second perpendicular firewall for a cross attack.",
	],
	"absolute_zero": [
		"Targets are slowed to 40% speed for 3 seconds and shatter into damaging ice shards on death.",
		"The freeze spreads to 2 nearby enemies and each kill launches up to 4 slowing shards.",
		"Slow reaches 20% speed for 5 seconds, spreads farther, and launches up to 6 shards.",
	],
	"cloud_outage": [
		"The first hit plants 1 lightning rod that repeatedly shocks enemies around it.",
		"The rod grows larger, lasts longer, and delivers heavier area shocks.",
		"The rod network also pulses once into up to 6 nearby enemies for 35% damage.",
	],
	"ransomware": [
		"Hits mark a carrier, add poison, and spread a weaker poison to 2 nearby enemies.",
		"Carriers gain stacking infection and fire 2 death darts at 45% damage when killed.",
		"Eligible normal enemies are hijacked for 5 seconds and elites for 3 seconds.",
	],
	"daemon_process": [
		"The field persists as a background process with its normal repeated damage.",
		"When it expires it forks into 2 child fields that deal 35% damage.",
		"When it expires it forks into 4 bounded child fields that deal 35% damage.",
	],
	"recursive_rollback": [
		"The returning boomerang deals 40% bonus return damage.",
		"The return replays hits and expiry launches 1 child boomerang at 50% damage.",
		"The return gains 70% bonus damage and launches 2 angled child boomerangs at 50% damage.",
	],
}

static func get_for_skill(skill_id: String) -> Dictionary:
	return BY_SKILL.get(skill_id, {}).duplicate(true)

static func is_valid_for_skill(skill_id: String, evolution_id: String) -> bool:
	return BY_SKILL.has(skill_id) and BY_SKILL[skill_id].id == evolution_id

static func create_behavior(id: String, tier: int) -> EvolutionBehavior:
	if not BEHAVIORS.has(id):
		return null
	var behavior: EvolutionBehavior = BEHAVIORS[id].new()
	behavior.configure(tier)
	return behavior

static func tier_description(evolution_id: String, tier: int) -> String:
	var descriptions: Array = TIER_DESCRIPTIONS.get(evolution_id, [])
	if descriptions.is_empty() or tier < 1 or tier > descriptions.size():
		return ""
	return str(descriptions[tier - 1])

static func all_tier_descriptions(skill_id: String) -> Array[String]:
	var result: Array[String] = []
	var data := get_for_skill(skill_id)
	for description: Variant in TIER_DESCRIPTIONS.get(data.get("id", ""), []):
		result.append(str(description))
	return result

static func roman(value: int) -> String:
	return ["0", "I", "II", "III"][clampi(value, 0, 3)]

static func roll_offers(skills: Array[SkillInstance], difficulty: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var eligible_indices: Array[int] = []
	for index in skills.size():
		if skills[index].evolution_tier < 3 and BY_SKILL.has(skills[index].base.id):
			eligible_indices.append(index)
	for i in range(eligible_indices.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, i)
		var value := eligible_indices[i]
		eligible_indices[i] = eligible_indices[swap_index]
		eligible_indices[swap_index] = value
	var tier_bands: Array = CompilationTerminal.ENCOUNTERS[clampi(difficulty, 0, 2)].tiers
	var offers: Array[Dictionary] = []
	for skill_index in eligible_indices.slice(0, mini(3, eligible_indices.size())):
		var skill: SkillInstance = skills[skill_index]
		var data := get_for_skill(skill.base.id)
		var rolled_tier: int = tier_bands[rng.randi_range(0, tier_bands.size() - 1)]
		var offered_tier := clampi(maxi(skill.evolution_tier + 1, rolled_tier), 1, 3)
		offers.append({"type": "evolution", "skill_index": skill_index,
			"evolution_id": data.id, "current_tier": skill.evolution_tier,
			"offered_tier": offered_tier, "name": data.name,
			"description": "Upgrade %s to tier %d" % [skill.base.name, offered_tier]})
	while offers.size() < 3:
		var fallback_index := offers.size() % maxi(1, skills.size())
		offers.append({"type": "support_slot", "skill_index": fallback_index,
			"name": "Hot Socket", "description": "Gain one additional support slot"})
	return offers
