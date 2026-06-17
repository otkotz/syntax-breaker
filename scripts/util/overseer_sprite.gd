class_name OverseerSprite
extends IndexBuffer

## Procedural "THE OVERSEER" boss sprite — the System given form.
## Ported from the JS pixel-buffer reference (engine/boss_overseer.js): a
## colossal hovering data-monolith — a beveled obelisk of compiled plate
## cracked vertically to bare a single great gaze-eye, a fractured halo-crown
## above, four orbiting rune-shards, and a tapering energy-keel instead of
## legs. Baked here as a single front-facing neutral pose (idle, frame 0).
## Accent: system / lightning / void.

const W := 80
const H := 84
const CX := 40

# accent -> [bright, mid, glow]
const ACCENTS := {
	"system": ["9EEBFF", "3FB4F0", "1359A8"],
	"lightning": ["BFE0FF", "66B3FF", "1E5FA8"],
	"void": ["C2ABFF", "7B4DE6", "3A1F93"],
}

func _init() -> void:
	super(W, H)

# --- overseer parts (front-facing, neutral idle pose) -----------------------

func _paint() -> void:
	var body_top := 16
	var eye_y := body_top + 19
	var bx := _paint_body(body_top)
	_paint_keel(bx, body_top + 40)
	_paint_crown(bx, body_top)
	_paint_eye(bx, eye_y)
	# shards orbit in front of the obelisk (drawn last)
	_paint_shards(CX, eye_y)

# beveled hexagonal obelisk slab
func _paint_body(top_y: int) -> int:
	var bx := CX
	_fill_trapezoid(bx - 7, bx + 7, top_y, bx - 13, bx + 13, top_y + 10, 1)       # outline upper bevel
	_fill_rect(bx - 13, top_y + 10, 27, 20, 1)                                     # outline mid
	_fill_trapezoid(bx - 13, bx + 13, top_y + 30, bx - 8, bx + 8, top_y + 40, 1)   # outline lower bevel
	_fill_trapezoid(bx - 6, bx + 6, top_y + 1, bx - 12, bx + 12, top_y + 10, 3)
	_fill_rect(bx - 12, top_y + 10, 25, 20, 3)
	_fill_trapezoid(bx - 12, bx + 12, top_y + 30, bx - 7, bx + 7, top_y + 39, 3)
	# left-lit facet
	_fill_trapezoid(bx - 6, bx - 1, top_y + 1, bx - 12, bx - 3, top_y + 10, 4)
	_fill_rect(bx - 12, top_y + 10, 7, 20, 4)
	_fill_trapezoid(bx - 12, bx - 3, top_y + 30, bx - 7, bx - 2, top_y + 39, 4)
	# bevel rim light
	_line(bx - 13, top_y + 10, bx - 7, top_y, 5)
	_vline(top_y + 10, top_y + 29, bx - 12, 5)
	# hard panel seams
	_hline(bx - 12, bx + 12, top_y + 10, 9)
	_hline(bx - 12, bx + 12, top_y + 29, 9)
	_hline(bx - 11, bx + 11, top_y + 19, 8)
	# corrupted data glyphs etched on the plate
	_px(bx + 6, top_y + 14, 11); _px(bx + 8, top_y + 14, 12); _px(bx + 6, top_y + 16, 12)
	_px(bx - 9, top_y + 24, 12); _px(bx + 9, top_y + 24, 11); _px(bx - 7, top_y + 34, 12)
	return bx

# downward tapering blade of light beneath the monolith
func _paint_keel(cx: int, bot_y: int) -> void:
	for i in 12:
		var y := bot_y + i
		var half := maxi(0, 5 - _jr(i * 0.7))
		if half <= 0:
			if i % 2 == 0:
				_px(cx, y, 13)
			continue
		_hline(cx - half, cx + half, y, 3 if i < 4 else 2)
		_px(cx, y, 12 if i < 7 else 13)
		if i < 3:
			_px(cx - half, y, 5); _px(cx + half, y, 5)

# fractured halo-crown of broken crown-segments above the obelisk
func _paint_crown(cx: int, top_y: int) -> void:
	var segs := [-10, -6, -2, 2, 6, 10]
	for i in segs.size():
		var x: int = segs[i]
		var hh := 3 if (i == 0 or i == 5) else (6 if (i == 2 or i == 3) else 4)
		var yy := top_y - 2 - (2 if (i == 2 or i == 3) else 0)
		_fill_rect(cx + x - 1, yy - hh, 3, hh, 1)
		_fill_rect(cx + x, yy - hh + 1, 1, hh - 1, 5)
		_px(cx + x, yy - hh, 13)   # glowing tip
	_px(cx - 14, top_y - 6, 12); _px(cx + 14, top_y - 7, 13)   # detached glitched segments

# single great gaze-eye bared in the cracked plate
func _paint_eye(bx: int, ey: int) -> void:
	var rx := 6
	var ry := 4
	_fill_ellipse(bx, ey, rx + 1, ry + 1, 6)   # socket recess
	_fill_ellipse(bx, ey, rx, ry, 1)
	_fill_ellipse(bx, ey, rx - 1, ry - 1, 13)  # glowing iris
	_fill_ellipse(bx, ey, rx - 2, ry - 1, 12)
	_fill_ellipse(bx, ey, rx - 3, ry - 2, 11)
	_vline(ey - ry + 1, ey + ry - 1, bx, 6)     # dark slit pupil
	_vline(ey - ry + 2, ey + ry - 2, bx, 1)
	_px(bx, ey, 10); _px(bx - 1, ey - 1, 10)
	_hline(bx - rx, bx + rx, ey - ry - 1, 9)     # lid bevels
	_hline(bx - rx, bx + rx, ey + ry + 1, 9)
	_px(bx - rx - 1, ey, 5); _px(bx + rx + 1, ey, 5)   # brow brand

# four orbiting rune-shards (idle positions N/E/S/W)
func _paint_shards(cx: int, cy: int) -> void:
	var rad := 22.0
	for a0 in [-PI / 2.0, 0.0, PI / 2.0, PI]:
		var x := _jr(float(cx) + cos(a0) * rad * 1.05)
		var y := _jr(float(cy) + sin(a0) * rad * 0.85)
		_shard(x, y, 3)

func _shard(x: int, y: int, s: int) -> void:
	_px(x, y - s, 1); _px(x, y + s, 1); _px(x - s, y, 1); _px(x + s, y, 1)   # diamond points
	_line(x, y - s, x + s, y, 1); _line(x + s, y, x, y + s, 1)
	_line(x, y + s, x - s, y, 1); _line(x - s, y, x, y - s, 1)               # diamond edges
	_fill_ellipse(x, y, s - 1, s - 1, 3)
	_px(x, y, 13); _px(x, y - 1, 12); _px(x - 1, y, 5)   # glowing rune slit

# --- palette ----------------------------------------------------------------

func _palette(accent: String) -> Array:
	var a: Array = ACCENTS.get(accent, ACCENTS["system"])
	return [
		Color(0, 0, 0, 0),       # 0 transparent
		Color.html("05070e"),    # 1 outline
		Color.html("10162a"),    # 2 plate darkest
		Color.html("1a2440"),    # 3 plate base
		Color.html("263458"),    # 4 plate mid
		Color.html("374a74"),    # 5 plate rim
		Color.html("04060f"),    # 6 inner void
		Color.html("cdd9ef"),    # 7 bevel light
		Color.html("8d9cc0"),    # 8 bevel mid
		Color.html("566489"),    # 9 bevel dark
		Color.html("ffffff"),    # 10 white
		Color.html(a[0]),        # 11 accent bright
		Color.html(a[1]),        # 12 accent mid
		Color.html(a[2]),        # 13 accent glow
		Color.html("46E66A"),    # 14 data bit
	]

## Build a {"texture", "offset"} dict for the given corruption accent
## ("system", "lightning", "void").
static func build(accent: String = "system") -> Dictionary:
	var s := OverseerSprite.new()
	s._paint()
	return s._bake(CX, s._palette(accent))
