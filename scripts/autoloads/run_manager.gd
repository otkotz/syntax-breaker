extends Node

var current_stage: int = 0
var gold: int = 0
var skill_slots_unlocked: int = 1
var equipped_skills: Array = []
var owned_supports: Array = []
var owned_passives: Array = []
var support_quality: Dictionary = {}
var run_stats: Dictionary = {}
var last_shop_depth: int = 0
var current_stage_data: StageData

func start_run() -> void:
	current_stage = 0
	gold = 0
	skill_slots_unlocked = 1
	equipped_skills = []
	owned_supports = []
	owned_passives = []
	support_quality = {}
	last_shop_depth = 0
	current_stage_data = null
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
