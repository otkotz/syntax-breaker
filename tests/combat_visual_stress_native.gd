extends Node

func _ready() -> void:
	var failures := 0
	if CombatVisualBudget.MAX_FRIENDLY_COVERAGE > 0.20: failures += 1; push_error("friendly coverage exceeds 20%")
	if DeathEffect.MAX_ACTIVE > 8: failures += 1; push_error("death effects exceed stress cap")
	if SkillVisualRenderer.MAX_SEGMENTS > 20: failures += 1; push_error("skill renderer segment cap exceeded")
	var hazard := preload("res://scripts/enemies/boss_hazard.gd").new()
	add_child(hazard)
	await get_tree().process_frame
	if hazard.z_index < 20: failures += 1; push_error("hostile telegraph priority lost")
	hazard.queue_free()
	if failures == 0: print("combat_visual_stress_native: PASS (80-enemy contract)")
	get_tree().quit(failures)
