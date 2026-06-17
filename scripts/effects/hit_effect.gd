class_name HitEffect
extends Node2D

var _timer: float = 0.0
var _duration: float = 0.45
var _max_radius: float = 80.0
var _core_color: Color = Color(1.0, 0.9, 0.5)
var _ring_color: Color = Color(1.0, 0.38, 0.13)
var _debris_color: Color = Color(1.0, 0.5, 0.19)
var _debris_count: int = 10
var _debris_data: Array = []
var _element: String = "fire"

static var _pool: Array = []
static var _active: Array = []
const MAX_POOL := 20

static func clear_all() -> void:
	for instance in _active:
		if is_instance_valid(instance):
			instance.queue_free()
	_active.clear()
	for instance in _pool:
		if is_instance_valid(instance):
			instance.queue_free()
	_pool.clear()

static func spawn(parent: Node, pos: Vector2, element: String, radius: float = 80.0) -> void:
	var instance: HitEffect
	while _pool.size() > 0:
		var candidate = _pool.pop_back()
		if is_instance_valid(candidate):
			instance = candidate
			break
	if not instance:
		instance = HitEffect.new()

	instance._configure(element, radius)
	instance.global_position = pos
	instance._timer = 0.0
	instance.visible = true
	instance.set_process(true)
	_active.append(instance)

	if not instance.is_inside_tree():
		parent.add_child(instance)
	elif instance.get_parent() != parent:
		instance.reparent(parent, false)

func _configure(element: String, radius: float) -> void:
	_element = element
	_max_radius = radius
	match element:
		"fire":
			_core_color = Color(1.0, 0.97, 0.75)
			_ring_color = Color(1.0, 0.31, 0.13)
			_debris_color = Color(1.0, 0.5, 0.19)
			_duration = 0.45
			_debris_count = 12
		"lightning":
			_core_color = Color.WHITE
			_ring_color = Color(0.63, 0.85, 1.0)
			_debris_color = Color(0.75, 0.91, 1.0)
			_duration = 0.35
			_debris_count = 8
		"poison":
			_core_color = Color(0.8, 0.96, 0.63)
			_ring_color = Color(0.49, 0.83, 0.29)
			_debris_color = Color(0.49, 0.83, 0.29)
			_duration = 0.4
			_debris_count = 8
		"cold":
			_core_color = Color(0.9, 0.98, 1.0)
			_ring_color = Color(0.6, 0.85, 1.0)
			_debris_color = Color(0.75, 0.92, 1.0)
			_duration = 0.4
			_debris_count = 8
		_:
			_core_color = Color.WHITE
			_ring_color = Color(1.0, 0.9, 0.5)
			_debris_color = Color(0.9, 0.85, 0.7)
			_duration = 0.4
			_debris_count = 8
	_generate_debris()

func _generate_debris() -> void:
	_debris_data.clear()
	for i in _debris_count:
		var angle := (float(i) / _debris_count) * TAU + randf() * 0.5
		var dist := randf_range(40.0, 100.0)
		var size := randf_range(3.0, 8.0)
		_debris_data.append({"angle": angle, "dist": dist, "size": size})

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _duration:
		visible = false
		set_process(false)
		_active.erase(self)
		_pool.append(self)
		return
	queue_redraw()

func _draw() -> void:
	var t := _timer / _duration
	var eased := 1.0 - (1.0 - t) * (1.0 - t)
	var r := eased * _max_radius
	var fade := 1.0 - t

	draw_circle(Vector2.ZERO, r, Color(_ring_color, fade * 0.45))
	var flash_op := maxf(0.0, 1.0 - t * 3.0)
	if flash_op > 0.0:
		draw_circle(Vector2.ZERO, r * 0.6, Color(_core_color, flash_op))

	var ring_r := r * 0.9
	if ring_r > 4.0:
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 24, Color(_core_color, fade), 3.0)

	for d: Dictionary in _debris_data:
		var dist: float = d["dist"] * eased
		var sz: float = d["size"] * (1.0 - t * 0.4)
		var angle: float = d["angle"]
		var pos := Vector2(cos(angle), sin(angle)) * dist
		pos.y += eased * eased * 20.0
		draw_rect(Rect2(pos - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(_debris_color, fade))
