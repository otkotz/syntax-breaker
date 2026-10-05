extends RefCounted

# Dashed countdown is harmless; solid borders and crosses mark active damage.
const WARNING_COLOR := Color(1.0, 0.82, 0.3)
const BACKING := Color(0.025, 0.025, 0.05, 0.95)
const ACTIVATION_TIME := 0.25

static func outline(canvas: Node2D, points: PackedVector2Array, remaining: float, duration: float, color: Color, flash: float = 0.0) -> void:
	var warning := remaining > 0.0
	var ink := WARNING_COLOR if warning else color.lightened(0.25)
	if flash > 0.0:
		ink = ink.lerp(Color.WHITE, flash / ACTIVATION_TIME)
	canvas.draw_polyline(points, BACKING, 6.0)
	if not warning:
		canvas.draw_polyline(points, ink, 3.5)
		return
	var perimeter := 0.0
	for i in points.size() - 1:
		perimeter += points[i].distance_to(points[i + 1])
	var progress_length := perimeter * clampf(1.0 - remaining / maxf(duration, 0.001), 0.0, 1.0)
	var walked := 0.0
	for i in points.size() - 1:
		var start := points[i]
		var end := points[i + 1]
		var length := start.distance_to(end)
		var direction := start.direction_to(end)
		var step := 0.0
		while step < length:
			canvas.draw_line(start + direction * step, start + direction * minf(step + 7.0, length), ink, 3.0)
			step += 12.0
		var completed := clampf(progress_length - walked, 0.0, length)
		if completed > 0.0:
			canvas.draw_line(start, start + direction * completed, Color.WHITE, 3.0)
		walked += length

static func circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 49:
		points.append(Vector2.from_angle(TAU * i / 48.0) * radius)
	return points

static func fill_color(color: Color, remaining: float, flash: float) -> Color:
	if remaining > 0.0:
		return Color(WARNING_COLOR, 0.07)
	return Color(color.lightened(flash / ACTIVATION_TIME * 0.5), 0.3 + 0.2 * flash / ACTIVATION_TIME)

static func badge(canvas: Node2D, pos: Vector2, remaining: float) -> void:
	var text := "%.1fs" % remaining if remaining > 0.0 else "ACTIVE"
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	canvas.draw_rect(Rect2(pos + Vector2(-width / 2.0 - 4, -12), Vector2(width + 8, 17)), BACKING)
	canvas.draw_string(font, pos + Vector2(-width / 2.0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, WARNING_COLOR if remaining > 0.0 else Color.WHITE)

static func active_mark(canvas: Node2D, pos: Vector2, color: Color) -> void:
	for direction in [Vector2(1, 1), Vector2(1, -1)]:
		canvas.draw_line(pos - direction * 4.0, pos + direction * 4.0, BACKING, 4.0)
		canvas.draw_line(pos - direction * 4.0, pos + direction * 4.0, color.lightened(0.3), 2.0)

static func safe_arrow(canvas: Node2D, pos: Vector2, angle: float) -> void:
	var direction := Vector2.from_angle(angle)
	var side := direction.orthogonal()
	canvas.draw_colored_polygon(PackedVector2Array([pos + direction * 12.0,
		pos - direction * 8.0 + side * 8.0, pos - direction * 8.0 - side * 8.0]), Color(0.2, 1.0, 0.8))
	canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-16, -16), "SAFE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 1.0, 0.8))
