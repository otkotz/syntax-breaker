extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	MetaProgression.save_path = "res://.godot/ascension_rules_meta.json"
	RunManager.save_path = "res://.godot/ascension_rules_run.json"
	MetaProgression.highest_ascension_unlocked["burning_grounds"] = 20
	RunTelemetry.enabled = false
	var region := load("res://resources/regions/burning_grounds.tres") as RegionResource
	for level in [0, 4, 5, 9, 10, 14, 15, 20]:
		RunManager.start_run("burning_grounds", level)
		var mods := StageGenerator.get_ascension_modifiers(2)
		check(mods.has("elite_patrol") == (level >= 5), "Elite threshold at 5")
		check(mods.has("denial_reinforcement") == (level >= 10), "Caster threshold at 10")
		check(mods.has("shield_reinforcement") == (level >= 15), "Shield threshold at 15")
		check(StageGenerator.get_ascension_modifiers(1).is_empty(), "First stage is exempt")
		var tree := StageGenerator.generate_tree(region)
		for row in tree.rows:
			for node: Dictionary in row:
				var eligible: bool = node.depth >= 2 and node.type in [StageData.Type.COMBAT, StageData.Type.ELITE]
				for modifier in mods:
					check(node.modifiers.has(modifier) == eligible, "Map discloses rule only on combat/elite nodes")
		var restored := StageTree.deserialize(tree.serialize(), region)
		check(restored.rows == tree.rows, "Serialized map preserves qualitative modifiers")
	RunManager.start_run("burning_grounds", 15)
	var stage := StageData.new()
	stage.type = StageData.Type.COMBAT
	stage.depth = 2
	stage.modifiers = StageGenerator.get_ascension_modifiers(2)
	check(stage.get_scripted_roles(1).is_empty() and stage.get_scripted_roles(2) == ["denial_caster"], "Caster arrives on pulse 2, not first spawn")
	check(stage.get_scripted_roles(3) == ["elite"] and stage.get_scripted_roles(4) == ["shield_support"], "Elite and shield have separate pulses")
	check(stage.get_scripted_roles(5).is_empty(), "Opening rules do not repeat every pulse")
	check(stage.get_modifier_text().contains("Elite Patrol"), "Rule is readable through HUD/map modifier text")
	var arena := preload("res://scenes/stages/arena.tscn").instantiate() as Arena
	add_child(arena)
	arena.process_mode = Node.PROCESS_MODE_DISABLED
	var spawner := arena.spawner
	spawner.setup(arena.player, Rect2(0, 0, 1000, 1750), stage)
	var budget_before := spawner._spawned_count
	spawner._spawn_scripted_roles(2)
	check(spawner.get_active_role_count("denial_caster") == 1, "Actual caster reinforcement spawns")
	spawner._spawn_scripted_roles(2)
	check(spawner.get_active_role_count("denial_caster") == 1, "Reentrant request does not duplicate reinforcement")
	spawner._spawn_scripted_roles(3)
	check(spawner._elite_spawn_count == 1, "Actual extra elite spawns with affix")
	spawner._spawn_scripted_roles(4)
	check(spawner.get_active_role_count("shield_support") == 1, "Actual shield reinforcement spawns")
	check(spawner._spawned_count == budget_before, "Reinforcements do not silently replace ordinary wave budget")
	spawner.force_complete()
	await get_tree().process_frame
	spawner.setup(arena.player, Rect2(0, 0, 1000, 1750), stage)
	for pulse in 4:
		spawner._spawn_pulse()
	check(spawner.get_active_role_count("denial_caster") == 1 and spawner.get_active_role_count("shield_support") == 1 and spawner._elite_spawn_count == 1, "Ordinary pulse scheduler invokes all three scripted openings")
	spawner.force_complete()
	await get_tree().process_frame
	spawner.setup(arena.player, Rect2(0, 0, 1000, 1750), stage)
	spawner._spawn_enemy_at(Vector2(50, 50), "shield_support", false)
	spawner._spawn_scripted_roles(4)
	check(spawner.get_active_role_count("shield_support") == 1, "Existing shield cap is never exceeded")
	spawner.force_complete()
	await get_tree().process_frame
	stage.type = StageData.Type.BOSS
	spawner.setup(arena.player, Rect2(0, 0, 1000, 1750), stage)
	spawner._spawn_scripted_roles(2)
	check(spawner._enemies_alive == 0, "Boss stage cannot acquire opening reinforcements from stale modifiers")
	arena.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: Ascension 5/10/15 rules, map/save visibility, separate pulses, actual spawns, idempotence, role caps and boss exclusion")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
