class_name TankEnemy
extends EnemyBase

static var _brute_variants: Array = []

# Heavy "Null Brute" — built once, three corruption accents.
func _get_body_variants() -> Array:
	if _brute_variants.is_empty():
		_brute_variants.append(BruteSprite.build("amber"))
		_brute_variants.append(BruteSprite.build("toxic"))
		_brute_variants.append(BruteSprite.build("red"))
	return _brute_variants

func _draw_health_bar() -> void:
	var bar_width := 32.0
	var bar_height := 4.0
	var bar_y := -50.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), Color(0.8, 0.4, 0.1))
