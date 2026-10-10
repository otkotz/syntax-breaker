class_name CopyPasteBehavior
extends BehaviorBase

func on_cast(skill_instance, cast: Dictionary) -> void:
	var context: AttackContext = cast.context
	if not context.can_derive("copy_paste", "copied") or not skill_instance.request_recast.is_valid():
		return
	var child := context.derive("copy_paste", "copied")
	skill_instance.request_recast.call(cast.direction, child, cast.metadata.duplicate(true))
