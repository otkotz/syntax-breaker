class_name BossProjectileVolley
extends Node

const PROJECTILE_SCENE := preload("res://scenes/enemies/enemy_projectile.tscn")
const MAX_ACTIVE := 36

static func spawn(parent: Node, origin: Vector2, target: Vector2, pattern: String, count: int,
		speed: float, damage: float, source: String) -> Array[EnemyProjectile]:
	var result: Array[EnemyProjectile] = []
	if not is_instance_valid(parent):
		return result
	var pool := parent.get_node_or_null("BossProjectilePool") as ObjectPool
	if not pool:
		pool = ObjectPool.new(PROJECTILE_SCENE, 0, parent)
		pool.name = "BossProjectilePool"
	var available := mini(count, MAX_ACTIVE - pool.active_count())
	if available <= 0:
		return result
	var safe_origin := origin
	if parent.get("_arena_rect") is Rect2:
		var arena: Rect2 = parent.get("_arena_rect")
		safe_origin = origin.clamp(arena.position + Vector2(18, 18), arena.end - Vector2(18, 18))
	var base_angle := safe_origin.angle_to_point(target)
	for index in available:
		var angle := base_angle
		if pattern == "spiral":
			angle += TAU * float(index) / float(available)
		else:
			var spread := PI * 0.7
			angle += 0.0 if available == 1 else lerpf(-spread * 0.5, spread * 0.5, float(index) / float(available - 1))
		var projectile := pool.get_instance() as EnemyProjectile
		if not projectile:
			continue
		projectile.max_range = 900.0
		projectile.initialize(Vector2.from_angle(angle), speed, damage, safe_origin, pool, source)
		result.append(projectile)
	return result
