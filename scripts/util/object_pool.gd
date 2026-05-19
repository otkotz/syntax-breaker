class_name ObjectPool
extends Node

var _scene: PackedScene
var _pool: Array[Node] = []
var _active: Array[Node] = []
var _parent: Node

func _init(scene: PackedScene, initial_size: int, parent: Node) -> void:
	_scene = scene
	_parent = parent
	for i in initial_size:
		var instance := _scene.instantiate()
		instance.set_process(false)
		instance.set_physics_process(false)
		instance.hide()
		_parent.add_child(instance)
		_pool.append(instance)

func get_instance() -> Node:
	var instance: Node
	if _pool.size() > 0:
		instance = _pool.pop_back()
	else:
		instance = _scene.instantiate()
		_parent.add_child(instance)
	instance.set_process(true)
	instance.set_physics_process(true)
	instance.show()
	_active.append(instance)
	return instance

func release(instance: Node) -> void:
	if not _active.has(instance):
		return
	_active.erase(instance)
	instance.set_process(false)
	instance.set_physics_process(false)
	instance.hide()
	if instance.has_method("reset"):
		instance.reset()
	_pool.append(instance)

func release_all() -> void:
	for instance in _active.duplicate():
		release(instance)

func active_count() -> int:
	return _active.size()

func get_active() -> Array[Node]:
	return _active

func pool_count() -> int:
	return _pool.size()
