class_name ExpeditionLootCatalog
extends RefCounted

const TABLE_IDS: Array[String] = ["burning_elite", "burning_treasure", "burning_boss_set"]
const TABLES := {
	"burning_elite": preload("res://resources/expedition_loot/burning_elite.tres"),
	"burning_treasure": preload("res://resources/expedition_loot/burning_treasure.tres"),
	"burning_boss_set": preload("res://resources/expedition_loot/burning_boss_set.tres"),
}

static func all_table_ids() -> Array[String]:
	return TABLE_IDS.duplicate()

static func get_table(table_id: String) -> LootTableResource:
	if not TABLE_IDS.has(table_id): return null
	var table: LootTableResource = TABLES.get(table_id)
	if table == null or table.id != table_id or not _valid_entries(table.entries): return null
	return table

static func _valid_entries(entries: Array[Dictionary]) -> bool:
	var seen: Dictionary = {}
	for entry: Dictionary in entries:
		var artifact_id := str(entry.get("artifact_id", ""))
		if artifact_id.is_empty() or seen.has(artifact_id) or float(entry.get("weight", 0.0)) <= 0.0:
			return false
		seen[artifact_id] = true
	return not entries.is_empty()
