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
