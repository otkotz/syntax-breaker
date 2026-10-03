extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	RunManager.start_run()
	RunManager.advance_stage()
	var stage := StageData.new()
	stage.depth = 1
	stage.type = StageData.Type.COMBAT
	RunManager.current_stage_data = stage
	var skill := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	var skills: Array[SkillInstance] = [skill]
	var arena := preload("res://scenes/stages/arena.tscn").instantiate() as Arena
	add_child(arena)
	arena.start_stage(1, skills, stage)
	arena.set_process(false)
	arena.spawner.set_process(false)
	var test_enemy := AttributionEnemy.new()
	add_child(test_enemy)
	test_enemy.take_damage(50.0, false, skill.base)
	test_enemy.take_damage(50.0, false, skill.base)
	check(RunManager.run_stats.direct_damage_by_skill.get("fireball", 0.0) == 5.0, "Damage excludes overkill and hits on dead targets")
	check(RunManager.run_stats.direct_kills_by_skill.get("fireball", 0) == 1, "Direct kill credited once")
	test_enemy.queue_free()
	var hud := arena.hud as HUD
	for id: String in StageData.MODIFIER_DATA:
		stage.modifiers.append(id)
	hud.update_wave(17.2, 0.5, 3)
	await get_tree().process_frame
	check(hud._wave_label.text == "18s | 50% | 3 enemies", "Wave metrics stay on one line")
	check(is_equal_approx(hud._wave_progress.value, 0.5), "Wave progress has a visual meter")
	check(hud._wave_progress.position.y + hud._wave_progress.size.y < hud._modifier_row.position.y, "Wave meter does not overlap modifier touch targets (meter=%s, row=%s)" % [hud._wave_progress.get_rect(), hud._modifier_row.get_rect()])
	check(hud._wave_progress.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Wave meter does not consume movement input")
	check(hud._modifier_row.get_child_count() == 9, "All nine modifiers have compact badges")
	var first_badge := hud._modifier_row.get_child(0) as Button
	var last_badge := hud._modifier_row.get_child(8) as Button
	check(last_badge.position.x + last_badge.size.x <= 720.0, "All modifier badges fit HUD width")
	check(first_badge.size.y >= 48.0, "Modifier badges have touch targets")
	check(hud._modifier_row.position.y + first_badge.size.y < hud._boss_bar.position.y, "Badges do not overlap boss bar")
	first_badge.pressed.emit()
	check(hud._modifier_details.text == first_badge.tooltip_text, "Tap shows full modifier label and rule")
	check(not get_tree().paused, "Reading a modifier does not pause combat")
	var badge_id := first_badge.get_instance_id()
	stage.modifiers.append(stage.modifiers[0])
	stage.modifiers.append("unknown_legacy_modifier")
	hud.update_wave(16.0, 0.51, 3)
	check(hud._modifier_row.get_child(0).get_instance_id() == badge_id, "Wave updates reuse modifier buttons")
	check(hud._modifier_row.get_child_count() == 9, "Duplicate and unknown legacy modifiers do not overflow the row")
	check(not hud._modifier_details.text.is_empty(), "Wave updates preserve description")
	hud._process(5.1)
	check(hud._modifier_details.text.is_empty(), "Modifier description expires")
	first_badge.pressed.emit()
	stage.modifiers.clear()
	hud.update_wave(15.0, 0.52, 3)
	check(hud._modifier_row.get_child_count() == 0 and hud._modifier_details.text.is_empty(), "Changing modifiers clears badges and stale description")
	GameBus.boss_phase_changed.emit("PHASE II: TEST RULE")
	check(hud._boss_phase_label.text == "PHASE II: TEST RULE", "Phase change has separate HUD warning")
	hud._process(4.1)
	check(hud._boss_phase_label.text.is_empty(), "Phase warning expires")
	GameBus.keystone_triggered.emit("Sharpened Edge")
	check(hud._keystone_label.text == "SHARPENED EDGE", "Keystone activation shown")
	GameBus.keystone_triggered.emit("Arcane Tempo")
	check(hud._keystone_label.text == "SHARPENED EDGE", "Keystone messages rate limited")
	hud._process(1.6)
	check(hud._keystone_label.text.is_empty(), "Keystone message expires")
	GameBus.synergy_triggered.emit("Overload")
	check(hud._synergy_label.text == "OVERLOAD", "Synergy shown")
	GameBus.synergy_triggered.emit("Shatter")
	check(hud._synergy_label.text == "OVERLOAD", "Synergy notice rate limited")
	var boss := preload("res://scenes/enemies/mini_boss.tscn").instantiate() as MiniBoss
	arena.add_child(boss)
	boss.set_as_boss()
	hud._process(0.0)
	check(hud._boss_bar.visible and hud._boss_bar.max_value == boss.max_hp, "Boss bar follows living boss")
	boss.current_hp = 0.0
	hud._process(0.0)
	check(not hud._boss_bar.visible, "Boss bar hides on death")
	arena.spawner._stage_timer = arena.spawner._stage_duration * 0.64
	arena._process(0.0)
	check(get_tree().paused, "Checkpoint pauses combat")
	var picker: CompilationPicker
	for child: Node in arena.get_node("CanvasLayer").get_children():
		if child is CompilationPicker:
			picker = child
	check(picker != null, "Checkpoint creates selection UI")
	if picker:
		var box := picker.get_child(1).get_child(0)
		(box.get_child(1) as Button).pressed.emit()
		check(not get_tree().paused, "Selecting an override resumes combat")
		check(skill.stage_overrides.size() == 1, "Override applied once")
		(box.get_child(1) as Button).pressed.emit()
		check(skill.stage_overrides.size() == 1, "Double click cannot duplicate override")
	arena.spawner._stage_timer = arena.spawner._stage_duration * 0.29
	arena._process(0.0)
	check(get_tree().paused and arena._checkpoint_index == 2, "Second checkpoint")
	for child: Node in arena.get_node("CanvasLayer").get_children():
		if child is CompilationPicker and not child.is_queued_for_deletion():
			child._finish()
	check(not get_tree().paused, "Skipping resumes combat")
	arena._on_all_waves_cleared()
	check(skill.stage_overrides.is_empty(), "Stage end clears temporary effects")
	check(is_equal_approx(skill.computed_stats.damage, skill.base.base_damage), "Base damage restored")
	arena.queue_free()
	await get_tree().process_frame
	print(JSON.stringify({"failures": failures, "checkpoints": 2}))
	get_tree().quit(0 if failures.is_empty() else 1)

class AttributionEnemy extends EnemyBase:
	func _ready() -> void:
		current_hp = 5.0
	func _flash_hit() -> void:
		pass
	func _spawn_damage_number(_amount: float, _crit: bool = false) -> void:
		pass
	func _die() -> void:
		pass
