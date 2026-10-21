class_name SkillVisualRenderer
extends Node2D

const MAX_SEGMENTS := 20

@export var profile: SkillVisualProfile
var primary_support_id := ""
var support_signature: StringName = &""
var evolution_signature: StringName = &""
var hero_duration := 0.0
var punch_remaining := 0.0
var punch_duration := 0.10
var _hero_budgeted := false


func configure(value: SkillVisualProfile, support_ids: Array[String], evolution_tier: int) -> void:
	profile = value
	var modifier := SupportVisualModifier.first_supported(support_ids)
	primary_support_id = str(modifier.get("support_id", ""))
	support_signature = modifier.get("signature", &"")
	evolution_signature = StringName("tier_%d" % evolution_tier) if evolution_tier > 0 else &""
	hero_duration = 0.0
	punch_remaining = 0.0 if QualitySettings.reduced_motion else punch_duration
	scale = Vector2.ONE if QualitySettings.reduced_motion else Vector2.ONE * 0.82
	if evolution_tier >= 3:
		evolution_signature = &"tier_3_hero"
		hero_duration = 0.12
		_hero_budgeted = CombatVisualBudget.request(&"hero_moment", 3, get_instance_id())
	set_process(_hero_budgeted or punch_remaining > 0.0)
	queue_redraw()


func _process(delta: float) -> void:
	hero_duration = maxf(0.0, hero_duration - delta)
	punch_remaining = maxf(0.0, punch_remaining - delta)
	if punch_remaining > 0.0:
		var progress := 1.0 - punch_remaining / punch_duration
		scale = Vector2.ONE * lerpf(0.82, 1.0, ease(progress, 2.0))
	else:
		scale = Vector2.ONE
	if hero_duration <= 0.0 and _hero_budgeted:
		CombatVisualBudget.release(&"hero_moment", get_instance_id())
		_hero_budgeted = false
	if hero_duration <= 0.0 and punch_remaining <= 0.0:
		set_process(false)
	queue_redraw()


func _exit_tree() -> void:
	if _hero_budgeted:
		CombatVisualBudget.release(&"hero_moment", get_instance_id())


func _draw() -> void:
	if profile == null:
		return
	match profile.core_shape:
		&"hooked_bracket":
			draw_arc(Vector2.ZERO, 15.0, -2.4, 0.55, 12, profile.primary_color, 3.0)
			draw_polyline(PackedVector2Array([Vector2(9, 10), Vector2(20, 7), Vector2(14, -2)]), profile.accent_color, 3.0)
		&"compressed_square":
			draw_rect(Rect2(-7, -7, 14, 14), profile.primary_color, true)
			draw_polyline(PackedVector2Array([Vector2(-5, -1), Vector2.ZERO, Vector2(5, -4)]), profile.accent_color, 2.0)
		&"four_anchor_perimeter":
			for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
				var center := Vector2.from_angle(angle) * 22.0
				draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), profile.accent_color)
		&"jagged_trace":
			draw_polyline(PackedVector2Array([Vector2(-20, 8), Vector2(-8, -5), Vector2(-2, 2), Vector2(8, -14), Vector2(5, -2), Vector2(20, -9)]), profile.primary_color, 3.0)
			for point in [Vector2(-20, 8), Vector2(-2, 2), Vector2(20, -9)]: draw_circle(point, 2.5, profile.accent_color)
		&"needle":
			draw_polyline(PackedVector2Array([Vector2(-19, 5), Vector2(16, -5), Vector2(21, -1)]), profile.primary_color, 3.0)
			for x in [-10.0, 0.0, 10.0]: draw_circle(Vector2(x, 9), 2.0, profile.accent_color)
		&"broken_firewall":
			for x in [-20.0, -7.0, 8.0]: draw_polyline(PackedVector2Array([Vector2(x, 12), Vector2(x + 3, -10), Vector2(x + 9, 12)]), profile.primary_color, 3.0)
		&"hollow_hex_fracture":
			var points := PackedVector2Array()
			for i in 7: points.append(Vector2.from_angle(i * TAU / 6.0) * 20.0)
			draw_polyline(points, profile.primary_color, 3.0)
			for i in 6:
				var p := Vector2.from_angle(i * TAU / 6.0) * 20.0
				draw_line(p, p * 1.35, profile.accent_color, 2.0)
	_draw_support()


func _draw_support() -> void:
	match support_signature:
		&"network_nodes":
			for point in [Vector2(-14, -12), Vector2(0, -17), Vector2(14, -12)]: draw_circle(point, 2.5, Color.WHITE)
		&"reverse_arrow":
			draw_polyline(PackedVector2Array([Vector2(12, 15), Vector2(0, 20), Vector2(5, 12)]), Color(1, 0.2, 0.8), 2.0)
		&"offset_outline":
			draw_arc(Vector2(4, 3), 19.0, -2.4, 0.55, 12, Color(0.7, 0.8, 1, 0.45), 2.0)
		&"closing_diamond":
			draw_polyline(PackedVector2Array([Vector2(0, -22), Vector2(22, 0), Vector2(0, 22), Vector2(-22, 0), Vector2(0, -22)]), Color(1, 0.75, 0.2, 0.8), 2.0)
		&"transmitter_brackets":
			draw_arc(Vector2.ZERO, 21.0, -0.7, 0.7, 6, Color(0.4, 1, 0.9), 2.0)
			draw_arc(Vector2.ZERO, 21.0, PI - 0.7, PI + 0.7, 6, Color(0.4, 1, 0.9), 2.0)
		&"duck_marker":
			draw_circle(Vector2(0, -22), 4.0, Color(1, 0.9, 0.1))
			draw_rect(Rect2(3, -23, 4, 2), Color(1, 0.5, 0.05))
