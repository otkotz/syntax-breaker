extends Node

const PROFILE_SAVE_PATH := "user://expedition_profile.json"
const SESSION_SAVE_PATH := "user://active_expedition.json"

var profile_path: String = PROFILE_SAVE_PATH
var session_path: String = SESSION_SAVE_PATH
var profile: ExpeditionProfile = ExpeditionProfile.new()
var session: Variant = null

func start_new_profile() -> void:
	profile = ExpeditionProfile.new()

func save_profile() -> bool:
	if profile == null:
		return false
	return _write_json_atomic(profile_path, profile.to_dict())

func load_profile() -> bool:
	profile = ExpeditionProfile.new()
	if not FileAccess.file_exists(profile_path):
		return false
	var file := FileAccess.open(profile_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var data := parsed as Dictionary
	if int(data.get("schema_version", -1)) != ExpeditionProfile.SCHEMA_VERSION:
		return false
	profile = ExpeditionProfile.from_dict(data)
	return true

func clear_active_session() -> void:
	session = null
	_remove_file(session_path)
	_remove_file(session_path + ".tmp")

func _write_json_atomic(path: String, data: Dictionary) -> bool:
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	if FileAccess.file_exists(path) and not _remove_file(path):
		return false
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(path)
	)
	return error == OK

func _remove_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
