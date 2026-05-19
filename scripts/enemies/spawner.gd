class_name Spawner
extends Node2D

signal all_waves_cleared

@export var enemy_scenes: Array[PackedScene] = []
@export var mini_boss_scene: PackedScene
@export var spawn_margin: float = 50.0
@export var enemies_per_stage: int = 40

var _enemies_alive: int = 0
var _player: Node2D
var _arena_rect: Rect2
var _is_boss_stage: bool = false
var _pools: Dictionary = {}

func setup(player: Node2D, arena_rect: Rect2, boss_stage: bool = false) -> void:
	_player = player
	_arena_rect = arena_rect
	_is_boss_stage = boss_stage
	_enemies_alive = 0
	_ensure_pools()

func _ensure_pools() -> void:
	for scene: PackedScene in enemy_scenes:
		var path := scene.resource_path
		if not _pools.has(path):
			_pools[path] = []

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
	var clamped_pos := pos.clamp(_arena_rect.position + Vector2(spawn_margin, spawn_margin), _arena_rect.end - Vector2(spawn_margin, spawn_margin))

	var enemy := _get_from_pool(scene)
	enemy.global_position = clamped_pos
	enemy._arena_rect = _arena_rect
	enemy.initialize(_player)

func _get_from_pool(scene: PackedScene) -> EnemyBase:
	var path := scene.resource_path
	if not _pools.has(path):
		_pools[path] = []
	var pool: Array = _pools[path]

	if pool.size() > 0:
		var enemy: EnemyBase = pool.pop_back()
		enemy.reset()
		return enemy

	var enemy := scene.instantiate() as EnemyBase
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)
	return enemy

func _return_to_pool(enemy: EnemyBase) -> void:
	var scene_path := enemy.scene_file_path
	if not _pools.has(scene_path):
		_pools[scene_path] = []
	_pools[scene_path].append(enemy)

func _on_enemy_died(enemy: EnemyBase) -> void:
	_return_to_pool(enemy)
	_enemies_alive -= 1
	if _enemies_alive <= 0:
		all_waves_cleared.emit()

func _spawn_mini_boss() -> void:
	_enemies_alive += 1
	var boss := mini_boss_scene.instantiate() as EnemyBase
	boss.global_position = _arena_rect.get_center()
	boss._arena_rect = _arena_rect
	boss.initialize(_player)
	boss.died.connect(_on_enemy_died)
	add_child(boss)

func release_all() -> void:
	for path: String in _pools:
		var pool: Array = _pools[path]
		for enemy: EnemyBase in pool:
			enemy.queue_free()
		pool.clear()

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
