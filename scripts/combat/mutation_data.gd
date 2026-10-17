class_name MutationData
extends RefCounted

const ICON_DIR := "res://assets/icons/mutations/"

static func with_icon(mutation: Dictionary) -> Dictionary:
	var result := mutation.duplicate(true)
	result["icon_path"] = icon_path(str(result.get("id", "")))
	return result

static func icon_path(mutation_id: String) -> String:
	return ICON_DIR + mutation_id + ".png"

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

const TERMINAL_POOL := [
	{"id": "fork_bomb", "name": "Fork Bomb", "desc": "+4 projectiles, but each deals 30% less damage.",
		"stats": {"projectile_count": 4, "damage_mult": 0.7}, "terminal": true},
	{"id": "zero_latency", "name": "Zero Latency", "desc": "Cooldowns are cut by 55%, but damage falls by 35%.",
		"stats": {"cooldown_mult": 0.45, "damage_mult": 0.65}, "terminal": true},
	{"id": "stack_overflow", "name": "Stack Overflow", "desc": "+120% damage and +60% area, but 45% slower casting.",
		"stats": {"damage_mult": 2.2, "area_mult": 1.6, "cooldown_mult": 1.45}, "terminal": true},
	{"id": "packet_storm", "name": "Packet Storm", "desc": "+6 pierce and +40% speed, but 20% less damage.",
		"stats": {"pierce": 6, "speed_mult": 1.4, "damage_mult": 0.8}, "terminal": true},
	{"id": "memory_leak", "name": "Memory Leak", "desc": "Kills erupt across a huge area, but casting is 25% slower.",
		"stats": {"cooldown_mult": 1.25}, "special": "terminal_explosive", "terminal": true},
	{"id": "recursive_call", "name": "Recursive Call", "desc": "Kills recursively strike three enemies, but direct damage falls by 20%.",
		"stats": {"damage_mult": 0.8}, "special": "terminal_recursive", "terminal": true},
	{"id": "multithreading", "name": "Multithreading", "desc": "+2 projectiles and 30% faster casting, but 28% less damage.",
		"stats": {"projectile_count": 2, "cooldown_mult": 0.7, "damage_mult": 0.72}, "terminal": true},
	{"id": "kernel_panic", "name": "Kernel Panic", "desc": "+100% critical chance and +100% critical damage.",
		"stats": {"crit_chance_add": 1.0, "crit_mult": 1.0, "cooldown_mult": 1.35}, "terminal": true},
]

static func is_terminal(mutation: Dictionary) -> bool:
	return bool(mutation.get("terminal", false))

static func can_apply(mutation: Dictionary, target: Variant) -> bool:
	var skill: SkillResource = target.base if target is SkillInstance else target as SkillResource
	if skill == null:
		return false
	match mutation.get("id", ""):
		"piercing", "scatter", "fork_bomb", "packet_storm", "multithreading":
			# Mines explode as an area and neither pierce nor create projectiles.
			var tags: Array[String] = target.get_all_tags() if target is SkillInstance else skill.tags
			return skill.has_tag("projectile") and not (
				target is SkillInstance and target.computed_stats.get("is_mine", 0) > 0
			) and (mutation.get("id", "") != "piercing" or not tags.has("beam"))
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
		available.append(with_icon(m))
	available.shuffle()
	var result: Array[Dictionary] = []
	for i in mini(count, available.size()):
		result.append(available[i])
	return result

static func roll_terminal_mutations(count: int, exclude_ids: Array = [], skills: Array[SkillInstance] = []) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for mutation: Dictionary in TERMINAL_POOL:
		if mutation.id in exclude_ids:
			continue
		if not skills.is_empty() and not skills.any(func(skill: SkillInstance): return can_apply(mutation, skill)):
			continue
		available.append(with_icon(mutation))
	available.shuffle()
	return available.slice(0, mini(count, available.size()))
