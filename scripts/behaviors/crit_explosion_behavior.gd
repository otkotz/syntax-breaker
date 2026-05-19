class_name CritExplosionBehavior
extends BehaviorBase

func on_hit(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	var crit_chance: float = skill_instance.computed_stats.get("crit_chance", 0.05)
	if randf() > crit_chance:
		return

	RunManager.record_stat("crits_landed", 1)
	var explosion_damage: float = skill_instance.computed_stats.get("damage", 10.0) * 0.5
	var explosion_radius: float = 60.0
	var enemies := Targeting.find_enemies_in_range(target.global_position, explosion_radius, 20)
	for enemy in enemies:
		if enemy != target and enemy.has_method("take_damage"):
			enemy.take_damage(explosion_damage)
