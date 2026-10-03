class_name ArchetypeChallenges
extends RefCounted

const DEFINITIONS := [
	{"id": "mine_only", "name": "Mine Specialist", "description": "Win using only mine casts, with no unattributed damage. Skill-triggered DoT/procs are allowed."},
	{"id": "two_elements", "name": "Dual Compiler", "description": "Win dealing skill damage from exactly two base elements (fire, cold, lightning, poison), without physical or unattributed damage."},
	{"id": "no_healing", "name": "Unpatched", "description": "Win without recovering HP, including between-stage regeneration and auto-revive. Max-HP ratio changes are not healing."},
]
const ELEMENTS := ["fire", "cold", "lightning", "poison"]

static func evaluate(victory: bool, stats: Dictionary) -> Array[String]:
	var result: Array[String] = []
	# Missing historical evidence is not a successful challenge.
	if not victory or stats.get("challenge_tracking_version", 0) != 1 or float(stats.get("damage_dealt", 0)) <= 0:
		return result
	if float(stats.get("healing_received", 0)) == 0.0:
		result.append("no_healing")
	var fully_attributed := float(stats.get("unattributed_damage", 0)) == 0.0
	if fully_attributed and int(stats.get("mine_casts", 0)) > 0 and int(stats.get("non_mine_casts", 0)) == 0:
		result.append("mine_only")
	var elements: Array = stats.get("challenge_elements", [])
	if fully_attributed and elements.size() == 2 and not stats.get("challenge_non_elemental_damage", false):
		result.append("two_elements")
	return result

static func display_name(id: String) -> String:
	for definition in DEFINITIONS:
		if definition.id == id:
			return definition.name
	return id
