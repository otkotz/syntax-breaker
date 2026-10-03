extends Node2D

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

func dummy(hp: float = 100.0) -> DamageDummy:
	var enemy := DamageDummy.new()
	enemy.max_hp = hp
	add_child(enemy)
	enemy.set_process(false)
	enemy.set_physics_process(false)
	return enemy

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	RunManager.save_path = "res://.godot/damage_run_test.json"
	MetaProgression.save_path = "res://.godot/damage_meta_test.json"
	RunManager.start_run()
	var fire := load("res://resources/skills/fireball.tres") as SkillResource
	var lightning := load("res://resources/skills/lightning_bolt.tres") as SkillResource
	var enemy := dummy()
	enemy.take_damage(25.0, false, fire)
	enemy.apply_dot("burn", 10.0, 3.0, 0.5, fire)
	enemy._process(0.5)
	enemy._process(0.5)
	check(enemy.current_hp == 55.0 and RunManager.run_stats.damage_by_skill.fireball == 45.0, "Direct and DoT contribute to same skill total")
	check(RunManager.run_stats.direct_damage_by_skill.fireball == 25.0 and RunManager.run_stats.dot_damage_by_skill.fireball == 20.0, "Damage channels remain separate")
	enemy.apply_dot("poison", 2.0, 3.0, 0.5, fire)
	enemy.apply_dot("poison", 3.0, 3.0, 0.5, lightning)
	enemy._dots.erase("burn")
	enemy._process(0.5)
	check(RunManager.run_stats.dot_damage_by_skill.lightning_bolt == 3.0, "Replacing same DoT transfers source to replacement, no double tick")
	var lethal := dummy(8.0)
	var killers: Array[Resource] = []
	GameBus.enemy_killed.connect(func(killed: Node2D, skill: Resource):
		if killed == lethal:
			killers.append(skill)
	)
	lethal.apply_dot("poison", 99.0, 3.0, 0.5, lightning)
	lethal._process(0.5)
	lethal.take_damage(99.0, false, fire)
	check(RunManager.run_stats.dot_damage_by_skill.lightning_bolt == 11.0, "Lethal DoT caps damage to remaining HP")
	check(RunManager.run_stats.dot_kills_by_skill.lightning_bolt == 1 and RunManager.run_stats.kills_by_skill.lightning_bolt == 1, "DoT kill credited once to owning skill")
	check(killers.size() == 1 and killers[0] == lightning, "Kill bus receives actual DoT killer resource")
	lethal.reset()
	lethal.set_process(false)
	lethal.set_physics_process(false)
	check(lethal._dots.is_empty() and lethal._kill_source == null, "Pooling clears DoT and previous killer")
	var proc_target := dummy(12.0)
	SynergyTracker._trigger_shatter(proc_target, 10.0, fire)
	check(RunManager.run_stats.proc_damage_by_skill.fireball == 12.0 and RunManager.run_stats.proc_kills_by_skill.fireball == 1, "Synergy proc owns effective damage and kill")
	var ignite_target := dummy()
	ignite_target.apply_dot("poison", 2.0, 1.0, 0.5, lightning)
	TagInteractions.process_hit(ignite_target, 10.0, ["fire"], self, fire)
	check(RunManager.run_stats.proc_damage_by_skill.fireball == 18.0, "Ignite attributed to triggering skill")
	check(not ignite_target._dots.has("poison"), "Consumed DoT cannot deal later double-counted ticks")
	var support_target := dummy()
	var skill := SkillInstance.new(fire)
	PoisonOnHitBehavior.new().on_hit(skill, support_target, self)
	support_target._process(0.5)
	check(support_target._dots.poison.source == fire, "Support-applied DoT carries parent skill source")
	var unknown := dummy(5.0)
	unknown.take_damage(50.0)
	check(RunManager.run_stats.unattributed_damage == 5.0 and RunManager.run_stats.unattributed_kills == 1, "Unknown/consumable source is separate, not guessed")
	var skill_sum := 0.0
	for amount in RunManager.run_stats.damage_by_skill.values():
		skill_sum += float(amount)
	check(is_equal_approx(RunManager.run_stats.damage_dealt, skill_sum + 5.0), "Total damage conserves all attributed and other damage")
	var recorded := RunManager.run_stats.duplicate(true)
	RunManager.save_run([])
	RunManager.restore_from_save(RunManager.load_run())
	check(RunManager.run_stats == JSON.parse_string(JSON.stringify(recorded)), "Attribution dictionaries survive save/resume (JSON normalizes numeric types)")
	var resumed_stats := RunManager.run_stats
	RunManager.run_stats = {"direct_damage_by_skill": {"fireball": 10.0}, "direct_kills_by_skill": {"fireball": 1}}
	RunManager.record_combat_damage(fire, 3.0, false, "dot")
	check(RunManager.run_stats.damage_by_skill.fireball == 13.0 and RunManager.run_stats.damage_dealt == 13.0, "Old saves preserve earlier direct records in total")
	check(RunManager.run_stats.kills_by_skill.fireball == 1 and RunManager.run_stats.dot_damage_by_skill.fireball == 3.0, "Old-save attribution initializes missing dictionaries safely")
	RunManager.run_stats = resumed_stats

	var notices: Array[String] = []
	GameBus.keystone_triggered.connect(func(label: String): notices.append(label))
	RunManager.owned_passives = []
	for key: String in ["sharpened_edge", "arcane_tempo", "virulence", "detonation_expert", "deep_freeze"]:
		RunManager.owned_passives.append(load("res://resources/passives/%s.tres" % key))
	EngineTracker.clear()
	EngineTracker.on_crit()
	EngineTracker.on_crit()
	check(notices.count("Sharpened Edge") == 1, "Repeated engine activations throttled")
	EngineTracker.tick(2.1)
	EngineTracker.on_crit()
	check(notices.count("Sharpened Edge") == 2, "Engine notice re-arms after combat cooldown")
	EngineTracker.on_cast("fireball")
	EngineTracker.on_cast("fireball")
	check(not notices.has("Arcane Tempo"), "No tempo notice without changing skill")
	EngineTracker.on_cast("lightning_bolt")
	check(notices.has("Arcane Tempo"), "Alternating skills activates tempo notice")
	EngineTracker.get_detonation_mult(2)
	check(not notices.has("Detonation Expert"), "No detonation notice below threshold")
	EngineTracker.get_detonation_mult(3)
	check(notices.has("Detonation Expert"), "Detonation threshold activates notice")
	enemy.apply_slow(0.5, 3.0)
	EngineTracker.get_deep_freeze_mult(enemy)
	check(notices.has("Deep Freeze"), "Slow-dependent damage engine activates notice")
	enemy.apply_dot("burn", 1.0, 3.0, 0.5, fire)
	EngineTracker.get_virulence_mult(enemy)
	check(notices.has("Virulence"), "Multiple statuses activate poison engine notice")
	RunManager.owned_passives.clear()
	EngineTracker.clear()
	SynergyTracker.clear()

	var summary := preload("res://scenes/ui/run_summary.tscn").instantiate() as RunSummary
	add_child(summary)
	summary.set_anchors_preset(Control.PRESET_TOP_LEFT)
	summary.size = Vector2(1080, 720)
	summary.setup(false)
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll := summary.get_node("CenterContainer/VBox/StatsScroll") as ScrollContainer
	check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "Expanded summary scrolls on short viewport")
	check(summary.play_again_button.get_global_rect().end.y <= 720.0, "Return button remains inside short viewport")
	check(summary.stats_container.get_child_count() >= 16, "Summary includes skill breakdown and other damage")
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: direct, DoT, proc, kill and save attribution; keystone notices; summary scrolling")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
