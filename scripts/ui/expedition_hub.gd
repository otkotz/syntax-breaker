class_name ExpeditionHub
extends Control

signal new_expedition_pressed(blood_omen: bool)
signal resume_pressed
signal back_pressed
signal artifacts_pressed
signal codex_pressed
signal forge_pressed

var new_button: Button
var resume_button: Button
var back_button: Button
var omen_button: Button
var reliquary_slots: Array[PanelContainer] = []
var secondary_tiles: Array[Button] = []
var objective_label: Label
var omen_cut_labels: Array[Label] = []
var _blood_omen_selected := false
var _level_label: Label
var _result_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()

func setup(profile: ExpeditionProfile, can_resume: bool, result: String = "") -> void:
	_level_label.text = "CHARACTER LEVEL %d" % profile.level
	resume_button.visible = can_resume
	_blood_omen_selected = false
	omen_button.visible = preload("res://scripts/expedition/blood_omen.gd").is_available(profile) and not can_resume
	var pity := clampi(int(profile.pity_counters.get(ExpeditionLootRoller.CHASE_PITY_KEY, 0)), 0, 5)
	for index in omen_cut_labels.size(): omen_cut_labels[index].text = "╱" if index < pity else "│"
	_update_omen_button()
	_result_label.text = _result_text(result)
	_result_label.visible = not result.is_empty()
	for index in reliquary_slots.size():
		var artifact := ArtifactCatalog.get_artifact(profile.equipped_artifact_ids[index])
		(reliquary_slots[index].get_child(0) as Label).text = artifact.display_name if artifact else "EMPTY SLOT"
	var missing := "COLLECTION COMPLETE"
	for id in ArtifactCatalog.all_ids():
		if not profile.owned_artifact_ids.has(id): missing = "NEXT HUNT  ·  %s" % ArtifactCatalog.get_artifact(id).display_name; break
	objective_label.text = missing

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = UITheme.C_BG
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 28)
	margin.add_child(content)

	var title := Label.new()
	title.text = "EXPEDITION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "BURNING GROUNDS · PROTOTYPE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	content.add_child(subtitle)

	_level_label = Label.new()
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.add_theme_font_size_override("font_size", 30)
	_level_label.add_theme_color_override("font_color", UITheme.C_SILVER)
	content.add_child(_level_label)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 28)
	_result_label.add_theme_color_override("font_color", UITheme.C_RARITY_LEGENDARY)
	content.add_child(_result_label)
	objective_label = Label.new()
	objective_label.name = "NextHuntObjective"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.custom_minimum_size.y = 64
	content.add_child(objective_label)
	var reliquary := GridContainer.new()
	reliquary.columns = 2
	reliquary.add_theme_constant_override("h_separation", 12)
	reliquary.add_theme_constant_override("v_separation", 12)
	content.add_child(reliquary)
	for index in ArtifactLoadout.SLOT_COUNT:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(300, 92)
		slot.add_theme_stylebox_override("panel", ExpeditionVisualTheme.make_frame())
		var label := Label.new()
		label.text = "EMPTY SLOT"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(label)
		reliquary.add_child(slot)
		reliquary_slots.append(slot)

	new_button = _make_button("NEW EXPEDITION")
	new_button.name = "NewExpeditionButton"
	new_button.pressed.connect(func() -> void: new_expedition_pressed.emit(_blood_omen_selected))
	content.add_child(new_button)
	omen_button = _make_button("BLOOD OMEN — OFF")
	omen_button.name = "BloodOmenButton"
	omen_button.pressed.connect(func() -> void:
		_blood_omen_selected = not _blood_omen_selected
		_update_omen_button()
	)
	content.add_child(omen_button)
	var omen_seal := HBoxContainer.new()
	omen_seal.alignment = BoxContainer.ALIGNMENT_CENTER
	omen_seal.add_theme_constant_override("separation", 12)
	content.add_child(omen_seal)
	for index in 5:
		var cut := Label.new()
		cut.text = "│"
		cut.add_theme_font_size_override("font_size", 32)
		cut.add_theme_color_override("font_color", ExpeditionVisualTheme.BLOOD)
		omen_seal.add_child(cut)
		omen_cut_labels.append(cut)

	resume_button = _make_button("RESUME EXPEDITION")
	resume_button.name = "ResumeExpeditionButton"
	resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	content.add_child(resume_button)
	var artifacts_button := _make_button("ARTIFACTS")
	artifacts_button.name = "ArtifactsButton"
	artifacts_button.pressed.connect(func() -> void: artifacts_pressed.emit())
	content.add_child(artifacts_button)
	var codex_button := _make_button("CODEX")
	codex_button.name = "CodexButton"
	codex_button.pressed.connect(func() -> void: codex_pressed.emit())
	content.add_child(codex_button)
	var forge_button := _make_button("EMBER FORGE")
	forge_button.name = "ForgeButton"
	forge_button.pressed.connect(func() -> void: forge_pressed.emit())
	content.add_child(forge_button)
	secondary_tiles.assign([codex_button, forge_button])

	back_button = _make_button("BACK")
	back_button.name = "BackButton"
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	content.add_child(back_button)

func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(600, 96)
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", UITheme.C_SILVER)
	return button

func _result_text(result: String) -> String:
	match result:
		"victory": return "EXPEDITION COMPLETE"
		"failed": return "EXPEDITION FAILED"
		"abandoned": return "EXPEDITION ABANDONED"
	return ""

func _update_omen_button() -> void:
	if omen_button != null: omen_button.text = "BLOOD OMEN — %s · +RISK · +CHASE CHANCE" % ("ON" if _blood_omen_selected else "OFF")
