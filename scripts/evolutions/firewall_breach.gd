class_name FirewallBreachEvolution
extends EvolutionBehavior

static func simulate(value: int) -> Dictionary:
	return {"crossing_walls": 2 if value >= 3 else (1 if value >= 1 else 0)}

func on_hit(_skill: SkillInstance, target: Node2D, attack: Node2D) -> void:
	var context: AttackContext = attack.attack_context if "attack_context" in attack else null
	if not context or context.metadata.get("firewall_breach_emitted", false):
		return
	context.metadata["firewall_breach_emitted"] = true
	var root := attack.get_tree().current_scene
	if root:
		AftermathEffect.spawn(root, target.global_position, "scorch", 90.0 + tier * 20.0, 3.0 + tier)
