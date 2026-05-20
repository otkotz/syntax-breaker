class_name ComboDisplay
extends Control

var _combo_label: Label
var _mult_label: Label

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	anchor_left = 0.6
	anchor_right = 1.0
	anchor_top = 0.35
	anchor_bottom = 0.5
	offset_left = 0
	offset_right = -20
	offset_top = 0
	offset_bottom = 0

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	_combo_label = Label.new()
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_combo_label.add_theme_font_size_override("font_size", 56)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(_combo_label)

	_mult_label = Label.new()
	_mult_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_mult_label.add_theme_font_size_override("font_size", 30)
	_mult_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	vbox.add_child(_mult_label)

func setup(tracker: ComboTracker) -> void:
	tracker.combo_changed.connect(_on_combo_changed)

func _on_combo_changed(count: int, multiplier: float) -> void:
	if count < 3:
		visible = false
		return
	visible = true
	_combo_label.text = "%d COMBO" % count
	if multiplier > 1.01:
		_mult_label.text = "x%.1f DMG" % multiplier
		_mult_label.visible = true
	else:
		_mult_label.visible = false
	_combo_label.scale = Vector2(1.3, 1.3)
	var tween := create_tween()
	tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.15)
