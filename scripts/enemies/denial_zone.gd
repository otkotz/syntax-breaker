extends Node2D

const WARNING_TIME := 1.2
const ACTIVE_TIME := 3.0
const RADIUS := 70.0
var warning_remaining: float = WARNING_TIME
var active_remaining: float = ACTIVE_TIME
var tick_remaining: float = 0.0
var damage: float = 6.0
var target: Node2D
var radius: float = RADIUS
var warning_duration: float = WARNING_TIME
var tick_interval: float = 0.5
var color := Color(0.8, 0.3, 1.0)
var zone_group: String = "denial_zones"
var source_id: String = "denial_zone"

func _ready() -> void:
	add_to_group(zone_group)

func _process(delta: float) -> void:
	if warning_remaining > 0.0:
		warning_remaining = maxf(0.0, warning_remaining - delta)
		queue_redraw()
		return
	# Lifetime and damage start only after the full warning, never during it.
	active_remaining -= delta
	if active_remaining <= 0.0:
		queue_free()
		return
	tick_remaining -= delta
	if tick_remaining <= 0.0:
		tick_remaining = tick_interval
		if is_instance_valid(target) and target.has_method("take_damage"):
			if global_position.distance_to(target.global_position) <= radius:
				Player.hurt(target, damage, source_id)
	queue_redraw()

func _draw() -> void:
	var warning := warning_remaining > 0.0
	draw_circle(Vector2.ZERO, radius, Color(color, 0.12 if warning else 0.4))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, color, 3.0)
	if warning:
		draw_arc(Vector2.ZERO, radius * (1.0 - warning_remaining / warning_duration), 0, TAU, 48, color, 2.0)
	else:
		for offset in [-18.0, 0.0, 18.0]:
			draw_line(Vector2(-20, offset), Vector2(20, offset), color, 2.0)
