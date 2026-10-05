extends Node2D

const Visual = preload("res://scripts/util/hazard_visual.gd")

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
var activation_remaining: float = 0.0
var _activated: bool = false

func _ready() -> void:
	z_index = 2
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
	if not _activated:
		_activated = true
		activation_remaining = Visual.ACTIVATION_TIME
		RunTelemetry.record("hazard_active", {"source": owner_boss.get_enemy_id() + ":" + kind,
			"warning_seconds": warning_duration, "x": global_position.x, "y": global_position.y})
	else:
		activation_remaining = maxf(0.0, activation_remaining - delta)
	angle += angular_speed * delta
	tick_remaining -= delta
	if tick_remaining <= 0.0:
		tick_remaining = tick_interval
		if is_instance_valid(target) and target.has_method("take_damage") and threatens(target.global_position):
			Player.hurt(target, damage, owner_boss.get_enemy_id() + ":" + kind, owner_boss.get_damage_context())
	queue_redraw()

func _draw() -> void:
	var fill := Visual.fill_color(color, warning_remaining, activation_remaining)
	var badge_position := Vector2.ZERO
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
			points.append(Vector2.ZERO)
			Visual.outline(self, points, warning_remaining, warning_duration, color, activation_remaining)
			Visual.safe_arrow(self, Vector2.from_angle(angle) * minf(radius * 0.45, 100.0), angle)
			badge_position = -Vector2.from_angle(angle) * minf(radius * 0.45, 90.0)
			if warning_remaining <= 0.0:
				for i in 5:
					var theta := angle + safe_half_angle + (TAU - 2 * safe_half_angle) * (i + 0.5) / 5.0
					var mark := Vector2.from_angle(theta) * minf(radius * 0.65, 160.0)
					if threatens(global_position + mark):
						Visual.active_mark(self, mark, color)
		"border":
			draw_rect(Rect2(arena_rect.position, Vector2(arena_rect.size.x, 80)), fill)
			draw_rect(Rect2(arena_rect.position + Vector2(0, arena_rect.size.y - 80), Vector2(arena_rect.size.x, 80)), fill)
			draw_rect(Rect2(arena_rect.position + Vector2(0, 80), Vector2(80, arena_rect.size.y - 160)), fill)
			draw_rect(Rect2(arena_rect.position + Vector2(arena_rect.size.x - 80, 80), Vector2(80, arena_rect.size.y - 160)), fill)
			_draw_rect_outline(arena_rect.grow(-80))
			badge_position = target.global_position - global_position if is_instance_valid(target) else arena_rect.get_center()
		"pressure":
			draw_rect(arena_rect, fill)
			_draw_rect_outline(arena_rect)
			badge_position = target.global_position - global_position if is_instance_valid(target) else arena_rect.get_center()
		_:
			draw_circle(Vector2.ZERO, radius, fill)
			Visual.outline(self, Visual.circle_points(radius), warning_remaining, warning_duration, color, activation_remaining)
			if warning_remaining <= 0.0:
				for offset in [Vector2(-25, -20), Vector2(25, 20)]:
					if threatens(global_position + offset):
						Visual.active_mark(self, offset, color)
	for disc in cleared_discs:
		draw_circle(disc.position, disc.radius, Color(0.04, 0.12, 0.12, 0.9))
		draw_arc(disc.position, disc.radius, 0, TAU, 48, Color(0.2, 1.0, 0.8), 3.0)
	Visual.badge(self, badge_position + Vector2(0, -14), warning_remaining)

func _draw_rect_outline(rect: Rect2) -> void:
	Visual.outline(self, PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y), rect.position]), warning_remaining, warning_duration, color, activation_remaining)

func _draw_strip(start: float, end: float, fill: Color) -> void:
	var points := PackedVector2Array([
		Vector2(start, -half_width).rotated(angle), Vector2(end, -half_width).rotated(angle),
		Vector2(end, half_width).rotated(angle), Vector2(start, half_width).rotated(angle)])
	draw_colored_polygon(points, fill)
	points.append(points[0])
	Visual.outline(self, points, warning_remaining, warning_duration, color, activation_remaining)
	if warning_remaining <= 0.0:
		var x := start + 25.0
		while x < end:
			var mark := Vector2(x, 0).rotated(angle)
			if threatens(global_position + mark):
				Visual.active_mark(self, mark, color)
			x += 65.0
