class_name RansomwareEvolution
extends EvolutionBehavior

static func can_hijack(role: String) -> bool:
	return role not in ["boss", "mini_boss"]

static func hijack_duration(role: String, value: int) -> float:
	if value < 3 or not can_hijack(role):
		return 0.0
	return 3.0 if role == "elite" else 5.0

func on_hit(_skill: SkillInstance, target: Node2D, _attack: Node2D) -> void:
	if tier >= 2:
		target.set_meta("ransomware_stacks", mini(5, int(target.get_meta("ransomware_stacks", 0)) + 1))
	if tier >= 3:
		var role: String = target.get_meta("combat_role", target.get_meta("spawn_role", "normal"))
		var duration := hijack_duration(role, tier)
		if duration > 0.0:
			target.set_meta("hijacked_until_msec", Time.get_ticks_msec() + int(duration * 1000.0))
