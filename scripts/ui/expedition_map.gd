class_name ExpeditionMapUI
extends Control

signal room_chosen(room_id: String)
signal abandon_pressed
const TYPE_NAMES := {DungeonRoomData.Type.START:"START", DungeonRoomData.Type.COMBAT:"COMBAT", DungeonRoomData.Type.ELITE:"ELITE", DungeonRoomData.Type.EVENT:"EVENT", DungeonRoomData.Type.TREASURE:"TREASURE", DungeonRoomData.Type.BOSS:"BOSS"}
const SHAPES := {DungeonRoomData.Type.COMBAT:"●", DungeonRoomData.Type.ELITE:"◆", DungeonRoomData.Type.EVENT:"◇", DungeonRoomData.Type.TREASURE:"⬡", DungeonRoomData.Type.BOSS:"◉", DungeonRoomData.Type.START:"○"}
var room_buttons: Dictionary = {}
var selected_room_id := ""
var connector_count := 0
var connector_thickness := 8.0
var detail_sheet: PanelContainer
var detail_label: Label
var enter_button: Button
var abandon_button: Button
var _abandon_armed := false
var _graph: Control
var _session: ExpeditionSession

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()

func setup(session: ExpeditionSession) -> void:
	_session = session
	selected_room_id = ""
	for child in _graph.get_children(): child.queue_free()
	room_buttons.clear()
	connector_count = 0
	var depths: Dictionary = {}
	for room: DungeonRoomData in session.layout.rooms.values():
		if not depths.has(room.depth): depths[room.depth] = []
		depths[room.depth].append(room)
	var max_depth := maxi(1, int(depths.keys().max()))
	var node_centers: Dictionary = {}
	for depth: int in depths:
		var depth_rooms: Array = depths[depth]
		for lane in depth_rooms.size():
			var placed := depth_rooms[lane] as DungeonRoomData
			node_centers[placed.id] = Vector2(80.0 + lane * 160.0, 70.0 + float(depth) / max_depth * 400.0)
	for source: String in session.layout.edges:
		for target: String in session.layout.get_outgoing(source):
			var from := node_centers[source] as Vector2
			var to := node_centers[target] as Vector2
			var line := ColorRect.new()
			line.name = "Connector_%s_%s" % [source, target]
			line.color = ExpeditionVisualTheme.COPPER
			line.position = from
			line.size = Vector2(from.distance_to(to), connector_thickness)
			line.rotation = from.angle_to_point(to)
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_graph.add_child(line)
			connector_count += 1
	var available := session.get_available_room_ids()
	for depth: int in depths:
		var rooms: Array = depths[depth]
		for lane in rooms.size():
			var room := rooms[lane] as DungeonRoomData
			var button := Button.new()
			button.name = "Room_%s" % room.id
			button.text = "%s\n%s" % [SHAPES.get(room.type, "●"), TYPE_NAMES.get(room.type, "ROOM")]
			button.custom_minimum_size = Vector2(120, 120)
			button.position = (node_centers[room.id] as Vector2) - Vector2(60, 60)
			button.disabled = not available.has(room.id)
			button.pressed.connect(_select_room.bind(room.id))
			_graph.add_child(button)
			room_buttons[room.id] = button
	enter_button.disabled = true
	_abandon_armed = false
	abandon_button.text = "ABANDON EXPEDITION"
	detail_label.text = "SELECT A NODE\nTHREAT —  REWARD —"

func _select_room(room_id: String) -> void:
	selected_room_id = room_id
	var room := _session.layout.rooms[room_id] as DungeonRoomData
	var reward := "ARTIFACT CHANCE" if room.type in [DungeonRoomData.Type.ELITE, DungeonRoomData.Type.TREASURE, DungeonRoomData.Type.BOSS] else "EMBER / PROGRESS"
	detail_label.text = "%s  ·  DEPTH %d\nTHREAT  %s\nREWARD  %s" % [TYPE_NAMES[room.type], room.depth + 1, _threat(room.type), reward]
	enter_button.disabled = not _session.can_enter(room_id)

func _confirm_room() -> void:
	if not selected_room_id.is_empty() and _session.can_enter(selected_room_id): room_chosen.emit(selected_room_id)

func _request_abandon() -> void:
	if not _abandon_armed:
		_abandon_armed = true
		abandon_button.text = "CONFIRM ABANDON"
		return
	abandon_pressed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"): return
	if not selected_room_id.is_empty():
		selected_room_id = ""
		enter_button.disabled = true
		detail_label.text = "SELECT A NODE\nTHREAT —  REWARD —"
	elif _abandon_armed:
		_abandon_armed = false
		abandon_button.text = "ABANDON EXPEDITION"
	else:
		_request_abandon()
	get_viewport().set_input_as_handled()

func _threat(type: DungeonRoomData.Type) -> String:
	return "SEVERE" if type in [DungeonRoomData.Type.ELITE, DungeonRoomData.Type.BOSS] else "STANDARD"

func _build_ui() -> void:
	var bg := ColorRect.new(); bg.color = UITheme.C_BG; bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left", 28); margin.add_theme_constant_override("margin_right", 28); margin.add_theme_constant_override("margin_top", 28); margin.add_theme_constant_override("margin_bottom", 36); add_child(margin)
	var content := VBoxContainer.new(); content.add_theme_constant_override("separation", 14); margin.add_child(content)
	var title := Label.new(); title.text = "BURNING GROUNDS"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 42); content.add_child(title)
	_graph = Control.new(); _graph.custom_minimum_size = Vector2(0, 520); _graph.size_flags_vertical = SIZE_EXPAND_FILL; content.add_child(_graph)
	detail_sheet = PanelContainer.new(); detail_sheet.custom_minimum_size.y = 300; detail_sheet.add_theme_stylebox_override("panel", ExpeditionVisualTheme.make_frame()); content.add_child(detail_sheet)
	var detail := VBoxContainer.new(); detail_sheet.add_child(detail)
	detail_label = Label.new(); detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; detail_label.size_flags_vertical = SIZE_EXPAND_FILL; detail.add_child(detail_label)
	enter_button = Button.new(); enter_button.name = "EnterRoomButton"; enter_button.text = "ENTER"; enter_button.custom_minimum_size.y = 96; enter_button.pressed.connect(_confirm_room); detail.add_child(enter_button)
	abandon_button = Button.new(); abandon_button.name = "AbandonExpeditionButton"; abandon_button.text = "ABANDON EXPEDITION"; abandon_button.custom_minimum_size.y = 88; abandon_button.pressed.connect(_request_abandon); detail.add_child(abandon_button)
