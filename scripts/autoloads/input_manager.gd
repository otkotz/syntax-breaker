extends Node

var movement_vector: Vector2 = Vector2.ZERO
var input_source: String = "touch"

signal movement_changed(direction: Vector2)

func set_movement(direction: Vector2) -> void:
	movement_vector = direction.normalized() if direction.length() > 0.1 else Vector2.ZERO
	movement_changed.emit(movement_vector)
