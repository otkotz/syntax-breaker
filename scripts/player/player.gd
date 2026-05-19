class_name Player
extends CharacterBody2D

@export var move_speed: float = 250.0
@export var max_hp: float = 100.0

var current_hp: float
var _damage_cooldown: float = 0.0

const IFRAME_DURATION := 0.5

signal hp_changed(current: float, maximum: float)
signal died

func _ready() -> void:
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)

func _process(delta: float) -> void:
	_damage_cooldown = max(_damage_cooldown - delta, 0.0)

func _physics_process(_delta: float) -> void:
	velocity = InputManager.movement_vector * move_speed
	move_and_slide()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(0.27, 0.53, 1.0))

func take_damage(amount: float) -> void:
	if _damage_cooldown > 0.0:
		return
	_damage_cooldown = IFRAME_DURATION
	current_hp = max(current_hp - amount, 0.0)
	hp_changed.emit(current_hp, max_hp)
	_spawn_damage_number(amount)
	modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	if current_hp <= 0.0:
		died.emit()
		GameBus.player_died.emit()

func _spawn_damage_number(amount: float) -> void:
	var dmg_num := DamageNumber.new()
	dmg_num.amount = amount
	dmg_num.global_position = global_position + Vector2(0, -20)
	get_parent().add_child(dmg_num)

func heal(amount: float) -> void:
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)

func set_max_hp(value: float) -> void:
	max_hp = value
	current_hp = min(current_hp, max_hp)
	hp_changed.emit(current_hp, max_hp)
