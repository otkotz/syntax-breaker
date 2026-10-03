extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run_checks.call_deferred()

func run_checks() -> void:
	var joystick := preload("res://scenes/ui/virtual_joystick.tscn").instantiate() as VirtualJoystick
	# In combat the joystick inherits pausable processing from Arena, while the
	# test runner must stay active to inspect the paused state.
	joystick.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(joystick)
	check(joystick.has_method("set_test_controls_enabled"), "Joystick supports opt-in test arrows")
	if not joystick.has_method("set_test_controls_enabled"):
		joystick.queue_free()
		finish()
		return
	check(not joystick.has_node("TestArrows"), "Normal builds keep test controls out of the UI")
	touch(joystick, true)
	drag(joystick)
	check(InputManager.movement_vector == Vector2.RIGHT, "Normal joystick still moves right")
	joystick.call("set_test_controls_enabled", true)
	check(InputManager.movement_vector == Vector2.ZERO, "Enabling arrows releases the old joystick gesture")
	check(not joystick.base.visible, "Arrow mode hides joystick base")
	await get_tree().process_frame
	var pad := joystick.get_node_or_null("TestArrows") as Control
	check(pad != null and pad.visible, "Enabled test arrows are visible")
	if pad:
		# Removing a handler or reversing a direction must break the real input state.
		for entry: Array in [["Up", Vector2.UP], ["Left", Vector2.LEFT], ["Right", Vector2.RIGHT], ["Down", Vector2.DOWN]]:
			var button := pad.get_node(entry[0]) as Button
			check(button.size.x >= 100.0 and button.size.y >= 100.0, "Arrow has a large touch target")
			button.button_down.emit()
			check(InputManager.movement_vector == entry[1], "%s moves while held" % entry[0])
			touch(joystick, true)
			drag(joystick)
			check(InputManager.movement_vector == entry[1], "Joystick cannot overwrite arrow movement")
			button.button_up.emit()
			check(InputManager.movement_vector == Vector2.ZERO, "Releasing %s stops movement" % entry[0])
		var up := pad.get_node("Up") as Button
		up.button_down.emit()
		get_tree().paused = true
		check(InputManager.movement_vector == Vector2.ZERO, "A checkpoint pause releases held arrows")
		get_tree().paused = false
		check(InputManager.movement_vector == Vector2.ZERO, "Resuming does not restart stale movement")
		# Route real mouse input (the same Button path used by emulated touch),
		# not only signals: a release while paused must not swallow the next press.
		mouse_button(up, true)
		check(InputManager.movement_vector == Vector2.UP, "Routed input starts arrow movement")
		get_tree().paused = true
		mouse_button(up, false)
		get_tree().paused = false
		mouse_button(up, true)
		check(InputManager.movement_vector == Vector2.UP, "The first press after a paused release still moves")
		mouse_button(up, false)
		check(InputManager.movement_vector == Vector2.ZERO, "Routed release stops arrow movement")
		up.button_down.emit()
		joystick.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(InputManager.movement_vector == Vector2.ZERO, "App focus loss stops test movement")
		up.button_down.emit()
		joystick.call("set_test_controls_enabled", false)
		check(InputManager.movement_vector == Vector2.ZERO and not pad.visible, "Disabling arrows stops and hides them")
		touch(joystick, true)
		drag(joystick)
		check(InputManager.movement_vector == Vector2.RIGHT, "Disabling arrows restores the original joystick")
		touch(joystick, false)
		check(InputManager.movement_vector == Vector2.ZERO, "Joystick release still stops movement")
	joystick.queue_free()
	await get_tree().process_frame
	finish()

func touch(joystick: VirtualJoystick, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = Vector2(500, 600)
	event.pressed = pressed
	joystick._input(event)

func drag(joystick: VirtualJoystick) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = Vector2(600, 600)
	joystick._input(event)

func mouse_button(button: Button, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = button.get_global_rect().get_center()
	event.global_position = event.position
	get_viewport().push_input(event, true)

func finish() -> void:
	print(JSON.stringify({"failures": failures, "test": "test_controls_native"}))
	get_tree().quit(0 if failures.is_empty() else 1)
