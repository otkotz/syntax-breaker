class_name BuildPortrait
extends Control

var loadout: Dictionary = {}

func _init() -> void:
	custom_minimum_size = Vector2(192, 192)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(value: Dictionary) -> void:
	loadout = value.duplicate(true)
	queue_redraw()

func _draw() -> void:
	var element := str(loadout.get("element", "physical"))
	var colors: Dictionary = BreakerSprite.ELEMENTS.get(element, BreakerSprite.ELEMENTS.physical)
	var glow: Color = Color.html(str(colors.glow))
	var mid: Color = Color.html(str(colors.mid))
	draw_circle(Vector2(96, 92), 76, Color(0.025, 0.012, 0.055, 0.94))
	draw_arc(Vector2(96, 92), 74, -2.7, 0.45, 28, Color(glow, 0.65), 4.0)
	# Authored bust: broad cloak, unmistakable hood and dark face opening.
	var cloak := PackedVector2Array([Vector2(35, 184), Vector2(48, 112), Vector2(69, 89), Vector2(123, 89), Vector2(145, 112), Vector2(158, 184)])
	draw_colored_polygon(cloak, Color("25103d"))
	draw_polyline(cloak, Color("09020f"), 7.0)
	draw_circle(Vector2(96, 75), 48, Color("351758"))
	draw_circle(Vector2(96, 80), 33, Color("08030e"))
	draw_circle(Vector2(84, 80), 4, Color.html(str(colors.bright)))
	draw_circle(Vector2(108, 80), 4, Color.html(str(colors.bright)))
	if loadout.get("layers", []).has("emblem"):
		draw_circle(Vector2(96, 137), 13, Color("711622")); draw_arc(Vector2(96, 137), 17, 0, TAU, 12, Color("ff5264"), 3)
	if loadout.get("layers", []).has("focus"):
		draw_circle(Vector2(151, 125), 14, Color(glow, 0.8)); draw_circle(Vector2(151, 125), 6, mid)
	if loadout.get("layers", []).has("back"):
		draw_arc(Vector2(96, 116), 57, -2.5, -0.55, 14, Color("e45b27"), 6)
