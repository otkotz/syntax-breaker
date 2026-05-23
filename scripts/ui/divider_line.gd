class_name DividerLine
extends Control

var line_color := Color(0.38, 0.30, 0.19)
var diamond_color := Color(0.56, 0.45, 0.28)

func _draw() -> void:
	var cx := size.x / 2.0
	var cy := size.y / 2.0
	var hw := size.x * 0.3
	draw_line(Vector2(cx - hw, cy), Vector2(cx - 8, cy), line_color, 1.0)
	draw_line(Vector2(cx + 8, cy), Vector2(cx + hw, cy), line_color, 1.0)
	var pts := PackedVector2Array([
		Vector2(cx, cy - 6), Vector2(cx + 6, cy),
		Vector2(cx, cy + 6), Vector2(cx - 6, cy),
	])
	draw_colored_polygon(pts, diamond_color)
