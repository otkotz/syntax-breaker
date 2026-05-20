class_name MainMenu
extends Control

@onready var start_button: Button = $CenterContainer/VBox/StartButton
@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var asc_label: Label = $CenterContainer/VBox/AscensionBox/AscLabel
@onready var asc_down: Button = $CenterContainer/VBox/AscensionBox/AscDown
@onready var asc_up: Button = $CenterContainer/VBox/AscensionBox/AscUp
@onready var asc_desc: Label = $CenterContainer/VBox/AscDesc
@onready var region_label: Label = $CenterContainer/VBox/RegionBox/RegionLabel
@onready var region_prev: Button = $CenterContainer/VBox/RegionBox/RegionPrev
@onready var region_next: Button = $CenterContainer/VBox/RegionBox/RegionNext
@onready var unlocks_button: Button = $CenterContainer/VBox/MenuButtons/UnlocksButton
@onready var codex_button: Button = $CenterContainer/VBox/MenuButtons/CodexButton

signal start_pressed
signal unlocks_pressed
signal codex_pressed

var _region_ids: Array[String] = []
var _region_index: int = 0

func _ready() -> void:
	title_label.text = "SYNTAX BREAKER"
	start_button.pressed.connect(func(): start_pressed.emit())
	unlocks_button.pressed.connect(func(): unlocks_pressed.emit())
	codex_button.pressed.connect(func(): codex_pressed.emit())
	asc_down.pressed.connect(func(): _change_ascension(-1))
	asc_up.pressed.connect(func(): _change_ascension(1))
	region_prev.pressed.connect(func(): _change_region(-1))
	region_next.pressed.connect(func(): _change_region(1))
	_load_regions()
	_refresh_ascension()
	_refresh_region()

func _load_regions() -> void:
	_region_ids = [""]
	var dir := DirAccess.open("res://resources/regions/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://resources/regions/" + file_name)
			if res is RegionResource:
				_region_ids.append(res.id)
		file_name = dir.get_next()

func _change_ascension(delta: int) -> void:
	var level := clampi(MetaProgression.ascension_level + delta, 0, MetaProgression.MAX_ASCENSION)
	MetaProgression.set_ascension(level)
	_refresh_ascension()

func _refresh_ascension() -> void:
	var level := MetaProgression.ascension_level
	asc_label.text = "ASCENSION %d" % level
	asc_down.disabled = level <= 0
	asc_up.disabled = level >= MetaProgression.MAX_ASCENSION
	if level == 0:
		asc_desc.text = "Normal difficulty"
	else:
		var scaling: Dictionary = MetaProgression.get_ascension_scaling()
		var hp_pct := int((scaling["hp_mult"] - 1.0) * 100)
		var dmg_pct := int((scaling["damage_mult"] - 1.0) * 100)
		asc_desc.text = "+%d%% enemy HP, +%d%% enemy damage" % [hp_pct, dmg_pct]

func _change_region(delta: int) -> void:
	_region_index = wrapi(_region_index + delta, 0, _region_ids.size())
	_refresh_region()

func _refresh_region() -> void:
	if _region_ids.is_empty():
		region_label.text = "REGION: DEFAULT"
		return
	var rid: String = _region_ids[_region_index]
	if rid.is_empty():
		region_label.text = "REGION: DEFAULT"
	else:
		var res := _load_region(rid)
		region_label.text = "REGION: %s" % (res.name.to_upper() if res else rid.to_upper())
	region_prev.visible = _region_ids.size() > 1
	region_next.visible = _region_ids.size() > 1

func _load_region(rid: String) -> RegionResource:
	var path := "res://resources/regions/%s.tres" % rid
	if ResourceLoader.exists(path):
		return load(path) as RegionResource
	return null

func get_selected_region() -> String:
	if _region_index >= 0 and _region_index < _region_ids.size():
		return _region_ids[_region_index]
	return ""
