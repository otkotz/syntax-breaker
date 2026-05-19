class_name PoisonOnHitBehavior
extends BehaviorBase

const POISON_DAMAGE := 3.0
const POISON_DURATION := 3.0
const POISON_TICK := 0.5

func on_hit(_skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if target.has_method("apply_dot"):
		target.apply_dot("poison", POISON_DAMAGE, POISON_DURATION, POISON_TICK)
		RunManager.record_stat("poison_applied", 1)
