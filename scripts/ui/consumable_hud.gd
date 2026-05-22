class_name ConsumableHUD
extends HBoxContainer

var _manager: ConsumableManager
var _buttons: Array[Button] = []

func setup(manager: ConsumableManager) -> void:
	_manager = manager
	_manager.consumable_used.connect(_on_consumable_used)
	_manager.effect_expired.connect(func(_t: String): _refresh())
	_refresh()

func _refresh() -> void:
	for btn: Button in _buttons:
		btn.queue_free()
	_buttons.clear()

	for i in _manager.get_slot_count():
		var info := _manager.get_slot_info(i)
		if info.is_empty():
			continue
		var res: ConsumableResource = info["resource"]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 80)
		btn.text = "%s\nx%d" % [res.name, info["charges"]]
		btn.add_theme_font_size_override("font_size", 22)
		var idx := i
		btn.pressed.connect(func(): _manager.use_consumable(idx))
		add_child(btn)
		_buttons.append(btn)

func _on_consumable_used(_index: int) -> void:
	_refresh()
