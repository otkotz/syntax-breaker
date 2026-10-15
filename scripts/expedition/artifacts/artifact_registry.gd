class_name ArtifactRegistry
extends RefCounted

var _factories: Dictionary = {}

func register_factory(behavior_key: StringName, factory: Callable) -> void:
	if not behavior_key.is_empty() and factory.is_valid():
		_factories[behavior_key] = factory

func create(behavior_key: StringName) -> ArtifactBehavior:
	var factory: Callable = _factories.get(behavior_key, Callable())
	if not factory.is_valid():
		return null
	var behavior: Variant = factory.call()
	return behavior as ArtifactBehavior
