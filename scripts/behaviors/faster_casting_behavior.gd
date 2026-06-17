class_name FasterCastingBehavior
extends BehaviorBase

const SLOW_DURATION := 1.5
const SLOW_FACTOR := 0.6

func on_hit(_skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if not is_mastered():
		return
	if target.has_method("apply_slow"):
		target.apply_slow(SLOW_FACTOR, SLOW_DURATION)
