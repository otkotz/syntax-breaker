class_name CorpseBloomBehavior
extends BehaviorBase

const BASE_RADIUS := 70.0
const BASE_DAMAGE := 3.0
const DURATION := 2.0
const TICK := 0.5
const MAX_CLOUDS := 5
const MAX_Q_RADIUS := 100.0
const MAX_Q_DAMAGE := 5.0

static var _active_clouds: int = 0

func on_kill(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if not TriggerGuard.can_trigger(target):
		return
	if _active_clouds >= MAX_CLOUDS:
		return

	var tree := target.get_tree()
	if not tree:
		return
	var scene := tree.current_scene
	if not scene:
		return

	var radius := MAX_Q_RADIUS if is_mastered() else BASE_RADIUS
	var dmg := MAX_Q_DAMAGE if is_mastered() else BASE_DAMAGE

	TriggerGuard.begin(target)
	_active_clouds += 1

	var pos := target.global_position
	var enemies := Targeting.find_enemies_in_range(pos, radius, 15)
	for enemy: Node2D in enemies:
		if enemy == target:
			continue
		if enemy.has_method("apply_dot"):
			enemy.apply_dot("poison", dmg, DURATION, TICK)

	var cloud := _PoisonCloud.new()
	cloud.setup(radius, dmg, DURATION, TICK)
	cloud.tree_exiting.connect(func(): _active_clouds = maxi(0, _active_clouds - 1))
	scene.add_child(cloud)
	cloud.global_position = pos

	CombatLog.interaction("Corpse Bloom", target.name, "poison cloud r=%.0f" % radius)
	RunManager.record_stat("triggers_fired", 1)
	TriggerGuard.end()

static func reset_clouds() -> void:
	_active_clouds = 0


class _PoisonCloud extends Node2D:
	var _radius: float = 70.0
	var _damage: float = 3.0
	var _tick_interval: float = 0.5
	var _lifetime: float = 2.0
	var _timer: float = 0.0
	var _tick_timer: float = 0.0

	func setup(radius: float, damage: float, lifetime: float, tick: float) -> void:
		_radius = radius
		_damage = damage
		_lifetime = lifetime
		_tick_interval = tick

	func _process(delta: float) -> void:
		_timer += delta
		_tick_timer += delta
		if _tick_timer >= _tick_interval:
			_tick_timer = 0.0
			_apply_tick()
		queue_redraw()
		if _timer >= _lifetime:
			queue_free()

	func _apply_tick() -> void:
		var enemies := Targeting.find_enemies_in_range(global_position, _radius, 15)
		for enemy: Node2D in enemies:
			if enemy.has_method("apply_dot"):
				enemy.apply_dot("poison", _damage, 1.0, 0.5)

	func _draw() -> void:
		var fade := 1.0 - (_timer / _lifetime)
		var pulse := 0.7 + 0.3 * sin(_timer * 6.0)
		draw_circle(Vector2.ZERO, _radius, Color(0.49, 0.83, 0.29, 0.12 * fade * pulse))
		if _radius > 4.0:
			draw_arc(Vector2.ZERO, _radius, 0, TAU, 24, Color(0.49, 0.83, 0.29, 0.3 * fade), 2.0)
