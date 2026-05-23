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
var _color: Color = Color(1.0, 0.8, 0.1)
var _skill_id: String = ""

var _trail_positions: Array[Vector2] = []
var _trail_timer: float = 0.0
const TRAIL_INTERVAL := 0.016
const MAX_TRAIL := 12

var _bolt_segments: Array[Vector2] = []
var _bolt_flicker: float = 1.0

static var active_count: int = 0
const MAX_PROJECTILES := 60

func _ready() -> void:
	top_level = false

func initialize(si: SkillInstance, dir: Vector2, pool: ObjectPool) -> void:
	var spawn_pos := global_position
	top_level = true
	global_position = spawn_pos
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
	var area_mult: float = si.computed_stats.get("area_mult", 1.0)
	scale = Vector2.ONE * area_mult
	_color = TagColors.get_color(si.base.tags)
	_skill_id = si.base.id
	_trail_positions.clear()
	_trail_timer = 0.0
	_bolt_segments.clear()
	if _skill_id == "lightning_bolt":
		_generate_bolt_segments()
	active_count += 1

func _generate_bolt_segments() -> void:
	_bolt_segments.clear()
	var seg_count := 10
	var bolt_len := 50.0
	for i in seg_count + 1:
		var f := float(i) / seg_count
		var base_x := -bolt_len * (1.0 - f)
		var jitter := 0.0 if (i == 0 or i == seg_count) else randf_range(-14.0, 14.0)
		_bolt_segments.append(Vector2(base_x, jitter))

func _physics_process(delta: float) -> void:
	if get_meta("is_returning", false):
		var owner_node: Node2D = get_meta("return_target", null)
		if owner_node and is_instance_valid(owner_node):
			direction = global_position.direction_to(owner_node.global_position)
			rotation = direction.angle()
			if global_position.distance_to(owner_node.global_position) < 20.0:
				_return_to_pool()
				return

	var move_dist := speed * delta
	global_position += direction * move_dist
	_distance_traveled += move_dist

	_trail_timer += delta
	if _trail_timer >= TRAIL_INTERVAL:
		_trail_timer = 0.0
		_trail_positions.push_back(global_position)
		if _trail_positions.size() > MAX_TRAIL:
			_trail_positions.pop_front()

	if _skill_id == "lightning_bolt":
		_bolt_flicker = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.06)

	queue_redraw()

	if _distance_traveled >= _max_range and not get_meta("is_returning", false):
		if get_meta("pierce_return", false):
			_start_return()
		else:
			_return_to_pool()

func _draw() -> void:
	match _skill_id:
		"fireball":
			_draw_fireball()
		"lightning_bolt":
			_draw_lightning()
		"poison_dart":
			_draw_poison_dart()
		_:
			_draw_default()

func _draw_fireball() -> void:
	var inv := global_transform.affine_inverse()
	for i in _trail_positions.size():
		var fade := float(i) / (_trail_positions.size() + 1)
		var trail_r := 6.0 * (0.4 + 0.6 * fade)
		var local_pos := inv * _trail_positions[i]
		draw_circle(local_pos, trail_r, Color(1.0, 0.38, 0.13, fade * 0.5))

	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.31, 0.13, 0.4))
	draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.5, 0.12))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.97, 0.75))

func _draw_lightning() -> void:
	if _bolt_segments.size() < 2:
		return
	for i in _bolt_segments.size() - 1:
		var from := _bolt_segments[i]
		var to := _bolt_segments[i + 1]
		draw_line(from, to, Color(0.63, 0.85, 1.0, 0.35 * _bolt_flicker), 8.0)
	for i in _bolt_segments.size() - 1:
		var from := _bolt_segments[i]
		var to := _bolt_segments[i + 1]
		draw_line(from, to, Color(0.63, 0.85, 1.0, 0.9 * _bolt_flicker), 4.0)
	for i in _bolt_segments.size() - 1:
		var from := _bolt_segments[i]
		var to := _bolt_segments[i + 1]
		draw_line(from, to, Color(1.0, 1.0, 1.0, _bolt_flicker), 2.0)
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 1.0, 1.0, 0.8))

func _draw_poison_dart() -> void:
	var inv := global_transform.affine_inverse()
	for i in _trail_positions.size():
		var fade := float(i) / (_trail_positions.size() + 1)
		var trail_r := 4.0 * (0.3 + 0.5 * fade)
		var local_pos := inv * _trail_positions[i]
		draw_circle(local_pos, trail_r, Color(0.49, 0.83, 0.29, fade * 0.5))

	draw_rect(Rect2(-12, -4, 24, 8), Color(0.49, 0.83, 0.29))
	draw_circle(Vector2.ZERO, 5.0, Color(0.8, 0.96, 0.63))

func _draw_default() -> void:
	draw_circle(Vector2.ZERO, 8.0, _color)
	draw_circle(Vector2.ZERO, 5.0, Color(_color, 0.6).lightened(0.4))

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	if _hit_targets.has(body):
		return
	_hit_targets.append(body)

	var hit_damage := damage
	var is_crit := false
	if skill_instance:
		var roll := CombatUtils.roll_damage(damage, skill_instance)
		hit_damage = roll["damage"]
		is_crit = roll["is_crit"]

	var skill_name := skill_instance.base.name if skill_instance else "unknown"
	if body.has_method("take_damage"):
		body.take_damage(hit_damage, is_crit)
		CombatLog.hit(skill_name, body.name, hit_damage, is_crit)
		if is_crit:
			RunManager.record_stat("crits_landed", 1)
		GameBus.enemy_hit.emit(body, hit_damage, skill_instance.base if skill_instance else null)

	_spawn_hit_effect(body.global_position)
	_spawn_aftermath(body.global_position)

	if skill_instance:
		_apply_elemental_effects(body)
		TagInteractions.process_hit(body, hit_damage, skill_instance.get_all_tags(), self)
		skill_instance.notify_hit(body, self)
		if body.has_method("is_alive") and not body.is_alive():
			CombatLog.kill(skill_name, body.name)
			skill_instance.notify_kill(body, self)

	if pierce_remaining <= 0:
		_return_to_pool()
	else:
		pierce_remaining -= 1

func _spawn_hit_effect(pos: Vector2) -> void:
	var element := "fire"
	if skill_instance:
		var tags := skill_instance.get_all_tags()
		if tags.has("lightning"):
			element = "lightning"
		elif tags.has("poison"):
			element = "poison"
		elif tags.has("fire"):
			element = "fire"
	var parent_node := get_tree().current_scene
	if parent_node:
		HitEffect.spawn(parent_node, pos, element, 60.0)

func _spawn_aftermath(pos: Vector2) -> void:
	var parent_node := get_tree().current_scene
	if not parent_node or not skill_instance:
		return
	var tags := skill_instance.get_all_tags()
	if tags.has("fire"):
		AftermathEffect.spawn(parent_node, pos, "scorch", 30.0, 1.5)
	elif tags.has("poison"):
		AftermathEffect.spawn(parent_node, pos, "poison_pool", 25.0, 2.0)
	elif tags.has("lightning"):
		AftermathEffect.spawn(parent_node, pos, "static_crackle", 30.0, 1.5)

func _apply_elemental_effects(body: Node2D) -> void:
	if not body.has_method("apply_dot"):
		return
	var tags := skill_instance.get_all_tags()
	if tags.has("fire"):
		body.apply_dot("burn", damage * 0.2, 2.0, 0.5)
		CombatLog.dot_applied("burn", body.name, damage * 0.2, 2.0)
	if tags.has("poison") and randf() <= 0.5:
		body.apply_dot("poison", damage * 0.3, 3.0, 0.5)
		CombatLog.dot_applied("poison", body.name, damage * 0.3, 3.0)

func set_pierce_count(count: int) -> void:
	pierce_remaining = count

func _start_return() -> void:
	var tree := get_tree()
	var players := tree.get_nodes_in_group("player") if tree else []
	var player: Node2D = players[0] if players.size() > 0 else null
	set_meta("return_target", player)
	if player:
		direction = global_position.direction_to(player.global_position)
	else:
		direction = -direction
	rotation = direction.angle()
	_distance_traveled = 0.0
	_hit_targets.clear()
	damage *= get_meta("return_damage_mult", 0.6)
	set_meta("is_returning", true)
	set_meta("pierce_return", false)
	pierce_remaining = 999

func reset() -> void:
	top_level = false
	skill_instance = null
	pool_ref = null
	_hit_targets.clear()
	_distance_traveled = 0.0
	_trail_positions.clear()
	_trail_timer = 0.0
	_bolt_segments.clear()
	_skill_id = ""
	scale = Vector2.ONE
	for key in ["pierce_return", "is_returning", "return_damage_mult", "return_target"]:
		if has_meta(key):
			remove_meta(key)

func _return_to_pool() -> void:
	active_count = maxi(0, active_count - 1)
	if pool_ref:
		pool_ref.release(self)
