class_name BehaviorBase
extends RefCounted

var support_id: String = ""

func is_mastered() -> bool:
	for p: Resource in RunManager.owned_passives:
		if p is PassiveResource and p.id == support_id + "_mastery":
			return true
	return false

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
