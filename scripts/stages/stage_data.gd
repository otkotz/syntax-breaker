class_name StageData
extends RefCounted

enum Type { COMBAT, ELITE, SHOP, TREASURE, BOSS }

var type: Type
var depth: int
var modifiers: Array[String] = []

const TYPE_NAMES := {
	Type.COMBAT: "Combat",
	Type.ELITE: "Elite",
	Type.SHOP: "Shop",
	Type.TREASURE: "Treasure",
	Type.BOSS: "Boss",
}

const TYPE_COLORS := {
	Type.COMBAT: Color(0.8, 0.8, 0.3),
	Type.ELITE: Color(1.0, 0.5, 0.2),
	Type.SHOP: Color(0.3, 0.8, 0.3),
	Type.TREASURE: Color(0.9, 0.8, 0.2),
	Type.BOSS: Color(1.0, 0.2, 0.2),
}

const TYPE_DESCRIPTIONS := {
	Type.COMBAT: "Clear waves of enemies",
	Type.ELITE: "Fewer but tougher foes, better loot",
	Type.SHOP: "Spend gold on skills & supports",
	Type.TREASURE: "Pick a free reward",
	Type.BOSS: "Defeat the boss to advance",
}

const MODIFIER_DATA := {
	"swift": {"label": "Swift", "desc": "Enemies 30% faster"},
	"tough": {"label": "Tough", "desc": "Enemies +50% HP"},
	"swarming": {"label": "Swarming", "desc": "50% more enemies"},
	"deadly": {"label": "Deadly", "desc": "Enemies +40% damage"},
	"enriched": {"label": "Enriched", "desc": "2x gold drops"},
	"cursed": {"label": "Cursed", "desc": "Player 20% slower"},
}

func get_type_name() -> String:
	return TYPE_NAMES.get(type, "Unknown")

func get_type_color() -> Color:
	return TYPE_COLORS.get(type, Color.WHITE)

func get_description() -> String:
	return TYPE_DESCRIPTIONS.get(type, "")

func get_modifier_text() -> String:
	var parts: PackedStringArray = []
	for mod: String in modifiers:
		if MODIFIER_DATA.has(mod):
			parts.append(MODIFIER_DATA[mod]["label"])
	return ", ".join(parts)

func get_enemy_hp_mult() -> float:
	var mult := 1.0
	if type == Type.ELITE:
		mult *= 2.5
	if modifiers.has("tough"):
		mult *= 1.5
	return mult

func get_enemy_speed_mult() -> float:
	var mult := 1.0
	if modifiers.has("swift"):
		mult *= 1.3
	return mult

func get_enemy_damage_mult() -> float:
	var mult := 1.0
	if type == Type.ELITE:
		mult *= 1.5
	if modifiers.has("deadly"):
		mult *= 1.4
	return mult

func get_enemy_count_mult() -> float:
	var mult := 1.0
	if type == Type.ELITE:
		mult *= 0.4
	if modifiers.has("swarming"):
		mult *= 1.5
	return mult

func get_gold_mult() -> float:
	var mult := 1.0
	if type == Type.ELITE:
		mult *= 1.5
	if modifiers.has("enriched"):
		mult *= 2.0
	return mult

func get_player_speed_mult() -> float:
	if modifiers.has("cursed"):
		return 0.8
	return 1.0
