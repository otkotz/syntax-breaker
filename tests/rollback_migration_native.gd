extends Node

var failures := 0


func _ready() -> void:
	var skill := load("res://resources/skills/blade_spin.tres") as SkillResource
	check(skill != null, "legacy skill id still resolves")
	if skill == null:
		print("ROLLBACK MIGRATION TESTS: %d failed" % failures)
		get_tree().quit(1)
		return
	check(skill.id == "blade_spin", "legacy save id remains compatible")
	check(skill.name == "Rollback", "player-facing Blade Spin is replaced by Rollback")
	check(skill.scene_path == "res://scenes/skills/rollback.tscn", "Rollback uses boomerang runtime")
	check(not skill.tags.has("melee"), "Rollback is no longer exposed as a melee orbit skill")
	print("ROLLBACK MIGRATION TESTS: %d failed" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
