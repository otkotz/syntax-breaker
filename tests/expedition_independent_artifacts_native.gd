extends Node

class FakePlayer extends Node2D:
	var current_hp := 100.0
	var max_hp := 100.0
	func try_spend_artifact_health(percent: float) -> bool:
		if current_hp / max_hp < 0.9: return false
		current_hp = maxf(1.0, current_hp - max_hp * percent)
		return true

var failures: Array[String] = []
var events: Array[Dictionary] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var hooks := ArtifactCombatHooks.new()
	hooks.combat_event.connect(func(name: StringName, context: Dictionary):
		events.append({"name": name, "context": context})
	)
	var runtime := ArtifactRuntime.new(ArtifactRegistry.with_defaults(), hooks)
	var skill_resource := SkillResource.new()
	skill_resource.base_cooldown = 1.0
	var skill := SkillInstance.new(skill_resource)
	runtime.setup(["fractured_prism", "echoing_hourglass", "bloodwritten_sigil", ""], [skill], self)
	check(is_equal_approx(skill.computed_stats.cooldown, 1.2), "Hourglass lengthens cooldown by twenty percent")
	var fragments: Array[Dictionary] = []
	var prism_projectile := ProjectileBase.new()
	add_child(prism_projectile)
	var prism_context := {"projectile": prism_projectile, "damage": 100.0,
		"origin_flags": prism_projectile.artifact_origin_flags, "generation": 0,
		"spawn_fragment": func(data): fragments.append(data)}
	hooks.emit_event(&"projectile_hit", prism_context)
	check(fragments.size() == 2 and is_equal_approx(fragments[0].damage, 55.0), "Prism creates two 55% fragments")
	hooks.emit_event(&"projectile_hit", prism_context)
	check(fragments.size() == 2, "Prism fragments never split recursively")
	check(fragments[0].generation == 1, "Prism increments fragment generation")
	var echoes := [0]
	for i in 6:
		hooks.emit_event(&"skill_cast", {"spawn_echo": func(): echoes[0] += 1})
	await get_tree().create_timer(0.4).timeout
	check(echoes[0] == 2, "Hourglass echoes every third cast")
	for i in 3:
		hooks.emit_event(&"skill_cast", {"origin_flags": ["echoing_hourglass", "secondary_artifact_projectile"], "spawn_echo": func(): echoes[0] += 1})
	await get_tree().create_timer(0.4).timeout
	check(echoes[0] == 2, "Artifact echoes do not schedule more echoes")
	var player := FakePlayer.new()
	add_child(player)
	var empowered: Array[Dictionary] = []
	hooks.combat_event.connect(func(name: StringName, context: Dictionary):
		if name == &"artifact_cast_empowered": empowered.append(context)
	)
	hooks.emit_event(&"skill_cast", {"player": player})
	check(player.current_hp == 92.0, "Sigil spends eight percent maximum health")
	check(empowered.size() == 1 and empowered[0].damage_mult == 1.35 and empowered[0].area_mult == 1.3, "Sigil supplies damage and area multipliers")
	player.current_hp = 89.0
	hooks.emit_event(&"skill_cast", {"player": player})
	check(player.current_hp == 89.0 and empowered.size() == 1, "Sigil does not empower below threshold")
	runtime.teardown()
	check(is_equal_approx(skill.computed_stats.cooldown, 1.0), "Teardown removes Hourglass cooldown override")
	var before: int = echoes[0]
	for i in 3: hooks.emit_event(&"skill_cast", {"spawn_echo": func(): echoes[0] += 1})
	await get_tree().create_timer(0.4).timeout
	check(echoes[0] == before, "Teardown prevents delayed echoes")
	prism_projectile.queue_free()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
