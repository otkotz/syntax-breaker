class_name GameManager
extends Node

enum State { MENU, COMBAT, SHOP, BOSS, RUN_END }

const ARENA_SCENE := preload("res://scenes/stages/arena.tscn")
const SHOP_SCENE := preload("res://scenes/ui/shop.tscn")
const RUN_SUMMARY_SCENE := preload("res://scenes/ui/run_summary.tscn")

var _state: State = State.MENU
var _arena: Arena
var _skill_instances: Array[SkillInstance] = []
var _shop: Shop
var _run_summary: RunSummary
var _ui_layer: CanvasLayer

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
	_setup_starter_skills()
	_advance_to_combat()

func _setup_starter_skills() -> void:
	_skill_instances.clear()
	var fireball_res := load("res://resources/skills/fireball.tres") as SkillResource
	if fireball_res:
		_skill_instances.append(SkillInstance.new(fireball_res))

func _advance_to_combat() -> void:
	RunManager.advance_stage()
	_state = State.COMBAT
	state_changed.emit(_state)

	if _arena:
		_arena.queue_free()

	_arena = ARENA_SCENE.instantiate() as Arena
	add_child(_arena)
	_arena.stage_completed.connect(_on_stage_completed, CONNECT_ONE_SHOT)
	var is_boss_stage := RunManager.current_stage == 3 or RunManager.current_stage == 5
	_arena.start_stage(RunManager.current_stage, _skill_instances, is_boss_stage)

func _on_stage_completed() -> void:
	if RunManager.current_stage >= 5:
		end_run(true)
	else:
		_open_shop()

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
	_advance_to_combat()

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
