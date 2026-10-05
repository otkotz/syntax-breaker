extends Node2D

const Zone = preload("res://scripts/enemies/denial_zone.gd")
const MAX_HAZARDS := 6
var kind: String = ""
var cooldown: float = 1.5
var enemy: EnemyBase

func _ready() -> void:
	enemy = get_parent() as EnemyBase
	enemy.died.connect(_on_enemy_died)

func configure(affix: String) -> void:
	kind = affix if affix in ["trail", "nova"] else ""
	cooldown = 1.5
	queue_redraw()

func reset_affix() -> void:
	configure("")

func _process(delta: float) -> void:
	if kind != "trail" or not enemy.is_alive() or not is_instance_valid(enemy._target):
		return
	cooldown -= delta
	# Short range prevents new hazards appearing without an on-screen warning.
	if cooldown <= 0.0 and enemy.global_position.distance_to(enemy._target.global_position) <= 200.0:
		if get_tree().get_nodes_in_group("elite_hazards").size() < MAX_HAZARDS - 1:
			_spawn_zone(false)
		cooldown = 1.5

func _on_enemy_died(_dead: EnemyBase) -> void:
	if kind == "nova" and is_instance_valid(enemy._target):
		if get_tree().get_nodes_in_group("elite_hazards").size() < MAX_HAZARDS:
			_spawn_zone(true)
	reset_affix()

func _spawn_zone(nova: bool) -> void:
	var zone := Zone.new()
	zone.zone_group = "elite_hazards"
	zone.target = enemy._target
	zone.source_id = "elite:" + ("nova" if nova else "trail")
	zone.damage_context = enemy.get_damage_context()
	zone.radius = 100.0 if nova else 32.0
	zone.color = Color(1.0, 0.15, 0.25) if nova else Color(1.0, 0.9, 0.15)
	zone.damage = enemy.contact_damage * (1.2 if nova else 0.5)
	zone.warning_duration = 1.2 if nova else 0.8
	zone.warning_remaining = zone.warning_duration
	zone.active_remaining = 0.6 if nova else 2.5
	zone.tick_interval = 100.0 if nova else 0.5
	enemy.get_parent().add_child(zone)
	zone.global_position = enemy.global_position
	RunTelemetry.record("hazard_warning", {"source": zone.source_id, "warning_seconds": zone.warning_duration, "x": zone.global_position.x, "y": zone.global_position.y})

func _draw() -> void:
	if kind.is_empty():
		return
	var color := Color(1.0, 0.15, 0.25) if kind == "nova" else Color(1.0, 0.9, 0.15)
	draw_string(ThemeDB.fallback_font, Vector2(-24, -94), kind.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
