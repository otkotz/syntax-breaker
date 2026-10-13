class_name FirewallHazard
extends Node2D

const MAX_ACTIVE := 6
const TICK_SECONDS := 0.35
static var active_count := 0

var start_point := Vector2.ZERO
var end_point := Vector2.ZERO
var damage := 0.0
var source: SkillResource
var duration := 4.0
var _elapsed := 0.0
var _tick := 0.0

static func spawn(parent: Node, from: Vector2, to: Vector2, tick_damage: float, skill: SkillResource) -> FirewallHazard:
	if not is_instance_valid(parent) or active_count >= MAX_ACTIVE:
		return null
	var wall := FirewallHazard.new()
	wall.top_level = true
	wall.start_point = from
	wall.end_point = to
	wall.damage = tick_damage
	wall.source = skill
	parent.add_child(wall)
	wall.add_to_group("stage_transient_hazards")
	active_count += 1
	return wall

func _process(delta: float) -> void:
	_elapsed += delta
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK_SECONDS
		_damage_crossing_enemies()
	queue_redraw()
	if _elapsed >= duration:
		queue_free()

func _damage_crossing_enemies() -> void:
	var midpoint := (start_point + end_point) * 0.5
	var search_radius := start_point.distance_to(end_point) * 0.5 + 36.0
	for enemy: Node2D in Targeting.find_enemies_in_range(midpoint, search_radius, 50):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start_point, end_point)
		if enemy.global_position.distance_to(closest) <= 28.0:
			enemy.take_damage(damage, false, source, "proc")

func _draw() -> void:
	var local_start := to_local(start_point)
	var local_end := to_local(end_point)
	var fade := clampf((duration - _elapsed) * 2.0, 0.0, 1.0)
	draw_line(local_start, local_end, Color(1.0, 0.18, 0.05, 0.45 * fade), 30.0)
	draw_line(local_start, local_end, Color(1.0, 0.78, 0.2, 0.9 * fade), 8.0)

func _exit_tree() -> void:
	active_count = maxi(0, active_count - 1)
