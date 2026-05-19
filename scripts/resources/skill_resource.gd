class_name SkillResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var tags: Array[String] = []
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.0
@export var base_speed: float = 300.0
@export var base_range: float = 400.0
@export var base_pierce: int = 0
@export var base_projectile_count: int = 1
@export var max_supports: int = 2
@export var scene_path: String = ""
@export var icon: Texture2D
@export var rarity: String = "common"
@export_multiline var description: String = ""

func has_tag(tag: String) -> bool:
	return tags.has(tag)

func has_any_tag(check_tags: Array[String]) -> bool:
	for tag in check_tags:
		if tags.has(tag):
			return true
	return false
