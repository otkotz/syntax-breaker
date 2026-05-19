class_name BasicRanged
extends EnemyBase

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")

@export var preferred_distance: float = 250.0
@export var fire_rate: float = 2.0
@export var projectile_speed: float = 200.0
@export var projectile_damage: float = 5.0

var _fire_timer: float = 0.0

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

	_fire_timer += delta
	if _fire_timer >= fire_rate and dist < preferred_distance + 100.0:
		_fire_projectile(dir)
		_fire_timer = 0.0

func _fire_projectile(dir: Vector2) -> void:
	var proj := ENEMY_PROJECTILE_SCENE.instantiate() as EnemyProjectile
	proj.direction = dir
	proj.speed = projectile_speed
	proj.damage = projectile_damage
	proj.global_position = global_position
	get_tree().current_scene.add_child(proj)
