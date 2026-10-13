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
	var freed_between_batches: Node = nodes[8]
	freed_between_batches.free()
	await get_tree().process_frame
	check(released[0] <= 3, "Cleanup respects per-frame object bound")
	for frame in 8:
		await get_tree().process_frame
		if not result[0].is_empty():
			break
	check(released[0] == 9 and result[0].objects == 10, "Externally freed objects are skipped and every valid object releases once")
	check(result[0].batches >= 4 and result[0].worst_batch_ms >= 0.0, "Cleanup reports bounded batch metrics")
	var packed := PackedScene.new()
	var template := Node2D.new()
	packed.pack(template)
	template.free()
	var pool_host := Node2D.new()
	host.add_child(pool_host)
	var pool := ObjectPool.new(packed, 4, pool_host)
	pool.get_instance()
	var drained := pool.drain_instances()
	check(drained.size() == 4 and pool.active_count() == 0 and pool.pool_count() == 0,
		"Stage teardown can drain active and inactive pooled instances into the batch")
	for instance: Node in drained:
		instance.queue_free()
	host.queue_free()
	if failures.is_empty():
		print("PASS: bounded detach-first stage cleanup")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
