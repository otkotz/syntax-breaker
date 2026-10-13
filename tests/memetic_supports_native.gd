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
	for pooled_attack: Node2D in [ProjectileBase.new(), AoeSkillBase.new()]:
		pooled_attack.set_meta("spaghetti_resolved", true)
		pooled_attack.set_meta("stored_frost", true)
		pooled_attack.reset()
		check(not pooled_attack.has_meta("spaghetti_resolved") and not pooled_attack.has_meta("stored_frost"),
			"Pooled attacks clear one-cast support latches before reuse")
		pooled_attack.free()
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
	RunManager.current_stage = 0
	ComboTracker.current_multiplier = 1.0
	fireball.computed_stats["crit_chance"] = 0.0
	fireball.computed_stats["crit_mult"] = 2.0
	var forced_crit := CombatUtils.roll_damage(10.0, fireball, true)
	check(forced_crit.is_crit and is_equal_approx(float(forced_crit.damage), 20.0),
		"Works critical mode multiplies damage instead of changing only the crit flag")

	check(not AltF4Behavior.should_execute_ratio(0.121, false),
		"Alt+F4 leaves normal enemies above 12% alive")
	check(AltF4Behavior.should_execute_ratio(0.12, false),
		"Alt+F4 executes normal enemies at 12%")
	check(not AltF4Behavior.should_execute_ratio(0.031, true),
		"Alt+F4 leaves bosses above 3% alive")
	check(AltF4Behavior.should_execute_ratio(0.03, true),
		"Alt+F4 executes bosses at 3%")
	check(not AltF4Behavior.should_execute_ratio(0.01, false, true),
		"Alt+F4 respects execution protection")

	var lag_plan := LagSpikeBehavior.event_plan(root)
	check(lag_plan.damage_events == 2 and lag_plan.derived_events == 1,
		"Lag Spike schedules exactly one delayed derived hit")
	var lag_child := root.derive("lag_spike", "lagged")
	var recursive_lag_plan := LagSpikeBehavior.event_plan(lag_child)
	check(recursive_lag_plan.damage_events == 1 and recursive_lag_plan.derived_events == 0,
		"A delayed Lag Spike hit cannot recursively spike")

	var duck_plan := RubberDuckBehavior.simulate_hits(["a", "a", "b", "a", "a", "a"])
	check(duck_plan.debugged_targets == ["a"],
		"Rubber Duck debugs only after three consecutive hits on one target")

	for support_id in ["copy_paste", "spaghetti_code", "works_on_my_machine", "lag_spike", "alt_f4", "rubber_duck"]:
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
