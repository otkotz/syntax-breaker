extends Node

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var screen := ExpeditionArtifactsUI.new()
	add_child(screen)
	var profile := ExpeditionProfile.new()
	profile.equipped_artifact_ids = ["furnace_heart", "ashen_needle", "", ""]
	screen.setup(profile, false)
	check(screen.slot_buttons.size() == 4, "Artifact screen exposes four slots")
	check(screen.card_buttons.size() == 6, "Artifact screen exposes six cards")
	for button: Button in screen.slot_buttons + screen.card_buttons:
		check(button.custom_minimum_size.y >= 88.0, "Every artifact target is at least 88 pixels high")
	check(screen.set_label.text.contains("2/3"), "Two equipped pieces display set tier 2/3")
	screen.setup(profile, true)
	check(screen.lock_label.visible, "Active expedition displays loadout lock")
	for button: Button in screen.card_buttons: check(button.disabled, "Locked artifact cards are disabled")
	profile.equipped_artifact_ids[2] = "cinder_crown"
	screen.setup(profile, false)
	check(screen.set_label.text.contains("3/3"), "Three equipped pieces display set tier 3/3")
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
