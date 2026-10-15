class_name DungeonLayout
extends RefCounted

var seed_value: int = 0
var region_id: String = ""
var rooms: Dictionary = {}
var edges: Dictionary = {}
var start_room_id: String = ""
var boss_room_id: String = ""
var current_room_id: String = ""
var completed_room_ids: Array[String] = []

func get_outgoing(room_id: String) -> Array[String]:
	var result: Array[String] = []
	for target: Variant in edges.get(room_id, []):
		var target_id := str(target)
		if rooms.has(target_id):
			result.append(target_id)
	return result

func get_available_room_ids() -> Array[String]:
	var result: Array[String] = []
	for room_id: String in get_outgoing(current_room_id):
		if not completed_room_ids.has(room_id):
			result.append(room_id)
	return result

func has_path(from_room_id: String, to_room_id: String) -> bool:
	if not rooms.has(from_room_id) or not rooms.has(to_room_id):
		return false
	var pending: Array[String] = [from_room_id]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var room_id: String = pending.pop_back()
		if room_id == to_room_id:
			return true
		if visited.has(room_id):
			continue
		visited[room_id] = true
		for next_room_id: String in get_outgoing(room_id):
			if not visited.has(next_room_id):
				pending.append(next_room_id)
	return false

func serialize() -> Dictionary:
	var serialized_rooms: Array[Dictionary] = []
	var room_ids: Array = rooms.keys()
	room_ids.sort()
	for room_id: String in room_ids:
		serialized_rooms.append((rooms[room_id] as DungeonRoomData).serialize())
	var serialized_edges: Dictionary = {}
	for room_id: String in room_ids:
		serialized_edges[room_id] = get_outgoing(room_id)
	return {
		"seed_value": seed_value,
		"region_id": region_id,
		"rooms": serialized_rooms,
		"edges": serialized_edges,
		"start_room_id": start_room_id,
		"boss_room_id": boss_room_id,
		"current_room_id": current_room_id,
		"completed_room_ids": completed_room_ids,
	}

static func deserialize(data: Dictionary) -> DungeonLayout:
	var layout := DungeonLayout.new()
	if not data.get("rooms", []) is Array or not data.get("edges", {}) is Dictionary \
		or not data.get("completed_room_ids", []) is Array:
		return layout
	if typeof(data.get("seed_value")) in [TYPE_INT, TYPE_FLOAT]:
		layout.seed_value = int(data.get("seed_value"))
	if data.get("region_id") is String:
		layout.region_id = data.get("region_id")
	for room_data: Variant in data.get("rooms", []):
		if not room_data is Dictionary:
			continue
		var room := DungeonRoomData.deserialize(room_data)
		if not room.id.is_empty():
			layout.rooms[room.id] = room
	for source: Variant in data.get("edges", {}):
		var source_id := str(source)
		if not layout.rooms.has(source_id):
			continue
		var valid_targets: Array[String] = []
		var targets: Variant = data.get("edges", {})[source]
		if not targets is Array:
			return DungeonLayout.new()
		for target: Variant in targets:
			var target_id := str(target)
			if layout.rooms.has(target_id) and not valid_targets.has(target_id):
				valid_targets.append(target_id)
		layout.edges[source_id] = valid_targets
	for room_id: String in layout.rooms:
		if not layout.edges.has(room_id):
			layout.edges[room_id] = [] as Array[String]
	if data.get("start_room_id") is String:
		layout.start_room_id = data.get("start_room_id")
	if data.get("boss_room_id") is String:
		layout.boss_room_id = data.get("boss_room_id")
	if data.get("current_room_id") is String:
		layout.current_room_id = data.get("current_room_id")
	for completed_id: Variant in data.get("completed_room_ids", []):
		var room_id := str(completed_id)
		if layout.rooms.has(room_id) and not layout.completed_room_ids.has(room_id):
			layout.completed_room_ids.append(room_id)
	return layout
