class_name ExpeditionLootRoller
extends RefCounted

const CHASE_ID := "bloodwritten_sigil"
const CHASE_PITY_KEY := "burning_boss_sigil"
const CHASE_CHANCE := 0.15

static func roll(table: LootTableResource, seed_value: int, reward_id: String, source_tag: String,
		difficulty: int, _pity: Dictionary) -> Dictionary:
	var result := _empty_reward(reward_id, source_tag)
	if table == null or table.source_tag != source_tag or reward_id.is_empty(): return result
	var eligible: Array[Dictionary] = []
	for entry: Dictionary in table.entries:
		var artifact := ArtifactCatalog.get_artifact(str(entry.get("artifact_id", "")))
		if artifact != null and artifact.source_tags.has(source_tag) and difficulty >= artifact.minimum_difficulty:
			eligible.append(entry)
	if eligible.is_empty(): return result
	var rng := _rng(seed_value, reward_id)
	if rng.randf() >= table.drop_chance:
		result["shard_amount"] = 2 if source_tag == "elite" else 4 if source_tag == "treasure" else 0
		return result
	var total := 0.0
	for entry in eligible: total += float(entry.get("weight", 0.0))
	var needle := rng.randf() * total
	for entry in eligible:
		needle -= float(entry.get("weight", 0.0))
		if needle <= 0.0:
			result["artifact_ids"] = [str(entry.get("artifact_id", ""))]
			break
	return result

static func roll_chase(seed_value: int, reward_id: String, difficulty: int, pity: Dictionary) -> Dictionary:
	var result := _empty_reward(reward_id, "boss_chase")
	result["pity_key"] = CHASE_PITY_KEY
	var artifact := ArtifactCatalog.get_artifact(CHASE_ID)
	if artifact == null or difficulty < artifact.minimum_difficulty: return result
	var guaranteed := int(pity.get(CHASE_PITY_KEY, 0)) >= 4
	if guaranteed or _rng(seed_value, reward_id).randf() < CHASE_CHANCE:
		result["artifact_ids"] = [CHASE_ID]
		result["chase_awarded"] = true
	return result

static func _empty_reward(reward_id: String, source_tag: String) -> Dictionary:
	return {"reward_id": reward_id, "source_tag": source_tag, "artifact_ids": [], "shard_amount": 0,
		"pity_key": "", "chase_awarded": false}

static func _rng(seed_value: int, reward_id: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%s" % [seed_value, reward_id])
	return rng
