extends Node

var current_stage: int = 0
var gold: int = 0
var skill_slots_unlocked: int = 1
var equipped_skills: Array = []
var owned_supports: Array = []
var owned_passives: Array = []
var owned_consumables: Array[Dictionary] = []
var support_quality: Dictionary = {}
var run_stats: Dictionary = {}
var shop_bonuses: Dictionary = {}
var current_stage_data: StageData
var current_region: String = ""
var ascension_level: int = 0
var stage_tree: StageTree

func start_run(region: String = "", ascension: int = -1) -> void:
	current_stage = 0
	gold = 30
	skill_slots_unlocked = 1
	equipped_skills = []
	owned_supports = []
	owned_passives = []
	owned_consumables = []
	support_quality = {}
	shop_bonuses = {}
	current_stage_data = null
	stage_tree = null
	current_region = region
	ascension_level = ascension if ascension >= 0 else MetaProgression.ascension_level
	run_stats = {
		"enemies_killed": 0,
		"damage_by_tag": {},
		"stages_reached": 0,
		"projectiles_fired": 0,
		"crits_landed": 0,
		"poison_applied": 0,
		"skills_used": [],
		"mini_bosses_killed": 0,
		"max_aoe_kill": 0,
		"max_dot_spread_kill": 0,
		"elites_cleared": 0,
		"best_combo": 0,
		"triggers_fired": 0,
		"region": region,
		"ascension_level": ascension_level,
	}

func add_gold(amount: int) -> void:
	gold += amount
	GameBus.gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		GameBus.gold_changed.emit(gold)
		return true
	return false

func advance_stage() -> void:
	current_stage += 1
	run_stats["stages_reached"] = current_stage
	if current_stage == 2 or current_stage == 4:
		skill_slots_unlocked = mini(skill_slots_unlocked + 1, 4)

const MAX_QUALITY_LEVEL := 4
const QUALITY_PER_LEVEL := 0.05

func get_support_quality(support_id: String) -> int:
	return support_quality.get(support_id, 0)

func upgrade_support_quality(support_id: String) -> bool:
	var current: int = support_quality.get(support_id, 0)
	if current >= MAX_QUALITY_LEVEL:
		return false
	support_quality[support_id] = current + 1
	return true

func is_support_max_quality(support_id: String) -> bool:
	return get_support_quality(support_id) >= MAX_QUALITY_LEVEL

func add_consumable(res: ConsumableResource) -> void:
	for entry: Dictionary in owned_consumables:
		if entry["id"] == res.id:
			entry["charges"] += 1
			return
	owned_consumables.append({"id": res.id, "charges": 1, "resource": res})

func get_consumable_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in owned_consumables:
		result.append(entry.duplicate())
	return result

const RUN_SAVE_PATH := "user://active_run.json"

func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)

func save_run(skill_data: Array[Dictionary]) -> void:
	var supports_data: Array[Dictionary] = []
	for s: Resource in owned_supports:
		if s is SupportResource:
			supports_data.append({"id": s.id})
	var passives_data: Array[Dictionary] = []
	for p: Resource in owned_passives:
		if p is PassiveResource:
			passives_data.append({"id": p.id})

	var consumables_data: Array[Dictionary] = []
	for entry: Dictionary in owned_consumables:
		consumables_data.append({"id": entry["id"], "charges": entry["charges"]})

	var data := {
		"current_stage": current_stage,
		"gold": gold,
		"skill_slots_unlocked": skill_slots_unlocked,
		"support_quality": support_quality,
		"shop_bonuses": shop_bonuses,
		"run_stats": run_stats,
		"current_region": current_region,
		"ascension_level": ascension_level,
		"skills": skill_data,
		"supports": supports_data,
		"passives": passives_data,
		"consumables": consumables_data,
		"stage_tree": stage_tree.serialize() if stage_tree else {},
	}
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_run() -> Dictionary:
	if not has_saved_run():
		return {}
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	return json.data as Dictionary

func clear_saved_run() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)

func restore_from_save(data: Dictionary) -> void:
	current_stage = int(data.get("current_stage", 0))
	gold = int(data.get("gold", 0))
	skill_slots_unlocked = int(data.get("skill_slots_unlocked", 1))
	support_quality = data.get("support_quality", {})
	shop_bonuses = data.get("shop_bonuses", {})
	run_stats = data.get("run_stats", {})
	current_region = data.get("current_region", "")
	ascension_level = int(data.get("ascension_level", 0))

	var tree_data: Dictionary = data.get("stage_tree", {})
	if tree_data.size() > 0:
		var region: RegionResource = null
		if not current_region.is_empty():
			var r_path := "res://resources/regions/%s.tres" % current_region
			if ResourceLoader.exists(r_path):
				region = load(r_path) as RegionResource
		stage_tree = StageTree.deserialize(tree_data, region)

	owned_supports.clear()
	for s_data: Dictionary in data.get("supports", []):
		var path := "res://resources/supports/%s.tres" % s_data["id"]
		if ResourceLoader.exists(path):
			owned_supports.append(load(path))

	owned_passives.clear()
	for p_data: Dictionary in data.get("passives", []):
		var path := "res://resources/passives/%s.tres" % p_data["id"]
		if ResourceLoader.exists(path):
			owned_passives.append(load(path))

	owned_consumables.clear()
	for c_data: Dictionary in data.get("consumables", []):
		var path := "res://resources/consumables/%s.tres" % c_data["id"]
		if ResourceLoader.exists(path):
			var res := load(path) as ConsumableResource
			if res:
				owned_consumables.append({"id": c_data["id"], "charges": int(c_data["charges"]), "resource": res})

func record_stat(stat_key: String, value: Variant) -> void:
	match typeof(run_stats.get(stat_key)):
		TYPE_INT:
			run_stats[stat_key] += value if value is int else 1
		TYPE_ARRAY:
			if not run_stats[stat_key].has(value):
				run_stats[stat_key].append(value)
		TYPE_DICTIONARY:
			for tag_key: String in value:
				if run_stats[stat_key].has(tag_key):
					run_stats[stat_key][tag_key] += value[tag_key]
				else:
					run_stats[stat_key][tag_key] = value[tag_key]
