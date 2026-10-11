class_name RansomwareEvolution
extends EvolutionBehavior

static func can_hijack(role: String) -> bool:
	return role not in ["boss", "mini_boss"]

static func hijack_duration(role: String, value: int) -> float:
	if value < 3 or not can_hijack(role):
		return 0.0
	return 3.0 if role == "elite" else 5.0

func on_hit(skill: SkillInstance, target: Node2D, _attack: Node2D) -> void:
	target.set_meta("ransomware_carrier", true)
	if target.has_method("apply_dot"):
		target.apply_dot("poison", float(skill.computed_stats.get("damage", 8.0)) * 0.2, 3.0, 0.5, skill.base)
	for enemy: Node2D in Targeting.find_enemies_in_range(target.global_position, 90.0, tier + 1):
		if enemy != target and enemy.has_method("apply_dot"):
			enemy.apply_dot("poison", float(skill.computed_stats.get("damage", 8.0)) * 0.12, 2.0, 0.5, skill.base)
	if tier >= 2:
		target.set_meta("ransomware_stacks", mini(5, int(target.get_meta("ransomware_stacks", 0)) + 1))
	if tier >= 3:
		var role: String = target.get_meta("combat_role", target.get_meta("spawn_role", "normal"))
		var duration := hijack_duration(role, tier)
		if duration > 0.0:
			target.set_meta("hijacked_until_msec", Time.get_ticks_msec() + int(duration * 1000.0))

func on_kill(skill: SkillInstance, _target: Node2D, attack: Node2D) -> void:
	if tier < 2 or not skill.request_recast.is_valid():
		return
	var context: AttackContext = attack.attack_context if "attack_context" in attack else null
	if not context or not context.can_derive("ransomware", "ransomware_death_dart"):
		return
	for index in mini(2, tier):
		var child := context.derive("ransomware", "ransomware_death_dart")
		child.metadata["damage_mult"] = 0.45
		skill.request_recast.call_deferred(Vector2.from_angle(TAU * index / mini(2, tier)), child, {})
