class_name MiniBoss
extends EnemyBase

enum Phase { CHASE, TELEGRAPH, CHARGE, COOLDOWN }

@export var charge_speed: float = 400.0
@export var telegraph_duration: float = 0.8
@export var charge_duration: float = 0.5
@export var cooldown_duration: float = 1.5
@export var ability_interval: float = 3.0

var _phase: Phase = Phase.CHASE
var _phase_timer: float = 0.0
var _ability_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO

static var _boss_texture: ImageTexture
static var _boss_offset: Vector2

func _get_body_texture_data() -> Dictionary:
	if not _boss_texture:
		var data := _build_boss_texture()
		_boss_texture = data["texture"]
		_boss_offset = data["offset"]
	return {"texture": _boss_texture, "offset": _boss_offset}

static func _build_boss_texture() -> Dictionary:
	const PLATE_D := Color(0.039, 0.016, 0.031)
	const PLATE_M := Color(0.102, 0.039, 0.078)
	const PLATE_L := Color(0.227, 0.102, 0.149)
	const MUSCLE_D := Color(0.290, 0.039, 0.078)
	const MUSCLE_M := Color(0.478, 0.094, 0.133)
	const MUSCLE_L := Color(0.722, 0.196, 0.227)
	const MUSCLE_H := Color(0.910, 0.353, 0.376)
	const MOLTEN := Color(1.0, 0.478, 0.188)
	const MOLTEN_H := Color(1.0, 0.847, 0.439)
	const BONE_D := Color(0.165, 0.102, 0.078)
	const BONE_M := Color(0.416, 0.290, 0.227)
	const BONE_L := Color(0.749, 0.627, 0.455)
	const BONE_H := Color(0.957, 0.863, 0.627)
	const EYE_R := Color(1.0, 0.188, 0.251)
	const EYE_C := Color(1.0, 0.847, 0.302)
	const OUTLINE := Color(0.02, 0.008, 0.02)

	var r: Array = []
	var c: Array = []
	var _r := func(x: float, y: float, w: float, h: float, col: Color) -> void:
		r.append({"rect": Rect2(x, y, w, h), "color": col})

	# Drop shadow
	c.append({"pos": Vector2.ZERO, "radius": 32.0, "color": Color(0, 0, 0, 0.45)})

	# --- LEGS + FEET ---
	for side in [-1, 1]:
		var lx: float = -16.0 if side == -1 else 8.0
		_r.call(lx, -22, 8, 22, MUSCLE_M)
		_r.call(lx, -22, 2, 22, MUSCLE_D); _r.call(lx + 6, -22, 2, 22, MUSCLE_D)
		_r.call(lx - 1, -14, 10, 3, PLATE_M); _r.call(lx - 1, -14, 10, 1, PLATE_L)
		_r.call(lx + 3, -13, 2, 1, MOLTEN)
		_r.call(lx - 2, -3, 12, 3, PLATE_M); _r.call(lx - 2, -3, 12, 1, PLATE_L)
		for i in 3:
			var cx: float = lx - 1.0 + i * 4.0
			_r.call(cx, 0, 2, 3, BONE_M); _r.call(cx, 2, 1, 1, BONE_H)

	# --- HIP / LOINCLOTH ---
	_r.call(-20, -30, 40, 8, PLATE_D); _r.call(-20, -30, 40, 2, PLATE_M)
	_r.call(-3, -31, 6, 4, PLATE_L); _r.call(-2, -30, 4, 2, MOLTEN); _r.call(-1, -30, 2, 1, MOLTEN_H)
	_r.call(-22, -28, 3, 12, PLATE_M); _r.call(19, -28, 3, 12, PLATE_M)

	# --- TORSO ---
	_r.call(-18, -48, 36, 18, MUSCLE_M)
	_r.call(-18, -48, 3, 18, MUSCLE_D); _r.call(15, -48, 3, 18, MUSCLE_D)
	_r.call(-14, -46, 10, 4, MUSCLE_L); _r.call(4, -46, 10, 4, MUSCLE_L)
	_r.call(-12, -46, 6, 1, MUSCLE_H); _r.call(6, -46, 6, 1, MUSCLE_H)
	_r.call(-2, -48, 4, 18, MUSCLE_D); _r.call(-1, -47, 2, 16, OUTLINE)
	_r.call(0, -45, 1, 12, MOLTEN); _r.call(0, -44, 1, 8, MOLTEN_H)
	for i in 3:
		var ry: float = -38.0 + i * 3.0
		_r.call(-14, ry, 28, 2, PLATE_M); _r.call(-14, ry, 28, 1, PLATE_L)
	_r.call(-14, -30, 28, 1, MOLTEN); _r.call(-8, -30, 16, 1, MOLTEN_H)
	_r.call(-20, -50, 40, 2, PLATE_M); _r.call(-20, -50, 40, 1, PLATE_L); _r.call(-1, -50, 2, 2, BONE_L)

	# --- ARMS ---
	for side in [-1, 1]:
		var ax: float = -28.0 if side == -1 else 20.0
		_r.call(ax, -44, 8, 16, MUSCLE_M)
		_r.call(ax, -44, 2, 16, MUSCLE_D); _r.call(ax + 6, -44, 2, 16, MUSCLE_D)
		_r.call(ax + 2, -42, 4, 4, MUSCLE_L)
		var elbow_x: float = ax + (8.0 if side == -1 else -2.0)
		_r.call(elbow_x + side * -4, -30, 2, 3, BONE_M); _r.call(elbow_x + side * -5, -29, 1, 1, BONE_L)
		_r.call(ax + 1, -28, 6, 16, MUSCLE_M); _r.call(ax + 1, -28, 2, 16, MUSCLE_D)
		var spike_x: float = ax + (0.0 if side == -1 else 7.0)
		_r.call(spike_x, -24, 1, 2, BONE_M); _r.call(spike_x, -18, 1, 2, BONE_M)
		_r.call(ax + 1, -12, 6, 1, PLATE_M); _r.call(ax + 3, -12, 2, 1, MOLTEN)
		_r.call(ax + 1, -11, 6, 5, MUSCLE_D); _r.call(ax + 1, -11, 6, 1, MUSCLE_M)
		for i in 4:
			var claw_x: float = ax + 1.0 + i * 1.5
			_r.call(claw_x, -6, 1, 5, BONE_M); _r.call(claw_x, -2, 1, 1, BONE_H)

	# --- SHOULDERS ---
	for side in [-1, 1]:
		var sx: float = -30.0 if side == -1 else 14.0
		_r.call(sx, -56, 16, 10, PLATE_D)
		_r.call(sx, -56, 16, 2, PLATE_M); _r.call(sx, -55, 16, 1, PLATE_L)
		_r.call(sx + 7, -52, 2, 2, MOLTEN); _r.call(sx + 8, -52, 1, 1, MOLTEN_H)
		for i in 3:
			var spk_x: float = sx + 2.0 + i * 5.0
			var spk_h: float = 6.0 + (2 - i) * 2.0
			_r.call(spk_x, -56 - spk_h, 2, spk_h, BONE_M)
			_r.call(spk_x, -56 - spk_h - 1, 1, 1, BONE_L)

	# --- HEAD ---
	_r.call(-10, -60, 20, 2, PLATE_M); _r.call(-9, -58, 18, 2, PLATE_M)
	_r.call(-8, -56, 16, 2, PLATE_M); _r.call(-7, -54, 14, 2, PLATE_M)
	_r.call(-8, -60, 16, 1, PLATE_L); _r.call(-4, -60, 8, 1, Color(0.353, 0.165, 0.227))
	_r.call(-10, -59, 1, 6, PLATE_D); _r.call(9, -59, 1, 6, PLATE_D)
	# Forehead sigil
	_r.call(-3, -59, 6, 1, MOLTEN); _r.call(-2, -58, 4, 1, MOLTEN)
	_r.call(-1, -57, 2, 1, MOLTEN_H); _r.call(0, -56, 1, 1, MOLTEN_H)
	# Eyes
	for side in [-1, 1]:
		var ex: float = -8.0 if side == -1 else 3.0
		_r.call(ex, -57, 5, 4, OUTLINE)
		_r.call(ex + 1, -56, 3, 2, EYE_R)
		_r.call(ex + 1, -56, 1, 1, EYE_C); _r.call(ex + 3, -55, 1, 1, EYE_C)
		_r.call(ex + 2, -56, 1, 1, Color.WHITE)
	# Jaw
	_r.call(-5, -52, 10, 2, PLATE_M); _r.call(-2, -52, 4, 2, OUTLINE)
	_r.call(-1, -52, 2, 1, MOLTEN)
	# Mandibles
	for side in [-1, 1]:
		var mx: float = -6.0 if side == -1 else 4.0
		var md: float = float(side)
		_r.call(mx, -50, 2, 2, BONE_M)
		_r.call(mx + md * 2, -48, 2, 2, BONE_M)
		_r.call(mx + md * 3, -46, 2, 2, BONE_L)
		_r.call(mx + md * 3, -44, 1, 1, BONE_H)

	# --- HORN CROWN ---
	# Central spike
	for i in 16:
		var w: int = maxi(1, 3 - int(float(i) / 16.0 * 2.5))
		_r.call(-w / 2, -61 - i, w, 1, BONE_M)
		if w > 1 and (i % 2 == 0):
			_r.call(-w / 2, -61 - i, 1, 1, BONE_L)
	_r.call(0, -77, 1, 1, BONE_H)
	_r.call(-3, -61, 6, 2, PLATE_M); _r.call(-3, -61, 6, 1, PLATE_L)
	# Horn pairs
	_add_horn_rects(r, -6, -60, -2.0, 10)
	_add_horn_rects(r, -10, -59, -3.0, 14)
	_add_horn_rects(r, -13, -57, -4.0, 18)
	_add_horn_rects(r, 5, -60, 2.0, 10)
	_add_horn_rects(r, 9, -59, 3.0, 14)
	_add_horn_rects(r, 12, -57, 4.0, 18)

	return PixelSprite.build_texture(r, c)

static func _add_horn_rects(r: Array, start_x: float, start_y: float, dx_per_step: float, length: int) -> void:
	const BONE_M := Color(0.416, 0.290, 0.227)
	const BONE_D := Color(0.165, 0.102, 0.078)
	const BONE_L := Color(0.749, 0.627, 0.455)
	const BONE_H := Color(0.957, 0.863, 0.627)
	var dir: float = signf(dx_per_step) if dx_per_step != 0.0 else 1.0
	var hx: float = start_x
	var hy: float = start_y
	for i in length:
		var t: float = float(i) / float(length - 1)
		hx += dx_per_step * 0.4
		hy -= 1
		var w: int = maxi(1, int(4.0 - t * 3.5))
		var x_off: int = int(hx) - (w / 2 if dir < 0 else 0)
		r.append({"rect": Rect2(x_off, hy, w, 1), "color": BONE_M})
		if w > 1:
			r.append({"rect": Rect2(x_off, hy, 1, 1), "color": BONE_L if dir < 0 else BONE_D})
			r.append({"rect": Rect2(x_off + w - 1, hy, 1, 1), "color": BONE_D if dir < 0 else BONE_L})
	r.append({"rect": Rect2(int(hx), int(hy) - 1, 1, 1), "color": BONE_H})

func _draw_health_bar() -> void:
	var bar_width := 48.0
	var bar_height := 4.0
	var bar_y := -80.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), Color(0.85, 0.15, 0.15))

func _physics_process(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return

	match _phase:
		Phase.CHASE:
			_chase(delta)
		Phase.TELEGRAPH:
			_telegraph(delta)
		Phase.CHARGE:
			_charge(delta)
		Phase.COOLDOWN:
			_cooldown(delta)

func _chase(delta: float) -> void:
	var dist := global_position.distance_to(_target.global_position)
	if dist < 40.0:
		var away := _target.global_position.direction_to(global_position)
		velocity = away * move_speed * 0.5
	else:
		var dir := global_position.direction_to(_target.global_position)
		velocity = dir * move_speed
	velocity += _get_separation_force() * move_speed
	move_and_slide()
	_clamp_to_arena()
	_check_contact_damage()
	_update_facing()
	Targeting.update_position(self)

	_ability_timer += delta
	if _ability_timer >= ability_interval:
		_ability_timer = 0.0
		_start_telegraph()

func _start_telegraph() -> void:
	_phase = Phase.TELEGRAPH
	_phase_timer = telegraph_duration
	_charge_dir = global_position.direction_to(_target.global_position)
	modulate = Color(1.5, 0.3, 0.3)

func _telegraph(delta: float) -> void:
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase = Phase.CHARGE
		_phase_timer = charge_duration

func _charge(delta: float) -> void:
	velocity = _charge_dir * charge_speed
	move_and_slide()
	_clamp_to_arena()
	_check_contact_damage()
	_update_facing()
	Targeting.update_position(self)
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase = Phase.COOLDOWN
		_phase_timer = cooldown_duration
		modulate = Color(0.7, 0.7, 0.7)

func _cooldown(delta: float) -> void:
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase = Phase.CHASE
		modulate = Color.WHITE

func reset() -> void:
	super.reset()
	_phase = Phase.CHASE
	_phase_timer = 0.0
	_ability_timer = 0.0
	_charge_dir = Vector2.ZERO

func _die() -> void:
	RunManager.record_stat("mini_bosses_killed", 1)
	super._die()
