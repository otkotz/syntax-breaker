class_name StageMapUI
extends Control

signal stage_chosen(stage: StageData)

var _tree: StageTree
var _buttons: Array = []

const ROW_HEIGHT := 160.0
const NODE_RADIUS := 28.0
const MARGIN_TOP := 120.0
const MARGIN_BOTTOM := 200.0

var _canvas: Control
var _scroll: ScrollContainer
var _title_label: Label

var _vp_size: Vector2

func setup(tree: StageTree) -> void:
	_tree = tree
	_build_ui()

func _ready() -> void:
	_vp_size = get_viewport_rect().size
	position = Vector2.ZERO
	size = _vp_size

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.10)
	bg.position = Vector2.ZERO
	bg.size = _vp_size
	add_child(bg)

	var header_h := 80.0
	var header := MarginContainer.new()
	header.position = Vector2.ZERO
	header.size = Vector2(_vp_size.x, header_h)
	header.add_theme_constant_override("margin_left", 30)
	header.add_theme_constant_override("margin_right", 30)
	header.add_theme_constant_override("margin_top", 20)
	header.add_theme_constant_override("margin_bottom", 10)
	add_child(header)

	_title_label = Label.new()
	_title_label.text = "STAGE MAP"
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(_title_label)

	var scroll_h := _vp_size.y - header_h
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(0, header_h)
	_scroll.size = Vector2(_vp_size.x, scroll_h)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	var total_height := MARGIN_TOP + StageGenerator.MAX_DEPTH * ROW_HEIGHT + MARGIN_BOTTOM
	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(_vp_size.x, total_height)
	_scroll.add_child(_canvas)

	var line_drawer := Control.new()
	line_drawer.position = Vector2.ZERO
	line_drawer.size = _canvas.custom_minimum_size
	line_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(line_drawer)
	line_drawer.draw.connect(_draw_map.bind(line_drawer))

	_place_nodes()
	_scroll_to_current()
	line_drawer.queue_redraw()

func _row_y(depth_idx: int) -> float:
	return MARGIN_TOP + (StageGenerator.MAX_DEPTH - 1 - depth_idx) * ROW_HEIGHT

func _node_x(node_idx: int, row_size: int) -> float:
	if row_size == 1:
		return _vp_size.x / 2.0
	var spacing := _vp_size.x / (row_size + 1)
	return spacing * (node_idx + 1)

func _place_nodes() -> void:
	var available := _tree.get_available_nodes()
	var current_d := _tree.current_depth

	for depth_idx in _tree.rows.size():
		var row: Array = _tree.rows[depth_idx]
		var y := _row_y(depth_idx)

		for node_idx in row.size():
			var node: Dictionary = row[node_idx]
			var x := _node_x(node_idx, row.size())
			var type: StageData.Type = node["type"]
			var is_visited: bool = int(_tree.visited[depth_idx]) >= 0 and int(_tree.visited[depth_idx]) == node_idx
			var is_available := depth_idx == current_d and available.has(node_idx)
			var is_future := depth_idx > current_d
			var is_past_unvisited := depth_idx < current_d and not is_visited

			if is_available:
				var btn := Button.new()
				btn.custom_minimum_size = Vector2(NODE_RADIUS * 4.5, NODE_RADIUS * 3)
				btn.size = btn.custom_minimum_size
				btn.position = Vector2(x - btn.size.x / 2, y - btn.size.y / 2)

				var type_name: String = StageData.TYPE_NAMES.get(type, "?")
				var mod_text := ""
				var mods: Array = node.get("modifiers", [])
				if mods.size() > 0:
					var parts: PackedStringArray = []
					for mod: String in mods:
						if StageData.MODIFIER_DATA.has(mod):
							parts.append(StageData.MODIFIER_DATA[mod]["label"])
					mod_text = "\n" + ", ".join(parts)
				btn.text = type_name + mod_text

				var type_color: Color = StageData.TYPE_COLORS.get(type, Color.WHITE)
				var sb := StyleBoxFlat.new()
				sb.bg_color = Color(type_color, 0.25)
				sb.border_color = type_color
				sb.border_width_bottom = 2
				sb.border_width_top = 2
				sb.border_width_left = 2
				sb.border_width_right = 2
				sb.corner_radius_top_left = 8
				sb.corner_radius_top_right = 8
				sb.corner_radius_bottom_left = 8
				sb.corner_radius_bottom_right = 8
				btn.add_theme_stylebox_override("normal", sb)

				var sb_hover := sb.duplicate()
				sb_hover.bg_color = Color(type_color, 0.4)
				btn.add_theme_stylebox_override("hover", sb_hover)

				var sb_pressed := sb.duplicate()
				sb_pressed.bg_color = Color(type_color, 0.5)
				btn.add_theme_stylebox_override("pressed", sb_pressed)

				btn.add_theme_font_size_override("font_size", 22)
				btn.add_theme_color_override("font_color", type_color)
				btn.add_theme_color_override("font_hover_color", Color.WHITE)

				var idx := node_idx
				btn.pressed.connect(func():
					var stage := _tree.visit(idx)
					stage_chosen.emit(stage)
				)
				_canvas.add_child(btn)
				_buttons.append(btn)
			else:
				var marker := Control.new()
				marker.size = Vector2(NODE_RADIUS * 2, NODE_RADIUS * 2)
				marker.position = Vector2(x - NODE_RADIUS, y - NODE_RADIUS)
				marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_canvas.add_child(marker)

				var type_color: Color = StageData.TYPE_COLORS.get(type, Color.WHITE)
				var type_label: String = StageData.TYPE_NAMES.get(type, "?")
				var initial := type_label.left(1)
				if is_visited:
					marker.draw.connect(_draw_visited_node.bind(marker, type_color))
				elif is_past_unvisited:
					marker.draw.connect(_draw_dimmed_node.bind(marker, type_color, 0.15, initial))
				else:
					marker.draw.connect(_draw_dimmed_node.bind(marker, type_color, 0.3 if is_future else 0.2, initial))
				marker.queue_redraw()

func _draw_visited_node(ctrl: Control, color: Color) -> void:
	var center := ctrl.size / 2
	ctrl.draw_circle(center, NODE_RADIUS * 0.7, Color(color, 0.6))
	ctrl.draw_arc(center, NODE_RADIUS * 0.7, 0, TAU, 20, color, 2.0)
	ctrl.draw_string(ThemeDB.fallback_font, center + Vector2(-6, 5), "✓", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)

func _draw_dimmed_node(ctrl: Control, color: Color, alpha: float, type_initial: String = "") -> void:
	var center := ctrl.size / 2
	ctrl.draw_circle(center, NODE_RADIUS * 0.5, Color(color, alpha * 0.5))
	ctrl.draw_arc(center, NODE_RADIUS * 0.5, 0, TAU, 16, Color(color, alpha), 1.5)
	if not type_initial.is_empty():
		ctrl.draw_string(ThemeDB.fallback_font, center + Vector2(-5, 5), type_initial,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(color, alpha * 0.8))

func _draw_map(drawer: Control) -> void:
	if not _tree:
		return

	for depth_idx in _tree.edges.size():
		var from_row: Array = _tree.rows[depth_idx]
		var to_row: Array = _tree.rows[depth_idx + 1]
		var edge_list: Array = _tree.edges[depth_idx]

		for edge: Vector2i in edge_list:
			var from_x := _node_x(edge.x, from_row.size())
			var from_y := _row_y(depth_idx)
			var to_x := _node_x(edge.y, to_row.size())
			var to_y := _row_y(depth_idx + 1)

			var from_visited: bool = int(_tree.visited[depth_idx]) >= 0 and int(_tree.visited[depth_idx]) == edge.x
			var to_visited: bool = int(_tree.visited[depth_idx + 1]) >= 0 and int(_tree.visited[depth_idx + 1]) == edge.y
			var is_taken := from_visited and to_visited

			var color: Color
			var width: float
			if is_taken:
				color = Color(UITheme.C_V_BRIGHT, 0.8)
				width = 3.0
			elif _tree.current_depth == depth_idx + 1 and from_visited:
				color = Color(UITheme.C_V_BRIGHT, 0.5)
				width = 2.0
			else:
				color = Color(0.3, 0.28, 0.4, 0.3)
				width = 1.5

			drawer.draw_line(Vector2(from_x, from_y), Vector2(to_x, to_y), color, width)

	for depth_idx in _tree.rows.size():
		var y := _row_y(depth_idx)
		var depth_str := str(depth_idx + 1)
		drawer.draw_string(ThemeDB.fallback_font, Vector2(15, y + 5), depth_str,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(UITheme.C_INK_FAINT, 0.6))

func _scroll_to_current() -> void:
	var scroll_h := _scroll.size.y
	var target_y := _row_y(_tree.current_depth) - scroll_h / 2
	target_y = clampf(target_y, 0.0, _canvas.custom_minimum_size.y - scroll_h)
	_scroll.scroll_vertical = int(target_y)
