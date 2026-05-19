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
