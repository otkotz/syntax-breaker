class_name DamageNumber
extends Node2D

var amount: float = 0.0
var is_crit: bool = false

func _ready() -> void:
	var combo_scale := clampf(ComboTracker.current_multiplier, 1.0, 1.5)
	var tween := create_tween()
	tween.set_parallel(true)
	var rise := -50.0 if not is_crit else -70.0
	tween.tween_property(self, "position", position + Vector2(randf_range(-15, 15), rise), 0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.2)
	if is_crit:
		tween.tween_property(self, "scale", Vector2(0.7, 0.7) * combo_scale, 0.4).from(Vector2(1.3, 1.3) * combo_scale)
	elif combo_scale > 1.05:
		tween.tween_property(self, "scale", Vector2.ONE * combo_scale, 0.3).from(Vector2(1.1, 1.1) * combo_scale)
	tween.chain().tween_callback(queue_free)

func _draw() -> void:
	var text := str(roundi(amount))
	if is_crit:
		text += "!"
	var font := ThemeDB.fallback_font
	var font_size := 48 if is_crit else 36
	var color := Color.YELLOW if is_crit else Color.WHITE
	if ComboTracker.current_multiplier > 1.2:
		color = color.lerp(Color(1.0, 0.5, 0.1), clampf((ComboTracker.current_multiplier - 1.2) / 0.8, 0.0, 1.0))
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := Vector2(-text_size.x / 2, 0)
	font.draw_string(get_canvas_item(), pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
	font.draw_string(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)
