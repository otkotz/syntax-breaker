class_name ExpeditionSession
extends RefCounted

const SCHEMA_VERSION := 2
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

static func create(seed_value: int, region_id: String, artifact_ids: Array[String] = []) -> ExpeditionSession:
	var result := ExpeditionSession.new()
	result.session_id = "%d-%d" % [int(Time.get_unix_time_from_system()), seed_value]
	result.seed_value = seed_value
	result.region_id = region_id
	result.layout = DungeonGenerator.generate(seed_value, region_id)
	result.current_room_id = result.layout.start_room_id
	result.completed_room_ids = [result.layout.start_room_id]
	result.artifact_loadout_ids = ArtifactLoadout.normalize(ArtifactCatalog.all_ids(), artifact_ids)
	result._sync_layout()
	return result

func get_available_room_ids() -> Array[String]:
	if layout == null:
		return []
	if not completed_room_ids.has(current_room_id):
		return []
	_sync_layout()
	return layout.get_available_room_ids()

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
	}

static func from_dict(data: Dictionary) -> ExpeditionSession:
	if typeof(data.get("schema_version")) not in [TYPE_INT, TYPE_FLOAT]:
		return null
	var schema_version := int(data.get("schema_version"))
	if schema_version not in [1, SCHEMA_VERSION]:
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
		data.get("artifact_loadout_ids", []) if schema_version == SCHEMA_VERSION else [])
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

func _sync_layout() -> void:
	if layout == null:
		return
	layout.current_room_id = current_room_id
	layout.completed_room_ids = completed_room_ids.duplicate()
