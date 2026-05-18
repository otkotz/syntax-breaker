class_name GameManager
extends Node

enum State { MENU, COMBAT, SHOP, BOSS, RUN_END }

const ARENA_SCENE := preload("res://scenes/stages/arena.tscn")

var _state: State = State.MENU
var _arena: Arena
var _skill_instances: Array[SkillInstance] = []
var _shop: Control

signal state_changed(new_state: State)
signal run_completed(victory: bool)

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
	_state = State.SHOP
	state_changed.emit(_state)

func close_shop() -> void:
	_advance_to_combat()

func end_run(victory: bool) -> void:
	_state = State.RUN_END
	state_changed.emit(_state)
	GameBus.run_ended.emit(victory)
	run_completed.emit(victory)

func get_skill_instances() -> Array[SkillInstance]:
	return _skill_instances

func add_skill_instance(si: SkillInstance) -> bool:
	if _skill_instances.size() >= RunManager.skill_slots_unlocked:
		return false
	_skill_instances.append(si)
	return true
