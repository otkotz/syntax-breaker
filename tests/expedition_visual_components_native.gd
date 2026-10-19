extends Node

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var expected := {
		"furnace_heart": "res://assets/icons/artifacts/furnace-heart-v1.png",
		"ashen_needle": "res://assets/icons/artifacts/ashen-needle-v1.png",
		"cinder_crown": "res://assets/icons/artifacts/cinder-crown-v1.png",
		"fractured_prism": "res://assets/icons/artifacts/fractured-prism-v1.png",
		"echoing_hourglass": "res://assets/icons/artifacts/echoing-hourglass-v1.png",
		"bloodwritten_sigil": "res://assets/icons/artifacts/bloodwritten-sigil-v1.png",
	}
	for id: String in expected:
		var artifact := ArtifactCatalog.get_artifact(id)
		check(artifact != null and artifact.icon != null, id + " has non-null icon artwork")
		if artifact != null and artifact.icon != null:
			check(artifact.icon.resource_path == expected[id], id + " keeps a stable 1:1 source path")
	for path: String in ["res://assets/icons/expedition/ember-shard-v1.png", "res://assets/icons/expedition/source-elite-v1.png",
		"res://assets/icons/expedition/source-treasure-v1.png", "res://assets/icons/expedition/source-boss-v1.png"]:
		check(ResourceLoader.exists(path), path + " utility glyph exists")
	var artifact := ArtifactCatalog.get_artifact("furnace_heart")
	for state: String in ["unknown", "encountered", "owned"]:
		var card := ArtifactCard.new()
		add_child(card)
		card.setup(artifact, state, {"source_tag": "elite"})
		check(card.discovery_state == state and card.state_label.text.to_lower().contains(state), "Artifact card labels " + state + " state")
		check(card.source_icon.texture != null and card.source_label.text.contains("ELITE"), "Artifact card reinforces source with glyph and label")
		check(card.custom_minimum_size.x < 600.0, "Artifact card has no fixed desktop width")
		if state == "unknown": check(card.icon_rect.texture == null, "Unknown card does not leak relic art")
		else: check(card.icon_rect.texture == artifact.icon, state + " card shows relic art")
		card.queue_free()
	var meter := CovenantMeter.new()
	add_child(meter)
	for count in 4:
		meter.set_progress(count)
		check(meter.progress_label.text.contains("%d/3" % count), "Covenant meter renders %d/3" % count)
	meter.set_progress(2, 3)
	check(meter.progress_label.text.contains("2/3") and meter.preview_label.text.contains("3/3") and meter.preview_label.visible, "Covenant meter exposes labeled preview delta")
	check(meter.segment_labels.size() == 3 and meter.segment_labels.all(func(label: Label): return not label.text.is_empty()), "Color meter also labels every segment")
	meter.queue_free()
	var frame := ExpeditionVisualTheme.make_frame(ExpeditionVisualTheme.EMBER)
	check(frame.border_width_left == 2 and frame.bg_color.a > 0.0 and frame.corner_radius_top_left == 0, "Theme produces smoked-glass clipped-corner frame")
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
