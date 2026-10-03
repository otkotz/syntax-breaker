extends GutTest

var _fireball: SkillResource
var _chain: SupportResource
var _beam_only: SupportResource

func before_each() -> void:
	_fireball = SkillResource.new()
	_fireball.id = "fireball"
	_fireball.tags = ["projectile", "fire"]
	_fireball.base_damage = 10.0
	_fireball.base_cooldown = 0.8
	_fireball.base_speed = 300.0
	_fireball.base_range = 400.0
	_fireball.base_pierce = 0
	_fireball.max_supports = 2

	_chain = SupportResource.new()
	_chain.id = "chain"
	_chain.required_tags = ["projectile"]
	_chain.stat_modifiers = {"damage_mult": 0.8, "chain_count": 3}
	_chain.added_tags = ["chain"]
	_chain.behavior_key = ""

	_beam_only = SupportResource.new()
	_beam_only.id = "beam_focus"
	_beam_only.required_tags = ["beam"]

func test_link_matching_support() -> void:
	var si := SkillInstance.new(_fireball)
	assert_true(si.link_support(_chain))
	assert_eq(si.linked_supports.size(), 1)

func test_reject_non_matching_support() -> void:
	var si := SkillInstance.new(_fireball)
	assert_false(si.link_support(_beam_only))
	assert_eq(si.linked_supports.size(), 0)

func test_max_supports_enforced() -> void:
	var si := SkillInstance.new(_fireball)
	var s1 := SupportResource.new()
	s1.required_tags = []
	var s2 := SupportResource.new()
	s2.required_tags = []
	var s3 := SupportResource.new()
	s3.required_tags = []
	assert_true(si.link_support(s1))
	assert_true(si.link_support(s2))
	assert_false(si.link_support(s3))

func test_computed_stats_update_on_link() -> void:
	var si := SkillInstance.new(_fireball)
	si.link_support(_chain)
	assert_almost_eq(si.computed_stats["damage"], 8.0, 0.01)
	assert_eq(si.computed_stats["chain_count"], 3)

func test_added_tags() -> void:
	var si := SkillInstance.new(_fireball)
	si.link_support(_chain)
	var tags := si.get_all_tags()
	assert_has(tags, "chain")
	assert_has(tags, "projectile")
	assert_has(tags, "fire")

func test_unlink_support() -> void:
	var si := SkillInstance.new(_fireball)
	si.link_support(_chain)
	si.unlink_support(_chain)
	assert_eq(si.linked_supports.size(), 0)
	assert_eq(si.computed_stats["damage"], 10.0)

func test_cast_modes_and_echo_cannot_silently_override_each_other() -> void:
	var si := SkillInstance.new(_fireball)
	var mine := load("res://resources/supports/mine.tres") as SupportResource
	var totem := load("res://resources/supports/totem.tres") as SupportResource
	var echo := load("res://resources/supports/spell_echo.tres") as SupportResource
	assert_true(si.link_support(mine))
	assert_false(si.link_support(totem))
	assert_false(si.link_support(echo))

func test_mine_rejects_projectile_only_supports() -> void:
	var si := SkillInstance.new(_fireball)
	var pierce := load("res://resources/supports/pierce.tres") as SupportResource
	var mine := load("res://resources/supports/mine.tres") as SupportResource
	assert_true(si.link_support(pierce))
	assert_false(si.link_support(mine))

func test_mutation_projectile_count_respects_final_cap() -> void:
	var si := SkillInstance.new(_fireball)
	si.add_mutation({"id": "scatter", "stats": {"projectile_count": 99}})
	assert_eq(si.computed_stats["projectile_count"], StatCalculator.STAT_MAXS["projectile_count"])

func test_mutations_respect_all_final_stat_bounds() -> void:
	var fragile := SkillResource.new()
	fragile.base_damage = 1.0
	fragile.base_cooldown = 0.05
	var si := SkillInstance.new(fragile)
	si.add_mutation({"id": "extreme_tradeoff", "stats": {
		"damage_mult": 0.01, "cooldown_mult": 0.01,
	}})
	assert_eq(si.computed_stats["damage"], StatCalculator.STAT_MINS["damage"])
	assert_eq(si.computed_stats["cooldown"], StatCalculator.STAT_MINS["cooldown"])
