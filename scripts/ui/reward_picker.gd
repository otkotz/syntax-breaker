class_name RewardPicker
extends Control

signal reward_chosen(reward: Dictionary)

@onready var title_label: Label = $MarginContainer/VBox/TitleLabel
@onready var reward_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/RewardContainer

func setup(stage_type: StageData.Type) -> void:
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
		btn.pressed.connect(func(): reward_chosen.emit(reward))
		reward_container.add_child(btn)

func _roll_rewards(high_quality: bool) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	var types := ["skill", "support", "passive", "gold"]
	types.shuffle()

	for i in 3:
		var rtype: String = types[i % types.size()]
		var reward := _try_roll(rtype, high_quality, rewards)
		if reward.is_empty():
			reward = _roll_gold(high_quality)
		rewards.append(reward)

	return rewards

func _try_roll(rtype: String, high_quality: bool, existing: Array[Dictionary]) -> Dictionary:
	match rtype:
		"skill":
			return _roll_skill(existing)
		"support":
			return _roll_support(existing)
		"passive":
			return _roll_passive(existing)
		"gold":
			return _roll_gold(high_quality)
	return {}

func _roll_skill(existing: Array[Dictionary]) -> Dictionary:
	var all := _load_resources("res://resources/skills/")
	all.shuffle()
	for res: Resource in all:
		if not res is SkillResource:
			continue
		if not MetaProgression.is_unlocked("skills", res.id):
			continue
		var dupe := false
		for e: Dictionary in existing:
			if e.get("type") == "skill" and e.get("id") == res.id:
				dupe = true
				break
		if dupe:
			continue
		return {"type": "skill", "id": res.id, "resource": res}
	return {}

func _roll_support(existing: Array[Dictionary]) -> Dictionary:
	var all := _load_resources("res://resources/supports/")
	all.shuffle()
	for res: Resource in all:
		if not res is SupportResource:
			continue
		if not MetaProgression.is_unlocked("supports", res.id):
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
		"gold":
			return "GOLD\n+%d gold" % reward["amount"]
	return "???"

func _load_resources(dir_path: String) -> Array:
	var resources: Array = []
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res := load(dir_path + file_name)
				if res:
					resources.append(res)
			file_name = dir.get_next()
	return resources
