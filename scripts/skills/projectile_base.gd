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
var _sprite: Sprite2D

static var _circle_texture: ImageTexture
static var _circle_offset: Vector2
static var active_count: int = 0
const MAX_PROJECTILES := 60

func _ready() -> void:
	if not _circle_texture:
		var data := PixelSprite.build_circle_texture(8.0, Color.WHITE)
		_circle_texture = data["texture"]
		_circle_offset = data["offset"]
	_sprite = Sprite2D.new()
	_sprite.texture = _circle_texture
	_sprite.offset = _circle_offset
	add_child(_sprite)

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
	_color = TagColors.get_color(si.base.tags)
	if _sprite:
		_sprite.modulate = _color
	active_count += 1

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
	if _distance_traveled >= _max_range and not get_meta("is_returning", false):
		if get_meta("pierce_return", false):
			_start_return()
		else:
			_return_to_pool()

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
	for key in ["pierce_return", "is_returning", "return_damage_mult", "return_target"]:
		if has_meta(key):
			remove_meta(key)

func _return_to_pool() -> void:
	active_count = maxi(0, active_count - 1)
	if pool_ref:
		pool_ref.release(self)
