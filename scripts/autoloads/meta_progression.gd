extends Node

const SAVE_PATH := "user://meta_progression.json"

var unlocked_items: Dictionary = {
	"skills": ["fireball", "lightning_bolt", "blade_spin"],
	"supports": ["pierce", "faster_casting", "poison_on_hit"],
	"passives": ["thick_skin"],
}

func _ready() -> void:
	load_progress()

func is_unlocked(item_type: String, item_id: String) -> bool:
	return unlocked_items.get(item_type, []).has(item_id)

func unlock_item(item_type: String, item_id: String) -> bool:
	if is_unlocked(item_type, item_id):
		return false
	if not unlocked_items.has(item_type):
		unlocked_items[item_type] = []
	unlocked_items[item_type].append(item_id)
	save_progress()
	return true

func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(unlocked_items))

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			unlocked_items = json.data
