class_name EvolutionGallery
extends Control

const SELECTORS := ["skill", "support_set", "tier", "terminal_difficulty", "formation", "density"]
const SKILL_IDS := ["fireball", "flame_wave", "frost_nova", "lightning_bolt", "poison_dart", "static_field", "blade_spin"]
const SIGNATURES := {
	"fireball": "firewall", "flame_wave": "reply_all", "frost_nova": "frozen_process",
	"lightning_bolt": "wifi_extender", "poison_dart": "malware",
	"static_field": "background_process", "blade_spin": "undo_history",
}

var _controls: Dictionary = {}
var _controls_built := false
var _preview_skill: SkillInstance
var _world: Node2D
var _caster: SkillCaster
var _preview_enemy: EnemyBase
var _spawner: Spawner
var _terminal: CompilationTerminal

func _ready() -> void:
	_build_controls()
	_build_production_preview()
	_apply_selection()

func selector_names() -> Array[String]:
	var names: Array[String] = []
	for selector: String in SELECTORS:
		names.append(selector)
	return names

func get_preview_skill() -> SkillInstance:
	return _preview_skill

func get_preview_terminal() -> CompilationTerminal:
	return _terminal

func trigger_cast() -> bool:
	if not _caster or not _preview_skill or not is_instance_valid(_preview_enemy):
		return false
	Targeting.update_position(_preview_enemy)
	return _caster._try_cast(_preview_skill)

func trigger_terminal() -> bool:
	if not _terminal:
		return false
	_terminal.state = CompilationTerminal.State.READY
	_terminal.difficulty = _controls["terminal_difficulty"].selected
	_terminal.encounter_override.clear()
	var definition := _terminal.get_encounter_definition()
	var density_mult: float = [0.25, 0.5, 0.75, 1.0][_controls["density"].selected]
	definition["enemy_count"] = maxi(1, int(ceil(float(definition.enemy_count) * density_mult)))
	_terminal.encounter_override = definition
	_terminal.wave_size = definition.enemy_count
	_terminal.zone_radius = definition.zone_radius
	_terminal.outside_grace = definition.outside_grace
	var activated := _terminal.activate()
	if activated:
		_apply_wave_formation()
	return activated

func preview_wave_count() -> int:
	var count := 0
	for child: Node in _spawner.get_children() if _spawner else []:
		if child.get_meta("compilation_wave", false):
			count += 1
	return count

func production_effect_count() -> int:
	return ProjectileBase.active_count + Rollback.active_count + AoeSkillBase.active_count

func show_effect(evolution_id: String, tier: int) -> void:
	var skill_index := -1
	for index in SKILL_IDS.size():
		if EvolutionData.BY_SKILL[SKILL_IDS[index]].id == evolution_id:
			skill_index = index
			break
	if skill_index < 0:
		return
	_controls["skill"].select(skill_index)
	_controls["tier"].select(clampi(tier, 1, 3) - 1)
	_apply_selection()
	trigger_cast()

func count_gameplay_effects(kind: String) -> int:
	match kind:
		"rollback": return Rollback.active_count
		"projectile": return ProjectileBase.active_count
		"aoe": return AoeSkillBase.active_count
	return get_tree().get_nodes_in_group("evolution_%s" % kind).size() if is_inside_tree() else 0

func _build_production_preview() -> void:
	_world = Node2D.new()
	_world.name = "ProductionPreviewWorld"
	add_child(_world)
	_caster = SkillCaster.new()
	_caster.name = "ProductionSkillCaster"
	_world.add_child(_caster)
	_caster.position = Vector2(300, 700)
	_caster.set_physics_process(false)
	_preview_enemy = preload("res://scenes/enemies/basic_melee.tscn").instantiate() as EnemyBase
	_preview_enemy.name = "ProductionPreviewEnemy"
	_world.add_child(_preview_enemy)
	_preview_enemy.global_position = Vector2(380, 700)
	_preview_enemy.initialize(_caster)
	Targeting.update_position(_preview_enemy)
	_preview_enemy.set_physics_process(false)
	_terminal = CompilationTerminal.new()
	_terminal.name = "ProductionCompilationTerminal"
	_world.add_child(_terminal)
	_terminal.position = Vector2(300, 980)
	_spawner = Spawner.new()
	_spawner.melee_scene = preload("res://scenes/enemies/basic_melee.tscn")
	_spawner.ranged_scene = preload("res://scenes/enemies/basic_ranged.tscn")
	_spawner.tank_scene = preload("res://scenes/enemies/tank_enemy.tscn")
	_spawner.swarm_scene = preload("res://scenes/enemies/swarm_enemy.tscn")
	_spawner.mini_boss_scene = preload("res://scenes/enemies/mini_boss.tscn")
	_spawner.charger_scene = preload("res://scenes/enemies/charger_enemy.tscn")
	_world.add_child(_spawner)
	_spawner.setup(_caster, Rect2(0, 480, 720, 900))
	_spawner.set_process(false)
	_terminal.setup(_caster, _spawner)
	_terminal.set_process(false)

func _apply_wave_formation() -> void:
	var enemies: Array[Node2D] = []
	for child: Node in _spawner.get_children():
		if child is Node2D and child.get_meta("compilation_wave", false):
			enemies.append(child)
	var mode: int = _controls["formation"].selected
	for index in enemies.size():
		match mode:
			0: enemies[index].global_position = _terminal.global_position + Vector2(0, -100 - index * 18)
			1: enemies[index].global_position = _terminal.global_position + Vector2((index - enemies.size() * 0.5) * 42, -120)
			2:
				var angle := TAU * index / maxi(1, enemies.size())
				enemies[index].global_position = _terminal.global_position + Vector2.from_angle(angle) * 180.0
			3: enemies[index].global_position = _terminal.global_position + Vector2((index % 4 - 1.5) * 48, (index / 4) * 48 - 160)
		Targeting.update_position(enemies[index])

func _apply_selection(_index: int = 0) -> void:
	if not _caster or _controls.is_empty():
		return
	var skill_id: String = SKILL_IDS[_controls["skill"].selected]
	_preview_skill = SkillInstance.new(load("res://resources/skills/%s.tres" % skill_id))
	var support_mode: int = _controls["support_set"].selected
	if support_mode >= 1:
		_link_support_if_legal(SIGNATURES[skill_id])
	if support_mode >= 2:
		for support_id in ["copy_paste", "spaghetti_code", "lag_spike", "rubber_duck"]:
			_link_support_if_legal(support_id)
	var evolution: Dictionary = EvolutionData.get_for_skill(skill_id)
	_preview_skill.set_evolution(evolution.id, _controls["tier"].selected + 1)
	_caster.set_skills([_preview_skill])

func _link_support_if_legal(support_id: String) -> void:
	var support := load("res://resources/supports/%s.tres" % support_id) as SupportResource
	if support and _preview_skill.support_rejection_reason(support).is_empty():
		_preview_skill.link_support(support)

func _build_controls() -> void:
	if _controls_built:
		return
	_controls_built = true
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	var title := Label.new()
	title.text = "EVOLUTION TEST GALLERY"
	UITheme.style_label_title(title, 30)
	list.add_child(title)
	for selector: String in SELECTORS:
		var label := Label.new()
		label.text = selector.replace("_", " ").to_upper()
		UITheme.style_label_body(label, 18)
		list.add_child(label)
		var options := OptionButton.new()
		options.name = selector
		options.custom_minimum_size.y = 64
		for value: String in _values_for(selector):
			options.add_item(value)
		options.item_selected.connect(_apply_selection)
		_controls[selector] = options
		list.add_child(options)
	var cast_button := Button.new()
	cast_button.text = "CAST SELECTED BUILD"
	cast_button.custom_minimum_size.y = 96
	cast_button.pressed.connect(trigger_cast)
	list.add_child(cast_button)
	var terminal_button := Button.new()
	terminal_button.text = "START TERMINAL WAVE"
	terminal_button.custom_minimum_size.y = 96
	terminal_button.pressed.connect(trigger_terminal)
	list.add_child(terminal_button)

func _values_for(selector: String) -> Array[String]:
	match selector:
		"skill": return ["Fireball", "Flame Wave", "Frost Nova", "Lightning Bolt", "Poison Dart", "Static Field", "Rollback"]
		"support_set": return ["None", "Signature", "Memetic", "Stress"]
		"tier": return ["I", "II", "III"]
		"terminal_difficulty": return ["Compile", "Overclock", "Kernel Breach"]
		"formation": return ["Single", "Line", "Ring", "Swarm"]
		"density": return ["Low", "Medium", "High", "Cap"]
	return []
