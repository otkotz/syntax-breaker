extends Node

@onready var game_manager: GameManager = $GameManager

var _main_menu: MainMenu
var _canvas: CanvasLayer

func _ready() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 20
	add_child(_canvas)

	_main_menu = preload("res://scenes/ui/main_menu.tscn").instantiate() as MainMenu
	_canvas.add_child(_main_menu)
	_main_menu.start_pressed.connect(_on_start_run)
	_main_menu.unlocks_pressed.connect(_on_unlocks)
	_main_menu.codex_pressed.connect(_on_codex)

	game_manager.return_to_menu_requested.connect(_on_return_to_menu)

	if game_manager.has_saved_run():
		_show_resume_prompt()

func _on_start_run() -> void:
	_main_menu.hide()
	var region := _main_menu.get_selected_region()
	game_manager.start_run(region)

func _on_return_to_menu() -> void:
	_main_menu.show()

func _on_unlocks() -> void:
	var tree_ui := preload("res://scenes/ui/unlock_tree.tscn").instantiate()
	_canvas.add_child(tree_ui)

func _on_codex() -> void:
	var codex_ui := preload("res://scenes/ui/codex.tscn").instantiate()
	_canvas.add_child(codex_ui)

func _show_resume_prompt() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	var ps := StyleBoxFlat.new()
	ps.bg_color = UITheme.C_BG_1
	ps.border_color = UITheme.C_V_LINE
	ps.set_border_width_all(2)
	ps.set_content_margin_all(40)
	ps.shadow_color = UITheme.C_V_GLOW
	ps.shadow_size = 24
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "— A PATH AWAITS —"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)
	header.uppercase = true
	vbox.add_child(header)

	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer1)

	var title := Label.new()
	title.text = "SAVED RUN\nFOUND"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", UITheme.C_SILVER)
	vbox.add_child(title)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer2)

	var desc := Label.new()
	desc.text = "Resume where you left off, or abandon\nthe old path and begin anew."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	vbox.add_child(desc)

	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer3)

	var divider := DividerLine.new()
	divider.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(divider)

	var spacer4 := Control.new()
	spacer4.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(spacer4)

	var resume_btn := Button.new()
	resume_btn.text = "RESUME RUN"
	resume_btn.custom_minimum_size = Vector2(0, 100)
	resume_btn.add_theme_font_size_override("font_size", 36)
	resume_btn.add_theme_color_override("font_color", UITheme.C_SILVER)
	resume_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	var cta_normal := StyleBoxFlat.new()
	cta_normal.bg_color = UITheme.C_V_BASE
	cta_normal.border_color = Color(0.45, 0.30, 0.85)
	cta_normal.set_border_width_all(2)
	cta_normal.set_content_margin_all(16)
	cta_normal.shadow_color = UITheme.C_V_GLOW
	cta_normal.shadow_size = 20
	resume_btn.add_theme_stylebox_override("normal", cta_normal)
	var cta_hover := StyleBoxFlat.new()
	cta_hover.bg_color = UITheme.C_V_MID
	cta_hover.border_color = Color(0.55, 0.40, 0.90)
	cta_hover.set_border_width_all(2)
	cta_hover.set_content_margin_all(16)
	cta_hover.shadow_color = UITheme.C_V_GLOW
	cta_hover.shadow_size = 28
	resume_btn.add_theme_stylebox_override("hover", cta_hover)
	var cta_pressed := StyleBoxFlat.new()
	cta_pressed.bg_color = UITheme.C_V_DEEP
	cta_pressed.border_color = UITheme.C_V_LINE
	cta_pressed.set_border_width_all(2)
	cta_pressed.set_content_margin_all(16)
	cta_pressed.shadow_color = UITheme.C_V_GLOW
	cta_pressed.shadow_size = 12
	resume_btn.add_theme_stylebox_override("pressed", cta_pressed)
	resume_btn.pressed.connect(func() -> void:
		overlay.queue_free()
		_main_menu.hide()
		game_manager.resume_run()
	)
	vbox.add_child(resume_btn)

	var spacer5 := Control.new()
	spacer5.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(spacer5)

	var new_btn := Button.new()
	new_btn.text = "ABANDON & START NEW"
	new_btn.custom_minimum_size = Vector2(0, 80)
	new_btn.add_theme_font_size_override("font_size", 28)
	new_btn.add_theme_color_override("font_color", UITheme.C_SILVER_D)
	new_btn.add_theme_color_override("font_hover_color", UITheme.C_V_BRIGHT)
	var ghost_normal := StyleBoxFlat.new()
	ghost_normal.bg_color = Color(0.05, 0.03, 0.10, 0.7)
	ghost_normal.border_color = UITheme.C_V_LINE
	ghost_normal.set_border_width_all(2)
	ghost_normal.set_content_margin_all(12)
	new_btn.add_theme_stylebox_override("normal", ghost_normal)
	var ghost_hover := StyleBoxFlat.new()
	ghost_hover.bg_color = Color(0.08, 0.04, 0.16, 0.8)
	ghost_hover.border_color = UITheme.C_V_BRIGHT
	ghost_hover.set_border_width_all(2)
	ghost_hover.set_content_margin_all(12)
	new_btn.add_theme_stylebox_override("hover", ghost_hover)
	var ghost_pressed := StyleBoxFlat.new()
	ghost_pressed.bg_color = Color(0.03, 0.02, 0.07, 0.8)
	ghost_pressed.border_color = UITheme.C_V_LINE
	ghost_pressed.set_border_width_all(2)
	ghost_pressed.set_content_margin_all(12)
	new_btn.add_theme_stylebox_override("pressed", ghost_pressed)
	new_btn.pressed.connect(func() -> void:
		overlay.queue_free()
		RunManager.clear_saved_run()
	)
	vbox.add_child(new_btn)
