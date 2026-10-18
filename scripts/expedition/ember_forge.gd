class_name EmberForge
extends RefCounted

const DEFINITIONS := {
	"treasure_choice": {"name": "TREASURE CHOICE", "cost": 20, "description": "Treasure reveals one deterministic alternative."},
	"discovery_ward": {"name": "DISCOVERY WARD", "cost": 30, "description": "The next elite or treasure excludes owned artifacts."},
	"covenant_mark": {"name": "COVENANT MARK", "cost": 25, "description": "The next Covenant reward selects a missing piece."},
}

static func ids() -> Array[String]:
	return ["treasure_choice", "discovery_ward", "covenant_mark"]

static func get_commitment(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {}).duplicate(true)
