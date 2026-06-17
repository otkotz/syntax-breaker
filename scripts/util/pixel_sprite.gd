class_name PixelSprite
extends RefCounted

static func build_texture(rects: Array, circles: Array = [], padding: int = 2) -> Dictionary:
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for entry: Dictionary in rects:
		var r: Rect2 = entry["rect"]
		min_pos = min_pos.min(r.position)
		max_pos = max_pos.max(r.position + r.size)
	for entry: Dictionary in circles:
		var pos: Vector2 = entry["pos"]
		var radius: float = entry["radius"]
		min_pos = min_pos.min(pos - Vector2(radius, radius))
		max_pos = max_pos.max(pos + Vector2(radius, radius))

	var size := max_pos - min_pos + Vector2(padding * 2, padding * 2)
	var offset := -min_pos + Vector2(padding, padding)
	var img := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)

	for entry: Dictionary in rects:
		var r: Rect2 = entry["rect"]
		var c: Color = entry["color"]
		var x0 := int(r.position.x + offset.x)
		var y0 := int(r.position.y + offset.y)
		var w := int(r.size.x)
		var h := int(r.size.y)
		for y in range(maxi(0, y0), mini(img.get_height(), y0 + h)):
			for x in range(maxi(0, x0), mini(img.get_width(), x0 + w)):
				img.set_pixel(x, y, c)

	for entry: Dictionary in circles:
		var pos: Vector2 = entry["pos"]
		var radius: float = entry["radius"]
		var c: Color = entry["color"]
		var cx := pos.x + offset.x
		var cy := pos.y + offset.y
		var r2 := radius * radius
		for y in range(maxi(0, int(cy - radius)), mini(img.get_height(), int(cy + radius) + 1)):
			for x in range(maxi(0, int(cx - radius)), mini(img.get_width(), int(cx + radius) + 1)):
				var dx := float(x) + 0.5 - cx
				var dy := float(y) + 0.5 - cy
				if dx * dx + dy * dy <= r2:
					img.set_pixel(x, y, c)

	var tex := ImageTexture.create_from_image(img)
	var sprite_offset := (min_pos + max_pos) / 2.0
	return {"texture": tex, "offset": sprite_offset}

static func hue_shift(base_data: Dictionary, shift: float) -> Dictionary:
	var img: Image = base_data["texture"].get_image().duplicate()
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0:
				c.h = fmod(c.h + shift, 1.0)
				img.set_pixel(x, y, c)
	return {"texture": ImageTexture.create_from_image(img), "offset": base_data["offset"]}

static func build_circle_texture(radius: float, color: Color) -> Dictionary:
	return build_texture([], [{"pos": Vector2.ZERO, "radius": radius, "color": color}])

static func build_knife_texture(color: Color) -> Dictionary:
	var blade := color
	var edge := color.lightened(0.4)
	var handle := Color(0.35, 0.25, 0.18)
	var rects: Array = [
		{"rect": Rect2(-1, -10, 3, 12), "color": blade},
		{"rect": Rect2(0, -10, 1, 12), "color": edge},
		{"rect": Rect2(-1, -12, 3, 2), "color": blade.lightened(0.2)},
		{"rect": Rect2(0, -12, 1, 1), "color": Color.WHITE},
		{"rect": Rect2(-2, 2, 5, 2), "color": Color(0.5, 0.5, 0.55)},
		{"rect": Rect2(-1, 4, 3, 6), "color": handle},
		{"rect": Rect2(0, 4, 1, 6), "color": handle.lightened(0.15)},
	]
	return build_texture(rects)
