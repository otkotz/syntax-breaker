extends Node2D

const CompilationTerminalScript = preload("res://scripts/stages/compilation_terminal.gd")
const TerminalContractPickerScript = preload("res://scripts/ui/terminal_contract_picker.gd")
const DecisionQueueScript = preload("res://scripts/main/decision_queue.gd")

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
	RunManager.save_path = "res://.godot/compiler_heat_run_test.json"
	RunManager.start_run()
	check(RunManager.compiler_heat == 0, "New run starts with a cold compiler")
	RunManager.add_compiler_heat(1)
	RunManager.add_compiler_heat(3)
	check(RunManager.compiler_heat == 4, "Completed contracts accumulate compiler heat")
	RunManager.save_run([])
	RunManager.compiler_heat = 0
	RunManager.restore_from_save(RunManager.load_run())
	check(RunManager.compiler_heat == 4, "Compiler heat survives save and resume")
	var queue := DecisionQueueScript.new()
	add_child(queue)
	var order: Array[StringName] = []
	queue.decision_ready.connect(func(request: Dictionary): order.append(request.kind))
	queue.enqueue(&"terminal", {}, 400)
	queue.enqueue(&"reward_a", {}, 200)
	queue.enqueue(&"reward_b", {}, 200)
	check(order == [&"terminal"], "Only one modal decision becomes active")
	check(queue.complete_active({}) and not queue.complete_active({}), "A decision can complete exactly once")
	await get_tree().process_frame
	check(order == [&"terminal", &"reward_a"], "Queue advances after completion")
	check(queue.cancel_active("test") and not queue.cancel_active("duplicate"), "Cancellation is explicit and idempotent")
	await get_tree().process_frame
	check(order == [&"terminal", &"reward_a", &"reward_b"], "Equal priorities preserve FIFO")
	queue.clear()
	check(queue.active_request().is_empty() and queue.pending_count() == 0, "Clear removes active and pending decisions")
	queue.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261010
	var counts := [0, 0, 0]
	for i in 3000:
		counts[CompilationTerminalScript.roll_difficulty(rng)] += 1
	for count: int in counts:
		check(count >= 900 and count <= 1100, "Test mode exposes each difficulty approximately equally")
	var definitions := CompilationTerminalScript.ENCOUNTERS
	check(definitions[0].enemy_count == 24 and definitions[0].outside_grace == 3.0, "Compile contract")
	check(definitions[1].enemy_count == 32 and definitions[1].outside_grace == 2.0, "Overclock contract")
	check(definitions[2].enemy_count == 40 and definitions[2].outside_grace == 1.0, "Kernel contract")
	var early_contract := CompilationTerminalScript.scaled_encounter(CompilationTerminalScript.Difficulty.COMPILE, 1, 1.0, 0)
	check(early_contract.enemy_count <= 14 and early_contract.outside_grace >= 4.0,
		"Early Compile contract is survivable for a starter build")
	check(float(early_contract.hp_mult) <= 0.9 and not early_contract.miniboss,
		"Early terminal does not create a hidden stat wall or miniboss")
	check(CompilationTerminalScript.pressure_color(0.15, 0.0).b > CompilationTerminalScript.pressure_color(0.15, 0.0).r,
		"Early compilation pressure reads cyan")
	check(CompilationTerminalScript.pressure_color(0.7, 0.0).r > CompilationTerminalScript.pressure_color(0.7, 0.0).b,
		"Late compilation pressure reads amber")
	check(CompilationTerminalScript.pressure_color(0.2, 0.8).r > 0.8,
		"Signal loss overrides progress with a red danger state")
	var late_contract := CompilationTerminalScript.scaled_encounter(CompilationTerminalScript.Difficulty.KERNEL_BREACH, 9, 18.0, 4)
	var cold_late_contract := CompilationTerminalScript.scaled_encounter(CompilationTerminalScript.Difficulty.KERNEL_BREACH, 9, 18.0, 0)
	check(late_contract.enemy_count >= 36 and late_contract.elite_count >= 4 and late_contract.miniboss,
		"Late high-power Kernel contract adds composition pressure")
	check(float(late_contract.hp_mult) < 1.75 and float(late_contract.damage_mult) < 1.6,
		"Adaptive terminal scaling remains bucketed instead of matching player power one-to-one")
	check(late_contract.enemy_count > cold_late_contract.enemy_count and late_contract.elite_count > cold_late_contract.elite_count,
		"Compiler heat adds visible composition pressure to future contracts")
	var contract_options := CompilationTerminalScript.build_contract_options(5, 10.0, 4)
	check(contract_options.size() == 3, "Approaching a terminal exposes all three contracts")
	check(contract_options[0].heat_gain == 1 and contract_options[2].heat_gain == 3,
		"Contract cards disclose their different Heat stakes")
	var contract_picker := TerminalContractPickerScript.new()
	add_child(contract_picker)
	contract_picker.setup(contract_options)
	check(find_buttons(contract_picker).size() == 3, "Contract picker has exactly three touch targets")
	contract_picker.queue_free()
	await get_tree().process_frame
	var choice_terminal := CompilationTerminalScript.new()
	add_child(choice_terminal)
	choice_terminal.contract_options = contract_options
	var contract_requests := [0]
	choice_terminal.contract_requested.connect(func(_options: Array[Dictionary]): contract_requests[0] += 1)
	choice_terminal.request_contract()
	choice_terminal.request_contract()
	check(contract_requests[0] == 1, "Standing near a terminal opens the contract choice only once")
	check(choice_terminal.select_contract(CompilationTerminalScript.Difficulty.OVERCLOCK),
		"Choosing a contract starts its encounter")
	check(choice_terminal.difficulty == CompilationTerminalScript.Difficulty.OVERCLOCK
		and choice_terminal.wave_size == contract_options[1].enemy_count,
		"Selected contract controls the actual wave")
	choice_terminal.queue_free()
	await get_tree().process_frame
	var maxed_skills: Array[SkillInstance] = []
	for skill_id: String in EvolutionData.BY_SKILL:
		var maxed := SkillInstance.new(load("res://resources/skills/%s.tres" % skill_id))
		maxed.set_evolution(EvolutionData.get_for_skill(skill_id).id, 3)
		maxed_skills.append(maxed)
	var fallback := EvolutionData.roll_offers(maxed_skills, 2, rng)
	check(fallback.size() == 3 and fallback.all(func(offer): return offer.type == "kernel_fork"),
		"Max-tier skills receive rule-changing Kernel Fork offers")
	check(fallback.all(func(offer): return MutationData.is_terminal(offer.mutation)),
		"Every Kernel Fork comes from the capped terminal mutation pool")
	var fork_picker := CompilationPicker.new()
	add_child(fork_picker)
	fork_picker.setup(maxed_skills, CompilationTerminalScript.Difficulty.KERNEL_BREACH, rng)
	var fork_buttons := find_buttons(fork_picker)
	var fork_skill_index := int(fallback[0].get("skill_index", 0))
	var fork_count_before := maxed_skills[fork_skill_index].mutations.size()
	fork_buttons[0].pressed.emit()
	check(maxed_skills.any(func(skill: SkillInstance): return skill.mutations.size() > fork_count_before),
		"Choosing a Kernel Fork permanently mutates one max-tier skill")
	await get_tree().process_frame

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
	var scaled_spawned := spawner.spawn_compilation_wave(Vector2(100, 100), {
		"enemy_count": 1, "elite_count": 0, "miniboss": false,
		"hp_mult": 0.5, "damage_mult": 0.5})
	var scaled_enemy: EnemyBase = spawner.get_children().filter(
		func(node: Node): return node is EnemyBase and node.global_position.distance_to(Vector2(310, 100)) < 5.0
	).front() if scaled_spawned == 1 else null
	check(scaled_enemy != null and scaled_enemy.max_hp <= 3.1 and scaled_enemy.contact_damage <= 1.6,
		"Terminal-only scaling changes its enemies without changing the normal stage curve")
	spawner.clear_transients()
	spawner.queue_free()
	target.queue_free()
	await get_tree().process_frame

	var fireball := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	var offers := MutationData.roll_terminal_mutations(3, [], [fireball])
	check(offers.size() == 3, "Terminal offers three compatible mutations")
	for mutation: Dictionary in offers:
		check(MutationData.can_apply(mutation, fireball), "Every terminal mutation fits an owned skill")
		var stats: Dictionary = mutation.get("stats", {})
		var has_tradeoff := float(stats.get("damage_mult", 1.0)) < 1.0 \
			or float(stats.get("area_mult", 1.0)) < 1.0 \
			or float(stats.get("range_mult", 1.0)) < 1.0 \
			or float(stats.get("speed_mult", 1.0)) < 1.0 \
			or float(stats.get("cooldown_mult", 1.0)) > 1.0
		check(has_tradeoff, "Every Kernel Fork carries a visible mechanical tradeoff")

	var picker := CompilationPicker.new()
	add_child(picker)
	picker.setup([fireball])
	var buttons := find_buttons(picker)
	check(buttons.size() == 3, "Successful terminal offers exactly three rewards and no skip button")
	var tier_before := fireball.evolution_tier
	buttons[0].pressed.emit()
	check(fireball.evolution_tier > tier_before,
		"Choosing a terminal reward installs a persistent skill evolution")
	await get_tree().process_frame

	RunTelemetry.log_directory = "res://.godot/terminal_cleanup_telemetry"
	RunTelemetry.begin({"test": "terminal_cleanup"}, true)
	var interrupted_picker := CompilationPicker.new()
	add_child(interrupted_picker)
	interrupted_picker.setup([fireball], CompilationTerminalScript.Difficulty.KERNEL_BREACH, rng)
	Engine.time_scale = 0.08
	interrupted_picker.queue_free()
	arena._restore_combat_time()
	await get_tree().process_frame
	var cancel_events: Array = RunTelemetry.data.events.filter(func(event): return event.type == "decision_canceled")
	check(Engine.time_scale == 1.0 and cancel_events.size() == 1,
		"Stage cleanup restores time and records one interrupted terminal result")
	RunTelemetry.finish("test_complete", [])

	if failures.is_empty():
		print("PASS: compilation terminal risk, permanence and mutation rewards")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
