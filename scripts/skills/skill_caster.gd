class_name SkillCaster
extends Node2D

signal spell_cast

var skill_instances: Array[SkillInstance] = []
var _cooldown_timers: Array[float] = []
var _pools: Dictionary = {}
var _active_totems: Array[SkillTotem] = []
var _active_mines: Array[SkillMine] = []
var artifact_hooks: ArtifactCombatHooks
var _last_cast_projectiles: Array[Node2D] = []
var _last_cast_direction := Vector2.ZERO
var _last_cast_target: Node2D
var _last_cast_origin := Vector2.ZERO

const MAX_TOTEMS := 2
const MAX_MINES := 5

func set_skills(instances: Array[SkillInstance]) -> void:
	skill_instances = instances
	_cooldown_timers.resize(instances.size())
	_cooldown_timers.fill(0.0)
	_setup_pools()
	_bind_on_death_recast()

func _setup_pools() -> void:
	for si in skill_instances:
		if si.base.scene_path.is_empty():
			continue
		if _pools.has(si.base.scene_path):
			continue
		var scene := load(si.base.scene_path) as PackedScene
		if scene:
			_pools[si.base.scene_path] = ObjectPool.new(scene, 10, self)

var _consumable_manager: ConsumableManager

func _physics_process(delta: float) -> void:
	if not _consumable_manager:
		_consumable_manager = _find_consumable_manager()
	var cd_mult := _consumable_manager.get_cooldown_mult() if _consumable_manager else 1.0
	for i in skill_instances.size():
		_cooldown_timers[i] -= delta
		if _cooldown_timers[i] <= 0.0:
			_last_cast_projectiles.clear()
			_last_cast_direction = Vector2.ZERO
			_last_cast_target = null
			_last_cast_origin = global_position
			if _try_cast(skill_instances[i]):
				if artifact_hooks != null and artifact_hooks.active:
					artifact_hooks.emit_event(&"skill_cast", {"skill": skill_instances[i], "player": get_parent(),
						"projectiles": _last_cast_projectiles.duplicate(), "world_position": global_position,
						"spawn_echo": _spawn_artifact_echo.bind(skill_instances[i], _last_cast_direction,
							_last_cast_target, _last_cast_origin)})
				var tempo_mult := EngineTracker.get_tempo_cooldown_mult()
				_cooldown_timers[i] = skill_instances[i].computed_stats.get("cooldown", 1.0) * cd_mult * tempo_mult
				EngineTracker.on_cast(skill_instances[i].base.id)
				spell_cast.emit()

func _find_consumable_manager() -> ConsumableManager:
	var nodes := get_tree().get_nodes_in_group("consumable_manager")
	if nodes.size() > 0:
		return nodes[0] as ConsumableManager
	return null

func _try_cast(si: SkillInstance) -> bool:
	if si.computed_stats.get("is_totem", 0) > 0:
		return _place_totem(si)
	if si.computed_stats.get("is_mine", 0) > 0:
		return _place_mine(si)

	var is_self_cast := si.base.has_tag("aoe") or si.base.has_tag("melee")

	if is_self_cast:
		if si.base.has_tag("melee"):
			var pool: ObjectPool = _pools.get(si.base.scene_path)
			if pool and pool.active_count() >= 3:
				return false
		CombatLog.skill_cast(si.base.name, 1)
		_spawn_skill(si, Vector2.ZERO, null)
		_schedule_echoes(si, Vector2.ZERO, null)
		return true

	var target := Targeting.find_nearest_enemy(global_position, si.computed_stats.get("range", 400.0))
	if target == null:
		return false
	if not si.get_all_tags().has("beam") and ProjectileBase.active_count >= QualitySettings.projectile_cap:
		return false

	var count: int = si.computed_stats.get("projectile_count", 1)

	if PassiveBehaviors.has_ring_of_fire() and si.base.has_tag("projectile"):
		for i in count:
			var angle := randf() * TAU
			_spawn_skill(si, Vector2.from_angle(angle), target)
	else:
		var direction := global_position.direction_to(Targeting.combat_aim_position(target))
		if count <= 1:
			_spawn_skill(si, direction, target)
		else:
			var spread := deg_to_rad(15.0) * (count - 1)
			for i in count:
				var angle_offset := -spread / 2.0 + spread / (count - 1) * i
				var dir := direction.rotated(angle_offset)
				_spawn_skill(si, dir, target)

	CombatLog.skill_cast(si.base.name, count)
	RunManager.record_stat("projectiles_fired", count)
	var aim_dir := global_position.direction_to(Targeting.combat_aim_position(target))
	_schedule_echoes(si, aim_dir, target)
	return true

func _schedule_echoes(si: SkillInstance, direction: Vector2, target: Node2D) -> void:
	var echoes: int = si.computed_stats.get("echo_count", 0)
	if echoes <= 0:
		return
	for i in echoes:
		var delay := 0.15 * (i + 1)
		get_tree().create_timer(delay).timeout.connect(func():
			if not is_instance_valid(self):
				return
			var is_self_cast := si.base.has_tag("aoe") or si.base.has_tag("melee")
			if is_self_cast:
				_spawn_skill(si, Vector2.ZERO, null)
			else:
				var echo_target := target if is_instance_valid(target) else Targeting.find_nearest_enemy(global_position, si.computed_stats.get("range", 400.0))
				if echo_target:
					var echo_dir := global_position.direction_to(Targeting.combat_aim_position(echo_target))
					var count: int = si.computed_stats.get("projectile_count", 1)
					if count <= 1:
						_spawn_skill(si, echo_dir, echo_target)
					else:
						var spread := deg_to_rad(15.0) * (count - 1)
						for j in count:
							var offset := -spread / 2.0 + spread / (count - 1) * j
							_spawn_skill(si, echo_dir.rotated(offset), echo_target)
		)

func _spawn_skill(si: SkillInstance, direction: Vector2, _target: Node2D,
		origin_flags: Array = [], generation: int = 0, spawn_position: Variant = null) -> void:
	if si.base.scene_path.is_empty():
		return
	if si.get_all_tags().has("beam"):
		RunManager.record_challenge_cast(false)
		SkillLaser.fire(self, si, direction)
		return
	if si.base.has_tag("projectile") and ProjectileBase.active_count >= QualitySettings.projectile_cap:
		return
	var pool: ObjectPool = _pools.get(si.base.scene_path)
	if pool == null:
		return

	var projectile := pool.get_instance()
	RunManager.record_challenge_cast(false)
	projectile.global_position = spawn_position if spawn_position is Vector2 else global_position

	if projectile.has_method("initialize"):
		projectile.initialize(si, direction, pool)
		projectile.artifact_hooks = artifact_hooks
		projectile.artifact_origin_flags = origin_flags.duplicate()
		projectile.artifact_generation = generation
		projectile.artifact_spawn_fragment = _spawn_artifact_fragment.bind(si, direction)
		_last_cast_projectiles.append(projectile)
		_last_cast_direction = direction
		_last_cast_target = _target
		_last_cast_origin = projectile.global_position

	if projectile.has_method("set_orbit_parent"):
		projectile.set_orbit_parent(get_parent())
		_redistribute_orbit_offsets(pool)

	si.notify_spawn(projectile)
	if artifact_hooks != null and artifact_hooks.active:
		artifact_hooks.emit_event(&"projectile_spawned", {"projectile": projectile, "skill": si, "world_position": projectile.global_position})

func set_artifact_hooks(value: ArtifactCombatHooks) -> void:
	artifact_hooks = value

func _spawn_artifact_echo(si: SkillInstance, direction: Vector2, target: Node2D, origin: Vector2) -> void:
	if artifact_hooks == null or not artifact_hooks.active: return
	_spawn_skill(si, direction, target if is_instance_valid(target) else null,
		["echoing_hourglass", "secondary_artifact_projectile"], 1, origin)

func _spawn_artifact_fragment(si: SkillInstance, base_direction: Vector2, data: Dictionary) -> void:
	var projectile_count_before := _last_cast_projectiles.size()
	_spawn_skill(si, base_direction.rotated(float(data.get("angle_offset", 0.0))), null,
		data.get("origin_flags", []), int(data.get("generation", 0)), data.get("world_position"))
	if _last_cast_projectiles.size() <= projectile_count_before: return
	var projectile: Node2D = _last_cast_projectiles.back()
	projectile.damage = float(data.get("damage", projectile.damage))

func _place_totem(si: SkillInstance) -> bool:
	var pool: ObjectPool = _pools.get(si.base.scene_path)
	if not pool:
		return false

	_clean_totems()
	while _active_totems.size() >= MAX_TOTEMS:
		_active_totems[0].queue_free()
		_active_totems.remove_at(0)

	var totem := SkillTotem.new()
	totem.setup(si, pool, global_position)
	_get_placement_parent().add_child(totem)
	totem.global_position = global_position
	totem.tree_exiting.connect(func(): _active_totems.erase(totem))
	_active_totems.append(totem)
	RunManager.record_challenge_cast(false)
	CombatLog.skill_cast(si.base.name + " (Totem)", 1)
	return true

func _place_mine(si: SkillInstance) -> bool:
	_clean_mines()
	while _active_mines.size() >= MAX_MINES:
		_active_mines[0].queue_free()
		_active_mines.remove_at(0)

	var mine := SkillMine.new()
	var placement := global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	mine.setup(si, placement)
	_get_placement_parent().add_child(mine)
	mine.global_position = placement
	mine.tree_exiting.connect(func(): _active_mines.erase(mine))
	_active_mines.append(mine)
	RunManager.record_challenge_cast(true)
	CombatLog.skill_cast(si.base.name + " (Mine)", 1)
	return true

func _get_placement_parent() -> Node:
	var ancestor := get_parent()
	while ancestor:
		if ancestor is Arena:
			return ancestor
		ancestor = ancestor.get_parent()
	return get_tree().current_scene

func _exit_tree() -> void:
	# Also clean standalone/test placements, where no Arena ancestor exists.
	for placement in _active_mines + _active_totems:
		if is_instance_valid(placement) and not placement.is_queued_for_deletion():
			placement.queue_free()

func _clean_totems() -> void:
	_active_totems = _active_totems.filter(func(t: SkillTotem): return is_instance_valid(t))

func _clean_mines() -> void:
	_active_mines = _active_mines.filter(func(m: SkillMine): return is_instance_valid(m))

func _bind_on_death_recast() -> void:
	for si: SkillInstance in skill_instances:
		si.trigger_on_death_recast = _on_death_recast

func _on_death_recast(si: SkillInstance, dead_enemy: Node2D) -> void:
	if si.base.scene_path.is_empty():
		return
	if ProjectileBase.active_count >= QualitySettings.projectile_cap:
		return
	var target := Targeting.find_nearest_enemy(global_position, si.computed_stats.get("range", 400.0))
	if target == null:
		return
	var dir := global_position.direction_to(Targeting.combat_aim_position(target))
	_spawn_skill(si, dir, target)

func _redistribute_orbit_offsets(pool: ObjectPool) -> void:
	var active := pool.get_active()
	var count := active.size()
	for i in count:
		if active[i].has_method("set_angle_offset"):
			active[i].set_angle_offset(i * TAU / count)
