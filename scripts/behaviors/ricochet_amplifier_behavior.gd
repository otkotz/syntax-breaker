class_name RicochetAmplifierBehavior
extends BehaviorBase

const BONUS_PER_CHAIN := 0.05
const MAX_BONUS := 0.30
const MAX_Q_BONUS_PER_CHAIN := 0.07
const MAX_Q_MAX_BONUS := 0.42

func on_hit(_skill_instance, _target: Node2D, projectile: Node2D) -> void:
	if not projectile is ProjectileBase:
		return
	if not projectile.has_meta("chains_remaining"):
		return
	var bonus_per := MAX_Q_BONUS_PER_CHAIN if is_max_quality() else BONUS_PER_CHAIN
	var cap := MAX_Q_MAX_BONUS if is_max_quality() else MAX_BONUS

	var current_bonus: float = projectile.get_meta("ricochet_bonus", 0.0)
	current_bonus = minf(current_bonus + bonus_per, cap)
	projectile.set_meta("ricochet_bonus", current_bonus)
	projectile.damage *= (1.0 + bonus_per)
