extends Node

const IDS := ["rollback", "fireball", "static_field", "lightning_bolt", "poison_dart", "flame_wave", "frost_nova"]

func _ready() -> void:
	var failures := 0
	var shapes := {}
	for id: String in IDS:
		var profile: SkillVisualProfile = load("res://resources/skill_visuals/%s.tres" % id)
		if profile == null or profile.skill_id != id or profile.core_shape.is_empty():
			failures += 1; push_error("missing visual profile: " + id); continue
		if shapes.has(profile.core_shape): failures += 1; push_error("duplicate grayscale core: " + id)
		shapes[profile.core_shape] = true
		if profile.max_screen_coverage > 0.20: failures += 1; push_error("coverage too high: " + id)
	for id: String in ["lightning_bolt", "poison_dart", "flame_wave", "frost_nova"]:
		var scene: Node = load("res://scenes/skills/%s.tscn" % id).instantiate()
		var identity := scene.get_node_or_null("VisualIdentity")
		if identity == null or identity.get_meta("profile", null) == null: failures += 1; push_error("scene profile missing: " + id)
		scene.free()
	if failures == 0: print("skill_visual_catalog_native: PASS")
	get_tree().quit(failures)
