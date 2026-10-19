class_name EmberForgeUI
extends Control

const FORGE := preload("res://scripts/expedition/ember_forge.gd")

signal purchase_requested(id: String)
signal back_pressed

var action_buttons: Array[Button] = []
var back_button: Button
var detail_sheet: PanelContainer
var detail_label: Label
var _profile: ExpeditionProfile
var _pending_id := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 100)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 22)
	margin.add_child(content)
	var title := Label.new()
	title.text = "EMBER FORGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	content.add_child(title)
	detail_sheet = PanelContainer.new()
	detail_sheet.custom_minimum_size.y = 180
	detail_sheet.add_theme_stylebox_override("panel", ExpeditionVisualTheme.make_frame())
	detail_label = Label.new()
	detail_label.text = "SELECT A FORGE COMMITMENT"
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_sheet.add_child(detail_label)
	content.add_child(detail_sheet)
	for id: String in FORGE.ids():
		var button := Button.new()
		button.custom_minimum_size = Vector2(800, 96)
		button.pressed.connect(_on_action.bind(id))
		content.add_child(button)
		action_buttons.append(button)
	back_button = Button.new()
	back_button.text = "BACK"
	back_button.custom_minimum_size = Vector2(800, 96)
	back_button.pressed.connect(_on_back)
	content.add_child(back_button)

func setup(profile: ExpeditionProfile) -> void:
	_profile = profile
	_pending_id = ""
	_refresh()

func _refresh() -> void:
	for index in action_buttons.size():
		var id: String = FORGE.ids()[index]
		var definition: Dictionary = FORGE.get_commitment(id)
		var owned := _profile != null and _profile.forge_commitments.has(id)
		var affordable := _profile != null and _profile.ember_shards >= int(definition.cost)
		var state := ("ACTIVE · CONFIRM" if _pending_id == id else "ACTIVE") if owned or _pending_id == id else ("READY" if affordable else "INSUFFICIENT")
		action_buttons[index].text = "%s · %d SHARDS · %s" % [definition.name, definition.cost, state]
		action_buttons[index].disabled = _profile == null or owned or not affordable

func _on_action(id: String) -> void:
	var index: int = FORGE.ids().find(id)
	if _pending_id != id:
		_pending_id = id
		var definition := FORGE.get_commitment(id)
		detail_label.text = "%s\n%s\nTAP ACTIVE AGAIN TO COMMIT" % [definition.name, definition.description]
		_refresh()
		return
	_pending_id = ""
	purchase_requested.emit(id)

func _on_back() -> void:
	if not _pending_id.is_empty():
		_pending_id = ""
		detail_label.text = "SELECT A FORGE COMMITMENT"
		_refresh()
	else: back_pressed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()
