extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func find_offer_buttons(root: Node) -> Array[Button]:
	var result: Array[Button] = []
	for child in root.find_children("*", "Button", true, false):
		if child.get_meta("evolution_offer", false):
			result.append(child)
	return result

func find_text(root: Node, fragment: String) -> bool:
	for child in root.find_children("*", "Label", true, false):
		if fragment in (child as Label).text:
			return true
	return false

func _ready() -> void:
	var skills: Array[SkillInstance] = []
	for id in ["fireball", "lightning_bolt", "blade_spin"]:
		var skill := SkillInstance.new(load("res://resources/skills/%s.tres" % id))
		var evolution := EvolutionData.get_for_skill(id)
		skill.set_evolution(evolution.id, 2)
		skills.append(skill)
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	var picker := CompilationPicker.new()
	add_child(picker)
	picker.setup(skills, CompilationTerminal.Difficulty.KERNEL_BREACH, rng)
	await get_tree().process_frame
	var cards := find_offer_buttons(picker)
	check(cards.size() == 3, "Evolution picker shows exactly three legal offers")
	for card: Button in cards:
		check(card.size.y >= 96.0, "Every portrait offer has a 96 px touch target")
		check(card.tooltip_text.is_empty(), "Critical information never depends on hover")
	check(find_text(picker, "II → III"), "Upgrade card shows current-to-new tier")
	picker.queue_free()

	QualitySettings.set_preset(QualitySettings.Preset.LOW)
	var gallery := EvolutionGallery.new()
	add_child(gallery)
	gallery.show_effect("recursive_rollback", 3)
	check(gallery.selector_names() == ["skill", "support_set", "tier", "terminal_difficulty", "formation", "density"],
		"Gallery exposes all production test selectors")
	check(gallery.count_gameplay_effects("rollback") >= 1,
		"Low preset preserves mechanic identity")
	check(gallery.count_gameplay_effects("rollback") <= QualitySettings.projectile_cap,
		"Low preset obeys gameplay cap")

	if failures.is_empty():
		print("PASS: portrait evolution cards and low-quality touch gallery")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
