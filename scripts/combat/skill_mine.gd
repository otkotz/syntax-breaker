class_name SkillMine
extends Area2D

var skill_instance: SkillInstance
var pool_ref: ObjectPool
var owner_node: Node2D
var _lifetime: float = 15.0
var _timer: float = 0.0
var _detonated := false
var _color: Color = Color(0.8, 0.2, 0.2)

func setup(si: SkillInstance, pool: ObjectPool, pos: Vector2, cast_owner: Node2D = null) -> void:
	skill_instance = si
	pool_ref = pool
	owner_node = cast_owner
	global_position = pos
	_color = TagColors.get_color(si.get_all_tags())

	collision_layer = 4
	collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= _lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _detonated:
		return
	if not body.is_in_group("enemies"):
		return
	_detonate(body)

func _detonate(target: Node2D = null) -> void:
	_detonated = true
	if not skill_instance or not pool_ref:
		queue_free()
		return
	if not is_instance_valid(target):
		target = Targeting.find_nearest_enemy(global_position, skill_instance.computed_stats.get("range", 400.0))
	var direction := Vector2.RIGHT
	if is_instance_valid(target):
		direction = global_position.direction_to(Targeting.combat_aim_position(target))
	var count: int = skill_instance.computed_stats.get("projectile_count", 1)
	if count <= 1:
		_spawn_one(direction)
	else:
		var spread := deg_to_rad(15.0) * (count - 1)
		for i in count:
			var offset := -spread / 2.0 + spread / (count - 1) * i
			_spawn_one(direction.rotated(offset))
	CombatLog.skill_cast(skill_instance.base.name + " (Mine Detonation)", count)
	queue_free()

func _spawn_one(direction: Vector2) -> void:
	if skill_instance.get_all_tags().has("beam"):
		SkillLaser.fire(self, skill_instance, direction)
		return
	if skill_instance.base.has_tag("projectile") and ProjectileBase.active_count >= QualitySettings.projectile_cap:
		return
	var payload := pool_ref.get_instance()
	if not payload:
		return
	payload.global_position = global_position
	var context := skill_instance.create_attack_context()
	if payload is Rollback:
		payload.initialize(skill_instance, direction, pool_ref, context)
		payload.set_owner_node(owner_node)
	elif payload is ProjectileBase or payload is AoeSkillBase:
		payload.initialize(skill_instance, direction, pool_ref, context)
	elif payload.has_method("initialize"):
		payload.initialize(skill_instance, direction, pool_ref)
	skill_instance.notify_spawn(payload)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, _color * Color(1, 1, 1, 0.6))
	draw_arc(Vector2.ZERO, 30.0, 0, TAU, 32, _color * Color(1, 1, 1, 0.3), 1.0)
