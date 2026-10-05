extends Node2D

const Visual = preload("res://scripts/util/hazard_visual.gd")

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
var damage_context: Dictionary = {}
var activation_remaining: float = 0.0
var _activated: bool = false

func _ready() -> void:
	z_index = 2
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
	if not _activated:
		_activated = true
		activation_remaining = Visual.ACTIVATION_TIME
		RunTelemetry.record("hazard_active", {"source": source_id, "warning_seconds": warning_duration,
			"x": global_position.x, "y": global_position.y})
	else:
		activation_remaining = maxf(0.0, activation_remaining - delta)
	tick_remaining -= delta
	if tick_remaining <= 0.0:
		tick_remaining = tick_interval
		if is_instance_valid(target) and target.has_method("take_damage"):
			if global_position.distance_to(target.global_position) <= radius:
				Player.hurt(target, damage, source_id, damage_context)
	queue_redraw()

func _draw() -> void:
	var warning := warning_remaining > 0.0
	draw_circle(Vector2.ZERO, radius, Visual.fill_color(color, warning_remaining, activation_remaining))
	Visual.outline(self, Visual.circle_points(radius), warning_remaining, warning_duration, color, activation_remaining)
	if not warning:
		for offset in [-18.0, 0.0, 18.0]:
			Visual.active_mark(self, Vector2(0, offset), color)
	Visual.badge(self, Vector2(0, -radius * 0.5), warning_remaining)
