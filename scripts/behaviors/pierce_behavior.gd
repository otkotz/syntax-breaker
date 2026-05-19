class_name PierceBehavior
extends BehaviorBase

const RETURN_DAMAGE_MULT := 0.6

func modify_spawn(skill_instance, projectile: Node2D) -> void:
	if projectile.has_method("set_pierce_count"):
		projectile.set_pierce_count(skill_instance.computed_stats.get("pierce", 0))
	if is_max_quality() and projectile is ProjectileBase:
		projectile.set_meta("pierce_return", true)
		projectile.set_meta("return_damage_mult", RETURN_DAMAGE_MULT)
