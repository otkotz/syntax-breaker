class_name ReplyAllBehavior
extends BehaviorBase

const REQUIRED_SKILL_ID := "fireball"

func accepts(skill_instance: SkillInstance) -> bool:
	return skill_instance.base.id == REQUIRED_SKILL_ID

static func children_after_hits(hit_count: int) -> int:
	return 1 if hit_count > 0 else 0

func on_hit(skill_instance, _target: Node2D, projectile: Node2D) -> void:
	var context: AttackContext = projectile.attack_context if "attack_context" in projectile else null
	if not context or context.metadata.get("reply_all_emitted", false):
		return
	if not context.can_derive("reply_all", "reply_all_child") or not skill_instance.request_recast.is_valid():
		return
	context.metadata["reply_all_emitted"] = true
	var child := context.derive("reply_all", "reply_all_child")
	var direction: Vector2 = projectile.direction if "direction" in projectile else Vector2.RIGHT
	skill_instance.request_recast.call_deferred(direction, child, {})
