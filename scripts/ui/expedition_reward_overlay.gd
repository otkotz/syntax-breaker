class_name ExpeditionRewardOverlay
extends Control

signal confirmed

var result_label: Label
var confirm_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.015, 0.03, 0.92)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(PRESET_CENTER)
	panel.position = Vector2(-330, -170)
	panel.custom_minimum_size = Vector2(660, 340)
	panel.add_theme_constant_override("separation", 24)
	add_child(panel)
	var title := Label.new()
	title.text = "EXPEDITION LOOT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	panel.add_child(title)
	result_label = Label.new()
	result_label.custom_minimum_size = Vector2(640, 140)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 26)
	panel.add_child(result_label)
	confirm_button = Button.new()
	confirm_button.text = "CONTINUE"
	confirm_button.custom_minimum_size = Vector2(640, 88)
	confirm_button.pressed.connect(func() -> void:
		confirmed.emit()
		queue_free()
	)
	panel.add_child(confirm_button)

func setup(rewards: Array[Dictionary]) -> void:
	if result_label == null:
		_ready()
	var lines: Array[String] = []
	for reward: Dictionary in rewards:
		var artifact_ids: Variant = reward.get("artifact_ids", [])
		if artifact_ids is Array and not artifact_ids.is_empty():
			for artifact_id: Variant in artifact_ids:
				var artifact := ArtifactCatalog.get_artifact(str(artifact_id))
				lines.append(artifact.display_name if artifact != null else "UNKNOWN ARTIFACT")
		elif int(reward.get("shard_amount", 0)) > 0:
			lines.append("+%d EMBER SHARDS" % int(reward.get("shard_amount")))
		else:
			lines.append("NO ARTIFACT THIS TIME")
	result_label.text = "\n".join(lines) if not lines.is_empty() else "NO ARTIFACT THIS TIME"
