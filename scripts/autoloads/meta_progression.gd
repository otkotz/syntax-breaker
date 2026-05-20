extends Node

const SAVE_PATH := "user://meta_progression.json"

var unlocked_items: Dictionary = {
	"skills": ["fireball", "lightning_bolt", "blade_spin"],
	"supports": ["pierce", "faster_casting", "poison_on_hit", "spell_echo", "cast_on_kill", "void_rift", "totem", "mine"],
	"passives": ["thick_skin"],
}

var _unlock_conditions: Array = []

func _ready() -> void:
	load_progress()
	_load_unlock_conditions()

func _load_unlock_conditions() -> void:
	var dir := DirAccess.open("res://resources/unlocks/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://resources/unlocks/" + file_name)
			if res is UnlockConditionResource:
				_unlock_conditions.append(res)
		file_name = dir.get_next()

func check_unlocks(run_stats: Dictionary) -> Array[String]:
	var newly_unlocked: Array[String] = []
	for condition: UnlockConditionResource in _unlock_conditions:
		if is_unlocked(condition.item_type, condition.item_id):
			continue
		if condition.check(run_stats):
			unlock_item(condition.item_type, condition.item_id)
			newly_unlocked.append(condition.item_id)
	return newly_unlocked

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
