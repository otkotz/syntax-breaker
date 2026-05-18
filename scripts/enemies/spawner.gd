class_name Spawner
extends Node2D

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared

@export var enemy_scenes: Array[PackedScene] = []
@export var mini_boss_scene: PackedScene
@export var spawn_margin: float = 50.0

var _current_wave: int = 0
var _total_waves: int = 3
var _enemies_alive: int = 0
var _player: Node2D
var _arena_rect: Rect2
var _is_boss_stage: bool = false

func setup(player: Node2D, arena_rect: Rect2, total_waves: int, boss_stage: bool = false) -> void:
	_player = player
	_arena_rect = arena_rect
	_total_waves = total_waves
	_current_wave = 0
	_is_boss_stage = boss_stage

func start_next_wave() -> void:
	_current_wave += 1
	if _current_wave > _total_waves:
		all_waves_cleared.emit()
		return

	var enemy_count := 5 + _current_wave * 3
	_enemies_alive = enemy_count
	wave_started.emit(_current_wave)
	if _current_wave > 1:
		GameBus.wave_cleared.emit(_current_wave - 1)

	for i in enemy_count:
		_spawn_enemy()

func _spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		return
	var scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy := scene.instantiate() as EnemyBase
	enemy.global_position = _random_edge_position()
	enemy.initialize(_player)
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)

func _on_enemy_died(_enemy: EnemyBase) -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0:
		if _current_wave >= _total_waves:
			if _is_boss_stage and mini_boss_scene:
				_spawn_mini_boss()
			else:
				all_waves_cleared.emit()
		else:
			get_tree().create_timer(1.0).timeout.connect(start_next_wave)

func _spawn_mini_boss() -> void:
	var boss := mini_boss_scene.instantiate() as EnemyBase
	boss.global_position = Vector2(_arena_rect.get_center().x, _arena_rect.position.y + 100)
	boss.initialize(_player)
	boss.died.connect(func(_e): all_waves_cleared.emit(), CONNECT_ONE_SHOT)
	_enemies_alive = 1
	add_child(boss)

func _random_edge_position() -> Vector2:
	var side := randi() % 4
	match side:
		0: return Vector2(randf_range(_arena_rect.position.x, _arena_rect.end.x), _arena_rect.position.y - spawn_margin)
		1: return Vector2(randf_range(_arena_rect.position.x, _arena_rect.end.x), _arena_rect.end.y + spawn_margin)
		2: return Vector2(_arena_rect.position.x - spawn_margin, randf_range(_arena_rect.position.y, _arena_rect.end.y))
		_: return Vector2(_arena_rect.end.x + spawn_margin, randf_range(_arena_rect.position.y, _arena_rect.end.y))
