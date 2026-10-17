extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	var profile := ExpeditionProfile.fresh()
	profile.owned_artifact_ids = ["furnace_heart", "ashen_needle"]
	profile.discovered_artifact_ids = ["furnace_heart", "ashen_needle", "fractured_prism"]
	profile.pity_counters["burning_boss_sigil"] = 4
	var screen := ExpeditionCodexUI.new()
	add_child(screen)
	screen.setup(profile)
	check(screen.card_buttons.size() == 6, "Codex exposes one stable card per artifact")
	check(screen.filter_buttons.keys().all(func(key): return key in ["all", "owned", "missing", "burning_grounds"])
		and screen.filter_buttons.size() == 4, "Codex exposes the four approved filters")
	for button: Button in screen.filter_buttons.values():
		check(button.custom_minimum_size.y >= 88.0, "Every primary Codex filter target is at least 88 pixels high")
	var owned_text := (screen.card_buttons["furnace_heart"] as Button).text
	var encountered_text := (screen.card_buttons["fractured_prism"] as Button).text
	var unknown_text := (screen.card_buttons["echoing_hourglass"] as Button).text
	check(owned_text.contains("OWNED") and owned_text.contains("Furnace Heart"), "Owned card reveals full identity")
	check(encountered_text.contains("DISCOVERED") and encountered_text.contains("Fractured Prism"), "Discovered card reveals its identity")
	check(unknown_text.contains("UNKNOWN RELIC") and not unknown_text.contains("Repeats"), "Unknown card hides identity and effect")
	check(unknown_text.contains("TREASURE") or unknown_text.contains("ELITE"), "Unknown card still identifies its source category")
	check(screen.set_progress_label.text.contains("2/3"), "Codex exposes Covenant collection progress")
	check(screen.pity_label.text.contains("4/5"), "Codex exposes the exact chase pity state")
	check(screen.goal_label.text.contains("Cinder Crown") and screen.goal_label.text.contains("BOSS"),
		"Next Hunt points to a missing set piece and its source")
	screen.apply_filter("owned")
	check(screen.visible_card_ids() == ["furnace_heart", "ashen_needle"], "Owned filter shows only owned cards")
	screen.apply_filter("missing")
	check(screen.visible_card_ids().size() == 4, "Missing filter excludes owned cards")
	screen.apply_filter("burning_grounds")
	check(screen.visible_card_ids().size() == 6, "Region filter uses artifact metadata")
	var backed := [false]
	screen.back_pressed.connect(func(): backed[0] = true)
	screen.back_button.pressed.emit()
	check(backed[0], "Codex back target emits navigation")

	var complete := ExpeditionProfile.fresh()
	complete.owned_artifact_ids = ArtifactCatalog.all_ids()
	complete.discovered_artifact_ids = ArtifactCatalog.all_ids()
	screen.setup(complete)
	check(screen.goal_label.text.contains("COLLECTION COMPLETE"), "Complete collection has no fake next-hunt recommendation")

	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
