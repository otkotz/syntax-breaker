class_name ExpeditionGameManager
extends Node

enum State { HUB, MAP, COMBAT }

signal return_to_main_menu

const ARENA_SCENE := preload("res://scenes/stages/arena.tscn")
const FIREBALL := preload("res://resources/skills/fireball.tres")
const HUB_SCENE := preload("res://scenes/ui/expedition_hub.tscn")
const MAP_SCENE := preload("res://scenes/ui/expedition_map.tscn")
const ARTIFACTS_SCENE := preload("res://scenes/ui/expedition_artifacts.tscn")
const CODEX_SCENE := preload("res://scenes/ui/expedition_codex.tscn")
const REWARD_OVERLAY_SCENE := preload("res://scenes/ui/expedition_reward_overlay.tscn")
const FORGE_SCENE := preload("res://scenes/ui/ember_forge.tscn")

var state: State = State.HUB
var arena: Arena
var skill_instances: Array[SkillInstance] = []
var last_result: String = ""
var hub: ExpeditionHub
var map_ui: ExpeditionMapUI
var artifacts_ui: ExpeditionArtifactsUI
var codex_ui: ExpeditionCodexUI
var reward_overlay: ExpeditionRewardOverlay
var forge_ui: Control
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
	hub.codex_pressed.connect(open_codex, CONNECT_ONE_SHOT)
	hub.forge_pressed.connect(open_forge, CONNECT_ONE_SHOT)

func open_forge() -> void:
	_clear_ui()
	forge_ui = FORGE_SCENE.instantiate() as Control
	_ui_layer.add_child(forge_ui)
	forge_ui.setup(ExpeditionManager.profile)
	forge_ui.purchase_requested.connect(_on_forge_purchase)
	forge_ui.back_pressed.connect(open_hub, CONNECT_ONE_SHOT)

func _on_forge_purchase(id: String) -> void:
	ExpeditionManager.buy_forge_commitment(id)
	forge_ui.setup(ExpeditionManager.profile)

func open_codex() -> void:
	_clear_ui()
	codex_ui = CODEX_SCENE.instantiate() as ExpeditionCodexUI
	_ui_layer.add_child(codex_ui)
	codex_ui.setup(ExpeditionManager.profile)
	codex_ui.back_pressed.connect(open_hub, CONNECT_ONE_SHOT)

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
	if ExpeditionManager.session != null and not ExpeditionManager.session.unresolved_reward_id.is_empty():
		_show_unresolved_reward()
		return
	map_ui = MAP_SCENE.instantiate() as ExpeditionMapUI
	_ui_layer.add_child(map_ui)
	map_ui.setup(ExpeditionManager.session)
	map_ui.room_chosen.connect(enter_room)
	map_ui.abandon_pressed.connect(abandon_expedition, CONNECT_ONE_SHOT)

func start_new_expedition(seed_value: int, blood_omen: bool = false) -> bool:
	if ExpeditionManager.profile == null:
		ExpeditionManager.start_new_profile()
		if not ExpeditionManager.save_profile():
			return false
	if not ExpeditionManager.start_expedition(seed_value, "burning_grounds", blood_omen):
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
	artifact_runtime.setup(session.effective_artifact_ids(), skill_instances, arena, session.tempered_artifact_ids, ExpeditionManager.profile.selected_sigil_variant)
	artifact_runtime.artifact_triggered.connect(_on_artifact_triggered)
	artifact_runtime.synergy_triggered.connect(_on_synergy_triggered)
	(arena.player.get_node("SkillCaster") as SkillCaster).set_artifact_hooks(artifact_runtime.hooks)
	arena.stage_completed.connect(_on_stage_completed, CONNECT_ONE_SHOT)
	arena.start_stage(room.depth + 1, skill_instances, _make_stage_data(room))

func _on_artifact_triggered(artifact_id: String, world_position: Vector2) -> void:
	if arena != null:
		ArtifactVFX.spawn(arena, artifact_id, world_position)

func _on_synergy_triggered(synergy_id: StringName, world_position: Vector2) -> void:
	if ExpeditionManager.discover_synergy(str(synergy_id)) and arena != null:
		ArtifactVFX.spawn(arena, str(synergy_id), world_position)

func _make_stage_data(room: DungeonRoomData) -> StageData:
	var stage := StageData.new()
	stage.depth = room.depth + 1 + (1 if room.type == DungeonRoomData.Type.BOSS and ExpeditionManager.session != null and ExpeditionManager.session.blood_omen_active else 0)
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
	var room := ExpeditionManager.session.layout.rooms.get(_active_room_id) as DungeonRoomData
	var reward_start := ExpeditionManager.session.pending_rewards.size()
	if not checkpoint_room_rewards(room):
		ExpeditionManager.session = ExpeditionSession.from_dict(snapshot)
		var retry_room := ExpeditionManager.session.layout.rooms.get(_active_room_id) as DungeonRoomData
		_clear_arena()
		_start_combat(retry_room)
		return
	var rewards := _rewards_since(reward_start)
	_clear_arena()
	if won:
		if not ExpeditionManager.session.unresolved_reward_id.is_empty():
			_show_reward_overlay(rewards)
		elif ExpeditionManager.settle_victory():
			last_result = "victory"
			open_hub()
			_show_reward_overlay(rewards)
	else:
		show_map()
		_show_reward_overlay(rewards)

func _complete_non_combat_room() -> void:
	var session := ExpeditionManager.session
	var snapshot := session.to_dict().duplicate(true)
	var completion_id := "%s:%s" % [session.session_id, _active_room_id]
	var room := session.layout.rooms.get(_active_room_id) as DungeonRoomData
	var reward_start := session.pending_rewards.size()
	if session.complete_current_room(completion_id, session.current_hp, session.max_hp) \
		and not checkpoint_room_rewards(room):
		ExpeditionManager.session = ExpeditionSession.from_dict(snapshot)
		show_map()
		return
	show_map()
	_show_reward_overlay(_rewards_since(reward_start))

func checkpoint_room_rewards(room: DungeonRoomData) -> bool:
	var session := ExpeditionManager.session
	if session == null or room == null:
		return false
	var snapshot := session.to_dict().duplicate(true)
	var profile_snapshot := ExpeditionManager.profile.to_dict().duplicate(true)
	var rewards := _roll_rewards_for(room)
	for reward: Dictionary in rewards:
		if not session.rolled_reward_ids.has(str(reward.get("reward_id", ""))):
			var artifact_ids: Array = reward.get("artifact_ids", [])
			reward["is_duplicate"] = not artifact_ids.is_empty() and ExpeditionManager.profile.owned_artifact_ids.has(str(artifact_ids[0]))
			session.record_reward(reward)
	if ExpeditionManager.save_session():
		for reward: Dictionary in rewards:
			var commitment_ids: Array[String] = []
			for value: Variant in reward.get("forge_commitment_ids", []):
				var id := str(value)
				if not id.is_empty() and not commitment_ids.has(id): commitment_ids.append(id)
			var single_id := str(reward.get("forge_commitment_id", ""))
			if not single_id.is_empty() and not commitment_ids.has(single_id): commitment_ids.append(single_id)
			if not commitment_ids.is_empty() and not ExpeditionManager.consume_forge_commitments(commitment_ids, str(reward.get("reward_id", ""))):
				ExpeditionManager.profile = ExpeditionProfile.from_dict(profile_snapshot)
				ExpeditionManager.session = ExpeditionSession.from_dict(snapshot)
				ExpeditionManager.save_session()
				return false
		return true
	ExpeditionManager.session = ExpeditionSession.from_dict(snapshot)
	return false

func _roll_rewards_for(room: DungeonRoomData) -> Array[Dictionary]:
	var session := ExpeditionManager.session
	var rewards: Array[Dictionary] = []
	if room.type == DungeonRoomData.Type.ELITE:
		var id := session.reward_id_for(room.id)
		if not session.rolled_reward_ids.has(id):
			rewards.append(ExpeditionLootRoller.roll(ExpeditionLootCatalog.get_table("burning_elite"), session.seed_value, id, "elite", session.difficulty, ExpeditionManager.profile.pity_counters, ExpeditionManager.profile.owned_artifact_ids.duplicate(), ExpeditionManager.profile.forge_commitments.duplicate()))
	elif room.type == DungeonRoomData.Type.TREASURE:
		var id := session.reward_id_for(room.id)
		if not session.rolled_reward_ids.has(id):
			rewards.append(ExpeditionLootRoller.roll(ExpeditionLootCatalog.get_table("burning_treasure"), session.seed_value, id, "treasure", session.difficulty, ExpeditionManager.profile.pity_counters, ExpeditionManager.profile.owned_artifact_ids.duplicate(), ExpeditionManager.profile.forge_commitments.duplicate()))
	elif room.type == DungeonRoomData.Type.BOSS:
		var set_id := session.reward_id_for(room.id, "boss_set")
		var chase_id := session.reward_id_for(room.id, "boss_chase")
		if not session.rolled_reward_ids.has(set_id):
			rewards.append(ExpeditionLootRoller.roll(ExpeditionLootCatalog.get_table("burning_boss_set"), session.seed_value, set_id, "boss_set", session.difficulty, ExpeditionManager.profile.pity_counters, ExpeditionManager.profile.owned_artifact_ids.duplicate(), ExpeditionManager.profile.forge_commitments.duplicate()))
		if not session.rolled_reward_ids.has(chase_id):
			rewards.append(ExpeditionLootRoller.roll_chase(session.seed_value, chase_id, session.difficulty, ExpeditionManager.profile.pity_counters, session.blood_omen_active, ExpeditionManager.profile.owned_artifact_ids.has(ExpeditionLootRoller.CHASE_ID)))
	return rewards

func _rewards_since(start: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if ExpeditionManager.session == null:
		return result
	for index: int in range(start, ExpeditionManager.session.pending_rewards.size()):
		result.append(ExpeditionManager.session.pending_rewards[index])
	return result

func _show_reward_overlay(rewards: Array[Dictionary]) -> void:
	if _ui_layer == null:
		return
	if ExpeditionManager.session != null and not ExpeditionManager.session.unresolved_reward_id.is_empty():
		_show_unresolved_reward()
		return
	if rewards.is_empty(): return
	reward_overlay = REWARD_OVERLAY_SCENE.instantiate() as ExpeditionRewardOverlay
	_ui_layer.add_child(reward_overlay)
	reward_overlay.setup(rewards)
	reward_overlay.confirmed.connect(func() -> void: reward_overlay = null, CONNECT_ONE_SHOT)

func _show_unresolved_reward() -> void:
	if reward_overlay != null and is_instance_valid(reward_overlay) and not reward_overlay.is_queued_for_deletion(): return
	var session := ExpeditionManager.session
	if session == null or session.unresolved_reward_id.is_empty() or _ui_layer == null: return
	var reward := session.get_reward(session.unresolved_reward_id)
	if reward.is_empty(): return
	reward_overlay = REWARD_OVERLAY_SCENE.instantiate() as ExpeditionRewardOverlay
	_ui_layer.add_child(reward_overlay)
	reward_overlay.setup_decision(reward, session)
	reward_overlay.decision_requested.connect(_on_reward_decision, CONNECT_ONE_SHOT)

func _on_reward_decision(reward_id: String, action: String, slot: int) -> void:
	var session := ExpeditionManager.session
	if session == null: return
	var snapshot := session.to_dict().duplicate(true)
	if not session.resolve_reward(reward_id, action, slot) or not ExpeditionManager.save_session():
		ExpeditionManager.session = ExpeditionSession.from_dict(snapshot)
		_clear_ui()
		_show_unresolved_reward()
		return
	if session.status == "victory":
		if ExpeditionManager.settle_victory():
			last_result = "victory"
			open_hub()
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
	forge_ui = null
	reward_overlay = null
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
