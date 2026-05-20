class_name CastOnKillBehavior
extends BehaviorBase

func on_kill(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	var nearest := Targeting.find_nearest_enemy(target.global_position, 300.0)
	if not nearest or not nearest.has_method("take_damage"):
		return
	if nearest == target:
		return
	var damage: float = skill_instance.computed_stats.get("damage", 10.0) * 0.5
	damage *= ComboTracker.current_multiplier
	nearest.take_damage(damage)
	CombatLog.interaction("Cast on Kill", target.name, "%.1f to %s" % [damage, nearest.name])
