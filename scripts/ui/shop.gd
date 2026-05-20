class_name Shop
extends Control

signal continue_pressed
signal skill_purchased(si: SkillInstance)

const OFFERING_COUNT := 4
const RARITY_COSTS := {
	"skill": {"common": 15, "uncommon": 20, "rare": 25},
	"support": {"common": 8, "uncommon": 12, "rare": 15},
	"passive": {"common": 10, "uncommon": 15, "rare": 20},
}

var _skill_instances: Array[SkillInstance]
var _reroll_cost: int = 2
var _offerings: Array[Dictionary] = []
var _pending_support: SupportResource = null

@onready var gold_label: Label = $MarginContainer/VBox/Header/GoldLabel
@onready var item_list: VBoxContainer = $MarginContainer/VBox/ScrollContainer/ItemList
@onready var reroll_button: Button = $MarginContainer/VBox/ButtonBar/RerollButton
@onready var manage_button: Button = $MarginContainer/VBox/ButtonBar/ManageButton
@onready var continue_button: Button = $MarginContainer/VBox/ButtonBar/ContinueButton
@onready var link_panel: PanelContainer = $MarginContainer/VBox/LinkPanel
@onready var link_container: VBoxContainer = $MarginContainer/VBox/LinkPanel/LinkContainer

var _skill_manager: SkillManagerUI

func _ready() -> void:
	reroll_button.pressed.connect(_on_reroll)
	manage_button.pressed.connect(_on_manage)
	continue_button.pressed.connect(func(): continue_pressed.emit())

func setup(skill_instances: Array[SkillInstance]) -> void:
	_skill_instances = skill_instances
	_generate_offerings()
	_refresh_ui()

func _generate_offerings() -> void:
	_offerings.clear()
	var pool: Array[Dictionary] = []

	for res: Resource in _load_resources("res://resources/skills/"):
		if res is SkillResource and MetaProgression.is_unlocked("skills", res.id):
			var owned := false
			for si: SkillInstance in _skill_instances:
				if si.base.id == res.id:
					owned = true
					break
			if not owned:
				pool.append({"type": "skill", "resource": res, "cost": _get_cost("skill", res.rarity)})

	for res: Resource in _load_resources("res://resources/supports/"):
		if res is SupportResource and MetaProgression.is_unlocked("supports", res.id):
			var already_owned := false
			for s: Resource in RunManager.owned_supports:
				if s is SupportResource and s.id == res.id:
					already_owned = true
					break
			if already_owned:
				if not RunManager.is_support_max_quality(res.id):
					pool.append({"type": "support_upgrade", "resource": res, "cost": _get_cost("support", res.rarity)})
			else:
				pool.append({"type": "support", "resource": res, "cost": _get_cost("support", res.rarity)})

	for res: Resource in _load_resources("res://resources/passives/"):
		if res is PassiveResource and MetaProgression.is_unlocked("passives", res.id):
			var owned := false
			for p: Resource in RunManager.owned_passives:
				if p is PassiveResource and p.id == res.id:
					owned = true
					break
			if not owned:
				pool.append({"type": "passive", "resource": res, "cost": _get_cost("passive", res.rarity)})

	pool.shuffle()
	for i in mini(OFFERING_COUNT, pool.size()):
		_offerings.append(pool[i])

func _load_resources(dir_path: String) -> Array:
	var resources: Array = []
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res := load(dir_path + file_name)
				if res:
					resources.append(res)
			file_name = dir.get_next()
	return resources

func _get_cost(item_type: String, rarity: String) -> int:
	return RARITY_COSTS.get(item_type, {}).get(rarity, 10)

func _refresh_ui() -> void:
	gold_label.text = "Gold: %d" % RunManager.gold
	reroll_button.text = "Reroll (%dg)" % _reroll_cost

	for child: Node in item_list.get_children():
		child.queue_free()

	for offering: Dictionary in _offerings:
		item_list.add_child(_create_card(offering))

func _create_card(offering: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 130.0
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	var type_label: String = offering["type"]
	if type_label == "support_upgrade":
		var q_level: int = RunManager.get_support_quality(offering["resource"].id) + 1
		type_label = "QUALITY %d/4" % q_level
	else:
		type_label = type_label.to_upper()
	title.text = "[%s] %s" % [type_label, offering["resource"].name]
	var desc := Label.new()
	var desc_text: String = offering["resource"].description
	if offering["type"] == "support_upgrade":
		var next_q: int = RunManager.get_support_quality(offering["resource"].id) + 1
		desc_text = "+%d%% modifier strength" % (next_q * 5)
		if next_q >= RunManager.MAX_QUALITY_LEVEL:
			var bonus_desc := StatCalculator.get_max_quality_description(offering["resource"].id)
			desc_text += "\nMAX BONUS: " + bonus_desc
	desc.text = desc_text
	desc.add_theme_font_size_override("font_size", 26)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(title)
	info.add_child(desc)
	hbox.add_child(info)

	var buy_btn := Button.new()
	buy_btn.text = "%dg" % offering["cost"]
	buy_btn.custom_minimum_size.x = 120.0
	buy_btn.pressed.connect(_on_buy.bind(offering))
	hbox.add_child(buy_btn)

	return panel

func _on_buy(offering: Dictionary) -> void:
	if not RunManager.spend_gold(offering["cost"]):
		return

	match offering["type"]:
		"skill":
			var si := SkillInstance.new(offering["resource"] as SkillResource)
			si.recompute(RunManager.owned_passives)
			skill_purchased.emit(si)
			GameBus.skill_acquired.emit(offering["resource"])
		"support":
			_pending_support = offering["resource"] as SupportResource
			RunManager.owned_supports.append(offering["resource"])
			GameBus.support_acquired.emit(offering["resource"])
			_show_link_panel()
		"support_upgrade":
			var support := offering["resource"] as SupportResource
			RunManager.upgrade_support_quality(support.id)
			_recompute_all_skills()
		"passive":
			RunManager.owned_passives.append(offering["resource"])
			_recompute_all_skills()
			GameBus.passive_acquired.emit(offering["resource"])

	_offerings.erase(offering)
	_refresh_ui()

func _show_link_panel() -> void:
	if not _pending_support:
		return
	link_panel.visible = true

	for child: Node in link_container.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "Link '%s' to:" % _pending_support.name
	link_container.add_child(header)

	for i in _skill_instances.size():
		var si := _skill_instances[i]
		if not TagMatcher.can_link_support(si.base, _pending_support):
			continue
		if si.linked_supports.size() >= si.base.max_supports:
			continue
		var btn := Button.new()
		btn.text = si.base.name
		btn.pressed.connect(_on_link_skill.bind(i))
		link_container.add_child(btn)

	var skip := Button.new()
	skip.text = "Skip"
	skip.pressed.connect(func():
		link_panel.visible = false
		_pending_support = null
	)
	link_container.add_child(skip)

func _on_link_skill(index: int) -> void:
	if _pending_support and index < _skill_instances.size():
		_skill_instances[index].link_support(_pending_support)
		_skill_instances[index].recompute(RunManager.owned_passives)
	_pending_support = null
	link_panel.visible = false

func _on_manage() -> void:
	if not _skill_manager:
		_skill_manager = preload("res://scenes/ui/skill_manager.tscn").instantiate() as SkillManagerUI
		add_child(_skill_manager)
		_skill_manager.closed.connect(func(): _refresh_ui())
	_skill_manager.open(_skill_instances, RunManager.owned_supports)

func _on_reroll() -> void:
	if not RunManager.spend_gold(_reroll_cost):
		return
	_reroll_cost += 1
	_generate_offerings()
	_refresh_ui()

func _recompute_all_skills() -> void:
	for si: SkillInstance in _skill_instances:
		si.recompute(RunManager.owned_passives)
