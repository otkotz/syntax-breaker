class_name GameManager
extends Node

enum State { MENU, STAGE_CHOICE, COMBAT, SHOP, REWARD, RUN_END }

const ARENA_SCENE := preload("res://scenes/stages/arena.tscn")
const SHOP_SCENE := preload("res://scenes/ui/shop.tscn")
const RUN_SUMMARY_SCENE := preload("res://scenes/ui/run_summary.tscn")
const SKILL_PICKER_SCENE := preload("res://scenes/ui/skill_picker.tscn")
const STAGE_CHOICE_SCENE := preload("res://scenes/ui/stage_choice.tscn")
const REWARD_PICKER_SCENE := preload("res://scenes/ui/reward_picker.tscn")

var _state: State = State.MENU
var _arena: Arena
var _skill_instances: Array[SkillInstance] = []
var _shop: Shop
var _run_summary: RunSummary
var _ui_layer: CanvasLayer
var _current_stage_data: StageData

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

func start_run() -> void:
	RunManager.start_run()
	_skill_instances.clear()
	_show_skill_picker()

func _show_skill_picker() -> void:
	var picker := SKILL_PICKER_SCENE.instantiate() as SkillPicker
	_ui_layer.add_child(picker)
	picker.skill_chosen.connect(func(skill: SkillResource):
		_skill_instances.append(SkillInstance.new(skill))
		picker.queue_free()
		_show_stage_choice()
	, CONNECT_ONE_SHOT)

func _show_stage_choice() -> void:
	var next_depth := RunManager.current_stage + 1
	if next_depth > StageGenerator.MAX_DEPTH:
		end_run(true)
		return

	var choices := StageGenerator.generate_choices(next_depth, RunManager.last_shop_depth)

	if choices.size() == 1:
		_enter_stage(choices[0])
		return

	_state = State.STAGE_CHOICE
	state_changed.emit(_state)

	var choice_ui := STAGE_CHOICE_SCENE.instantiate() as StageChoice
	_ui_layer.add_child(choice_ui)
	choice_ui.setup(choices, next_depth)
	choice_ui.stage_chosen.connect(func(stage: StageData):
		choice_ui.queue_free()
		_enter_stage(stage)
	, CONNECT_ONE_SHOT)

func _enter_stage(stage_data: StageData) -> void:
	_current_stage_data = stage_data
	RunManager.current_stage_data = stage_data
	RunManager.advance_stage()

	match stage_data.type:
		StageData.Type.COMBAT, StageData.Type.ELITE, StageData.Type.BOSS:
			_advance_to_combat(stage_data)
		StageData.Type.SHOP:
			RunManager.last_shop_depth = stage_data.depth
			_open_shop()
		StageData.Type.TREASURE:
			_show_reward_picker(StageData.Type.TREASURE)

func _advance_to_combat(stage_data: StageData) -> void:
	_state = State.COMBAT
	state_changed.emit(_state)

	if _arena:
		_arena.queue_free()

	_arena = ARENA_SCENE.instantiate() as Arena
	add_child(_arena)
	_arena.stage_completed.connect(_on_stage_completed, CONNECT_ONE_SHOT)
	_arena.start_stage(RunManager.current_stage, _skill_instances, stage_data)

func _on_stage_completed() -> void:
	if _current_stage_data and _current_stage_data.type == StageData.Type.ELITE:
		RunManager.record_stat("elites_cleared", 1)

	if _arena:
		_arena.queue_free()
		_arena = null

	if RunManager.current_stage >= StageGenerator.MAX_DEPTH:
		end_run(true)
	else:
		var stage_type := _current_stage_data.type if _current_stage_data else StageData.Type.COMBAT
		_show_reward_picker(stage_type)

func _show_reward_picker(stage_type: StageData.Type) -> void:
	_state = State.REWARD
	state_changed.emit(_state)

	var picker := REWARD_PICKER_SCENE.instantiate() as RewardPicker
	_ui_layer.add_child(picker)
	picker.setup(stage_type)
	picker.reward_chosen.connect(func(reward: Dictionary):
		picker.queue_free()
		_apply_reward(reward)
		_show_stage_choice()
	, CONNECT_ONE_SHOT)

func _apply_reward(reward: Dictionary) -> void:
	match reward.get("type", ""):
		"skill":
			var res: SkillResource = reward["resource"]
			if _skill_instances.size() < RunManager.skill_slots_unlocked:
				var si := SkillInstance.new(res)
				si.recompute(RunManager.owned_passives)
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
		"gold":
			RunManager.add_gold(reward["amount"])

func _open_shop() -> void:
	if _arena:
		_arena.queue_free()
		_arena = null

	_state = State.SHOP
	state_changed.emit(_state)

	_shop = SHOP_SCENE.instantiate() as Shop
	_ui_layer.add_child(_shop)
	_shop.setup(_skill_instances)
	_shop.continue_pressed.connect(_on_shop_continue, CONNECT_ONE_SHOT)
	_shop.skill_purchased.connect(_on_skill_purchased)

func _on_skill_purchased(si: SkillInstance) -> void:
	add_skill_instance(si)

func _on_shop_continue() -> void:
	if _shop:
		_shop.queue_free()
		_shop = null
	_show_stage_choice()

func end_run(victory: bool) -> void:
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
