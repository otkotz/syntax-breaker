class_name OrbitSkill
extends Area2D

var skill_instance: SkillInstance
var damage: float = 8.0
var orbit_radius: float = 60.0
var orbit_speed: float = 4.0
var pool_ref: ObjectPool
var _angle: float = 0.0
var _parent_node: Node2D
var _hit_cooldowns: Dictionary = {}

const HIT_COOLDOWN := 0.5

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, Color(0.4, 0.9, 1.0))

func initialize(si: SkillInstance, _direction: Vector2, pool: ObjectPool) -> void:
	skill_instance = si
	damage = si.computed_stats.get("damage", 8.0)
	orbit_radius = si.computed_stats.get("range", 60.0) * si.computed_stats.get("area_mult", 1.0)
	orbit_speed = si.computed_stats.get("speed", 300.0) / 75.0
	pool_ref = pool
	_hit_cooldowns.clear()

func set_orbit_parent(parent: Node2D) -> void:
	_parent_node = parent

func _physics_process(delta: float) -> void:
	_angle += orbit_speed * delta
	if _parent_node and is_instance_valid(_parent_node):
		global_position = _parent_node.global_position + Vector2(cos(_angle), sin(_angle)) * orbit_radius

	var expired_keys: Array = []
	for key: int in _hit_cooldowns:
		_hit_cooldowns[key] -= delta
		if _hit_cooldowns[key] <= 0.0:
			expired_keys.append(key)
	for key: int in expired_keys:
		_hit_cooldowns.erase(key)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	var body_id := body.get_instance_id()
	if _hit_cooldowns.has(body_id):
		return
	_hit_cooldowns[body_id] = HIT_COOLDOWN

	if body.has_method("take_damage"):
		body.take_damage(damage)
		GameBus.enemy_hit.emit(body, damage, skill_instance.base if skill_instance else null)
	if skill_instance:
		skill_instance.notify_hit(body, self)
		if body.has_method("is_alive") and not body.is_alive():
			skill_instance.notify_kill(body, self)

func reset() -> void:
	skill_instance = null
	pool_ref = null
	_hit_cooldowns.clear()
	_angle = 0.0
	_parent_node = null
