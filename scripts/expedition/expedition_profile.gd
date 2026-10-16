class_name ExpeditionProfile
extends RefCounted

const SCHEMA_VERSION := 2

var character_id: String = "breaker"
var level: int = 1
var experience: int = 0
var unlocked_regions: Array[String] = ["burning_grounds"]
var owned_artifact_ids: Array[String] = ArtifactCatalog.all_ids()
var equipped_artifact_ids: Array[String] = ["", "", "", ""]

func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"character_id": character_id,
		"level": level,
		"experience": experience,
		"unlocked_regions": unlocked_regions,
		"owned_artifact_ids": owned_artifact_ids,
		"equipped_artifact_ids": equipped_artifact_ids,
	}

static func from_dict(data: Dictionary) -> ExpeditionProfile:
	var profile := ExpeditionProfile.new()
	if typeof(data.get("schema_version")) not in [TYPE_INT, TYPE_FLOAT]:
		return profile
	var schema_version := int(data.get("schema_version"))
	if schema_version not in [1, SCHEMA_VERSION]:
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
	if schema_version == SCHEMA_VERSION:
		profile.owned_artifact_ids.clear()
		var raw_owned: Variant = data.get("owned_artifact_ids", [])
		if raw_owned is Array:
			for value: Variant in raw_owned:
				if value is String and not value.is_empty() and not profile.owned_artifact_ids.has(value):
					profile.owned_artifact_ids.append(value)
	profile.equipped_artifact_ids = ArtifactLoadout.normalize(
		profile.owned_artifact_ids,
		data.get("equipped_artifact_ids", []) if schema_version == SCHEMA_VERSION else []
	)
	return profile
