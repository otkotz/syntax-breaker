class_name EvolutionBehavior
extends RefCounted

var tier := 0

func configure(value: int) -> void:
	tier = clampi(value, 0, 3)

func on_cast(_skill: SkillInstance, _cast: Dictionary) -> void:
	pass

func on_spawn(_skill: SkillInstance, _effect: Node2D) -> void:
	pass

func on_hit(_skill: SkillInstance, _target: Node2D, _attack: Node2D) -> void:
	pass

func on_kill(_skill: SkillInstance, _target: Node2D, _attack: Node2D) -> void:
	pass

func on_expire(_skill: SkillInstance, _effect: Node2D) -> void:
	pass
