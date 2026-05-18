extends Node

var current_stage: int = 0
var gold: int = 0
var skill_slots_unlocked: int = 1
var equipped_skills: Array = []
var owned_supports: Array = []
var owned_passives: Array = []
var run_stats: Dictionary = {}

func start_run() -> void:
	current_stage = 0
	gold = 0
	skill_slots_unlocked = 1
	equipped_skills = []
	owned_supports = []
	owned_passives = []
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

func record_stat(stat_key: String, value: Variant) -> void:
	match typeof(run_stats.get(stat_key)):
		TYPE_INT:
			run_stats[stat_key] += value if value is int else 1
		TYPE_ARRAY:
			if not run_stats[stat_key].has(value):
				run_stats[stat_key].append(value)
		TYPE_DICTIONARY:
			for tag_key in value:
				if run_stats[stat_key].has(tag_key):
					run_stats[stat_key][tag_key] += value[tag_key]
				else:
					run_stats[stat_key][tag_key] = value[tag_key]
