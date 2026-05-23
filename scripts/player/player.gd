class_name Player
extends CharacterBody2D

@export var move_speed: float = 250.0
@export var max_hp: float = 100.0

var current_hp: float
var _damage_cooldown: float = 0.0
var _base_move_speed: float
var _speed_mult: float = 1.0

const IFRAME_DURATION := 0.5

static var _player_texture: ImageTexture

signal hp_changed(current: float, maximum: float)
signal died

static var _player_offset: Vector2

func _ready() -> void:
	_base_move_speed = move_speed
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	add_to_group("player")
	if not _player_texture:
		var data := PixelSprite.build_circle_texture(16.0, Color(0.27, 0.53, 1.0))
		_player_texture = data["texture"]
		_player_offset = data["offset"]
	var sprite := Sprite2D.new()
	sprite.texture = _player_texture
	sprite.offset = _player_offset
	add_child(sprite)

func _draw() -> void:
	var bar_width := 32.0
	var bar_height := 4.0
	var bar_y := -24.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.15, 0.15, 0.15))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	var bar_color := Color(0.1, 0.85, 0.2) if hp_ratio > 0.3 else Color(0.9, 0.15, 0.1)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), bar_color)

func _process(delta: float) -> void:
	_damage_cooldown = max(_damage_cooldown - delta, 0.0)

func _physics_process(_delta: float) -> void:
	velocity = InputManager.movement_vector * move_speed
	move_and_slide()

func take_damage(amount: float) -> void:
	if _damage_cooldown > 0.0:
		return
	if get_meta("god_mode", false):
		return
	_damage_cooldown = IFRAME_DURATION
	var final_amount := amount * _get_damage_taken_mult()
	current_hp = max(current_hp - final_amount, 0.0)
	hp_changed.emit(current_hp, max_hp)
	queue_redraw()
	_spawn_damage_number(final_amount)
	modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	if current_hp <= 0.0:
		if _try_auto_revive():
			return
		died.emit()
		GameBus.player_died.emit()

func _get_damage_taken_mult() -> float:
	var nodes := get_tree().get_nodes_in_group("consumable_manager")
	if nodes.size() > 0:
		return (nodes[0] as ConsumableManager).get_damage_taken_mult()
	return 1.0

func _try_auto_revive() -> bool:
	var nodes := get_tree().get_nodes_in_group("consumable_manager")
	if nodes.size() > 0:
		var mgr := nodes[0] as ConsumableManager
		if mgr.consume_auto_revive():
			current_hp = max_hp * 0.3
			hp_changed.emit(current_hp, max_hp)
			return true
	return false

func _spawn_damage_number(amount: float) -> void:
	DamageNumber.spawn(get_parent(), global_position + Vector2(0, -20), amount, false, true)

func heal(amount: float) -> void:
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)
	queue_redraw()

func set_max_hp(value: float) -> void:
	max_hp = value
	current_hp = min(current_hp, max_hp)
	hp_changed.emit(current_hp, max_hp)
	queue_redraw()

func set_speed_mult(mult: float) -> void:
	_speed_mult = mult
	move_speed = _base_move_speed * _speed_mult
