class_name Arena
extends Node2D

@onready var player: Player = $Player
@onready var spawner: Spawner = $Spawner
@onready var joystick: VirtualJoystick = $CanvasLayer/VirtualJoystick
@onready var hud: Control = $CanvasLayer/HUD
@onready var camera: CameraShake = $Player/Camera2D
@onready var minimap: Minimap = $CanvasLayer/Minimap

@export var arena_size := Vector2(3200, 3200)
@export var balance: GameBalance

var _arena_rect: Rect2

signal stage_completed

func _ready() -> void:
	if not balance:
		balance = preload("res://resources/config/game_balance.tres")
	GameBus.enemy_killed.connect(_on_enemy_killed)
	GameBus.enemy_hit.connect(_on_enemy_hit)

func start_stage(stage_number: int, skill_instances: Array[SkillInstance], boss_stage: bool = false) -> void:
	_arena_rect = Rect2(Vector2.ZERO, arena_size)
	player.global_position = Vector2(arena_size.x / 2, arena_size.y * 0.7)

	var caster := player.get_node("SkillCaster") as SkillCaster
	caster.set_skills(skill_instances)

	spawner.setup(player, _arena_rect, boss_stage)
	spawner.all_waves_cleared.connect(_on_all_waves_cleared, CONNECT_ONE_SHOT)
	spawner.start_next_wave()

	if hud and hud.has_method("setup"):
		hud.setup(player)

	if minimap:
		minimap.setup(player, _arena_rect)

	queue_redraw()

func _process(_delta: float) -> void:
	if player:
		player.global_position = player.global_position.clamp(
			_arena_rect.position + Vector2(16, 16),
			_arena_rect.end - Vector2(16, 16)
		)

func _draw() -> void:
	draw_rect(_arena_rect, Color(0.12, 0.12, 0.18), true)
	draw_rect(_arena_rect, Color(0.4, 0.4, 0.5), false, 2.0)

	var grid_spacing := 50.0
	var grid_color := Color(0.18, 0.18, 0.25)
	var x := _arena_rect.position.x + grid_spacing
	while x < _arena_rect.end.x:
		draw_line(Vector2(x, _arena_rect.position.y), Vector2(x, _arena_rect.end.y), grid_color)
		x += grid_spacing
	var y := _arena_rect.position.y + grid_spacing
	while y < _arena_rect.end.y:
		draw_line(Vector2(_arena_rect.position.x, y), Vector2(_arena_rect.end.x, y), grid_color)
		y += grid_spacing

func _on_enemy_hit(_enemy: Node2D, _damage: float, _skill: Resource) -> void:
	if camera and balance:
		camera.shake(balance.screen_shake_on_hit, balance.screen_shake_duration)

func _on_enemy_killed(_enemy: Node2D, _killer_skill: Resource) -> void:
	if camera and balance:
		camera.shake(balance.screen_shake_on_kill, balance.screen_shake_duration)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		Engine.time_scale = 1.0

func _on_all_waves_cleared() -> void:
	GameBus.stage_cleared.emit()
	stage_completed.emit()
