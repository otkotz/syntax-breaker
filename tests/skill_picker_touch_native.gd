extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

# Exercises real GUI input, not emitting a button's pressed signal by hand.
func run_checks() -> void:
	MetaProgression.save_path = "res://.godot/picker_touch_meta.json"
	MetaProgression.unlocked_items["skills"] = ["fireball", "lightning_bolt", "blade_spin", "frost_nova", "poison_dart", "static_field"]
	var picker := SkillPicker.new()
	picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(picker)
	var choices := [0]
	picker.skill_chosen.connect(func(_skill: SkillResource, _tier: String): choices[0] += 1)
	await get_tree().process_frame
	await get_tree().process_frame
	check(picker._skill_grid.columns == 1, "Starting skill cards form a readable vertical list")
	var card: Control = picker._skill_grid.get_child(0)
	check(card.size.y >= 300.0, "Skill card has room for legible text and a large touch target")
	var scroller := picker._skill_grid.get_parent().get_parent() as ScrollContainer
	check(scroller.get_v_scroll_bar().max_value > scroller.size.y, "Long skill list can scroll beyond the first screen")
	var wheel := InputEventMouseButton.new()
	wheel.position = card.global_position + Vector2(200, 100)
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	get_tree().root.push_input(wheel, true)
	await get_tree().process_frame
	check(scroller.scroll_vertical > 0, "Wheel input over card body scrolls its parent list")
	check(choices[0] == 0, "Scrolling a card does not accidentally start a run")
	scroller.scroll_vertical = 0
	await get_tree().process_frame
	# Headless DisplayServer is not a touchscreen. Finger dragging uses the
	# platform's emulated mouse pipeline and remains a device-QA check.
	var point := card.global_position + Vector2(5, 5)
	click(point)
	await get_tree().process_frame
	check(choices[0] == 1, "Tapping card header/body chooses the skill, not only the bottom caption")
	click(point)
	await get_tree().process_frame
	check(choices[0] == 1, "Repeated card taps cannot choose a starter twice")
	picker.queue_free()
	await get_tree().process_frame
	MetaProgression.region_victories = {}
	var locked_picker := SkillPicker.new()
	locked_picker.selected_contract = "miner"
	locked_picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(locked_picker)
	locked_picker.skill_chosen.connect(func(_skill: SkillResource, _tier: String): choices[0] += 1)
	await get_tree().process_frame
	await get_tree().process_frame
	var locked_card: Control = locked_picker._skill_grid.get_child(0)
	check(locked_card.get_node("CardHitArea").disabled, "Full-card hit area respects locked contract")
	click(locked_card.global_position + Vector2(5, 5))
	await get_tree().process_frame
	check(choices[0] == 1, "Disabled card cannot bypass a contract lock")
	locked_picker.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: full-card GUI input, wheel scrolling without selection and single-choice protection")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)

func click(point: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.position = point
	down.global_position = point
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	get_tree().root.push_input(down, true)
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	get_tree().root.push_input(up, true)
