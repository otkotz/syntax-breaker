class_name UnlockConditionResource
extends Resource

@export var id: String = ""
@export var item_type: String = ""
@export var item_id: String = ""
@export var condition_type: String = ""
@export var condition_params: Dictionary = {}
@export_multiline var description: String = ""

func check(run_stats: Dictionary) -> bool:
	match condition_type:
		"complete_run":
			return run_stats.get("run_completed", false)
		"reach_stage":
			return run_stats.get("stages_reached", 0) >= condition_params.get("stage", 999)
		"kill_count":
			return run_stats.get("enemies_killed", 0) >= condition_params.get("count", 999)
		"kill_mini_boss":
			return run_stats.get("mini_bosses_killed", 0) >= 1
		"skills_used_count":
			var tag_filter: String = condition_params.get("tag", "")
			var needed: int = condition_params.get("count", 999)
			if tag_filter.is_empty():
				return run_stats.get("skills_used", []).size() >= needed
			var matching := 0
			for skill_id: String in run_stats.get("skills_used", []):
				matching += 1
			return matching >= needed
		"stat_threshold":
			var stat_key: String = condition_params.get("stat", "")
			var threshold: float = condition_params.get("threshold", 999999.0)
			if stat_key.begins_with("damage_by_tag."):
				var tag := stat_key.split(".")[1]
				return run_stats.get("damage_by_tag", {}).get(tag, 0.0) >= threshold
			return run_stats.get(stat_key, 0.0) >= threshold
		"max_event":
			var event_key: String = condition_params.get("event", "")
			var threshold: int = condition_params.get("count", 999)
			return run_stats.get(event_key, 0) >= threshold
	return false
