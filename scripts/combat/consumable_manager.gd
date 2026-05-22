class_name ConsumableManager
extends Node

signal consumable_used(index: int)
signal effect_expired(effect_type: String)

const MAX_SLOTS := 4

var slots: Array[ConsumableResource] = []
var charges: Array[int] = []
var _active_effects: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("consumable_manager")

func setup(consumable_data: Array[Dictionary]) -> void:
	slots.clear()
	charges.clear()
	for entry: Dictionary in consumable_data:
		var res: ConsumableResource = entry.get("resource")
		if res:
			slots.append(res)
			charges.append(entry.get("charges", 1))

func use_consumable(index: int) -> bool:
	if index < 0 or index >= slots.size():
		return false
	if charges[index] <= 0:
		return false

	var res := slots[index]
	charges[index] -= 1
	_apply_effect(res)
	consumable_used.emit(index)

	if charges[index] <= 0:
		slots.remove_at(index)
		charges.remove_at(index)

	return true

func _apply_effect(res: ConsumableResource) -> void:
	match res.effect_type:
		"heal":
			_apply_heal(res.magnitude)
		"bomb":
			_apply_bomb(res.magnitude)
		"magnet":
			_apply_magnet()
		_:
			if res.duration > 0.0:
				_active_effects.append({
					"type": res.effect_type,
					"remaining": res.duration,
					"magnitude": res.magnitude,
				})

func _process(delta: float) -> void:
	var i := _active_effects.size() - 1
	while i >= 0:
		_active_effects[i]["remaining"] -= delta
		if _active_effects[i]["remaining"] <= 0.0:
			var etype: String = _active_effects[i]["type"]
			_active_effects.remove_at(i)
			effect_expired.emit(etype)
		i -= 1

func get_damage_mult() -> float:
	var mult := 1.0
	for effect: Dictionary in _active_effects:
		match effect["type"]:
			"damage_buff":
				mult *= effect["magnitude"]
			"berserk":
				mult *= effect["magnitude"]
	return mult

func get_cooldown_mult() -> float:
	var mult := 1.0
	for effect: Dictionary in _active_effects:
		if effect["type"] == "cooldown_buff":
			mult *= (1.0 / effect["magnitude"])
	return mult

func get_speed_mult() -> float:
	var mult := 1.0
	for effect: Dictionary in _active_effects:
		if effect["type"] == "speed_buff":
			mult *= effect["magnitude"]
	return mult

func get_damage_taken_mult() -> float:
	var mult := 1.0
	for effect: Dictionary in _active_effects:
		if effect["type"] == "berserk":
			mult *= 2.0
	return mult

func get_enemy_speed_mult() -> float:
	var mult := 1.0
	for effect: Dictionary in _active_effects:
		if effect["type"] == "time_slow":
			mult *= effect["magnitude"]
	return mult

func has_auto_revive() -> bool:
	for i in slots.size():
		if slots[i].effect_type == "revive" and charges[i] > 0:
			return true
	return false

func consume_auto_revive() -> bool:
	for i in slots.size():
		if slots[i].effect_type == "revive" and charges[i] > 0:
			charges[i] -= 1
			if charges[i] <= 0:
				slots.remove_at(i)
				charges.remove_at(i)
			return true
	return false

func _apply_heal(magnitude: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].has_method("heal"):
		var player: Node = players[0]
		var heal_amount: float = player.max_hp * magnitude
		player.heal(heal_amount)

func _apply_bomb(magnitude: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy: Node in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(magnitude)

func _apply_magnet() -> void:
	var pickups := get_tree().get_nodes_in_group("pickups")
	for pickup: Node in pickups:
		if pickup.has_method("attract"):
			pickup.attract()

func get_slot_count() -> int:
	return slots.size()

func get_slot_info(index: int) -> Dictionary:
	if index < 0 or index >= slots.size():
		return {}
	return {"resource": slots[index], "charges": charges[index]}
