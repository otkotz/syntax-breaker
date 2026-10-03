extends Node2D

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func living_fragments(spawner: Spawner) -> Array[EnemyBase]:
	var result: Array[EnemyBase] = []
	for child: Node in spawner.get_children():
		if child is EnemyBase and child.is_alive() and child.get_meta("spawn_role", "") == "split_fragment":
			result.append(child)
	return result

func run_checks() -> void:
	RunManager.save_path = "res://.godot/splitter_run_test.json"
	MetaProgression.save_path = "res://.godot/splitter_meta_test.json"
	RunManager.start_run()
	var target := Node2D.new()
	add_child(target)
	var spawner := Spawner.new()
	spawner.melee_scene = preload("res://scenes/enemies/basic_melee.tscn")
	spawner.splitter_scene = preload("res://scenes/enemies/splitter_enemy.tscn")
	spawner.split_fragment_scene = preload("res://scenes/enemies/split_fragment.tscn")
	add_child(spawner)
	var completions := [0]
	spawner.all_waves_cleared.connect(func(): completions[0] += 1)
	spawner.setup(target, Rect2(-200, -200, 400, 400))
	spawner._total_budget = 1
	spawner._hp_mult = 1.5
	spawner._damage_mult = 2.0
	spawner._gold_mult = 0.6
	spawner._spawn_enemy_at(Vector2(195, 195), "splitter")
	var splitter: EnemyBase = spawner.get_child(0)
	splitter.take_damage(99999.0)
	splitter.take_damage(99999.0)
	check(spawner._pending_split_fragments == 2 and completions[0] == 0, "Deferred offspring reserve wave count before last parent death")
	check(spawner.get_remaining_enemies() == 2, "HUD counts pending offspring")
	await get_tree().process_frame
	var fragments := living_fragments(spawner)
	check(fragments.size() == 2, "One splitter creates exactly two targets, never repeated on dead hits")
	check(spawner._spawned_count == 1, "Offspring do not consume normal wave budget")
	check(spawner._enemies_alive == 2 and completions[0] == 0, "Last splitter death cannot complete wave before offspring")
	check(spawner.get_active_role_count("splitter") == 0 and spawner.get_active_role_count("split_fragment") == 2, "Role counters reflect replacement")
	for fragment in fragments:
		check(fragment.max_hp == 9.0 and fragment.contact_damage == 6.0, "Offspring inherit stage scaling")
		check(is_equal_approx(fragment.gold_value, 0.15), "Fractional offspring reward retains scaling")
		check(fragment.global_position.x <= 180 and fragment.global_position.y <= 180, "Offspring stay inside arena")
		fragment.set_physics_process(false)
		var origin := fragment.global_position
		fragment._physics_process(0.5)
		check(fragment.global_position == origin and fragment.collision_mask == 0, "Warning fragment cannot move or contact-hit")
		fragment._physics_process(0.51)
		check(fragment.collision_mask == 5 and fragment.collision_layer == 2, "Contact activates after full warning")
		fragment.take_damage(99999.0)
	check(spawner._enemies_alive == 0 and completions[0] == 1, "Wave completes exactly once after last fragment")
	check(living_fragments(spawner).is_empty(), "Fragments never split recursively")
	check(is_equal_approx(RunManager.run_stats.gold_earned, 1.2), "Whole family reward is conserved without integer truncation")

	spawner.setup(target, Rect2(-200, -200, 400, 400))
	spawner._stage_timer = 10.0
	for i in 10:
		spawner._spawn_enemy_at(Vector2.ZERO, "split_fragment", false)
	check(spawner.get_active_role_count("split_fragment") == 8 and spawner._enemies_alive == 8, "Fragment cap cannot fall back to unlimited trash")
	for fragment in living_fragments(spawner):
		check(fragment.activation_remaining == 1.0 and fragment.collision_mask == 0, "Pool reuse restores warning and no contact")
	spawner._spawn_enemy_at(Vector2.ZERO, "splitter")
	splitter.take_damage(99999.0)
	check(spawner.get_active_role_count("split_fragment") == 8, "Splitter death respects saturated fragment cap")
	spawner._spawn_enemy_at(Vector2.ZERO, "splitter")
	var outsider := preload("res://scenes/enemies/basic_melee.tscn").instantiate() as EnemyBase
	add_child(outsider)
	spawner.force_complete()
	check(spawner._enemies_alive == 0 and living_fragments(spawner).is_empty(), "Forced completion suppresses offspring and kills all owned enemies")
	check(spawner.get_active_role_count("split_fragment") == 0 and spawner.get_active_role_count("splitter") == 0, "Forced completion clears role counts")
	check(outsider.is_alive(), "Forced completion cannot kill enemies outside its spawner")
	check(completions[0] == 2, "Forced completion emits only one completion event")
	spawner.setup(target, Rect2(-200, -200, 400, 400))
	spawner._spawn_enemy_at(Vector2.ZERO, "splitter")
	splitter.take_damage(99999.0)
	check(spawner._pending_split_fragments == 2, "New death reserves offspring")
	spawner.force_complete()
	await get_tree().process_frame
	check(spawner._pending_split_fragments == 0 and living_fragments(spawner).is_empty(), "Forced completion invalidates queued spawns")
	check(completions[0] == 3, "Canceled queued offspring cannot emit duplicate completion")
	# Exercise the actual collision-signal path, not just a direct method call.
	spawner.setup(target, Rect2(-200, -200, 400, 400))
	spawner._total_budget = 1
	spawner._spawn_enemy_at(Vector2.ZERO, "splitter")
	splitter.set_physics_process(false)
	var hit_area := Area2D.new()
	hit_area.collision_layer = 0
	hit_area.collision_mask = 2
	var hit_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 60.0
	hit_shape.shape = circle
	hit_area.add_child(hit_shape)
	var collision_hits := [0]
	hit_area.body_entered.connect(func(body: Node2D):
		if body == splitter:
			collision_hits[0] += 1
			body.take_damage(99999.0)
	)
	add_child(hit_area)
	for i in 5:
		await get_tree().physics_frame
		await get_tree().process_frame
	check(collision_hits[0] == 1 and living_fragments(spawner).size() == 2, "Physics collision death safely materializes two offspring")
	check(completions[0] == 3, "Physics-triggered split still waits for children")
	hit_area.queue_free()
	outsider.queue_free()
	spawner.queue_free()
	target.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: splitter offspring, warning, scaling, caps, pooling and wave completion")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
