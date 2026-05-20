class_name VoidRiftBehavior
extends BehaviorBase

func on_kill(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	var damage: float = skill_instance.computed_stats.get("damage", 10.0) * 0.4
	var radius := 80.0
	if is_max_quality():
		radius = 120.0
		damage *= 1.3
	var enemies := Targeting.find_enemies_in_range(target.global_position, radius, 20)
	var hit_count := 0
	for enemy: Node2D in enemies:
		if enemy != target and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			hit_count += 1
	if hit_count > 0:
		CombatLog.interaction("Void Rift", target.name, "burst %.1f to %d nearby" % [damage, hit_count])
