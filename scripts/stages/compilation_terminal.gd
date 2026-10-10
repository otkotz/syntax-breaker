class_name CompilationTerminal
extends Node2D

enum State { READY, ACTIVE, COMPLETED, FAILED }
enum Difficulty { COMPILE, OVERCLOCK, KERNEL_BREACH }

const ENCOUNTERS := [
	{"name": "COMPILE", "enemy_count": 24, "elite_count": 0, "miniboss": false, "zone_radius": 260.0, "outside_grace": 3.0, "tiers": [1, 1, 1, 2]},
	{"name": "OVERCLOCK", "enemy_count": 32, "elite_count": 3, "miniboss": false, "zone_radius": 220.0, "outside_grace": 2.0, "tiers": [1, 2, 2, 2, 3]},
	{"name": "KERNEL BREACH", "enemy_count": 40, "elite_count": 4, "miniboss": true, "zone_radius": 180.0, "outside_grace": 1.0, "tiers": [2, 2, 3, 3]},
]

signal activated(wave_size: int)
signal wave_completed
signal terminal_failed
signal status_changed(text: String)

const ACTIVATION_RADIUS := 72.0
const ZONE_RADIUS := 260.0
const DEFAULT_WAVE_SIZE := 24
const DEFAULT_OUTSIDE_GRACE := 3.0

var state: State = State.READY
var wave_size := DEFAULT_WAVE_SIZE
var kills_remaining := 0
var outside_grace := DEFAULT_OUTSIDE_GRACE
var outside_time := 0.0
var _player: Node2D
var _spawner: Spawner
var _player_inside := true
var _pulse := 0.0
var difficulty: Difficulty = Difficulty.COMPILE
var zone_radius := ZONE_RADIUS

static func roll_difficulty(rng: RandomNumberGenerator) -> Difficulty:
	return rng.randi_range(0, Difficulty.size() - 1)

func get_encounter_definition() -> Dictionary:
	return ENCOUNTERS[difficulty].duplicate(true)

func setup(player: Node2D, spawner: Spawner) -> void:
	_player = player
	_spawner = spawner
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	difficulty = roll_difficulty(rng)
	var definition := get_encounter_definition()
	wave_size = definition.enemy_count
	outside_grace = definition.outside_grace
	zone_radius = definition.zone_radius
	GameBus.enemy_killed.connect(_on_enemy_killed)
	status_changed.emit("%s — APPROACH TO COMPILE" % definition.name)
	queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta
	if state == State.READY and is_instance_valid(_player):
		if global_position.distance_to(_player.global_position) <= ACTIVATION_RADIUS:
			activate()
	elif state == State.ACTIVE and is_instance_valid(_player):
		set_player_inside(global_position.distance_to(_player.global_position) <= zone_radius)
		advance_wave(delta)
	queue_redraw()

func activate() -> bool:
	if state != State.READY:
		return false
	state = State.ACTIVE
	kills_remaining = wave_size
	outside_time = 0.0
	if is_instance_valid(_spawner):
		kills_remaining = _spawner.spawn_compilation_wave(global_position, get_encounter_definition())
		if kills_remaining <= 0:
			_fail()
			return false
	activated.emit(kills_remaining)
	status_changed.emit("COMPILATION LOCKED — %d HOSTILES" % kills_remaining)
	return true

func set_player_inside(value: bool) -> void:
	_player_inside = value

func advance_wave(delta: float) -> void:
	if state != State.ACTIVE:
		return
	if _player_inside:
		outside_time = 0.0
		return
	outside_time += delta
	status_changed.emit("SIGNAL LOST — %.1fs" % maxf(0.0, outside_grace - outside_time))
	if outside_time >= outside_grace:
		_fail()

func register_wave_kill() -> void:
	if state != State.ACTIVE:
		return
	kills_remaining = maxi(0, kills_remaining - 1)
	status_changed.emit("COMPILING — %d HOSTILES" % kills_remaining)
	if kills_remaining == 0:
		state = State.COMPLETED
		status_changed.emit("COMPILATION COMPLETE")
		wave_completed.emit()

func _on_enemy_killed(enemy: Node2D, _skill: Resource) -> void:
	if enemy.get_meta("compilation_wave", false):
		register_wave_kill()

func _fail() -> void:
	if state != State.ACTIVE:
		return
	state = State.FAILED
	status_changed.emit("TERMINAL DESTROYED")
	terminal_failed.emit()
	queue_redraw()

func _draw() -> void:
	if state == State.ACTIVE:
		draw_circle(Vector2.ZERO, zone_radius, Color(0.2, 0.75, 1.0, 0.055))
		draw_arc(Vector2.ZERO, zone_radius, 0.0, TAU, 96, Color(0.25, 0.85, 1.0, 0.75), 4.0)
	var glow := 0.72 + sin(_pulse * 4.0) * 0.18 if state == State.READY else 0.45
	var color := Color(0.2, 0.85, 1.0, glow)
	if state == State.ACTIVE:
		color = Color(1.0, 0.35, 0.15, glow)
	elif state == State.COMPLETED:
		color = Color(0.35, 1.0, 0.5, 0.75)
	elif state == State.FAILED:
		color = Color(0.18, 0.12, 0.14, 0.9)
	draw_rect(Rect2(-34, -42, 68, 84), Color(0.025, 0.03, 0.06), true)
	draw_rect(Rect2(-34, -42, 68, 84), color, false, 4.0)
	draw_rect(Rect2(-23, -29, 46, 37), color.darkened(0.45), true)
	for y in 3:
		draw_line(Vector2(-17, -22 + y * 10), Vector2(17, -22 + y * 10), color, 3.0)
	draw_line(Vector2(-16, 24), Vector2(16, 24), color, 5.0)
