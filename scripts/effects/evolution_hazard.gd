class_name EvolutionHazard
extends Node2D

static var active_count := 0

var kind := "sun"
var tier := 1
var radius := 90.0
var duration := 2.5
var pulse_interval := 0.5
var skill: SkillInstance
var context: AttackContext
var _elapsed := 0.0
var _pulse_elapsed := 0.0
var _registered := false

static func spawn(parent: Node, position: Vector2, hazard_kind: String, owner_skill: SkillInstance,
		attack_context: AttackContext, hazard_tier: int) -> Node2D:
	if not parent or not AttackContext.can_spawn_child("evolution_hazard", active_count, QualitySettings.projectile_cap):
		return null
	var hazard := new()
	hazard.kind = hazard_kind
	hazard.skill = owner_skill
	hazard.context = attack_context
	hazard.tier = clampi(hazard_tier, 1, 3)
	hazard.global_position = position
	match hazard_kind:
		"sun":
			hazard.radius = 85.0 + hazard.tier * 15.0
			hazard.duration = 2.0 + hazard.tier * 0.5
		"lightning_rod":
			hazard.radius = 120.0 + hazard.tier * 20.0
			hazard.duration = 3.0
		"firewall":
			hazard.radius = 75.0 + hazard.tier * 15.0
			hazard.duration = 2.0 + hazard.tier
	parent.add_child(hazard)
	return hazard

func _ready() -> void:
	if not _registered:
		active_count += 1
		_registered = true
	add_to_group("evolution_hazards")
	add_to_group("evolution_%s" % kind)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	_pulse_elapsed += delta
	if _pulse_elapsed >= pulse_interval:
		_pulse_elapsed = 0.0
		_pulse()
	if _elapsed >= duration:
		if kind == "sun" and tier >= 3:
			_damage_nearby(radius * 1.7, 0.8)
		queue_free()
	queue_redraw()

func _pulse() -> void:
	match kind:
		"sun": _damage_nearby(radius, 0.2 if tier == 1 else 0.32)
		"lightning_rod": _damage_nearby(radius, 0.18 if tier == 1 else 0.3)
		"firewall": _damage_nearby(radius, 0.22 + tier * 0.06)

func _damage_nearby(effect_radius: float, multiplier: float) -> void:
	if not skill:
		return
	var damage := float(skill.computed_stats.get("damage", 8.0)) * multiplier
	for enemy: Node2D in Targeting.find_enemies_in_range(global_position, effect_radius, 8):
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, false, skill.base, "proc")
		if kind == "firewall" and enemy.has_method("apply_dot"):
			enemy.apply_dot("burn", damage * 0.35, 2.0, 0.5, skill.base)

func _draw() -> void:
	var fade := clampf(1.0 - _elapsed / duration, 0.0, 1.0)
	match kind:
		"sun":
			draw_circle(Vector2.ZERO, 15.0 + tier * 3.0, Color(1.0, 0.55, 0.08, 0.7 * fade))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.82, 0.2, 0.45 * fade), 3.0)
		"lightning_rod":
			draw_line(Vector2(0, -24), Vector2(0, 24), Color(0.4, 0.8, 1.0, fade), 5.0)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.45, 0.75, 1.0, 0.22 * fade), 2.0)
		"firewall":
			draw_rect(Rect2(-radius, -8, radius * 2.0, 16), Color(1.0, 0.24, 0.06, 0.55 * fade))

func _exit_tree() -> void:
	if _registered:
		active_count = maxi(0, active_count - 1)
		_registered = false
