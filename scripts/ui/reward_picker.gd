class_name RewardPicker
extends Control

signal reward_chosen(reward: Dictionary)

var _skill_instances: Array[SkillInstance]
var _chosen := false

@onready var title_label: Label = $MarginContainer/VBox/TitleLabel
@onready var reward_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/RewardContainer

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_viewport().set_input_as_handled()

func setup(stage_type: StageData.Type, skill_instances: Array[SkillInstance] = []) -> void:
	_skill_instances = skill_instances
	var is_elite := stage_type == StageData.Type.ELITE
	var is_boss := stage_type == StageData.Type.BOSS
	if title_label:
		if is_boss:
			title_label.text = "Boss Defeated! Pick a Reward"
		elif is_elite:
			title_label.text = "Elite Cleared! Pick a Reward"
		else:
			title_label.text = "Stage Clear! Pick a Reward"
	_build_rewards(is_elite or is_boss)

func _build_rewards(high_quality: bool) -> void:
	for child: Node in reward_container.get_children():
		child.queue_free()

	var rewards := _roll_rewards(high_quality)
	for reward: Dictionary in rewards:
		var btn := Button.new()
		btn.custom_minimum_size.y = 150.0
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.text = _format_reward(reward)
		UITheme.style_button(btn, 26)
		btn.pressed.connect(_on_reward_pressed.bind(reward))
		reward_container.add_child(btn)

func _on_reward_pressed(reward: Dictionary) -> void:
	if _chosen:
		return
	_chosen = true
	for btn: Node in reward_container.get_children():
		if btn is Button:
			btn.disabled = true
	if reward.get("type") == "mutation" and _skill_instances.size() > 1:
		_show_skill_target(reward)
	else:
		if reward.get("type") == "mutation" and _skill_instances.size() == 1:
			reward["skill_index"] = 0
		reward_chosen.emit(reward)

func _show_skill_target(reward: Dictionary) -> void:
	for child: Node in reward_container.get_children():
		child.queue_free()
	if title_label:
		var m: Dictionary = reward["mutation"]
		title_label.text = "Apply '%s' to which skill?" % m["name"]
	for i in _skill_instances.size():
		var si := _skill_instances[i]
		var btn := Button.new()
		btn.custom_minimum_size.y = 120.0
		btn.text = si.base.name
		UITheme.style_button(btn, 28)
		var idx := i
		btn.pressed.connect(func():
			reward["skill_index"] = idx
			reward_chosen.emit(reward)
		)
		reward_container.add_child(btn)

func _roll_rewards(high_quality: bool) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	var types := ["skill", "support", "passive", "gold"]
	if _skill_instances.size() > 0:
		types.append("mutation")
	types.shuffle()

	for i in 3:
		var rtype: String = types[i % types.size()]
		var reward := _try_roll(rtype, high_quality, rewards)
		if reward.is_empty():
			reward = _roll_fallback(high_quality, rewards)
		rewards.append(reward)

	return rewards

func _roll_fallback(high_quality: bool, existing: Array[Dictionary]) -> Dictionary:
	var quality_up := _roll_support_quality(existing)
	if not quality_up.is_empty():
		return quality_up
	if _skill_instances.size() > 0:
		var mutation := _roll_mutation(existing)
		if not mutation.is_empty():
			return mutation
	return _roll_gold(high_quality)

func _try_roll(rtype: String, high_quality: bool, existing: Array[Dictionary]) -> Dictionary:
	match rtype:
		"skill":
			return _roll_skill(existing)
		"support":
			var s := _roll_support(existing)
			if s.is_empty():
				return _roll_support_quality(existing)
			return s
		"passive":
			return _roll_passive(existing)
		"mutation":
			return _roll_mutation(existing)
		"gold":
			return _roll_gold(high_quality)
	return {}

func _roll_skill(existing: Array[Dictionary]) -> Dictionary:
	var existing_skill_count := 0
	for e: Dictionary in existing:
		if e.get("type") == "skill":
			existing_skill_count += 1
	if _skill_instances.size() + existing_skill_count >= RunManager.skill_slots_unlocked:
		return {}

	var owned_ids: Dictionary = {}
	for si: SkillInstance in _skill_instances:
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

func _roll_support(existing: Array[Dictionary]) -> Dictionary:
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

func _roll_passive(existing: Array[Dictionary]) -> Dictionary:
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

func _roll_support_quality(existing: Array[Dictionary]) -> Dictionary:
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

func _roll_mutation(existing: Array[Dictionary]) -> Dictionary:
	var exclude_ids: Array = []
	for si: SkillInstance in _skill_instances:
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

func _roll_gold(high_quality: bool) -> Dictionary:
	var amount := randi_range(10, 25)
	if high_quality:
		amount = randi_range(25, 50)
	return {"type": "gold", "amount": amount}

func _format_reward(reward: Dictionary) -> String:
	match reward.get("type", ""):
		"skill":
			var res: SkillResource = reward["resource"]
			return "NEW SKILL: %s\n%s  [%s]" % [res.name, res.description, ", ".join(res.tags)]
		"support":
			var res: SupportResource = reward["resource"]
			return "SUPPORT: %s\n%s" % [res.name, res.description]
		"passive":
			var res: PassiveResource = reward["resource"]
			return "PASSIVE: %s\n%s" % [res.name, res.description]
		"support_quality":
			var res: SupportResource = reward["resource"]
			var q: int = RunManager.get_support_quality(res.id) + 1
			var desc_text := "+%d%% modifier strength" % (q * 5)
			if q >= RunManager.MAX_QUALITY_LEVEL:
				var bonus := StatCalculator.get_max_quality_description(res.id)
				if not bonus.is_empty():
					desc_text += "\nMAX: " + bonus
			return "QUALITY %d/4: %s\n%s" % [q, res.name, desc_text]
		"mutation":
			var m: Dictionary = reward["mutation"]
			return "MUTATION: %s\n%s" % [m["name"], m["desc"]]
		"gold":
			return "GOLD\n+%d gold" % reward["amount"]
	return "???"

func _load_resources(dir_path: String) -> Array:
	var resources: Array = []
	for file_name in ResourceListing.get_resource_files(dir_path):
		var res := load(dir_path + file_name)
		if res:
			resources.append(res)
	return resources
