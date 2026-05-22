class_name PassiveResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var affected_tags: Array[String] = []
@export var stat_modifiers: Dictionary = {}
@export var rarity: String = "common"
@export var behavior_key: String = ""
@export_multiline var description: String = ""

func is_global() -> bool:
	return affected_tags.is_empty()
