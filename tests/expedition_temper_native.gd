extends Node

const TEMPER_DATA := preload("res://scripts/expedition/artifact_temper_data.gd")

class FakeBehavior extends ArtifactBehavior:
	pass

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	for artifact_id in ArtifactCatalog.all_ids():
		var data: Dictionary = TEMPER_DATA.get_for_artifact(artifact_id)
		check(not data.is_empty(), "%s has a Temper definition" % artifact_id)
		check(not str(data.get("name", "")).is_empty(), "%s Temper is named" % artifact_id)
		check(not str(data.get("upside", "")).is_empty() and not str(data.get("downside", "")).is_empty(), "%s Temper states one upside and downside" % artifact_id)
		check(data.get("allow_secondary_triggers", true) == false, "%s Temper cannot recursively trigger secondary effects" % artifact_id)
		for value: Variant in data.get("parameter_multipliers", {}).values():
			check(float(value) >= 0.5 and float(value) <= 1.5, "%s Temper multiplier remains bounded" % artifact_id)
	var session := ExpeditionSession.create(44, "burning_grounds", ["fractured_prism", "", "", ""])
	var reward := {"reward_id": "duplicate", "source_tag": "elite", "artifact_ids": ["fractured_prism"], "shard_amount": 0, "pity_key": "", "chase_awarded": false, "is_duplicate": true}
	session.record_reward(reward)
	check(session.resolve_reward("duplicate", "temper"), "Equipped duplicate can be Tempered")
	check(session.tempered_artifact_ids == ["fractured_prism"], "Temper is stored as run-only session state")
	var restored := ExpeditionSession.from_dict(session.to_dict())
	check(restored != null and restored.tempered_artifact_ids == ["fractured_prism"], "Temper survives save and resume")
	var registry := ArtifactRegistry.new()
	registry.register_factory(&"fractured_prism", func(): return FakeBehavior.new())
	var runtime := ArtifactRuntime.new(registry, ArtifactCombatHooks.new())
	runtime.setup(session.effective_artifact_ids(), [], null, session.tempered_artifact_ids)
	check(runtime.behaviors.size() == 1 and runtime.behaviors[0].parameters.get("tempered", false), "Runtime applies Temper data to the active artifact")
	runtime.teardown()
	check(runtime.active_tempered_artifact_ids.is_empty(), "Runtime teardown clears all Temper state")
	registry.register_factory(&"furnace_heart", func(): return FakeBehavior.new())
	registry.register_factory(&"cinder_crown", func(): return FakeBehavior.new())
	runtime.setup(["furnace_heart", "cinder_crown", "", ""], [], null, ["furnace_heart", "cinder_crown"])
	check(is_equal_approx(float(runtime.behaviors[0].parameters.get("burn_duration", 0.0)), 2.4), "Furnace Temper applies its shorter burn downside")
	check(is_equal_approx(float(runtime.behaviors[1].parameters.get("transfer_damage_mult", 0.0)), 0.75), "Cinder Temper applies its weaker transfer downside")
	runtime.teardown()
	var next_session := ExpeditionSession.create(45, "burning_grounds", ["fractured_prism", "", "", ""])
	check(next_session.tempered_artifact_ids.is_empty(), "New expedition does not inherit abandoned Temper state")
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
