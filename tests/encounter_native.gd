extends Node2D

class TargetDummy extends Node2D:
	var damage_received: float = 0.0
	func take_damage(amount: float) -> void:
		damage_received += amount

class DamageDummy extends EnemyBase:
	func _setup_sprite() -> void:
		pass
	func _flash_hit() -> void:
		pass
	func _spawn_damage_number(_amount: float, _crit: bool = false) -> void:
		pass

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	RunManager.save_path = "res://.godot/encounter_run_test.json"
	MetaProgression.save_path = "res://.godot/encounter_meta_test.json"
	RunManager.start_run()
	var target := TargetDummy.new()
	add_child(target)
	target.position = Vector2(150, 0)
	var charger = preload("res://scenes/enemies/charger_enemy.tscn").instantiate()
	add_child(charger)
	charger.initialize(target)
	charger.set_physics_process(false)
	charger.attack_timer = 0.0
	charger._physics_process(0.01)
	check(charger.attack_state == "windup", "Charger starts with warning")
	var locked_direction: Vector2 = charger.charge_direction
	target.position = Vector2(150, 150)
	charger._physics_process(0.5)
	check(charger.attack_state == "windup" and charger.position == Vector2.ZERO, "No movement during warning")
	check(charger.charge_direction == locked_direction, "Charge aim stays locked for perpendicular dodge")
	charger._physics_process(0.5)
	check(charger.attack_state == "charge", "Charge follows full warning")
	charger.apply_slow(0.5, 0.1)
	charger._physics_process(0.2)
	check(charger._slow_factor == 1.0, "Slow expires during charge")
	charger.reset()
	check(charger.attack_state == "chase" and charger.attack_timer == 2.0, "Pool reset clears charge")
	charger.set_physics_process(false)
	charger.queue_free()

	var caster = preload("res://scenes/enemies/denial_caster.tscn").instantiate()
	add_child(caster)
	caster.initialize(target)
	caster.set_physics_process(false)
	caster.cast_timer = 0.0
	caster._physics_process(0.01)
	var zones := get_tree().get_nodes_in_group("denial_zones")
	check(zones.size() == 1, "Caster creates a zone")
	var zone = zones[0]
	zone.set_process(false)
	check(zone.global_position == target.global_position, "Zone marks locked target position")
	zone._process(1.1)
	check(target.damage_received == 0.0, "Warning cannot deal damage")
	zone._process(0.11)
	target.position += Vector2(100, 0)
	zone._process(0.01)
	check(target.damage_received == 0.0, "Leaving zone avoids damage")
	target.global_position = zone.global_position
	zone._process(0.5)
	check(target.damage_received == 6.0, "Active zone deals configured tick damage")
	zone._process(0.1)
	check(target.damage_received == 6.0, "Damage ticks are rate limited")
	zone._process(3.0)
	check(zone.is_queued_for_deletion(), "Zone expires")
	await get_tree().process_frame
	for i in 8:
		caster.cast_timer = 0.0
		caster._physics_process(0.01)
	check(get_tree().get_nodes_in_group("denial_zones").size() == 6, "Zone population capped at six")
	caster.reset()
	check(caster.cast_timer == 2.0, "Pool reset clears caster cooldown")
	caster.set_physics_process(false)
	for live_zone in get_tree().get_nodes_in_group("denial_zones"):
		live_zone.queue_free()
	caster.queue_free()

	var ally := DamageDummy.new()
	ally.max_hp = 100.0
	add_child(ally)
	ally.set_physics_process(false)
	var support = preload("res://scenes/enemies/shield_support.tscn").instantiate()
	add_child(support)
	support.initialize(target)
	support.set_physics_process(false)
	support._refresh_links()
	check(support.linked_allies.has(ally) and ally._has_support_guard(), "Nearby ally has visible support link")
	var fireball := load("res://resources/skills/fireball.tres") as SkillResource
	ally.take_damage(10.0, false, fireball)
	check(ally.current_hp == 93.0, "Shield reduces received damage by thirty percent")
	check(RunManager.run_stats.direct_damage_by_skill.get("fireball", 0) == 7.0, "Attribution records damage after enemy shield")
	ally.position = Vector2(151, 0)
	check(not ally._has_support_guard(), "Leaving aura removes protection immediately")
	ally.take_damage(10.0)
	check(ally.current_hp == 83.0, "Outside aura damage is unmodified")
	ally.position = Vector2.ZERO
	ally.add_to_group("bosses")
	check(not ally._has_support_guard(), "Bosses are not shielded")
	ally.remove_from_group("bosses")
	check(not support._has_support_guard(), "Support cannot shield itself")
	var other_support = preload("res://scenes/enemies/shield_support.tscn").instantiate()
	add_child(other_support)
	other_support.initialize(target)
	other_support.set_physics_process(false)
	check(not other_support._has_support_guard(), "Supports cannot shield each other")
	ally.take_damage(10.0)
	check(ally.current_hp == 76.0, "Two overlapping supports cannot stack reduction")
	other_support.take_damage(999.0)
	support.take_damage(999.0)
	check(support.linked_allies.is_empty() and not ally._has_support_guard(), "Real support death removes aura and links")
	ally.take_damage(10.0)
	check(ally.current_hp == 66.0, "Killing priority target restores full damage to group")
	support.reset()
	support.set_physics_process(false)
	check(support.linked_allies.is_empty() and not ally._has_support_guard(), "Reset does not restore aura before initialization")
	support.initialize(target)
	support.set_physics_process(false)
	check(ally._has_support_guard(), "Reinitialized pooled support grants fresh aura")
	support.queue_free()
	other_support.queue_free()
	ally.queue_free()
	await get_tree().process_frame

	var spawner := Spawner.new()
	spawner.melee_scene = preload("res://scenes/enemies/basic_melee.tscn")
	spawner.charger_scene = preload("res://scenes/enemies/charger_enemy.tscn")
	spawner.denial_caster_scene = preload("res://scenes/enemies/denial_caster.tscn")
	spawner.shield_support_scene = preload("res://scenes/enemies/shield_support.tscn")
	spawner.mini_boss_scene = preload("res://scenes/enemies/mini_boss.tscn")
	add_child(spawner)
	spawner.setup(target, Rect2(-500, -500, 1000, 1000))
	for role: String in ["charger", "denial_caster", "shield_support"]:
		for i in 4:
			spawner._spawn_enemy_at(Vector2.ZERO, role)
		check(spawner.get_active_role_count(role) == int(Spawner.ROLE_LIMITS[role]), "Special enemy cap: " + role)
	var pooled: EnemyBase = spawner.get_child(0)
	pooled.current_hp = 0.0
	spawner._on_enemy_died(pooled)
	check(spawner.get_active_role_count("charger") == 1, "Death releases active role count")
	spawner._spawn_enemy_at(Vector2.ZERO, "charger")
	check(spawner.get_active_role_count("charger") == 2 and pooled.current_hp > 0, "Pooled charger re-enters with reset health/count")
	spawner._spawn_elite()
	var elite: EnemyBase
	for child: Node in spawner.get_children():
		if child.has_node("EliteAffix"):
			elite = child
	var affix = elite.get_node("EliteAffix")
	check(affix.kind == "trail", "First elite receives trail affix")
	elite.global_position = target.global_position
	for i in 8:
		affix.cooldown = 0.0
		affix._process(0.01)
	check(get_tree().get_nodes_in_group("elite_hazards").size() == 5, "Trail cap reserves one slot for nova")
	var trail = get_tree().get_nodes_in_group("elite_hazards")[0]
	trail.set_process(false)
	var damage_before := target.damage_received
	trail._process(0.8)
	check(target.damage_received == damage_before, "Trail warning is harmless")
	trail._process(0.01)
	check(target.damage_received > damage_before, "Active trail deals damage")
	for hazard in get_tree().get_nodes_in_group("elite_hazards"):
		hazard.queue_free()
	await get_tree().process_frame
	# Death of a trail elite has no nova, and pool reset removes the old affix.
	elite.take_damage(99999.0)
	check(affix.kind.is_empty(), "Death clears previous affix")
	check(get_tree().get_nodes_in_group("elite_hazards").is_empty(), "Trail elite does not explode")
	spawner._spawn_elite()
	check(affix.kind == "nova" and elite.is_alive(), "Next elite reuses pool with new nova affix")
	elite.global_position = target.global_position
	var nova_damage := elite.contact_damage * 1.2
	damage_before = target.damage_received
	elite.take_damage(99999.0)
	var hazards := get_tree().get_nodes_in_group("elite_hazards")
	check(hazards.size() == 1, "Real nova elite death creates one stage-owned hazard")
	var nova = hazards[0]
	nova.set_process(false)
	check(nova.get_parent() == spawner, "Nova is not attached to pooled corpse")
	nova._process(1.2)
	check(target.damage_received == damage_before, "Death nova gives full warning before damage")
	nova._process(0.01)
	check(is_equal_approx(target.damage_received, damage_before + nova_damage), "Nova delivers scaled damage")
	nova._process(0.5)
	check(is_equal_approx(target.damage_received, damage_before + nova_damage), "Nova hits only once")
	nova._process(0.1)
	check(nova.is_queued_for_deletion(), "Nova expires after one pulse")
	spawner.queue_free()
	target.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: encounter warnings, dodge, lifetime, caps, shield aura, elite affixes and pool reset")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
