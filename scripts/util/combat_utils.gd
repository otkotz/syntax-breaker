class_name CombatUtils
extends RefCounted

static func roll_damage(base_damage: float, si: SkillInstance) -> Dictionary:
	var crit_chance: float = si.computed_stats.get("crit_chance", 0.05)
	var crit_mult: float = si.computed_stats.get("crit_mult", 1.5)
	var is_crit := randf() < crit_chance
	var final_damage := base_damage * crit_mult if is_crit else base_damage
	final_damage *= ComboTracker.current_multiplier
	final_damage *= _get_stage_mult()
	final_damage *= _get_consumable_damage_mult()
	return {"damage": final_damage, "is_crit": is_crit}

static func _get_stage_mult() -> float:
	return 1.0 + RunManager.current_stage * 0.05

static func _get_consumable_damage_mult() -> float:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return 1.0
	var nodes := tree.get_nodes_in_group("consumable_manager")
	if nodes.size() > 0:
		return (nodes[0] as ConsumableManager).get_damage_mult()
	return 1.0
