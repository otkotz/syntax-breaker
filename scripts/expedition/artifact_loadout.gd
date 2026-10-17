class_name ArtifactLoadout
extends RefCounted

const SLOT_COUNT := 4

static func normalize(owned: Array[String], raw: Variant) -> Array[String]:
	var result: Array[String] = ["", "", "", ""]
	if not raw is Array:
		return result
	for index in mini(SLOT_COUNT, raw.size()):
		var value: Variant = raw[index]
		var artifact_id := value as String if value is String else ""
		if not artifact_id.is_empty() and owned.has(artifact_id) and not result.has(artifact_id):
			result[index] = artifact_id
	return result

static func active_set_tiers(slots: Array[String]) -> Dictionary:
	var counts: Dictionary = {}
	for artifact_id in slots:
		var artifact := ArtifactCatalog.get_artifact(artifact_id)
		if artifact != null and not artifact.set_id.is_empty():
			counts[artifact.set_id] = int(counts.get(artifact.set_id, 0)) + 1
	var tiers: Dictionary = {}
	for set_id in counts:
		if int(counts[set_id]) >= 2:
			tiers[set_id] = mini(3, int(counts[set_id]))
	return tiers

static func normalize_snapshot(raw: Variant) -> Array[String]:
	var result: Array[String] = ["", "", "", ""]
	if not raw is Array: return result
	for index in mini(SLOT_COUNT, raw.size()):
		var value: Variant = raw[index]
		var artifact_id := value as String if value is String else ""
		if not artifact_id.is_empty() and not result.has(artifact_id): result[index] = artifact_id
	return result

static func apply_slot_overrides(base_ids: Variant, override_ids: Variant) -> Array[String]:
	var base := normalize_snapshot(base_ids)
	var overrides := normalize_snapshot(override_ids)
	var result := base.duplicate()
	for index in SLOT_COUNT:
		if overrides[index].is_empty():
			continue
		var duplicate_index := result.find(overrides[index])
		if duplicate_index >= 0 and duplicate_index != index:
			continue
		result[index] = overrides[index]
	return result
