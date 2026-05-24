class_name MutationPicker
extends Control

signal mutation_chosen(mutation: Dictionary, skill_index: int)

var _mutations: Array[Dictionary] = []
var _skill_instances: Array[SkillInstance] = []
var _selected_mutation: Dictionary = {}

@onready var title_label: Label = $MarginContainer/VBox/TitleLabel
@onready var content: VBoxContainer = $MarginContainer/VBox/ScrollContainer/Content

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_viewport().set_input_as_handled()

func setup(skill_instances: Array[SkillInstance]) -> void:
	_skill_instances = skill_instances
	var exclude: Array = []
	for si: SkillInstance in skill_instances:
		for m: Dictionary in si.mutations:
			exclude.append(m["id"])
	_mutations = MutationData.roll_mutations(3, exclude)
	_show_mutations()

func _show_mutations() -> void:
	for child: Node in content.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "Choose a mutation for one of your skills:"
	header.add_theme_font_size_override("font_size", 30)
	header.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	header.autowrap_mode = TextServer.AUTOWRAP_WORD
	content.add_child(header)

	for mutation: Dictionary in _mutations:
		var btn := Button.new()
		btn.custom_minimum_size.y = 120.0
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.text = "%s\n%s" % [mutation["name"], mutation["desc"]]
		UITheme.style_button(btn, 26)
		btn.pressed.connect(func(): _on_mutation_selected(mutation))
		content.add_child(btn)

func _on_mutation_selected(mutation: Dictionary) -> void:
	_selected_mutation = mutation
	if _skill_instances.size() == 1:
		mutation_chosen.emit(mutation, 0)
		return
	_show_skill_picker()

func _show_skill_picker() -> void:
	for child: Node in content.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "Apply '%s' to which skill?" % _selected_mutation["name"]
	header.add_theme_font_size_override("font_size", 30)
	header.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	header.autowrap_mode = TextServer.AUTOWRAP_WORD
	content.add_child(header)

	for i in _skill_instances.size():
		var si := _skill_instances[i]
		var btn := Button.new()
		btn.custom_minimum_size.y = 100.0
		btn.text = si.base.name
		UITheme.style_button(btn, 28)
		var idx := i
		btn.pressed.connect(func(): mutation_chosen.emit(_selected_mutation, idx))
		content.add_child(btn)
