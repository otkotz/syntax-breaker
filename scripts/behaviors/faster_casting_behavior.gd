class_name FasterCastingBehavior
extends BehaviorBase

func modify_stats(stats: Dictionary) -> Dictionary:
	stats["cooldown"] = stats.get("cooldown", 1.0) * 0.75
	return stats
