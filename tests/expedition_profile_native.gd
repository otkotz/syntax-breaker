extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	ExpeditionManager.profile_path = "res://.godot/expedition_profile_test.json"
	ExpeditionManager.session_path = "res://.godot/expedition_session_test.json"
	_cleanup_files()

	ExpeditionManager.start_new_profile()
	ExpeditionManager.profile.level = 7
	check(ExpeditionManager.save_profile(), "Profile saves")
	ExpeditionManager.profile = null
	check(ExpeditionManager.load_profile(), "Profile loads")
	check(ExpeditionManager.profile.level == 7, "Level survives roundtrip")

	var broken := FileAccess.open(ExpeditionManager.profile_path, FileAccess.WRITE)
	broken.store_string("{broken")
	broken.close()
	check(not ExpeditionManager.load_profile(), "Malformed JSON reports failure")
	check(ExpeditionManager.profile != null and ExpeditionManager.profile.level == 1, "Malformed JSON falls back safely")

	var future := FileAccess.open(ExpeditionManager.profile_path, FileAccess.WRITE)
	future.store_string(JSON.stringify({"schema_version": 999, "level": 42}))
	future.close()
	check(not ExpeditionManager.load_profile(), "Unknown schema reports failure")
	check(ExpeditionManager.profile != null and ExpeditionManager.profile.level == 1, "Unknown schema falls back safely")
	check(ExpeditionManager.profile_path != RunManager.save_path, "Expedition never aliases roguelite save")

	_cleanup_files()
	print(JSON.stringify({"failures": failures, "schema_version": ExpeditionProfile.SCHEMA_VERSION}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _cleanup_files() -> void:
	for path: String in [
		ExpeditionManager.profile_path,
		ExpeditionManager.profile_path + ".tmp",
		ExpeditionManager.session_path,
		ExpeditionManager.session_path + ".tmp",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
