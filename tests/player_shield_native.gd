extends Node2D

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	RunManager.save_path = "res://.godot/shield_test_save.json"
	MetaProgression.save_path = "res://.godot/shield_test_meta.json"
	RunManager.start_run()
	for passive_id in ["ward_capacity", "ward_recovery", "ward_reflex"]:
		check(MetaProgression.is_unlocked("passives", passive_id), "Defensive passive is available without a separate unlock: " + passive_id)
		var passive := load("res://resources/passives/" + passive_id + ".tres") as PassiveResource
		check(BuildOptions.can_offer_passive(passive, []), "Shield passive can be offered to every skill build: " + passive_id)
	var player = load("res://scenes/player/player.tscn").instantiate()
	add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	if player.get("max_shield") == null:
		push_error("Player needs a rechargeable shield independent of HP")
		get_tree().quit(1)
		return
	check(is_equal_approx(player.current_shield, 20.0), "New run starts with 20 shield")
	player.take_damage(12.0, "shield_test")
	check(is_equal_approx(player.current_hp, 100.0) and is_equal_approx(player.current_shield, 8.0), "Shield absorbs before HP")
	player.take_damage(12.0, "iframe_test")
	check(is_equal_approx(player.current_shield, 8.0), "Ignored iframe hit cannot damage shield")
	player._process(0.5)
	player.take_damage(15.0, "overflow_test")
	check(is_equal_approx(player.current_hp, 93.0) and is_zero_approx(player.current_shield), "Only shield overflow damages HP")
	RunManager.save_run([])
	var delayed_save: Dictionary = RunManager.load_run()
	check(is_equal_approx(float(delayed_save.get("shield_recharge_remaining", -1)), 5.0), "Accepted hit persists full recharge delay")
	check(is_zero_approx(float(delayed_save.get("current_shield", -1))), "Depleted shield persists instead of being refilled in save")
	player._process(4.0)
	check(is_zero_approx(player.current_shield), "Recharge waits five seconds after accepted hit")
	player._process(2.0)
	check(is_equal_approx(player.current_shield, 5.0), "Large delta only regenerates time after delay")
	RunManager.save_run([])
	var saved: Dictionary = RunManager.load_run()
	player.queue_free()
	await get_tree().process_frame
	RunManager.restore_from_save(saved)
	RunManager.owned_passives = [load("res://resources/passives/ward_capacity.tres"), load("res://resources/passives/ward_recovery.tres"), load("res://resources/passives/ward_reflex.tres")]
	var next = load("res://scenes/player/player.tscn").instantiate()
	add_child(next)
	next.set_process(false)
	next.set_physics_process(false)
	check(is_equal_approx(next.max_shield, 35.0), "Capacity passive adds 15 shield")
	check(is_equal_approx(next.current_shield, 5.0), "Stage transition/capacity increase does not refill shield")
	check(is_equal_approx(next.shield_recharge_rate, 7.5) and is_equal_approx(next.shield_recharge_delay, 4.0), "Passives scale rate and delay independently")
	next._process(20.0)
	check(is_equal_approx(next.current_shield, 35.0), "Recharge is capped at capacity")
	next._damage_cooldown = 0.0
	next.take_damage(1.0, "delay_reset")
	next._process(1.0)
	check(is_equal_approx(next.current_shield, 34.0), "Even a fully absorbed hit restarts recharge delay")
	RunManager.restore_from_save(delayed_save)
	check(is_equal_approx(RunManager.shield_recharge_remaining, 5.0), "Restore retains recharge delay across screens")
	var restored = load("res://scenes/player/player.tscn").instantiate()
	add_child(restored)
	restored.set_process(false)
	restored.set_physics_process(false)
	check(is_equal_approx(restored._shield_recharge_remaining, 5.0) and is_zero_approx(restored.current_shield), "Actual restored player retains depleted shield and delay")
	restored.queue_free()
	var reflex := load("res://resources/passives/ward_reflex.tres")
	RunManager.owned_passives = [reflex, reflex, reflex, reflex, reflex, reflex]
	var stacked = load("res://scenes/player/player.tscn").instantiate()
	add_child(stacked)
	stacked.set_process(false)
	stacked.set_physics_process(false)
	check(is_equal_approx(stacked.shield_recharge_delay, 1.0), "Stacked delay reduction cannot bypass the one-second floor")
	stacked.queue_free()
	RunManager.restore_from_save({"current_hp": 50.0, "max_hp": 100.0})
	check(is_equal_approx(RunManager.current_shield, 20.0), "Old saves get base shield without changing HP")
	if failures.is_empty():
		print("PASS: shield absorption, overflow, iframes, timed recharge, passive scaling and save persistence")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
