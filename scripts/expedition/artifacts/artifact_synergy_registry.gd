class_name ArtifactSynergyRegistry
extends RefCounted

const PAIRS := {
	&"prism_needle_crossfire": ["fractured_prism", "ashen_needle"],
	&"hourglass_sigil_blood_echo": ["echoing_hourglass", "bloodwritten_sigil"],
	&"crown_prism_split_transfer": ["cinder_crown", "fractured_prism"],
}

class SynergyBehavior extends ArtifactBehavior:
	var synergy_id: StringName
	func handle(event: StringName, context: Dictionary) -> void:
		match synergy_id:
			&"prism_needle_crossfire": _crossfire(event, context)
			&"hourglass_sigil_blood_echo": _blood_echo(event, context)
			&"crown_prism_split_transfer": _split_transfer(event, context)
	func _crossfire(event: StringName, context: Dictionary) -> void:
		var flags: Array = context.get("origin_flags", [])
		if event != &"projectile_hit" or int(context.get("pre_hit_burn_count", 0)) <= 0 or int(context.get("generation", 0)) > 0 or flags.has("prism_needle_crossfire"): return
		var spawn: Callable = context.get("spawn_fragment", Callable())
		if not spawn.is_valid(): return
		spawn.call({"damage": float(context.get("damage", 0.0)) * 0.35, "angle_offset": 0.0,
			"origin_flags": ["prism_needle_crossfire", "secondary_artifact_projectile"],
			"generation": 1, "world_position": context.get("world_position", Vector2.ZERO)})
		runtime.trigger_synergy(synergy_id, context.get("world_position", Vector2.ZERO))
	func _blood_echo(event: StringName, context: Dictionary) -> void:
		var flags: Array = context.get("origin_flags", [])
		if event != &"artifact_cast_empowered" or int(context.get("generation", 0)) > 0 or flags.has("hourglass_sigil_blood_echo"): return
		var spawn: Callable = context.get("spawn_echo", Callable())
		if not spawn.is_valid(): return
		spawn.call()
		runtime.trigger_synergy(synergy_id, context.get("world_position", Vector2.ZERO))
	func _split_transfer(event: StringName, context: Dictionary) -> void:
		if event != &"enemy_killed" or int(context.get("generation", 0)) > 0: return
		var dead: Node2D = context.get("target")
		var burns: Array = context.get("burns", [])
		if dead == null or burns.is_empty(): return
		burns.sort_custom(func(a: Dictionary, b: Dictionary): return float(a.damage) > float(b.damage))
		var valid_index := 0
		for enemy: Node2D in Targeting.find_enemies_in_range(dead.global_position, 400.0, 8):
			if enemy == dead or not enemy.has_method("apply_dot_stack"): continue
			valid_index += 1
			if valid_index != 2: continue
			var burn: Dictionary = burns[0]
			enemy.apply_dot_stack("burn", float(burn.damage) * 0.5, burn.remaining, burn.interval, burn.source,
				"split-transfer-%s" % context.get("event_id", 0), runtime.burn_stack_limit(), 1)
			runtime.trigger_synergy(synergy_id, enemy.global_position)
			return

static func get_active_pairs(ids: Array[String]) -> Array[StringName]:
	var unique := ids.duplicate()
	var result: Array[StringName] = []
	for pair_id: StringName in PAIRS:
		var required: Array = PAIRS[pair_id]
		if unique.has(str(required[0])) and unique.has(str(required[1])): result.append(pair_id)
	return result

static func is_known(id: String) -> bool:
	return PAIRS.has(StringName(id))

static func create_behavior(id: StringName) -> ArtifactBehavior:
	if not PAIRS.has(id): return null
	var behavior := SynergyBehavior.new()
	behavior.synergy_id = id
	return behavior
