class_name SkillCaster
extends Node2D

var skill_instances: Array[SkillInstance] = []
var _cooldown_timers: Array[float] = []
var _pools: Dictionary = {}
var _active_totems: Array[SkillTotem] = []
var _active_mines: Array[SkillMine] = []

const MAX_TOTEMS := 2
const MAX_MINES := 5

func set_skills(instances: Array[SkillInstance]) -> void:
	skill_instances = instances
	_cooldown_timers.resize(instances.size())
	_cooldown_timers.fill(0.0)
	_setup_pools()

func _setup_pools() -> void:
	for si in skill_instances:
		if si.base.scene_path.is_empty():
			continue
		if _pools.has(si.base.scene_path):
			continue
		var scene := load(si.base.scene_path) as PackedScene
		if scene:
			_pools[si.base.scene_path] = ObjectPool.new(scene, 10, self)

func _physics_process(delta: float) -> void:
	for i in skill_instances.size():
		_cooldown_timers[i] -= delta
		if _cooldown_timers[i] <= 0.0:
			if _try_cast(skill_instances[i]):
				_cooldown_timers[i] = skill_instances[i].computed_stats.get("cooldown", 1.0)

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

	var direction := global_position.direction_to(target.global_position)
	var count: int = si.computed_stats.get("projectile_count", 1)
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
	_schedule_echoes(si, direction, target)
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
					var echo_dir := global_position.direction_to(echo_target.global_position)
					var count: int = si.computed_stats.get("projectile_count", 1)
					if count <= 1:
						_spawn_skill(si, echo_dir, echo_target)
					else:
						var spread := deg_to_rad(15.0) * (count - 1)
						for j in count:
							var offset := -spread / 2.0 + spread / (count - 1) * j
							_spawn_skill(si, echo_dir.rotated(offset), echo_target)
		)

func _spawn_skill(si: SkillInstance, direction: Vector2, _target: Node2D) -> void:
	if si.base.scene_path.is_empty():
		return
	var pool: ObjectPool = _pools.get(si.base.scene_path)
	if pool == null:
		return

	var projectile := pool.get_instance()
	projectile.global_position = global_position

	if projectile.has_method("initialize"):
		projectile.initialize(si, direction, pool)

	if projectile.has_method("set_orbit_parent"):
		projectile.set_orbit_parent(get_parent())
		_redistribute_orbit_offsets(pool)

	si.notify_spawn(projectile)

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
	get_tree().current_scene.add_child(totem)
	totem.tree_exiting.connect(func(): _active_totems.erase(totem))
	_active_totems.append(totem)
	CombatLog.skill_cast(si.base.name + " (Totem)", 1)
	return true

func _place_mine(si: SkillInstance) -> bool:
	_clean_mines()
	while _active_mines.size() >= MAX_MINES:
		_active_mines[0].queue_free()
		_active_mines.remove_at(0)

	var mine := SkillMine.new()
	mine.setup(si, global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30)))
	get_tree().current_scene.add_child(mine)
	mine.tree_exiting.connect(func(): _active_mines.erase(mine))
	_active_mines.append(mine)
	CombatLog.skill_cast(si.base.name + " (Mine)", 1)
	return true

func _clean_totems() -> void:
	_active_totems = _active_totems.filter(func(t: SkillTotem): return is_instance_valid(t))

func _clean_mines() -> void:
	_active_mines = _active_mines.filter(func(m: SkillMine): return is_instance_valid(m))

func _redistribute_orbit_offsets(pool: ObjectPool) -> void:
	var active := pool.get_active()
	var count := active.size()
	for i in count:
		if active[i].has_method("set_angle_offset"):
			active[i].set_angle_offset(i * TAU / count)
