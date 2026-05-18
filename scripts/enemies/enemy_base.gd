class_name EnemyBase
extends CharacterBody2D

@export var max_hp: float = 20.0
@export var move_speed: float = 80.0
@export var contact_damage: float = 10.0
@export var gold_value: int = 1

var current_hp: float
var _target: Node2D
var _dots: Dictionary = {}

signal died(enemy: EnemyBase)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")

func initialize(target: Node2D) -> void:
	_target = target
	current_hp = max_hp
	_dots.clear()
	show()
	set_process(true)
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if _target and is_instance_valid(_target):
		var dir := global_position.direction_to(_target.global_position)
		velocity = dir * move_speed
		move_and_slide()

func _process(delta: float) -> void:
	var expired: Array = []
	for dot_type in _dots:
		var dot: Dictionary = _dots[dot_type]
		dot["timer"] += delta
		dot["remaining"] -= delta
		if dot["timer"] >= dot["interval"]:
			dot["timer"] -= dot["interval"]
			take_damage(dot["damage"])
		if dot["remaining"] <= 0.0:
			expired.append(dot_type)
	for key in expired:
		_dots.erase(key)

func take_damage(amount: float) -> void:
	current_hp -= amount
	_flash_hit()
	if current_hp <= 0.0:
		_die()

func is_alive() -> bool:
	return current_hp > 0.0

func apply_dot(dot_type: String, damage_per_tick: float, duration: float, tick_interval: float) -> void:
	_dots[dot_type] = {
		"damage": damage_per_tick,
		"remaining": duration,
		"interval": tick_interval,
		"timer": 0.0,
	}

func _die() -> void:
	RunManager.add_gold(gold_value)
	RunManager.record_stat("enemies_killed", 1)
	GameBus.enemy_killed.emit(self, null)
	died.emit(self)
	set_process(false)
	set_physics_process(false)
	hide()

func _flash_hit() -> void:
	modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func reset() -> void:
	current_hp = max_hp
	modulate = Color.WHITE
	velocity = Vector2.ZERO
	_target = null
	_dots.clear()
