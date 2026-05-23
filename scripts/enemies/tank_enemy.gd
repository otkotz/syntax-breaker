class_name TankEnemy
extends EnemyBase

static var _tank_texture: ImageTexture
static var _tank_offset: Vector2

func _get_body_texture_data() -> Dictionary:
	if not _tank_texture:
		var data := _build_tank_texture()
		_tank_texture = data["texture"]
		_tank_offset = data["offset"]
	return {"texture": _tank_texture, "offset": _tank_offset}

static func _build_tank_texture() -> Dictionary:
	const ARMOR_D := Color(0.15, 0.12, 0.08)
	const ARMOR_M := Color(0.35, 0.28, 0.18)
	const ARMOR_L := Color(0.55, 0.45, 0.28)
	const SKIN_D := Color(0.20, 0.04, 0.06)
	const SKIN_M := Color(0.45, 0.10, 0.14)
	const EYE := Color(1.0, 0.3, 0.2)
	const OUTLINE := Color(0.04, 0.02, 0.02)

	var r: Array = []
	var c: Array = []
	var _r := func(x: float, y: float, w: float, h: float, col: Color) -> void:
		r.append({"rect": Rect2(x, y, w, h), "color": col})
	var _c := func(pos: Vector2, radius: float, col: Color) -> void:
		c.append({"pos": pos, "radius": radius, "color": col})

	# Legs
	_r.call(-6, -14, 5, 14, SKIN_M); _r.call(2, -14, 5, 14, SKIN_M)
	_r.call(-6, 0, 5, 1, OUTLINE); _r.call(2, 0, 5, 1, OUTLINE)
	# Torso armor
	_r.call(-8, -28, 16, 14, ARMOR_M); _r.call(-8, -28, 16, 2, ARMOR_L)
	_r.call(-8, -28, 2, 14, ARMOR_D); _r.call(6, -28, 2, 14, ARMOR_D)
	# Chest plate
	_r.call(-5, -25, 10, 8, ARMOR_L); _r.call(-3, -24, 6, 4, ARMOR_D)
	# Shoulder pads
	_r.call(-10, -30, 4, 6, ARMOR_M); _r.call(-10, -30, 4, 2, ARMOR_L)
	_r.call(6, -30, 4, 6, ARMOR_M); _r.call(6, -30, 4, 2, ARMOR_L)
	# Arms
	_r.call(-10, -24, 3, 10, SKIN_M); _r.call(7, -24, 3, 10, SKIN_M)
	# Head (helmeted)
	_r.call(-5, -38, 10, 10, ARMOR_M); _r.call(-5, -38, 10, 2, ARMOR_L)
	_r.call(-5, -38, 1, 10, ARMOR_D); _r.call(4, -38, 1, 10, ARMOR_D)
	# Visor slit
	_r.call(-3, -34, 6, 2, OUTLINE); _r.call(-2, -33, 2, 1, EYE); _r.call(1, -33, 2, 1, EYE)
	# Shield
	_r.call(-12, -26, 3, 14, ARMOR_D); _r.call(-12, -26, 3, 2, ARMOR_L); _r.call(-11, -20, 1, 2, ARMOR_L)

	return PixelSprite.build_texture(r, c)

func _draw_health_bar() -> void:
	var bar_width := 32.0
	var bar_height := 4.0
	var bar_y := -50.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), Color(0.8, 0.4, 0.1))
