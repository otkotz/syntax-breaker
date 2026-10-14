class_name ExpeditionGameManager
extends Node

enum State { HUB, MAP, COMBAT }

signal return_to_main_menu

const ARENA_SCENE := preload("res://scenes/stages/arena.tscn")
const FIREBALL := preload("res://resources/skills/fireball.tres")

var state: State = State.HUB
var arena: Arena
var skill_instances: Array[SkillInstance] = []
var last_result: String = ""
var _active_room_id: String = ""

func _ready() -> void:
	GameBus.player_died.connect(_on_player_died)

func open_hub() -> void:
	state = State.HUB

func show_map() -> void:
	state = State.MAP

func start_new_expedition(seed_value: int) -> bool:
	if ExpeditionManager.profile == null:
		ExpeditionManager.start_new_profile()
		if not ExpeditionManager.save_profile():
			return false
	if not ExpeditionManager.start_expedition(seed_value, "burning_grounds"):
		return false
	skill_instances.clear()
	skill_instances.append(SkillInstance.new(FIREBALL))
	last_result = ""
	show_map()
	return true

func enter_room(room_id: String) -> bool:
	var session := ExpeditionManager.session
	if session == null or not session.enter_room(room_id):
		return false
	if not ExpeditionManager.save_session():
		return false
	_active_room_id = room_id
	var room := session.layout.rooms.get(room_id) as DungeonRoomData
	if room == null:
		return false
	if room.type in [DungeonRoomData.Type.COMBAT, DungeonRoomData.Type.ELITE, DungeonRoomData.Type.BOSS]:
		_start_combat(room)
	else:
		_complete_non_combat_room()
	return true

func abandon_expedition() -> void:
	last_result = "abandoned"
	_clear_arena()
	ExpeditionManager.clear_active_session()
	open_hub()

func _start_combat(room: DungeonRoomData) -> void:
	state = State.COMBAT
	_clear_arena()
	var session := ExpeditionManager.session
	RunManager.current_hp = session.current_hp
	RunManager.max_hp = session.max_hp
	arena = ARENA_SCENE.instantiate() as Arena
	add_child(arena)
	arena.stage_completed.connect(_on_stage_completed, CONNECT_ONE_SHOT)
	arena.start_stage(room.depth + 1, skill_instances, _make_stage_data(room))

func _make_stage_data(room: DungeonRoomData) -> StageData:
	var stage := StageData.new()
	stage.depth = room.depth + 1
	var region_path := "res://resources/regions/%s.tres" % room.region_id
	if ResourceLoader.exists(region_path):
		stage.region = load(region_path) as RegionResource
	match room.type:
		DungeonRoomData.Type.ELITE:
			stage.type = StageData.Type.ELITE
		DungeonRoomData.Type.BOSS:
			stage.type = StageData.Type.BOSS
		_:
			stage.type = StageData.Type.COMBAT
	return stage

func _on_stage_completed() -> void:
	if state != State.COMBAT or ExpeditionManager.session == null or arena == null:
		return
	var hp := arena.player.current_hp
	var hp_max := arena.player.max_hp
	var completion_id := "%s:%s" % [ExpeditionManager.session.session_id, _active_room_id]
	if not ExpeditionManager.session.complete_current_room(completion_id, hp, hp_max):
		return
	var won := ExpeditionManager.session.status == "victory"
	_clear_arena()
	if won:
		_finish_expedition("victory")
	else:
		ExpeditionManager.save_session()
		show_map()

func _complete_non_combat_room() -> void:
	var session := ExpeditionManager.session
	var completion_id := "%s:%s" % [session.session_id, _active_room_id]
	if session.complete_current_room(completion_id, session.current_hp, session.max_hp):
		ExpeditionManager.save_session()
	show_map()

func _on_player_died() -> void:
	if state != State.COMBAT or ExpeditionManager.session == null:
		return
	ExpeditionManager.session.status = "failed"
	_finish_expedition("failed")

func _finish_expedition(result: String) -> void:
	last_result = result
	_clear_arena()
	ExpeditionManager.save_profile()
	ExpeditionManager.clear_active_session()
	open_hub()

func _clear_arena() -> void:
	if arena != null:
		arena.queue_free()
		arena = null
