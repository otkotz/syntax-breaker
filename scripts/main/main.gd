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
	_main_menu.unlocks_pressed.connect(_on_unlocks)
	_main_menu.codex_pressed.connect(_on_codex)

	game_manager.return_to_menu_requested.connect(_on_return_to_menu)

	if game_manager.has_saved_run():
		_show_resume_prompt()

func _on_start_run() -> void:
	_main_menu.hide()
	var region := _main_menu.get_selected_region()
	game_manager.start_run(region)

func _on_return_to_menu() -> void:
	_main_menu.show()

func _on_unlocks() -> void:
	var tree_ui := preload("res://scenes/ui/unlock_tree.tscn").instantiate()
	_canvas.add_child(tree_ui)

func _on_codex() -> void:
	var codex_ui := preload("res://scenes/ui/codex.tscn").instantiate()
	_canvas.add_child(codex_ui)

func _show_resume_prompt() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "A saved run was found.\nResume where you left off?"
	dialog.ok_button_text = "Resume"
	dialog.cancel_button_text = "New Run"
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_main_menu.hide()
		game_manager.resume_run()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
		RunManager.clear_saved_run()
	)
	_canvas.add_child(dialog)
	dialog.popup_centered()
