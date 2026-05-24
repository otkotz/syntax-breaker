class_name ArcBurstBehavior
extends BehaviorBase

const ARC_COUNT := 2
const ARC_DAMAGE_MULT := 0.25
const ARC_RANGE := 120.0
const MAX_Q_ARC_COUNT := 3
const MAX_Q_DAMAGE_MULT := 0.35

func on_crit(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if not TriggerGuard.can_trigger(target):
		return

	TriggerGuard.begin(target)
	var arc_count := MAX_Q_ARC_COUNT if is_max_quality() else ARC_COUNT
	var dmg_mult := MAX_Q_DAMAGE_MULT if is_max_quality() else ARC_DAMAGE_MULT
	var arc_damage: float = skill_instance.computed_stats.get("damage", 10.0) * dmg_mult

	var enemies := Targeting.find_enemies_in_range(target.global_position, ARC_RANGE, arc_count + 1)
	var arced := 0
	for enemy: Node2D in enemies:
		if enemy == target:
			continue
		if arced >= arc_count:
			break
		if enemy.has_method("take_damage"):
			enemy.take_damage(arc_damage)
			arced += 1

	if arced > 0:
		CombatLog.interaction("Arc Burst", target.name, "arced %.1f to %d targets" % [arc_damage, arced])
		RunManager.record_stat("triggers_fired", 1)
	TriggerGuard.end()
