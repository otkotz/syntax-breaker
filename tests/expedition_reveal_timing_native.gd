extends Node

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var session := ExpeditionSession.create(1201, "burning_grounds", ["furnace_heart", "ashen_needle", "", ""])
	var cases: Array[Dictionary] = [
		{"reward": _reward("shards", "elite", [], 3), "class": ExpeditionRewardOverlay.SHARDS, "duration": 1.0},
		{"reward": _reward("duplicate", "elite", ["furnace_heart"], 0, true), "class": ExpeditionRewardOverlay.DUPLICATE, "duration": 0.22},
		{"reward": _reward("new", "elite", ["fractured_prism"]), "class": ExpeditionRewardOverlay.NEW, "duration": 0.8},
		{"reward": _reward("set", "boss_set", ["cinder_crown"]), "class": ExpeditionRewardOverlay.SET_PIECE, "duration": 0.95},
		{"reward": _reward("complete", "boss_set", ["cinder_crown"]), "class": ExpeditionRewardOverlay.SET_COMPLETE, "duration": 1.35, "complete": true},
		{"reward": _reward("chase", "boss_chase", ["bloodwritten_sigil"]), "class": ExpeditionRewardOverlay.CHASE, "duration": 1.6},
	]
	for entry in cases:
		var case_session := session
		if entry["class"] == ExpeditionRewardOverlay.SET_PIECE: case_session = ExpeditionSession.create(1203, "burning_grounds", ["furnace_heart", "", "", ""])
		if entry.get("complete", false): case_session = ExpeditionSession.create(1202, "burning_grounds", ["furnace_heart", "ashen_needle", "", ""])
		var overlay := ExpeditionRewardOverlay.new()
		add_child(overlay)
		overlay.configure_presentation(entry.reward, case_session, false)
		check(overlay.presentation_class == entry["class"], "%s classification" % entry["class"])
		check(is_equal_approx(overlay.reveal_duration, entry["duration"]), "%s uses ranked timing cap" % entry["class"])
		check(overlay.skip_available_after <= 0.25, "%s exposes skip by 0.25 seconds" % entry["class"])
		overlay.skip_reveal()
		check(overlay.reveal_complete and overlay.scale == Vector2.ONE and overlay.rotation == 0.0 and overlay.modulate.a == 1.0, "%s skip lands on final frame" % entry["class"])
		if entry["class"] == ExpeditionRewardOverlay.SHARDS:
			check(not overlay.blocks_gameplay and overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Shard toast is non-modal")
		overlay.queue_free()
	var reduced := ExpeditionRewardOverlay.new()
	add_child(reduced)
	reduced.configure_presentation(cases[-1].reward, session, true)
	check(reduced.reveal_duration == 0.0 and reduced.scale == Vector2.ONE and reduced.rotation == 0.0 and reduced.flash_strength == 0.0, "Reduced motion is a clean crossfade without punch, spin, or flash")
	reduced.queue_free()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _reward(id: String, source: String, artifacts: Array, shards: int = 0, duplicate: bool = false) -> Dictionary:
	return {"reward_id": id, "source_tag": source, "artifact_ids": artifacts, "shard_amount": shards,
		"is_duplicate": duplicate, "pity_key": "", "chase_awarded": source == "boss_chase"}
