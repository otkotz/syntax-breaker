extends Node

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	var session := ExpeditionSession.create(1101, "burning_grounds", [])
	var map := ExpeditionMapUI.new()
	add_child(map)
	map.setup(session)
	check(map.connector_count == _edge_count(session.layout), "Map draws every real graph connector")
	check(map.connector_thickness == 8.0, "Map connectors are 8 px")
	check(map.detail_sheet != null and map.enter_button != null and map.enter_button.disabled, "Pinned detail sheet owns a separate disabled Enter action")
	var available := session.get_available_room_ids()[0]
	var chosen := [""]
	map.room_chosen.connect(func(id: String): chosen[0] = id)
	(map.room_buttons[available] as Button).pressed.emit()
	check(chosen[0].is_empty() and map.selected_room_id == available and not map.enter_button.disabled, "First tap previews without entering")
	check(map.detail_label.text.contains("THREAT") and map.detail_label.text.contains("REWARD"), "Room sheet labels threat and reward family")
	map.enter_button.pressed.emit()
	check(chosen[0] == available, "Enter confirms selected room")
	for button: Button in map.room_buttons.values(): check(button.custom_minimum_size.x >= 120.0 and button.custom_minimum_size.y >= 120.0, "Node hit area is at least 120 square")
	map.queue_free()

	var profile := ExpeditionProfile.fresh()
	profile.equipped_artifact_ids = ["furnace_heart", "ashen_needle", "", ""]
	profile.discovered_artifact_ids = ["furnace_heart", "ashen_needle"]
	var hub := ExpeditionHub.new()
	add_child(hub)
	hub.setup(profile, false)
	check(hub.reliquary_slots.size() == 4 and hub.secondary_tiles.size() == 2, "Hub has 2x2 reliquary and two secondary tiles")
	check(hub.objective_label.visible and not hub.objective_label.text.is_empty(), "Hub shows next hunt without scrolling")
	hub.queue_free()

	var codex := ExpeditionCodexUI.new()
	add_child(codex)
	codex.setup(profile)
	for button: Button in codex.filter_buttons.values(): check(button.custom_minimum_size.y >= 64.0 and button.custom_minimum_size.y <= 72.0, "Codex filter chips are compact")
	for card: Button in codex.card_buttons.values(): check(card.custom_minimum_size.y == 136.0, "Codex cards retain 136 px rhythm")
	codex.queue_free()

	profile.ember_shards = 0
	var forge := EmberForgeUI.new()
	add_child(forge)
	forge.setup(profile)
	check(forge.action_buttons.all(func(button: Button): return button.text.contains("INSUFFICIENT")), "Forge labels insufficient actions")
	profile.ember_shards = 999
	forge.setup(profile)
	check(forge.action_buttons.all(func(button: Button): return button.text.contains("READY")), "Forge labels ready actions")
	forge.action_buttons[0].pressed.emit()
	check(forge.action_buttons[0].text.contains("ACTIVE"), "Forge confirmation uses active state")
	forge.queue_free()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _edge_count(layout: DungeonLayout) -> int:
	var count := 0
	for targets: Array in layout.edges.values(): count += targets.size()
	return count
