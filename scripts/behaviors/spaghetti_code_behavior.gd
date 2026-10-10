class_name SpaghettiCodeBehavior
extends BehaviorBase

const MAX_REDIRECTS := 4

static func redirect_plan(count: int) -> Dictionary:
	var capped := mini(MAX_REDIRECTS, maxi(0, count))
	var steps: Array[float] = []
	for i in capped:
		steps.append(1.0 + i * 0.25)
	return {"unique_targets": capped, "damage_steps": steps}

func on_hit(skill_instance, target: Node2D, projectile: Node2D) -> void:
	if not projectile is ProjectileBase or projectile.get_meta("spaghetti_resolved", false):
		return
	projectile.set_meta("spaghetti_resolved", true)
	var visited: Dictionary = {target.get_instance_id(): true}
	var candidates := Targeting.find_enemies_in_range(target.global_position, 360.0, MAX_REDIRECTS + 4)
	var step := 0
	for enemy: Node2D in candidates:
		if visited.has(enemy.get_instance_id()):
			continue
		visited[enemy.get_instance_id()] = true
		ProjectileBase.resolve_skill_hit(skill_instance, enemy, projectile,
			projectile.damage * (1.0 + step * 0.25))
		step += 1
		if step >= MAX_REDIRECTS:
			break
