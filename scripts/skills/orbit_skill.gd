class_name OrbitSkill
extends Area2D

var skill_instance: SkillInstance
var damage: float = 8.0
var orbit_radius: float = 60.0
var orbit_speed: float = 4.0
var pool_ref: ObjectPool
var _angle_offset: float = 0.0
var _parent_node: Node2D
var _hit_cooldowns: Dictionary = {}
var _color: Color = Color(0.4, 0.9, 1.0)
var _sprite: Sprite2D

const HIT_COOLDOWN := 0.5

static var _circle_texture: ImageTexture
static var _circle_offset: Vector2

func _ready() -> void:
	if not _circle_texture:
		var data := PixelSprite.build_circle_texture(10.0, Color.WHITE)
		_circle_texture = data["texture"]
		_circle_offset = data["offset"]
	_sprite = Sprite2D.new()
	_sprite.texture = _circle_texture
	_sprite.offset = _circle_offset
	add_child(_sprite)

func initialize(si: SkillInstance, _direction: Vector2, pool: ObjectPool) -> void:
	skill_instance = si
	damage = si.computed_stats.get("damage", 8.0)
	var area_mult: float = si.computed_stats.get("area_mult", 1.0)
	orbit_radius = si.computed_stats.get("range", 60.0) * area_mult
	orbit_speed = si.computed_stats.get("speed", 300.0) / 75.0
	pool_ref = pool
	_hit_cooldowns.clear()
	_color = TagColors.get_color(si.get_all_tags())
	scale = Vector2.ONE * area_mult
	if _sprite:
		_sprite.modulate = _color

func set_orbit_parent(parent: Node2D) -> void:
	_parent_node = parent

func _physics_process(delta: float) -> void:
	var base_angle := fmod(Time.get_ticks_msec() / 1000.0 * orbit_speed, TAU)
	var angle := base_angle + _angle_offset
	if _parent_node and is_instance_valid(_parent_node):
		global_position = _parent_node.global_position + Vector2(cos(angle), sin(angle)) * orbit_radius

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

	var hit_damage := damage
	var is_crit := false
	if skill_instance:
		var roll := CombatUtils.roll_damage(damage, skill_instance)
		hit_damage = roll["damage"]
		is_crit = roll["is_crit"]
		if is_crit:
			RunManager.record_stat("crits_landed", 1)

	var skill_name := skill_instance.base.name if skill_instance else "unknown"
	if body.has_method("take_damage"):
		body.take_damage(hit_damage, is_crit)
		CombatLog.hit(skill_name, body.name, hit_damage, is_crit)
		GameBus.enemy_hit.emit(body, hit_damage, skill_instance.base if skill_instance else null)
	if skill_instance:
		var tags := skill_instance.get_all_tags()
		if body.has_method("apply_dot") and tags.has("fire"):
			body.apply_dot("burn", hit_damage * 0.2, 2.0, 0.5)
			CombatLog.dot_applied("burn", body.name, hit_damage * 0.2, 2.0)
		TagInteractions.process_hit(body, hit_damage, tags, self)
		skill_instance.notify_hit(body, self)
		if body.has_method("is_alive") and not body.is_alive():
			CombatLog.kill(skill_name, body.name)
			skill_instance.notify_kill(body, self)

func set_angle_offset(angle: float) -> void:
	_angle_offset = angle

func reset() -> void:
	skill_instance = null
	pool_ref = null
	_hit_cooldowns.clear()
	_angle_offset = 0.0
	_parent_node = null
	scale = Vector2.ONE
