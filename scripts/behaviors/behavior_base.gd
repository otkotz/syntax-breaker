class_name BehaviorBase
extends RefCounted

func modify_spawn(_skill_instance, _projectile: Node2D) -> void:
	pass

func on_hit(_skill_instance, _target: Node2D, _projectile: Node2D) -> void:
	pass

func on_kill(_skill_instance, _target: Node2D, _projectile: Node2D) -> void:
	pass

func modify_stats(stats: Dictionary) -> Dictionary:
	return stats
