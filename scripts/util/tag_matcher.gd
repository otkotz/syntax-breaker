class_name TagMatcher
extends RefCounted

static func can_link_support(skill: SkillResource, support: SupportResource) -> bool:
	if not support.excluded_tags.is_empty():
		for tag in support.excluded_tags:
			if skill.has_tag(tag):
				return false
	if support.is_universal():
		return true
	return skill.has_any_tag(support.required_tags)

static func get_matching_passives(skill: SkillResource, passives: Array) -> Array:
	var matching: Array = []
	for passive: PassiveResource in passives:
		if passive.is_global() or skill.has_any_tag(passive.affected_tags):
			matching.append(passive)
	return matching

static func get_linkable_supports(skill: SkillResource, supports: Array) -> Array:
	var linkable: Array = []
	for support: SupportResource in supports:
		if can_link_support(skill, support):
			linkable.append(support)
	return linkable
