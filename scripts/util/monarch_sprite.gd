class_name MonarchSprite
extends IndexBuffer

## Procedural "THE HOLLOW MONARCH" boss sprite.
## Ported from the JS pixel-buffer reference (engine/boss_monarch.js): a
## towering insectoid ant-king — a crowned wedge head with compound eyes and
## splayed mandibles, a high carapace collar over an armored thorax cracked
## open on a glowing brood-core, two great scythe forearms, folded elytra
## wing-cases, a segmented abdomen and digitigrade legs. Baked here as a single
## front-facing neutral pose (idle, frame 0). Accent: toxic / royal / red.

const W := 64
const H := 88
const CX := 32

# accent -> [bright, mid, glow]
const ACCENTS := {
	"toxic": ["9CFF8C", "3DF04A", "188A24"],
	"royal": ["D7B3FF", "9A5BE6", "4A1F93"],
	"red": ["FF7E96", "FF3355", "A8112E"],
}

func _init() -> void:
	super(W, H)

# --- monarch body parts (front-facing, neutral idle pose) -------------------

func _paint() -> void:
	var thorax_top := 34
	var sh_y := thorax_top + 4
	_paint_abdomen(thorax_top + 16)
	_paint_elytra(sh_y)
	_paint_legs(84)
	_paint_thorax(thorax_top)
	_paint_head(thorax_top - 4)
	_scythe(CX - 10, sh_y + 2, -1)
	_scythe(CX + 10, sh_y + 2, 1)

# tapering teardrop of stacked chitin segments behind the body
func _paint_abdomen(top_y: int) -> void:
	for seg in [[top_y, 8], [top_y + 5, 7], [top_y + 10, 5], [top_y + 15, 3]]:
		var y: int = seg[0]
		var r: int = seg[1]
		_fill_ellipse(CX, y, r + 1, 4, 1)
		_fill_ellipse(CX, y, r, 3, 2)
		_fill_ellipse(CX - 1, y - 1, r - 2, 2, 3)
		_hline(CX - r, CX + r, y + 3, 1)   # segment seam
	_px(CX, top_y + 18, 1); _px(CX, top_y + 19, 9)   # stinger tip

# folded elytra wing-cases on the back
func _paint_elytra(sh_y: int) -> void:
	for s in [-1, 1]:
		var x: int = CX + s * 7
		_fill_trapezoid(x - 3 * s, x + 4 * s, sh_y - 2, x - 1 * s, x + 2 * s, sh_y + 18, 1)
		_fill_trapezoid(x - 2 * s, x + 3 * s, sh_y - 1, x, x + 2 * s, sh_y + 17, 3)
		_line(x + 2 * s, sh_y, x + 1 * s, sh_y + 15, 9)   # vein highlight
		_px(x - 1 * s, sh_y + 4, 11); _px(x, sh_y + 10, 13)   # corrupted glints

# digitigrade legs (thick chitin)
func _paint_legs(top_y: int) -> void:
	for spec in [[-1, CX - 11], [1, CX + 11]]:
		var sgn: int = spec[0]
		var foot_x: int = spec[1]
		var hip_x := CX + sgn * 5
		var hip_y := top_y - 18
		var knee_x := foot_x
		var knee_y := top_y - 8
		var ank_x := foot_x - sgn * 2
		var ank_y := top_y
		_limb(hip_x, hip_y, knee_x, knee_y, 1, 3, 1)   # thigh
		_limb(knee_x, knee_y, ank_x, ank_y, 1, 4, 1)   # shin
		_px(knee_x, knee_y - 1, 5)
		# clawed foot splay
		_px(ank_x, ank_y + 1, 1); _px(ank_x - sgn * 2, ank_y + 1, 7); _px(ank_x - sgn * 3, ank_y + 2, 8)
		_px(ank_x + sgn, ank_y + 1, 7); _px(ank_x + sgn * 2, ank_y + 2, 8)

# armored thorax with a high collar, brood-core and pauldrons
func _paint_thorax(top_y: int) -> void:
	_fill_trapezoid(CX - 9, CX + 9, top_y - 2, CX - 10, CX + 10, top_y + 3, 1)   # collar
	_fill_trapezoid(CX - 8, CX + 8, top_y - 1, CX - 9, CX + 9, top_y + 2, 4)
	_fill_trapezoid(CX - 9, CX + 9, top_y + 2, CX - 7, CX + 7, top_y + 22, 1)    # chest
	_fill_trapezoid(CX - 8, CX + 8, top_y + 3, CX - 6, CX + 6, top_y + 21, 3)
	_fill_trapezoid(CX - 8, CX + 2, top_y + 3, CX - 6, CX + 1, top_y + 21, 4)
	var gy := top_y + 12
	_fill_ellipse(CX, gy, 4, 6, 1)
	_fill_ellipse(CX, gy, 3, 5, 13)
	_fill_ellipse(CX, gy, 2, 4, 12)
	_px(CX, gy - 1, 11)
	_hline(CX - 7, CX + 7, top_y + 5, 8); _hline(CX - 6, CX + 6, top_y + 18, 9)   # rib seams
	_px(CX - 5, gy - 4, 13); _px(CX + 5, gy + 3, 13); _px(CX - 4, gy + 5, 12)     # core cracks
	_fill_ellipse(CX - 9, top_y + 3, 4, 3, 1); _fill_ellipse(CX - 9, top_y + 3, 3, 2, 4)   # pauldrons
	_fill_ellipse(CX + 9, top_y + 3, 4, 3, 1); _fill_ellipse(CX + 9, top_y + 3, 3, 2, 4)

# crowned wedge head with compound eyes + mandibles
func _paint_head(hy: int) -> void:
	var hcx := CX
	var hcy := hy
	for spec in [[-5, -14, -7], [-2, -16, -3], [2, -16, 3], [5, -14, 7]]:
		_line(hcx + spec[0], hcy - 4, hcx + spec[2], hcy + spec[1], 1)
		_px(hcx + spec[2], hcy + spec[1], 5)   # crown horn tip
	_vline(hcy - 19, hcy - 5, hcx, 1); _vline(hcy - 18, hcy - 6, hcx, 5); _px(hcx, hcy - 19, 10)   # central spire
	_fill_trapezoid(hcx - 6, hcx + 6, hcy - 5, hcx - 4, hcx + 4, hcy + 7, 1)   # wedge head
	_fill_trapezoid(hcx - 5, hcx + 5, hcy - 4, hcx - 3, hcx + 3, hcy + 6, 3)
	_fill_trapezoid(hcx - 5, hcx + 1, hcy - 4, hcx - 3, hcx, hcy + 6, 4)
	_px(hcx - 4, hcy - 3, 5)
	_compound_eye(hcx - 3, hcy, 1)
	_compound_eye(hcx + 3, hcy, -1)
	_hline(hcx - 5, hcx + 5, hcy - 2, 2)   # brow ridge
	_mandible(hcx - 2, hcy + 6, -1)
	_mandible(hcx + 2, hcy + 6, 1)

func _compound_eye(x: int, y: int, sgn: int) -> void:
	_px(x, y, 13); _px(x + sgn, y, 13); _px(x, y + 1, 13); _px(x - sgn, y, 1)
	_px(x, y - 1, 10)

func _mandible(x: int, y: int, sgn: int) -> void:
	_line(x, y, x + sgn * 2, y + 3, 1)
	_line(x, y, x + sgn * 2, y + 2, 7)
	_px(x + sgn * 2, y + 3, 8)   # tip fang

# scythe arm folded up at rest, blade vertical
func _scythe(sx: int, sy: int, sgn: int) -> void:
	var elbow_x := sx + sgn * 6
	var elbow_y := sy + 3
	var wrist_x := sx + sgn * 4
	var wrist_y := sy - 4
	var tip_x := sx + sgn * 6
	var tip_y := sy - 13
	_fill_ellipse(sx, sy, 3, 3, 1); _fill_ellipse(sx, sy, 2, 2, 4)   # shoulder ball
	_limb(sx, sy, elbow_x, elbow_y, 1, 3, 1)
	_px(elbow_x, elbow_y, 5)
	_limb(elbow_x, elbow_y, wrist_x, wrist_y, 1, 4, 1)
	_limb(wrist_x, wrist_y, tip_x, tip_y, 1, 7, 1)   # the scythe blade
	_px(tip_x, tip_y, 10)
	_px(tip_x + sgn, tip_y + 1, 8)   # back edge of barb
	var mx := _jr((wrist_x + tip_x) / 2.0)
	var my := _jr((wrist_y + tip_y) / 2.0)
	_px(mx + sgn, my, 9)
	_px(_jr(mx * 0.5 + wrist_x * 0.5) + sgn, _jr(my * 0.5 + wrist_y * 0.5), 9)   # serrations

# --- palette ----------------------------------------------------------------

func _palette(accent: String) -> Array:
	var a: Array = ACCENTS.get(accent, ACCENTS["toxic"])
	return [
		Color(0, 0, 0, 0),       # 0 transparent
		Color.html("06040a"),    # 1 outline
		Color.html("15101e"),    # 2 chitin darkest
		Color.html("211a30"),    # 3 chitin base
		Color.html("2f2543"),    # 4 chitin mid
		Color.html("41355d"),    # 5 chitin rim
		Color.html("070310"),    # 6 inner void
		Color.html("e7dcc4"),    # 7 blade / bone light
		Color.html("b3a583"),    # 8 blade / bone mid
		Color.html("766a4f"),    # 9 blade / bone dark
		Color.html("ffffff"),    # 10 white
		Color.html(a[0]),        # 11 accent bright
		Color.html(a[1]),        # 12 accent mid
		Color.html(a[2]),        # 13 accent glow
		Color.html("46E66A"),    # 14 data bit
	]

## Build a {"texture", "offset"} dict for the given corruption accent
## ("toxic", "royal", "red").
static func build(accent: String = "toxic") -> Dictionary:
	var s := MonarchSprite.new()
	s._paint()
	return s._bake(CX, s._palette(accent))
