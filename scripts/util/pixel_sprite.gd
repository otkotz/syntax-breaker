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
	var sprite_offset := -(min_pos + max_pos) / 2.0
	return {"texture": tex, "offset": sprite_offset}

static func build_circle_texture(radius: float, color: Color) -> Dictionary:
	return build_texture([], [{"pos": Vector2.ZERO, "radius": radius, "color": color}])
