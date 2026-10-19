class_name ArtifactVFX
extends Node2D

const MAX_EFFECTS := 12
const MAX_TRAILS := 4
const MAX_SYNERGIES := 2
const SYNERGY_IDS := [&"chain_conflagration", &"prism_needle_crossfire", &"hourglass_sigil_blood_echo", &"crown_prism_split_transfer"]
static var _pools: Dictionary = {}

var color := Color.WHITE
var radius := 28.0
var reduced_motion := false
var arc_segments := 20
var effect_id := ""
var origin_id := 0
var active := false
var is_synergy := false
var _life_tween: Tween

static func spawn(parent: Node, artifact_id: String, world_position: Vector2, use_reduced_motion: bool = false, generation: int = 0, request_origin_id: int = 0) -> ArtifactVFX:
	if parent == null or generation > 1: return null
	var pool := _pool(parent)
	for candidate: ArtifactVFX in pool.effects:
		if candidate.active and request_origin_id != 0 and candidate.origin_id == request_origin_id and candidate.effect_id == artifact_id:
			candidate.global_position = world_position
			return candidate
	var synergy := StringName(artifact_id) in SYNERGY_IDS
	if _active_effect_count(pool.effects) >= MAX_EFFECTS: return null
	if synergy and _active_synergy_count(pool.effects) >= MAX_SYNERGIES: return null
	var effect: ArtifactVFX = null
	for candidate: ArtifactVFX in pool.effects:
		if is_instance_valid(candidate) and not candidate.active:
			effect = candidate
			break
	if effect == null:
		effect = ArtifactVFX.new()
		parent.add_child(effect)
		pool.effects.append(effect)
	effect._activate(artifact_id, world_position, use_reduced_motion, request_origin_id, synergy)
	return effect

static func spawn_trail(parent: Node, from: Vector2, to: Vector2, trail_color: Color) -> Line2D:
	if parent == null: return null
	var pool := _pool(parent)
	var active_trails := 0
	for trail: Line2D in pool.trails:
		active_trails += int(bool(trail.get_meta("artifact_vfx_active", false)))
	if active_trails >= MAX_TRAILS: return null
	var line: Line2D = null
	for trail: Line2D in pool.trails:
		if is_instance_valid(trail) and not bool(trail.get_meta("artifact_vfx_active", false)):
			line = trail
			break
	if line == null:
		line = Line2D.new()
		line.width = 3.0
		line.z_index = 1
		parent.add_child(line)
		pool.trails.append(line)
	line.clear_points()
	line.add_point(from)
	line.add_point(to)
	line.default_color = trail_color
	line.modulate = Color.WHITE
	line.visible = true
	line.set_meta("artifact_vfx_active", true)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func() -> void:
		if is_instance_valid(line):
			line.visible = false
			line.set_meta("artifact_vfx_active", false)
	)
	return line

static func active_count(parent: Node) -> int:
	if parent == null or not _pools.has(parent.get_instance_id()): return 0
	return _active_effect_count((_pools[parent.get_instance_id()] as Dictionary).effects)

static func release_all(parent: Node) -> void:
	if parent == null or not _pools.has(parent.get_instance_id()): return
	var pool: Dictionary = _pools[parent.get_instance_id()]
	for effect: ArtifactVFX in pool.effects:
		if is_instance_valid(effect): effect._release()
	for trail: Line2D in pool.trails:
		if is_instance_valid(trail):
			trail.visible = false
			trail.set_meta("artifact_vfx_active", false)

static func _pool(parent: Node) -> Dictionary:
	var key := parent.get_instance_id()
	if not _pools.has(key): _pools[key] = {"effects": [] as Array[ArtifactVFX], "trails": [] as Array[Line2D]}
	return _pools[key]

static func _active_effect_count(effects: Array) -> int:
	var count := 0
	for effect: ArtifactVFX in effects:
		count += int(is_instance_valid(effect) and effect.active)
	return count

static func _active_synergy_count(effects: Array) -> int:
	var count := 0
	for effect: ArtifactVFX in effects:
		count += int(is_instance_valid(effect) and effect.active and effect.is_synergy)
	return count

func _activate(id: String, world_position: Vector2, use_reduced_motion: bool, request_origin_id: int, synergy: bool) -> void:
	if _life_tween != null and _life_tween.is_valid(): _life_tween.kill()
	effect_id = id
	origin_id = request_origin_id
	is_synergy = synergy
	active = true
	visible = true
	global_position = world_position
	reduced_motion = use_reduced_motion
	color = {
		"echo": Color(0.25, 0.9, 1.0), "temper": Color(1.0, 0.2, 0.72),
		"fractured_prism": Color(0.72, 0.35, 1.0), "echoing_hourglass": Color(0.25, 0.9, 1.0),
		"bloodwritten_sigil": Color(1.0, 0.15, 0.2), "ashen_needle": Color(1.0, 0.55, 0.15),
		"cinder_crown": Color(1.0, 0.3, 0.05), "chain_conflagration": Color(1.0, 0.65, 0.1),
		"prism_needle_crossfire": Color(0.35, 0.9, 1.0), "hourglass_sigil_blood_echo": Color(1.0, 0.12, 0.38),
		"crown_prism_split_transfer": Color(0.95, 0.32, 0.8),
	}.get(id, Color(1.0, 0.45, 0.1))
	radius = {"prism_needle_crossfire":22.0, "hourglass_sigil_blood_echo":34.0, "crown_prism_split_transfer":46.0}.get(id, 28.0)
	z_index = 1
	modulate = Color.WHITE
	scale = Vector2.ONE
	rotation = 0.0
	queue_redraw()
	_life_tween = create_tween().set_parallel(true)
	if not reduced_motion: _life_tween.tween_property(self, "rotation", 0.18, 0.24)
	_life_tween.tween_property(self, "modulate:a", 0.0, 0.12 if reduced_motion else 0.28)
	_life_tween.chain().tween_callback(_release)

func _release() -> void:
	if _life_tween != null and _life_tween.is_valid(): _life_tween.kill()
	active = false
	visible = false
	origin_id = 0

func _draw() -> void:
	# Short, open glyphs preserve the floor and hostile warning silhouettes.
	draw_arc(Vector2.ZERO, radius, -2.45, -0.68, arc_segments, color, 4.0)
	draw_line(Vector2(-radius * 0.55, 0), Vector2.ZERO, color, 4.0)
	draw_line(Vector2.ZERO, Vector2(radius * 0.45, -radius * 0.5), color, 4.0)
	if is_synergy:
		draw_arc(Vector2.ZERO, radius * 0.62, 0.2, 2.2, 16, color.lightened(0.2), 3.0)
