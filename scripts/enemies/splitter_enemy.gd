extends EnemyBase

const SPLITTER_TEXTURE := preload("res://assets/sprites/enemies/splitter-v1.png")

func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = SPLITTER_TEXTURE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2.ONE * 0.055
	_sprite.position = Vector2(0, -17)
	add_child(_sprite)

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
