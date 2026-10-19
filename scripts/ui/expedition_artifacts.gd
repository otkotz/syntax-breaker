class_name ExpeditionArtifactsUI
extends Control

signal equip_requested(artifact_id: String, slot: int)
signal unequip_requested(slot: int)
signal back_pressed

var slot_buttons: Array[Button] = []
var card_buttons: Array[Button] = []
var set_label: Label
var lock_label: Label
var message_label: Label
var detail_sheet: PanelContainer
var detail_card: ArtifactCard
var equip_button: Button
var _selected_artifact_id := ""
var _profile: ExpeditionProfile
var _locked := false

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()

func setup(profile: ExpeditionProfile, locked: bool) -> void:
	_profile = profile
	_locked = locked
	_render()

func show_message(text: String) -> void:
	message_label.text = text

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = UITheme.C_BG
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(scroll)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(700, 0)
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)
	var title := Label.new()
	title.text = "EXPEDITION ARTIFACTS"
	title.add_theme_font_size_override("font_size", 42)
	content.add_child(title)
	lock_label = Label.new()
	lock_label.text = "LOADOUT LOCKED DURING ACTIVE EXPEDITION"
	lock_label.add_theme_color_override("font_color", UITheme.C_RARITY_LEGENDARY)
	content.add_child(lock_label)
	set_label = Label.new()
	set_label.add_theme_font_size_override("font_size", 26)
	content.add_child(set_label)
	message_label = Label.new()
	content.add_child(message_label)
	for index in ArtifactLoadout.SLOT_COUNT:
		var button := Button.new()
		button.custom_minimum_size = Vector2(650, 88)
		button.pressed.connect(_request_unequip.bind(index))
		slot_buttons.append(button)
		content.add_child(button)
	for artifact_id in ArtifactCatalog.all_ids():
		var button := Button.new()
		button.custom_minimum_size = Vector2(650, 112)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_preview_artifact.bind(artifact_id))
		card_buttons.append(button)
		content.add_child(button)
	detail_sheet = PanelContainer.new()
	detail_sheet.visible = false
	detail_sheet.custom_minimum_size.y = 300
	detail_sheet.add_theme_stylebox_override("panel", ExpeditionVisualTheme.make_frame())
	var detail_content := VBoxContainer.new()
	detail_sheet.add_child(detail_content)
	detail_card = ArtifactCard.new()
	detail_content.add_child(detail_card)
	equip_button = Button.new()
	equip_button.text = "EQUIP SELECTED RELIC"
	equip_button.custom_minimum_size.y = 88
	equip_button.pressed.connect(func(): _request_equip(_selected_artifact_id))
	detail_content.add_child(equip_button)
	content.add_child(detail_sheet)
	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(650, 88)
	back.pressed.connect(func(): back_pressed.emit())
	content.add_child(back)

func _request_equip(artifact_id: String) -> void:
	if _profile == null or _locked: return
	var slot := _profile.equipped_artifact_ids.find("")
	if slot < 0: slot = 0
	equip_requested.emit(artifact_id, slot)

func _preview_artifact(artifact_id: String) -> void:
	var artifact := ArtifactCatalog.get_artifact(artifact_id)
	if artifact == null: return
	_selected_artifact_id = artifact_id
	detail_card.setup(artifact, "owned", {"source_tag": artifact.source_tags.front() if not artifact.source_tags.is_empty() else "treasure"})
	equip_button.disabled = _locked or _profile.equipped_artifact_ids.has(artifact_id)
	detail_sheet.visible = true

func _request_unequip(slot: int) -> void:
	if not _locked: unequip_requested.emit(slot)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"): return
	if detail_sheet.visible: detail_sheet.visible = false
	else: back_pressed.emit()
	get_viewport().set_input_as_handled()

func _render() -> void:
	if _profile == null: return
	lock_label.visible = _locked
	for index in slot_buttons.size():
		var artifact_id := _profile.equipped_artifact_ids[index]
		var artifact := ArtifactCatalog.get_artifact(artifact_id)
		slot_buttons[index].text = "SLOT %d  ·  %s" % [index + 1, artifact.display_name if artifact else "EMPTY"]
		slot_buttons[index].disabled = _locked or artifact_id.is_empty()
	for index in card_buttons.size():
		var artifact := ArtifactCatalog.get_artifact(ArtifactCatalog.all_ids()[index])
		card_buttons[index].text = "%s\n%s" % [artifact.display_name, artifact.description]
		card_buttons[index].disabled = _locked or _profile.equipped_artifact_ids.has(artifact.id)
	var tier := int(ArtifactLoadout.active_set_tiers(_profile.equipped_artifact_ids).get("covenant_of_embers", 0))
	set_label.text = "COVENANT OF EMBERS  ·  %d/3" % tier
