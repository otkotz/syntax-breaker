class_name SkillManagerUI
extends Control

signal closed

const C_BG := Color(0.06, 0.05, 0.04)
const C_PANEL := Color(0.10, 0.07, 0.05)
const C_BRONZE := Color(0.56, 0.45, 0.28)
const C_BRONZE_HI := Color(0.78, 0.68, 0.48)
const C_BRONZE_LINE := Color(0.38, 0.30, 0.19)
const C_BRONZE_DARK := Color(0.30, 0.24, 0.15)
const C_EMBER := Color(0.78, 0.38, 0.15)
const C_EMBER_GLOW := Color(0.78, 0.38, 0.15, 0.35)
const C_INK := Color(0.92, 0.88, 0.80)
const C_INK_MUTE := Color(0.72, 0.68, 0.58)
const C_INK_LOW := Color(0.50, 0.46, 0.38)
const C_INK_FAINT := Color(0.35, 0.32, 0.26)
const C_GOLD := Color(0.94, 0.87, 0.65)
const C_CARD_BG := Color(0.08, 0.06, 0.04, 0.75)
const C_STAT_BG := Color(0.0, 0.0, 0.0, 0.3)

const C_STR := Color(0.75, 0.30, 0.18)
const C_DEX := Color(0.40, 0.78, 0.40)
const C_INT := Color(0.45, 0.55, 0.85)

var _skill_instances: Array[SkillInstance] = []
var _available_supports: Array[SupportResource] = []
var _active_slot: Dictionary = {}

var _scroller: ScrollContainer
var _scroll_vbox: VBoxContainer
var _drawer_scrim: ColorRect
var _drawer: PanelContainer
var _drawer_list: VBoxContainer
var _drawer_title: Label
var _drawer_sub: Label
var _drawer_actions: HBoxContainer
var _footer_stage_lbl: Label
var _footer_linked_lbl: Label

func open(skill_instances: Array[SkillInstance], supports: Array) -> void:
	_skill_instances = skill_instances
	_available_supports = []
	for s in supports:
		if s is SupportResource:
			_available_supports.append(s)
	_active_slot = {}
	_rebuild_ui()
	show()

func _ready() -> void:
	_build_ui()

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
	_scroller = ScrollContainer.new()
	_scroller.size_flags_vertical = SIZE_EXPAND_FILL
	_scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroller)

	_scroll_vbox = VBoxContainer.new()
	_scroll_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll_vbox.add_theme_constant_override("separation", 14)
	var scroll_margin := MarginContainer.new()
	scroll_margin.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll_margin.add_theme_constant_override("margin_left", 14)
	scroll_margin.add_theme_constant_override("margin_right", 14)
	scroll_margin.add_theme_constant_override("margin_top", 16)
	scroll_margin.add_theme_constant_override("margin_bottom", 12)
	scroll_margin.add_child(_scroll_vbox)
	_scroller.add_child(scroll_margin)

	_build_footer(root)
	_build_drawer()

func _build_header(parent: Control) -> void:
	var header := PanelContainer.new()
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.09, 0.07, 0.05)
	hs.border_color = C_BRONZE_LINE
	hs.border_width_bottom = 1
	hs.set_content_margin_all(0)
	hs.content_margin_left = 16
	hs.content_margin_right = 16
	hs.content_margin_top = 16
	hs.content_margin_bottom = 12
	header.add_theme_stylebox_override("panel", hs)
	parent.add_child(header)

	var hbox := VBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	header.add_child(hbox)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(row)

	var back_btn := _make_icon_btn("‹")
	back_btn.pressed.connect(func() -> void: _close())
	row.add_child(back_btn)

	var title := Label.new()
	title.text = "SKILLS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", C_GOLD)
	title.uppercase = true
	row.add_child(title)

	var help_btn := _make_icon_btn("?")
	row.add_child(help_btn)

	var sub := Label.new()
	sub.text = "— TAP A SLOT TO LINK OR SWAP —"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", C_INK_LOW)
	sub.uppercase = true
	hbox.add_child(sub)

func _build_footer(parent: Control) -> void:
	var footer := PanelContainer.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0.07, 0.06, 0.04)
	fs.border_color = C_BRONZE_LINE
	fs.border_width_top = 1
	fs.set_content_margin_all(0)
	fs.content_margin_left = 16
	fs.content_margin_right = 16
	fs.content_margin_top = 14
	fs.content_margin_bottom = 16
	footer.add_theme_stylebox_override("panel", fs)
	parent.add_child(footer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	footer.add_child(vbox)

	var meta := HBoxContainer.new()
	vbox.add_child(meta)
	_footer_stage_lbl = Label.new()
	_footer_stage_lbl.text = ""
	_footer_stage_lbl.add_theme_font_size_override("font_size", 18)
	_footer_stage_lbl.add_theme_color_override("font_color", C_INK_LOW)
	_footer_stage_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	meta.add_child(_footer_stage_lbl)

	_footer_linked_lbl = Label.new()
	_footer_linked_lbl.text = ""
	_footer_linked_lbl.add_theme_font_size_override("font_size", 18)
	_footer_linked_lbl.add_theme_color_override("font_color", C_INK_LOW)
	meta.add_child(_footer_linked_lbl)

	var done_btn := _make_cta("RESUME", 24)
	done_btn.custom_minimum_size.y = 56
	done_btn.pressed.connect(func() -> void: _close())
	vbox.add_child(done_btn)

func _build_drawer() -> void:
	_drawer_scrim = ColorRect.new()
	_drawer_scrim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_drawer_scrim.color = Color(0, 0, 0, 0.65)
	_drawer_scrim.visible = false
	_drawer_scrim.mouse_filter = MOUSE_FILTER_STOP
	_drawer_scrim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_drawer()
	)
	add_child(_drawer_scrim)

	_drawer = PanelContainer.new()
	_drawer.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	_drawer.anchor_top = 0.35
	_drawer.visible = false
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.09, 0.07, 0.05)
	ds.border_color = C_BRONZE_LINE
	ds.border_width_top = 1
	ds.set_content_margin_all(0)
	ds.content_margin_left = 16
	ds.content_margin_right = 16
	ds.content_margin_top = 14
	ds.content_margin_bottom = 18
	ds.shadow_color = Color(0, 0, 0, 0.7)
	ds.shadow_size = 30
	ds.shadow_offset = Vector2(0, -10)
	_drawer.add_theme_stylebox_override("panel", ds)
	add_child(_drawer)

	var drawer_scroll := ScrollContainer.new()
	drawer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	drawer_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_drawer.add_child(drawer_scroll)

	var drawer_content := VBoxContainer.new()
	drawer_content.size_flags_horizontal = SIZE_EXPAND_FILL
	drawer_content.add_theme_constant_override("separation", 0)
	drawer_scroll.add_child(drawer_content)

	var handle := ColorRect.new()
	handle.custom_minimum_size = Vector2(56, 4)
	handle.color = C_BRONZE
	handle.modulate.a = 0.6
	handle.size_flags_horizontal = SIZE_SHRINK_CENTER
	drawer_content.add_child(handle)
	drawer_content.add_child(_gap(12))

	_drawer_title = Label.new()
	_drawer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drawer_title.add_theme_font_size_override("font_size", 22)
	_drawer_title.add_theme_color_override("font_color", C_BRONZE_HI)
	_drawer_title.uppercase = true
	drawer_content.add_child(_drawer_title)

	_drawer_sub = Label.new()
	_drawer_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drawer_sub.add_theme_font_size_override("font_size", 16)
	_drawer_sub.add_theme_color_override("font_color", C_INK_LOW)
	_drawer_sub.uppercase = true
	drawer_content.add_child(_drawer_sub)
	drawer_content.add_child(_gap(14))

	_drawer_list = VBoxContainer.new()
	_drawer_list.add_theme_constant_override("separation", 8)
	_drawer_list.size_flags_horizontal = SIZE_EXPAND_FILL
	drawer_content.add_child(_drawer_list)

	drawer_content.add_child(_gap(14))
	_drawer_actions = HBoxContainer.new()
	_drawer_actions.add_theme_constant_override("separation", 10)
	drawer_content.add_child(_drawer_actions)

func _rebuild_ui() -> void:
	_clear_children(_scroll_vbox)
	_build_section_label(_scroll_vbox, "ACTIVE SKILLS", str(_skill_instances.size()))
	for si in _skill_instances:
		_build_skill_card(_scroll_vbox, si)
	_build_section_label(_scroll_vbox, "UNLINKED SUPPORTS", str(_available_supports.size()))
	_build_inventory(_scroll_vbox)
	_update_footer()

func _update_footer() -> void:
	_footer_stage_lbl.text = "STAGE %d/%d" % [RunManager.current_stage, StageGenerator.MAX_DEPTH]
	var linked_count := 0
	var total_sockets := 0
	for si in _skill_instances:
		total_sockets += si.base.max_supports
		linked_count += si.linked_supports.size()
	_footer_linked_lbl.text = "%d/%d LINKED" % [linked_count, total_sockets]

func _build_section_label(parent: Control, text: String, count: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)

	var line_l := ColorRect.new()
	line_l.color = C_BRONZE_LINE
	line_l.custom_minimum_size = Vector2(0, 1)
	line_l.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(line_l)

	var lbl := Label.new()
	lbl.text = "%s · %s" % [text, count]
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", C_BRONZE)
	lbl.uppercase = true
	hbox.add_child(lbl)

	var line_r := ColorRect.new()
	line_r.color = C_BRONZE_LINE
	line_r.custom_minimum_size = Vector2(0, 1)
	line_r.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(line_r)

func _build_skill_card(parent: Control, si: SkillInstance) -> void:
	var card_color := _get_skill_color(si)

	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = C_CARD_BG
	cs.border_color = C_BRONZE_LINE
	cs.set_border_width_all(1)
	cs.border_width_left = 3
	cs.set_content_margin_all(14)
	cs.content_margin_bottom = 16
	cs.shadow_color = Color(0, 0, 0, 0.35)
	cs.shadow_size = 8
	card.add_theme_stylebox_override("panel", cs)

	parent.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	card.add_child(vbox)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	vbox.add_child(head)

	var gem := _build_gem_main(card_color)
	head.add_child(gem)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 5)
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = si.base.name
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", card_color)
	info.add_child(name_lbl)

	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 5)
	info.add_child(tag_row)
	for i in si.base.tags.size():
		var tag_text: String = si.base.tags[i]
		var pill := _make_pill(tag_text, i == 0, card_color)
		tag_row.add_child(pill)

	vbox.add_child(_gap(12))

	var stats_panel := PanelContainer.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = C_STAT_BG
	ss.border_color = C_BRONZE_LINE
	ss.border_width_top = 1
	ss.border_width_bottom = 1
	ss.set_content_margin_all(10)
	ss.content_margin_left = 12
	ss.content_margin_right = 12
	stats_panel.add_theme_stylebox_override("panel", ss)
	vbox.add_child(stats_panel)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 20)
	stats_panel.add_child(stats_row)

	var damage: float = si.computed_stats.get("damage", si.base.base_damage)
	var cooldown: float = si.computed_stats.get("cooldown", si.base.base_cooldown)
	var proj_range: float = si.computed_stats.get("range", si.base.base_range)
	var dps := damage / maxf(cooldown, 0.01)
	_add_stat(stats_row, "DPS", str(roundi(dps)))
	_add_stat(stats_row, "CD", "%.2fs" % cooldown)
	_add_stat(stats_row, "RNG", str(roundi(proj_range)))

	vbox.add_child(_gap(14))

	var socket_label := Label.new()
	socket_label.text = "— SUPPORTS · %d/%d —" % [si.linked_supports.size(), si.base.max_supports]
	socket_label.add_theme_font_size_override("font_size", 16)
	socket_label.add_theme_color_override("font_color", C_INK_LOW)
	socket_label.uppercase = true
	vbox.add_child(socket_label)
	vbox.add_child(_gap(8))

	var socket_list := VBoxContainer.new()
	socket_list.add_theme_constant_override("separation", 6)
	vbox.add_child(socket_list)

	for i in si.base.max_supports:
		var filled: bool = i < si.linked_supports.size()
		var support: SupportResource = si.linked_supports[i] if filled else null
		var slot_btn := _build_slot_row(filled, support, card_color)
		slot_btn.pressed.connect(_on_slot_clicked.bind(si, i))
		socket_list.add_child(slot_btn)

func _build_gem_main(color: Color) -> PanelContainer:
	var container := PanelContainer.new()
	container.custom_minimum_size = Vector2(56, 56)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(color, 0.12)
	ps.border_color = Color(color, 0.6)
	ps.set_border_width_all(2)
	ps.set_content_margin_all(0)
	ps.shadow_color = Color(color, 0.25)
	ps.shadow_size = 8
	container.add_theme_stylebox_override("panel", ps)
	return container

func _build_slot_row(filled: bool, support: SupportResource, _skill_color: Color) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var color := _get_support_color(support) if filled else C_BRONZE_DARK
	var border := color if filled else C_BRONZE_DARK

	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0.05, 0.04, 0.03)
	ns.border_color = border
	ns.set_border_width_all(1)
	ns.border_width_left = 3
	ns.set_content_margin_all(10)
	ns.content_margin_left = 14
	btn.add_theme_stylebox_override("normal", ns)

	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.08, 0.06, 0.05)
	hs.border_color = border.lightened(0.2)
	hs.set_border_width_all(1)
	hs.border_width_left = 3
	hs.set_content_margin_all(10)
	hs.content_margin_left = 14
	btn.add_theme_stylebox_override("hover", hs)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.03, 0.02, 0.02)
	ps.border_color = border
	ps.set_border_width_all(1)
	ps.border_width_left = 3
	ps.set_content_margin_all(10)
	ps.content_margin_left = 14
	btn.add_theme_stylebox_override("pressed", ps)

	if filled:
		var q: int = RunManager.get_support_quality(support.id)
		var q_str := "  Q%d" % q if q > 0 else ""
		btn.text = support.name + q_str
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", color)
		btn.add_theme_color_override("font_hover_color", color.lightened(0.2))
	else:
		btn.text = "+ Empty Socket"
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color", C_INK_FAINT)
		btn.add_theme_color_override("font_hover_color", C_BRONZE)

	return btn

func _build_inventory(parent: Control) -> void:
	if _available_supports.is_empty():
		var empty := Label.new()
		empty.text = "No unlinked supports yet."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 20)
		empty.add_theme_color_override("font_color", C_INK_FAINT)
		parent.add_child(empty)
		return

	var inv_list := VBoxContainer.new()
	inv_list.add_theme_constant_override("separation", 6)
	parent.add_child(inv_list)

	for support in _available_supports:
		var item := _build_inv_item(support)
		inv_list.add_child(item)

func _build_inv_item(support: SupportResource) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 64)
	btn.size_flags_horizontal = SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var color := _get_support_color(support)
	var q: int = RunManager.get_support_quality(support.id)
	var q_str := "  Q%d" % q if q > 0 else ""
	btn.text = support.name + q_str + "\n" + support.description
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", color.lightened(0.2))

	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0, 0, 0, 0.35)
	ns.border_color = C_BRONZE_LINE
	ns.set_border_width_all(1)
	ns.border_width_left = 3
	ns.set_content_margin_all(10)
	ns.content_margin_left = 14
	btn.add_theme_stylebox_override("normal", ns)

	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0, 0, 0, 0.5)
	hs.border_color = C_BRONZE_HI
	hs.set_border_width_all(1)
	hs.border_width_left = 3
	hs.set_content_margin_all(10)
	hs.content_margin_left = 14
	btn.add_theme_stylebox_override("hover", hs)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0, 0, 0, 0.5)
	ps.border_color = color
	ps.set_border_width_all(1)
	ps.border_width_left = 3
	ps.set_content_margin_all(10)
	ps.content_margin_left = 14
	btn.add_theme_stylebox_override("pressed", ps)

	btn.pressed.connect(func() -> void:
		_show_support_info_drawer(support)
	)
	return btn

func _on_slot_clicked(si: SkillInstance, index: int) -> void:
	_active_slot = {"skill": si, "index": index}
	_show_drawer()

func _show_drawer() -> void:
	var si: SkillInstance = _active_slot["skill"]
	var index: int = _active_slot["index"]
	var has_support := index < si.linked_supports.size()
	var current_support: SupportResource = si.linked_supports[index] if has_support else null

	_clear_children(_drawer_list)
	_clear_children(_drawer_actions)

	if current_support:
		_drawer_title.text = "SLOTTED SUPPORT"
		_drawer_sub.text = "REPLACE, OR REMOVE FROM SOCKET"
	else:
		_drawer_title.text = "CHOOSE A SUPPORT"
		_drawer_sub.text = "UNLINKED SUPPORTS IN YOUR STASH"

	if current_support:
		var current_item := _build_drawer_item(current_support, true)
		_drawer_list.add_child(current_item)
		var sep := HSeparator.new()
		sep.add_theme_stylebox_override("separator", StyleBoxLine.new())
		_drawer_list.add_child(sep)

	var compatible := TagMatcher.get_linkable_supports(si.base, _available_supports)
	if compatible.is_empty() and not current_support:
		var empty := Label.new()
		empty.text = "No supports remain. Find more on your descent."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 20)
		empty.add_theme_color_override("font_color", C_INK_FAINT)
		_drawer_list.add_child(empty)
	else:
		for support: SupportResource in compatible:
			var item := _build_drawer_item(support, false)
			item.pressed.connect(_assign_to_slot.bind(si, index, support, current_support))
			_drawer_list.add_child(item)

	var cancel_btn := _make_drawer_btn("CANCEL", false)
	cancel_btn.pressed.connect(func() -> void: _close_drawer())
	_drawer_actions.add_child(cancel_btn)

	if current_support:
		var remove_btn := _make_drawer_btn("REMOVE GEM", true)
		remove_btn.pressed.connect(_remove_from_slot.bind(si, current_support))
		_drawer_actions.add_child(remove_btn)
	else:
		var empty_btn := _make_drawer_btn("EMPTY", false)
		empty_btn.disabled = true
		empty_btn.modulate.a = 0.4
		_drawer_actions.add_child(empty_btn)

	_drawer_scrim.visible = true
	_drawer.visible = true

func _show_support_info_drawer(support: SupportResource) -> void:
	_clear_children(_drawer_list)
	_clear_children(_drawer_actions)

	_drawer_title.text = support.name.to_upper()
	_drawer_sub.text = "UNLINKED SUPPORT"

	var desc := Label.new()
	desc.text = support.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", C_INK_MUTE)
	_drawer_list.add_child(desc)

	var q: int = RunManager.get_support_quality(support.id)
	if q > 0:
		var q_lbl := Label.new()
		q_lbl.text = "Quality: %d" % q
		q_lbl.add_theme_font_size_override("font_size", 20)
		q_lbl.add_theme_color_override("font_color", C_BRONZE)
		_drawer_list.add_child(q_lbl)

	if RunManager.is_support_max_quality(support.id):
		var bonus := Label.new()
		bonus.text = "MAX: " + StatCalculator.get_max_quality_description(support.id)
		bonus.add_theme_font_size_override("font_size", 20)
		bonus.add_theme_color_override("font_color", C_GOLD)
		bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_drawer_list.add_child(bonus)

	var cancel_btn := _make_drawer_btn("CLOSE", false)
	cancel_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(func() -> void: _close_drawer())
	_drawer_actions.add_child(cancel_btn)

	_drawer_scrim.visible = true
	_drawer.visible = true

func _build_drawer_item(support: SupportResource, is_current: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 70)
	btn.size_flags_horizontal = SIZE_EXPAND_FILL

	var color := _get_support_color(support)
	var q: int = RunManager.get_support_quality(support.id)
	var q_str := "  Q%d" % q if q > 0 else ""
	var current_marker := "  [current]" if is_current else ""
	btn.text = support.name + q_str + current_marker + "\n" + support.description
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", color.lightened(0.2))

	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0, 0, 0, 0.35)
	ns.border_color = C_BRONZE_LINE
	ns.set_border_width_all(1)
	ns.border_width_left = 3
	ns.set_content_margin_all(10)
	ns.content_margin_left = 14
	btn.add_theme_stylebox_override("normal", ns)

	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0, 0, 0, 0.5)
	hs.border_color = color
	hs.set_border_width_all(1)
	hs.border_width_left = 3
	hs.set_content_margin_all(10)
	hs.content_margin_left = 14
	btn.add_theme_stylebox_override("hover", hs)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0, 0, 0, 0.6)
	ps.border_color = color.darkened(0.2)
	ps.set_border_width_all(1)
	ps.border_width_left = 3
	ps.set_content_margin_all(10)
	ps.content_margin_left = 14
	btn.add_theme_stylebox_override("pressed", ps)

	return btn

func _close_drawer() -> void:
	_active_slot = {}
	_drawer_scrim.visible = false
	_drawer.visible = false

func _close() -> void:
	_close_drawer()
	closed.emit()
	hide()

# --- Assignment Logic ---

func _assign_to_slot(si: SkillInstance, index: int, new_support: SupportResource, old_support: SupportResource) -> void:
	if old_support:
		si.unlink_support(old_support)
		_available_supports.append(old_support)
	_available_supports.erase(new_support)
	si.linked_supports.insert(mini(index, si.linked_supports.size()), new_support)
	si.recompute(RunManager.owned_passives)
	_close_drawer()
	_rebuild_ui()

func _remove_from_slot(si: SkillInstance, support: SupportResource) -> void:
	si.unlink_support(support)
	_available_supports.append(support)
	si.recompute(RunManager.owned_passives)
	_close_drawer()
	_rebuild_ui()

# --- Helpers ---

func _make_pill(text: String, is_primary: bool, card_color: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0, 0, 0, 0.4)
	ps.border_color = C_BRONZE_LINE if not is_primary else Color(card_color, 0.85)
	ps.set_border_width_all(1)
	ps.content_margin_left = 7
	ps.content_margin_right = 7
	ps.content_margin_top = 2
	ps.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", ps)

	var lbl := Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", C_INK_LOW if not is_primary else card_color)
	pill.add_child(lbl)
	return pill

func _add_stat(parent: Control, key: String, value: String) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	parent.add_child(vbox)

	var k := Label.new()
	k.text = key
	k.add_theme_font_size_override("font_size", 14)
	k.add_theme_color_override("font_color", C_INK_FAINT)
	k.uppercase = true
	vbox.add_child(k)

	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 22)
	v.add_theme_color_override("font_color", C_INK)
	vbox.add_child(v)

func _make_icon_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(44, 44)
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", C_BRONZE_HI)
	b.add_theme_color_override("font_hover_color", C_GOLD)
	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0.14, 0.11, 0.08)
	ns.border_color = C_BRONZE_LINE
	ns.set_border_width_all(1)
	ns.set_content_margin_all(4)
	b.add_theme_stylebox_override("normal", ns)
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.18, 0.14, 0.10)
	hs.border_color = C_BRONZE
	hs.set_border_width_all(1)
	hs.set_content_margin_all(4)
	b.add_theme_stylebox_override("hover", hs)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.08, 0.06)
	ps.border_color = C_BRONZE_LINE
	ps.set_border_width_all(1)
	ps.set_content_margin_all(4)
	b.add_theme_stylebox_override("pressed", ps)
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
	normal.set_content_margin_all(12)
	normal.shadow_color = C_EMBER_GLOW
	normal.shadow_size = 20
	b.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.42, 0.20, 0.08)
	hover.border_color = Color(0.65, 0.35, 0.15)
	hover.set_border_width_all(2)
	hover.set_content_margin_all(12)
	hover.shadow_color = C_EMBER_GLOW
	hover.shadow_size = 28
	b.add_theme_stylebox_override("hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.30, 0.12, 0.05)
	pressed.border_color = Color(0.55, 0.28, 0.10)
	pressed.set_border_width_all(2)
	pressed.set_content_margin_all(12)
	pressed.shadow_color = C_EMBER_GLOW
	pressed.shadow_size = 12
	b.add_theme_stylebox_override("pressed", pressed)
	return b

func _make_drawer_btn(text: String, is_danger: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color(0.80, 0.30, 0.18) if is_danger else C_INK)
	b.add_theme_color_override("font_hover_color", Color(0.90, 0.40, 0.25) if is_danger else C_BRONZE_HI)
	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0.12, 0.09, 0.06)
	ns.border_color = C_BRONZE_LINE
	ns.set_border_width_all(1)
	ns.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", ns)
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.16, 0.12, 0.08)
	hs.border_color = C_BRONZE
	hs.set_border_width_all(1)
	hs.set_content_margin_all(8)
	b.add_theme_stylebox_override("hover", hs)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.08, 0.06, 0.04)
	ps.border_color = C_BRONZE_LINE
	ps.set_border_width_all(1)
	ps.set_content_margin_all(8)
	b.add_theme_stylebox_override("pressed", ps)
	return b

func _gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _get_skill_color(si: SkillInstance) -> Color:
	if si.base.tags.has("fire"):
		return C_STR
	elif si.base.tags.has("lightning") or si.base.tags.has("spell"):
		return C_INT
	elif si.base.tags.has("melee") or si.base.tags.has("projectile"):
		return C_DEX
	return C_BRONZE

func _get_support_color(support: SupportResource) -> Color:
	if support.required_tags.has("projectile") or support.required_tags.has("melee"):
		return C_DEX
	elif support.required_tags.has("spell") or support.required_tags.has("lightning"):
		return C_INT
	elif support.required_tags.has("fire"):
		return C_STR
	if support.added_tags.has("poison") or support.behavior_key == "poison":
		return C_DEX
	return C_BRONZE

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
