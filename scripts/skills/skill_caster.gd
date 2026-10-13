class_name SkillCaster
extends Node2D

signal spell_cast

var skill_instances: Array[SkillInstance] = []
var _cooldown_timers: Array[float] = []
var _pools: Dictionary = {}
var _active_totems: Array[SkillTotem] = []
var _active_mines: Array[SkillMine] = []
var _shutting_down := false

const MAX_TOTEMS := 2
const MAX_MINES := 5

func set_skills(instances: Array[SkillInstance]) -> void:
	skill_instances = instances
	_cooldown_timers.resize(instances.size())
	_cooldown_timers.fill(0.0)
	_setup_pools()
	_bind_on_death_recast()
	for si: SkillInstance in skill_instances:
		si.request_recast = _request_recast.bind(si)

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
			if _try_cast(skill_instances[i]):
				var tempo_mult := EngineTracker.get_tempo_cooldown_mult()
				var works_mult := 0.7 if skill_instances[i].last_cast_metadata.get("works_mode", "") == "cooldown" else 1.0
				_cooldown_timers[i] = skill_instances[i].computed_stats.get("cooldown", 1.0) * cd_mult * tempo_mult * works_mult
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

	var is_self_cast := (si.base.has_tag("aoe") or si.base.has_tag("melee")) and not si.base.has_tag("projectile")
	var context := si.create_attack_context()

	if is_self_cast:
		if si.base.has_tag("melee"):
			var pool: ObjectPool = _pools.get(si.base.scene_path)
			if pool and pool.active_count() >= 3:
				return false
		CombatLog.skill_cast(si.base.name, 1)
		var cast := si.notify_cast(Vector2.ZERO, context, {})
		_spawn_skill(si, Vector2.ZERO, null, context)
		_schedule_echoes(si, Vector2.ZERO, null)
		return true

	var target := Targeting.find_nearest_enemy(global_position, si.computed_stats.get("range", 400.0))
	if target == null:
		return false
	if not si.get_all_tags().has("beam") and ProjectileBase.active_count >= QualitySettings.projectile_cap:
		return false

	var count: int = si.computed_stats.get("projectile_count", 1)
	var direction := global_position.direction_to(Targeting.combat_aim_position(target))
	var cast := si.notify_cast(direction, context, {})
	if cast.metadata.get("works_mode", "") == "projectiles":
		count += 1

	if PassiveBehaviors.has_ring_of_fire() and si.base.has_tag("projectile"):
		for i in count:
			var angle := randf() * TAU
			_spawn_skill(si, Vector2.from_angle(angle), target, context)
	else:
		if count <= 1:
			_spawn_skill(si, direction, target, context)
		else:
			var spread := deg_to_rad(15.0) * (count - 1)
			for i in count:
				var angle_offset := -spread / 2.0 + spread / (count - 1) * i
				var dir := direction.rotated(angle_offset)
				_spawn_skill(si, dir, target, context)

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
			var is_self_cast := (si.base.has_tag("aoe") or si.base.has_tag("melee")) and not si.base.has_tag("projectile")
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

func _spawn_skill(si: SkillInstance, direction: Vector2, _target: Node2D, context: AttackContext = null) -> void:
	if _shutting_down:
		return
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
	projectile.global_position = context.metadata.get("origin", global_position) if context else global_position

	if projectile.has_method("initialize"):
		if projectile is Rollback:
			projectile.initialize(si, direction, pool, context if context else si.create_attack_context())
			projectile.set_owner_node(get_parent())
		elif projectile is ProjectileBase:
			projectile.initialize(si, direction, pool, context if context else si.create_attack_context())
		elif projectile is AoeSkillBase:
			projectile.initialize(si, direction, pool, context if context else si.create_attack_context())
		else:
			projectile.initialize(si, direction, pool)

	if projectile.has_method("set_orbit_parent"):
		projectile.set_orbit_parent(get_parent())
		_redistribute_orbit_offsets(pool)

	si.notify_spawn(projectile)

func _request_recast(direction: Vector2, context: AttackContext, metadata: Dictionary, si: SkillInstance) -> void:
	if _shutting_down:
		return
	if not AttackContext.can_spawn_child("gameplay_effect", _active_gameplay_effect_count(), QualitySettings.projectile_cap):
		return
	var cast := si.notify_cast(direction, context, metadata)
	var count := 2 if cast.metadata.get("works_mode", "") == "projectiles" else 1
	for i in count:
		_spawn_skill(si, direction.rotated((i - (count - 1) * 0.5) * 0.18), null, context)

func _active_gameplay_effect_count() -> int:
	return ProjectileBase.active_count + Rollback.active_count + AoeSkillBase.active_count

func shutdown_for_cleanup() -> void:
	_shutting_down = true
	set_process(false)
	set_physics_process(false)
	for totem: SkillTotem in _active_totems:
		if is_instance_valid(totem):
			totem.queue_free()
	_active_totems.clear()
	for mine: SkillMine in _active_mines:
		if is_instance_valid(mine):
			mine.queue_free()
	_active_mines.clear()

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
