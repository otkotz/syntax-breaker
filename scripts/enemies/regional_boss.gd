extends MiniBoss

const Hazard = preload("res://scripts/enemies/boss_hazard.gd")
const MAX_HAZARDS := 12
@export var boss_region: String = "burning_grounds"
var final_encounter: bool = false
var second_phase: bool = false
var attack_cooldown: float = 2.0
var encounter_attack_count: int = 0
var hazards: Array[Node2D] = []

func _boss_type() -> String:
	return BOSS_BY_REGION.get(boss_region, DEFAULT_BOSS)

func configure_encounter(depth: int) -> void:
	final_encounter = depth >= 10
	second_phase = false
	attack_cooldown = 2.0
	encounter_attack_count = 0

func _physics_process(delta: float) -> void:
	if not is_alive() or not is_instance_valid(_target):
		return
	_update_slow(delta)
	_move_toward_target()
	if final_encounter and not second_phase and current_hp <= max_hp * 0.5:
		_enter_second_phase()
	attack_cooldown -= delta
	if attack_cooldown <= 0.0 and global_position.distance_to(_target.global_position) <= 210.0:
		_perform_attack()
		attack_cooldown = 4.0

func _perform_attack() -> void:
	encounter_attack_count += 1
	match boss_region:
		"storm_spire":
			for i in 3:
				var beam = _spawn_hazard("beam", _target.global_position, 1.0 + i * 0.65, 0.4)
				if beam:
					beam.angle = encounter_attack_count * PI / 6.0 + i * PI / 3.0
					beam.tick_interval = 100.0
		"toxic_depths":
			for offset in [Vector2.ZERO, Vector2(-110, 40), Vector2(110, -40)]:
				_spawn_hazard("pool", _target.global_position + offset, 1.2, 5.0)
			if get_parent().has_method("spawn_boss_adds"):
				get_parent().spawn_boss_adds(self)
			if second_phase:
				_spawn_pressure_rule()
		_:
			if encounter_attack_count % 2 == 1:
				var wall = _spawn_hazard("wall", _target.global_position + Vector2(60, 0), 1.2, 3.0)
				if wall:
					wall.angle = (encounter_attack_count / 2) * PI / 2.0
			else:
				var wedge = _spawn_hazard("wedge", _target.global_position - Vector2(80, 0), 1.3, 2.0)
				if wedge:
					wedge.radius = 200.0
					wedge.angle = encounter_attack_count * PI / 2.0

func _spawn_hazard(kind: String, origin: Vector2, warning: float, lifetime: float) -> Node2D:
	for i in range(hazards.size() - 1, -1, -1):
		if not is_instance_valid(hazards[i]) or hazards[i].is_queued_for_deletion():
			hazards.remove_at(i)
	if hazards.size() >= MAX_HAZARDS:
		return null
	var hazard := Hazard.new()
	hazard.owner_boss = self
	hazard.target = _target
	hazard.kind = kind
	hazard.warning_duration = warning
	hazard.warning_remaining = warning
	hazard.lifetime = lifetime
	hazard.damage = contact_damage * 0.6
	hazard.color = Color(0.2, 0.7, 1.0) if boss_region == "storm_spire" else (Color(0.55, 0.95, 0.15) if boss_region == "toxic_depths" else Color(1.0, 0.4, 0.08))
	get_parent().add_child(hazard)
	hazard.global_position = origin
	RunTelemetry.record("hazard_warning", {"source": get_enemy_id() + ":" + kind,
		"warning_seconds": warning, "x": origin.x, "y": origin.y})
	hazards.append(hazard)
	return hazard

func _enter_second_phase() -> void:
	second_phase = true
	match boss_region:
		"storm_spire":
			var wedge = _spawn_hazard("rotating_gap", _arena_rect.get_center(), 2.0, 9999.0)
			if wedge:
				wedge.radius = _arena_rect.size.length()
				wedge.angle = (_target.global_position - wedge.global_position).angle()
				wedge.angular_speed = 0.14
			GameBus.boss_phase_changed.emit("PHASE II: SAFE WEDGE ROTATES")
		"toxic_depths":
			_spawn_pressure_rule()
			GameBus.boss_phase_changed.emit("PHASE II: SAFE ISLANDS; KILL ADDS TO CLEAR")
		_:
			var border = _spawn_hazard("border", Vector2.ZERO, 2.0, 9999.0)
			if border:
				border.arena_rect = _arena_rect
			GameBus.boss_phase_changed.emit("PHASE II: ARENA EDGES IGNITE")

func _spawn_pressure_rule() -> void:
	# Replace rather than overlap islands: a reachable safe area always remains.
	for hazard in hazards:
		if is_instance_valid(hazard) and hazard.kind == "pressure":
			hazard.queue_free()
	var pressure = _spawn_hazard("pressure", Vector2.ZERO, 2.0, 9999.0)
	if pressure:
		pressure.arena_rect = _arena_rect
		var offset := Vector2(90 if encounter_attack_count % 2 == 0 else -90, 0)
		var safe_center := (_target.global_position + offset).clamp(_arena_rect.position + Vector2(80, 80), _arena_rect.end - Vector2(80, 80))
		pressure.clear_at(safe_center, 80.0)
		# Regular puddles must not invalidate the promised safe island.
		for hazard in hazards:
			if is_instance_valid(hazard) and hazard != pressure and hazard.is_in_group("boss_poison"):
				hazard.clear_at(safe_center, 80.0)

func _clear_hazards() -> void:
	for hazard in hazards:
		if is_instance_valid(hazard):
			hazard.queue_free()
	hazards.clear()

func _die() -> void:
	_clear_hazards()
	super._die()

func reset() -> void:
	_clear_hazards()
	super.reset()
	final_encounter = false
	second_phase = false
	attack_cooldown = 2.0
	encounter_attack_count = 0

func _exit_tree() -> void:
	_clear_hazards()
