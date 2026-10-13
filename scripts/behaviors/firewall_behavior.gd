class_name FirewallBehavior
extends BehaviorBase

const REQUIRED_SKILL_ID := "fireball"

func accepts(skill_instance: SkillInstance) -> bool:
	return skill_instance.base.id == REQUIRED_SKILL_ID

static func segments_for_impact() -> int:
	return 1

func on_hit(skill_instance, target: Node2D, projectile: Node2D) -> void:
	var context: AttackContext = projectile.attack_context if "attack_context" in projectile else null
	if not context or context.metadata.get("firewall_emitted", false):
		return
	context.metadata["firewall_emitted"] = true
	var players := projectile.get_tree().get_nodes_in_group("player")
	var caster_position: Vector2 = (players[0] as Node2D).global_position if not players.is_empty() else projectile.global_position
	var parent: Node = projectile.get_parent()
	if parent:
		FirewallHazard.spawn(parent, caster_position, target.global_position,
			float(skill_instance.computed_stats.get("damage", 10.0)) * 0.22, skill_instance.base)
