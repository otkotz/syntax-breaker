class_name ChainBehavior
extends BehaviorBase

func on_hit(skill_instance, target: Node2D, projectile: Node2D) -> void:
	var chain_count: int = skill_instance.computed_stats.get("chain_count", 3)
	if not projectile.has_meta("chains_remaining"):
		projectile.set_meta("chains_remaining", chain_count)

	var remaining: int = projectile.get_meta("chains_remaining")
	if remaining <= 0:
		return

	projectile.set_meta("chains_remaining", remaining - 1)

	var next_target := Targeting.find_nearest_enemy(
		target.global_position,
		skill_instance.computed_stats.get("range", 400.0),
	)
	if next_target == target:
		var enemies := Targeting.find_enemies_in_range(target.global_position, skill_instance.computed_stats.get("range", 400.0), 2)
		next_target = enemies[1] if enemies.size() > 1 else null

	if next_target and projectile is ProjectileBase:
		projectile.direction = target.global_position.direction_to(next_target.global_position)
		projectile.rotation = projectile.direction.angle()
		projectile._distance_traveled = 0.0
		projectile._hit_targets.clear()
		projectile.damage *= skill_instance.computed_stats.get("damage_mult", 0.8)
		projectile.set_meta("chain_redirected", true)
