extends EnemyBase

const GUARD_RADIUS := 150.0
var refresh_timer: float = 0.0
var linked_allies: Array[EnemyBase] = []

func _ready() -> void:
	super._ready()
	add_to_group("shield_supports")

func _setup_sprite() -> void:
	pass

func grants_guard(ally: EnemyBase) -> bool:
	return is_alive() and visible and is_instance_valid(_target) \
		and ally != self and ally.is_alive() and ally.get_parent() == get_parent() \
		and not ally.is_in_group("shield_supports") and not ally.is_in_group("bosses") \
		and global_position.distance_squared_to(ally.global_position) <= GUARD_RADIUS * GUARD_RADIUS

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target) or global_position.distance_to(_target.global_position) > 220.0:
		super._physics_process(delta)
	else:
		_update_slow(delta)
		velocity = Vector2.ZERO
	refresh_timer -= delta
	if refresh_timer <= 0.0:
		refresh_timer = 0.2
		_refresh_links()
	queue_redraw()

func _refresh_links() -> void:
	_clear_links()
	for child: Node in get_parent().get_children():
		if child is EnemyBase and grants_guard(child):
			linked_allies.append(child)
			child.queue_redraw()

func _clear_links() -> void:
	for ally in linked_allies:
		if is_instance_valid(ally):
			ally.queue_redraw()
	linked_allies.clear()

func _die() -> void:
	_clear_links()
	super._die()

func _exit_tree() -> void:
	_clear_links()

func reset() -> void:
	_clear_links()
	super.reset()
	refresh_timer = 0.0
	queue_redraw()

func _draw() -> void:
	var color := Color(0.15, 0.95, 0.95)
	draw_rect(Rect2(-17, -30, 34, 34), Color(0.04, 0.25, 0.3))
	draw_rect(Rect2(-17, -30, 34, 34), color, false, 3.0)
	draw_rect(Rect2(-5, -27, 10, 28), color)
	draw_rect(Rect2(-14, -18, 28, 10), color)
	if is_instance_valid(_target):
		draw_arc(Vector2.ZERO, GUARD_RADIUS, 0, TAU, 48, Color(color, 0.4), 2.0)
		for ally in linked_allies:
			if is_instance_valid(ally) and grants_guard(ally):
				draw_line(Vector2(0, -13), to_local(ally.global_position) + Vector2(0, -13), Color(color, 0.5), 2.0)
	super._draw()
