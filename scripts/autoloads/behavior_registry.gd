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
	register("shotgun", preload("res://scripts/behaviors/shotgun_behavior.gd"))
	register("cast_on_kill", preload("res://scripts/behaviors/cast_on_kill_behavior.gd"))
	register("void_rift", preload("res://scripts/behaviors/void_rift_behavior.gd"))
	register("corpse_bloom", preload("res://scripts/behaviors/corpse_bloom_behavior.gd"))
	register("toxic_burst", preload("res://scripts/behaviors/toxic_burst_behavior.gd"))
	register("arc_burst", preload("res://scripts/behaviors/arc_burst_behavior.gd"))
	register("echo_trigger", preload("res://scripts/behaviors/echo_trigger_behavior.gd"))
	register("plague_carrier", preload("res://scripts/behaviors/plague_carrier_behavior.gd"))
	register("ricochet_amplifier", preload("res://scripts/behaviors/ricochet_amplifier_behavior.gd"))
	register("crit_cascade", preload("res://scripts/behaviors/crit_cascade_behavior.gd"))
	register("returning", preload("res://scripts/behaviors/returning_behavior.gd"))
	register("hypothermia", preload("res://scripts/behaviors/hypothermia_behavior.gd"))
	register("laser", preload("res://scripts/behaviors/laser_behavior.gd"))
	register("copy_paste", preload("res://scripts/behaviors/copy_paste_behavior.gd"))
	register("spaghetti_code", preload("res://scripts/behaviors/spaghetti_code_behavior.gd"))
	register("works_on_my_machine", preload("res://scripts/behaviors/works_on_my_machine_behavior.gd"))
	register("lag_spike", preload("res://scripts/behaviors/lag_spike_behavior.gd"))
	register("alt_f4", preload("res://scripts/behaviors/alt_f4_behavior.gd"))
	register("rubber_duck", preload("res://scripts/behaviors/rubber_duck_behavior.gd"))
	register("firewall", preload("res://scripts/behaviors/firewall_behavior.gd"))
	register("reply_all", preload("res://scripts/behaviors/reply_all_behavior.gd"))
	register("frozen_process", preload("res://scripts/behaviors/frozen_process_behavior.gd"))
	register("wifi_extender", preload("res://scripts/behaviors/wifi_extender_behavior.gd"))
	register("malware", preload("res://scripts/behaviors/malware_behavior.gd"))
	register("background_process", preload("res://scripts/behaviors/background_process_behavior.gd"))
	register("undo_history", preload("res://scripts/behaviors/undo_history_behavior.gd"))

func register(key: String, behavior_script: GDScript) -> void:
	_behaviors[key] = behavior_script

func get_behavior(key: String) -> BehaviorBase:
	if _behaviors.has(key):
		return _behaviors[key].new()
	push_warning("BehaviorRegistry: unknown key '%s'" % key)
	return null

func has_behavior(key: String) -> bool:
	return _behaviors.has(key)
