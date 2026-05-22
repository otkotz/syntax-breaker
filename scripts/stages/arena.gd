class_name Arena
extends Node2D

@onready var player: Player = $Player
@onready var spawner: Spawner = $Spawner
@onready var joystick: VirtualJoystick = $CanvasLayer/VirtualJoystick
@onready var hud: Control = $CanvasLayer/HUD
@onready var camera: CameraShake = $Player/Camera2D
@onready var minimap: Minimap = $CanvasLayer/Minimap
var _debug_menu: DebugMenu
var _combo_tracker: ComboTracker
var _consumable_manager: ConsumableManager

@export var arena_size := Vector2(1000, 1750)
@export var balance: GameBalance

var _arena_rect: Rect2
var _stage_data: StageData

signal stage_completed

func _ready() -> void:
	if not balance:
		balance = preload("res://resources/config/game_balance.tres")
	GameBus.enemy_killed.connect(_on_enemy_killed)
	GameBus.enemy_hit.connect(_on_enemy_hit)

func start_stage(stage_number: int, skill_instances: Array[SkillInstance], stage_data: StageData = null) -> void:
	_stage_data = stage_data
	_arena_rect = Rect2(Vector2.ZERO, arena_size)
	Targeting.setup()
	player.global_position = Vector2(arena_size.x / 2, arena_size.y * 0.7)

	if _stage_data:
		var speed_mult := _stage_data.get_player_speed_mult()
		if speed_mult != 1.0 and player.has_method("set_speed_mult"):
			player.set_speed_mult(speed_mult)

	var caster := player.get_node("SkillCaster") as SkillCaster
	caster.set_skills(skill_instances)

	spawner.setup(player, _arena_rect, stage_data)
	spawner.all_waves_cleared.connect(_on_all_waves_cleared, CONNECT_ONE_SHOT)
	spawner.start_next_wave()

	if camera:
		camera.limit_left = int(_arena_rect.position.x)
		camera.limit_right = int(_arena_rect.end.x)
		camera.limit_top = int(_arena_rect.position.y)
		camera.limit_bottom = int(_arena_rect.end.y)

	if hud and hud.has_method("setup"):
		hud.setup(player)

	if minimap:
		minimap.setup(player, _arena_rect)

	_debug_menu = DebugMenu.new()
	add_child(_debug_menu)
	_debug_menu.setup(player)

	_combo_tracker = ComboTracker.new()
	add_child(_combo_tracker)
	var combo_display := ComboDisplay.new()
	combo_display.anchors_preset = Control.PRESET_CENTER_RIGHT
	combo_display.offset_left = -150
	combo_display.offset_right = -10
	$CanvasLayer.add_child(combo_display)
	combo_display.setup(_combo_tracker)

	_consumable_manager = ConsumableManager.new()
	add_child(_consumable_manager)
	_consumable_manager.setup(RunManager.get_consumable_data())

	if _consumable_manager.get_slot_count() > 0:
		var consumable_hud := ConsumableHUD.new()
		consumable_hud.anchors_preset = Control.PRESET_BOTTOM_WIDE
		consumable_hud.offset_top = -100
		consumable_hud.alignment = BoxContainer.ALIGNMENT_CENTER
		$CanvasLayer.add_child(consumable_hud)
		consumable_hud.setup(_consumable_manager)

	SynergyTracker.clear()
	queue_redraw()

func _process(_delta: float) -> void:
	if player:
		player.global_position = player.global_position.clamp(
			_arena_rect.position + Vector2(16, 16),
			_arena_rect.end - Vector2(16, 16)
		)

func _draw() -> void:
	var bg := Color(0.12, 0.12, 0.18)
	var grid_c := Color(0.18, 0.18, 0.25)
	var border_c := Color(0.4, 0.4, 0.5)
	if _stage_data and _stage_data.region:
		bg = _stage_data.region.bg_color
		grid_c = _stage_data.region.grid_color
		border_c = _stage_data.region.border_color

	draw_rect(_arena_rect, bg, true)
	draw_rect(_arena_rect, border_c, false, 2.0)

	var grid_spacing := 50.0
	var x := _arena_rect.position.x + grid_spacing
	while x < _arena_rect.end.x:
		draw_line(Vector2(x, _arena_rect.position.y), Vector2(x, _arena_rect.end.y), grid_c)
		x += grid_spacing
	var y := _arena_rect.position.y + grid_spacing
	while y < _arena_rect.end.y:
		draw_line(Vector2(_arena_rect.position.x, y), Vector2(_arena_rect.end.x, y), grid_c)
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
