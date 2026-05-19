extends Node

var _behaviors: Dictionary = {}

func _ready() -> void:
	register("pierce", preload("res://scripts/behaviors/pierce_behavior.gd"))
	register("chain", preload("res://scripts/behaviors/chain_behavior.gd"))
	register("split", preload("res://scripts/behaviors/split_behavior.gd"))
	register("increased_area", preload("res://scripts/behaviors/increased_area_behavior.gd"))
	register("faster_casting", preload("res://scripts/behaviors/faster_casting_behavior.gd"))
	register("crit_explosion", preload("res://scripts/behaviors/crit_explosion_behavior.gd"))
	register("poison_on_hit", preload("res://scripts/behaviors/poison_on_hit_behavior.gd"))
	register("elemental_proliferation", preload("res://scripts/behaviors/elemental_proliferation_behavior.gd"))

func register(key: String, behavior_script: GDScript) -> void:
	_behaviors[key] = behavior_script

func get_behavior(key: String) -> BehaviorBase:
	if _behaviors.has(key):
		return _behaviors[key].new()
	push_warning("BehaviorRegistry: unknown key '%s'" % key)
	return null

func has_behavior(key: String) -> bool:
	return _behaviors.has(key)
