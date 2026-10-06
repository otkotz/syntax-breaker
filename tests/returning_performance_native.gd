extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	ProjectileBase.active_count = 0
	var player := Node2D.new()
	player.add_to_group("player")
	player.global_position = Vector2.ZERO
	add_child(player)

	var fire := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	fire.computed_stats["range"] = 5000.0
	fire.computed_stats["speed"] = 300.0
	var first := ProjectileBase.new()
	var second := ProjectileBase.new()
	add_child(first)
	add_child(second)
	first.global_position = Vector2(100, 0)
	second.global_position = Vector2(120, 0)
	first.initialize(fire, Vector2.RIGHT, null)
	second.initialize(fire, Vector2.RIGHT, null)
	check(ProjectileBase.active_count == 2, "Each initialized projectile increments the active count once")

	# A frame-rate trail sampler would add a point after these two tiny moves.
	# Distance sampling must wait until the projectile has moved at least 12 px.
	first._physics_process(0.01)
	first._physics_process(0.01)
	check(first._trail_positions.is_empty(), "Trail sampling ignores sub-threshold movement")
	first._physics_process(0.02)
	check(first._trail_positions.size() == 1, "Trail sampling records one point after 12 px")

	first.set_meta("pierce_return", true)
	first.set_meta("return_damage_mult", 0.6)
	first._start_return()
	check(first.get_meta("is_returning", false), "Returning state starts at maximum range")
	check(first.get("_return_target") == player, "Return target is cached on the projectile")
	for i in 100:
		first._trail_positions.append(Vector2(i, 0))
		first._trim_trail()
	check(first._trail_positions.size() <= 12, "Trail storage stays bounded under stress")

	first._return_to_pool()
	first._return_to_pool()
	check(ProjectileBase.active_count == 1, "Repeated release cannot decrement another projectile's active count")
	first.reset()
	check(first.get("_return_target") == null, "Pool reset clears the cached return target")
	check(first._trail_positions.is_empty(), "Pool reset clears trail storage")
	check(not first.has_meta("is_returning") and not first.has_meta("pierce_return"), "Pool reset clears returning metadata")

	first.initialize(fire, Vector2.RIGHT, null)
	check(not first.get_meta("is_returning", false) and first.get("_return_target") == null,
		"A reused normal projectile does not inherit returning state")
	first._return_to_pool()
	second._return_to_pool()
	check(ProjectileBase.active_count == 0, "All stress-test projectiles clean up their active count")

	first.queue_free()
	second.queue_free()
	player.queue_free()
	if failures.is_empty():
		print("PASS: returning trail work, target cache, active count, and pool reset are bounded")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
