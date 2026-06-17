class_name OracleSprite
extends IndexBuffer

## Procedural "NULL ORACLE" ranged-caster sprite.
## Ported from the JS pixel-buffer reference (engine/ranged_oracle.js): a
## floating corrupted seer — one oversized vertical EYE set in an ornate
## diamond brow-frame above a narrow draped robe that trails to a frayed
## floating hem (no legs), two thin arms hanging at rest. Baked here as a
## single front-facing neutral pose (idle, frame 0). Corruption accent
## selects the colour variant (void / magenta / cold).

const W := 32
const H := 36
const CX := 16

# accent -> [bright, mid, glow]
const ACCENTS := {
	"void": ["C2ABFF", "7B4DE6", "3A1F93"],
	"magenta": ["FF87E0", "E63DB0", "8C1E73"],
	"cold": ["DFF7FF", "99E6FF", "2E7FA8"],
}

func _init() -> void:
	super(W, H)

# --- oracle body parts (front-facing, neutral idle pose) --------------------

func _paint() -> void:
	var geo := _paint_robe()
	_paint_head()
	_paint_arms(geo)

# draped robe trailing to a frayed floating hem, glowing corruption seam
func _paint_robe() -> Dictionary:
	var sh_y := 16
	var hem_y := 29
	_fill_trapezoid(CX - 5, CX + 5, sh_y - 1, CX - 7, CX + 7, hem_y + 1, 1)
	_fill_trapezoid(CX - 4, CX + 4, sh_y, CX - 6, CX + 6, hem_y, 3)
	_fill_trapezoid(CX - 2, CX + 3, sh_y + 1, CX - 4, CX + 5, hem_y, 4)
	_vline(sh_y + 1, hem_y - 1, CX + 4, 5)   # rim light
	_vline(sh_y + 2, hem_y - 1, CX - 1, 2)   # dark fold
	# frayed floating tatters at the hem
	for i in range(-3, 4):
		var tx := CX + i * 2
		var length := 2 + (i + 7) % 3
		for j in length:
			var yy := hem_y + j
			if yy >= H:
				break
			_px(tx, yy, 1 if j == length - 1 else (2 if j % 2 == 1 else 3))
	# glowing corruption seam down the centre
	var y := sh_y + 2
	while y < hem_y:
		_px(CX, y, 13)
		y += 2
	return {"sh_y": sh_y, "hem_y": hem_y}

# single-eye head in an ornate diamond brow-frame
func _paint_head() -> void:
	var cy := 10
	var fx := CX
	# diamond frame outline
	_line(fx, cy - 8, fx + 7, cy, 1); _line(fx + 7, cy, fx, cy + 8, 1)
	_line(fx, cy + 8, fx - 7, cy, 1); _line(fx - 7, cy, fx, cy - 8, 1)
	# inner frame metal
	_line(fx, cy - 7, fx + 6, cy, 8); _line(fx + 6, cy, fx, cy + 7, 8)
	_line(fx, cy + 7, fx - 6, cy, 9); _line(fx - 6, cy, fx, cy - 7, 9)
	# prong accents
	_px(fx, cy - 9, 8); _px(fx - 8, cy, 8); _px(fx + 8, cy, 8)
	# the eye: tall almond with a glowing vertical iris
	_fill_ellipse(fx, cy, 4, 6, 6)   # sclera (dark)
	_fill_ellipse(fx, cy, 3, 5, 7)   # void
	_fill_ellipse(fx, cy, 2, 4, 13)  # glow
	_fill_ellipse(fx, cy, 1, 3, 12)
	_vline(cy - 2, cy + 2, fx, 11)
	_px(fx, cy - 1, 10)              # glint
	_px(fx, cy - 6, 9); _px(fx, cy + 6, 9)  # lid shading

# thin arms hanging at rest
func _paint_arms(geo: Dictionary) -> void:
	var sh_y: int = geo["sh_y"]
	_line(CX - 4, sh_y + 2, CX - 5, sh_y + 8, 1); _line(CX - 4, sh_y + 1, CX - 5, sh_y + 7, 4)
	_line(CX + 4, sh_y + 2, CX + 5, sh_y + 8, 1); _line(CX + 4, sh_y + 1, CX + 5, sh_y + 7, 4)
	_px(CX - 5, sh_y + 8, 8); _px(CX + 5, sh_y + 8, 8)  # hands

# --- palette ----------------------------------------------------------------

func _palette(accent: String) -> Array:
	var a: Array = ACCENTS.get(accent, ACCENTS["void"])
	return [
		Color(0, 0, 0, 0),       # 0 transparent
		Color.html("040108"),    # 1 outline
		Color.html("150a24"),    # 2 robe darkest
		Color.html("231138"),    # 3 robe base
		Color.html("351b51"),    # 4 robe mid
		Color.html("4d2a6e"),    # 5 robe rim
		Color.html("0a0512"),    # 6 eye sclera
		Color.html("02000a"),    # 7 iris / void
		Color.html("b9a6cf"),    # 8 frame metal
		Color.html("6a5685"),    # 9 frame shadow
		Color.html("ffffff"),    # 10 white
		Color.html(a[0]),        # 11 accent bright
		Color.html(a[1]),        # 12 accent mid
		Color.html(a[2]),        # 13 accent glow
		Color.html("46E66A"),    # 14 toxic data
	]

## Build a {"texture", "offset"} dict for the given corruption accent
## ("void", "magenta", "cold").
static func build(accent: String = "void") -> Dictionary:
	var s := OracleSprite.new()
	s._paint()
	return s._bake(CX, s._palette(accent))
