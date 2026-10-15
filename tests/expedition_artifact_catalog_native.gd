extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	var expected: Array[String] = [
		"furnace_heart", "ashen_needle", "cinder_crown",
		"fractured_prism", "echoing_hourglass", "bloodwritten_sigil",
	]
	check(ArtifactCatalog.all_ids() == expected, "Catalog exposes six stable ids")
	var seen: Dictionary = {}
	var set_pieces := 0
	for artifact_id in ArtifactCatalog.all_ids():
		var artifact := ArtifactCatalog.get_artifact(artifact_id)
		check(artifact != null, "Artifact %s loads" % artifact_id)
		if artifact == null:
			continue
		check(not seen.has(artifact.id), "Artifact id %s is unique" % artifact.id)
		seen[artifact.id] = true
		check(not artifact.display_name.is_empty(), "Artifact %s has a name" % artifact_id)
		check(not artifact.description.is_empty(), "Artifact %s has a description" % artifact_id)
		check(not artifact.behavior_key.is_empty(), "Artifact %s has a behavior key" % artifact_id)
		for parameter in artifact.behavior_parameters.values():
			check(parameter is int or parameter is float, "Artifact %s parameters are numeric" % artifact_id)
		if artifact.set_id == "covenant_of_embers":
			set_pieces += 1
	check(set_pieces == 3, "Exactly three artifacts belong to Covenant of Embers")
	check(ArtifactCatalog.get_artifact("missing") == null, "Unknown artifact is safe")
	var set_resource := ArtifactCatalog.get_set("covenant_of_embers")
	check(set_resource != null, "Covenant set loads")
	if set_resource != null:
		check(set_resource.behavior_parameters.get("stack_limit") == 5, "Set defines five burn stacks")
		check(set_resource.behavior_parameters.get("max_generations") == 2, "Set caps chain generations")
	check(ArtifactCatalog.get_set("missing") == null, "Unknown set is safe")
	print(JSON.stringify({"failures": failures, "ids": ArtifactCatalog.all_ids()}))
	get_tree().quit(0 if failures.is_empty() else 1)
