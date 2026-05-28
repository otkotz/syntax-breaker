class_name DeathEffect
extends Node2D

var _timer: float = 0.0
const DURATION := 0.55
const PARTICLE_COUNT := 14
const RING_DURATION := 0.25

var _particles: Array = []
var _ring_color: Color = Color.WHITE

static var _pool: Array = []
static var _active: Array = []
const MAX_POOL := 15

static func clear_all() -> void:
	for instance in _active:
		if is_instance_valid(instance):
			instance.queue_free()
	_active.clear()
	for instance in _pool:
		if is_instance_valid(instance):
			instance.queue_free()
	_pool.clear()

static func spawn(parent: Node, pos: Vector2, active_dots: Dictionary) -> void:
	var instance: DeathEffect
	while _pool.size() > 0:
		var candidate = _pool.pop_back()
		if is_instance_valid(candidate):
			instance = candidate
			break
	if not instance:
		instance = DeathEffect.new()

	instance._configure(active_dots)
	instance.global_position = pos
	instance._timer = 0.0
	instance.visible = true
	instance.set_process(true)
	_active.append(instance)

	if not instance.is_inside_tree():
		parent.add_child(instance)
	elif instance.get_parent() != parent:
		instance.reparent(parent, false)

const BODY_COLORS: Array = [
	Color(0.54, 0.12, 0.17),
	Color(0.84, 0.23, 0.28),
	Color(0.23, 0.04, 0.08),
	Color(0.97, 0.54, 0.54),
]

const DOT_COLORS: Dictionary = {
	"poison": Color(0.2, 0.9, 0.2),
	"burn": Color(1.0, 0.5, 0.1),
	"bleed": Color(0.9, 0.15, 0.15),
	"shock": Color(0.4, 0.8, 1.0),
	"frostblight": Color(0.7, 0.9, 1.0),
}

func _configure(active_dots: Dictionary) -> void:
	_particles.clear()
	var colors: Array = []
	for c: Color in BODY_COLORS:
		colors.append(c)
	for dot_type: String in active_dots:
		if DOT_COLORS.has(dot_type):
			colors.append(DOT_COLORS[dot_type])
			colors.append(DOT_COLORS[dot_type])

	if not active_dots.is_empty():
		var first_dot: String = active_dots.keys()[0]
		_ring_color = DOT_COLORS.get(first_dot, Color.WHITE)
	else:
		_ring_color = Color(1.0, 0.85, 0.5)

	for i in PARTICLE_COUNT:
		var angle := randf() * TAU
		var speed := randf_range(80.0, 200.0)
		var col: Color = colors[i % colors.size()]
		var sz := randf_range(2.0, 5.0)
		_particles.append({
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed,
			"x": randf_range(-4.0, 4.0),
			"y": randf_range(-8.0, 0.0),
			"size": sz,
			"color": col,
		})

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= DURATION:
		visible = false
		set_process(false)
		_active.erase(self)
		_pool.append(self)
		return
	for p: Dictionary in _particles:
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		p["vy"] += 220.0 * delta
	queue_redraw()

func _draw() -> void:
	var t := _timer / DURATION
	var fade := 1.0 - t * t

	# Ring burst
	if _timer < RING_DURATION:
		var rt := _timer / RING_DURATION
		var ring_r := rt * 40.0
		var ring_op := (1.0 - rt) * 0.7
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 20, Color(_ring_color, ring_op), 2.0)
		if rt < 0.4:
			draw_circle(Vector2.ZERO, (1.0 - rt * 2.5) * 12.0, Color(Color.WHITE, (1.0 - rt * 2.5) * 0.9))

	for p: Dictionary in _particles:
		var sz: float = p["size"] * fade
		if sz < 0.5:
			continue
		var col: Color = p["color"]
		draw_rect(Rect2(Vector2(p["x"] - sz * 0.5, p["y"] - sz * 0.5), Vector2(sz, sz)), Color(col, fade))
