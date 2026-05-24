class_name BehaviorBase
extends RefCounted

var quality_level: int = 0

func is_max_quality() -> bool:
	return quality_level >= RunManager.MAX_QUALITY_LEVEL

func modify_spawn(_skill_instance, _projectile: Node2D) -> void:
	pass

func on_hit(_skill_instance, _target: Node2D, _projectile: Node2D) -> void:
	pass

func on_kill(_skill_instance, _target: Node2D, _projectile: Node2D) -> void:
	pass

func on_crit(_skill_instance, _target: Node2D, _projectile: Node2D) -> void:
	pass

func on_status_apply(_skill_instance, _target: Node2D, _status_type: String) -> void:
	pass
