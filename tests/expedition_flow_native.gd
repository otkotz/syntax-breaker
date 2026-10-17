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
	ExpeditionManager.start_new_profile()
	ExpeditionManager.profile.equipped_artifact_ids = ["fractured_prism", "furnace_heart", "ashen_needle", "cinder_crown"]
	RunManager.gold = 321
	RunManager.current_shield = 17.0
	RunManager.owned_passives = [load("res://resources/passives/thick_skin.tres")]
	RunManager.owned_consumables = [{"id": "damage_flask", "charges": 2, "resource": load("res://resources/consumables/damage_flask.tres")}]

	var game := ExpeditionGameManager.new()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(game)
	check(game.start_new_expedition(20261014), "New expedition starts")
	check(game.state == ExpeditionGameManager.State.MAP, "New expedition opens map state")
	var chosen_room_id := "room_1"
	check(game.enter_room(chosen_room_id), "Reachable combat room opens")
	check(game.state == ExpeditionGameManager.State.COMBAT, "Combat room opens arena")
	check(game.arena != null, "Existing arena is reused")
	check(game.artifact_runtime != null and game.artifact_runtime.active, "Combat creates artifact runtime")
	check(game.artifact_runtime.behaviors.size() == 6, "Prism plus full Ember set activates six behaviors")
	check((game.arena.player.get_node("SkillCaster") as SkillCaster).artifact_hooks == game.artifact_runtime.hooks, "Real caster receives artifact hooks")
	ExpeditionManager.profile.equipped_artifact_ids = ["bloodwritten_sigil", "", "", ""]
	check(ExpeditionManager.session.artifact_loadout_ids[0] == "fractured_prism", "Combat keeps frozen session loadout")
	check(RunManager.owned_passives.is_empty() and RunManager.owned_consumables.is_empty(), "Expedition combat hides roguelite build and inventory")
	check(game.skill_instances.size() == 1 and game.skill_instances[0].base.id == "fireball", "Prototype has stable starter skill")
	RunManager.add_gold(99)
	game.arena.player.current_hp = 63.0
	game.arena._on_all_waves_cleared()
	check(ExpeditionManager.session.completed_room_ids.has(chosen_room_id), "Arena clear completes room")
	check(game.state == ExpeditionGameManager.State.MAP, "Clear returns to expedition map")
	check(ExpeditionManager.has_saved_session(), "Clear checkpoints session")
	check(RunManager.gold == 321 and RunManager.current_shield == 17.0, "Expedition restores roguelite economy and shield")
	check(RunManager.owned_passives.size() == 1 and RunManager.owned_consumables.size() == 1 and not RunManager.has_saved_run(), "Expedition restores roguelite build and inventory")
	check(game.artifact_runtime == null, "Leaving combat tears artifact runtime down")
	game.queue_free()
	await get_tree().process_frame
	ExpeditionManager.session = null
	check(ExpeditionManager.load_session(), "Active expedition resumes")
	check(ExpeditionManager.session.current_hp == 63.0, "Resume preserves health")
	check(ExpeditionManager.session.completed_room_ids.has(chosen_room_id), "Resume preserves cleared room")
	check(ExpeditionManager.session.layout.seed_value == 20261014, "Resume preserves seed")
	check(not ExpeditionManager.session.can_enter(chosen_room_id), "Resume cannot replay cleared room")

	var resume_game := ExpeditionGameManager.new()
	resume_game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(resume_game)
	check(resume_game.resume_expedition(), "Game manager resumes checkpoint")
	check(resume_game.enter_room("room_3"), "Resumed route reaches merge room")
	if resume_game.state == ExpeditionGameManager.State.COMBAT:
		resume_game.arena._on_all_waves_cleared()
	check(ExpeditionManager.session.completed_room_ids.has("room_3"), "Merge room completes")
	check(resume_game.enter_room("room_4"), "Completed route unlocks boss")
	check(resume_game.state == ExpeditionGameManager.State.COMBAT, "Boss uses arena combat")
	resume_game.arena._on_all_waves_cleared()
	if resume_game.reward_overlay != null and resume_game.reward_overlay.keep_button != null:
		resume_game.reward_overlay.keep_button.pressed.emit()
	check(resume_game.last_result == "victory" and resume_game.state == ExpeditionGameManager.State.HUB, "Boss victory returns to hub")
	check(ExpeditionManager.session == null and not ExpeditionManager.has_saved_session(), "Victory clears active checkpoint")
	resume_game.queue_free()
	await get_tree().process_frame

	var interrupted_game := ExpeditionGameManager.new()
	interrupted_game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(interrupted_game)
	check(interrupted_game.start_new_expedition(20261016), "Interrupted-room fixture starts")
	check(interrupted_game.enter_room("room_1"), "Interrupted-room fixture enters combat")
	interrupted_game.queue_free()
	await get_tree().process_frame
	ExpeditionManager.session = null
	var interrupted_resume := ExpeditionGameManager.new()
	interrupted_resume.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(interrupted_resume)
	check(interrupted_resume.resume_expedition(), "Unfinished room session loads")
	check(interrupted_resume.state == ExpeditionGameManager.State.COMBAT and ExpeditionManager.session.current_room_id == "room_1", "Resume restarts unfinished combat room")
	interrupted_resume.abandon_expedition()
	interrupted_resume.queue_free()
	await get_tree().process_frame

	var transaction_game := ExpeditionGameManager.new()
	transaction_game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(transaction_game)
	check(transaction_game.start_new_expedition(20261017), "Transaction fixture starts")
	var valid_session_path := ExpeditionManager.session_path
	ExpeditionManager.session_path = "res://.godot/missing/subdir/session.json"
	check(not transaction_game.enter_room("room_1"), "Failed entry checkpoint reports failure")
	check(ExpeditionManager.session.current_room_id == "room_0", "Failed entry checkpoint rolls back navigation")
	ExpeditionManager.session_path = valid_session_path
	transaction_game.abandon_expedition()
	transaction_game.queue_free()
	await get_tree().process_frame

	var completion_transaction := ExpeditionGameManager.new()
	completion_transaction.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(completion_transaction)
	check(completion_transaction.start_new_expedition(20261018), "Completion transaction fixture starts")
	check(completion_transaction.enter_room("room_1"), "Completion transaction enters combat")
	valid_session_path = ExpeditionManager.session_path
	ExpeditionManager.session_path = "res://.godot/missing/subdir/session.json"
	completion_transaction.arena._on_all_waves_cleared()
	check(not ExpeditionManager.session.completed_room_ids.has("room_1"), "Failed completion checkpoint rolls back room completion")
	check(completion_transaction.state == ExpeditionGameManager.State.COMBAT and completion_transaction.arena != null, "Failed completion checkpoint restarts combat")
	ExpeditionManager.session_path = valid_session_path
	completion_transaction.abandon_expedition()
	completion_transaction.queue_free()
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

	ExpeditionManager.clear_active_session()
	ExpeditionManager.start_new_profile()
	ExpeditionManager.profile.level = 9
	check(ExpeditionManager.save_profile(), "Main-entry fixture profile saves")
	ExpeditionManager.profile = ExpeditionProfile.new()
	var main_scene := preload("res://scenes/main/main.tscn").instantiate()
	main_scene.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(main_scene)
	await get_tree().process_frame
	var menu := main_scene.get("_main_menu") as MainMenu
	menu.show()
	var expedition_button := _find_named(menu, "ExpeditionButton") as Button
	check(expedition_button != null, "Main menu exposes ExpeditionButton")
	if expedition_button != null:
		check(expedition_button.custom_minimum_size.x >= 600.0 and expedition_button.custom_minimum_size.y >= 88.0, "Expedition menu target is touch-sized")
		expedition_button.pressed.emit()
		check(ExpeditionManager.profile.level == 9, "Opening Expedition loads persisted profile")
		var ui_game: Node = main_scene.get("_expedition_game")
		check(ui_game != null and not menu.visible, "Expedition button opens separate game manager")
		if ui_game != null:
			var hub: Node = ui_game.get("hub")
			check(hub != null, "Expedition manager shows hub")
			if hub != null:
				var codex_button := _find_named(hub, "CodexButton") as Button
				check(codex_button != null and codex_button.custom_minimum_size.y >= 88.0,
					"Hub exposes a touch-sized Codex route")
				if codex_button != null:
					codex_button.pressed.emit()
					var codex: Node = ui_game.get("codex_ui")
					check(codex is ExpeditionCodexUI, "Codex route opens the dedicated read-only screen")
					if codex is ExpeditionCodexUI:
						(codex as ExpeditionCodexUI).back_button.pressed.emit()
						hub = ui_game.get("hub")
						check(hub != null, "Codex Back returns to Expedition hub")
				var new_button := hub.get("new_button") as Button
				check(new_button != null, "Hub exposes new expedition action")
				if new_button != null:
					new_button.pressed.emit()
					var map_ui: Node = ui_game.get("map_ui")
					check(map_ui != null, "New expedition opens map UI")
					if map_ui != null:
						var room_buttons: Dictionary = map_ui.get("room_buttons")
						var available_buttons: Array[Button] = []
						for room_id: String in ExpeditionManager.session.get_available_room_ids():
							var room_button := room_buttons.get(room_id) as Button
							check(room_button != null and room_button.custom_minimum_size.y >= 96.0, "Available room uses a full touch tile")
							if room_button != null:
								available_buttons.append(room_button)
						if not available_buttons.is_empty():
							available_buttons[0].pressed.emit()
							check(ui_game.get("state") == ExpeditionGameManager.State.COMBAT, "Room tile enters combat")
							var ui_arena := ui_game.get("arena") as Arena
							ui_arena._on_all_waves_cleared()
							check(ui_game.get("state") == ExpeditionGameManager.State.MAP and ui_game.get("map_ui") != null, "Combat clear rebuilds map UI")
	main_scene.queue_free()
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

func _find_named(root: Node, target_name: String) -> Node:
	if root.name == target_name:
		return root
	for child: Node in root.get_children():
		var found := _find_named(child, target_name)
		if found != null:
			return found
	return null
