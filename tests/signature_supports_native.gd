extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	check(FirewallBehavior.segments_for_impact() == 1,
		"Firewall connects caster and impact once")
	check(ReplyAllBehavior.children_after_hits(99) == 1,
		"Reply All emits once per root cast")
	check(FrozenProcessBehavior.repeat_damage(17.0) == 17.0,
		"Frozen Process repeats stored damage on thaw")
	check(WifiExtenderBehavior.chain_ranges(100.0) == [100.0, 125.0, 150.0],
		"Wi-Fi Extender grows chain range")
	check(MalwareBehavior.damage_after_actions(10.0, 3) > MalwareBehavior.damage_after_actions(10.0, 0),
		"Malware grows when its host acts")
	check(BackgroundProcessBehavior.ghosts_after_expiry() == 1,
		"Background Process leaves one bounded ghost")
	var path: Array[Vector2] = [Vector2.ZERO, Vector2.RIGHT, Vector2(2, 1)]
	check(UndoHistoryBehavior.retrace_path(path) == [Vector2(2, 1), Vector2.RIGHT, Vector2.ZERO],
		"Undo History retraces the exact outbound path")

	var root := AttackContext.root("fireball", 1)
	var copy := root.derive("copy_paste", "copied")
	var reply := copy.derive("reply_all", "reply_all_child")
	var recursive := reply.derive("recursive_rollback", "recursive_rollback")
	check(recursive.generation == AttackContext.MAX_GENERATION,
		"Composite signature effects stop at the provenance generation cap")
	check(not recursive.can_derive("reply_all", "reply_all_child"),
		"Composite signature effects cannot repeat their own flags")

	var fireball := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	var replies: Array[AttackContext] = []
	fireball.request_recast = func(_direction: Vector2, child: AttackContext, _metadata: Dictionary):
		replies.append(child)
	var projectile := ProjectileBase.new()
	projectile.attack_context = AttackContext.root("fireball", 20)
	projectile.direction = Vector2.RIGHT
	add_child(projectile)
	var reply_behavior := ReplyAllBehavior.new()
	reply_behavior.on_hit(fireball, projectile, projectile)
	reply_behavior.on_hit(fireball, projectile, projectile)
	await get_tree().process_frame
	check(replies.size() == 1 and replies[0].has_flag("reply_all_child"),
		"Reply All emits one real derived recast per root context")
	projectile.queue_free()

	var static_field := SkillInstance.new(load("res://resources/skills/static_field.tres"))
	var ghosts: Array[AttackContext] = []
	static_field.request_recast = func(_direction: Vector2, child: AttackContext, _metadata: Dictionary):
		ghosts.append(child)
	var field := AoeSkillBase.new()
	field.attack_context = AttackContext.root("static_field", 21)
	add_child(field)
	var background := BackgroundProcessBehavior.new()
	background.on_expire(static_field, field)
	background.on_expire(static_field, field)
	await get_tree().process_frame
	check(ghosts.size() == 1 and ghosts[0].has_flag("background_ghost"),
		"Background Process produces bounded derived ghost contexts")
	check(not ghosts[0].can_derive("background_process", "background_ghost"),
		"A Background Process ghost cannot leave another ghost")
	field.queue_free()

	var expected := {
		"firewall": "flame_wave", "reply_all": "fireball",
		"frozen_process": "frost_nova", "wifi_extender": "lightning_bolt",
		"malware": "poison_dart", "background_process": "static_field",
		"undo_history": "blade_spin",
	}
	for support_id: String in expected:
		var support := load("res://resources/supports/%s.tres" % support_id) as SupportResource
		check(support != null and BehaviorRegistry.has_behavior(support_id),
			"%s is a registered support" % support_id)
		if support:
			var behavior := BehaviorRegistry.get_behavior(support.behavior_key)
			var correct := SkillInstance.new(load("res://resources/skills/%s.tres" % expected[support_id]))
			check(behavior.accepts(correct), "%s accepts its signature skill" % support_id)
			check(correct.link_support(support), "%s links to its signature skill" % support_id)
			var wrong_skill_id := "lightning_bolt" if expected[support_id] != "lightning_bolt" else "fireball"
			var wrong := SkillInstance.new(load("res://resources/skills/%s.tres" % wrong_skill_id))
			check(not wrong.link_support(support), "%s rejects other skills" % support_id)

	if failures.is_empty():
		print("PASS: seven bounded signature supports and composite provenance")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
