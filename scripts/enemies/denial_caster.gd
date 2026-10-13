extends EnemyBase

const DENIAL_TEXTURE := preload("res://assets/sprites/enemies/denial-caster-v1.png")

func _uses_randomized_body_variants() -> bool:
	return false

const Zone = preload("res://scripts/enemies/denial_zone.gd")
const MAX_ZONES := 6
var cast_timer: float = 2.0

func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = DENIAL_TEXTURE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * 0.055
	_sprite.position = Vector2(0, -18)
	add_child(_sprite)

func reset() -> void:
	super.reset()
	cast_timer = 2.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	cast_timer -= delta
	var combat_target := get_effective_target()
	if not is_instance_valid(combat_target) or global_position.distance_to(combat_target.global_position) > 240.0:
		super._physics_process(delta)
		return
	_update_slow(delta)
	velocity = Vector2.ZERO
	if cast_timer <= 0.0 and get_tree().get_nodes_in_group("denial_zones").size() < MAX_ZONES:
		record_malware_action()
		var zone := Zone.new()
		zone.target = combat_target
		zone.source_id = get_enemy_id() + ":zone"
		zone.damage_context = get_damage_context()
		zone.damage = contact_damage * 0.6
		get_parent().add_child(zone)
		zone.global_position = combat_target.global_position
		RunTelemetry.record("hazard_warning", {"source": zone.source_id, "warning_seconds": zone.WARNING_TIME, "x": zone.global_position.x, "y": zone.global_position.y})
		cast_timer = 4.0
	queue_redraw()

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -34), Vector2(18, -13), Vector2(0, 8), Vector2(-18, -13)]), Color(0.7, 0.2, 0.95))
	draw_circle(Vector2(0, -13), 7, Color(0.95, 0.8, 1.0))
	draw_arc(Vector2(0, -13), 24, 0, TAU, 16, Color(0.7, 0.2, 0.95), 2.0)
	super._draw()
