class_name EnemyProjectile
extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 200.0
var damage: float = 5.0
var _distance_traveled: float = 0.0
var max_range: float = 600.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.4, 0.25))

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
