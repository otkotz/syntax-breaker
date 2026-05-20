class_name SkillManagerUI
extends Control

@onready var skill_slots: VBoxContainer = $Panel/HSplit/SkillSlots
@onready var support_pool: VBoxContainer = $Panel/HSplit/SupportPool
@onready var close_button: Button = $Panel/CloseButton

var _skill_instances: Array[SkillInstance] = []
var _available_supports: Array[SupportResource] = []
var _active_slot: Dictionary = {}

signal closed

func _ready() -> void:
	close_button.pressed.connect(func(): closed.emit(); hide())

func open(skill_instances: Array[SkillInstance], supports: Array) -> void:
	_skill_instances = skill_instances
	_available_supports = []
	for s in supports:
		if s is SupportResource:
			_available_supports.append(s)
	_active_slot = {}
	_rebuild_ui()
	show()

func _rebuild_ui() -> void:
	_clear_children(skill_slots)
	_clear_children(support_pool)
	_build_skill_panels()
	if _active_slot.is_empty():
		_build_support_overview()
	else:
		_build_slot_choices()

func _build_skill_panels() -> void:
	for si in _skill_instances:
		var panel := VBoxContainer.new()
		panel.add_theme_constant_override("separation", 4)

		var name_label := Label.new()
		name_label.text = si.base.name
		name_label.add_theme_font_size_override("font_size", 30)
		panel.add_child(name_label)

		var tag_label := Label.new()
		tag_label.text = ", ".join(si.base.tags)
		tag_label.add_theme_font_size_override("font_size", 22)
		tag_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		panel.add_child(tag_label)

		for i in si.base.max_supports:
			var slot_btn := Button.new()
			slot_btn.custom_minimum_size = Vector2(0, 44)

			var is_active: bool = _active_slot.get("skill") == si and _active_slot.get("index") == i

			if i < si.linked_supports.size():
				var linked := si.linked_supports[i]
				var q: int = RunManager.get_support_quality(linked.id)
				var q_str := " (Q%d)" % q if q > 0 else ""
				slot_btn.text = linked.name + q_str
				if is_active:
					slot_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			else:
				slot_btn.text = "+ Add Support"
				slot_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				if is_active:
					slot_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))

			slot_btn.pressed.connect(_on_slot_clicked.bind(si, i))
			panel.add_child(slot_btn)

		var sep := HSeparator.new()
		panel.add_child(sep)
		skill_slots.add_child(panel)

func _on_slot_clicked(si: SkillInstance, index: int) -> void:
	if _active_slot.get("skill") == si and _active_slot.get("index") == index:
		_active_slot = {}
	else:
		_active_slot = {"skill": si, "index": index}
	_rebuild_ui()

func _build_support_overview() -> void:
	var header := Label.new()
	header.text = "Tap a slot to manage"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	support_pool.add_child(header)

	if _available_supports.is_empty():
		var empty := Label.new()
		empty.text = "No unlinked supports"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		support_pool.add_child(empty)
		return

	var pool_label := Label.new()
	pool_label.text = "Unlinked (%d)" % _available_supports.size()
	pool_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	support_pool.add_child(pool_label)

	for support in _available_supports:
		var lbl := Label.new()
		var q: int = RunManager.get_support_quality(support.id)
		var q_str := " Q%d" % q if q > 0 else ""
		lbl.text = "  %s%s" % [support.name, q_str]
		lbl.add_theme_font_size_override("font_size", 24)
		support_pool.add_child(lbl)
		if RunManager.is_support_max_quality(support.id):
			var bonus := Label.new()
			bonus.text = "    MAX: " + StatCalculator.get_max_quality_description(support.id)
			bonus.add_theme_font_size_override("font_size", 20)
			bonus.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			bonus.autowrap_mode = TextServer.AUTOWRAP_WORD
			support_pool.add_child(bonus)

func _build_slot_choices() -> void:
	var si: SkillInstance = _active_slot["skill"]
	var index: int = _active_slot["index"]
	var has_support := index < si.linked_supports.size()
	var current_support: SupportResource = si.linked_supports[index] if has_support else null

	var header := Label.new()
	header.text = "%s — Slot %d" % [si.base.name, index + 1]
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	support_pool.add_child(header)

	if current_support:
		var current_label := Label.new()
		var q: int = RunManager.get_support_quality(current_support.id)
		var q_str := " (Q%d)" % q if q > 0 else ""
		current_label.text = "Current: %s%s" % [current_support.name, q_str]
		current_label.add_theme_font_size_override("font_size", 24)
		support_pool.add_child(current_label)

		var desc_label := Label.new()
		desc_label.text = current_support.description
		desc_label.add_theme_font_size_override("font_size", 20)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		support_pool.add_child(desc_label)

		if RunManager.is_support_max_quality(current_support.id):
			var bonus_label := Label.new()
			bonus_label.text = "MAX: " + StatCalculator.get_max_quality_description(current_support.id)
			bonus_label.add_theme_font_size_override("font_size", 20)
			bonus_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			support_pool.add_child(bonus_label)

		var remove_btn := Button.new()
		remove_btn.text = "Remove"
		remove_btn.custom_minimum_size = Vector2(0, 40)
		remove_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		remove_btn.pressed.connect(_remove_from_slot.bind(si, current_support))
		support_pool.add_child(remove_btn)

		var sep := HSeparator.new()
		support_pool.add_child(sep)

	var swap_label := Label.new()
	swap_label.text = "Assign:" if not current_support else "Swap with:"
	swap_label.add_theme_font_size_override("font_size", 24)
	swap_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	support_pool.add_child(swap_label)

	var compatible := TagMatcher.get_linkable_supports(si.base, _available_supports)
	if compatible.is_empty():
		var none := Label.new()
		none.text = "No compatible supports"
		none.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		support_pool.add_child(none)
	else:
		for support: SupportResource in compatible:
			var entry := VBoxContainer.new()
			var btn := Button.new()
			var q: int = RunManager.get_support_quality(support.id)
			var q_str := " (Q%d)" % q if q > 0 else ""
			btn.text = support.name + q_str
			btn.custom_minimum_size = Vector2(0, 44)
			btn.pressed.connect(_assign_to_slot.bind(si, index, support, current_support))
			entry.add_child(btn)

			var desc := Label.new()
			desc.text = support.description
			desc.add_theme_font_size_override("font_size", 20)
			desc.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD
			entry.add_child(desc)

			if RunManager.is_support_max_quality(support.id):
				var bonus := Label.new()
				bonus.text = "MAX: " + StatCalculator.get_max_quality_description(support.id)
				bonus.add_theme_font_size_override("font_size", 20)
				bonus.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
				bonus.autowrap_mode = TextServer.AUTOWRAP_WORD
				entry.add_child(bonus)

			support_pool.add_child(entry)

func _assign_to_slot(si: SkillInstance, index: int, new_support: SupportResource, old_support: SupportResource) -> void:
	if old_support:
		si.unlink_support(old_support)
		_available_supports.append(old_support)
	_available_supports.erase(new_support)
	si.linked_supports.insert(mini(index, si.linked_supports.size()), new_support)
	si.recompute(RunManager.owned_passives)
	_active_slot = {}
	_rebuild_ui()

func _remove_from_slot(si: SkillInstance, support: SupportResource) -> void:
	si.unlink_support(support)
	_available_supports.append(support)
	si.recompute(RunManager.owned_passives)
	_active_slot = {}
	_rebuild_ui()

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
