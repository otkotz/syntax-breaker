class_name DamageNumber
extends Node2D

var amount: float = 0.0
var is_crit: bool = false
var is_player_damage: bool = false
var _tween: Tween

static var _pool: Array[DamageNumber] = []
static var _active: Array[DamageNumber] = []
const MAX_ACTIVE := 30

static func spawn(parent: Node, pos: Vector2, dmg: float, crit: bool = false, player_dmg: bool = false) -> void:
	var instance: DamageNumber
	while _pool.size() > 0:
		var candidate: DamageNumber = _pool.pop_back()
		if is_instance_valid(candidate):
			instance = candidate
			break
	if not instance:
		_active = _active.filter(func(n: DamageNumber) -> bool: return is_instance_valid(n))
		if _active.size() >= MAX_ACTIVE:
			var oldest := _active[0]
			oldest._force_recycle()
			while _pool.size() > 0:
				var candidate2: DamageNumber = _pool.pop_back()
				if is_instance_valid(candidate2):
					instance = candidate2
					break
		if not instance:
			instance = DamageNumber.new()

	instance.amount = dmg
	instance.is_crit = crit
	instance.is_player_damage = player_dmg
	instance.global_position = pos
	instance.modulate.a = 1.0
	instance.scale = Vector2.ONE
	instance.visible = true
	_active.append(instance)

	if not instance.is_inside_tree():
		parent.add_child(instance)
	elif instance.get_parent() != parent:
		instance.reparent(parent, false)
	instance._animate()

func _force_recycle() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
	visible = false
	_active.erase(self)
	_pool.append(self)

func _animate() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	visible = true
	queue_redraw()
	var combo_scale := clampf(ComboTracker.current_multiplier, 1.0, 1.5)
	_tween = create_tween()
	_tween.set_parallel(true)
	var rise := -50.0 if not is_crit else -70.0
	_tween.tween_property(self, "position", position + Vector2(randf_range(-15, 15), rise), 0.6)
	_tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.2)
	if is_crit:
		_tween.tween_property(self, "scale", Vector2(0.7, 0.7) * combo_scale, 0.4).from(Vector2(1.3, 1.3) * combo_scale)
	elif combo_scale > 1.05:
		_tween.tween_property(self, "scale", Vector2.ONE * combo_scale, 0.3).from(Vector2(1.1, 1.1) * combo_scale)
	_tween.chain().tween_callback(_on_animation_done)

func _on_animation_done() -> void:
	_tween = null
	visible = false
	_active.erase(self)
	_pool.append(self)

func _draw() -> void:
	var text := str(roundi(amount))
	if is_crit:
		text += "!"
	var font := ThemeDB.fallback_font
	var font_size := 48 if is_crit else 36
	var color := Color.RED if is_player_damage else (Color.YELLOW if is_crit else Color.WHITE)
	if ComboTracker.current_multiplier > 1.2:
		color = color.lerp(Color(1.0, 0.5, 0.1), clampf((ComboTracker.current_multiplier - 1.2) / 0.8, 0.0, 1.0))
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := Vector2(-text_size.x / 2, 0)
	font.draw_string(get_canvas_item(), pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
	font.draw_string(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)
