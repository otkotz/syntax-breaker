extends Node

class TestPlayer extends Player:
	func _setup_animated_sprite() -> void:
		_anim_sprite = AnimatedSprite2D.new()
		add_child(_anim_sprite)
	func _spawn_damage_number(_amount: float) -> void:
		pass

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	RunManager.save_path = "res://.godot/telemetry_run_test.json"
	MetaProgression.save_path = "res://.godot/telemetry_meta_test.json"
	RunTelemetry.log_directory = "res://.godot/telemetry_test_" + Crypto.new().generate_random_bytes(6).hex_encode()
	for sample in 50:
		RunManager.start_run()
		RunTelemetry.begin({"fixture": sample}, true)
		check(RunTelemetry.data.source == "synthetic", "Fixtures must never count as human playtests")
		var run_id: String = RunTelemetry.data.run_id
		var starter := RunTelemetry.open_decision("starter", [{"id": "fireball"}])
		RunTelemetry.choose(starter, {"id": "fireball"})
		var initial_map := RunTelemetry.open_decision("map", [])
		RunTelemetry.choose(initial_map, {"index": 0})
		check(RunTelemetry.data.first_decision_seconds == null, "Pre-combat map cannot make first combat decision artificially zero")
		var stage := StageData.new()
		stage.depth = 1
		stage.type = StageData.Type.COMBAT
		RunTelemetry.begin_stage(stage)
		RunTelemetry.enemy_spawned("charger")
		RunTelemetry.tick_combat(17.5, false)
		var compilation := RunTelemetry.open_decision("compilation", [{"id": "Breach", "skill": "fireball"}])
		get_tree().paused = true
		RunTelemetry._process(5.0)
		RunTelemetry.choose(compilation, {"id": "Breach", "skill": "fireball"})
		RunTelemetry.choose(compilation, {"id": "duplicate"})
		get_tree().paused = false
		check(RunTelemetry.data.first_decision_seconds == 17.5 and RunTelemetry.data.combat_seconds == 17.5, "First combat decision excludes starter and paused thinking")
		RunTelemetry.tick_combat(2.0, true)
		check(RunTelemetry.data.spawn_wait_seconds == 2.0 and RunTelemetry.data.stages[0].spawns.charger == 1, "Spawn wait and role counts persist in stage")
		RunManager.save_run([])
		RunManager.restore_from_save(RunManager.load_run())
		check(RunTelemetry.data.run_id == run_id and RunTelemetry.data.events[-1].type == "run_resumed", "Resume retains run ID and earlier samples")
		RunTelemetry.end_stage("cleared", {"normal_spawned": 1})
		check(RunTelemetry.finish("victory", [{"skill_id": "fireball"}]), "Atomic JSON write works, including overwrite after checkpoints")
		check(not RunTelemetry.finish("victory", []), "Finish cannot count run twice")
		var path := RunTelemetry.log_directory.path_join(run_id + ".json")
		var file := FileAccess.open(path, FileAccess.READ)
		var recorded: Dictionary = JSON.parse_string(file.get_as_text())
		check(recorded.status == "victory" and recorded.final_build[0].skill_id == "fireball", "Finished log is valid, complete JSON")
		check(not FileAccess.file_exists(path + ".tmp"), "Atomic write leaves no temporary log")
		var selections := 0
		for event in recorded.events:
			if event.type == "decision_chosen":
				selections += 1
		check(selections == 3, "Double click cannot create duplicate choice")
	RunManager.start_run()
	RunTelemetry.begin({"fixture": "damage"}, true)
	var player := TestPlayer.new()
	add_child(player)
	player.set_physics_process(false)
	player.take_damage(10.0, "basic_ranged:projectile")
	player.take_damage(10.0, "ignored_iframe")
	check(RunManager.run_stats.last_damage_source == "basic_ranged:projectile", "I-frame rejected hits cannot replace actual source")
	RunManager.add_consumable(load("res://resources/consumables/auto_revive.tres"))
	var manager := ConsumableManager.new()
	add_child(manager)
	manager.setup(RunManager.get_consumable_data())
	player._damage_cooldown = 0.0
	Player.hurt(player, 999.0, "elite:nova")
	check(player.current_hp == 30.0 and not RunManager.run_stats.has("death_source"), "Revive does not record false death")
	check(RunManager.run_stats.healing_received == 30.0, "Revive counts recovered HP for summary and no-healing challenge")
	player._damage_cooldown = 0.0
	Player.hurt(player, 999.0, "storm_boss:beam")
	check(RunManager.run_stats.death_source == "storm_boss:beam", "Lethal damage records precise attack source")
	RunTelemetry.finish("death", [])
	player.queue_free()
	manager.queue_free()
	RunTelemetry.begin({"fixture": "bounded_events"}, true)
	for i in RunTelemetry.MAX_EVENTS + 10:
		RunTelemetry.record("fixture", {"sample": i})
	check(RunTelemetry.data.events.size() == RunTelemetry.MAX_EVENTS and RunTelemetry.data.dropped_events > 0, "Telemetry memory is bounded and truncation explicit")
	RunTelemetry.finish("abandoned", [])
	RunTelemetry.restore({})
	check(not RunTelemetry.active and RunTelemetry.data.is_empty(), "Legacy saves cannot inherit a previous recording")
	RunTelemetry.begin({"fixture": "invalid_restore"}, true)
	RunTelemetry.restore({"data": {"schema_version": 999, "status": "in_progress"}})
	check(not RunTelemetry.active and RunTelemetry._open_decisions.is_empty(), "Invalid schema cannot remain active")
	var reporter := preload("res://tests/telemetry_report.gd").new()
	var excluded: Dictionary = reporter.aggregate(RunTelemetry.log_directory, false)
	check(excluded.completed_runs == 0 and excluded.synthetic_excluded == 53, "Report excludes all synthetic fixtures by default")
	var included: Dictionary = reporter.aggregate(RunTelemetry.log_directory, true)
	check(included.completed_runs == 51 and included.completed_playtests == 0, "Explicit synthetic analysis cannot satisfy playtest sample")
	check(included.metrics.first_decision_seconds.median == 17.5 and included.metrics.spawn_wait_seconds.median == 2.0, "Report preserves measured cadence and wait values")
	check(included.deaths_by_source.get("storm_boss:beam", 0) == 1, "Report attributes the recorded death")
	check(included.choices["compilation/option/Breach"].offered == 50 and included.choices["compilation/option/Breach"].picked == 50, "Pick rate denominator is actual availability")
	reporter.free()
	var manifest := FileAccess.open("res://.godot/telemetry_test_result.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"directory": RunTelemetry.log_directory, "synthetic_runs": 50, "failures": failures}))
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: 50 synthetic telemetry fixtures, atomic writes, resume, choice timing, sources, revive and bounded events")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
