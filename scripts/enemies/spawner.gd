class_name Spawner
extends Node2D

signal all_waves_cleared

@export var melee_scene: PackedScene
@export var ranged_scene: PackedScene
@export var tank_scene: PackedScene
@export var swarm_scene: PackedScene
@export var mini_boss_scene: PackedScene
@export var charger_scene: PackedScene
@export var denial_caster_scene: PackedScene
@export var shield_support_scene: PackedScene
@export var splitter_scene: PackedScene
@export var split_fragment_scene: PackedScene

const ROLE_LIMITS := {"charger": 2, "denial_caster": 2, "shield_support": 1, "splitter": 2, "split_fragment": 8}
var _active_role_counts: Dictionary = {}
var _suppress_split_spawns: bool = false
var _pending_split_fragments: int = 0
var _spawn_generation: int = 0
var _pending_boss_add_requests: Dictionary = {}
var _next_boss_add_request: int = 0

var _player: Node2D
var _arena_rect: Rect2
var _pools: Dictionary = {}
var _active: bool = false
var _completed: bool = false

var _hp_mult: float = 1.0
var _speed_mult: float = 1.0
var _damage_mult: float = 1.0
var _gold_mult: float = 1.0

var _pulse_cooldown: float = 0.0
var _pulse_count: int = 0
var _total_budget: int = 80
var _spawned_count: int = 0
var _enemies_alive: int = 0
var _enemies_per_pulse: int = 6
var _spawn_threshold: int = 3

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

const MIN_PULSE_COOLDOWN := 2.0
const EliteAffix = preload("res://scripts/enemies/elite_affix.gd")
# Load scenes at encounter creation, not while parsing this global class. Regional
# bosses reference Player -> SkillCaster -> Arena -> Spawner; preloading their
# inherited scenes here creates an export-time resource loading cycle.
const REGIONAL_BOSS_PATHS := {
	"burning_grounds": "res://scenes/enemies/burning_boss.tscn",
	"storm_spire": "res://scenes/enemies/storm_boss.tscn",
	"toxic_depths": "res://scenes/enemies/toxic_boss.tscn",
}
var _elite_spawn_count: int = 0
var _encounter_data: StageData
var _scripted_pulses: Dictionary = {}
var _boss_region: String = "burning_grounds"
var _stage_depth: int = 1

const ROLE_SCALING := {
	"trash": {"hp": 0.3, "speed": 1.0, "damage": 0.3, "gold": 0.5},
	"medium": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
	"tank": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
	"swarm": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
	"ranged": {"hp": 0.5, "speed": 0.8, "damage": 0.8, "gold": 1.0},
	"elite": {"hp": 2.0, "speed": 1.0, "damage": 1.3, "gold": 1.5},
	"charger": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
	"denial_caster": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
	"shield_support": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
	"splitter": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
	"split_fragment": {"hp": 1.0, "speed": 1.0, "damage": 1.0, "gold": 1.0},
}

func setup(player: Node2D, arena_rect: Rect2, stage_data: StageData = null) -> void:
	_player = player
	_arena_rect = arena_rect
	_enemies_alive = 0
	_active_role_counts.clear()
	_pending_split_fragments = 0
	_pending_boss_add_requests.clear()
	_spawn_generation += 1
	_elite_spawn_count = 0
	_scripted_pulses.clear()
	_spawned_count = 0
	_pulse_count = 0
	_pulse_cooldown = 0.0
	_pulses_since_elite = 0
	_mini_boss_spawned = false
	_active = false
	_completed = false
	_ensure_pools()
	_apply_stage_data(stage_data)

func _apply_stage_data(stage_data: StageData) -> void:
	_encounter_data = stage_data
	_boss_region = stage_data.region.id if stage_data and stage_data.region else RunManager.current_region
	_stage_depth = stage_data.depth if stage_data else 1
	if not stage_data:
		_phase = 1
		_total_budget = int(80 * QualitySettings.entity_mult)
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

	_total_budget = int(_total_budget * QualitySettings.entity_mult)
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

	var num_pulses := maxi(1, int(_stage_duration / MIN_PULSE_COOLDOWN))
	_enemies_per_pulse = maxi(4, _total_budget / num_pulses)
	_spawn_threshold = maxi(2, int(_enemies_per_pulse * 0.35))

func _ensure_pools() -> void:
	for scene: PackedScene in [melee_scene, ranged_scene, tank_scene, swarm_scene, charger_scene, denial_caster_scene, shield_support_scene, splitter_scene, split_fragment_scene]:
		if scene:
			var path := scene.resource_path
			if not _pools.has(path):
				_pools[path] = []

func start_next_wave() -> void:
	_active = true
	_stage_timer = _stage_duration
	_pulse_cooldown = 0.0

	if _is_boss_stage:
		_spawn_boss()

func _process(delta: float) -> void:
	if not _active:
		return

	_stage_timer -= delta
	_pulse_cooldown -= delta

	var can_spawn := _stage_timer > 0.0 and _spawned_count < _total_budget

	if can_spawn and _pulse_cooldown <= 0.0 and _enemies_alive <= _spawn_threshold:
		_spawn_pulse()
		_pulse_cooldown = MIN_PULSE_COOLDOWN

	if not can_spawn and _enemies_alive <= 0 and _pending_split_fragments == 0:
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

	if _pulses_since_elite >= _elite_interval and _phase >= 2 and not _is_boss_stage:
		_pulses_since_elite = 0
		_spawn_elite()
	_spawn_scripted_roles(_pulse_count)

	if _has_mini_boss and not _mini_boss_spawned and _spawned_count >= _total_budget * 0.6:
		_mini_boss_spawned = true
		_spawn_mini_boss()

func _spawn_scripted_roles(pulse: int) -> void:
	if not _encounter_data or _scripted_pulses.has(pulse):
		return
	_scripted_pulses[pulse] = true
	for role in _encounter_data.get_scripted_roles(pulse):
		if role == "elite":
			_spawn_elite()
		elif get_active_role_count(role) < int(ROLE_LIMITS.get(role, 999)):
			_spawn_enemy_at(SpawnFormation.random_edge_position(_arena_rect, _player.global_position), role, false)

func _pick_role() -> String:
	var roll := randf()
	match _phase:
		1:
			if roll >= 0.94: return "charger"
			return "trash" if roll < 0.85 else "medium"
		2:
			if roll < 0.65: return "trash"
			if roll < 0.79: return "medium"
			if roll < 0.82: return "splitter"
			if roll < 0.85: return "shield_support"
			if roll < 0.90: return "tank"
			if roll < 0.93: return "swarm"
			return "charger" if roll < 0.97 else "denial_caster"
		_:
			if roll < 0.60: return "trash"
			if roll < 0.72: return "medium"
			if roll < 0.76: return "splitter"
			if roll < 0.80: return "shield_support"
			if roll < 0.85: return "tank"
			if roll < 0.88: return "swarm"
			return "charger" if roll < 0.94 else "denial_caster"

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
		"charger":
			return charger_scene if charger_scene else melee_scene
		"denial_caster":
			return denial_caster_scene if denial_caster_scene else melee_scene
		"shield_support":
			return shield_support_scene if shield_support_scene else melee_scene
		"splitter":
			return splitter_scene if splitter_scene else melee_scene
		"split_fragment":
			return split_fragment_scene
	return melee_scene

func _spawn_enemy_at(pos: Vector2, role: String, counts_toward_budget: bool = true, cleansing: bool = false) -> void:
	if ROLE_LIMITS.has(role) and get_active_role_count(role) >= int(ROLE_LIMITS[role]):
		if role == "split_fragment":
			return
		role = "trash"
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
	enemy.set_meta("spawn_role", role)
	if cleansing:
		enemy.set_meta("cleanses_boss_poison", true)
	elif enemy.has_meta("cleanses_boss_poison"):
		enemy.remove_meta("cleanses_boss_poison")
	_active_role_counts[role] = get_active_role_count(role) + 1
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

	if counts_toward_budget:
		_spawned_count += 1
	_enemies_alive += 1
	RunTelemetry.enemy_spawned(role)

func spawn_split_children(source: EnemyBase) -> void:
	_reserve_fragments(source, false)

func spawn_boss_adds(source: EnemyBase) -> void:
	_reserve_fragments(source, true)

func _reserve_fragments(source: EnemyBase, cleansing: bool) -> void:
	if _suppress_split_spawns or _completed or source.get_parent() != self or not split_fragment_scene:
		return
	var available := int(ROLE_LIMITS["split_fragment"]) - get_active_role_count("split_fragment") - _pending_split_fragments
	var count := mini(2, maxi(0, available))
	if count == 0:
		return
	_pending_split_fragments += count
	var request := 0
	if cleansing:
		_next_boss_add_request += 1
		request = _next_boss_add_request
		_pending_boss_add_requests[request] = {"source_id": source.get_instance_id(), "count": count}
	# Death can run inside body_entered while the physics server is flushing queries.
	_materialize_split_fragments.call_deferred(source.global_position, count, _spawn_generation, cleansing, request)

func _materialize_split_fragments(origin: Vector2, count: int, generation: int, cleansing: bool, request: int) -> void:
	if generation != _spawn_generation:
		return
	if cleansing:
		if not _pending_boss_add_requests.has(request):
			return
		_pending_boss_add_requests.erase(request)
	_pending_split_fragments -= count
	if _completed or _suppress_split_spawns:
		return
	for i in count:
		var offset := Vector2(-24 if i == 0 else 24, 0)
		_spawn_enemy_at(origin + offset, "split_fragment", false, cleansing)

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
	var affix := enemy.get_node_or_null("EliteAffix")
	if not affix:
		affix = EliteAffix.new()
		affix.name = "EliteAffix"
		enemy.add_child(affix)
	affix.configure("trail" if _elite_spawn_count % 2 == 0 else "nova")
	_elite_spawn_count += 1
	_enemies_alive += 1
	RunTelemetry.enemy_spawned("elite")

func _spawn_mini_boss() -> void:
	if not mini_boss_scene:
		return
	var boss := mini_boss_scene.instantiate() as EnemyBase
	boss.died.connect(_on_enemy_died)
	add_child(boss)
	boss.global_position = SpawnFormation.random_edge_position(_arena_rect, _player.global_position)
	boss._arena_rect = _arena_rect
	boss.initialize(_player)
	boss.apply_scaling(_hp_mult * 1.5, _speed_mult, _damage_mult * 1.2, _gold_mult * 2.0)
	_enemies_alive += 1
	RunTelemetry.enemy_spawned("mini_boss")

func _spawn_boss() -> void:
	var scene := load(REGIONAL_BOSS_PATHS.get(_boss_region, REGIONAL_BOSS_PATHS["burning_grounds"])) as PackedScene
	if not scene:
		return
	var boss := scene.instantiate() as EnemyBase
	boss.died.connect(_on_enemy_died)
	add_child(boss)
	if boss is MiniBoss:
		(boss as MiniBoss).set_as_boss()
	boss.global_position = _arena_rect.get_center()
	boss._arena_rect = _arena_rect
	boss.initialize(_player)
	if boss.has_method("configure_encounter"):
		boss.configure_encounter(_stage_depth)
	boss.apply_scaling(_hp_mult * 3.0, _speed_mult * 0.8, _damage_mult * 1.5, _gold_mult * 3.0)
	_enemies_alive += 1
	RunTelemetry.enemy_spawned("boss:" + _boss_region)

func force_complete() -> void:
	_suppress_split_spawns = true
	_spawn_generation += 1
	_pending_split_fragments = 0
	_pending_boss_add_requests.clear()
	_spawned_count = _total_budget
	_stage_timer = 0.0
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if e.get_parent() != self:
			continue
		if e.has_method("is_alive") and e.is_alive() and e.has_method("take_damage"):
			e.take_damage(99999.0)
	_spawned_count = _total_budget
	_stage_timer = 0.0
	_enemies_alive = 0
	_suppress_split_spawns = false
	_complete_stage()

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
	for request in _pending_boss_add_requests.keys():
		var pending: Dictionary = _pending_boss_add_requests[request]
		if pending.source_id == enemy.get_instance_id():
			_pending_split_fragments -= int(pending.count)
			_pending_boss_add_requests.erase(request)
	if enemy.get_meta("cleanses_boss_poison", false):
		for hazard: Node in get_tree().get_nodes_in_group("boss_poison"):
			if hazard.get_parent() == self and not hazard.is_queued_for_deletion():
				hazard.clear_at(enemy.global_position, 160.0)
		enemy.remove_meta("cleanses_boss_poison")
	var role: String = enemy.get_meta("spawn_role", "")
	if not role.is_empty():
		_active_role_counts[role] = maxi(0, get_active_role_count(role) - 1)
		enemy.remove_meta("spawn_role")
	_return_to_pool(enemy)
	_enemies_alive -= 1
	var can_spawn := _stage_timer > 0.0 and _spawned_count < _total_budget
	if not can_spawn and _enemies_alive <= 0 and _pending_split_fragments == 0:
		_complete_stage()

func get_stage_timer() -> float:
	return maxf(_stage_timer, 0.0)

func get_active_role_count(role: String) -> int:
	return int(_active_role_counts.get(role, 0))

func get_remaining_enemies() -> int:
	return _enemies_alive + _pending_split_fragments + (maxi(0, _total_budget - _spawned_count) if _stage_timer > 0.0 else 0)

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
