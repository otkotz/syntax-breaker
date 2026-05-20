class_name StageGenerator
extends RefCounted

const ALL_MODIFIERS := ["swift", "tough", "swarming", "deadly", "enriched", "cursed"]
const MAX_DEPTH := 10
const BOSS_DEPTHS := [5, 10]

static func generate_choices(depth: int, last_shop_depth: int, region: RegionResource = null) -> Array[StageData]:
	if depth in BOSS_DEPTHS:
		var boss := StageData.new()
		boss.type = StageData.Type.BOSS
		boss.depth = depth
		boss.region = region
		return [boss]

	if depth == 1:
		var combat := StageData.new()
		combat.type = StageData.Type.COMBAT
		combat.depth = depth
		combat.region = region
		return [combat]

	var choices: Array[StageData] = []

	var combat := StageData.new()
	combat.type = StageData.Type.COMBAT
	combat.depth = depth
	combat.region = region
	_apply_modifiers(combat)
	choices.append(combat)

	var slot2 := StageData.new()
	slot2.depth = depth
	slot2.region = region
	slot2.type = _pick_secondary_type(depth, last_shop_depth)
	if slot2.type == StageData.Type.COMBAT or slot2.type == StageData.Type.ELITE:
		_apply_modifiers(slot2)
	choices.append(slot2)

	var slot3 := StageData.new()
	slot3.depth = depth
	slot3.region = region
	slot3.type = _pick_tertiary_type(depth, last_shop_depth, slot2.type)
	if slot3.type == StageData.Type.COMBAT or slot3.type == StageData.Type.ELITE:
		_apply_modifiers(slot3)
	choices.append(slot3)

	return choices

static func _pick_secondary_type(depth: int, last_shop_depth: int) -> StageData.Type:
	if depth >= 3 and randf() < 0.5:
		return StageData.Type.ELITE
	if depth - last_shop_depth >= 3:
		return StageData.Type.SHOP
	if depth - last_shop_depth >= 2 and randf() < 0.4:
		return StageData.Type.SHOP
	return StageData.Type.ELITE if depth >= 3 else StageData.Type.COMBAT

static func _pick_tertiary_type(depth: int, last_shop_depth: int, slot2_type: StageData.Type) -> StageData.Type:
	if slot2_type != StageData.Type.SHOP and depth - last_shop_depth >= 2:
		return StageData.Type.SHOP
	if depth >= 2 and randf() < 0.3:
		return StageData.Type.TREASURE
	if depth >= 3 and slot2_type != StageData.Type.ELITE:
		return StageData.Type.ELITE
	return StageData.Type.COMBAT

static func _apply_modifiers(stage: StageData) -> void:
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
	return {
		"hp_mult": 1.0 + 0.15 * (depth - 1),
		"damage_mult": 1.0 + 0.10 * (depth - 1),
		"count_add": 5 * (depth - 1),
	}
