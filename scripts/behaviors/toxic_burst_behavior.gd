class_name ToxicBurstBehavior
extends BehaviorBase

const BASE_BURST_MULT := 0.4
const MAX_Q_BURST_MULT := 0.6

func on_status_apply(skill_instance, target: Node2D, status_type: String) -> void:
	if status_type != "poison":
		return
	if not TriggerGuard.can_trigger(target):
		return
	if not target.has_method("take_damage"):
		return

	TriggerGuard.begin(target)
	var burst_mult := MAX_Q_BURST_MULT if is_max_quality() else BASE_BURST_MULT
	var burst_damage: float = skill_instance.computed_stats.get("damage", 10.0) * burst_mult
	target.take_damage(burst_damage)
	CombatLog.interaction("Toxic Burst", target.name, "burst %.1f on poison apply" % burst_damage)
	RunManager.record_stat("triggers_fired", 1)
	TriggerGuard.end()
