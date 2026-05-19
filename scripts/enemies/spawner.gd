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
var _hp_mult: float = 1.0
var _speed_mult: float = 1.0
var _damage_mult: float = 1.0
var _gold_mult: float = 1.0
var _enemy_count: int = 40

func setup(player: Node2D, arena_rect: Rect2, stage_data: StageData = null) -> void:
	_player = player
	_arena_rect = arena_rect
	_enemies_alive = 0
	_ensure_pools()
	_apply_stage_data(stage_data)

func _apply_stage_data(stage_data: StageData) -> void:
	if not stage_data:
		_is_boss_stage = false
		_hp_mult = 1.0
		_speed_mult = 1.0
		_damage_mult = 1.0
		_gold_mult = 1.0
		_enemy_count = enemies_per_stage
		return

	_is_boss_stage = stage_data.type == StageData.Type.BOSS

	var depth_scale := StageGenerator.get_depth_scaling(stage_data.depth)
	_hp_mult = depth_scale["hp_mult"] * stage_data.get_enemy_hp_mult()
	_speed_mult = stage_data.get_enemy_speed_mult()
	_damage_mult = depth_scale["damage_mult"] * stage_data.get_enemy_damage_mult()
	_gold_mult = stage_data.get_gold_mult()

	var base_count: int = enemies_per_stage + int(depth_scale["count_add"])
	_enemy_count = int(base_count * stage_data.get_enemy_count_mult())
	_enemy_count = clampi(_enemy_count, 8, 80)

func _ensure_pools() -> void:
	for scene: PackedScene in enemy_scenes:
		var path := scene.resource_path
		if not _pools.has(path):
			_pools[path] = []

func start_next_wave() -> void:
	var remaining := _enemy_count
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
	enemy.apply_scaling(_hp_mult, _speed_mult, _damage_mult, _gold_mult)

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
	boss.apply_scaling(_hp_mult * 1.5, _speed_mult, _damage_mult * 1.3, _gold_mult * 3.0)
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
