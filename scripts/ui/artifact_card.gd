class_name ArtifactCard
extends PanelContainer

var discovery_state: String = "unknown"
var icon_rect: TextureRect
var state_label: Label
var source_icon: TextureRect
var source_label: Label
var name_label: Label
var description_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(280.0, 116.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", ExpeditionVisualTheme.make_frame())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(80.0, 80.0)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon_rect)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var heading := HBoxContainer.new()
	copy.add_child(heading)
	name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)
	heading.add_child(name_label)
	state_label = Label.new()
	heading.add_child(state_label)
	description_label = Label.new()
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(description_label)
	var source_row := HBoxContainer.new()
	copy.add_child(source_row)
	source_icon = TextureRect.new()
	source_icon.custom_minimum_size = Vector2(22.0, 22.0)
	source_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	source_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	source_row.add_child(source_icon)
	source_label = Label.new()
	source_row.add_child(source_label)

func setup(artifact: ArtifactResource, state: String, context: Dictionary = {}) -> void:
	discovery_state = state if state in ["unknown", "encountered", "owned"] else "unknown"
	var concealed := discovery_state == "unknown"
	name_label.text = "UNKNOWN RELIC" if concealed else artifact.display_name
	description_label.text = "Unrecorded expedition artifact." if concealed else artifact.description
	icon_rect.texture = null if concealed else artifact.icon
	state_label.text = discovery_state.to_upper()
	state_label.modulate = ExpeditionVisualTheme.UNKNOWN if concealed else ExpeditionVisualTheme.EMBER
	var source_tag := String(context.get("source_tag", artifact.source_tags.front() if not artifact.source_tags.is_empty() else "treasure"))
	source_icon.texture = ExpeditionVisualTheme.source_icon(source_tag)
	source_label.text = ExpeditionVisualTheme.source_label(source_tag)
