class_name SkillPicker
extends Control

signal skill_chosen(skill: SkillResource)

@onready var title_label: Label = $MarginContainer/VBox/TitleLabel
@onready var skill_list: VBoxContainer = $MarginContainer/VBox/ScrollContainer/SkillList

func _ready() -> void:
	_populate()

func _populate() -> void:
	var dir := DirAccess.open("res://resources/skills/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://resources/skills/" + file_name)
			if res is SkillResource:
				_add_skill_button(res as SkillResource)
		file_name = dir.get_next()

func _add_skill_button(skill: SkillResource) -> void:
	var btn := Button.new()
	btn.custom_minimum_size.y = 130.0
	btn.text = "%s\n%s  [%s]" % [skill.name, skill.description, ", ".join(skill.tags)]
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	btn.pressed.connect(func(): skill_chosen.emit(skill))
	skill_list.add_child(btn)
