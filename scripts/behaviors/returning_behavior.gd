class_name ReturningBehavior
extends BehaviorBase

const RETURN_DAMAGE_MULT := 0.6

func modify_spawn(skill_instance, projectile: Node2D) -> void:
	if projectile is ProjectileBase:
		projectile.set_meta("pierce_return", true)
		var mult := RETURN_DAMAGE_MULT
		if is_max_quality():
			mult = 0.8
		projectile.set_meta("return_damage_mult", mult)
