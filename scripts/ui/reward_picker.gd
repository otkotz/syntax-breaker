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

	var rewards := RewardRoller.roll(_skill_instances, high_quality)
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
