extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	MetaProgression.save_path = "res://.godot/challenges_meta_test.json"
	RunManager.save_path = "res://.godot/challenges_run_test.json"
	RunTelemetry.enabled = false
	MetaProgression.completed_challenges = {}
	RunManager.start_run("burning_grounds")
	var fire := load("res://resources/skills/fireball.tres") as SkillResource
	var cold := load("res://resources/skills/frost_nova.tres") as SkillResource
	var lightning := load("res://resources/skills/lightning_bolt.tres") as SkillResource
	var physical := load("res://resources/skills/blade_spin.tres") as SkillResource
	check(ArchetypeChallenges.evaluate(true, RunManager.run_stats).is_empty(), "Empty run cannot earn challenges")
	RunManager.record_combat_damage(fire, 10.0, false, "direct")
	RunManager.record_combat_damage(cold, 10.0, false, "dot")
	var earned := ArchetypeChallenges.evaluate(true, RunManager.run_stats)
	check(earned.has("two_elements") and earned.has("no_healing"), "Two actual elemental sources and no healing qualify")
	check(ArchetypeChallenges.evaluate(false, RunManager.run_stats).is_empty(), "Death never completes victory challenge")
	RunManager.record_combat_damage(lightning, 0.0, false, "proc")
	check(ArchetypeChallenges.evaluate(true, RunManager.run_stats).has("two_elements"), "Rejected zero damage does not add third element")
	RunManager.save_run([])
	RunManager.restore_from_save(RunManager.load_run())
	check(ArchetypeChallenges.evaluate(true, RunManager.run_stats).has("two_elements"), "Whole-run evidence persists across save/resume")
	RunManager.record_combat_damage(lightning, 1.0, false, "proc")
	check(not ArchetypeChallenges.evaluate(true, RunManager.run_stats).has("two_elements"), "Third element remains disqualifying even if final build removes it")
	RunManager.start_run()
	RunManager.record_combat_damage(fire, 1.0, false, "direct")
	RunManager.record_combat_damage(cold, 1.0, false, "direct")
	RunManager.record_combat_damage(physical, 1.0, false, "direct")
	check(not ArchetypeChallenges.evaluate(true, RunManager.run_stats).has("two_elements"), "Physical damage disqualifies elemental-only challenge")
	RunManager.start_run()
	RunManager.record_combat_damage(fire, 1.0, false, "direct")
	RunManager.record_challenge_cast(true)
	check(ArchetypeChallenges.evaluate(true, RunManager.run_stats).has("mine_only"), "Mine casts with attributed damage qualify")
	RunManager.record_challenge_cast(false)
	check(not ArchetypeChallenges.evaluate(true, RunManager.run_stats).has("mine_only"), "Earlier direct/totem cast cannot be hidden by linking Mine at the end")
	RunManager.start_run()
	RunManager.record_combat_damage(fire, 1.0, false, "direct")
	RunManager.record_challenge_cast(true)
	RunManager.record_combat_damage(null, 1.0, false, "proc")
	check(not ArchetypeChallenges.evaluate(true, RunManager.run_stats).has("mine_only"), "Bomb/unattributed damage invalidates mine-only claim")
	RunManager.sync_health(50, 100)
	RunManager.heal_between_stages()
	check(not ArchetypeChallenges.evaluate(true, RunManager.run_stats).has("no_healing"), "Between-stage regeneration counts as healing")
	RunManager.run_stats.erase("challenge_tracking_version")
	check(ArchetypeChallenges.evaluate(true, RunManager.run_stats).is_empty(), "Legacy run cannot earn retrospective challenges")
	RunManager.start_run()
	var mine_skill := SkillInstance.new(fire)
	mine_skill.link_support(load("res://resources/supports/mine.tres"))
	var caster := SkillCaster.new()
	add_child(caster)
	caster.set_physics_process(false)
	caster.set_skills([mine_skill])
	check(caster._place_mine(mine_skill), "Real mine placement succeeds")
	check(RunManager.run_stats.mine_casts == 1 and RunManager.run_stats.non_mine_casts == 0, "Real placement updates mine cast evidence")
	var mine_target := Node2D.new()
	mine_target.add_to_group("enemies")
	mine_target.global_position = Vector2.RIGHT * 40.0
	add_child(mine_target)
	var fire_pool: ObjectPool = caster._pools.get(fire.scene_path)
	var placed_fire_mine: SkillMine = caster._active_mines.back()
	placed_fire_mine._on_body_entered(mine_target)
	check(fire_pool.active_count() == 1 and fire_pool.get_active()[0] is ProjectileBase,
		"Mine detonates through the linked projectile skill payload")
	for skill_resource: SkillResource in [cold, physical]:
		var supported_skill := SkillInstance.new(skill_resource)
		supported_skill.link_support(load("res://resources/supports/mine.tres"))
		var supported_caster := SkillCaster.new()
		add_child(supported_caster)
		supported_caster.set_physics_process(false)
		supported_caster.set_skills([supported_skill])
		check(supported_caster._place_mine(supported_skill), "%s mine placement succeeds" % skill_resource.name)
		var supported_pool: ObjectPool = supported_caster._pools.get(skill_resource.scene_path)
		var placed_mine: SkillMine = supported_caster._active_mines.back()
		placed_mine._on_body_entered(mine_target)
		var expected_payload := supported_pool.get_active()[0] if supported_pool.active_count() > 0 else null
		check((skill_resource.id == "frost_nova" and expected_payload is AoeSkillBase)
			or (skill_resource.id == "blade_spin" and expected_payload is Rollback),
			"Mine detonates through the linked %s payload" % skill_resource.name)
		supported_caster.queue_free()
	mine_target.queue_free()
	caster._spawn_skill(mine_skill, Vector2.RIGHT, null)
	check(RunManager.run_stats.non_mine_casts == 1, "Direct/triggered spawn records non-mine cast even for a mine-linked skill")
	for mine: SkillMine in caster._active_mines.duplicate():
		mine.queue_free()
	caster.queue_free()
	await get_tree().process_frame
	RunManager.start_run("burning_grounds")
	RunManager.record_combat_damage(fire, 1.0, false, "direct")
	var before_bonuses := RunManager.shop_bonuses.duplicate(true)
	var newly := MetaProgression.record_challenges(true, RunManager.run_stats, "burning_grounds", 0)
	check(newly == ["no_healing"], "First completion awards achievement")
	check(MetaProgression.record_challenges(true, RunManager.run_stats, "burning_grounds", 0).is_empty(), "Completion is idempotent")
	MetaProgression.completed_challenges.clear()
	MetaProgression.load_progress()
	check(MetaProgression.completed_challenges.has("no_healing"), "Achievements persist in selected profile path")
	check(RunManager.shop_bonuses == before_bonuses, "Achievement adds no permanent power")
	RunManager.run_stats["new_challenges"] = newly
	var summary := preload("res://scenes/ui/run_summary.tscn").instantiate() as RunSummary
	add_child(summary)
	summary.setup(true, [])
	var summary_has_challenge := false
	for row in summary.stats_container.get_children():
		if row.get_child(0).text == "Challenge completed":
			summary_has_challenge = row.get_child(1).text == "Unpatched"
	check(summary_has_challenge, "Victory summary names newly earned achievement")
	summary.queue_free()
	var codex := preload("res://scenes/ui/codex.tscn").instantiate() as CodexUI
	add_child(codex)
	codex._select_category("challenges")
	await get_tree().process_frame
	check(codex.entry_list.get_child_count() == 3, "All three challenge goals are visible in Codex")
	check(codex.count_label.text.contains("1 / 3"), "Codex distinguishes completed and pending challenges")
	codex.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: archetype challenges, whole-run evidence, save/resume, persistence, idempotence, no power rewards and Codex goals")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
