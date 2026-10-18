class_name ExpeditionProfile
extends RefCounted

const FORGE := preload("res://scripts/expedition/ember_forge.gd")

const SCHEMA_VERSION := 6
const REWARD_HISTORY_LIMIT := 100

var character_id: String = "breaker"
var level: int = 1
var experience: int = 0
var unlocked_regions: Array[String] = ["burning_grounds"]
var owned_artifact_ids: Array[String] = ArtifactCatalog.all_ids()
var equipped_artifact_ids: Array[String] = ["", "", "", ""]
var ember_shards: int = 0
var discovered_artifact_ids: Array[String] = []
var pity_counters: Dictionary = {}
var settled_reward_ids: Array[String] = []
var reward_history: Array[Dictionary] = []
var forge_commitments: Dictionary = {}
var discovered_synergy_ids: Array[String] = []
var bloodwritten_fragments: int = 0
var selected_sigil_variant: String = ""

static func fresh() -> ExpeditionProfile:
	var profile := ExpeditionProfile.new()
	profile.owned_artifact_ids.clear()
	return profile

func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"character_id": character_id,
		"level": level,
		"experience": experience,
		"unlocked_regions": unlocked_regions,
		"owned_artifact_ids": owned_artifact_ids,
		"equipped_artifact_ids": equipped_artifact_ids,
		"ember_shards": ember_shards,
		"discovered_artifact_ids": discovered_artifact_ids,
		"pity_counters": pity_counters,
		"settled_reward_ids": settled_reward_ids,
		"reward_history": reward_history,
		"forge_commitments": forge_commitments,
		"discovered_synergy_ids": discovered_synergy_ids,
		"bloodwritten_fragments": bloodwritten_fragments,
		"selected_sigil_variant": selected_sigil_variant,
	}

static func from_dict(data: Dictionary) -> ExpeditionProfile:
	var profile := ExpeditionProfile.new()
	if typeof(data.get("schema_version")) not in [TYPE_INT, TYPE_FLOAT]:
		return profile
	var schema_version := int(data.get("schema_version"))
	if schema_version not in [1, 2, 3, 4, 5, SCHEMA_VERSION]:
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
	if schema_version >= 2:
		profile.owned_artifact_ids.clear()
		var raw_owned: Variant = data.get("owned_artifact_ids", [])
		if raw_owned is Array:
			for value: Variant in raw_owned:
				if value is String and not value.is_empty() and not profile.owned_artifact_ids.has(value):
					profile.owned_artifact_ids.append(value)
	profile.equipped_artifact_ids = ArtifactLoadout.normalize(
		profile.owned_artifact_ids,
		data.get("equipped_artifact_ids", []) if schema_version >= 2 else []
	)
	if schema_version == 2:
		for artifact_id: String in profile.owned_artifact_ids:
			if ArtifactCatalog.get_artifact(artifact_id) != null:
				profile.discovered_artifact_ids.append(artifact_id)
	elif schema_version >= 3:
		profile.discovered_artifact_ids = _unique_strings(data.get("discovered_artifact_ids", []))
		if typeof(data.get("ember_shards")) in [TYPE_INT, TYPE_FLOAT]:
			profile.ember_shards = maxi(0, int(data.get("ember_shards")))
		var raw_pity: Variant = data.get("pity_counters", {})
		if raw_pity is Dictionary:
			for key: Variant in raw_pity:
				var pity_key := str(key)
				var value: Variant = raw_pity[key]
				if not pity_key.is_empty() and typeof(value) in [TYPE_INT, TYPE_FLOAT]:
					profile.pity_counters[pity_key] = maxi(0, int(value))
		profile.settled_reward_ids = _unique_strings(data.get("settled_reward_ids", []))
		var raw_history: Variant = data.get("reward_history", [])
		if raw_history is Array:
			var start := maxi(0, raw_history.size() - REWARD_HISTORY_LIMIT)
			for index: int in range(start, raw_history.size()):
				if raw_history[index] is Dictionary:
					profile.reward_history.append((raw_history[index] as Dictionary).duplicate(true))
	if schema_version >= 4 and data.get("forge_commitments", {}) is Dictionary:
		for id: String in FORGE.ids():
			if bool(data.get("forge_commitments", {}).get(id, false)): profile.forge_commitments[id] = true
	if schema_version >= 5:
		profile.discovered_synergy_ids = _unique_strings(data.get("discovered_synergy_ids", []))
	if schema_version >= 6:
		profile.bloodwritten_fragments = maxi(0, int(data.get("bloodwritten_fragments", 0))) if typeof(data.get("bloodwritten_fragments", 0)) in [TYPE_INT, TYPE_FLOAT] else 0
		var variant := str(data.get("selected_sigil_variant", ""))
		var omen := preload("res://scripts/expedition/blood_omen.gd")
		if not omen.get_variant(variant).is_empty(): profile.selected_sigil_variant = variant
	return profile

static func _unique_strings(raw_values: Variant) -> Array[String]:
	var result: Array[String] = []
	if not raw_values is Array:
		return result
	for value: Variant in raw_values:
		if value is String and not value.is_empty() and not result.has(value):
			result.append(value)
	return result
