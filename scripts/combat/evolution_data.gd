class_name EvolutionData
extends RefCounted

const BY_SKILL := {
	"fireball": {"id": "solar_flare", "name": "Solar Flare"},
	"flame_wave": {"id": "firewall_breach", "name": "Firewall Breach"},
	"frost_nova": {"id": "absolute_zero", "name": "Absolute Zero"},
	"lightning_bolt": {"id": "cloud_outage", "name": "Cloud Outage"},
	"poison_dart": {"id": "ransomware", "name": "Ransomware"},
	"static_field": {"id": "daemon_process", "name": "Daemon Process"},
	"blade_spin": {"id": "recursive_rollback", "name": "Recursive Rollback"},
}

static func get_for_skill(skill_id: String) -> Dictionary:
	return BY_SKILL.get(skill_id, {}).duplicate(true)

static func is_valid_for_skill(skill_id: String, evolution_id: String) -> bool:
	return BY_SKILL.has(skill_id) and BY_SKILL[skill_id].id == evolution_id
