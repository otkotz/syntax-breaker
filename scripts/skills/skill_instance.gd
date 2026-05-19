class_name SkillInstance
extends RefCounted

var base: SkillResource
var linked_supports: Array[SupportResource] = []
var computed_stats: Dictionary = {}
var behaviors: Array[BehaviorBase] = []

func _init(skill_resource: SkillResource) -> void:
	base = skill_resource
	recompute()

func link_support(support: SupportResource) -> bool:
	if linked_supports.size() >= base.max_supports:
		return false
	if not TagMatcher.can_link_support(base, support):
		return false
	linked_supports.append(support)
	recompute()
	return true

func unlink_support(support: SupportResource) -> void:
	linked_supports.erase(support)
	recompute()

func clear_supports() -> void:
	linked_supports.clear()
	recompute()

func recompute(passives: Array = []) -> void:
	computed_stats = StatCalculator.compute(base, linked_supports, passives)
	_rebuild_behaviors()

func get_all_tags() -> Array[String]:
	var tags: Array[String] = base.tags.duplicate()
	for support in linked_supports:
		for tag in support.added_tags:
			if not tags.has(tag):
				tags.append(tag)
	return tags

func _rebuild_behaviors() -> void:
	behaviors.clear()
	for support in linked_supports:
		if not support.behavior_key.is_empty():
			var behavior: BehaviorBase = BehaviorRegistry.get_behavior(support.behavior_key)
			if behavior:
				behaviors.append(behavior)

func notify_spawn(projectile: Node2D) -> void:
	for behavior in behaviors:
		behavior.modify_spawn(self, projectile)

func notify_hit(target: Node2D, projectile: Node2D) -> void:
	for behavior in behaviors:
		behavior.on_hit(self, target, projectile)

func notify_kill(target: Node2D, projectile: Node2D) -> void:
	for behavior in behaviors:
		behavior.on_kill(self, target, projectile)
