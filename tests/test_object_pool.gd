extends GutTest

var _pool: ObjectPool
var _parent: Node2D

func before_each() -> void:
	_parent = Node2D.new()
	add_child_autofree(_parent)
	var scene := PackedScene.new()
	var node := Sprite2D.new()
	scene.pack(node)
	node.free()
	_pool = ObjectPool.new(scene, 3, _parent)

func test_initial_pool_size() -> void:
	assert_eq(_pool.pool_count(), 3)
	assert_eq(_pool.active_count(), 0)

func test_get_instance_moves_to_active() -> void:
	var inst := _pool.get_instance()
	assert_not_null(inst)
	assert_eq(_pool.active_count(), 1)
	assert_eq(_pool.pool_count(), 2)
	assert_true(inst.visible)

func test_release_returns_to_pool() -> void:
	var inst := _pool.get_instance()
	_pool.release(inst)
	assert_eq(_pool.active_count(), 0)
	assert_eq(_pool.pool_count(), 3)
	assert_false(inst.visible)

func test_get_beyond_pool_creates_new() -> void:
	for i in 4:
		_pool.get_instance()
	assert_eq(_pool.active_count(), 4)
	assert_eq(_pool.pool_count(), 0)

func test_release_all() -> void:
	for i in 3:
		_pool.get_instance()
	_pool.release_all()
	assert_eq(_pool.active_count(), 0)
	assert_eq(_pool.pool_count(), 3)
