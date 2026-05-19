class_name CombatLog
extends RefCounted

static var enabled := true

static func hit(skill_name: String, target_name: String, damage: float, is_crit: bool) -> void:
	if not enabled:
		return
	var crit_str := " CRIT!" if is_crit else ""
	print("[HIT] %s -> %s for %.1f%s" % [skill_name, target_name, damage, crit_str])

static func dot_applied(dot_type: String, target_name: String, dps: float, duration: float) -> void:
	if not enabled:
		return
	print("[DOT] %s on %s (%.1f/tick, %.1fs)" % [dot_type, target_name, dps, duration])

static func interaction(interaction_name: String, target_name: String, detail: String) -> void:
	if not enabled:
		return
	print("[PROC] %s on %s — %s" % [interaction_name, target_name, detail])

static func kill(skill_name: String, target_name: String) -> void:
	if not enabled:
		return
	print("[KILL] %s killed %s" % [skill_name, target_name])

static func skill_cast(skill_name: String, projectile_count: int) -> void:
	if not enabled:
		return
	if projectile_count > 1:
		print("[CAST] %s x%d" % [skill_name, projectile_count])
	else:
		print("[CAST] %s" % skill_name)
