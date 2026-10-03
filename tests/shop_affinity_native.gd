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
	RunManager.start_run()
	var shop := CatalogShop.new()
	for element: String in ["fire", "lightning", "poison"]:
		var passive := PassiveResource.new()
		passive.id = "affinity_test_" + element
		passive.name = passive.id
		passive.affected_tags = [element]
		passive.stat_modifiers = {"damage_add": 1.0}
		shop.catalog.append(passive)
		MetaProgression.unlocked_items.passives.append(passive.id)
	for id: String in ["fireball", "lightning_bolt", "poison_dart"]:
		shop._skill_instances.append(SkillInstance.new(load("res://resources/skills/%s.tres" % id)))
	RunManager.skill_slots_unlocked = 3
	for region_id: String in ["burning_grounds", "storm_spire", "toxic_depths"]:
		RunManager.current_region = region_id
		var region := load("res://resources/regions/%s.tres" % region_id) as RegionResource
		for iteration in 30:
			seed(20261003 + iteration)
			shop._generate_offerings()
			check(shop._offerings.size() == 4, "Four offers with full eligible catalog")
			check(shop._offerings[0].type == "stat_upgrade", "Upgrade remains its own slot")
			check(RewardRoller.get_region_affinity(shop._offerings[1], region) > 0, "One build slot prefers region: " + region_id)
			var regional_count := 0
			var ids: Array[String] = []
			for offer: Dictionary in shop._offerings:
				if offer.type != "passive":
					continue
				ids.append(offer.resource.id)
				regional_count += int(RewardRoller.get_region_affinity(offer, region) > 0)
				check(offer.resource.stat_modifiers == {"damage_add": 1.0}, "Regional selection does not strengthen resource")
			check(regional_count == 1 and ids.size() == 3, "Other slots retain off-region choices")
			check(ids[0] != ids[1] and ids[1] != ids[2] and ids[0] != ids[2], "Reserved offer is removed from flexible pool")
		var preferred: PassiveResource = shop._offerings[1].resource
		RunManager.owned_passives.append(preferred)
		shop._generate_offerings()
		check(shop._offerings.size() == 3, "Missing eligible affinity falls back without manufacturing an offer")
		for offer: Dictionary in shop._offerings:
			if offer.type == "passive":
				check(offer.resource != preferred, "Affinity never bypasses owned-item filtering")
		RunManager.owned_passives.clear()
	RunManager.current_region = ""
	var selected: Dictionary = {}
	for iteration in 30:
		seed(20261003 + iteration)
		shop._generate_offerings()
		selected[shop._offerings[1].resource.id] = true
	check(selected.size() > 1, "No region leaves build slot flexible")
	shop.free()
	print(JSON.stringify({"failures": failures, "regional_rolls": 90, "unbiased_rolls": 30}))
	get_tree().quit(0 if failures.is_empty() else 1)
