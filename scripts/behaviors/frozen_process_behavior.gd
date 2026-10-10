class_name FrozenProcessBehavior
extends BehaviorBase

const REQUIRED_SKILL_ID := "frost_nova"

func accepts(skill_instance: SkillInstance) -> bool:
	return skill_instance.base.id == REQUIRED_SKILL_ID

static func repeat_damage(stored_damage: float) -> float:
	return stored_damage

func on_hit(skill_instance, target: Node2D, projectile: Node2D) -> void:
	if projectile.get_meta("stored_frost", false):
		return
	projectile.set_meta("stored_frost", true)
	if target.has_method("apply_slow"):
		target.apply_slow(0.35, 1.25)
	if target.has_method("take_damage"):
		_thaw(skill_instance, target, projectile.get_tree(), float(skill_instance.computed_stats.get("damage", 0.0)))

func _thaw(skill_instance, target: Node2D, tree: SceneTree, stored_damage: float) -> void:
	await tree.create_timer(1.25).timeout
	if is_instance_valid(target) and target.has_method("is_alive") and target.is_alive():
		target.take_damage(stored_damage, false, skill_instance.base, "proc")
