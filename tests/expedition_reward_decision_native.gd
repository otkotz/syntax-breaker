extends Node

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var session := ExpeditionSession.create(33, "burning_grounds", ["furnace_heart", "ashen_needle", "cinder_crown", ""])
	var reward := {"reward_id": "elite:reward", "source_tag": "elite", "artifact_ids": ["fractured_prism"], "shard_amount": 0, "pity_key": "", "chase_awarded": false}
	session.record_reward(reward)
	var overlay := preload("res://scenes/ui/expedition_reward_overlay.tscn").instantiate() as ExpeditionRewardOverlay
	add_child(overlay)
	overlay.setup_decision(reward, session)
	check(overlay.keep_button.text == "KEEP LOADOUT", "New artifact offers Keep Loadout")
	check(overlay.slot_buttons.size() == 4, "New artifact offers all four Echo replacement slots")
	for button: Button in overlay.slot_buttons + [overlay.keep_button]:
		check(button.custom_minimum_size.y >= 88.0, "Every reward decision target is touch-sized")
	check(overlay.preview_label.text.contains("3/3") and overlay.preview_label.text.contains("2/3"), "Replacement preview summarizes before and after set tiers")
	var decisions: Array[Array] = []
	overlay.decision_requested.connect(func(id: String, action: String, slot: int) -> void: decisions.append([id, action, slot]))
	overlay.slot_buttons[2].pressed.emit()
	overlay.keep_button.pressed.emit()
	check(decisions == [["elite:reward", "echo", 2]], "Overlay emits exactly one decision")
	var back := InputEventKey.new()
	back.keycode = KEY_ESCAPE
	back.pressed = true
	overlay._unhandled_input(back)
	check(overlay.is_inside_tree(), "Android back cannot dismiss an unresolved reward")
	check(overlay.scroll_container != null and overlay.scroll_container.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "Portrait decision content supports touch scrolling")
	overlay.queue_free()
	var duplicate := reward.duplicate(true)
	duplicate["reward_id"] = "duplicate:reward"
	duplicate["is_duplicate"] = true
	session = ExpeditionSession.create(34, "burning_grounds", ["fractured_prism", "", "", ""])
	session.record_reward(duplicate)
	var duplicate_overlay := preload("res://scenes/ui/expedition_reward_overlay.tscn").instantiate() as ExpeditionRewardOverlay
	add_child(duplicate_overlay)
	duplicate_overlay.setup_decision(duplicate, session)
	check(duplicate_overlay.temper_button != null and duplicate_overlay.temper_button.text == "TEMPER", "Equipped duplicate offers Temper")
	check(duplicate_overlay.shatter_button != null and duplicate_overlay.shatter_button.text == "SHATTER", "Duplicate offers Shatter")
	var duplicate_decisions: Array[Array] = []
	duplicate_overlay.decision_requested.connect(func(id: String, action: String, slot: int) -> void: duplicate_decisions.append([id, action, slot]))
	duplicate_overlay.temper_button.pressed.emit()
	duplicate_overlay.shatter_button.pressed.emit()
	check(duplicate_decisions == [["duplicate:reward", "temper", -1]], "Duplicate reward accepts exactly one Temper or Shatter action")
	duplicate_overlay.queue_free()
	var inactive_session := ExpeditionSession.create(35, "burning_grounds", ["furnace_heart", "", "", ""])
	inactive_session.record_reward(duplicate)
	var inactive_overlay := preload("res://scenes/ui/expedition_reward_overlay.tscn").instantiate() as ExpeditionRewardOverlay
	add_child(inactive_overlay)
	inactive_overlay.setup_decision(duplicate, inactive_session)
	check(inactive_overlay.temper_button.disabled, "Temper is disabled when the duplicate is not in the effective loadout")
	inactive_overlay.queue_free()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
