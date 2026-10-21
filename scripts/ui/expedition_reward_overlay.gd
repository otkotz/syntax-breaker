class_name ExpeditionRewardOverlay
extends Control

signal confirmed
signal decision_requested(reward_id: String, action: String, slot: int)

const SHARDS := "SHARDS"
const DUPLICATE := "DUPLICATE"
const NEW := "NEW"
const SET_PIECE := "SET_PIECE"
const SET_COMPLETE := "SET_COMPLETE"
const CHASE := "CHASE"

var result_label: Label
var preview_label: Label
var confirm_button: Button
var keep_button: Button
var echo_button: Button
var temper_button: Button
var shatter_button: Button
var slot_buttons: Array[Button] = []
var choice_buttons: Array[Button] = []
var scroll_container: ScrollContainer
var accent_label: Label
var skip_button: Button
var artifact_icon: TextureRect
var comparison: ArtifactComparison
var temper_reason_label: Label
var _panel: VBoxContainer
var _reward_id := ""
var _decision_locked := false
var _selected_slot := 0
var _decision_session: ExpeditionSession
var _decision_artifact_id := ""
var presentation_class := NEW
var reveal_skippable := true
var reveal_duration := 0.35
var reveal_accent := "ember"
var reveal_complete := false
var skip_available_after := 0.25
var blocks_gameplay := true
var flash_strength := 0.0
var reveal_pattern := "line_print"
var _reveal_tween: Tween

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
	accent_label = Label.new()
	accent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	accent_label.add_theme_font_size_override("font_size", 22)
	_panel.add_child(accent_label)
	artifact_icon = TextureRect.new()
	artifact_icon.custom_minimum_size = Vector2(176, 176)
	artifact_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artifact_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_panel.add_child(artifact_icon)
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
	comparison = ArtifactComparison.new()
	comparison.visible = false
	_panel.add_child(comparison)
	temper_reason_label = Label.new()
	temper_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	temper_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(temper_reason_label)
	skip_button = _add_button("SKIP REVEAL")
	skip_button.custom_minimum_size.y = 64
	skip_button.pressed.connect(skip_reveal)

func setup(rewards: Array[Dictionary]) -> void:
	if not rewards.is_empty(): configure_presentation(rewards[0], null, QualitySettings.reduced_motion)
	var lines: Array[String] = []
	for reward: Dictionary in rewards:
		for artifact_id: Variant in reward.get("artifact_ids", []):
			var artifact := ArtifactCatalog.get_artifact(str(artifact_id))
			lines.append(artifact.display_name if artifact != null else "UNKNOWN ARTIFACT")
		if reward.get("artifact_ids", []).is_empty() and int(reward.get("shard_amount", 0)) > 0:
			lines.append("+%d EMBER SHARDS" % int(reward.get("shard_amount")))
	result_label.text = "\n".join(lines) if not lines.is_empty() else "NO ARTIFACT THIS TIME"
	if presentation_class == SHARDS:
		skip_button.visible = false
		_auto_close_toast()
		return
	confirm_button = _add_button("CONTINUE")
	confirm_button.pressed.connect(func() -> void: confirmed.emit(); queue_free())

func setup_decision(reward: Dictionary, session: ExpeditionSession) -> void:
	configure_presentation(reward, session, QualitySettings.reduced_motion)
	_reward_id = str(reward.get("reward_id", ""))
	var artifact_ids: Array = reward.get("artifact_ids", [])
	var artifact_id := str(artifact_ids[0]) if not artifact_ids.is_empty() else ""
	_decision_session = session
	_decision_artifact_id = artifact_id
	var artifact := ArtifactCatalog.get_artifact(artifact_id)
	result_label.text = artifact.display_name if artifact != null else "UNKNOWN ARTIFACT"
	artifact_icon.texture = artifact.icon if artifact != null else null
	if reward.has("alternative_artifact_ids") and not bool(reward.get("choice_selected", false)):
		preview_label.text = "TREASURE CHOICE — select the relic to carry forward"
		var original_button := _add_button("KEEP ORIGINAL — %s" % result_label.text)
		original_button.pressed.connect(_request_decision.bind("choose_original", -1))
		choice_buttons.append(original_button)
		var alternative_ids: Array = reward.get("alternative_artifact_ids", [])
		var alternative := ArtifactCatalog.get_artifact(str(alternative_ids[0])) if not alternative_ids.is_empty() else null
		var alternative_button := _add_button("TAKE ALTERNATIVE — %s" % (alternative.display_name if alternative != null else "EMBER SHARDS"))
		alternative_button.disabled = alternative_ids.is_empty()
		alternative_button.pressed.connect(_request_decision.bind("choose_alternative", -1))
		choice_buttons.append(alternative_button)
		return
	if bool(reward.get("is_duplicate", false)):
		preview_label.text = "DUPLICATE — empower this run or bank shards on victory"
		temper_button = _add_button("TEMPER")
		temper_button.disabled = not session.effective_artifact_ids().has(artifact_id) or session.tempered_artifact_ids.has(artifact_id)
		if temper_button.disabled:
			temper_reason_label.text = "TEMPER REQUIRES THIS RELIC IN THE ACTIVE LOADOUT" if not session.effective_artifact_ids().has(artifact_id) else "THIS RELIC IS ALREADY TEMPERED"
		temper_button.pressed.connect(_request_decision.bind("temper", -1))
		shatter_button = _add_button("SHATTER")
		shatter_button.pressed.connect(_request_decision.bind("shatter", -1))
		keep_button = _add_button("KEEP / SKIP")
		keep_button.pressed.connect(_request_decision.bind("keep_loadout", -1))
		return
	var before := _tier_summary(ArtifactLoadout.active_set_tiers(session.effective_artifact_ids()))
	comparison.visible = true
	for slot in ArtifactLoadout.SLOT_COUNT:
		var preview := session.preview_echo(artifact_id, slot)
		var after := _tier_summary(preview.get("after_set_tiers", {}))
		var current := ArtifactCatalog.get_artifact(str(session.effective_artifact_ids()[slot]))
		var button := _add_button("PREVIEW SLOT %d · %s" % [slot + 1, current.display_name if current != null else "EMPTY"])
		button.disabled = not preview.get("valid", false)
		button.pressed.connect(_select_echo_slot.bind(slot))
		slot_buttons.append(button)
		if slot == 0: preview_label.text = "SET: %s  →  %s" % [before, after]
	_select_echo_slot(0)
	echo_button = _add_button("EQUIP ECHO")
	echo_button.pressed.connect(func() -> void: _request_decision("echo", _selected_slot))
	keep_button = _add_button("KEEP LOADOUT")
	keep_button.pressed.connect(_request_decision.bind("keep_loadout", -1))

func configure_presentation(reward: Dictionary, session: ExpeditionSession, reduced_motion: bool = false) -> void:
	presentation_class = classify_reward(reward, session)
	var ids: Array = reward.get("artifact_ids", [])
	var reveal_artifact := ArtifactCatalog.get_artifact(str(ids[0])) if not ids.is_empty() else null
	artifact_icon.texture = reveal_artifact.icon if reveal_artifact != null else null
	artifact_icon.visible = reveal_artifact != null
	var timings := {SHARDS: 1.0, DUPLICATE: 0.22, NEW: 0.8, SET_PIECE: 0.95, SET_COMPLETE: 1.35, CHASE: 1.6}
	reveal_duration = float(timings[presentation_class])
	blocks_gameplay = presentation_class != SHARDS
	mouse_filter = Control.MOUSE_FILTER_STOP if blocks_gameplay else Control.MOUSE_FILTER_IGNORE
	reveal_accent = "blood_seal" if presentation_class == CHASE else ("hot_gold" if presentation_class == SET_COMPLETE else "ember")
	reveal_pattern = {SHARDS: "magnet_streak", DUPLICATE: "double_image_fracture", NEW: "line_print",
		SET_PIECE: "copper_seal_assembly", SET_COMPLETE: "three_linked_relics", CHASE: "five_cut_crimson_seal"}[presentation_class]
	queue_redraw()
	var rank_title := "NEW SET PIECE" if presentation_class == SET_PIECE else presentation_class.replace("_", " ")
	accent_label.text = "%s · %s" % [rank_title, reveal_accent.replace("_", " ").to_upper()]
	accent_label.add_theme_color_override("font_color", Color("e52f4f") if presentation_class == CHASE else (Color("ffc04a") if presentation_class == SET_COMPLETE else Color("ffb02e")))
	reveal_complete = reduced_motion
	modulate.a = 1.0 if reduced_motion else 0.72
	scale = Vector2.ONE if reduced_motion else Vector2(0.985, 0.985)
	rotation = 0.0
	flash_strength = 0.0
	if reduced_motion:
		reveal_duration = 0.0
		return
	_reveal_tween = create_tween().set_parallel(true)
	_reveal_tween.tween_property(self, "modulate:a", 1.0, reveal_duration)
	_reveal_tween.tween_property(self, "scale", Vector2.ONE, reveal_duration)
	_reveal_tween.chain().tween_callback(func() -> void: reveal_complete = true)

static func classify_reward(reward: Dictionary, session: ExpeditionSession) -> String:
	var artifact_ids: Array = reward.get("artifact_ids", [])
	if artifact_ids.is_empty(): return SHARDS
	if bool(reward.get("is_duplicate", false)): return DUPLICATE
	if str(reward.get("source_tag", "")) == "boss_chase": return CHASE
	var artifact := ArtifactCatalog.get_artifact(str(artifact_ids[0]))
	if artifact == null or artifact.set_id.is_empty(): return NEW
	var set_count := 0
	if session != null:
		for equipped_id: String in session.effective_artifact_ids():
			var equipped := ArtifactCatalog.get_artifact(equipped_id)
			if equipped != null and equipped.set_id == artifact.set_id: set_count += 1
	if session == null or not session.effective_artifact_ids().has(artifact.id): set_count += 1
	return SET_COMPLETE if set_count >= 3 else SET_PIECE

func skip_reveal() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid(): _reveal_tween.kill()
	modulate.a = 1.0
	scale = Vector2.ONE
	reveal_complete = true
	queue_redraw()

func _draw() -> void:
	var center := size * Vector2(0.5, 0.25)
	var ink := Color("ffb02e") if presentation_class != CHASE else Color("e52f4f")
	match reveal_pattern:
		"magnet_streak":
			for y in [-18.0, 0.0, 18.0]: draw_line(center + Vector2(-110, y), center + Vector2(70, y * 0.25), Color(ink, 0.65), 3.0)
		"double_image_fracture":
			draw_rect(Rect2(center - Vector2(58, 42), Vector2(76, 84)), Color(ink, 0.14), false, 4.0)
			draw_rect(Rect2(center - Vector2(18, 42), Vector2(76, 84)), Color(ink, 0.28), false, 4.0)
			draw_line(center + Vector2(-8, -50), center + Vector2(8, 50), ink, 3.0)
		"copper_seal_assembly":
			draw_arc(center, 58, 0.2, 2.0, 8, ink, 5.0); draw_arc(center, 58, 2.3, 4.0, 8, ink, 5.0); draw_arc(center, 58, 4.3, 6.1, 8, ink, 5.0)
		"three_linked_relics":
			var points := [center + Vector2(0, -55), center + Vector2(-52, 35), center + Vector2(52, 35)]
			for i in 3: draw_line(points[i], points[(i + 1) % 3], ink, 5.0); draw_circle(points[i], 12, ink)
		"five_cut_crimson_seal":
			for i in 5:
				var d := Vector2.from_angle(i * TAU / 5.0)
				draw_line(center + d * 24, center + d * 74, ink, 6.0)
		_:
			for i in 6: draw_line(center + Vector2(-75, -45 + i * 18), center + Vector2(75, -45 + i * 18), Color(ink, 0.7), 2.0)

func _auto_close_toast() -> void:
	await get_tree().create_timer(reveal_duration).timeout
	if not is_inside_tree(): return
	confirmed.emit()
	queue_free()

func _select_echo_slot(slot: int) -> void:
	if _decision_session == null: return
	_selected_slot = slot
	var preview := _decision_session.preview_echo(_decision_artifact_id, slot)
	comparison.setup(_decision_session.effective_artifact_ids(), _decision_artifact_id, slot)
	preview_label.text = "SLOT %d · SET: %s → %s" % [slot + 1,
		_tier_summary(preview.get("before_set_tiers", {})), _tier_summary(preview.get("after_set_tiers", {}))]

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
	for button in choice_buttons: button.disabled = true
	if keep_button != null: keep_button.disabled = true
	if echo_button != null: echo_button.disabled = true
	if temper_button != null: temper_button.disabled = true
	if shatter_button != null: shatter_button.disabled = true
	decision_requested.emit(_reward_id, action, slot)

func _tier_summary(tiers: Dictionary) -> String:
	if tiers.is_empty(): return "0/3"
	var values: Array[String] = []
	for set_id in tiers: values.append("%d/3" % int(tiers[set_id]))
	return ", ".join(values)

func _unhandled_input(event: InputEvent) -> void:
	if reveal_skippable and not reveal_complete and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		skip_reveal()
		get_viewport().set_input_as_handled()
		return
	if not _reward_id.is_empty() and event.is_action_pressed("ui_cancel"):
		if not slot_buttons.is_empty() and _selected_slot != 0:
			_selected_slot = 0
			_select_echo_slot(0)
		else:
			preview_label.text = "CHOOSE BEFORE CONTINUING"
		get_viewport().set_input_as_handled()
