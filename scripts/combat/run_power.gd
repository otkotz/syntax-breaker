class_name RunPower
extends RefCounted

static func score(skills: Array[SkillInstance]) -> float:
	var total := 0.0
	for skill: SkillInstance in skills:
		total += 1.0
		total += float(skill.evolution_tier) * 0.8
		total += float(skill.linked_supports.size()) * 0.35
		total += float(skill.mutations.size()) * 0.55
		total += float(RarityTiers.tier_index(skill.rarity_tier)) * 0.25
	var bonuses := RunManager.shop_bonuses
	total += maxf(0.0, float(bonuses.get("damage", 0.0))) / 10.0
	total += maxf(0.0, -float(bonuses.get("cooldown", 0.0))) * 5.0
	total += maxf(0.0, float(bonuses.get("crit_chance", 0.0))) * 3.0
	return total
