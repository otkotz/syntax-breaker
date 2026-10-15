class_name ExpeditionProfile
extends RefCounted

const SCHEMA_VERSION := 1

var character_id: String = "breaker"
var level: int = 1
var experience: int = 0
var unlocked_regions: Array[String] = ["burning_grounds"]

func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"character_id": character_id,
		"level": level,
		"experience": experience,
		"unlocked_regions": unlocked_regions,
	}

static func from_dict(data: Dictionary) -> ExpeditionProfile:
	var profile := ExpeditionProfile.new()
	if typeof(data.get("schema_version")) not in [TYPE_INT, TYPE_FLOAT] \
		or int(data.get("schema_version")) != SCHEMA_VERSION:
		return profile
	if data.get("character_id") is String and not str(data.get("character_id")).is_empty():
		profile.character_id = data.get("character_id")
	if typeof(data.get("level")) in [TYPE_INT, TYPE_FLOAT]:
		profile.level = maxi(1, int(data.get("level")))
	if typeof(data.get("experience")) in [TYPE_INT, TYPE_FLOAT]:
		profile.experience = maxi(0, int(data.get("experience")))
	var regions: Variant = data.get("unlocked_regions", [])
	if not regions is Array:
		regions = []
	for region: Variant in regions:
		var region_id := str(region)
		if not region_id.is_empty() and not profile.unlocked_regions.has(region_id):
			profile.unlocked_regions.append(region_id)
	if not profile.unlocked_regions.has("burning_grounds"):
		profile.unlocked_regions.append("burning_grounds")
	return profile
