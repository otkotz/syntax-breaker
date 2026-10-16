extends Node

const PROFILE_SAVE_PATH := "user://expedition_profile.json"
const SESSION_SAVE_PATH := "user://active_expedition.json"

var profile_path: String = PROFILE_SAVE_PATH
var session_path: String = SESSION_SAVE_PATH
var profile: ExpeditionProfile = ExpeditionProfile.new()
var session: ExpeditionSession = null

func start_new_profile() -> void:
	profile = ExpeditionProfile.new()

func save_profile() -> bool:
	if profile == null:
		return false
	return _write_json_atomic(profile_path, profile.to_dict())

func load_profile() -> bool:
	profile = ExpeditionProfile.new()
	for candidate: String in [profile_path, profile_path + ".bak", profile_path + ".tmp"]:
		var data := _read_json_dictionary(candidate)
		if data.is_empty() or typeof(data.get("schema_version")) not in [TYPE_INT, TYPE_FLOAT] \
			or int(data.get("schema_version")) not in [1, ExpeditionProfile.SCHEMA_VERSION]:
			continue
		profile = ExpeditionProfile.from_dict(data)
		if candidate != profile_path:
			save_profile()
		return true
	return false

func equip_artifact(artifact_id: String, slot: int) -> bool:
	if profile == null or session != null or has_saved_session() or slot < 0 or slot >= ArtifactLoadout.SLOT_COUNT:
		return false
	if not profile.owned_artifact_ids.has(artifact_id) or profile.equipped_artifact_ids.has(artifact_id):
		return false
	var previous := profile.equipped_artifact_ids.duplicate()
	profile.equipped_artifact_ids[slot] = artifact_id
	if save_profile():
		return true
	profile.equipped_artifact_ids = previous
	return false

func unequip_artifact(slot: int) -> bool:
	if profile == null or session != null or has_saved_session() or slot < 0 or slot >= ArtifactLoadout.SLOT_COUNT:
		return false
	var previous := profile.equipped_artifact_ids.duplicate()
	profile.equipped_artifact_ids[slot] = ""
	if save_profile():
		return true
	profile.equipped_artifact_ids = previous
	return false

func has_saved_session() -> bool:
	return FileAccess.file_exists(session_path)

func start_expedition(seed_value: int, region_id: String) -> bool:
	if profile == null or not profile.unlocked_regions.has(region_id):
		return false
	session = ExpeditionSession.create(seed_value, region_id, profile.equipped_artifact_ids.duplicate())
	return save_session()

func save_session() -> bool:
	if session == null:
		return false
	return _write_json_atomic(session_path, session.to_dict())

func load_session() -> bool:
	session = null
	for candidate: String in [session_path, session_path + ".bak", session_path + ".tmp"]:
		var data := _read_json_dictionary(candidate)
		if data.is_empty():
			continue
		session = ExpeditionSession.from_dict(data)
		if session != null:
			if candidate != session_path:
				save_session()
			return true
	return false

func clear_active_session() -> void:
	session = null
	_remove_file(session_path)
	_remove_file(session_path + ".tmp")
	_remove_file(session_path + ".bak")

func _write_json_atomic(path: String, data: Dictionary) -> bool:
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return false
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temporary_path := ProjectSettings.globalize_path(temporary_path)
	var backup_path := path + ".bak"
	var absolute_backup_path := ProjectSettings.globalize_path(backup_path)
	_remove_file(backup_path)
	if FileAccess.file_exists(path) and DirAccess.rename_absolute(absolute_path, absolute_backup_path) != OK:
		return false
	var error := DirAccess.rename_absolute(
		absolute_temporary_path,
		absolute_path
	)
	if error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(absolute_backup_path, absolute_path)
		return false
	_remove_file(backup_path)
	return true

func _read_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	return json.data as Dictionary

func _remove_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
