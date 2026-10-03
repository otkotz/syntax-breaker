extends Node

## Headless runtime check using the game's own SkillInstance and StatCalculator.
## Run with Godot: --headless --path . --scene res://tests/balance_native.tscn

var _variants := 0
var _support_loadouts := 0
var _invalid: Array[String] = []
var _coverage: Dictionary = {}
var _post_mutation_limits := {"cooldown_below_min": 0, "projectile_count_above_max": 0,
	"crit_chance_above_max": 0, "damage_below_min": 0}

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var skills := _load_resources("res://resources/skills/")
	var supports := _load_resources("res://resources/supports/")
	var passives := _load_resources("res://resources/passives/")
	var mutations: Array = MutationData.POOL
	for entry: Dictionary in [
		{"path": "res://resources/skills/", "loaded": skills.size()},
		{"path": "res://resources/supports/", "loaded": supports.size()},
		{"path": "res://resources/passives/", "loaded": passives.size()},
	]:
		var expected := ResourceListing.get_resource_files(entry["path"]).size()
		if entry["loaded"] != expected:
			_invalid.append("%s: loaded %d of %d resources" % [entry["path"], entry["loaded"], expected])
	if not _invalid.is_empty():
		print(JSON.stringify({"invalid": _invalid}))
		get_tree().quit(1)
		return
	RunManager.owned_passives.clear()
	RunManager.owned_supports.clear()
	_check_regressions(skills, supports, passives)

	for skill_res: Resource in skills:
		if not skill_res is SkillResource:
			continue
		var skill := skill_res as SkillResource
		var compatible: Array[SupportResource] = []
		for support_res: Resource in supports:
			if support_res is SupportResource and TagMatcher.can_link_support(skill, support_res):
				compatible.append(support_res)
		var support_sets := _support_sets(compatible, skill.max_supports)
		for set_variant: Variant in support_sets:
			var chosen: Array[SupportResource] = set_variant
			var instance := SkillInstance.new(skill)
			var legal := true
			for support: SupportResource in chosen:
				if not instance.link_support(support):
					legal = false
					break
			if not legal:
				continue
			_support_loadouts += 1
			for passive_idx in passives.size() + 1:
				RunManager.owned_passives.clear()
				if passive_idx < passives.size():
					var passive := passives[passive_idx] as PassiveResource
					if not passive:
						continue
					if not _passive_applies(skill, chosen, passive):
						continue
					RunManager.owned_passives.append(passive)
					_coverage["passive:" + passive.id] = true
				for mutation_idx in mutations.size() + 1:
					instance.mutations.clear()
					if mutation_idx < mutations.size():
						var mutation: Dictionary = mutations[mutation_idx]
						if not MutationData.can_apply(mutation, instance):
							continue
						instance.mutations.append(mutation)
						_coverage["mutation:" + mutation["id"]] = true
					instance.recompute(RunManager.owned_passives)
					_validate(skill, chosen, instance)
					_variants += 1
					if _invalid.size() >= 10:
						break
				if _invalid.size() >= 10:
					break
			if _invalid.size() >= 10:
				break
		if _invalid.size() >= 10:
			break
		print("checked %s: %d support loadouts" % [skill.id, support_sets.size()])

	var missing_passives: Array[String] = []
	for passive_res: Resource in passives:
		var passive := passive_res as PassiveResource
		if passive.id != "arcane_tempo" and not _coverage.has("passive:" + passive.id):
			missing_passives.append(passive.id)
	var missing_mutations: Array[String] = []
	for mutation: Dictionary in mutations:
		if not _coverage.has("mutation:" + mutation["id"]):
			missing_mutations.append(mutation["id"])
	if not missing_passives.is_empty() or not missing_mutations.is_empty():
		_invalid.append("Missing coverage: passives=%s mutations=%s" % [missing_passives, missing_mutations])
	var result := {
		"variants": _variants,
		"support_loadouts": _support_loadouts,
		"covered_passives_and_mutations": _coverage.size(),
		"post_mutation_limits": _post_mutation_limits,
		"invalid": _invalid,
	}
	print(JSON.stringify(result))
	get_tree().quit(1 if not _invalid.is_empty() else 0)

func _load_resources(dir_path: String) -> Array[Resource]:
	var result: Array[Resource] = []
	for file_name in ResourceListing.get_resource_files(dir_path):
		var res := load(dir_path + file_name)
		if res:
			result.append(res)
	return result

func _check_regressions(skills: Array[Resource], supports: Array[Resource],
		passives: Array[Resource]) -> void:
	var fireball: SkillResource
	var frost_nova: SkillResource
	var chain: SupportResource
	var fire_mastery: PassiveResource
	for resource: SkillResource in skills:
		if resource.id == "fireball": fireball = resource
		if resource.id == "frost_nova": frost_nova = resource
	for resource: SupportResource in supports:
		if resource.id == "chain": chain = resource
	for resource: PassiveResource in passives:
		if resource.id == "fire_mastery": fire_mastery = resource
	if not fireball or not frost_nova or not chain or not fire_mastery:
		_invalid.append("Missing Fire Mastery regression resources")
		return
	var fire_instance := SkillInstance.new(fireball)
	var cold_instance := SkillInstance.new(frost_nova)
	var fire_skills: Array[SkillInstance] = [fire_instance]
	var cold_skills: Array[SkillInstance] = [cold_instance]
	if not BuildOptions.can_offer_passive(fire_mastery, fire_skills):
		_invalid.append("Fire Mastery not offered for Fireball")
	if BuildOptions.can_offer_passive(fire_mastery, cold_skills):
		_invalid.append("Fire Mastery offered for Frost Nova")
	fire_instance.linked_supports = [chain]
	RunManager.owned_passives.append(fire_mastery)
	fire_instance.recompute(RunManager.owned_passives)
	if not is_equal_approx(fire_instance.computed_stats["damage"], 10.0):
		_invalid.append("Fireball + Chain + Fire Mastery has wrong damage")
	var burning := load("res://resources/regions/burning_grounds.tres") as RegionResource
	var lightning := load("res://resources/skills/lightning_bolt.tres") as SkillResource
	if RewardRoller.get_region_affinity(
		{"type": "skill", "id": fireball.id, "resource": fireball}, burning) != 1:
		_invalid.append("Burning Grounds does not favor fire rewards")
	if RewardRoller.get_region_affinity(
		{"type": "skill", "id": lightning.id, "resource": lightning}, burning) != 0:
		_invalid.append("Burning Grounds incorrectly favors lightning rewards")
	if RewardRoller.get_region_affinity(
		{"type": "mutation", "id": "heavy_payload"}, burning) != 1:
		_invalid.append("Burning Grounds does not favor its mutation identity")
	RunManager.owned_passives.clear()

func _support_sets(items: Array[SupportResource], max_size: int) -> Array:
	var result: Array = []
	var empty: Array[SupportResource] = []
	result.append(empty)
	for size in range(1, mini(max_size, items.size()) + 1):
		_collect_sets(items, size, 0, [], result)
	return result

func _collect_sets(items: Array[SupportResource], remaining: int, start: int,
		chosen: Array[SupportResource], result: Array) -> void:
	if remaining == 0:
		result.append(chosen.duplicate())
		return
	for i in range(start, items.size() - remaining + 1):
		chosen.append(items[i])
		_collect_sets(items, remaining - 1, i + 1, chosen, result)
		chosen.pop_back()

func _passive_applies(skill: SkillResource, chosen: Array[SupportResource], passive: PassiveResource) -> bool:
	if passive.id == "arcane_tempo":
		return false  # Requires two equipped skills; covered by the static audit.
	if passive.id.ends_with("_mastery") and passive.affected_tags.is_empty():
		for support: SupportResource in chosen:
			if support.id == passive.id.trim_suffix("_mastery"):
				return true
		return false
	return passive.is_global() or skill.has_any_tag(passive.affected_tags)

func _validate(skill: SkillResource, chosen: Array[SupportResource], instance: SkillInstance) -> void:
	var stats := instance.computed_stats
	for key in ["damage", "cooldown", "speed", "range", "crit_chance", "projectile_count"]:
		if not stats.has(key) or not is_finite(float(stats[key])):
			_invalid.append("%s %s: invalid %s" % [skill.id, _support_names(chosen), key])
			return
	if stats["damage"] <= 0.0 or stats["cooldown"] <= 0.0:
		_invalid.append("%s %s: nonpositive damage/cooldown" % [skill.id, _support_names(chosen)])
	elif chosen.size() > skill.max_supports:
		_invalid.append("%s: too many supports" % skill.id)
	if stats["cooldown"] < StatCalculator.STAT_MINS["cooldown"] - 0.00001:
		_post_mutation_limits["cooldown_below_min"] += 1
	if stats["projectile_count"] > StatCalculator.STAT_MAXS["projectile_count"]:
		_post_mutation_limits["projectile_count_above_max"] += 1
	if stats["crit_chance"] > StatCalculator.STAT_MAXS["crit_chance"] + 0.00001:
		_post_mutation_limits["crit_chance_above_max"] += 1
	if stats["damage"] < StatCalculator.STAT_MINS["damage"] - 0.00001:
		_post_mutation_limits["damage_below_min"] += 1

func _support_names(chosen: Array[SupportResource]) -> String:
	var ids: PackedStringArray = []
	for support: SupportResource in chosen:
		ids.append(support.id)
	return ",".join(ids)
