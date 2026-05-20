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
]

static func roll_mutations(count: int, exclude_ids: Array = []) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for m: Dictionary in POOL:
		if not m["id"] in exclude_ids:
			available.append(m)
	available.shuffle()
	var result: Array[Dictionary] = []
	for i in mini(count, available.size()):
		result.append(available[i])
	return result
