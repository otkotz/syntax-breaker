extends Node

var _behaviors: Dictionary = {}

func register(key: String, behavior_script: GDScript) -> void:
	_behaviors[key] = behavior_script

func get_behavior(key: String) -> RefCounted:
	if _behaviors.has(key):
		return _behaviors[key].new()
	push_warning("BehaviorRegistry: unknown key '%s'" % key)
	return null

func has_behavior(key: String) -> bool:
	return _behaviors.has(key)
