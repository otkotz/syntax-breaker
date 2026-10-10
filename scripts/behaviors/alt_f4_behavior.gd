class_name AltF4Behavior
extends BehaviorBase

const NORMAL_EXECUTE_RATIO := 0.12
const BOSS_EXECUTE_RATIO := 0.03

static func should_execute_ratio(hp_ratio: float, is_boss: bool, protected: bool = false) -> bool:
	if protected:
		return false
	var threshold := BOSS_EXECUTE_RATIO if is_boss else NORMAL_EXECUTE_RATIO
	return hp_ratio > 0.0 and hp_ratio <= threshold

func on_hit(skill_instance, target: Node2D, _projectile: Node2D) -> void:
	if not target.has_method("take_damage") or not target.has_method("is_alive") or not target.is_alive():
		return
	var protected: bool = target.has_method("is_execution_protected") and target.is_execution_protected()
	var role: String = target.get_meta("combat_role", "")
	var is_boss := role in ["boss", "mini_boss"] or target.is_in_group("bosses")
	var maximum := float(target.get("max_hp"))
	var current := float(target.get("current_hp"))
	if maximum <= 0.0 or not should_execute_ratio(current / maximum, is_boss, protected):
		return
	target.take_damage(current, false, skill_instance.base if skill_instance else null, "execute")
