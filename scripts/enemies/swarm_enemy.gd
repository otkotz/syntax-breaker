class_name SwarmEnemy
extends EnemyBase

static var _swarm_texture: ImageTexture
static var _swarm_offset: Vector2

func _get_body_texture_data() -> Dictionary:
	if not _swarm_texture:
		var data := _build_swarm_texture()
		_swarm_texture = data["texture"]
		_swarm_offset = data["offset"]
	return {"texture": _swarm_texture, "offset": _swarm_offset}

static func _build_swarm_texture() -> Dictionary:
	const BODY_D := Color(0.12, 0.15, 0.08)
	const BODY_M := Color(0.25, 0.35, 0.15)
	const BODY_L := Color(0.40, 0.55, 0.22)
	const EYE := Color(1.0, 0.8, 0.2)
	const LEG := Color(0.15, 0.10, 0.05)

	var r: Array = []
	var _r := func(x: float, y: float, w: float, h: float, c: Color) -> void:
		r.append({"rect": Rect2(x, y, w, h), "color": c})

	# Body
	_r.call(-3, -8, 6, 8, BODY_M); _r.call(-2, -9, 4, 1, BODY_L)
	_r.call(-3, -8, 1, 8, BODY_D); _r.call(2, -8, 1, 8, BODY_D)
	# Eyes
	_r.call(-2, -7, 1, 1, EYE); _r.call(1, -7, 1, 1, EYE)
	# Legs
	for i in 3:
		var ly := float(-6 + i * 3)
		_r.call(-4, ly, 1, 1, LEG); _r.call(3, ly, 1, 1, LEG)
	# Mandibles
	_r.call(-1, -10, 1, 1, LEG); _r.call(0, -10, 1, 1, LEG)

	return PixelSprite.build_texture(r)

func _draw_health_bar() -> void:
	var bar_width := 12.0
	var bar_height := 2.0
	var bar_y := -16.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), Color(0.3, 0.9, 0.3))
