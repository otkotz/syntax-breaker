class_name DungeonRoomData
extends RefCounted

enum Type { START, COMBAT, ELITE, EVENT, TREASURE, BOSS }

var id: String = ""
var depth: int = 0
var type: Type = Type.COMBAT
var region_id: String = ""

func serialize() -> Dictionary:
	return {
		"id": id,
		"depth": depth,
		"type": int(type),
		"region_id": region_id,
	}

static func deserialize(data: Dictionary) -> DungeonRoomData:
	var room := DungeonRoomData.new()
	if not data.get("id") is String or not data.get("region_id") is String \
		or typeof(data.get("depth")) not in [TYPE_INT, TYPE_FLOAT] \
		or typeof(data.get("type")) not in [TYPE_INT, TYPE_FLOAT]:
		return room
	if data.get("id") is String:
		room.id = data.get("id")
	if typeof(data.get("depth")) in [TYPE_INT, TYPE_FLOAT]:
		room.depth = maxi(0, int(data.get("depth")))
	if typeof(data.get("type")) in [TYPE_INT, TYPE_FLOAT]:
		room.type = clampi(int(data.get("type")), Type.START, Type.BOSS) as Type
	if data.get("region_id") is String:
		room.region_id = data.get("region_id")
	return room
