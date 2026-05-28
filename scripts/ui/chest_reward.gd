class_name ChestReward
extends Control

signal item_chosen(index: int)

var _items: Array[Dictionary] = []
var _is_boss: bool = false
var _title_text: String = ""
var _phase := 0
var _cards: Array[PanelContainer] = []
var _bg: ColorRect
var _flash: ColorRect
var _chest: Control
var _glow_ring: Control
var _sparkle_layer: Control
var _tap_label: Label
var _title_label: Label
var _card_box: VBoxContainer
var _pulse_tween: Tween
var _breathe_tween: Tween
var _glitch_tween: Tween
var _vp: Vector2

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_viewport().set_input_as_handled()

func setup(items: Array[Dictionary], is_boss: bool = false, title: String = "") -> void:
	_items = items
	_is_boss = is_boss
	_title_text = title if not title.is_empty() else ("BOSS LOOT" if is_boss else "RARE LOOT")
	_vp = get_viewport_rect().size
	if _vp == Vector2.ZERO:
		_vp = Vector2(1080, 1920)
	_build()
	_play_entrance()

func _build() -> void:
	mouse_filter = MOUSE_FILTER_STOP

	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_bg.color = Color(0, 0, 0, 0)
	_bg.mouse_filter = MOUSE_FILTER_PASS
	add_child(_bg)

	_glow_ring = _GlowRing.new()
	_glow_ring.is_boss = _is_boss
	_glow_ring.position = Vector2(_vp.x / 2 - 240, _vp.y * 0.33 - 240)
	_glow_ring.size = Vector2(480, 480)
	_glow_ring.modulate.a = 0
	_glow_ring.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_glow_ring)

	_sparkle_layer = Control.new()
	_sparkle_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_sparkle_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_sparkle_layer)

	var chest_w := 180.0
	var chest_h := 180.0
	_chest = _ChestVisual.new()
	(_chest as _ChestVisual).is_boss = _is_boss
	_chest.position = Vector2(_vp.x / 2 - chest_w / 2, _vp.y * 0.33 - chest_h / 2)
	_chest.size = Vector2(chest_w, chest_h)
	_chest.pivot_offset = Vector2(chest_w / 2, chest_h / 2)
	_chest.modulate.a = 0
	_chest.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_chest)

	_tap_label = Label.new()
	_tap_label.text = "TAP TO OPEN"
	_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_label.add_theme_font_size_override("font_size", 36)
	var tap_color := Color(1.0, 0.85, 0.4) if _is_boss else UITheme.C_V_BRIGHT
	_tap_label.add_theme_color_override("font_color", tap_color)
	_tap_label.position = Vector2(_vp.x / 2 - 200, _vp.y * 0.33 + chest_h / 2 + 30)
	_tap_label.size = Vector2(400, 50)
	_tap_label.modulate.a = 0
	_tap_label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_tap_label)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.text = _title_text
	_title_label.add_theme_font_size_override("font_size", 52)
	var title_color := UITheme.C_RARITY_LEGENDARY if _is_boss else UITheme.C_V_BRIGHT
	_title_label.add_theme_color_override("font_color", title_color)
	_title_label.position = Vector2(40, 60)
	_title_label.size = Vector2(_vp.x - 80, 70)
	_title_label.modulate.a = 0
	_title_label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_title_label)

	_card_box = VBoxContainer.new()
	_card_box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_card_box.offset_top = 150
	_card_box.offset_bottom = -40
	_card_box.offset_left = 40
	_card_box.offset_right = -40
	_card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_box.add_theme_constant_override("separation", 16)
	_card_box.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_card_box)

	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_flash.color = Color(1, 0.9, 0.6, 0) if _is_boss else Color(0.7, 0.5, 1.0, 0)
	_flash.mouse_filter = MOUSE_FILTER_IGNORE
	_flash.z_index = 5
	add_child(_flash)

func _play_entrance() -> void:
	_phase = 0
	var tw := create_tween()
	tw.tween_property(_bg, "color", Color(0.01, 0.005, 0.02, 0.97), 0.5)
	tw.parallel().tween_property(_glow_ring, "modulate:a", 0.8, 0.8).set_delay(0.2)

	tw.tween_property(_chest, "modulate:a", 1.0, 0.01)
	_chest.scale = Vector2(0.1, 0.1)
	tw.tween_property(_chest, "scale", Vector2(1.2, 0.75), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_chest, "scale", Vector2(0.85, 1.15), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_chest, "scale", Vector2(1.05, 0.95), 0.08)
	tw.tween_property(_chest, "scale", Vector2(1.0, 1.0), 0.06)

	tw.tween_property(_tap_label, "modulate:a", 1.0, 0.3)
	tw.tween_callback(func():
		_phase = 1
		_start_idle_effects()
	)

func _start_idle_effects() -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_tap_label, "modulate:a", 0.2, 0.8).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_tap_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

	_breathe_tween = create_tween().set_loops()
	_breathe_tween.tween_property(_chest, "scale", Vector2(1.03, 1.06), 1.2).set_trans(Tween.TRANS_SINE)
	_breathe_tween.tween_property(_chest, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE)

	_glitch_tween = create_tween().set_loops()
	_glitch_tween.tween_interval(randf_range(0.8, 2.5))
	_glitch_tween.tween_callback(_do_glitch)
	_glitch_tween.tween_interval(0.15)
	_glitch_tween.tween_callback(func(): _chest.position.x = _vp.x / 2 - 90)

	_spawn_idle_sparkles()

func _do_glitch() -> void:
	if _phase != 1:
		return
	var offset := randf_range(-6, 6)
	_chest.position.x += offset
	var glitch_color := Color(1.3, 1.0, 0.7) if _is_boss else Color(1.0, 0.8, 1.3)
	_chest.modulate = glitch_color
	var restore := create_tween()
	restore.tween_property(_chest, "modulate", Color.WHITE, 0.1)

func _spawn_idle_sparkles() -> void:
	if _phase != 1:
		return
	var center := Vector2(_vp.x / 2, _vp.y * 0.33)
	var accent := Color(1.0, 0.9, 0.4, 0.8) if _is_boss else Color(0.7, 0.5, 1.0, 0.8)
	for i in 6:
		_spawn_one_sparkle(center, accent, randf_range(0.0, 1.5))
	var timer := Timer.new()
	timer.wait_time = 0.4
	timer.timeout.connect(func():
		if _phase == 1:
			_spawn_one_sparkle(center, accent, 0.0)
		else:
			timer.queue_free()
	)
	add_child(timer)
	timer.start()

func _spawn_one_sparkle(center: Vector2, accent: Color, delay: float) -> void:
	var s := ColorRect.new()
	var sz := randf_range(2, 5)
	s.size = Vector2(sz, sz)
	var angle := randf() * TAU
	var dist := randf_range(50, 130)
	var start := center + Vector2(cos(angle), sin(angle)) * dist
	s.position = start
	s.color = accent.lerp(Color.WHITE, randf_range(0.2, 0.7))
	s.modulate.a = 0
	s.mouse_filter = MOUSE_FILTER_IGNORE
	_sparkle_layer.add_child(s)

	var tw := create_tween()
	var drift := Vector2(randf_range(-20, 20), randf_range(-40, -15))
	tw.tween_interval(delay)
	tw.tween_property(s, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(s, "position", start + drift, 1.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(s, "modulate:a", 0.0, 0.3)
	tw.tween_callback(s.queue_free)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _phase == 1:
			accept_event()
			_open_chest()
		elif _phase >= 2:
			accept_event()

func _open_chest() -> void:
	_phase = 2

	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	if _breathe_tween and _breathe_tween.is_valid():
		_breathe_tween.kill()
	if _glitch_tween and _glitch_tween.is_valid():
		_glitch_tween.kill()
	_tap_label.visible = false

	for child in _sparkle_layer.get_children():
		child.queue_free()

	_spawn_burst_particles()

	_chest.scale = Vector2(1.0, 1.0)
	_chest.modulate = Color.WHITE
	var tw := create_tween()
	tw.tween_property(_chest, "scale", Vector2(1.4, 1.5), 0.1)
	tw.parallel().tween_property(_flash, "color:a", 0.9, 0.1)

	tw.tween_property(_flash, "color:a", 0.0, 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_chest, "scale", Vector2(1.0, 1.0), 0.2)

	tw.tween_interval(0.1)

	_title_label.pivot_offset = _title_label.size / 2
	_title_label.scale = Vector2(0.5, 0.5)
	tw.tween_property(_title_label, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(_title_label, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tw.parallel().tween_property(_chest, "modulate:a", 0.0, 0.5).set_delay(0.05)
	tw.parallel().tween_property(_glow_ring, "modulate:a", 0.0, 0.5).set_delay(0.05)

	tw.tween_callback(func():
		_chest.visible = false
		_glow_ring.visible = false
		_sparkle_layer.visible = false
		_reveal_cards()
	)

func _spawn_burst_particles() -> void:
	var center := Vector2(_vp.x / 2, _vp.y * 0.33)
	var accent := Color(1.0, 0.85, 0.3) if _is_boss else Color(0.6, 0.4, 1.0)
	for i in 32:
		var p := ColorRect.new()
		var sz := randf_range(3, 12)
		p.size = Vector2(sz, sz)
		p.color = accent.lerp(Color.WHITE, randf_range(0.0, 0.6))
		p.position = center - p.size / 2
		p.mouse_filter = MOUSE_FILTER_IGNORE
		p.z_index = 4
		add_child(p)

		var angle := randf() * TAU
		var dist := randf_range(180, 500)
		var dest := center + Vector2(cos(angle), sin(angle)) * dist
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", dest, randf_range(0.5, 1.0)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, randf_range(0.5, 0.9)).set_delay(0.15)
		tw.tween_property(p, "size", Vector2.ZERO, 0.8)
		tw.chain().tween_callback(p.queue_free)

func _reveal_cards() -> void:
	_phase = 3
	_cards.clear()

	for i in _items.size():
		var card := _build_card(_items[i], i)
		_card_box.add_child(card)
		card.modulate.a = 0
		card.scale = Vector2(0.7, 0.01)
		card.pivot_offset = Vector2(200, 70)
		_cards.append(card)

	await get_tree().process_frame
	await get_tree().process_frame

	var tw := create_tween()
	for i in _cards.size():
		var card := _cards[i]
		card.pivot_offset = card.size / 2
		var d := i * 0.2
		tw.parallel().tween_property(card, "modulate:a", 1.0, 0.3).set_delay(d)
		tw.parallel().tween_property(card, "scale", Vector2(1.06, 1.06), 0.35).set_delay(d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.12).set_delay(d + 0.35)

	tw.tween_callback(func():
		_phase = 4
		_pulse_cards()
	)

func _pulse_cards() -> void:
	for card in _cards:
		var sb: StyleBoxFlat = card.get_theme_stylebox("panel")
		if sb:
			var base_color: Color = sb.border_color
			var bright := base_color.lightened(0.35)
			var ptw := create_tween().set_loops()
			ptw.tween_method(func(v: float):
				sb.border_color = base_color.lerp(bright, v)
			, 0.0, 1.0, 1.0).set_trans(Tween.TRANS_SINE)
			ptw.tween_method(func(v: float):
				sb.border_color = base_color.lerp(bright, v)
			, 1.0, 0.0, 1.0).set_trans(Tween.TRANS_SINE)

func _build_card(item: Dictionary, index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size.y = 140
	card.size_flags_vertical = SIZE_EXPAND_FILL
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	card.mouse_filter = MOUSE_FILTER_STOP

	var rarity_color: Color = item.get("color", UITheme.C_RARITY_RARE)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.025, 0.015, 0.05, 0.92)
	sb.border_color = rarity_color
	sb.set_border_width_all(3)
	sb.set_content_margin_all(16)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var type_label := Label.new()
	type_label.text = item.get("type_label", "")
	type_label.add_theme_font_size_override("font_size", 22)
	type_label.add_theme_color_override("font_color", rarity_color.darkened(0.1))
	type_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(type_label)

	var title := Label.new()
	title.text = item.get("title", "???")
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", rarity_color)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = item.get("desc", "")
	desc.add_theme_font_size_override("font_size", 24)
	desc.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and _phase == 4:
			_on_card_picked(index)
	)
	return card

func _on_card_picked(index: int) -> void:
	_phase = 5
	var tw := create_tween()

	for i in _cards.size():
		if i == index:
			tw.parallel().tween_property(_cards[i], "scale", Vector2(1.08, 1.08), 0.12)
			tw.parallel().tween_property(_cards[i], "modulate", Color(1.4, 1.4, 1.4, 1.0), 0.12)
		else:
			tw.parallel().tween_property(_cards[i], "modulate:a", 0.0, 0.25)
			tw.parallel().tween_property(_cards[i], "scale", Vector2(0.9, 0.9), 0.25)

	tw.tween_property(_cards[index], "scale", Vector2(1.0, 1.0), 0.1)
	tw.tween_property(_cards[index], "modulate", Color.WHITE, 0.1)
	tw.tween_interval(0.15)
	tw.tween_callback(func(): item_chosen.emit(index))


class _GlowRing extends Control:
	var is_boss := false
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var cx := size.x / 2
		var cy := size.y / 2
		var base := Color(1.0, 0.75, 0.2, 0.12) if is_boss else Color(0.5, 0.3, 0.9, 0.12)
		var bright := Color(1.0, 0.85, 0.4, 0.2) if is_boss else Color(0.6, 0.4, 1.0, 0.2)
		var center := Vector2(cx, cy)

		for i in 6:
			var radius := 60.0 + i * 30.0 + sin(_time * 1.8 + i * 0.7) * 12.0
			var alpha := lerpf(0.18, 0.03, float(i) / 5.0)
			var col := base
			col.a = alpha
			draw_arc(center, radius, 0, TAU, 64, col, 3.5 + sin(_time * 2.0 + i) * 1.5)

		for i in 16:
			var angle := _time * 0.5 + i * (TAU / 16.0)
			var r := 50.0 + sin(_time * 2.0 + i * 1.1) * 25.0
			var ray_len := 60.0 + sin(_time * 1.3 + i * 0.7) * 30.0
			var ray_start := center + Vector2(cos(angle), sin(angle)) * r
			var ray_end := center + Vector2(cos(angle), sin(angle)) * (r + ray_len)
			var col := bright
			col.a = 0.08 + sin(_time * 3.0 + i) * 0.04
			draw_line(ray_start, ray_end, col, 2.0)

		var pulse_r := 40.0 + sin(_time * 3.0) * 10.0
		var pulse_col := bright
		pulse_col.a = 0.05 + sin(_time * 3.0) * 0.03
		draw_circle(center, pulse_r, pulse_col)


class _ChestVisual extends Control:
	var is_boss := false
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var cx := size.x / 2.0
		var cy := size.y / 2.0
		var w := 150.0
		var h := 105.0
		var lid_h := 42.0

		var wood := Color(0.45, 0.22, 0.08) if is_boss else Color(0.20, 0.13, 0.30)
		var wood_l := Color(0.60, 0.35, 0.14) if is_boss else Color(0.28, 0.18, 0.40)
		var wood_h := Color(0.70, 0.42, 0.18) if is_boss else Color(0.35, 0.24, 0.50)
		var metal := Color(0.85, 0.75, 0.42) if is_boss else Color(0.55, 0.42, 0.70)
		var metal_d := Color(0.55, 0.42, 0.22) if is_boss else Color(0.32, 0.25, 0.45)
		var metal_h := Color(0.95, 0.88, 0.60) if is_boss else Color(0.70, 0.58, 0.85)
		var gem := Color(1.0, 0.85, 0.3) if is_boss else Color(0.65, 0.45, 1.0)
		var gem_bright := gem.lightened(0.4)
		var gem_pulse := sin(_time * 4.0) * 0.15 + 0.85
		var gem_glow := gem
		gem_glow.a = 0.15 + sin(_time * 3.0) * 0.1
		var outline := Color(0.03, 0.02, 0.01)

		var bx := cx - w / 2
		var by := cy - h / 2 + lid_h / 2

		# Ground shadow
		draw_rect(Rect2(bx + 8, by + h + 2, w - 4, 10), Color(0, 0, 0, 0.25))

		# Gem underglow
		var glow_r := 35.0 + sin(_time * 3.0) * 5.0
		var glow_col := gem_glow
		glow_col.a = 0.08 + sin(_time * 2.5) * 0.04
		draw_circle(Vector2(cx, by - 2), glow_r, glow_col)

		# === BODY ===
		draw_rect(Rect2(bx, by, w, h), outline)
		draw_rect(Rect2(bx + 2, by + 2, w - 4, h - 4), wood)
		# Wood grain highlight
		draw_rect(Rect2(bx + 2, by + 2, w - 4, 4), wood_h)
		draw_rect(Rect2(bx + 2, by + 2, 3, h - 4), wood_l)
		# Planks
		for i in 4:
			var py := by + 16.0 + i * 20.0
			draw_rect(Rect2(bx + 4, py, w - 8, 1), wood.darkened(0.2))

		# Bottom band
		draw_rect(Rect2(bx - 2, by + h - 16, w + 4, 16), metal_d)
		draw_rect(Rect2(bx - 2, by + h - 16, w + 4, 3), metal_h)
		draw_rect(Rect2(bx - 2, by + h - 2, w + 4, 2), metal)
		for i in 7:
			var rx := bx + 8.0 + i * (w - 16.0) / 6.0
			draw_circle(Vector2(rx, by + h - 8), 3.0, metal_h)
			draw_circle(Vector2(rx, by + h - 8), 2.0, metal)

		# Middle band
		var mid_y := by + h * 0.38
		draw_rect(Rect2(bx - 2, mid_y, w + 4, 12), metal_d)
		draw_rect(Rect2(bx - 2, mid_y, w + 4, 2), metal_h)
		draw_rect(Rect2(bx - 2, mid_y + 10, w + 4, 2), metal)

		# === LID ===
		var lx := bx - 6
		var ly := by - lid_h - 8
		var lw := w + 12
		# Lid body
		draw_rect(Rect2(lx, ly, lw, lid_h + 8), outline)
		draw_rect(Rect2(lx + 2, ly + 2, lw - 4, lid_h + 4), wood_l)
		draw_rect(Rect2(lx + 2, ly + 2, lw - 4, 6), wood_h)
		draw_rect(Rect2(lx + 2, ly + lid_h - 2, lw - 4, 6), wood)
		# Lid band
		var lid_band_y := ly + lid_h * 0.45
		draw_rect(Rect2(lx - 2, lid_band_y, lw + 4, 10), metal_d)
		draw_rect(Rect2(lx - 2, lid_band_y, lw + 4, 2), metal_h)
		draw_rect(Rect2(lx - 2, lid_band_y + 8, lw + 4, 2), metal)
		for i in 7:
			var rx := lx + 10.0 + i * (lw - 20.0) / 6.0
			draw_circle(Vector2(rx, lid_band_y + 5), 3.0, metal_h)
			draw_circle(Vector2(rx, lid_band_y + 5), 2.0, metal)

		# === LOCK PLATE ===
		var lock_w := 36.0
		var lock_h := 30.0
		var lock_x := cx - lock_w / 2
		var lock_y := by - 4
		draw_rect(Rect2(lock_x - 3, lock_y - 3, lock_w + 6, lock_h + 6), outline)
		draw_rect(Rect2(lock_x, lock_y, lock_w, lock_h), metal_d)
		draw_rect(Rect2(lock_x, lock_y, lock_w, 3), metal_h)
		# Lock ornament lines
		draw_rect(Rect2(lock_x + 3, lock_y + lock_h - 4, lock_w - 6, 1), metal)

		# Gem with pulse
		var gem_draw := gem.lerp(gem_bright, (gem_pulse - 0.7) * 2.0)
		draw_circle(Vector2(cx, lock_y + lock_h / 2), 10, gem_glow)
		draw_circle(Vector2(cx, lock_y + lock_h / 2), 8, gem_draw)
		draw_circle(Vector2(cx - 2, lock_y + lock_h / 2 - 2), 3, gem_bright)
		draw_circle(Vector2(cx + 1, lock_y + lock_h / 2 + 1), 1, gem.darkened(0.3))

		# === CORNER BRACKETS ===
		for sx in [-1, 1]:
			for sy in [-1, 1]:
				var corner_x := (bx - 4) if sx == -1 else (bx + w - 10)
				var corner_y := (by - 2) if sy == -1 else (by + h - 12)
				draw_rect(Rect2(corner_x, corner_y, 14, 14), outline)
				draw_rect(Rect2(corner_x + 1, corner_y + 1, 12, 12), metal_d)
				draw_rect(Rect2(corner_x + 2, corner_y + 2, 10, 2), metal_h)
				draw_rect(Rect2(corner_x + 2, corner_y + 2, 2, 10), metal_h)
				draw_circle(Vector2(corner_x + 7, corner_y + 7), 2, metal)

		# Hinges on back
		for i in 2:
			var hx := bx + 20.0 + i * (w - 40.0)
			draw_rect(Rect2(hx, ly + lid_h + 2, 10, 8), metal_d)
			draw_rect(Rect2(hx, ly + lid_h + 2, 10, 2), metal_h)
