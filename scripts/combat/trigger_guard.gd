class_name TriggerGuard
extends RefCounted

static var _trigger_depth: int = 0
const MAX_TRIGGER_DEPTH := 1

static var _target_cooldowns: Dictionary = {}
const TARGET_COOLDOWN := 0.25

static func can_trigger(target: Node2D = null) -> bool:
	if _trigger_depth >= MAX_TRIGGER_DEPTH:
		return false
	if target and _is_on_cooldown(target):
		return false
	return true

static func begin(target: Node2D = null) -> void:
	_trigger_depth += 1
	if target:
		_target_cooldowns[target.get_instance_id()] = Time.get_ticks_msec() / 1000.0

static func end() -> void:
	_trigger_depth = maxi(0, _trigger_depth - 1)

static func _is_on_cooldown(target: Node2D) -> bool:
	var eid := target.get_instance_id()
	if not _target_cooldowns.has(eid):
		return false
	var elapsed: float = Time.get_ticks_msec() / 1000.0 - float(_target_cooldowns[eid])
	if elapsed >= TARGET_COOLDOWN:
		_target_cooldowns.erase(eid)
		return false
	return true

static func clear() -> void:
	_trigger_depth = 0
	_target_cooldowns.clear()
