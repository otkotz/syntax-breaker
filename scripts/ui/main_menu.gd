class_name MainMenu
extends Control

signal start_pressed
signal unlocks_pressed
signal codex_pressed

const C_BG := Color(0.06, 0.05, 0.04)
const C_PANEL := Color(0.10, 0.07, 0.05)
const C_BRONZE := Color(0.56, 0.45, 0.28)
const C_BRONZE_HI := Color(0.78, 0.68, 0.48)
const C_BRONZE_LINE := Color(0.38, 0.30, 0.19)
const C_EMBER := Color(0.78, 0.38, 0.15)
const C_EMBER_GLOW := Color(0.78, 0.38, 0.15, 0.35)
const C_INK := Color(0.92, 0.88, 0.80)
const C_INK_MUTE := Color(0.72, 0.68, 0.58)
const C_INK_LOW := Color(0.50, 0.46, 0.38)
const C_INK_FAINT := Color(0.35, 0.32, 0.26)
const C_GOLD := Color(0.94, 0.87, 0.65)
const C_BTN_BG := Color(0.14, 0.11, 0.08)

var _region_ids: Array[String] = []
var _region_index: int = 0
var _asc_num: Label
var _asc_desc: Label
var _asc_down: Button
var _asc_up: Button
var _region_name: Label
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

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	margin.add_child(root)

	_build_crest(root)
	root.add_child(_flex())
	_build_title(root)
	root.add_child(_gap(16))
	_build_divider(root)
	root.add_child(_flex())
	root.add_child(_build_panel())
	root.add_child(_gap(28))
	_build_actions(root)
	root.add_child(_flex())
	_build_footer(root)

func _build_crest(parent: Control) -> void:
	var bar := HBoxContainer.new()
	parent.add_child(bar)
	var left := _lbl("● SANCTUM ONLINE", 18, C_INK_FAINT)
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left.uppercase = true
	bar.add_child(left)
	var right := _lbl("CHAPTER · III", 18, C_INK_FAINT, HORIZONTAL_ALIGNMENT_RIGHT)
	right.uppercase = true
	bar.add_child(right)

func _build_title(parent: Control) -> void:
	var eyebrow := _lbl("— A ROGUELITE OF BROKEN CODE —", 18, C_BRONZE)
	eyebrow.uppercase = true
	parent.add_child(eyebrow)
	parent.add_child(_gap(14))
	parent.add_child(_lbl("SYNTAX\nBREAKER", 96, C_GOLD))

func _build_divider(parent: Control) -> void:
	var div := DividerLine.new()
	div.custom_minimum_size = Vector2(0, 24)
	div.line_color = C_BRONZE_LINE
	div.diamond_color = C_BRONZE
	parent.add_child(div)

func _build_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = C_PANEL
	ps.border_color = C_BRONZE_LINE
	ps.set_border_width_all(2)
	ps.set_content_margin_all(28)
	ps.shadow_color = Color(0, 0, 0, 0.5)
	ps.shadow_size = 12
	panel.add_theme_stylebox_override("panel", ps)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	panel.add_child(v)

	v.add_child(_lbl("— ASCENSION —", 20, C_BRONZE))
	v.add_child(_gap(16))

	var ar := HBoxContainer.new()
	ar.alignment = BoxContainer.ALIGNMENT_CENTER
	ar.add_theme_constant_override("separation", 24)
	v.add_child(ar)

	_asc_down = _make_step("−")
	_asc_down.pressed.connect(func() -> void: _change_ascension(-1))
	ar.add_child(_asc_down)

	_asc_num = _lbl("0", 72, C_GOLD)
	_asc_num.custom_minimum_size = Vector2(120, 0)
	ar.add_child(_asc_num)

	_asc_up = _make_step("+")
	_asc_up.pressed.connect(func() -> void: _change_ascension(1))
	ar.add_child(_asc_up)

	v.add_child(_gap(10))
	_asc_desc = _lbl("Normal — the first descent.", 22, C_INK_MUTE)
	v.add_child(_asc_desc)
	v.add_child(_gap(24))

	var pd := DividerLine.new()
	pd.custom_minimum_size = Vector2(0, 16)
	pd.line_color = C_BRONZE_LINE
	pd.diamond_color = C_BRONZE
	v.add_child(pd)
	v.add_child(_gap(24))

	v.add_child(_lbl("— STARTING REGION —", 20, C_BRONZE))
	v.add_child(_gap(16))

	var rr := HBoxContainer.new()
	rr.add_theme_constant_override("separation", 12)
	v.add_child(rr)

	_region_prev = _make_arrow("‹")
	_region_prev.pressed.connect(func() -> void: _change_region(-1))
	rr.add_child(_region_prev)

	var region_box := PanelContainer.new()
	region_box.size_flags_horizontal = SIZE_EXPAND_FILL
	var rbs := StyleBoxFlat.new()
	rbs.bg_color = Color(0.08, 0.06, 0.04)
	rbs.border_color = C_BRONZE_LINE
	rbs.set_border_width_all(1)
	rbs.set_content_margin_all(14)
	region_box.add_theme_stylebox_override("panel", rbs)
	rr.add_child(region_box)

	_region_name = _lbl("DEFAULT", 30, C_INK)
	region_box.add_child(_region_name)

	_region_next = _make_arrow("›")
	_region_next.pressed.connect(func() -> void: _change_region(1))
	rr.add_child(_region_next)

	v.add_child(_gap(10))
	_region_desc = _lbl("", 20, C_INK_LOW)
	_region_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_region_desc)

	return panel

func _build_actions(parent: Control) -> void:
	var start := _make_cta("START RUN", 40)
	start.custom_minimum_size.y = 120
	start.pressed.connect(func() -> void: start_pressed.emit())
	parent.add_child(start)
	parent.add_child(_gap(14))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)

	var unlocks := _make_ghost("◇  UNLOCKS", 28)
	unlocks.size_flags_horizontal = SIZE_EXPAND_FILL
	unlocks.custom_minimum_size.y = 80
	unlocks.pressed.connect(func() -> void: unlocks_pressed.emit())
	row.add_child(unlocks)

	var codex := _make_ghost("❖  CODEX", 28)
	codex.size_flags_horizontal = SIZE_EXPAND_FILL
	codex.custom_minimum_size.y = 80
	codex.pressed.connect(func() -> void: codex_pressed.emit())
	row.add_child(codex)

func _build_footer(parent: Control) -> void:
	var bar := HBoxContainer.new()
	parent.add_child(bar)
	var left := _lbl("V0.4.2 ▮ BUILD 1840", 16, C_INK_LOW, HORIZONTAL_ALIGNMENT_LEFT)
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.uppercase = true
	bar.add_child(left)
	var right := _lbl("SETTINGS · ⚙", 16, C_INK_LOW, HORIZONTAL_ALIGNMENT_RIGHT)
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

func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _flex() -> Control:
	var c := Control.new()
	c.size_flags_vertical = SIZE_EXPAND_FILL
	return c

func _sbf(bg: Color, border: Color, bw: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_content_margin_all(12)
	return s

func _make_step(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(80, 80)
	b.add_theme_font_size_override("font_size", 40)
	b.add_theme_color_override("font_color", C_BRONZE_HI)
	b.add_theme_color_override("font_hover_color", C_GOLD)
	b.add_theme_color_override("font_pressed_color", C_INK)
	b.add_theme_color_override("font_disabled_color", C_INK_FAINT)
	b.add_theme_stylebox_override("normal", _sbf(C_BTN_BG, C_BRONZE_LINE))
	b.add_theme_stylebox_override("hover", _sbf(C_BTN_BG.lightened(0.12), C_BRONZE))
	b.add_theme_stylebox_override("pressed", _sbf(C_BTN_BG.darkened(0.05), C_BRONZE_LINE))
	b.add_theme_stylebox_override("disabled", _sbf(C_BTN_BG, C_BRONZE_LINE.darkened(0.3)))
	return b

func _make_arrow(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(70, 70)
	b.add_theme_font_size_override("font_size", 36)
	b.add_theme_color_override("font_color", C_BRONZE_HI)
	b.add_theme_color_override("font_hover_color", C_GOLD)
	b.add_theme_stylebox_override("normal", _sbf(C_BTN_BG, C_BRONZE_LINE))
	b.add_theme_stylebox_override("hover", _sbf(C_BTN_BG.lightened(0.12), C_BRONZE))
	b.add_theme_stylebox_override("pressed", _sbf(C_BTN_BG.darkened(0.05), C_BRONZE_LINE))
	return b

func _make_cta(text: String, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color(0.97, 0.92, 0.80))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.85))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.35, 0.15, 0.06)
	normal.border_color = Color(0.60, 0.30, 0.12)
	normal.set_border_width_all(2)
	normal.set_content_margin_all(16)
	normal.shadow_color = C_EMBER_GLOW
	normal.shadow_size = 20
	b.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.42, 0.20, 0.08)
	hover.border_color = Color(0.65, 0.35, 0.15)
	hover.set_border_width_all(2)
	hover.set_content_margin_all(16)
	hover.shadow_color = C_EMBER_GLOW
	hover.shadow_size = 28
	b.add_theme_stylebox_override("hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.30, 0.12, 0.05)
	pressed.border_color = Color(0.55, 0.28, 0.10)
	pressed.set_border_width_all(2)
	pressed.set_content_margin_all(16)
	pressed.shadow_color = C_EMBER_GLOW
	pressed.shadow_size = 12
	b.add_theme_stylebox_override("pressed", pressed)
	return b

func _make_ghost(text: String, font_size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", C_INK)
	b.add_theme_color_override("font_hover_color", C_BRONZE_HI)
	var bg := Color(0.12, 0.09, 0.06)
	b.add_theme_stylebox_override("normal", _sbf(bg, C_BRONZE_LINE))
	b.add_theme_stylebox_override("hover", _sbf(bg.lightened(0.08), C_BRONZE))
	b.add_theme_stylebox_override("pressed", _sbf(bg.darkened(0.03), C_BRONZE_LINE))
	return b

# --- Game Logic ---

func _load_regions() -> void:
	_region_ids = [""]
	var dir := DirAccess.open("res://resources/regions/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://resources/regions/" + file_name)
			if res is RegionResource:
				_region_ids.append(res.id)
		file_name = dir.get_next()

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
		_region_desc.text = ""
		return
	var rid: String = _region_ids[_region_index]
	if rid.is_empty():
		_region_name.text = "DEFAULT"
		_region_desc.text = "The standard proving grounds."
	else:
		var res := _load_region(rid)
		if res:
			_region_name.text = res.name.to_upper()
			_region_desc.text = res.description if res.description else ""
		else:
			_region_name.text = rid.to_upper()
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
