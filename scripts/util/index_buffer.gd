class_name IndexBuffer
extends RefCounted

## Tiny indexed-colour pixel buffer + crisp baker, shared by the procedural
## enemy sprites ported from the JS reference pack (engine/pixel.js). A buffer
## is a w×h grid of palette INDICES (index 0 = transparent). Drawing primitives
## paint indices; `_bake()` resolves them against a palette into an ImageTexture.

var w: int
var h: int
var data: PackedByteArray

func _init(width: int, height: int) -> void:
	w = width
	h = height
	data.resize(w * h)

# --- primitives (palette indices; 0 = transparent) --------------------------

func _idx(x: int, y: int) -> int:
	return y * w + x

func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h

func _px(x: int, y: int, c: int) -> void:
	if _in_bounds(x, y):
		data[_idx(x, y)] = c

## paint only if the target pixel is currently transparent
func _set_behind(x: int, y: int, c: int) -> void:
	if _in_bounds(x, y) and data[_idx(x, y)] == 0:
		data[_idx(x, y)] = c

func _get_px(x: int, y: int) -> int:
	return data[_idx(x, y)] if _in_bounds(x, y) else 0

func _hline(x0: int, x1: int, y: int, c: int) -> void:
	for x in range(mini(x0, x1), maxi(x0, x1) + 1):
		_px(x, y, c)

func _vline(y0: int, y1: int, x: int, c: int) -> void:
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		_px(x, y, c)

func _line(x0: int, y0: int, x1: int, y1: int, c: int) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		_px(x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

func _fill_rect(x: int, y: int, rw: int, rh: int, c: int) -> void:
	for j in rh:
		for i in rw:
			_px(x + i, y + j, c)

func _fill_ellipse(cx: int, cy: int, rx: int, ry: int, c: int) -> void:
	if rx <= 0 or ry <= 0:
		return
	for y in range(-ry, ry + 1):
		for x in range(-rx, rx + 1):
			var nx := float(x) / float(rx)
			var ny := float(y) / float(ry)
			if nx * nx + ny * ny <= 1.0:
				_px(cx + x, cy + y, c)

func _fill_trapezoid(tx0: int, tx1: int, ty: int, bx0: int, bx1: int, by: int, c: int) -> void:
	var span := by - ty
	if span == 0:
		span = 1
	for y in range(ty, by + 1):
		var t := float(y - ty) / float(span)
		var x0 := _jr(float(tx0) + float(bx0 - tx0) * t)
		var x1 := _jr(float(tx1) + float(bx1 - tx1) * t)
		_hline(x0, x1, y, c)

## thick line of half-width `wid` (edge index on the outer two rows)
func _limb(x0: int, y0: int, x1: int, y1: int, wid: int, c_fill: int, c_edge: int) -> void:
	var dx := x1 - x0
	var dy := y1 - y0
	var l := maxf(1.0, sqrt(float(dx * dx + dy * dy)))
	var nx := -float(dy) / l
	var ny := float(dx) / l
	for o in range(-wid, wid + 1):
		var c := c_edge if (o == -wid or o == wid) else c_fill
		_line(_jr(x0 + nx * o), _jr(y0 + ny * o), _jr(x1 + nx * o), _jr(y1 + ny * o), c)

## JS-style Math.round (half rounds toward +infinity)
func _jr(v: float) -> int:
	return int(floor(v + 0.5))

# --- bake -------------------------------------------------------------------

## Crop to non-transparent content, resolve `pal` (Array[Color] by index) and
## return a {"texture", "offset"} dict matching PixelSprite.build_texture's
## contract. Pivot is bottom-centre on column `cx` (feet on the baseline).
func _bake(cx: int, pal: Array) -> Dictionary:
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	for y in h:
		for x in w:
			if data[_idx(x, y)] != 0:
				min_x = mini(min_x, x); max_x = maxi(max_x, x)
				min_y = mini(min_y, y); max_y = maxi(max_y, y)
	if max_x < 0:
		return {"texture": ImageTexture.new(), "offset": Vector2.ZERO}

	var iw := max_x - min_x + 1
	var ih := max_y - min_y + 1
	var img := Image.create(iw, ih, false, Image.FORMAT_RGBA8)
	for y in ih:
		for x in iw:
			var c := data[_idx(min_x + x, min_y + y)]
			if c != 0:
				img.set_pixel(x, y, pal[c])

	var tex := ImageTexture.create_from_image(img)
	var offset := Vector2(
		(min_x + max_x) / 2.0 - cx,
		(min_y + max_y) / 2.0 - max_y
	)
	return {"texture": tex, "offset": offset}
