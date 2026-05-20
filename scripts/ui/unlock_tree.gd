class_name UnlockTreeUI
extends Control

const SECTION_ORDER := ["skills", "supports", "passives"]
const SECTION_LABELS := {
	"skills": "SKILLS",
	"supports": "SUPPORTS",
	"passives": "PASSIVES",
}

@onready var back_button: Button = $BackButton
@onready var scroll: ScrollContainer = $MarginContainer/ScrollContainer
@onready var content: VBoxContainer = $MarginContainer/ScrollContainer/Content
@onready var progress_label: Label = $MarginContainer/ProgressLabel

var _unlock_conditions: Dictionary = {}

func _ready() -> void:
	back_button.pressed.connect(func(): queue_free())
	_load_unlock_conditions()
	_build_tree()

func _load_unlock_conditions() -> void:
	var dir := DirAccess.open("res://resources/unlocks/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://resources/unlocks/" + file_name)
			if res is UnlockConditionResource:
				var key := "%s:%s" % [res.item_type, res.item_id]
				_unlock_conditions[key] = res
		file_name = dir.get_next()

func _build_tree() -> void:
	var total := 0
	var unlocked := 0

	for section: String in SECTION_ORDER:
		var header := Label.new()
		header.text = SECTION_LABELS[section]
		header.add_theme_font_size_override("font_size", 36)
		header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
		content.add_child(header)

		var sep := HSeparator.new()
		content.add_child(sep)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 8)
		content.add_child(grid)

		var items := _get_all_items(section)
		for item: Dictionary in items:
			total += 1
			var is_unlocked: bool = MetaProgression.is_unlocked(section, item["id"])
			if is_unlocked:
				unlocked += 1
			var card := _create_card(item, section, is_unlocked)
			grid.add_child(card)

		var spacer := Control.new()
		spacer.custom_minimum_size.y = 20
		content.add_child(spacer)

	progress_label.text = "%d / %d unlocked" % [unlocked, total]

func _get_all_items(section: String) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var dir_path := "res://resources/%s/" % section
	var dir := DirAccess.open(dir_path)
	if not dir:
		return items
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(dir_path + file_name)
			match section:
				"skills":
					if res is SkillResource:
						items.append({"id": res.id, "name": res.name, "description": res.description, "rarity": res.rarity})
				"supports":
					if res is SupportResource:
						items.append({"id": res.id, "name": res.name, "description": res.description, "rarity": res.rarity})
				"passives":
					if res is PassiveResource:
						var passive := res as PassiveResource
						items.append({"id": passive.id, "name": passive.name, "description": passive.description, "rarity": passive.rarity})
		file_name = dir.get_next()
	return items

func _create_card(item: Dictionary, section: String, is_unlocked: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 100)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 28)

	if is_unlocked:
		title.text = item["name"]
		title.add_theme_color_override("font_color", _rarity_color(item["rarity"]))
		var desc := Label.new()
		desc.text = item["description"]
		desc.add_theme_font_size_override("font_size", 20)
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(title)
		vbox.add_child(desc)
	else:
		title.text = "LOCKED"
		title.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
		vbox.add_child(title)

		var cond_key := "%s:%s" % [section, item["id"]]
		if _unlock_conditions.has(cond_key):
			var cond: UnlockConditionResource = _unlock_conditions[cond_key]
			var cond_label := Label.new()
			cond_label.text = cond.description
			cond_label.add_theme_font_size_override("font_size", 20)
			cond_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.3))
			cond_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(cond_label)
		else:
			var hint := Label.new()
			hint.text = "Unlock condition unknown"
			hint.add_theme_font_size_override("font_size", 20)
			hint.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			vbox.add_child(hint)

	return panel

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"uncommon": return Color(0.3, 0.8, 0.3)
		"rare": return Color(0.4, 0.5, 1.0)
		_: return Color.WHITE
