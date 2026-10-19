class_name ArtifactComparison
extends VBoxContainer

var preview_slot := 0
var lost_label: Label
var gained_label: Label
var covenant_meter: CovenantMeter
var changed_stat_labels: Array[Label] = []

func _init() -> void:
	add_theme_constant_override("separation", 6)
	lost_label = Label.new()
	lost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(lost_label)
	gained_label = Label.new()
	gained_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(gained_label)
	covenant_meter = CovenantMeter.new()
	add_child(covenant_meter)

func setup(current_ids: Array[String], candidate_id: String, slot: int) -> void:
	preview_slot = clampi(slot, 0, ArtifactLoadout.SLOT_COUNT - 1)
	for label in changed_stat_labels: label.queue_free()
	changed_stat_labels.clear()
	var before := ArtifactLoadout.normalize_snapshot(current_ids)
	var lost := ArtifactCatalog.get_artifact(before[preview_slot])
	var gained := ArtifactCatalog.get_artifact(candidate_id)
	lost_label.text = "LOST  ·  %s%s" % [lost.display_name if lost else "EMPTY SLOT", " — " + lost.description if lost else ""]
	gained_label.text = "GAINED  ·  %s%s" % [gained.display_name if gained else "NO RELIC", " — " + gained.description if gained else ""]
	var after := before.duplicate()
	after[preview_slot] = candidate_id
	var before_count := int(ArtifactLoadout.active_set_tiers(before).get("covenant_of_embers", 0))
	var after_count := int(ArtifactLoadout.active_set_tiers(after).get("covenant_of_embers", 0))
	covenant_meter.set_progress(before_count, after_count)
	if gained == null: return
	var old_params: Dictionary = lost.behavior_parameters if lost else {}
	var changed_keys: Array = old_params.keys()
	for key: Variant in gained.behavior_parameters:
		if not changed_keys.has(key): changed_keys.append(key)
	for key: Variant in changed_keys:
		if changed_stat_labels.size() >= 3: break
		var new_value: Variant = gained.behavior_parameters.get(key, "—")
		var old_value: Variant = old_params.get(key, "—")
		if typeof(old_value) == typeof(new_value) and old_value == new_value: continue
		var label := Label.new()
		label.text = "%s  %s → %s" % [str(key).to_upper().replace("_", " "), str(old_value), str(new_value)]
		add_child(label)
		changed_stat_labels.append(label)

func get_combined_text() -> String:
	var lines: Array[String] = [lost_label.text, gained_label.text, covenant_meter.progress_label.text, covenant_meter.preview_label.text]
	for label in changed_stat_labels: lines.append(label.text)
	return "\n".join(lines)
