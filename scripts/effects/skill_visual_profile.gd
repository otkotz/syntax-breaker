class_name SkillVisualProfile
extends Resource

@export var skill_id: String = ""
@export var core_shape: StringName = &""
@export var cast_signature: StringName = &""
@export var hit_signature: StringName = &""
@export var residue_signature: StringName = &""
@export var primary_color: Color = Color.WHITE
@export var accent_color: Color = Color.WHITE
@export_range(0.01, 0.20, 0.01) var max_screen_coverage := 0.12
