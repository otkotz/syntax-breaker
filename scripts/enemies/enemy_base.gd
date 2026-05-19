class_name EnemyBase
extends CharacterBody2D

@export var max_hp: float = 20.0
@export var move_speed: float = 80.0
@export var contact_damage: float = 10.0
@export var gold_value: int = 1
@export var aggro_range: float = 200.0

var current_hp: float
var _target: Node2D
var _dots: Dictionary = {}
var _wander_dir: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0

signal died(enemy: EnemyBase)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	_pick_wander_dir()

func initialize(target: Node2D) -> void:
	_target = target
	current_hp = max_hp
	_dots.clear()
	_pick_wander_dir()
	show()
	set_process(true)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if _target and is_instance_valid(_target):
		var dist := global_position.distance_to(_target.global_position)
		if dist < aggro_range:
			var dir := global_position.direction_to(_target.global_position)
			velocity = dir * move_speed
		else:
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_pick_wander_dir()
			velocity = _wander_dir * move_speed * 0.3
	else:
		velocity = _wander_dir * move_speed * 0.3

	move_and_slide()
	_check_contact_damage()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.27, 0.27))
	_draw_health_bar()

func _draw_health_bar() -> void:
	var bar_width := 24.0
	var bar_height := 3.0
	var bar_y := -18.0
	var bg_rect := Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height))
	draw_rect(bg_rect, Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	var hp_rect := Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height))
	draw_rect(hp_rect, Color(0.1, 0.9, 0.1))

func _check_contact_damage() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() is Player:
			collision.get_collider().take_damage(contact_damage)

func _pick_wander_dir() -> void:
	_wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_wander_timer = randf_range(1.5, 3.0)

func _process(delta: float) -> void:
	var expired: Array = []
	for dot_type: String in _dots:
		var dot: Dictionary = _dots[dot_type]
		dot["timer"] += delta
		dot["remaining"] -= delta
		if dot["timer"] >= dot["interval"]:
			dot["timer"] -= dot["interval"]
			take_damage(dot["damage"])
		if dot["remaining"] <= 0.0:
			expired.append(dot_type)
	for key: String in expired:
		_dots.erase(key)

func take_damage(amount: float) -> void:
	current_hp -= amount
	_flash_hit()
	_spawn_damage_number(amount)
	queue_redraw()
	if current_hp <= 0.0:
		_die()

func _spawn_damage_number(amount: float) -> void:
	var dmg_num := DamageNumber.new()
	dmg_num.amount = amount
	dmg_num.position = Vector2(0, -20)
	add_child(dmg_num)

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
