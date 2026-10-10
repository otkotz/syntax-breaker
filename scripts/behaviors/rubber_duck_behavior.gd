class_name RubberDuckBehavior
extends BehaviorBase

const REQUIRED_HITS := 3
const DEBUG_DURATION := 4.0
const DEBUG_DAMAGE_MULT := 1.25

var _last_target_id := 0
var _consecutive_hits := 0

static func simulate_hits(target_ids: Array) -> Dictionary:
	var last: Variant = null
	var streak := 0
	var debugged: Array = []
	for target_id: Variant in target_ids:
		if target_id == last:
			streak += 1
		else:
			last = target_id
			streak = 1
		if streak == REQUIRED_HITS:
			debugged.append(target_id)
			streak = 0
	return {"debugged_targets": debugged}

func on_hit(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	var target_id := target.get_instance_id()
	if target_id == _last_target_id:
		_consecutive_hits += 1
	else:
		_last_target_id = target_id
		_consecutive_hits = 1
	if _consecutive_hits < REQUIRED_HITS:
		return
	_consecutive_hits = 0
	if target.has_method("apply_debugged"):
		target.apply_debugged(DEBUG_DURATION, DEBUG_DAMAGE_MULT,
			skill_instance.base if skill_instance else null)
		RunManager.record_stat("targets_debugged", 1)
