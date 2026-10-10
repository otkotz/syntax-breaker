class_name SolarFlareEvolution
extends EvolutionBehavior

static func simulate(value: int) -> Dictionary:
	return {"suns": 1 if value >= 1 else 0, "sun_shots": 3 if value >= 2 else 0,
		"supernovas": 1 if value >= 3 else 0}

func on_cast(skill: SkillInstance, cast: Dictionary) -> void:
	cast.metadata["solar_suns"] = 1
	if tier >= 2:
		cast.metadata["solar_shots"] = 3
	if tier >= 3:
		cast.metadata["solar_supernova"] = true
	var context: AttackContext = cast.context
	if tier < 2 or context.metadata.get("solar_children_emitted", false):
		return
	if not context.can_derive("solar_flare", "solar_child") or not skill.request_recast.is_valid():
		return
	context.metadata["solar_children_emitted"] = true
	var child_count := 3 if tier >= 2 else 0
	var direction: Vector2 = cast.direction
	for index in child_count:
		var child := context.derive("solar_flare", "solar_child")
		child.metadata["damage_mult"] = 0.45
		var angle := (index - (child_count - 1) * 0.5) * 0.35
		skill.request_recast.call_deferred(direction.rotated(angle), child, {})
