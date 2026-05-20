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
var _arena_rect: Rect2
var _slow_factor: float = 1.0
var _slow_timer: float = 0.0
var _base_max_hp: float
var _base_move_speed: float
var _base_contact_damage: float
var _base_gold_value: int

signal died(enemy: EnemyBase)

func get_enemy_id() -> String:
	return scene_file_path.get_file().get_basename() if not scene_file_path.is_empty() else get_class()

func _ready() -> void:
	_base_max_hp = max_hp
	_base_move_speed = move_speed
	_base_contact_damage = contact_damage
	_base_gold_value = gold_value
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
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0
			modulate.b = 1.0

	var effective_speed := move_speed * _slow_factor

	if _target and is_instance_valid(_target):
		var dist := global_position.distance_to(_target.global_position)
		if dist < 30.0:
			var away := _target.global_position.direction_to(global_position)
			velocity = away * effective_speed * 0.5
		elif dist < aggro_range:
			var dir := global_position.direction_to(_target.global_position)
			velocity = dir * effective_speed
		else:
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_pick_wander_dir()
			velocity = _wander_dir * effective_speed * 0.3
	else:
		velocity = _wander_dir * effective_speed * 0.3

	move_and_slide()
	_clamp_to_arena()
	_check_contact_damage()

func _draw() -> void:
	_draw_body()
	_draw_health_bar()

func _draw_body() -> void:
	var f := 1.0 if _target and is_instance_valid(_target) and _target.global_position.x >= global_position.x else -1.0
	_draw_oni(f)

func _draw_oni(f: float) -> void:
	const OUTLINE := Color(0.04, 0.01, 0.02)
	const SKIN_D := Color(0.23, 0.04, 0.08)
	const SKIN_M := Color(0.54, 0.12, 0.17)
	const SKIN_L := Color(0.84, 0.23, 0.28)
	const SKIN_H := Color(0.97, 0.54, 0.54)
	const EYE := Color(1.0, 0.85, 0.3)
	const FANG := Color(0.96, 0.91, 0.82)
	const HORN_D := Color(0.23, 0.15, 0.09)
	const HORN_L := Color(0.75, 0.63, 0.46)
	const PANTS := Color(0.1, 0.04, 0.09)
	const PANTS_L := Color(0.16, 0.08, 0.16)
	const SASH := Color(0.48, 0.09, 0.13)
	const SASH_L := Color(0.84, 0.23, 0.28)
	const BLADE_D := Color(0.35, 0.38, 0.46)
	const BLADE_L := Color(0.88, 0.91, 0.96)

	var fx := func(dx: float, w: float) -> float:
		return (dx if f > 0 else -dx - w)

	# feet y = 0, body goes upward
	# legs -11 to 0
	draw_rect(Rect2(Vector2(fx.call(-3, 3), -11), Vector2(3, 11)), PANTS)
	draw_rect(Rect2(Vector2(fx.call(1, 3), -11), Vector2(3, 11)), PANTS)
	draw_rect(Rect2(Vector2(fx.call(-4, 8), -2), Vector2(8, 1)), PANTS_L)
	draw_rect(Rect2(Vector2(fx.call(-4, 8), 0), Vector2(8, 1)), OUTLINE)
	# sash -13 to -11
	draw_rect(Rect2(Vector2(fx.call(-4, 8), -13), Vector2(8, 2)), SASH)
	draw_rect(Rect2(Vector2(fx.call(-4, 8), -13), Vector2(8, 1)), SASH_L)
	draw_rect(Rect2(Vector2(fx.call(-5, 2), -12), Vector2(2, 3)), SASH)
	# torso -19 to -13
	draw_rect(Rect2(Vector2(fx.call(-4, 7), -19), Vector2(7, 6)), SKIN_M)
	draw_rect(Rect2(Vector2(fx.call(-4, 8), -19), Vector2(8, 1)), SKIN_M)
	draw_rect(Rect2(Vector2(fx.call(-4, 1), -18), Vector2(1, 5)), SKIN_D)
	draw_rect(Rect2(Vector2(fx.call(3, 1), -18), Vector2(1, 5)), SKIN_D)
	draw_rect(Rect2(Vector2(fx.call(-2, 4), -18), Vector2(4, 2)), SKIN_L)
	draw_rect(Rect2(Vector2(fx.call(-1, 3), -18), Vector2(3, 1)), SKIN_H)
	draw_rect(Rect2(Vector2(fx.call(0, 1), -17), Vector2(1, 3)), SKIN_D)
	# head -26 to -20
	draw_rect(Rect2(Vector2(fx.call(-3, 7), -26), Vector2(7, 6)), SKIN_M)
	draw_rect(Rect2(Vector2(fx.call(-3, 7), -21), Vector2(7, 1)), SKIN_D)
	draw_rect(Rect2(Vector2(fx.call(-3, 1), -26), Vector2(1, 6)), SKIN_D)
	draw_rect(Rect2(Vector2(fx.call(3, 1), -26), Vector2(1, 6)), SKIN_D)
	draw_rect(Rect2(Vector2(fx.call(-2, 5), -26), Vector2(5, 1)), SKIN_L)
	draw_rect(Rect2(Vector2(fx.call(-1, 4), -26), Vector2(4, 1)), SKIN_H)
	# neck
	draw_rect(Rect2(Vector2(fx.call(-2, 3), -20), Vector2(3, 1)), SKIN_D)
	# eyes
	draw_rect(Rect2(Vector2(fx.call(-2, 2), -24), Vector2(2, 2)), OUTLINE)
	draw_rect(Rect2(Vector2(fx.call(1, 2), -24), Vector2(2, 2)), OUTLINE)
	draw_rect(Rect2(Vector2(fx.call(-2, 2), -23), Vector2(2, 1)), EYE)
	draw_rect(Rect2(Vector2(fx.call(1, 2), -23), Vector2(2, 1)), EYE)
	# mouth + fangs
	draw_rect(Rect2(Vector2(fx.call(-1, 4), -22), Vector2(4, 1)), OUTLINE)
	draw_rect(Rect2(Vector2(fx.call(-1, 1), -22), Vector2(1, 1)), FANG)
	draw_rect(Rect2(Vector2(fx.call(2, 1), -22), Vector2(1, 1)), FANG)
	# horns
	draw_rect(Rect2(Vector2(fx.call(-3, 2), -28), Vector2(2, 2)), HORN_L)
	draw_rect(Rect2(Vector2(fx.call(-4, 2), -30), Vector2(2, 2)), HORN_L)
	draw_rect(Rect2(Vector2(fx.call(-4, 1), -31), Vector2(1, 1)), FANG)
	draw_rect(Rect2(Vector2(fx.call(-4, 1), -28), Vector2(1, 2)), HORN_D)
	draw_rect(Rect2(Vector2(fx.call(2, 2), -28), Vector2(2, 2)), HORN_L)
	draw_rect(Rect2(Vector2(fx.call(3, 2), -30), Vector2(2, 2)), HORN_L)
	draw_rect(Rect2(Vector2(fx.call(4, 1), -31), Vector2(1, 1)), FANG)
	draw_rect(Rect2(Vector2(fx.call(4, 1), -28), Vector2(1, 2)), HORN_D)
	# sword arm + blade
	draw_rect(Rect2(Vector2(fx.call(4, 2), -17), Vector2(2, 6)), SKIN_M)
	draw_rect(Rect2(Vector2(fx.call(4, 1), -17), Vector2(1, 6)), SKIN_D)
	draw_rect(Rect2(Vector2(fx.call(5, 2), -11), Vector2(2, 1)), SKIN_D)
	# sword
	draw_rect(Rect2(Vector2(fx.call(6, 1), -18), Vector2(1, 3)), OUTLINE)
	draw_rect(Rect2(Vector2(fx.call(6, 2), -21), Vector2(2, 1)), SASH)
	draw_rect(Rect2(Vector2(fx.call(6, 1), -35), Vector2(1, 14)), BLADE_L)
	draw_rect(Rect2(Vector2(fx.call(7, 1), -34), Vector2(1, 12)), BLADE_D)
	# off arm
	draw_rect(Rect2(Vector2(fx.call(-5, 2), -17), Vector2(2, 5)), SKIN_M)
	draw_rect(Rect2(Vector2(fx.call(-5, 1), -17), Vector2(1, 5)), SKIN_D)
	draw_rect(Rect2(Vector2(fx.call(-6, 2), -12), Vector2(2, 1)), SKIN_D)

func _draw_health_bar() -> void:
	var bar_width := 24.0
	var bar_height := 3.0
	var bar_y := -38.0
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

func _clamp_to_arena() -> void:
	if _arena_rect.size != Vector2.ZERO:
		global_position = global_position.clamp(
			_arena_rect.position + Vector2(16, 16),
			_arena_rect.end - Vector2(16, 16)
		)

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

func take_damage(amount: float, crit: bool = false) -> void:
	if current_hp <= 0.0:
		return
	current_hp -= amount
	_flash_hit()
	_spawn_damage_number(amount, crit)
	queue_redraw()
	if current_hp <= 0.0:
		_die()

func _spawn_damage_number(amount: float, crit: bool = false) -> void:
	var dmg_num := DamageNumber.new()
	dmg_num.amount = amount
	dmg_num.is_crit = crit
	dmg_num.global_position = global_position + Vector2(0, -36)
	get_parent().add_child(dmg_num)

func is_alive() -> bool:
	return current_hp > 0.0

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = min(_slow_factor, factor)
	_slow_timer = max(_slow_timer, duration)
	modulate.b = 2.0

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
	collision_layer = 0
	collision_mask = 0
	hide()

func _flash_hit() -> void:
	modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func apply_scaling(hp_mult: float, speed_mult: float, damage_mult: float, gold_mult: float) -> void:
	max_hp = _base_max_hp * hp_mult
	current_hp = max_hp
	move_speed = _base_move_speed * speed_mult
	contact_damage = _base_contact_damage * damage_mult
	gold_value = int(_base_gold_value * gold_mult)
	queue_redraw()

func reset() -> void:
	max_hp = _base_max_hp
	current_hp = max_hp
	move_speed = _base_move_speed
	contact_damage = _base_contact_damage
	gold_value = _base_gold_value
	modulate = Color.WHITE
	velocity = Vector2.ZERO
	collision_layer = 2
	collision_mask = 5
	_target = null
	_dots.clear()
	_slow_factor = 1.0
	_slow_timer = 0.0
