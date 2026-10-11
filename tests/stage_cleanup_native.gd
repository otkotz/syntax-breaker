extends Node

const CleanupBatchData = preload("res://scripts/stages/cleanup_batch.gd")
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _ready() -> void:
	var host := Node2D.new()
	add_child(host)
	var nodes: Array[Node] = []
	for index in 11:
		var body := CharacterBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 1
		host.add_child(body)
		nodes.append(body)
	var externally_freed: Node = nodes.pop_back()
	externally_freed.free()
	var batch := CleanupBatchData.new()
	host.add_child(batch)
	var released := [0]
	var result := [{}]
	batch.release_callable = func(node: Node):
		released[0] += 1
		node.queue_free()
	batch.finished.connect(func(metrics: Dictionary): result[0] = metrics)
	batch.start(nodes, 3, 100000)
	check(nodes.all(func(node: Node): return not node.is_processing() and not node.is_physics_processing()),
		"Cleanup disables processing immediately")
	check(nodes.all(func(node: Node): return (node as CollisionObject2D).collision_layer == 0),
		"Cleanup disables combat collision immediately")
	await get_tree().process_frame
	check(released[0] <= 3, "Cleanup respects per-frame object bound")
	for frame in 8:
		await get_tree().process_frame
		if not result[0].is_empty():
			break
	check(released[0] == 10 and result[0].objects == 10, "Every still-valid object is released once")
	check(result[0].batches >= 4 and result[0].worst_batch_ms >= 0.0, "Cleanup reports bounded batch metrics")
	host.queue_free()
	if failures.is_empty():
		print("PASS: bounded detach-first stage cleanup")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
