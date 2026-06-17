class_name BreakerSprite
extends RefCounted

## Procedural pixel model of "The Breaker" — a GDScript port of the
## breaker.js / pixel.js sprite engine (player sprite Remix).
##
## Builds a 32x36 indexed-color hooded figure parameterised by facing
## direction (8-way) and animation frame (0..4). Three modes are
## supported: "idle", "walk" and "cast". Recolouring the energy
## signature = swapping the three ACCENT palette entries per element.

const W := 32
const H := 36

const DIRS := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

# ---- damage-element accent ramps (bright / mid / glow) ----------------
const ELEMENTS := {
	"cold": {"bright": "EAFBFF", "mid": "99E6FF", "glow": "3FA8D6"},
	"fire": {"bright": "FFC089", "mid": "FF6619", "glow": "B83A00"},
	"lightning": {"bright": "CDE8FF", "mid": "66B3FF", "glow": "2A66C0"},
	"poison": {"bright": "BEFFA6", "mid": "4DE633", "glow": "1F8A14"},
	"physical": {"bright": "FFFFFF", "mid": "CCCCCC", "glow": "7C7C8C"},
}

# ---- static palette (index -> Color); accent slots filled per element --
static func palette(element: String) -> PackedColorArray:
	var e: Dictionary = ELEMENTS.get(element, ELEMENTS["cold"])
	return PackedColorArray([
		Color(0, 0, 0, 0),          # 0 transparent
		Color.html("080111"),       # 1 outline
		Color.html("140720"),       # 2 cloak darkest
		Color.html("1E0A30"),       # 3 cloak dark (base)
		Color.html("301452"),       # 4 cloak mid
		Color.html("46236B"),       # 5 cloak light / rim
		Color.html("0B0414"),       # 6 hood interior
		Color.html("ECE2F4"),       # 7 skin light
		Color.html("C6B3DC"),       # 8 skin mid
		Color.html("8E78AC"),       # 9 skin shadow
		Color.html("FFFFFF"),       # 10 highlight
		Color.html(e["bright"]),    # 11 accent bright
		Color.html(e["mid"]),       # 12 accent mid
		Color.html(e["glow"]),      # 13 accent glow
		Color.html("7B3FA0"),       # 14 glitch rune trim
	])


# ---- indexed pixel buffer (port of pixel.js PixelBuffer) --------------
class Buf:
	var w: int
	var h: int
	var data: PackedByteArray

	func _init(_w: int, _h: int) -> void:
		w = _w
		h = _h
		data.resize(w * h)
		data.fill(0)

	func in_bounds(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h

	func set_px(x: int, y: int, c: int) -> void:
		if in_bounds(x, y):
			data[y * w + x] = c

	# paint only if the target is currently transparent
	func set_behind(x: int, y: int, c: int) -> void:
		if in_bounds(x, y) and data[y * w + x] == 0:
			data[y * w + x] = c

	func get_px(x: int, y: int) -> int:
		return data[y * w + x] if in_bounds(x, y) else 0

	func hline(x0: int, x1: int, y: int, c: int) -> void:
		if x0 > x1:
			var t := x0; x0 = x1; x1 = t
		for x in range(x0, x1 + 1):
			set_px(x, y, c)

	func vline(y0: int, y1: int, x: int, c: int) -> void:
		if y0 > y1:
			var t := y0; y0 = y1; y1 = t
		for y in range(y0, y1 + 1):
			set_px(x, y, c)

	func line(x0: int, y0: int, x1: int, y1: int, c: int) -> void:
		var dx := absi(x1 - x0)
		var dy := -absi(y1 - y0)
		var sx := 1 if x0 < x1 else -1
		var sy := 1 if y0 < y1 else -1
		var err := dx + dy
		while true:
			set_px(x0, y0, c)
			if x0 == x1 and y0 == y1:
				break
			var e2 := 2 * err
			if e2 >= dy:
				err += dy
				x0 += sx
			if e2 <= dx:
				err += dx
				y0 += sy

	func fill_ellipse(cx: int, cy: int, rx: int, ry: int, c: int) -> void:
		if rx <= 0 or ry <= 0:
			return
		for y in range(-ry, ry + 1):
			for x in range(-rx, rx + 1):
				var nx := float(x) / float(rx)
				var ny := float(y) / float(ry)
				if nx * nx + ny * ny <= 1.0:
					set_px(cx + x, cy + y, c)

	func fill_trapezoid(tx0: int, tx1: int, ty: int, bx0: int, bx1: int, by: int, c: int) -> void:
		var span := by - ty
		if span == 0:
			span = 1
		for y in range(ty, by + 1):
			var t := float(y - ty) / float(span)
			var x0 := roundi(tx0 + (bx0 - tx0) * t)
			var x1 := roundi(tx1 + (bx1 - tx1) * t)
			hline(x0, x1, y, c)

	func mirrored_x() -> Buf:
		var out := Buf.new(w, h)
		for y in h:
			for x in w:
				out.data[y * w + (w - 1 - x)] = data[y * w + x]
		return out


# ---- deterministic RNG (stable per-frame "glitch") --------------------
class Rng:
	var s: int
	func _init(seed: int) -> void:
		s = seed & 0xFFFFFFFF
	func next() -> float:
		s = (s * 1664525 + 1013904223) & 0xFFFFFFFF
		return float(s) / 4294967296.0


# ---- motion models ----------------------------------------------------
static func _motion(frame: int) -> Dictionary:
	var phase := (float(frame) / 5.0) * PI * 2.0
	return {
		"leg_swing": sin(phase),
		"bob": roundi(-absf(cos(phase)) + 0.5),
		"cloak": sin(phase + 0.6),
	}

static func _idle_motion(frame: int) -> Dictionary:
	var phase := (float(frame) / 5.0) * PI * 2.0
	return {
		"leg_swing": 0.0,
		"bob": roundi(sin(phase) * 0.6 - 0.2),
		"cloak": sin(phase) * 1.0,
	}

static func _cast_motion(frame: int) -> Dictionary:
	var phase := (float(frame) / 5.0) * PI * 2.0
	return {
		"leg_swing": 0.0,
		"bob": 0 if frame == 0 else -1,
		"cloak": sin(phase) * 0.6,
		"orb_r": [1, 1, 2, 2, 3][frame % 5],
		"burst": frame == 4,
		"parts": [1, 2, 3, 4, 7][frame % 5],
	}

# forward unit vectors (screen space) per drawDir
const FWD := {
	"N": Vector2(0, -1), "NE": Vector2(1, -1), "E": Vector2(1, 0),
	"SE": Vector2(1, 1), "S": Vector2(0, 1),
}
# hand target relative to (cx, base) per drawDir
const HAND := {
	"N": {"sx": 1, "sy": 0, "hx": 8, "hy": -14},
	"NE": {"sx": 2, "sy": 0, "hx": 9, "hy": -13},
	"E": {"sx": 2, "sy": 1, "hx": 10, "hy": 1},
	"SE": {"sx": 2, "sy": 1, "hx": 8, "hy": 6},
	"S": {"sx": 1, "sy": 1, "hx": 5, "hy": 9},
}


# ---- part painters ----------------------------------------------------
static func _paint_legs(b: Buf, cx: int, hem_y: int, m: Dictionary, lean: int) -> void:
	var sw: float = m["leg_swing"]
	var l_lead := roundi(sw * 1.6)
	var r_lead := roundi(-sw * 1.6)
	var l_shift := roundi(sw * 0.8) + lean
	var r_shift := roundi(-sw * 0.8) + lean
	_leg_col(b, cx - 3 + l_shift, hem_y, 2 + maxi(0, l_lead) + 2, sw > 0)
	_leg_col(b, cx + 1 + r_shift, hem_y, 2 + maxi(0, r_lead) + 2, sw < 0)

static func _leg_col(b: Buf, x: int, y: int, length: int, lead: bool) -> void:
	for j in length:
		b.set_px(x, y + j, 7)
		b.set_px(x + 1, y + j, 7 if lead else 8)
	b.set_px(x, y + length, 1)
	b.set_px(x + 1, y + length, 1)

static func _paint_legs_planted(b: Buf, cx: int, hem_y: int, lean: int) -> void:
	_leg_col(b, cx - 3 + lean, hem_y, 3, false)
	_leg_col(b, cx + 2 + lean, hem_y, 3, true)

static func _paint_cloak(b: Buf, cx: int, m: Dictionary, facing: String) -> Dictionary:
	var bob: int = m["bob"]
	var drift := roundi(m["cloak"] * 1.2)
	var sh_y := 18 + bob
	var hem_y := 30 + bob
	b.fill_trapezoid(cx - 6, cx + 5, sh_y - 1, cx - 9 + drift, cx + 8 + drift, hem_y + 2, 1)
	b.fill_trapezoid(cx - 5, cx + 4, sh_y, cx - 8 + drift, cx + 7 + drift, hem_y, 3)
	b.fill_trapezoid(cx - 2, cx + 3, sh_y + 1, cx - 4 + drift, cx + 6 + drift, hem_y, 4)
	var rim_x := cx + 4 if facing == "side" else cx + 3
	b.fill_trapezoid(rim_x, rim_x + 1, sh_y + 1, rim_x + 1 + drift, rim_x + 2 + drift, hem_y - 1, 5)
	b.vline(sh_y + 2, hem_y - 1, cx - 1, 2)
	return {"sh_y": sh_y, "hem_y": hem_y, "drift": drift}

static func _paint_cloak_trail(b: Buf, cx: int, m: Dictionary, dir: String) -> void:
	var drift := roundi(m["cloak"] * 2.0)
	var back := -1 if dir == "S" else 1
	var base_y := 16 if (dir == "S" or dir == "SE" or dir == "SW") else 28
	for i in 6:
		var y := base_y + i * back
		var wdt := 7 - i
		b.fill_trapezoid(cx - wdt + drift, cx + wdt + drift, y, cx - wdt + 2 + drift, cx + wdt - 2 + drift, y + 1, 2)

static func _paint_arms(b: Buf, cx: int, m: Dictionary, _facing: String) -> void:
	var sw: float = m["leg_swing"]
	var bob: int = m["bob"]
	var l_arm_y := 21 + bob - roundi(sw * 1.0)
	var r_arm_y := 21 + bob + roundi(sw * 1.0)
	b.set_px(cx - 6, l_arm_y, 1); b.set_px(cx - 5, l_arm_y, 7)
	b.set_px(cx - 5, l_arm_y + 1, 8); b.set_px(cx - 6, l_arm_y + 1, 1)
	b.set_px(cx + 5, r_arm_y, 7); b.set_px(cx + 6, r_arm_y, 1)
	b.set_px(cx + 5, r_arm_y + 1, 8); b.set_px(cx + 6, r_arm_y + 1, 1)

static func _paint_cast(b: Buf, cx: int, m: Dictionary, dir: String, frame: int) -> void:
	var bob: int = m["bob"]
	var base := 20 + bob
	var hnd: Dictionary = HAND.get(dir, HAND["S"])
	var fwd: Vector2 = FWD.get(dir, FWD["S"])
	var sx := cx + int(hnd["sx"])
	var sy := base + int(hnd["sy"])
	var hx := cx + int(hnd["hx"])
	var hy := base + int(hnd["hy"])

	var sgn := signi(int(hnd["hx"])) if int(hnd["hx"]) != 0 else 1
	var oax := cx - sgn * 5
	b.set_px(oax, base + 1, 1); b.set_px(oax + sgn, base + 1, 7)
	b.set_px(oax, base + 2, 8)

	b.line(sx, sy + 1, hx, hy + 1, 1)
	b.line(sx - 1, sy, hx - 1, hy, 1)
	b.line(sx, sy, hx, hy, 7)
	b.set_px(hx, hy + 1, 8)
	b.set_px(sx, sy, 9)

	var r: int = m["orb_r"]
	b.fill_ellipse(hx, hy, r + 1, r + 1, 13)
	b.fill_ellipse(hx, hy, r, r, 12)
	if r - 1 >= 0:
		b.fill_ellipse(hx, hy, r - 1, r - 1, 11)
	b.set_px(hx, hy, 10)

	var rand := Rng.new(((frame + 7) * 211) ^ (dir.unicode_at(0) * 29))
	var perp := Vector2(-fwd.y, fwd.x)
	var parts: int = m["parts"]
	var burst: bool = m["burst"]
	for i in parts:
		var dist := r + 1.5 + i * 1.1 + (3.0 if burst else 0.0)
		var spread := (rand.next() * 2.0 - 1.0) * (0.6 + i * 0.5)
		var px := roundi(hx + fwd.x * dist + perp.x * spread)
		var py := roundi(hy + fwd.y * dist + perp.y * spread)
		if not b.in_bounds(px, py):
			continue
		b.set_px(px, py, 11 if rand.next() < 0.55 else 13)
		if burst and rand.next() < 0.4:
			b.set_behind(px + int(fwd.x), py + int(fwd.y), 13)
	if frame == 3:
		b.set_behind(hx - r - 2, hy, 13); b.set_behind(hx + r + 2, hy, 13)
		b.set_behind(hx, hy - r - 2, 13); b.set_behind(hx, hy + r + 2, 13)

static func _eye(b: Buf, x: int, y: int) -> void:
	b.set_px(x, y, 11)
	b.set_px(x, y - 1, 13)
	b.set_behind(x, y + 1, 13)
	b.set_behind(x - 1, y, 13)

static func _paint_head_front(b: Buf, cx: int, m: Dictionary, three_quarter: bool) -> void:
	var bob: int = m["bob"]
	var cy := 11 + bob
	var lean := 1 if three_quarter else 0
	b.fill_ellipse(cx + lean, cy, 8, 8, 1)
	b.fill_ellipse(cx + lean, cy, 7, 7, 3)
	b.fill_ellipse(cx + lean, cy + 1, 6, 6, 4)
	b.set_px(cx + lean, cy - 8, 1); b.set_px(cx + lean, cy - 7, 3)
	var fx := cx + lean
	b.fill_ellipse(fx, cy + 1, 5, 5, 6)
	for y in range(cy - 4, cy + 2):
		for x in range(fx - 4, fx + 5):
			var nx := float(x - fx) / 4.4
			var ny := float(y - cy - 0.5) / 4.8
			if nx * nx + ny * ny <= 1.0 and y <= cy + 1:
				b.set_px(x, y, 7)
	b.fill_ellipse(fx + 2, cy, 2, 3, 8)
	b.set_px(fx + 3, cy - 1, 8); b.set_px(fx + 3, cy, 8)
	b.set_px(fx - 2, cy - 3, 10); b.set_px(fx - 1, cy - 3, 10); b.set_px(fx - 2, cy - 2, 10)
	b.hline(fx - 4, fx + 4, cy - 4, 3)
	b.set_px(fx - 5, cy - 3, 3); b.set_px(fx + 5, cy - 3, 3)
	b.hline(fx - 3, fx + 3, cy + 1, 9)
	var eye_y := cy + 3
	var e0 := fx - 2 + (1 if three_quarter else 0)
	var e1 := fx + 2 + (1 if three_quarter else 0)
	_eye(b, e0, eye_y)
	_eye(b, e1, eye_y)

static func _paint_head_back(b: Buf, cx: int, m: Dictionary, three_quarter: bool) -> void:
	var bob: int = m["bob"]
	var cy := 11 + bob
	var lean := -1 if three_quarter else 0
	b.fill_ellipse(cx + lean, cy, 8, 8, 1)
	b.fill_ellipse(cx + lean, cy, 7, 7, 3)
	b.fill_ellipse(cx + lean, cy + 1, 6, 6, 4)
	b.set_px(cx + lean, cy - 8, 1); b.set_px(cx + lean, cy - 7, 3)
	b.fill_ellipse(cx + lean - 1, cy - 1, 4, 4, 5)
	b.fill_ellipse(cx + lean - 1, cy - 1, 3, 3, 3)
	b.vline(cy - 5, cy + 4, cx + lean, 2)
	b.set_px(cx + lean, cy + 5, 8); b.set_px(cx + lean + 1, cy + 5, 9)

static func _paint_head_side(b: Buf, cx: int, m: Dictionary) -> void:
	var bob: int = m["bob"]
	var cy := 11 + bob
	var fx := cx + 1
	b.fill_ellipse(cx, cy, 8, 8, 1)
	b.fill_ellipse(cx, cy, 7, 7, 3)
	b.fill_ellipse(cx - 1, cy + 1, 6, 6, 4)
	b.set_px(cx, cy - 8, 1); b.set_px(cx, cy - 7, 3)
	b.fill_ellipse(fx + 2, cy + 1, 4, 5, 6)
	b.fill_ellipse(fx + 2, cy - 1, 3, 4, 7)
	b.fill_ellipse(fx + 2, cy + 1, 3, 3, 7)
	for y in range(cy - 5, cy + 4):
		for x in range(cx - 7, fx - 1):
			if b.get_px(x, y) == 7:
				b.set_px(x, y, 4)
	b.set_px(fx + 4, cy, 8); b.set_px(fx + 4, cy + 1, 8); b.set_px(fx + 3, cy + 2, 8)
	b.set_px(fx, cy - 3, 10); b.set_px(fx + 1, cy - 3, 10)
	b.set_px(fx - 1, cy - 3, 3); b.set_px(fx, cy - 4, 3); b.set_px(fx + 1, cy - 4, 3); b.set_px(fx + 2, cy - 4, 3)
	b.hline(fx, fx + 4, cy + 1, 9)
	_eye(b, fx + 3, cy + 3)

static func _paint_emblem(b: Buf, cx: int, m: Dictionary, dir: String) -> void:
	if dir == "N" or dir == "NE" or dir == "NW":
		return
	var bob: int = m["bob"]
	var y := 23 + bob
	var x := cx + 1 if (dir == "E" or dir == "W" or dir == "SE" or dir == "SW") else cx
	b.set_px(x, y - 2, 13)
	b.set_px(x - 1, y - 1, 12); b.set_px(x, y - 1, 11); b.set_px(x + 1, y - 1, 12)
	b.set_px(x - 2, y, 13); b.set_px(x - 1, y, 11); b.set_px(x, y, 10); b.set_px(x + 1, y, 11); b.set_px(x + 2, y, 13)
	b.set_px(x - 1, y + 1, 12); b.set_px(x, y + 1, 11); b.set_px(x + 1, y + 1, 12)
	b.set_px(x, y + 2, 13)

static func _paint_runes_and_glitch(b: Buf, cx: int, geo: Dictionary, glitch: float, dir: String, frame: int) -> void:
	var g := glitch
	var r := Rng.new(((frame + 1) * 131) ^ (dir.unicode_at(0) * 17) ^ int(floor(g * 100.0)))
	var hem_y: int = geo["hem_y"]
	var drift: int = geo.get("drift", 0)
	var x := cx - 7 + drift
	while x <= cx + 6 + drift:
		var v := b.get_px(x, hem_y - 1)
		if v == 3 or v == 4:
			b.set_px(x, hem_y - 1, 14)
		x += 3
	b.set_behind(cx - 5, geo["sh_y"] + 1, 14)
	b.set_behind(cx + 4, geo["sh_y"] + 1, 14)
	var frags := roundi(3 + g * 8)
	for i in frags:
		var fxp := cx - 8 + floori(r.next() * 16) + drift
		var fyp := hem_y + floori(r.next() * 3)
		if r.next() < 0.5:
			b.set_px(fxp, fyp, 0)
		else:
			b.set_px(fxp, fyp + 1 + floori(r.next() * 2), 14 if r.next() < 0.4 else 3)
	var parts := roundi(g * 3)
	for i in parts:
		var px := cx - 9 + floori(r.next() * 19)
		var py := 8 + floori(r.next() * 22)
		if b.get_px(px, py) == 0:
			b.set_px(px, py, 13 if r.next() < 0.5 else 14)


# ---- master builder ---------------------------------------------------
# dir: one of N, NE, E, SE, S, SW, W, NW
# mode: "idle" | "walk" | "cast"
static func build(dir: String, frame: int, mode: String = "walk", glitch: float = 0.3) -> Buf:
	var b := Buf.new(W, H)
	var m: Dictionary
	if mode == "idle":
		m = _idle_motion(frame)
	elif mode == "cast":
		m = _cast_motion(frame)
	else:
		m = _motion(frame)
	var cx := 16

	var facing: String
	var mirror := false
	var draw_dir := dir
	match dir:
		"S": facing = "front"
		"SE": facing = "front34"
		"SW": facing = "front34"; mirror = true; draw_dir = "SE"
		"E": facing = "side"
		"W": facing = "side"; mirror = true; draw_dir = "E"
		"NE": facing = "back34"
		"NW": facing = "back34"; mirror = true; draw_dir = "NE"
		"N": facing = "back"
		_: facing = "front"

	_paint_cloak_trail(b, cx, m, draw_dir)
	var geo := _paint_cloak(b, cx, m, "side" if facing == "side" else "front")
	if mode == "walk":
		_paint_legs(b, cx, geo["hem_y"] + 1, m, 1 if facing == "side" else 0)
		_paint_arms(b, cx, m, facing)
	else:
		_paint_legs_planted(b, cx, geo["hem_y"] + 1, 1 if facing == "side" else 0)
		if mode == "cast":
			_paint_cast(b, cx, m, draw_dir, frame)
		else:
			_paint_arms(b, cx, m, facing)

	if facing == "front":
		_paint_head_front(b, cx, m, false)
	elif facing == "front34":
		_paint_head_front(b, cx, m, true)
	elif facing == "side":
		_paint_head_side(b, cx, m)
	elif facing == "back34":
		_paint_head_back(b, cx, m, true)
	else:
		_paint_head_back(b, cx, m, false)

	_paint_emblem(b, cx, m, draw_dir)
	_paint_runes_and_glitch(b, cx, geo, glitch, draw_dir, frame)

	return b.mirrored_x() if mirror else b


# ---- render a buffer to an ImageTexture using a resolved palette ------
static func build_texture(dir: String, frame: int, mode: String, pal: PackedColorArray, glitch: float = 0.3) -> ImageTexture:
	var b := build(dir, frame, mode, glitch)
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var idx := b.data[y * W + x]
			if idx != 0:
				img.set_pixel(x, y, pal[idx])
	return ImageTexture.create_from_image(img)
