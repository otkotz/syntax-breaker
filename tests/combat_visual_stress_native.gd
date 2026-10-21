extends Node

func _ready() -> void:
	var failures := 0
	var enemies: Array[EnemyBase] = []
	for i in 80:
		var enemy := EnemyBase.new()
		enemy.position = Vector2((i % 10) * 28, (i / 10) * 28)
		add_child(enemy)
		enemies.append(enemy)
	await get_tree().process_frame
	if get_tree().get_nodes_in_group("enemies").size() < 80: failures += 1; push_error("80-enemy fixture did not materialize")
	if CombatVisualBudget.MAX_FRIENDLY_COVERAGE > 0.20: failures += 1; push_error("friendly coverage exceeds 20%")
	if DeathEffect.MAX_ACTIVE > 8: failures += 1; push_error("death effects exceed stress cap")
	if SkillVisualRenderer.MAX_SEGMENTS > 20: failures += 1; push_error("skill renderer segment cap exceeded")
	CombatVisualBudget.reset()
	for i in 24: CombatVisualBudget.request(&"full_trail", 1, i + 1)
	if CombatVisualBudget.request(&"full_trail", 1, 999): failures += 1; push_error("friendly saturation admitted overflow")
	if not CombatVisualBudget.request(&"hostile_warning", 99, 1000): failures += 1; push_error("hostile warning lost under friendly saturation")
	var hazard := preload("res://scripts/enemies/boss_hazard.gd").new()
	add_child(hazard)
	hazard.set_process(false)
	if hazard.z_index < 20: failures += 1; push_error("hostile telegraph priority lost")
	hazard.queue_free()
	for enemy: EnemyBase in enemies: enemy.queue_free()
	CombatVisualBudget.reset()
	if failures == 0: print("combat_visual_stress_native: PASS (80-enemy contract)")
	get_tree().quit(failures)
