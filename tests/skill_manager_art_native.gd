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

func has_text(node: Node, fragment: String) -> bool:
	if node is Label and (node as Label).text.contains(fragment):
		return true
	if node is Button and (node as Button).text.contains(fragment):
		return true
	for child: Node in node.get_children():
		if has_text(child, fragment):
			return true
	return false

func find_detail_button(node: Node) -> Button:
	if node is Button and node.get_meta("skill_details", false):
		return node as Button
	for child: Node in node.get_children():
		var found := find_detail_button(child)
		if found:
			return found
	return null

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var fireball := load("res://resources/skills/fireball.tres") as SkillResource
	var manager := preload("res://scenes/ui/skill_manager.tscn").instantiate() as SkillManagerUI
	manager.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(manager)
	await get_tree().process_frame
	var instance := SkillInstance.new(fireball)
	instance.set_rarity_tier("legendary")
	instance.set_evolution("solar_flare", 2)
	var pierce := load("res://resources/supports/pierce.tres") as SupportResource
	instance.link_support(pierce)
	manager.open([instance], [])
	await get_tree().process_frame
	check(has_texture(manager, fireball.icon), "Skill manager renders production artwork for equipped skills")
	var detail_button := find_detail_button(manager)
	check(detail_button != null and detail_button.custom_minimum_size.y >= 48.0, "Skill card header is a phone-sized detail touch target")
	if detail_button:
		detail_button.pressed.emit()
	check(manager._drawer.visible, "Tapping a skill opens its detail drawer")
	for fragment in [fireball.description, "Current stats", "Common x1.00", "Legendary x1.60", "Solar Flare I", "Solar Flare II — CURRENT", "Solar Flare III", pierce.description]:
		check(has_text(manager._drawer, fragment), "Skill detail drawer explains: " + fragment)
	manager._close_drawer()
	var socket_button: Button = null
	for node: Node in manager.find_children("*", "Button", true, false):
		if (node as Button).text.contains(pierce.name):
			socket_button = node as Button
			break
	if socket_button:
		socket_button.pressed.emit()
	check(manager._drawer.visible and manager._drawer_title.text != fireball.name.to_upper(), "Support socket keeps assignment behavior instead of opening skill details")
	manager.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: skill manager renders production skill artwork")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
