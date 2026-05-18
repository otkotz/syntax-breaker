class_name SupportResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var required_tags: Array[String] = []
@export var excluded_tags: Array[String] = []
@export var stat_modifiers: Dictionary = {}
@export var added_tags: Array[String] = []
@export var behavior_key: String = ""
@export var icon: Texture2D
@export var rarity: String = "common"
@export_multiline var description: String = ""

func is_universal() -> bool:
	return required_tags.is_empty()
