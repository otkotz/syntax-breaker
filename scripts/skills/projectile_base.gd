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
var _cosmetic_style: String = "projectile_default"
var artifact_hooks: ArtifactCombatHooks
var artifact_origin_flags: Array = []
var artifact_generation: int = 0
var artifact_spawn_fragment: Callable

var _trail_positions: Array[Vector2] = []
var _last_trail_position: Vector2 = Vector2.ZERO
var _return_target: Node2D
var _counted_active: bool = false
const TRAIL_MIN_DISTANCE := 12.0
const MAX_TRAIL := 12
const MAX_RETURN_HITS := 8

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
	_cosmetic_style = CosmeticStyles.selected("projectile")
	_trail_positions.clear()
	_last_trail_position = global_position
	_return_target = null
	_bolt_segments.clear()
	if _skill_id == "lightning_bolt":
		_generate_bolt_segments()
	if not _counted_active:
		active_count += 1
		_counted_active = true

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
		var owner_node := _return_target
		if owner_node and is_instance_valid(owner_node):
			direction = global_position.direction_to(owner_node.global_position)
			rotation = direction.angle()
			if global_position.distance_to(owner_node.global_position) < 20.0:
				_return_to_pool()
				return

	var move_dist := speed * delta
	global_position += direction * move_dist
	_distance_traveled += move_dist

	var sampled_trail := false
	if global_position.distance_to(_last_trail_position) >= TRAIL_MIN_DISTANCE:
		_trail_positions.push_back(global_position)
		_last_trail_position = global_position
		_trim_trail()
		sampled_trail = true

	if _skill_id == "lightning_bolt":
		_bolt_flicker = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.06)

	if sampled_trail or not _trail_positions.is_empty() or _skill_id == "lightning_bolt":
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
		_draw_trail_dot(local_pos, trail_r, Color(1.0, 0.38, 0.13, fade * 0.5))

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
		if lightning_uses_trail_style() and i % 2 == 0:
			_draw_trail_dot(from, 4.0, Color(0.63, 0.85, 1.0, 0.2 * _bolt_flicker))
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
		_draw_trail_dot(local_pos, trail_r, Color(0.49, 0.83, 0.29, fade * 0.5))

	draw_rect(Rect2(-12, -4, 24, 8), Color(0.49, 0.83, 0.29))
	draw_circle(Vector2.ZERO, 5.0, Color(0.8, 0.96, 0.63))

func _draw_default() -> void:
	draw_circle(Vector2.ZERO, 8.0, _color)
	draw_circle(Vector2.ZERO, 5.0, Color(_color, 0.6).lightened(0.4))

func _draw_trail_dot(center: Vector2, radius: float, color: Color) -> void:
	if _cosmetic_style == "faceted_trails":
		draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, 0), center + Vector2(0, -radius),
			center + Vector2(radius, 0), center + Vector2(0, radius)]), color)
	elif _cosmetic_style == "ember_trails":
		draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, 0), center + Vector2(-radius * 0.25, -radius * 0.25),
			center + Vector2(0, -radius), center + Vector2(radius * 0.25, -radius * 0.25), center + Vector2(radius, 0),
			center + Vector2(radius * 0.25, radius * 0.25), center + Vector2(0, radius), center + Vector2(-radius * 0.25, radius * 0.25)]), color)
	elif _cosmetic_style == "void_trails":
		draw_arc(center, radius, 0, TAU, 12, color, maxf(1.0, radius * 0.35))
	else:
		draw_circle(center, radius, color)

func lightning_uses_trail_style() -> bool:
	return _skill_id == "lightning_bolt" and _cosmetic_style != "projectile_default"

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	if _hit_targets.has(body):
		return
	_hit_targets.append(body)
	var pre_hit_burn_count: int = body.get_dot_stacks("burn").size() if body.has_method("get_dot_stacks") else 0
	resolve_skill_hit(skill_instance, body, self, damage)
	if artifact_hooks != null and artifact_hooks.active:
		artifact_hooks.emit_event(&"projectile_hit", {"projectile": self, "skill": skill_instance, "target": body,
			"damage": damage, "world_position": body.global_position, "origin_flags": artifact_origin_flags,
			"generation": artifact_generation, "pre_hit_burn_count": pre_hit_burn_count,
			"spawn_fragment": artifact_spawn_fragment})
	if get_meta("chain_redirected", false):
		remove_meta("chain_redirected")
	elif pierce_remaining <= 0:
		_return_to_pool()
	else:
		pierce_remaining -= 1

static func resolve_skill_hit(si: SkillInstance, body: Node2D, hit_source: Node2D, raw_damage: float) -> void:
	if not is_instance_valid(body) or not body.has_method("take_damage"):
		return
	var hit_damage := raw_damage
	var is_crit := false
	if si:
		var roll := CombatUtils.roll_damage(raw_damage, si)
		hit_damage = roll["damage"]
		is_crit = roll["is_crit"]
	var skill_name := si.base.name if si else "unknown"
	body.take_damage(hit_damage, is_crit, si.base if si else null)
	CombatLog.hit(skill_name, body.name, hit_damage, is_crit)
	if is_crit:
		RunManager.record_stat("crits_landed", 1)
	GameBus.enemy_hit.emit(body, hit_damage, si.base if si else null)
	_spawn_resolved_hit_effect(hit_source, body.global_position, si)
	_spawn_resolved_aftermath(hit_source, body.global_position, si)
	if not si:
		return
	_apply_resolved_elemental_effects(body, si, raw_damage, hit_source)
	TagInteractions.process_hit(body, hit_damage, si.get_all_tags(), hit_source, si.base)
	si.notify_hit(body, hit_source)
	if is_crit:
		si.notify_crit(body, hit_source)
	if body.has_method("is_alive") and not body.is_alive():
		CombatLog.kill(skill_name, body.name)
		si.notify_kill(body, hit_source)

static func _spawn_resolved_hit_effect(hit_source: Node2D, pos: Vector2, si: SkillInstance) -> void:
	var element := "fire"
	if si:
		var tags := si.get_all_tags()
		if tags.has("lightning"):
			element = "lightning"
		elif tags.has("poison"):
			element = "poison"
		elif tags.has("fire"):
			element = "fire"
	var parent_node := hit_source.get_tree().current_scene if is_instance_valid(hit_source) else null
	if parent_node:
		HitEffect.spawn(parent_node, pos, element, 60.0)

static func _spawn_resolved_aftermath(hit_source: Node2D, pos: Vector2, si: SkillInstance) -> void:
	var parent_node := hit_source.get_tree().current_scene if is_instance_valid(hit_source) else null
	if not parent_node or not si:
		return
	var tags := si.get_all_tags()
	if tags.has("fire"):
		AftermathEffect.spawn(parent_node, pos, "scorch", 30.0, 1.5)
	elif tags.has("poison"):
		AftermathEffect.spawn(parent_node, pos, "poison_pool", 25.0, 2.0)
	elif tags.has("lightning"):
		AftermathEffect.spawn(parent_node, pos, "static_crackle", 30.0, 1.5)

static func _apply_resolved_elemental_effects(body: Node2D, si: SkillInstance, raw_damage: float, hit_source: Node2D = null) -> void:
	if not body.has_method("apply_dot"):
		return
	var tags := si.get_all_tags()
	var furnace_active: bool = hit_source is ProjectileBase and hit_source.artifact_hooks != null \
		and hit_source.artifact_hooks.active_artifact_ids.has("furnace_heart")
	if tags.has("fire") and not furnace_active:
		body.apply_dot("burn", raw_damage * 0.3, 3.0, 0.5, si.base)
		CombatLog.dot_applied("burn", body.name, raw_damage * 0.3, 3.0)
		si.notify_status_apply(body, "burn")
	if tags.has("poison") and randf() <= 0.8:
		body.apply_dot("poison", raw_damage * 0.4, 4.0, 0.5, si.base)
		si.notify_status_apply(body, "poison")
		CombatLog.dot_applied("poison", body.name, raw_damage * 0.4, 4.0)

func set_pierce_count(count: int) -> void:
	pierce_remaining = count

func _trim_trail() -> void:
	while _trail_positions.size() > MAX_TRAIL:
		_trail_positions.pop_front()

func _start_return() -> void:
	var tree := get_tree()
	var players := tree.get_nodes_in_group("player") if tree else []
	var player: Node2D = players[0] if players.size() > 0 else null
	_return_target = player
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
	pierce_remaining = MAX_RETURN_HITS

func reset() -> void:
	_release_active_count()
	top_level = false
	skill_instance = null
	pool_ref = null
	_hit_targets.clear()
	_distance_traveled = 0.0
	_trail_positions.clear()
	_last_trail_position = Vector2.ZERO
	_return_target = null
	_bolt_segments.clear()
	_skill_id = ""
	_cosmetic_style = "projectile_default"
	artifact_hooks = null
	artifact_origin_flags.clear()
	artifact_generation = 0
	artifact_spawn_fragment = Callable()
	scale = Vector2.ONE
	for key in ["pierce_return", "is_returning", "return_damage_mult", "return_target", "chains_remaining", "is_split", "chain_redirected", "ricochet_bonus"]:
		if has_meta(key):
			remove_meta(key)

func _return_to_pool() -> void:
	_release_active_count()
	if pool_ref:
		pool_ref.release(self)

func _release_active_count() -> void:
	if _counted_active:
		active_count = maxi(0, active_count - 1)
		_counted_active = false

func _exit_tree() -> void:
	_release_active_count()
