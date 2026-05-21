class_name SwarmEnemy
extends EnemyBase

func _draw_body() -> void:
	var f := 1.0 if _target and is_instance_valid(_target) and _target.global_position.x >= global_position.x else -1.0
	_draw_swarm(f)

func _draw_health_bar() -> void:
	var bar_width := 12.0
	var bar_height := 2.0
	var bar_y := -16.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), Color(0.3, 0.9, 0.3))

func _draw_swarm(f: float) -> void:
	const BODY_D := Color(0.12, 0.15, 0.08)
	const BODY_M := Color(0.25, 0.35, 0.15)
	const BODY_L := Color(0.40, 0.55, 0.22)
	const EYE := Color(1.0, 0.8, 0.2)
	const LEG := Color(0.15, 0.10, 0.05)

	var fx := func(dx: float, w: float) -> float:
		return (dx if f > 0 else -dx - w)

	# Body
	draw_rect(Rect2(Vector2(fx.call(-3, 6), -8), Vector2(6, 8)), BODY_M)
	draw_rect(Rect2(Vector2(fx.call(-2, 4), -9), Vector2(4, 1)), BODY_L)
	draw_rect(Rect2(Vector2(fx.call(-3, 1), -8), Vector2(1, 8)), BODY_D)
	draw_rect(Rect2(Vector2(fx.call(2, 1), -8), Vector2(1, 8)), BODY_D)
	# Eyes
	draw_rect(Rect2(Vector2(fx.call(-2, 1), -7), Vector2(1, 1)), EYE)
	draw_rect(Rect2(Vector2(fx.call(1, 1), -7), Vector2(1, 1)), EYE)
	# Legs
	for i in 3:
		var ly := float(-6 + i * 3)
		draw_rect(Rect2(Vector2(fx.call(-4, 1), ly), Vector2(1, 1)), LEG)
		draw_rect(Rect2(Vector2(fx.call(3, 1), ly), Vector2(1, 1)), LEG)
	# Mandibles
	draw_rect(Rect2(Vector2(fx.call(-1, 1), -10), Vector2(1, 1)), LEG)
	draw_rect(Rect2(Vector2(fx.call(0, 1), -10), Vector2(1, 1)), LEG)
