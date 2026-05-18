extends GutTest

var _fireball: SkillResource
var _chain: SupportResource
var _fire_mastery: PassiveResource

func before_each() -> void:
	_fireball = SkillResource.new()
	_fireball.id = "fireball"
	_fireball.tags = ["projectile", "fire"]
	_fireball.base_damage = 10.0
	_fireball.base_cooldown = 0.8
	_fireball.base_speed = 300.0
	_fireball.base_range = 400.0
	_fireball.base_pierce = 0

	_chain = SupportResource.new()
	_chain.id = "chain"
	_chain.required_tags = ["projectile"]
	_chain.stat_modifiers = {"damage_mult": 0.8, "chain_count": 3}

	_fire_mastery = PassiveResource.new()
	_fire_mastery.id = "fire_mastery"
	_fire_mastery.affected_tags = ["fire"]
	_fire_mastery.stat_modifiers = {"damage_mult": 1.2, "cooldown_mult": 0.9}

func test_base_stats_no_modifiers() -> void:
	var stats := StatCalculator.compute(_fireball, [], [])
	assert_eq(stats["damage"], 10.0)
	assert_eq(stats["cooldown"], 0.8)

func test_support_multiplier() -> void:
	var stats := StatCalculator.compute(_fireball, [_chain], [])
	assert_almost_eq(stats["damage"], 8.0, 0.01)
	assert_eq(stats["chain_count"], 3)

func test_passive_multiplier() -> void:
	var stats := StatCalculator.compute(_fireball, [], [_fire_mastery])
	assert_almost_eq(stats["damage"], 12.0, 0.01)
	assert_almost_eq(stats["cooldown"], 0.72, 0.01)

func test_support_and_passive_stack() -> void:
	var stats := StatCalculator.compute(_fireball, [_chain], [_fire_mastery])
	assert_almost_eq(stats["damage"], 9.6, 0.01)

func test_unrelated_passive_ignored() -> void:
	var lightning_passive := PassiveResource.new()
	lightning_passive.affected_tags = ["lightning"]
	lightning_passive.stat_modifiers = {"damage_mult": 1.5}
	var stats := StatCalculator.compute(_fireball, [], [lightning_passive])
	assert_eq(stats["damage"], 10.0)

func test_clamp_minimum_damage() -> void:
	var nuke_nerf := SupportResource.new()
	nuke_nerf.required_tags = []
	nuke_nerf.stat_modifiers = {"damage_mult": 0.001}
	var stats := StatCalculator.compute(_fireball, [nuke_nerf], [])
	assert_eq(stats["damage"], 1.0)

func test_additive_modifier() -> void:
	var pierce_support := SupportResource.new()
	pierce_support.required_tags = ["projectile"]
	pierce_support.stat_modifiers = {"pierce": 2}
	var stats := StatCalculator.compute(_fireball, [pierce_support], [])
	assert_eq(stats["pierce"], 2)
