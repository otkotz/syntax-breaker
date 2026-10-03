class_name RewardRoller
extends RefCounted

static func roll(skill_instances: Array[SkillInstance], high_quality: bool) -> Array[Dictionary]:
	var skills: Array[Dictionary] = []
	var supports: Array[Dictionary] = []
	var focused_passives: Array[Dictionary] = []
	var general_passives: Array[Dictionary] = []
	var mutations: Array[Dictionary] = []

	if skill_instances.size() < RunManager.skill_slots_unlocked:
		for res: Resource in _load_resources("res://resources/skills/"):
			if not res is SkillResource or not MetaProgression.is_unlocked("skills", res.id):
				continue
			var owned := false
			for si: SkillInstance in skill_instances:
				if si.base.id == res.id:
					owned = true
					break
			if not owned:
				skills.append({"type": "skill", "id": res.id, "resource": res})

	for res: Resource in _load_resources("res://resources/supports/"):
		if res is SupportResource and MetaProgression.is_unlocked("supports", res.id) and BuildOptions.can_offer_support(res, skill_instances):
			supports.append({"type": "support", "id": res.id, "resource": res})

	for res: Resource in _load_resources("res://resources/passives/"):
		if not res is PassiveResource or res.rarity == "legendary":
			continue
		if not MetaProgression.is_unlocked("passives", res.id) or not BuildOptions.can_offer_passive(res, skill_instances):
			continue
		var owned := false
		for passive: Resource in RunManager.owned_passives:
			if passive is PassiveResource and passive.id == res.id:
				owned = true
				break
		if owned:
			continue
		var offer := {"type": "passive", "id": res.id, "resource": res}
		if BuildOptions.is_focused_passive(res):
			focused_passives.append(offer)
		else:
			general_passives.append(offer)

	if not skill_instances.is_empty():
		var excluded: Array = []
		for si: SkillInstance in skill_instances:
			for mutation: Dictionary in si.mutations:
				excluded.append(mutation["id"])
		for mutation: Dictionary in MutationData.roll_mutations(MutationData.POOL.size(), excluded, skill_instances):
			mutations.append({"type": "mutation", "id": mutation["id"], "mutation": mutation})

	# Each region softly biases the draft toward a different build identity.
	# Duplicating entries only changes offer probability; item power is unchanged.
	var region := _load_current_region()
	if region:
		skills = _apply_region_weight(skills, region)
		supports = _apply_region_weight(supports, region)
		focused_passives = _apply_region_weight(focused_passives, region)
		mutations = _apply_region_weight(mutations, region)

	# One immediate build improvement, one new direction, and one general pick.
	var rewards: Array[Dictionary] = []
	var build_pool := supports + focused_passives
	var direction_pool: Array[Dictionary] = []
	if not skills.is_empty():
		direction_pool.append_array(skills)
	else:
		direction_pool.append_array(supports)
		direction_pool.append_array(focused_passives)
		if high_quality or randf() < 0.25:
			direction_pool.append_array(mutations)
	var safe_pool := general_passives
	var flexible_pool := general_passives + supports + focused_passives + skills + mutations
	for pool: Array in [build_pool, direction_pool, safe_pool]:
		var pick := _take_unique(pool, rewards)
		if pick.is_empty():
			pick = _take_unique(flexible_pool, rewards)
		if pick.is_empty():
			pick = _roll_gold(high_quality)
		if pick.get("type") == "skill":
			var skill: SkillResource = pick["resource"]
			pick["tier"] = RarityTiers.roll_tier(skill.rarity, RunManager.get_luck())
		rewards.append(pick)
	return rewards

static func _take_unique(pool: Array, existing: Array[Dictionary]) -> Dictionary:
	var shuffled := pool.duplicate()
	shuffled.shuffle()
	for candidate: Dictionary in shuffled:
		var duplicate := false
		for chosen: Dictionary in existing:
			if chosen.get("type") == candidate.get("type") and chosen.get("id") == candidate.get("id"):
				duplicate = true
				break
		if not duplicate:
			return candidate.duplicate()
	return {}

static func _roll_gold(high_quality: bool) -> Dictionary:
	var amount := randi_range(25, 50) if high_quality else randi_range(10, 25)
	return {"type": "gold", "amount": amount}

static func _load_current_region() -> RegionResource:
	if RunManager.current_region.is_empty():
		return null
	var path := "res://resources/regions/%s.tres" % RunManager.current_region
	return load(path) as RegionResource if ResourceLoader.exists(path) else null

static func _apply_region_weight(pool: Array[Dictionary], region: RegionResource) -> Array[Dictionary]:
	var weighted: Array[Dictionary] = pool.duplicate()
	for offer: Dictionary in pool:
		if get_region_affinity(offer, region) > 0:
			# 2x total weight is noticeable without forcing a regional build.
			weighted.append(offer)
	return weighted

static func get_region_affinity(offer: Dictionary, region: RegionResource) -> int:
	if not region:
		return 0
	if offer.get("type") == "mutation":
		return 1 if offer.get("id", "") in region.favored_mutations else 0
	var resource: Resource = offer.get("resource")
	var tags: Array[String] = []
	if resource is SkillResource:
		tags = resource.tags
	elif resource is SupportResource:
		tags = resource.required_tags + resource.added_tags
	elif resource is PassiveResource:
		tags = resource.affected_tags
	for tag: String in tags:
		if tag in region.favored_tags:
			return 1
	return 0

static func _load_resources(dir_path: String) -> Array:
	var resources: Array = []
	for file_name in ResourceListing.get_resource_files(dir_path):
		var res := load(dir_path + file_name)
		if res:
			resources.append(res)
	return resources
