class_name CameraShake
extends Camera2D

var _shake_strength: float = 0.0
var _shake_decay: float = 0.0

func shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_decay = strength / duration

func _process(delta: float) -> void:
	if _shake_strength > 0.0:
		offset = Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
		_shake_strength = maxf(_shake_strength - _shake_decay * delta, 0.0)
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO
