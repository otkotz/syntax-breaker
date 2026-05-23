class_name CodexUI
extends Control

const CATEGORIES := ["skills", "supports", "passives", "enemies"]
const CATEGORY_LABELS := {
	"skills": "Skills",
	"supports": "Supports",
	"passives": "Passives",
	"enemies": "Enemies",
}

@onready var back_button: Button = $BackButton
@onready var tab_bar: HBoxContainer = $MarginContainer/VBox/TabBar
@onready var scroll: ScrollContainer = $MarginContainer/VBox/ScrollContainer
@onready var entry_list: VBoxContainer = $MarginContainer/VBox/ScrollContainer/EntryList
@onready var count_label: Label = $MarginContainer/VBox/CountLabel

var _current_category: String = "skills"

func _ready() -> void:
	back_button.pressed.connect(func(): queue_free())
	for cat: String in CATEGORIES:
		var btn := Button.new()
		btn.text = CATEGORY_LABELS[cat]
		btn.custom_minimum_size = Vector2(160, 60)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_select_category.bind(cat))
		tab_bar.add_child(btn)
	_select_category("skills")

func _select_category(category: String) -> void:
	_current_category = category
	_refresh()

func _refresh() -> void:
	for child: Node in entry_list.get_children():
		child.queue_free()

	var entries: Array[Dictionary] = _get_entries(_current_category)
	var discovered := 0

	for entry: Dictionary in entries:
		var is_found: bool = entry["discovered"]
		if is_found:
			discovered += 1
		var card := _create_entry_card(entry)
		entry_list.add_child(card)

	count_label.text = "%s: %d / %d discovered" % [CATEGORY_LABELS[_current_category], discovered, entries.size()]

func _get_entries(category: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	match category:
		"skills":
			for res: Resource in _load_resources("res://resources/skills/"):
				if res is SkillResource:
					var skill := res as SkillResource
					entries.append({
						"id": skill.id, "name": skill.name, "description": skill.description,
						"tags": ", ".join(skill.tags), "rarity": skill.rarity,
						"discovered": MetaProgression.is_discovered("skills", skill.id),
					})
		"supports":
			for res: Resource in _load_resources("res://resources/supports/"):
				if res is SupportResource:
					var support := res as SupportResource
					entries.append({
						"id": support.id, "name": support.name, "description": support.description,
						"tags": ", ".join(support.required_tags),
						"rarity": support.rarity,
						"discovered": MetaProgression.is_discovered("supports", support.id),
					})
		"passives":
			for res: Resource in _load_resources("res://resources/passives/"):
				if res is PassiveResource:
					var passive := res as PassiveResource
					entries.append({
						"id": passive.id, "name": passive.name, "description": passive.description,
						"tags": "", "rarity": passive.rarity,
						"discovered": MetaProgression.is_discovered("passives", passive.id),
					})
		"enemies":
			var enemy_data := {
				"basic_enemy": {"name": "Shambler", "description": "Basic melee enemy that wanders until provoked."},
				"basic_ranged": {"name": "Dark Mage", "description": "Ranged caster that fires arcane bolts."},
				"mini_boss": {"name": "The Sovereign", "description": "A towering overlord with devastating melee attacks."},
				"oni_enemy": {"name": "Oni Brute", "description": "Aggressive melee fighter with high damage."},
			}
			for eid: String in enemy_data:
				var data: Dictionary = enemy_data[eid]
				entries.append({
					"id": eid, "name": data["name"], "description": data["description"],
					"tags": "", "rarity": "",
					"discovered": MetaProgression.is_discovered("enemies", eid),
				})
	return entries

func _create_entry_card(entry: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 100.0
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	if entry["discovered"]:
		title.text = entry["name"]
		title.add_theme_color_override("font_color", _rarity_color(entry["rarity"]))
	else:
		title.text = "???"
		title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)

	var desc := Label.new()
	if entry["discovered"]:
		desc.text = entry["description"]
		if not entry["tags"].is_empty():
			desc.text += "  [%s]" % entry["tags"]
	else:
		desc.text = "Not yet discovered"
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	return panel

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"uncommon": return Color(0.3, 0.8, 0.3)
		"rare": return Color(0.4, 0.5, 1.0)
		_: return Color.WHITE

func _load_resources(dir_path: String) -> Array:
	var resources: Array = []
	for file_name in ResourceListing.get_resource_files(dir_path):
		var res := load(dir_path + file_name)
		if res:
			resources.append(res)
	return resources
