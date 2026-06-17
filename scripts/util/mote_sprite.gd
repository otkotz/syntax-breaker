class_name MoteSprite
extends IndexBuffer

## Procedural "NULL MOTE" swarm sprite.
## Ported from the JS pixel-buffer reference (engine/enemy_mote.js): a
## floating corrupted-data wisp — a big glowing orb-head under a jagged
## membrane hood, hovering over a ragged energy-veil that frays into raw
## pixels (no legs), with two thin clawed tendril-arms. Baked here as a
## single front-facing neutral pose (idle, frame 0). Corruption accent
## selects the colour variant (toxic / void / red). Rendered small — meant
## to be scaled down by the swarm enemy.

const W := 32
const H := 36
const CX := 16

# accent -> [bright, mid, glow]
const ACCENTS := {
	"toxic": ["9CFF8C", "3DF04A", "188A24"],
	"void": ["B9A0FF", "7B4DE6", "3A1F93"],
	"red": ["FF7E96", "FF3355", "A8112E"],
}

func _init() -> void:
	super(W, H)

# --- mote body parts (front-facing, neutral idle pose) ----------------------

func _paint() -> void:
	_paint_tail()
	var geo := _paint_orb()
	_paint_arms(geo)

# ragged energy-veil tail: streams down, narrows, frays into loose pixels
func _paint_tail() -> void:
	var top_y := 17
	for i in range(0, 14):
		var y := top_y + i
		if y >= H:
			break
		var t := float(i) / 13.0
		var wob := _jr(sin(t * 5.0) * (1.0 + t * 2.0))
		var half := maxi(0, 4 - _jr(t * 4.5))
		if half <= 0:
			# frayed tip: sparse detached pixels
			if i % 2 == 0:
				_px(CX + wob, y, 13 if i % 4 == 0 else 3)
			continue
		_hline(CX - half + wob - 1, CX + half + wob + 1, y, 1)          # outline
		_hline(CX - half + wob, CX + half + wob, y, 3 if t < 0.5 else 2)  # veil band
		if i < 9 and i % 2 == 0:
			_px(CX + wob, y, 13)                                          # glowing inner thread

# orb head: membrane hood over a glowing face with hollow hostile eyes
func _paint_orb() -> Dictionary:
	var cy := 11
	var fx := CX
	_fill_ellipse(fx, cy, 8, 8, 0)        # reserve halo (clears overlapping tail)
	_fill_ellipse(fx, cy, 7, 7, 1)        # outline
	_fill_ellipse(fx, cy, 6, 6, 3)        # membrane base
	_fill_ellipse(fx, cy - 1, 5, 5, 4)    # mid up top
	_px(fx - 4, cy - 3, 5); _px(fx - 3, cy - 4, 5); _px(fx - 2, cy - 5, 5)  # rim light
	_px(fx, cy - 7, 1); _px(fx - 1, cy - 6, 4); _px(fx + 1, cy - 6, 4)      # hood peak

	var fy := cy + 1
	_fill_ellipse(fx, fy + 1, 5, 4, 13)   # face glow
	_fill_ellipse(fx, fy + 1, 4, 3, 12)   # mid
	_fill_ellipse(fx, fy + 1, 3, 2, 11)   # bright core
	_px(fx, fy + 1, 10)                    # hotspot
	_hline(fx - 4, fx + 4, cy - 2, 2)      # brim shadow across the brow
	_px(fx - 5, cy - 1, 3); _px(fx + 5, cy - 1, 3)
	_hollow_eye(fx - 2, fy, -1)
	_hollow_eye(fx + 2, fy, 1)
	_px(fx - 2, fy + 3, 7); _px(fx, fy + 4, 7); _px(fx + 2, fy + 3, 7)      # fanged underbite
	return {"cy": cy, "fx": fx}

func _hollow_eye(x: int, y: int, slant: int) -> void:
	_px(x, y, 6); _px(x + slant, y - 1, 6); _px(x, y + 1, 1)
	_px(x - slant, y, 11)                  # hot accent glint

# two thin clawed tendril-arms, dangling in idle
func _paint_arms(geo: Dictionary) -> void:
	var cy: int = geo["cy"]
	var fx: int = geo["fx"]
	_tendril(fx - 5, cy + 3, fx - 6, cy + 9, 1)
	_tendril(fx + 5, cy + 3, fx + 6, cy + 9, 1)

# thin 1px arm with a splayed bone-claw at the tip (forward = straight down)
func _tendril(sx: int, sy: int, ex: int, ey: int, spread: int) -> void:
	_line(sx, sy + 1, ex, ey + 1, 1)       # outline below
	_line(sx, sy, ex, ey, 8)               # arm
	_px(ex, ey, 7)
	_px(ex, ey + 1, 7)
	_px(ex - spread, ey + 1, 7)
	_px(ex + spread, ey + 1, 7)

# --- palette ----------------------------------------------------------------

func _palette(accent: String) -> Array:
	var a: Array = ACCENTS.get(accent, ACCENTS["toxic"])
	return [
		Color(0, 0, 0, 0),       # 0 transparent
		Color.html("050109"),    # 1 outline
		Color.html("120620"),    # 2 veil darkest
		Color.html("1d0c30"),    # 3 veil base
		Color.html("2c1648"),    # 4 veil mid
		Color.html("442463"),    # 5 veil rim
		Color.html("08030f"),    # 6 inner void
		Color.html("d7c8e6"),    # 7 claw light
		Color.html("9c89b3"),    # 8 claw mid
		Color.html("665382"),    # 9 claw shadow
		Color.html("ffffff"),    # 10 highlight
		Color.html(a[0]),        # 11 accent bright
		Color.html(a[1]),        # 12 accent mid
		Color.html(a[2]),        # 13 accent glow
		Color.html("46E66A"),    # 14 toxic data
	]

## Build a {"texture", "offset"} dict for the given corruption accent
## ("toxic", "void", "red").
static func build(accent: String = "toxic") -> Dictionary:
	var m := MoteSprite.new()
	m._paint()
	return m._bake(CX, m._palette(accent))
