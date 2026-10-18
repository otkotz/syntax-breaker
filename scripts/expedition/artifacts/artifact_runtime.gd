class_name ArtifactRuntime
extends RefCounted

const TEMPER_DATA := preload("res://scripts/expedition/artifact_temper_data.gd")

signal artifact_triggered(artifact_id: String, world_position: Vector2)

var behaviors: Array[ArtifactBehavior] = []
var hooks: ArtifactCombatHooks
var registry: ArtifactRegistry
var active := false
var active_loadout_ids: Array[String] = []
var active_tempered_artifact_ids: Array[String] = []
var _skills: Array = []
var _arena: Node

func _init(custom_registry: ArtifactRegistry = null, custom_hooks: ArtifactCombatHooks = null) -> void:
	registry = custom_registry if custom_registry != null else ArtifactRegistry.with_defaults()
	hooks = custom_hooks if custom_hooks != null else ArtifactCombatHooks.new()

func setup(ids: Array[String], skills: Array, arena: Node, tempered_ids: Array[String] = []) -> void:
	var normalized := ArtifactLoadout.normalize(ArtifactCatalog.all_ids(), ids)
	var normalized_tempered: Array[String] = []
	for artifact_id in tempered_ids:
		if normalized.has(artifact_id) and not normalized_tempered.has(artifact_id): normalized_tempered.append(artifact_id)
	if active and normalized == active_loadout_ids and normalized_tempered == active_tempered_artifact_ids:
		return
	if active:
		teardown()
	behaviors.clear()
	active = true
	hooks.active = true
	_skills = skills
	_arena = arena
	active_loadout_ids = normalized.duplicate()
	active_tempered_artifact_ids = normalized_tempered
	hooks.active_artifact_ids = normalized.duplicate()
	for artifact_id in normalized:
		if artifact_id.is_empty(): continue
		var artifact := ArtifactCatalog.get_artifact(artifact_id)
		if artifact != null:
			var params := artifact.behavior_parameters.duplicate(true)
			if active_tempered_artifact_ids.has(artifact_id): params = _temper_parameters(artifact_id, params)
			_add_behavior(artifact.behavior_key, artifact.id, params)
	var tiers := ArtifactLoadout.active_set_tiers(normalized)
	for set_id in tiers:
		var set_resource := ArtifactCatalog.get_set(set_id)
		if set_resource == null: continue
		for tier in [2, 3]:
			if int(tiers[set_id]) >= tier:
				_add_behavior(str(set_resource.tier_behavior_keys.get(tier, "")), "%s_%d" % [set_id, tier], set_resource.behavior_parameters)
	hooks.burn_stack_limit = burn_stack_limit()
	if not hooks.combat_event.is_connected(_on_combat_event):
		hooks.combat_event.connect(_on_combat_event)
	if not GameBus.enemy_killed.is_connected(_on_enemy_killed):
		GameBus.enemy_killed.connect(_on_enemy_killed)
	for skill in _skills:
		for behavior in behaviors:
			behavior.before_skill_recompute(skill)
		if skill != null and skill.has_method("recompute"):
			skill.recompute()

func _add_behavior(key: String, source_id: String, params: Dictionary) -> void:
	if key.is_empty(): return
	var behavior := registry.create(StringName(key))
	if behavior == null: return
	behavior.runtime = self
	behavior.artifact_id = source_id
	behavior.parameters = params.duplicate(true)
	behaviors.append(behavior)
	behavior.setup({"skills": _skills, "arena": _arena, "hooks": hooks})

func _temper_parameters(artifact_id: String, params: Dictionary) -> Dictionary:
	var temper := TEMPER_DATA.get_for_artifact(artifact_id)
	for key: String in temper.get("parameter_multipliers", {}):
		if params.has(key) and typeof(params[key]) in [TYPE_INT, TYPE_FLOAT]:
			var value := float(params[key]) * float(temper.parameter_multipliers[key])
			params[key] = maxi(1, int(round(value))) if params[key] is int else value
	params["tempered"] = true
	params["allow_secondary_triggers"] = false
	return params

func _on_combat_event(event_name: StringName, context: Dictionary) -> void:
	if not active: return
	for behavior in behaviors:
		behavior.handle(event_name, context)

func _on_enemy_killed(enemy: Node2D, killer_skill: Resource) -> void:
	if not active: return
	var generation := int(enemy.get_meta("artifact_kill_generation", 0)) if is_instance_valid(enemy) else 0
	var inherited_burns: Array = enemy.get_meta("artifact_kill_burns", []) if is_instance_valid(enemy) else []
	if inherited_burns.is_empty() and is_instance_valid(enemy) and enemy.has_method("get_dot_stacks"):
		inherited_burns = enemy.get_dot_stacks("burn")
		for burn: Dictionary in inherited_burns:
			generation = maxi(generation, int(burn.get("artifact_generation", 0)))
	hooks.emit_event(&"enemy_killed", {"target": enemy, "skill_resource": killer_skill,
		"world_position": enemy.global_position if is_instance_valid(enemy) else Vector2.ZERO,
		"generation": generation, "burns": inherited_burns})

func burn_stack_limit() -> int:
	for behavior: ArtifactBehavior in behaviors:
		if behavior.artifact_id == "covenant_of_embers_2":
			return int(behavior.parameters.get("stack_limit", 5))
	return 1

func trigger(artifact_id: String, world_position: Vector2 = Vector2.ZERO) -> void:
	if active: artifact_triggered.emit(artifact_id, world_position)

func teardown() -> void:
	if not active: return
	active = false
	if hooks.combat_event.is_connected(_on_combat_event):
		hooks.combat_event.disconnect(_on_combat_event)
	if GameBus.enemy_killed.is_connected(_on_enemy_killed):
		GameBus.enemy_killed.disconnect(_on_enemy_killed)
	hooks.deactivate()
	hooks.active_artifact_ids.clear()
	active_loadout_ids.clear()
	active_tempered_artifact_ids.clear()
	for behavior in behaviors:
		behavior.teardown()
		behavior.runtime = null
	_skills.clear()
	_arena = null
