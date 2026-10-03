class_name Player
extends CharacterBody2D

@export var move_speed: float = 250.0
@export var max_hp: float = 100.0

var current_hp: float
var _damage_cooldown: float = 0.0
var _base_move_speed: float
var _speed_mult: float = 1.0
var _passive_speed_mult: float = 1.0

const IFRAME_DURATION := 0.5

@export var energy_element: String = "cold"

var _anim_sprite: AnimatedSprite2D
var _cast_timer: float = 0.0
var _facing: String = "S"
const CAST_ANIM_DURATION := 0.3
const FACE_RANGE := 1200.0

signal hp_changed(current: float, maximum: float)
signal died

func _ready() -> void:
	_base_move_speed = move_speed
	_apply_run_passives()
	current_hp = clampf(RunManager.current_hp / maxf(RunManager.max_hp, 1.0) * max_hp, 0.0, max_hp)
	hp_changed.connect(RunManager.sync_health)
	hp_changed.emit(current_hp, max_hp)
	add_to_group("player")
	_setup_animated_sprite()
	_connect_caster()

func _apply_run_passives() -> void:
	var hp_bonus := 0.0
	var speed_bonus := 0.0
	for res: Resource in RunManager.owned_passives:
		if not res is PassiveResource:
			continue
		var modifiers: Dictionary = res.stat_modifiers
		hp_bonus += float(modifiers.get("max_hp_mult", 1.0)) - 1.0
		# Other speed modifiers affect projectiles through StatCalculator.
		if res.id == "swift_feet":
			speed_bonus += float(modifiers.get("speed_mult", 1.0)) - 1.0
	max_hp *= maxf(0.1, 1.0 + hp_bonus)
	_passive_speed_mult = maxf(0.1, 1.0 + speed_bonus)
	move_speed = _base_move_speed * _passive_speed_mult

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
	var pal := CosmeticStyles.player_palette(energy_element)

	# Procedurally generate idle / walk / cast for all 8 facing directions.
	for dir: String in BreakerSprite.DIRS:
		_build_mode(frames, pal, "idle", dir, 8.0, true)
		_build_mode(frames, pal, "walk", dir, 12.0, true)
		_build_mode(frames, pal, "cast", dir, 16.0, true)

	frames.remove_animation(&"default")
	_anim_sprite.sprite_frames = frames
	_anim_sprite.animation = _anim_name("idle", _facing)
	_anim_sprite.play()
	_anim_sprite.scale = Vector2(1.5, 1.5)
	add_child(_anim_sprite)

func _build_mode(frames: SpriteFrames, pal: PackedColorArray, mode: String, dir: String, speed: float, loops: bool) -> void:
	var anim := _anim_name(mode, dir)
	frames.add_animation(anim)
	frames.set_animation_speed(anim, speed)
	frames.set_animation_loop(anim, loops)
	for frame in 5:
		frames.add_frame(anim, BreakerSprite.build_texture(dir, frame, mode, pal))

func _anim_name(mode: String, dir: String) -> StringName:
	return StringName(mode + "_" + dir)

func _update_animation() -> void:
	var mode: String
	if _cast_timer > 0.0:
		mode = "cast"
		_face_nearest_enemy()
	elif velocity.length_squared() > 10.0:
		mode = "walk"
		_facing = _dir_from_vector(velocity)
	else:
		mode = "idle"
	var target_anim := _anim_name(mode, _facing)
	if _anim_sprite.animation != target_anim:
		_anim_sprite.play(target_anim)

func _face_nearest_enemy() -> void:
	var target := Targeting.find_nearest_enemy(global_position, FACE_RANGE)
	if target:
		_facing = _dir_from_vector(global_position.direction_to(target.global_position))
	elif velocity.length_squared() > 10.0:
		_facing = _dir_from_vector(velocity)

func _dir_from_vector(v: Vector2) -> String:
	# Screen space (y down): E=0°, S=90°, W=180°, N=-90°.
	var idx := int(roundi(rad_to_deg(v.angle()) / 45.0)) % 8
	if idx < 0:
		idx += 8
	return ["E", "SE", "S", "SW", "W", "NW", "N", "NE"][idx]

func _connect_caster() -> void:
	var caster := get_node_or_null("SkillCaster") as SkillCaster
	if caster:
		caster.spell_cast.connect(_on_spell_cast)

func _on_spell_cast() -> void:
	_cast_timer = CAST_ANIM_DURATION

static func hurt(target: Node2D, amount: float, source: String) -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	if target is Player:
		target.take_damage(amount, source)
	else:
		target.take_damage(amount)

func take_damage(amount: float, source: String = "unknown") -> void:
	if current_hp <= 0.0 or amount <= 0.0:
		return
	if _damage_cooldown > 0.0:
		return
	if get_meta("god_mode", false):
		return
	_damage_cooldown = IFRAME_DURATION
	var final_amount := amount * _get_damage_taken_mult()
	var before := current_hp
	RunManager.run_stats["last_damage_source"] = source
	RunTelemetry.record("player_damage", {"source": source, "amount": minf(current_hp, final_amount),
		"hp_before": before, "hp_after": maxf(0.0, before - final_amount), "x": global_position.x, "y": global_position.y})
	RunManager.record_stat("damage_taken", minf(current_hp, final_amount))
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
		RunManager.run_stats["death_source"] = source
		RunTelemetry.record("player_death", {"source": source, "x": global_position.x, "y": global_position.y})
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
			RunManager.record_stat("healing_received", current_hp)
			RunTelemetry.record("player_revive", {"hp": current_hp})
			hp_changed.emit(current_hp, max_hp)
			return true
	return false

func _spawn_damage_number(amount: float) -> void:
	DamageNumber.spawn(get_parent(), global_position + Vector2(0, -20), amount, false, true)

func heal(amount: float) -> void:
	RunManager.record_stat("healing_received", minf(max_hp - current_hp, maxf(amount, 0.0)))
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)
	queue_redraw()

func set_max_hp(value: float) -> void:
	var ratio := current_hp / maxf(max_hp, 1.0)
	max_hp = value
	current_hp = max_hp * ratio
	hp_changed.emit(current_hp, max_hp)
	queue_redraw()

func set_speed_mult(mult: float) -> void:
	_speed_mult = mult
	move_speed = _base_move_speed * _passive_speed_mult * _speed_mult
