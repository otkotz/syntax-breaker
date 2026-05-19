class_name Arena
extends Node2D

@onready var player: Player = $Player
@onready var spawner: Spawner = $Spawner
@onready var joystick: VirtualJoystick = $CanvasLayer/VirtualJoystick
@onready var hud: Control = $CanvasLayer/HUD

@export var arena_size := Vector2(3200, 3200)

var _waves_for_stage: int = 3
var _arena_rect: Rect2

signal stage_completed

func start_stage(stage_number: int, skill_instances: Array[SkillInstance], boss_stage: bool = false) -> void:
	_waves_for_stage = 3 + stage_number
	_arena_rect = Rect2(Vector2.ZERO, arena_size)
	player.global_position = Vector2(arena_size.x / 2, arena_size.y * 0.7)

	var caster := player.get_node("SkillCaster") as SkillCaster
	caster.set_skills(skill_instances)

	spawner.setup(player, _arena_rect, _waves_for_stage, boss_stage)
	spawner.all_waves_cleared.connect(_on_all_waves_cleared, CONNECT_ONE_SHOT)
	spawner.start_next_wave()

	if hud and hud.has_method("setup"):
		hud.setup(player)

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

func _on_all_waves_cleared() -> void:
	GameBus.stage_cleared.emit()
	stage_completed.emit()
