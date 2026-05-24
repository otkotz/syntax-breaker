class_name StageTree
extends RefCounted

var rows: Array = []
var edges: Array = []
var visited: Array = []
var current_depth: int = 0
var _region: RegionResource

func generate(region: RegionResource = null) -> void:
	_region = region
	rows.clear()
	edges.clear()
	visited.clear()

	for depth in StageGenerator.MAX_DEPTH:
		var d := depth + 1
		var row: Array = []
		if d == 1:
			row.append(_make_node(StageData.Type.COMBAT, d))
		elif d in StageGenerator.BOSS_DEPTHS:
			row.append(_make_node(StageData.Type.BOSS, d))
		else:
			row = _generate_row(d)
		rows.append(row)
		visited.append(-1)

	for depth in StageGenerator.MAX_DEPTH - 1:
		edges.append(_generate_edges(depth))

func _make_node(type: StageData.Type, depth: int) -> Dictionary:
	var node := {"type": type, "depth": depth, "modifiers": [] as Array[String]}
	if type in [StageData.Type.COMBAT, StageData.Type.ELITE]:
		node["modifiers"] = _roll_modifiers(depth)
	return node

func _roll_modifiers(depth: int) -> Array[String]:
	var mods: Array[String] = []
	if _region:
		for mod: String in _region.stage_modifiers:
			if not mods.has(mod):
				mods.append(mod)
	if depth < 3:
		return mods
	var count := 1 if depth < 7 else 2
	var pool := StageGenerator.ALL_MODIFIERS.duplicate()
	for existing: String in mods:
		pool.erase(existing)
	pool.shuffle()
	for i in mini(count, pool.size()):
		mods.append(pool[i])
	return mods

func _generate_row(depth: int) -> Array:
	var row: Array = []
	for i in 3:
		var type := _pick_node_type(depth, i)
		row.append(_make_node(type, depth))
	var has_combat := false
	for node: Dictionary in row:
		if node["type"] == StageData.Type.COMBAT:
			has_combat = true
			break
	if not has_combat:
		row[0] = _make_node(StageData.Type.COMBAT, depth)
	return row

func _pick_node_type(depth: int, _index: int) -> StageData.Type:
	var roll := randf()
	if depth >= 3:
		if roll < 0.20:
			return StageData.Type.ELITE
		if roll < 0.35:
			return StageData.Type.SHOP
		if roll < 0.50:
			return StageData.Type.TREASURE
	elif depth >= 2:
		if roll < 0.15:
			return StageData.Type.TREASURE
	return StageData.Type.COMBAT

func _generate_edges(from_depth_idx: int) -> Array:
	var from_row: Array = rows[from_depth_idx]
	var to_row: Array = rows[from_depth_idx + 1]
	var result: Array = []

	if from_row.size() == 1:
		for to_idx in to_row.size():
			result.append(Vector2i(0, to_idx))
		return result

	if to_row.size() == 1:
		for from_idx in from_row.size():
			result.append(Vector2i(from_idx, 0))
		return result

	var to_connected: Dictionary = {}
	for from_idx in from_row.size():
		var primary := clampi(from_idx, 0, to_row.size() - 1)
		result.append(Vector2i(from_idx, primary))
		to_connected[primary] = true

		if randf() < 0.5:
			var secondary := -1
			if primary > 0 and randf() < 0.5:
				secondary = primary - 1
			elif primary < to_row.size() - 1:
				secondary = primary + 1
			elif primary > 0:
				secondary = primary - 1
			if secondary >= 0:
				var edge := Vector2i(from_idx, secondary)
				if not result.has(edge):
					result.append(edge)
				to_connected[secondary] = true

	for to_idx in to_row.size():
		if not to_connected.has(to_idx):
			var closest := clampi(to_idx, 0, from_row.size() - 1)
			result.append(Vector2i(closest, to_idx))

	return result

func get_available_nodes() -> Array[int]:
	var available: Array[int] = []
	if current_depth >= StageGenerator.MAX_DEPTH:
		return available
	if current_depth <= 0:
		return [0]

	var edge_idx := current_depth - 1
	if edge_idx >= edges.size():
		return available

	var last_visited: int = visited[current_depth - 1]
	if last_visited < 0:
		return available

	var edge_list: Array = edges[edge_idx]
	for edge: Vector2i in edge_list:
		if edge.x == last_visited and not available.has(edge.y):
			available.append(edge.y)

	return available

func visit(node_index: int) -> StageData:
	visited[current_depth] = node_index
	var node: Dictionary = rows[current_depth][node_index]
	var stage := StageData.new()
	stage.type = node["type"] as StageData.Type
	stage.depth = node["depth"]
	stage.modifiers = node["modifiers"]
	stage.region = _region
	current_depth += 1
	return stage

func get_node_data(depth_idx: int, node_idx: int) -> Dictionary:
	if depth_idx < rows.size() and node_idx < rows[depth_idx].size():
		return rows[depth_idx][node_idx]
	return {}

func serialize() -> Dictionary:
	var s_rows: Array = []
	for row: Array in rows:
		var s_row: Array = []
		for node: Dictionary in row:
			s_row.append({"type": node["type"], "depth": node["depth"], "modifiers": node["modifiers"]})
		s_rows.append(s_row)

	var s_edges: Array = []
	for edge_row: Array in edges:
		var s_edge: Array = []
		for edge: Vector2i in edge_row:
			s_edge.append([edge.x, edge.y])
		s_edges.append(s_edge)

	return {
		"rows": s_rows,
		"edges": s_edges,
		"visited": visited,
		"current_depth": current_depth,
	}

static func deserialize(data: Dictionary, region: RegionResource = null) -> StageTree:
	var tree := StageTree.new()
	tree._region = region
	for row_data: Array in data.get("rows", []):
		var row: Array = []
		for node_data: Dictionary in row_data:
			row.append({
				"type": int(node_data["type"]) as StageData.Type,
				"depth": int(node_data["depth"]),
				"modifiers": node_data.get("modifiers", []),
			})
		tree.rows.append(row)

	for edge_data: Array in data.get("edges", []):
		var edge_row: Array = []
		for pair: Array in edge_data:
			edge_row.append(Vector2i(int(pair[0]), int(pair[1])))
		tree.edges.append(edge_row)

	tree.visited = []
	for v in data.get("visited", []):
		tree.visited.append(int(v))
	tree.current_depth = int(data.get("current_depth", 0))
	return tree
