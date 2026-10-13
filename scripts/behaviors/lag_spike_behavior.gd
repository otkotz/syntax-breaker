class_name LagSpikeBehavior
extends BehaviorBase

const DELAY_SECONDS := 0.28
const DELAYED_DAMAGE_MULT := 0.65

static func event_plan(context: AttackContext) -> Dictionary:
	if not context or not context.can_derive("lag_spike", "lagged"):
		return {"damage_events": 1, "derived_events": 0}
	return {"damage_events": 2, "derived_events": 1}

func on_hit(skill_instance, target: Node2D, projectile: Node2D) -> void:
	var context := _attack_context(projectile)
	if not context or not context.can_derive("lag_spike", "lagged"):
		return
	var raw_damage := float(projectile.get("damage")) if "damage" in projectile else float(skill_instance.computed_stats.get("damage", 10.0))
	var generation := int(target.get("life_generation")) if "life_generation" in target else -1
	_delayed_hit(skill_instance, target, projectile.get_tree(), raw_damage, context.derive("lag_spike", "lagged"), generation)

func _delayed_hit(skill_instance, target: Node2D, tree: SceneTree, raw_damage: float, _context: AttackContext, generation: int = -1) -> void:
	await tree.create_timer(DELAY_SECONDS).timeout
	if not is_instance_valid(target) or not target.has_method("is_alive") or not target.is_alive():
		return
	if generation >= 0 and (not "life_generation" in target or int(target.get("life_generation")) != generation):
		return
	# Resolve only damage and attribution; the delayed packet must not fan out through
	# every linked on-hit support a second time.
	target.take_damage(raw_damage * DELAYED_DAMAGE_MULT, false,
		skill_instance.base if skill_instance else null, "proc")
	RunManager.record_stat("lag_spike_hits", 1)

static func _attack_context(projectile: Node2D) -> AttackContext:
	if "attack_context" in projectile:
		return projectile.attack_context
	if "context" in projectile:
		return projectile.context
	return null
