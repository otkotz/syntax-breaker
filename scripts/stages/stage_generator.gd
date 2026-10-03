class_name StageGenerator
extends RefCounted

const ALL_MODIFIERS := ["swift", "tough", "swarming", "deadly", "enriched", "cursed"]
const MAX_DEPTH := 10
const BOSS_DEPTHS := [5, 10]

static func get_ascension_modifiers(depth: int) -> Array[String]:
	var result: Array[String] = []
	if depth < 2:
		return result
	if RunManager.ascension_level >= 5:
		result.append("elite_patrol")
	if RunManager.ascension_level >= 10:
		result.append("denial_reinforcement")
	if RunManager.ascension_level >= 15:
		result.append("shield_reinforcement")
	return result

static func generate_tree(region: RegionResource = null) -> StageTree:
	var tree := StageTree.new()
	tree.generate(region)
	return tree

static func _apply_modifiers(stage: StageData) -> void:
	if stage.type in [StageData.Type.COMBAT, StageData.Type.ELITE]:
		for modifier in get_ascension_modifiers(stage.depth):
			if not stage.modifiers.has(modifier):
				stage.modifiers.append(modifier)
	if stage.region:
		for mod: String in stage.region.stage_modifiers:
			if not stage.modifiers.has(mod):
				stage.modifiers.append(mod)
	if stage.depth < 3:
		return
	var count := 1 if stage.depth < 7 else 2
	var pool := ALL_MODIFIERS.duplicate()
	for existing: String in stage.modifiers:
		pool.erase(existing)
	pool.shuffle()
	for i in mini(count, pool.size()):
		stage.modifiers.append(pool[i])

static func get_depth_scaling(depth: int) -> Dictionary:
	var dmg_mult := 0.5 if depth == 1 else 1.0 + 0.10 * (depth - 1)
	return {
		"hp_mult": pow(1.16, depth - 1),
		"damage_mult": dmg_mult,
		"count_add": 5 * (depth - 1),
	}

static func get_density_curve(depth: int) -> Dictionary:
	match depth:
		1: return {"total_enemies": 80, "duration": 50.0, "has_mini_boss": false}
		2: return {"total_enemies": 100, "duration": 55.0, "has_mini_boss": false}
		3: return {"total_enemies": 130, "duration": 60.0, "has_mini_boss": false}
		4: return {"total_enemies": 180, "duration": 70.0, "has_mini_boss": true}
		5: return {"total_enemies": 250, "duration": 75.0, "has_mini_boss": false}
		6: return {"total_enemies": 290, "duration": 75.0, "has_mini_boss": false}
		7: return {"total_enemies": 360, "duration": 80.0, "has_mini_boss": true}
		8: return {"total_enemies": 440, "duration": 85.0, "has_mini_boss": false}
		9: return {"total_enemies": 500, "duration": 85.0, "has_mini_boss": false}
		10: return {"total_enemies": 580, "duration": 90.0, "has_mini_boss": false}
	return {"total_enemies": 580 + (depth - 10) * 50, "duration": 90.0, "has_mini_boss": depth % 3 == 1}
