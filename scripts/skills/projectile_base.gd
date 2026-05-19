class_name ProjectileBase
extends Area2D

var skill_instance: SkillInstance
var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: float = 10.0
var pierce_remaining: int = 0
var pool_ref: ObjectPool
var _distance_traveled: float = 0.0
var _max_range: float = 400.0
var _hit_targets: Array[Node2D] = []

func initialize(si: SkillInstance, dir: Vector2, pool: ObjectPool) -> void:
	skill_instance = si
	direction = dir.normalized()
	speed = si.computed_stats.get("speed", 300.0)
	damage = si.computed_stats.get("damage", 10.0)
	pierce_remaining = si.computed_stats.get("pierce", 0)
	_max_range = si.computed_stats.get("range", 400.0)
	pool_ref = pool
	_distance_traveled = 0.0
	_hit_targets.clear()
	rotation = direction.angle()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.8, 0.1))

func _physics_process(delta: float) -> void:
	var move_dist := speed * delta
	position += direction * move_dist
	_distance_traveled += move_dist
	if _distance_traveled >= _max_range:
		_return_to_pool()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	if _hit_targets.has(body):
		return
	_hit_targets.append(body)

	if body.has_method("take_damage"):
		body.take_damage(damage)
		GameBus.enemy_hit.emit(body, damage, skill_instance.base if skill_instance else null)

	if skill_instance:
		if skill_instance.base.has_tag("poison") and body.has_method("apply_dot"):
			if randf() <= 0.5:
				body.apply_dot("poison", damage * 0.3, 3.0, 0.5)
		skill_instance.notify_hit(body, self)
		if body.has_method("is_alive") and not body.is_alive():
			skill_instance.notify_kill(body, self)

	if pierce_remaining <= 0:
		_return_to_pool()
	else:
		pierce_remaining -= 1

func set_pierce_count(count: int) -> void:
	pierce_remaining = count

func reset() -> void:
	skill_instance = null
	pool_ref = null
	_hit_targets.clear()
	_distance_traveled = 0.0

func _return_to_pool() -> void:
	if pool_ref:
		pool_ref.release(self)
