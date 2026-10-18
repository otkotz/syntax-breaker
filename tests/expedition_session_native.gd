extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	var session := ExpeditionSession.create(20261014, "burning_grounds", ["fractured_prism", "", "furnace_heart", ""])
	check(session.difficulty == 1, "New sessions use difficulty one")
	check(session.artifact_loadout_ids == ["fractured_prism", "", "furnace_heart", ""], "Session captures four artifact slots")
	check(session.echo_artifact_ids == ["", "", "", ""], "New session starts without Echo overrides")
	check(session.effective_artifact_ids() == session.artifact_loadout_ids, "Empty Echo keeps frozen loadout effective")
	var echo_preview: Dictionary = session.preview_echo("ashen_needle", 1)
	check(echo_preview.get("valid", false), "Echo preview accepts a free replacement")
	check(echo_preview.get("after_ids", []) == ["fractured_prism", "ashen_needle", "furnace_heart", ""], "Echo preview exposes effective replacement")
	check(session.apply_echo("ashen_needle", 1), "Echo replaces one frozen slot")
	check(session.effective_artifact_ids() == ["fractured_prism", "ashen_needle", "furnace_heart", ""], "Echo becomes effective for the session")
	check(not session.apply_echo("fractured_prism", 2), "Echo rejects duplicate effective artifacts")
	check(not session.apply_echo("future_artifact", 4), "Echo rejects out-of-range slots")
	check(session.apply_echo("", 1), "Clearing Echo restores the frozen slot")
	check(session.effective_artifact_ids() == session.artifact_loadout_ids, "Cleared Echo restores frozen loadout")
	check(session.apply_echo("future_artifact", 3), "Echo preserves forward-compatible artifact ids")
	var decision_reward := {"reward_id": "decision:1", "source_tag": "elite", "artifact_ids": ["ashen_needle"], "shard_amount": 0, "pity_key": "", "chase_awarded": false}
	check(session.record_reward(decision_reward), "Artifact reward is recorded for a decision")
	check(session.unresolved_reward_id == "decision:1", "First artifact reward locks progression until resolved")
	check(not session.resolve_reward("wrong", "keep_loadout"), "Only the unresolved reward can be resolved")
	check(session.resolve_reward("decision:1", "echo", 1), "Echo decision resolves into the selected slot")
	check(session.unresolved_reward_id.is_empty() and session.effective_artifact_ids()[1] == "ashen_needle", "Resolved Echo clears the lock and updates effective loadout")
	check(session.get_available_room_ids().size() == 2, "Start exposes two routes")
	check(not session.enter_room("missing"), "Unknown room cannot be entered")
	check(not session.enter_room("room_4"), "Locked boss cannot be entered")
	check(session.current_room_id == "room_0", "Rejected entry does not mutate current room")
	check(session.enter_room("room_1"), "Reachable room can be entered")
	check(session.get_available_room_ids().is_empty(), "Unfinished room blocks forward navigation")
	check(session.complete_current_room("clear-room-1", 72.0, 100.0), "Room completes once")
	check(not session.complete_current_room("clear-room-1", 10.0, 100.0), "Duplicate completion is ignored")
	check(session.current_hp == 72.0, "Duplicate completion cannot overwrite state")
	check(not session.enter_room("room_1"), "Completed room cannot be entered again")
	var restored := ExpeditionSession.from_dict(session.to_dict())
	check(restored != null and restored.to_dict() == session.to_dict(), "Session survives roundtrip")
	check(restored != null and restored.echo_artifact_ids == ["", "ashen_needle", "", "future_artifact"], "Echo survives save and resume")
	var schema_three := session.to_dict()
	schema_three["schema_version"] = 3
	schema_three.erase("echo_artifact_ids")
	var migrated_three := ExpeditionSession.from_dict(schema_three)
	check(migrated_three != null and migrated_three.echo_artifact_ids == ["", "", "", ""], "Schema three migrates to empty Echo slots")
	check(migrated_three != null and migrated_three.unresolved_reward_id.is_empty(), "Schema three migrates without an unresolved choice")
	var schema_five := session.to_dict()
	schema_five["schema_version"] = 5
	schema_five.erase("tempered_artifact_ids")
	var migrated_five := ExpeditionSession.from_dict(schema_five)
	check(migrated_five != null and migrated_five.tempered_artifact_ids.is_empty(), "Schema five migrates without run-only Temper state")
	var schema_six := session.to_dict()
	schema_six["schema_version"] = 6
	schema_six.erase("blood_omen_active")
	var migrated_six := ExpeditionSession.from_dict(schema_six)
	check(migrated_six != null and not migrated_six.blood_omen_active, "Schema six migrates with Blood Omen inactive")
	var schema_one := session.to_dict()
	schema_one["schema_version"] = 1
	schema_one.erase("artifact_loadout_ids")
	var migrated := ExpeditionSession.from_dict(schema_one)
	check(migrated != null and migrated.artifact_loadout_ids == ["", "", "", ""] and migrated.difficulty == 1, "Schema one session migrates to empty slots and difficulty one")
	var corrupt_slots := session.to_dict()
	corrupt_slots["artifact_loadout_ids"] = ["furnace_heart", null, "furnace_heart", "missing", "ashen_needle"]
	var normalized := ExpeditionSession.from_dict(corrupt_slots)
	check(normalized != null and normalized.artifact_loadout_ids == ["furnace_heart", "", "", "missing"], "Corrupt session slots normalize while preserving unknown ids")
	var future_slots := session.to_dict()
	future_slots["artifact_loadout_ids"] = ["future_artifact", "", "", ""]
	var future_session := ExpeditionSession.from_dict(future_slots)
	check(future_session != null and future_session.artifact_loadout_ids[0] == "future_artifact", "Unknown artifact id survives session roundtrip")
	var future_created := ExpeditionSession.create(8, "burning_grounds", ["future_artifact", "", "", ""])
	check(future_created.artifact_loadout_ids[0] == "future_artifact", "Unknown artifact id survives new-session snapshot")

	var clamped := ExpeditionSession.create(7, "burning_grounds")
	check(clamped.enter_room("room_1"), "Clamp fixture enters room")
	check(clamped.complete_current_room("clamp", -5.0, 0.0), "Invalid health is normalized")
	check(clamped.current_hp == 0.0 and clamped.max_hp == 1.0, "Health clamps to valid range")

	var dead_graph_data := session.to_dict()
	var dead_layout: Dictionary = dead_graph_data["layout"]
	var dead_edges: Dictionary = dead_layout["edges"]
	dead_edges["room_3"] = []
	check(ExpeditionSession.from_dict(dead_graph_data) == null, "Session rejects graph without reachable boss")
	var invalid_health_data := session.to_dict()
	invalid_health_data["current_hp"] = -1.0
	invalid_health_data["max_hp"] = 0.0
	check(ExpeditionSession.from_dict(invalid_health_data) == null, "Session rejects invalid persisted health")
	var invalid_shape_data := session.to_dict()
	invalid_shape_data["completed_room_ids"] = null
	check(ExpeditionSession.from_dict(invalid_shape_data) == null, "Session rejects malformed collection types")
	var invalid_nested_data := session.to_dict().duplicate(true)
	invalid_nested_data["layout"]["rooms"][0]["depth"] = {"bad": true}
	check(ExpeditionSession.from_dict(invalid_nested_data) == null, "Session rejects malformed nested room fields")

	ExpeditionManager.profile_path = "res://.godot/expedition_session_profile_test.json"
	ExpeditionManager.session_path = "res://.godot/expedition_session_test.json"
	_cleanup_files()
	ExpeditionManager.start_new_profile()
	ExpeditionManager.profile.equipped_artifact_ids = ["fractured_prism", "furnace_heart", "", ""]
	check(not ExpeditionManager.start_expedition(1, "locked_region"), "Locked region cannot start")
	check(ExpeditionManager.start_expedition(20261014, "burning_grounds"), "Unlocked expedition starts and saves")
	ExpeditionManager.profile.equipped_artifact_ids[0] = "bloodwritten_sigil"
	check(ExpeditionManager.session.artifact_loadout_ids[0] == "fractured_prism", "Active session ignores later profile changes")
	check(ExpeditionManager.session.apply_echo("ashen_needle", 0), "Manager session accepts an Echo override")
	check(ExpeditionManager.profile.equipped_artifact_ids[0] == "bloodwritten_sigil", "Echo never mutates the permanent profile")
	ExpeditionManager.session.enter_room("room_1")
	ExpeditionManager.session.complete_current_room("manager-clear", 61.0, 100.0)
	check(ExpeditionManager.save_session(), "Session checkpoint saves")
	ExpeditionManager.session = null
	check(ExpeditionManager.load_session(), "Session checkpoint loads")
	check(ExpeditionManager.session.current_hp == 61.0, "Manager roundtrip preserves health")
	check(ExpeditionManager.session.artifact_loadout_ids == ["fractured_prism", "furnace_heart", "", ""], "Manager roundtrip preserves frozen artifacts")
	check(ExpeditionManager.session.echo_artifact_ids == ["ashen_needle", "", "", ""], "Manager roundtrip preserves Echo overrides")
	ExpeditionManager.session = null
	DirAccess.rename_absolute(ProjectSettings.globalize_path(ExpeditionManager.session_path),
		ProjectSettings.globalize_path(ExpeditionManager.session_path + ".bak"))
	check(ExpeditionManager.has_saved_session(), "Recoverable backup keeps session and loadout locked")
	check(ExpeditionManager.load_session(), "Session loads from recoverable backup")
	_cleanup_files()
	ExpeditionManager.session_path = "res://missing_directory/session.json"
	check(not ExpeditionManager.start_expedition(99, "burning_grounds"), "Failed initial checkpoint reports failure")
	check(ExpeditionManager.session == null, "Failed initial checkpoint rolls in-memory session back")

	_cleanup_files()
	print(JSON.stringify({"failures": failures, "available": session.get_available_room_ids()}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _cleanup_files() -> void:
	for path: String in [
		ExpeditionManager.profile_path,
		ExpeditionManager.profile_path + ".tmp",
		ExpeditionManager.session_path,
		ExpeditionManager.session_path + ".tmp",
		ExpeditionManager.session_path + ".bak",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
