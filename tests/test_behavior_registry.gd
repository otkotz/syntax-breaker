extends GutTest

var _registry: Node

func before_each() -> void:
	_registry = preload("res://scripts/autoloads/behavior_registry.gd").new()
	_registry._ready()

func after_each() -> void:
	_registry.free()

func test_registered_behavior_exists() -> void:
	assert_true(_registry.has_behavior("pierce"))

func test_get_returns_behavior_instance() -> void:
	var b := _registry.get_behavior("pierce")
	assert_not_null(b)
	assert_is(b, BehaviorBase)

func test_unknown_key_returns_null() -> void:
	var b := _registry.get_behavior("nonexistent")
	assert_null(b)
