extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	var owned := ArtifactCatalog.all_ids()
	check(ArtifactLoadout.normalize(owned, null) == ["", "", "", ""], "Null slots normalize safely")
	check(ArtifactLoadout.normalize(owned, ["furnace_heart", "furnace_heart", "missing", "ashen_needle", "cinder_crown"]) == ["furnace_heart", "", "", "ashen_needle"], "Invalid, duplicate, and excess slots normalize")
	check(ArtifactLoadout.active_set_tiers(["furnace_heart", "ashen_needle", "", ""]) == {"covenant_of_embers": 2}, "Two set pieces activate tier two")
	check(ArtifactLoadout.active_set_tiers(["furnace_heart", "ashen_needle", "cinder_crown", ""]) == {"covenant_of_embers": 3}, "Three set pieces activate tiers through three")

	ExpeditionManager.profile_path = "res://.godot/artifact_loadout_profile.json"
	_cleanup()
	ExpeditionManager.start_new_profile()
	check(ExpeditionManager.equip_artifact("fractured_prism", 0), "Owned artifact equips")
	check(ExpeditionManager.profile.equipped_artifact_ids[0] == "fractured_prism", "Equip updates profile")
	check(not ExpeditionManager.equip_artifact("fractured_prism", 1), "Duplicate artifact is rejected")
	check(ExpeditionManager.unequip_artifact(0), "Artifact unequips")
	check(ExpeditionManager.profile.equipped_artifact_ids[0].is_empty(), "Unequip clears slot")
	ExpeditionManager.session = ExpeditionSession.create(77, "burning_grounds")
	check(not ExpeditionManager.equip_artifact("fractured_prism", 0), "Active expedition locks equip API")
	check(not ExpeditionManager.unequip_artifact(0), "Active expedition locks unequip API")
	ExpeditionManager.session = null
	var before := ExpeditionManager.profile.equipped_artifact_ids.duplicate()
	ExpeditionManager.profile_path = "res://missing_directory/profile.json"
	check(not ExpeditionManager.equip_artifact("bloodwritten_sigil", 2), "Failed save reports failure")
	check(ExpeditionManager.profile.equipped_artifact_ids == before, "Failed save rolls profile back")
	_cleanup()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _cleanup() -> void:
	for path in ["res://.godot/artifact_loadout_profile.json", "res://.godot/artifact_loadout_profile.json.tmp", "res://.godot/artifact_loadout_profile.json.bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
