class_name WorksOnMyMachineBehavior
extends BehaviorBase

const MODES := ["size", "projectiles", "critical", "cooldown"]

static func roll_mode(seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return MODES[rng.randi_range(0, MODES.size() - 1)]

func on_cast(_skill_instance, cast: Dictionary) -> void:
	var context: AttackContext = cast.context
	if not context.metadata.has("works_mode"):
		context.metadata["works_mode"] = roll_mode(context.root_cast_id)
	cast.metadata["works_mode"] = context.metadata.works_mode

func modify_spawn(_skill_instance, projectile: Node2D) -> void:
	if not projectile is ProjectileBase:
		return
	var context: AttackContext = (projectile as ProjectileBase).attack_context
	if context and context.metadata.get("works_mode", "") == "size":
		projectile.scale *= 1.5
