class_name SynergyTracker
extends RefCounted

const SYNERGY_WINDOW := 1.5
const ELEMENT_TAGS := ["fire", "lightning", "poison", "cold"]

static var _recent_hits: Dictionary = {}

static func record_and_check(target: Node2D, tags: Array, damage: float) -> void:
	var eid := target.get_instance_id()
	var now := Time.get_ticks_msec() / 1000.0

	if not _recent_hits.has(eid):
		_recent_hits[eid] = {}
	var recent: Dictionary = _recent_hits[eid]

	var new_elements: Array[String] = []
	for tag: String in tags:
		if tag in ELEMENT_TAGS:
			recent[tag] = now
			new_elements.append(tag)

	var expired: Array[String] = []
	for tag: String in recent:
		if now - recent[tag] > SYNERGY_WINDOW:
			expired.append(tag)
	for tag: String in expired:
		recent.erase(tag)

	if new_elements.is_empty():
		return

	var active: Array[String] = []
	for tag: String in recent:
		active.append(tag)

	if active.has("fire") and active.has("lightning") and ("fire" in new_elements or "lightning" in new_elements):
		_trigger_overload(target, damage)
		recent.erase("fire")
		recent.erase("lightning")
	elif active.has("lightning") and active.has("cold") and ("lightning" in new_elements or "cold" in new_elements):
		_trigger_shatter(target, damage)
		recent.erase("lightning")
		recent.erase("cold")
	elif active.has("cold") and active.has("poison") and ("cold" in new_elements or "poison" in new_elements):
		_trigger_frostblight(target, damage)
		recent.erase("cold")
		recent.erase("poison")

static func _trigger_overload(target: Node2D, damage: float) -> void:
	var burst := damage * 0.8
	var enemies := Targeting.find_enemies_in_range(target.global_position, 130.0, 20)
	for e: Node2D in enemies:
		if e.has_method("take_damage"):
			e.take_damage(burst)
	CombatLog.interaction("Overload", target.name, "fire+lightning AoE %.1f to %d" % [burst, enemies.size()])

static func _trigger_shatter(target: Node2D, damage: float) -> void:
	var burst := damage * 2.0
	if target.has_method("take_damage"):
		target.take_damage(burst)
	CombatLog.interaction("Shatter", target.name, "lightning+cold burst %.1f" % burst)

static func _trigger_frostblight(target: Node2D, damage: float) -> void:
	if target.has_method("apply_dot"):
		target.apply_dot("frostblight", damage * 0.6, 4.0, 0.5)
	var enemies := Targeting.find_enemies_in_range(target.global_position, 120.0, 10)
	var spread := 0
	for e: Node2D in enemies:
		if e != target and e.has_method("apply_dot"):
			e.apply_dot("frostblight", damage * 0.4, 3.0, 0.5)
			spread += 1
	CombatLog.interaction("Frostblight", target.name, "cold+poison spread to %d" % spread)

static func clear() -> void:
	_recent_hits.clear()
