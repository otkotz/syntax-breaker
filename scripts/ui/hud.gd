class_name HUD
extends Control

@onready var hp_bar: ProgressBar = $TopBar/HPBar
@onready var hp_label: Label = $TopBar/HPBar/HPLabel
@onready var shield_bar: ProgressBar = $TopBar/ShieldBar
@onready var shield_label: Label = $TopBar/ShieldBar/ShieldLabel
@onready var gold_label: Label = $InfoPanel/GoldLabel
@onready var stage_label: Label = $InfoPanel/StageLabel
@onready var cooldown_container: HBoxContainer = $BottomBar/CooldownContainer

var _player: Player
var _pause_btn: Button
var _wave_label: Label
var _wave_progress: ProgressBar
var _modifier_row: HBoxContainer
var _modifier_details: Label
var _shown_modifiers: Array[String] = []
var _modifier_timer := 0.0
var _boss_bar: ProgressBar
var _synergy_label: Label
var _synergy_timer := 0.0
var _synergy_cooldown := 0.0
var _boss_phase_label: Label
var _boss_phase_timer: float = 0.0
var _keystone_label: Label
var _keystone_timer: float = 0.0
var _keystone_cooldown: float = 0.0

const C_BRONZE_LINE := UITheme.C_V_LINE
const C_BRONZE_HI := UITheme.C_V_BRIGHT
const C_GOLD := UITheme.C_SILVER
const MODIFIER_SYMBOLS := {
	"swift": ">>", "tough": "+HP", "swarming": "+++",
	"deadly": "ATK", "enriched": "2G", "cursed": "SLO",
	"elite_patrol": "EL", "denial_reinforcement": "ZONE",
	"shield_reinforcement": "SH",
}

func setup(player: Player) -> void:
	_player = player
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.18, 0.55, 0.25)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	_player.hp_changed.connect(_on_hp_changed)
	_on_hp_changed(player.current_hp, player.max_hp)
	var shield_fill := StyleBoxFlat.new()
	shield_fill.bg_color = Color(0.12, 0.55, 0.75)
	shield_bar.add_theme_stylebox_override("fill", shield_fill)
	_player.shield_changed.connect(_on_shield_changed)
	_on_shield_changed(player.current_shield, player.max_shield)
	_on_gold_changed(RunManager.gold)
	GameBus.gold_changed.connect(_on_gold_changed)
	_update_stage()
	_build_pause_button()
	_wave_label = Label.new()
	_wave_label.position = Vector2(180, 80)
	_wave_label.size = Vector2(720, 32)
	_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_label.add_theme_font_size_override("font_size", 24)
	add_child(_wave_label)
	_wave_progress = ProgressBar.new()
	_wave_progress.position = Vector2(180, 112)
	_wave_progress.max_value = 1.0
	_wave_progress.show_percentage = false
	_wave_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var progress_background := StyleBoxFlat.new()
	progress_background.bg_color = Color(0.04, 0.02, 0.08, 0.85)
	_wave_progress.add_theme_stylebox_override("background", progress_background)
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = C_BRONZE_HI
	_wave_progress.add_theme_stylebox_override("fill", progress_fill)
	add_child(_wave_progress)
	# Set the compact height after entering the tree and receiving the HUD theme.
	_wave_progress.size = Vector2(720, 8)
	_modifier_row = HBoxContainer.new()
	_modifier_row.position = Vector2(180, 124)
	_modifier_row.size = Vector2(720, 48)
	_modifier_row.add_theme_constant_override("separation", 6)
	_modifier_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modifier_row)
	_modifier_details = Label.new()
	_modifier_details.position = Vector2(180, 378)
	_modifier_details.size = Vector2(720, 84)
	_modifier_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modifier_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modifier_details.add_theme_font_size_override("font_size", 22)
	add_child(_modifier_details)
	_boss_bar = ProgressBar.new()
	_boss_bar.position = Vector2(180, 178)
	_boss_bar.size = Vector2(720, 28)
	_boss_bar.show_percentage = true
	_boss_bar.visible = false
	add_child(_boss_bar)
	_synergy_label = Label.new()
	_synergy_label.position = Vector2(180, 214)
	_synergy_label.add_theme_font_size_override("font_size", 28)
	_synergy_label.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)
	add_child(_synergy_label)
	GameBus.synergy_triggered.connect(_on_synergy)
	_boss_phase_label = Label.new()
	_boss_phase_label.position = Vector2(180, 254)
	_boss_phase_label.size = Vector2(720, 70)
	_boss_phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boss_phase_label.add_theme_font_size_override("font_size", 24)
	add_child(_boss_phase_label)
	GameBus.boss_phase_changed.connect(_on_boss_phase)
	_keystone_label = Label.new()
	_keystone_label.position = Vector2(180, 330)
	_keystone_label.add_theme_font_size_override("font_size", 24)
	add_child(_keystone_label)
	GameBus.keystone_triggered.connect(_on_keystone)

func _on_keystone(display_name: String) -> void:
	if _keystone_cooldown > 0.0:
		return
	_keystone_label.text = display_name.to_upper()
	_keystone_timer = 1.5
	_keystone_cooldown = 2.0

func _on_boss_phase(message: String) -> void:
	_boss_phase_label.text = message
	_boss_phase_timer = 4.0

func _on_synergy(synergy_name: String) -> void:
	if _synergy_cooldown > 0.0:
		return
	_synergy_label.text = synergy_name.to_upper()
	_synergy_timer = 1.5
	_synergy_cooldown = 2.0

func _process(delta: float) -> void:
	if is_instance_valid(_player):
		var recharge_text := " | RECHARGE %.1fs" % _player._shield_recharge_remaining if _player._shield_recharge_remaining > 0.0 else ""
		shield_label.text = "SHIELD %d / %d%s" % [ceili(_player.current_shield), ceili(_player.max_shield), recharge_text]
	_modifier_timer = maxf(0.0, _modifier_timer - delta)
	if _modifier_details and _modifier_timer == 0.0:
		_modifier_details.text = ""
	_keystone_timer = maxf(0.0, _keystone_timer - delta)
	_keystone_cooldown = maxf(0.0, _keystone_cooldown - delta)
	if _keystone_label and _keystone_timer == 0.0:
		_keystone_label.text = ""
	_boss_phase_timer = maxf(0.0, _boss_phase_timer - delta)
	if _boss_phase_label and _boss_phase_timer == 0.0:
		_boss_phase_label.text = ""
	_synergy_timer = maxf(0.0, _synergy_timer - delta)
	_synergy_cooldown = maxf(0.0, _synergy_cooldown - delta)
	if _synergy_label and _synergy_timer == 0.0:
		_synergy_label.text = ""
	if not _boss_bar:
		return
	_boss_bar.visible = false
	for boss: Node in get_tree().get_nodes_in_group("bosses"):
		if boss is EnemyBase and boss.is_alive():
			_boss_bar.max_value = boss.max_hp
			_boss_bar.value = boss.current_hp
			_boss_bar.visible = true
			break

func update_wave(seconds: float, progress: float, remaining: int) -> void:
	if _wave_label:
		_wave_label.text = "%ds | %d%% | %d enemies" % [ceili(seconds), roundi(progress * 100), remaining]
		_wave_progress.value = clampf(progress, 0.0, 1.0)
		_update_modifiers()

func _update_modifiers() -> void:
	var modifiers: Array[String] = []
	if RunManager.current_stage_data:
		for id: String in RunManager.current_stage_data.modifiers:
			if StageData.MODIFIER_DATA.has(id) and not modifiers.has(id):
				modifiers.append(id)
	if modifiers == _shown_modifiers:
		return
	_shown_modifiers = modifiers
	_modifier_timer = 0.0
	_modifier_details.text = ""
	for child: Node in _modifier_row.get_children():
		_modifier_row.remove_child(child)
		child.queue_free()
	for id: String in modifiers:
		var data: Dictionary = StageData.MODIFIER_DATA[id]
		var button := Button.new()
		button.text = MODIFIER_SYMBOLS.get(id, "?")
		button.custom_minimum_size = Vector2(68, 48)
		button.add_theme_font_size_override("font_size", 20)
		button.tooltip_text = "%s: %s" % [data.label, data.desc]
		button.pressed.connect(_show_modifier.bind(button.tooltip_text))
		_modifier_row.add_child(button)

func _show_modifier(description: String) -> void:
	_modifier_details.text = description
	_modifier_timer = 5.0

func _on_shield_changed(current: float, maximum: float) -> void:
	shield_bar.max_value = maxf(1.0, maximum)
	shield_bar.value = current

func _on_hp_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "HP %d / %d" % [ceili(current), ceili(maximum)]

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
	ns.bg_color = Color(0.04, 0.02, 0.08, 0.85)
	ns.border_color = C_BRONZE_LINE
	ns.set_border_width_all(2)
	ns.set_content_margin_all(8)
	ns.shadow_color = Color(0, 0, 0, 0.4)
	ns.shadow_size = 6
	_pause_btn.add_theme_stylebox_override("normal", ns)

	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.06, 0.03, 0.14, 0.9)
	hs.border_color = UITheme.C_V_BRIGHT
	hs.set_border_width_all(2)
	hs.set_content_margin_all(8)
	_pause_btn.add_theme_stylebox_override("hover", hs)

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.03, 0.01, 0.06, 0.9)
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
