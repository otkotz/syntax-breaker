class_name CompilationPicker
extends Control

signal chosen
var _chosen := false
var _decision_id: int = 0

const OPTIONS := [
	{"name": "Focused payload", "desc": "+20% damage, +15% cooldown", "stats": {"damage_mult": 1.2, "cooldown_mult": 1.15}},
	{"name": "Quick cycle", "desc": "-15% cooldown, -12% damage", "stats": {"cooldown_mult": 0.85, "damage_mult": 0.88}},
	{"name": "Wide sweep", "desc": "+25% area, -15% damage", "stats": {"area_mult": 1.25, "damage_mult": 0.85}, "tag": "aoe"},
	{"name": "Extended reach", "desc": "+25% range, -15% projectile speed", "stats": {"range_mult": 1.25, "speed_mult": 0.85}, "tag": "projectile"},
	{"name": "Breach", "desc": "+1 pierce, -10% damage", "stats": {"pierce": 1, "damage_mult": 0.9}, "tag": "projectile"},
]

static func available_options(skill: SkillInstance) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for option: Dictionary in OPTIONS:
		var tag: String = option.get("tag", "")
		if not tag.is_empty() and not skill.base.has_tag(tag):
			continue
		if tag == "projectile" and skill.computed_stats.get("is_mine", 0) > 0:
			continue
		result.append(option)
	return result

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
	title.text = "FIELD COMPILATION\nChoose an override for this battle only"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var offers: Array[Dictionary] = []
	for skill: SkillInstance in skills:
		for option: Dictionary in available_options(skill):
			offers.append({"skill": skill, "option": option})
	offers.shuffle()
	var offered: Array = []
	for offer in offers.slice(0, mini(3, offers.size())):
		offered.append({"id": offer.option.name, "skill": offer.skill.base.id})
	_decision_id = RunTelemetry.open_decision("compilation", offered)
	for offer: Dictionary in offers.slice(0, mini(3, offers.size())):
		var skill: SkillInstance = offer.skill
		var option: Dictionary = offer.option
		var btn := Button.new()
		btn.text = "%s: %s\n%s" % [skill.base.name, option.name, option.desc]
		btn.custom_minimum_size.y = 120
		UITheme.style_button(btn, 26)
		btn.pressed.connect(func():
			if _chosen:
				return
			skill.stage_overrides.append(option.stats.duplicate())
			skill.recompute(RunManager.owned_passives)
			_finish({"id": option.name, "skill": skill.base.id})
		)
		box.add_child(btn)
	var skip := Button.new()
	skip.text = "Keep current configuration"
	UITheme.style_button(skip, 24)
	skip.pressed.connect(_finish)
	box.add_child(skip)

func _finish(selected: Dictionary = {"id": "skip"}) -> void:
	if _chosen:
		return
	_chosen = true
	RunTelemetry.choose(_decision_id, selected)
	chosen.emit()
	queue_free()
