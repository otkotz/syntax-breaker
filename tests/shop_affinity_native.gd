extends Node

class CatalogShop extends Shop:
	var catalog: Array = []
	func _load_resources(path: String) -> Array:
		return catalog if path.ends_with("passives/") else []

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	RunManager.save_path = "res://.godot/shop_affinity_run_test.json"
	RunManager.start_run()
	var reroll_curve: Array[int] = []
	for i in 6:
		reroll_curve.append(RunManager.reroll_cost)
		RunManager.advance_reroll_cost()
	check(reroll_curve == [2, 3, 5, 8, 12, 17], "Reroll heat follows the run-wide triangular cost curve")
	var saved_reroll_count: int = RunManager.reroll_count
	RunManager.save_run([])
	RunManager.reroll_count = 0
	RunManager.reroll_cost = 2
	RunManager.restore_from_save(RunManager.load_run())
	check(RunManager.reroll_count == saved_reroll_count and RunManager.reroll_cost == 23,
		"Reroll heat survives save and resume")
	var shop := CatalogShop.new()
	for element: String in ["fire", "lightning", "poison"]:
		var passive := PassiveResource.new()
		passive.id = "affinity_test_" + element
		passive.name = passive.id
		passive.affected_tags = [element]
		passive.stat_modifiers = {"damage_add": 1.0}
		shop.catalog.append(passive)
		MetaProgression.unlocked_items.passives.append(passive.id)
	for index in 3:
		var general := PassiveResource.new()
		general.id = "general_test_%d" % index
		general.name = general.id
		general.stat_modifiers = {"damage_add": 0.5}
		shop.catalog.append(general)
		MetaProgression.unlocked_items.passives.append(general.id)
	for id: String in ["fireball", "lightning_bolt", "poison_dart"]:
		shop._skill_instances.append(SkillInstance.new(load("res://resources/skills/%s.tres" % id)))
	RunManager.skill_slots_unlocked = 3
	for region_id: String in ["burning_grounds", "storm_spire", "toxic_depths"]:
		RunManager.current_region = region_id
		var region := load("res://resources/regions/%s.tres" % region_id) as RegionResource
		var stat_seen := 0
		var stat_missing := 0
		var affinity_seen := 0
		var affinity_missing := 0
		for iteration in 30:
			seed(20261003 + iteration)
			shop._generate_offerings()
			check(shop._offerings.size() == 4, "Four offers with full eligible catalog")
			var regional_count := 0
			var stat_count := 0
			var ids: Array[String] = []
			for offer: Dictionary in shop._offerings:
				stat_count += int(offer.type == "stat_upgrade")
				if offer.type != "passive":
					continue
				ids.append(offer.resource.id)
				regional_count += int(RewardRoller.get_region_affinity(offer, region) > 0)
				if offer.resource.id.begins_with("affinity_test_"):
					check(offer.resource.stat_modifiers == {"damage_add": 1.0}, "Regional selection does not strengthen resource")
			stat_seen += int(stat_count == 1)
			stat_missing += int(stat_count == 0)
			affinity_seen += int(regional_count == 1)
			affinity_missing += int(regional_count == 0)
			check(stat_count <= 1 and regional_count <= 1, "Shop never stacks multiple targeting anchors")
			check(ids.size() >= 2, "Most shop slots remain flexible build choices")
			var unique_ids: Dictionary = {}
			for id: String in ids:
				unique_ids[id] = true
			check(unique_ids.size() == ids.size(), "Reserved offer is removed from flexible pool")
		check(stat_seen > 0 and stat_missing > 0, "Stat upgrade is possible but no longer guaranteed")
		check(affinity_seen > 0 and affinity_missing > 0, "Regional fit is possible but no longer guaranteed")
		var preferred: PassiveResource = shop._offerings.filter(func(offer): return offer.type == "passive")[0].resource
		RunManager.owned_passives.append(preferred)
		shop._generate_offerings()
		check(shop._offerings.size() == 4, "Missing eligible affinity falls back without manufacturing an offer")
		for offer: Dictionary in shop._offerings:
			if offer.type == "passive":
				check(offer.resource != preferred, "Affinity never bypasses owned-item filtering")
		RunManager.owned_passives.clear()
	RunManager.current_region = ""
	var selected: Dictionary = {}
	for iteration in 30:
		seed(20261003 + iteration)
		shop._generate_offerings()
		for offer: Dictionary in shop._offerings:
			if offer.type == "passive":
				selected[offer.resource.id] = true
	check(selected.size() > 1, "No region leaves build slot flexible")
	shop.free()
	print(JSON.stringify({"failures": failures, "regional_rolls": 90, "unbiased_rolls": 30}))
	get_tree().quit(0 if failures.is_empty() else 1)
