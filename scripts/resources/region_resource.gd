class_name RegionResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var bg_color: Color = Color(0.12, 0.12, 0.18)
@export var grid_color: Color = Color(0.18, 0.18, 0.25)
@export var border_color: Color = Color(0.4, 0.4, 0.5)
@export var enemy_tint: Color = Color.WHITE
@export var ambient_particle_color: Color = Color(1, 1, 1, 0.1)
@export var stage_modifiers: Array[String] = []
@export var hp_mult: float = 1.0
@export var damage_mult: float = 1.0
@export var rarity: String = "common"
