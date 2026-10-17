extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func reward(id: String, source: String, artifacts: Array[String], pity_key: String = "", chase: bool = false) -> Dictionary:
	return {"reward_id": id, "source_tag": source, "artifact_ids": artifacts, "shard_amount": 0,
		"pity_key": pity_key, "chase_awarded": chase}

func _ready() -> void:
	var profile := ExpeditionProfile.fresh()
	profile.owned_artifact_ids = ["fractured_prism", "bloodwritten_sigil"]
	profile.discovered_artifact_ids = ["fractured_prism", "bloodwritten_sigil"]
	profile.pity_counters[ExpeditionLootRoller.CHASE_PITY_KEY] = 2
	for index: int in range(99):
		profile.reward_history.append({"reward_id": "old_%d" % index, "source_tag": "elite", "artifact_ids": []})
	var rewards: Array[Dictionary] = [
		reward("new", "boss_set", ["furnace_heart"]),
		reward("normal_duplicate", "treasure", ["fractured_prism"]),
		reward("chase_duplicate", "boss_chase", ["bloodwritten_sigil"], ExpeditionLootRoller.CHASE_PITY_KEY, false),
		reward("unknown", "elite", ["future_artifact"]),
	]
	var settled := ExpeditionRewardSettlement.apply(profile, rewards)
	check(settled != profile, "Settlement returns a copy")
	check(profile.ember_shards == 0 and not profile.owned_artifact_ids.has("furnace_heart"), "Settlement does not mutate its input")
	check(settled.owned_artifact_ids.has("furnace_heart") and settled.discovered_artifact_ids.has("furnace_heart"), "New known artifact becomes owned and discovered")
	check(not settled.owned_artifact_ids.has("future_artifact"), "Unknown artifact is not added to ownership")
	check(settled.ember_shards == 33, "Victory and duplicate conversion grant 10 plus 5, 15, and 3 shards")
	check(settled.pity_counters.get(ExpeditionLootRoller.CHASE_PITY_KEY) == 3, "Missed chase reward increments pity")
	check(settled.reward_history.size() == 100 and settled.reward_history[0].get("reward_id") == "old_3" and settled.reward_history[-1].get("reward_id") == "unknown", "History keeps the newest 100 rewards including unknowns")
	var repeated := ExpeditionRewardSettlement.apply(settled, rewards)
	check(repeated.ember_shards == 33 and repeated.reward_history.size() == 100, "Repeated reward IDs have no effect")
	var hit := ExpeditionRewardSettlement.apply(repeated, [reward("chase_hit", "boss_chase", ["bloodwritten_sigil"], ExpeditionLootRoller.CHASE_PITY_KEY, true)])
	check(hit.pity_counters.get(ExpeditionLootRoller.CHASE_PITY_KEY) == 0, "Awarded chase artifact resets pity")

	_test_manager_transaction()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _test_manager_transaction() -> void:
	var original_profile_path := ExpeditionManager.profile_path
	var original_session_path := ExpeditionManager.session_path
	ExpeditionManager.start_new_profile()
	ExpeditionManager.session = ExpeditionSession.create(12, "burning_grounds")
	ExpeditionManager.session.status = "victory"
	ExpeditionManager.session.record_reward(reward("manager_reward", "boss_set", ["furnace_heart"]))
	var before_profile := ExpeditionManager.profile.to_dict()
	var before_session := ExpeditionManager.session.to_dict()
	ExpeditionManager.profile_path = "res://missing_directory/profile.json"
	check(not ExpeditionManager.settle_victory(), "Failed profile save reports failure")
	check(ExpeditionManager.profile.to_dict() == before_profile and ExpeditionManager.session.to_dict() == before_session, "Failed save leaves live profile and session unchanged")
	ExpeditionManager.profile_path = "res://.godot/reward_settlement_profile.json"
	ExpeditionManager.session_path = "res://.godot/reward_settlement_session.json"
	check(ExpeditionManager.save_session(), "Settlement fixture checkpoints session")
	check(ExpeditionManager.settle_victory(), "Successful settlement saves profile")
	check(ExpeditionManager.session == null and not ExpeditionManager.has_saved_session(), "Successful save clears session afterward")
	var shards_after := ExpeditionManager.profile.ember_shards
	check(not ExpeditionManager.settle_victory() and ExpeditionManager.profile.ember_shards == shards_after, "Retry cannot double-award")
	for path: String in [ExpeditionManager.profile_path, ExpeditionManager.profile_path + ".tmp", ExpeditionManager.profile_path + ".bak", ExpeditionManager.session_path, ExpeditionManager.session_path + ".tmp", ExpeditionManager.session_path + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	ExpeditionManager.profile_path = original_profile_path
	ExpeditionManager.session_path = original_session_path
