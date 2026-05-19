class_name VirtualJoystick
extends Control

@export var dead_zone: float = 0.1
@export var clamp_zone: float = 75.0

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO

func _ready() -> void:
	base.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch_index != -1:
			return
		if event.position.x > get_viewport_rect().size.x * 0.5:
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
