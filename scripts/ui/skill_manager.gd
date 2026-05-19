class_name SkillManagerUI
extends Control

@onready var skill_slots: VBoxContainer = $Panel/HSplit/SkillSlots
@onready var support_pool: VBoxContainer = $Panel/HSplit/SupportPool
@onready var close_button: Button = $Panel/CloseButton

var _skill_instances: Array[SkillInstance] = []
var _available_supports: Array[SupportResource] = []
var _selected_support: SupportResource = null

signal closed

func _ready() -> void:
	close_button.pressed.connect(func(): closed.emit(); hide())

func open(skill_instances: Array[SkillInstance], supports: Array) -> void:
	_skill_instances = skill_instances
	_available_supports = []
	for s in supports:
		if s is SupportResource:
			_available_supports.append(s)
	_selected_support = null
	_rebuild_ui()
	show()

func _rebuild_ui() -> void:
	_clear_children(skill_slots)
	_clear_children(support_pool)

	for si in _skill_instances:
		var skill_panel := _create_skill_panel(si)
		skill_slots.add_child(skill_panel)

	var header := Label.new()
	header.text = "Supports"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	support_pool.add_child(header)

	for support in _available_supports:
		var btn := Button.new()
		btn.text = support.name
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(_on_support_selected.bind(support))
		support_pool.add_child(btn)

func _on_support_selected(support: SupportResource) -> void:
	_selected_support = support

func _create_skill_panel(si: SkillInstance) -> VBoxContainer:
	var panel := VBoxContainer.new()
	var name_label := Label.new()
	name_label.text = si.base.name + " [" + ", ".join(si.base.tags) + "]"
	panel.add_child(name_label)

	for i in si.base.max_supports:
		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(0, 40)
		if i < si.linked_supports.size():
			var linked := si.linked_supports[i]
			slot_btn.text = linked.name
			slot_btn.pressed.connect(_unlink_support.bind(si, linked))
		else:
			slot_btn.text = "[Empty Slot]"
			slot_btn.pressed.connect(_link_selected_to.bind(si))
		panel.add_child(slot_btn)

	return panel

func _link_selected_to(si: SkillInstance) -> void:
	if _selected_support == null:
		return
	if si.link_support(_selected_support):
		_available_supports.erase(_selected_support)
		si.recompute(RunManager.owned_passives)
		_selected_support = null
		_rebuild_ui()

func _unlink_support(si: SkillInstance, support: SupportResource) -> void:
	si.unlink_support(support)
	_available_supports.append(support)
	si.recompute(RunManager.owned_passives)
	_rebuild_ui()

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
