class_name SpatialGrid
extends RefCounted

var _cell_size: float
var _cells: Dictionary = {}
var _entity_cells: Dictionary = {}

func _init(cell_size: float = 100.0) -> void:
	_cell_size = cell_size

func clear() -> void:
	_cells.clear()
	_entity_cells.clear()

func update_entity(entity: Node2D) -> void:
	var id := entity.get_instance_id()
	var new_cell := _pos_to_cell(entity.global_position)
	if _entity_cells.has(id):
		var old_cell: Vector2i = _entity_cells[id]
		if old_cell == new_cell:
			return
		_remove_from_cell(id, old_cell)
	_add_to_cell(id, entity, new_cell)
	_entity_cells[id] = new_cell

func remove_entity(entity: Node2D) -> void:
	var id := entity.get_instance_id()
	if _entity_cells.has(id):
		_remove_from_cell(id, _entity_cells[id])
		_entity_cells.erase(id)

func query_nearest(pos: Vector2, max_range: float) -> Node2D:
	var range_sq := max_range * max_range
	var nearest: Node2D = null
	var nearest_dist_sq := range_sq
	var min_cell := _pos_to_cell(pos - Vector2(max_range, max_range))
	var max_cell := _pos_to_cell(pos + Vector2(max_range, max_range))
	for cx in range(min_cell.x, max_cell.x + 1):
		for cy in range(min_cell.y, max_cell.y + 1):
			var cell_key := Vector2i(cx, cy)
			if not _cells.has(cell_key):
				continue
			var bucket: Array = _cells[cell_key]
			for entry: Array in bucket:
				var raw = entry[1]
				if not is_instance_valid(raw):
					continue
				var entity: Node2D = raw
				if not entity.visible:
					continue
				if entity.has_method("is_alive") and not entity.is_alive():
					continue
				var dist_sq := pos.distance_squared_to(entity.global_position)
				if dist_sq < nearest_dist_sq:
					nearest_dist_sq = dist_sq
					nearest = entity
	return nearest

func query_range(pos: Vector2, max_range: float, max_count: int = 50) -> Array[Node2D]:
	var range_sq := max_range * max_range
	var results: Array[Dictionary] = []
	var min_cell := _pos_to_cell(pos - Vector2(max_range, max_range))
	var max_cell := _pos_to_cell(pos + Vector2(max_range, max_range))
	for cx in range(min_cell.x, max_cell.x + 1):
		for cy in range(min_cell.y, max_cell.y + 1):
			var cell_key := Vector2i(cx, cy)
			if not _cells.has(cell_key):
				continue
			var bucket: Array = _cells[cell_key]
			for entry: Array in bucket:
				var raw = entry[1]
				if not is_instance_valid(raw):
					continue
				var entity: Node2D = raw
				if not entity.visible:
					continue
				if entity.has_method("is_alive") and not entity.is_alive():
					continue
				var dist_sq := pos.distance_squared_to(entity.global_position)
				if dist_sq < range_sq:
					results.append({"node": entity, "dist": dist_sq})
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["dist"] < b["dist"])
	var out: Array[Node2D] = []
	for i in mini(results.size(), max_count):
		out.append(results[i]["node"])
	return out

func _pos_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / _cell_size)), int(floor(pos.y / _cell_size)))

func _add_to_cell(id: int, entity: Node2D, cell: Vector2i) -> void:
	if not _cells.has(cell):
		_cells[cell] = []
	_cells[cell].append([id, entity])

func _remove_from_cell(id: int, cell: Vector2i) -> void:
	if not _cells.has(cell):
		return
	var bucket: Array = _cells[cell]
	for i in range(bucket.size() - 1, -1, -1):
		if bucket[i][0] == id:
			bucket.remove_at(i)
			break
	if bucket.is_empty():
		_cells.erase(cell)
