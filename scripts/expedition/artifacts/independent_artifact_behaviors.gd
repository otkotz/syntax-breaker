class_name IndependentArtifactBehaviors
extends RefCounted

class FracturedPrismBehavior extends ArtifactBehavior:
	func handle(event: StringName, context: Dictionary) -> void:
		var flags: Array = context.get("origin_flags", [])
		if event != &"projectile_hit" or "fractured_prism" in flags or "secondary_artifact_projectile" in flags:
			return
		var spawn: Callable = context.get("spawn_fragment", Callable())
		if not spawn.is_valid(): return
		var projectile: Variant = context.get("projectile")
		if projectile != null and is_instance_valid(projectile) and not projectile.artifact_origin_flags.has("fractured_prism"):
			projectile.artifact_origin_flags.append("fractured_prism")
		var damage := float(context.get("damage", 0.0)) * float(parameters.get("fragment_damage_mult", 0.55))
		for index in int(parameters.get("fragment_count", 2)):
			spawn.call({"damage": damage, "angle_offset": -0.22 if index == 0 else 0.22,
				"origin_flags": ["fractured_prism", "secondary_artifact_projectile"],
				"generation": int(context.get("generation", 0)) + 1,
				"world_position": context.get("world_position", Vector2.ZERO)})
		runtime.trigger("fractured_prism", context.get("world_position", Vector2.ZERO))

class EchoingHourglassBehavior extends ArtifactBehavior:
	var cast_count := 0
	var lifecycle := 0
	var arena: Node
	var applied_overrides: Dictionary = {}
	func setup(context: Dictionary) -> void:
		arena = context.get("arena")
	func before_skill_recompute(skill: SkillInstance) -> void:
		var override := {"cooldown_mult": float(parameters.get("cooldown_mult", 1.2))}
		skill.runtime_overrides.append(override)
		applied_overrides[skill] = override
	func handle(event: StringName, context: Dictionary) -> void:
		if event != &"skill_cast" or "echoing_hourglass" in context.get("origin_flags", []): return
		cast_count += 1
		if cast_count % int(parameters.get("cast_interval", 3)) != 0: return
		var spawn: Callable = context.get("spawn_echo", Callable())
		if not spawn.is_valid() or arena == null or not is_instance_valid(arena): return
		var token := lifecycle
		var timer := arena.get_tree().create_timer(float(parameters.get("delay", 0.35)))
		timer.timeout.connect(func():
			if runtime != null and runtime.active and token == lifecycle:
				spawn.call()
				runtime.trigger("echoing_hourglass", context.get("world_position", Vector2.ZERO))
		)
	func teardown() -> void:
		lifecycle += 1
		arena = null
		for skill: SkillInstance in applied_overrides:
			skill.runtime_overrides.erase(applied_overrides[skill])
			skill.recompute()
		applied_overrides.clear()

class BloodwrittenSigilBehavior extends ArtifactBehavior:
	func handle(event: StringName, context: Dictionary) -> void:
		var flags: Array = context.get("origin_flags", [])
		if event != &"skill_cast" or "bloodwritten_sigil" in flags or "secondary_artifact_projectile" in flags: return
		var player: Variant = context.get("player")
		if player == null or not is_instance_valid(player): return
		var ratio := float(player.current_hp) / maxf(float(player.max_hp), 1.0)
		if ratio < float(parameters.get("hp_threshold", 0.9)): return
		if not player.try_spend_artifact_health(float(parameters.get("hp_cost", 0.08))): return
		for projectile: Node2D in context.get("projectiles", []):
			if is_instance_valid(projectile):
				projectile.damage *= float(parameters.get("damage_mult", 1.35))
				projectile.scale *= float(parameters.get("area_mult", 1.3))
		runtime.hooks.emit_event(&"artifact_cast_empowered", {
			"skill": context.get("skill"),
			"damage_mult": float(parameters.get("damage_mult", 1.35)),
			"area_mult": float(parameters.get("area_mult", 1.3)),
			"origin_flags": ["bloodwritten_sigil"],
			"generation": int(context.get("generation", 0)),
			"spawn_echo": context.get("spawn_echo", Callable()),
			"world_position": player.global_position,
		})
		runtime.trigger("bloodwritten_sigil", player.global_position)

static func create(key: StringName) -> ArtifactBehavior:
	match key:
		&"fractured_prism": return FracturedPrismBehavior.new()
		&"echoing_hourglass": return EchoingHourglassBehavior.new()
		&"bloodwritten_sigil": return BloodwrittenSigilBehavior.new()
	return null
