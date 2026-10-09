class_name ShopUpgradeIcons
extends RefCounted

const ICONS := {
	"damage": preload("res://assets/icons/upgrades/damage-v1.png"),
	"cooldown": preload("res://assets/icons/upgrades/haste-v1.png"),
	"crit_chance": preload("res://assets/icons/upgrades/critical-v1.png"),
}

static func get_icon(key: String) -> Texture2D:
	return ICONS.get(key) as Texture2D
