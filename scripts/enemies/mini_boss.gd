class_name MiniBoss
extends EnemyBase

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")

enum Phase { CHASE, TELEGRAPH, ATTACK, COOLDOWN }
enum Attack { CHARGE, SLAM, VOLLEY }

@export var charge_speed: float = 400.0
@export var telegraph_duration: float = 0.8
@export var charge_duration: float = 0.5
@export var cooldown_duration: float = 1.5
@export var ability_interval: float = 3.0

var _phase: Phase = Phase.CHASE
var _phase_timer: float = 0.0
var _ability_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO
var _is_boss_mode: bool = false

var _current_attack: Attack = Attack.CHARGE
var _slam_target: Vector2 = Vector2.ZERO
var _slam_origin: Vector2 = Vector2.ZERO
var _attack_count: int = 0
var _telegraph_indicator: Node2D

# Each region has its own boss sprite. Sprites are authored at different native
# resolutions, so each carries a display scale that lands it at a comparable,
# imposing on-screen height (~2× a heavy).
const BOSS_BY_REGION := {
	"burning_grounds": "demon",
	"toxic_depths": "monarch",
	"storm_spire": "overseer",
}
const BOSS_SCALE := {
	"demon": 0.8,
	"monarch": 0.85,
	"overseer": 1.0,
}
const DEFAULT_BOSS := "demon"

# Built once per boss type, keyed by type -> Array of variant textures.
static var _boss_variants_by_type: Dictionary = {}
static var _projectile_pool: ObjectPool

const SLAM_RADIUS := 120.0
const SLAM_DAMAGE_MULT := 1.5
const VOLLEY_COUNT := 8
const VOLLEY_SPEED := 180.0

func _boss_type() -> String:
	return BOSS_BY_REGION.get(RunManager.current_region, DEFAULT_BOSS)

func _setup_sprite() -> void:
	super._setup_sprite()
	var s: float = BOSS_SCALE.get(_boss_type(), 0.8)
	_sprite.scale = Vector2(s, s)

# Region boss — built once per type, three corruption accents each.
func _get_body_variants() -> Array:
	var t := _boss_type()
	if not _boss_variants_by_type.has(t):
		_boss_variants_by_type[t] = _build_boss_variants(t)
	return _boss_variants_by_type[t]

func _build_boss_variants(boss_type: String) -> Array:
	match boss_type:
		"monarch":
			return [MonarchSprite.build("toxic"), MonarchSprite.build("royal"), MonarchSprite.build("red")]
		"overseer":
			return [OverseerSprite.build("system"), OverseerSprite.build("lightning"), OverseerSprite.build("void")]
		_:
			return [DemonSprite.build("fire"), DemonSprite.build("red"), DemonSprite.build("void")]

func set_as_boss() -> void:
	_is_boss_mode = true
	scale = Vector2(1.8, 1.8)
	if _sprite:
		_sprite.modulate = Color(1.3, 1.0, 0.7)

func _draw_health_bar() -> void:
	var bar_width := 72.0 if _is_boss_mode else 48.0
	var bar_height := 5.0 if _is_boss_mode else 4.0
	var bar_y := -85.0 if _is_boss_mode else -80.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	var bar_color := Color(1.0, 0.75, 0.1) if _is_boss_mode else Color(0.85, 0.15, 0.15)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), bar_color)

# --- Attack selection ---

func _pick_attack() -> Attack:
	_attack_count += 1
	if _attack_count <= 1:
		return Attack.CHARGE
	var roll := randf()
	if _is_boss_mode:
		if roll < 0.35: return Attack.CHARGE
		if roll < 0.65: return Attack.SLAM
		return Attack.VOLLEY
	else:
		return Attack.CHARGE if roll < 0.55 else Attack.SLAM

# --- Phase machine ---

func _physics_process(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return

	match _phase:
		Phase.CHASE:
			_chase(delta)
		Phase.TELEGRAPH:
			_telegraph(delta)
		Phase.ATTACK:
			_do_attack(delta)
		Phase.COOLDOWN:
			_cooldown(delta)

func _chase(delta: float) -> void:
	var dist := global_position.distance_to(_target.global_position)
	if dist < 40.0:
		var away := _target.global_position.direction_to(global_position)
		velocity = away * move_speed * 0.5
	else:
		var dir := global_position.direction_to(_target.global_position)
		velocity = dir * move_speed
	velocity += _get_separation_force() * move_speed
	move_and_slide()
	_clamp_to_arena()
	_check_contact_damage()
	_update_facing()
	Targeting.update_position(self)

	_ability_timer += delta
	if _ability_timer >= ability_interval:
		_ability_timer = 0.0
		_begin_telegraph()

func _begin_telegraph() -> void:
	_current_attack = _pick_attack()
	_phase = Phase.TELEGRAPH
	velocity = Vector2.ZERO

	match _current_attack:
		Attack.CHARGE:
			_phase_timer = telegraph_duration
			_charge_dir = global_position.direction_to(_target.global_position)
			modulate = Color(1.5, 0.3, 0.3)
		Attack.SLAM:
			_phase_timer = 1.0
			_slam_target = _target.global_position
			_slam_origin = global_position
			modulate = Color(1.5, 0.8, 0.2)
			_spawn_slam_indicator()
		Attack.VOLLEY:
			_phase_timer = 0.9
			modulate = Color(0.6, 0.3, 1.5)

func _telegraph(delta: float) -> void:
	_phase_timer -= delta
	queue_redraw()

	if _current_attack == Attack.SLAM:
		var t := 1.0 - _phase_timer
		var lift := sin(t * PI) * 8.0
		if _sprite:
			_sprite.position.y = -lift

	if _phase_timer <= 0.0:
		_phase = Phase.ATTACK
		_execute_attack()

func _execute_attack() -> void:
	match _current_attack:
		Attack.CHARGE:
			_phase_timer = charge_duration
		Attack.SLAM:
			_phase_timer = 0.15
			global_position = _slam_target
			if _sprite:
				_sprite.position.y = 0.0
			_slam_hit()
			_remove_slam_indicator()
		Attack.VOLLEY:
			_phase_timer = 0.3
			_fire_volley()

func _do_attack(delta: float) -> void:
	match _current_attack:
		Attack.CHARGE:
			velocity = _charge_dir * charge_speed
			move_and_slide()
			_clamp_to_arena()
			_check_contact_damage()
			_update_facing()
			Targeting.update_position(self)

	_phase_timer -= delta
	queue_redraw()
	if _phase_timer <= 0.0:
		_phase = Phase.COOLDOWN
		_phase_timer = cooldown_duration
		modulate = Color(0.7, 0.7, 0.7)

func _cooldown(delta: float) -> void:
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase = Phase.CHASE
		modulate = Color.WHITE

# --- Slam ---

func _spawn_slam_indicator() -> void:
	_remove_slam_indicator()
	_telegraph_indicator = _SlamIndicator.new()
	(_telegraph_indicator as _SlamIndicator).radius = SLAM_RADIUS
	get_parent().add_child(_telegraph_indicator)
	_telegraph_indicator.global_position = _slam_target

func _remove_slam_indicator() -> void:
	if _telegraph_indicator and is_instance_valid(_telegraph_indicator):
		_telegraph_indicator.queue_free()
		_telegraph_indicator = null

func _slam_hit() -> void:
	var damage: float = contact_damage * SLAM_DAMAGE_MULT
	var players := get_tree().get_nodes_in_group("player")
	for p: Node2D in players:
		if p.global_position.distance_to(_slam_target) <= SLAM_RADIUS:
			if p.has_method("take_damage"):
				p.take_damage(damage)
	_spawn_slam_shockwave()

func _spawn_slam_shockwave() -> void:
	var wave := _Shockwave.new()
	wave.max_radius = SLAM_RADIUS
	get_parent().add_child(wave)
	wave.global_position = _slam_target

# --- Volley ---

func _fire_volley() -> void:
	if not _projectile_pool or not is_instance_valid(_projectile_pool._parent):
		_projectile_pool = ObjectPool.new(ENEMY_PROJECTILE_SCENE, 16, get_tree().current_scene)
	var count := VOLLEY_COUNT + (4 if _is_boss_mode else 0)
	var offset_angle := randf() * TAU
	for i in count:
		var angle := offset_angle + (float(i) / count) * TAU
		var dir := Vector2.from_angle(angle)
		var proj := _projectile_pool.get_instance() as EnemyProjectile
		if proj:
			var dmg := contact_damage * 0.6
			proj.initialize(dir, VOLLEY_SPEED, dmg, global_position, _projectile_pool)

# --- Draw telegraph indicators on boss ---

func _draw() -> void:
	_draw_health_bar()
	_draw_status_icons()
	if _phase != Phase.TELEGRAPH:
		return

	match _current_attack:
		Attack.CHARGE:
			var line_end := _charge_dir * 200.0
			var alpha := 0.4 + 0.3 * sin(_phase_timer * 12.0)
			draw_line(Vector2.ZERO, line_end, Color(1.0, 0.2, 0.1, alpha), 3.0)
		Attack.VOLLEY:
			var pulse := 0.3 + 0.2 * sin(_phase_timer * 10.0)
			draw_arc(Vector2.ZERO, 40.0, 0, TAU, 16, Color(0.6, 0.2, 1.0, pulse), 2.0)
			draw_arc(Vector2.ZERO, 60.0, 0, TAU, 20, Color(0.6, 0.2, 1.0, pulse * 0.5), 1.5)

# --- Reset ---

func reset() -> void:
	super.reset()
	_phase = Phase.CHASE
	_phase_timer = 0.0
	_ability_timer = 0.0
	_charge_dir = Vector2.ZERO
	_current_attack = Attack.CHARGE
	_attack_count = 0
	_remove_slam_indicator()
	if _sprite:
		_sprite.position.y = 0.0
	if _is_boss_mode:
		_is_boss_mode = false
		scale = Vector2.ONE
		if _sprite:
			_sprite.modulate = Color.WHITE

func _die() -> void:
	_remove_slam_indicator()
	if _sprite:
		_sprite.position.y = 0.0
	RunManager.record_stat("mini_bosses_killed", 1)
	super._die()

# --- Inner classes for visual effects ---

class _SlamIndicator extends Node2D:
	var radius: float = 120.0
	var _timer: float = 0.0

	func _process(delta: float) -> void:
		_timer += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.3 * sin(_timer * 10.0)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(1.0, 0.5, 0.1, pulse), 2.0)
		var inner := radius * (0.3 + 0.15 * sin(_timer * 8.0))
		draw_arc(Vector2.ZERO, inner, 0, TAU, 16, Color(1.0, 0.8, 0.2, pulse * 0.6), 1.5)
		draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.9, 0.3, pulse))

class _Shockwave extends Node2D:
	var max_radius: float = 120.0
	var _timer: float = 0.0
	const DURATION := 0.35

	func _process(delta: float) -> void:
		_timer += delta
		queue_redraw()
		if _timer >= DURATION:
			queue_free()

	func _draw() -> void:
		var t := _timer / DURATION
		var r := max_radius * t
		var fade := 1.0 - t
		draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(1.0, 0.6, 0.1, fade * 0.8), 3.0)
		if r > 10.0:
			draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 20, Color(1.0, 0.8, 0.3, fade * 0.4), 2.0)
