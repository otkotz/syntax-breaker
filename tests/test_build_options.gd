extends GutTest

var _old_supports: Array
var _old_passives: Array
var _old_unlocks: Dictionary
var _old_slots: int

func before_each() -> void:
	_old_supports = RunManager.owned_supports.duplicate()
	_old_passives = RunManager.owned_passives.duplicate()
	_old_unlocks = MetaProgression.unlocked_items.duplicate(true)
	_old_slots = RunManager.skill_slots_unlocked
	RunManager.owned_supports = []
	RunManager.owned_passives = []
	RunManager.skill_slots_unlocked = 2
	MetaProgression.unlocked_items = {
		"skills": ["fireball", "lightning_bolt"],
		"supports": ["pierce", "faster_casting"],
		"passives": ["thick_skin", "heavy_hitter", "pierce_mastery"],
	}

func after_each() -> void:
	RunManager.owned_supports = _old_supports
	RunManager.owned_passives = _old_passives
	RunManager.skill_slots_unlocked = _old_slots
	MetaProgression.unlocked_items = _old_unlocks

func _fireball() -> SkillInstance:
	return SkillInstance.new(load("res://resources/skills/fireball.tres") as SkillResource)

func test_support_requires_compatible_skill_and_no_unlinked_copy() -> void:
	var si := _fireball()
	var skills: Array[SkillInstance] = []
	skills.append(si)
	var compatible := load("res://resources/supports/pierce.tres") as SupportResource
	var incompatible := load("res://resources/supports/increased_area.tres") as SupportResource
	assert_true(BuildOptions.can_offer_support(compatible, skills))
	assert_false(BuildOptions.can_offer_support(incompatible, skills))
	RunManager.owned_supports.append(compatible)
	assert_false(BuildOptions.can_offer_support(compatible, skills))
	si.link_support(compatible)
	assert_false(BuildOptions.can_offer_support(compatible, skills))

func test_mastery_requires_linked_support() -> void:
	var si := _fireball()
	var skills: Array[SkillInstance] = []
	skills.append(si)
	var mastery := load("res://resources/passives/pierce_mastery.tres") as PassiveResource
	assert_false(BuildOptions.can_offer_passive(mastery, skills))
	var support := load("res://resources/supports/pierce.tres") as SupportResource
	RunManager.owned_supports.append(support)
	assert_false(BuildOptions.can_offer_passive(mastery, skills))
	si.link_support(support)
	assert_true(BuildOptions.can_offer_passive(mastery, skills))

func test_elemental_mastery_is_not_support_mastery() -> void:
	var fire_skill: Array[SkillInstance] = []
	fire_skill.append(_fireball())
	var cold_skill: Array[SkillInstance] = []
	cold_skill.append(SkillInstance.new(load("res://resources/skills/frost_nova.tres") as SkillResource))
	var mastery := load("res://resources/passives/fire_mastery.tres") as PassiveResource
	assert_true(BuildOptions.can_offer_passive(mastery, fire_skill))
	assert_false(BuildOptions.can_offer_passive(mastery, cold_skill))

func test_full_support_slots_can_still_offer_replacements() -> void:
	var skill := SkillResource.new()
	skill.tags = ["projectile"]
	skill.max_supports = 1
	var si := SkillInstance.new(skill)
	var current := load("res://resources/supports/pierce.tres") as SupportResource
	var replacement := load("res://resources/supports/faster_casting.tres") as SupportResource
	RunManager.owned_supports.append(current)
	si.link_support(current)
	var skills: Array[SkillInstance] = []
	skills.append(si)
	assert_true(BuildOptions.can_offer_support(replacement, skills))

func test_reward_screen_has_usable_build_option() -> void:
	var skills: Array[SkillInstance] = []
	skills.append(_fireball())
	for _i in 20:
		var rewards := RewardRoller.roll(skills, false)
		assert_eq(rewards.size(), 3)
		assert_eq(rewards[0]["type"], "support")
		for reward: Dictionary in rewards:
			assert_ne(reward.get("id", ""), "pierce_mastery")

func test_mutations_only_target_skills_that_use_them() -> void:
	var projectile := _fireball().base
	var aoe := load("res://resources/skills/frost_nova.tres") as SkillResource
	assert_true(MutationData.can_apply(MutationData.POOL[0], projectile))
	assert_false(MutationData.can_apply(MutationData.POOL[0], aoe))
	assert_false(MutationData.can_apply(MutationData.POOL[4], aoe))

func test_mine_blocks_projectile_only_mutations_and_conflicting_supports() -> void:
	var si := _fireball()
	var mine := load("res://resources/supports/mine.tres") as SupportResource
	var echo := load("res://resources/supports/spell_echo.tres") as SupportResource
	assert_true(si.link_support(mine))
	assert_false(MutationData.can_apply(MutationData.POOL[0], si))
	assert_false(MutationData.can_apply(MutationData.POOL[4], si))
	var skills: Array[SkillInstance] = [si]
	assert_false(BuildOptions.can_offer_support(echo, skills))

func test_region_affinity_changes_frequency_not_power() -> void:
	var burning := load("res://resources/regions/burning_grounds.tres") as RegionResource
	var fireball := load("res://resources/skills/fireball.tres") as SkillResource
	var lightning := load("res://resources/skills/lightning_bolt.tres") as SkillResource
	assert_eq(RewardRoller.get_region_affinity(
		{"type": "skill", "id": fireball.id, "resource": fireball}, burning), 1)
	assert_eq(RewardRoller.get_region_affinity(
		{"type": "skill", "id": lightning.id, "resource": lightning}, burning), 0)
	assert_eq(RewardRoller.get_region_affinity(
		{"type": "mutation", "id": "heavy_payload"}, burning), 1)
	assert_eq(fireball.base_damage, 10.0, "Regional weighting must not alter item stats")

func test_tradeoff_mutations_have_restricted_targets() -> void:
	var concentrated: Dictionary = MutationData.POOL[10]
	var close_quarters: Dictionary = MutationData.POOL[11]
	var fireball := _fireball()
	var frost := SkillInstance.new(load("res://resources/skills/frost_nova.tres") as SkillResource)
	assert_false(MutationData.can_apply(concentrated, fireball))
	assert_true(MutationData.can_apply(concentrated, frost))
	assert_true(MutationData.can_apply(close_quarters, fireball))
	assert_false(MutationData.can_apply(close_quarters, frost))
