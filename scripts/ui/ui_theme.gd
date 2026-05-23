class_name UITheme

const C_BG := Color(0.02, 0.012, 0.031)
const C_BG_1 := Color(0.039, 0.024, 0.071)
const C_BG_2 := Color(0.063, 0.039, 0.110)
const C_PANEL_BG := Color(0.05, 0.03, 0.10, 0.65)

const C_V_DEEP := Color(0.118, 0.051, 0.251)
const C_V_BASE := Color(0.357, 0.129, 0.714)
const C_V_MID := Color(0.427, 0.157, 0.851)
const C_V_BRIGHT := Color(0.545, 0.361, 0.965)
const C_V_GLOW := Color(0.545, 0.361, 0.965, 0.45)
const C_V_LINE := Color(0.231, 0.106, 0.439)
const C_V_LINE_D := Color(0.165, 0.078, 0.333)

const C_SILVER := Color(0.90, 0.89, 0.93)
const C_SILVER_D := Color(0.78, 0.76, 0.82)
const C_INK := Color(0.90, 0.89, 0.93)
const C_INK_MUTE := Color(0.68, 0.67, 0.73)
const C_INK_LOW := Color(0.47, 0.45, 0.55)
const C_INK_FAINT := Color(0.33, 0.30, 0.40)

const C_CARD_BG := Color(0.05, 0.03, 0.10, 0.75)
const C_STAT_BG := Color(0.0, 0.0, 0.0, 0.3)

const C_STR := Color(0.75, 0.30, 0.18)
const C_DEX := Color(0.40, 0.78, 0.40)
const C_INT := Color(0.45, 0.55, 0.85)

static func style_button(btn: Button, font_size: int = 28) -> void:
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", C_SILVER)
	btn.add_theme_color_override("font_hover_color", C_V_BRIGHT)

	var ns := StyleBoxFlat.new()
	ns.bg_color = C_V_DEEP
	ns.border_color = C_V_LINE
	ns.set_border_width_all(2)
	ns.set_content_margin_all(12)
	btn.add_theme_stylebox_override("normal", ns)

	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.357, 0.129, 0.714, 0.5)
	hs.border_color = C_V_BRIGHT
	hs.set_border_width_all(2)
	hs.set_content_margin_all(12)
	btn.add_theme_stylebox_override("hover", hs)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.118, 0.051, 0.251, 0.8)
	ps.border_color = C_V_LINE
	ps.set_border_width_all(2)
	ps.set_content_margin_all(12)
	btn.add_theme_stylebox_override("pressed", ps)

static func style_panel(panel: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_CARD_BG
	sb.border_color = C_V_LINE
	sb.set_border_width_all(1)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)

static func style_label_title(lbl: Label, font_size: int = 48) -> void:
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", C_V_BRIGHT)

static func style_label_body(lbl: Label, font_size: int = 26) -> void:
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", C_INK_MUTE)
