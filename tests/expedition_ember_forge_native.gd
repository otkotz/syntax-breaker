extends Node

var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _ready() -> void:
	ExpeditionManager.profile_path = "res://.godot/forge_profile.json"
	_cleanup()
	var migrated := ExpeditionProfile.from_dict({"schema_version": 3, "ember_shards": 12})
	check(migrated.forge_commitments.is_empty(), "Schema three migrates with no Forge commitments")
	check(not migrated.to_dict().has("damage") and not migrated.to_dict().has("health"), "Forge adds no raw-stat fields")
	ExpeditionManager.start_new_profile()
	ExpeditionManager.profile.ember_shards = 14
	check(not ExpeditionManager.buy_forge_commitment("treasure_choice"), "Insufficient shards cannot buy a commitment")
	ExpeditionManager.profile.ember_shards = 65
	var purchase_path := ExpeditionManager.profile_path
	var purchase_before := ExpeditionManager.profile.to_dict().duplicate(true)
	ExpeditionManager.profile_path = "res://missing_directory/forge_purchase.json"
	check(not ExpeditionManager.buy_forge_commitment("treasure_choice") and ExpeditionManager.profile.to_dict() == purchase_before, "Failed purchase save rolls shards and commitment back atomically")
	ExpeditionManager.profile_path = purchase_path
	check(ExpeditionManager.buy_forge_commitment("treasure_choice"), "Treasure Choice costs 15 shards")
	check(ExpeditionManager.profile.ember_shards == 50 and ExpeditionManager.profile.forge_commitments.get("treasure_choice", false), "Treasure Choice purchase is persisted")
	check(not ExpeditionManager.buy_forge_commitment("treasure_choice"), "Only one active copy can be owned")
	check(ExpeditionManager.buy_forge_commitment("discovery_ward") and ExpeditionManager.profile.ember_shards == 30, "Discovery Ward costs exactly 20 shards")
	check(ExpeditionManager.buy_forge_commitment("covenant_mark") and ExpeditionManager.profile.ember_shards == 0, "Covenant Mark costs exactly 30 shards")
	var before := ExpeditionManager.profile.to_dict().duplicate(true)
	var valid_path := ExpeditionManager.profile_path
	ExpeditionManager.profile_path = "res://missing_directory/forge.json"
	check(not ExpeditionManager.consume_forge_commitment("treasure_choice", "reward:1"), "Failed consumption save reports failure")
	check(ExpeditionManager.profile.to_dict() == before, "Failed consumption save rolls profile back atomically")
	ExpeditionManager.profile_path = valid_path
	check(ExpeditionManager.consume_forge_commitment("treasure_choice", "reward:1"), "Commitment consumes after a reward checkpoint")
	check(not ExpeditionManager.profile.forge_commitments.has("treasure_choice"), "Consumed commitment is single-use")

	var ui: Control = preload("res://scenes/ui/ember_forge.tscn").instantiate() as Control
	add_child(ui)
	ui.setup(ExpeditionManager.profile)
	check(ui.action_buttons.size() == 3, "Forge exposes exactly three commitments")
	for button: Button in ui.action_buttons:
		check(button.custom_minimum_size.y >= 88.0, "Forge actions are touch-sized")
	check(ui.action_buttons[0].text.contains("15") and ui.action_buttons[1].text.contains("20") and ui.action_buttons[2].text.contains("30"), "Forge shows exact costs")
	var purchases: Array[String] = []
	ui.purchase_requested.connect(func(id: String) -> void: purchases.append(id))
	ui.action_buttons[0].pressed.emit()
	check(purchases.is_empty() and ui.action_buttons[0].text.contains("CONFIRM"), "Forge purchase requires confirmation")
	var back := InputEventKey.new()
	back.keycode = KEY_ESCAPE
	back.pressed = true
	ui._unhandled_input(back)
	check(purchases.is_empty(), "Android back cancels confirmation without purchasing")
	ui.action_buttons[0].pressed.emit()
	ui.action_buttons[0].pressed.emit()
	check(purchases == ["treasure_choice"], "Confirmed Forge action emits once")
	ui.queue_free()
	_cleanup()
	print(JSON.stringify({"failures": failures}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = ExpeditionManager.profile_path + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
