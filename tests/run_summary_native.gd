extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func has_text(root: Node, fragment: String) -> bool:
	for node: Node in root.find_children("*", "Label", true, false):
		if fragment in (node as Label).text:
			return true
	return false

func _ready() -> void:
	RunManager.start_run()
	for index in 7:
		RunManager.record_damage_event({"source": "tank:contact" if index < 6 else "basic_ranged:projectile",
			"hp_damage": float(index + 1), "shield_absorbed": 2.0 if index == 2 else 0.0})
	var sequence: Array[Dictionary] = RunManager.get_death_sequence()
	check(sequence.size() == 5 and sequence[0].hp_damage == 3.0 and sequence[-1].hp_damage == 7.0,
		"Death history retains the last five accepted hits in chronological order")
	sequence[0]["hp_damage"] = 999.0
	check(RunManager.get_death_sequence()[0].hp_damage == 3.0, "Death history API returns a defensive copy")
	RunManager.run_stats["death_source"] = "basic_ranged:projectile"
	var summary := preload("res://scenes/ui/run_summary.tscn").instantiate() as RunSummary
	add_child(summary)
	summary.setup(false)
	await get_tree().process_frame
	check(has_text(summary, "Final blow") and has_text(summary, "Ranged Projectile"),
		"Defeat summary names and normalizes the final blow")
	check(has_text(summary, "Recent burst") and has_text(summary, "Shield"),
		"Defeat summary totals recent HP and shield damage")
	check(summary.stats_container.get_children().filter(func(node: Node): return node.get_meta("death_hit", false)).size() == 5,
		"Defeat summary renders five compact damage rows")
	RunManager.start_run()
	check(RunManager.get_death_sequence().is_empty(), "A new run clears death history")
	if failures.is_empty():
		print("PASS: bounded five-hit death sequence and readable defeat recap")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
