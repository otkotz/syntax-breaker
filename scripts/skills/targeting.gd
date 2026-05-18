class_name Targeting
extends RefCounted

static func find_nearest_enemy(from: Vector2, max_range: float, enemies_group: String = "enemies") -> Node2D:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	var enemies := tree.get_nodes_in_group(enemies_group)
	var nearest: Node2D = null
	var nearest_dist := max_range * max_range

	for enemy in enemies:
		if enemy is Node2D and enemy.is_inside_tree() and not enemy.is_queued_for_deletion():
			if enemy.has_method("is_alive") and not enemy.is_alive():
				continue
			var dist_sq := from.distance_squared_to(enemy.global_position)
			if dist_sq < nearest_dist:
				nearest_dist = dist_sq
				nearest = enemy

	return nearest

static func find_enemies_in_range(from: Vector2, max_range: float, max_count: int = 10, enemies_group: String = "enemies") -> Array[Node2D]:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return []
	var enemies := tree.get_nodes_in_group(enemies_group)
	var in_range: Array[Dictionary] = []
	var range_sq := max_range * max_range

	for enemy in enemies:
		if enemy is Node2D and enemy.is_inside_tree() and not enemy.is_queued_for_deletion():
			if enemy.has_method("is_alive") and not enemy.is_alive():
				continue
			var dist_sq := from.distance_squared_to(enemy.global_position)
			if dist_sq < range_sq:
				in_range.append({"node": enemy, "dist": dist_sq})

	in_range.sort_custom(func(a, b): return a["dist"] < b["dist"])

	var result: Array[Node2D] = []
	for i in mini(in_range.size(), max_count):
		result.append(in_range[i]["node"])
	return result
