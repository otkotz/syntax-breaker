extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	var session := ExpeditionSession.create(20261014, "burning_grounds")
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
	check(not ExpeditionManager.start_expedition(1, "locked_region"), "Locked region cannot start")
	check(ExpeditionManager.start_expedition(20261014, "burning_grounds"), "Unlocked expedition starts and saves")
	ExpeditionManager.session.enter_room("room_1")
	ExpeditionManager.session.complete_current_room("manager-clear", 61.0, 100.0)
	check(ExpeditionManager.save_session(), "Session checkpoint saves")
	ExpeditionManager.session = null
	check(ExpeditionManager.load_session(), "Session checkpoint loads")
	check(ExpeditionManager.session.current_hp == 61.0, "Manager roundtrip preserves health")

	_cleanup_files()
	print(JSON.stringify({"failures": failures, "available": session.get_available_room_ids()}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _cleanup_files() -> void:
	for path: String in [
		ExpeditionManager.profile_path,
		ExpeditionManager.profile_path + ".tmp",
		ExpeditionManager.session_path,
		ExpeditionManager.session_path + ".tmp",
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
