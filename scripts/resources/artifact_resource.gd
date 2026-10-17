class_name ArtifactResource
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var region_id: String = "burning_grounds"
@export var behavior_key: String = ""
@export var behavior_parameters: Dictionary = {}
@export var set_id: String = ""
@export var set_piece_name: String = ""
@export var source_tags: Array[String] = []
@export var minimum_difficulty: int = 1
@export var is_chase: bool = false
@export var duplicate_shard_value: int = 5
