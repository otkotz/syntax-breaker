extends Node

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var enemy := EnemyBase.new()
	enemy.current_hp = 1000.0
	enemy.max_hp = 1000.0
	enemy.apply_dot("burn", 2.0, 3.0, 0.5)
	enemy.apply_dot("burn", 4.0, 3.0, 0.5)
	check(enemy.get_dot_stacks("burn").size() == 1 and enemy.get_dot_stacks("burn")[0].damage == 4.0, "Legacy burn remains single and replaceable")
	for index in 6:
		enemy.apply_dot_stack("burn", float(index + 1), 3.0, 0.5, null, "stack-%d" % index, 5)
	var stacks: Array = enemy.get_dot_stacks("burn")
	check(stacks.size() == 5, "Kindling caps burn at five stacks")
	check(stacks[0].stack_id == "stack-1" and stacks[4].stack_id == "stack-5", "Sixth burn replaces oldest stack")
	var consumed: Array = enemy.consume_dot_stacks("burn", 5)
	check(consumed.size() == 5 and enemy.get_dot_stacks("burn").is_empty(), "Conflagration consumes five stacks")
	var fire_resource := SkillResource.new()
	fire_resource.tags = ["projectile", "fire"]
	fire_resource.base_damage = 10.0
	var fire_skill := SkillInstance.new(fire_resource)
	var hooks := ArtifactCombatHooks.new()
	var runtime := ArtifactRuntime.new(ArtifactRegistry.with_defaults(), hooks)
	runtime.setup(["furnace_heart", "ashen_needle", "cinder_crown", ""], [fire_skill], self)
	check(is_equal_approx(fire_skill.computed_stats.damage, 8.0), "Furnace Heart reduces direct fire damage")
	var target := EnemyBase.new()
	add_child(target)
	target.current_hp = 1000.0
	target.max_hp = 1000.0
	var projectile := ProjectileBase.new()
	add_child(projectile)
	projectile.pierce_remaining = 0
	for index in 5:
		hooks.emit_event(&"projectile_hit", {"skill": fire_skill, "target": target, "projectile": projectile,
			"damage": 8.0, "world_position": Vector2.ZERO})
	check(target.get_dot_stacks("burn").size() == 5, "Kindling Engine builds five independent burns")
	hooks.emit_event(&"projectile_hit", {"skill": fire_skill, "target": target, "projectile": projectile,
		"damage": 8.0, "world_position": Vector2.ZERO})
	check(target.get_dot_stacks("burn").is_empty() and target.current_hp < 1000.0, "Next fire hit detonates and consumes a primed target")
	runtime.teardown()
	check(is_equal_approx(fire_skill.computed_stats.damage, 10.0), "Teardown removes Furnace penalty")
	remove_child(projectile)
	projectile.free()
	remove_child(target)
	target.free()
	enemy.free()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
