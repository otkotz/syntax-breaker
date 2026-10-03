class_name StarterContracts
extends RefCounted

const STARTING_GOLD := 30
const DEFINITIONS := [
	{"id": "standard", "name": "Standard", "support": "", "wins": 0},
	{"id": "miner", "name": "Miner", "support": "mine", "wins": 1},
	{"id": "architect", "name": "Architect", "support": "totem", "wins": 3},
]

static func definition(id: String) -> Dictionary:
	for entry in DEFINITIONS:
		if entry.id == id:
			return entry
	return {}

static func is_unlocked(id: String) -> bool:
	var contract := definition(id)
	if contract.is_empty():
		return false
	var wins := 0
	for count in MetaProgression.region_victories.values():
		wins += maxi(0, int(count))
	return wins >= int(contract.wins)

static func support_for(id: String) -> SupportResource:
	var contract := definition(id)
	if contract.is_empty() or contract.support.is_empty():
		return null
	return load("res://resources/supports/%s.tres" % contract.support) as SupportResource

static func cost(id: String) -> int:
	var support := support_for(id)
	return int(Shop.RARITY_COSTS.support.get(support.rarity, 10)) if support else 0

static func rejection_reason(id: String, skill: SkillResource) -> String:
	if definition(id).is_empty():
		return "Unknown contract"
	if not is_unlocked(id):
		return "Requires %d victories" % int(definition(id).wins)
	if skill == null or not MetaProgression.is_unlocked("skills", skill.id):
		return "Skill is locked"
	var support := support_for(id)
	if not definition(id).support.is_empty() and support == null:
		return "Contract resource unavailable"
	if support:
		if not MetaProgression.is_unlocked("supports", support.id):
			return "Support is locked"
		return SkillInstance.new(skill).support_rejection_reason(support)
	return ""

static func apply(id: String, si: SkillInstance) -> bool:
	if si == null or not rejection_reason(id, si.base).is_empty():
		return false
	if RunManager.current_stage != 0 or RunManager.run_stats.get("starter_contract_applied", false):
		return false
	if RunManager.gold != STARTING_GOLD or RunManager.gold_fraction != 0.0 or not si.linked_supports.is_empty():
		return false
	var price := cost(id)
	if price < 0 or price > STARTING_GOLD:
		return false
	var support := support_for(id)
	if support and not si.link_support(support):
		return false
	si.set_rarity_tier("common")
	# Allocate the initial budget, not a purchase: earned/spent stay unchanged.
	RunManager.gold = STARTING_GOLD - price
	RunManager.run_stats["starter_contract"] = id
	RunManager.run_stats["starter_contract_cost"] = price
	RunManager.run_stats["starter_contract_applied"] = true
	RunManager.run_stats["starting_gold"] = RunManager.gold
	GameBus.gold_changed.emit(RunManager.gold)
	if RunTelemetry.active:
		RunTelemetry.data.metadata["starter_contract"] = id
		RunTelemetry.data.metadata["starting_gold"] = RunManager.gold
	RunTelemetry.record("starter_contract", {"id": id, "support": definition(id).support,
		"allocated_cost": price, "starting_gold": RunManager.gold})
	return true
