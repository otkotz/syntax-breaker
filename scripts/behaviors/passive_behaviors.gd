class_name PassiveBehaviors
extends RefCounted

static func has_passive(passive_id: String) -> bool:
	for p: Resource in RunManager.owned_passives:
		if p is PassiveResource and p.id == passive_id:
			return true
	return false

static func has_ring_of_fire() -> bool:
	return has_passive("ring_of_fire")

static func has_trigger_on_death() -> bool:
	return has_passive("trigger_on_death")
