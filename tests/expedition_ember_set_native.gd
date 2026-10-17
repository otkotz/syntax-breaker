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
	enemy.apply_dot_stack("burn", 99.0, 4.0, 0.5, null, "stack-5", 5)
	stacks = enemy.get_dot_stacks("burn")
	check(stacks.size() == 5 and stacks[4].damage == 99.0, "Refreshing a stack id does not duplicate it")
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
	var trail_target := EnemyBase.new()
	add_child(trail_target)
	trail_target.add_to_group("enemies")
	trail_target.global_position = Vector2(24, 0)
	trail_target.current_hp = 1000.0
	trail_target.max_hp = 1000.0
	for index in 5:
		hooks.emit_event(&"projectile_hit", {"skill": fire_skill, "target": target, "projectile": projectile,
			"damage": 8.0, "world_position": Vector2.ZERO})
	check(target.get_dot_stacks("burn").size() == 5, "Kindling Engine builds five independent burns")
	projectile.artifact_origin_flags.clear()
	var pierce_before := projectile.pierce_remaining
	hooks.emit_event(&"projectile_hit", {"skill": fire_skill, "target": target, "projectile": projectile,
		"damage": 8.0, "world_position": Vector2.ZERO, "origin_flags": projectile.artifact_origin_flags})
	var pierce_after_first := projectile.pierce_remaining
	hooks.emit_event(&"projectile_hit", {"skill": fire_skill, "target": target, "projectile": projectile,
		"damage": 8.0, "world_position": Vector2.ZERO, "origin_flags": projectile.artifact_origin_flags})
	check(pierce_after_first == pierce_before + 1 and projectile.pierce_remaining == pierce_after_first,
		"Ashen Needle grants pierce only once per projectile")
	check(not trail_target.get_dot_stacks("burn").is_empty(), "Ashen Needle leaves a damaging fire trail")
	# Re-prime after the Ashen Needle checks detonated the original target.
	for index in 5:
		target.apply_dot_stack("burn", 10.0, 3.0, 0.5, fire_resource, "detonate-%d" % index, 5)
	var nearby := EnemyBase.new()
	add_child(nearby)
	nearby.add_to_group("enemies")
	nearby.global_position = Vector2(40, 0)
	nearby.current_hp = 1000.0
	nearby.max_hp = 1000.0
	hooks.emit_event(&"projectile_hit", {"skill": fire_skill, "target": target, "projectile": projectile,
		"damage": 8.0, "world_position": Vector2.ZERO, "origin_flags": ["ashen_needle"]})
	check(target.get_dot_stacks("burn").is_empty() and target.current_hp < 1000.0, "Next fire hit detonates and consumes a primed target")
	check(nearby.current_hp < 1000.0, "Conflagration damages nearby enemies")
	var boss := EnemyBase.new()
	add_child(boss)
	boss.set_meta("combat_role", "boss")
	boss.current_hp = 1000.0
	boss.max_hp = 1000.0
	for index in 5:
		boss.apply_dot_stack("burn", 1000.0, 3.0, 0.5, fire_resource, "boss-%d" % index, 5)
	hooks.emit_event(&"projectile_hit", {"skill": fire_skill, "target": boss, "projectile": projectile,
		"damage": 8.0, "world_position": boss.global_position, "origin_flags": ["ashen_needle"]})
	check(boss.current_hp >= 850.0, "Conflagration respects the real boss damage cap")
	var dead := EnemyBase.new()
	add_child(dead)
	dead.apply_dot_stack("burn", 7.0, 2.0, 0.5, fire_resource, "dead-burn", 5)
	var crown_target := EnemyBase.new()
	add_child(crown_target)
	crown_target.current_hp = 1000.0
	crown_target.max_hp = 1000.0
	for node in [target, trail_target, nearby, boss]:
		node.remove_from_group("enemies")
		Targeting.unregister(node)
	crown_target.add_to_group("enemies")
	crown_target.global_position = Vector2(60, 0)
	Targeting.update_position(crown_target)
	check(Targeting.find_enemies_in_range(dead.global_position, 400.0, 8).has(crown_target), "Crown transfer target is discoverable")
	GameBus.enemy_killed.emit(dead, fire_resource)
	check(not crown_target.get_dot_stacks("burn").is_empty(), "Cinder Crown reacts to non-projectile and DoT kills")
	runtime.teardown()
	check(is_equal_approx(fire_skill.computed_stats.damage, 10.0), "Teardown removes Furnace penalty")
	var pair_hooks := ArtifactCombatHooks.new()
	var pair_runtime := ArtifactRuntime.new(ArtifactRegistry.with_defaults(), pair_hooks)
	pair_runtime.setup(["ashen_needle", "cinder_crown", "", ""], [fire_skill], self)
	var pair_target := EnemyBase.new()
	add_child(pair_target)
	pair_target.current_hp = 1000.0
	pair_target.max_hp = 1000.0
	var pair_projectile := ProjectileBase.new()
	add_child(pair_projectile)
	pair_projectile.artifact_hooks = pair_hooks
	for index in 3:
		ProjectileBase.resolve_skill_hit(fire_skill, pair_target, pair_projectile, 10.0)
	check(pair_target.get_dot_stacks("burn").size() == 3,
		"Kindling Engine stacks normal fire burns for any two-piece combination")
	pair_runtime.teardown()
	remove_child(pair_projectile)
	pair_projectile.free()
	remove_child(pair_target)
	pair_target.free()
	remove_child(projectile)
	projectile.free()
	remove_child(target)
	target.free()
	for node in [trail_target, nearby, boss, dead, crown_target]:
		remove_child(node)
		node.free()
	enemy.free()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
