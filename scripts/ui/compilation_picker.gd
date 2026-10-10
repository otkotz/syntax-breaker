class_name CompilationPicker
extends Control

signal chosen
var _chosen := false
var _decision_id := 0

func setup(skills: Array[SkillInstance], difficulty: int = 0, rng: RandomNumberGenerator = null) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var roller := rng
	if roller == null:
		roller = RandomNumberGenerator.new()
		roller.randomize()
	var offers := EvolutionData.roll_offers(skills, difficulty, roller)
	_decision_id = RunTelemetry.open_decision("terminal_evolution", offers)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.05, 0.96)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 700
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)
	var title := Label.new()
	title.text = "COMPILATION COMPLETE\nChoose one permanent upgrade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	for offer: Dictionary in offers:
		var button := Button.new()
		button.text = "%s\n%s" % [offer.name, offer.description]
		button.custom_minimum_size.y = 120
		UITheme.style_button(button, 26)
		button.pressed.connect(func(): _select_offer(offer, skills))
		box.add_child(button)

func _select_offer(offer: Dictionary, skills: Array[SkillInstance]) -> void:
	if _chosen:
		return
	var skill_index := int(offer.get("skill_index", -1))
	if skill_index < 0 or skill_index >= skills.size():
		return
	var skill := skills[skill_index]
	if offer.type == "evolution":
		if not skill.set_evolution(offer.evolution_id, int(offer.offered_tier)):
			return
	elif offer.type == "support_slot":
		skill.grant_support_slot()
	else:
		return
	_finish(offer)

func _finish(selected: Dictionary) -> void:
	if _chosen:
		return
	_chosen = true
	RunTelemetry.choose(_decision_id, selected)
	chosen.emit()
	queue_free()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_EXIT_TREE, NOTIFICATION_PREDELETE] and not _chosen and _decision_id != 0:
		RunTelemetry.cancel_decision(_decision_id, "picker_closed")
		_decision_id = 0
