extends Node2D

class TargetDummy extends Node2D:
	var damage_received: float = 0.0
	func take_damage(amount: float) -> void:
		damage_received += amount

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	RunManager.save_path = "res://.godot/boss_run_test.json"
	MetaProgression.save_path = "res://.godot/boss_meta_test.json"
	RunManager.start_run()
	var notices := [0]
	GameBus.boss_phase_changed.connect(func(_message: String): notices[0] += 1)
	for region: String in ["burning_grounds", "storm_spire", "toxic_depths"]:
		var target := TargetDummy.new()
		add_child(target)
		target.position = Vector2(600, 875)
		var spawner := Spawner.new()
		spawner.split_fragment_scene = preload("res://scenes/enemies/split_fragment.tscn")
		add_child(spawner)
		var stage := StageData.new()
		stage.type = StageData.Type.BOSS
		stage.depth = 5
		stage.region = load("res://resources/regions/%s.tres" % region)
		spawner.setup(target, Rect2(0, 0, 1000, 1750), stage)
		spawner._total_budget = 0
		spawner._spawn_boss()
		var boss = spawner.get_child(0)
		boss.set_physics_process(false)
		boss.move_speed = 0.0
		check(boss.boss_region == region and boss.is_in_group("bosses"), "Spawner routes regional scene: " + region)
		boss._perform_attack()
		for hazard in boss.hazards:
			hazard.set_process(false)
		match region:
			"burning_grounds":
				var wall = boss.hazards[0]
				check(wall.kind == "wall", "Fire boss starts with wall, not legacy charge")
				check(not wall.threatens(wall.global_position), "Wall has a safe gap")
				check(wall.threatens(wall.global_position + Vector2(100, 0).rotated(wall.angle)), "Wall threatens its painted strip")
				check(not wall.threatens(wall.global_position + Vector2(100, 70).rotated(wall.angle)), "Crossing wall perpendicularly allows dodge")
				boss._perform_attack()
				var wedge = boss.hazards[-1]
				wedge.set_process(false)
				check(wedge.kind == "wedge", "Fire boss alternates safe-wedge attack")
				check(not wedge.threatens(wedge.global_position + Vector2.from_angle(wedge.angle) * 100), "Wedge safe sector is genuinely safe")
				check(wedge.threatens(wedge.global_position - Vector2.from_angle(wedge.angle) * 100), "Other sectors deal damage")
			"storm_spire":
				check(boss.hazards.size() == 3, "Storm creates sequence of three lines")
				check(boss.hazards[0].angle != boss.hazards[1].angle and boss.hazards[0].warning_remaining < boss.hazards[1].warning_remaining, "Storm lines rotate and are staggered")
				var beam = boss.hazards[0]
				beam._process(0.99)
				check(target.damage_received == 0.0, "Storm warning deals no damage")
				beam._process(0.02)
				beam._process(0.01)
				var damage_after: float = target.damage_received
				check(damage_after > 0, "Storm line strikes after warning")
				beam._process(0.1)
				check(target.damage_received == damage_after, "Storm line strikes once")
			"toxic_depths":
				check(boss.hazards.size() == 3 and boss.hazards[0].kind == "pool", "Toxic boss lays three poison pools")
				var pool = boss.hazards[0]
				check(pool.threatens(target.global_position), "Poison marks original target position")
				await get_tree().process_frame
				var adds: Array[EnemyBase] = []
				for child in spawner.get_children():
					if child is EnemyBase and child.get_meta("cleanses_boss_poison", false):
						adds.append(child)
				check(adds.size() == 2 and spawner._enemies_alive == 3, "Toxic adds are registered living targets")
				adds[0].global_position = target.global_position
				adds[0].take_damage(99999.0)
				check(not pool.threatens(target.global_position), "Killing toxic add clears nearby poison")
				check(not adds[0].has_meta("cleanses_boss_poison"), "Cleanse marker cannot leak into pool reuse")
		boss.current_hp = boss.max_hp * 0.49
		boss._physics_process(0.0)
		check(not boss.second_phase, "Depth five boss never enters final phase")
		boss.configure_encounter(10)
		var notice_before: int = notices[0]
		boss._physics_process(0.0)
		boss._physics_process(0.0)
		check(boss.second_phase and notices[0] == notice_before + 1, "Final phase starts at half HP and warns only once: " + region)
		var rule = boss.hazards[-1]
		rule.set_process(false)
		match region:
			"burning_grounds":
				check(rule.kind == "border" and rule.threatens(Vector2(20, 875)) and not rule.threatens(Vector2(500, 875)), "Fire finale ignites edges, leaving center safe")
			"storm_spire":
				check(rule.kind == "rotating_gap" and rule.angular_speed > 0, "Storm finale changes arena to rotating safe sector")
				var old_angle: float = rule.angle
				rule._process(2.0)
				rule._process(0.5)
				check(rule.angle > old_angle, "Final storm safe sector actually rotates")
			"toxic_depths":
				check(rule.kind == "pressure", "Toxic finale poisons arena outside safe islands")
				var safe_center: Vector2 = rule.cleared_discs[0].position
				check(not rule.threatens(safe_center) and rule.threatens(Vector2(20, 20)), "Toxic pressure leaves a reachable safe island")
				for poison in boss.hazards:
					if poison.is_in_group("boss_poison"):
						check(not poison.threatens(safe_center), "Regular puddles cannot invalidate safe island")
		for i in 20:
			boss._spawn_hazard("beam", target.global_position, 1.0, 1.0)
		check(boss.hazards.size() == 12, "Boss hazard population is bounded")
		for hazard in boss.hazards:
			hazard.set_process(false)
		if region == "toxic_depths":
			spawner.spawn_boss_adds(boss)
			check(spawner._pending_split_fragments > 0, "Live toxic boss can reserve further adds")
		boss.take_damage(999999.0)
		for child: Node in spawner.get_children().duplicate():
			if child is EnemyBase and child != boss and child.visible:
				(child as EnemyBase).take_damage(999999.0)
		check(spawner.completion_boss_killed, "A real depth-five boss death preserves boss-kill credit")
		check(spawner._pending_split_fragments == 0, "Boss death cancels pending adds")
		check(boss.hazards.is_empty() and rule.is_queued_for_deletion(), "Boss death removes all owned hazards")
		boss.reset()
		check(not boss.second_phase and not boss.final_encounter and boss.hazards.is_empty(), "Boss pool reset removes encounter state")
		await get_tree().process_frame
		check(spawner._pending_boss_add_requests.is_empty(), "Canceled add callbacks cannot revive boss requests")
		spawner.queue_free()
		target.queue_free()
		await get_tree().process_frame
	check(notices[0] == 3, "Three regional final-phase notices")

	var final_target := TargetDummy.new()
	add_child(final_target)
	final_target.position = Vector2(500, 875)
	var final_spawner := Spawner.new()
	final_spawner.melee_scene = preload("res://scenes/enemies/basic_melee.tscn")
	final_spawner.split_fragment_scene = preload("res://scenes/enemies/split_fragment.tscn")
	add_child(final_spawner)
	var final_stage := StageData.new()
	final_stage.type = StageData.Type.BOSS
	final_stage.depth = 10
	final_stage.region = load("res://resources/regions/burning_grounds.tres")
	final_spawner.setup(final_target, Rect2(0, 0, 1000, 1750), final_stage)
	var final_completions := [0]
	final_spawner.all_waves_cleared.connect(func() -> void: final_completions[0] += 1)
	check(final_spawner.has_method("is_final_boss_encounter") and final_spawner.is_final_boss_encounter(),
		"Depth ten boss stage is a dedicated final encounter")
	final_spawner.start_next_wave()
	final_spawner._process(20.0)
	var final_boss: EnemyBase
	var ordinary_count := 0
	for child: Node in final_spawner.get_children():
		if child is EnemyBase and child.visible:
			if child.get_meta("combat_role", "") == "boss":
				final_boss = child
			else:
				ordinary_count += 1
	check(final_spawner._spawned_count == 0 and ordinary_count == 0,
		"Final boss stage never spawns ordinary waves")
	check(final_boss != null, "Final encounter starts with exactly one boss")
	check(final_spawner.get_remaining_enemies() == 1,
		"Final encounter HUD counts only its live boss, not suppressed normal waves")
	if final_boss:
		check("phase_index" in final_boss and final_boss.get("phase_index") == 1,
			"Final boss starts in phase one")
		check(final_boss.max_hp >= final_boss._base_max_hp * final_spawner._hp_mult * 4.9,
			"Final boss receives approximately five times stage-scaled HP")
		check(final_boss.move_speed >= final_boss._base_move_speed * final_spawner._speed_mult,
			"Final boss keeps full stage speed instead of the legacy slowdown")
		var old_world_scale: float = MiniBoss.BOSS_SCALE.get(final_boss._boss_type(), 0.8) * 1.8
		check(final_boss._sprite.scale.x >= old_world_scale * 1.35 and final_boss.get_node("CollisionShape2D").scale.x <= 1.15,
			"Final boss is at least 35 percent larger than its previous world-space footprint without hitbox inflation")
		final_boss.current_hp = final_boss.max_hp * 0.64
		final_boss._physics_process(0.0)
		check(final_boss.get("phase_index") == 2, "Phase two begins below 65 percent")
		final_boss.current_hp = final_boss.max_hp * 0.29
		final_boss._physics_process(0.0)
		check(final_boss.get("phase_index") == 3, "Phase three begins below 30 percent")
		check(ResourceLoader.exists("res://scripts/enemies/boss_projectile_volley.gd"),
			"Final boss has a dedicated projectile-volley helper")
		var volley_script := load("res://scripts/enemies/boss_projectile_volley.gd")
		volley_script.spawn(final_spawner, Vector2(-50, -50), final_target.global_position,
			"fan", 50, 200.0, 5.0, "test:edge_volley")
		var projectile_pool := final_spawner.get_node_or_null("BossProjectilePool") as ObjectPool
		check(projectile_pool != null and projectile_pool.active_count() <= 36,
			"Boss projectile population is hard capped")
		if projectile_pool:
			for projectile: EnemyProjectile in projectile_pool.get_active().duplicate():
				check(final_spawner._arena_rect.has_point(projectile.global_position),
					"Edge volleys start inside the readable arena")
				var warning_origin := projectile.global_position
				check(projectile.get("warning_remaining") is float and projectile.get("warning_remaining") > 0.0,
					"Boss projectiles expose a harmless emission telegraph")
				projectile._physics_process(0.2)
				check(projectile.global_position == warning_origin,
					"Boss projectiles remain stationary during their warning")
				projectile._physics_process(10.0)
			check(projectile_pool.active_count() == 0, "Every boss projectile releases after its range")
		final_spawner._spawn_enemy_at(Vector2(300, 300), "split_fragment", false, true)
		final_boss.take_damage(final_boss.current_hp + 1.0)
		check(final_completions[0] == 1, "Boss death immediately completes final map")
		check(final_spawner.get_remaining_enemies() == 0, "Mechanic adds do not gate final victory")
	final_spawner.queue_free()
	final_target.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: three regional bosses, telegraphs, safe areas, cleanse adds and final phases")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
