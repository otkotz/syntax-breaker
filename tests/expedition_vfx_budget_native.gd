extends Node2D

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var parent := Node2D.new()
	add_child(parent)
	var first := ArtifactVFX.spawn(parent, "fractured_prism", Vector2.ZERO)
	for index in 11: ArtifactVFX.spawn(parent, "furnace_heart", Vector2(index * 4, 0))
	check(ArtifactVFX.active_count(parent) == 12, "Artifact feedback stops at twelve active effects")
	check(ArtifactVFX.spawn(parent, "cinder_crown", Vector2.ONE) == null, "Thirteenth lightweight effect is dropped")
	await get_tree().create_timer(0.35).timeout
	var reused := ArtifactVFX.spawn(parent, "fractured_prism", Vector2(8, 8))
	check(reused == first, "Expired artifact CanvasItem is reused from the pool")
	ArtifactVFX.release_all(parent)
	check(ArtifactVFX.active_count(parent) == 0, "Teardown releases every active effect")
	for index in 4: check(ArtifactVFX.spawn_trail(parent, Vector2.ZERO, Vector2(20, 20), Color.CYAN) != null, "Trail %d fits budget" % index)
	check(ArtifactVFX.spawn_trail(parent, Vector2.ZERO, Vector2.ONE, Color.CYAN) == null, "Fifth trail is dropped")
	for index in 2: check(ArtifactVFX.spawn(parent, "prism_needle_crossfire", Vector2(index * 10, 0)) != null, "Synergy %d fits budget" % index)
	check(ArtifactVFX.spawn(parent, "hourglass_sigil_blood_echo", Vector2.ZERO) == null, "Third simultaneous synergy is dropped")
	ArtifactVFX.release_all(parent)
	check(ArtifactVFX.spawn(parent, "furnace_heart", Vector2.ZERO, false, 2, 99) == null, "Secondary generations cannot recursively request feedback")
	var origin_first := ArtifactVFX.spawn(parent, "ashen_needle", Vector2.ZERO, false, 0, 77)
	var origin_merge := ArtifactVFX.spawn(parent, "ashen_needle", Vector2(4, 4), false, 0, 77)
	check(origin_first == origin_merge and ArtifactVFX.active_count(parent) == 1, "Same origin merges into its live glyph")
	check(origin_first.z_index < 20 and origin_first.arc_segments >= 16 and origin_first.arc_segments <= 24, "Friendly glyph stays below hostile projectile priority with bounded geometry")
	ArtifactVFX.release_all(parent)
	parent.queue_free()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)
