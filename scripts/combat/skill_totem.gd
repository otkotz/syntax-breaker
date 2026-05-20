class_name SkillTotem
extends Node2D

var skill_instance: SkillInstance
var pool_ref: ObjectPool
var _lifetime: float = 10.0
var _timer: float = 0.0
var _cast_timer: float = 0.0
var _color: Color = Color(0.6, 0.4, 0.8)

func setup(si: SkillInstance, pool: ObjectPool, pos: Vector2) -> void:
	skill_instance = si
	pool_ref = pool
	global_position = pos
	_cast_timer = 0.0
	_timer = 0.0
	if si:
		_color = TagColors.get_color(si.get_all_tags())

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= _lifetime:
		queue_free()
		return

	_cast_timer -= delta
	if _cast_timer <= 0.0:
		_try_cast()
		var cd: float = skill_instance.computed_stats.get("cooldown", 1.0) if skill_instance else 1.0
		_cast_timer = cd

func _try_cast() -> void:
	if not skill_instance or not pool_ref:
		return
	var target := Targeting.find_nearest_enemy(global_position, skill_instance.computed_stats.get("range", 400.0))
	if not target:
		return
	var direction := global_position.direction_to(target.global_position)
	var count: int = skill_instance.computed_stats.get("projectile_count", 1)
	if count <= 1:
		_spawn_one(direction)
	else:
		var spread := deg_to_rad(15.0) * (count - 1)
		for i in count:
			var offset := -spread / 2.0 + spread / (count - 1) * i
			_spawn_one(direction.rotated(offset))
	CombatLog.skill_cast(skill_instance.base.name + " (Totem)", count)

func _spawn_one(direction: Vector2) -> void:
	var proj := pool_ref.get_instance()
	proj.global_position = global_position
	if proj.has_method("initialize"):
		proj.initialize(skill_instance, direction, pool_ref)
	skill_instance.notify_spawn(proj)

func _draw() -> void:
	draw_rect(Rect2(-8, -16, 16, 32), _color * 0.6)
	draw_circle(Vector2(0, -16), 6, _color)
	var fade := 1.0 - (_timer / _lifetime)
	draw_arc(Vector2.ZERO, 14.0, 0, TAU * fade, 16, _color * 0.4, 2.0)
