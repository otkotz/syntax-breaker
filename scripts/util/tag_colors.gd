class_name TagColors
extends RefCounted

const ELEMENT_COLORS := {
	"fire": Color(1.0, 0.4, 0.1),
	"lightning": Color(0.4, 0.7, 1.0),
	"poison": Color(0.3, 0.9, 0.2),
	"cold": Color(0.6, 0.9, 1.0),
	"physical": Color(0.8, 0.8, 0.8),
}

const DEFAULT_COLOR := Color(1.0, 0.8, 0.1)

static func get_color(tags: Array) -> Color:
	for tag: String in tags:
		if ELEMENT_COLORS.has(tag):
			return ELEMENT_COLORS[tag]
	return DEFAULT_COLOR

static func get_color_faded(tags: Array, alpha: float = 0.35) -> Color:
	var c := get_color(tags)
	c.a = alpha
	return c
