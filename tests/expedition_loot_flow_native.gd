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
	var count_after_elite := ExpeditionManager.session.pending_rewards.size()
	check(game.checkpoint_room_rewards(room("elite", DungeonRoomData.Type.ELITE)) and ExpeditionManager.session.pending_rewards.size() == count_after_elite and ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("elite")) == elite_reward, "Resume reuses stored elite outcome")
	check(game.checkpoint_room_rewards(room("treasure", DungeonRoomData.Type.TREASURE)), "Treasure reward checkpoints")
	check(ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("treasure")).get("source_tag") == "treasure", "Treasure stores its source reward")
	check(game.checkpoint_room_rewards(room("boss", DungeonRoomData.Type.BOSS)), "Boss rewards checkpoint together")
	check(not ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("boss", "boss_set")).is_empty() and not ExpeditionManager.session.get_reward(ExpeditionManager.session.reward_id_for("boss", "boss_chase")).is_empty(), "Boss stores distinct set and chase rewards")

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
