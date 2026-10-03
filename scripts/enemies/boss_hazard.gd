extends Node2D

var owner_boss: EnemyBase
var target: Node2D
var kind: String = "pool"
var warning_duration: float = 1.2
var warning_remaining: float = 1.2
var lifetime: float = 3.0
var radius: float = 65.0
var angle: float = 0.0
var angular_speed: float = 0.0
var half_width: float = 18.0
var half_length: float = 300.0
var gap: float = 45.0
var safe_half_angle: float = PI / 4.0
var arena_rect: Rect2
var damage: float = 10.0
var color := Color(0.6, 0.95, 0.2)
var tick_remaining: float = 0.0
var tick_interval: float = 0.5
var cleared_discs: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("boss_hazards")
	if kind in ["pool", "pressure"]:
		add_to_group("boss_poison")

func clear_at(world_position: Vector2, clear_radius: float) -> void:
	cleared_discs.append({"position": world_position - global_position, "radius": clear_radius})
	queue_redraw()

func threatens(world_position: Vector2) -> bool:
	var point := world_position - global_position
	for disc in cleared_discs:
		if point.distance_squared_to(disc.position) <= float(disc.radius) * float(disc.radius):
			return false
	var aligned := point.rotated(-angle)
	match kind:
		"wall":
			return absf(aligned.y) <= half_width and absf(aligned.x) <= half_length and absf(aligned.x) > gap
		"beam":
			return absf(aligned.y) <= half_width and absf(aligned.x) <= half_length
		"wedge", "rotating_gap":
			return point.length() <= radius and absf(wrapf(point.angle() - angle, -PI, PI)) > safe_half_angle
		"border":
			return arena_rect.has_point(point) and not arena_rect.grow(-80.0).has_point(point)
		"pressure":
			return arena_rect.has_point(point)
		_:
			return point.length() <= radius

func _process(delta: float) -> void:
	if not is_instance_valid(owner_boss) or not owner_boss.is_alive():
		queue_free()
		return
	if warning_remaining > 0.0:
		warning_remaining = maxf(0.0, warning_remaining - delta)
		queue_redraw()
		return
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	angle += angular_speed * delta
	tick_remaining -= delta
	if tick_remaining <= 0.0:
		tick_remaining = tick_interval
		if is_instance_valid(target) and target.has_method("take_damage") and threatens(target.global_position):
			Player.hurt(target, damage, owner_boss.get_enemy_id() + ":" + kind)
	queue_redraw()

func _draw() -> void:
	var fill := Color(color, 0.12 if warning_remaining > 0.0 else 0.32)
	match kind:
		"wall", "beam":
			if kind == "beam":
				_draw_strip(-half_length, half_length, fill)
			else:
				_draw_strip(-half_length, -gap, fill)
				_draw_strip(gap, half_length, fill)
		"wedge", "rotating_gap":
			var points := PackedVector2Array([Vector2.ZERO])
			for i in 49:
				var theta := angle + safe_half_angle + (TAU - 2.0 * safe_half_angle) * i / 48.0
				points.append(Vector2.from_angle(theta) * radius)
			draw_colored_polygon(points, fill)
			draw_polyline(points, color, 3.0)
			draw_line(Vector2.ZERO, points[-1], color, 3.0)
		"border":
			draw_rect(Rect2(arena_rect.position, Vector2(arena_rect.size.x, 80)), fill)
			draw_rect(Rect2(arena_rect.position + Vector2(0, arena_rect.size.y - 80), Vector2(arena_rect.size.x, 80)), fill)
			draw_rect(Rect2(arena_rect.position + Vector2(0, 80), Vector2(80, arena_rect.size.y - 160)), fill)
			draw_rect(Rect2(arena_rect.position + Vector2(arena_rect.size.x - 80, 80), Vector2(80, arena_rect.size.y - 160)), fill)
			draw_rect(arena_rect.grow(-80), color, false, 3.0)
		"pressure":
			draw_rect(arena_rect, fill)
		_:
			draw_circle(Vector2.ZERO, radius, fill)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 48, color, 3.0)
	for disc in cleared_discs:
		draw_circle(disc.position, disc.radius, Color(0.04, 0.12, 0.12, 0.9))
		draw_arc(disc.position, disc.radius, 0, TAU, 48, Color(0.2, 1.0, 0.8), 3.0)

func _draw_strip(start: float, end: float, fill: Color) -> void:
	var points := PackedVector2Array([
		Vector2(start, -half_width).rotated(angle), Vector2(end, -half_width).rotated(angle),
		Vector2(end, half_width).rotated(angle), Vector2(start, half_width).rotated(angle)])
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, color, 3.0)
