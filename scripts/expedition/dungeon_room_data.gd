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
	room.id = str(data.get("id", ""))
	room.depth = maxi(0, int(data.get("depth", 0)))
	room.type = clampi(int(data.get("type", Type.COMBAT)), Type.START, Type.BOSS) as Type
	room.region_id = str(data.get("region_id", ""))
	return room
