class_name GameManager
extends Node

enum State { MENU, STAGE_MAP, COMBAT, SHOP, REWARD, RUN_END }

const ARENA_SCENE := preload("res://scenes/stages/arena.tscn")
const SHOP_SCENE := preload("res://scenes/ui/shop.tscn")
const RUN_SUMMARY_SCENE := preload("res://scenes/ui/run_summary.tscn")
const SKILL_PICKER_SCENE := preload("res://scenes/ui/skill_picker.tscn")
const REWARD_PICKER_SCENE := preload("res://scenes/ui/reward_picker.tscn")
const MUTATION_PICKER_SCENE := preload("res://scenes/ui/mutation_picker.tscn")
const LEGENDARY_PICKER_SCENE := preload("res://scenes/ui/legendary_picker.tscn")
const CHEST_REWARD_SCENE := preload("res://scenes/ui/chest_reward.tscn")

var _state: State = State.MENU
var _arena: Arena
var _skill_instances: Array[SkillInstance] = []
var _shop: Shop
var _run_summary: RunSummary
var _ui_layer: CanvasLayer
var _current_stage_data: StageData
var _region: RegionResource
var _stage_tree: StageTree

signal state_changed(new_state: State)
signal run_completed(victory: bool)
signal return_to_menu_requested

func _ready() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	add_child(_ui_layer)
	GameBus.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	if _state == State.COMBAT:
		end_run(false)

func _clear_ui() -> void:
	if _shop:
		_shop.queue_free()
		_shop = null
	for child: Node in _ui_layer.get_children():
		child.queue_free()

func start_run(region_id: String = "") -> void:
	_region = _load_region(region_id)
	RunManager.start_run(region_id)
	_skill_instances.clear()
	_stage_tree = StageGenerator.generate_tree(_region)
	RunManager.stage_tree = _stage_tree
	_show_skill_picker()

func _load_region(region_id: String) -> RegionResource:
	if region_id.is_empty():
		return null
	var path := "res://resources/regions/%s.tres" % region_id
	if ResourceLoader.exists(path):
		return load(path) as RegionResource
	return null

func _show_skill_picker() -> void:
	var picker := SKILL_PICKER_SCENE.instantiate() as SkillPicker
	_ui_layer.add_child(picker)
	picker.skill_chosen.connect(func(skill: SkillResource, tier: String):
		var si := SkillInstance.new(skill)
		si.set_rarity_tier(tier)
		_skill_instances.append(si)
		picker.queue_free()
		_enter_first_stage()
	, CONNECT_ONE_SHOT)

func _enter_first_stage() -> void:
	var stage := _stage_tree.visit(0)
	_enter_stage(stage)

func _show_stage_map() -> void:
	_clear_ui()
	_auto_save()
	if not _stage_tree:
		return
	if _stage_tree.current_depth >= StageGenerator.MAX_DEPTH:
		end_run(true)
		return

	var available := _stage_tree.get_available_nodes()
	if available.size() == 1:
		var stage := _stage_tree.visit(available[0])
		_enter_stage(stage)
		return

	_state = State.STAGE_MAP
	state_changed.emit(_state)

	var map_ui := StageMapUI.new()
	_ui_layer.add_child(map_ui)
	map_ui.setup(_stage_tree)
	map_ui.stage_chosen.connect(func(stage: StageData):
		map_ui.queue_free()
		_enter_stage(stage)
	, CONNECT_ONE_SHOT)

func _enter_stage(stage_data: StageData) -> void:
	_current_stage_data = stage_data
	RunManager.current_stage_data = stage_data
	RunManager.advance_stage()

	match stage_data.type:
		StageData.Type.COMBAT, StageData.Type.ELITE, StageData.Type.BOSS:
			_advance_to_combat(stage_data)
		StageData.Type.TREASURE:
			_show_reward_picker(true)
		StageData.Type.SHOP:
			_open_map_shop()
		_:
			_advance_to_combat(stage_data)

func _advance_to_combat(stage_data: StageData) -> void:
	_state = State.COMBAT
	state_changed.emit(_state)
	_clear_ui()

	if _arena:
		_arena.queue_free()

	_arena = ARENA_SCENE.instantiate() as Arena
	add_child(_arena)
	_arena.stage_completed.connect(_on_stage_completed, CONNECT_ONE_SHOT)
	_arena.start_stage(RunManager.current_stage, _skill_instances, stage_data)

func _on_stage_completed() -> void:
	if _current_stage_data and _current_stage_data.type == StageData.Type.ELITE:
		RunManager.record_stat("elites_cleared", 1)

	var was_boss := _current_stage_data and _current_stage_data.type == StageData.Type.BOSS

	if _arena:
		_arena.queue_free()
		_arena = null

	if _stage_tree.current_depth >= StageGenerator.MAX_DEPTH:
		end_run(true)
	elif was_boss and _skill_instances.size() > 0:
		_show_mutation_picker()
	else:
		_show_reward_picker(false)

func _show_mutation_picker() -> void:
	var exclude: Array = []
	for si: SkillInstance in _skill_instances:
		for m: Dictionary in si.mutations:
			exclude.append(m["id"])
	var mutations := MutationData.roll_mutations(3, exclude)
	if mutations.is_empty():
		_show_legendary_picker()
		return

	var items: Array[Dictionary] = []
	for m: Dictionary in mutations:
		items.append({
			"type_label": "MUTATION",
			"title": m["name"],
			"desc": m["desc"],
			"color": Color(1.0, 0.55, 0.2),
		})

	var chest := CHEST_REWARD_SCENE.instantiate() as ChestReward
	_ui_layer.add_child(chest)
	chest.setup(items, true, "BOSS MUTATION")
	chest.item_chosen.connect(func(index: int):
		var mutation: Dictionary = mutations[index]
		chest.queue_free()
		if _skill_instances.size() == 1:
			_skill_instances[0].add_mutation(mutation)
			_show_legendary_picker()
		else:
			_show_mutation_skill_target(mutation)
	, CONNECT_ONE_SHOT)

func _show_mutation_skill_target(mutation: Dictionary) -> void:
	_clear_ui()
	var picker := MUTATION_PICKER_SCENE.instantiate() as MutationPicker
	_ui_layer.add_child(picker)
	picker.setup_skill_only(mutation, _skill_instances)
	picker.mutation_chosen.connect(func(_m: Dictionary, skill_idx: int):
		picker.queue_free()
		if skill_idx >= 0 and skill_idx < _skill_instances.size():
			_skill_instances[skill_idx].add_mutation(mutation)
		_show_legendary_picker()
	, CONNECT_ONE_SHOT)

func _show_legendary_picker() -> void:
	var legendaries := _get_available_legendaries()
	legendaries.shuffle()
	var choices := legendaries.slice(0, mini(3, legendaries.size()))

	if choices.is_empty():
		_show_reward_picker(false)
		return

	var items: Array[Dictionary] = []
	for passive: PassiveResource in choices:
		items.append({
			"type_label": "LEGENDARY PASSIVE",
			"title": passive.name,
			"desc": passive.description,
			"color": UITheme.C_RARITY_LEGENDARY,
		})

	var chest := CHEST_REWARD_SCENE.instantiate() as ChestReward
	_ui_layer.add_child(chest)
	chest.setup(items, true, "LEGENDARY RELIC")
	chest.item_chosen.connect(func(index: int):
		chest.queue_free()
		var passive: PassiveResource = choices[index]
		RunManager.owned_passives.append(passive)
		GameBus.passive_acquired.emit(passive)
		for si: SkillInstance in _skill_instances:
			si.recompute(RunManager.owned_passives)
		_show_reward_picker(false)
	, CONNECT_ONE_SHOT)

func _get_available_legendaries() -> Array[PassiveResource]:
	var result: Array[PassiveResource] = []
	for file_name in ResourceListing.get_resource_files("res://resources/passives/"):
		var res := load("res://resources/passives/" + file_name)
		if res is PassiveResource and res.rarity == "legendary":
			if not MetaProgression.is_unlocked("passives", res.id):
				continue
			var owned := false
			for p: Resource in RunManager.owned_passives:
				if p is PassiveResource and p.id == res.id:
					owned = true
					break
			if not owned:
				result.append(res)
	return result

func _show_reward_picker(is_treasure: bool) -> void:
	_state = State.REWARD
	state_changed.emit(_state)

	var stage_type := _current_stage_data.type if _current_stage_data else StageData.Type.COMBAT
	var is_elite := stage_type == StageData.Type.ELITE
	var is_boss := stage_type == StageData.Type.BOSS

	if is_elite or is_boss:
		_show_chest_rewards(is_treasure, is_elite or is_boss)
		return

	var picker := REWARD_PICKER_SCENE.instantiate() as RewardPicker
	_ui_layer.add_child(picker)
	picker.setup(stage_type, _skill_instances)
	var chose := false
	picker.reward_chosen.connect(func(reward: Dictionary):
		chose = true
		picker.queue_free()
		_apply_reward(reward)
		if is_treasure:
			_show_stage_map()
		else:
			_open_mandatory_shop()
	, CONNECT_ONE_SHOT)
	picker.tree_exiting.connect(func():
		if not chose:
			if is_treasure:
				_show_stage_map()
			else:
				_open_mandatory_shop()
	)

func _show_chest_rewards(is_treasure: bool, is_boss_tier: bool) -> void:
	var rewards := RewardRoller.roll(_skill_instances, true)

	var items: Array[Dictionary] = []
	for reward: Dictionary in rewards:
		items.append(_format_reward_for_chest(reward))

	var chest := CHEST_REWARD_SCENE.instantiate() as ChestReward
	_ui_layer.add_child(chest)
	var title := "BOSS SPOILS" if is_boss_tier else "ELITE LOOT"
	chest.setup(items, is_boss_tier, title)
	chest.item_chosen.connect(func(index: int):
		chest.queue_free()
		var reward: Dictionary = rewards[index]
		if reward.get("type") == "mutation" and _skill_instances.size() > 1:
			_show_chest_mutation_target(reward, is_treasure)
		else:
			if reward.get("type") == "mutation" and _skill_instances.size() == 1:
				reward["skill_index"] = 0
			_apply_reward(reward)
			if is_treasure:
				_show_stage_map()
			else:
				_open_mandatory_shop()
	, CONNECT_ONE_SHOT)

func _show_chest_mutation_target(reward: Dictionary, is_treasure: bool) -> void:
	var mutation: Dictionary = reward["mutation"]
	var picker := MUTATION_PICKER_SCENE.instantiate() as MutationPicker
	_ui_layer.add_child(picker)
	picker.setup_skill_only(mutation, _skill_instances)
	picker.mutation_chosen.connect(func(_m: Dictionary, skill_idx: int):
		picker.queue_free()
		reward["skill_index"] = skill_idx
		_apply_reward(reward)
		if is_treasure:
			_show_stage_map()
		else:
			_open_mandatory_shop()
	, CONNECT_ONE_SHOT)

func _format_reward_for_chest(reward: Dictionary) -> Dictionary:
	match reward.get("type", ""):
		"skill":
			var res: SkillResource = reward["resource"]
			return {
				"type_label": "%s SKILL" % str(reward.get("tier", res.rarity)).to_upper(),
				"title": res.name,
				"desc": "%s  [%s]" % [res.description, ", ".join(res.tags)],
				"color": UITheme.get_rarity_color(reward.get("tier", res.rarity)),
			}
		"support":
			var res: SupportResource = reward["resource"]
			return {
				"type_label": "SUPPORT",
				"title": res.name,
				"desc": res.description,
				"color": UITheme.get_rarity_color(res.rarity),
			}
		"passive":
			var res: PassiveResource = reward["resource"]
			return {
				"type_label": "PASSIVE",
				"title": res.name,
				"desc": res.description,
				"color": UITheme.get_rarity_color(res.rarity),
			}
		"mutation":
			var m: Dictionary = reward["mutation"]
			return {
				"type_label": "MUTATION",
				"title": m["name"],
				"desc": m["desc"],
				"color": Color(1.0, 0.55, 0.2),
			}
		"gold":
			return {
				"type_label": "GOLD",
				"title": "+%d Gold" % reward["amount"],
				"desc": "Add to your treasury",
				"color": Color(1.0, 0.85, 0.3),
			}
	return {"type_label": "???", "title": "Unknown", "desc": "", "color": UITheme.C_INK_MUTE}

func _apply_reward(reward: Dictionary) -> void:
	match reward.get("type", ""):
		"skill":
			var res: SkillResource = reward["resource"]
			if _skill_instances.size() < RunManager.skill_slots_unlocked:
				var si := SkillInstance.new(res)
				si.set_rarity_tier(reward.get("tier", res.rarity), RunManager.owned_passives)
				_skill_instances.append(si)
				GameBus.skill_acquired.emit(res)
			else:
				RunManager.add_gold(15)
		"support":
			var res: SupportResource = reward["resource"]
			RunManager.owned_supports.append(res)
			for si: SkillInstance in _skill_instances:
				if si.link_support(res):
					si.recompute(RunManager.owned_passives)
					break
			GameBus.support_acquired.emit(res)
		"passive":
			var res: PassiveResource = reward["resource"]
			RunManager.owned_passives.append(res)
			for si: SkillInstance in _skill_instances:
				si.recompute(RunManager.owned_passives)
			GameBus.passive_acquired.emit(res)
		"mutation":
			var mutation: Dictionary = reward["mutation"]
			var skill_idx: int = reward.get("skill_index", 0)
			if skill_idx >= 0 and skill_idx < _skill_instances.size():
				_skill_instances[skill_idx].add_mutation(mutation)
		"gold":
			RunManager.add_gold(reward["amount"])

func _open_map_shop() -> void:
	_state = State.SHOP
	state_changed.emit(_state)
	_shop = SHOP_SCENE.instantiate() as Shop
	_ui_layer.add_child(_shop)
	_shop.setup(_skill_instances)
	_shop.continue_pressed.connect(func():
		if _shop:
			_shop.queue_free()
			_shop = null
		_show_stage_map()
	, CONNECT_ONE_SHOT)
	_shop.skill_purchased.connect(_on_skill_purchased)

func _open_mandatory_shop() -> void:
	_state = State.SHOP
	state_changed.emit(_state)

	_shop = SHOP_SCENE.instantiate() as Shop
	_ui_layer.add_child(_shop)
	_shop.setup(_skill_instances)
	_shop.continue_pressed.connect(_on_shop_continue, CONNECT_ONE_SHOT)
	_shop.skill_purchased.connect(_on_skill_purchased)

func _on_skill_purchased(_si: SkillInstance) -> void:
	pass

func _on_shop_continue() -> void:
	if _shop:
		_shop.queue_free()
		_shop = null
	_show_stage_map()

func end_run(victory: bool) -> void:
	RunManager.clear_saved_run()
	_clear_ui()

	if _arena:
		_arena.queue_free()
		_arena = null

	_state = State.RUN_END
	state_changed.emit(_state)

	var new_unlocks := MetaProgression.check_unlocks(RunManager.run_stats)
	if victory:
		RunManager.run_stats["run_completed"] = true
		new_unlocks.append_array(MetaProgression.check_unlocks(RunManager.run_stats))

	GameBus.run_ended.emit(victory)
	run_completed.emit(victory)

	_run_summary = RUN_SUMMARY_SCENE.instantiate() as RunSummary
	_ui_layer.add_child(_run_summary)
	_run_summary.setup(victory, new_unlocks)
	_run_summary.play_again_pressed.connect(_on_return_to_menu, CONNECT_ONE_SHOT)

func _on_return_to_menu() -> void:
	if _run_summary:
		_run_summary.queue_free()
		_run_summary = null
	return_to_menu_requested.emit()

func get_skill_instances() -> Array[SkillInstance]:
	return _skill_instances

func add_skill_instance(si: SkillInstance) -> bool:
	if _skill_instances.size() >= RunManager.skill_slots_unlocked:
		return false
	_skill_instances.append(si)
	return true

func _serialize_skills() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for si: SkillInstance in _skill_instances:
		var supports: Array[String] = []
		for s: SupportResource in si.linked_supports:
			supports.append(s.id)
		var muts: Array[Dictionary] = []
		for m: Dictionary in si.mutations:
			muts.append(m)
		result.append({"skill_id": si.base.id, "supports": supports, "mutations": muts, "tier": si.rarity_tier})
	return result

func _deserialize_skills(skill_data: Array) -> void:
	_skill_instances.clear()
	for entry: Dictionary in skill_data:
		var skill_id: String = entry.get("skill_id", "")
		var path := "res://resources/skills/%s.tres" % skill_id
		if not ResourceLoader.exists(path):
			continue
		var skill_res := load(path) as SkillResource
		if not skill_res:
			continue
		var si := SkillInstance.new(skill_res)
		si.rarity_tier = entry.get("tier", skill_res.rarity)
		for support_id: String in entry.get("supports", []):
			var s_path := "res://resources/supports/%s.tres" % support_id
			if ResourceLoader.exists(s_path):
				var support_res := load(s_path) as SupportResource
				if support_res:
					si.link_support(support_res)
		for mutation: Dictionary in entry.get("mutations", []):
			si.mutations.append(mutation)
		si.recompute(RunManager.owned_passives)
		_skill_instances.append(si)

func _auto_save() -> void:
	RunManager.save_run(_serialize_skills())

func has_saved_run() -> bool:
	return RunManager.has_saved_run()

func resume_run() -> void:
	var data := RunManager.load_run()
	if data.is_empty():
		return_to_menu_requested.emit()
		return
	RunManager.restore_from_save(data)
	_region = _load_region(RunManager.current_region)
	_deserialize_skills(data.get("skills", []))
	_stage_tree = RunManager.stage_tree
	if not _stage_tree:
		RunManager.clear_saved_run()
		return_to_menu_requested.emit()
		return
	RunManager.clear_saved_run()
	_show_stage_map()
