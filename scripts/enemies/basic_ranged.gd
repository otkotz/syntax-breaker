class_name BasicRanged
extends EnemyBase

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")

@export var preferred_distance: float = 250.0
@export var fire_rate: float = 2.0
@export var projectile_speed: float = 200.0
@export var projectile_damage: float = 5.0

var _fire_timer: float = 0.0

static var _projectile_pool: ObjectPool

static var _oracle_variants: Array = []

# Ranged "Null Oracle" — built once, three corruption accents.
func _get_body_variants() -> Array:
	if _oracle_variants.is_empty():
		_oracle_variants.append(OracleSprite.build("void"))
		_oracle_variants.append(OracleSprite.build("magenta"))
		_oracle_variants.append(OracleSprite.build("cold"))
	return _oracle_variants

func _physics_process(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return

	var dist := global_position.distance_to(_target.global_position)
	var dir := global_position.direction_to(_target.global_position)

	if dist > preferred_distance + 30.0:
		velocity = dir * move_speed
	elif dist < preferred_distance - 30.0:
		velocity = -dir * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_clamp_to_arena()
	_check_contact_damage()
	_update_facing()
	Targeting.update_position(self)

	_fire_timer += delta
	if _fire_timer >= fire_rate:
		_fire_projectile(dir)
		_fire_timer = 0.0

func _fire_projectile(dir: Vector2) -> void:
	if not _projectile_pool or not is_instance_valid(_projectile_pool._parent):
		_projectile_pool = ObjectPool.new(ENEMY_PROJECTILE_SCENE, 10, get_tree().current_scene)
	var proj := _projectile_pool.get_instance() as EnemyProjectile
	if not proj:
		return
	proj.initialize(dir, projectile_speed, projectile_damage, global_position, _projectile_pool)
