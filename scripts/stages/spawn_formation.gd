class_name SpawnFormation
extends RefCounted

enum Type { RING, LINES, CLUSTER, STREAM, SCATTERED }

static func get_positions(type: Type, count: int, arena: Rect2, player_pos: Vector2) -> Array[Vector2]:
	if count <= 0:
		return []
	match type:
		Type.RING:
			return _ring(count, arena, player_pos)
		Type.LINES:
			return _lines(count, arena)
		Type.CLUSTER:
			return _cluster(count, arena, player_pos)
		Type.STREAM:
			return _stream(count, arena)
		Type.SCATTERED:
			return _scattered(count, arena, player_pos)
	return _scattered(count, arena, player_pos)

static func random_edge_position(arena: Rect2, player_pos: Vector2) -> Vector2:
	return _random_edge_point(arena, player_pos)

static func _ring(count: int, arena: Rect2, player_pos: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var offset_angle := randf() * TAU
	for i in count:
		var angle := offset_angle + (float(i) / count) * TAU
		var dir := Vector2.from_angle(angle)
		positions.append(_project_to_edge(player_pos, dir, arena))
	return positions

static func _lines(count: int, arena: Rect2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var edge := randi() % 4
	var margin := 40.0
	for i in count:
		var t := (float(i) + 0.5) / count
		var pos: Vector2
		match edge:
			0:
				pos = Vector2(lerpf(arena.position.x + margin, arena.end.x - margin, t), arena.position.y + margin)
			1:
				pos = Vector2(lerpf(arena.position.x + margin, arena.end.x - margin, t), arena.end.y - margin)
			2:
				pos = Vector2(arena.position.x + margin, lerpf(arena.position.y + margin, arena.end.y - margin, t))
			_:
				pos = Vector2(arena.end.x - margin, lerpf(arena.position.y + margin, arena.end.y - margin, t))
		positions.append(pos)
	return positions

static func _cluster(count: int, arena: Rect2, player_pos: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var num_clusters := clampi(count / 6, 2, 4)
	var per_cluster := count / num_clusters
	var remainder := count % num_clusters
	for c in num_clusters:
		var center := _random_edge_point(arena, player_pos)
		var c_count := per_cluster + (1 if c < remainder else 0)
		for i in c_count:
			var offset := Vector2(randf_range(-35, 35), randf_range(-35, 35))
			positions.append(center + offset)
	return positions

static func _stream(count: int, arena: Rect2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var edge := randi() % 4
	var margin := 40.0
	var center_t := randf_range(0.3, 0.7)
	for i in count:
		var t := clampf(center_t + randf_range(-0.08, 0.08), 0.05, 0.95)
		var spread := randf_range(-25, 25)
		var pos: Vector2
		match edge:
			0:
				pos = Vector2(lerpf(arena.position.x, arena.end.x, t), arena.position.y + margin + spread * 0.3)
			1:
				pos = Vector2(lerpf(arena.position.x, arena.end.x, t), arena.end.y - margin + spread * 0.3)
			2:
				pos = Vector2(arena.position.x + margin + spread * 0.3, lerpf(arena.position.y, arena.end.y, t))
			_:
				pos = Vector2(arena.end.x - margin + spread * 0.3, lerpf(arena.position.y, arena.end.y, t))
		positions.append(pos)
	return positions

static func _scattered(count: int, arena: Rect2, player_pos: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for i in count:
		positions.append(_random_edge_point(arena, player_pos))
	return positions

static func _random_edge_point(arena: Rect2, player_pos: Vector2) -> Vector2:
	var margin := 40.0
	var min_dist := 150.0
	for attempt in 10:
		var edge := randi() % 4
		var pos: Vector2
		match edge:
			0:
				pos = Vector2(randf_range(arena.position.x + margin, arena.end.x - margin), arena.position.y + margin)
			1:
				pos = Vector2(randf_range(arena.position.x + margin, arena.end.x - margin), arena.end.y - margin)
			2:
				pos = Vector2(arena.position.x + margin, randf_range(arena.position.y + margin, arena.end.y - margin))
			_:
				pos = Vector2(arena.end.x - margin, randf_range(arena.position.y + margin, arena.end.y - margin))
		if pos.distance_to(player_pos) > min_dist:
			return pos
	return Vector2(arena.end.x - margin, arena.get_center().y)

static func _project_to_edge(origin: Vector2, direction: Vector2, arena: Rect2) -> Vector2:
	var margin := 40.0
	var inner := Rect2(
		arena.position + Vector2(margin, margin),
		arena.size - Vector2(margin * 2, margin * 2)
	)
	var best_t := 99999.0
	if direction.x != 0:
		var t_left := (inner.position.x - origin.x) / direction.x
		if t_left > 0:
			var yl := origin.y + direction.y * t_left
			if yl >= inner.position.y and yl <= inner.end.y:
				best_t = minf(best_t, t_left)
		var t_right := (inner.end.x - origin.x) / direction.x
		if t_right > 0:
			var yr := origin.y + direction.y * t_right
			if yr >= inner.position.y and yr <= inner.end.y:
				best_t = minf(best_t, t_right)
	if direction.y != 0:
		var t_top := (inner.position.y - origin.y) / direction.y
		if t_top > 0:
			var xt := origin.x + direction.x * t_top
			if xt >= inner.position.x and xt <= inner.end.x:
				best_t = minf(best_t, t_top)
		var t_bottom := (inner.end.y - origin.y) / direction.y
		if t_bottom > 0:
			var xb := origin.x + direction.x * t_bottom
			if xb >= inner.position.x and xb <= inner.end.x:
				best_t = minf(best_t, t_bottom)
	if best_t < 99999.0:
		return origin + direction * best_t
	return _random_edge_point(arena, origin)
