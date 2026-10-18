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
		var limit := runtime.burn_stack_limit()
		target.apply_dot_stack("burn", float(context.get("damage", 0.0)) * 0.3, float(parameters.get("burn_duration", 3.0)), 0.5,
			skill.base, "furnace-%s" % context.get("event_id", 0), limit)
		runtime.trigger("furnace_heart", context.get("world_position", Vector2.ZERO))
	func teardown() -> void:
		for skill: SkillInstance in applied_overrides:
			skill.runtime_overrides.erase(applied_overrides[skill])
			skill.recompute()
		applied_overrides.clear()

class AshenNeedleBehavior extends ArtifactBehavior:
	func handle(event: StringName, context: Dictionary) -> void:
		var origin_flags: Array = context.get("origin_flags", [])
		if event != &"projectile_hit" or "ashen_needle" in origin_flags or "secondary_artifact_projectile" in origin_flags: return
		var target: Node2D = context.get("target")
		var projectile: Node2D = context.get("projectile")
		if target == null or projectile == null or not target.has_method("get_dot_stacks"): return
		if projectile.artifact_origin_flags.has("ashen_needle"): return
		if int(context.get("pre_hit_burn_count", target.get_dot_stacks("burn").size())) <= 0: return
		projectile.pierce_remaining += int(parameters.get("bonus_pierce", 1))
		if not projectile.artifact_origin_flags.has("ashen_needle"):
			projectile.artifact_origin_flags.append("ashen_needle")
		context["origin_flags"] = projectile.artifact_origin_flags
		var trail_damage := float(context.get("damage", 0.0)) * float(parameters.get("trail_damage_mult", 0.2))
		for enemy: Node2D in Targeting.find_enemies_in_range(context.get("world_position", target.global_position),
				float(parameters.get("trail_radius", 72.0)), 8):
			if enemy != target and enemy.has_method("apply_dot_stack"):
				enemy.apply_dot_stack("burn", trail_damage, float(parameters.get("trail_duration", 2.0)), 0.5,
					context.get("skill").base if context.get("skill") != null else null,
					"needle-%s" % context.get("event_id", 0), runtime.burn_stack_limit(),
					int(context.get("generation", 0)) + 1)
		runtime.trigger("ashen_needle", context.get("world_position", Vector2.ZERO))

class CinderCrownBehavior extends ArtifactBehavior:
	func handle(event: StringName, context: Dictionary) -> void:
		if event != &"enemy_killed" or int(context.get("generation", 0)) >= 2: return
		var dead: Node2D = context.get("target")
		if dead == null or not dead.has_method("get_dot_stacks"): return
		var burns: Array = context.get("burns", dead.get_dot_stacks("burn"))
		if burns.is_empty(): return
		for burn: Dictionary in burns:
			if str(burn.get("stack_id", "")).begins_with("split-transfer-"): return
		burns.sort_custom(func(a: Dictionary, b: Dictionary): return float(a.damage) > float(b.damage))
		var transfers := 0
		for enemy: Node2D in Targeting.find_enemies_in_range(dead.global_position, 400.0, 8):
			if enemy != dead and enemy.has_method("apply_dot_stack"):
				var burn: Dictionary = burns[0]
				enemy.apply_dot_stack("burn", float(burn.damage) * float(parameters.get("transfer_damage_mult", 1.0)), burn.remaining, burn.interval, burn.source,
					"cinder-%s" % context.get("event_id", 0), runtime.burn_stack_limit(),
					int(context.get("generation", 0)) + 1)
				runtime.trigger("cinder_crown", enemy.global_position)
				transfers += 1
				if transfers >= int(parameters.get("transfer_count", 1)): break

class KindlingEngineBehavior extends ArtifactBehavior:
	pass

class ChainConflagrationBehavior extends ArtifactBehavior:
	var processed: Dictionary = {}
	func handle(event: StringName, context: Dictionary) -> void:
		if event != &"projectile_hit" or int(context.get("pre_hit_burn_count", context.get("pre_burn_count", 0))) < int(parameters.get("stack_limit", 5)): return
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
		target.set_meta("artifact_kill_burns", burns)
		target.set_meta("artifact_kill_generation", int(context.get("generation", 0)) + 1)
		_apply_explosion_damage(target, damage, skill)
		target.remove_meta("artifact_kill_burns")
		target.remove_meta("artifact_kill_generation")
		for enemy: Node2D in Targeting.find_enemies_in_range(target.global_position,
				float(parameters.get("explosion_radius", 180.0)), 12):
			if enemy != target:
				_apply_explosion_damage(enemy, damage * float(parameters.get("splash_damage_mult", 0.5)), skill)
		runtime.trigger("chain_conflagration", context.get("world_position", Vector2.ZERO))
	func _apply_explosion_damage(enemy: Node2D, amount: float, skill: SkillInstance) -> void:
		if enemy == null or not enemy.has_method("take_damage"): return
		if enemy.get_meta("combat_role", "") == "boss":
			amount = minf(amount, float(enemy.max_hp) * 0.15)
		enemy.take_damage(amount, false, skill.base, "proc")

static func create(key: StringName) -> ArtifactBehavior:
	match key:
		&"furnace_heart": return FurnaceHeartBehavior.new()
		&"ashen_needle": return AshenNeedleBehavior.new()
		&"cinder_crown": return CinderCrownBehavior.new()
		&"kindling_engine": return KindlingEngineBehavior.new()
		&"chain_conflagration": return ChainConflagrationBehavior.new()
	return null
