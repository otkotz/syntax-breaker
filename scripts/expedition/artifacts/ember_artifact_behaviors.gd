class_name EmberArtifactBehaviors
extends RefCounted

class FurnaceHeartBehavior extends ArtifactBehavior:
	var applied_overrides: Dictionary = {}
	func before_skill_recompute(skill: SkillInstance) -> void:
		if not skill.get_all_tags().has("fire"): return
		var override := {"damage_mult": float(parameters.get("direct_hit_mult", 0.8))}
		skill.runtime_overrides.append(override)
		applied_overrides[skill] = override
	func handle(event: StringName, context: Dictionary) -> void:
		if event != &"projectile_hit": return
		var skill: SkillInstance = context.get("skill")
		var target: Node2D = context.get("target")
		if skill == null or target == null or not skill.get_all_tags().has("fire") or not target.has_method("apply_dot_stack"): return
		var current: Array = target.get_dot_stacks("burn")
		context["pre_burn_count"] = current.size()
		var limit := 1
		for behavior: ArtifactBehavior in runtime.behaviors:
			if behavior.artifact_id == "covenant_of_embers_2": limit = int(behavior.parameters.get("stack_limit", 5))
		target.apply_dot_stack("burn", float(context.get("damage", 0.0)) * 0.3, 3.0, 0.5,
			skill.base, "furnace-%s" % context.get("event_id", 0), limit)
		runtime.trigger("furnace_heart", context.get("world_position", Vector2.ZERO))
	func teardown() -> void:
		for skill: SkillInstance in applied_overrides:
			skill.runtime_overrides.erase(applied_overrides[skill])
			skill.recompute()
		applied_overrides.clear()

class AshenNeedleBehavior extends ArtifactBehavior:
	func handle(event: StringName, context: Dictionary) -> void:
		if event != &"projectile_hit" or "ashen_needle" in context.get("origin_flags", []): return
		var target: Node2D = context.get("target")
		var projectile: Node2D = context.get("projectile")
		if target == null or projectile == null or not target.has_method("get_dot_stacks"): return
		if target.get_dot_stacks("burn").is_empty(): return
		projectile.pierce_remaining += int(parameters.get("bonus_pierce", 1))
		context["origin_flags"] = context.get("origin_flags", []) + ["ashen_needle"]
		runtime.trigger("ashen_needle", context.get("world_position", Vector2.ZERO))

class CinderCrownBehavior extends ArtifactBehavior:
	func handle(event: StringName, context: Dictionary) -> void:
		if event != &"enemy_killed" or int(context.get("generation", 0)) >= 2: return
		var dead: Node2D = context.get("target")
		if dead == null or not dead.has_method("get_dot_stacks"): return
		var burns: Array = dead.get_dot_stacks("burn")
		if burns.is_empty(): return
		burns.sort_custom(func(a: Dictionary, b: Dictionary): return float(a.damage) > float(b.damage))
		for enemy: Node2D in Targeting.find_enemies_in_range(dead.global_position, 400.0, 8):
			if enemy != dead and enemy.has_method("apply_dot_stack"):
				var burn: Dictionary = burns[0]
				enemy.apply_dot_stack("burn", burn.damage, burn.remaining, burn.interval, burn.source,
					"cinder-%s" % context.get("event_id", 0), 5)
				runtime.trigger("cinder_crown", enemy.global_position)
				break

class KindlingEngineBehavior extends ArtifactBehavior:
	pass

class ChainConflagrationBehavior extends ArtifactBehavior:
	var processed: Dictionary = {}
	func handle(event: StringName, context: Dictionary) -> void:
		if event != &"projectile_hit" or int(context.get("pre_burn_count", 0)) < int(parameters.get("stack_limit", 5)): return
		if int(context.get("generation", 0)) > int(parameters.get("max_generations", 2)): return
		var event_id: Variant = context.get("event_id")
		if processed.has(event_id): return
		processed[event_id] = true
		var target: Node2D = context.get("target")
		var skill: SkillInstance = context.get("skill")
		if target == null or skill == null or not skill.get_all_tags().has("fire"): return
		var burns: Array = target.consume_dot_stacks("burn", int(parameters.get("stack_limit", 5)))
		if burns.size() < int(parameters.get("stack_limit", 5)): return
		var damage := 0.0
		for burn: Dictionary in burns:
			damage += float(burn.damage) * maxf(1.0, float(burn.remaining) / maxf(float(burn.interval), 0.01))
		if target.get_meta("is_boss", false): damage = minf(damage, target.max_hp * 0.15)
		target.take_damage(damage, false, skill.base, "proc")
		runtime.trigger("chain_conflagration", context.get("world_position", Vector2.ZERO))

static func create(key: StringName) -> ArtifactBehavior:
	match key:
		&"furnace_heart": return FurnaceHeartBehavior.new()
		&"ashen_needle": return AshenNeedleBehavior.new()
		&"cinder_crown": return CinderCrownBehavior.new()
		&"kindling_engine": return KindlingEngineBehavior.new()
		&"chain_conflagration": return ChainConflagrationBehavior.new()
	return null
