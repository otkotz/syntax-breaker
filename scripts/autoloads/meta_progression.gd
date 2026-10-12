extends Node

const ThreatProtocolsData = preload("res://scripts/util/threat_protocols.gd")
const SAVE_PATH := "user://meta_progression.json"
const MAX_ASCENSION := 20
const MAX_THREAT_PROTOCOL := ThreatProtocolsData.MAX_LEVEL
var save_path: String = SAVE_PATH

var unlocked_items: Dictionary = {
	"skills": ["fireball", "lightning_bolt", "blade_spin"],
	"supports": ["pierce", "faster_casting", "poison_on_hit", "spell_echo", "cast_on_kill", "void_rift", "totem", "mine", "returning", "hypothermia", "laser", "copy_paste", "spaghetti_code", "works_on_my_machine", "lag_spike", "alt_f4", "rubber_duck", "firewall", "reply_all", "frozen_process", "wifi_extender", "malware", "background_process", "undo_history"],
	"passives": ["ward_capacity", "ward_recovery", "ward_reflex", "thick_skin", "swift_feet", "sharp_eyes", "heavy_hitter", "rapid_fire", "iron_will", "extra_shot", "wide_impact", "fortune",
		"pierce_mastery", "returning_mastery", "chain_mastery", "split_mastery", "shotgun_mastery",
		"increased_area_mastery", "faster_casting_mastery", "crit_explosion_mastery", "poison_on_hit_mastery",
		"elemental_proliferation_mastery", "glass_cannon_mastery", "overcharge_mastery", "spell_echo_mastery",
		"cast_on_kill_mastery", "void_rift_mastery", "totem_mastery", "mine_mastery", "corpse_bloom_mastery",
		"toxic_burst_mastery", "arc_burst_mastery", "echo_trigger_mastery", "plague_carrier_mastery",
		"ricochet_amplifier_mastery", "crit_cascade_mastery", "deep_freeze"],
}

var ascension_level: int = 0
var highest_ascension_unlocked: Dictionary = {}
var threat_protocol_level: int = 0
var highest_threat_protocol_unlocked: Dictionary = {}
var region_victories: Dictionary = {}
var codex_entries: Dictionary = {}
var completed_challenges: Dictionary = {}
var selected_cosmetics: Dictionary = {"player": "player_default", "projectile": "projectile_default"}
var cosmetic_points: int = 0
var purchased_cosmetics: Array[String] = []

func add_cosmetic_points(amount: int) -> void:
	if amount <= 0:
		return
	cosmetic_points += amount
	save_progress()

func buy_cosmetic(id: String) -> bool:
	var entry := CosmeticStyles.definition(id)
	if entry.is_empty():
		return false
	if CosmeticStyles.is_unlocked(id):
		return true
	var price := int(entry.get("price", 0))
	if price <= 0 or cosmetic_points < price:
		return false
	cosmetic_points -= price
	purchased_cosmetics.append(id)
	save_progress()
	return true

func equip_cosmetic(id: String) -> bool:
	var entry := CosmeticStyles.definition(id)
	if entry.is_empty() or not CosmeticStyles.is_unlocked(id):
		return false
	selected_cosmetics[entry.kind] = id
	save_progress()
	return true

func record_challenges(victory: bool, stats: Dictionary, region: String, level: int) -> Array[String]:
	var newly_completed: Array[String] = []
	for id in ArchetypeChallenges.evaluate(victory, stats):
		if completed_challenges.has(id):
			continue
		completed_challenges[id] = {"region": region, "threat_protocol": level, "completed_utc": Time.get_datetime_string_from_system(true)}
		newly_completed.append(id)
	if not newly_completed.is_empty():
		save_progress()
	return newly_completed

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

func get_max_ascension(region: String = "") -> int:
	return clampi(int(highest_ascension_unlocked.get(region, 0)), 0, MAX_ASCENSION)

func get_max_threat_protocol(region: String = "") -> int:
	return clampi(int(highest_threat_protocol_unlocked.get(region, 0)), 0, MAX_THREAT_PROTOCOL)

func record_victory(region: String, level: int) -> void:
	region_victories[region] = int(region_victories.get(region, 0)) + 1
	if level <= get_max_threat_protocol(region):
		highest_threat_protocol_unlocked[region] = maxi(get_max_threat_protocol(region), mini(level + 1, MAX_THREAT_PROTOCOL))
	_sync_contract_supports()
	save_progress()

func _sync_contract_supports() -> void:
	# Older profiles may predate the default Mine/Totem catalogue entries.
	for contract in StarterContracts.DEFINITIONS:
		if not contract.support.is_empty() and StarterContracts.is_unlocked(contract.id):
			if not unlocked_items.has("supports"):
				unlocked_items["supports"] = []
			if not is_unlocked("supports", contract.support):
				unlocked_items.supports.append(contract.support)

func set_ascension(level: int, region: String = "") -> void:
	ascension_level = clampi(level, 0, get_max_ascension(region))
	save_progress()

func set_threat_protocol(level: int, region: String = "") -> void:
	threat_protocol_level = clampi(level, 0, get_max_threat_protocol(region))
	save_progress()

func get_ascension_scaling(level: int = -1) -> Dictionary:
	var a := float(RunManager.ascension_level if level < 0 else level)
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
		"threat_protocol_level": threat_protocol_level,
		"highest_threat_protocol_unlocked": highest_threat_protocol_unlocked,
		"region_victories": region_victories,
		"codex_entries": codex_entries,
		"completed_challenges": completed_challenges,
		"selected_cosmetics": selected_cosmetics,
		"cosmetic_points": cosmetic_points,
		"purchased_cosmetics": purchased_cosmetics,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_progress() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data: Dictionary = json.data
			var migrated_legacy_progress := false
			cosmetic_points = maxi(0, int(data.get("cosmetic_points", 0)))
			purchased_cosmetics.clear()
			for id: Variant in data.get("purchased_cosmetics", []):
				if id is String and not purchased_cosmetics.has(id):
					purchased_cosmetics.append(id)
			if data.has("highest_threat_protocol_unlocked"):
				highest_threat_protocol_unlocked = data.get("highest_threat_protocol_unlocked", {}).duplicate(true)
				threat_protocol_level = clampi(int(data.get("threat_protocol_level", 0)), 0, MAX_THREAT_PROTOCOL)
			else:
				highest_threat_protocol_unlocked = {}
				for region: Variant in data.get("highest_ascension_unlocked", {}):
					var legacy_level := int(data.highest_ascension_unlocked[region])
					highest_threat_protocol_unlocked[str(region)] = ThreatProtocolsData.from_legacy_ascension(legacy_level)
				threat_protocol_level = ThreatProtocolsData.from_legacy_ascension(int(data.get("ascension_level", 0)))
				var migrated_region := str(data.get("current_region", ""))
				threat_protocol_level = clampi(threat_protocol_level, 0, get_max_threat_protocol(migrated_region)) if highest_threat_protocol_unlocked.has(migrated_region) else threat_protocol_level
				migrated_legacy_progress = true
			# Keep aliases coherent while older runtime consumers are migrated task-by-task.
			ascension_level = threat_protocol_level
			highest_ascension_unlocked = highest_threat_protocol_unlocked.duplicate(true)
			region_victories = data.get("region_victories", {})
			completed_challenges = data.get("completed_challenges", {})
			selected_cosmetics = data.get("selected_cosmetics", {}).duplicate(true) if data.get("selected_cosmetics", {}) is Dictionary else {}
			for kind in CosmeticStyles.DEFAULTS:
				selected_cosmetics[kind] = CosmeticStyles.selected(kind)
			if data.has("unlocked_items"):
				unlocked_items = data["unlocked_items"]
			elif not data.has("ascension_level"):
				unlocked_items = data
			if data.has("codex_entries"):
				codex_entries = data["codex_entries"]
			_sync_contract_supports()
			# New defensive passives are baseline content, including for existing profiles.
			if not unlocked_items.has("passives"):
				unlocked_items["passives"] = []
			for passive_id in ["ward_capacity", "ward_recovery", "ward_reflex"]:
				if not unlocked_items.passives.has(passive_id):
					unlocked_items.passives.append(passive_id)
			if not unlocked_items.has("supports"):
				unlocked_items["supports"] = []
			if not unlocked_items.supports.has("laser"):
				unlocked_items.supports.append("laser")
			for support_id in ["copy_paste", "spaghetti_code", "works_on_my_machine", "lag_spike", "alt_f4", "rubber_duck", "firewall", "reply_all", "frozen_process", "wifi_extender", "malware", "background_process", "undo_history"]:
				if not unlocked_items.supports.has(support_id):
					unlocked_items.supports.append(support_id)
			if migrated_legacy_progress:
				save_progress()
