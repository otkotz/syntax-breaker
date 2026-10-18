class_name ExpeditionRewardSettlement
extends RefCounted

const VICTORY_SHARDS := 10
const UNKNOWN_ARTIFACT_SHARDS := 3

static func apply(profile: ExpeditionProfile, rewards: Array[Dictionary]) -> ExpeditionProfile:
	var result := ExpeditionProfile.from_dict(profile.to_dict())
	var processed_any := false
	for reward: Dictionary in rewards:
		var reward_id := str(reward.get("reward_id", ""))
		if reward_id.is_empty() or result.settled_reward_ids.has(reward_id):
			continue
		processed_any = true
		result.settled_reward_ids.append(reward_id)
		result.ember_shards += maxi(0, int(reward.get("shard_amount", 0)))
		result.ember_shards += maxi(0, int(reward.get("decision_shard_amount", 0)))
		var artifact_ids: Variant = reward.get("artifact_ids", [])
		if artifact_ids is Array and str(reward.get("decision_action", "")) not in ["temper", "shatter"]:
			for value: Variant in artifact_ids:
				_settle_artifact(result, str(value))
		_update_pity(result, reward)
		result.reward_history.append({
			"reward_id": reward_id,
			"source_tag": str(reward.get("source_tag", "")),
			"artifact_ids": artifact_ids.duplicate() if artifact_ids is Array else [],
		})
	if processed_any:
		result.ember_shards += VICTORY_SHARDS
	while result.reward_history.size() > ExpeditionProfile.REWARD_HISTORY_LIMIT:
		result.reward_history.pop_front()
	return result

static func _settle_artifact(profile: ExpeditionProfile, artifact_id: String) -> void:
	var artifact := ArtifactCatalog.get_artifact(artifact_id)
	if artifact == null:
		profile.ember_shards += UNKNOWN_ARTIFACT_SHARDS
	elif profile.owned_artifact_ids.has(artifact_id):
		profile.ember_shards += maxi(0, artifact.duplicate_shard_value)
	else:
		profile.owned_artifact_ids.append(artifact_id)
		if not profile.discovered_artifact_ids.has(artifact_id):
			profile.discovered_artifact_ids.append(artifact_id)

static func _update_pity(profile: ExpeditionProfile, reward: Dictionary) -> void:
	var pity_key := str(reward.get("pity_key", ""))
	if pity_key.is_empty():
		return
	if bool(reward.get("chase_awarded", false)):
		profile.pity_counters[pity_key] = 0
	else:
		profile.pity_counters[pity_key] = int(profile.pity_counters.get(pity_key, 0)) + 1
