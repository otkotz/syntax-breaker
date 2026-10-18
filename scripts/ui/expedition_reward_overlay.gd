class_name ExpeditionRewardOverlay
extends Control

signal confirmed
signal decision_requested(reward_id: String, action: String, slot: int)

var result_label: Label
var preview_label: Label
var confirm_button: Button
var keep_button: Button
var temper_button: Button
var shatter_button: Button
var slot_buttons: Array[Button] = []
var scroll_container: ScrollContainer
var _panel: VBoxContainer
var _reward_id := ""
var _decision_locked := false

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.015, 0.03, 0.94)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	scroll_container = ScrollContainer.new()
	scroll_container.set_anchors_and_offsets_preset(PRESET_FULL_RECT, PRESET_MODE_MINSIZE, 36)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll_container)
	_panel = VBoxContainer.new()
	_panel.custom_minimum_size = Vector2(936, 0)
	_panel.add_theme_constant_override("separation", 18)
	scroll_container.add_child(_panel)
	var title := Label.new()
	title.text = "EXPEDITION LOOT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	_panel.add_child(title)
	result_label = Label.new()
	result_label.custom_minimum_size = Vector2(900, 140)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 26)
	_panel.add_child(result_label)
	preview_label = Label.new()
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(preview_label)

func setup(rewards: Array[Dictionary]) -> void:
	var lines: Array[String] = []
	for reward: Dictionary in rewards:
		for artifact_id: Variant in reward.get("artifact_ids", []):
			var artifact := ArtifactCatalog.get_artifact(str(artifact_id))
			lines.append(artifact.display_name if artifact != null else "UNKNOWN ARTIFACT")
		if reward.get("artifact_ids", []).is_empty() and int(reward.get("shard_amount", 0)) > 0:
			lines.append("+%d EMBER SHARDS" % int(reward.get("shard_amount")))
	result_label.text = "\n".join(lines) if not lines.is_empty() else "NO ARTIFACT THIS TIME"
	confirm_button = _add_button("CONTINUE")
	confirm_button.pressed.connect(func() -> void: confirmed.emit(); queue_free())

func setup_decision(reward: Dictionary, session: ExpeditionSession) -> void:
	_reward_id = str(reward.get("reward_id", ""))
	var artifact_ids: Array = reward.get("artifact_ids", [])
	var artifact_id := str(artifact_ids[0]) if not artifact_ids.is_empty() else ""
	var artifact := ArtifactCatalog.get_artifact(artifact_id)
	result_label.text = artifact.display_name if artifact != null else "UNKNOWN ARTIFACT"
	if bool(reward.get("is_duplicate", false)):
		preview_label.text = "DUPLICATE — empower this run or bank shards on victory"
		temper_button = _add_button("TEMPER")
		temper_button.disabled = not session.effective_artifact_ids().has(artifact_id) or session.tempered_artifact_ids.has(artifact_id)
		temper_button.pressed.connect(_request_decision.bind("temper", -1))
		shatter_button = _add_button("SHATTER")
		shatter_button.pressed.connect(_request_decision.bind("shatter", -1))
		return
	var before := _tier_summary(ArtifactLoadout.active_set_tiers(session.effective_artifact_ids()))
	for slot in ArtifactLoadout.SLOT_COUNT:
		var preview := session.preview_echo(artifact_id, slot)
		var after := _tier_summary(preview.get("after_set_tiers", {}))
		var button := _add_button("EQUIP ECHO — SLOT %d" % (slot + 1))
		button.disabled = not preview.get("valid", false)
		button.pressed.connect(_request_decision.bind("echo", slot))
		slot_buttons.append(button)
		if slot == 0: preview_label.text = "SET: %s  →  %s" % [before, after]
	keep_button = _add_button("KEEP LOADOUT")
	keep_button.pressed.connect(_request_decision.bind("keep_loadout", -1))

func _add_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(900, 88)
	_panel.add_child(button)
	return button

func _request_decision(action: String, slot: int) -> void:
	if _decision_locked: return
	_decision_locked = true
	for button in slot_buttons: button.disabled = true
	if keep_button != null: keep_button.disabled = true
	if temper_button != null: temper_button.disabled = true
	if shatter_button != null: shatter_button.disabled = true
	decision_requested.emit(_reward_id, action, slot)

func _tier_summary(tiers: Dictionary) -> String:
	if tiers.is_empty(): return "0/3"
	var values: Array[String] = []
	for set_id in tiers: values.append("%d/3" % int(tiers[set_id]))
	return ", ".join(values)

func _unhandled_input(event: InputEvent) -> void:
	if not _reward_id.is_empty() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
