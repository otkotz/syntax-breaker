class_name MainMenu
extends Control

@onready var start_button: Button = $CenterContainer/VBox/StartButton
@onready var title_label: Label = $CenterContainer/VBox/TitleLabel

signal start_pressed

func _ready() -> void:
	start_button.pressed.connect(func(): start_pressed.emit())
	title_label.text = "SYNTAX BREAKER"
