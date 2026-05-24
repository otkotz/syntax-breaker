class_name EnemyProjectile
extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 200.0
var damage: float = 5.0
var _distance_traveled: float = 0.0
var max_range: float = 600.0

static var _orb_texture: ImageTexture
static var _orb_offset: Vector2

func _ready() -> void:
	if not _orb_texture:
		var data := _build_orb_texture()
		_orb_texture = data["texture"]
		_orb_offset = data["offset"]
	var sprite := Sprite2D.new()
	sprite.texture = _orb_texture
	sprite.offset = _orb_offset
	add_child(sprite)

static func _build_orb_texture() -> Dictionary:
	const CORE := Color(1.0, 0.85, 0.7)
	const MID := Color(1.0, 0.3, 0.15)
	const EDGE := Color(0.85, 0.15, 0.1)
	const GLOW := Color(1.0, 0.2, 0.1, 0.3)

	var r: Array = []
	var c: Array = []
	var _r := func(x: float, y: float, w: float, h: float, col: Color) -> void:
		r.append({"rect": Rect2(x, y, w, h), "color": col})

	c.append({"pos": Vector2.ZERO, "radius": 8.0, "color": GLOW})
	_r.call(-4, 0, 1, 1, EDGE); _r.call(4, 0, 1, 1, EDGE)
	_r.call(0, -4, 1, 1, EDGE); _r.call(0, 4, 1, 1, EDGE)
	_r.call(-3, -1, 7, 3, MID); _r.call(-1, -3, 3, 7, MID)
	_r.call(-2, -2, 5, 5, MID)
	_r.call(-1, -1, 3, 3, CORE); _r.call(0, 0, 1, 1, Color.WHITE)

	return PixelSprite.build_texture(r, c)

var _pool_ref: ObjectPool

func initialize(dir: Vector2, spd: float, dmg: float, pos: Vector2, pool: ObjectPool) -> void:
	direction = dir
	speed = spd
	damage = dmg
	global_position = pos
	_distance_traveled = 0.0
	_pool_ref = pool

func _physics_process(delta: float) -> void:
	var move_dist := speed * delta
	position += direction * move_dist
	_distance_traveled += move_dist
	if _distance_traveled >= max_range:
		_return_to_pool()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_return_to_pool()

func _return_to_pool() -> void:
	if _pool_ref:
		_pool_ref.release(self)
	else:
		queue_free()

func reset() -> void:
	_distance_traveled = 0.0
	_pool_ref = null
