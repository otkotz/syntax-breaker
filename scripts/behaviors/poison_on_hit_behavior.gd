class_name PoisonOnHitBehavior
extends BehaviorBase

const POISON_DAMAGE := 3.0
const POISON_DURATION := 3.0
const POISON_TICK := 0.5
const MAX_Q_DAMAGE := 5.0
const MAX_Q_DURATION := 4.0

func on_hit(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if not target.has_method("apply_dot"):
		return
	var dmg := MAX_Q_DAMAGE if is_mastered() else POISON_DAMAGE
	var dur := MAX_Q_DURATION if is_mastered() else POISON_DURATION
	target.apply_dot("poison", dmg, dur, POISON_TICK)
	RunManager.record_stat("poison_applied", 1)
	if skill_instance:
		skill_instance.notify_status_apply(target, "poison")
