class_name EnemyProjectile
extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 200.0
var damage: float = 5.0
var _distance_traveled: float = 0.0
var max_range: float = 600.0

func _draw() -> void:
	const ORB_MID := Color(0.753, 0.659, 1.0)
	const ORB_GLOW := Color(0.478, 0.353, 0.8)
	# Outer glow
	draw_circle(Vector2.ZERO, 5.0, Color(0.478, 0.353, 0.8, 0.35))
	# Cross arms
	draw_rect(Rect2(Vector2(-3, 0), Vector2(1, 1)), ORB_GLOW)
	draw_rect(Rect2(Vector2(3, 0), Vector2(1, 1)), ORB_GLOW)
	draw_rect(Rect2(Vector2(0, -3), Vector2(1, 1)), ORB_GLOW)
	draw_rect(Rect2(Vector2(0, 3), Vector2(1, 1)), ORB_GLOW)
	draw_rect(Rect2(Vector2(-2, 0), Vector2(5, 1)), ORB_MID)
	draw_rect(Rect2(Vector2(0, -2), Vector2(1, 5)), ORB_MID)
	# Core
	draw_rect(Rect2(Vector2(-1, -1), Vector2(3, 3)), ORB_MID)
	draw_rect(Rect2(Vector2(0, 0), Vector2(1, 1)), Color.WHITE)

func _physics_process(delta: float) -> void:
	var move_dist := speed * delta
	position += direction * move_dist
	_distance_traveled += move_dist
	if _distance_traveled >= max_range:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
