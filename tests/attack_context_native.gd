extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	var root := AttackContext.root("fireball", 17)
	var copy := root.derive("copy_paste", "copied")
	check(copy.root_cast_id == 17 and copy.generation == 1,
		"Child preserves root and increments generation")
	check(copy.has_flag("copied"), "Child records copied provenance")
	check(not copy.can_derive("copy_paste", "copied"), "Copy cannot recursively copy itself")
	check(root.generation == 0 and not root.has_flag("copied"), "Derivation does not mutate its parent")
	check(AttackContext.can_spawn_child("projectile", 19, 20),
		"Low preset preserves one remaining gameplay slot")
	check(not AttackContext.can_spawn_child("projectile", 20, 20),
		"Low preset enforces gameplay cap")

	var balance := GameBalance.new()
	check(balance.gameplay_projectile_caps.size() == balance.cosmetic_particle_caps.size(),
		"Gameplay and cosmetic quality budgets are independently configurable")
	check(balance.cosmetic_particle_caps[0] < balance.gameplay_projectile_caps[0],
		"Low quality degrades cosmetics before recognizable gameplay")

	var fire := load("res://resources/skills/fireball.tres") as SkillResource
	var skill := SkillInstance.new(fire)
	var first := skill.create_attack_context()
	var second := skill.create_attack_context()
	check(first.skill_id == "fireball" and second.root_cast_id == first.root_cast_id + 1,
		"Skill instances issue stable monotonically increasing root cast IDs")

	if failures.is_empty():
		print("PASS: bounded derived attack provenance and quality caps")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
