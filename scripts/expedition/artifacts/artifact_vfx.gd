class_name ArtifactVFX
extends Node2D

var color := Color.WHITE
var radius := 28.0

static func spawn(parent: Node, artifact_id: String, world_position: Vector2) -> ArtifactVFX:
	if parent == null: return null
	var effect := ArtifactVFX.new()
	effect.color = {
		"fractured_prism": Color(0.72, 0.35, 1.0), "echoing_hourglass": Color(0.5, 0.8, 1.0),
		"bloodwritten_sigil": Color(1.0, 0.15, 0.2), "ashen_needle": Color(1.0, 0.55, 0.15),
		"cinder_crown": Color(1.0, 0.3, 0.05), "chain_conflagration": Color(1.0, 0.65, 0.1),
		"prism_needle_crossfire": Color(0.35, 0.9, 1.0), "hourglass_sigil_blood_echo": Color(1.0, 0.12, 0.38),
		"crown_prism_split_transfer": Color(0.95, 0.32, 0.8),
	}.get(artifact_id, Color(1.0, 0.45, 0.1))
	effect.radius = {"prism_needle_crossfire": 22.0, "hourglass_sigil_blood_echo": 34.0,
		"crown_prism_split_transfer": 46.0}.get(artifact_id, 28.0)
	effect.global_position = world_position
	effect.add_to_group("artifact_vfx")
	parent.add_child(effect)
	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2.ONE * 2.2, 0.28)
	tween.tween_property(effect, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(effect.queue_free)
	return effect

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 5.0)
	draw_circle(Vector2.ZERO, 5.0, color.lightened(0.35))
