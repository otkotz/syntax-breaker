class_name RunSummary
extends Control

signal play_again_pressed

@onready var result_label: Label = $CenterContainer/VBox/ResultLabel
@onready var stats_container: VBoxContainer = $CenterContainer/VBox/StatsContainer
@onready var play_again_button: Button = $CenterContainer/VBox/PlayAgainButton

func _ready() -> void:
	play_again_button.pressed.connect(func(): play_again_pressed.emit())

func setup(victory: bool) -> void:
	result_label.text = "VICTORY!" if victory else "DEFEAT"
	result_label.modulate = Color.GOLD if victory else Color.RED

	_add_stat("Stage Reached", str(RunManager.current_stage))
	_add_stat("Enemies Killed", str(RunManager.run_stats.get("enemies_killed", 0)))
	_add_stat("Gold Earned", str(RunManager.gold))
	_add_stat("Projectiles Fired", str(RunManager.run_stats.get("projectiles_fired", 0)))
	_add_stat("Crits Landed", str(RunManager.run_stats.get("crits_landed", 0)))

func _add_stat(stat_name: String, value: String) -> void:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = stat_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(lbl)
	hbox.add_child(val)
	stats_container.add_child(hbox)
