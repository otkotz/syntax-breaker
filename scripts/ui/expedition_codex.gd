class_name ExpeditionCodexUI
extends Control

signal back_pressed
signal variant_selected(id: String)

var card_buttons: Dictionary = {}
var filter_buttons: Dictionary = {}
var goal_label: Label
var set_progress_label: Label
var pity_label: Label
var synergy_label: Label
var omen_label: Label
var back_button: Button
var variant_buttons: Array[Button] = []
var _cards: VBoxContainer
var _profile: ExpeditionProfile
var _active_filter := "all"

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build_ui()

func setup(profile: ExpeditionProfile) -> void:
	_profile = profile
	if _cards == null:
		_build_ui()
	_render()

func apply_filter(filter_id: String) -> void:
	if not filter_buttons.has(filter_id):
		return
	_active_filter = filter_id
	_render_cards()

func visible_card_ids() -> Array[String]:
	var result: Array[String] = []
	for artifact_id: String in ArtifactCatalog.all_ids():
		var button := card_buttons.get(artifact_id) as Button
		if button != null and button.visible:
			result.append(artifact_id)
	return result

func _build_ui() -> void:
	if _cards != null:
		return
	var background := ColorRect.new()
	background.color = UITheme.C_BG
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 72)
	margin.add_theme_constant_override("margin_bottom", 72)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var title := Label.new()
	title.text = "EXPEDITION CODEX"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label_title(title, 46)
	content.add_child(title)
	goal_label = Label.new()
	goal_label.name = "NextHuntLabel"
	goal_label.custom_minimum_size.y = 88.0
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.style_label_body(goal_label, 25)
	content.add_child(goal_label)
	var progress := HBoxContainer.new()
	progress.alignment = BoxContainer.ALIGNMENT_CENTER
	progress.add_theme_constant_override("separation", 32)
	content.add_child(progress)
	set_progress_label = Label.new()
	pity_label = Label.new()
	for label: Label in [set_progress_label, pity_label]:
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", UITheme.C_RARITY_LEGENDARY)
		progress.add_child(label)
	synergy_label = Label.new()
	synergy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	synergy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	synergy_label.add_theme_font_size_override("font_size", 22)
	content.add_child(synergy_label)
	omen_label = Label.new()
	omen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	omen_label.add_theme_font_size_override("font_size", 22)
	content.add_child(omen_label)
	var variants := HBoxContainer.new()
	variants.alignment = BoxContainer.ALIGNMENT_CENTER
	variants.add_theme_constant_override("separation", 12)
	content.add_child(variants)
	for entry: Dictionary in [
		{"id": "crimson_overdrive", "text": "CRIMSON · 12% HP · 1.55× DMG"},
		{"id": "hematic_reserve", "text": "RESERVE · 5% HP · 1.15× DMG"},
	]:
		var variant_button := Button.new()
		variant_button.text = entry.text
		variant_button.custom_minimum_size = Vector2(430, 88)
		variant_button.pressed.connect(_emit_variant.bind(str(entry.id)))
		variants.add_child(variant_button)
		variant_buttons.append(variant_button)
	var filters := HBoxContainer.new()
	filters.alignment = BoxContainer.ALIGNMENT_CENTER
	filters.add_theme_constant_override("separation", 10)
	content.add_child(filters)
	for entry: Dictionary in [
		{"id": "all", "label": "ALL"}, {"id": "owned", "label": "OWNED"},
		{"id": "missing", "label": "MISSING"}, {"id": "burning_grounds", "label": "BURNING"}]:
		var button := Button.new()
		button.text = entry.label
		button.custom_minimum_size = Vector2(175, 88)
		UITheme.style_button(button, 22)
		button.pressed.connect(apply_filter.bind(entry.id))
		filters.add_child(button)
		filter_buttons[entry.id] = button
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(scroll)
	_cards = VBoxContainer.new()
	_cards.size_flags_horizontal = SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 12)
	scroll.add_child(_cards)
	back_button = Button.new()
	back_button.text = "BACK"
	back_button.custom_minimum_size = Vector2(600, 88)
	UITheme.style_button(back_button, 28)
	back_button.pressed.connect(func(): back_pressed.emit())
	content.add_child(back_button)

func _render() -> void:
	_render_summary()
	_render_cards()

func _render_summary() -> void:
	var covenant_owned := 0
	var missing_set: ArtifactResource = null
	for artifact_id: String in ArtifactCatalog.all_ids():
		var artifact := ArtifactCatalog.get_artifact(artifact_id)
		if artifact == null or artifact.set_id != "covenant_of_embers":
			continue
		if _profile.owned_artifact_ids.has(artifact_id):
			covenant_owned += 1
		elif missing_set == null:
			missing_set = artifact
	set_progress_label.text = "COVENANT %d/3" % covenant_owned
	pity_label.text = "SIGIL %d/5" % clampi(int(_profile.pity_counters.get("burning_boss_sigil", 0)), 0, 4)
	var synergy_names: Array[String] = []
	for id in _profile.discovered_synergy_ids:
		synergy_names.append(id.to_upper().replace("_", " "))
	synergy_label.text = "DISCOVERED SYNERGIES: %s" % (", ".join(synergy_names) if not synergy_names.is_empty() else "NONE")
	var omen := preload("res://scripts/expedition/blood_omen.gd")
	if not _profile.selected_sigil_variant.is_empty():
		omen_label.text = "SIGIL PATH: %s" % str(omen.get_variant(_profile.selected_sigil_variant).get("name", "UNKNOWN"))
	elif _profile.owned_artifact_ids.has(ExpeditionLootRoller.CHASE_ID) and _profile.bloodwritten_fragments >= 3:
		omen_label.text = "NEXT: CHOOSE A SIGIL PATH"
	elif _profile.owned_artifact_ids.has(ExpeditionLootRoller.CHASE_ID):
		omen_label.text = "SIGIL FRAGMENTS %d/3" % mini(3, _profile.bloodwritten_fragments)
	elif omen.is_available(_profile):
		omen_label.text = "BLOOD OMEN READY — OPT IN BEFORE EXPEDITION"
	else:
		omen_label.text = "BLOOD OMEN DORMANT"
	for button: Button in variant_buttons:
		button.visible = _profile.selected_sigil_variant.is_empty() and _profile.owned_artifact_ids.has(ExpeditionLootRoller.CHASE_ID) and _profile.bloodwritten_fragments >= 3
	var known_owned := 0
	for known_id: String in ArtifactCatalog.all_ids(): known_owned += int(_profile.owned_artifact_ids.has(known_id))
	if known_owned >= ArtifactCatalog.all_ids().size():
		goal_label.text = "NEXT HUNT  ·  COLLECTION COMPLETE"
	elif missing_set != null:
		goal_label.text = "NEXT HUNT  ·  %s  ·  BOSS" % missing_set.display_name
	else:
		for artifact_id: String in ArtifactCatalog.all_ids():
			if not _profile.owned_artifact_ids.has(artifact_id):
				var artifact := ArtifactCatalog.get_artifact(artifact_id)
				if artifact != null:
					goal_label.text = "NEXT HUNT  ·  %s  ·  %s" % [artifact.display_name, _source_label(artifact)]
					return

func _render_cards() -> void:
	for child: Node in _cards.get_children():
		child.free()
	card_buttons.clear()
	for artifact_id: String in ArtifactCatalog.all_ids():
		var artifact := ArtifactCatalog.get_artifact(artifact_id)
		if artifact == null:
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 136)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = _card_text(artifact)
		button.visible = _matches_filter(artifact)
		UITheme.style_button(button, 23)
		_cards.add_child(button)
		card_buttons[artifact_id] = button

func _card_text(artifact: ArtifactResource) -> String:
	var source := _source_label(artifact)
	if not _profile.discovered_artifact_ids.has(artifact.id):
		return "UNKNOWN RELIC  ·  MISSING\nSOURCE: %s" % source
	var state := "OWNED" if _profile.owned_artifact_ids.has(artifact.id) else "DISCOVERED"
	return "%s  ·  %s\n%s\nSOURCE: %s" % [artifact.display_name, state, artifact.description, source]

func _matches_filter(artifact: ArtifactResource) -> bool:
	match _active_filter:
		"owned": return _profile.owned_artifact_ids.has(artifact.id)
		"missing": return not _profile.owned_artifact_ids.has(artifact.id)
		"burning_grounds": return artifact.region_id == "burning_grounds"
	return true

func _source_label(artifact: ArtifactResource) -> String:
	var labels: Array[String] = []
	for source: String in artifact.source_tags:
		labels.append(source.to_upper().replace("_", " "))
	return " / ".join(labels) if not labels.is_empty() else "UNKNOWN"

func _emit_variant(id: String) -> void:
	variant_selected.emit(id)
