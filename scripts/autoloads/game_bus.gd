extends Node

signal enemy_killed(enemy: Node2D, killer_skill: Resource)
signal enemy_hit(enemy: Node2D, damage: float, skill: Resource)
signal stage_cleared
signal gold_changed(new_amount: int)
signal player_died
signal run_ended(victory: bool)
signal skill_acquired(skill: Resource)
signal support_acquired(support: Resource)
signal passive_acquired(passive: Resource)
signal codex_discovered(category: String, entry_id: String)

func _ready() -> void:
	skill_acquired.connect(_on_skill_acquired)
	support_acquired.connect(_on_support_acquired)
	passive_acquired.connect(_on_passive_acquired)
	enemy_killed.connect(_on_enemy_killed)

func _on_skill_acquired(skill: Resource) -> void:
	if skill is SkillResource and MetaProgression.discover_codex("skills", skill.id):
		codex_discovered.emit("skills", skill.id)

func _on_support_acquired(support: Resource) -> void:
	if support is SupportResource and MetaProgression.discover_codex("supports", support.id):
		codex_discovered.emit("supports", support.id)

func _on_passive_acquired(passive: Resource) -> void:
	if passive is PassiveResource and MetaProgression.discover_codex("passives", passive.id):
		codex_discovered.emit("passives", passive.id)

func _on_enemy_killed(enemy: Node2D, _killer_skill: Resource) -> void:
	var enemy_type: String = enemy.get_enemy_id() if enemy.has_method("get_enemy_id") else enemy.get_class()
	MetaProgression.discover_codex("enemies", enemy_type)
