class_name DebugMenu
extends CanvasLayer

var _panel: PanelContainer
var _visible := false
var _stats_label: Label
var _player: Player

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_visible = not _visible
		_panel.visible = _visible
		get_tree().paused = _visible

func setup(player: Player) -> void:
	_player = player

func _process(_delta: float) -> void:
	if not _visible:
		return
	_update_stats()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.offset_left = 10
	_panel.offset_top = 80
	_panel.offset_right = 520
	_panel.offset_bottom = 900
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.012, 0.031, 0.95)
	panel_style.border_color = UITheme.C_V_LINE
	panel_style.set_border_width_all(1)
	panel_style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "DEBUG (F1)"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)
	vbox.add_child(title)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 24)
	_stats_label.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	vbox.add_child(_stats_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_add_button(vbox, "Kill All Enemies", func():
		for e: Node in get_tree().get_nodes_in_group("enemies"):
			if e.has_method("is_alive") and e.is_alive() and e.has_method("take_damage"):
				e.take_damage(99999.0)
	)
	_add_button(vbox, "+100 Gold", func(): RunManager.add_gold(100))
	_add_button(vbox, "Full Heal", func():
		if _player:
			_player.current_hp = _player.max_hp
			_player.hp_changed.emit(_player.current_hp, _player.max_hp)
	)
	_add_button(vbox, "+50% Crit Chance", func():
		if not _player:
			return
		var caster := _player.get_node("SkillCaster") as SkillCaster
		if not caster:
			return
		for si in caster.skill_instances:
			si.computed_stats["crit_chance"] = si.computed_stats.get("crit_chance", 0.05) + 0.5
	)
	_add_button(vbox, "Toggle God Mode", func():
		if _player:
			_player.set_meta("god_mode", not _player.get_meta("god_mode", false))
	)
	_add_button(vbox, "Skip Stage", func():
		for e: Node in get_tree().get_nodes_in_group("enemies"):
			if e.has_method("is_alive") and e.is_alive() and e.has_method("take_damage"):
				e.take_damage(99999.0)
	)
	_add_button(vbox, "Manage Skills", func():
		if not _player:
			return
		var caster := _player.get_node("SkillCaster") as SkillCaster
		if not caster or caster.skill_instances.is_empty():
			return
		var mgr := preload("res://scenes/ui/skill_manager.tscn").instantiate() as SkillManagerUI
		add_child(mgr)
		mgr.open(caster.skill_instances, RunManager.owned_supports)
		mgr.closed.connect(func():
			mgr.queue_free()
			for si in caster.skill_instances:
				si.recompute(RunManager.owned_passives)
		, CONNECT_ONE_SHOT)
	)
	_add_button(vbox, "Add All Supports (Max Q)", func():
		for file_name in ResourceListing.get_resource_files("res://resources/supports/"):
				var support := load("res://resources/supports/" + file_name) as SupportResource
				if support:
					var already_owned := false
					for s: Resource in RunManager.owned_supports:
						if s is SupportResource and s.id == support.id:
							already_owned = true
							break
					if not already_owned:
						RunManager.owned_supports.append(support)
					RunManager.support_quality[support.id] = RunManager.MAX_QUALITY_LEVEL
	)

func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	UITheme.style_button(btn, 24)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func _update_stats() -> void:
	var fps := Engine.get_frames_per_second()
	var enemies := get_tree().get_nodes_in_group("enemies")
	var alive := 0
	for e: Node in enemies:
		if e.visible:
			alive += 1

	var stage_type := ""
	if RunManager.current_stage_data:
		stage_type = " (%s)" % RunManager.current_stage_data.get_type_name()
		var mods := RunManager.current_stage_data.get_modifier_text()
		if not mods.is_empty():
			stage_type += " [%s]" % mods
	var text := "FPS: %d\n" % fps
	text += "Stage: %d/%d%s\n" % [RunManager.current_stage, StageGenerator.MAX_DEPTH, stage_type]
	text += "Gold: %d\n" % RunManager.gold
	text += "Enemies: %d alive\n" % alive
	if _player:
		text += "HP: %.0f / %.0f\n" % [_player.current_hp, _player.max_hp]
		text += "Pos: %.0f, %.0f\n" % [_player.global_position.x, _player.global_position.y]
		text += "God Mode: %s\n" % str(_player.get_meta("god_mode", false))
	text += "\nRun Stats:\n"
	text += "  Kills: %d\n" % RunManager.run_stats.get("enemies_killed", 0)
	text += "  Crits: %d\n" % RunManager.run_stats.get("crits_landed", 0)
	text += "  Elites: %d\n" % RunManager.run_stats.get("elites_cleared", 0)
	text += "  Projectiles: %d\n" % RunManager.run_stats.get("projectiles_fired", 0)
	text += "  Best Combo: %d\n" % RunManager.run_stats.get("best_combo", 0)
	text += "  Combo Mult: x%.1f\n" % ComboTracker.current_multiplier
	text += "  Stage Mult: x%.2f\n" % (1.0 + RunManager.current_stage * 0.05)
	_stats_label.text = text
