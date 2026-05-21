class_name BasicRanged
extends EnemyBase

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")

@export var preferred_distance: float = 250.0
@export var fire_rate: float = 2.0
@export var projectile_speed: float = 200.0
@export var projectile_damage: float = 5.0

var _fire_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if not _target or not is_instance_valid(_target):
		return

	var dist := global_position.distance_to(_target.global_position)
	var dir := global_position.direction_to(_target.global_position)

	if dist > preferred_distance + 30.0:
		velocity = dir * move_speed
	elif dist < preferred_distance - 30.0:
		velocity = -dir * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_clamp_to_arena()
	_check_contact_damage()

	_fire_timer += delta
	if _fire_timer >= fire_rate:
		_fire_projectile(dir)
		_fire_timer = 0.0

func _draw_body() -> void:
	var f := 1.0 if _target and is_instance_valid(_target) and _target.global_position.x >= global_position.x else -1.0
	_draw_mage(f)

func _draw_mage(f: float) -> void:
	const ROBE_D := Color(0.102, 0.039, 0.165)
	const ROBE_M := Color(0.165, 0.078, 0.314)
	const ROBE_L := Color(0.29, 0.157, 0.502)
	const TRIM := Color(0.831, 0.659, 0.227)
	const TRIM_L := Color(1.0, 0.949, 0.627)
	const CLOTH := Color(0.039, 0.016, 0.094)
	const ORB_MID := Color(0.753, 0.659, 1.0)
	const ORB_GLOW := Color(0.478, 0.353, 0.8)
	const EYE_C := Color(0.784, 0.659, 1.0)
	const SKIN_D := Color(0.227, 0.165, 0.251)
	const STAFF_W := Color(0.29, 0.157, 0.094)
	const BEARD_L := Color(0.847, 0.831, 0.878)
	const BEARD_M := Color(0.659, 0.647, 0.722)
	const BEARD_D := Color(0.416, 0.416, 0.533)
	const OUTLINE := Color(0.016, 0.012, 0.039)

	var fx := func(dx: float, w: float) -> float:
		return (dx if f > 0 else -dx - w)

	# Robe hem outline
	draw_rect(Rect2(Vector2(fx.call(-8, 16), 0), Vector2(16, 1)), OUTLINE)
	# Robe hem trim
	draw_rect(Rect2(Vector2(fx.call(-7, 14), -1), Vector2(14, 1)), TRIM)
	# Robe lower body (wider)
	draw_rect(Rect2(Vector2(fx.call(-7, 14), -7), Vector2(14, 6)), ROBE_M)
	draw_rect(Rect2(Vector2(fx.call(-7, 2), -7), Vector2(2, 6)), ROBE_D)
	draw_rect(Rect2(Vector2(fx.call(5, 2), -7), Vector2(2, 6)), ROBE_D)
	# Robe upper body (narrower)
	draw_rect(Rect2(Vector2(fx.call(-6, 12), -12), Vector2(12, 5)), ROBE_M)
	draw_rect(Rect2(Vector2(fx.call(-6, 2), -12), Vector2(2, 5)), ROBE_D)
	draw_rect(Rect2(Vector2(fx.call(4, 2), -12), Vector2(2, 5)), ROBE_D)
	# Center fold highlights
	draw_rect(Rect2(Vector2(fx.call(-1, 2), -10), Vector2(2, 1)), ROBE_L)
	draw_rect(Rect2(Vector2(fx.call(-1, 2), -5), Vector2(2, 1)), ROBE_L)
	# Rune decorations
	draw_rect(Rect2(Vector2(fx.call(-4, 1), -8), Vector2(1, 1)), TRIM)
	draw_rect(Rect2(Vector2(fx.call(3, 1), -4), Vector2(1, 1)), TRIM_L)
	# Feet peeking under hem
	draw_rect(Rect2(Vector2(fx.call(-5, 3), -1), Vector2(3, 1)), OUTLINE)
	draw_rect(Rect2(Vector2(fx.call(2, 3), -1), Vector2(3, 1)), OUTLINE)
	# Belt sash
	draw_rect(Rect2(Vector2(fx.call(-6, 12), -13), Vector2(12, 1)), TRIM)
	draw_rect(Rect2(Vector2(fx.call(-1, 2), -13), Vector2(2, 1)), TRIM_L)
	# Torso
	draw_rect(Rect2(Vector2(fx.call(-6, 12), -17), Vector2(12, 4)), ROBE_M)
	# Shoulder highlight
	draw_rect(Rect2(Vector2(fx.call(-7, 14), -17), Vector2(14, 1)), ROBE_L)
	# Collar
	draw_rect(Rect2(Vector2(fx.call(-2, 4), -17), Vector2(4, 1)), ROBE_D)
	draw_rect(Rect2(Vector2(fx.call(-1, 2), -16), Vector2(2, 1)), CLOTH)
	# Trim band
	draw_rect(Rect2(Vector2(fx.call(-5, 10), -14), Vector2(10, 1)), TRIM)
	# Off arm sleeve
	draw_rect(Rect2(Vector2(fx.call(-8, 3), -16), Vector2(3, 4)), ROBE_D)
	draw_rect(Rect2(Vector2(fx.call(-7, 1), -16), Vector2(1, 4)), ROBE_M)
	draw_rect(Rect2(Vector2(fx.call(-8, 3), -12), Vector2(3, 1)), TRIM)
	draw_rect(Rect2(Vector2(fx.call(-7, 2), -11), Vector2(2, 1)), SKIN_D)
	# Head shadow under brim
	draw_rect(Rect2(Vector2(fx.call(-4, 8), -21), Vector2(8, 4)), CLOTH)
	# Chin
	draw_rect(Rect2(Vector2(fx.call(-3, 6), -18), Vector2(6, 1)), SKIN_D)
	# Glowing eyes
	draw_rect(Rect2(Vector2(fx.call(-3, 2), -20), Vector2(2, 1)), ORB_GLOW)
	draw_rect(Rect2(Vector2(fx.call(1, 2), -20), Vector2(2, 1)), ORB_GLOW)
	draw_rect(Rect2(Vector2(fx.call(-2, 1), -20), Vector2(1, 1)), EYE_C)
	draw_rect(Rect2(Vector2(fx.call(2, 1), -20), Vector2(1, 1)), EYE_C)
	# Beard
	draw_rect(Rect2(Vector2(fx.call(-3, 6), -17), Vector2(6, 1)), BEARD_L)
	draw_rect(Rect2(Vector2(fx.call(-2, 4), -16), Vector2(4, 1)), BEARD_M)
	draw_rect(Rect2(Vector2(fx.call(-1, 2), -15), Vector2(2, 1)), BEARD_D)
	draw_rect(Rect2(Vector2(fx.call(0, 1), -14), Vector2(1, 1)), BEARD_D)
	# Hat brim
	draw_rect(Rect2(Vector2(fx.call(-9, 18), -24), Vector2(18, 1)), ROBE_D)
	draw_rect(Rect2(Vector2(fx.call(-8, 16), -23), Vector2(16, 1)), ROBE_M)
	draw_rect(Rect2(Vector2(fx.call(-7, 14), -22), Vector2(14, 1)), ROBE_L)
	# Hat band
	draw_rect(Rect2(Vector2(fx.call(-6, 12), -25), Vector2(12, 1)), OUTLINE)
	draw_rect(Rect2(Vector2(fx.call(-1, 3), -25), Vector2(3, 1)), TRIM)
	# Hat cone — bent tip toward facing direction
	draw_rect(Rect2(Vector2(fx.call(-4, 8), -27), Vector2(8, 2)), ROBE_M)
	draw_rect(Rect2(Vector2(fx.call(-4, 1), -27), Vector2(1, 2)), ROBE_D)
	draw_rect(Rect2(Vector2(fx.call(3, 1), -27), Vector2(1, 2)), ROBE_L)
	draw_rect(Rect2(Vector2(fx.call(-2, 6), -29), Vector2(6, 2)), ROBE_M)
	draw_rect(Rect2(Vector2(fx.call(-2, 1), -29), Vector2(1, 2)), ROBE_D)
	draw_rect(Rect2(Vector2(fx.call(3, 1), -29), Vector2(1, 2)), ROBE_L)
	draw_rect(Rect2(Vector2(fx.call(0, 4), -31), Vector2(4, 2)), ROBE_M)
	draw_rect(Rect2(Vector2(fx.call(0, 1), -31), Vector2(1, 2)), ROBE_D)
	draw_rect(Rect2(Vector2(fx.call(3, 1), -31), Vector2(1, 2)), ROBE_L)
	draw_rect(Rect2(Vector2(fx.call(2, 2), -33), Vector2(2, 2)), ROBE_M)
	draw_rect(Rect2(Vector2(fx.call(4, 1), -34), Vector2(1, 1)), ROBE_M)
	draw_rect(Rect2(Vector2(fx.call(5, 1), -35), Vector2(1, 1)), TRIM)
	# Staff arm sleeve
	draw_rect(Rect2(Vector2(fx.call(5, 3), -16), Vector2(3, 4)), ROBE_D)
	draw_rect(Rect2(Vector2(fx.call(6, 1), -16), Vector2(1, 4)), ROBE_M)
	draw_rect(Rect2(Vector2(fx.call(5, 3), -12), Vector2(3, 1)), TRIM)
	draw_rect(Rect2(Vector2(fx.call(6, 2), -11), Vector2(2, 1)), SKIN_D)
	# Staff shaft
	draw_rect(Rect2(Vector2(fx.call(7, 1), -30), Vector2(1, 18)), STAFF_W)
	draw_rect(Rect2(Vector2(fx.call(7, 1), -25), Vector2(1, 1)), TRIM)
	draw_rect(Rect2(Vector2(fx.call(7, 1), -20), Vector2(1, 1)), TRIM)
	draw_rect(Rect2(Vector2(fx.call(7, 1), -12), Vector2(1, 1)), ROBE_D)
	# Orb at staff top
	var orb_x: float = fx.call(7, 1) + 0.5
	draw_circle(Vector2(orb_x, -32.0), 4.0, Color(0.478, 0.353, 0.8, 0.4))
	draw_circle(Vector2(orb_x, -32.0), 2.5, ORB_MID)
	draw_circle(Vector2(orb_x, -32.0), 1.0, Color.WHITE)

func _fire_projectile(dir: Vector2) -> void:
	var proj := ENEMY_PROJECTILE_SCENE.instantiate() as EnemyProjectile
	proj.direction = dir
	proj.speed = projectile_speed
	proj.damage = projectile_damage
	proj.global_position = global_position
	get_tree().current_scene.add_child(proj)
