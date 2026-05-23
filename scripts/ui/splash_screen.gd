class_name SplashScreen
extends Control

signal finished

var _timer: float = 0.0
var _glitch_start: float = -1.0
var _done: bool = false
var _logo_tex: Texture2D

const DISPLAY_DURATION := 2.0
const GLITCH_DURATION := 0.7
const SLICE_COUNT := 24

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	_logo_tex = preload("res://assets/sprites/logo.png")

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= DISPLAY_DURATION and _glitch_start < 0.0:
		_glitch_start = _timer
	if _glitch_start > 0.0 and _timer >= _glitch_start + GLITCH_DURATION and not _done:
		_done = true
		finished.emit()
	queue_redraw()

func _draw() -> void:
	var vp := size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.012, 0.031))

	if not _logo_tex:
		return

	var tex_size := Vector2(_logo_tex.get_width(), _logo_tex.get_height())
	var target_w := vp.x * 0.88
	var sc: float = target_w / tex_size.x
	var scaled := tex_size * sc
	var logo_pos := Vector2((vp.x - scaled.x) / 2.0, vp.y * 0.5 - scaled.y * 0.55)

	var fade_in: float = clampf(_timer / 0.5, 0.0, 1.0)
	var glitch_t := 0.0
	if _glitch_start > 0.0:
		glitch_t = clampf((_timer - _glitch_start) / GLITCH_DURATION, 0.0, 1.0)

	if glitch_t > 0.0:
		_draw_glitched(logo_pos, scaled, tex_size, glitch_t)
	else:
		var pulse: float = 0.97 + 0.03 * sin(_timer * 2.5)
		var ps := scaled * pulse
		var pp := logo_pos + (scaled - ps) * 0.5
		draw_texture_rect(_logo_tex, Rect2(pp, ps), false, Color(1, 1, 1, fade_in))
		if _timer > 0.8:
			_draw_micro_glitch(logo_pos, scaled, tex_size)

	_draw_scanlines(vp, fade_in * 0.08)

	var tag_alpha: float = clampf((_timer - 1.0) / 0.5, 0.0, 1.0) * (1.0 - glitch_t)
	if tag_alpha > 0.01:
		_draw_tagline(vp, logo_pos.y + scaled.y + 40.0, tag_alpha)

	if glitch_t > 0.4:
		var fade_out: float = (glitch_t - 0.4) / 0.6
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.012, 0.031, fade_out))

func _draw_micro_glitch(logo_pos: Vector2, scaled: Vector2, tex_size: Vector2) -> void:
	if randf() > 0.08:
		return
	var slice_h := scaled.y / SLICE_COUNT
	var tex_slice_h := tex_size.y / SLICE_COUNT
	var idx := randi() % SLICE_COUNT
	var offset_x: float = randf_range(-20.0, 20.0)
	var src := Rect2(0, tex_slice_h * idx, tex_size.x, tex_slice_h)
	var dst := Rect2(logo_pos + Vector2(offset_x, slice_h * idx), Vector2(scaled.x, slice_h))
	draw_texture_rect_region(_logo_tex, dst, src, Color(0.7, 0.9, 1.0, 0.6))

func _draw_glitched(logo_pos: Vector2, scaled: Vector2, tex_size: Vector2, t: float) -> void:
	var vp := size
	var intensity: float = t * t * 1.5
	var slice_h := scaled.y / SLICE_COUNT
	var tex_slice_h := tex_size.y / SLICE_COUNT

	for i in SLICE_COUNT:
		var src := Rect2(0, tex_slice_h * i, tex_size.x, tex_slice_h)
		var offset_x := 0.0
		if randf() < intensity:
			offset_x = randf_range(-120.0, 120.0) * intensity
		var dst_pos := logo_pos + Vector2(offset_x, slice_h * i)
		var dst := Rect2(dst_pos, Vector2(scaled.x, slice_h))

		if randf() < intensity * 0.4:
			var sep: float = randf_range(5.0, 16.0) * intensity
			draw_texture_rect_region(_logo_tex, Rect2(dst_pos + Vector2(-sep, 0), dst.size), src, Color(1, 0.2, 0.2, 0.4))
			draw_texture_rect_region(_logo_tex, Rect2(dst_pos + Vector2(sep, 0), dst.size), src, Color(0.2, 0.2, 1, 0.4))

		var alpha: float = 1.0 - t * 0.5
		draw_texture_rect_region(_logo_tex, dst, src, Color(1, 1, 1, alpha))

	var bar_count := int(intensity * 18)
	for i in bar_count:
		var by: float = randf() * vp.y
		var bh: float = randf_range(1.0, 6.0)
		var bw: float = randf_range(vp.x * 0.3, vp.x)
		var bx: float = randf_range(-vp.x * 0.1, vp.x * 0.3)
		draw_rect(Rect2(bx, by, bw, bh),
			Color(randf_range(0.15, 0.35), randf_range(0.0, 0.08), randf_range(0.2, 0.45), randf_range(0.2, 0.6) * intensity))

	var px_count := int(intensity * 50)
	for i in px_count:
		var px: float = randf() * vp.x
		var py: float = randf() * vp.y
		var ps: float = randf_range(2.0, 5.0)
		draw_rect(Rect2(px, py, ps, ps), Color(1, 1, 1, randf_range(0.05, 0.3) * intensity))

func _draw_scanlines(vp: Vector2, alpha: float) -> void:
	if alpha < 0.005:
		return
	var y := 0.0
	while y < vp.y:
		draw_rect(Rect2(0, y, vp.x, 1), Color(0, 0, 0, alpha))
		y += 4.0

func _draw_tagline(vp: Vector2, y_pos: float, alpha: float) -> void:
	var font := ThemeDB.fallback_font
	var text := "BREAK THE SYSTEM. BECOME UNBOUND."
	var fs := 22
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
	var pos := Vector2((vp.x - text_size.x) / 2.0, y_pos)
	font.draw_string(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs,
		Color(UITheme.C_INK_MUTE, alpha))
