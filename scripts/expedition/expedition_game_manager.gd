class_name ExpeditionGameManager
extends Node

enum State { HUB, MAP, COMBAT }

signal return_to_main_menu

const ARENA_SCENE := preload("res://scenes/stages/arena.tscn")
const FIREBALL := preload("res://resources/skills/fireball.tres")
const HUB_SCENE := preload("res://scenes/ui/expedition_hub.tscn")
const MAP_SCENE := preload("res://scenes/ui/expedition_map.tscn")
const ARTIFACTS_SCENE := preload("res://scenes/ui/expedition_artifacts.tscn")

var state: State = State.HUB
var arena: Arena
var skill_instances: Array[SkillInstance] = []
var last_result: String = ""
var hub: ExpeditionHub
var map_ui: ExpeditionMapUI
var artifacts_ui: ExpeditionArtifactsUI
var artifact_runtime: ArtifactRuntime
var _active_room_id: String = ""
var _ui_layer: CanvasLayer
var _run_snapshot: Dictionary = {}
var _profile_loaded := false

func _ready() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 20
	add_child(_ui_layer)
	GameBus.player_died.connect(_on_player_died)

func open_hub() -> void:
	if not _profile_loaded:
		if not ExpeditionManager.load_profile():
			ExpeditionManager.start_new_profile()
			ExpeditionManager.save_profile()
		_profile_loaded = true
	_clear_ui()
	state = State.HUB
	hub = HUB_SCENE.instantiate() as ExpeditionHub
	_ui_layer.add_child(hub)
	hub.setup(ExpeditionManager.profile, ExpeditionManager.has_saved_session(), last_result)
	hub.new_expedition_pressed.connect(func() -> void:
		start_new_expedition(int(Time.get_unix_time_from_system()))
	, CONNECT_ONE_SHOT)
	hub.resume_pressed.connect(resume_expedition, CONNECT_ONE_SHOT)
	hub.back_pressed.connect(func() -> void: return_to_main_menu.emit(), CONNECT_ONE_SHOT)
	hub.artifacts_pressed.connect(open_artifacts, CONNECT_ONE_SHOT)

func open_artifacts() -> void:
	_clear_ui()
	artifacts_ui = ARTIFACTS_SCENE.instantiate() as ExpeditionArtifactsUI
	_ui_layer.add_child(artifacts_ui)
	artifacts_ui.setup(ExpeditionManager.profile, ExpeditionManager.session != null or ExpeditionManager.has_saved_session())
	artifacts_ui.equip_requested.connect(_on_equip_artifact)
	artifacts_ui.unequip_requested.connect(_on_unequip_artifact)
	artifacts_ui.back_pressed.connect(open_hub, CONNECT_ONE_SHOT)

func _on_equip_artifact(artifact_id: String, slot: int) -> void:
	if not ExpeditionManager.equip_artifact(artifact_id, slot): artifacts_ui.show_message("COULD NOT SAVE LOADOUT")
	artifacts_ui.setup(ExpeditionManager.profile, ExpeditionManager.session != null or ExpeditionManager.has_saved_session())

func _on_unequip_artifact(slot: int) -> void:
	if not ExpeditionManager.unequip_artifact(slot): artifacts_ui.show_message("COULD NOT SAVE LOADOUT")
	artifacts_ui.setup(ExpeditionManager.profile, ExpeditionManager.session != null or ExpeditionManager.has_saved_session())

func show_map() -> void:
	_clear_ui()
	state = State.MAP
	map_ui = MAP_SCENE.instantiate() as ExpeditionMapUI
	_ui_layer.add_child(map_ui)
	map_ui.setup(ExpeditionManager.session)
	map_ui.room_chosen.connect(enter_room)
	map_ui.abandon_pressed.connect(abandon_expedition, CONNECT_ONE_SHOT)

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

func resume_expedition() -> bool:
	if not ExpeditionManager.load_session():
		open_hub()
		return false
	if skill_instances.is_empty():
		skill_instances.append(SkillInstance.new(FIREBALL))
	last_result = ""
	if not ExpeditionManager.session.completed_room_ids.has(ExpeditionManager.session.current_room_id):
		return _open_entered_room(ExpeditionManager.session.current_room_id)
	show_map()
	return true

func enter_room(room_id: String) -> bool:
	var session := ExpeditionManager.session
	var snapshot := session.to_dict().duplicate(true) if session != null else {}
	if session == null or not session.enter_room(room_id):
		return false
	if not ExpeditionManager.save_session():
		ExpeditionManager.session = ExpeditionSession.from_dict(snapshot)
		return false
	return _open_entered_room(room_id)

func _open_entered_room(room_id: String) -> bool:
	var session := ExpeditionManager.session
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
	_clear_ui()
	_clear_arena()
	var session := ExpeditionManager.session
	_prepare_expedition_run_state(session, room)
	arena = ARENA_SCENE.instantiate() as Arena
	add_child(arena)
	artifact_runtime = ArtifactRuntime.new()
	artifact_runtime.setup(session.artifact_loadout_ids, skill_instances, arena)
	artifact_runtime.artifact_triggered.connect(_on_artifact_triggered)
	(arena.player.get_node("SkillCaster") as SkillCaster).set_artifact_hooks(artifact_runtime.hooks)
	arena.stage_completed.connect(_on_stage_completed, CONNECT_ONE_SHOT)
	arena.start_stage(room.depth + 1, skill_instances, _make_stage_data(room))

func _on_artifact_triggered(artifact_id: String, world_position: Vector2) -> void:
	if arena != null:
		ArtifactVFX.spawn(arena, artifact_id, world_position)

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
	var snapshot := ExpeditionManager.session.to_dict().duplicate(true)
	if not ExpeditionManager.session.complete_current_room(completion_id, hp, hp_max):
		return
	var won := ExpeditionManager.session.status == "victory"
	if not won and not ExpeditionManager.save_session():
		ExpeditionManager.session = ExpeditionSession.from_dict(snapshot)
		var retry_room := ExpeditionManager.session.layout.rooms.get(_active_room_id) as DungeonRoomData
		_clear_arena()
		_start_combat(retry_room)
		return
	_clear_arena()
	if won:
		_finish_expedition("victory")
	else:
		show_map()

func _complete_non_combat_room() -> void:
	var session := ExpeditionManager.session
	var snapshot := session.to_dict().duplicate(true)
	var completion_id := "%s:%s" % [session.session_id, _active_room_id]
	if session.complete_current_room(completion_id, session.current_hp, session.max_hp) \
		and not ExpeditionManager.save_session():
		ExpeditionManager.session = ExpeditionSession.from_dict(snapshot)
		show_map()
		return
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
	if artifact_runtime != null:
		artifact_runtime.teardown()
		artifact_runtime = null
	_restore_run_state()
	if arena != null:
		arena.queue_free()
		arena = null

func _clear_ui() -> void:
	hub = null
	map_ui = null
	artifacts_ui = null
	if _ui_layer == null:
		return
	for child: Node in _ui_layer.get_children():
		child.queue_free()

func _exit_tree() -> void:
	_clear_arena()

func _capture_run_state() -> void:
	if not _run_snapshot.is_empty():
		return
	for property_name: String in [
		"current_stage", "gold", "gold_fraction", "current_hp", "max_hp",
		"current_shield", "shield_recharge_remaining", "skill_slots_unlocked",
		"equipped_skills", "owned_supports", "owned_passives", "owned_consumables",
		"run_stats", "shop_bonuses", "reroll_cost", "current_stage_data",
		"current_region", "ascension_level", "stage_tree",
	]:
		var value: Variant = RunManager.get(property_name)
		_run_snapshot[property_name] = value.duplicate(true) if value is Array or value is Dictionary else value

func _prepare_expedition_run_state(session: ExpeditionSession, room: DungeonRoomData) -> void:
	_capture_run_state()
	RunManager.current_stage = room.depth + 1
	RunManager.gold = 0
	RunManager.gold_fraction = 0.0
	RunManager.current_hp = session.current_hp
	RunManager.max_hp = session.max_hp
	RunManager.current_shield = 0.0
	RunManager.shield_recharge_remaining = 0.0
	RunManager.skill_slots_unlocked = 1
	RunManager.equipped_skills = []
	RunManager.owned_supports = []
	RunManager.owned_passives = []
	RunManager.owned_consumables = []
	RunManager.run_stats = {}
	RunManager.shop_bonuses = {}
	RunManager.reroll_cost = 2
	RunManager.current_stage_data = null
	RunManager.current_region = session.region_id
	RunManager.ascension_level = 0
	RunManager.stage_tree = null

func _restore_run_state() -> void:
	if _run_snapshot.is_empty():
		return
	for property_name: String in _run_snapshot:
		RunManager.set(property_name, _run_snapshot[property_name])
	_run_snapshot.clear()
	RunManager.consumables_changed.emit()
