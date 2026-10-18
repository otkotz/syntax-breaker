class_name ExpeditionLootRoller
extends RefCounted

const CHASE_ID := "bloodwritten_sigil"
const CHASE_PITY_KEY := "burning_boss_sigil"
const CHASE_CHANCE := 0.15

static func roll(table: LootTableResource, seed_value: int, reward_id: String, source_tag: String,
		difficulty: int, _pity: Dictionary, owned_ids: Array[String] = [], forge_commitments: Dictionary = {}) -> Dictionary:
	var result := _empty_reward(reward_id, source_tag)
	if table == null or table.source_tag != source_tag or reward_id.is_empty(): return result
	var eligible: Array[Dictionary] = []
	for entry: Dictionary in table.entries:
		var artifact := ArtifactCatalog.get_artifact(str(entry.get("artifact_id", "")))
		if artifact != null and artifact.source_tags.has(source_tag) and difficulty >= artifact.minimum_difficulty:
			eligible.append(entry)
	if eligible.is_empty(): return result
	var forge_id := ""
	if bool(forge_commitments.get("discovery_ward", false)) and source_tag in ["elite", "treasure"]:
		var unowned: Array[Dictionary] = []
		for entry in eligible:
			if not owned_ids.has(str(entry.get("artifact_id", ""))): unowned.append(entry)
		if not unowned.is_empty(): eligible = unowned
		forge_id = "discovery_ward"
	if bool(forge_commitments.get("covenant_mark", false)) and source_tag == "boss_set":
		var missing: Array[Dictionary] = []
		for entry in eligible:
			if not owned_ids.has(str(entry.get("artifact_id", ""))): missing.append(entry)
		if not missing.is_empty():
			result["artifact_ids"] = [str(missing[_rng(seed_value, reward_id).randi_range(0, missing.size() - 1)].get("artifact_id", ""))]
			result["forge_commitment_id"] = "covenant_mark"
			return result
	var rng := _rng(seed_value, reward_id)
	if rng.randf() >= table.drop_chance:
		result["shard_amount"] = 2 if source_tag == "elite" else 4 if source_tag == "treasure" else 0
		if not forge_id.is_empty(): result["forge_commitment_id"] = forge_id
		return _with_treasure_choice(result, table, seed_value, reward_id, source_tag, difficulty, _pity, owned_ids, forge_commitments)
	var covenant_ids: Array[String] = []
	for artifact_id in ArtifactCatalog.all_ids():
		var candidate := ArtifactCatalog.get_artifact(artifact_id)
		if candidate != null and candidate.set_id == "covenant_of_embers": covenant_ids.append(artifact_id)
	var covenant_complete := not covenant_ids.is_empty()
	for artifact_id in covenant_ids:
		if not owned_ids.has(artifact_id): covenant_complete = false
	var weights: Array[float] = []
	var total := 0.0
	for entry in eligible:
		var weight := float(entry.get("weight", 0.0))
		var artifact := ArtifactCatalog.get_artifact(str(entry.get("artifact_id", "")))
		if not covenant_complete and artifact != null and artifact.set_id == "covenant_of_embers" and not owned_ids.has(artifact.id):
			weight *= 4.0
		weights.append(weight)
		total += weight
	var needle := rng.randf() * total
	for index in eligible.size():
		var entry := eligible[index]
		needle -= weights[index]
		if needle <= 0.0:
			result["artifact_ids"] = [str(entry.get("artifact_id", ""))]
			break
	if not forge_id.is_empty(): result["forge_commitment_id"] = forge_id
	return _with_treasure_choice(result, table, seed_value, reward_id, source_tag, difficulty, _pity, owned_ids, forge_commitments)

static func _with_treasure_choice(result: Dictionary, table: LootTableResource, seed_value: int, reward_id: String,
		source_tag: String, difficulty: int, pity: Dictionary, owned_ids: Array[String], forge_commitments: Dictionary) -> Dictionary:
	if source_tag != "treasure" or not bool(forge_commitments.get("treasure_choice", false)): return result
	var alternative_id := reward_id + ":forge_alternative"
	var original_id := str(result.get("artifact_ids", [""])[0]) if not result.get("artifact_ids", []).is_empty() else ""
	var candidates: Array[Dictionary] = []
	for entry: Dictionary in table.entries:
		var artifact_id := str(entry.get("artifact_id", ""))
		var artifact := ArtifactCatalog.get_artifact(artifact_id)
		if artifact == null or artifact_id == original_id or difficulty < artifact.minimum_difficulty: continue
		if bool(forge_commitments.get("discovery_ward", false)) and owned_ids.has(artifact_id): continue
		candidates.append(entry)
	var alternative_ids: Array[String] = []
	if not candidates.is_empty():
		var total := 0.0
		for entry in candidates: total += float(entry.get("weight", 0.0))
		var needle := _rng(seed_value, alternative_id).randf() * total
		for entry in candidates:
			needle -= float(entry.get("weight", 0.0))
			if needle <= 0.0:
				alternative_ids = [str(entry.get("artifact_id", ""))]
				break
	result["alternative_reward_id"] = alternative_id
	result["alternative_artifact_ids"] = alternative_ids
	var applied: Array = result.get("forge_commitment_ids", [])
	var previous := str(result.get("forge_commitment_id", ""))
	if not previous.is_empty() and previous != "treasure_choice" and not applied.has(previous): applied.append(previous)
	if not applied.has("treasure_choice"): applied.append("treasure_choice")
	result["forge_commitment_ids"] = applied
	result["forge_commitment_id"] = "treasure_choice"
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
