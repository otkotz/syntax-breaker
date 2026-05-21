class_name Spawner
extends Node2D

signal all_waves_cleared

@export var melee_scene: PackedScene
@export var ranged_scene: PackedScene
@export var tank_scene: PackedScene
@export var swarm_scene: PackedScene
@export var mini_boss_scene: PackedScene

var _player: Node2D
var _arena_rect: Rect2
var _pools: Dictionary = {}
var _active: bool = false
var _completed: bool = false

var _hp_mult: float = 1.0
var _speed_mult: float = 1.0
var _damage_mult: float = 1.0
var _gold_mult: float = 1.0

var _pulse_timer: float = 0.0
var _pulse_count: int = 0
var _total_budget: int = 80
var _spawned_count: int = 0
var _enemies_alive: int = 0
var _enemies_per_pulse: int = 6

var _phase: int = 1
var _stage_duration: float = 55.0
var _stage_timer: float = 0.0
var _ranged_ratio: float = 0.0
var _formations_per_pulse: int = 1
var _has_mini_boss: bool = false
var _mini_boss_spawned: bool = false
var _is_boss_stage: bool = false
var _elite_interval: int = 999
var _pulses_since_elite: int = 0
var _power_pulse_interval: int = 5

const PULSE_INTERVAL := 4.5

const ROLE_SCALING := {
	"trash": {"hp": 0.3, "speed": 1.0, "damage": 0.5, "gold": 0.5},
	"medium": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
	"tank": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
	"swarm": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
	"ranged": {"hp": 0.5, "speed": 0.8, "damage": 0.8, "gold": 1.0},
	"elite": {"hp": 3.0, "speed": 1.0, "damage": 1.5, "gold": 5.0},
}

func setup(player: Node2D, arena_rect: Rect2, stage_data: StageData = null) -> void:
	_player = player
	_arena_rect = arena_rect
	_enemies_alive = 0
	_spawned_count = 0
	_pulse_count = 0
	_pulses_since_elite = 0
	_mini_boss_spawned = false
	_active = false
	_completed = false
	_ensure_pools()
	_apply_stage_data(stage_data)

func _apply_stage_data(stage_data: StageData) -> void:
	if not stage_data:
		_phase = 1
		_total_budget = 80
		_stage_duration = 55.0
		_hp_mult = 1.0
		_speed_mult = 1.0
		_damage_mult = 1.0
		_gold_mult = 1.0
		_has_mini_boss = false
		_is_boss_stage = false
		_configure_phase()
		return

	_is_boss_stage = stage_data.type == StageData.Type.BOSS
	_phase = stage_data.get_run_phase()

	var depth_scale := StageGenerator.get_depth_scaling(stage_data.depth)
	_hp_mult = depth_scale["hp_mult"] * stage_data.get_enemy_hp_mult()
	_speed_mult = stage_data.get_enemy_speed_mult()
	_damage_mult = depth_scale["damage_mult"] * stage_data.get_enemy_damage_mult()
	_gold_mult = stage_data.get_gold_mult()

	var curve := StageGenerator.get_density_curve(stage_data.depth)
	_total_budget = int(curve["total_enemies"] * stage_data.get_enemy_count_mult())
	_stage_duration = curve["duration"]
	_has_mini_boss = curve["has_mini_boss"] and not _is_boss_stage

	if _is_boss_stage:
		_total_budget = int(_total_budget * 0.5)

	_configure_phase()

func _configure_phase() -> void:
	match _phase:
		1:
			_ranged_ratio = 0.0
			_formations_per_pulse = 1
			_elite_interval = 999
			_power_pulse_interval = 6
		2:
			_ranged_ratio = 0.08
			_formations_per_pulse = 2
			_elite_interval = 3
			_power_pulse_interval = 5
		_:
			_ranged_ratio = 0.12
			_formations_per_pulse = 3
			_elite_interval = 2
			_power_pulse_interval = 4

	var num_pulses := maxi(1, int(_stage_duration / PULSE_INTERVAL))
	_enemies_per_pulse = maxi(4, _total_budget / num_pulses)

func _ensure_pools() -> void:
	for scene: PackedScene in [melee_scene, ranged_scene, tank_scene, swarm_scene]:
		if scene:
			var path := scene.resource_path
			if not _pools.has(path):
				_pools[path] = []

func start_next_wave() -> void:
	_active = true
	_stage_timer = _stage_duration
	_pulse_timer = 0.5

	if _is_boss_stage and mini_boss_scene:
		_spawn_boss()

func _process(delta: float) -> void:
	if not _active:
		return

	_stage_timer -= delta
	_pulse_timer -= delta

	var can_spawn := _stage_timer > 0.0 and _spawned_count < _total_budget

	if _pulse_timer <= 0.0 and can_spawn:
		_spawn_pulse()
		_pulse_timer = PULSE_INTERVAL

	if not can_spawn and _enemies_alive <= 0:
		_complete_stage()

func _spawn_pulse() -> void:
	_pulse_count += 1
	_pulses_since_elite += 1

	var is_power := _pulse_count > 1 and _pulse_count % _power_pulse_interval == 0
	var count := _enemies_per_pulse
	if is_power:
		count *= 2

	count = mini(count, _total_budget - _spawned_count)
	if count <= 0:
		return

	var available_formations: Array[SpawnFormation.Type] = [
		SpawnFormation.Type.RING,
		SpawnFormation.Type.LINES,
		SpawnFormation.Type.CLUSTER,
		SpawnFormation.Type.STREAM,
		SpawnFormation.Type.SCATTERED,
	]
	available_formations.shuffle()
	var num_formations := mini(_formations_per_pulse, available_formations.size())

	var per_formation := count / num_formations
	var remainder := count % num_formations

	for i in num_formations:
		var f_count := per_formation + (1 if i < remainder else 0)
		if f_count <= 0:
			continue
		var formation: SpawnFormation.Type = available_formations[i]
		var positions := SpawnFormation.get_positions(formation, f_count, _arena_rect, _player.global_position)
		for pos: Vector2 in positions:
			_spawn_enemy_at(pos, _pick_role())

	if _pulses_since_elite >= _elite_interval and _phase >= 2:
		_pulses_since_elite = 0
		_spawn_elite()

	if _has_mini_boss and not _mini_boss_spawned and _spawned_count >= _total_budget * 0.6:
		_mini_boss_spawned = true
		_spawn_mini_boss()

func _pick_role() -> String:
	var roll := randf()
	match _phase:
		1:
			return "trash" if roll < 0.85 else "medium"
		2:
			if roll < 0.65: return "trash"
			if roll < 0.85: return "medium"
			if roll < 0.90: return "tank"
			if roll < 0.93: return "swarm"
			return "trash"
		_:
			if roll < 0.60: return "trash"
			if roll < 0.80: return "medium"
			if roll < 0.85: return "tank"
			if roll < 0.88: return "swarm"
			return "trash"

func _get_scene_for_role(role: String) -> PackedScene:
	match role:
		"trash", "medium":
			return melee_scene
		"tank":
			return tank_scene if tank_scene else melee_scene
		"swarm":
			return swarm_scene if swarm_scene else melee_scene
		"ranged":
			return ranged_scene if ranged_scene else melee_scene
	return melee_scene

func _spawn_enemy_at(pos: Vector2, role: String) -> void:
	if role in ["trash", "medium"] and randf() < _ranged_ratio:
		role = "ranged"

	var scene := _get_scene_for_role(role)
	if not scene:
		return

	var clamped := pos.clamp(
		_arena_rect.position + Vector2(20, 20),
		_arena_rect.end - Vector2(20, 20)
	)

	var enemy := _get_from_pool(scene)
	enemy.global_position = clamped
	enemy._arena_rect = _arena_rect
	enemy.initialize(_player)

	var rs: Dictionary = ROLE_SCALING.get(role, ROLE_SCALING["trash"])
	enemy.apply_scaling(
		_hp_mult * rs["hp"],
		_speed_mult * rs["speed"],
		_damage_mult * rs["damage"],
		_gold_mult * rs["gold"]
	)

	_spawned_count += 1
	_enemies_alive += 1

func _spawn_elite() -> void:
	if not mini_boss_scene:
		return
	var pos := SpawnFormation.random_edge_position(_arena_rect, _player.global_position)
	var enemy := _get_from_pool(mini_boss_scene)
	enemy.global_position = pos
	enemy._arena_rect = _arena_rect
	enemy.initialize(_player)
	var rs: Dictionary = ROLE_SCALING["elite"]
	enemy.apply_scaling(
		_hp_mult * rs["hp"],
		_speed_mult * rs["speed"],
		_damage_mult * rs["damage"],
		_gold_mult * rs["gold"]
	)
	_enemies_alive += 1

func _spawn_mini_boss() -> void:
	if not mini_boss_scene:
		return
	var boss := mini_boss_scene.instantiate() as EnemyBase
	boss.died.connect(_on_enemy_died)
	add_child(boss)
	boss.global_position = SpawnFormation.random_edge_position(_arena_rect, _player.global_position)
	boss._arena_rect = _arena_rect
	boss.initialize(_player)
	boss.apply_scaling(_hp_mult * 2.0, _speed_mult, _damage_mult * 1.5, _gold_mult * 5.0)
	_enemies_alive += 1

func _spawn_boss() -> void:
	var boss := mini_boss_scene.instantiate() as EnemyBase
	boss.died.connect(_on_enemy_died)
	add_child(boss)
	boss.global_position = _arena_rect.get_center()
	boss._arena_rect = _arena_rect
	boss.initialize(_player)
	boss.apply_scaling(_hp_mult * 5.0, _speed_mult * 0.8, _damage_mult * 2.0, _gold_mult * 10.0)
	_enemies_alive += 1

func _complete_stage() -> void:
	if _completed:
		return
	_completed = true
	_active = false
	all_waves_cleared.emit()

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
	var can_spawn := _stage_timer > 0.0 and _spawned_count < _total_budget
	if not can_spawn and _enemies_alive <= 0:
		_complete_stage()

func get_stage_timer() -> float:
	return maxf(_stage_timer, 0.0)

func get_stage_progress() -> float:
	if _stage_duration <= 0.0:
		return 1.0
	return 1.0 - clampf(_stage_timer / _stage_duration, 0.0, 1.0)

func release_all() -> void:
	for path: String in _pools:
		var pool: Array = _pools[path]
		for enemy: EnemyBase in pool:
			enemy.queue_free()
		pool.clear()
