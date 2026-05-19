class_name MiniBoss
extends EnemyBase

enum Phase { CHASE, TELEGRAPH, CHARGE, COOLDOWN }

@export var charge_speed: float = 400.0
@export var telegraph_duration: float = 0.8
@export var charge_duration: float = 0.5
@export var cooldown_duration: float = 1.5
@export var ability_interval: float = 3.0

var _phase: Phase = Phase.CHASE
var _phase_timer: float = 0.0
var _ability_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return

	match _phase:
		Phase.CHASE:
			_chase(delta)
		Phase.TELEGRAPH:
			_telegraph(delta)
		Phase.CHARGE:
			_charge(delta)
		Phase.COOLDOWN:
			_cooldown(delta)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 24.0, Color(0.8, 0.13, 0.13))

func _chase(delta: float) -> void:
	var dir := global_position.direction_to(_target.global_position)
	velocity = dir * move_speed
	move_and_slide()
	_check_contact_damage()

	_ability_timer += delta
	if _ability_timer >= ability_interval:
		_ability_timer = 0.0
		_start_telegraph()

func _start_telegraph() -> void:
	_phase = Phase.TELEGRAPH
	_phase_timer = telegraph_duration
	_charge_dir = global_position.direction_to(_target.global_position)
	modulate = Color(1.5, 0.3, 0.3)

func _telegraph(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase = Phase.CHARGE
		_phase_timer = charge_duration

func _charge(delta: float) -> void:
	velocity = _charge_dir * charge_speed
	move_and_slide()
	_check_contact_damage()
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase = Phase.COOLDOWN
		_phase_timer = cooldown_duration
		modulate = Color(0.7, 0.7, 0.7)

func _cooldown(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase = Phase.CHASE
		modulate = Color.WHITE

func _die() -> void:
	RunManager.record_stat("mini_bosses_killed", 1)
	super._die()
