extends Node2D

class RollbackDummy extends Node2D:
	var outbound_hits := 0
	var return_hits := 0
	func _ready() -> void:
		add_to_group("enemies")
	func take_damage(_damage: float, _crit: bool, _source: Resource, _channel: String = "direct") -> void:
		var rollback := get_meta("rollback_source") as Rollback
		if rollback.state == Rollback.State.OUTBOUND:
			outbound_hits += 1
		elif rollback.state == Rollback.State.RETURNING:
			return_hits += 1
	func is_alive() -> bool:
		return true

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	var player := Node2D.new()
	add_child(player)
	var skill := SkillInstance.new(load("res://resources/skills/blade_spin.tres"))
	var rollback := preload("res://scenes/skills/rollback.tscn").instantiate() as Rollback
	add_child(rollback)
	rollback.initialize(skill, Vector2.RIGHT, null, AttackContext.root("blade_spin", 1))
	rollback.set_owner_node(player)
	var dummy := RollbackDummy.new()
	dummy.set_meta("rollback_source", rollback)
	add_child(dummy)
	rollback._on_body_entered(dummy)
	rollback._on_body_entered(dummy)
	rollback.advance_simulation(0.6)
	check(rollback.state == Rollback.State.RETURNING, "Rollback turns at maximum range")
	rollback._on_body_entered(dummy)
	rollback._on_body_entered(dummy)
	player.position = Vector2(0, 120)
	rollback.advance_simulation(0.6)
	check(rollback.state == Rollback.State.CAUGHT, "Return trajectory follows the moving owner")
	check(dummy.outbound_hits == 1 and dummy.return_hits == 1,
		"A target can be hit once in each direction")
	check(rollback.get_ordered_hits().size() == 2 and rollback.get_recorded_path().size() >= 2,
		"Rollback exposes ordered hits and its recorded path")
	check(skill.base.id == "blade_spin" and skill.base.name == "Rollback",
		"Legacy skill ID loads with the Rollback display identity")
	if failures.is_empty():
		print("PASS: rollback state machine, moving owner, path and directional hits")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
