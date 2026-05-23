class_name StageChoice
extends Control

signal stage_chosen(stage: StageData)

@onready var title_label: Label = $MarginContainer/VBox/TitleLabel
@onready var depth_label: Label = $MarginContainer/VBox/DepthLabel
@onready var choice_container: VBoxContainer = $MarginContainer/VBox/ScrollContainer/ChoiceContainer

func setup(choices: Array[StageData], current_depth: int) -> void:
	if depth_label:
		depth_label.text = "Depth %d / %d" % [current_depth, StageGenerator.MAX_DEPTH]
	_build_buttons(choices)

func _build_buttons(choices: Array[StageData]) -> void:
	for child: Node in choice_container.get_children():
		child.queue_free()

	if choices.size() == 1:
		var stage := choices[0]
		_add_choice_button(stage)
		return

	for stage: StageData in choices:
		_add_choice_button(stage)

func _add_choice_button(stage: StageData) -> void:
	var btn := Button.new()
	btn.custom_minimum_size.y = 180.0
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD

	var text := stage.get_type_name()
	text += "\n" + stage.get_description()
	var mod_text := stage.get_modifier_text()
	if not mod_text.is_empty():
		text += "\n[" + mod_text + "]"

	btn.text = text
	UITheme.style_button(btn, 26)
	btn.pressed.connect(func(): stage_chosen.emit(stage))
	choice_container.add_child(btn)
