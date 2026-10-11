class_name CleanupBatch
extends Node

signal finished(metrics: Dictionary)

var release_callable: Callable
var _nodes: Array[Node] = []
var _max_per_frame := 16
var _max_usec := 1500
var _started_usec := 0
var _objects := 0
var _batches := 0
var _worst_batch_usec := 0
var _done := false

func start(nodes: Array[Node], max_per_frame: int = 16, max_usec: int = 1500) -> void:
	_nodes.clear()
	var seen := {}
	for node: Node in nodes:
		if not is_instance_valid(node) or seen.has(node.get_instance_id()):
			continue
		seen[node.get_instance_id()] = true
		_detach_from_combat(node)
		_nodes.append(node)
	_objects = _nodes.size()
	_max_per_frame = maxi(1, max_per_frame)
	_max_usec = maxi(1, max_usec)
	_started_usec = Time.get_ticks_usec()
	set_process(true)
	if _nodes.is_empty():
		_finish()

func _process(_delta: float) -> void:
	if _done:
		return
	var batch_started := Time.get_ticks_usec()
	var processed := 0
	while processed < _max_per_frame and not _nodes.is_empty():
		var node: Variant = _nodes.pop_front()
		if is_instance_valid(node):
			if release_callable.is_valid():
				release_callable.call(node)
			else:
				node.queue_free()
		processed += 1
		if Time.get_ticks_usec() - batch_started >= _max_usec:
			break
	_batches += 1
	_worst_batch_usec = maxi(_worst_batch_usec, Time.get_ticks_usec() - batch_started)
	if _nodes.is_empty():
		_finish()

func _detach_from_combat(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	if node is CollisionObject2D:
		(node as CollisionObject2D).collision_layer = 0
		(node as CollisionObject2D).collision_mask = 0

func _finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	var metrics := {"objects": _objects, "batches": _batches,
		"duration_ms": (Time.get_ticks_usec() - _started_usec) / 1000.0,
		"worst_batch_ms": _worst_batch_usec / 1000.0}
	finished.emit(metrics)
