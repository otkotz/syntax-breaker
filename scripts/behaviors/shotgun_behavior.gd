class_name ShotgunBehavior
extends BehaviorBase

const VORTEX_CHANCE := 0.2
const VORTEX_RADIUS := 120.0
const VORTEX_PULL_STRENGTH := 200.0
const VORTEX_DURATION := 1.5

func on_hit(_skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if not is_max_quality():
		return
	if randf() > VORTEX_CHANCE:
		return
	var vortex := Vortex.new()
	target.get_parent().add_child(vortex)
	vortex.setup(target.global_position, VORTEX_RADIUS, VORTEX_PULL_STRENGTH, VORTEX_DURATION)
