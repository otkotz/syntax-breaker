class_name CombatUtils
extends RefCounted

static func roll_damage(base_damage: float, si: SkillInstance) -> Dictionary:
	var crit_chance: float = si.computed_stats.get("crit_chance", 0.05)
	var crit_mult: float = si.computed_stats.get("crit_mult", 1.5)
	var is_crit := randf() < crit_chance
	var final_damage := base_damage * crit_mult if is_crit else base_damage
	return {"damage": final_damage, "is_crit": is_crit}
