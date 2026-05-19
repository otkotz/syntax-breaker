class_name DamageNumber
extends Node2D

var amount: float = 0.0
var is_crit: bool = false

func _ready() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	var rise := -40.0 if not is_crit else -55.0
	tween.tween_property(self, "position", position + Vector2(randf_range(-10, 10), rise), 0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.2)
	if is_crit:
		tween.tween_property(self, "scale", Vector2(0.7, 0.7), 0.4).from(Vector2(1.3, 1.3))
	tween.chain().tween_callback(queue_free)

func _draw() -> void:
	var text := str(roundi(amount))
	if is_crit:
		text += "!"
	var font := ThemeDB.fallback_font
	var font_size := 32 if is_crit else 24
	var color := Color.YELLOW if is_crit else Color.WHITE
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := Vector2(-text_size.x / 2, 0)
	font.draw_string(get_canvas_item(), pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)
	font.draw_string(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)
