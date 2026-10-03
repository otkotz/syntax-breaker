class_name SkillInstance
extends RefCounted

var base: SkillResource
var linked_supports: Array[SupportResource] = []
var computed_stats: Dictionary = {}
var behaviors: Array[BehaviorBase] = []
var mutations: Array[Dictionary] = []
var rarity_tier: String = ""
var stage_overrides: Array[Dictionary] = []

func _init(skill_resource: SkillResource) -> void:
	base = skill_resource
	rarity_tier = skill_resource.rarity  # intrinsic rarity is the floor until a tier is rolled
	recompute()

# Sets the rolled rarity tier (which scales base damage) and recomputes stats.
func set_rarity_tier(tier: String, passives: Array = []) -> void:
	rarity_tier = tier
	recompute(passives)

func link_support(support: SupportResource) -> bool:
	if not support_rejection_reason(support).is_empty():
		return false
	linked_supports.append(support)
	recompute()
	return true

func support_rejection_reason(support: SupportResource, replacing: SupportResource = null) -> String:
	if not TagMatcher.can_link_support(base, support):
		return "Incompatible skill tags"
	if linked_supports.size() >= base.max_supports and replacing == null:
		return "All sockets are full"
	for linked: SupportResource in linked_supports:
		if linked != replacing and not support.id.is_empty() and linked.id == support.id:
			return "Already linked"
	if not can_combine_support(support, replacing):
		return "Conflicting casting mode or projectile behavior"
	return ""

func can_combine_support(support: SupportResource, replacing: SupportResource = null) -> bool:
	# These supports change who casts the skill. Stacking them previously made the
	# later effects silently disappear because SkillCaster can only use one mode.
	const CAST_MODE_SUPPORTS := ["mine", "totem"]
	const DEFERRED_CAST_SUPPORTS := ["mine", "totem", "spell_echo"]
	const MINE_INCOMPATIBLE_SUPPORTS := [
		"chain", "pierce", "returning", "ricochet_amplifier", "shotgun", "split",
	]
	for linked: SupportResource in linked_supports:
		if linked == replacing:
			continue
		if support.id in CAST_MODE_SUPPORTS and linked.id in CAST_MODE_SUPPORTS:
			return false
		if support.id in DEFERRED_CAST_SUPPORTS and linked.id in DEFERRED_CAST_SUPPORTS:
			return false
		if (support.id == "mine" and linked.id in MINE_INCOMPATIBLE_SUPPORTS) or (
			linked.id == "mine" and support.id in MINE_INCOMPATIBLE_SUPPORTS
		):
			return false
	return true

func unlink_support(support: SupportResource) -> void:
	linked_supports.erase(support)
	recompute()

func clear_supports() -> void:
	linked_supports.clear()
	recompute()

func recompute(passives: Array = []) -> void:
	computed_stats = StatCalculator.compute(base, linked_supports, passives)
	if not rarity_tier.is_empty():
		computed_stats["damage"] *= RarityTiers.damage_mult(rarity_tier)
	_apply_mutations()
	for override_stats: Dictionary in stage_overrides:
		for key: String in override_stats:
			if key.ends_with("_mult") and computed_stats.has(key.trim_suffix("_mult")):
				computed_stats[key.trim_suffix("_mult")] *= override_stats[key]
			elif computed_stats.has(key):
				computed_stats[key] += override_stats[key]
	# Mutations are applied after StatCalculator, so enforce every final bound.
	StatCalculator.clamp_final_stats(computed_stats)
	_rebuild_behaviors()

func add_mutation(mutation: Dictionary) -> void:
	mutations.append(mutation)
	recompute(RunManager.owned_passives)

func has_mutation(special_key: String) -> bool:
	for m: Dictionary in mutations:
		if m.get("special", "") == special_key:
			return true
	return false

func get_all_tags() -> Array[String]:
	var tags: Array[String] = base.tags.duplicate()
	for support in linked_supports:
		for tag in support.added_tags:
			if not tags.has(tag):
				tags.append(tag)
	return tags

func _apply_mutations() -> void:
	for mutation: Dictionary in mutations:
		var stats: Dictionary = mutation.get("stats", {})
		for key: String in stats:
			if key.ends_with("_mult"):
				var base_key: String = key.trim_suffix("_mult")
				if computed_stats.has(base_key):
					computed_stats[base_key] *= stats[key]
			elif key.ends_with("_add"):
				var base_key: String = key.trim_suffix("_add")
				if computed_stats.has(base_key):
					computed_stats[base_key] += stats[key]
			elif computed_stats.has(key):
				computed_stats[key] += stats[key]

func _rebuild_behaviors() -> void:
	behaviors.clear()
	for support in linked_supports:
		if not support.behavior_key.is_empty():
			var behavior: BehaviorBase = BehaviorRegistry.get_behavior(support.behavior_key)
			if behavior:
				behavior.support_id = support.id
				behaviors.append(behavior)

func notify_spawn(projectile: Node2D) -> void:
	for behavior in behaviors:
		behavior.modify_spawn(self, projectile)

func notify_hit(target: Node2D, projectile: Node2D) -> void:
	for behavior in behaviors:
		behavior.on_hit(self, target, projectile)

func notify_crit(target: Node2D, projectile: Node2D) -> void:
	EngineTracker.on_crit()
	for behavior in behaviors:
		behavior.on_crit(self, target, projectile)

func notify_status_apply(target: Node2D, status_type: String) -> void:
	for behavior in behaviors:
		behavior.on_status_apply(self, target, status_type)

var trigger_on_death_recast: Callable = Callable()

func notify_kill(target: Node2D, projectile: Node2D) -> void:
	for behavior in behaviors:
		behavior.on_kill(self, target, projectile)
	_process_mutation_kills(target)
	if PassiveBehaviors.has_trigger_on_death() and trigger_on_death_recast.is_valid():
		trigger_on_death_recast.call(self, target)

func _process_mutation_kills(target: Node2D) -> void:
	if has_mutation("vampiric"):
		var players := target.get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0].has_method("heal"):
			players[0].heal(2.0)
	if has_mutation("explosive"):
		var damage: float = computed_stats.get("damage", 10.0) * 0.3
		var enemies := Targeting.find_enemies_in_range(target.global_position, 80.0, 10)
		for enemy: Node2D in enemies:
			if enemy != target and enemy.has_method("take_damage"):
				enemy.take_damage(damage, false, base, "proc")
