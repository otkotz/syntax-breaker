extends Node

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	MetaProgression.save_path = "res://.godot/menu_touch_meta.json"
	var menu := MainMenu.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	var passed := true
	for button in [menu._asc_down, menu._asc_up, menu._region_prev, menu._region_next]:
		if button.size.x < 80.0 or button.size.y < 80.0 or not is_zero_approx(button.rotation):
			push_error("Menu controls need at least 80px upright touch targets")
			passed = false
	if menu._region_sub.get_theme_font_size("font_size") < 24 or menu._asc_desc.get_theme_font_size("font_size") < 24:
		push_error("Menu explanatory labels need readable phone typography")
		passed = false
	RunManager.ascension_level = 0
	MetaProgression.highest_ascension_unlocked[""] = 15
	MetaProgression.ascension_level = 0
	menu._change_ascension(10)
	if not menu._asc_desc.text.contains("HP +150%") or not menu._asc_desc.text.contains("Damage +100%") or not menu._asc_desc.text.contains("Speed +30%"):
		push_error("Menu must preview selected Ascension, not the previous run level")
		passed = false
	if RunManager.ascension_level != 0:
		push_error("Previewing Ascension must not mutate the active run")
		passed = false
	if passed:
		print("PASS: readable menu typography and upright 80px touch controls")
	get_tree().quit(0 if passed else 1)
