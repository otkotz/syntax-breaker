class_name CovenantMeter
extends VBoxContainer

var progress_label: Label
var preview_label: Label
var segment_labels: Array[Label] = []
var _segments: Array[PanelContainer] = []

func _init() -> void:
	add_theme_constant_override("separation", 5)
	var heading := HBoxContainer.new()
	add_child(heading)
	var title := Label.new()
	title.text = "COVENANT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	progress_label = Label.new()
	heading.add_child(progress_label)
	var track := HBoxContainer.new()
	track.add_theme_constant_override("separation", 4)
	add_child(track)
	for index in 3:
		var segment := PanelContainer.new()
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.custom_minimum_size.y = 28.0
		track.add_child(segment)
		var label := Label.new()
		label.text = ["HEART", "NEEDLE", "CROWN"][index]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		segment.add_child(label)
		_segments.append(segment)
		segment_labels.append(label)
	preview_label = Label.new()
	preview_label.modulate = ExpeditionVisualTheme.EMBER
	add_child(preview_label)
	set_progress(0)

func set_progress(count: int, preview_count: int = -1) -> void:
	var current := clampi(count, 0, 3)
	progress_label.text = "%d/3" % current
	var has_preview := preview_count >= 0 and clampi(preview_count, 0, 3) != current
	preview_label.visible = has_preview
	preview_label.text = "PREVIEW  %d/3" % clampi(preview_count, 0, 3) if has_preview else ""
	for index in _segments.size():
		var active := index < current
		var previewed := has_preview and index < clampi(preview_count, 0, 3) and not active
		var accent := ExpeditionVisualTheme.EMBER if active else (ExpeditionVisualTheme.COPPER if previewed else ExpeditionVisualTheme.UNKNOWN)
		_segments[index].add_theme_stylebox_override("panel", ExpeditionVisualTheme.make_frame(accent))
		segment_labels[index].modulate = Color.WHITE if active or previewed else ExpeditionVisualTheme.ASH
