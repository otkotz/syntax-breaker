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
	check(ExpeditionManager.profile.owned_artifact_ids.is_empty(), "Fresh profile starts without artifacts")
	check(ExpeditionManager.profile.discovered_artifact_ids.is_empty(), "Fresh profile starts without discoveries")
	check(ExpeditionManager.profile.ember_shards == 0, "Fresh profile starts without Ember Shards")
	check(ExpeditionManager.profile.equipped_artifact_ids == ["", "", "", ""], "New profile has four empty slots")
	ExpeditionManager.profile.level = 7
	check(ExpeditionManager.save_profile(), "Profile saves")
	ExpeditionManager.profile = null
	check(ExpeditionManager.load_profile(), "Profile loads")
	check(ExpeditionManager.profile.level == 7, "Level survives roundtrip")
	check(ExpeditionManager.profile.equipped_artifact_ids.size() == 4, "Artifact slots survive roundtrip")

	var migrated := ExpeditionProfile.from_dict({"schema_version": 1, "level": 9, "experience": 23})
	check(migrated.level == 9 and migrated.experience == 23, "Schema one preserves progression")
	check(migrated.owned_artifact_ids == ArtifactCatalog.all_ids(), "Schema one unlocks prototype artifacts")
	var normalized := ExpeditionProfile.from_dict({
		"schema_version": 2,
		"owned_artifact_ids": ["furnace_heart", "ashen_needle", "future_artifact"],
		"equipped_artifact_ids": ["furnace_heart", null, "furnace_heart", "missing", "ashen_needle"],
	})
	check(normalized.equipped_artifact_ids == ["furnace_heart", "", "", ""], "Schema two normalizes corrupt slots")
	check(normalized.owned_artifact_ids.has("future_artifact"), "Schema two preserves unknown ownership")
	check(normalized.discovered_artifact_ids == ["furnace_heart", "ashen_needle"], "Schema two discovers owned known artifacts once")
	var future_artifact := ExpeditionProfile.from_dict({"schema_version": 2,
		"owned_artifact_ids": ["future_artifact"], "equipped_artifact_ids": ["future_artifact", "", "", ""]})
	check(future_artifact.owned_artifact_ids == ["future_artifact"] and future_artifact.equipped_artifact_ids[0] == "future_artifact", "Unknown artifact ids survive profile roundtrip")

	var history: Array[Dictionary] = []
	for index: int in range(105):
		history.append({"reward_id": "reward_%d" % index, "source_tag": "elite", "artifact_ids": ["future_artifact"]})
	var schema_three := ExpeditionProfile.from_dict({
		"schema_version": 3,
		"owned_artifact_ids": ["future_artifact", "future_artifact"],
		"discovered_artifact_ids": ["future_artifact", "future_artifact"],
		"ember_shards": -12,
		"pity_counters": {"burning_boss_sigil": -4, "valid": 2, "bad": "no"},
		"settled_reward_ids": ["reward_1", "reward_1", "reward_2", ""],
		"reward_history": history,
	})
	check(schema_three.owned_artifact_ids == ["future_artifact"], "Schema three deduplicates unknown ownership without deleting it")
	check(schema_three.discovered_artifact_ids == ["future_artifact"], "Schema three preserves and deduplicates unknown discoveries")
	check(schema_three.ember_shards == 0, "Ember Shards cannot become negative")
	check(schema_three.pity_counters == {"burning_boss_sigil": 0, "valid": 2}, "Pity counters are nonnegative and malformed values are skipped")
	check(schema_three.settled_reward_ids == ["reward_1", "reward_2"], "Settled reward IDs are nonempty and deduplicated")
	check(schema_three.reward_history.size() == 100 and schema_three.reward_history[0].get("reward_id") == "reward_5" and schema_three.reward_history[99].get("reward_id") == "reward_104", "Reward history retains the newest 100 entries")
	var schema_four := ExpeditionProfile.from_dict({"schema_version": 4, "discovered_synergy_ids": ["prism_needle_crossfire"]})
	check(schema_four.discovered_synergy_ids.is_empty(), "Schema four migrates without synergy discoveries")

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
	var malformed_shape := ExpeditionProfile.from_dict({"schema_version": 1, "level": "bad", "unlocked_regions": null})
	check(malformed_shape.level == 1 and malformed_shape.unlocked_regions == ["burning_grounds"], "Invalid field types fall back safely")

	var recoverable := ExpeditionProfile.new()
	recoverable.level = 8
	var interrupted := FileAccess.open(ExpeditionManager.profile_path + ".tmp", FileAccess.WRITE)
	interrupted.store_string(JSON.stringify(recoverable.to_dict()))
	interrupted.close()
	if FileAccess.file_exists(ExpeditionManager.profile_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ExpeditionManager.profile_path))
	check(ExpeditionManager.load_profile(), "Interrupted profile commit recovers temporary save")
	check(ExpeditionManager.profile.level == 8, "Recovered temporary save preserves data")
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
