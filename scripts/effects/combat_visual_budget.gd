class_name CombatVisualBudget
extends RefCounted

const DAMAGE_AGGREGATION_WINDOW := 0.25
const CAPS := {
	&"hit_flash": 8,
	&"death_signature": 8,
	&"full_trail": 24,
	&"hero_moment": 2,
}

static var _active: Dictionary = {}
static var _damage_windows: Dictionary = {}


static func reset() -> void:
	_active.clear()
	_damage_windows.clear()


static func request(kind: StringName, _priority: int, origin_id: int) -> bool:
	if kind == &"hostile_warning":
		return true
	var cap: int = CAPS.get(kind, 0)
	if cap <= 0:
		return true
	var origins: Dictionary = _active.get(kind, {})
	if origins.has(origin_id):
		return true
	if origins.size() >= cap:
		return false
	origins[origin_id] = true
	_active[kind] = origins
	return true


static func release(kind: StringName, origin_id: int) -> void:
	var origins: Dictionary = _active.get(kind, {})
	origins.erase(origin_id)
	if origins.is_empty():
		_active.erase(kind)
	else:
		_active[kind] = origins


static func active_count(kind: StringName) -> int:
	return (_active.get(kind, {}) as Dictionary).size()


static func aggregate_damage(target_id: int, source_id: StringName, amount: float, now: float) -> Dictionary:
	var key := "%d:%s" % [target_id, source_id]
	var previous: Dictionary = _damage_windows.get(key, {})
	var merged := not previous.is_empty() and now - float(previous.get("window_start", -INF)) <= DAMAGE_AGGREGATION_WINDOW
	var total := amount + (float(previous.get("amount", 0.0)) if merged else 0.0)
	_damage_windows[key] = {"window_start": previous.get("window_start", now) if merged else now, "amount": total}
	return {"key": key, "amount": total, "merged": merged}
