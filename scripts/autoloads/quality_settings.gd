extends Node

enum Preset { HIGH, MEDIUM, LOW }

var current_preset: Preset = Preset.HIGH

var entity_mult: float = 1.0
var projectile_cap: int = 60
var minimap_enabled: bool = true
var minimap_interval: int = 3
var viewport_scale: float = 1.0

func _ready() -> void:
	_auto_detect()
	_apply_preset()

func set_preset(preset: Preset) -> void:
	current_preset = preset
	_apply_preset()

func _auto_detect() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		var cores := OS.get_processor_count()
		if cores <= 4:
			current_preset = Preset.LOW
		else:
			current_preset = Preset.MEDIUM
	else:
		current_preset = Preset.HIGH

func _apply_preset() -> void:
	match current_preset:
		Preset.HIGH:
			entity_mult = 1.0
			projectile_cap = 60
			minimap_enabled = true
			minimap_interval = 3
			viewport_scale = 1.0
		Preset.MEDIUM:
			entity_mult = 0.75
			projectile_cap = 50
			minimap_enabled = true
			minimap_interval = 5
			viewport_scale = 0.75
		Preset.LOW:
			entity_mult = 0.5
			projectile_cap = 40
			minimap_enabled = false
			minimap_interval = 10
			viewport_scale = 0.667

	_apply_viewport_scale()

func _apply_viewport_scale() -> void:
	if viewport_scale < 1.0:
		var base_w := 1080
		var base_h := 1920
		var window := get_viewport()
		if window:
			window.size = Vector2i(int(base_w * viewport_scale), int(base_h * viewport_scale))
