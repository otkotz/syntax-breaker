extends GutTest

var _fireball: SkillResource
var _chain: SupportResource
var _faster_casting: SupportResource
var _beam_only: SupportResource
var _fire_mastery: PassiveResource
var _thick_skin: PassiveResource

func before_each() -> void:
	_fireball = SkillResource.new()
	_fireball.id = "fireball"
	_fireball.tags = ["projectile", "fire"]

	_chain = SupportResource.new()
	_chain.id = "chain"
	_chain.required_tags = ["projectile"]
	_chain.excluded_tags = ["beam"]

	_faster_casting = SupportResource.new()
	_faster_casting.id = "faster_casting"
	_faster_casting.required_tags = []

	_beam_only = SupportResource.new()
	_beam_only.id = "beam_focus"
	_beam_only.required_tags = ["beam"]

	_fire_mastery = PassiveResource.new()
	_fire_mastery.id = "fire_mastery"
	_fire_mastery.affected_tags = ["fire"]

	_thick_skin = PassiveResource.new()
	_thick_skin.id = "thick_skin"
	_thick_skin.affected_tags = []

func test_can_link_matching_tag() -> void:
	assert_true(TagMatcher.can_link_support(_fireball, _chain))

func test_cannot_link_missing_tag() -> void:
	assert_false(TagMatcher.can_link_support(_fireball, _beam_only))

func test_universal_support_links_to_any() -> void:
	assert_true(TagMatcher.can_link_support(_fireball, _faster_casting))

func test_excluded_tag_blocks_link() -> void:
	var beam_skill := SkillResource.new()
	beam_skill.tags = ["projectile", "beam"]
	assert_false(TagMatcher.can_link_support(beam_skill, _chain))

func test_matching_passives_by_tag() -> void:
	var passives: Array = [_fire_mastery, _thick_skin]
	var result := TagMatcher.get_matching_passives(_fireball, passives)
	assert_eq(result.size(), 2)

func test_matching_passives_excludes_unrelated() -> void:
	var lightning_passive := PassiveResource.new()
	lightning_passive.affected_tags = ["lightning"]
	var passives: Array = [lightning_passive]
	var result := TagMatcher.get_matching_passives(_fireball, passives)
	assert_eq(result.size(), 0)

func test_get_linkable_supports() -> void:
	var supports: Array = [_chain, _faster_casting, _beam_only]
	var result := TagMatcher.get_linkable_supports(_fireball, supports)
	assert_eq(result.size(), 2)
	assert_has(result, _chain)
	assert_has(result, _faster_casting)
