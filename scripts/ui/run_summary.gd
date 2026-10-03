class_name RunSummary
extends Control

signal play_again_pressed

@onready var result_label: Label = $CenterContainer/VBox/ResultLabel
@onready var stats_container: VBoxContainer = $CenterContainer/VBox/StatsScroll/StatsContainer
@onready var unlocks_label: Label = $CenterContainer/VBox/UnlocksLabel
@onready var play_again_button: Button = $CenterContainer/VBox/PlayAgainButton

func _ready() -> void:
	play_again_button.pressed.connect(func(): play_again_pressed.emit())
	UITheme.style_button(play_again_button, 36)
	unlocks_label.add_theme_color_override("font_color", UITheme.C_V_BRIGHT)

func setup(victory: bool, new_unlocks: Array[String] = []) -> void:
	result_label.text = "VICTORY!" if victory else "DEFEAT"
	result_label.modulate = UITheme.C_V_BRIGHT if victory else Color(0.9, 0.25, 0.25)

	for child: Node in stats_container.get_children():
		child.queue_free()

	_add_stat("Stage Reached", "%d / %d" % [RunManager.current_stage, StageGenerator.MAX_DEPTH])
	_add_stat("Enemies Killed", str(RunManager.run_stats.get("enemies_killed", 0)))
	_add_stat("Elites Cleared", str(RunManager.run_stats.get("elites_cleared", 0)))
	_add_stat("Gold Earned", "%.1f" % RunManager.run_stats.get("gold_earned", 0.0))
	_add_stat("Gold Spent", str(RunManager.run_stats.get("gold_spent", 0)))
	_add_stat("Gold Remaining", str(RunManager.gold))
	_add_stat("Damage Taken", "%.0f" % RunManager.run_stats.get("damage_taken", 0.0))
	if not victory:
		_add_stat("Death Source", str(RunManager.run_stats.get("death_source", "unknown")))
	_add_stat("Healing Received", "%.0f" % RunManager.run_stats.get("healing_received", 0.0))
	_add_stat("Combat Time", "%.0fs" % RunManager.run_stats.get("time_played", 0.0))
	_add_stat("Shop Rerolls", str(RunManager.run_stats.get("rerolls", 0)))
	for id: String in RunManager.run_stats.get("new_challenges", []):
		_add_stat("Challenge completed", ArchetypeChallenges.display_name(id))
	_add_stat("Crits Landed", str(RunManager.run_stats.get("crits_landed", 0)))
	var totals: Dictionary = RunManager.run_stats.get("damage_by_skill", RunManager.run_stats.get("direct_damage_by_skill", {}))
	var kills: Dictionary = RunManager.run_stats.get("kills_by_skill", RunManager.run_stats.get("direct_kills_by_skill", {}))
	var combat_seconds := maxf(1.0, float(RunManager.run_stats.get("time_played", 0.0)))
	for skill_id: String in totals:
		var resource := load("res://resources/skills/%s.tres" % skill_id) as SkillResource
		var display_name := resource.name if resource else skill_id
		_add_stat(display_name, "%.0f dmg | %.1f DPS | %d kills" % [totals[skill_id], float(totals[skill_id]) / combat_seconds, int(kills.get(skill_id, 0))])
		var direct: float = RunManager.run_stats.get("direct_damage_by_skill", {}).get(skill_id, 0.0)
		var dot: float = RunManager.run_stats.get("dot_damage_by_skill", {}).get(skill_id, 0.0)
		var proc: float = RunManager.run_stats.get("proc_damage_by_skill", {}).get(skill_id, 0.0)
		_add_stat("  Direct / DoT / proc", "%.0f / %.0f / %.0f" % [direct, dot, proc])
	var other: float = RunManager.run_stats.get("unattributed_damage", 0.0)
	if other > 0.0:
		_add_stat("Other damage", "%.0f dmg | %d kills" % [other, int(RunManager.run_stats.get("unattributed_kills", 0))])
	if int(RunManager.run_stats.get("damage_attribution_version", 1)) < 2:
		_add_stat("Old save", "Earlier DoT/procs not recorded")
	var best_combo: int = RunManager.run_stats.get("best_combo", 0)
	if best_combo > 0:
		_add_stat("Best Combo", str(best_combo))

	if new_unlocks.is_empty():
		unlocks_label.text = ""
	else:
		unlocks_label.text = "NEW UNLOCKS:\n" + "\n".join(new_unlocks)

func _add_stat(stat_name: String, value: String) -> void:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = stat_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", UITheme.C_INK_MUTE)
	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", 28)
	val.add_theme_color_override("font_color", UITheme.C_SILVER)
	hbox.add_child(lbl)
	hbox.add_child(val)
	stats_container.add_child(hbox)
