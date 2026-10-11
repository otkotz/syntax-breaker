class_name AbsoluteZeroEvolution
extends EvolutionBehavior

static func simulate(value: int) -> Dictionary:
	return {"max_generation": mini(maxi(value, 0), AttackContext.MAX_GENERATION)}

func on_hit(_skill: SkillInstance, target: Node2D, attack: Node2D) -> void:
	if target.has_method("apply_slow"):
		target.apply_slow(maxf(0.15, 0.5 - tier * 0.1), 2.0 + tier)
	var context: AttackContext = attack.attack_context if "attack_context" in attack else null
	if tier < 2 or not context or not context.can_derive("absolute_zero", "absolute_zero_spread"):
		return
	context.flags["absolute_zero_spread"] = true
	for enemy: Node2D in Targeting.find_enemies_in_range(target.global_position, 70.0 + tier * 20.0, tier):
		if enemy != target and enemy.has_method("apply_slow"):
			enemy.apply_slow(0.35, 1.5 + tier)

func on_kill(skill: SkillInstance, target: Node2D, attack: Node2D) -> void:
	var context: AttackContext = attack.attack_context if "attack_context" in attack else null
	if not context or not context.can_derive("absolute_zero", "absolute_zero_shatter"):
		return
	var child := context.derive("absolute_zero", "absolute_zero_shatter")
	var shard_damage := float(skill.computed_stats.get("damage", 8.0)) * (0.25 + tier * 0.1)
	for enemy: Node2D in Targeting.find_enemies_in_range(target.global_position, 80.0 + tier * 25.0, tier * 2):
		if enemy == target or not child.can_spawn_child("shard", 0, tier * 2):
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(shard_damage, false, skill.base, "proc")
		if tier >= 2 and enemy.has_method("apply_slow"):
			enemy.apply_slow(0.3, 1.5 + tier * 0.5)
