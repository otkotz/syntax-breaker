extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func make_game(type: StageData.Type, depth: int) -> GameManager:
	RunManager.start_run("burning_grounds")
	RunManager.current_stage = depth - 1
	RunManager.current_hp = 50.0
	var game := GameManager.new()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(game)
	game._skill_instances.append(SkillInstance.new(load("res://resources/skills/fireball.tres")))
	game._region = load("res://resources/regions/burning_grounds.tres")
	game._stage_tree = StageGenerator.generate_tree(game._region)
	# Keep the real map/visit implementation, but guarantee three choices after
	# the tested node rather than letting random one-way paths skip the map UI.
	for index in StageGenerator.MAX_DEPTH:
		if index + 1 not in [1, 5, 10]:
			game._stage_tree.rows[index] = [game._stage_tree._make_node(StageData.Type.COMBAT, index + 1), game._stage_tree._make_node(StageData.Type.SHOP, index + 1), game._stage_tree._make_node(StageData.Type.TREASURE, index + 1)]
		game._stage_tree.visited[index] = 0 if index < depth else -1
	game._stage_tree.edges.clear()
	for index in StageGenerator.MAX_DEPTH - 1:
		var edge_row := game._stage_tree._generate_edges(index)
		if game._stage_tree.rows[index + 1].size() > 1 and not edge_row.has(Vector2i(0, 1)):
			edge_row.append(Vector2i(0, 1))
		game._stage_tree.edges.append(edge_row)
	game._stage_tree.current_depth = depth
	RunManager.stage_tree = game._stage_tree
	var stage := StageData.new()
	stage.type = type
	stage.depth = depth
	stage.region = game._region
	game._enter_stage(stage)
	return game

func find_ui(game: GameManager, script: Script) -> Node:
	for child: Node in game._ui_layer.get_children():
		if not child.is_queued_for_deletion() and child.get_script() == script:
			return child
	return null

func check_map(game: GameManager, context: String) -> void:
	check(game._state == GameManager.State.STAGE_MAP, context + " returns to map")
	check(game._shop == null and find_ui(game, preload("res://scripts/ui/shop.gd")) == null, context + " has no mandatory shop")
	check(find_ui(game, preload("res://scripts/ui/stage_map.gd")) != null, context + " creates real map UI")
	check(RunManager.has_saved_run(), context + " auto-saves on map")

func run_checks() -> void:
	seed(20261003)
	RunManager.save_path = "res://.godot/node_routes_run_test.json"
	MetaProgression.save_path = "res://.godot/node_routes_meta_test.json"
	for file: String in ResourceListing.get_resource_files("res://resources/passives/"):
		var passive := load("res://resources/passives/" + file) as PassiveResource
		if not MetaProgression.unlocked_items.passives.has(passive.id):
			MetaProgression.unlocked_items.passives.append(passive.id)
	var game := make_game(StageData.Type.COMBAT, 1)
	check(game._state == GameManager.State.COMBAT and game._arena != null, "Normal node creates real arena")
	game._arena._on_all_waves_cleared()
	var picker := find_ui(game, preload("res://scripts/ui/reward_picker.gd")) as RewardPicker
	check(picker != null and game._state == GameManager.State.REWARD, "Normal combat opens reward UI")
	if picker:
		(picker.reward_container.get_child(0) as Button).pressed.emit()
	check_map(game, "Normal reward")
	await get_tree().process_frame
	check_map(game, "Normal reward after picker destruction")
	game.queue_free()
	await get_tree().process_frame
	game = make_game(StageData.Type.COMBAT, 1)
	game._stage_tree.rows[1][0].type = StageData.Type.TREASURE
	game._stage_tree.edges[0] = [Vector2i(0, 0)]
	game._arena._on_all_waves_cleared()
	picker = find_ui(game, preload("res://scripts/ui/reward_picker.gd")) as RewardPicker
	if picker:
		(picker.reward_container.get_child(0) as Button).pressed.emit()
	var treasure_picker := find_ui(game, preload("res://scripts/ui/reward_picker.gd")) as RewardPicker
	check(treasure_picker != null and RunManager.current_stage == 2, "Single route immediately enters next treasure picker")
	await get_tree().process_frame
	check(game._state == GameManager.State.REWARD and find_ui(game, preload("res://scripts/ui/reward_picker.gd")) == treasure_picker, "Old selected picker exit cannot skip next reward UI")
	if treasure_picker:
		(treasure_picker.reward_container.get_child(2) as Button).pressed.emit()
	check_map(game, "Consecutive reward exit")
	game.queue_free()
	await get_tree().process_frame
	game = make_game(StageData.Type.COMBAT, 1)
	game._arena._on_all_waves_cleared()
	game.end_run(false)
	await get_tree().process_frame
	check(game._state == GameManager.State.RUN_END and game._run_summary != null and not RunManager.has_saved_run(), "End run while reward open cannot recreate map/save")
	game.queue_free()
	await get_tree().process_frame
	game = make_game(StageData.Type.COMBAT, 1)
	game._arena._on_all_waves_cleared()
	picker = find_ui(game, preload("res://scripts/ui/reward_picker.gd")) as RewardPicker
	if picker:
		picker.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	check_map(game, "Unselected picker closure deferred safely")
	game.queue_free()
	await get_tree().process_frame
	game = make_game(StageData.Type.ELITE, 3)
	game._arena._on_all_waves_cleared()
	var chest := find_ui(game, preload("res://scripts/ui/chest_reward.gd")) as ChestReward
	check(chest != null and chest._items.size() == 3 and chest._title_text == "ELITE LOOT", "Elite opens three high-quality chest choices")
	if chest:
		chest.item_chosen.emit(0)
	check_map(game, "Elite reward")
	check(RunManager.run_stats.elites_cleared == 1, "Elite clear recorded once")
	game.queue_free()
	await get_tree().process_frame
	for choice in [1, 2]:
		game = make_game(StageData.Type.TREASURE, 3)
		picker = find_ui(game, preload("res://scripts/ui/reward_picker.gd")) as RewardPicker
		check(game._arena == null and picker != null, "Treasure skips combat and creates picker")
		if picker:
			check(picker.reward_container.get_child_count() == 3, "Treasure has gear/heal/gold choices")
			(picker.reward_container.get_child(choice) as Button).pressed.emit()
		if choice == 1:
			check(is_equal_approx(RunManager.current_hp, 90.0) and is_equal_approx(RunManager.run_stats.healing_received, 40.0), "Treasure restores 40% max HP through actual button")
		else:
			check(RunManager.gold == 65 and RunManager.run_stats.gold_earned == 35.0, "Treasure grants 35 gold through actual button")
		check_map(game, "Treasure")
		game.queue_free()
		await get_tree().process_frame
	game = make_game(StageData.Type.SHOP, 3)
	check(game._state == GameManager.State.SHOP and game._arena == null and game._shop != null, "Map shop has its own node and no combat")
	if game._shop:
		game._shop.continue_button.pressed.emit()
	check_map(game, "Map shop exit")
	game.queue_free()
	await get_tree().process_frame
	game = make_game(StageData.Type.BOSS, 5)
	game._arena._on_all_waves_cleared()
	chest = find_ui(game, preload("res://scripts/ui/chest_reward.gd")) as ChestReward
	check(chest != null and chest._title_text == "BOSS MUTATION", "Boss 5 starts with mutation choice")
	if chest:
		chest.item_chosen.emit(0)
	check(game._skill_instances[0].mutations.size() == 1, "Boss mutation applies to actual skill")
	chest = find_ui(game, preload("res://scripts/ui/chest_reward.gd")) as ChestReward
	check(chest != null and chest._title_text == "LEGENDARY RELIC", "Boss mutation leads to legendary choice")
	if chest:
		chest.item_chosen.emit(0)
	check(RunManager.owned_passives.size() == 1 and RunManager.owned_passives[0].rarity == "legendary", "Boss legendary enters run inventory")
	chest = find_ui(game, preload("res://scripts/ui/chest_reward.gd")) as ChestReward
	check(chest != null and chest._title_text == "BOSS SPOILS", "Legendary leads to normal boss reward")
	if chest:
		chest.item_chosen.emit(0)
	check(game._state == GameManager.State.SHOP and game._shop != null, "Boss 5 alone guarantees post-reward shop")
	if game._shop:
		game._shop.continue_button.pressed.emit()
	check_map(game, "Boss shop exit")
	game.queue_free()
	await get_tree().process_frame
	game = make_game(StageData.Type.BOSS, 10)
	game._arena._on_all_waves_cleared()
	check(game._state == GameManager.State.RUN_END and game._run_summary != null, "Final boss opens actual run summary")
	check(RunManager.run_stats.run_completed and game._shop == null, "Final boss wins without useless shop")
	check(not RunManager.has_saved_run(), "Final victory removes active run save")
	game.queue_free()
	await get_tree().process_frame
	print(JSON.stringify({"failures": failures, "node_routes": 10, "synthetic": true}))
	get_tree().quit(0 if failures.is_empty() else 1)
