extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func room(id: String, type: DungeonRoomData.Type) -> DungeonRoomData:
	var value := DungeonRoomData.new()
	value.id = id
	value.type = type
	value.region_id = "burning_grounds"
	return value

func _ready() -> void:
	ExpeditionManager.session_path = "res://.godot/loot_flow_session.json"
	ExpeditionManager.profile_path = "res://.godot/loot_flow_profile.json"
	_cleanup()
	ExpeditionManager.start_new_profile()
	ExpeditionManager.session = ExpeditionSession.create(8128, "burning_grounds")
	var game := ExpeditionGameManager.new()
	add_child(game)
	check(game.checkpoint_room_rewards(room("combat", DungeonRoomData.Type.COMBAT)), "Combat reward checkpoint succeeds")
	check(ExpeditionManager.session.pending_rewards.is_empty(), "Combat room does not roll an artifact")
	check(game.checkpoint_room_rewards(room("elite", DungeonRoomData.Type.ELITE)), "Elite reward checkpoints")
	var elite_reward := ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("elite"))
	check(not elite_reward.is_empty() and elite_reward.get("source_tag") == "elite", "Elite stores its source reward")
	var decision_reward := elite_reward
	if decision_reward.get("artifact_ids", []).is_empty():
		decision_reward = {"reward_id": "fixture:elite", "source_tag": "elite", "artifact_ids": ["fractured_prism"], "shard_amount": 0, "pity_key": "", "chase_awarded": false}
		ExpeditionManager.session.record_reward(decision_reward)
		ExpeditionManager.save_session()
	check(ExpeditionManager.session.unresolved_reward_id == decision_reward.get("reward_id"), "Artifact reward locks navigation")
	var unresolved_id := ExpeditionManager.session.unresolved_reward_id
	ExpeditionManager.session = null
	check(ExpeditionManager.load_session() and ExpeditionManager.session.unresolved_reward_id == unresolved_id, "Resume restores the same unresolved reward decision")
	game.show_map()
	check(game.map_ui == null and game.reward_overlay != null, "Locked navigation restores the reward decision instead of the map")
	game.reward_overlay.keep_button.pressed.emit()
	check(ExpeditionManager.session.unresolved_reward_id.is_empty() and game.map_ui != null, "Successful choice checkpoint unlocks navigation")
	var count_after_elite := ExpeditionManager.session.pending_rewards.size()
	var stored_elite_id := str(elite_reward.get("reward_id"))
	check(game.checkpoint_room_rewards(room("elite", DungeonRoomData.Type.ELITE)) and ExpeditionManager.session.pending_rewards.size() == count_after_elite and str(ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("elite")).get("reward_id")) == stored_elite_id, "Resume reuses stored elite outcome")
	ExpeditionManager.profile.forge_commitments["discovery_ward"] = true
	ExpeditionManager.profile.forge_commitments["treasure_choice"] = true
	check(ExpeditionManager.save_profile(), "Forge flow fixture saves active ward")
	check(game.checkpoint_room_rewards(room("treasure", DungeonRoomData.Type.TREASURE)), "Treasure reward checkpoints")
	check(ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("treasure")).get("source_tag") == "treasure", "Treasure stores its source reward")
	var stored_treasure := ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("treasure"))
	var treasure_count := ExpeditionManager.session.pending_rewards.size()
	check(not ExpeditionManager.profile.forge_commitments.has("discovery_ward") and not ExpeditionManager.profile.forge_commitments.has("treasure_choice"), "Affected reward atomically consumes Ward and Treasure Choice only after checkpoint")
	check(game.checkpoint_room_rewards(room("treasure", DungeonRoomData.Type.TREASURE)) and ExpeditionManager.session.pending_rewards.size() == treasure_count and ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("treasure")) == stored_treasure, "Resume reuses the committed ward result without rerolling")
	if ExpeditionManager.session.unresolved_reward_id.is_empty():
		ExpeditionManager.session.record_reward({"reward_id": "fixture:treasure", "source_tag": "treasure", "artifact_ids": ["echoing_hourglass"], "shard_amount": 0, "pity_key": "", "chase_awarded": false})
		ExpeditionManager.save_session()
	var decision_snapshot := ExpeditionManager.session.to_dict().duplicate(true)
	var decision_valid_path := ExpeditionManager.session_path
	ExpeditionManager.session_path = "res://missing_directory/decision.json"
	game.show_map()
	if not game.reward_overlay.choice_buttons.is_empty():
		game.reward_overlay.choice_buttons[0].pressed.emit()
	else:
		game.reward_overlay.slot_buttons[0].pressed.emit()
		game.reward_overlay.echo_button.pressed.emit()
	check(ExpeditionManager.session.to_dict() == decision_snapshot and game.reward_overlay != null, "Failed decision save rolls back session and keeps the choice visible")
	ExpeditionManager.session_path = decision_valid_path
	if not game.reward_overlay.choice_buttons.is_empty(): game.reward_overlay.choice_buttons[0].pressed.emit()
	game.reward_overlay.keep_button.pressed.emit()
	ExpeditionManager.profile.owned_artifact_ids = ["furnace_heart", "ashen_needle"]
	check(game.checkpoint_room_rewards(room("boss", DungeonRoomData.Type.BOSS)), "Boss rewards checkpoint together")
	check(not ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("boss", "boss_set")).is_empty() and not ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("boss", "boss_chase")).is_empty(), "Boss stores distinct set and chase rewards")
	var expected_boss_set := ExpeditionLootRoller.roll(ExpeditionLootCatalog.get_table("burning_boss_set"), ExpeditionManager.session.seed_value, ExpeditionManager.session.reward_id_for("boss", "boss_set"), "boss_set", ExpeditionManager.session.difficulty, ExpeditionManager.profile.pity_counters, ExpeditionManager.profile.owned_artifact_ids.duplicate())
	check(ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("boss", "boss_set")).artifact_ids == expected_boss_set.artifact_ids, "Boss set roll uses the profile ownership snapshot")

	var before := ExpeditionManager.session.to_dict().duplicate(true)
	var valid_path := ExpeditionManager.session_path
	ExpeditionManager.session_path = "res://missing_directory/loot.json"
	check(not game.checkpoint_room_rewards(room("failed", DungeonRoomData.Type.ELITE)), "Failed reward checkpoint blocks progression")
	check(ExpeditionManager.session.to_dict() == before, "Failed reward checkpoint rolls back pending loot")
	ExpeditionManager.session_path = valid_path

	var overlay := preload("res://scenes/ui/expedition_reward_overlay.tscn").instantiate() as ExpeditionRewardOverlay
	add_child(overlay)
	overlay.setup([elite_reward])
	check(overlay.confirm_button.custom_minimum_size.y >= 48.0, "Reward confirmation is touch-sized")
	check(not overlay.result_label.text.is_empty(), "Reward overlay presents a readable result")
	var confirmation := [false]
	overlay.confirmed.connect(func() -> void: confirmation[0] = true)
	overlay.confirm_button.pressed.emit()
	check(confirmation[0], "Reward overlay emits confirmation")
	overlay.queue_free()
	game.queue_free()
	_cleanup()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _cleanup() -> void:
	for suffix: String in ["", ".tmp", ".bak"]:
		var path := ExpeditionManager.session_path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for suffix: String in ["", ".tmp", ".bak"]:
		var profile_path := ExpeditionManager.profile_path + suffix
		if FileAccess.file_exists(profile_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(profile_path))
