class_name Vortex
extends Node2D

var radius: float = 120.0
var pull_strength: float = 200.0
var duration: float = 1.5
var _timer: float = 0.0

func setup(pos: Vector2, r: float, strength: float, dur: float) -> void:
	global_position = pos
	radius = r
	pull_strength = strength
	duration = dur

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= duration:
		queue_free()
		return
	_pull_enemies(delta)
	queue_redraw()

func _pull_enemies(delta: float) -> void:
	var enemies := Targeting.find_enemies_in_range(global_position, radius, 30)
	for enemy: Node2D in enemies:
		var dir := enemy.global_position.direction_to(global_position)
		var dist := enemy.global_position.distance_to(global_position)
		var falloff := 1.0 - (dist / radius)
		enemy.global_position += dir * pull_strength * falloff * delta

func _draw() -> void:
	var progress := _timer / duration
	var alpha := 0.3 * (1.0 - progress)
	draw_circle(Vector2.ZERO, radius * (1.0 - progress * 0.3), Color(0.6, 0.3, 1.0, alpha))
	draw_arc(Vector2.ZERO, radius * 0.5, 0, TAU, 32, Color(0.8, 0.5, 1.0, alpha * 1.5), 2.0)
