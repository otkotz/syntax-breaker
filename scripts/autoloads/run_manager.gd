extends Node

var current_stage: int = 0
var gold: int = 0
var gold_fraction: float = 0.0
var current_hp: float = 100.0
var max_hp: float = 100.0
var current_shield: float = 20.0
var shield_recharge_remaining: float = 0.0
signal consumables_changed
var skill_slots_unlocked: int = 1
var equipped_skills: Array = []
var owned_supports: Array = []
var owned_passives: Array = []
var owned_consumables: Array[Dictionary] = []
var run_stats: Dictionary = {}
var shop_bonuses: Dictionary = {}
var reroll_cost: int = 2
var current_stage_data: StageData
var current_region: String = ""
var ascension_level: int = 0
var stage_tree: StageTree

func start_run(region: String = "", ascension: int = -1) -> void:
	current_stage = 0
	gold = 30
	gold_fraction = 0.0
	current_hp = 100.0
	max_hp = 100.0
	current_shield = 20.0
	shield_recharge_remaining = 0.0
	skill_slots_unlocked = 1
	equipped_skills = []
	owned_supports = []
	owned_passives = []
	owned_consumables = []
	shop_bonuses = {}
	reroll_cost = 2
	current_stage_data = null
	stage_tree = null
	current_region = region
	ascension_level = clampi(ascension if ascension >= 0 else MetaProgression.ascension_level, 0, MetaProgression.get_max_ascension(region))
	run_stats = {
		"enemies_killed": 0,
		"gold_earned": 0.0,
		"gold_spent": 0,
		"gold_refunded": 0,
		"damage_taken": 0.0,
		"healing_received": 0.0,
		"time_played": 0.0,
		"rerolls": 0,
		"damage_by_tag": {},
		"direct_damage_by_skill": {},
		"direct_kills_by_skill": {},
		"damage_by_skill": {},
		"kills_by_skill": {},
		"dot_damage_by_skill": {},
		"dot_kills_by_skill": {},
		"proc_damage_by_skill": {},
		"proc_kills_by_skill": {},
		"damage_dealt": 0.0,
		"unattributed_damage": 0.0,
		"unattributed_kills": 0,
		"damage_attribution_version": 2,
		"challenge_tracking_version": 1,
		"challenge_elements": [],
		"challenge_non_elemental_damage": false,
		"mine_casts": 0,
		"non_mine_casts": 0,
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

func add_gold(amount: float) -> void:
	if amount <= 0.0:
		return
	run_stats["gold_earned"] = float(run_stats.get("gold_earned", 0.0)) + amount
	gold_fraction += amount
	var whole := int(floor(gold_fraction + 0.000001))
	gold += whole
	gold_fraction = maxf(0.0, gold_fraction - whole)
	GameBus.gold_changed.emit(gold)

func sync_health(hp: float, maximum: float) -> void:
	max_hp = maxf(1.0, maximum)
	current_hp = clampf(hp, 0.0, max_hp)

func heal_between_stages() -> void:
	var recovered := minf(max_hp - current_hp, max_hp * maxf(0.02, 0.1 - ascension_level * 0.004))
	current_hp += recovered
	record_stat("healing_received", recovered)

# Luck biases skill rarity-tier rolls toward higher tiers. Derived from owned
# passives' "luck" modifier plus any shop luck bonus.
func get_luck() -> float:
	var l := float(shop_bonuses.get("luck", 0.0))
	for p: Resource in owned_passives:
		if p is PassiveResource:
			l += float((p as PassiveResource).stat_modifiers.get("luck", 0.0))
	return l

func spend_gold(amount: int) -> bool:
	if amount >= 0 and gold >= amount:
		gold -= amount
		run_stats["gold_spent"] = int(run_stats.get("gold_spent", 0)) + amount
		GameBus.gold_changed.emit(gold)
		return true
	return false

func refund_gold(amount: int) -> bool:
	var spent := int(run_stats.get("gold_spent", 0))
	if amount <= 0 or amount > spent:
		return false
	gold += amount
	run_stats["gold_spent"] = spent - amount
	run_stats["gold_refunded"] = int(run_stats.get("gold_refunded", 0)) + amount
	GameBus.gold_changed.emit(gold)
	return true

func advance_stage() -> void:
	current_stage += 1
	run_stats["stages_reached"] = current_stage
	if current_stage in [1, 4, 7]:
		skill_slots_unlocked = mini(skill_slots_unlocked + 1, 4)


func add_consumable(res: ConsumableResource) -> void:
	for entry: Dictionary in owned_consumables:
		if entry["id"] == res.id:
			entry["charges"] += 1
			consumables_changed.emit()
			return
	if owned_consumables.size() >= ConsumableManager.MAX_SLOTS:
		return
	owned_consumables.append({"id": res.id, "charges": 1, "resource": res})
	consumables_changed.emit()

func consume_charge(item_id: String) -> bool:
	for i in owned_consumables.size():
		if owned_consumables[i]["id"] == item_id and owned_consumables[i]["charges"] > 0:
			owned_consumables[i]["charges"] -= 1
			if owned_consumables[i]["charges"] == 0:
				owned_consumables.remove_at(i)
			consumables_changed.emit()
			return true
	return false

func get_consumable_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in owned_consumables:
		result.append(entry.duplicate())
	return result

const RUN_SAVE_PATH := "user://active_run.json"
var save_path: String = RUN_SAVE_PATH

func has_saved_run() -> bool:
	return FileAccess.file_exists(save_path)

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
		"gold_fraction": gold_fraction,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"current_shield": current_shield,
		"shield_recharge_remaining": shield_recharge_remaining,
		"skill_slots_unlocked": skill_slots_unlocked,
		"shop_bonuses": shop_bonuses,
		"reroll_cost": reroll_cost,
		"run_stats": run_stats,
		"telemetry": RunTelemetry.snapshot(),
		"current_region": current_region,
		"ascension_level": ascension_level,
		"skills": skill_data,
		"supports": supports_data,
		"passives": passives_data,
		"consumables": consumables_data,
		"stage_tree": stage_tree.serialize() if stage_tree else {},
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_run() -> Dictionary:
	if not has_saved_run():
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	return json.data as Dictionary

func clear_saved_run() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)

func restore_from_save(data: Dictionary) -> void:
	current_stage = int(data.get("current_stage", 0))
	gold = int(data.get("gold", 0))
	gold_fraction = float(data.get("gold_fraction", 0.0))
	sync_health(float(data.get("current_hp", 100.0)), float(data.get("max_hp", 100.0)))
	current_shield = maxf(0.0, float(data.get("current_shield", 20.0)))
	shield_recharge_remaining = maxf(0.0, float(data.get("shield_recharge_remaining", 0.0)))
	skill_slots_unlocked = int(data.get("skill_slots_unlocked", 1))
	shop_bonuses = data.get("shop_bonuses", {})
	reroll_cost = int(data.get("reroll_cost", 2))
	run_stats = data.get("run_stats", {})
	RunTelemetry.restore(data.get("telemetry", {}))
	current_region = data.get("current_region", "")
	ascension_level = int(data.get("ascension_level", 0))

	var tree_data: Dictionary = data.get("stage_tree", {})
	stage_tree = null
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
		TYPE_FLOAT:
			run_stats[stat_key] += float(value)
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

func record_combat_damage(source: SkillResource, effective: float, killed: bool, category: String) -> void:
	if effective <= 0.0:
		return
	if source != null and run_stats.get("challenge_tracking_version", 0) == 1:
		var elemental := false
		for element in ArchetypeChallenges.ELEMENTS:
			if source.has_tag(element):
				elemental = true
				if not run_stats.challenge_elements.has(element):
					run_stats.challenge_elements.append(element)
		if not elemental or source.has_tag("physical"):
			run_stats.challenge_non_elemental_damage = true
	# Old active-run saves may lack the new dictionaries; retain their direct records.
	if not run_stats.has("damage_by_skill"):
		run_stats["damage_by_skill"] = run_stats.get("direct_damage_by_skill", {}).duplicate(true)
	if not run_stats.has("kills_by_skill"):
		run_stats["kills_by_skill"] = run_stats.get("direct_kills_by_skill", {}).duplicate(true)
	if not run_stats.has("damage_dealt"):
		var known_total: float = float(run_stats.get("unattributed_damage", 0.0))
		for amount in run_stats["damage_by_skill"].values():
			known_total += float(amount)
		run_stats["damage_dealt"] = known_total
	run_stats["damage_dealt"] = float(run_stats["damage_dealt"]) + effective
	if source == null or source.id.is_empty():
		run_stats["unattributed_damage"] = float(run_stats.get("unattributed_damage", 0.0)) + effective
		if killed:
			run_stats["unattributed_kills"] = int(run_stats.get("unattributed_kills", 0)) + 1
		return
	var channel := category if category in ["direct", "dot", "proc"] else "proc"
	for key: String in ["damage_by_skill", channel + "_damage_by_skill"]:
		var values: Dictionary = run_stats.get(key, {})
		values[source.id] = float(values.get(source.id, 0.0)) + effective
		run_stats[key] = values
	if killed:
		for key: String in ["kills_by_skill", channel + "_kills_by_skill"]:
			var values: Dictionary = run_stats.get(key, {})
			values[source.id] = int(values.get(source.id, 0)) + 1
			run_stats[key] = values

func record_challenge_cast(is_mine: bool) -> void:
	if run_stats.get("challenge_tracking_version", 0) != 1:
		return
	var key := "mine_casts" if is_mine else "non_mine_casts"
	run_stats[key] = int(run_stats.get(key, 0)) + 1
