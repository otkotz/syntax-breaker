extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	var fireball := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	check(fireball.set_evolution("solar_flare", 1), "First evolution applies")
	check(not fireball.set_evolution("solar_flare", 1), "Duplicate tier is rejected")
	check(not fireball.set_evolution("solar_flare", 0), "Downgrade is rejected")
	check(fireball.set_evolution("solar_flare", 3), "Direct tier III upgrade is legal")
	check(not fireball.set_evolution("daemon_process", 3), "Wrong-skill evolution is rejected")

	var corrupt := {"skill_id": "fireball", "evolution_id": "removed_id", "evolution_tier": 99}
	var restored := GameManager.deserialize_skill_entry(corrupt)
	check(restored != null and restored.evolution_id.is_empty() and restored.evolution_tier == 0,
		"Invalid saved evolution falls back to a usable base skill")

	var valid := {"skill_id": "fireball", "evolution_id": "solar_flare", "evolution_tier": 2}
	var evolved := GameManager.deserialize_skill_entry(valid)
	check(evolved != null and evolved.evolution_id == "solar_flare" and evolved.evolution_tier == 2,
		"Valid saved evolution restores its tier")

	if failures.is_empty():
		print("PASS: tiered evolution state and corrupt-save migration")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
