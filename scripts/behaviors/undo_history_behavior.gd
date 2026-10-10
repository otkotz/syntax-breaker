class_name UndoHistoryBehavior
extends BehaviorBase

const REQUIRED_SKILL_ID := "blade_spin"

func accepts(skill_instance: SkillInstance) -> bool:
	return skill_instance.base.id == REQUIRED_SKILL_ID

static func retrace_path(outbound_path: Array[Vector2]) -> Array[Vector2]:
	var retrace := outbound_path.duplicate()
	retrace.reverse()
	return retrace

func modify_spawn(_skill_instance, projectile: Node2D) -> void:
	projectile.set_meta("undo_retrace", true)
