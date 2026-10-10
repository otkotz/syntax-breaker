class_name BackgroundProcessBehavior
extends BehaviorBase

const REQUIRED_SKILL_ID := "static_field"

func accepts(skill_instance: SkillInstance) -> bool:
	return skill_instance.base.id == REQUIRED_SKILL_ID

static func ghosts_after_expiry() -> int:
	return 1

func modify_spawn(_skill_instance, projectile: Node2D) -> void:
	if not projectile.get_meta("background_ghost", false):
		projectile.set_meta("leave_background_ghost", true)

func on_expire(skill_instance, effect: Node2D) -> void:
	var context: AttackContext = effect.attack_context if "attack_context" in effect else null
	if not context or context.metadata.get("background_ghost_emitted", false):
		return
	if not context.can_derive("background_process", "background_ghost"):
		return
	if not skill_instance.request_recast.is_valid():
		return
	context.metadata["background_ghost_emitted"] = true
	var child := context.derive("background_process", "background_ghost")
	child.metadata["damage_mult"] = 0.45
	skill_instance.request_recast.call_deferred(Vector2.ZERO, child, {})
