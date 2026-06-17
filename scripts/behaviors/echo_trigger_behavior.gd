class_name EchoTriggerBehavior
extends BehaviorBase

const BASE_CHANCE := 0.3
const DAMAGE_MULT := 0.5
const MAX_Q_CHANCE := 0.4
const MAX_Q_DAMAGE_MULT := 0.65

func on_kill(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if not TriggerGuard.can_trigger(target):
		return

	var chance := MAX_Q_CHANCE if is_mastered() else BASE_CHANCE
	if randf() > chance:
		return

	var nearest := Targeting.find_nearest_enemy(target.global_position, 300.0)
	if not nearest or nearest == target:
		return
	if not nearest.has_method("take_damage"):
		return
	if ProjectileBase.active_count >= QualitySettings.projectile_cap:
		return

	TriggerGuard.begin(target)
	var dmg_mult := MAX_Q_DAMAGE_MULT if is_mastered() else DAMAGE_MULT
	var echo_damage: float = skill_instance.computed_stats.get("damage", 10.0) * dmg_mult
	echo_damage *= ComboTracker.current_multiplier
	nearest.take_damage(echo_damage)
	CombatLog.interaction("Echo Trigger", target.name, "echo %.1f to %s" % [echo_damage, nearest.name])
	RunManager.record_stat("triggers_fired", 1)
	TriggerGuard.end()
