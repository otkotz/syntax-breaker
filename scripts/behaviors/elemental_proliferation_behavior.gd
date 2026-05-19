class_name ElementalProliferationBehavior
extends BehaviorBase

const SPREAD_RADIUS := 100.0
const MAX_Q_SPREAD_RADIUS := 180.0

func on_kill(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	var tags: Array = skill_instance.get_all_tags()
	var radius := MAX_Q_SPREAD_RADIUS if is_max_quality() else SPREAD_RADIUS
	var nearby := Targeting.find_enemies_in_range(target.global_position, radius, 10)
	var spread_count := 0

	for enemy in nearby:
		if enemy == target:
			continue
		if not enemy.has_method("apply_dot"):
			continue

		if "fire" in tags:
			enemy.apply_dot("fire", 5.0, 2.0, 0.5)
			spread_count += 1
		if "lightning" in tags:
			enemy.apply_dot("shock", 3.0, 1.5, 0.3)
			spread_count += 1
		if "poison" in tags:
			enemy.apply_dot("poison", 3.0, 3.0, 0.5)
			spread_count += 1

	if spread_count > RunManager.run_stats.get("max_dot_spread_kill", 0):
		RunManager.run_stats["max_dot_spread_kill"] = spread_count
