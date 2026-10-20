extends Node

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _ready() -> void:
	_check_profiles()
	_check_budget()
	_check_damage_aggregation()
	_check_telegraph_grammar()
	if failures.is_empty():
		print("PASS: skill profiles, adaptive visual caps, damage aggregation and hostile telegraph priority")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)


func _check_profiles() -> void:
	var paths := [
		"res://resources/skill_visuals/rollback.tres",
		"res://resources/skill_visuals/fireball.tres",
		"res://resources/skill_visuals/static_field.tres",
	]
	var shapes: Array[StringName] = []
	for path in paths:
		check(ResourceLoader.exists(path), "Visual profile exists: " + path)
		if not ResourceLoader.exists(path):
			continue
		var profile = load(path)
		check(profile != null, "Visual profile loads: " + path)
		if profile == null:
			continue
		check(not profile.skill_id.is_empty(), "Profile has skill id: " + path)
		check(not profile.core_shape.is_empty(), "Profile has shape identity: " + path)
		check(not profile.cast_signature.is_empty(), "Profile has cast signature: " + path)
		check(not profile.hit_signature.is_empty(), "Profile has hit signature: " + path)
		check(not profile.residue_signature.is_empty(), "Profile has travel/field residue: " + path)
		check(profile.max_screen_coverage > 0.0 and profile.max_screen_coverage <= 0.20,
			"Friendly profile caps opaque screen coverage: " + path)
		shapes.append(profile.core_shape)
	check(shapes.size() == 3 and shapes.duplicate().all(func(shape): return shapes.count(shape) == 1),
		"Rollback, Fireball and Static Field use distinct non-color core shapes")


func _check_budget() -> void:
	var path := "res://scripts/effects/combat_visual_budget.gd"
	check(ResourceLoader.exists(path), "CombatVisualBudget implementation exists")
	if not ResourceLoader.exists(path):
		return
	var budget = load(path)
	budget.reset()
	for i in 8:
		check(budget.request(&"hit_flash", 1, 100 + i), "First eight hit flashes are admitted")
	check(not budget.request(&"hit_flash", 1, 999), "Ninth hit flash is dropped")
	for i in 8:
		check(budget.request(&"death_signature", 1, 200 + i), "First eight death signatures are admitted")
	check(not budget.request(&"death_signature", 1, 998), "Ninth death signature is dropped")
	for i in 24:
		check(budget.request(&"full_trail", 1, 300 + i), "First twenty-four full trails are admitted")
	check(not budget.request(&"full_trail", 1, 997), "Twenty-fifth full trail is dropped")
	check(budget.request(&"hero_moment", 2, 401), "First hero moment is admitted")
	check(budget.request(&"hero_moment", 2, 402), "Second hero moment is admitted")
	check(not budget.request(&"hero_moment", 2, 403), "Third hero moment is dropped")
	check(budget.request(&"hostile_warning", 100, 500), "Hostile warnings bypass friendly limits")
	check(budget.request(&"hostile_warning", 100, 501), "Multiple hostile warnings remain admitted")
	budget.reset()
	check(budget.request(&"hit_flash", 1, 42), "Origin is admitted once")
	check(budget.request(&"hit_flash", 1, 42), "Repeated origin merges instead of consuming another slot")
	check(budget.active_count(&"hit_flash") == 1, "Merged origin occupies one budget slot")
	budget.release(&"hit_flash", 42)
	check(budget.active_count(&"hit_flash") == 0, "Release returns the visual slot")


func _check_damage_aggregation() -> void:
	var path := "res://scripts/effects/combat_visual_budget.gd"
	if not ResourceLoader.exists(path):
		return
	var budget = load(path)
	budget.reset()
	var first: Dictionary = budget.aggregate_damage(7, &"fireball", 10.0, 1.0)
	var merged: Dictionary = budget.aggregate_damage(7, &"fireball", 5.0, 1.20)
	var later: Dictionary = budget.aggregate_damage(7, &"fireball", 3.0, 1.26)
	var other_source: Dictionary = budget.aggregate_damage(7, &"rollback", 4.0, 1.20)
	check(not first.merged and first.amount == 10.0, "First damage number starts an aggregation window")
	check(merged.merged and merged.amount == 15.0, "Same target/source merges within 0.25 seconds")
	check(not later.merged and later.amount == 3.0, "Damage after 0.25 seconds starts a new number")
	check(not other_source.merged, "Different sources do not merge")


func _check_telegraph_grammar() -> void:
	var hazard_script = load("res://scripts/enemies/boss_hazard.gd")
	var telegraph_z = hazard_script.get("TELEGRAPH_Z")
	check(telegraph_z is int and telegraph_z >= 20, "Hostile ground telegraphs render above friendly effects")
	check(hazard_script.get("WARNING_DASHED") == true, "Warning phase uses a dashed contour")
	check(hazard_script.get("IMMINENT_SEGMENTS_CLOSE") == true, "Imminent phase closes contour segments")
	check(hazard_script.get("ACTIVE_HATCHED") == true, "Active phase uses non-color hatching")
	check(hazard_script.get("SAFE_CHEVRONS_INWARD") == true, "Safe space uses inward chevrons")
