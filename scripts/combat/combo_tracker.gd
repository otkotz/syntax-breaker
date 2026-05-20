class_name ComboTracker
extends Node

signal combo_changed(count: int, multiplier: float)

static var current_multiplier: float = 1.0

var combo_count: int = 0
var _decay_timer: float = 0.0
var _best_combo: int = 0

const COMBO_WINDOW := 2.0
const MAX_MULT := 2.0
const COMBO_FOR_MAX := 50

func _ready() -> void:
	current_multiplier = 1.0
	GameBus.enemy_killed.connect(_on_enemy_killed)

func _process(delta: float) -> void:
	if combo_count > 0:
		_decay_timer -= delta
		if _decay_timer <= 0.0:
			combo_count = 0
			current_multiplier = 1.0
			combo_changed.emit(0, 1.0)

func _on_enemy_killed(_enemy: Node2D, _skill: Resource) -> void:
	combo_count += 1
	_decay_timer = COMBO_WINDOW
	current_multiplier = _calc_multiplier()
	if combo_count > _best_combo:
		_best_combo = combo_count
		RunManager.run_stats["best_combo"] = _best_combo
	combo_changed.emit(combo_count, current_multiplier)

func _calc_multiplier() -> float:
	if combo_count <= 0:
		return 1.0
	var t := clampf(float(combo_count) / float(COMBO_FOR_MAX), 0.0, 1.0)
	return 1.0 + t * (MAX_MULT - 1.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		current_multiplier = 1.0
