extends EnemyBase

const WINDUP := 1.0
const CHARGE_TIME := 0.6
const CHARGE_SPEED := 360.0
var attack_state: String = "chase"
var attack_timer: float = 2.0
var charge_direction := Vector2.RIGHT

func _setup_sprite() -> void:
	pass

func get_contact_source() -> String:
	return get_enemy_id() + ":" + attack_state

func reset() -> void:
	super.reset()
	attack_state = "chase"
	attack_timer = 2.0
	charge_direction = Vector2.RIGHT
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		super._physics_process(delta)
		return
	attack_timer -= delta
	if attack_state == "chase":
		if attack_timer <= 0.0 and global_position.distance_to(_target.global_position) <= 200.0:
			charge_direction = global_position.direction_to(_target.global_position)
			attack_state = "windup"
			attack_timer = WINDUP
			velocity = Vector2.ZERO
			RunTelemetry.record("hazard_warning", {"source": get_enemy_id() + ":charge",
				"warning_seconds": WINDUP, "x": global_position.x, "y": global_position.y,
				"direction_x": charge_direction.x, "direction_y": charge_direction.y})
		else:
			super._physics_process(delta)
	else:
		_update_slow(delta)
		if attack_state == "windup" and attack_timer <= 0.0:
			attack_state = "charge"
			attack_timer = CHARGE_TIME
		elif attack_state == "charge":
			velocity = charge_direction * CHARGE_SPEED * _slow_factor * _get_consumable_slow()
			move_and_slide()
			_clamp_to_arena()
			_check_contact_damage()
			Targeting.update_position(self)
			if attack_timer <= 0.0:
				attack_state = "chase"
				attack_timer = 3.0
				velocity = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var center := Vector2(0, -13)
	var side := charge_direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		center + charge_direction * 22.0,
		center - charge_direction * 14.0 + side * 15.0,
		center - charge_direction * 14.0 - side * 15.0]), Color(1.0, 0.48, 0.08))
	if attack_state == "windup":
		var end := charge_direction * CHARGE_SPEED * CHARGE_TIME
		draw_line(Vector2.ZERO, end, Color(1.0, 0.5, 0.1, 0.2), 40.0)
		draw_line(side * 20.0, end + side * 20.0, Color.ORANGE, 3.0)
		draw_line(-side * 20.0, end - side * 20.0, Color.ORANGE, 3.0)
		draw_line(end - side * 20.0, end + side * 20.0, Color.ORANGE, 3.0)
	super._draw()
