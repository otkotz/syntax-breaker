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
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return profile
	profile.character_id = str(data.get("character_id", "breaker"))
	profile.level = maxi(1, int(data.get("level", 1)))
	profile.experience = maxi(0, int(data.get("experience", 0)))
	for region: Variant in data.get("unlocked_regions", ["burning_grounds"]):
		var region_id := str(region)
		if not region_id.is_empty() and not profile.unlocked_regions.has(region_id):
			profile.unlocked_regions.append(region_id)
	if not profile.unlocked_regions.has("burning_grounds"):
		profile.unlocked_regions.append("burning_grounds")
	return profile
