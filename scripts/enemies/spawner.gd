class_name Spawner
extends Node2D

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared

@export var enemy_scenes: Array[PackedScene] = []
@export var mini_boss_scene: PackedScene
@export var spawn_margin: float = 50.0
@export var enemies_per_stage: int = 40

var _enemies_alive: int = 0
var _player: Node2D
var _arena_rect: Rect2
var _is_boss_stage: bool = false

func setup(player: Node2D, arena_rect: Rect2, total_waves: int, boss_stage: bool = false) -> void:
	_player = player
	_arena_rect = arena_rect
	_is_boss_stage = boss_stage
	_enemies_alive = 0

func start_next_wave() -> void:
	var remaining := enemies_per_stage
	_enemies_alive = remaining

	while remaining > 0:
		var group_size: int = mini(randi_range(4, 6), remaining)
		var center := _random_map_position()
		for i in group_size:
			_spawn_enemy_at(center + Vector2(randf_range(-40, 40), randf_range(-40, 40)))
		remaining -= group_size

	if _is_boss_stage and mini_boss_scene:
		_spawn_mini_boss()

func _spawn_enemy_at(pos: Vector2) -> void:
	if enemy_scenes.is_empty():
		return
	var scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy := scene.instantiate() as EnemyBase
	enemy.global_position = pos.clamp(_arena_rect.position + Vector2(spawn_margin, spawn_margin), _arena_rect.end - Vector2(spawn_margin, spawn_margin))
	enemy.initialize(_player)
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)

func _on_enemy_died(_enemy: EnemyBase) -> void:
	_enemies_alive -= 1
	if _enemies_alive <= 0:
		all_waves_cleared.emit()

func _spawn_mini_boss() -> void:
	_enemies_alive += 1
	var boss := mini_boss_scene.instantiate() as EnemyBase
	boss.global_position = _arena_rect.get_center()
	boss.initialize(_player)
	boss.died.connect(_on_enemy_died)
	add_child(boss)

func _random_map_position() -> Vector2:
	var margin := spawn_margin
	var min_dist_from_player := 200.0
	for attempt in 10:
		var pos := Vector2(
			randf_range(_arena_rect.position.x + margin, _arena_rect.end.x - margin),
			randf_range(_arena_rect.position.y + margin, _arena_rect.end.y - margin),
		)
		if not _player or pos.distance_to(_player.global_position) > min_dist_from_player:
			return pos
	return _arena_rect.get_center()
