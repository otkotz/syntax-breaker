class_name ExpeditionMapUI
extends Control

signal room_chosen(room_id: String)
signal abandon_pressed

const TYPE_NAMES := {
	DungeonRoomData.Type.START: "START",
	DungeonRoomData.Type.COMBAT: "COMBAT",
	DungeonRoomData.Type.ELITE: "ELITE",
	DungeonRoomData.Type.EVENT: "EVENT",
	DungeonRoomData.Type.TREASURE: "TREASURE",
	DungeonRoomData.Type.BOSS: "BOSS",
}

var room_buttons: Dictionary = {}
var _room_container: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()

func setup(session: ExpeditionSession) -> void:
	for child: Node in _room_container.get_children():
		child.queue_free()
	room_buttons.clear()
	var available := session.get_available_room_ids()
	var room_ids: Array = session.layout.rooms.keys()
	room_ids.sort_custom(func(a: String, b: String) -> bool:
		return (session.layout.rooms[a] as DungeonRoomData).depth < (session.layout.rooms[b] as DungeonRoomData).depth
	)
	for room_id: String in room_ids:
		var room := session.layout.rooms[room_id] as DungeonRoomData
		var status := "LOCKED"
		if session.completed_room_ids.has(room_id):
			status = "COMPLETED"
		elif available.has(room_id):
			status = "AVAILABLE"
		var button := Button.new()
		button.name = "Room_%s" % room_id
		button.text = "%s  ·  DEPTH %d\n%s" % [TYPE_NAMES.get(room.type, "UNKNOWN"), room.depth + 1, status]
		button.custom_minimum_size = Vector2(760, 110)
		button.disabled = status != "AVAILABLE"
		button.add_theme_font_size_override("font_size", 26)
		if status == "AVAILABLE":
			button.pressed.connect(func() -> void: room_chosen.emit(room_id))
		_room_container.add_child(button)
		room_buttons[room_id] = button

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = UITheme.C_BG
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 90)
	margin.add_theme_constant_override("margin_bottom", 70)
	add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	margin.add_child(content)

	var title := Label.new()
	title.text = "BURNING GROUNDS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)
	content.add_child(title)

	var route := Label.new()
	route.text = "START → A / B → MERGE → BOSS"
	route.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route.add_theme_font_size_override("font_size", 22)
	route.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	content.add_child(route)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(scroll)
	_room_container = VBoxContainer.new()
	_room_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_room_container.add_theme_constant_override("separation", 18)
	scroll.add_child(_room_container)

	var abandon := Button.new()
	abandon.name = "AbandonExpeditionButton"
	abandon.text = "ABANDON EXPEDITION"
	abandon.custom_minimum_size = Vector2(600, 96)
	abandon.add_theme_font_size_override("font_size", 28)
	abandon.pressed.connect(func() -> void: abandon_pressed.emit())
	content.add_child(abandon)
