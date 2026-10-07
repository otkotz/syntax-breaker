class_name SkillLaser
extends Node2D

const VISUAL_LIFETIME := 0.09
const COLLISION_MASK_ENEMIES := 2

var _end_local: Vector2 = Vector2.ZERO
var _color: Color = Color(0.55, 0.85, 1.0)
var _remaining: float = VISUAL_LIFETIME
var _cosmetic_style: String = "projectile_default"

static func create_visual(end_local: Vector2, color: Color) -> SkillLaser:
	var visual := SkillLaser.new()
	visual._end_local = end_local
	visual._color = color
	visual._cosmetic_style = CosmeticStyles.selected("projectile")
	return visual

static func fire(emitter: Node2D, skill_instance: SkillInstance, direction: Vector2) -> bool:
	if not is_instance_valid(emitter) or skill_instance == null or not emitter.is_inside_tree():
		return false
	var aim := direction.normalized()
	if aim == Vector2.ZERO:
		return false
	var max_range: float = skill_instance.computed_stats.get("range", 400.0)
	var origin := emitter.global_position
	var ray_end := origin + aim * max_range
	var query := PhysicsRayQueryParameters2D.create(origin, ray_end, COLLISION_MASK_ENEMIES)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := emitter.get_world_2d().direct_space_state.intersect_ray(query)
	var target := result.get("collider") as Node2D
	var hit := target != null and target.is_in_group("enemies") and target.has_method("take_damage")
	if hit:
		ray_end = result.get("position", target.global_position)

	var visual := create_visual(ray_end - origin, TagColors.get_color(skill_instance.get_all_tags()))
	var parent := emitter.get_tree().current_scene
	if parent == null:
		parent = emitter.get_parent()
	parent.add_child(visual)
	visual.global_position = origin
	visual._end_local = visual.to_local(ray_end)
	visual.queue_redraw()
	if hit:
		ProjectileBase.resolve_skill_hit(skill_instance, target, visual,
			float(skill_instance.computed_stats.get("damage", 10.0)))
	return hit

func _process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var alpha := clampf(_remaining / VISUAL_LIFETIME, 0.0, 1.0)
	draw_line(Vector2.ZERO, _end_local, Color(_color, 0.2 * alpha), 10.0)
	draw_line(Vector2.ZERO, _end_local, Color(_color, 0.85 * alpha), 4.0)
	draw_line(Vector2.ZERO, _end_local, Color(1.0, 1.0, 1.0, alpha), 1.5)
	if uses_cosmetic_style():
		var length := _end_local.length()
		var direction := _end_local.normalized()
		for distance in range(18, int(length), 24):
			var point := direction * distance
			if _cosmetic_style == "ember_trails":
				var side := direction.orthogonal() * 3.0
				draw_colored_polygon(PackedVector2Array([point - direction * 5.0, point + side, point + direction * 5.0, point - side]), Color(_color, 0.7 * alpha))
			elif _cosmetic_style == "void_trails":
				draw_arc(point, 4.0, 0, TAU, 10, Color(_color, 0.65 * alpha), 1.5)

func uses_cosmetic_style() -> bool:
	return _cosmetic_style in ["ember_trails", "void_trails", "faceted_trails"]
