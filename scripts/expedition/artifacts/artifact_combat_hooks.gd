class_name ArtifactCombatHooks
extends RefCounted

signal combat_event(event_name: StringName, context: Dictionary)

var active := true
var _next_event_id := 1
var active_artifact_ids: Array[String] = []

func emit_event(event_name: StringName, context: Dictionary = {}) -> void:
	if not active:
		return
	var payload := context.duplicate()
	if not payload.has("event_id"):
		payload["event_id"] = _next_event_id
		_next_event_id += 1
	if not payload.has("origin_flags"):
		payload["origin_flags"] = []
	if not payload.has("generation"):
		payload["generation"] = 0
	combat_event.emit(event_name, payload)

func deactivate() -> void:
	active = false
