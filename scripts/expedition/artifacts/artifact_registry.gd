class_name ArtifactRegistry
extends RefCounted

var _factories: Dictionary = {}

static func with_defaults() -> ArtifactRegistry:
	var result := ArtifactRegistry.new()
	result.register_factory(&"fractured_prism", func(): return IndependentArtifactBehaviors.create(&"fractured_prism"))
	result.register_factory(&"echoing_hourglass", func(): return IndependentArtifactBehaviors.create(&"echoing_hourglass"))
	result.register_factory(&"bloodwritten_sigil", func(): return IndependentArtifactBehaviors.create(&"bloodwritten_sigil"))
	return result

func register_factory(behavior_key: StringName, factory: Callable) -> void:
	if not behavior_key.is_empty() and factory.is_valid():
		_factories[behavior_key] = factory

func create(behavior_key: StringName) -> ArtifactBehavior:
	var factory: Callable = _factories.get(behavior_key, Callable())
	if not factory.is_valid():
		return null
	var behavior: Variant = factory.call()
	return behavior as ArtifactBehavior
