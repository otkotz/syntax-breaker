class_name TankEnemy
extends EnemyBase

func _draw_body() -> void:
	var f := 1.0 if _target and is_instance_valid(_target) and _target.global_position.x >= global_position.x else -1.0
	_draw_tank(f)

func _draw_health_bar() -> void:
	var bar_width := 32.0
	var bar_height := 4.0
	var bar_y := -50.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), Color(0.8, 0.4, 0.1))

func _draw_tank(f: float) -> void:
	const ARMOR_D := Color(0.15, 0.12, 0.08)
	const ARMOR_M := Color(0.35, 0.28, 0.18)
	const ARMOR_L := Color(0.55, 0.45, 0.28)
	const SKIN_D := Color(0.20, 0.04, 0.06)
	const SKIN_M := Color(0.45, 0.10, 0.14)
	const EYE := Color(1.0, 0.3, 0.2)
	const OUTLINE := Color(0.04, 0.02, 0.02)

	var fx := func(dx: float, w: float) -> float:
		return (dx if f > 0 else -dx - w)

	draw_circle(Vector2.ZERO, 18.0, Color(0, 0, 0, 0.3))
	# Legs
	draw_rect(Rect2(Vector2(fx.call(-6, 5), -14), Vector2(5, 14)), SKIN_M)
	draw_rect(Rect2(Vector2(fx.call(2, 5), -14), Vector2(5, 14)), SKIN_M)
	draw_rect(Rect2(Vector2(fx.call(-6, 5), 0), Vector2(5, 1)), OUTLINE)
	draw_rect(Rect2(Vector2(fx.call(2, 5), 0), Vector2(5, 1)), OUTLINE)
	# Torso armor
	draw_rect(Rect2(Vector2(fx.call(-8, 16), -28), Vector2(16, 14)), ARMOR_M)
	draw_rect(Rect2(Vector2(fx.call(-8, 16), -28), Vector2(16, 2)), ARMOR_L)
	draw_rect(Rect2(Vector2(fx.call(-8, 2), -28), Vector2(2, 14)), ARMOR_D)
	draw_rect(Rect2(Vector2(fx.call(6, 2), -28), Vector2(2, 14)), ARMOR_D)
	# Chest plate
	draw_rect(Rect2(Vector2(fx.call(-5, 10), -25), Vector2(10, 8)), ARMOR_L)
	draw_rect(Rect2(Vector2(fx.call(-3, 6), -24), Vector2(6, 4)), ARMOR_D)
	# Shoulder pads
	draw_rect(Rect2(Vector2(fx.call(-10, 4), -30), Vector2(4, 6)), ARMOR_M)
	draw_rect(Rect2(Vector2(fx.call(-10, 4), -30), Vector2(4, 2)), ARMOR_L)
	draw_rect(Rect2(Vector2(fx.call(6, 4), -30), Vector2(4, 6)), ARMOR_M)
	draw_rect(Rect2(Vector2(fx.call(6, 4), -30), Vector2(4, 2)), ARMOR_L)
	# Arms
	draw_rect(Rect2(Vector2(fx.call(-10, 3), -24), Vector2(3, 10)), SKIN_M)
	draw_rect(Rect2(Vector2(fx.call(7, 3), -24), Vector2(3, 10)), SKIN_M)
	# Head (helmeted)
	draw_rect(Rect2(Vector2(fx.call(-5, 10), -38), Vector2(10, 10)), ARMOR_M)
	draw_rect(Rect2(Vector2(fx.call(-5, 10), -38), Vector2(10, 2)), ARMOR_L)
	draw_rect(Rect2(Vector2(fx.call(-5, 1), -38), Vector2(1, 10)), ARMOR_D)
	draw_rect(Rect2(Vector2(fx.call(4, 1), -38), Vector2(1, 10)), ARMOR_D)
	# Visor slit
	draw_rect(Rect2(Vector2(fx.call(-3, 6), -34), Vector2(6, 2)), OUTLINE)
	draw_rect(Rect2(Vector2(fx.call(-2, 2), -33), Vector2(2, 1)), EYE)
	draw_rect(Rect2(Vector2(fx.call(1, 2), -33), Vector2(2, 1)), EYE)
	# Shield
	draw_rect(Rect2(Vector2(fx.call(-12, 3), -26), Vector2(3, 14)), ARMOR_D)
	draw_rect(Rect2(Vector2(fx.call(-12, 3), -26), Vector2(3, 2)), ARMOR_L)
	draw_rect(Rect2(Vector2(fx.call(-11, 1), -20), Vector2(1, 2)), ARMOR_L)
