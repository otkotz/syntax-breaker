class_name IncreasedAreaBehavior
extends BehaviorBase

func modify_stats(stats: Dictionary) -> Dictionary:
	stats["area_mult"] = stats.get("area_mult", 1.0) * 1.4
	return stats
