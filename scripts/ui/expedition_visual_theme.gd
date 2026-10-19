class_name ExpeditionVisualTheme
extends RefCounted

const SMOKE := Color(0.035, 0.03, 0.04, 0.94)
const ASH := Color(0.72, 0.69, 0.65)
const EMBER := Color(1.0, 0.38, 0.08)
const BLOOD := Color(0.78, 0.08, 0.12)
const COPPER := Color(0.68, 0.35, 0.16)
const UNKNOWN := Color(0.25, 0.24, 0.27)

const SOURCE_ICONS := {
	"elite": preload("res://assets/icons/expedition/source-elite-v1.png"),
	"treasure": preload("res://assets/icons/expedition/source-treasure-v1.png"),
	"boss": preload("res://assets/icons/expedition/source-boss-v1.png"),
	"boss_set": preload("res://assets/icons/expedition/source-boss-v1.png"),
	"boss_chase": preload("res://assets/icons/expedition/source-boss-v1.png"),
}

static func make_frame(accent: Color = EMBER) -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.bg_color = SMOKE
	frame.border_color = accent
	frame.set_border_width_all(2)
	frame.content_margin_left = 12.0
	frame.content_margin_top = 10.0
	frame.content_margin_right = 12.0
	frame.content_margin_bottom = 10.0
	return frame

static func source_icon(source_tag: String) -> Texture2D:
	return SOURCE_ICONS.get(source_tag, SOURCE_ICONS["treasure"]) as Texture2D

static func source_label(source_tag: String) -> String:
	match source_tag:
		"elite": return "ELITE"
		"boss", "boss_set", "boss_chase": return "BOSS"
		_: return "TREASURE"
