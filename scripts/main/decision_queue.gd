class_name DecisionQueue
extends Node

signal decision_ready(request: Dictionary)

var _pending: Array[Dictionary] = []
var _active: Dictionary = {}
var _sequence := 0

func enqueue(kind: StringName, payload: Dictionary = {}, priority: int = 0) -> int:
	_sequence += 1
	var request := {"id": _sequence, "kind": kind, "payload": payload.duplicate(true),
		"priority": priority, "sequence": _sequence}
	if not _active.is_empty() and priority > int(_active.get("priority", 0)):
		_pending.append(_active)
		_active = request
		_pending.sort_custom(func(a: Dictionary, b: Dictionary):
			return a.priority > b.priority if a.priority != b.priority else a.sequence < b.sequence)
		decision_ready.emit(_active.duplicate(true))
		return _sequence
	_pending.append(request)
	_pending.sort_custom(func(a: Dictionary, b: Dictionary):
		return a.priority > b.priority if a.priority != b.priority else a.sequence < b.sequence)
	_activate_next()
	return _sequence

func complete_active(_result: Dictionary = {}) -> bool:
	if _active.is_empty():
		return false
	_active.clear()
	call_deferred("_activate_next")
	return true

func cancel_active(_reason: String = "canceled") -> bool:
	if _active.is_empty():
		return false
	_active.clear()
	call_deferred("_activate_next")
	return true

func clear() -> void:
	_pending.clear()
	_active.clear()

func active_request() -> Dictionary:
	return _active.duplicate(true)

func pending_count() -> int:
	return _pending.size()

func _activate_next() -> void:
	if not _active.is_empty() or _pending.is_empty():
		return
	_active = _pending.pop_front()
	decision_ready.emit(_active.duplicate(true))
