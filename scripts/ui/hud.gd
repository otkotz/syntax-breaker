class_name HUD
extends Control

@onready var hp_bar: ProgressBar = $TopBar/HPBar
@onready var gold_label: Label = $InfoPanel/GoldLabel
@onready var stage_label: Label = $InfoPanel/StageLabel
@onready var cooldown_container: HBoxContainer = $BottomBar/CooldownContainer

var _player: Player
var _pause_btn: Button

const C_BRONZE_LINE := Color(0.38, 0.30, 0.19)
const C_BRONZE_HI := Color(0.78, 0.68, 0.48)
const C_GOLD := Color(0.94, 0.87, 0.65)

func setup(player: Player) -> void:
	_player = player
	_player.hp_changed.connect(_on_hp_changed)
	GameBus.gold_changed.connect(_on_gold_changed)
	_update_stage()
	_build_pause_button()

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

func _build_pause_button() -> void:
	_pause_btn = Button.new()
	_pause_btn.text = "⚙"
	_pause_btn.custom_minimum_size = Vector2(64, 64)
	_pause_btn.add_theme_font_size_override("font_size", 32)
	_pause_btn.add_theme_color_override("font_color", C_BRONZE_HI)
	_pause_btn.add_theme_color_override("font_hover_color", C_GOLD)

	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0.10, 0.07, 0.05, 0.85)
	ns.border_color = C_BRONZE_LINE
	ns.set_border_width_all(2)
	ns.set_content_margin_all(8)
	ns.shadow_color = Color(0, 0, 0, 0.4)
	ns.shadow_size = 6
	_pause_btn.add_theme_stylebox_override("normal", ns)

	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.14, 0.10, 0.07, 0.9)
	hs.border_color = Color(0.56, 0.45, 0.28)
	hs.set_border_width_all(2)
	hs.set_content_margin_all(8)
	_pause_btn.add_theme_stylebox_override("hover", hs)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.07, 0.05, 0.03, 0.9)
	ps.border_color = C_BRONZE_LINE
	ps.set_border_width_all(2)
	ps.set_content_margin_all(8)
	_pause_btn.add_theme_stylebox_override("pressed", ps)

	_pause_btn.anchors_preset = PRESET_TOP_LEFT
	_pause_btn.position = Vector2(16, 80)
	_pause_btn.pressed.connect(_on_pause_pressed)
	add_child(_pause_btn)

func _on_pause_pressed() -> void:
	get_tree().paused = true

	var caster: SkillCaster = _player.get_node("SkillCaster") if _player else null
	if not caster:
		get_tree().paused = false
		return

	var mgr := preload("res://scenes/ui/skill_manager.tscn").instantiate() as SkillManagerUI
	mgr.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(mgr)
	mgr.open(caster.skill_instances, RunManager.owned_supports)
	mgr.closed.connect(func() -> void:
		mgr.queue_free()
		get_tree().paused = false
	, CONNECT_ONE_SHOT)
