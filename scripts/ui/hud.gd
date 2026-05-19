class_name HUD
extends Control

@onready var hp_bar: ProgressBar = $TopBar/HPBar
@onready var gold_label: Label = $InfoPanel/GoldLabel
@onready var stage_label: Label = $InfoPanel/StageLabel
@onready var cooldown_container: HBoxContainer = $BottomBar/CooldownContainer

var _player: Player

func setup(player: Player) -> void:
	_player = player
	_player.hp_changed.connect(_on_hp_changed)
	GameBus.gold_changed.connect(_on_gold_changed)
	_update_stage()

func _on_hp_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current

func _on_gold_changed(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount

func _update_stage() -> void:
	var stage_type := ""
	if RunManager.current_stage_data:
		stage_type = " - " + RunManager.current_stage_data.get_type_name()
	stage_label.text = "Stage %d/%d%s" % [RunManager.current_stage, StageGenerator.MAX_DEPTH, stage_type]

func update_cooldowns(skill_instances: Array[SkillInstance], timers: Array[float]) -> void:
	for i in mini(skill_instances.size(), cooldown_container.get_child_count()):
		var bar: ProgressBar = cooldown_container.get_child(i) as ProgressBar
		if bar:
			bar.max_value = skill_instances[i].computed_stats.get("cooldown", 1.0)
			bar.value = max(timers[i], 0.0)
