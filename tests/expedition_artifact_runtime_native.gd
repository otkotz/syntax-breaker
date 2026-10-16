extends Node

class FakeBehavior extends ArtifactBehavior:
	var setup_count := 0
	var event_count := 0
	var teardown_count := 0
	func setup(_context: Dictionary) -> void: setup_count += 1
	func handle(_event: StringName, _context: Dictionary) -> void: event_count += 1
	func teardown() -> void: teardown_count += 1

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var registry := ArtifactRegistry.new()
	registry.register_factory(&"furnace_heart", func(): return FakeBehavior.new())
	registry.register_factory(&"ashen_needle", func(): return FakeBehavior.new())
	registry.register_factory(&"cinder_crown", func(): return FakeBehavior.new())
	registry.register_factory(&"kindling_engine", func(): return FakeBehavior.new())
	registry.register_factory(&"chain_conflagration", func(): return FakeBehavior.new())
	var hooks := ArtifactCombatHooks.new()
	var runtime := ArtifactRuntime.new(registry, hooks)
	runtime.setup(["furnace_heart", "ashen_needle", "cinder_crown", "missing"], [], null)
	check(runtime.behaviors.size() == 5, "Three pieces activate artifacts and both set tiers")
	for behavior in runtime.behaviors: check(behavior.setup_count == 1, "Behavior sets up once")
	hooks.emit_event(&"skill_cast", {"event_id": 1})
	for behavior in runtime.behaviors: check(behavior.event_count == 1, "Behavior receives routed event")
	runtime.teardown()
	runtime.teardown()
	hooks.emit_event(&"skill_cast", {"event_id": 2})
	for behavior in runtime.behaviors: check(behavior.teardown_count == 1 and behavior.event_count == 1, "Teardown is final and idempotent")
	runtime.setup(["furnace_heart", "", "", ""], [], null)
	check(runtime.behaviors.size() == 1, "Runtime reuse discards behaviors from the previous setup")
	runtime.teardown()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
