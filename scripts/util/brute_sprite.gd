class_name BruteSprite
extends IndexBuffer

## Procedural "NULL BRUTE" heavy/tank sprite.
## Ported from the JS pixel-buffer reference (engine/tank_brute.js): a
## bloated ogre bruiser — hunched rounded mass, one HUGE swing-arm fist and
## a smaller off-arm, a tiny head sunk into the shoulders, thick stubby legs
## and a cracked glowing data-core gut. Baked here as a single front-facing
## neutral pose (idle, frame 0). Corruption accent selects the colour
## variant (amber / toxic / red).

const W := 44
const H := 48
const CX := 22

# accent -> [bright, mid, glow]
const ACCENTS := {
	"amber": ["FFC272", "FF8A1E", "A83C00"],
	"toxic": ["9CFF8C", "3DF04A", "188A24"],
	"red": ["FF7E96", "FF3355", "A8112E"],
}

func _init() -> void:
	super(W, H)

# --- brute body parts (front-facing, neutral idle pose) ---------------------

func _paint() -> void:
	_paint_legs(35)
	var geo := _paint_body()
	_paint_head(geo)
	_paint_arms(geo)

# thick stubby legs
func _paint_legs(top_y: int) -> void:
	var lx := CX - 6
	var rx := CX + 6
	_fill_rect(lx - 3, top_y, 7, 7, 1)
	_fill_rect(lx - 2, top_y, 5, 6, 3)
	_fill_rect(lx - 2, top_y, 5, 2, 4)
	_fill_rect(rx - 3, top_y, 7, 7, 1)
	_fill_rect(rx - 2, top_y, 5, 6, 3)
	_fill_rect(rx - 2, top_y, 5, 2, 4)
	_px(lx - 2, top_y + 6, 7); _px(lx, top_y + 6, 7)
	_px(rx, top_y + 6, 7); _px(rx + 2, top_y + 6, 7)

# hunched rounded mass with a cracked glowing data-core gut
func _paint_body() -> Dictionary:
	var sh_y := 18
	var bx := CX
	_fill_ellipse(bx, sh_y + 2, 11, 9, 1)     # outline mass
	_fill_ellipse(bx, sh_y + 2, 10, 8, 3)     # base hide
	_fill_ellipse(bx - 2, sh_y, 8, 6, 4)      # lit upper-left
	_fill_ellipse(bx - 4, sh_y - 2, 3, 3, 5)  # rim hump light
	_fill_ellipse(bx, sh_y + 10, 9, 6, 1)     # lower belly bulge
	_fill_ellipse(bx, sh_y + 10, 8, 5, 3)
	# cracked glowing data-core gut (idle pulse is low -> single bright pip)
	var gy := sh_y + 9
	_fill_ellipse(bx, gy, 4, 4, 1)
	_fill_ellipse(bx, gy, 3, 3, 13)
	_fill_ellipse(bx, gy, 2, 2, 12)
	_px(bx, gy, 11)
	_px(bx - 4, gy - 3, 13); _px(bx - 5, gy - 4, 12); _px(bx + 4, gy - 2, 13)
	_px(bx + 3, gy + 4, 13); _px(bx - 3, gy + 4, 12)
	_px(bx - 6, sh_y, 8); _px(bx + 6, sh_y + 2, 8); _px(bx + 4, sh_y - 3, 2)  # warts
	return {"bx": bx, "sh_y": sh_y}

# small sunken head with beady eyes + tusks
func _paint_head(geo: Dictionary) -> void:
	var hx: int = geo["bx"]
	var hy: int = geo["sh_y"] - 7
	_fill_ellipse(hx, hy, 4, 3, 1)
	_fill_ellipse(hx, hy, 3, 2, 4)
	_px(hx - 2, hy - 1, 5)
	_px(hx - 2, hy, 11); _px(hx + 2, hy, 11)      # beady glowing eyes
	_hline(hx - 3, hx + 3, hy - 1, 2)              # brow shadow
	_px(hx - 2, hy + 2, 7); _px(hx + 2, hy + 2, 7)  # tusks
	_px(hx - 2, hy + 3, 8); _px(hx + 2, hy + 3, 8)

# one HUGE swing-fist arm + a smaller off-arm
func _paint_arms(geo: Dictionary) -> void:
	var bx: int = geo["bx"]
	var sh_y: int = geo["sh_y"]
	# big arm — screen-right, dragging at rest
	_line(bx + 7, sh_y + 2, bx + 10, sh_y + 13, 1)
	_line(bx + 7, sh_y + 2, bx + 9, sh_y + 13, 4)
	_big_fist(bx + 10, sh_y + 15)
	# small off-arm — screen-left
	_line(bx - 7, sh_y + 3, bx - 9, sh_y + 11, 1)
	_line(bx - 7, sh_y + 3, bx - 9, sh_y + 11, 3)
	_fill_ellipse(bx - 9, sh_y + 12, 2, 2, 4)

func _big_fist(x: int, y: int) -> void:
	var r := 4
	_fill_ellipse(x, y, r + 1, r + 1, 1)
	_fill_ellipse(x, y, r, r, 4)
	_fill_ellipse(x - 1, y - 1, r - 1, r - 1, 3)
	_px(x - 2, y - 2, 5)
	_px(x - 1, y - r + 1, 8); _px(x + 1, y - r + 1, 8); _px(x, y - r, 7)  # knuckles

# --- palette ----------------------------------------------------------------

func _palette(accent: String) -> Array:
	var a: Array = ACCENTS.get(accent, ACCENTS["amber"])
	return [
		Color(0, 0, 0, 0),       # 0 transparent
		Color.html("0a0408"),    # 1 outline
		Color.html("2c1b2e"),    # 2 hide darkest
		Color.html("3d2747"),    # 3 hide base
		Color.html("523a5f"),    # 4 hide mid
		Color.html("6a5279"),    # 5 hide rim
		Color.html("0c0510"),    # 6 maw / core void
		Color.html("e4d8c2"),    # 7 tusk / nail light
		Color.html("a89a82"),    # 8 tusk / nail mid
		Color.html("6e6052"),    # 9 tusk / nail dark
		Color.html("ffffff"),    # 10 white
		Color.html(a[0]),        # 11 accent bright
		Color.html(a[1]),        # 12 accent mid
		Color.html(a[2]),        # 13 accent glow
		Color.html("46E66A"),    # 14 data bit
	]

## Build a {"texture", "offset"} dict for the given corruption accent
## ("amber", "toxic", "red").
static func build(accent: String = "amber") -> Dictionary:
	var s := BruteSprite.new()
	s._paint()
	return s._bake(CX, s._palette(accent))
