class_name Player
extends CharacterBody2D

@export var move_speed: float = 250.0
@export var max_hp: float = 100.0

var current_hp: float
var _damage_cooldown: float = 0.0
var _base_move_speed: float
var _speed_mult: float = 1.0

const IFRAME_DURATION := 0.5

var _anim_sprite: AnimatedSprite2D
var _cast_timer: float = 0.0
const CAST_ANIM_DURATION := 0.3

signal hp_changed(current: float, maximum: float)
signal died

func _ready() -> void:
	_base_move_speed = move_speed
	current_hp = max_hp
	hp_changed.emit(current_hp, max_hp)
	add_to_group("player")
	_setup_animated_sprite()
	_connect_caster()

func _draw() -> void:
	var bar_width := 40.0
	var bar_height := 4.0
	var bar_y := -36.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.15, 0.15, 0.15))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	var bar_color := Color(0.1, 0.85, 0.2) if hp_ratio > 0.3 else Color(0.9, 0.15, 0.1)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), bar_color)

func _process(delta: float) -> void:
	_damage_cooldown = max(_damage_cooldown - delta, 0.0)
	if _cast_timer > 0.0:
		_cast_timer -= delta

func _physics_process(_delta: float) -> void:
	velocity = InputManager.movement_vector * move_speed
	move_and_slide()
	_update_animation()

func _setup_animated_sprite() -> void:
	_anim_sprite = AnimatedSprite2D.new()
	_anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()

	var idle_sheet: Texture2D = load("res://assets/sprites/player_idle.png")
	var walk_sheet: Texture2D = load("res://assets/sprites/player_walk.png")
	var cast_sheet: Texture2D = load("res://assets/sprites/player_cast.png")

	var idle_cols := 5
	var idle_rows := 5
	var idle_frame_w := idle_sheet.get_width() / idle_cols
	var idle_frame_h := idle_sheet.get_height() / idle_rows
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 10.0)
	frames.set_animation_loop(&"idle", true)
	for row in idle_rows:
		for col in idle_cols:
			var atlas := AtlasTexture.new()
			atlas.atlas = idle_sheet
			atlas.region = Rect2(col * idle_frame_w, row * idle_frame_h, idle_frame_w, idle_frame_h)
			frames.add_frame(&"idle", atlas)

	var walk_cols := 5
	var walk_rows := 5
	var walk_frame_w := walk_sheet.get_width() / walk_cols
	var walk_frame_h := walk_sheet.get_height() / walk_rows
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", 15.0)
	frames.set_animation_loop(&"walk", true)
	for row in walk_rows:
		for col in walk_cols:
			var atlas := AtlasTexture.new()
			atlas.atlas = walk_sheet
			atlas.region = Rect2(col * walk_frame_w, row * walk_frame_h, walk_frame_w, walk_frame_h)
			frames.add_frame(&"walk", atlas)

	frames.add_animation(&"cast")
	frames.set_animation_speed(&"cast", 6.0)
	frames.set_animation_loop(&"cast", true)
	for i in 4:
		var atlas := AtlasTexture.new()
		atlas.atlas = cast_sheet
		atlas.region = Rect2(i * 64, 0, 64, 64)
		frames.add_frame(&"cast", atlas)

	frames.remove_animation(&"default")
	_anim_sprite.sprite_frames = frames
	_anim_sprite.animation = &"idle"
	_anim_sprite.play()
	_anim_sprite.scale = Vector2(0.5, 0.5)
	add_child(_anim_sprite)

func _update_animation() -> void:
	var target_anim: StringName
	if _cast_timer > 0.0:
		target_anim = &"cast"
	elif velocity.length_squared() > 10.0:
		target_anim = &"walk"
	else:
		target_anim = &"idle"
	if _anim_sprite.animation != target_anim:
		_anim_sprite.play(target_anim)

func _connect_caster() -> void:
	var caster := get_node_or_null("SkillCaster") as SkillCaster
	if caster:
		caster.spell_cast.connect(_on_spell_cast)

func _on_spell_cast() -> void:
	_cast_timer = CAST_ANIM_DURATION

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
	_anim_sprite.modulate = Color(10, 10, 10)
	var tween := create_tween()
	tween.tween_property(_anim_sprite, "modulate", Color.WHITE, 0.15)
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
