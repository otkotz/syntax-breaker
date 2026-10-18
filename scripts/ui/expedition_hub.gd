class_name ExpeditionHub
extends Control

signal new_expedition_pressed
signal resume_pressed
signal back_pressed
signal artifacts_pressed
signal codex_pressed
signal forge_pressed

var new_button: Button
var resume_button: Button
var back_button: Button
var _level_label: Label
var _result_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()

func setup(profile: ExpeditionProfile, can_resume: bool, result: String = "") -> void:
	_level_label.text = "CHARACTER LEVEL %d" % profile.level
	resume_button.visible = can_resume
	_result_label.text = _result_text(result)
	_result_label.visible = not result.is_empty()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = UITheme.C_BG
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_top", 180)
	margin.add_theme_constant_override("margin_bottom", 120)
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

	new_button = _make_button("NEW EXPEDITION")
	new_button.name = "NewExpeditionButton"
	new_button.pressed.connect(func() -> void: new_expedition_pressed.emit())
	content.add_child(new_button)

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
