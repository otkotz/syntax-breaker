class_name SwarmEnemy
extends EnemyBase

# Mote sprites are authored at full enemy resolution; shrink them so the
# swarm still reads as tiny, fast cannon-fodder. Tune to taste.
const SPRITE_SCALE := 0.5

static var _mote_variants: Array = []

func _setup_sprite() -> void:
	super._setup_sprite()
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)

# Swarm "Null Mote" — built once, three corruption accents (green-led).
func _get_body_variants() -> Array:
	if _mote_variants.is_empty():
		_mote_variants.append(MoteSprite.build("toxic"))
		_mote_variants.append(MoteSprite.build("void"))
		_mote_variants.append(MoteSprite.build("red"))
	return _mote_variants

func _draw_health_bar() -> void:
	var bar_width := 12.0
	var bar_height := 2.0
	var bar_y := -16.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), Color(0.3, 0.9, 0.3))
