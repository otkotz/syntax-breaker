extends Node

class FakeBehavior extends ArtifactBehavior:
	var teardown_count := 0
	func teardown() -> void: teardown_count += 1

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var profile_ids: Array[String] = ["furnace_heart", "ashen_needle", "cinder_crown", ""]
	var session := ExpeditionSession.create(20261017, "burning_grounds", profile_ids)
	var registry := ArtifactRegistry.new()
	for key: StringName in [&"furnace_heart", &"ashen_needle", &"cinder_crown", &"fractured_prism", &"kindling_engine", &"chain_conflagration"]:
		registry.register_factory(key, func(): return FakeBehavior.new())
	var runtime := ArtifactRuntime.new(registry, ArtifactCombatHooks.new())
	runtime.setup(session.effective_artifact_ids(), [], null)
	check(runtime.behaviors.size() == 5, "Frozen three-piece loadout activates both Ember set tiers")
	var old_behaviors := runtime.behaviors.duplicate()
	check(session.apply_echo("fractured_prism", 2), "Pending artifact can Echo into a frozen slot")
	runtime.setup(session.effective_artifact_ids(), [], null)
	check(runtime.behaviors.size() == 4, "Echo replacement changes artifacts and drops the tier-three set behavior")
	check(runtime.hooks.active_artifact_ids == ["furnace_heart", "ashen_needle", "fractured_prism", ""], "Runtime installs the effective Echo loadout")
	for behavior: FakeBehavior in old_behaviors:
		check(behavior.teardown_count == 1, "Runtime rebuild disconnects every old behavior")
	runtime.teardown()
	check(not runtime.active and runtime.hooks.active_artifact_ids.is_empty(), "Teardown clears the Echo runtime")
	var next_session := ExpeditionSession.create(20261018, "burning_grounds", profile_ids)
	check(next_session.echo_artifact_ids == ["", "", "", ""], "A new expedition starts without the previous Echo")
	check(next_session.effective_artifact_ids() == profile_ids, "A new expedition restores the profile loadout")
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
