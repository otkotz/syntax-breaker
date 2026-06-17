class_name DemonSprite
extends IndexBuffer

## Procedural "DROSS, THE BURNING" boss sprite.
## Ported from the JS pixel-buffer reference (engine/boss_demon.js): a hulking
## horned demon-lord of charred data-flesh — sweeping horns over a skull head
## with burning eye-pits and a molten maw, broad hunched shoulders, huge clawed
## arms, a ribcage cracked open over a molten furnace-core, a spiked spine and
## cloven-hoof legs. Baked here as a single front-facing neutral pose (idle,
## frame 0). Corruption accent selects the colour variant (fire / red / void).

const W := 72
const H := 82
const CX := 36

# accent -> [bright, mid, glow]
const ACCENTS := {
	"fire": ["FFD24A", "FF6619", "A82400"],
	"red": ["FF7E96", "FF3355", "A8112E"],
	"void": ["C2ABFF", "7B4DE6", "3A1F93"],
}

func _init() -> void:
	super(W, H)

# --- demon body parts (front-facing, neutral idle pose) ---------------------

func _paint() -> void:
	var ground_top := 78
	var torso_top := 22
	var sh_y := torso_top + 3
	_paint_back(sh_y)
	_paint_legs(ground_top)
	_paint_torso(torso_top)
	_paint_head(torso_top - 3)
	# huge clawed arms hang heavy, drawn over the torso
	_arm(CX - 16, sh_y + 2, -1)
	_arm(CX + 16, sh_y + 2, 1)

# row of bony spine spikes rising over the shoulders
func _paint_back(sh_y: int) -> void:
	for i in range(-2, 3):
		var x := CX + i * 4
		var hh := 6 - absi(i)
		_line(x, sh_y - 2, x, sh_y - 2 - hh, 1)
		_line(x, sh_y - 2, x, sh_y - 1 - hh, 7)
		_px(x, sh_y - 2 - hh, 5)

# cloven-hoof digitigrade legs
func _paint_legs(top_y: int) -> void:
	for spec in [[-1, CX - 13], [1, CX + 13]]:
		var sgn: int = spec[0]
		var hoof_x: int = spec[1]
		var hip_x := CX + sgn * 7
		var hip_y := top_y - 20
		var knee_x := hoof_x
		var knee_y := top_y - 9
		var ank_x := hoof_x - sgn * 3
		var ank_y := top_y
		_limb(hip_x, hip_y, knee_x, knee_y, 2, 3, 1)   # thick thigh
		_limb(knee_x, knee_y, ank_x, ank_y, 1, 4, 1)   # shin
		_px(knee_x, knee_y - 1, 5)
		# cloven hoof (two toes)
		_fill_rect(ank_x - 3, ank_y, 7, 3, 1)
		_fill_rect(ank_x - 2, ank_y, 5, 2, 9)
		_px(ank_x, ank_y + 2, 0)   # cleft
		_px(ank_x - 3, ank_y - 1, 14); _px(ank_x + 3, ank_y, 14)  # embers

# broad hunched chest cracked open over a molten furnace-core
func _paint_torso(top_y: int) -> void:
	_fill_trapezoid(CX - 17, CX + 17, top_y, CX - 11, CX + 11, top_y + 26, 1)
	_fill_trapezoid(CX - 16, CX + 16, top_y + 1, CX - 10, CX + 10, top_y + 25, 3)
	_fill_trapezoid(CX - 15, CX + 3, top_y + 1, CX - 9, CX + 1, top_y + 25, 4)
	_hline(CX - 14, CX + 14, top_y + 4, 8)   # pectoral ridge
	var gy := top_y + 15
	_fill_ellipse(CX, gy, 6, 7, 1)
	_fill_ellipse(CX, gy, 5, 6, 13)
	_fill_ellipse(CX, gy, 4, 5, 12)
	_fill_ellipse(CX, gy - 1, 1, 2, 11)
	for r in [-4, 0, 4]:
		_line(CX + r, gy - 5, CX + r, gy + 5, 1)   # rib bars
	_px(CX - 6, gy - 5, 13); _px(CX + 6, gy - 3, 13); _px(CX - 5, gy + 6, 12)
	_px(CX + 5, gy + 5, 13); _px(CX - 8, gy, 14); _px(CX + 8, gy - 1, 14)  # molten cracks

# horned skull head with burning eye-pits and a molten maw
func _paint_head(hy: int) -> void:
	var hcx := CX
	var hcy := hy
	for s in [-1, 1]:
		_line(hcx + s * 5, hcy - 4, hcx + s * 10, hcy - 10, 1)
		_line(hcx + s * 10, hcy - 10, hcx + s * 9, hcy - 19, 1)
		_line(hcx + s * 5, hcy - 4, hcx + s * 9, hcy - 10, 7)
		_line(hcx + s * 10, hcy - 10, hcx + s * 8, hcy - 18, 8)
		_px(hcx + s * 9, hcy - 19, 5)   # horn tip
		_line(hcx + s * 6, hcy - 1, hcx + s * 12, hcy - 3, 1); _px(hcx + s * 12, hcy - 3, 8)
	_fill_ellipse(hcx, hcy, 7, 6, 1)
	_fill_ellipse(hcx, hcy, 6, 5, 3)
	_fill_ellipse(hcx - 1, hcy - 1, 4, 3, 4)
	_px(hcx - 4, hcy - 2, 5)
	# burning eye-pits
	_fill_ellipse(hcx - 3, hcy - 1, 2, 2, 6); _px(hcx - 3, hcy - 1, 11); _set_behind(hcx - 3, hcy - 2, 13)
	_fill_ellipse(hcx + 3, hcy - 1, 2, 2, 6); _px(hcx + 3, hcy - 1, 11); _set_behind(hcx + 3, hcy - 2, 13)
	_hline(hcx - 6, hcx + 6, hcy - 3, 2)   # brow ridge
	# molten maw
	_fill_ellipse(hcx, hcy + 4, 3, 3, 1)
	_fill_ellipse(hcx, hcy + 4, 2, 2, 13)
	for t in [-2, 0, 2]:
		_px(hcx + t, hcy + 2, 7); _px(hcx + t, hcy + 6, 7)   # fang teeth

# huge clawed arm hanging heavy at rest
func _arm(sx: int, sy: int, sgn: int) -> void:
	var elbow_x := sx + sgn * 7
	var elbow_y := sy + 9
	var fist_x := sx + sgn * 6
	var fist_y := sy + 19
	_fill_ellipse(sx, sy, 5, 4, 1); _fill_ellipse(sx, sy, 4, 3, 4); _px(sx - sgn, sy - 1, 5)  # shoulder knot
	_limb(sx, sy, elbow_x, elbow_y, 2, 3, 1)
	_px(elbow_x, elbow_y, 5)
	_limb(elbow_x, elbow_y, fist_x, fist_y, 2, 4, 1)
	_fill_ellipse(fist_x, fist_y, 4, 4, 1)
	_fill_ellipse(fist_x, fist_y, 3, 3, 3)
	_fill_ellipse(fist_x - 1, fist_y - 1, 2, 2, 4)
	_px(fist_x - 3, fist_y + 3, 7); _px(fist_x, fist_y + 4, 7); _px(fist_x + 3, fist_y + 3, 7)  # talons
	_px(fist_x - 3, fist_y + 4, 8); _px(fist_x + 3, fist_y + 4, 8)

# --- palette ----------------------------------------------------------------

func _palette(accent: String) -> Array:
	var a: Array = ACCENTS.get(accent, ACCENTS["fire"])
	return [
		Color(0, 0, 0, 0),       # 0 transparent
		Color.html("0a0406"),    # 1 outline
		Color.html("241016"),    # 2 charred flesh darkest
		Color.html("3a1820"),    # 3 charred flesh base
		Color.html("4f2024"),    # 4 charred flesh mid
		Color.html("6e2d2a"),    # 5 charred flesh rim
		Color.html("080205"),    # 6 maw / core void
		Color.html("e8d6b0"),    # 7 horn / claw light
		Color.html("b69a72"),    # 8 horn / claw mid
		Color.html("7a6044"),    # 9 horn / claw dark
		Color.html("ffffff"),    # 10 white
		Color.html(a[0]),        # 11 accent bright
		Color.html(a[1]),        # 12 accent mid
		Color.html(a[2]),        # 13 accent glow
		Color.html("FF8A3C"),    # 14 ember
	]

## Build a {"texture", "offset"} dict for the given corruption accent
## ("fire", "red", "void").
static func build(accent: String = "fire") -> Dictionary:
	var s := DemonSprite.new()
	s._paint()
	return s._bake(CX, s._palette(accent))
