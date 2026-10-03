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
	if failures.is_empty():
		print("PASS: three regional bosses, telegraphs, safe areas, cleanse adds and final phases")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
