class_name HypothermiaBehavior
extends BehaviorBase

const SLOW_FACTOR := 0.6
const SLOW_DURATION := 1.5
const FROST_DAMAGE := 2.0
const FROST_DURATION := 2.0
const FROST_TICK := 0.5

const MASTERED_SLOW_FACTOR := 0.45
const MASTERED_SLOW_DURATION := 2.0
const MASTERED_FROST_DAMAGE := 3.5

func on_hit(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	var factor := MASTERED_SLOW_FACTOR if is_mastered() else SLOW_FACTOR
	var dur := MASTERED_SLOW_DURATION if is_mastered() else SLOW_DURATION
	if target.has_method("apply_slow"):
		target.apply_slow(factor, dur)
	if target.has_method("apply_dot"):
		var dmg := MASTERED_FROST_DAMAGE if is_mastered() else FROST_DAMAGE
		target.apply_dot("frostblight", dmg, FROST_DURATION, FROST_TICK)
		CombatLog.dot_applied("frostblight", target.name, dmg, FROST_DURATION)
		if skill_instance:
			skill_instance.notify_status_apply(target, "frostblight")
