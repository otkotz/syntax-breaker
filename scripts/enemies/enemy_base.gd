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
var _sprite: Sprite2D
var _facing_right: bool = true

static var _oni_texture: ImageTexture
static var _oni_offset: Vector2

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
	_setup_sprite()

func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	var data := _get_body_texture_data()
	_sprite.texture = data["texture"]
	_sprite.offset = data["offset"]
	add_child(_sprite)

func _get_body_texture_data() -> Dictionary:
	if not _oni_texture:
		var data := _build_oni_texture()
		_oni_texture = data["texture"]
		_oni_offset = data["offset"]
	return {"texture": _oni_texture, "offset": _oni_offset}

static func _build_oni_texture() -> Dictionary:
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

	var r: Array = []
	var _r := func(x: float, y: float, w: float, h: float, c: Color) -> void:
		r.append({"rect": Rect2(x, y, w, h), "color": c})

	# Facing right (f=1): dx as-is
	# legs
	_r.call(-3, -11, 3, 11, PANTS); _r.call(1, -11, 3, 11, PANTS)
	_r.call(-4, -2, 8, 1, PANTS_L); _r.call(-4, 0, 8, 1, OUTLINE)
	# sash
	_r.call(-4, -13, 8, 2, SASH); _r.call(-4, -13, 8, 1, SASH_L); _r.call(-5, -12, 2, 3, SASH)
	# torso
	_r.call(-4, -19, 7, 6, SKIN_M); _r.call(-4, -19, 8, 1, SKIN_M)
	_r.call(-4, -18, 1, 5, SKIN_D); _r.call(3, -18, 1, 5, SKIN_D)
	_r.call(-2, -18, 4, 2, SKIN_L); _r.call(-1, -18, 3, 1, SKIN_H); _r.call(0, -17, 1, 3, SKIN_D)
	# head
	_r.call(-3, -26, 7, 6, SKIN_M); _r.call(-3, -21, 7, 1, SKIN_D)
	_r.call(-3, -26, 1, 6, SKIN_D); _r.call(3, -26, 1, 6, SKIN_D)
	_r.call(-2, -26, 5, 1, SKIN_L); _r.call(-1, -26, 4, 1, SKIN_H)
	# neck
	_r.call(-2, -20, 3, 1, SKIN_D)
	# eyes
	_r.call(-2, -24, 2, 2, OUTLINE); _r.call(1, -24, 2, 2, OUTLINE)
	_r.call(-2, -23, 2, 1, EYE); _r.call(1, -23, 2, 1, EYE)
	# mouth + fangs
	_r.call(-1, -22, 4, 1, OUTLINE); _r.call(-1, -22, 1, 1, FANG); _r.call(2, -22, 1, 1, FANG)
	# horns
	_r.call(-3, -28, 2, 2, HORN_L); _r.call(-4, -30, 2, 2, HORN_L); _r.call(-4, -31, 1, 1, FANG)
	_r.call(-4, -28, 1, 2, HORN_D)
	_r.call(2, -28, 2, 2, HORN_L); _r.call(3, -30, 2, 2, HORN_L); _r.call(4, -31, 1, 1, FANG)
	_r.call(4, -28, 1, 2, HORN_D)
	# sword arm
	_r.call(4, -17, 2, 6, SKIN_M); _r.call(4, -17, 1, 6, SKIN_D); _r.call(5, -11, 2, 1, SKIN_D)
	# sword
	_r.call(6, -18, 1, 3, OUTLINE); _r.call(6, -21, 2, 1, SASH)
	_r.call(6, -35, 1, 14, BLADE_L); _r.call(7, -34, 1, 12, BLADE_D)
	# off arm
	_r.call(-5, -17, 2, 5, SKIN_M); _r.call(-5, -17, 1, 5, SKIN_D); _r.call(-6, -12, 2, 1, SKIN_D)

	return PixelSprite.build_texture(r)

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
			queue_redraw()

	var effective_speed := move_speed * _slow_factor * _get_consumable_slow()

	if _target and is_instance_valid(_target):
		var dist := global_position.distance_to(_target.global_position)
		if dist < 30.0:
			var away := _target.global_position.direction_to(global_position)
			velocity = away * effective_speed * 0.5
		else:
			var dir := global_position.direction_to(_target.global_position)
			velocity = dir * effective_speed
	else:
		velocity = _wander_dir * effective_speed * 0.3

	velocity += _get_separation_force() * effective_speed

	move_and_slide()
	_clamp_to_arena()
	_check_contact_damage()
	_update_facing()
	Targeting.update_position(self)

func _update_facing() -> void:
	if not _sprite:
		return
	var should_face_right := not _target or not is_instance_valid(_target) or _target.global_position.x >= global_position.x
	if should_face_right != _facing_right:
		_facing_right = should_face_right
		_sprite.flip_h = not _facing_right

func _draw() -> void:
	_draw_health_bar()
	_draw_status_icons()

func _draw_health_bar() -> void:
	var bar_width := 24.0
	var bar_height := 3.0
	var bar_y := -38.0
	var bg_rect := Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height))
	draw_rect(bg_rect, Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	var hp_rect := Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height))
	draw_rect(hp_rect, Color(0.1, 0.9, 0.1))

const STATUS_COLORS: Dictionary = {
	"poison": Color(0.2, 0.9, 0.2),
	"burn": Color(1.0, 0.5, 0.1),
	"bleed": Color(0.9, 0.15, 0.15),
	"shock": Color(0.4, 0.8, 1.0),
	"frostblight": Color(0.7, 0.9, 1.0),
}

func _draw_status_icons() -> void:
	var active: Array = []
	for dot_type: String in _dots:
		active.append(dot_type)
	if _slow_timer > 0.0:
		active.append("slow")
	if active.is_empty():
		return
	var icon_size := 4.0
	var gap := 1.0
	var total_w: float = active.size() * icon_size + (active.size() - 1) * gap
	var start_x: float = -total_w / 2.0
	var icon_y := -34.0
	for i: int in active.size():
		var key: String = active[i]
		var col: Color = STATUS_COLORS.get(key, Color(0.5, 0.5, 1.0))
		var x: float = start_x + i * (icon_size + gap)
		draw_rect(Rect2(Vector2(x, icon_y), Vector2(icon_size, icon_size)), col)

func _check_contact_damage() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() is Player:
			collision.get_collider().take_damage(contact_damage)

const SEPARATION_RADIUS := 40.0
const SEPARATION_STRENGTH := 0.6

func _get_separation_force() -> Vector2:
	var force := Vector2.ZERO
	var nearby := Targeting.find_enemies_in_range(global_position, SEPARATION_RADIUS, 6)
	for other: Node2D in nearby:
		if other == self:
			continue
		var away := other.global_position.direction_to(global_position)
		var dist := global_position.distance_to(other.global_position)
		if dist < 1.0:
			away = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			dist = 1.0
		force += away * (1.0 - dist / SEPARATION_RADIUS)
	if force.length_squared() > 0.0:
		force = force.normalized() * SEPARATION_STRENGTH
	return force

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
			var tick_dmg: float = dot["damage"]
			if dot_type == "poison":
				tick_dmg *= EngineTracker.get_virulence_mult(self)
			take_damage(tick_dmg)
		if dot["remaining"] <= 0.0:
			expired.append(dot_type)
	if not expired.is_empty():
		for key: String in expired:
			_dots.erase(key)
		queue_redraw()

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
	DamageNumber.spawn(get_parent(), global_position + Vector2(0, -36), amount, crit)

func is_alive() -> bool:
	return current_hp > 0.0

func apply_slow(factor: float, duration: float) -> void:
	var was_slowed := _slow_timer > 0.0
	_slow_factor = min(_slow_factor, factor)
	_slow_timer = max(_slow_timer, duration)
	modulate.b = 2.0
	if not was_slowed:
		queue_redraw()

func apply_dot(dot_type: String, damage_per_tick: float, duration: float, tick_interval: float) -> void:
	var is_new := dot_type not in _dots
	_dots[dot_type] = {
		"damage": damage_per_tick,
		"remaining": duration,
		"interval": tick_interval,
		"timer": 0.0,
	}
	if is_new:
		queue_redraw()

func _die() -> void:
	DeathEffect.spawn(get_parent(), global_position + Vector2(0, -14), _dots)
	Targeting.unregister(self)
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
	_facing_right = true
	show()
	set_process(true)
	set_physics_process(true)
	if _sprite:
		_sprite.flip_h = false

static var _cached_consumable_slow: float = 1.0
static var _consumable_slow_frame: int = -1

func _get_consumable_slow() -> float:
	var frame := Engine.get_process_frames()
	if frame == _consumable_slow_frame:
		return _cached_consumable_slow
	_consumable_slow_frame = frame
	var nodes := get_tree().get_nodes_in_group("consumable_manager")
	if nodes.size() > 0:
		_cached_consumable_slow = (nodes[0] as ConsumableManager).get_enemy_speed_mult()
	else:
		_cached_consumable_slow = 1.0
	return _cached_consumable_slow
