class_name LootTableResource
extends Resource

@export var id: String = ""
@export var source_tag: String = ""
@export_range(0.0, 1.0) var drop_chance: float = 1.0
@export var entries: Array[Dictionary] = []
