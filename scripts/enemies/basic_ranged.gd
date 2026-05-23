class_name BasicRanged
extends EnemyBase

const ENEMY_PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")

@export var preferred_distance: float = 250.0
@export var fire_rate: float = 2.0
@export var projectile_speed: float = 200.0
@export var projectile_damage: float = 5.0

var _fire_timer: float = 0.0

static var _projectile_pool: ObjectPool

static var _mage_texture: ImageTexture
static var _mage_offset: Vector2

func _get_body_texture_data() -> Dictionary:
	if not _mage_texture:
		var data := _build_mage_texture()
		_mage_texture = data["texture"]
		_mage_offset = data["offset"]
	return {"texture": _mage_texture, "offset": _mage_offset}

static func _build_mage_texture() -> Dictionary:
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

	var r: Array = []
	var c: Array = []
	var _r := func(x: float, y: float, w: float, h: float, col: Color) -> void:
		r.append({"rect": Rect2(x, y, w, h), "color": col})
	var _c := func(pos: Vector2, radius: float, col: Color) -> void:
		c.append({"pos": pos, "radius": radius, "color": col})

	# Robe hem
	_r.call(-8, 0, 16, 1, OUTLINE); _r.call(-7, -1, 14, 1, TRIM)
	# Robe lower body
	_r.call(-7, -7, 14, 6, ROBE_M); _r.call(-7, -7, 2, 6, ROBE_D); _r.call(5, -7, 2, 6, ROBE_D)
	# Robe upper body
	_r.call(-6, -12, 12, 5, ROBE_M); _r.call(-6, -12, 2, 5, ROBE_D); _r.call(4, -12, 2, 5, ROBE_D)
	# Center fold
	_r.call(-1, -10, 2, 1, ROBE_L); _r.call(-1, -5, 2, 1, ROBE_L)
	# Rune decorations
	_r.call(-4, -8, 1, 1, TRIM); _r.call(3, -4, 1, 1, TRIM_L)
	# Feet
	_r.call(-5, -1, 3, 1, OUTLINE); _r.call(2, -1, 3, 1, OUTLINE)
	# Belt sash
	_r.call(-6, -13, 12, 1, TRIM); _r.call(-1, -13, 2, 1, TRIM_L)
	# Torso
	_r.call(-6, -17, 12, 4, ROBE_M)
	# Shoulder highlight
	_r.call(-7, -17, 14, 1, ROBE_L)
	# Collar
	_r.call(-2, -17, 4, 1, ROBE_D); _r.call(-1, -16, 2, 1, CLOTH)
	# Trim band
	_r.call(-5, -14, 10, 1, TRIM)
	# Off arm sleeve
	_r.call(-8, -16, 3, 4, ROBE_D); _r.call(-7, -16, 1, 4, ROBE_M)
	_r.call(-8, -12, 3, 1, TRIM); _r.call(-7, -11, 2, 1, SKIN_D)
	# Head shadow
	_r.call(-4, -21, 8, 4, CLOTH)
	# Chin
	_r.call(-3, -18, 6, 1, SKIN_D)
	# Glowing eyes
	_r.call(-3, -20, 2, 1, ORB_GLOW); _r.call(1, -20, 2, 1, ORB_GLOW)
	_r.call(-2, -20, 1, 1, EYE_C); _r.call(2, -20, 1, 1, EYE_C)
	# Beard
	_r.call(-3, -17, 6, 1, BEARD_L); _r.call(-2, -16, 4, 1, BEARD_M)
	_r.call(-1, -15, 2, 1, BEARD_D); _r.call(0, -14, 1, 1, BEARD_D)
	# Hat brim
	_r.call(-9, -24, 18, 1, ROBE_D); _r.call(-8, -23, 16, 1, ROBE_M); _r.call(-7, -22, 14, 1, ROBE_L)
	# Hat band
	_r.call(-6, -25, 12, 1, OUTLINE); _r.call(-1, -25, 3, 1, TRIM)
	# Hat cone
	_r.call(-4, -27, 8, 2, ROBE_M); _r.call(-4, -27, 1, 2, ROBE_D); _r.call(3, -27, 1, 2, ROBE_L)
	_r.call(-2, -29, 6, 2, ROBE_M); _r.call(-2, -29, 1, 2, ROBE_D); _r.call(3, -29, 1, 2, ROBE_L)
	_r.call(0, -31, 4, 2, ROBE_M); _r.call(0, -31, 1, 2, ROBE_D); _r.call(3, -31, 1, 2, ROBE_L)
	_r.call(2, -33, 2, 2, ROBE_M); _r.call(4, -34, 1, 1, ROBE_M); _r.call(5, -35, 1, 1, TRIM)
	# Staff arm sleeve
	_r.call(5, -16, 3, 4, ROBE_D); _r.call(6, -16, 1, 4, ROBE_M)
	_r.call(5, -12, 3, 1, TRIM); _r.call(6, -11, 2, 1, SKIN_D)
	# Staff shaft
	_r.call(7, -30, 1, 18, STAFF_W)
	_r.call(7, -25, 1, 1, TRIM); _r.call(7, -20, 1, 1, TRIM); _r.call(7, -12, 1, 1, ROBE_D)
	# Orb at staff top
	_c.call(Vector2(7.5, -32.0), 4.0, Color(0.478, 0.353, 0.8, 0.4))
	_c.call(Vector2(7.5, -32.0), 2.5, ORB_MID)
	_c.call(Vector2(7.5, -32.0), 1.0, Color.WHITE)

	return PixelSprite.build_texture(r, c)

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
	_update_facing()
	Targeting.update_position(self)

	_fire_timer += delta
	if _fire_timer >= fire_rate:
		_fire_projectile(dir)
		_fire_timer = 0.0

func _fire_projectile(dir: Vector2) -> void:
	if not _projectile_pool or not is_instance_valid(_projectile_pool._parent):
		_projectile_pool = ObjectPool.new(ENEMY_PROJECTILE_SCENE, 10, get_tree().current_scene)
	var proj := _projectile_pool.get_instance() as EnemyProjectile
	if not proj:
		return
	proj.initialize(dir, projectile_speed, projectile_damage, global_position, _projectile_pool)
