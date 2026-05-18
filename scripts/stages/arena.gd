class_name Arena
extends Node2D

@onready var player: Player = $Player
@onready var spawner: Spawner = $Spawner
@onready var joystick: VirtualJoystick = $CanvasLayer/VirtualJoystick
@onready var hud: Control = $CanvasLayer/HUD

@export var arena_size := Vector2(1080, 1400)

var _waves_for_stage: int = 3

signal stage_completed

func start_stage(stage_number: int, skill_instances: Array[SkillInstance], boss_stage: bool = false) -> void:
	_waves_for_stage = 3 + stage_number
	player.global_position = Vector2(arena_size.x / 2, arena_size.y * 0.7)

	var caster := player.get_node("SkillCaster") as SkillCaster
	caster.set_skills(skill_instances)

	var arena_rect := Rect2(Vector2.ZERO, arena_size)
	spawner.setup(player, arena_rect, _waves_for_stage, boss_stage)
	spawner.all_waves_cleared.connect(_on_all_waves_cleared, CONNECT_ONE_SHOT)
	spawner.start_next_wave()

	if hud and hud.has_method("setup"):
		hud.setup(player)

func _on_all_waves_cleared() -> void:
	GameBus.stage_cleared.emit()
	stage_completed.emit()
