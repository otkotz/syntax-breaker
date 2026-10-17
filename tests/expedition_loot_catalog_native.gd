extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	check(ExpeditionLootCatalog.all_table_ids() == ["burning_elite", "burning_treasure", "burning_boss_set"],
		"Catalog exposes stable table ids")
	var elite := ExpeditionLootCatalog.get_table("burning_elite")
	var treasure := ExpeditionLootCatalog.get_table("burning_treasure")
	var boss := ExpeditionLootCatalog.get_table("burning_boss_set")
	check(elite != null and is_equal_approx(elite.drop_chance, 0.35) and elite.source_tag == "elite",
		"Elite table has the expected source and chance")
	check(treasure != null and is_equal_approx(treasure.drop_chance, 0.65) and treasure.source_tag == "treasure",
		"Treasure table has the expected source and chance")
	check(boss != null and is_equal_approx(boss.drop_chance, 1.0) and boss.source_tag == "boss_set",
		"Boss set table always drops")
	check(_equal_weights(elite.entries) and _equal_weights(treasure.entries) and _equal_weights(boss.entries),
		"Every first-slice pool uses equal entry weights")
	check(_ids(elite.entries) == ["fractured_prism", "echoing_hourglass"], "Elite pool contains discovery artifacts")
	check(_ids(treasure.entries) == ["fractured_prism", "echoing_hourglass"], "Treasure pool contains discovery artifacts")
	check(_ids(boss.entries) == ["furnace_heart", "ashen_needle", "cinder_crown"], "Boss pool contains set pieces")
	for artifact_id in ArtifactCatalog.all_ids():
		var artifact := ArtifactCatalog.get_artifact(artifact_id)
		check(artifact.minimum_difficulty == 1, "%s starts at difficulty one" % artifact_id)
		check(artifact.duplicate_shard_value == (15 if artifact_id == "bloodwritten_sigil" else 5),
			"%s has exact duplicate shard value" % artifact_id)
	var sigil := ArtifactCatalog.get_artifact("bloodwritten_sigil")
	check(sigil.is_chase and sigil.source_tags == ["boss_chase"], "Sigil is the boss-only chase artifact")
	check(ExpeditionLootCatalog.get_table("missing") == null, "Unknown table is safe")
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _equal_weights(entries: Array[Dictionary]) -> bool:
	if entries.is_empty(): return false
	var expected := float(entries[0].get("weight", 0.0))
	for entry in entries:
		if not is_equal_approx(float(entry.get("weight", 0.0)), expected): return false
	return expected > 0.0

func _ids(entries: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for entry in entries: result.append(str(entry.get("artifact_id", "")))
	return result
