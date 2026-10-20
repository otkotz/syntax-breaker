extends Node

const BossHazard := preload("res://scripts/enemies/boss_hazard.gd")

var failures := 0

func _ready() -> void:
	var shapes: Dictionary = {}
	for role: String in ["swarm", "trash", "ranged", "tank", "shield_support", "charger", "elite"]:
		var shape: PackedVector2Array = EnemyBase.role_outline(role)
		_check(shape.size() >= 3, role + " has a readable outline")
		shapes[role] = str(shape)
	var unique_shapes := {}
	for value: String in shapes.values(): unique_shapes[value] = true
	_check(unique_shapes.size() == 7, "combat roles remain distinct without color")
	var enemy := EnemyBase.new()
	enemy.max_hp = 20.0; enemy.current_hp = 20.0
	_check(not enemy.should_show_health_bar(), "full-health trash bar is hidden")
	enemy.current_hp = 19.0
	_check(enemy.should_show_health_bar(), "damaged trash bar appears")
	enemy.set_meta("combat_role", "elite"); enemy.current_hp = 20.0
	_check(enemy.should_show_health_bar(), "elite bar stays visible")
	_check(EnemyBase.visible_statuses(["poison", "burn", "shock", "slow"]).size() == 3, "two statuses plus overflow glyph")
	for source: String in ["fire", "cold", "lightning", "poison", "physical", "void"]:
		_check(DeathEffect.signature_for(source).fragment_count <= 6, source + " death stays within fragment cap")
		_check(not str(DeathEffect.signature_for(source).shape).is_empty(), source + " death has source shape")
	_check(DeathEffect.DURATION >= 0.25 and DeathEffect.DURATION <= 0.45, "death punctuation is short")
	_check(DeathEffect.MAX_ACTIVE == 8, "death pool has eight-effect cap")
	_check(BossHazard.TELEGRAPH_STAGES == [&"pose", &"warning", &"active"], "boss tells preserve pose-warning-active order")
	enemy.free()
	if failures == 0: print("enemy_visual_roles_native: PASS")
	get_tree().quit(failures)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1; push_error("FAIL: " + message)
