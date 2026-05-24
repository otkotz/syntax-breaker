class_name PierceBehavior
extends BehaviorBase

func modify_spawn(skill_instance, projectile: Node2D) -> void:
	if projectile.has_method("set_pierce_count"):
		projectile.set_pierce_count(skill_instance.computed_stats.get("pierce", 0))
