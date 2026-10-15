class_name ArtifactBehavior
extends RefCounted

var artifact_id: String = ""
var parameters: Dictionary = {}
var runtime: ArtifactRuntime

func setup(_context: Dictionary) -> void:
	pass

func before_skill_recompute(_skill: SkillInstance) -> void:
	pass

func handle(_event: StringName, _context: Dictionary) -> void:
	pass

func teardown() -> void:
	pass
