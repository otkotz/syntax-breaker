class_name FirewallBreachEvolution
extends EvolutionBehavior

const Hazard = preload("res://scripts/effects/evolution_hazard.gd")

static func simulate(value: int) -> Dictionary:
	return {"crossing_walls": 2 if value >= 3 else (1 if value >= 1 else 0)}

func on_hit(_skill: SkillInstance, target: Node2D, attack: Node2D) -> void:
	var context: AttackContext = attack.attack_context if "attack_context" in attack else null
	if not context or context.metadata.get("firewall_breach_emitted", false):
		return
	context.metadata["firewall_breach_emitted"] = true
	var root := attack.get_tree().current_scene
	if root:
		Hazard.spawn(root, target.global_position, "firewall", _skill, context, tier)

func on_expire(skill: SkillInstance, effect: Node2D) -> void:
	if tier < 2 or not skill.request_recast.is_valid():
		return
	var context: AttackContext = effect.attack_context if "attack_context" in effect else null
	if not context or not context.can_derive("firewall_breach", "firewall_return"):
		return
	var returned := context.derive("firewall_breach", "firewall_return")
	returned.metadata["origin"] = effect.global_position
	returned.metadata.erase("firewall_breach_emitted")
	var direction := Vector2.LEFT
	if "direction" in effect:
		direction = -effect.direction
	skill.request_recast.call_deferred(direction, returned, {})
	if tier >= 3 and returned.can_derive("firewall_cross", "firewall_cross"):
		var crossing := returned.derive("firewall_cross", "firewall_cross")
		crossing.metadata.erase("firewall_breach_emitted")
		skill.request_recast.call_deferred(direction.rotated(PI / 2.0), crossing, {})
