extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	ExpeditionManager.profile_path = "res://.godot/expedition_flow_profile_test.json"
	ExpeditionManager.session_path = "res://.godot/expedition_flow_session_test.json"
	RunManager.save_path = "res://.godot/expedition_flow_roguelite_test.json"
	RunManager.gold = 321
	_cleanup_files()
	ExpeditionManager.profile = null
	ExpeditionManager.session = null

	var game := ExpeditionGameManager.new()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(game)
	check(game.start_new_expedition(20261014), "New expedition starts")
	check(game.state == ExpeditionGameManager.State.MAP, "New expedition opens map state")
	var chosen_room_id := "room_1"
	check(game.enter_room(chosen_room_id), "Reachable combat room opens")
	check(game.state == ExpeditionGameManager.State.COMBAT, "Combat room opens arena")
	check(game.arena != null, "Existing arena is reused")
	check(game.skill_instances.size() == 1 and game.skill_instances[0].base.id == "fireball", "Prototype has stable starter skill")
	game.arena._on_all_waves_cleared()
	check(ExpeditionManager.session.completed_room_ids.has(chosen_room_id), "Arena clear completes room")
	check(game.state == ExpeditionGameManager.State.MAP, "Clear returns to expedition map")
	check(ExpeditionManager.has_saved_session(), "Clear checkpoints session")
	check(RunManager.gold == 321 and not RunManager.has_saved_run(), "Expedition does not write roguelite economy or save")
	game.queue_free()
	await get_tree().process_frame

	var death_game := ExpeditionGameManager.new()
	death_game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(death_game)
	check(death_game.start_new_expedition(20261015), "Death fixture starts")
	ExpeditionManager.profile.level = 4
	check(ExpeditionManager.save_profile(), "Death fixture profile saves")
	check(death_game.enter_room("room_1"), "Death fixture enters combat")
	death_game._on_player_died()
	check(death_game.last_result == "failed", "Death records failed result")
	check(death_game.state == ExpeditionGameManager.State.HUB, "Death returns to hub")
	check(ExpeditionManager.session == null and not ExpeditionManager.has_saved_session(), "Death clears only active session")
	ExpeditionManager.profile = null
	check(ExpeditionManager.load_profile() and ExpeditionManager.profile.level == 4, "Death preserves persistent profile")
	death_game.queue_free()
	await get_tree().process_frame

	_cleanup_files()
	print(JSON.stringify({"failures": failures, "flow": "combat-clear-death"}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _cleanup_files() -> void:
	for path: String in [
		ExpeditionManager.profile_path,
		ExpeditionManager.profile_path + ".tmp",
		ExpeditionManager.session_path,
		ExpeditionManager.session_path + ".tmp",
		RunManager.save_path,
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
