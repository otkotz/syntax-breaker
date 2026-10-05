extends Node2D

var failures: Array[String] = []

class FixedSlam extends MiniBoss:
	func _pick_attack() -> Attack:
		return Attack.SLAM

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	RunManager.save_path = "res://.godot/readability_run_test.json"
	MetaProgression.save_path = "res://.godot/readability_meta_test.json"
	RunTelemetry.log_directory = "res://.godot/readability_telemetry"
	RunManager.start_run()
	_check_projectile()
	_check_silhouettes()
	await _check_slam_budget()
	_check_warning_activation()
	_check_damage_telemetry()
	if failures.is_empty():
		print("PASS: opaque hostile projectiles, readable silhouettes, A0 boss damage budget, warning/activation phases and uncapped damage telemetry")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)

# Catches glow overwriting the opaque core in the baked image, not color declarations.
func _check_projectile() -> void:
	var projectile = load("res://scenes/enemies/enemy_projectile.tscn").instantiate()
	add_child(projectile)
	projectile.set_physics_process(false)
	var img: Image = EnemyProjectile._build_orb_texture().texture.get_image()
	var core := img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	check(core.a >= 0.99 and core.r > 0.9 and core.g > 0.8, "Hostile projectile retains bright opaque core after baking glow")
	check(projectile.z_index >= 20, "Hostile projectile stays above player spells and floor hazards")
	check(is_equal_approx(projectile.get_node("CollisionShape2D").shape.radius, 7.0), "Readability does not enlarge projectile hitbox")
	projectile.queue_free()

# Catches sizing the authoring buffer instead of cropped body, and scaling colliders.
func _check_silhouettes() -> void:
	for fixture in [
		["basic_melee", 25.0, 30.0, 12.0],
		["basic_ranged", 25.0, 45.0, 12.0],
		["tank_enemy", 33.0, 40.0, 16.0],
		["swarm_enemy", 12.0, 20.0, 6.0],
	]:
		var enemy = load("res://scenes/enemies/%s.tscn" % fixture[0]).instantiate()
		add_child(enemy)
		enemy.set_physics_process(false)
		var size: Vector2 = enemy._sprite.texture.get_size() * enemy._sprite.scale
		check(size.x >= fixture[1] and size.y >= fixture[2], "Cropped silhouette meets mobile readability size: " + fixture[0])
		check(enemy.scale == Vector2.ONE and is_equal_approx(enemy.get_node("CollisionShape2D").shape.radius, fixture[3]), "Visual resize leaves physical hitbox unchanged: " + fixture[0])
		enemy.reset()
		enemy.set_physics_process(false)
		enemy.initialize(null)
		enemy.set_physics_process(false)
		var reused_size: Vector2 = enemy._sprite.texture.get_size() * enemy._sprite.scale
		check(reused_size.y >= fixture[2], "Pool reuse preserves readable silhouette: " + fixture[0])
		enemy.queue_free()

# Real spawner + Player: full-HP deaths caused by Elite/Deadly/role multiplier stacking.
func _check_slam_budget() -> void:
	RunTelemetry.begin({}, true)
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	for depth in [4, 6, 10]:
		var stage := StageData.new()
		stage.depth = depth
		stage.type = StageData.Type.ELITE
		stage.region = load("res://resources/regions/burning_grounds.tres")
		stage.modifiers = ["deadly"]
		var spawner := Spawner.new()
		spawner.mini_boss_scene = load("res://scenes/enemies/mini_boss.tscn")
		add_child(spawner)
		spawner.setup(player, Rect2(0, 0, 1080, 1920), stage)
		spawner._spawn_elite()
		var boss: MiniBoss = spawner.get_child(0)
		boss.set_physics_process(false)
		boss.set_process(false)
		boss._slam_target = player.global_position
		player.max_hp = 100.0
		player.current_hp = 100.0
		# Attack-budget regression isolates damage from shield mitigation.
		player.current_shield = 0.0
		player._damage_cooldown = 0.0
		boss._slam_hit()
		var lost: float = 100.0 - player.current_hp
		check(lost >= 28.0 and lost <= 68.0 and player.current_hp > 0.0, "A0 Elite + Deadly slam is punishable, not a full-HP one-shot at depth %d (got %.3f)" % [depth, lost])
		check(boss.contact_damage <= 50.0, "A0 large-enemy contact cannot exceed half base HP at depth %d" % depth)
		var last_hits: Array = RunTelemetry.data.events.filter(func(e: Dictionary): return e.type == "player_damage")
		if not last_hits.is_empty():
			check(last_hits[-1].data.get("attacker_role", "") == "elite" and last_hits[-1].data.get("attacker_id", "") == str(boss.get_instance_id()), "Accepted slam identifies elite instance, not just shared mini_boss source")
		print("BUDGET depth=%d slam=%.3f contact=%.3f" % [depth, lost, boss.contact_damage])
		player.current_hp = 100.0
		player._damage_cooldown = 0.0
		boss._slam_target = player.global_position + Vector2(121, 0)
		boss._slam_hit()
		check(player.current_hp == 100.0, "Escaping locked slam radius prevents damage")
		spawner.queue_free()
		await get_tree().process_frame
	player.queue_free()
	await get_tree().process_frame
	RunTelemetry.finish("abandoned", [])

# Catches early hazard damage, loss of safe sector, invisible activation and missing slam warnings.
func _check_warning_activation() -> void:
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	player.position = Vector2(-100, 0)
	var boss := FixedSlam.new()
	add_child(boss)
	boss.initialize(player)
	boss.set_physics_process(false)
	boss.set_meta("combat_role", "elite")
	RunTelemetry.begin({}, true)
	boss._begin_telegraph()
	var warnings: Array = RunTelemetry.data.events.filter(func(e: Dictionary): return e.type == "hazard_warning" and e.data.source.ends_with(":slam"))
	check(warnings.size() == 1, "Every slam emits its warning before attacking")
	if not warnings.is_empty():
		check(warnings[0].data.get("attacker_role", "") == "elite" and warnings[0].data.get("radius", 0.0) == 120.0, "Slam warning identifies attacker role and exact dangerous area")
	for script_path in ["res://scripts/enemies/boss_hazard.gd", "res://scripts/enemies/denial_zone.gd"]:
		var hazard = load(script_path).new()
		hazard.target = player
		hazard.warning_duration = 1.3
		hazard.warning_remaining = 1.3
		hazard.damage = 10.0
		if script_path.ends_with("boss_hazard.gd"):
			hazard.owner_boss = boss
			hazard.kind = "wedge"
			hazard.radius = 200.0
		else:
			hazard.radius = 200.0
		add_child(hazard)
		hazard.set_process(false)
		player.current_hp = 100.0
		player._damage_cooldown = 0.0
		var events_before: int = RunTelemetry.data.events.filter(func(e: Dictionary): return e.type == "hazard_active").size()
		player.current_shield = 0.0
		hazard._process(1.29)
		check(player.current_hp == 100.0, "Full warning is harmless: " + script_path)
		hazard._process(0.02)
		hazard._process(0.01)
		check(player.current_hp == 90.0, "First active hazard frame damages marked region: " + script_path)
		var has_flash: bool = hazard.get_property_list().any(func(p: Dictionary): return p.name == "activation_remaining")
		check(has_flash, "Hazard has an explicit activation flash: " + script_path)
		if has_flash:
			check(hazard.get("activation_remaining") > 0.0, "Activation flash coincides with the first damaging frame")
		check(RunTelemetry.data.events.filter(func(e: Dictionary): return e.type == "hazard_active").size() == events_before + 1, "Activation recorded once at damage start")
		hazard._process(0.1)
		check(player.current_hp == 90.0, "Hazard tick delay preserved")
		if script_path.ends_with("boss_hazard.gd"):
			player.position = Vector2(100, 0)
			player._damage_cooldown = 0.0
			hazard._process(0.5)
			check(player.current_hp == 90.0, "Pacman opening remains safe after activation")
			player.position = Vector2(-100, 0)
		hazard.queue_free()
	RunTelemetry.finish("abandoned", [])
	boss._remove_slam_indicator()
	boss.queue_free()
	player.queue_free()

# Catches clipped-overkill-only logs, missing max HP and rejected-hit logging.
func _check_damage_telemetry() -> void:
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	RunTelemetry.begin({}, true)
	player.max_hp = 100.0
	player.current_hp = 20.0
	player.current_shield = 0.0
	player.take_damage(75.0, "mini_boss:slam")
	var hits: Array = RunTelemetry.data.events.filter(func(e: Dictionary): return e.type == "player_damage")
	check(hits.size() == 1, "One accepted hit produces one damage event")
	var hit: Dictionary = hits[0].data
	check(hit.get("raw_amount", -1.0) == 75.0 and hit.get("mitigated_amount", -1.0) == 75.0 and hit.amount == 20.0, "Telemetry distinguishes attack strength from clipped HP loss")
	check(hit.get("max_hp", -1.0) == 100.0, "Telemetry can distinguish full-HP one-shot from low-HP finishing hit")
	player.take_damage(75.0, "ignored")
	check(RunTelemetry.data.events.filter(func(e: Dictionary): return e.type == "player_damage").size() == 1, "Dead or invulnerable targets do not record accepted damage")
	RunTelemetry.finish("death", [])
	player.queue_free()
