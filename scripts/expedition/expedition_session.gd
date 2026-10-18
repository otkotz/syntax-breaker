class_name ExpeditionSession
extends RefCounted

const SCHEMA_VERSION := 8
const VALID_STATUSES: Array[String] = ["active", "victory", "failed"]

var session_id: String = ""
var seed_value: int = 0
var region_id: String = ""
var layout: DungeonLayout
var current_room_id: String = ""
var completed_room_ids: Array[String] = []
var completion_ids: Array[String] = []
var current_hp: float = 100.0
var max_hp: float = 100.0
var status: String = "active"
var artifact_loadout_ids: Array[String] = ["", "", "", ""]
var echo_artifact_ids: Array[String] = ["", "", "", ""]
var unresolved_reward_id: String = ""
var tempered_artifact_ids: Array[String] = []
var blood_omen_active: bool = false
var difficulty: int = 1
var pending_rewards: Array[Dictionary] = []
var rolled_reward_ids: Array[String] = []
var telemetry_snapshot: Dictionary = {}

static func create(seed_value: int, region_id: String, artifact_ids: Array[String] = []) -> ExpeditionSession:
	var result := ExpeditionSession.new()
	result.session_id = "%d-%d" % [int(Time.get_unix_time_from_system()), seed_value]
	result.seed_value = seed_value
	result.region_id = region_id
	result.layout = DungeonGenerator.generate(seed_value, region_id)
	result.current_room_id = result.layout.start_room_id
	result.completed_room_ids = [result.layout.start_room_id]
	result.artifact_loadout_ids = ArtifactLoadout.normalize_snapshot(artifact_ids)
	result._sync_layout()
	return result

func get_available_room_ids() -> Array[String]:
	if layout == null:
		return []
	if not completed_room_ids.has(current_room_id):
		return []
	_sync_layout()
	return layout.get_available_room_ids()

func activate_blood_omen(profile: ExpeditionProfile) -> bool:
	var omen := preload("res://scripts/expedition/blood_omen.gd")
	if blood_omen_active or not omen.is_available(profile): return false
	blood_omen_active = true
	return true

func can_enter(room_id: String) -> bool:
	return status == "active" \
		and layout != null \
		and layout.rooms.has(room_id) \
		and not completed_room_ids.has(room_id) \
		and get_available_room_ids().has(room_id)

func enter_room(room_id: String) -> bool:
	if not can_enter(room_id):
		return false
	current_room_id = room_id
	_sync_layout()
	return true

func complete_current_room(completion_id: String, hp: float, hp_max: float) -> bool:
	if completion_id.is_empty() or completion_ids.has(completion_id):
		return false
	if layout == null or current_room_id.is_empty() or completed_room_ids.has(current_room_id):
		return false
	completion_ids.append(completion_id)
	completed_room_ids.append(current_room_id)
	max_hp = maxf(1.0, hp_max)
	current_hp = clampf(hp, 0.0, max_hp)
	if current_room_id == layout.boss_room_id:
		status = "victory"
	_sync_layout()
	return true

func reward_id_for(room_id: String, suffix: String = "room") -> String:
	return "%s:%s:%s" % [session_id, room_id, suffix]

func record_reward(reward: Dictionary) -> bool:
	if not _is_valid_reward(reward):
		return false
	var reward_id := str(reward.get("reward_id"))
	if rolled_reward_ids.has(reward_id):
		return false
	pending_rewards.append(reward.duplicate(true))
	rolled_reward_ids.append(reward_id)
	if unresolved_reward_id.is_empty() and (not reward.get("artifact_ids", []).is_empty() or not reward.get("alternative_artifact_ids", []).is_empty()):
		unresolved_reward_id = reward_id
	return true

func get_reward(reward_id: String) -> Dictionary:
	for reward: Dictionary in pending_rewards:
		if reward.get("reward_id", "") == reward_id:
			return reward.duplicate(true)
	return {}

func effective_artifact_ids() -> Array[String]:
	return ArtifactLoadout.apply_slot_overrides(artifact_loadout_ids, echo_artifact_ids)

func preview_echo(artifact_id: String, slot: int) -> Dictionary:
	var before_ids := effective_artifact_ids()
	var valid := slot >= 0 and slot < ArtifactLoadout.SLOT_COUNT
	var after_ids := before_ids.duplicate()
	if valid:
		var next_echo := echo_artifact_ids.duplicate()
		next_echo[slot] = artifact_id
		after_ids = ArtifactLoadout.apply_slot_overrides(artifact_loadout_ids, next_echo)
		valid = artifact_id.is_empty() or after_ids[slot] == artifact_id
	return {
		"valid": valid,
		"slot": slot,
		"artifact_id": artifact_id,
		"before_ids": before_ids,
		"after_ids": after_ids,
		"before_set_tiers": ArtifactLoadout.active_set_tiers(before_ids),
		"after_set_tiers": ArtifactLoadout.active_set_tiers(after_ids),
	}

func apply_echo(artifact_id: String, slot: int) -> bool:
	var preview := preview_echo(artifact_id, slot)
	if not preview.get("valid", false):
		return false
	echo_artifact_ids[slot] = artifact_id
	return true

func resolve_reward(reward_id: String, action: String, slot: int = -1) -> bool:
	if reward_id.is_empty() or reward_id != unresolved_reward_id:
		return false
	var reward := get_reward(reward_id)
	var artifact_ids: Array = reward.get("artifact_ids", [])
	var reward_index := _reward_index(reward_id)
	if action in ["choose_original", "choose_alternative"]:
		if not pending_rewards[reward_index].has("alternative_artifact_ids") or bool(pending_rewards[reward_index].get("choice_selected", false)): return false
		if action == "choose_alternative":
			var alternative_ids: Array = pending_rewards[reward_index].get("alternative_artifact_ids", [])
			if alternative_ids.is_empty(): return false
			pending_rewards[reward_index]["artifact_ids"] = alternative_ids.duplicate()
		pending_rewards[reward_index]["choice_selected"] = true
		pending_rewards[reward_index]["treasure_choice_action"] = action
		if action == "choose_original" and artifact_ids.is_empty():
			pending_rewards[reward_index]["decision_action"] = "keep_loadout"
			unresolved_reward_id = _next_unresolved_reward_id(reward_id)
		return true
	artifact_ids = pending_rewards[reward_index].get("artifact_ids", [])
	if artifact_ids.is_empty(): return false
	var artifact_id := str(artifact_ids[0])
	if action == "echo":
		if not apply_echo(artifact_id, slot): return false
	elif action == "temper":
		if not bool(reward.get("is_duplicate", false)) or not effective_artifact_ids().has(artifact_id) or tempered_artifact_ids.has(artifact_id): return false
		tempered_artifact_ids.append(artifact_id)
		pending_rewards[reward_index]["decision_action"] = "temper"
	elif action == "shatter":
		if not bool(reward.get("is_duplicate", false)): return false
		var artifact := ArtifactCatalog.get_artifact(artifact_id)
		if artifact == null: return false
		pending_rewards[reward_index]["decision_action"] = "shatter"
		pending_rewards[reward_index]["decision_shard_amount"] = maxi(0, artifact.duplicate_shard_value)
	elif action != "keep_loadout":
		return false
	pending_rewards[reward_index]["decision_action"] = action
	unresolved_reward_id = _next_unresolved_reward_id(reward_id)
	return true

func _next_unresolved_reward_id(after_reward_id: String) -> String:
	var found_current := false
	for reward: Dictionary in pending_rewards:
		var candidate_id := str(reward.get("reward_id", ""))
		if candidate_id == after_reward_id:
			found_current = true
			continue
		if found_current and not reward.get("artifact_ids", []).is_empty() and str(reward.get("decision_action", "")).is_empty():
			return candidate_id
	return ""

func _reward_index(reward_id: String) -> int:
	for index in pending_rewards.size():
		if str(pending_rewards[index].get("reward_id", "")) == reward_id: return index
	return -1

func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"session_id": session_id,
		"seed_value": seed_value,
		"region_id": region_id,
		"layout": layout.serialize() if layout else {},
		"current_room_id": current_room_id,
		"completed_room_ids": completed_room_ids,
		"completion_ids": completion_ids,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"status": status,
		"artifact_loadout_ids": artifact_loadout_ids,
		"echo_artifact_ids": echo_artifact_ids,
		"unresolved_reward_id": unresolved_reward_id,
		"tempered_artifact_ids": tempered_artifact_ids,
		"blood_omen_active": blood_omen_active,
		"difficulty": difficulty,
		"pending_rewards": pending_rewards,
		"rolled_reward_ids": rolled_reward_ids,
		"telemetry_snapshot": telemetry_snapshot,
	}

static func from_dict(data: Dictionary) -> ExpeditionSession:
	if typeof(data.get("schema_version")) not in [TYPE_INT, TYPE_FLOAT]:
		return null
	var schema_version := int(data.get("schema_version"))
	if schema_version not in [1, 2, 3, 4, 5, 6, 7, SCHEMA_VERSION]:
		return null
	if not data.get("layout", {}) is Dictionary:
		return null
	if not data.get("completed_room_ids", []) is Array \
		or not data.get("completion_ids", []) is Array:
		return null
	var restored_layout := DungeonLayout.deserialize(data.get("layout", {}))
	if restored_layout.start_room_id.is_empty() or restored_layout.boss_room_id.is_empty():
		return null
	if not restored_layout.rooms.has(restored_layout.start_room_id) \
		or not restored_layout.rooms.has(restored_layout.boss_room_id) \
		or not restored_layout.has_path(restored_layout.start_room_id, restored_layout.boss_room_id):
		return null
	if typeof(data.get("max_hp")) not in [TYPE_INT, TYPE_FLOAT] \
		or typeof(data.get("current_hp")) not in [TYPE_INT, TYPE_FLOAT]:
		return null
	var restored_max_hp := float(data.get("max_hp"))
	var restored_hp := float(data.get("current_hp"))
	if restored_max_hp <= 0.0 or restored_hp < 0.0 or restored_hp > restored_max_hp:
		return null
	var restored_status := str(data.get("status", ""))
	if not VALID_STATUSES.has(restored_status):
		return null
	var restored_current_room_id := str(data.get("current_room_id", ""))
	if not restored_layout.rooms.has(restored_current_room_id):
		return null

	var result := ExpeditionSession.new()
	result.session_id = str(data.get("session_id", ""))
	result.seed_value = int(data.get("seed_value")) if typeof(data.get("seed_value")) in [TYPE_INT, TYPE_FLOAT] else restored_layout.seed_value
	result.region_id = str(data.get("region_id", restored_layout.region_id))
	result.layout = restored_layout
	result.current_room_id = restored_current_room_id
	result.current_hp = restored_hp
	result.max_hp = restored_max_hp
	result.status = restored_status
	result.artifact_loadout_ids = ArtifactLoadout.normalize_snapshot(
		data.get("artifact_loadout_ids", []) if schema_version >= 2 else [])
	result.echo_artifact_ids = ArtifactLoadout.normalize_snapshot(
		data.get("echo_artifact_ids", []) if schema_version >= 4 else [])
	if schema_version >= 3:
		if typeof(data.get("difficulty")) in [TYPE_INT, TYPE_FLOAT]:
			result.difficulty = maxi(1, int(data.get("difficulty")))
		var raw_rewards: Variant = data.get("pending_rewards", [])
		if raw_rewards is Array:
			for reward: Variant in raw_rewards:
				if reward is Dictionary:
					result.record_reward(reward)
	result.unresolved_reward_id = str(data.get("unresolved_reward_id", "")) if schema_version >= 5 else ""
	if schema_version >= 6:
		for value: Variant in data.get("tempered_artifact_ids", []):
			var artifact_id := str(value)
			if not artifact_id.is_empty() and not result.tempered_artifact_ids.has(artifact_id): result.tempered_artifact_ids.append(artifact_id)
	result.blood_omen_active = bool(data.get("blood_omen_active", false)) if schema_version >= 7 else false
	if schema_version >= 8 and data.get("telemetry_snapshot", {}) is Dictionary:
		result.telemetry_snapshot = data.get("telemetry_snapshot", {}).duplicate(true)
	for value: Variant in data.get("completed_room_ids", []):
		var room_id := str(value)
		if not restored_layout.rooms.has(room_id):
			return null
		if not result.completed_room_ids.has(room_id):
			result.completed_room_ids.append(room_id)
	for value: Variant in data.get("completion_ids", []):
		var completion_id := str(value)
		if completion_id.is_empty():
			return null
		if not result.completion_ids.has(completion_id):
			result.completion_ids.append(completion_id)
	result._sync_layout()
	return result

static func _is_valid_reward(reward: Dictionary) -> bool:
	if not reward.get("reward_id") is String or str(reward.get("reward_id")).is_empty():
		return false
	if not reward.get("source_tag", "") is String or not reward.get("artifact_ids", []) is Array:
		return false
	for artifact_id: Variant in reward.get("artifact_ids", []):
		if not artifact_id is String:
			return false
	if typeof(reward.get("shard_amount", 0)) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	if not reward.get("pity_key", "") is String or not reward.get("chase_awarded", false) is bool:
		return false
	return true

func _sync_layout() -> void:
	if layout == null:
		return
	layout.current_room_id = current_room_id
	layout.completed_room_ids = completed_room_ids.duplicate()
