class_name Minimap
extends Control

const MAP_SIZE := 240.0
const PLAYER_COLOR := Color(0.27, 0.53, 1.0)
const ENEMY_COLOR := Color(1.0, 0.27, 0.27)
const BOSS_COLOR := Color(0.8, 0.13, 0.13)
const BG_COLOR := Color(0.1, 0.1, 0.15, 0.7)
const BORDER_COLOR := Color(0.4, 0.4, 0.5, 0.8)

var _arena_rect: Rect2
var _player: Node2D

func setup(player: Node2D, arena_rect: Rect2) -> void:
	_player = player
	_arena_rect = arena_rect

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_SIZE, MAP_SIZE)), BG_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_SIZE, MAP_SIZE)), BORDER_COLOR, false, 1.0)

	if _arena_rect.size == Vector2.ZERO:
		return

	if _player and is_instance_valid(_player):
		var p := _world_to_minimap(_player.global_position)
		draw_circle(p, 5.0, PLAYER_COLOR)

	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not enemy.visible:
			continue
		var pos := _world_to_minimap(enemy.global_position)
		var is_boss := enemy is MiniBoss
		var dot_size := 5.0 if is_boss else 3.0
		draw_rect(Rect2(pos - Vector2(dot_size / 2, dot_size / 2), Vector2(dot_size, dot_size)), BOSS_COLOR if is_boss else ENEMY_COLOR)

func _world_to_minimap(world_pos: Vector2) -> Vector2:
	var ratio := (world_pos - _arena_rect.position) / _arena_rect.size
	return ratio * MAP_SIZE
