class_name Shop
extends Control

signal continue_pressed
signal skill_purchased(si: SkillInstance)
signal skill_swapped(old_si: SkillInstance, new_si: SkillInstance)

const OFFERING_COUNT := 8
const RARITY_COSTS := {
	"skill": {"common": 15, "uncommon": 20, "rare": 25},
	"support": {"common": 8, "uncommon": 12, "rare": 15},
	"passive": {"common": 10, "uncommon": 15, "rare": 20, "legendary": 40},
}

var _skill_instances: Array[SkillInstance]
var _reroll_cost: int = 2
var _offerings: Array[Dictionary] = []
var _pending_support: SupportResource = null
var _pending_skill_instance: SkillInstance = null

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

	var owned_skill_ids: Dictionary = {}
	for si: SkillInstance in _skill_instances:
		owned_skill_ids[si.base.id] = true

	for res: Resource in _load_resources("res://resources/skills/"):
		var skill_res := res as SkillResource
		if skill_res and MetaProgression.is_unlocked("skills", skill_res.id) and not owned_skill_ids.has(skill_res.id):
			pool.append({"type": "skill", "resource": skill_res, "cost": _get_cost("skill", skill_res.rarity)})

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

	var legendary_pool: Array[Dictionary] = []
	for res: Resource in _load_resources("res://resources/passives/"):
		if res is PassiveResource and MetaProgression.is_unlocked("passives", res.id):
			var owned := false
			for p: Resource in RunManager.owned_passives:
				if p is PassiveResource and p.id == res.id:
					owned = true
					break
			if not owned:
				if res.rarity == "legendary":
					legendary_pool.append({"type": "passive", "resource": res, "cost": _get_cost("passive", res.rarity)})
				else:
					pool.append({"type": "passive", "resource": res, "cost": _get_cost("passive", res.rarity)})

	var legendary_added := false
	if RunManager.current_stage >= 5 and legendary_pool.size() > 0 and randf() < 1.0 / 15.0:
		legendary_pool.shuffle()
		_offerings.append(legendary_pool[0])
		legendary_added = true

	for upgrade_def: Dictionary in STAT_UPGRADES:
		_offerings.append(_make_stat_upgrade(upgrade_def))

	pool.shuffle()
	var count := mini(OFFERING_COUNT - (1 if legendary_added else 0) - STAT_UPGRADES.size(), pool.size())
	for i in count:
		_offerings.append(pool[i])

func _load_resources(dir_path: String) -> Array:
	var resources: Array = []
	for file_name in ResourceListing.get_resource_files(dir_path):
		var res := load(dir_path + file_name)
		if res:
			resources.append(res)
	return resources

const STAT_UPGRADES := [
	{"key": "damage", "name": "Flat Damage", "amount": 5.0, "base_cost": 30, "cost_step": 10,
	 "fmt": "+%.0f damage to all skills (current: +%.0f)"},
	{"key": "cooldown", "name": "Haste", "amount": -0.08, "base_cost": 35, "cost_step": 12,
	 "fmt": "-%.0f%% cooldown (current: %.0f%% reduction)"},
	{"key": "crit_chance", "name": "Precision", "amount": 0.04, "base_cost": 40, "cost_step": 15,
	 "fmt": "+%.0f%% crit chance (current: +%.0f%%)"},
]

func _make_stat_upgrade(upgrade_def: Dictionary) -> Dictionary:
	var key: String = upgrade_def["key"]
	var current: float = RunManager.shop_bonuses.get(key, 0.0)
	var times_bought: int = int(absf(current) / absf(upgrade_def["amount"]))
	var cost: int = upgrade_def["base_cost"] + times_bought * upgrade_def["cost_step"]
	return {"type": "stat_upgrade", "cost": cost, "upgrade": upgrade_def}

func _get_cost(item_type: String, rarity: String) -> int:
	return RARITY_COSTS.get(item_type, {}).get(rarity, 10)

func _refresh_ui() -> void:
	gold_label.text = "Gold: %d" % RunManager.gold
	gold_label.add_theme_color_override("font_color", UITheme.C_SILVER)
	reroll_button.text = "Reroll (%dg)" % _reroll_cost
	UITheme.style_button(reroll_button, 28)
	UITheme.style_button(manage_button, 28)
	UITheme.style_button(continue_button, 28)

	for child: Node in item_list.get_children():
		child.queue_free()

	for offering: Dictionary in _offerings:
		item_list.add_child(_create_card(offering))

func _create_card(offering: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 130.0

	var is_upgrade := offering["type"] == "stat_upgrade"
	var rarity := "rare" if is_upgrade else (offering["resource"].rarity if "rarity" in offering["resource"] else "common")
	var rarity_color := UITheme.get_rarity_color(rarity)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.C_CARD_BG
	sb.border_color = Color(rarity_color, 0.5)
	sb.set_border_width_all(1)
	sb.border_width_left = 3
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	var rarity_label := Label.new()
	var desc := Label.new()

	if is_upgrade:
		var upg: Dictionary = offering["upgrade"]
		var key: String = upg["key"]
		var current: float = RunManager.shop_bonuses.get(key, 0.0)
		title.text = "[UPGRADE] %s" % upg["name"]
		rarity_label.text = "UPGRADE"
		var display_amount := absf(upg["amount"])
		var display_current := absf(current)
		if key != "damage":
			display_amount *= 100.0
			display_current *= 100.0
		desc.text = upg["fmt"] % [display_amount, display_current]
	else:
		var type_label: String = offering["type"]
		if type_label == "support_upgrade":
			var q_level: int = RunManager.get_support_quality(offering["resource"].id) + 1
			type_label = "QUALITY %d/4" % q_level
		else:
			type_label = type_label.to_upper()
		title.text = "[%s] %s" % [type_label, offering["resource"].name]
		rarity_label.text = rarity.to_upper()
		var desc_text: String = offering["resource"].description
		if offering["type"] == "support_upgrade":
			var next_q: int = RunManager.get_support_quality(offering["resource"].id) + 1
			desc_text = "+%d%% modifier strength" % (next_q * 5)
			if next_q >= RunManager.MAX_QUALITY_LEVEL:
				var bonus_desc := StatCalculator.get_max_quality_description(offering["resource"].id)
				desc_text += "\nMAX BONUS: " + bonus_desc
		desc.text = desc_text

	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", UITheme.C_SILVER)
	rarity_label.add_theme_font_size_override("font_size", 22)
	rarity_label.add_theme_color_override("font_color", rarity_color)
	desc.add_theme_font_size_override("font_size", 26)
	desc.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_child(title)
	info.add_child(rarity_label)
	info.add_child(desc)
	hbox.add_child(info)

	var buy_btn := Button.new()
	buy_btn.text = "%dg" % offering["cost"]
	buy_btn.custom_minimum_size.x = 120.0
	UITheme.style_button(buy_btn, 26)
	buy_btn.pressed.connect(_on_buy.bind(offering))
	hbox.add_child(buy_btn)

	return panel

func _on_buy(offering: Dictionary) -> void:
	if offering not in _offerings:
		return
	if not RunManager.spend_gold(offering["cost"]):
		return

	_offerings.erase(offering)

	match offering["type"]:
		"skill":
			var si := SkillInstance.new(offering["resource"] as SkillResource)
			si.recompute(RunManager.owned_passives)
			if _skill_instances.size() >= RunManager.skill_slots_unlocked:
				_pending_skill_instance = si
				_show_swap_panel()
			else:
				_skill_instances.append(si)
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
		"stat_upgrade":
			var upg: Dictionary = offering["upgrade"]
			var key: String = upg["key"]
			var current: float = RunManager.shop_bonuses.get(key, 0.0)
			RunManager.shop_bonuses[key] = current + upg["amount"]
			_recompute_all_skills()
			_offerings.append(_make_stat_upgrade(upg))
	_refresh_ui()

func _show_link_panel() -> void:
	if not _pending_support:
		return
	link_panel.visible = true

	for child: Node in link_container.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "Link '%s' to:" % _pending_support.name
	header.add_theme_font_size_override("font_size", 30)
	header.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)
	link_container.add_child(header)

	for i in _skill_instances.size():
		var si := _skill_instances[i]
		if not TagMatcher.can_link_support(si.base, _pending_support):
			continue
		if si.linked_supports.size() >= si.base.max_supports:
			continue
		var btn := Button.new()
		btn.text = si.base.name
		UITheme.style_button(btn, 28)
		btn.pressed.connect(_on_link_skill.bind(i))
		link_container.add_child(btn)

	var skip := Button.new()
	skip.text = "Skip"
	UITheme.style_button(skip, 28)
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

func _show_swap_panel() -> void:
	if not _pending_skill_instance:
		return
	link_panel.visible = true

	for child: Node in link_container.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "Replace which skill?"
	header.add_theme_font_size_override("font_size", 30)
	header.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)
	link_container.add_child(header)

	var new_label := Label.new()
	new_label.text = "New: %s" % _pending_skill_instance.base.name
	new_label.add_theme_font_size_override("font_size", 26)
	new_label.add_theme_color_override("font_color", UITheme.C_SILVER)
	link_container.add_child(new_label)

	for i in _skill_instances.size():
		var si := _skill_instances[i]
		var incompatible := _count_incompatible_supports(si, _pending_skill_instance.base)
		var btn := Button.new()
		btn.text = si.base.name
		if incompatible > 0:
			btn.text += "  (%d support%s unlinked)" % [incompatible, "" if incompatible == 1 else "s"]
		UITheme.style_button(btn, 28)
		btn.pressed.connect(_on_swap_skill.bind(i))
		link_container.add_child(btn)

	var cancel := Button.new()
	cancel.text = "Cancel"
	UITheme.style_button(cancel, 28)
	cancel.pressed.connect(func():
		link_panel.visible = false
		if _pending_skill_instance:
			_offerings.append({"type": "skill", "resource": _pending_skill_instance.base, "cost": _get_cost("skill", _pending_skill_instance.base.rarity)})
			RunManager.add_gold(_get_cost("skill", _pending_skill_instance.base.rarity))
		_pending_skill_instance = null
		_refresh_ui()
	)
	link_container.add_child(cancel)

func _on_swap_skill(index: int) -> void:
	if not _pending_skill_instance or index >= _skill_instances.size():
		_pending_skill_instance = null
		link_panel.visible = false
		return

	var old_si := _skill_instances[index]
	var new_si := _pending_skill_instance
	var new_skill := new_si.base

	var kept: Array[SupportResource] = []
	for support: SupportResource in old_si.linked_supports:
		if TagMatcher.can_link_support(new_skill, support):
			kept.append(support)

	for support in kept:
		new_si.link_support(support)
	new_si.recompute(RunManager.owned_passives)

	_skill_instances[index] = new_si
	skill_swapped.emit(old_si, new_si)
	GameBus.skill_acquired.emit(new_skill)

	_pending_skill_instance = null
	link_panel.visible = false
	_refresh_ui()

func _count_incompatible_supports(old_si: SkillInstance, new_skill: SkillResource) -> int:
	var count := 0
	for support: SupportResource in old_si.linked_supports:
		if not TagMatcher.can_link_support(new_skill, support):
			count += 1
	return count

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
