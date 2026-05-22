class_name LegendaryPicker
extends Control

signal legendary_chosen(passive: PassiveResource)

@onready var title_label: Label = $MarginContainer/VBox/TitleLabel
@onready var content: VBoxContainer = $MarginContainer/VBox/ScrollContainer/Content

func setup(skill_instances: Array[SkillInstance]) -> void:
	var legendaries := _get_available_legendaries()
	legendaries.shuffle()
	var choices := legendaries.slice(0, mini(3, legendaries.size()))

	if choices.is_empty():
		legendary_chosen.emit(null)
		return

	_build_ui(choices)

func _get_available_legendaries() -> Array[PassiveResource]:
	var result: Array[PassiveResource] = []
	var dir := DirAccess.open("res://resources/passives/")
	if not dir:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://resources/passives/" + file_name)
			if res is PassiveResource and res.rarity == "legendary":
				if not MetaProgression.is_unlocked("passives", res.id):
					file_name = dir.get_next()
					continue
				var owned := false
				for p: Resource in RunManager.owned_passives:
					if p is PassiveResource and p.id == res.id:
						owned = true
						break
				if not owned:
					result.append(res)
		file_name = dir.get_next()
	return result

func _build_ui(choices: Array[PassiveResource]) -> void:
	for child: Node in content.get_children():
		child.queue_free()

	for passive: PassiveResource in choices:
		var btn := Button.new()
		btn.custom_minimum_size.y = 180.0
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.text = "★ %s\n%s" % [passive.name, passive.description]
		btn.pressed.connect(func():
			RunManager.owned_passives.append(passive)
			GameBus.passive_acquired.emit(passive)
			legendary_chosen.emit(passive)
		)
		content.add_child(btn)
