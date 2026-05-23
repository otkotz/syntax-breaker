class_name SkillPicker
extends Control

signal skill_chosen(skill: SkillResource)

const C_BG := UITheme.C_BG
const C_BRONZE := UITheme.C_V_BRIGHT
const C_BRONZE_HI := UITheme.C_V_BRIGHT
const C_BRONZE_LINE := UITheme.C_V_LINE
const C_INK := UITheme.C_INK
const C_INK_MUTE := UITheme.C_INK_MUTE
const C_INK_LOW := UITheme.C_INK_LOW
const C_INK_FAINT := UITheme.C_INK_FAINT
const C_GOLD := UITheme.C_SILVER
const C_CARD_BG := UITheme.C_CARD_BG

const C_STR := UITheme.C_STR
const C_DEX := UITheme.C_DEX
const C_INT := UITheme.C_INT

var _skill_list: VBoxContainer

func _ready() -> void:
	_build_ui()
	_populate()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_STOP
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	_build_header(root)

	var scroller := ScrollContainer.new()
	scroller.size_flags_vertical = SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroller)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroller.add_child(margin)

	_skill_list = VBoxContainer.new()
	_skill_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_skill_list.add_theme_constant_override("separation", 14)
	margin.add_child(_skill_list)

func _build_header(parent: Control) -> void:
	var header := PanelContainer.new()
	var hs := StyleBoxFlat.new()
	hs.bg_color = UITheme.C_BG_1
	hs.border_color = C_BRONZE_LINE
	hs.border_width_bottom = 1
	hs.set_content_margin_all(0)
	hs.content_margin_left = 16
	hs.content_margin_right = 16
	hs.content_margin_top = 24
	hs.content_margin_bottom = 20
	header.add_theme_stylebox_override("panel", hs)
	parent.add_child(header)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	header.add_child(vbox)

	var eyebrow := Label.new()
	eyebrow.text = "— YOUR JOURNEY BEGINS —"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_color_override("font_color", C_BRONZE)
	eyebrow.uppercase = true
	vbox.add_child(eyebrow)

	var title := Label.new()
	title.text = "CHOOSE A SKILL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", C_GOLD)
	title.uppercase = true
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "SELECT YOUR STARTING ABILITY"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", C_INK_LOW)
	sub.uppercase = true
	vbox.add_child(sub)

func _populate() -> void:
	for file_name in ResourceListing.get_resource_files("res://resources/skills/"):
		var res := load("res://resources/skills/" + file_name)
		if res is SkillResource:
			_add_skill_card(res as SkillResource)

func _add_skill_card(skill: SkillResource) -> void:
	var color := _get_skill_color(skill)

	var card := PanelContainer.new()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = C_CARD_BG
	card_style.border_color = C_BRONZE_LINE
	card_style.set_border_width_all(1)
	card_style.border_width_left = 3
	card_style.set_content_margin_all(14)
	card_style.content_margin_bottom = 16
	card_style.shadow_color = Color(0, 0, 0, 0.3)
	card_style.shadow_size = 6
	card.add_theme_stylebox_override("panel", card_style)
	card.mouse_filter = MOUSE_FILTER_STOP
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			skill_chosen.emit(skill)
	)
	_skill_list.add_child(card)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	content.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(content)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	head.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child(head)

	var gem := _build_gem(color)
	head.add_child(gem)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	info.mouse_filter = MOUSE_FILTER_IGNORE
	head.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = skill.name
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", color)
	name_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	info.add_child(name_lbl)

	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 5)
	tag_row.mouse_filter = MOUSE_FILTER_IGNORE
	info.add_child(tag_row)
	for i in skill.tags.size():
		var pill := _make_pill(skill.tags[i], i == 0, color)
		tag_row.add_child(pill)

	content.add_child(_gap(10))

	var desc := Label.new()
	desc.text = skill.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", C_INK_MUTE)
	desc.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child(desc)

	content.add_child(_gap(12))

	var stats_panel := PanelContainer.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0, 0, 0, 0.3)
	ss.border_color = C_BRONZE_LINE
	ss.border_width_top = 1
	ss.border_width_bottom = 1
	ss.set_content_margin_all(10)
	ss.content_margin_left = 12
	ss.content_margin_right = 12
	stats_panel.add_theme_stylebox_override("panel", ss)
	stats_panel.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child(stats_panel)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 24)
	stats_row.mouse_filter = MOUSE_FILTER_IGNORE
	stats_panel.add_child(stats_row)

	var dps := skill.base_damage / maxf(skill.base_cooldown, 0.01)
	_add_stat(stats_row, "DMG", str(roundi(skill.base_damage)))
	_add_stat(stats_row, "DPS", str(roundi(dps)))
	_add_stat(stats_row, "CD", "%.1fs" % skill.base_cooldown)
	_add_stat(stats_row, "SLOTS", str(skill.max_supports))

	content.add_child(_gap(10))

	var divider := DividerLine.new()
	divider.custom_minimum_size = Vector2(0, 16)
	divider.line_color = C_BRONZE_LINE
	divider.diamond_color = C_BRONZE
	divider.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child(divider)

	content.add_child(_gap(2))

	var cta_hint := Label.new()
	cta_hint.text = "TAP TO SELECT"
	cta_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cta_hint.add_theme_font_size_override("font_size", 16)
	cta_hint.add_theme_color_override("font_color", C_INK_FAINT)
	cta_hint.uppercase = true
	cta_hint.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child(cta_hint)

func _build_gem(color: Color) -> PanelContainer:
	var container := PanelContainer.new()
	container.custom_minimum_size = Vector2(56, 56)
	container.mouse_filter = MOUSE_FILTER_IGNORE
	var gem_s := StyleBoxFlat.new()
	gem_s.bg_color = Color(color, 0.12)
	gem_s.border_color = Color(color, 0.6)
	gem_s.set_border_width_all(2)
	gem_s.set_content_margin_all(0)
	gem_s.shadow_color = Color(color, 0.25)
	gem_s.shadow_size = 8
	container.add_theme_stylebox_override("panel", gem_s)
	return container

func _make_pill(text: String, is_primary: bool, card_color: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.mouse_filter = MOUSE_FILTER_IGNORE
	var pill_s := StyleBoxFlat.new()
	pill_s.bg_color = Color(0, 0, 0, 0.4)
	pill_s.border_color = C_BRONZE_LINE if not is_primary else Color(card_color, 0.85)
	pill_s.set_border_width_all(1)
	pill_s.content_margin_left = 7
	pill_s.content_margin_right = 7
	pill_s.content_margin_top = 2
	pill_s.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", pill_s)

	var lbl := Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", C_INK_LOW if not is_primary else card_color)
	lbl.mouse_filter = MOUSE_FILTER_IGNORE
	pill.add_child(lbl)
	return pill

func _add_stat(parent: Control, key: String, value: String) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(vbox)

	var k := Label.new()
	k.text = key
	k.add_theme_font_size_override("font_size", 14)
	k.add_theme_color_override("font_color", C_INK_FAINT)
	k.uppercase = true
	k.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(k)

	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 22)
	v.add_theme_color_override("font_color", C_INK)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(v)

func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = MOUSE_FILTER_IGNORE
	return c

func _get_skill_color(skill: SkillResource) -> Color:
	if skill.tags.has("fire"):
		return C_STR
	elif skill.tags.has("lightning") or skill.tags.has("spell"):
		return C_INT
	elif skill.tags.has("melee") or skill.tags.has("projectile"):
		return C_DEX
	return C_BRONZE
