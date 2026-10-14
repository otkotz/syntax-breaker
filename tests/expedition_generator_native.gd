extends Node

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	var first := DungeonGenerator.generate(20261014, "burning_grounds")
	var repeated := DungeonGenerator.generate(20261014, "burning_grounds")
	var other := DungeonGenerator.generate(20261015, "burning_grounds")
	check(first.serialize() == repeated.serialize(), "Same seed reproduces identical layout")
	check(first.serialize() != other.serialize(), "Different seed changes room assignment")
	check(first.rooms.size() == 5, "Prototype contains five rooms")
	check(first.start_room_id == "room_0" and first.boss_room_id == "room_4", "Start and boss are stable")
	check(first.has_path(first.start_room_id, first.boss_room_id), "Boss is reachable")
	check(first.get_outgoing("room_0").size() == 2, "Start presents a route choice")
	var restored := DungeonLayout.deserialize(first.serialize())
	check(restored.serialize() == first.serialize(), "Layout roundtrip preserves graph")
	seed(90210)
	var global_before := randf()
	DungeonGenerator.generate(44, "burning_grounds")
	var global_after := randf()
	seed(90210)
	var expected_before := randf()
	var expected_after := randf()
	check(global_before == expected_before and global_after == expected_after, "Generator leaves global RNG untouched")
	print(JSON.stringify({"failures": failures, "rooms": first.rooms.size()}))
	get_tree().quit(0 if failures.is_empty() else 1)
