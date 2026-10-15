class_name ArtifactCatalog
extends RefCounted

const IDS: Array[String] = [
	"furnace_heart",
	"ashen_needle",
	"cinder_crown",
	"fractured_prism",
	"echoing_hourglass",
	"bloodwritten_sigil",
]

const ARTIFACTS: Dictionary = {
	"furnace_heart": preload("res://resources/artifacts/furnace_heart.tres"),
	"ashen_needle": preload("res://resources/artifacts/ashen_needle.tres"),
	"cinder_crown": preload("res://resources/artifacts/cinder_crown.tres"),
	"fractured_prism": preload("res://resources/artifacts/fractured_prism.tres"),
	"echoing_hourglass": preload("res://resources/artifacts/echoing_hourglass.tres"),
	"bloodwritten_sigil": preload("res://resources/artifacts/bloodwritten_sigil.tres"),
}

const SETS: Dictionary = {
	"covenant_of_embers": preload("res://resources/artifact_sets/covenant_of_embers.tres"),
}

static func all_ids() -> Array[String]:
	return IDS.duplicate()

static func get_artifact(id: String) -> ArtifactResource:
	return ARTIFACTS.get(id) as ArtifactResource

static func get_set(set_id: String) -> SetBonusResource:
	return SETS.get(set_id) as SetBonusResource
