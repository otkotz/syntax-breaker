class_name FasterCastingBehavior
extends BehaviorBase

const SLOW_DURATION := 1.5
const SLOW_FACTOR := 0.6

func modify_stats(stats: Dictionary) -> Dictionary:
	stats["cooldown"] = stats.get("cooldown", 1.0) * 0.75
	stats["speed"] = stats.get("speed", 300.0) * 1.3
	return stats

func on_hit(_skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if not is_max_quality():
		return
	if target.has_method("apply_slow"):
		target.apply_slow(SLOW_FACTOR, SLOW_DURATION)
