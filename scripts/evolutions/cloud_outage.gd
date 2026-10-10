class_name CloudOutageEvolution
extends EvolutionBehavior

static func simulate(value: int) -> Dictionary:
	return {"network_pulses": 1 if value >= 3 else 0}

func on_cast(_skill: SkillInstance, cast: Dictionary) -> void:
	cast.metadata["cloud_rods"] = tier
	cast.metadata["cloud_network_pulse"] = tier >= 3

func on_hit(skill: SkillInstance, target: Node2D, attack: Node2D) -> void:
	var context: AttackContext = attack.attack_context if "attack_context" in attack else null
	if tier < 3 or not context or context.metadata.get("cloud_pulsed", false):
		return
	context.metadata["cloud_pulsed"] = true
	for enemy: Node2D in Targeting.find_enemies_in_range(target.global_position, 150.0, 6):
		if enemy != target and enemy.has_method("take_damage"):
			enemy.take_damage(float(skill.computed_stats.get("damage", 8.0)) * 0.35, false, skill.base, "proc")
