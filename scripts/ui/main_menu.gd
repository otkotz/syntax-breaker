class_name MainMenu
extends Control

signal start_pressed
signal unlocks_pressed
signal codex_pressed

const C_BG := Color(0.02, 0.012, 0.031)
const C_BG_1 := Color(0.039, 0.024, 0.071)
const C_BG_2 := Color(0.063, 0.039, 0.110)
const C_PANEL_BG := Color(0.05, 0.03, 0.10, 0.65)

const C_V_DEEP := Color(0.118, 0.051, 0.251)
const C_V_BASE := Color(0.357, 0.129, 0.714)
const C_V_MID := Color(0.427, 0.157, 0.851)
const C_V_BRIGHT := Color(0.545, 0.361, 0.965)
const C_V_GLOW := Color(0.545, 0.361, 0.965, 0.45)
const C_V_LINE := Color(0.231, 0.106, 0.439)
const C_V_LINE_D := Color(0.165, 0.078, 0.333)

const C_SILVER := Color(0.90, 0.89, 0.93)
const C_SILVER_D := Color(0.78, 0.76, 0.82)
const C_INK := Color(0.90, 0.89, 0.93)
const C_INK_MUTE := Color(0.68, 0.67, 0.73)
const C_INK_LOW := Color(0.47, 0.45, 0.55)
const C_INK_FAINT := Color(0.33, 0.30, 0.40)

var _region_ids: Array[String] = []
var _region_index: int = 0
var _asc_num: Label
var _asc_desc: Label
var _asc_down: Button
var _asc_up: Button
var _region_name: Label
var _region_sub: Label
var _region_desc: Label
var _region_prev: Button
var _region_next: Button

func _ready() -> void:
	_build_ui()
	_load_regions()
	_refresh_ascension()
	_refresh_region()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	var bg_glow := ColorRect.new()
	bg_glow.color = Color(0.08, 0.03, 0.18, 0.45)
	bg_glow.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg_glow.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg_glow)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	margin.add_child(root)

	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 0)
	top.size_flags_vertical = SIZE_EXPAND_FILL
	top.size_flags_stretch_ratio = 1.0
	root.add_child(top)
	_build_crest(top)
	_build_logo(top)
	_build_seed_chip(top)

	var bottom := VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 0)
	bottom.size_flags_vertical = SIZE_EXPAND_FILL
	bottom.size_flags_stretch_ratio = 1.0
	root.add_child(bottom)
	bottom.add_child(_gap(8))
	bottom.add_child(_build_panel())
	bottom.add_child(_gap(16))
	_build_actions(bottom)
	bottom.add_child(_gap(10))
	_build_footer(bottom)

func _build_crest(parent: Control) -> void:
	var bar := HBoxContainer.new()
	parent.add_child(bar)
	var left := _lbl("● SANCTUM ONLINE", 16, C_INK_FAINT)
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left.uppercase = true
	bar.add_child(left)
	var right := _lbl("CHAPTER · III", 16, C_INK_FAINT, HORIZONTAL_ALIGNMENT_RIGHT)
	right.uppercase = true
	bar.add_child(right)

func _build_logo(parent: Control) -> void:
	var logo_tex := preload("res://assets/sprites/logo.png")
	var logo := TextureRect.new()
	logo.texture = logo_tex
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size_flags_horizontal = SIZE_EXPAND_FILL
	logo.size_flags_vertical = SIZE_EXPAND_FILL
	parent.add_child(logo)

func _build_seed_chip(parent: Control) -> void:
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(center)

	var chip := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0, 0, 0, 0.4)
	cs.border_color = C_V_LINE_D
	cs.set_border_width_all(1)
	cs.corner_radius_top_left = 20
	cs.corner_radius_top_right = 20
	cs.corner_radius_bottom_left = 20
	cs.corner_radius_bottom_right = 20
	cs.content_margin_left = 14
	cs.content_margin_right = 14
	cs.content_margin_top = 5
	cs.content_margin_bottom = 5
	chip.add_theme_stylebox_override("panel", cs)
	center.add_child(chip)

	var seed_text := _lbl("● SEED · %s" % _generate_seed(), 16, C_INK_LOW)
	seed_text.uppercase = true
	chip.add_child(seed_text)

func _generate_seed() -> String:
	var chars := "0123456789ABCDEF"
	var s := ""
	for i in 3:
		s += chars[randi() % chars.length()]
	s += "-"
	for i in 4:
		s += chars[randi() % chars.length()]
	return s

func _build_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = C_PANEL_BG
	ps.border_color = C_V_LINE
	ps.set_border_width_all(1)
	ps.set_content_margin_all(22)
	ps.content_margin_top = 24
	ps.shadow_color = C_V_GLOW
	ps.shadow_size = 20
	panel.add_theme_stylebox_override("panel", ps)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	panel.add_child(v)

	var asc_label := _row_label("ASCENSION")
	v.add_child(asc_label)
	v.add_child(_gap(14))

	var ar := HBoxContainer.new()
	ar.alignment = BoxContainer.ALIGNMENT_CENTER
	ar.add_theme_constant_override("separation", 18)
	v.add_child(ar)

	_asc_down = _make_diamond_btn("−")
	_asc_down.pressed.connect(func() -> void: _change_ascension(-1))
	ar.add_child(_asc_down)

	var medallion := _build_medallion()
	ar.add_child(medallion)

	_asc_up = _make_diamond_btn("+")
	_asc_up.pressed.connect(func() -> void: _change_ascension(1))
	ar.add_child(_asc_up)

	v.add_child(_gap(24))
	_asc_desc = Label.new()
	_asc_desc.text = "Normal — the first descent."
	_asc_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_asc_desc.add_theme_font_size_override("font_size", 20)
	_asc_desc.add_theme_color_override("font_color", C_INK_MUTE)
	v.add_child(_asc_desc)

	v.add_child(_gap(20))
	var pd := DividerLine.new()
	pd.custom_minimum_size = Vector2(0, 16)
	pd.line_color = C_V_LINE
	pd.diamond_color = C_V_BRIGHT
	v.add_child(pd)
	v.add_child(_gap(20))

	var reg_label := _row_label("STARTING REGION")
	v.add_child(reg_label)
	v.add_child(_gap(14))

	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 8)
	v.add_child(rr)

	_region_prev = _make_arrow("‹")
	_region_prev.pressed.connect(func() -> void: _change_region(-1))
	rr.add_child(_region_prev)

	var region_box := PanelContainer.new()
	region_box.size_flags_horizontal = SIZE_EXPAND_FILL
	var rbs := StyleBoxFlat.new()
	rbs.bg_color = Color(0.06, 0.03, 0.12, 0.6)
	rbs.border_color = C_V_LINE
	rbs.set_border_width_all(1)
	rbs.set_content_margin_all(14)
	rbs.content_margin_top = 12
	region_box.add_theme_stylebox_override("panel", rbs)
	rr.add_child(region_box)

	var region_inner := VBoxContainer.new()
	region_inner.add_theme_constant_override("separation", 4)
	region_box.add_child(region_inner)

	_region_sub = _lbl("", 14, C_V_BRIGHT)
	_region_sub.uppercase = true
	region_inner.add_child(_region_sub)

	_region_name = _lbl("DEFAULT", 28, C_SILVER)
	_region_name.uppercase = true
	region_inner.add_child(_region_name)

	_region_next = _make_arrow("›")
	_region_next.pressed.connect(func() -> void: _change_region(1))
	rr.add_child(_region_next)

	v.add_child(_gap(10))
	_region_desc = Label.new()
	_region_desc.text = ""
	_region_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_region_desc.add_theme_font_size_override("font_size", 18)
	_region_desc.add_theme_color_override("font_color", C_INK_LOW)
	_region_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_region_desc)

	return panel

func _build_medallion() -> PanelContainer:
	var m := PanelContainer.new()
	m.custom_minimum_size = Vector2(100, 100)
	var ms := StyleBoxFlat.new()
	ms.bg_color = Color(0.08, 0.04, 0.18)
	ms.border_color = C_V_LINE
	ms.set_border_width_all(1)
	ms.corner_radius_top_left = 50
	ms.corner_radius_top_right = 50
	ms.corner_radius_bottom_left = 50
	ms.corner_radius_bottom_right = 50
	ms.shadow_color = C_V_GLOW
	ms.shadow_size = 32
	ms.set_content_margin_all(0)
	m.add_theme_stylebox_override("panel", ms)

	_asc_num = Label.new()
	_asc_num.text = "0"
	_asc_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_asc_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_asc_num.add_theme_font_size_override("font_size", 44)
	_asc_num.add_theme_color_override("font_color", C_SILVER)
	_asc_num.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	_asc_num.add_theme_constant_override("shadow_offset_x", 0)
	_asc_num.add_theme_constant_override("shadow_offset_y", 1)
	m.add_child(_asc_num)

	return m

func _build_actions(parent: Control) -> void:
	var start := _make_cta("START RUN")
	start.pressed.connect(func() -> void: start_pressed.emit())
	parent.add_child(start)
	parent.add_child(_gap(10))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var unlocks := _make_ghost("◇  UNLOCKS")
	unlocks.size_flags_horizontal = SIZE_EXPAND_FILL
	unlocks.custom_minimum_size.y = 64
	unlocks.pressed.connect(func() -> void: unlocks_pressed.emit())
	row.add_child(unlocks)

	var codex := _make_ghost("◇  CODEX")
	codex.size_flags_horizontal = SIZE_EXPAND_FILL
	codex.custom_minimum_size.y = 64
	codex.pressed.connect(func() -> void: codex_pressed.emit())
	row.add_child(codex)

func _build_footer(parent: Control) -> void:
	var bar := HBoxContainer.new()
	parent.add_child(bar)
	var left := _lbl("v0.4.2 ▮ BUILD 1840", 14, C_INK_LOW, HORIZONTAL_ALIGNMENT_LEFT)
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.uppercase = true
	bar.add_child(left)
	var right := _lbl("SETTINGS · ⚙", 14, C_INK_LOW, HORIZONTAL_ALIGNMENT_RIGHT)
	right.uppercase = true
	bar.add_child(right)

# --- Helpers ---

func _lbl(text: String, font_size: int, color: Color, halign: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = halign
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _row_label(text: String) -> Label:
	var l := Label.new()
	l.text = "◇  %s  ◇" % text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", C_V_BRIGHT)
	l.uppercase = true
	return l

func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _flex() -> Control:
	var c := Control.new()
	c.size_flags_vertical = SIZE_EXPAND_FILL
	return c

func _make_diamond_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(50, 50)
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", C_V_BRIGHT)
	b.add_theme_color_override("font_hover_color", C_SILVER)
	b.add_theme_color_override("font_disabled_color", C_INK_FAINT)
	b.pivot_offset = Vector2(25, 25)
	b.rotation = deg_to_rad(45)

	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0.10, 0.06, 0.19)
	ns.border_color = C_V_LINE
	ns.set_border_width_all(1)
	ns.set_content_margin_all(4)
	ns.shadow_color = C_V_GLOW
	ns.shadow_size = 12
	b.add_theme_stylebox_override("normal", ns)

	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.15, 0.08, 0.25)
	hs.border_color = C_V_BRIGHT
	hs.set_border_width_all(1)
	hs.set_content_margin_all(4)
	hs.shadow_color = C_V_GLOW
	hs.shadow_size = 16
	b.add_theme_stylebox_override("hover", hs)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.03, 0.14)
	ps.border_color = C_V_LINE
	ps.set_border_width_all(1)
	ps.set_content_margin_all(4)
	b.add_theme_stylebox_override("pressed", ps)

	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.06, 0.03, 0.14)
	ds.border_color = C_V_LINE_D
	ds.set_border_width_all(1)
	ds.set_content_margin_all(4)
	b.add_theme_stylebox_override("disabled", ds)

	return b

func _make_arrow(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(48, 0)
	b.size_flags_vertical = SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", C_V_BRIGHT)
	b.add_theme_color_override("font_hover_color", C_SILVER)

	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0.08, 0.04, 0.16)
	ns.border_color = C_V_LINE
	ns.set_border_width_all(1)
	ns.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", ns)

	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.12, 0.06, 0.24)
	hs.border_color = C_V_BRIGHT
	hs.set_border_width_all(1)
	hs.set_content_margin_all(8)
	b.add_theme_stylebox_override("hover", hs)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.02, 0.10)
	ps.border_color = C_V_LINE
	ps.set_border_width_all(1)
	ps.set_content_margin_all(8)
	b.add_theme_stylebox_override("pressed", ps)

	return b

func _make_cta(text: String) -> Button:
	var b := Button.new()
	b.text = "◢◣  %s  ◢◣" % text
	b.custom_minimum_size.y = 70
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", C_SILVER)
	b.add_theme_color_override("font_hover_color", Color.WHITE)

	var normal := StyleBoxFlat.new()
	normal.bg_color = C_V_BASE
	normal.border_color = Color(0.45, 0.30, 0.85)
	normal.set_border_width_all(1)
	normal.set_content_margin_all(16)
	normal.shadow_color = C_V_GLOW
	normal.shadow_size = 32
	b.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = C_V_MID
	hover.border_color = Color(0.55, 0.40, 0.90)
	hover.set_border_width_all(1)
	hover.set_content_margin_all(16)
	hover.shadow_color = C_V_GLOW
	hover.shadow_size = 40
	b.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = C_V_DEEP
	pressed.border_color = C_V_LINE
	pressed.set_border_width_all(1)
	pressed.set_content_margin_all(16)
	pressed.shadow_color = C_V_GLOW
	pressed.shadow_size = 12
	b.add_theme_stylebox_override("pressed", pressed)

	return b

func _make_ghost(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 64
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", C_SILVER_D)
	b.add_theme_color_override("font_hover_color", C_V_BRIGHT)

	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0.05, 0.03, 0.10, 0.7)
	ns.border_color = C_V_LINE
	ns.set_border_width_all(1)
	ns.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", ns)

	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.08, 0.04, 0.16, 0.8)
	hs.border_color = C_V_BRIGHT
	hs.set_border_width_all(1)
	hs.set_content_margin_all(10)
	b.add_theme_stylebox_override("hover", hs)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.03, 0.02, 0.07, 0.8)
	ps.border_color = C_V_LINE
	ps.set_border_width_all(1)
	ps.set_content_margin_all(10)
	b.add_theme_stylebox_override("pressed", ps)

	return b

# --- Game Logic ---

func _load_regions() -> void:
	_region_ids = [""]
	for file_name in ResourceListing.get_resource_files("res://resources/regions/"):
		var res := load("res://resources/regions/" + file_name)
		if res is RegionResource:
			_region_ids.append(res.id)

func _change_ascension(delta: int) -> void:
	var level := clampi(MetaProgression.ascension_level + delta, 0, MetaProgression.MAX_ASCENSION)
	MetaProgression.set_ascension(level)
	_refresh_ascension()

func _refresh_ascension() -> void:
	var level := MetaProgression.ascension_level
	_asc_num.text = str(level)
	_asc_down.disabled = level <= 0
	_asc_up.disabled = level >= MetaProgression.MAX_ASCENSION
	if level == 0:
		_asc_desc.text = "Normal — the first descent."
	elif level <= 2:
		_asc_desc.text = "Cruel — wounds remember."
	elif level <= 5:
		_asc_desc.text = "Merciless — the world bites back."
	elif level <= 9:
		_asc_desc.text = "Sovereign — kneel, or break."
	else:
		_asc_desc.text = "Eternal — there is no morning."

func _change_region(delta: int) -> void:
	_region_index = wrapi(_region_index + delta, 0, _region_ids.size())
	_refresh_region()

func _refresh_region() -> void:
	if _region_ids.is_empty():
		_region_name.text = "DEFAULT"
		_region_sub.text = ""
		_region_desc.text = ""
		return
	var rid: String = _region_ids[_region_index]
	if rid.is_empty():
		_region_name.text = "VELLHAVEN"
		_region_sub.text = "GREYLANDS · TIER I"
		_region_desc.text = "\"Murmuring fens at the system's edge.\""
	else:
		var res := _load_region(rid)
		if res:
			_region_name.text = res.name.to_upper()
			_region_sub.text = res.description.to_upper() if res.description else ""
			_region_desc.text = ""
		else:
			_region_name.text = rid.to_upper()
			_region_sub.text = ""
			_region_desc.text = ""
	_region_prev.visible = _region_ids.size() > 1
	_region_next.visible = _region_ids.size() > 1

func _load_region(rid: String) -> RegionResource:
	var path := "res://resources/regions/%s.tres" % rid
	if ResourceLoader.exists(path):
		return load(path) as RegionResource
	return null

func get_selected_region() -> String:
	if _region_index >= 0 and _region_index < _region_ids.size():
		return _region_ids[_region_index]
	return ""
