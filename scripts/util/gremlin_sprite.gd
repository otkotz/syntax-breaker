class_name GremlinSprite
extends IndexBuffer

## Procedural "GLITCH GREMLIN" trash-melee sprite.
## Ported from the JS pixel-buffer reference (engine/gremlin.js): a squat,
## hunched corrupted-data imp — big jagged shoulders, low head, dangling
## clawed arms, stubby splayed legs. Baked here as a single front-facing
## neutral pose (idle, frame 0). Corruption accent selects the colour
## variant (red / toxic / void).

const W := 32
const H := 36
const CX := 16

# accent -> [bright, mid, glow] (eyes / core / glow)
const ACCENTS := {
	"red": ["FF7E96", "FF3355", "A8112E"],
	"toxic": ["9CFF8C", "3DF04A", "188A24"],
	"void": ["B9A0FF", "7B4DE6", "3A1F93"],
}

func _init() -> void:
	super(W, H)

# --- gremlin body parts (front-facing, neutral idle pose) -------------------

func _paint() -> void:
	var sh_y := 16          # shoulder line (high, hunched)
	var hip_y := 27         # hips (low, narrow)

	# hunched torso: narrow hips rising to broad jagged shoulders
	_fill_trapezoid(CX - 8, CX + 8, sh_y - 1, CX - 4, CX + 4, hip_y + 1, 1)  # outline
	_fill_trapezoid(CX - 7, CX + 7, sh_y, CX - 3, CX + 3, hip_y, 3)          # base hide
	_fill_trapezoid(CX - 4, CX + 5, sh_y + 1, CX - 2, CX + 3, hip_y, 4)      # mid shade
	# jagged shoulder humps (rim light) + spike tips
	_px(CX - 7, sh_y, 5); _px(CX - 6, sh_y - 1, 5)
	_px(CX + 6, sh_y - 1, 5); _px(CX + 7, sh_y, 5)
	_px(CX - 6, sh_y, 1); _px(CX + 6, sh_y, 1)
	_vline(sh_y + 2, hip_y - 1, CX - 1, 2)                                    # darkest core fold

	# stubby splayed legs with little claw feet
	_leg(CX - 4, hip_y, 3)
	_leg(CX + 2, hip_y, 3)

	# cracked glowing data-core in the chest
	var core_y := 21
	_fill_ellipse(CX, core_y, 2, 2, 13)
	_px(CX, core_y, 11); _px(CX - 1, core_y, 12); _px(CX + 1, core_y, 12)
	_px(CX, core_y - 1, 12); _px(CX, core_y + 1, 12)
	_px(CX, core_y, 10)
	_px(CX - 2, core_y - 1, 11); _px(CX + 2, core_y + 1, 11)               # crack lines

	# jagged head, sunk low between the shoulders
	var cy := 16
	_fill_ellipse(CX, cy, 6, 5, 1)
	_fill_ellipse(CX, cy, 5, 4, 3)
	_fill_ellipse(CX, cy - 1, 4, 3, 4)
	_px(CX - 3, cy - 4, 1); _px(CX, cy - 5, 1); _px(CX + 3, cy - 4, 1)    # crest spikes
	_px(CX, cy - 4, 4)
	_hline(CX - 4, CX + 4, cy - 1, 2)                                         # brow ridge shadow
	_angry_eye(CX - 2, cy, -1)
	_angry_eye(CX + 2, cy, 1)
	_fill_ellipse(CX, cy + 3, 3, 1, 6)                                        # snarling maw
	_px(CX - 2, cy + 3, 7); _px(CX, cy + 4, 7); _px(CX + 2, cy + 3, 7)    # teeth

	# both arms dangle, claws at the tips
	_arm_hang(CX - 7, sh_y + 2, 5)
	_arm_hang(CX + 6, sh_y + 2, 5)

func _leg(x: int, y: int, length: int) -> void:
	for j in length:
		_px(x, y + j, 3)
		_px(x + 1, y + j, 3)
	var fy := y + length
	_px(x - 1, fy, 7); _px(x, fy, 8); _px(x + 1, fy, 7); _px(x + 2, fy, 7)
	_px(x, fy, 1)

func _angry_eye(x: int, y: int, dir2: int) -> void:
	_px(x, y, 11); _px(x + dir2, y - 1, 11); _px(x - dir2, y + 1, 12)
	_set_behind(x, y + 1, 13); _set_behind(x + dir2, y, 13)

func _arm_hang(x: int, y: int, length: int) -> void:
	_line(x, y, x, y + length, 1)
	var inner := x + 1 if x < CX else x - 1
	_line(inner, y, inner, y + length, 4)
	var claw_y := y + length + 1
	_px(x, claw_y, 8)
	_px(x - 1, claw_y + 1, 7); _px(x, claw_y + 1, 7); _px(x + 1, claw_y + 1, 7)

# --- palette ----------------------------------------------------------------

func _palette(accent: String) -> Array:
	var a: Array = ACCENTS.get(accent, ACCENTS["red"])
	return [
		Color(0, 0, 0, 0),       # 0 transparent
		Color.html("050109"),    # 1 outline
		Color.html("140622"),    # 2 hide darkest
		Color.html("241038"),    # 3 hide base
		Color.html("371b50"),    # 4 hide mid
		Color.html("4f2a6c"),    # 5 hide rim
		Color.html("0a0414"),    # 6 maw / inner shadow
		Color.html("cdbcd9"),    # 7 claw / teeth light (bone)
		Color.html("9a86ad"),    # 8 claw mid
		Color.html("695681"),    # 9 claw shadow
		Color.html("ffffff"),    # 10 highlight
		Color.html(a[0]),        # 11 accent bright
		Color.html(a[1]),        # 12 accent mid
		Color.html(a[2]),        # 13 accent glow
		Color.html("46E66A"),    # 14 toxic data
	]

## Build a {"texture", "offset"} dict for the given corruption accent
## ("red", "toxic", "void").
static func build(accent: String = "red") -> Dictionary:
	var g := GremlinSprite.new()
	g._paint()
	return g._bake(CX, g._palette(accent))
