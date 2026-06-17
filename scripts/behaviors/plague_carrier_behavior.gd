class_name PlagueCarrierBehavior
extends BehaviorBase

const SPREAD_COUNT := 2
const SPREAD_RANGE := 100.0
const MAX_Q_SPREAD_COUNT := 3
const MAX_Q_SPREAD_RANGE := 140.0

func on_kill(_skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if not TriggerGuard.can_trigger(target):
		return
	var dots: Dictionary = target.get("_dots") if target else {}
	if not dots or not dots.has("poison"):
		return

	var poison_data: Dictionary = dots["poison"]
	var spread_dmg: float = poison_data["damage"]
	var spread_dur: float = poison_data["remaining"]
	if spread_dur <= 0.1:
		return

	TriggerGuard.begin(target)
	var count := MAX_Q_SPREAD_COUNT if is_mastered() else SPREAD_COUNT
	var radius := MAX_Q_SPREAD_RANGE if is_mastered() else SPREAD_RANGE
	var enemies := Targeting.find_enemies_in_range(target.global_position, radius, count + 1)
	var spread := 0
	for enemy: Node2D in enemies:
		if enemy == target:
			continue
		if spread >= count:
			break
		if enemy.has_method("apply_dot"):
			enemy.apply_dot("poison", spread_dmg, spread_dur, 0.5)
			spread += 1

	if spread > 0:
		CombatLog.interaction("Plague Carrier", target.name, "spread poison to %d" % spread)
		RunManager.record_stat("triggers_fired", 1)
	TriggerGuard.end()
