class_name SkillCaster
extends Node2D

var skill_instances: Array[SkillInstance] = []
var _cooldown_timers: Array[float] = []
var _pools: Dictionary = {}

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
	var is_self_cast := si.base.has_tag("aoe") or si.base.has_tag("melee")

	if is_self_cast:
		_spawn_skill(si, Vector2.ZERO, null)
		return true

	var target := Targeting.find_nearest_enemy(global_position, si.computed_stats.get("range", 400.0))
	if target == null:
		return false

	var direction := global_position.direction_to(target.global_position)
	_spawn_skill(si, direction, target)
	RunManager.record_stat("projectiles_fired", 1)
	return true

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

	si.notify_spawn(projectile)
