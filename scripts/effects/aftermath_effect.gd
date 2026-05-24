class_name AftermathEffect
extends Node2D

var _type: String = "scorch"
var _timer: float = 0.0
var _duration: float = 3.0
var _radius: float = 50.0
var _seed: int = 0

static var _pool: Array = []
static var _active: Array = []
const MAX_ACTIVE := 15
static var _active_count: int = 0

static func clear_all() -> void:
	for instance in _active:
		if is_instance_valid(instance):
			instance.queue_free()
	_active.clear()
	for instance in _pool:
		if is_instance_valid(instance):
			instance.queue_free()
	_pool.clear()
	_active_count = 0

static func spawn(parent: Node, pos: Vector2, type: String, radius: float = 50.0, duration: float = 3.0) -> void:
	if _active_count >= MAX_ACTIVE:
		return
	var instance: AftermathEffect
	while _pool.size() > 0:
		var candidate = _pool.pop_back()
		if is_instance_valid(candidate):
			instance = candidate
			break
	if not instance:
		instance = AftermathEffect.new()

	instance._type = type
	instance._radius = radius
	instance._duration = duration
	instance._timer = 0.0
	instance._seed = randi()
	instance.global_position = pos
	instance.visible = true
	instance.set_process(true)
	instance.z_index = -1 if (type in ["scorch", "poison_pool", "burn_patch"]) else 0
	_active_count += 1
	_active.append(instance)

	if not instance.is_inside_tree():
		parent.add_child(instance)
	elif instance.get_parent() != parent:
		instance.reparent(parent, false)

static func _prand(i: int) -> float:
	var x: float = sin(float(i) * 12.9898 + 78.233) * 43758.5453
	return x - floorf(x)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _duration:
		visible = false
		set_process(false)
		_active.erase(self)
		_active_count = maxi(0, _active_count - 1)
		_pool.append(self)
		return
	queue_redraw()

func _draw() -> void:
	match _type:
		"scorch":
			_draw_scorch()
		"poison_pool":
			_draw_poison_pool()
		"burn_patch":
			_draw_burn_patch()
		"embers":
			_draw_embers()
		"smoke":
			_draw_smoke()
		"static_crackle":
			_draw_static_crackle()

func _draw_scorch() -> void:
	var fade_in: float = minf(1.0, _timer / 0.2)
	var pulse: float = 0.6 + 0.4 * sin(_timer * 3.0)
	draw_circle(Vector2.ZERO, _radius, Color(0.23, 0.1, 0.04, 0.5 * fade_in))
	draw_circle(Vector2.ZERO, _radius * 0.65, Color(0.1, 0.04, 0.04, 0.7 * fade_in))
	for i in 5:
		var ang: float = (_prand(_seed + i + 1) - 0.5) * TAU
		var dist: float = _prand(_seed + i + 7) * _radius * 0.5 + _radius * 0.2
		var pos := Vector2(cos(ang), sin(ang)) * dist
		draw_rect(Rect2(pos - Vector2(2, 2), Vector2(4, 4)), Color(1.0, 0.38, 0.19, pulse * fade_in))

func _draw_poison_pool() -> void:
	var fade_in: float = minf(1.0, _timer / 0.3)
	draw_circle(Vector2.ZERO, _radius, Color(0.1, 0.23, 0.06, 0.65 * fade_in))
	draw_circle(Vector2.ZERO, _radius * 0.75, Color(0.16, 0.35, 0.13, 0.75 * fade_in))
	draw_circle(Vector2.ZERO, _radius * 0.5, Color(0.35, 0.54, 0.19, 0.6 * fade_in))
	for i in 6:
		var period: float = 1.6 + _prand(_seed + i + 30) * 0.8
		var phase: float = fmod(_timer / period + _prand(_seed + i + 40), 1.0)
		var ang: float = _prand(_seed + i + 50) * TAU
		var dist: float = _prand(_seed + i + 60) * _radius * 0.7
		var bpos := Vector2(cos(ang) * dist, sin(ang) * dist - phase * 25.0)
		var sz: float = (1.0 - phase) * 6.0 + 3.0
		draw_circle(bpos, sz, Color(0.66, 0.88, 0.25, (1.0 - phase) * fade_in))

func _draw_burn_patch() -> void:
	var fade_in: float = minf(1.0, _timer / 0.3)
	var fade_out: float = minf(1.0, _duration - _timer)
	var op: float = fade_in * fade_out
	draw_circle(Vector2.ZERO, _radius, Color(0.1, 0.04, 0.03, 0.45 * op))
	for i in 4:
		var ang: float = (float(i) / 4.0) * TAU + _prand(_seed + i + 80) * 0.5
		var dist: float = _prand(_seed + i + 90) * _radius * 0.4
		var fx: float = cos(ang) * dist
		var fy: float = sin(ang) * dist
		var flicker: float = 0.5 + 0.5 * sin(_timer * 12.0 + _prand(_seed + i + 100) * 10.0)
		fy -= flicker * 10.0
		draw_circle(Vector2(fx, fy), 5.0 + flicker * 3.0, Color(1.0, 0.38, 0.13, 0.65 * op))
		draw_circle(Vector2(fx, fy), 3.0 + flicker * 2.0, Color(1.0, 0.88, 0.5, 0.8 * op))

func _draw_embers() -> void:
	var fade: float = minf(1.0, (_duration - _timer) * 2.0)
	for i in 10:
		var period: float = 1.2 + _prand(_seed + i + 300) * 0.6
		var offset: float = _prand(_seed + i + 310) * period
		var local_t: float = fmod((_timer + offset), period) / period
		var dx: float = (_prand(_seed + i + 320) - 0.5) * _radius * 1.6
		var fy: float = -local_t * 80.0
		var fx: float = dx + sin(local_t * 4.0 + i) * 5.0
		var sz: float = 3.0 + (1.0 - local_t) * 3.0
		draw_rect(Rect2(Vector2(fx - sz / 2.0, fy - sz / 2.0), Vector2(sz, sz)),
			Color(1.0, 0.5, 0.19, (1.0 - local_t) * 0.85 * fade))

func _draw_smoke() -> void:
	var fade_out: float = minf(1.0, _duration - _timer)
	for i in 5:
		var period: float = 1.8
		var offset: float = _prand(_seed + i + 200) * period
		var local_t: float = fmod((_timer + offset), period) / period
		var op: float = (1.0 - local_t) * 0.45 * fade_out
		var dx: float = (_prand(_seed + i + 210) - 0.5) * 30.0
		var sx: float = dx + sin(local_t * 4.0 + i) * 8.0
		var sy: float = -local_t * 60.0
		var sz: float = 4.0 + local_t * 12.0
		draw_circle(Vector2(sx, sy), sz, Color(0.23, 0.23, 0.23, op))

func _draw_static_crackle() -> void:
	for i in 5:
		var phase: float = fmod(_timer * 6.0 + _prand(_seed + i + 400) * 4.0, 1.0)
		if phase > 0.4:
			continue
		var ang: float = _prand(_seed + i + 410) * TAU + _timer * (_prand(_seed + i + 420) - 0.5) * 4.0
		var r: float = _radius * (0.4 + _prand(_seed + i + 430) * 0.6)
		var p1 := Vector2(cos(ang), sin(ang)) * r * 0.2
		var p2 := Vector2(cos(ang), sin(ang)) * r
		var op: float = 1.0 - phase / 0.4
		draw_line(p1, p2, Color(0.63, 0.85, 1.0, 0.35 * op), 5.0)
		draw_line(p1, p2, Color(0.63, 0.85, 1.0, 0.8 * op), 3.0)
		draw_line(p1, p2, Color(1.0, 1.0, 1.0, op), 1.0)
