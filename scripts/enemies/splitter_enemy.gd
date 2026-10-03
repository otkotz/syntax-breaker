extends EnemyBase

func _setup_sprite() -> void:
	pass

func _die() -> void:
	# Register offspring before the death signal can complete the arena.
	if get_parent().has_method("spawn_split_children"):
		get_parent().spawn_split_children(self)
	super._die()

func _draw() -> void:
	var color := Color(0.65, 1.0, 0.15)
	draw_circle(Vector2(-9, -13), 16.0, color)
	draw_circle(Vector2(9, -13), 16.0, color)
	draw_line(Vector2(0, -30), Vector2(0, 4), Color(0.1, 0.2, 0.03), 3.0)
	draw_circle(Vector2(-9, -17), 3.0, Color(0.1, 0.2, 0.03))
	draw_circle(Vector2(9, -17), 3.0, Color(0.1, 0.2, 0.03))
	super._draw()
