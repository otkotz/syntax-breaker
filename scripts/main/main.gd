extends Node

@onready var game_manager: GameManager = $GameManager

var _main_menu: MainMenu
var _canvas: CanvasLayer

func _ready() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 20
	add_child(_canvas)

	_main_menu = preload("res://scenes/ui/main_menu.tscn").instantiate() as MainMenu
	_canvas.add_child(_main_menu)
	_main_menu.start_pressed.connect(_on_start_run)

	game_manager.return_to_menu_requested.connect(_on_return_to_menu)

func _on_start_run() -> void:
	_main_menu.hide()
	game_manager.start_run()

func _on_return_to_menu() -> void:
	_main_menu.show()
