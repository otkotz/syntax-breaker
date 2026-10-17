class_name TerminalContractPicker
extends Control

signal chosen(difficulty: int)

var _chosen := false

func setup(options: Array[Dictionary]) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.055, 0.96)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 720.0
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	var title := Label.new()
	title.text = "SELECT COMPILATION CONTRACT\nHigher risk accelerates Compiler Heat"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	for option: Dictionary in options:
		var button := Button.new()
		button.custom_minimum_size = Vector2(720, 116)
		button.text = _card_text(option)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 19)
		UITheme.style_button(button, 20)
		var selected_difficulty := int(option.difficulty)
		button.pressed.connect(func(): _choose(selected_difficulty))
		box.add_child(button)

func _card_text(option: Dictionary) -> String:
	var boss_text := " + MINIBOSS" if bool(option.get("miniboss", false)) else ""
	return "%s   [HEAT +%d]\n%d HOSTILES / %d ELITES%s   •   ZONE %dm\nREWARD POWER: %s" % [
		str(option.get("name", "CONTRACT")), int(option.get("heat_gain", 1)),
		int(option.get("enemy_count", 0)), int(option.get("elite_count", 0)), boss_text,
		int(round(float(option.get("zone_radius", 0.0)) / 10.0)), str(option.get("reward_label", "STANDARD"))]

func _choose(difficulty: int) -> void:
	if _chosen:
		return
	_chosen = true
	chosen.emit(difficulty)
	queue_free()
