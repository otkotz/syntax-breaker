extends Node

const SAVE_PATH := "user://meta_progression.json"
const MAX_ASCENSION := 20

var unlocked_items: Dictionary = {
	"skills": ["fireball", "lightning_bolt", "blade_spin"],
	"supports": ["pierce", "faster_casting", "poison_on_hit", "spell_echo", "cast_on_kill", "void_rift", "totem", "mine", "returning", "hypothermia"],
	"passives": ["thick_skin", "swift_feet", "sharp_eyes", "heavy_hitter", "rapid_fire", "iron_will", "extra_shot", "wide_impact",
		"pierce_mastery", "returning_mastery", "chain_mastery", "split_mastery", "shotgun_mastery",
		"increased_area_mastery", "faster_casting_mastery", "crit_explosion_mastery", "poison_on_hit_mastery",
		"elemental_proliferation_mastery", "glass_cannon_mastery", "overcharge_mastery", "spell_echo_mastery",
		"cast_on_kill_mastery", "void_rift_mastery", "totem_mastery", "mine_mastery", "corpse_bloom_mastery",
		"toxic_burst_mastery", "arc_burst_mastery", "echo_trigger_mastery", "plague_carrier_mastery",
		"ricochet_amplifier_mastery", "crit_cascade_mastery", "deep_freeze"],
}

var ascension_level: int = 0
var codex_entries: Dictionary = {}

var _unlock_conditions: Array = []

func _ready() -> void:
	load_progress()
	_load_unlock_conditions()

func _load_unlock_conditions() -> void:
	for file_name in ResourceListing.get_resource_files("res://resources/unlocks/"):
		var res := load("res://resources/unlocks/" + file_name)
		if res is UnlockConditionResource:
			_unlock_conditions.append(res)

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

func set_ascension(level: int) -> void:
	ascension_level = clampi(level, 0, MAX_ASCENSION)
	save_progress()

func get_ascension_scaling() -> Dictionary:
	var a := float(ascension_level)
	return {
		"hp_mult": 1.0 + a * 0.15,
		"damage_mult": 1.0 + a * 0.10,
		"speed_mult": 1.0 + a * 0.03,
		"gold_mult": maxf(1.0 - a * 0.02, 0.5),
	}

func discover_codex(category: String, entry_id: String) -> bool:
	if not codex_entries.has(category):
		codex_entries[category] = []
	if entry_id in codex_entries[category]:
		return false
	codex_entries[category].append(entry_id)
	save_progress()
	return true

func is_discovered(category: String, entry_id: String) -> bool:
	return codex_entries.get(category, []).has(entry_id)

func unlock_item(item_type: String, item_id: String) -> bool:
	if is_unlocked(item_type, item_id):
		return false
	if not unlocked_items.has(item_type):
		unlocked_items[item_type] = []
	unlocked_items[item_type].append(item_id)
	save_progress()
	return true

func save_progress() -> void:
	var data := {
		"unlocked_items": unlocked_items,
		"ascension_level": ascension_level,
		"codex_entries": codex_entries,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data: Dictionary = json.data
			if data.has("unlocked_items"):
				unlocked_items = data["unlocked_items"]
			elif not data.has("ascension_level"):
				unlocked_items = data
			if data.has("ascension_level"):
				ascension_level = int(data["ascension_level"])
			if data.has("codex_entries"):
				codex_entries = data["codex_entries"]
