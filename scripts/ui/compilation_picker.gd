class_name CompilationPicker
extends Control

signal chosen
var _chosen := false
var _decision_id: int = 0

func setup(skills: Array[SkillInstance]) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
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
	title.text = "TERMINAL OVERRIDDEN\nChoose one permanent mutation for this run"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var excluded: Array = []
	for skill: SkillInstance in skills:
		for mutation: Dictionary in skill.mutations:
			excluded.append(mutation.get("id", ""))
	var mutations := MutationData.roll_terminal_mutations(8, excluded, skills)
	var offers: Array[Dictionary] = []
	for mutation: Dictionary in mutations:
		for skill: SkillInstance in skills:
			if MutationData.can_apply(mutation, skill):
				offers.append({"skill": skill, "mutation": mutation})
	offers.shuffle()
	var offered: Array = []
	for offer in offers.slice(0, mini(3, offers.size())):
		offered.append({"id": offer.mutation.id, "skill": offer.skill.base.id})
	_decision_id = RunTelemetry.open_decision("terminal_mutation", offered)
	for offer: Dictionary in offers.slice(0, mini(3, offers.size())):
		var skill: SkillInstance = offer.skill
		var mutation: Dictionary = offer.mutation
		var btn := Button.new()
		btn.text = "%s: %s\n%s" % [skill.base.name, mutation.name, mutation.desc]
		btn.custom_minimum_size.y = 120
		UITheme.style_button(btn, 26)
		btn.pressed.connect(func():
			if _chosen:
				return
			skill.add_mutation(mutation)
			_finish({"id": mutation.id, "skill": skill.base.id})
		)
		box.add_child(btn)

func _finish(selected: Dictionary = {"id": "skip"}) -> void:
	if _chosen:
		return
	_chosen = true
	RunTelemetry.choose(_decision_id, selected)
	chosen.emit()
	queue_free()
