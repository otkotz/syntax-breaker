class_name AttackContext
extends RefCounted

const MAX_GENERATION := 3

var root_cast_id: int
var skill_id: String
var source_chain: Array[String] = []
var flags: Dictionary = {}
var generation := 0

static func root(id: String, cast_id: int) -> AttackContext:
	var context := AttackContext.new()
	context.skill_id = id
	context.root_cast_id = cast_id
	return context

func derive(source_id: String, flag: String) -> AttackContext:
	var child := duplicate_context()
	child.generation += 1
	child.source_chain.append(source_id)
	child.flags[flag] = true
	return child

func duplicate_context() -> AttackContext:
	var copy := AttackContext.new()
	copy.root_cast_id = root_cast_id
	copy.skill_id = skill_id
	copy.source_chain = source_chain.duplicate()
	copy.flags = flags.duplicate()
	copy.generation = generation
	return copy

func has_flag(flag: String) -> bool:
	return flags.has(flag)

func can_derive(source_id: String, flag: String) -> bool:
	return generation < MAX_GENERATION and not flags.has(flag) and not source_chain.has(source_id)

static func can_spawn_child(_kind: String, active_count: int, quality_cap: int) -> bool:
	return quality_cap > 0 and active_count >= 0 and active_count < quality_cap
