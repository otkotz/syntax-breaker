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
		var button := _build_offer_card(offer, skills)
		button.pressed.connect(func(): _select_offer(offer, skills))
		box.add_child(button)

func format_tier_transition(current: int, offered: int) -> String:
	return "%s → %s" % [EvolutionData.roman(current), EvolutionData.roman(offered)]

func _build_offer_card(offer: Dictionary, skills: Array[SkillInstance]) -> Button:
	var button := Button.new()
	button.set_meta("evolution_offer", true)
	button.custom_minimum_size = Vector2(700, 120)
	button.tooltip_text = ""
	UITheme.style_button(button, 20)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 14)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	button.add_child(row)
	var artwork := UITheme.item_thumbnail(offer, 88)
	if artwork:
		row.add_child(artwork)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = SIZE_EXPAND_FILL
	copy.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var heading := Label.new()
	heading.text = str(offer.get("name", "Upgrade"))
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)
	heading.mouse_filter = MOUSE_FILTER_IGNORE
	copy.add_child(heading)
	var tier := Label.new()
	if offer.get("type") == "evolution":
		tier.text = format_tier_transition(int(offer.get("current_tier", 0)), int(offer.get("offered_tier", 0)))
	elif offer.get("type") == "kernel_fork":
		tier.text = "KERNEL FORK — POWER + TRADEOFF"
	else:
		tier.text = "EXTRA SUPPORT SLOT"
	tier.add_theme_font_size_override("font_size", 18)
	tier.add_theme_color_override("font_color", UITheme.C_RARITY_LEGENDARY)
	tier.mouse_filter = MOUSE_FILTER_IGNORE
	copy.add_child(tier)
	var description := Label.new()
	description.text = str(offer.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	description.mouse_filter = MOUSE_FILTER_IGNORE
	copy.add_child(description)
	return button

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
	elif offer.type == "kernel_fork":
		if skill.mutations.any(func(mutation: Dictionary): return MutationData.is_terminal(mutation)):
			return
		skill.mutations.append((offer.mutation as Dictionary).duplicate(true))
		skill.recompute(RunManager.owned_passives)
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
