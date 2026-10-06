class_name SkillMine
extends Area2D

var skill_instance: SkillInstance
var _lifetime: float = 15.0
var _timer: float = 0.0
var _detonated := false
var _damage: float = 10.0
var _radius: float = 80.0
var _color: Color = Color(0.8, 0.2, 0.2)

func setup(si: SkillInstance, pos: Vector2) -> void:
	skill_instance = si
	global_position = pos
	_damage = si.computed_stats.get("damage", 10.0) * 1.5
	_radius = si.computed_stats.get("range", 100.0) * si.computed_stats.get("area_mult", 1.0) * 0.5
	_color = TagColors.get_color(si.get_all_tags())

	collision_layer = 4
	collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= _lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _detonated:
		return
	if not body.is_in_group("enemies"):
		return
	_detonate()

func _detonate() -> void:
	_detonated = true
	if skill_instance and skill_instance.get_all_tags().has("beam"):
		_fire_laser_payload()
		queue_free()
		return
	var enemies := Targeting.find_enemies_in_range(global_position, _radius, 20)
	for enemy: Node2D in enemies:
		if enemy.has_method("take_damage"):
			var was_alive: bool = not enemy.has_method("is_alive") or enemy.is_alive()
			var roll := CombatUtils.roll_damage(_damage, skill_instance) if skill_instance else {"damage": _damage, "is_crit": false}
			enemy.take_damage(roll["damage"], roll["is_crit"], skill_instance.base if skill_instance else null)
			if skill_instance:
				skill_instance.notify_hit(enemy, self)
				if was_alive and enemy.has_method("is_alive") and not enemy.is_alive():
					skill_instance.notify_kill(enemy, self)
	if skill_instance:
		CombatLog.interaction("Mine", "", "detonated %.1f in radius %.0f, hit %d" % [_damage, _radius, enemies.size()])
	queue_free()

func _fire_laser_payload() -> void:
	var target := Targeting.find_nearest_enemy(global_position, skill_instance.computed_stats.get("range", 400.0))
	if not target:
		return
	var direction := global_position.direction_to(target.global_position)
	var count: int = skill_instance.computed_stats.get("projectile_count", 1)
	if count <= 1:
		SkillLaser.fire(self, skill_instance, direction)
	else:
		var spread := deg_to_rad(15.0) * (count - 1)
		for i in count:
			var offset := -spread / 2.0 + spread / (count - 1) * i
			SkillLaser.fire(self, skill_instance, direction.rotated(offset))
	CombatLog.skill_cast(skill_instance.base.name + " (Mine Laser)", count)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, _color * Color(1, 1, 1, 0.6))
	draw_arc(Vector2.ZERO, 30.0, 0, TAU, 32, _color * Color(1, 1, 1, 0.3), 1.0)
