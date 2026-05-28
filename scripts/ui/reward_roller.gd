class_name RewardRoller
extends RefCounted

static func roll(skill_instances: Array[SkillInstance], high_quality: bool) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	var types := ["skill", "support", "passive", "gold"]
	if skill_instances.size() > 0:
		types.append("mutation")
	types.shuffle()

	for i in 3:
		var rtype: String = types[i % types.size()]
		var reward := _try_roll(rtype, high_quality, rewards, skill_instances)
		if reward.is_empty():
			reward = _roll_fallback(high_quality, rewards, skill_instances)
		rewards.append(reward)

	return rewards

static func _roll_fallback(high_quality: bool, existing: Array[Dictionary], skill_instances: Array[SkillInstance]) -> Dictionary:
	var quality_up := _roll_support_quality(existing)
	if not quality_up.is_empty():
		return quality_up
	if skill_instances.size() > 0:
		var mutation := _roll_mutation(existing, skill_instances)
		if not mutation.is_empty():
			return mutation
	return _roll_gold(high_quality)

static func _try_roll(rtype: String, high_quality: bool, existing: Array[Dictionary], skill_instances: Array[SkillInstance]) -> Dictionary:
	match rtype:
		"skill":
			return _roll_skill(existing, skill_instances)
		"support":
			var s := _roll_support(existing)
			if s.is_empty():
				return _roll_support_quality(existing)
			return s
		"passive":
			return _roll_passive(existing)
		"mutation":
			return _roll_mutation(existing, skill_instances)
		"gold":
			return _roll_gold(high_quality)
	return {}

static func _roll_skill(existing: Array[Dictionary], skill_instances: Array[SkillInstance]) -> Dictionary:
	var existing_skill_count := 0
	for e: Dictionary in existing:
		if e.get("type") == "skill":
			existing_skill_count += 1
	if skill_instances.size() + existing_skill_count >= RunManager.skill_slots_unlocked:
		return {}

	var owned_ids: Dictionary = {}
	for si: SkillInstance in skill_instances:
		owned_ids[si.base.id] = true

	var all := _load_resources("res://resources/skills/")
	all.shuffle()
	for res: Resource in all:
		var skill_res := res as SkillResource
		if not skill_res:
			continue
		if not MetaProgression.is_unlocked("skills", skill_res.id):
			continue
		if owned_ids.has(skill_res.id):
			continue
		var dupe := false
		for e: Dictionary in existing:
			if e.get("type") == "skill" and e.get("id") == skill_res.id:
				dupe = true
				break
		if dupe:
			continue
		return {"type": "skill", "id": skill_res.id, "resource": skill_res}
	return {}

static func _roll_support(existing: Array[Dictionary]) -> Dictionary:
	var all := _load_resources("res://resources/supports/")
	all.shuffle()
	for res: Resource in all:
		if not res is SupportResource:
			continue
		if not MetaProgression.is_unlocked("supports", res.id):
			continue
		var already_owned := false
		for s: Resource in RunManager.owned_supports:
			if s is SupportResource and s.id == res.id:
				already_owned = true
				break
		if already_owned:
			continue
		var dupe := false
		for e: Dictionary in existing:
			if e.get("type") == "support" and e.get("id") == res.id:
				dupe = true
				break
		if dupe:
			continue
		return {"type": "support", "id": res.id, "resource": res}
	return {}

static func _roll_passive(existing: Array[Dictionary]) -> Dictionary:
	var all := _load_resources("res://resources/passives/")
	all.shuffle()
	for res: Resource in all:
		if not res is PassiveResource:
			continue
		if not MetaProgression.is_unlocked("passives", res.id):
			continue
		var owned := false
		for p: Resource in RunManager.owned_passives:
			if p is PassiveResource and p.id == res.id:
				owned = true
				break
		if owned:
			continue
		var dupe := false
		for e: Dictionary in existing:
			if e.get("type") == "passive" and e.get("id") == res.id:
				dupe = true
				break
		if dupe:
			continue
		return {"type": "passive", "id": res.id, "resource": res}
	return {}

static func _roll_support_quality(existing: Array[Dictionary]) -> Dictionary:
	var upgradeable: Array[SupportResource] = []
	for s: Resource in RunManager.owned_supports:
		if s is SupportResource and not RunManager.is_support_max_quality(s.id):
			var dupe := false
			for e: Dictionary in existing:
				if e.get("type") == "support_quality" and e.get("id") == s.id:
					dupe = true
					break
			if not dupe:
				upgradeable.append(s)
	if upgradeable.is_empty():
		return {}
	upgradeable.shuffle()
	var pick := upgradeable[0]
	return {"type": "support_quality", "id": pick.id, "resource": pick}

static func _roll_mutation(existing: Array[Dictionary], skill_instances: Array[SkillInstance]) -> Dictionary:
	var exclude_ids: Array = []
	for si: SkillInstance in skill_instances:
		for m: Dictionary in si.mutations:
			exclude_ids.append(m["id"])
	for e: Dictionary in existing:
		if e.get("type") == "mutation":
			exclude_ids.append(e.get("id", ""))
	var available := MutationData.roll_mutations(1, exclude_ids)
	if available.is_empty():
		return {}
	var m: Dictionary = available[0]
	return {"type": "mutation", "id": m["id"], "mutation": m}

static func _roll_gold(high_quality: bool) -> Dictionary:
	var amount := randi_range(10, 25)
	if high_quality:
		amount = randi_range(25, 50)
	return {"type": "gold", "amount": amount}

static func _load_resources(dir_path: String) -> Array:
	var resources: Array = []
	for file_name in ResourceListing.get_resource_files(dir_path):
		var res := load(dir_path + file_name)
		if res:
			resources.append(res)
	return resources
