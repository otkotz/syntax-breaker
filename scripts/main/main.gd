extends Node

@onready var game_manager: GameManager = $GameManager

func _ready() -> void:
	game_manager.start_run()
