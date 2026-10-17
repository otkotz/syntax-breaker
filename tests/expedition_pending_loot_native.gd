extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	var session := ExpeditionSession.create(77, "burning_grounds")
	check(session.reward_id_for("room_2") == "%s:room_2:room" % session.session_id, "Room reward ID is stable")
	check(session.reward_id_for("room_4", "boss_set") != session.reward_id_for("room_4", "boss_chase"), "Boss reward suffixes produce distinct IDs")
	var reward := {"reward_id": session.reward_id_for("room_2"), "source_tag": "elite", "artifact_ids": ["fractured_prism"], "shard_amount": 0, "pity_key": "", "chase_awarded": false}
	check(session.record_reward(reward), "Valid reward records once")
	check(not session.record_reward(reward), "Duplicate reward record is rejected")
	check(session.get_reward(reward.reward_id) == reward, "Recorded reward can be retrieved")
	var restored := ExpeditionSession.from_dict(session.to_dict())
	check(restored != null and restored.get_reward(reward.reward_id) == reward, "Pending reward survives resume identically")
	var mixed := session.to_dict()
	mixed["pending_rewards"] = [reward, {"reward_id": "bad", "source_tag": [], "artifact_ids": "bad"}]
	mixed["rolled_reward_ids"] = [reward.reward_id, "bad"]
	var recovered := ExpeditionSession.from_dict(mixed)
	check(recovered != null and recovered.pending_rewards.size() == 1 and recovered.get_reward(reward.reward_id) == reward, "Malformed reward is skipped while valid reward survives")
	check(not session.record_reward({"reward_id": "", "source_tag": "elite", "artifact_ids": []}), "Empty reward ID is rejected")
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
