class_name AoeSkillBase
extends Area2D

var skill_instance: SkillInstance
var damage: float = 10.0
var area_radius: float = 100.0
var pool_ref: ObjectPool
var _lifetime: float = 0.3
var _timer: float = 0.0
var _has_hit: bool = false
var _color: Color = Color(1.0, 0.9, 0.6, 0.35)
var _sprite: Sprite2D

static var _circle_texture: ImageTexture
static var _circle_offset: Vector2

func _ready() -> void:
	if not _circle_texture:
		var data := PixelSprite.build_circle_texture(100.0, Color.WHITE)
		_circle_texture = data["texture"]
		_circle_offset = data["offset"]
	_sprite = Sprite2D.new()
	_sprite.texture = _circle_texture
	_sprite.offset = _circle_offset
	add_child(_sprite)

func initialize(si: SkillInstance, _direction: Vector2, pool: ObjectPool) -> void:
	skill_instance = si
	damage = si.computed_stats.get("damage", 10.0)
	area_radius = si.computed_stats.get("range", 100.0) * si.computed_stats.get("area_mult", 1.0)
	pool_ref = pool
	_timer = 0.0
	_has_hit = false
	_color = TagColors.get_color_faded(si.base.tags)
	scale = Vector2.ONE * (area_radius / 100.0)
	if _sprite:
		_sprite.modulate = _color

func _physics_process(delta: float) -> void:
	_timer += delta
	if not _has_hit:
		_has_hit = true
		_hit_enemies()
	if _timer >= _lifetime:
		_return_to_pool()

func _hit_enemies() -> void:
	var enemies := Targeting.find_enemies_in_range(global_position, area_radius, 50)
	var kill_count := 0
	var tags: Array = skill_instance.get_all_tags() if skill_instance else []
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var hit_damage := damage
			var is_crit := false
			if skill_instance:
				var roll := CombatUtils.roll_damage(damage, skill_instance)
				hit_damage = roll["damage"]
				is_crit = roll["is_crit"]
				if is_crit:
					RunManager.record_stat("crits_landed", 1)
			var skill_name := skill_instance.base.name if skill_instance else "unknown"
			enemy.take_damage(hit_damage, is_crit)
			CombatLog.hit(skill_name, enemy.name, hit_damage, is_crit)
			if enemy.has_method("apply_dot"):
				if tags.has("fire"):
					enemy.apply_dot("burn", hit_damage * 0.2, 2.0, 0.5)
					CombatLog.dot_applied("burn", enemy.name, hit_damage * 0.2, 2.0)
			GameBus.enemy_hit.emit(enemy, hit_damage, skill_instance.base if skill_instance else null)
			if skill_instance:
				TagInteractions.process_hit(enemy, hit_damage, tags, self)
				skill_instance.notify_hit(enemy, self)
				if enemy.has_method("is_alive") and not enemy.is_alive():
					CombatLog.kill(skill_name, enemy.name)
					skill_instance.notify_kill(enemy, self)
					kill_count += 1
	if kill_count > RunManager.run_stats.get("max_aoe_kill", 0):
		RunManager.run_stats["max_aoe_kill"] = kill_count

func reset() -> void:
	skill_instance = null
	pool_ref = null
	_timer = 0.0
	_has_hit = false
	scale = Vector2.ONE

func _return_to_pool() -> void:
	if pool_ref:
		pool_ref.release(self)
