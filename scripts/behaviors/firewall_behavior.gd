class_name FirewallBehavior
extends BehaviorBase

const REQUIRED_SKILL_ID := "fireball"

func accepts(skill_instance: SkillInstance) -> bool:
	return skill_instance.base.id == REQUIRED_SKILL_ID

static func segments_for_impact() -> int:
	return 1

func on_hit(_skill_instance, target: Node2D, projectile: Node2D) -> void:
	var context: AttackContext = projectile.attack_context if "attack_context" in projectile else null
	if not context or context.metadata.get("firewall_emitted", false):
		return
	context.metadata["firewall_emitted"] = true
	var root := projectile.get_tree().current_scene
	if root:
		AftermathEffect.spawn(root, target.global_position, "scorch", 72.0, 4.0)
