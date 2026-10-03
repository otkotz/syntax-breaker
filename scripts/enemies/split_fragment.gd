extends EnemyBase

const ACTIVATION_WARNING := 1.0
var activation_remaining: float = ACTIVATION_WARNING

func _setup_sprite() -> void:
	pass

func initialize(target: Node2D) -> void:
	super.initialize(target)
	activation_remaining = ACTIVATION_WARNING
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	queue_redraw()

func reset() -> void:
	super.reset()
	activation_remaining = ACTIVATION_WARNING
	collision_layer = 0
	collision_mask = 0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if activation_remaining > 0.0:
		_update_slow(delta)
		activation_remaining = maxf(0.0, activation_remaining - delta)
		if activation_remaining == 0.0:
			collision_layer = 2
			collision_mask = 5
		queue_redraw()
		return
	super._physics_process(delta)

func _draw() -> void:
	var color := Color(0.65, 1.0, 0.15)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -25), Vector2(10, -13), Vector2(0, -1), Vector2(-10, -13)]), color)
	if activation_remaining > 0.0:
		draw_arc(Vector2.ZERO, 28.0, 0, TAU, 24, color, 2.0)
		draw_arc(Vector2.ZERO, 28.0 * (1.0 - activation_remaining / ACTIVATION_WARNING), 0, TAU, 24, color, 2.0)
	if get_meta("cleanses_boss_poison", false):
		var cleanse_color := Color(0.2, 1.0, 0.8)
		draw_line(Vector2(-5, -13), Vector2(5, -13), cleanse_color, 3.0)
		draw_line(Vector2(0, -18), Vector2(0, -8), cleanse_color, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-24, -50), "CLEANSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, cleanse_color)
	super._draw()
