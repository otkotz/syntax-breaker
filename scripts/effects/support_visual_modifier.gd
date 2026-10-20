class_name SupportVisualModifier
extends RefCounted

const DEFINITIONS := {
	"chain": {"signature": &"network_nodes", "duration": 0.18},
	"returning": {"signature": &"reverse_arrow", "duration": 0.20},
	"spell_echo": {"signature": &"offset_outline", "duration": 0.20},
	"mine": {"signature": &"closing_diamond", "duration": 0.22},
	"totem": {"signature": &"transmitter_brackets", "duration": 0.22},
	"rubber_duck_debugging": {"signature": &"duck_marker", "duration": 0.25},
}


static func definition_for(support_id: String) -> Dictionary:
	return (DEFINITIONS.get(support_id, {}) as Dictionary).duplicate()


static func first_supported(support_ids: Array[String]) -> Dictionary:
	for support_id in support_ids:
		var definition := definition_for(support_id)
		if not definition.is_empty():
			definition["support_id"] = support_id
			return definition
	return {}
