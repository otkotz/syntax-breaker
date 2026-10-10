class_name RecursiveRollbackEvolution
extends EvolutionBehavior

static func simulate(value: int) -> Dictionary:
	return {"child_boomerangs": 2 if value >= 3 else (1 if value >= 2 else 0)}

func on_cast(_skill: SkillInstance, cast: Dictionary) -> void:
	cast.metadata["rollback_children"] = simulate(tier).child_boomerangs

func on_expire(skill: SkillInstance, effect: Node2D) -> void:
	var context: AttackContext = effect.context if "context" in effect else null
	var count: int = simulate(tier).child_boomerangs
	if count <= 0 or not context or context.metadata.get("rollback_children_emitted", false):
		return
	if not context.can_derive("recursive_rollback", "recursive_rollback") or not skill.request_recast.is_valid():
		return
	context.metadata["rollback_children_emitted"] = true
	for index in count:
		var child := context.derive("recursive_rollback", "recursive_rollback")
		child.metadata["damage_mult"] = 0.5
		var angle := -0.45 if index == 0 else 0.45
		skill.request_recast.call_deferred(effect.direction.rotated(angle), child, {})
