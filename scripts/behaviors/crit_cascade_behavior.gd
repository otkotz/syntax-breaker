class_name CritCascadeBehavior
extends BehaviorBase

const BASE_BONUS := 0.20
const DURATION := 1.0
const MAX_Q_BONUS := 0.30
const MAX_Q_DURATION := 1.5

static var _bonus_active: bool = false
static var _bonus_timer: float = 0.0
static var _bonus_amount: float = 0.0

func on_crit(_skill_instance, _target: Node2D, _projectile: Node2D) -> void:
	_bonus_amount = MAX_Q_BONUS if is_max_quality() else BASE_BONUS
	_bonus_active = true
	_bonus_timer = MAX_Q_DURATION if is_max_quality() else DURATION

static func get_cascade_bonus() -> float:
	if _bonus_active and _bonus_timer > 0.0:
		return _bonus_amount
	return 0.0

static func consume() -> void:
	_bonus_active = false
	_bonus_timer = 0.0

static func tick(delta: float) -> void:
	if _bonus_timer > 0.0:
		_bonus_timer -= delta
		if _bonus_timer <= 0.0:
			_bonus_active = false

static func clear() -> void:
	_bonus_active = false
	_bonus_timer = 0.0
	_bonus_amount = 0.0
