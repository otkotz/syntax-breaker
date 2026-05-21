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

func _draw_body() -> void:
	_draw_boss()

func _draw_health_bar() -> void:
	var bar_width := 48.0
	var bar_height := 4.0
	var bar_y := -80.0
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	var hp_ratio: float = clampf(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), Color(0.85, 0.15, 0.15))

func _draw_boss() -> void:
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

	# Drop shadow
	draw_circle(Vector2.ZERO, 32.0, Color(0, 0, 0, 0.45))

	# --- LEGS + FEET ---
	for side in [-1, 1]:
		var lx: float = -16.0 if side == -1 else 8.0
		# Thigh + shin
		draw_rect(Rect2(Vector2(lx, -22), Vector2(8, 22)), MUSCLE_M)
		draw_rect(Rect2(Vector2(lx, -22), Vector2(2, 22)), MUSCLE_D)
		draw_rect(Rect2(Vector2(lx + 6, -22), Vector2(2, 22)), MUSCLE_D)
		# Knee plate
		draw_rect(Rect2(Vector2(lx - 1, -14), Vector2(10, 3)), PLATE_M)
		draw_rect(Rect2(Vector2(lx - 1, -14), Vector2(10, 1)), PLATE_L)
		draw_rect(Rect2(Vector2(lx + 3, -13), Vector2(2, 1)), MOLTEN)
		# Foot plate
		draw_rect(Rect2(Vector2(lx - 2, -3), Vector2(12, 3)), PLATE_M)
		draw_rect(Rect2(Vector2(lx - 2, -3), Vector2(12, 1)), PLATE_L)
		# 3 claws
		for i in 3:
			var cx: float = lx - 1.0 + i * 4.0
			draw_rect(Rect2(Vector2(cx, 0), Vector2(2, 3)), BONE_M)
			draw_rect(Rect2(Vector2(cx, 2), Vector2(1, 1)), BONE_H)

	# --- HIP / LOINCLOTH ---
	draw_rect(Rect2(Vector2(-20, -30), Vector2(40, 8)), PLATE_D)
	draw_rect(Rect2(Vector2(-20, -30), Vector2(40, 2)), PLATE_M)
	# Belt molten center stone
	draw_rect(Rect2(Vector2(-3, -31), Vector2(6, 4)), PLATE_L)
	draw_rect(Rect2(Vector2(-2, -30), Vector2(4, 2)), MOLTEN)
	draw_rect(Rect2(Vector2(-1, -30), Vector2(2, 1)), MOLTEN_H)
	# Sash strips
	draw_rect(Rect2(Vector2(-22, -28), Vector2(3, 12)), PLATE_M)
	draw_rect(Rect2(Vector2(19, -28), Vector2(3, 12)), PLATE_M)

	# --- TORSO ---
	draw_rect(Rect2(Vector2(-18, -48), Vector2(36, 18)), MUSCLE_M)
	draw_rect(Rect2(Vector2(-18, -48), Vector2(3, 18)), MUSCLE_D)
	draw_rect(Rect2(Vector2(15, -48), Vector2(3, 18)), MUSCLE_D)
	# Pec highlights
	draw_rect(Rect2(Vector2(-14, -46), Vector2(10, 4)), MUSCLE_L)
	draw_rect(Rect2(Vector2(4, -46), Vector2(10, 4)), MUSCLE_L)
	draw_rect(Rect2(Vector2(-12, -46), Vector2(6, 1)), MUSCLE_H)
	draw_rect(Rect2(Vector2(6, -46), Vector2(6, 1)), MUSCLE_H)
	# Chest V-cleft + molten crack
	draw_rect(Rect2(Vector2(-2, -48), Vector2(4, 18)), MUSCLE_D)
	draw_rect(Rect2(Vector2(-1, -47), Vector2(2, 16)), OUTLINE)
	draw_rect(Rect2(Vector2(0, -45), Vector2(1, 12)), MOLTEN)
	draw_rect(Rect2(Vector2(0, -44), Vector2(1, 8)), MOLTEN_H)
	# Ribcage armor plates
	for i in 3:
		var ry: float = -38.0 + i * 3.0
		draw_rect(Rect2(Vector2(-14, ry), Vector2(28, 2)), PLATE_M)
		draw_rect(Rect2(Vector2(-14, ry), Vector2(28, 1)), PLATE_L)
	# Abs molten line
	draw_rect(Rect2(Vector2(-14, -30), Vector2(28, 1)), MOLTEN)
	draw_rect(Rect2(Vector2(-8, -30), Vector2(16, 1)), MOLTEN_H)
	# Collar
	draw_rect(Rect2(Vector2(-20, -50), Vector2(40, 2)), PLATE_M)
	draw_rect(Rect2(Vector2(-20, -50), Vector2(40, 1)), PLATE_L)
	draw_rect(Rect2(Vector2(-1, -50), Vector2(2, 2)), BONE_L)

	# --- ARMS ---
	for side in [-1, 1]:
		var ax: float = -28.0 if side == -1 else 20.0
		# Upper arm
		draw_rect(Rect2(Vector2(ax, -44), Vector2(8, 16)), MUSCLE_M)
		draw_rect(Rect2(Vector2(ax, -44), Vector2(2, 16)), MUSCLE_D)
		draw_rect(Rect2(Vector2(ax + 6, -44), Vector2(2, 16)), MUSCLE_D)
		draw_rect(Rect2(Vector2(ax + 2, -42), Vector2(4, 4)), MUSCLE_L)
		# Elbow spike
		var elbow_x: float = ax + (8.0 if side == -1 else -2.0)
		draw_rect(Rect2(Vector2(elbow_x + side * -4, -30), Vector2(2, 3)), BONE_M)
		draw_rect(Rect2(Vector2(elbow_x + side * -5, -29), Vector2(1, 1)), BONE_L)
		# Forearm
		draw_rect(Rect2(Vector2(ax + 1, -28), Vector2(6, 16)), MUSCLE_M)
		draw_rect(Rect2(Vector2(ax + 1, -28), Vector2(2, 16)), MUSCLE_D)
		# Forearm spikes
		var spike_x: float = ax + (0.0 if side == -1 else 7.0)
		draw_rect(Rect2(Vector2(spike_x, -24), Vector2(1, 2)), BONE_M)
		draw_rect(Rect2(Vector2(spike_x, -18), Vector2(1, 2)), BONE_M)
		# Wrist band
		draw_rect(Rect2(Vector2(ax + 1, -12), Vector2(6, 1)), PLATE_M)
		draw_rect(Rect2(Vector2(ax + 3, -12), Vector2(2, 1)), MOLTEN)
		# Claw hand
		draw_rect(Rect2(Vector2(ax + 1, -11), Vector2(6, 5)), MUSCLE_D)
		draw_rect(Rect2(Vector2(ax + 1, -11), Vector2(6, 1)), MUSCLE_M)
		# 4 claws
		for i in 4:
			var claw_x: float = ax + 1.0 + i * 1.5
			draw_rect(Rect2(Vector2(claw_x, -6), Vector2(1, 5)), BONE_M)
			draw_rect(Rect2(Vector2(claw_x, -2), Vector2(1, 1)), BONE_H)

	# --- SHOULDERS / PAULDRONS ---
	for side in [-1, 1]:
		var sx: float = -30.0 if side == -1 else 14.0
		draw_rect(Rect2(Vector2(sx, -56), Vector2(16, 10)), PLATE_D)
		draw_rect(Rect2(Vector2(sx, -56), Vector2(16, 2)), PLATE_M)
		draw_rect(Rect2(Vector2(sx, -55), Vector2(16, 1)), PLATE_L)
		# Molten rivet
		draw_rect(Rect2(Vector2(sx + 7, -52), Vector2(2, 2)), MOLTEN)
		draw_rect(Rect2(Vector2(sx + 8, -52), Vector2(1, 1)), MOLTEN_H)
		# 3 spikes per shoulder
		for i in 3:
			var spk_x: float = sx + 2.0 + i * 5.0
			var spk_h: float = 6.0 + (2 - i) * 2.0
			draw_rect(Rect2(Vector2(spk_x, -56 - spk_h), Vector2(2, spk_h)), BONE_M)
			draw_rect(Rect2(Vector2(spk_x, -56 - spk_h - 1), Vector2(1, 1)), BONE_L)

	# --- HEAD (chitinous skull) ---
	draw_rect(Rect2(Vector2(-10, -60), Vector2(20, 2)), PLATE_M)
	draw_rect(Rect2(Vector2(-9, -58), Vector2(18, 2)), PLATE_M)
	draw_rect(Rect2(Vector2(-8, -56), Vector2(16, 2)), PLATE_M)
	draw_rect(Rect2(Vector2(-7, -54), Vector2(14, 2)), PLATE_M)
	# Skull highlights
	draw_rect(Rect2(Vector2(-8, -60), Vector2(16, 1)), PLATE_L)
	draw_rect(Rect2(Vector2(-4, -60), Vector2(8, 1)), Color(0.353, 0.165, 0.227))
	draw_rect(Rect2(Vector2(-10, -59), Vector2(1, 6)), PLATE_D)
	draw_rect(Rect2(Vector2(9, -59), Vector2(1, 6)), PLATE_D)
	# Forehead sigil (molten inverted triangle)
	draw_rect(Rect2(Vector2(-3, -59), Vector2(6, 1)), MOLTEN)
	draw_rect(Rect2(Vector2(-2, -58), Vector2(4, 1)), MOLTEN)
	draw_rect(Rect2(Vector2(-1, -57), Vector2(2, 1)), MOLTEN_H)
	draw_rect(Rect2(Vector2(0, -56), Vector2(1, 1)), MOLTEN_H)
	# Compound eyes
	for side in [-1, 1]:
		var ex: float = -8.0 if side == -1 else 3.0
		draw_rect(Rect2(Vector2(ex, -57), Vector2(5, 4)), OUTLINE)
		draw_rect(Rect2(Vector2(ex + 1, -56), Vector2(3, 2)), EYE_R)
		draw_rect(Rect2(Vector2(ex + 1, -56), Vector2(1, 1)), EYE_C)
		draw_rect(Rect2(Vector2(ex + 3, -55), Vector2(1, 1)), EYE_C)
		draw_rect(Rect2(Vector2(ex + 2, -56), Vector2(1, 1)), Color.WHITE)
	# Lower jaw / maw
	draw_rect(Rect2(Vector2(-5, -52), Vector2(10, 2)), PLATE_M)
	draw_rect(Rect2(Vector2(-2, -52), Vector2(4, 2)), OUTLINE)
	draw_rect(Rect2(Vector2(-1, -52), Vector2(2, 1)), MOLTEN)
	# Mandibles (curved bone pincers)
	for side in [-1, 1]:
		var mx: float = -6.0 if side == -1 else 4.0
		var md: float = float(side)
		draw_rect(Rect2(Vector2(mx, -50), Vector2(2, 2)), BONE_M)
		draw_rect(Rect2(Vector2(mx + md * 2, -48), Vector2(2, 2)), BONE_M)
		draw_rect(Rect2(Vector2(mx + md * 3, -46), Vector2(2, 2)), BONE_L)
		draw_rect(Rect2(Vector2(mx + md * 3, -44), Vector2(1, 1)), BONE_H)

	# --- HORN CROWN ---
	# Central spike
	for i in 16:
		var w: int = maxi(1, 3 - int(float(i) / 16.0 * 2.5))
		draw_rect(Rect2(Vector2(-w / 2, -61 - i), Vector2(w, 1)), BONE_M)
		if w > 1 and (i % 2 == 0):
			draw_rect(Rect2(Vector2(-w / 2, -61 - i), Vector2(1, 1)), BONE_L)
	draw_rect(Rect2(Vector2(0, -77), Vector2(1, 1)), BONE_H)
	draw_rect(Rect2(Vector2(-3, -61), Vector2(6, 2)), PLATE_M)
	draw_rect(Rect2(Vector2(-3, -61), Vector2(6, 1)), PLATE_L)
	# Horn pairs (swept back)
	_draw_horn(-6, -60, -2.0, 10)
	_draw_horn(-10, -59, -3.0, 14)
	_draw_horn(-13, -57, -4.0, 18)
	_draw_horn(5, -60, 2.0, 10)
	_draw_horn(9, -59, 3.0, 14)
	_draw_horn(12, -57, 4.0, 18)

func _draw_horn(start_x: float, start_y: float, dx_per_step: float, length: int) -> void:
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
		draw_rect(Rect2(Vector2(x_off, hy), Vector2(w, 1)), BONE_M)
		if w > 1:
			draw_rect(Rect2(Vector2(x_off, hy), Vector2(1, 1)), BONE_L if dir < 0 else BONE_D)
			draw_rect(Rect2(Vector2(x_off + w - 1, hy), Vector2(1, 1)), BONE_D if dir < 0 else BONE_L)
	draw_rect(Rect2(Vector2(int(hx), int(hy) - 1), Vector2(1, 1)), BONE_H)

func _chase(delta: float) -> void:
	var dist := global_position.distance_to(_target.global_position)
	if dist < 40.0:
		var away := _target.global_position.direction_to(global_position)
		velocity = away * move_speed * 0.5
	else:
		var dir := global_position.direction_to(_target.global_position)
		velocity = dir * move_speed
	move_and_slide()
	_clamp_to_arena()
	_check_contact_damage()

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
	velocity = Vector2.ZERO
	move_and_slide()
	_clamp_to_arena()
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase = Phase.CHARGE
		_phase_timer = charge_duration

func _charge(delta: float) -> void:
	velocity = _charge_dir * charge_speed
	move_and_slide()
	_clamp_to_arena()
	_check_contact_damage()
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		_phase = Phase.COOLDOWN
		_phase_timer = cooldown_duration
		modulate = Color(0.7, 0.7, 0.7)

func _cooldown(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_clamp_to_arena()
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
