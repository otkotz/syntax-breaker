class_name Rollback
extends Area2D

enum State { OUTBOUND, TURNING, RETURNING, CAUGHT }

var state: State = State.OUTBOUND
var skill_instance: SkillInstance
var context: AttackContext
var direction := Vector2.RIGHT
var speed := 300.0
var damage := 8.0
var max_range := 240.0
var pool_ref: ObjectPool
var _owner_node: Node2D
var _distance_traveled := 0.0
var _recorded_path: Array[Vector2] = []
var _ordered_hits: Array[Dictionary] = []
var _outbound_hit_ids: Dictionary = {}
var _return_hit_ids: Dictionary = {}

func initialize(si: SkillInstance, dir: Vector2, pool: ObjectPool, attack_context: AttackContext = null) -> void:
	skill_instance = si
	direction = dir.normalized() if not dir.is_zero_approx() else Vector2.RIGHT
	pool_ref = pool
	context = attack_context if attack_context else si.create_attack_context()
	speed = si.computed_stats.get("speed", 300.0)
	damage = si.computed_stats.get("damage", 8.0)
	max_range = maxf(40.0, si.computed_stats.get("range", 240.0))
	state = State.OUTBOUND
	_distance_traveled = 0.0
	_recorded_path = [global_position]
	_ordered_hits.clear()
	_outbound_hit_ids.clear()
	_return_hit_ids.clear()
	rotation = direction.angle()
	queue_redraw()

func set_owner_node(owner_node: Node2D) -> void:
	_owner_node = owner_node

func advance_simulation(delta: float) -> void:
	match state:
		State.OUTBOUND:
			var travel := minf(speed * delta, max_range - _distance_traveled)
			global_position += direction * travel
			_distance_traveled += travel
			_record_path_point()
			if _distance_traveled >= max_range:
				state = State.TURNING
				state = State.RETURNING
		State.TURNING:
			state = State.RETURNING
		State.RETURNING:
			if not is_instance_valid(_owner_node):
				state = State.CAUGHT
				return
			var target := _owner_node.global_position
			var distance := global_position.distance_to(target)
			if distance <= speed * delta + 16.0:
				global_position = target
				_record_path_point()
				state = State.CAUGHT
			else:
				direction = global_position.direction_to(target)
				global_position += direction * speed * delta
				rotation = direction.angle()
				_record_path_point()
		State.CAUGHT:
			_release_to_pool()

func _physics_process(delta: float) -> void:
	advance_simulation(delta)

func _record_path_point() -> void:
	if _recorded_path.is_empty() or _recorded_path[-1].distance_to(global_position) >= 4.0:
		_recorded_path.append(global_position)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies") or state not in [State.OUTBOUND, State.RETURNING]:
		return
	var hit_ids := _outbound_hit_ids if state == State.OUTBOUND else _return_hit_ids
	var body_id := body.get_instance_id()
	if hit_ids.has(body_id):
		return
	hit_ids[body_id] = true
	_ordered_hits.append({"target": body, "target_id": body_id,
		"direction": "outbound" if state == State.OUTBOUND else "returning",
		"position": body.global_position})
	ProjectileBase.resolve_skill_hit(skill_instance, body, self, damage)

func get_recorded_path() -> Array[Vector2]:
	return _recorded_path.duplicate()

func get_ordered_hits() -> Array[Dictionary]:
	return _ordered_hits.duplicate(true)

func _release_to_pool() -> void:
	if pool_ref:
		pool_ref.release(self)
	else:
		set_physics_process(false)

func reset() -> void:
	state = State.CAUGHT
	skill_instance = null
	context = null
	pool_ref = null
	_owner_node = null
	_recorded_path.clear()
	_ordered_hits.clear()
	_outbound_hit_ids.clear()
	_return_hit_ids.clear()

func _draw() -> void:
	draw_arc(Vector2.ZERO, 16.0, -2.35, 0.75, 18, Color(0.15, 0.9, 1.0), 7.0)
	draw_colored_polygon(PackedVector2Array([Vector2(11, 9), Vector2(22, 5), Vector2(15, -3)]), Color(1.0, 0.2, 0.9))
