extends Node2D

class TestPlayer extends Player:
	func _setup_animated_sprite() -> void:
		_anim_sprite = AnimatedSprite2D.new()
		add_child(_anim_sprite)
	func _spawn_damage_number(_amount: float) -> void:
		pass

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	RunManager.start_run()
	var player := TestPlayer.new()
	add_child(player)
	player.global_position = Vector2(100, 0)
	player.set_physics_process(false)
	var first := EnemyBase.new()
	add_child(first)
	first.global_position = Vector2.ZERO
	first.set_physics_process(false)
	first.contact_damage = 5.0
	check(first.contact_damage_cooldown >= 0.75, "Normal enemies have a safe contact cooldown floor")
	check(first._attempt_contact(player), "First overlap hit is accepted")
	check(not first._attempt_contact(player), "One overlap cannot multi-hit during its cooldown")
	check(player.velocity.x > 0.0, "Contact separation pushes the player away from the attacker")
	var second := EnemyBase.new()
	add_child(second)
	second.set_physics_process(false)
	second.contact_damage = 5.0
	check(second._attempt_contact(player), "A second attacker owns an independent cooldown")
	check(RunManager.get_death_sequence().size() == 2, "Shield-only accepted contact hits enter damage history")
	first.advance_contact_cooldown(first.contact_damage_cooldown)
	check(first._attempt_contact(player), "Contact can hit again after the cooldown")
	first.deactivate_without_rewards()
	first.reset()
	check(first._attempt_contact(player) and not first._attempt_contact(player),
		"Pool reset permits one immediate hit and re-arms the cooldown")
	var tank := preload("res://scenes/enemies/tank_enemy.tscn").instantiate() as EnemyBase
	add_child(tank)
	check(tank.contact_damage_cooldown >= 0.9, "Tank contact cooldown is at least 0.9 seconds")
	if failures.is_empty():
		print("PASS: per-attacker contact cooldown, separation and pool reset")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
