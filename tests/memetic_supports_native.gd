extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	var fireball := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	var recasts: Array[AttackContext] = []
	fireball.request_recast = func(_direction: Vector2, context: AttackContext, _metadata: Dictionary):
		recasts.append(context)
	var copy := CopyPasteBehavior.new()
	var root := AttackContext.root("fireball", 1)
	copy.on_cast(fireball, {"direction": Vector2.RIGHT, "context": root, "metadata": {}})
	check(recasts.size() == 1, "Copy / Paste repeats one eligible cast")
	copy.on_cast(fireball, {"direction": Vector2.RIGHT, "context": recasts[0], "metadata": {}})
	check(recasts.size() == 1, "Copied cast cannot copy itself")

	var redirect := SpaghettiCodeBehavior.redirect_plan(4)
	check(redirect.unique_targets == 4 and redirect.damage_steps == [1.0, 1.25, 1.5, 1.75],
		"Spaghetti Code redirects with bounded growth")
	for seed in 64:
		var mode := WorksOnMyMachineBehavior.roll_mode(seed)
		check(mode in ["size", "projectiles", "critical", "cooldown"],
			"Works on My Machine has no penalty mode")
	var works := WorksOnMyMachineBehavior.new()
	var works_cast := {"direction": Vector2.RIGHT, "context": root, "metadata": {}}
	works.on_cast(fireball, works_cast)
	var inherited := root.derive("test_child", "test_child")
	check(inherited.metadata.get("works_mode", "") == works_cast.metadata.get("works_mode", ""),
		"Works mode is rolled once and inherited by derived attacks")

	for support_id in ["copy_paste", "spaghetti_code", "works_on_my_machine"]:
		var support := load("res://resources/supports/%s.tres" % support_id) as SupportResource
		check(support != null and BehaviorRegistry.has_behavior(support_id),
			"%s resource and behavior are registered" % support_id)

	if failures.is_empty():
		print("PASS: bounded cast and projectile memetic supports")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
