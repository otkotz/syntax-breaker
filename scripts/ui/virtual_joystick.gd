class_name VirtualJoystick
extends Control

@export var dead_zone: float = 0.1
@export var clamp_zone: float = 75.0

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _test_controls_enabled := false
var _test_arrows: Control
var _test_toggle: Button
var _test_direction := Vector2.ZERO

func _ready() -> void:
	base.hide()
	if OS.is_debug_build() and OS.has_feature("phone_test_controls"):
		set_test_controls_enabled(true)

func _input(event: InputEvent) -> void:
	if _test_controls_enabled:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch_index != -1:
			return
		_touch_index = event.index
		_center = event.position
		base.global_position = _center - base.size * 0.5
		knob.position = base.size * 0.5 - knob.size * 0.5
		base.show()
	else:
		if event.index != _touch_index:
			return
		_touch_index = -1
		base.hide()
		InputManager.set_movement(Vector2.ZERO)

func set_test_controls_enabled(enabled: bool) -> void:
	# The Android playtest preset opts in; release builds never expose these controls.
	if not OS.is_debug_build():
		return
	_reset_movement()
	_test_controls_enabled = enabled
	if enabled and not is_instance_valid(_test_arrows):
		_build_test_arrows()
	if is_instance_valid(_test_arrows):
		_test_arrows.visible = enabled
		_test_toggle.text = "TEST ARROWS: ON" if enabled else "TEST ARROWS: OFF"

func _build_test_arrows() -> void:
	_test_arrows = Control.new()
	_test_arrows.name = "TestArrows"
	_test_arrows.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
	_test_arrows.offset_left = 20
	_test_arrows.offset_right = 380
	_test_arrows.offset_top = -480
	_test_arrows.offset_bottom = -120
	_test_arrows.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_test_arrows)
	for entry: Array in [["Up", "↑", Vector2.UP, Vector2(120, 0)], ["Left", "←", Vector2.LEFT, Vector2(0, 120)], ["Right", "→", Vector2.RIGHT, Vector2(240, 120)], ["Down", "↓", Vector2.DOWN, Vector2(120, 240)]]:
		var button := Button.new()
		button.name = entry[0]
		button.text = entry[1]
		button.position = entry[3]
		button.custom_minimum_size = Vector2(112, 112)
		button.focus_mode = FOCUS_NONE
		UITheme.style_button(button, 48)
		var direction: Vector2 = entry[2]
		button.button_down.connect(func():
			if _test_controls_enabled and not get_tree().paused:
				_test_direction = direction
				InputManager.set_movement(direction)
		)
		button.button_up.connect(func():
			if _test_direction == direction:
				_test_direction = Vector2.ZERO
				InputManager.set_movement(Vector2.ZERO)
		)
		_test_arrows.add_child(button)
	_test_toggle = Button.new()
	_test_toggle.name = "TestArrowToggle"
	_test_toggle.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
	_test_toggle.offset_left = 20
	_test_toggle.offset_right = 380
	_test_toggle.offset_top = -550
	_test_toggle.offset_bottom = -490
	_test_toggle.focus_mode = FOCUS_NONE
	UITheme.style_button(_test_toggle, 24)
	_test_toggle.pressed.connect(func(): set_test_controls_enabled(not _test_controls_enabled))
	add_child(_test_toggle)

func _reset_movement() -> void:
	_touch_index = -1
	_test_direction = Vector2.ZERO
	if is_instance_valid(base):
		base.hide()
	if is_instance_valid(_test_arrows):
		for child: Node in _test_arrows.get_children():
			if child is Button:
				# Momentary buttons ignore set_pressed_no_signal. Disabling clears
				# the held state even if their release arrived while combat paused.
				child.disabled = true
				child.disabled = false
	InputManager.set_movement(Vector2.ZERO)

func _notification(what: int) -> void:
	if _test_controls_enabled and what in [NOTIFICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_EXIT_TREE]:
		_reset_movement()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	var diff := event.position - _center
	var dist := diff.length()
	var direction := diff.normalized()
	var clamped_dist: float = minf(dist, clamp_zone)

	knob.position = base.size * 0.5 - knob.size * 0.5 + direction * clamped_dist

	if dist / clamp_zone > dead_zone:
		InputManager.set_movement(direction * (clamped_dist / clamp_zone))
	else:
		InputManager.set_movement(Vector2.ZERO)
