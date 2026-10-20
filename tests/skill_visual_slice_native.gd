extends Node

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _ready() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	_check_scene_identities()
	_check_support_modifiers()
	_check_rollback_language()
	await get_tree().process_frame
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: three-skill silhouettes, bounded support punctuation and Rollback visual phases")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)


func _check_scene_identities() -> void:
	var scene_paths := [
		"res://scenes/skills/rollback.tscn",
		"res://scenes/skills/fireball.tscn",
		"res://scenes/skills/static_field.tscn",
	]
	var shapes: Array[StringName] = []
	for path in scene_paths:
		var skill = load(path).instantiate()
		add_child(skill)
		check(skill.has_node("VisualIdentity"), "Skill scene owns a visual identity renderer: " + path)
		if skill.has_node("VisualIdentity"):
			var visual = skill.get_node("VisualIdentity")
			check(visual.profile != null, "Skill scene binds a production profile: " + path)
			if visual.profile:
				shapes.append(visual.profile.core_shape)
		skill.queue_free()
	check(shapes.size() == 3 and shapes.duplicate().all(func(shape): return shapes.count(shape) == 1),
		"Rollback, Fireball and Static Field remain distinct without color")


func _check_support_modifiers() -> void:
	var script_path := "res://scripts/effects/support_visual_modifier.gd"
	check(ResourceLoader.exists(script_path), "Shared support visual modifier exists")
	if not ResourceLoader.exists(script_path):
		return
	var modifier = load(script_path)
	var expected := {
		"chain": &"network_nodes",
		"returning": &"reverse_arrow",
		"spell_echo": &"offset_outline",
		"mine": &"closing_diamond",
		"totem": &"transmitter_brackets",
		"rubber_duck_debugging": &"duck_marker",
	}
	for support_id: String in expected:
		var definition: Dictionary = modifier.definition_for(support_id)
		check(definition.get("signature", &"") == expected[support_id], "Support has recognizable punctuation: " + support_id)
		check(float(definition.get("duration", 0.0)) >= 0.12 and float(definition.get("duration", 1.0)) <= 0.25,
			"Support punctuation stays within 120–250 ms: " + support_id)
	var renderer_path := "res://scripts/effects/skill_visual_renderer.gd"
	check(ResourceLoader.exists(renderer_path), "Skill visual renderer exists")
	if not ResourceLoader.exists(renderer_path):
		return
	var renderer = load(renderer_path).new()
	add_child(renderer)
	var profile = load("res://resources/skill_visuals/rollback.tres") as SkillVisualProfile
	var supports: Array[String] = ["chain", "returning", "spell_echo"]
	renderer.configure(profile, supports, 3)
	check(renderer.primary_support_id == "chain", "Only one primary support modifier is composed")
	check(renderer.support_signature == &"network_nodes", "Renderer uses the shared support glyph")
	check(renderer.evolution_signature == &"tier_3_hero", "Tier III exposes one bounded hero signature")
	check(renderer.hero_duration <= 0.12, "Tier III rewind punctuation is capped at 120 ms")
	renderer.queue_free()


func _check_rollback_language() -> void:
	var skill := load("res://resources/skills/blade_spin.tres") as SkillResource
	check(skill.name == "Rollback", "Legacy save id exposes only the Rollback name")
	check(skill.icon.resource_path.ends_with("rollback-v1.png"), "Legacy save id uses Rollback artwork")
	check(skill.scene_path.ends_with("rollback.tscn"), "Legacy save id no longer loads the orbit scene")
	var rollback = load(skill.scene_path).instantiate()
	add_child(rollback)
	check(rollback.has_method("visual_phase"), "Rollback exposes its visual state language")
	if not rollback.has_method("visual_phase"):
		rollback.queue_free()
		return
	check(rollback.visual_phase() == &"outbound_continuous_cyan", "Outbound Rollback uses a continuous cyan write trail")
	rollback.state = Rollback.State.TURNING
	check(rollback.visual_phase() == &"turn_bracket", "Turn point flashes a bracket")
	rollback.state = Rollback.State.RETURNING
	check(rollback.visual_phase() == &"return_dashed_magenta", "Return uses a reversed dashed magenta trail")
	rollback.state = Rollback.State.CAUGHT
	check(rollback.visual_phase() == &"catch_close_glyph", "Catch closes the undo glyph")
	check(rollback.get_node_or_null("OrbitSprite") == null, "Rollback contains no orbiting-knife presentation")
	rollback.queue_free()
