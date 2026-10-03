extends Node

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _ready() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	MetaProgression.save_path = "res://.godot/cosmetics_meta_test.json"
	MetaProgression.completed_challenges = {}
	MetaProgression.region_victories = {}
	MetaProgression.selected_cosmetics = CosmeticStyles.DEFAULTS.duplicate()
	RunManager.start_run()
	check(not MetaProgression.equip_cosmetic("silver_cloak"), "Locked style cannot be equipped")
	check(not MetaProgression.equip_cosmetic("not_a_style"), "Unknown style cannot be equipped")
	var baseline := RunManager.run_stats.duplicate(true)
	MetaProgression.completed_challenges = {"no_healing": {}, "mine_only": {}, "two_elements": {}}
	check(MetaProgression.equip_cosmetic("silver_cloak"), "Achievement unlocks cloak")
	var original := BreakerSprite.palette("fire")
	var cosmetic := CosmeticStyles.player_palette("fire")
	check(original[3] != cosmetic[3], "Cloak palette visibly changes")
	for index in original.size():
		if index < 2 or index > 5:
			check(original[index] == cosmetic[index], "Cosmetic preserves non-cloak palette slot %d" % index)
	check(MetaProgression.equip_cosmetic("faceted_trails"), "Dual Compiler unlocks projectile style")
	MetaProgression.selected_cosmetics = {}
	MetaProgression.load_progress()
	check(CosmeticStyles.selected("player") == "silver_cloak" and CosmeticStyles.selected("projectile") == "faceted_trails", "Selections persist in profile")
	check(RunManager.run_stats == baseline and RunManager.shop_bonuses.is_empty(), "Equipping does not alter run stats or bonuses")
	MetaProgression.selected_cosmetics.player = "unknown"
	check(CosmeticStyles.selected("player") == "player_default", "Bad profile ID falls back safely")
	MetaProgression.selected_cosmetics.player = "faceted_trails"
	check(CosmeticStyles.selected("player") == "player_default", "Wrong cosmetic slot falls back safely")
	MetaProgression.selected_cosmetics.player = "silver_cloak"
	var fire := SkillInstance.new(load("res://resources/skills/fireball.tres"))
	var projectile := ProjectileBase.new()
	add_child(projectile)
	projectile.set_physics_process(false)
	projectile.initialize(fire, Vector2.RIGHT, null)
	var mechanics := [projectile.damage, projectile.speed, projectile._max_range, projectile.scale, projectile._color,
		projectile.collision_layer, projectile.collision_mask, projectile.pierce_remaining]
	check(projectile._cosmetic_style == "faceted_trails", "Projectile reads equipped style at spawn")
	projectile._return_to_pool()
	projectile.reset()
	check(projectile._cosmetic_style == "projectile_default", "Pool reset clears style")
	MetaProgression.equip_cosmetic("projectile_default")
	projectile.initialize(fire, Vector2.RIGHT, null)
	check(mechanics == [projectile.damage, projectile.speed, projectile._max_range, projectile.scale, projectile._color,
		projectile.collision_layer, projectile.collision_mask, projectile.pierce_remaining], "Style has no damage, speed, range, scale, element, collision or pierce effect")
	projectile._return_to_pool()
	projectile.queue_free()
	MetaProgression.region_victories = {"burning_grounds": 2}
	var codex := preload("res://scenes/ui/codex.tscn").instantiate() as CodexUI
	add_child(codex)
	var trophies := codex._get_entries("trophies")
	check(trophies.size() == 3 and trophies[0].discovered and not trophies[1].discovered, "Trophies use actual regional victories, not generic discovery")
	codex._select_category("trophies")
	await get_tree().process_frame
	check(codex.entry_list.get_child_count() == 3 and codex.count_label.text.contains("1 / 3"), "Codex displays three regional trophies")
	codex._select_category("cosmetics")
	await get_tree().process_frame
	check(codex.entry_list.get_child_count() == 5, "Codex exposes default and unlocked styles")
	codex.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: cosmetic unlocks, profile selection, cloak-only palette, projectile mechanics invariance, pool reset and regional trophies")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
