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
	check(overlay.artifact_icon != null and overlay.artifact_icon.custom_minimum_size.x >= 160.0 and overlay.artifact_icon.custom_minimum_size.x <= 192.0, "Reward reveal gives relic art hero scale")
	check(overlay.comparison != null, "Echo decision includes real artifact comparison")
	for button: Button in overlay.slot_buttons + [overlay.echo_button, overlay.keep_button]:
		check(button.custom_minimum_size.y >= 88.0, "Every reward decision target is touch-sized")
	check(overlay.preview_label.text.contains("3/3") and overlay.preview_label.text.contains("2/3"), "Replacement preview summarizes before and after set tiers")
	var decisions: Array[Array] = []
	overlay.decision_requested.connect(func(id: String, action: String, slot: int) -> void: decisions.append([id, action, slot]))
	overlay.slot_buttons[2].pressed.emit()
	check(overlay.preview_label.text.contains("3/3") and overlay.preview_label.text.contains("2/3"), "Selected slot shows its own before/after comparison")
	overlay.echo_button.pressed.emit()
	overlay.keep_button.pressed.emit()
	check(decisions == [["elite:reward", "echo", 2]], "Overlay emits exactly one decision")
	var back := InputEventKey.new()
	back.keycode = KEY_ESCAPE
	back.pressed = true
	overlay._unhandled_input(back)
	check(overlay.is_inside_tree(), "Android back cannot dismiss an unresolved reward")
	overlay._unhandled_input(back)
	overlay._unhandled_input(back)
	check(overlay.preview_label.text.contains("CHOOSE BEFORE CONTINUING"), "Back on a required decision explains why it cannot close")
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
	check(not inactive_overlay.temper_reason_label.text.is_empty(), "Disabled Temper explains why")
	inactive_overlay.queue_free()
	var treasure := reward.duplicate(true)
	treasure["reward_id"] = "treasure:choice"
	treasure["alternative_reward_id"] = "treasure:choice:alternative"
	treasure["alternative_artifact_ids"] = ["echoing_hourglass"]
	var choice_session := ExpeditionSession.create(36, "burning_grounds", [])
	choice_session.record_reward(treasure)
	var choice_overlay := preload("res://scenes/ui/expedition_reward_overlay.tscn").instantiate() as ExpeditionRewardOverlay
	add_child(choice_overlay)
	choice_overlay.setup_decision(treasure, choice_session)
	check(choice_overlay.choice_buttons.size() == 2, "Treasure Choice presents original and alternative before loadout decisions")
	choice_overlay.queue_free()
	check(choice_session.resolve_reward("treasure:choice", "choose_alternative"), "Treasure Choice persists the alternative selection")
	check(choice_session.get_reward("treasure:choice").artifact_ids == ["echoing_hourglass"] and choice_session.unresolved_reward_id == "treasure:choice", "Alternative selection still requires a loadout decision")
	check(choice_session.resolve_reward("treasure:choice", "keep_loadout"), "Selected Treasure Choice reward can then be resolved")
	var no_drop_choice := _reward("treasure:no-drop", "treasure", [])
	no_drop_choice["shard_amount"] = 4
	no_drop_choice["alternative_artifact_ids"] = ["fractured_prism"]
	var no_drop_session := ExpeditionSession.create(39, "burning_grounds", [])
	check(no_drop_session.record_reward(no_drop_choice) and no_drop_session.unresolved_reward_id == "treasure:no-drop", "Treasure Choice remains actionable when the original roll is shards")
	check(no_drop_session.resolve_reward("treasure:no-drop", "choose_alternative") and no_drop_session.get_reward("treasure:no-drop").artifact_ids == ["fractured_prism"], "No-drop Treasure Choice can select its artifact alternative")
	var boss_session := ExpeditionSession.create(37, "burning_grounds", [])
	var set_reward := _reward("boss:set", "boss_set", ["furnace_heart"])
	var chase_reward := _reward("boss:chase", "boss_chase", ["bloodwritten_sigil"])
	boss_session.record_reward(set_reward)
	boss_session.record_reward(chase_reward)
	check(boss_session.resolve_reward("boss:set", "keep_loadout") and boss_session.unresolved_reward_id == "boss:chase", "Resolving the set reward advances to the chase reward")
	check(boss_session.resolve_reward("boss:chase", "keep_loadout") and boss_session.unresolved_reward_id.is_empty(), "Every boss artifact receives its own decision")
	var unknown := _reward("future:duplicate", "treasure", ["future_artifact"])
	unknown["is_duplicate"] = true
	var unknown_session := ExpeditionSession.create(38, "burning_grounds", [])
	unknown_session.record_reward(unknown)
	var unknown_overlay := preload("res://scenes/ui/expedition_reward_overlay.tscn").instantiate() as ExpeditionRewardOverlay
	add_child(unknown_overlay)
	unknown_overlay.setup_decision(unknown, unknown_session)
	check(unknown_overlay.keep_button != null and not unknown_overlay.keep_button.disabled, "Unknown duplicate always exposes a safe Keep fallback")
	check(unknown_session.resolve_reward("future:duplicate", "keep_loadout"), "Unknown duplicate cannot block the expedition")
	unknown_overlay.queue_free()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _reward(id: String, source: String, artifacts: Array) -> Dictionary:
	return {"reward_id": id, "source_tag": source, "artifact_ids": artifacts, "shard_amount": 0,
		"pity_key": "", "chase_awarded": source == "boss_chase"}
