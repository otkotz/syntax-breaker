extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func has_texture(node: Node, texture: Texture2D) -> bool:
	if node is TextureRect and (node as TextureRect).texture == texture:
		return true
	for child: Node in node.get_children():
		if has_texture(child, texture):
			return true
	return false

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var fireball := load("res://resources/skills/fireball.tres") as SkillResource
	var manager := preload("res://scenes/ui/skill_manager.tscn").instantiate() as SkillManagerUI
	manager.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(manager)
	await get_tree().process_frame
	manager.open([SkillInstance.new(fireball)], [])
	await get_tree().process_frame
	check(has_texture(manager, fireball.icon), "Skill manager renders production artwork for equipped skills")
	manager.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: skill manager renders production skill artwork")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
