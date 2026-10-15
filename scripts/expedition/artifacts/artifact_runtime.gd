class_name ArtifactRuntime
extends RefCounted

signal artifact_triggered(artifact_id: String, world_position: Vector2)

var behaviors: Array[ArtifactBehavior] = []
var hooks: ArtifactCombatHooks
var registry: ArtifactRegistry
var active := false
var _skills: Array = []
var _arena: Node

func _init(custom_registry: ArtifactRegistry = null, custom_hooks: ArtifactCombatHooks = null) -> void:
	registry = custom_registry if custom_registry != null else ArtifactRegistry.with_defaults()
	hooks = custom_hooks if custom_hooks != null else ArtifactCombatHooks.new()

func setup(ids: Array[String], skills: Array, arena: Node) -> void:
	if active:
		teardown()
	active = true
	hooks.active = true
	_skills = skills
	_arena = arena
	var normalized := ArtifactLoadout.normalize(ArtifactCatalog.all_ids(), ids)
	for artifact_id in normalized:
		if artifact_id.is_empty(): continue
		var artifact := ArtifactCatalog.get_artifact(artifact_id)
		if artifact != null:
			_add_behavior(artifact.behavior_key, artifact.id, artifact.behavior_parameters)
	var tiers := ArtifactLoadout.active_set_tiers(normalized)
	for set_id in tiers:
		var set_resource := ArtifactCatalog.get_set(set_id)
		if set_resource == null: continue
		for tier in [2, 3]:
			if int(tiers[set_id]) >= tier:
				_add_behavior(str(set_resource.tier_behavior_keys.get(tier, "")), "%s_%d" % [set_id, tier], set_resource.behavior_parameters)
	if not hooks.combat_event.is_connected(_on_combat_event):
		hooks.combat_event.connect(_on_combat_event)
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

func _on_combat_event(event_name: StringName, context: Dictionary) -> void:
	if not active: return
	for behavior in behaviors:
		behavior.handle(event_name, context)

func trigger(artifact_id: String, world_position: Vector2 = Vector2.ZERO) -> void:
	if active: artifact_triggered.emit(artifact_id, world_position)

func teardown() -> void:
	if not active: return
	active = false
	if hooks.combat_event.is_connected(_on_combat_event):
		hooks.combat_event.disconnect(_on_combat_event)
	hooks.deactivate()
	for behavior in behaviors:
		behavior.teardown()
		behavior.runtime = null
	_skills.clear()
	_arena = null
