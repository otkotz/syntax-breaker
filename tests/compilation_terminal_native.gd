extends Node2D

const CompilationTerminalScript = preload("res://scripts/stages/compilation_terminal.gd")

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func find_buttons(root: Node) -> Array[Button]:
	var result: Array[Button] = []
	for child: Node in root.get_children():
		if child is Button:
			result.append(child)
		result.append_array(find_buttons(child))
	return result

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var terminal := CompilationTerminalScript.new()
	add_child(terminal)
	terminal.wave_size = 4
	terminal.outside_grace = 2.0
	var rewards := [0]
	var failures_seen := [0]
	terminal.wave_completed.connect(func() -> void: rewards[0] += 1)
	terminal.terminal_failed.connect(func() -> void: failures_seen[0] += 1)

	check(terminal.activate(), "Ready terminal activates once")
	check(not terminal.activate(), "Active terminal cannot be activated twice")
	for i in 3:
		terminal.register_wave_kill()
	check(rewards[0] == 0, "Partial wave never opens a reward")
	terminal.register_wave_kill()
	check(rewards[0] == 1 and terminal.state == CompilationTerminalScript.State.COMPLETED,
		"Killing the whole wave completes the terminal exactly once")
	terminal.register_wave_kill()
	check(rewards[0] == 1 and not terminal.activate(), "Completed terminal can never be reused")
	terminal.queue_free()
	await get_tree().process_frame

	var failed_terminal := CompilationTerminalScript.new()
	add_child(failed_terminal)
	failed_terminal.wave_size = 4
	failed_terminal.outside_grace = 2.0
	failed_terminal.terminal_failed.connect(func() -> void: failures_seen[0] += 1)
	check(failed_terminal.activate(), "Second ready terminal activates")
	failed_terminal.set_player_inside(false)
	failed_terminal.advance_wave(1.9)
	check(failed_terminal.state == CompilationTerminalScript.State.ACTIVE,
		"Briefly leaving the zone only pauses compilation")
	failed_terminal.advance_wave(0.2)
	check(failed_terminal.state == CompilationTerminalScript.State.FAILED and failures_seen[0] == 1,
		"Staying outside too long destroys the terminal")
	check(not failed_terminal.activate(), "Destroyed terminal is permanently unavailable")
	failed_terminal.register_wave_kill()
	check(failed_terminal.state == CompilationTerminalScript.State.FAILED,
		"Late kills cannot reward a failed terminal")

	var arena := Arena.new()
	Engine.time_scale = 0.08
	check(arena.has_method("_restore_combat_time"), "Arena exposes one combat-time cleanup boundary")
	if arena.has_method("_restore_combat_time"):
		arena._restore_combat_time()
	check(Engine.time_scale == 1.0, "Arena cleanup always restores normal time")

	var target := Node2D.new()
	add_child(target)
	var spawner := Spawner.new()
	spawner.melee_scene = preload("res://scenes/enemies/basic_melee.tscn")
	spawner.ranged_scene = preload("res://scenes/enemies/basic_ranged.tscn")
	spawner.charger_scene = preload("res://scenes/enemies/charger_enemy.tscn")
	spawner.tank_scene = preload("res://scenes/enemies/tank_enemy.tscn")
	add_child(spawner)
	spawner.setup(target, Rect2(-500, -500, 1000, 1000))
	var spawned: int = spawner.spawn_compilation_wave(Vector2.ZERO, 12)
	var marked := spawner.get_children().filter(func(node: Node): return node.get_meta("compilation_wave", false))
	check(spawned == 12 and marked.size() == 12, "Terminal wave spawns and marks every requested enemy")
	check(spawner._enemies_alive == 12 and spawner._spawned_count == 0,
		"Terminal enemies block encounter completion without consuming its normal budget")
	spawner.clear_transients()
	spawner.queue_free()
	target.queue_free()
	await get_tree().process_frame

	var fireball := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	var offers := MutationData.roll_terminal_mutations(3, [], [fireball])
	check(offers.size() == 3, "Terminal offers three compatible mutations")
	for mutation: Dictionary in offers:
		check(MutationData.can_apply(mutation, fireball), "Every terminal mutation fits an owned skill")
		for key: String in ["damage_mult", "area_mult", "range_mult", "speed_mult"]:
			check(not mutation.get("stats", {}).has(key) or float(mutation.stats[key]) >= 1.0,
				"Terminal mutations contain no harmful stat tradeoffs")

	var picker := CompilationPicker.new()
	add_child(picker)
	picker.setup([fireball])
	var buttons := find_buttons(picker)
	check(buttons.size() == 3, "Successful terminal offers exactly three rewards and no skip button")
	var mutations_before := fireball.mutations.size()
	buttons[0].pressed.emit()
	check(fireball.mutations.size() == mutations_before + 1,
		"Choosing a terminal reward installs a persistent skill mutation")
	await get_tree().process_frame

	if failures.is_empty():
		print("PASS: compilation terminal risk, permanence and mutation rewards")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
