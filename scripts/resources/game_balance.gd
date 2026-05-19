class_name GameBalance
extends Resource

@export_group("Player")
@export var player_move_speed: float = 250.0
@export var player_max_hp: float = 100.0
@export var iframe_duration: float = 0.5

@export_group("Enemies")
@export var aggro_range: float = 200.0
@export var enemy_move_speed: float = 80.0
@export var enemy_hp: float = 20.0
@export var contact_damage: float = 10.0
@export var gold_value: int = 1
@export var wander_speed_mult: float = 0.3

@export_group("Spawning")
@export var enemies_per_stage: int = 40
@export var group_size_min: int = 4
@export var group_size_max: int = 6
@export var group_spread: float = 40.0
@export var spawn_margin: float = 50.0
@export var min_spawn_dist_from_player: float = 200.0

@export_group("Stage Scaling")
@export var enemy_hp_per_stage: float = 5.0
@export var enemies_per_stage_growth: int = 5
@export var boss_stage_interval: int = 3

@export_group("Camera")
@export var screen_shake_on_hit: float = 3.0
@export var screen_shake_on_kill: float = 1.5
@export var screen_shake_duration: float = 0.15
@export var hit_stop_duration: float = 0.03
