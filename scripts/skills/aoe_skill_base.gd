class_name AoeSkillBase
extends Area2D

var skill_instance: SkillInstance
var damage: float = 10.0
var area_radius: float = 100.0
var pool_ref: ObjectPool
var _lifetime: float = 0.5
var _timer: float = 0.0
var _has_hit: bool = false
var _color: Color = Color(1.0, 0.9, 0.6, 0.35)
var _skill_id: String = ""
var _kill_count: int = 0
var _detonation_mult: float = 1.0

var _arc_data: Array = []
var _wave_hit_set: Array = []
const ARC_COUNT := 6

func _ready() -> void:
	pass

func initialize(si: SkillInstance, _direction: Vector2, pool: ObjectPool) -> void:
	skill_instance = si
	damage = si.computed_stats.get("damage", 10.0)
	area_radius = si.computed_stats.get("range", 100.0) * si.computed_stats.get("area_mult", 1.0)
	pool_ref = pool
	_timer = 0.0
	_has_hit = false
	_skill_id = si.base.id
	_color = TagColors.get_color_faded(si.base.tags)
	_wave_hit_set.clear()
	_kill_count = 0
	scale = Vector2.ONE

	match _skill_id:
		"flame_wave":
			_lifetime = 0.8
		"static_field":
			_lifetime = 0.6
			_generate_arcs()
		_:
			_lifetime = 0.5

func _generate_arcs() -> void:
	_arc_data.clear()
	for i in ARC_COUNT:
		var base_angle := (float(i) / ARC_COUNT) * TAU + randf() * 0.4
		var segments: Array[Vector2] = []
		for s in 9:
			var f := float(s) / 8
			var r := area_radius * f
			var ang := base_angle + randf_range(-0.3, 0.3)
			segments.append(Vector2(cos(ang) * r, sin(ang) * r))
		_arc_data.append(segments)

func _physics_process(delta: float) -> void:
	_timer += delta
	if _skill_id == "flame_wave":
		_hit_wave()
	elif not _has_hit:
		_has_hit = true
		_hit_enemies_in_radius(area_radius)
		_spawn_aftermath()
	queue_redraw()
	if _timer >= _lifetime:
		if _skill_id == "flame_wave":
			_spawn_aftermath()
		_return_to_pool()

func _draw() -> void:
	match _skill_id:
		"flame_wave":
			_draw_flame_wave()
		"static_field":
			_draw_static_field()
		_:
			_draw_default()

func _draw_flame_wave() -> void:
	var t := _timer / _lifetime
	var eased := 1.0 - (1.0 - t) * (1.0 - t)
	var fade := 1.0 - t

	var r_outer := eased * area_radius
	if r_outer > 4.0:
		draw_arc(Vector2.ZERO, r_outer, 0, TAU, 32, Color(1.0, 0.31, 0.13, fade * 0.7), 18.0)

	var r_inner := eased * area_radius * 0.9
	if r_inner > 4.0:
		draw_arc(Vector2.ZERO, r_inner, 0, TAU, 32, Color(1.0, 0.88, 0.5, fade * 0.6), 8.0)

	var flash_op := maxf(0.0, 1.0 - t * 3.0)
	if flash_op > 0.0:
		draw_circle(Vector2.ZERO, area_radius * 0.3 * eased, Color(1.0, 0.97, 0.75, flash_op * 0.6))

func _draw_static_field() -> void:
	var t := _timer / _lifetime
	var fade := 1.0 - t
	var pulse := 0.7 + 0.3 * sin(_timer * 10.0)

	draw_circle(Vector2.ZERO, area_radius, Color(0.25, 0.5, 0.75, 0.15 * pulse * fade))
	if area_radius > 4.0:
		draw_arc(Vector2.ZERO, area_radius, 0, TAU, 32, Color(0.63, 0.85, 1.0, 0.5 * pulse * fade), 3.0)

	var flicker: float = 0.6 + 0.4 * abs(sin(_timer * 18.0))
	for arc: Array in _arc_data:
		var strike := sin(_timer * 16.0 + _arc_data.find(arc) * 1.3) > 0.0
		if not strike:
			continue
		for i in arc.size() - 1:
			var from: Vector2 = arc[i]
			var to: Vector2 = arc[i + 1]
			draw_line(from, to, Color(0.63, 0.85, 1.0, 0.25 * flicker * fade), 6.0)
			draw_line(from, to, Color(0.63, 0.85, 1.0, 0.8 * flicker * fade), 3.0)
			draw_line(from, to, Color(1.0, 1.0, 1.0, flicker * fade), 1.0)

	var flash_op := maxf(0.0, 1.0 - t * 4.0)
	if flash_op > 0.0:
		draw_circle(Vector2.ZERO, area_radius * 0.5 * (1.0 - (1.0 - t) * (1.0 - t)), Color(1.0, 1.0, 1.0, flash_op * 0.5))

func _draw_default() -> void:
	var t := _timer / _lifetime
	var fade := 1.0 - t
	draw_circle(Vector2.ZERO, area_radius, Color(_color, 0.3 * fade))
	if area_radius > 4.0:
		draw_arc(Vector2.ZERO, area_radius * 0.8, 0, TAU, 24, Color(_color, 0.5 * fade), 2.0)

func _hit_wave() -> void:
	var t := _timer / _lifetime
	var eased := 1.0 - (1.0 - t) * (1.0 - t)
	var current_radius := eased * area_radius
	var enemies := Targeting.find_enemies_in_range(global_position, current_radius, 50)
	_detonation_mult = EngineTracker.get_detonation_mult(_wave_hit_set.size() + enemies.size())
	for enemy in enemies:
		if enemy in _wave_hit_set:
			continue
		if not is_instance_valid(enemy):
			continue
		_wave_hit_set.append(enemy)
		_damage_enemy(enemy)

func _hit_enemies_in_radius(radius: float) -> void:
	var enemies := Targeting.find_enemies_in_range(global_position, radius, 50)
	_detonation_mult = EngineTracker.get_detonation_mult(enemies.size())
	for enemy in enemies:
		_damage_enemy(enemy)

func _damage_enemy(enemy: Node2D) -> void:
	if not enemy.has_method("take_damage"):
		return
	var tags: Array = skill_instance.get_all_tags() if skill_instance else []
	var element := "fire"
	if tags.has("lightning"):
		element = "lightning"
	elif tags.has("poison"):
		element = "poison"

	var hit_damage := damage
	var is_crit := false
	if skill_instance:
		var roll := CombatUtils.roll_damage(damage, skill_instance)
		hit_damage = roll["damage"]
		is_crit = roll["is_crit"]
		if is_crit:
			RunManager.record_stat("crits_landed", 1)
	hit_damage *= _detonation_mult
	var skill_name := skill_instance.base.name if skill_instance else "unknown"
	enemy.take_damage(hit_damage, is_crit)
	CombatLog.hit(skill_name, enemy.name, hit_damage, is_crit)
	if enemy.has_method("apply_dot"):
		if tags.has("fire"):
			enemy.apply_dot("burn", hit_damage * 0.2, 2.0, 0.5)
			CombatLog.dot_applied("burn", enemy.name, hit_damage * 0.2, 2.0)
	GameBus.enemy_hit.emit(enemy, hit_damage, skill_instance.base if skill_instance else null)
	HitEffect.spawn(self, enemy.global_position - global_position + Vector2.ZERO, element, 50.0)
	if skill_instance:
		TagInteractions.process_hit(enemy, hit_damage, tags, self)
		skill_instance.notify_hit(enemy, self)
		if is_crit:
			skill_instance.notify_crit(enemy, self)
		if enemy.has_method("apply_dot") and tags.has("fire"):
			skill_instance.notify_status_apply(enemy, "burn")
		if enemy.has_method("is_alive") and not enemy.is_alive():
			CombatLog.kill(skill_name, enemy.name)
			skill_instance.notify_kill(enemy, self)
			_kill_count += 1

func _spawn_aftermath() -> void:
	if _kill_count > RunManager.run_stats.get("max_aoe_kill", 0):
		RunManager.run_stats["max_aoe_kill"] = _kill_count
	var tags: Array = skill_instance.get_all_tags() if skill_instance else []
	var element := "fire"
	if tags.has("lightning"):
		element = "lightning"
	elif tags.has("poison"):
		element = "poison"
	var scene_root := get_tree().current_scene if get_tree() else null
	if scene_root:
		match _skill_id:
			"flame_wave":
				AftermathEffect.spawn(scene_root, global_position, "scorch", area_radius * 0.6, 3.0)
				AftermathEffect.spawn(scene_root, global_position, "embers", area_radius * 0.5, 3.0)
			"static_field":
				AftermathEffect.spawn(scene_root, global_position, "static_crackle", area_radius * 0.7, 2.5)
			_:
				if element == "fire":
					AftermathEffect.spawn(scene_root, global_position, "scorch", area_radius * 0.4, 2.0)
				elif element == "poison":
					AftermathEffect.spawn(scene_root, global_position, "poison_pool", area_radius * 0.4, 2.0)
				elif element == "lightning":
					AftermathEffect.spawn(scene_root, global_position, "static_crackle", area_radius * 0.5, 2.0)

func reset() -> void:
	skill_instance = null
	pool_ref = null
	_timer = 0.0
	_has_hit = false
	_skill_id = ""
	_kill_count = 0
	_detonation_mult = 1.0
	_arc_data.clear()
	_wave_hit_set.clear()
	scale = Vector2.ONE

func _return_to_pool() -> void:
	if pool_ref:
		pool_ref.release(self)
