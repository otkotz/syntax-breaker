class_name MutationData
extends RefCounted

const POOL := [
	{
		"id": "piercing",
		"name": "Piercing",
		"desc": "+3 pierce",
		"stats": {"pierce": 3},
	},
	{
		"id": "rapid_fire",
		"name": "Rapid Fire",
		"desc": "-40% cooldown",
		"stats": {"cooldown_mult": 0.6},
	},
	{
		"id": "giant",
		"name": "Giant",
		"desc": "+80% area",
		"stats": {"area_mult": 1.8},
	},
	{
		"id": "sniper",
		"name": "Sniper",
		"desc": "+60% range, +30% damage",
		"stats": {"range_mult": 1.6, "damage_mult": 1.3},
	},
	{
		"id": "scatter",
		"name": "Scatter Shot",
		"desc": "+3 projectiles",
		"stats": {"projectile_count": 3},
	},
	{
		"id": "vampiric",
		"name": "Vampiric",
		"desc": "Heal 2 HP per kill",
		"stats": {},
		"special": "vampiric",
	},
	{
		"id": "explosive",
		"name": "Explosive",
		"desc": "Kills deal 30% damage nearby",
		"stats": {},
		"special": "explosive",
	},
	{
		"id": "crit_master",
		"name": "Critical Mastery",
		"desc": "+20% crit chance, +0.5 crit multiplier",
		"stats": {"crit_chance_add": 0.2, "crit_mult": 0.5},
	},
	{
		"id": "heavy_payload",
		"name": "Heavy Payload",
		"desc": "+45% damage, +35% cooldown",
		"stats": {"damage_mult": 1.45, "cooldown_mult": 1.35},
	},
	{
		"id": "hair_trigger",
		"name": "Hair Trigger",
		"desc": "-25% cooldown, -20% damage",
		"stats": {"cooldown_mult": 0.75, "damage_mult": 0.8},
	},
	{
		"id": "concentrated",
		"name": "Concentrated Force",
		"desc": "+35% damage, -35% area",
		"stats": {"damage_mult": 1.35, "area_mult": 0.65},
	},
	{
		"id": "close_quarters",
		"name": "Close Quarters",
		"desc": "+30% damage, -35% range",
		"stats": {"damage_mult": 1.3, "range_mult": 0.65},
	},
]

static func can_apply(mutation: Dictionary, target: Variant) -> bool:
	var skill: SkillResource = target.base if target is SkillInstance else target as SkillResource
	if skill == null:
		return false
	match mutation.get("id", ""):
		"piercing", "scatter":
			# Mines explode as an area and neither pierce nor create projectiles.
			return skill.has_tag("projectile") and not (
				target is SkillInstance and target.computed_stats.get("is_mine", 0) > 0
			)
		"concentrated":
			return skill.has_tag("aoe")
		"close_quarters":
			return skill.has_tag("projectile") or skill.has_tag("melee")
	return true

static func roll_mutations(count: int, exclude_ids: Array = [], skills: Array[SkillInstance] = []) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for m: Dictionary in POOL:
		if m["id"] in exclude_ids:
			continue
		if not skills.is_empty():
			var applicable := false
			for si: SkillInstance in skills:
				if can_apply(m, si):
					applicable = true
					break
			if not applicable:
				continue
		available.append(m)
	available.shuffle()
	var result: Array[Dictionary] = []
	for i in mini(count, available.size()):
		result.append(available[i])
	return result
