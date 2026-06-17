class_name SkillPicker
extends Control

signal skill_chosen(skill: SkillResource)

var _skill_grid: GridContainer

const CATEGORY_TAGS := ["melee", "projectile", "aoe"]

func _ready() -> void:
	_build_ui()
	_populate()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.C_BG
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
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroller.add_child(margin)

	_skill_grid = GridContainer.new()
	_skill_grid.columns = 2
	_skill_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_skill_grid.add_theme_constant_override("h_separation", 10)
	_skill_grid.add_theme_constant_override("v_separation", 10)
	margin.add_child(_skill_grid)

func _build_header(parent: Control) -> void:
	var header := PanelContainer.new()
	var hs := StyleBoxFlat.new()
	hs.bg_color = UITheme.C_BG_1
	hs.border_color = UITheme.C_V_LINE
	hs.border_width_bottom = 2
	hs.set_content_margin_all(0)
	hs.content_margin_left = 20
	hs.content_margin_right = 20
	hs.content_margin_top = 28
	hs.content_margin_bottom = 22
	header.add_theme_stylebox_override("panel", hs)
	parent.add_child(header)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	header.add_child(vbox)

	var title := Label.new()
	title.text = "ABILITY_MATRIX [SELECTION]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)
	title.uppercase = true
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "SELECT STARTING OVERRIDE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", UITheme.C_INK_LOW)
	sub.uppercase = true
	vbox.add_child(sub)

func _populate() -> void:
	for file_name in ResourceListing.get_resource_files("res://resources/skills/"):
		var res := load("res://resources/skills/" + file_name)
		if res is SkillResource and MetaProgression.is_unlocked("skills", (res as SkillResource).id):
			_add_skill_card(res as SkillResource)

func _add_skill_card(skill: SkillResource) -> void:
	var color := _get_skill_color(skill)

	var card := PanelContainer.new()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = UITheme.C_CARD_BG
	card_style.border_color = Color(color, 0.4)
	card_style.set_border_width_all(1)
	card_style.border_width_top = 2
	card_style.set_content_margin_all(10)
	card_style.content_margin_top = 12
	card_style.shadow_color = Color(color, 0.1)
	card_style.shadow_size = 4
	card.add_theme_stylebox_override("panel", card_style)
	_skill_grid.add_child(card)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	content.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(content)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child(head)

	var gem := _build_gem(color)
	head.add_child(gem)

	var name_lbl := Label.new()
	name_lbl.text = skill.name
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", UITheme.C_SILVER)
	name_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	name_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	head.add_child(name_lbl)

	content.add_child(_gap(6))

	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 4)
	tag_row.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child(tag_row)
	for tag: String in skill.tags:
		var is_category := tag in CATEGORY_TAGS
		var prefix := "C_" if is_category else "R_"
		var pill := _make_pill(prefix + tag.to_upper(), is_category, color)
		tag_row.add_child(pill)

	content.add_child(_gap(8))

	var desc := Label.new()
	desc.text = skill.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	desc.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child(desc)

	content.add_child(_gap(8))

	var stats_panel := PanelContainer.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0, 0, 0, 0.35)
	ss.border_color = UITheme.C_V_LINE_D
	ss.border_width_top = 1
	ss.set_content_margin_all(6)
	ss.content_margin_left = 8
	ss.content_margin_right = 8
	stats_panel.add_theme_stylebox_override("panel", ss)
	stats_panel.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_child(stats_panel)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 0)
	stats_row.mouse_filter = MOUSE_FILTER_IGNORE
	stats_panel.add_child(stats_row)

	var dps := skill.base_damage / maxf(skill.base_cooldown, 0.01)
	_add_stat(stats_row, "DMG", str(roundi(skill.base_damage)))
	_add_stat(stats_row, "DPS", str(roundi(dps)))
	_add_stat(stats_row, "CD", "%.1fs" % skill.base_cooldown)
	_add_stat(stats_row, "SLOTS", str(skill.max_supports))

	content.add_child(_gap(8))

	var select_btn := Button.new()
	select_btn.text = "SELECT [OVERRIDE]"
	select_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	_style_select_button(select_btn, color)
	select_btn.pressed.connect(func(): skill_chosen.emit(skill))
	content.add_child(select_btn)

func _build_gem(color: Color) -> PanelContainer:
	var container := PanelContainer.new()
	container.custom_minimum_size = Vector2(40, 40)
	container.mouse_filter = MOUSE_FILTER_IGNORE
	var gem_s := StyleBoxFlat.new()
	gem_s.bg_color = Color(color, 0.15)
	gem_s.border_color = Color(color, 0.6)
	gem_s.set_border_width_all(2)
	gem_s.set_content_margin_all(0)
	gem_s.shadow_color = Color(color, 0.2)
	gem_s.shadow_size = 6
	container.add_theme_stylebox_override("panel", gem_s)
	return container

func _make_pill(text: String, is_category: bool, card_color: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.mouse_filter = MOUSE_FILTER_IGNORE
	var pill_s := StyleBoxFlat.new()
	var pill_color := Color(0.3, 0.75, 0.85) if is_category else card_color
	pill_s.bg_color = Color(pill_color, 0.1)
	pill_s.border_color = Color(pill_color, 0.7)
	pill_s.set_border_width_all(1)
	pill_s.content_margin_left = 5
	pill_s.content_margin_right = 5
	pill_s.content_margin_top = 1
	pill_s.content_margin_bottom = 1
	pill.add_theme_stylebox_override("panel", pill_s)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(pill_color, 0.9))
	lbl.mouse_filter = MOUSE_FILTER_IGNORE
	pill.add_child(lbl)
	return pill

func _add_stat(parent: Control, key: String, value: String) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(vbox)

	var k := Label.new()
	k.text = key
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.add_theme_font_size_override("font_size", 11)
	k.add_theme_color_override("font_color", UITheme.C_INK_FAINT)
	k.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(k)

	var v := Label.new()
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_font_size_override("font_size", 18)
	v.add_theme_color_override("font_color", UITheme.C_INK)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(v)

func _style_select_button(btn: Button, color: Color) -> void:
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", UITheme.C_SILVER)
	btn.add_theme_color_override("font_hover_color", color)

	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(color, 0.1)
	ns.border_color = Color(color, 0.5)
	ns.set_border_width_all(1)
	ns.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", ns)

	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(color, 0.2)
	hs.border_color = Color(color, 0.8)
	hs.set_border_width_all(1)
	hs.set_content_margin_all(8)
	btn.add_theme_stylebox_override("hover", hs)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(color, 0.05)
	ps.border_color = Color(color, 0.3)
	ps.set_border_width_all(1)
	ps.set_content_margin_all(8)
	btn.add_theme_stylebox_override("pressed", ps)

func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = MOUSE_FILTER_IGNORE
	return c

func _get_skill_color(skill: SkillResource) -> Color:
	return TagColors.get_color(skill.tags)
