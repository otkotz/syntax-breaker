class_name EvolutionGallery
extends Control

const SELECTORS := ["skill", "support_set", "tier", "terminal_difficulty", "formation", "density"]
var _gameplay_effects: Dictionary = {}
var _controls_built := false

func _ready() -> void:
	_build_controls()

func selector_names() -> Array[String]:
	var names: Array[String] = []
	for selector: String in SELECTORS:
		names.append(selector)
	return names

func show_effect(evolution_id: String, tier: int) -> void:
	_gameplay_effects.clear()
	var skill_id := ""
	for candidate: String in EvolutionData.BY_SKILL:
		if EvolutionData.BY_SKILL[candidate].id == evolution_id:
			skill_id = candidate
			break
	if skill_id.is_empty():
		return
	var identity := "rollback" if skill_id == "blade_spin" else skill_id
	var requested := 1
	if evolution_id == "recursive_rollback":
		requested += RecursiveRollbackEvolution.simulate(tier).child_boomerangs
	_gameplay_effects[identity] = mini(requested, QualitySettings.projectile_cap)

func count_gameplay_effects(kind: String) -> int:
	return int(_gameplay_effects.get(kind, 0))

func _build_controls() -> void:
	if _controls_built:
		return
	_controls_built = true
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	var title := Label.new()
	title.text = "EVOLUTION TEST GALLERY"
	UITheme.style_label_title(title, 30)
	list.add_child(title)
	for selector: String in SELECTORS:
		var label := Label.new()
		label.text = selector.replace("_", " ").to_upper()
		UITheme.style_label_body(label, 18)
		list.add_child(label)
		var options := OptionButton.new()
		options.name = selector
		options.custom_minimum_size.y = 64
		for value: String in _values_for(selector):
			options.add_item(value)
		list.add_child(options)

func _values_for(selector: String) -> Array[String]:
	match selector:
		"skill": return ["Fireball", "Flame Wave", "Frost Nova", "Lightning Bolt", "Poison Dart", "Static Field", "Rollback"]
		"support_set": return ["None", "Signature", "Memetic", "Stress"]
		"tier": return ["I", "II", "III"]
		"terminal_difficulty": return ["Compile", "Overclock", "Kernel Breach"]
		"formation": return ["Single", "Line", "Ring", "Swarm"]
		"density": return ["Low", "Medium", "High", "Cap"]
	return []
