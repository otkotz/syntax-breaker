class_name DaemonProcessEvolution
extends EvolutionBehavior

const FIELD_CAP := 4

static func simulate(value: int) -> Dictionary:
	return {"child_fields": mini(FIELD_CAP, maxi(0, value - 1) * 2)}

func on_cast(_skill: SkillInstance, cast: Dictionary) -> void:
	cast.metadata["daemon_children"] = simulate(tier).child_fields

func on_expire(skill: SkillInstance, effect: Node2D) -> void:
	var context: AttackContext = effect.attack_context if "attack_context" in effect else null
	var count: int = simulate(tier).child_fields
	if count <= 0 or not context or context.metadata.get("daemon_emitted", false):
		return
	if not context.can_derive("daemon_process", "daemon_child") or not skill.request_recast.is_valid():
		return
	context.metadata["daemon_emitted"] = true
	for index in count:
		var child := context.derive("daemon_process", "daemon_child")
		child.metadata["damage_mult"] = 0.35
		skill.request_recast.call_deferred(Vector2.from_angle(TAU * index / count), child, {})
