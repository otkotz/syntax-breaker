class_name DungeonGenerator
extends RefCounted

static func generate(seed_value: int, region_id: String) -> DungeonLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var layout := DungeonLayout.new()
	layout.seed_value = seed_value
	layout.region_id = region_id
	var types: Array[DungeonRoomData.Type] = [
		DungeonRoomData.Type.START,
		DungeonRoomData.Type.COMBAT,
		DungeonRoomData.Type.ELITE if rng.randf() < 0.5 else DungeonRoomData.Type.TREASURE,
		DungeonRoomData.Type.COMBAT if rng.randf() < 0.5 else DungeonRoomData.Type.EVENT,
		DungeonRoomData.Type.BOSS,
	]
	for index in 5:
		var room := DungeonRoomData.new()
		room.id = "room_%d" % index
		room.depth = index
		room.type = types[index]
		room.region_id = region_id
		layout.rooms[room.id] = room
	layout.edges = {
		"room_0": ["room_1", "room_2"],
		"room_1": ["room_3"],
		"room_2": ["room_3"],
		"room_3": ["room_4"],
		"room_4": [],
	}
	layout.start_room_id = "room_0"
	layout.boss_room_id = "room_4"
	layout.current_room_id = "room_0"
	layout.completed_room_ids = ["room_0"]
	return layout
