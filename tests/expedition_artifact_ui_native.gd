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
	_test_reward_presentation()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _test_reward_presentation() -> void:
	var session := ExpeditionSession.create(91, "burning_grounds", ["furnace_heart", "ashen_needle"])
	var cases: Array[Dictionary] = [
		{"reward": _reward("shards", "elite", [], 2), "expected": "SHARDS"},
		{"reward": _reward("duplicate", "treasure", ["furnace_heart"], 0, true), "expected": "DUPLICATE"},
		{"reward": _reward("new", "treasure", ["fractured_prism"]), "expected": "NEW"},
		{"reward": _reward("piece", "boss_set", ["furnace_heart"]), "expected": "SET_PIECE"},
		{"reward": _reward("complete", "boss_set", ["cinder_crown"]), "expected": "SET_COMPLETE"},
		{"reward": _reward("chase", "boss_chase", ["bloodwritten_sigil"]), "expected": "CHASE"},
	]
	for value: Dictionary in cases:
		var overlay := ExpeditionRewardOverlay.new()
		add_child(overlay)
		overlay.configure_presentation(value.reward, session, false)
		check(overlay.presentation_class == value.expected, "%s reward uses its presentation class" % value.expected)
		check(overlay.reveal_skippable, "%s reveal can be skipped" % value.expected)
		if value.expected in ["SHARDS", "DUPLICATE"]:
			check(overlay.reveal_duration <= 0.2, "%s has no long ceremony" % value.expected)
		if value.expected == "CHASE":
			check(overlay.reveal_accent == "blood_seal" and overlay.reveal_duration > 0.2 and overlay.accent_label.text.contains("CHASE"), "Chase reward has distinctive visible treatment")
		overlay.skip_button.pressed.emit()
		check(overlay.reveal_complete and overlay.modulate.a == 1.0 and overlay.scale == Vector2.ONE, "Skip lands on the usable final frame")
		overlay.queue_free()
	var reduced := ExpeditionRewardOverlay.new()
	add_child(reduced)
	reduced.configure_presentation(cases[-1].reward, session, true)
	check(reduced.reveal_duration == 0.0 and reduced.reveal_complete, "Reduced motion reveals immediately")
	reduced.queue_free()
	var shards_overlay := ExpeditionRewardOverlay.new()
	add_child(shards_overlay)
	shards_overlay.setup([cases[0].reward])
	check(shards_overlay.presentation_class == "SHARDS", "Production shard setup routes through presentation hierarchy")
	shards_overlay.queue_free()
	var vfx_parent := Node2D.new()
	add_child(vfx_parent)
	var reduced_vfx := ArtifactVFX.spawn(vfx_parent, "bloodwritten_sigil", Vector2.ZERO, true)
	check(reduced_vfx != null and reduced_vfx.reduced_motion and reduced_vfx.scale == Vector2.ONE, "Artifact VFX reduced-motion fallback avoids scale punch")
	if reduced_vfx != null: reduced_vfx.queue_free()
	vfx_parent.queue_free()

func _reward(id: String, source: String, artifacts: Array, shards: int = 0, duplicate: bool = false) -> Dictionary:
	return {"reward_id": id, "source_tag": source, "artifact_ids": artifacts,
		"shard_amount": shards, "is_duplicate": duplicate, "pity_key": "", "chase_awarded": false}
