class_name SplitBehavior
extends BehaviorBase

const SPLIT_ANGLE := 0.3

func modify_spawn(skill_instance, projectile: Node2D) -> void:
	if projectile.has_meta("is_split"):
		return

	var split_count: int = skill_instance.computed_stats.get("split_count", 2)
	if not projectile is ProjectileBase:
		return

	var base_dir: Vector2 = projectile.direction
	var pool: ObjectPool = projectile.pool_ref
	if pool == null:
		return

	for i in split_count:
		var angle_offset := SPLIT_ANGLE * (i + 1) * (1 if i % 2 == 0 else -1)
		var split_dir := base_dir.rotated(angle_offset)
		var split := pool.get_instance()
		split.global_position = projectile.global_position
		split.set_meta("is_split", true)
		if split.has_method("initialize"):
			split.initialize(skill_instance, split_dir, pool)
		split.damage *= 0.7
