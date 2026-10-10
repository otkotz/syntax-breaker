class_name WifiExtenderBehavior
extends BehaviorBase

const REQUIRED_SKILL_ID := "lightning_bolt"

func accepts(skill_instance: SkillInstance) -> bool:
	return skill_instance.base.id == REQUIRED_SKILL_ID

static func chain_ranges(base_range: float) -> Array[float]:
	return [base_range, base_range * 1.25, base_range * 1.5]

func modify_spawn(_skill_instance, projectile: Node2D) -> void:
	projectile.set_meta("wifi_extended", true)
	projectile.set_meta("wifi_chain_ranges", chain_ranges(120.0))
	projectile.set_meta("wifi_chain_step", 0)

func on_hit(_skill_instance, target: Node2D, projectile: Node2D) -> void:
	if not projectile is ProjectileBase:
		return
	var step := int(projectile.get_meta("wifi_chain_step", 0))
	var ranges := chain_ranges(120.0)
	if step >= ranges.size():
		return
	var candidates := Targeting.find_enemies_in_range(target.global_position, ranges[step], 4)
	for next_target: Node2D in candidates:
		if next_target == target or projectile._hit_targets.has(next_target):
			continue
		projectile.set_meta("wifi_chain_step", step + 1)
		projectile.direction = target.global_position.direction_to(next_target.global_position)
		projectile.rotation = projectile.direction.angle()
		projectile._distance_traveled = 0.0
		projectile.set_meta("chain_redirected", true)
		return
