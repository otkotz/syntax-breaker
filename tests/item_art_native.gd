extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func has_texture(node: Node, texture: Texture2D) -> bool:
	if node is TextureRect and node.texture == texture:
		return true
	for child in node.get_children():
		if has_texture(child, texture):
			return true
	return false

func _ready() -> void:
	call_deferred("run_checks")

func has_mastery_badge(node: Node) -> bool:
	if node is Label and node.text == "MASTERY":
		return node.get_theme_font_size("font_size") >= 16 and node.mouse_filter == Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if has_mastery_badge(child):
			return true
	return false

# Catches art being available only in the shop, missing resource bindings,
# and revealing undiscovered Codex items through their illustration.
func run_checks() -> void:
	RunManager.save_path = "res://.godot/art_test_run.json"
	MetaProgression.save_path = "res://.godot/art_test_meta.json"
	RunTelemetry.enabled = false
	RunManager.start_run()
	RunManager.skill_slots_unlocked = 0
	MetaProgression.unlocked_items = {"skills": [], "supports": [], "passives": ["ward_capacity"]}
	var ward := load("res://resources/passives/ward_capacity.tres") as PassiveResource
	var pierce := load("res://resources/supports/pierce.tres") as SupportResource
	var mastery := load("res://resources/passives/pierce_mastery.tres") as PassiveResource
	check(mastery.icon == pierce.icon, "Mastery shares its matching support art, not an unrelated generic icon")
	var reward = load("res://scenes/ui/reward_picker.tscn").instantiate()
	get_tree().root.add_child(reward)
	var no_skills: Array[SkillInstance] = []
	reward.setup(StageData.Type.COMBAT, no_skills)
	var ward_button: Button
	for button: Button in reward.reward_container.get_children():
		if button.text.contains("Ward Core"):
			ward_button = button
	check(ward_button != null and ward_button.icon == ward.icon, "Reward choice shows its actual passive art")
	var choices := [0]
	reward.reward_chosen.connect(func(_offer): choices[0] += 1)
	await get_tree().process_frame
	await get_tree().process_frame
	if ward_button:
		click(ward_button.get_global_rect().get_center())
		await get_tree().process_frame
		check(choices[0] == 1, "Illustrated reward remains a selectable whole-card button")
	reward.queue_free()
	var manager := SkillManagerUI.new()
	for button: Button in [manager._build_inv_item(pierce), manager._build_slot_row(true, pierce, Color.WHITE), manager._build_drawer_item(pierce, false)]:
		check(button.icon == pierce.icon, "Support art is visible in inventory, sockets and assignment drawer")
		check(button.expand_icon and button.get_theme_constant("icon_max_width") <= 96, "Inventory art is bounded instead of using source PNG dimensions")
		button.free()
	var host := VBoxContainer.new()
	RunManager.owned_passives = [ward, mastery]
	manager._build_passives_section(host)
	check(has_texture(host, ward.icon), "Owned passive list shows passive illustration")
	check(has_texture(host, pierce.icon), "Owned mastery list shows matching support illustration")
	check(has_mastery_badge(host), "Mastery thumbnail has readable identification and does not intercept input")
	host.free()
	manager.free()
	var codex := CodexUI.new()
	var entry: Dictionary = codex._get_entries("supports").filter(func(e): return e.id == "pierce")[0]
	entry.discovered = true
	var card := codex._create_entry_card(entry)
	check(has_texture(card, pierce.icon), "Discovered Codex entry shows support art")
	card.free()
	entry.discovered = false
	card = codex._create_entry_card(entry)
	check(not has_texture(card, pierce.icon), "Undiscovered Codex entry does not leak art")
	card.free()
	codex.free()
	var legendary = load("res://scenes/ui/legendary_picker.tscn").instantiate()
	get_tree().root.add_child(legendary)
	var illustrated_choices: Array[PassiveResource] = [ward]
	legendary._build_ui(illustrated_choices)
	check(legendary.content.get_child(0).icon == ward.icon, "Legendary choice renderer uses the actual passive art")
	var mastery_choices: Array[PassiveResource] = [mastery]
	legendary._build_ui(mastery_choices)
	check(has_mastery_badge(legendary.content.get_child(-1)), "Illustrated mastery choice has a readable badge, not only shared support art")
	legendary.queue_free()
	var unlocks := UnlockTreeUI.new()
	var unlock_entry: Dictionary = unlocks._get_all_items("supports").filter(func(e): return e.id == "pierce")[0]
	card = unlocks._create_card(unlock_entry, "supports", true)
	check(has_texture(card, pierce.icon), "Unlocked item collection shows its illustration")
	card.free()
	card = unlocks._create_card(unlock_entry, "supports", false)
	check(not has_texture(card, pierce.icon), "Locked collection card does not leak illustration")
	card.free()
	unlocks.free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: illustrated rewards, support inventory/socket/drawer, owned passives/masteries and Codex discovery privacy")
	else:
		for message in failures:
			push_error(message)
	get_tree().quit(0 if failures.is_empty() else 1)

func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_tree().root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	get_tree().root.push_input(event, true)
