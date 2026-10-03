class_name BuildOptions
extends RefCounted

## Keep offers usable by the current loadout. A mastery only works when its
## matching support is linked; a tagged passive needs a matching active skill.
static func can_offer_support(support: SupportResource, skills: Array[SkillInstance]) -> bool:
	var owned_count := 0
	for owned: Resource in RunManager.owned_supports:
		if owned is SupportResource and owned.id == support.id:
			owned_count += 1
	var linked_count := 0
	for si: SkillInstance in skills:
		for linked: SupportResource in si.linked_supports:
			if linked.id == support.id:
				linked_count += 1
	if owned_count > linked_count:
		return false
	for si: SkillInstance in skills:
		if not TagMatcher.can_link_support(si.base, support):
			continue
		var usable := si.support_rejection_reason(support).is_empty()
		if not usable and si.linked_supports.size() >= si.base.max_supports:
			for replacing: SupportResource in si.linked_supports:
				if si.support_rejection_reason(support, replacing).is_empty():
					usable = true
					break
		if not usable:
			continue
		var already_linked := false
		for linked: SupportResource in si.linked_supports:
			if linked.id == support.id:
				already_linked = true
				break
		if not already_linked:
			return true
	return false

static func can_offer_passive(passive: PassiveResource, skills: Array[SkillInstance]) -> bool:
	if passive.id.ends_with("_mastery") and passive.affected_tags.is_empty():
		var support_id := passive.id.trim_suffix("_mastery")
		for si: SkillInstance in skills:
			for linked: SupportResource in si.linked_supports:
				if linked.id == support_id:
					return true
		return false
	if passive.id == "arcane_tempo" and skills.size() < 2:
		return false
	if passive.is_global():
		return true
	for si: SkillInstance in skills:
		if si.base.has_any_tag(passive.affected_tags):
			return true
	return false

static func is_focused_passive(passive: PassiveResource) -> bool:
	return not passive.is_global() or passive.id.ends_with("_mastery")
