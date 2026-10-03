class_name CosmeticStyles
extends RefCounted

const DEFAULTS := {"player": "player_default", "projectile": "projectile_default"}
const DEFINITIONS := [
	{"id": "player_default", "kind": "player", "name": "Original Cloak", "challenge": "", "description": "Original cloak palette."},
	{"id": "silver_cloak", "kind": "player", "name": "Silver Cloak", "challenge": "no_healing", "description": "Complete Unpatched. Changes cloak shading only; elemental accents remain unchanged."},
	{"id": "verdant_cloak", "kind": "player", "name": "Verdant Cloak", "challenge": "mine_only", "description": "Complete Mine Specialist. Changes cloak shading only; elemental accents remain unchanged."},
	{"id": "projectile_default", "kind": "projectile", "name": "Original Trails", "challenge": "", "description": "Original projectile rendering."},
	{"id": "faceted_trails", "kind": "projectile", "name": "Faceted Trails", "challenge": "two_elements", "description": "Complete Dual Compiler. Diamond-shaped trails; projectile cores and elemental colours stay unchanged."},
]

static func definition(id: String) -> Dictionary:
	for entry in DEFINITIONS:
		if entry.id == id:
			return entry
	return {}

static func is_unlocked(id: String) -> bool:
	var entry := definition(id)
	return not entry.is_empty() and (entry.challenge.is_empty() or MetaProgression.completed_challenges.has(entry.challenge))

static func selected(kind: String) -> String:
	var id := str(MetaProgression.selected_cosmetics.get(kind, DEFAULTS.get(kind, "")))
	var entry := definition(id)
	if entry.is_empty() or entry.kind != kind or not is_unlocked(id):
		return str(DEFAULTS.get(kind, ""))
	return id

static func player_palette(element: String, preview_id: String = "") -> PackedColorArray:
	var palette := BreakerSprite.palette(element)
	var ramp: Array[String] = []
	match selected("player") if preview_id.is_empty() else preview_id:
		"silver_cloak": ramp.assign(["14151E", "292C3B", "49546A", "708396"])
		"verdant_cloak": ramp.assign(["061C19", "0C332B", "195244", "347962"])
	for index in ramp.size():
		palette[2 + index] = Color.html(ramp[index])
	return palette
